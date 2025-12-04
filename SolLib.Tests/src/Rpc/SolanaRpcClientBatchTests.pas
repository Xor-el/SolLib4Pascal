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

unit SolanaRpcClientBatchTests;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.JSON.Serializers,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpJsonKit,
  SlpJsonStringEnumConverter,
  SlpEncodingConverter,
  SlpRpcEnum,
  SlpHttpApiClient,
  SlpHttpApiResponse,
  SlpRpcMessage,
  SlpRpcModel,
  SlpRequestResult,
  SlpClientFactory,
  SlpSolanaRpcClient,
  SlpSolanaRpcBatchWithCallbacks,
  SlpSolLibExceptions,
  RpcClientMocks,
  TestUtils,
  SolLibRpcClientTestCase;

type
  TSolanaRpcClientBatchTests = class(TSolLibRpcClientTestCase)
  const
    TokenProgramProgramId: string = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
  private
    FSerializer: TJsonSerializer;
    function BuildSerializer: TJsonSerializer;
    function CreateMockRequestResult<T>(
      const Req, Resp: string;
      const StatusCode: Integer
    ): IRequestResult<T>;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestCreateAndSerializeBatchTokenMintInfoRequest;
    procedure TestDeserializeBatchResponse;
    procedure TestDeserializeBatchTokenMintInfoResponse;
    procedure TestTransactionError_1;
    procedure TestAutoExecuteMode;
    procedure TestBatchFailed;
  end;

implementation

{ TSolanaRpcClientBatchTests }

function TSolanaRpcClientBatchTests.CreateMockRequestResult<T>(
  const Req, Resp: string;
  const StatusCode: Integer
): IRequestResult<T>;
var
  LRes: TRequestResult<T>;
begin
  LRes := TRequestResult<T>.Create;
  LRes.HttpStatusCode := StatusCode;
  LRes.RawRpcRequest  := Req;
  LRes.RawRpcResponse := Resp;

  if StatusCode = 200 then
    LRes.Result := FSerializer.Deserialize<T>(Resp);

  Result := LRes;
end;

function TSolanaRpcClientBatchTests.BuildSerializer: TJsonSerializer;
var
  Converters: TList<TJsonConverter>;
begin
  Converters := TList<TJsonConverter>.Create;
  try
    Converters.Add(TJsonStringEnumConverter.Create(TJsonNamingPolicy.CamelCase));
    Converters.Add(TEncodingConverter.Create());
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

procedure TSolanaRpcClientBatchTests.SetUp;
begin
  inherited;
  FSerializer := BuildSerializer;
end;

procedure TSolanaRpcClientBatchTests.TearDown;
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

procedure TSolanaRpcClientBatchTests.TestCreateAndSerializeBatchTokenMintInfoRequest;
var
  expected, json: string;
  unusedRpcClient: IRpcClient;
  unusedMockRpcHttpClient: IHttpApiClient;
  batch: TSolanaRpcBatchWithCallbacks;
  reqs: TJsonRpcBatchRequest;
begin
  expected := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Batch', 'SampleBatchTokenMintInfoRequest.json'])
  );

  unusedMockRpcHttpClient := SetupTest('', 200);
  // compose a new batch of requests
  unusedRpcClient := TClientFactory.GetClient(TCluster.TestNet, unusedMockRpcHttpClient);

  batch := TSolanaRpcBatchWithCallbacks.Create(unusedRpcClient);
  try
    batch.GetTokenMintInfo('7yC2ABeaKRfvQsbZ5rA7cKTKF6YcyCYWV65jYrWrnhRN');
    batch.GetTokenMintInfo('GPytBb4s75MZxxviHJzpbHHgdWTcajmMDBd8VsBVAFS5');

    AssertEquals(2, batch.Composer.Count, 'Composer.Count');

    reqs := nil;
    try
      reqs := batch.Composer.CreateJsonRequests;
      AssertNotNull(reqs, 'reqs should not be nil');
      AssertEquals(2, reqs.Count, 'reqs.Count');

      json := FSerializer.Serialize(reqs);
      AssertJsonMatch(expected, json, 'Serialized batch JSON mismatch');
    finally
      reqs.Free;
    end;
  finally
    batch.Free;
  end;
end;

procedure TSolanaRpcClientBatchTests.TestDeserializeBatchResponse;
var
  responseData: string;
  res: TJsonRpcBatchResponse;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Batch', 'SampleBatchResponse.json'])
  );

  res := nil;
  try
    res := FSerializer.Deserialize<TJsonRpcBatchResponse>(responseData);
    AssertNotNull(res, 'Batch response should not be nil');
    AssertEquals(5, res.Count, 'Batch response item count');
  finally
    res.Free;
  end;
end;

procedure TSolanaRpcClientBatchTests.TestDeserializeBatchTokenMintInfoResponse;
var
  responseData: string;
  res: TJsonRpcBatchResponse;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Batch', 'SampleBatchTokenMintInfoResponse.json'])
  );

  res := nil;
  try
    res := FSerializer.Deserialize<TJsonRpcBatchResponse>(responseData);
    AssertNotNull(res);
    AssertEquals(2, res.Count);
  finally
    res.Free;
  end;
end;

procedure TSolanaRpcClientBatchTests.TestTransactionError_1;
var
  exampleFail, json: string;
  obj: TTransactionError;
begin
  exampleFail := '{''InstructionError'':[0,''InvalidAccountData'']}';
  exampleFail := StringReplace(exampleFail, '''', '"', [rfReplaceAll]);

  obj := FSerializer.Deserialize<TTransactionError>(exampleFail);
  try
    AssertNotNull(obj, 'Deserialized object should not be nil');

    json := FSerializer.Serialize(obj);
    AssertTrue(json <> '', 'Serialized JSON should not be empty');
    AssertJsonMatch(exampleFail, json, 'Round-trip JSON mismatch');
  finally
    obj.Free;
  end;
end;

procedure TSolanaRpcClientBatchTests.TestAutoExecuteMode;
var
  expectedRequests, expectedResponses: string;
  foundLamports: UInt64;
  foundBalance: Double;
  sigCallbackCount: Integer;
  baseAddress: string;
  mockHandler: TMyMockHttpMessageHandler;
  mockHttpClient: IHttpApiClient;
  mockRpcClient: IRpcClient;
  batch: TSolanaRpcBatchWithCallbacks;
  LTokenAccountData: TTokenAccountData;
begin
  expectedRequests := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Batch', 'SampleBatchRequest.json'])
  );
  expectedResponses := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Batch', 'SampleBatchResponse.json'])
  );

  foundLamports := 0;
  foundBalance := 0.0;
  sigCallbackCount := 0;

  baseAddress := TestnetUrl;
  mockHandler := TMyMockHttpMessageHandler.Create;
  try
    mockHandler.Add(expectedRequests, expectedResponses, 200);
    mockHttpClient := TQueuedMockRpcHttpClient.Create(mockHandler, baseAddress);
    mockRpcClient := TClientFactory.GetClient(TCluster.TestNet, mockHttpClient, nil);

    batch := TSolanaRpcBatchWithCallbacks.Create(mockRpcClient);
    try
      batch.AutoExecute(TBatchAutoExecuteMode.ExecuteWithFatalFailure, 10);

      batch.GetBalance(
        '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', TCommitment.Finalized,
        procedure (x: TResponseValue<UInt64>; ex: Exception)
        begin
          foundLamports := x.Value;
        end
      );

      batch.GetTokenAccountsByOwner(
        '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', '', TokenProgramProgramId, TCommitment.Finalized,
        procedure (x: TResponseValue<TObjectList<TTokenAccount>>; ex: Exception)
        begin
          LTokenAccountData := x.Value[0].Account.Data.AsType<TTokenAccountData>;
          foundBalance := LTokenAccountData.Parsed.Info.TokenAmount.AmountDouble;
        end
      );

      batch.GetSignaturesForAddress(
        '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', 200, '', '', TCommitment.Finalized,
        procedure (x: TObjectList<TSignatureStatusInfo>; ex: Exception)
        begin
          Inc(sigCallbackCount, x.Count);
        end
      );
      batch.GetSignaturesForAddress(
        '88ocFjrLgHEMQRMwozC7NnDBQUsq2UoQaqREFZoDEex', 200, '', '', TCommitment.Finalized,
        procedure (x: TObjectList<TSignatureStatusInfo>; ex: Exception)
        begin
          Inc(sigCallbackCount, x.Count);
        end
      );
      batch.GetSignaturesForAddress(
        '4NSREK36nAr32vooa3L9z8tu6JWj5rY3k4KnsqTgynvm', 200, '', '', TCommitment.Finalized,
        procedure (x: TObjectList<TSignatureStatusInfo>; ex: Exception)
        begin
          Inc(sigCallbackCount, x.Count);
        end
      );

      // run through any remaining requests in batch
      batch.Flush;

      // after flush: queue should be empty; second flush non-fatal
      AssertEquals(0, batch.Composer.Count);
      batch.Flush;

      AssertEquals(237543960, foundLamports, 'lamports');
      AssertEquals(12.5, foundBalance, 0.0, 'balance');
      AssertEquals(3, sigCallbackCount, 'sig count');
    finally
      batch.Free;
    end;
  finally
    mockHandler.Free;
  end;
end;

procedure TSolanaRpcClientBatchTests.TestBatchFailed;
var
  expectedRequests, expectedResponses: string;
  exceptionsEncountered: Integer;
  baseAddress: string;
  mockHandler: TMyMockHttpMessageHandler;
  mockHttpClient: IHttpApiClient;
  mockRpcClient: IRpcClient;
  mockResultObj, exceptionResultObj: IRequestResult<TJsonRpcBatchResponse>;
  batch: TSolanaRpcBatchWithCallbacks;
  catchForAssert: EBatchRequestException;
begin
  expectedRequests := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Batch', 'SampleBatchRequest.json'])
  );
  expectedResponses := 'BAD REQUEST';
  exceptionsEncountered := 0;
  catchForAssert := nil;

  baseAddress := TestnetUrl;
  mockHandler := TMyMockHttpMessageHandler.Create;
  try
    // Mock HTTP 400
    mockHandler.Add(expectedRequests, expectedResponses, 400);
    mockHttpClient := TQueuedMockRpcHttpClient.Create(mockHandler, baseAddress);
    mockRpcClient := TClientFactory.GetClient(TCluster.TestNet, mockHttpClient, nil);

    batch := TSolanaRpcBatchWithCallbacks.Create(mockRpcClient);
    try
      // queue 5 requests; callbacks count exceptions / capture the batch exception
      batch.GetBalance(
        '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', TCommitment.Finalized,
        procedure (x: TResponseValue<UInt64>; ex: Exception)
        begin
          if ex <> nil then Inc(exceptionsEncountered);
        end
      );
      batch.GetTokenAccountsByOwner(
        '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', '', TokenProgramProgramId, TCommitment.Finalized,
        procedure (x: TResponseValue<TObjectList<TTokenAccount>>; ex: Exception)
        begin
          if ex <> nil then Inc(exceptionsEncountered);
        end
      );
      batch.GetSignaturesForAddress(
        '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', 200, '', '', TCommitment.Finalized,
        procedure (x: TObjectList<TSignatureStatusInfo>; ex: Exception)
        begin
          if ex <> nil then Inc(exceptionsEncountered);
        end
      );
      batch.GetSignaturesForAddress(
        '88ocFjrLgHEMQRMwozC7NnDBQUsq2UoQaqREFZoDEex', 200, '', '', TCommitment.Finalized,
        procedure (x: TObjectList<TSignatureStatusInfo>; ex: Exception)
        begin
          if ex <> nil then Inc(exceptionsEncountered);
        end
      );
      batch.GetSignaturesForAddress(
        '4NSREK36nAr32vooa3L9z8tu6JWj5rY3k4KnsqTgynvm', 200, '', '', TCommitment.Finalized,
        procedure (x: TObjectList<TSignatureStatusInfo>; ex: Exception)
        begin
          if ex is EBatchRequestException then
            catchForAssert := EBatchRequestException(ex);
          exceptionResultObj := catchForAssert.RpcResult;
          if ex <> nil then Inc(exceptionsEncountered);
        end
      );

      // before executing: 5 requests queued
      AssertEquals(5, batch.Composer.Count, 'Composer.Count');

      // fabricate failed RequestResult for composer failure path
      mockResultObj := CreateMockRequestResult<TJsonRpcBatchResponse>(
        expectedRequests, expectedResponses, 400
      );

      AssertNotNull(mockResultObj, 'resp');
      AssertNull(mockResultObj.Result, 'resp.Result');
      AssertEquals(expectedResponses, mockResultObj.RawRpcResponse);

      // process failure and invoke callbacks
      batch.Composer.ProcessBatchFailure(mockResultObj);

      // now all callbacks should have been called with exceptions
      AssertEquals(5, exceptionsEncountered, 'All callbacks should receive exceptions');
      AssertNotNull(catchForAssert, 'Expected EBatchRequestException to be caught');
      AssertNotNull(exceptionResultObj, 'Exception should carry RpcResult');
      AssertEquals(expectedResponses, exceptionResultObj.RawRpcResponse, 'RawRpcResponse');
    finally
      batch.Free;
    end;
  finally
    mockHandler.Free;
  end;
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientBatchTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientBatchTests.Suite);
{$ENDIF}

end.

