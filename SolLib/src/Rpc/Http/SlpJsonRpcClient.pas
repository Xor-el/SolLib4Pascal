{ * ************************************************************************ * }
{ *                              SolLib Library                              * }
{ *                  Copyright (c) 2025 Ugochukwu Mmaduekwe                  * }
{ *              Github Repository <https://github.com/Xor-el>               * }
{ *                                                                          * }
{ *  Distributed under the MIT software license, see the accompanying file   * }
{ *                                 LICENSE                                  * }
{ *         or visit http://www.opensource.org/licenses/mit-license.         * }
{ *                                                                          * }
{ *                            Acknowledgements:                             * }
{ *                                                                          * }
{ *  Thanks to InstallAware (https://www.installaware.com/) for sponsoring   * }
{ *                     the development of this library                      * }
{ * ************************************************************************ * }

(* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& *)

unit SlpJsonRpcClient;

{$I ..\..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Classes,
  System.Generics.Collections,
  System.JSON.Types,
  System.JSON.Serializers,
{$IFDEF FPC}
  URIParser,
{$ELSE}
  System.Net.URLClient,
{$ENDIF}
  SlpRateLimiter,
  SlpRequestResult,
  SlpRpcMessage,
  SlpJsonKit,
  SlpEncodingConverter,
  SlpJsonStringEnumConverter,
  SlpHttpApiResponse,
  SlpHttpApiClient,
  SlpLogger;

type
  /// <summary>
  /// Base Rpc client class that abstracts the HTTP handling through IRpcHttpClient.
  /// </summary>
  TJsonRpcClient = class abstract(TInterfacedObject)
  private
    FSerializer: TJsonSerializer;
    FClient: IHttpApiClient;
    FRateLimiter: IRateLimiter;
    FLogger: ILogger;
    FNodeAddress: TURI;

    class function IsNonEmptyValue<T>(const AValue: T): Boolean; static;

  protected

    function GetNodeAddress: TURI;

    /// Override to customize the serializer (add converters, etc.)
    function BuildSerializer: TJsonSerializer; virtual;

    /// Serialize Request to JSON string.
    function SerializeRequest(const Req: TJsonRpcRequest): string; virtual;

    /// <summary>
    /// Handles the result after sending a request.
    /// </summary>
    function HandleResult<T>(const Response: IHttpApiResponse): TRequestResult<T>;

    /// <summary>
    /// Handles the result after sending a batch of requests.
    /// </summary>
    function HandleBatchResult(const Response: IHttpApiResponse): TRequestResult<TJsonRpcBatchResponse>;

  public
    /// <summary>
    /// The internal constructor that setups the client.
    /// </summary>
    /// <param name="AUrl">The url of the RPC server.</param>
    /// <param name="AClient">The abstracted RPC HTTP client.</param>
    /// <param name="ALogger">The abstracted Logger instance or nil for no logger</param>
    /// <param name="ARateLimiter">An IRateLimiter instance or nil for no rate limiting.</param>
    constructor Create(const AUrl: string; const AClient: IHttpApiClient; const ALogger: ILogger = nil; const ARateLimiter: IRateLimiter = nil);
    destructor Destroy; override;

    /// <summary>The RPC node address (full URL).</summary>
    property NodeAddress: TURI read FNodeAddress;

  protected
    /// <summary>
    /// Sends a given message as a POST method and returns the deserialized message result based on the type parameter.
    /// </summary>
    function SendRequest<T>(const Req: TJsonRpcRequest): TRequestResult<T>;

  public
    /// <summary>
    /// Sends a batch of messages as a POST method and returns a collection of responses.
    /// </summary>
    function SendBatchRequest(const Reqs: TJsonRpcBatchRequest): TRequestResult<TJsonRpcBatchResponse>;
  end;

implementation

{ TJsonRpcClient }

constructor TJsonRpcClient.Create(const AUrl: string; const AClient: IHttpApiClient; const ALogger: ILogger; const ARateLimiter: IRateLimiter);
begin
  inherited Create;
  if not Assigned(AClient) then
    raise EArgumentNilException.Create('AClient');

  FNodeAddress := TURI.Create(AUrl);
  FClient := AClient;
  FLogger := ALogger;
  FRateLimiter := ARateLimiter;
  FSerializer := BuildSerializer;
end;

destructor TJsonRpcClient.Destroy;
var
  I: Integer;
begin
  if Assigned(FSerializer) then
  begin
    if Assigned(FSerializer.Converters) then
    begin
      for I := 0 to FSerializer.Converters.Count - 1 do
        if Assigned(FSerializer.Converters[I]) then
          FSerializer.Converters[I].Free;
      FSerializer.Converters.Clear;
    end;
    FSerializer.Free;
  end;

  inherited;
end;

function TJsonRpcClient.GetNodeAddress: TURI;
begin
  Result := FNodeAddress;
end;

function TJsonRpcClient.BuildSerializer: TJsonSerializer;
var
  Converters: TList<TJsonConverter>;
begin
  Converters := TList<TJsonConverter>.Create;
  try
    Converters.Add(TEncodingConverter.Create);
    Converters.Add(TJsonStringEnumConverter.Create(TJsonNamingPolicy.CamelCase));
    Result := TJsonSerializerFactory.CreateSerializer(
      TEnhancedContractResolver.Create(
        TJsonMemberSerialization.Public,
        TJsonNamingPolicy.CamelCase
      ),
      Converters
    );
  finally
    Converters.Free;
  end;
end;

function TJsonRpcClient.SerializeRequest(const Req: TJsonRpcRequest): string;
begin
  Result := FSerializer.Serialize(Req);
end;

class function TJsonRpcClient.IsNonEmptyValue<T>(const AValue: T): Boolean;
var
  V: TValue;
begin
  V := TValue.From<T>(AValue);
  if V.IsEmpty then
    Exit(False);

  case V.Kind of
    // treat strings specially: must be non-empty text
    tkUString, tkLString, tkWString, tkString:
      Result := V.AsString <> '';
  else
    // for everything else, "not empty" is enough
    Result := True;
  end;
end;

function TJsonRpcClient.HandleResult<T>(const Response: IHttpApiResponse): TRequestResult<T>;
var
  ResultObj: TRequestResult<T>;
  Raw: string;
  SingleRes: TJsonRpcResponse<T>;
  ErrRes: TJsonRpcErrorResponse;
begin
  ResultObj := TRequestResult<T>.CreateFromResponse(Response);
  try
    Raw := Response.ResponseBody;
    ResultObj.RawRpcResponse := Raw;

    if Assigned(FLogger) then
    FLogger.LogInformation('Rpc Response: {0}', [ResultObj.RawRpcResponse]);

    // ---- Try success shape ----
    SingleRes := nil;
    try
      SingleRes := FSerializer.Deserialize<TJsonRpcResponse<T>>(Raw);
      if Assigned(SingleRes) and IsNonEmptyValue<T>(SingleRes.Result) then
      begin
        // take ownership of payload, then null out wrapper to avoid double free/release
        ResultObj.Result := SingleRes.Result;
        SingleRes.Result := Default(T);

        ResultObj.WasRequestSuccessfullyHandled := True;
        Exit(ResultObj);
      end;
    finally
      SingleRes.Free;
    end;

    // ---- Try error shape ----
    ResultObj.Reason := 'Something wrong happened.';
    ErrRes := nil;
    ErrRes := FSerializer.Deserialize<TJsonRpcErrorResponse>(Raw);
    if Assigned(ErrRes) then
    begin
      try
        if Assigned(ErrRes.Error) then
        begin
          ResultObj.Reason := ErrRes.Error.Message;
          ResultObj.ServerErrorCode := ErrRes.Error.Code;

          // transfer ownership of Error.Data safely
          if Assigned(ErrRes.Error.Data) then
          begin
            ResultObj.ErrorData.Free;
            ResultObj.ErrorData := ErrRes.Error.Data;
            ErrRes.Error.Data := nil;
          end;
        end
        else if ErrRes.ErrorMessage <> '' then
          ResultObj.Reason := ErrRes.ErrorMessage;
      finally
        ErrRes.Free;
      end;
    end;

    ResultObj.WasRequestSuccessfullyHandled := False;
  except
    on E: Exception do
    begin
      ResultObj.WasRequestSuccessfullyHandled := False;
      ResultObj.Reason := 'Unable to parse json.';
      if Assigned(FLogger) then
      FLogger.LogException(TLogLevel.Error, E, 'An Exception Occurred In {0}', ['TJsonRpcClient.HandleResult<T>']);
    end;
  end;

  Result := ResultObj;
end;

function TJsonRpcClient.SendRequest<T>(const Req: TJsonRpcRequest): TRequestResult<T>;
var
  RequestJson: string;
  Resp: IHttpApiResponse;
begin
  RequestJson := SerializeRequest(Req);
  try
    if Assigned(FRateLimiter) then
      FRateLimiter.WaitFire;

    if Assigned(FLogger) and (Req.Id.HasValue) then
      FLogger.LogInformation(TEventId.Create(Req.Id.Value, Req.Method), 'Sending Request: {0}', [RequestJson]);

    Resp := FClient.PostJson(FNodeAddress.ToString, RequestJson);
    Result := HandleResult<T>(Resp);
    Result.RawRpcRequest := RequestJson;
  except
    on E: Exception do
    begin
      Result := TRequestResult<T>.CreateWithError(400, E.Message);
      Result.RawRpcRequest := RequestJson;
      if Assigned(FLogger) and (Req.Id.HasValue) then
      FLogger.LogException(TLogLevel.Error, TEventId.Create(Req.Id.Value, Req.Method), E, 'An Exception Occurred In {0}', ['TJsonRpcClient.SendRequest<T>']);
    end;
  end;
end;

function TJsonRpcClient.HandleBatchResult(const Response: IHttpApiResponse): TRequestResult<TJsonRpcBatchResponse>;
var
  ResultObj: TRequestResult<TJsonRpcBatchResponse>;
  Raw: string;
  BatchRes: TJsonRpcBatchResponse;
  ErrRes: TJsonRpcErrorResponse;
begin
  ResultObj := TRequestResult<TJsonRpcBatchResponse>.CreateFromResponse(Response);
  try
    Raw := Response.ResponseBody;
    ResultObj.RawRpcResponse := Raw;

    if Assigned(FLogger) then
    FLogger.LogInformation('Batch Rpc Response: {0}', [ResultObj.RawRpcResponse]);

    // ---- Try success shape ----
    BatchRes := nil;
    try
      BatchRes := FSerializer.Deserialize<TJsonRpcBatchResponse>(Raw);
      if Assigned(BatchRes) then
      begin
        // transfer ownership to ResultObj
        ResultObj.Result := BatchRes;
        BatchRes := nil; // prevent double free in finally

        ResultObj.WasRequestSuccessfullyHandled := True;
        Exit(ResultObj);
      end;
    finally
      BatchRes.Free;
    end;

    // ---- Try error shape ----
    ResultObj.Reason := 'Something wrong happened.';
    ErrRes := FSerializer.Deserialize<TJsonRpcErrorResponse>(Raw);
    if Assigned(ErrRes) then
    begin
      try
        if Assigned(ErrRes.Error) then
        begin
          ResultObj.Reason := ErrRes.Error.Message;
          ResultObj.ServerErrorCode := ErrRes.Error.Code;

          // transfer ownership of Error.Data safely
          if Assigned(ErrRes.Error.Data) then
          begin
            ResultObj.ErrorData := ErrRes.Error.Data; // take ownership
            ErrRes.Error.Data := nil;                 // avoid double-free on ErrRes.Free
          end;
        end
        else if ErrRes.ErrorMessage <> '' then
        begin
          ResultObj.Reason := ErrRes.ErrorMessage;
        end;
      finally
        ErrRes.Free;
      end;
    end;

    ResultObj.WasRequestSuccessfullyHandled := False;
  except
    on E: Exception do
    begin
      ResultObj.WasRequestSuccessfullyHandled := False;
      ResultObj.Reason := 'Unable to parse json.';
      if Assigned(FLogger) then
      FLogger.LogException(TLogLevel.Error, E, 'An Exception Occurred In {0}', ['TJsonRpcClient.HandleBatchResult']);
    end;
  end;

  Result := ResultObj;
end;

function TJsonRpcClient.SendBatchRequest(const Reqs: TJsonRpcBatchRequest): TRequestResult<TJsonRpcBatchResponse>;
var
  RequestsJson: string;
  Resp: IHttpApiResponse;
begin
  if Reqs = nil then
    raise EArgumentNilException.Create('reqs');
  if Reqs.Count = 0 then
    raise EArgumentException.Create('Empty batch');

  RequestsJson := FSerializer.Serialize(Reqs);

  try
    if Assigned(FRateLimiter) then
      FRateLimiter.WaitFire;

      if Assigned(FLogger) then
      FLogger.LogInformation('Batch Count: {0} Sending Batch Request: {1}', [Reqs.Count, RequestsJson]);

    Resp := FClient.PostJson(FNodeAddress.ToString, RequestsJson);
    Result := HandleBatchResult(Resp);
    Result.RawRpcRequest := RequestsJson;
  except
    on E: Exception do
    begin
      Result := TRequestResult<TJsonRpcBatchResponse>.CreateWithError(400, E.Message);
      Result.RawRpcRequest := RequestsJson;
      if Assigned(FLogger) then
      FLogger.LogException(TLogLevel.Error, E, 'An Exception Occurred In {0}', ['TJsonRpcClient.SendBatchRequest']);
    end;
  end;
end;

end.

