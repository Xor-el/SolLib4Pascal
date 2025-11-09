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

unit SlpSolanaRpcBatchComposer;

{$I ..\..\Include\SolLib.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  System.JSON,
  System.JSON.Readers,
  System.JSON.Serializers,
  SlpValueUtils,
  SlpSolanaRpcClient,
  SlpRpcMessage,
  SlpRpcModel,
  SlpRpcEnum,
  SlpRequestResult,
  SlpSolLibExceptions,
  SlpJsonKit,
  SlpJsonConverterFactory,
  SlpJsonStringEnumConverter;

type
  /// <summary>
  /// Encapsulates the request, the expected return type and will handle the response callback/task/delegate.
  /// </summary>
  TRpcBatchReqRespItem = class
  private
    FReq: TJsonRpcRequest;
    FResultType: PTypeInfo;
    FCallback: TProc<TJsonRpcBatchResponseItem, Exception>;
  public
    /// <summary>
    /// Construct a TRpcBatchReqRespItem instance.
    /// </summary>
    /// <param name="AReq"></param>
    /// <param name="AResultType"></param>
    /// <param name="ACallback"></param>
    constructor Create(const AReq: TJsonRpcRequest;
                       AResultType: PTypeInfo;
                       const ACallback: TProc<TJsonRpcBatchResponseItem, Exception>);

    destructor Destroy; override;

    /// <summary>
    /// Create a TRpcBatchReqRespItem instance ready for execution.
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="AId"></param>
    /// <param name="AMethod"></param>
    /// <param name="AParameters"></param>
    /// <param name="ACallback"></param>
    /// <returns></returns>
    class function CreateItem<T>(AId: Integer; const AMethod: string; AParameters: TList<TValue>;
      const ACallback: TProc<TJsonRpcBatchResponseItem, Exception>): TRpcBatchReqRespItem; static;

    property Req: TJsonRpcRequest read FReq;
    property ResultType: PTypeInfo read FResultType;
    property Callback: TProc<TJsonRpcBatchResponseItem, Exception> read FCallback;
  end;

  /// <summary>
  /// This object allows a caller to compose a batch of RPC requests for batch submission.
  /// </summary>
  TSolanaRpcBatchComposer = class
  private
    /// <summary>The IRpcClient instance to use.</summary>
    FRpcClient: IRpcClient;
    /// <summary>Batch of requests and their handlers.</summary>
    FReqs: TObjectList<TRpcBatchReqRespItem>;
    /// <summary>Holds the auto execution mode.</summary>
    FAutoMode: TBatchAutoExecuteMode;
    /// <summary>Holds the batch size threshold for the auto batch execution mode.</summary>
    FAutoBatchSize: Integer;

    FSerializer: TJsonSerializer;

    function GetCount: Integer;
    function BuildSerializer: TJsonSerializer;

    class function WrapCallback<T>(
      const ACallback: TProc<T, Exception>
    ): TProc<TJsonRpcBatchResponseItem, Exception>; static;

  public
    /// <summary>
    /// Constructs a new SolanaRpcBatchComposer instance.
    /// </summary>
    /// <param name="ARpcClient">A RPC client.</param>
    constructor Create(const ARpcClient: IRpcClient);
    destructor Destroy; override;

    /// <summary>
    /// How many requests are in this batch.
    /// </summary>
    property Count: Integer read GetCount;

    /// <summary>
    /// Sets the auto execute mode and trigger threshold.
    /// </summary>
    /// <param name="AMode">The auto execute mode to use.</param>
    /// <param name="ABatchSizeTrigger">The number of requests that will trigger a batch execution.</param>
    procedure AutoExecute(AMode: TBatchAutoExecuteMode; ABatchSizeTrigger: Integer);

    /// <summary>
    /// Returns a batch of JSON RPC requests.
    /// </summary>
    function CreateJsonRequests: TJsonRpcBatchRequest;

    /// <summary>
    /// Execute a batch request and process the response into the expected native types.
    /// Batch failure exception will invoke callbacks with an exception.
    /// </summary>
    function Execute: TJsonRpcBatchResponse; overload;

    /// <summary>
    /// Execute a batch request and process the response into the expected native types.
    /// Batch failure exception will invoke callbacks with an exception.
    /// </summary>
    /// <param name="AClient">The RPC client to execute this batch with.</param>
    function Execute(const AClient: IRpcClient): TJsonRpcBatchResponse; overload;

    /// <summary>
    /// Execute a batch request and process the response into the expected native types.
    /// Batch failure exception will throw an Exception and bypass callbacks.
    /// </summary>
    function ExecuteWithFatalFailure: TJsonRpcBatchResponse; overload;

    /// <summary>
    /// Execute a batch request and process the response into the expected native types.
    /// Batch failure exception will throw an Exception and bypass callbacks.
    /// </summary>
    /// <param name="AClient">The RPC client to execute this batch with.</param>
    function ExecuteWithFatalFailure(const AClient: IRpcClient): TJsonRpcBatchResponse; overload;

    /// <summary>
    /// Handles the conversion of the generic JSON-deserialized response values to the native types.
    /// </summary>
    /// <param name="AResponse">The successful batch response.</param>
    function ProcessBatchResponse(
      const AResponse: IRequestResult<TJsonRpcBatchResponse>
    ): TJsonRpcBatchResponse;

    /// <summary>
    /// Process a failed batch response by notifying all callbacks with the exception.
    /// </summary>
    /// <param name="AResponse">The failed batch RPC response.</param>
    function ProcessBatchFailure(
      const AResponse: IRequestResult<TJsonRpcBatchResponse>
    ): TJsonRpcBatchResponse;

    /// <summary>
    /// Convert a generic value to desired response native type (no-op in Delphi unless you box JSON).
    /// </summary>
    /// <param name="AInput">Input value.</param>
    /// <param name="ANativeType">Target type info.</param>
    function MapJsonTypeToNativeType(const AInput: TValue; ANativeType: PTypeInfo): TValue;

    /// <summary>
    /// Clears the internal list of requests.
    /// </summary>
    procedure Clear;

    /// <summary>
    /// Executes any batch using the auto execution mode (if set) or throws an exception.
    /// </summary>
    procedure Flush;

    /// <summary>
    /// Adds a request with a typed callback.
    /// </summary>
    procedure AddRequest<T>(
      const AMethod: string; AParameters: TList<TValue>;
      const ACallback: TProc<T, Exception>
    );

    /// <summary>
    /// Adds a prepared request item to the batch (and auto-executes if configured).
    /// </summary>
    procedure Add(const ATask: TRpcBatchReqRespItem);
  end;

implementation

{ TRpcBatchReqRespItem }

constructor TRpcBatchReqRespItem.Create(const AReq: TJsonRpcRequest;
  AResultType: PTypeInfo; const ACallback: TProc<TJsonRpcBatchResponseItem, Exception>);
begin
  if not Assigned(AReq) then
    raise EArgumentNilException.Create('AReq');
  if AResultType = nil then
    raise EArgumentNilException.Create('AResultType');
  FReq := AReq;
  FResultType := AResultType;
  FCallback := ACallback;
end;

destructor TRpcBatchReqRespItem.Destroy;
begin
  if Assigned(FReq) then
    FReq.Free;

  if Assigned(FResultType) then
    FResultType := nil;

  if Assigned(FCallback) then
    FCallback := nil;
  inherited;
end;

class function TRpcBatchReqRespItem.CreateItem<T>(AId: Integer; const AMethod: string;
  AParameters: TList<TValue>; const ACallback: TProc<TJsonRpcBatchResponseItem, Exception>): TRpcBatchReqRespItem;
var
  LReq: TJsonRpcRequest;
begin
  LReq := TJsonRpcRequest.Create(AId, AMethod, AParameters);
  Result := TRpcBatchReqRespItem.Create(LReq, TypeInfo(T), ACallback);
end;

{ TSolanaRpcBatchComposer }

constructor TSolanaRpcBatchComposer.Create(const ARpcClient: IRpcClient);
begin
  inherited Create;
  if not Assigned(ARpcClient) then
    raise EArgumentNilException.Create('ARpcClient');
  FRpcClient := ARpcClient;
  FReqs := TObjectList<TRpcBatchReqRespItem>.Create(True);
  FAutoMode := TBatchAutoExecuteMode.Manual;
  FAutoBatchSize := 0;
  FSerializer := BuildSerializer;
end;

destructor TSolanaRpcBatchComposer.Destroy;
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

  if Assigned(FReqs) then
    FReqs.Free;

  inherited;
end;

function TSolanaRpcBatchComposer.GetCount: Integer;
begin
  Result := FReqs.Count;
end;

function TSolanaRpcBatchComposer.BuildSerializer: TJsonSerializer;
var
  Converters: TList<TJsonConverter>;
begin
  Converters := TJsonConverterFactory.GetRpcConverters();
  try
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

procedure TSolanaRpcBatchComposer.AutoExecute(AMode: TBatchAutoExecuteMode; ABatchSizeTrigger: Integer);
begin
  FAutoMode := AMode;
  FAutoBatchSize := ABatchSizeTrigger;
end;

function TSolanaRpcBatchComposer.CreateJsonRequests: TJsonRpcBatchRequest;
var
  LReq: TRpcBatchReqRespItem;
begin
  Result := TJsonRpcBatchRequest.Create;
  for LReq in FReqs do
    Result.Add(LReq.Req.Clone());
end;

function TSolanaRpcBatchComposer.Execute: TJsonRpcBatchResponse;
begin
  Result := Execute(FRpcClient);
end;

function TSolanaRpcBatchComposer.Execute(
  const AClient: IRpcClient
): TJsonRpcBatchResponse;
var
  LBatch: TJsonRpcBatchRequest;
  LResp : IRequestResult<TJsonRpcBatchResponse>;
begin
  LBatch := CreateJsonRequests;
  try
    LResp := AClient.SendBatchRequest(LBatch);
    if LResp.WasSuccessful then
      Result := ProcessBatchResponse(LResp)
    else
      Result := ProcessBatchFailure(LResp);
  finally
    LBatch.Free;
  end;
end;

function TSolanaRpcBatchComposer.ExecuteWithFatalFailure: TJsonRpcBatchResponse;
begin
  Result := ExecuteWithFatalFailure(FRpcClient);
end;

function TSolanaRpcBatchComposer.ExecuteWithFatalFailure(
  const AClient: IRpcClient
): TJsonRpcBatchResponse;
var
  LBatch: TJsonRpcBatchRequest;
  LResp : IRequestResult<TJsonRpcBatchResponse>;
begin
  LBatch := CreateJsonRequests;
  try
    LResp := AClient.SendBatchRequest(LBatch);
    if LResp.WasSuccessful then
      Result := ProcessBatchResponse(LResp)
    else
      raise Exception.CreateFmt('Batch was unsuccessful: %s', [LResp.Reason]);
  finally
    LBatch.Free;
  end;
end;

function TSolanaRpcBatchComposer.ProcessBatchResponse(
  const AResponse: IRequestResult<TJsonRpcBatchResponse>
): TJsonRpcBatchResponse;
var
  I: Integer;
  LReq : TRpcBatchReqRespItem;
  LItem: TJsonRpcBatchResponseItem;
  LInvoked: Boolean;
begin
  if not Assigned(AResponse.Result) then
    raise EArgumentNilException.Create('AResponse.Result');

  if FReqs.Count <> AResponse.Result.Count then
    raise Exception.CreateFmt('Batch req/resp size mismatch %d/%d',
      [FReqs.Count, AResponse.Result.Count]);

  try
    // Transfer expected type info to individual batch response items
    for I := 0 to FReqs.Count - 1 do
    begin
      LReq  := FReqs[I];
      LItem := AResponse.Result[I];

      // Set the runtime type on the response item
      LItem.ResultType := LReq.ResultType;

      LInvoked := False;
      try
        // Remap "generic" (JSON DOM node) value to POCO runtime (no-op unless JSON boxing)
        if LReq.ResultType <> nil then
          LItem.Result := MapJsonTypeToNativeType(LItem.Result, LReq.ResultType);
      except
        on E: Exception do
        begin
          if Assigned(LReq.Callback) then
          begin
            LInvoked := True;
            LReq.Callback(LItem, E);
          end;
        end;
      end;

      // Success path callback
      if (not LInvoked) and Assigned(LReq.Callback) then
        LReq.Callback(LItem, nil);
    end;

    //Result := AResponse.Result;
    Result := AResponse.Result; // transfer ownership to Result
    AResponse.Result := nil; // prevent double free in finally

  finally
    // Reset composer for reuse even if callbacks raise
    Clear;
  end;

end;

function TSolanaRpcBatchComposer.ProcessBatchFailure(
  const AResponse: IRequestResult<TJsonRpcBatchResponse>
): TJsonRpcBatchResponse;
var
  LEx : EBatchRequestException;
  LReq: TRpcBatchReqRespItem;
begin
  if AResponse = nil then
    raise EArgumentNilException.Create('AResponse');

  LEx := EBatchRequestException.Create(AResponse);
  try
    try
      for LReq in FReqs do
        if Assigned(LReq.Callback) then
          try
            LReq.Callback(nil, LEx);
          except
            on E: EBatchRequestException do
            begin
              // If the callback re-raised the SAME exception instance,
              // let the RTL own & free it during unwinding.
              if E = LEx then
                LEx := nil;
              raise;
            end;
          end;

      Result := AResponse.Result; // transfer ownership to Result
      AResponse.Result := nil; // prevent double free in finally

    finally
      // Free our exception unless we've relinquished it to the RTL via re-raise
      if Assigned(LEx) then
        LEx.Free;

      Clear;
    end;
  except
    // re-raise other exceptions, just let them bubble up
    raise;
  end;
end;

function TSolanaRpcBatchComposer.MapJsonTypeToNativeType(
  const AInput: TValue; ANativeType: PTypeInfo
): TValue;
var
  LTextReader: TTextReader;
  LJsonReader: TJsonTextReader;
  LTarget    : TValue;
  LJson      : TJSONValue;
  IsClass    : Boolean;
  Obj        : TObject;
begin
  Result := AInput;
  if (ANativeType = nil) or AInput.IsEmpty then Exit;
  if (AInput.Kind <> tkClass) or not (AInput.AsObject is TJSONValue) then Exit;

  TValue.Make(nil, ANativeType, LTarget);
  IsClass := (ANativeType^.Kind = tkClass);
  if IsClass then
    LTarget := TValueUtils.MakeInstanceForPopulate(ANativeType);

  LJson := TJSONValue(AInput.AsObject);
  try
    LTextReader := TStringReader.Create(LJson.ToJSON);
    try
      LJsonReader := TJsonTextReader.Create(LTextReader);
      try
        try
          FSerializer.Populate(LJsonReader, LTarget);
        except
          on E: Exception do
          begin
            if IsClass and LTarget.TryAsType<TObject>(Obj) then
              Obj.Free; // prevent leak on failed populate
            raise;
          end;
        end;
      finally
        LJsonReader.Free;
      end;
    finally
      LTextReader.Free;
    end;
  finally
    // Free the JSON DOM now that we've consumed it.
    LJson.Free;
  end;

  Result := LTarget;
end;


procedure TSolanaRpcBatchComposer.Clear;
begin
  FReqs.Clear;
end;

procedure TSolanaRpcBatchComposer.Flush;
var
  Res: TJsonRpcBatchResponse;
begin
  Res := nil;
  try
    case FAutoMode of
      TBatchAutoExecuteMode.ExecuteWithFatalFailure:
       Res := ExecuteWithFatalFailure(FRpcClient);

      TBatchAutoExecuteMode.ExecuteWithCallbackFailures:
        Res := Execute(FRpcClient);
    else
      raise Exception.Create('BatchComposer AutoExecute mode not set');
    end;

  finally

    Res.Free;
  end;
end;

procedure TSolanaRpcBatchComposer.AddRequest<T>(
  const AMethod: string; AParameters: TList<TValue>;
  const ACallback: TProc<T, Exception>
);
var
  LWrapped: TProc<TJsonRpcBatchResponseItem, Exception>;
  LHandler: TRpcBatchReqRespItem;
begin
  LWrapped := WrapCallback<T>(ACallback);
  LHandler := TRpcBatchReqRespItem.CreateItem<T>(
    FRpcClient.GetNextIdForReq, AMethod, AParameters, LWrapped
  );
  Add(LHandler);
end;

procedure TSolanaRpcBatchComposer.Add(const ATask: TRpcBatchReqRespItem);
begin
  FReqs.Add(ATask);
  // does this trigger an auto execute?
  if (FAutoMode <> TBatchAutoExecuteMode.Manual) and (FReqs.Count >= FAutoBatchSize) then
    Flush;
end;

class function TSolanaRpcBatchComposer.WrapCallback<T>(
  const ACallback: TProc<T, Exception>
): TProc<TJsonRpcBatchResponseItem, Exception>;
begin
  if not Assigned(ACallback) then
    Exit(nil);

  Result :=
    procedure (AItem: TJsonRpcBatchResponseItem; AE: Exception)
    var
      LObj: T;
    begin
      if Assigned(AItem) then
        LObj := AItem.ResultAs<T>()
      else
      begin
        LObj := Default(T);
      end;
      ACallback(LObj, AE);
    end;
end;

end.

