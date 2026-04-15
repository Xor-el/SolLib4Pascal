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

unit SolanaRpcClientTransactionsTests;

interface

uses
  SysUtils,
  Generics.Collections,
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
  SlpSolanaRpcClient,
  SlpNullable,
  RpcClientMocks,
  SolLibRpcClientTestCase;

type
  TSolanaRpcClientTransactionsTests = class(TSolLibRpcClientTestCase)
  published
    procedure TestGetTransactionCount;
    procedure TestGetTransactionCountProcessed;

    procedure TestSendTransaction;
    procedure TestSendTransactionBytes;
    procedure TestSendTransactionExtraParams;

    procedure TestSimulateTransaction;
    procedure TestSimulateTransactionWithTransactionErrorObject;
    procedure TestSimulateTransactionExtraParams;
    procedure TestSimulateTransactionBytesExtraParams;
    procedure TestSimulateTransactionIncompatibleParams;
    procedure TestSimulateTransactionInsufficientLamports;
  end;

implementation

{ TSolanaRpcClientTransactionsTests }

procedure TSolanaRpcClientTransactionsTests.TestGetTransactionCount;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<UInt64>;
begin
  LResponseData := LoadTestData('Transaction/GetTransactionCountResponse.json');
  LRequestData := LoadTestData('Transaction/GetTransactionCountRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.GetTransactionCount;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(23632393337, LResult.Result);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTransactionsTests.TestGetTransactionCountProcessed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<UInt64>;
begin
  LResponseData := LoadTestData('Transaction/GetTransactionCountResponse.json');
  LRequestData := LoadTestData('Transaction/GetTransactionCountProcessedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.GetTransactionCount(TCommitment.Processed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.WasSuccessful);
  AssertEquals(23632393337, LResult.Result);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTransactionsTests.TestSendTransaction;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<string>;
  LTxData: string;
begin
  LResponseData := LoadTestData('Transaction/SendTransactionResponse.json');
  LRequestData := LoadTestData('Transaction/SendTransactionRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LTxData :=
    'ASIhFkj3HRTDLiPxrxudL7eXCQ3DKrBB6Go/pn0sHWYIYgIHWYu2jZjbDXQseCEu73Li53BP7AEt8lCwKz' +
    'X5awcBAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7J7rHLZwOnCKOnqrRmjOO1w2JcV0XhP'  +
    'LlWiw5thiFgQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KY' +
    'GeIhJMvTu9qCKNNRNmSFNMnUzw5+FDszWV6YvuvspBr0qlIoAdeg67wICAgABDAIAAACAlpgAAAAAAAMBA' +
    'BVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.SendTransaction(LTxData, TNullable<UInt32>.None, TNullable<UInt64>.None);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.WasSuccessful);
  AssertEquals('gaSFQXFqbYQypZdMFZy4Fe7uB2VFDEo4sGDypyrVxFgzZqc5MqWnRWTT9hXamcrFRcsiiH15vWii5ACSsyNScbp', LResult.Result);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTransactionsTests.TestSendTransactionBytes;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<string>;
  LTxData: string;
  LBytes: TBytes;
begin
  LResponseData := LoadTestData('Transaction/SendTransactionResponse.json');
  LRequestData := LoadTestData('Transaction/SendTransactionWithParamsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LTxData :=
    'ASIhFkj3HRTDLiPxrxudL7eXCQ3DKrBB6Go/pn0sHWYIYgIHWYu2jZjbDXQseCEu73Li53BP7AEt8lCwKz' +
    'X5awcBAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7J7rHLZwOnCKOnqrRmjOO1w2JcV0XhP'  +
    'LlWiw5thiFgQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KY' +
    'GeIhJMvTu9qCKNNRNmSFNMnUzw5+FDszWV6YvuvspBr0qlIoAdeg67wICAgABDAIAAACAlpgAAAAAAAMBA' +
    'BVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  LBytes := DecodeBase64(LTxData);

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.SendTransaction(LBytes, TNullable<UInt32>.None, TNullable<UInt64>.None, True, TBinaryEncoding.Base64, TCommitment.Confirmed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.WasSuccessful);
  AssertEquals('gaSFQXFqbYQypZdMFZy4Fe7uB2VFDEo4sGDypyrVxFgzZqc5MqWnRWTT9hXamcrFRcsiiH15vWii5ACSsyNScbp', LResult.Result);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTransactionsTests.TestSendTransactionExtraParams;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<string>;
  LTxData: string;
begin
  LResponseData := LoadTestData('Transaction/SendTransactionExtraParamsResponse.json');
  LRequestData := LoadTestData('Transaction/SendTransactionExtraParamsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LTxData :=
    'ASIhFkj3HRTDLiPxrxudL7eXCQ3DKrBB6Go/pn0sHWYIYgIHWYu2jZjbDXQseCEu73Li53BP7AEt8lCwKz' +
    'X5awcBAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7J7rHLZwOnCKOnqrRmjOO1w2JcV0XhP' +
    'LlWiw5thiFgQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KY' +
    'GeIhJMvTu9qCKNNRNmSFNMnUzw5+FDszWV6YvuvspBr0qlIoAdeg67wICAgABDAIAAACAlpgAAAAAAAMBA' +
    'BVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.SendTransaction(
    LTxData,
    5,             // maxRetries
    259525972,     // minContextSlot
    False,         // skipPreflight
    TBinaryEncoding.Base64, // binary encoding
    TCommitment.Confirmed  // preFlightCommitment
  );

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> '', 'Result should not be empty');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(
    'gaSFQXFqbYQypZdMFZy4Fe7uB2VFDEo4sGDypyrVxFgzZqc5MqWnRWTT9hXamcrFRcsiiH15vWii5ACSsyNScbp',
    LResult.Result
  );

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTransactionsTests.TestSimulateTransaction;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TSimulationLogs>>;
  LTxData: string;
begin
  LResponseData := LoadTestData('Transaction/SimulateTransactionResponse.json');
  LRequestData := LoadTestData('Transaction/SimulateTransactionRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LTxData :=
    'ASIhFkj3HRTDLiPxrxudL7eXCQ3DKrBB6Go/pn0sHWYIYgIHWYu2jZjbDXQseCEu73Li53BP7AEt8lCwKz' +
    'X5awcBAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7J7rHLZwOnCKOnqrRmjOO1w2JcV0XhP'  +
    'LlWiw5thiFgQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KY' +
    'GeIhJMvTu9qCKNNRNmSFNMnUzw5+FDszWV6YvuvspBr0qlIoAdeg67wICAgABDAIAAACAlpgAAAAAAAMBA' +
    'BVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.SimulateTransaction(LTxData);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result, 'Result should not be nil');
  AssertNotNull(LResult.Result.Value, 'Result.Value should not be nil');
  AssertEquals(79206888, LResult.Result.Context.Slot);
  AssertNull(LResult.Result.Value.Error, 'Error should be nil');
  AssertEquals(5, Length(LResult.Result.Value.Logs));

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTransactionsTests.TestSimulateTransactionWithTransactionErrorObject;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TSimulationLogs>>;
  LTxData: string;
begin
  LResponseData := LoadTestData('Transaction/SimulateTransactionResponse2.json');
  LRequestData := LoadTestData('Transaction/SimulateTransactionRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LTxData :=
    'ASIhFkj3HRTDLiPxrxudL7eXCQ3DKrBB6Go/pn0sHWYIYgIHWYu2jZjbDXQseCEu73Li53BP7AEt8lCwKz' +
    'X5awcBAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7J7rHLZwOnCKOnqrRmjOO1w2JcV0XhP'  +
    'LlWiw5thiFgQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KY' +
    'GeIhJMvTu9qCKNNRNmSFNMnUzw5+FDszWV6YvuvspBr0qlIoAdeg67wICAgABDAIAAACAlpgAAAAAAAMBA' +
    'BVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.SimulateTransaction(LTxData);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertNotNull(LResult.Result.Value);
  AssertEquals(461971, LResult.Result.Context.Slot);
  AssertNotNull(LResult.Result.Value.Error, 'Error should not be nil');
  AssertEquals(Ord(TTransactionErrorType.InsufficientFundsForRent), Ord(LResult.Result.Value.Error.&Type));
  AssertEquals(2, Length(LResult.Result.Value.Logs));

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTransactionsTests.TestSimulateTransactionExtraParams;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TSimulationLogs>>;
  LTxData: string;
  LAcctList: TList<string>;
begin
  LResponseData := LoadTestData('Transaction/SimulateTransactionResponse.json');
  LRequestData := LoadTestData('Transaction/SimulateTransactionExtraParamsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LTxData :=
    'ASIhFkj3HRTDLiPxrxudL7eXCQ3DKrBB6Go/pn0sHWYIYgIHWYu2jZjbDXQseCEu73Li53BP7AEt8lCwKz' +
    'X5awcBAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7J7rHLZwOnCKOnqrRmjOO1w2JcV0XhP'  +
    'LlWiw5thiFgQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KY' +
    'GeIhJMvTu9qCKNNRNmSFNMnUzw5+FDszWV6YvuvspBr0qlIoAdeg67wICAgABDAIAAACAlpgAAAAAAAMBA' +
    'BVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  LAcctList := TList<string>.Create;
  try
    LAcctList.Add('6bhhceZToGG9RsTe1nfNFXEMjavhj6CV55EsvearAt2z');

    LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

    LResult := LRpcClient.SimulateTransaction(LTxData, True, False, LAcctList.ToArray, TBinaryEncoding.Base64, TCommitment.Confirmed);

    AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
    AssertNotNull(LResult.Result);
    AssertNotNull(LResult.Result.Value);
    AssertEquals(1, LResult.Result.Value.Accounts.Count);
    AssertEquals(79206888, LResult.Result.Context.Slot);
    AssertNull(LResult.Result.Value.Error, 'Error should be nil');
    AssertEquals(5, Length(LResult.Result.Value.Logs));

    FinishTest(LMockRpcHttpClient, TestnetUrl);
  finally
    LAcctList.Free;
  end;
end;

procedure TSolanaRpcClientTransactionsTests.TestSimulateTransactionBytesExtraParams;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TSimulationLogs>>;
  LTxData: string;
  LBytes: TBytes;
  LAcctList: TList<string>;
begin
  LResponseData := LoadTestData('Transaction/SimulateTransactionResponse.json');
  LRequestData := LoadTestData('Transaction/SimulateTransactionExtraParamsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LTxData :=
    'ASIhFkj3HRTDLiPxrxudL7eXCQ3DKrBB6Go/pn0sHWYIYgIHWYu2jZjbDXQseCEu73Li53BP7AEt8lCwKz' +
    'X5awcBAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7J7rHLZwOnCKOnqrRmjOO1w2JcV0XhP'  +
    'LlWiw5thiFgQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KY' +
    'GeIhJMvTu9qCKNNRNmSFNMnUzw5+FDszWV6YvuvspBr0qlIoAdeg67wICAgABDAIAAACAlpgAAAAAAAMBA' +
    'BVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  LBytes := DecodeBase64(LTxData);
  LAcctList := TList<string>.Create;
  try
    LAcctList.Add('6bhhceZToGG9RsTe1nfNFXEMjavhj6CV55EsvearAt2z');

    LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

    LResult := LRpcClient.SimulateTransaction(LBytes, True, False, LAcctList.ToArray, TBinaryEncoding.Base64, TCommitment.Confirmed);

    AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
    AssertNotNull(LResult.Result);
    AssertNotNull(LResult.Result.Value);
    AssertEquals(1, LResult.Result.Value.Accounts.Count);
    AssertEquals(79206888, LResult.Result.Context.Slot);
    AssertTrue(LResult.Result.Value.Error = nil);
    AssertEquals(5, Length(LResult.Result.Value.Logs));

    FinishTest(LMockRpcHttpClient, TestnetUrl);
  finally
    LAcctList.Free;
  end;
end;

procedure TSolanaRpcClientTransactionsTests.TestSimulateTransactionIncompatibleParams;
var
  LRpcClient: IRpcClient;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
begin
  LMockRpcHttpClient := SetupTest('', 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  AssertException(
    procedure
    begin
      LRpcClient.SimulateTransaction(
        '',
        True,
        True
      );
    end,
    EArgumentException
  );
end;

procedure TSolanaRpcClientTransactionsTests.TestSimulateTransactionInsufficientLamports;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TSimulationLogs>>;
  LTxData: string;
begin
  LResponseData := LoadTestData('Transaction/SimulateTransactionInsufficientLamportsResponse.json');
  LRequestData := LoadTestData('Transaction/SimulateTransactionInsufficientLamportsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LTxData :=
    'ARymmnVB6PB0x//jV2vsTFFdeOkzD0FFoQq6P+wzGKlMD+XLb/hWnOebNaYlg/' +
    '+j6jdm9Fe2Sba/ACnvcv9KIA4BAAIEUy4zulRg8z2yKITZaNwcnq6G6aH8D0ITae862qbJ' +
    '+3eE3M6r5DRwldquwlqOuXDDOWZagXmbHnAU3w5Dg44kogAAAAAAAAAAAAAAAAAAAAAAAA' +
    'AAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KYGeIhJMvTu9qBann0itTd6uxx69h' +
    'ION5Js4E4drRP8CWwoLTdorAFUqAICAgABDAIAAACAlpgAAAAAAAMBABVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.SimulateTransaction(LTxData);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertNotNull(LResult.Result.Value);
  AssertEquals(79203980, LResult.Result.Context.Slot);
  AssertEquals(3, Length(LResult.Result.Value.Logs));
  AssertNotNull(LResult.Result.Value.Error, 'Error should not be nil');
  AssertEquals(Ord(TTransactionErrorType.InstructionError), Ord(LResult.Result.Value.Error.&Type));
  AssertNotNull(LResult.Result.Value.Error.InstructionError);
  AssertEquals(Ord(TInstructionErrorType.Custom), Ord(LResult.Result.Value.Error.InstructionError.&Type));
  AssertEquals(1, LResult.Result.Value.Error.InstructionError.CustomError.Value);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientTransactionsTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientTransactionsTests.Suite);
{$ENDIF}

end.
