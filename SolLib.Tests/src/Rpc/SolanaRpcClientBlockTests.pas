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

unit SolanaRpcClientBlockTests;

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
  SlpNullable,
  SlpSolanaRpcClient,
  RpcClientMocks,
  TestUtils,
  SolLibRpcClientTestCase;

type
  TSolanaRpcClientBlockTests = class(TSolLibRpcClientTestCase)
  published
    procedure TestGetBlock;
    procedure TestGetBlockInvalid;

    procedure TestGetBlockProductionNoArgs;
    procedure TestGetBlockProductionInvalidCommitment;
    procedure TestGetBlockProductionIdentity;
    procedure TestGetBlockProductionRangeStart;
    procedure TestGetBlockProductionIdentityRange;

    procedure TestGetTransaction;
    procedure TestGetTransaction2;
    procedure TestGetTransactionVersioned;
    procedure TestGetTransactionProcessed;

    procedure TestGetBlocks;
    procedure TestGetBlocksInvalidCommitment;
    procedure TestGetBlocksWithLimit;
    procedure TestGetBlocksWithLimitBadCommitment;

    procedure TestGetFirstAvailableBlock;
    procedure TestGetBlockHeight;
    procedure TestGetBlockHeightConfirmed;
    procedure TestGetBlockCommitment;
    procedure TestGetBlockTime;

    procedure TestGetLatestBlockHash;
    procedure TestIsBlockhashValid;
  end;

implementation

{ TSolanaRpcClientBlockTests }

procedure TSolanaRpcClientBlockTests.TestGetBlock;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  res : IRequestResult<TBlockInfo>;
  first: TTransactionMetaInfo;
  firstTransactionInfo: TTransactionInfo;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetBlock(79662905);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(res.Result <> nil, 'Result should not be nil');
  AssertEquals(2, res.Result.Transactions.Count);

  AssertEquals(66130135, res.Result.BlockHeight.Value);
  AssertEquals(1622632900, res.Result.BlockTime);
  AssertEquals(79662904, res.Result.ParentSlot);
  AssertEquals('5wLhsKAH9SCPbRZc4qWf3GBiod9CD8sCEZfMiU25qW8', res.Result.Blockhash);
  AssertEquals('CjJ97j84mUq3o67CEqzEkTifXpHLBCD8GvmfBYLz4Zdg', res.Result.PreviousBlockhash);

  AssertEquals(1, res.Result.Rewards.Count);
  AssertEquals(1785000, res.Result.Rewards[0].Lamports);
  AssertEquals(365762267923, res.Result.Rewards[0].PostBalance);
  AssertEquals('9zkU8suQBdhZVax2DSGNAnyEhEzfEELvA25CJhy5uwnW', res.Result.Rewards[0].Pubkey);
  AssertEquals(Ord(TRewardType.Fee), Ord(res.Result.Rewards[0].RewardType));

  first := res.Result.Transactions[0];
  AssertTrue(first.Meta.Error <> nil);
  AssertEquals(Ord(TTransactionErrorType.InstructionError), Ord(first.Meta.Error.&Type));
  AssertTrue(first.Meta.Error.InstructionError <> nil);
  AssertEquals(Ord(TInstructionErrorType.Custom), Ord(first.Meta.Error.InstructionError.&Type));
  AssertEquals(0, first.Meta.Error.InstructionError.CustomError.Value);

  AssertEquals(5000, first.Meta.Fee);
  AssertEquals(0, first.Meta.InnerInstructions.Count);
  AssertEquals(2, Length(first.Meta.LogMessages));
  AssertEquals(5, Length(first.Meta.PostBalances));
  AssertEquals(35132731759, first.Meta.PostBalances[0]);
  AssertEquals(5, Length(first.Meta.PreBalances));
  AssertEquals(35132736759, first.Meta.PreBalances[0]);
  AssertEquals(0, first.Meta.PostTokenBalances.Count);
  AssertEquals(0, first.Meta.PreTokenBalances.Count);

  firstTransactionInfo := first.Transaction.AsType<TTransactionInfo>;
  AssertEquals(1, Length(firstTransactionInfo.Signatures));
  AssertEquals(
    '2Hh35eZPP1wZLYQ1HHv8PqGoRo73XirJeKFpBVc19msi6qeJHk3yUKqS1viRtqkdb545CerTWeywPFXxjKEhDWTK',
    firstTransactionInfo.Signatures[0]);

  AssertEquals(5, Length(firstTransactionInfo.Message.AccountKeys));
  AssertEquals('DjuMPGThkGdyk2vDvDDYjTFSyxzTumdapnDNbvVZbYQE',
    firstTransactionInfo.Message.AccountKeys[0]);

  AssertEquals(0, firstTransactionInfo.Message.Header.NumReadonlySignedAccounts);
  AssertEquals(3, firstTransactionInfo.Message.Header.NumReadonlyUnsignedAccounts);
  AssertEquals(1, firstTransactionInfo.Message.Header.NumRequiredSignatures);

  AssertEquals(1, firstTransactionInfo.Message.Instructions.Count);
  AssertEquals(4, Length(firstTransactionInfo.Message.Instructions[0].Accounts));
  AssertEquals('2ZjTR1vUs2pHXyTLxtFDhN2tsm2HbaH36cAxzJcwaXf8y5jdTESsGNBLFaxGuWENxLa2ZL3cX9foNJcWbRq',
    firstTransactionInfo.Message.Instructions[0].Data);
  AssertEquals(4, firstTransactionInfo.Message.Instructions[0].ProgramIdIndex);

  AssertEquals('D8qh6AeX4KaTe6ZBpsZDdntTQUyPy7x6Xjp7NnEigCWH',
    firstTransactionInfo.Message.RecentBlockhash);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockInvalid;
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
      rpcClient.GetBlock(
        79662905,
        TTransactionDetailsFilterType.Full,
        False,
        0,
        TCommitment.Processed
      );
    end,
    EArgumentException
  );
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockProductionNoArgs;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<TResponseValue<TBlockProductionInfo>>;
  k   : string;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockProductionNoArgsResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockProductionNoArgsRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetBlockProduction('', TNullable<UInt64>.None, TNullable<UInt64>.None, TCommitment.Finalized);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertTrue(res.Result <> nil);
  AssertEquals(3, res.Result.Value.ByIdentity.Count);
  AssertEquals(79580256, res.Result.Value.Range.FirstSlot);
  AssertEquals(79712285, res.Result.Value.Range.LastSlot);

  k := '121cur1YFVPZSoKQGNyjNr9sZZRa3eX2bSuYjXHtKD6';
  AssertTrue(res.Result.Value.ByIdentity.ContainsKey(k));
  AssertEquals(60, res.Result.Value.ByIdentity[k][0]);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockProductionInvalidCommitment;
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
      rpcClient.GetBlockProduction(
        '',
        TNullable<UInt64>.None,
        1234556
      );
    end,
    EArgumentException
  );
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockProductionIdentity;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<TResponseValue<TBlockProductionInfo>>;
  k   : string;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockProductionIdentityResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockProductionIdentityRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetBlockProduction('Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu',
    TNullable<UInt64>.None, TNullable<UInt64>.None, TCommitment.Finalized);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertTrue(res.Result <> nil);
  AssertEquals(1, res.Result.Value.ByIdentity.Count);
  AssertEquals(79580256, res.Result.Value.Range.FirstSlot);
  AssertEquals(79712285, res.Result.Value.Range.LastSlot);

  k := 'Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu';
  AssertTrue(res.Result.Value.ByIdentity.ContainsKey(k));
  AssertEquals(96, res.Result.Value.ByIdentity[k][0]);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockProductionRangeStart;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<TResponseValue<TBlockProductionInfo>>;
  k   : string;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockProductionRangeStartResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockProductionRangeStartRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetBlockProduction('', 79714135, TNullable<UInt64>.None, TCommitment.Processed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertTrue(res.Result <> nil);
  AssertEquals(35, res.Result.Value.ByIdentity.Count);
  AssertEquals(79714135, res.Result.Value.Range.FirstSlot);
  AssertEquals(79714275, res.Result.Value.Range.LastSlot);

  k := '123vij84ecQEKUvQ7gYMKxKwKF6PbYSzCzzURYA4xULY';
  AssertTrue(res.Result.Value.ByIdentity.ContainsKey(k));
  AssertEquals(4, res.Result.Value.ByIdentity[k][0]);
  AssertEquals(3, res.Result.Value.ByIdentity[k][1]);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockProductionIdentityRange;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<TResponseValue<TBlockProductionInfo>>;
  k   : string;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockProductionIdentityRangeResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockProductionIdentityRangeRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetBlockProduction('Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu', 79000000, 79500000);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertTrue(res.Result <> nil);
  AssertEquals(1, res.Result.Value.ByIdentity.Count);
  AssertEquals(79000000, res.Result.Value.Range.FirstSlot);
  AssertEquals(79500000, res.Result.Value.Range.LastSlot);

  k := 'Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu';
  AssertTrue(res.Result.Value.ByIdentity.ContainsKey(k));
  AssertEquals(416, res.Result.Value.ByIdentity[k][0]);
  AssertEquals(341, res.Result.Value.ByIdentity[k][1]);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetTransaction;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<TTransactionMetaSlotInfo>;
  tmi : TTransactionMetaInfo;
  tmiTransactionInfo: TTransactionInfo;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Transaction', 'GetTransactionResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Transaction', 'GetTransactionRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetTransaction(
    '5as3w4KMpY23MP5T1nkPVksjXjN7hnjHKqiDxRMxUNcw5XsCGtStayZib1kQdyR2D9w8dR11Ha9Xk38KP3kbAwM1');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertTrue(res.Result <> nil);
  AssertEquals(Int64(79700345), res.Result.Slot);
  AssertEquals(1622655364, res.Result.BlockTime.Value);

  tmi := res.Result;
  AssertTrue(tmi.Meta.Error = nil);
  AssertEquals(5000, tmi.Meta.Fee);
  AssertEquals(0, tmi.Meta.InnerInstructions.Count);
  AssertEquals(2, Length(tmi.Meta.LogMessages));
  AssertEquals(5, Length(tmi.Meta.PostBalances));
  AssertEquals(395383573380, tmi.Meta.PostBalances[0]);
  AssertEquals(5, Length(tmi.Meta.PreBalances));
  AssertEquals(395383578380, tmi.Meta.PreBalances[0]);
  AssertEquals(0, tmi.Meta.PostTokenBalances.Count);
  AssertEquals(0, tmi.Meta.PreTokenBalances.Count);

  tmiTransactionInfo := tmi.Transaction.AsType<TTransactionInfo>;
  AssertEquals(1, Length(tmiTransactionInfo.Signatures));
  AssertEquals(
    '5as3w4KMpY23MP5T1nkPVksjXjN7hnjHKqiDxRMxUNcw5XsCGtStayZib1kQdyR2D9w8dR11Ha9Xk38KP3kbAwM1',
    tmiTransactionInfo.Signatures[0]);

  AssertEquals(5, Length(tmiTransactionInfo.Message.AccountKeys));
  AssertEquals(
    'EvVrzsxoj118sxxSTrcnc9u3fRdQfCc7d4gRzzX6TSqj',
    tmiTransactionInfo.Message.AccountKeys[0]);

  AssertEquals(0, tmiTransactionInfo.Message.Header.NumReadonlySignedAccounts);
  AssertEquals(3, tmiTransactionInfo.Message.Header.NumReadonlyUnsignedAccounts);
  AssertEquals(1, tmiTransactionInfo.Message.Header.NumRequiredSignatures);

  AssertEquals(1, tmiTransactionInfo.Message.Instructions.Count);
  AssertEquals(4, Length(tmiTransactionInfo.Message.Instructions[0].Accounts));
  AssertEquals('2kr3BYaDkghC7rvHsQYnBNoB4dhXrUmzgYMM4kbHSG7ALa3qsMPxfC9cJTFDKyJaC8VYSjrey9pvyRivtESUJrC3qzr89pvS2o6MQ'
    + 'hyRVxmh3raQStxFFYwZ6WyKFNoQXvcchBwy8uQGfhhUqzuLNREwRmZ5U2VgTjFWX8Vikqya6iyzvALQNZEvqz7ZoGEyRtJ6AzNyWbkUyEo63rZ5w3wnxmhr3Uood',
    tmiTransactionInfo.Message.Instructions[0].Data);

  AssertEquals(4, tmiTransactionInfo.Message.Instructions[0].ProgramIdIndex);
  AssertEquals('6XGYfEJ5CGGBA5E8E7Gw4ToyDLDNNAyUCb7CJj1rLk21', tmiTransactionInfo.Message.RecentBlockhash);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetTransaction2;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<TTransactionMetaSlotInfo>;
  first : TTransactionMetaInfo;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Transaction', 'GetTransactionResponse2.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Transaction', 'GetTransactionRequest2.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetTransaction(
    '3Q9mu4ePvtbtQzY1kpGmaViJKyBev6hgUppyXDF9hKgWHHnecwGLE2pSoFvNUF3h7acKyFwWd65bkwr9A1jN2CdT');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertTrue(res.Result <> nil);

  AssertEquals(132196637, res.Result.Slot);
  AssertEquals(1651763621, res.Result.BlockTime.Value);

  first := res.Result;

  AssertNotNull(first.Meta.Error);
  AssertEquals(Ord(TTransactionErrorType.InvalidRentPayingAccount), Ord(first.Meta.Error.&Type));

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetTransactionVersioned;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<TTransactionMetaSlotInfo>;
  tmi : TTransactionMetaInfo;
  tmiTransactionInfo: TTransactionInfo;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Transaction', 'GetTransactionVersionedResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Transaction', 'GetTransactionVersionedRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  // maxSupportedTransactionVersion = 0
  res := rpcClient.GetTransaction(
    '2KLm7JmcMgZgNNqmsrp3vX3G7U4wg4JQ4NUydeUWJRQA9nJPkCWsMJGr5V2eQSyKe8Jpztghv6w2kDerJX16MxSz',
    0);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertTrue(res.Result <> nil, 'Result should not be nil');

  AssertEquals(Int64(255401968), res.Result.Slot);
  AssertEquals(1710963316, res.Result.BlockTime.Value);

  tmi := res.Result;

  AssertTrue(tmi.Meta.Error = nil, 'Meta.Error should be nil');

  AssertEquals(1005001, tmi.Meta.Fee);
  AssertEquals(2, tmi.Meta.InnerInstructions.Count);
  AssertEquals(110, Length(tmi.Meta.LogMessages));
  AssertEquals(43, Length(tmi.Meta.PostBalances));
  AssertEquals(684571363, tmi.Meta.PostBalances[0]);
  AssertEquals(43, Length(tmi.Meta.PreBalances));
  AssertEquals(96756112, tmi.Meta.PreBalances[0]);
  AssertEquals(13, tmi.Meta.PostTokenBalances.Count);
  AssertEquals(13, tmi.Meta.PreTokenBalances.Count);

  tmiTransactionInfo := tmi.Transaction.AsType<TTransactionInfo>;

  AssertEquals(1, Length(tmiTransactionInfo.Signatures));
  AssertEquals(
    '2KLm7JmcMgZgNNqmsrp3vX3G7U4wg4JQ4NUydeUWJRQA9nJPkCWsMJGr5V2eQSyKe8Jpztghv6w2kDerJX16MxSz',
    tmiTransactionInfo.Signatures[0]);

  AssertEquals(15, Length(tmiTransactionInfo.Message.AccountKeys));
  AssertEquals(
    '5fVwGG2By5gLcpwH1RsqxYDyMzA5FfDRsRBPEvGDsSNu',
    tmiTransactionInfo.Message.AccountKeys[0]);

  AssertEquals(0, tmiTransactionInfo.Message.Header.NumReadonlySignedAccounts);
  AssertEquals(8, tmiTransactionInfo.Message.Header.NumReadonlyUnsignedAccounts);
  AssertEquals(1, tmiTransactionInfo.Message.Header.NumRequiredSignatures);

  AssertEquals(6, tmiTransactionInfo.Message.Instructions.Count);
  AssertEquals(6, Length(tmiTransactionInfo.Message.Instructions[2].Accounts));
  AssertEquals('3K7fezMZDETh', tmiTransactionInfo.Message.Instructions[1].Data);

  AssertEquals(7, tmiTransactionInfo.Message.Instructions[0].ProgramIdIndex);

  AssertEquals('AwqZBjWfsFBE1ozAHgp8TkxSz3C82MgtA2JuT43GgVti',
    tmiTransactionInfo.Message.RecentBlockhash);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetTransactionProcessed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<TTransactionMetaSlotInfo>;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Transaction', 'GetTransactionResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Transaction', 'GetTransactionProcessedRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetTransaction(
    '5as3w4KMpY23MP5T1nkPVksjXjN7hnjHKqiDxRMxUNcw5XsCGtStayZib1kQdyR2D9w8dR11Ha9Xk38KP3kbAwM1',
    0, 'json', TCommitment.Processed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertTrue(res.Result <> nil);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlocks;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<TList<UInt64>>;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlocksResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlocksRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetBlocks(79499950, 79500000, TCommitment.Finalized);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertTrue(res.Result <> nil);
  AssertEquals(39, res.Result.Count);
  AssertEquals(79499950, res.Result[0]);
  AssertEquals(79500000, res.Result[38]);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlocksInvalidCommitment;
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
      rpcClient.GetBlocks(
        79499950,
        79500000,
        TCommitment.Processed
      );
    end,
    EArgumentException
  );
end;

procedure TSolanaRpcClientBlockTests.TestGetBlocksWithLimit;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<TList<UInt64>>;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlocksWithLimitResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlocksWithLimitRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetBlocksWithLimit(79699950, 2);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertTrue(res.Result <> nil);
  AssertEquals(2, res.Result.Count);
  AssertEquals(79699950, res.Result[0]);
  AssertEquals(79699951, res.Result[1]);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlocksWithLimitBadCommitment;
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
      rpcClient.GetBlocksWithLimit(
        79699950,
        2,
        TCommitment.Processed
      );
    end,
    EArgumentException
  );
end;

procedure TSolanaRpcClientBlockTests.TestGetFirstAvailableBlock;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<UInt64>;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetFirstAvailableBlockResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetFirstAvailableBlockRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetFirstAvailableBlock;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertNotNull(res);
  AssertEquals(39368303, res.Result);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockHeight;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<UInt64>;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockHeightResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockHeightRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetBlockHeight;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertNotNull(res);
  AssertTrue(res.WasSuccessful);
  AssertEquals(1233, res.Result);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockHeightConfirmed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<UInt64>;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockHeightResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockHeightConfirmedRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetBlockHeight(TCommitment.Confirmed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertNotNull(res);
  AssertTrue(res.WasSuccessful);
  AssertEquals(1233, res.Result);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockCommitment;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<TBlockCommitment>;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockCommitmentResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockCommitmentRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetBlockCommitment(78561320);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertNotNull(res.Result);
  AssertTrue(res.WasSuccessful);
  AssertTrue(res.Result.Commitment = nil);
  AssertEquals(78380558524696194, res.Result.TotalStake);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockTime;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<UInt64>;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockTimeResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetBlockTimeRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetBlockTime(78561320);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertNotNull(res);
  AssertTrue(res.WasSuccessful);
  AssertEquals(1621971949, res.Result);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetLatestBlockHash;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<TResponseValue<TLatestBlockHash>>;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetLatestBlockhashResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'GetLatestBlockhashRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetLatestBlockhash(TCommitment.Finalized);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertNotNull(res.Result);
  AssertTrue(res.WasSuccessful);
  AssertEquals(127140942, res.Result.Context.Slot);
  AssertEquals('DDFfxGAsEVcqNbCLRgvDtzcc2ZxNnqJfQJfMTRhEEPwW', res.Result.Value.Blockhash);
  AssertEquals(115143990, res.Result.Value.LastValidBlockHeight);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestIsBlockhashValid;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient : IHttpApiClient;
  rpcClient : IRpcClient;
  res : IRequestResult<TResponseValue<Boolean>>;
begin
  responseData := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'IsBlockhashValidResponse.json']));
  requestData  := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Blocks', 'IsBlockhashValidRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient  := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.IsBlockhashValid('DDFfxGAsEVcqNbCLRgvDtzcc2ZxNnqJfQJfMTRhEEPwW');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson);
  AssertNotNull(res.Result);
  AssertTrue(res.WasSuccessful);
  AssertEquals(127140942, res.Result.Context.Slot);
  AssertTrue(res.Result.Value);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientBlockTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientBlockTests.Suite);
{$ENDIF}

end.
