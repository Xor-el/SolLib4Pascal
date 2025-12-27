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
  SlpSolanaRpcClient,
  SlpDataEncoders,
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
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<UInt64>;
begin
  responseData := LoadTestData('Transaction/GetTransactionCountResponse.json');
  requestData  := LoadTestData('Transaction/GetTransactionCountRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.GetTransactionCount;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(23632393337, result.Result);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTransactionsTests.TestGetTransactionCountProcessed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<UInt64>;
begin
  responseData := LoadTestData('Transaction/GetTransactionCountResponse.json');
  requestData  := LoadTestData('Transaction/GetTransactionCountProcessedRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.GetTransactionCount(TCommitment.Processed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.WasSuccessful);
  AssertEquals(23632393337, result.Result);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTransactionsTests.TestSendTransaction;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<string>;
  txData: string;
begin
  responseData := LoadTestData('Transaction/SendTransactionResponse.json');
  requestData  := LoadTestData('Transaction/SendTransactionRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  txData :=
    'ASIhFkj3HRTDLiPxrxudL7eXCQ3DKrBB6Go/pn0sHWYIYgIHWYu2jZjbDXQseCEu73Li53BP7AEt8lCwKz' +
    'X5awcBAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7J7rHLZwOnCKOnqrRmjOO1w2JcV0XhP'  +
    'LlWiw5thiFgQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KY' +
    'GeIhJMvTu9qCKNNRNmSFNMnUzw5+FDszWV6YvuvspBr0qlIoAdeg67wICAgABDAIAAACAlpgAAAAAAAMBA' +
    'BVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.SendTransaction(txData, TNullable<UInt32>.None, TNullable<UInt64>.None);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.WasSuccessful);
  AssertEquals('gaSFQXFqbYQypZdMFZy4Fe7uB2VFDEo4sGDypyrVxFgzZqc5MqWnRWTT9hXamcrFRcsiiH15vWii5ACSsyNScbp', result.Result);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTransactionsTests.TestSendTransactionBytes;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<string>;
  txData: string;
  bytes: TBytes;
begin
  responseData := LoadTestData('Transaction/SendTransactionResponse.json');
  requestData  := LoadTestData('Transaction/SendTransactionWithParamsRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  txData :=
    'ASIhFkj3HRTDLiPxrxudL7eXCQ3DKrBB6Go/pn0sHWYIYgIHWYu2jZjbDXQseCEu73Li53BP7AEt8lCwKz' +
    'X5awcBAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7J7rHLZwOnCKOnqrRmjOO1w2JcV0XhP'  +
    'LlWiw5thiFgQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KY' +
    'GeIhJMvTu9qCKNNRNmSFNMnUzw5+FDszWV6YvuvspBr0qlIoAdeg67wICAgABDAIAAACAlpgAAAAAAAMBA' +
    'BVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  bytes := TEncoders.Base64.DecodeData(txData);

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.SendTransaction(bytes, TNullable<UInt32>.None, TNullable<UInt64>.None, True, TBinaryEncoding.Base64, TCommitment.Confirmed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.WasSuccessful);
  AssertEquals('gaSFQXFqbYQypZdMFZy4Fe7uB2VFDEo4sGDypyrVxFgzZqc5MqWnRWTT9hXamcrFRcsiiH15vWii5ACSsyNScbp', result.Result);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTransactionsTests.TestSendTransactionExtraParams;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<string>;
  txData: string;
begin
  responseData := LoadTestData('Transaction/SendTransactionExtraParamsResponse.json');
  requestData  := LoadTestData('Transaction/SendTransactionExtraParamsRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  txData :=
    'ASIhFkj3HRTDLiPxrxudL7eXCQ3DKrBB6Go/pn0sHWYIYgIHWYu2jZjbDXQseCEu73Li53BP7AEt8lCwKz' +
    'X5awcBAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7J7rHLZwOnCKOnqrRmjOO1w2JcV0XhP' +
    'LlWiw5thiFgQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KY' +
    'GeIhJMvTu9qCKNNRNmSFNMnUzw5+FDszWV6YvuvspBr0qlIoAdeg67wICAgABDAIAAACAlpgAAAAAAAMBA' +
    'BVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.SendTransaction(
    txData,
    5,             // maxRetries
    259525972,     // minContextSlot
    False,         // skipPreflight
    TBinaryEncoding.Base64, // binary encoding
    TCommitment.Confirmed  // preFlightCommitment
  );

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> '', 'Result should not be empty');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(
    'gaSFQXFqbYQypZdMFZy4Fe7uB2VFDEo4sGDypyrVxFgzZqc5MqWnRWTT9hXamcrFRcsiiH15vWii5ACSsyNScbp',
    result.Result
  );

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTransactionsTests.TestSimulateTransaction;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TSimulationLogs>>;
  txData: string;
begin
  responseData := LoadTestData('Transaction/SimulateTransactionResponse.json');
  requestData  := LoadTestData('Transaction/SimulateTransactionRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  txData :=
    'ASIhFkj3HRTDLiPxrxudL7eXCQ3DKrBB6Go/pn0sHWYIYgIHWYu2jZjbDXQseCEu73Li53BP7AEt8lCwKz' +
    'X5awcBAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7J7rHLZwOnCKOnqrRmjOO1w2JcV0XhP'  +
    'LlWiw5thiFgQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KY' +
    'GeIhJMvTu9qCKNNRNmSFNMnUzw5+FDszWV6YvuvspBr0qlIoAdeg67wICAgABDAIAAACAlpgAAAAAAAMBA' +
    'BVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.SimulateTransaction(txData);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result, 'Result should not be nil');
  AssertNotNull(result.Result.Value, 'Result.Value should not be nil');
  AssertEquals(79206888, result.Result.Context.Slot);
  AssertNull(result.Result.Value.Error, 'Error should be nil');
  AssertEquals(5, Length(result.Result.Value.Logs));

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTransactionsTests.TestSimulateTransactionWithTransactionErrorObject;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TSimulationLogs>>;
  txData: string;
begin
  responseData := LoadTestData('Transaction/SimulateTransactionResponse2.json');
  requestData  := LoadTestData('Transaction/SimulateTransactionRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  txData :=
    'ASIhFkj3HRTDLiPxrxudL7eXCQ3DKrBB6Go/pn0sHWYIYgIHWYu2jZjbDXQseCEu73Li53BP7AEt8lCwKz' +
    'X5awcBAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7J7rHLZwOnCKOnqrRmjOO1w2JcV0XhP'  +
    'LlWiw5thiFgQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KY' +
    'GeIhJMvTu9qCKNNRNmSFNMnUzw5+FDszWV6YvuvspBr0qlIoAdeg67wICAgABDAIAAACAlpgAAAAAAAMBA' +
    'BVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.SimulateTransaction(txData);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertNotNull(result.Result.Value);
  AssertEquals(461971, result.Result.Context.Slot);
  AssertNotNull(result.Result.Value.Error, 'Error should not be nil');
  AssertEquals(Ord(TTransactionErrorType.InsufficientFundsForRent), Ord(result.Result.Value.Error.&Type));
  AssertEquals(2, Length(result.Result.Value.Logs));

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTransactionsTests.TestSimulateTransactionExtraParams;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TSimulationLogs>>;
  txData: string;
  acctList: TList<string>;
begin
  responseData := LoadTestData('Transaction/SimulateTransactionResponse.json');
  requestData  := LoadTestData('Transaction/SimulateTransactionExtraParamsRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  txData :=
    'ASIhFkj3HRTDLiPxrxudL7eXCQ3DKrBB6Go/pn0sHWYIYgIHWYu2jZjbDXQseCEu73Li53BP7AEt8lCwKz' +
    'X5awcBAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7J7rHLZwOnCKOnqrRmjOO1w2JcV0XhP'  +
    'LlWiw5thiFgQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KY' +
    'GeIhJMvTu9qCKNNRNmSFNMnUzw5+FDszWV6YvuvspBr0qlIoAdeg67wICAgABDAIAAACAlpgAAAAAAAMBA' +
    'BVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  acctList := TList<string>.Create;
  try
    acctList.Add('6bhhceZToGG9RsTe1nfNFXEMjavhj6CV55EsvearAt2z');

    rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

    result := rpcClient.SimulateTransaction(txData, True, False, acctList.ToArray, TBinaryEncoding.Base64, TCommitment.Confirmed);

    AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
    AssertNotNull(result.Result);
    AssertNotNull(result.Result.Value);
    AssertEquals(1, result.Result.Value.Accounts.Count);
    AssertEquals(79206888, result.Result.Context.Slot);
    AssertNull(result.Result.Value.Error, 'Error should be nil');
    AssertEquals(5, Length(result.Result.Value.Logs));

    FinishTest(mockRpcHttpClient, TestnetUrl);
  finally
    acctList.Free;
  end;
end;

procedure TSolanaRpcClientTransactionsTests.TestSimulateTransactionBytesExtraParams;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TSimulationLogs>>;
  txData: string;
  bytes: TBytes;
  acctList: TList<string>;
begin
  responseData := LoadTestData('Transaction/SimulateTransactionResponse.json');
  requestData  := LoadTestData('Transaction/SimulateTransactionExtraParamsRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  txData :=
    'ASIhFkj3HRTDLiPxrxudL7eXCQ3DKrBB6Go/pn0sHWYIYgIHWYu2jZjbDXQseCEu73Li53BP7AEt8lCwKz' +
    'X5awcBAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7J7rHLZwOnCKOnqrRmjOO1w2JcV0XhP'  +
    'LlWiw5thiFgQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KY' +
    'GeIhJMvTu9qCKNNRNmSFNMnUzw5+FDszWV6YvuvspBr0qlIoAdeg67wICAgABDAIAAACAlpgAAAAAAAMBA' +
    'BVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  bytes := TEncoders.Base64.DecodeData(txData);
  acctList := TList<string>.Create;
  try
    acctList.Add('6bhhceZToGG9RsTe1nfNFXEMjavhj6CV55EsvearAt2z');

    rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

    result := rpcClient.SimulateTransaction(bytes, True, False, acctList.ToArray, TBinaryEncoding.Base64, TCommitment.Confirmed);

    AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
    AssertNotNull(result.Result);
    AssertNotNull(result.Result.Value);
    AssertEquals(1, result.Result.Value.Accounts.Count);
    AssertEquals(79206888, result.Result.Context.Slot);
    AssertTrue(result.Result.Value.Error = nil);
    AssertEquals(5, Length(result.Result.Value.Logs));

    FinishTest(mockRpcHttpClient, TestnetUrl);
  finally
    acctList.Free;
  end;
end;

procedure TSolanaRpcClientTransactionsTests.TestSimulateTransactionIncompatibleParams;
var
  rpcClient: IRpcClient;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
begin
  mockRpcHttpClient := SetupTest('', 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  AssertException(
    procedure
    begin
      rpcClient.SimulateTransaction(
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
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TSimulationLogs>>;
  txData: string;
begin
  responseData := LoadTestData('Transaction/SimulateTransactionInsufficientLamportsResponse.json');
  requestData  := LoadTestData('Transaction/SimulateTransactionInsufficientLamportsRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  txData :=
    'ARymmnVB6PB0x//jV2vsTFFdeOkzD0FFoQq6P+wzGKlMD+XLb/hWnOebNaYlg/' +
    '+j6jdm9Fe2Sba/ACnvcv9KIA4BAAIEUy4zulRg8z2yKITZaNwcnq6G6aH8D0ITae862qbJ' +
    '+3eE3M6r5DRwldquwlqOuXDDOWZagXmbHnAU3w5Dg44kogAAAAAAAAAAAAAAAAAAAAAAAA' +
    'AAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KYGeIhJMvTu9qBann0itTd6uxx69h' +
    'ION5Js4E4drRP8CWwoLTdorAFUqAICAgABDAIAAACAlpgAAAAAAAMBABVIZWxsbyBmcm9tIFNvbC5OZXQgOik=';

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.SimulateTransaction(txData);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertNotNull(result.Result.Value);
  AssertEquals(79203980, result.Result.Context.Slot);
  AssertEquals(3, Length(result.Result.Value.Logs));
  AssertNotNull(result.Result.Value.Error, 'Error should not be nil');
  AssertEquals(Ord(TTransactionErrorType.InstructionError), Ord(result.Result.Value.Error.&Type));
  AssertNotNull(result.Result.Value.Error.InstructionError);
  AssertEquals(Ord(TInstructionErrorType.Custom), Ord(result.Result.Value.Error.InstructionError.&Type));
  AssertEquals(1, result.Result.Value.Error.InstructionError.CustomError.Value);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientTransactionsTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientTransactionsTests.Suite);
{$ENDIF}

end.
