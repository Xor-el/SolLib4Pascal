{ * ************************************************************************ * }
{ *                              SolLib Library                              * }
{ *                       Author - Ugochukwu Mmaduekwe                       * }
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

{$I ../../Include/SolLib.inc}

interface

uses
  SysUtils,
  Rtti,
  Classes,
  Generics.Collections,
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
  SlpJsonConverterFactory,
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

    /// <summary>
    /// Override to customize the converter list.
    /// </summary>
    function GetConverters: TList<TJsonConverter>; virtual;

    /// <summary>
    /// Override to customize the serializer
    /// </summary>
    function BuildSerializer: TJsonSerializer; virtual;

    /// Serialize Request to JSON string.
    function SerializeRequest(const AReq: TJsonRpcRequest): string; virtual;

    /// <summary>
    /// Handles the result after sending a request.
    /// </summary>
    function HandleResult<T>(const AResponse: IHttpApiResponse): TRequestResult<T>;

    /// <summary>
    /// Handles the result after sending a batch of requests.
    /// </summary>
    function HandleBatchResult(const AResponse: IHttpApiResponse): TRequestResult<TJsonRpcBatchResponse>;

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
    function SendRequest<T>(const AReq: TJsonRpcRequest): TRequestResult<T>;

  public
    /// <summary>
    /// Sends a batch of messages as a POST method and returns a collection of responses.
    /// </summary>
    function SendBatchRequest(const AReqs: TJsonRpcBatchRequest): TRequestResult<TJsonRpcBatchResponse>;
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
  LI: Integer;
begin
  if Assigned(FSerializer) then
  begin
    if Assigned(FSerializer.Converters) then
    begin
      for LI := 0 to FSerializer.Converters.Count - 1 do
        if Assigned(FSerializer.Converters[LI]) then
          FSerializer.Converters[LI].Free;
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

function TJsonRpcClient.GetConverters: TList<TJsonConverter>;
begin
  Result := TJsonConverterFactory.GetRpcConverters();
end;

function TJsonRpcClient.BuildSerializer: TJsonSerializer;
var
  LConverters: TList<TJsonConverter>;
begin
  LConverters := GetConverters();
  try
    Result := TJsonSerializerFactory.CreateSerializer(
      TEnhancedContractResolver.Create(
        TJsonMemberSerialization.Public,
        TJsonNamingPolicy.CamelCase
      ),
      LConverters
    );
  finally
    LConverters.Free;
  end;
end;

function TJsonRpcClient.SerializeRequest(const AReq: TJsonRpcRequest): string;
begin
  Result := FSerializer.Serialize(AReq);
end;

class function TJsonRpcClient.IsNonEmptyValue<T>(const AValue: T): Boolean;
var
  LV: TValue;
begin
  LV := TValue.From<T>(AValue);
  if LV.IsEmpty then
    Exit(False);

  case LV.Kind of
    // treat strings specially: must be non-empty text
    tkUString, tkLString, tkWString, tkString:
      Result := LV.AsString <> '';
  else
    // for everything else, "not empty" is enough
    Result := True;
  end;
end;

function TJsonRpcClient.HandleResult<T>(const AResponse: IHttpApiResponse): TRequestResult<T>;
var
  LResultObj: TRequestResult<T>;
  LRaw: string;
  LSingleRes: TJsonRpcResponse<T>;
  LErrRes: TJsonRpcErrorResponse;
begin
  LResultObj := TRequestResult<T>.CreateFromResponse(AResponse);
  try
    LRaw := AResponse.ResponseBody;
    LResultObj.RawRpcResponse := LRaw;

    if Assigned(FLogger) then
    FLogger.LogInformation('Rpc Response: {0}', [LResultObj.RawRpcResponse]);

    // ---- Try success shape ----
    LSingleRes := nil;
    try
      LSingleRes := FSerializer.Deserialize<TJsonRpcResponse<T>>(LRaw);
      if Assigned(LSingleRes) and IsNonEmptyValue<T>(LSingleRes.Result) then
      begin
        // take ownership of payload, then null out wrapper to avoid double free/release
        LResultObj.Result := LSingleRes.Result;
        LSingleRes.Result := Default(T);

        LResultObj.WasRequestSuccessfullyHandled := True;
        Exit(LResultObj);
      end;
    finally
      LSingleRes.Free;
    end;

    // ---- Try error shape ----
    LResultObj.Reason := 'Something wrong happened.';
    LErrRes := nil;
    LErrRes := FSerializer.Deserialize<TJsonRpcErrorResponse>(LRaw);
    if Assigned(LErrRes) then
    begin
      try
        if Assigned(LErrRes.Error) then
        begin
          LResultObj.Reason := LErrRes.Error.Message;
          LResultObj.ServerErrorCode := LErrRes.Error.Code;

          // transfer ownership of Error.Data safely
          if Assigned(LErrRes.Error.Data) then
          begin
            LResultObj.ErrorData.Free;
            LResultObj.ErrorData := LErrRes.Error.Data;
            LErrRes.Error.Data := nil;
          end;
        end
        else if LErrRes.ErrorMessage <> '' then
          LResultObj.Reason := LErrRes.ErrorMessage;
      finally
        LErrRes.Free;
      end;
    end;

    LResultObj.WasRequestSuccessfullyHandled := False;
  except
    on E: Exception do
    begin
      LResultObj.WasRequestSuccessfullyHandled := False;
      LResultObj.Reason := 'Unable to parse json.';
      if Assigned(FLogger) then
      FLogger.LogException(TLogLevel.Error, E, 'An Exception Occurred In {0}', ['TJsonRpcClient.HandleResult<T>']);
    end;
  end;

  Result := LResultObj;
end;

function TJsonRpcClient.SendRequest<T>(const AReq: TJsonRpcRequest): TRequestResult<T>;
var
  LRequestJson: string;
  LResp: IHttpApiResponse;
begin
  LRequestJson := SerializeRequest(AReq);
  try
    if Assigned(FRateLimiter) then
      FRateLimiter.WaitFire;

    if Assigned(FLogger) and (AReq.Id.HasValue) then
      FLogger.LogInformation(TEventId.Create(AReq.Id.Value, AReq.Method), 'Sending Request: {0}', [LRequestJson]);

    LResp := FClient.PostJson(FNodeAddress.ToString, LRequestJson);
    Result := HandleResult<T>(LResp);
    Result.RawRpcRequest := LRequestJson;
  except
    on E: Exception do
    begin
      Result := TRequestResult<T>.CreateWithError(400, E.Message);
      Result.RawRpcRequest := LRequestJson;
      if Assigned(FLogger) and (AReq.Id.HasValue) then
      FLogger.LogException(TLogLevel.Error, TEventId.Create(AReq.Id.Value, AReq.Method), E, 'An Exception Occurred In {0}', ['TJsonRpcClient.SendRequest<T>']);
    end;
  end;
end;

function TJsonRpcClient.HandleBatchResult(const AResponse: IHttpApiResponse): TRequestResult<TJsonRpcBatchResponse>;
var
  LResultObj: TRequestResult<TJsonRpcBatchResponse>;
  LRaw: string;
  LBatchRes: TJsonRpcBatchResponse;
  LErrRes: TJsonRpcErrorResponse;
begin
  LResultObj := TRequestResult<TJsonRpcBatchResponse>.CreateFromResponse(AResponse);
  try
    LRaw := AResponse.ResponseBody;
    LResultObj.RawRpcResponse := LRaw;

    if Assigned(FLogger) then
    FLogger.LogInformation('Batch Rpc Response: {0}', [LResultObj.RawRpcResponse]);

    // ---- Try success shape ----
    LBatchRes := nil;
    try
      LBatchRes := FSerializer.Deserialize<TJsonRpcBatchResponse>(LRaw);
      if Assigned(LBatchRes) then
      begin
        // transfer ownership to LResultObj
        LResultObj.Result := LBatchRes;
        LBatchRes := nil; // prevent double free in finally

        LResultObj.WasRequestSuccessfullyHandled := True;
        Exit(LResultObj);
      end;
    finally
      LBatchRes.Free;
    end;

    // ---- Try error shape ----
    LResultObj.Reason := 'Something wrong happened.';
    LErrRes := FSerializer.Deserialize<TJsonRpcErrorResponse>(LRaw);
    if Assigned(LErrRes) then
    begin
      try
        if Assigned(LErrRes.Error) then
        begin
          LResultObj.Reason := LErrRes.Error.Message;
          LResultObj.ServerErrorCode := LErrRes.Error.Code;

          // transfer ownership of Error.Data safely
          if Assigned(LErrRes.Error.Data) then
          begin
            LResultObj.ErrorData := LErrRes.Error.Data; // take ownership
            LErrRes.Error.Data := nil;                 // avoid double-free on LErrRes.Free
          end;
        end
        else if LErrRes.ErrorMessage <> '' then
        begin
          LResultObj.Reason := LErrRes.ErrorMessage;
        end;
      finally
        LErrRes.Free;
      end;
    end;

    LResultObj.WasRequestSuccessfullyHandled := False;
  except
    on E: Exception do
    begin
      LResultObj.WasRequestSuccessfullyHandled := False;
      LResultObj.Reason := 'Unable to parse json.';
      if Assigned(FLogger) then
      FLogger.LogException(TLogLevel.Error, E, 'An Exception Occurred In {0}', ['TJsonRpcClient.HandleBatchResult']);
    end;
  end;

  Result := LResultObj;
end;

function TJsonRpcClient.SendBatchRequest(const AReqs: TJsonRpcBatchRequest): TRequestResult<TJsonRpcBatchResponse>;
var
  LRequestsJson: string;
  LResp: IHttpApiResponse;
begin
  if AReqs = nil then
    raise EArgumentNilException.Create('reqs');
  if AReqs.Count = 0 then
    raise EArgumentException.Create('Empty batch');

  LRequestsJson := FSerializer.Serialize(AReqs);

  try
    if Assigned(FRateLimiter) then
      FRateLimiter.WaitFire;

      if Assigned(FLogger) then
      FLogger.LogInformation('Batch Count: {0} Sending Batch Request: {1}', [AReqs.Count, LRequestsJson]);

    LResp := FClient.PostJson(FNodeAddress.ToString, LRequestsJson);
    Result := HandleBatchResult(LResp);
    Result.RawRpcRequest := LRequestsJson;
  except
    on E: Exception do
    begin
      Result := TRequestResult<TJsonRpcBatchResponse>.CreateWithError(400, E.Message);
      Result.RawRpcRequest := LRequestsJson;
      if Assigned(FLogger) then
      FLogger.LogException(TLogLevel.Error, E, 'An Exception Occurred In {0}', ['TJsonRpcClient.SendBatchRequest']);
    end;
  end;
end;

end.

