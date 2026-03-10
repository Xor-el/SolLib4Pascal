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
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
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
    function CreateMockRequestResult<T>(
      const AReq, AResp: string;
      const AStatusCode: Integer
    ): IRequestResult<T>;

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
  const AReq, AResp: string;
  const AStatusCode: Integer
): IRequestResult<T>;
var
  LRes: TRequestResult<T>;
begin
  LRes := TRequestResult<T>.Create;
  LRes.HttpStatusCode := AStatusCode;
  LRes.RawRpcRequest := AReq;
  LRes.RawRpcResponse := AResp;

  if AStatusCode = 200 then
    LRes.Result := TTestUtils.Deserialize<T>(AResp);

  Result := LRes;
end;

procedure TSolanaRpcClientBatchTests.TestCreateAndSerializeBatchTokenMintInfoRequest;
var
  LExpected, LJson: string;
  LUnusedRpcClient: IRpcClient;
  LUnusedMockRpcHttpClient: IHttpApiClient;
  LBatch: TSolanaRpcBatchWithCallbacks;
  LReqs: TJsonRpcBatchRequest;
begin
  LExpected := LoadTestData('Batch/SampleBatchTokenMintInfoRequest.json');

  LUnusedMockRpcHttpClient := SetupTest('', 200);
  // compose a new batch of requests
  LUnusedRpcClient := TClientFactory.GetClient(TCluster.TestNet, LUnusedMockRpcHttpClient);

  LBatch := TSolanaRpcBatchWithCallbacks.Create(LUnusedRpcClient);
  try
    LBatch.GetTokenMintInfo('7yC2ABeaKRfvQsbZ5rA7cKTKF6YcyCYWV65jYrWrnhRN');
    LBatch.GetTokenMintInfo('GPytBb4s75MZxxviHJzpbHHgdWTcajmMDBd8VsBVAFS5');

    AssertEquals(2, LBatch.Composer.Count, 'Composer.Count');

    LReqs := nil;
    try
      LReqs := LBatch.Composer.CreateJsonRequests;
      AssertNotNull(LReqs, 'reqs should not be nil');
      AssertEquals(2, LReqs.Count, 'reqs.Count');

      LJson := TTestUtils.Serialize(LReqs);
      AssertJsonMatch(LExpected, LJson, 'Serialized batch JSON mismatch');
    finally
      LReqs.Free;
    end;
  finally
    LBatch.Free;
  end;
end;

procedure TSolanaRpcClientBatchTests.TestDeserializeBatchResponse;
var
  LResponseData: string;
  LRes: TJsonRpcBatchResponse;
begin
  LResponseData := LoadTestData('Batch/SampleBatchResponse.json');

  LRes := nil;
  try
    LRes := TTestUtils.Deserialize<TJsonRpcBatchResponse>(LResponseData);
    AssertNotNull(LRes, 'Batch response should not be nil');
    AssertEquals(5, LRes.Count, 'Batch response item count');
  finally
    LRes.Free;
  end;
end;

procedure TSolanaRpcClientBatchTests.TestDeserializeBatchTokenMintInfoResponse;
var
  LResponseData: string;
  LRes: TJsonRpcBatchResponse;
begin
  LResponseData := LoadTestData('Batch/SampleBatchTokenMintInfoResponse.json');

  LRes := nil;
  try
    LRes := TTestUtils.Deserialize<TJsonRpcBatchResponse>(LResponseData);
    AssertNotNull(LRes);
    AssertEquals(2, LRes.Count);
  finally
    LRes.Free;
  end;
end;

procedure TSolanaRpcClientBatchTests.TestTransactionError_1;
var
  LExampleFail, LJson: string;
  LObj: TTransactionError;
begin
  LExampleFail := '{''InstructionError'':[0,''InvalidAccountData'']}';
  LExampleFail := StringReplace(LExampleFail, '''', '"', [rfReplaceAll]);

  LObj := TTestUtils.Deserialize<TTransactionError>(LExampleFail);
  try
    AssertNotNull(LObj, 'Deserialized object should not be nil');

    LJson := TTestUtils.Serialize(LObj);
    AssertTrue(LJson <> '', 'Serialized JSON should not be empty');
    AssertJsonMatch(LExampleFail, LJson, 'Round-trip JSON mismatch');
  finally
    LObj.Free;
  end;
end;

procedure TSolanaRpcClientBatchTests.TestAutoExecuteMode;
var
  LExpectedRequests, LExpectedResponses: string;
  LFoundLamports: UInt64;
  LFoundBalance: Double;
  LSigCallbackCount: Integer;
  LBaseAddress: string;
  LMockHandler: TMyMockHttpMessageHandler;
  LMockHttpClient: IHttpApiClient;
  LMockRpcClient: IRpcClient;
  LBatch: TSolanaRpcBatchWithCallbacks;
  LTokenAccountData: TTokenAccountData;
begin
  LExpectedRequests := LoadTestData('Batch/SampleBatchRequest.json');
  LExpectedResponses := LoadTestData('Batch/SampleBatchResponse.json');

  LFoundLamports := 0;
  LFoundBalance := 0.0;
  LSigCallbackCount := 0;

  LBaseAddress := TestnetUrl;
  LMockHandler := TMyMockHttpMessageHandler.Create;
  try
    LMockHandler.Add(LExpectedRequests, LExpectedResponses, 200);
    LMockHttpClient := TQueuedMockRpcHttpClient.Create(LMockHandler, LBaseAddress);
    LMockRpcClient := TClientFactory.GetClient(TCluster.TestNet, LMockHttpClient, nil);

    LBatch := TSolanaRpcBatchWithCallbacks.Create(LMockRpcClient);
    try
      LBatch.AutoExecute(TBatchAutoExecuteMode.ExecuteWithFatalFailure, 10);

      LBatch.GetBalance(
        '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', TCommitment.Finalized,
        procedure (AResponse: TResponseValue<UInt64>; AException: Exception)
        begin
          LFoundLamports := AResponse.Value;
        end
      );

      LBatch.GetTokenAccountsByOwner(
        '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', '', TokenProgramProgramId, TBinaryEncoding.JsonParsed, TCommitment.Finalized,
        procedure (AResponse: TResponseValue<TObjectList<TTokenAccount>>; AException: Exception)
        begin
          LTokenAccountData := AResponse.Value[0].Account.Data.AsType<TTokenAccountData>;
          LFoundBalance := LTokenAccountData.Parsed.Info.TokenAmount.AmountDouble;
        end
      );

      LBatch.GetSignaturesForAddress(
        '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', 200, '', '', TCommitment.Finalized,
        procedure (AResponse: TObjectList<TSignatureStatusInfo>; AException: Exception)
        begin
          Inc(LSigCallbackCount, AResponse.Count);
        end
      );
      LBatch.GetSignaturesForAddress(
        '88ocFjrLgHEMQRMwozC7NnDBQUsq2UoQaqREFZoDEex', 200, '', '', TCommitment.Finalized,
        procedure (AResponse: TObjectList<TSignatureStatusInfo>; AException: Exception)
        begin
          Inc(LSigCallbackCount, AResponse.Count);
        end
      );
      LBatch.GetSignaturesForAddress(
        '4NSREK36nAr32vooa3L9z8tu6JWj5rY3k4KnsqTgynvm', 200, '', '', TCommitment.Finalized,
        procedure (AResponse: TObjectList<TSignatureStatusInfo>; AException: Exception)
        begin
          Inc(LSigCallbackCount, AResponse.Count);
        end
      );

      // run through any remaining requests in batch
      LBatch.Flush;

      // after flush: queue should be empty; second flush non-fatal
      AssertEquals(0, LBatch.Composer.Count);
      LBatch.Flush;

      AssertEquals(237543960, LFoundLamports, 'lamports');
      AssertEquals(12.5, LFoundBalance, 0.0, 'balance');
      AssertEquals(3, LSigCallbackCount, 'sig count');
    finally
      LBatch.Free;
    end;
  finally
    LMockHandler.Free;
  end;
end;

procedure TSolanaRpcClientBatchTests.TestBatchFailed;
var
  LExpectedRequests, LExpectedResponses: string;
  LExceptionsEncountered: Integer;
  LBaseAddress: string;
  LMockHandler: TMyMockHttpMessageHandler;
  LMockHttpClient: IHttpApiClient;
  LMockRpcClient: IRpcClient;
  LMockResultObj, LExceptionResultObj: IRequestResult<TJsonRpcBatchResponse>;
  LBatch: TSolanaRpcBatchWithCallbacks;
  LCatchForAssert: EBatchRequestException;
begin
  LExpectedRequests := LoadTestData('Batch/SampleBatchRequest.json');
  LExpectedResponses := 'BAD REQUEST';
  LExceptionsEncountered := 0;
  LCatchForAssert := nil;

  LBaseAddress := TestnetUrl;
  LMockHandler := TMyMockHttpMessageHandler.Create;
  try
    // Mock HTTP 400
    LMockHandler.Add(LExpectedRequests, LExpectedResponses, 400);
    LMockHttpClient := TQueuedMockRpcHttpClient.Create(LMockHandler, LBaseAddress);
    LMockRpcClient := TClientFactory.GetClient(TCluster.TestNet, LMockHttpClient, nil);

    LBatch := TSolanaRpcBatchWithCallbacks.Create(LMockRpcClient);
    try
      // queue 5 requests; callbacks count exceptions / capture the batch exception
      LBatch.GetBalance(
        '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', TCommitment.Finalized,
        procedure (AResponse: TResponseValue<UInt64>; AException: Exception)
        begin
          if AException <> nil then Inc(LExceptionsEncountered);
        end
      );
      LBatch.GetTokenAccountsByOwner(
        '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', '', TokenProgramProgramId, TBinaryEncoding.JsonParsed, TCommitment.Finalized,
        procedure (AResponse: TResponseValue<TObjectList<TTokenAccount>>; AException: Exception)
        begin
          if AException <> nil then Inc(LExceptionsEncountered);
        end
      );
      LBatch.GetSignaturesForAddress(
        '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', 200, '', '', TCommitment.Finalized,
        procedure (AResponse: TObjectList<TSignatureStatusInfo>; AException: Exception)
        begin
          if AException <> nil then Inc(LExceptionsEncountered);
        end
      );
      LBatch.GetSignaturesForAddress(
        '88ocFjrLgHEMQRMwozC7NnDBQUsq2UoQaqREFZoDEex', 200, '', '', TCommitment.Finalized,
        procedure (AResponse: TObjectList<TSignatureStatusInfo>; AException: Exception)
        begin
          if AException <> nil then Inc(LExceptionsEncountered);
        end
      );
      LBatch.GetSignaturesForAddress(
        '4NSREK36nAr32vooa3L9z8tu6JWj5rY3k4KnsqTgynvm', 200, '', '', TCommitment.Finalized,
        procedure (AResponse: TObjectList<TSignatureStatusInfo>; AException: Exception)
        begin
          if AException is EBatchRequestException then
            LCatchForAssert := EBatchRequestException(AException);
          LExceptionResultObj := LCatchForAssert.RpcResult;
          if AException <> nil then Inc(LExceptionsEncountered);
        end
      );

      // before executing: 5 requests queued
      AssertEquals(5, LBatch.Composer.Count, 'Composer.Count');

      // fabricate failed RequestResult for composer failure path
      LMockResultObj := CreateMockRequestResult<TJsonRpcBatchResponse>(
        LExpectedRequests, LExpectedResponses, 400
      );

      AssertNotNull(LMockResultObj, 'resp');
      AssertNull(LMockResultObj.Result, 'resp.Result');
      AssertEquals(LExpectedResponses, LMockResultObj.RawRpcResponse);

      // process failure and invoke callbacks
      LBatch.Composer.ProcessBatchFailure(LMockResultObj);

      // now all callbacks should have been called with exceptions
      AssertEquals(5, LExceptionsEncountered, 'All callbacks should receive exceptions');
      AssertNotNull(LCatchForAssert, 'Expected EBatchRequestException to be caught');
      AssertNotNull(LExceptionResultObj, 'Exception should carry RpcResult');
      AssertEquals(LExpectedResponses, LExceptionResultObj.RawRpcResponse, 'RawRpcResponse');
    finally
      LBatch.Free;
    end;
  finally
    LMockHandler.Free;
  end;
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientBatchTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientBatchTests.Suite);
{$ENDIF}

end.

