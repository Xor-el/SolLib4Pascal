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
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TBlockInfo>;
  LFirst: TTransactionMetaInfo;
  LFirstTransactionInfo: TTransactionInfo;
begin
  LResponseData := LoadTestData('Blocks/GetBlockResponse.json');
  LRequestData := LoadTestData('Blocks/GetBlockRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetBlock(79662905);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LRes.Result <> nil, 'Result should not be nil');
  AssertEquals(2, LRes.Result.Transactions.Count);

  AssertEquals(66130135, LRes.Result.BlockHeight.Value);
  AssertEquals(1622632900, LRes.Result.BlockTime);
  AssertEquals(79662904, LRes.Result.ParentSlot);
  AssertEquals('5wLhsKAH9SCPbRZc4qWf3GBiod9CD8sCEZfMiU25qW8', LRes.Result.Blockhash);
  AssertEquals('CjJ97j84mUq3o67CEqzEkTifXpHLBCD8GvmfBYLz4Zdg', LRes.Result.PreviousBlockhash);

  AssertEquals(1, LRes.Result.Rewards.Count);
  AssertEquals(1785000, LRes.Result.Rewards[0].Lamports);
  AssertEquals(365762267923, LRes.Result.Rewards[0].PostBalance);
  AssertEquals('9zkU8suQBdhZVax2DSGNAnyEhEzfEELvA25CJhy5uwnW', LRes.Result.Rewards[0].Pubkey);
  AssertEquals(Ord(TRewardType.Fee), Ord(LRes.Result.Rewards[0].RewardType));

  LFirst := LRes.Result.Transactions[0];
  AssertTrue(LFirst.Meta.Error <> nil);
  AssertEquals(Ord(TTransactionErrorType.InstructionError), Ord(LFirst.Meta.Error.&Type));
  AssertTrue(LFirst.Meta.Error.InstructionError <> nil);
  AssertEquals(Ord(TInstructionErrorType.Custom), Ord(LFirst.Meta.Error.InstructionError.&Type));
  AssertEquals(0, LFirst.Meta.Error.InstructionError.CustomError.Value);

  AssertEquals(5000, LFirst.Meta.Fee);
  AssertEquals(0, LFirst.Meta.InnerInstructions.Count);
  AssertEquals(2, Length(LFirst.Meta.LogMessages));
  AssertEquals(5, Length(LFirst.Meta.PostBalances));
  AssertEquals(35132731759, LFirst.Meta.PostBalances[0]);
  AssertEquals(5, Length(LFirst.Meta.PreBalances));
  AssertEquals(35132736759, LFirst.Meta.PreBalances[0]);
  AssertEquals(0, LFirst.Meta.PostTokenBalances.Count);
  AssertEquals(0, LFirst.Meta.PreTokenBalances.Count);

  LFirstTransactionInfo := LFirst.Transaction.AsType<TTransactionInfo>;
  AssertEquals(1, Length(LFirstTransactionInfo.Signatures));
  AssertEquals(
    '2Hh35eZPP1wZLYQ1HHv8PqGoRo73XirJeKFpBVc19msi6qeJHk3yUKqS1viRtqkdb545CerTWeywPFXxjKEhDWTK',
    LFirstTransactionInfo.Signatures[0]);

  AssertEquals(5, Length(LFirstTransactionInfo.Message.AccountKeys));
  AssertEquals('DjuMPGThkGdyk2vDvDDYjTFSyxzTumdapnDNbvVZbYQE',
    LFirstTransactionInfo.Message.AccountKeys[0]);

  AssertEquals(0, LFirstTransactionInfo.Message.Header.NumReadonlySignedAccounts);
  AssertEquals(3, LFirstTransactionInfo.Message.Header.NumReadonlyUnsignedAccounts);
  AssertEquals(1, LFirstTransactionInfo.Message.Header.NumRequiredSignatures);

  AssertEquals(1, LFirstTransactionInfo.Message.Instructions.Count);
  AssertEquals(4, Length(LFirstTransactionInfo.Message.Instructions[0].Accounts));
  AssertEquals('2ZjTR1vUs2pHXyTLxtFDhN2tsm2HbaH36cAxzJcwaXf8y5jdTESsGNBLFaxGuWENxLa2ZL3cX9foNJcWbRq',
    LFirstTransactionInfo.Message.Instructions[0].Data);
  AssertEquals(4, LFirstTransactionInfo.Message.Instructions[0].ProgramIdIndex);

  AssertEquals('D8qh6AeX4KaTe6ZBpsZDdntTQUyPy7x6Xjp7NnEigCWH',
    LFirstTransactionInfo.Message.RecentBlockhash);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockInvalid;
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
      LRpcClient.GetBlock(
        79662905,
        TTransactionDetailsFilterType.Full,
        False,
        0,
        TBinaryEncoding.Json,
        TCommitment.Processed
      );
    end,
    EArgumentException
  );
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockProductionNoArgs;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TResponseValue<TBlockProductionInfo>>;
  LKey: string;
begin
  LResponseData := LoadTestData('Blocks/GetBlockProductionNoArgsResponse.json');
  LRequestData := LoadTestData('Blocks/GetBlockProductionNoArgsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetBlockProduction('', TNullable<UInt64>.None, TNullable<UInt64>.None, TCommitment.Finalized);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertTrue(LRes.Result <> nil);
  AssertEquals(3, LRes.Result.Value.ByIdentity.Count);
  AssertEquals(79580256, LRes.Result.Value.Range.FirstSlot);
  AssertEquals(79712285, LRes.Result.Value.Range.LastSlot);

  LKey := '121cur1YFVPZSoKQGNyjNr9sZZRa3eX2bSuYjXHtKD6';
  AssertTrue(LRes.Result.Value.ByIdentity.ContainsKey(LKey));
  AssertEquals(60, LRes.Result.Value.ByIdentity[LKey][0]);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockProductionInvalidCommitment;
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
      LRpcClient.GetBlockProduction(
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
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TResponseValue<TBlockProductionInfo>>;
  LKey: string;
begin
  LResponseData := LoadTestData('Blocks/GetBlockProductionIdentityResponse.json');
  LRequestData := LoadTestData('Blocks/GetBlockProductionIdentityRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetBlockProduction('Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu',
    TNullable<UInt64>.None, TNullable<UInt64>.None, TCommitment.Finalized);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertTrue(LRes.Result <> nil);
  AssertEquals(1, LRes.Result.Value.ByIdentity.Count);
  AssertEquals(79580256, LRes.Result.Value.Range.FirstSlot);
  AssertEquals(79712285, LRes.Result.Value.Range.LastSlot);

  LKey := 'Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu';
  AssertTrue(LRes.Result.Value.ByIdentity.ContainsKey(LKey));
  AssertEquals(96, LRes.Result.Value.ByIdentity[LKey][0]);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockProductionRangeStart;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TResponseValue<TBlockProductionInfo>>;
  LKey: string;
begin
  LResponseData := LoadTestData('Blocks/GetBlockProductionRangeStartResponse.json');
  LRequestData := LoadTestData('Blocks/GetBlockProductionRangeStartRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetBlockProduction('', 79714135, TNullable<UInt64>.None, TCommitment.Processed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertTrue(LRes.Result <> nil);
  AssertEquals(35, LRes.Result.Value.ByIdentity.Count);
  AssertEquals(79714135, LRes.Result.Value.Range.FirstSlot);
  AssertEquals(79714275, LRes.Result.Value.Range.LastSlot);

  LKey := '123vij84ecQEKUvQ7gYMKxKwKF6PbYSzCzzURYA4xULY';
  AssertTrue(LRes.Result.Value.ByIdentity.ContainsKey(LKey));
  AssertEquals(4, LRes.Result.Value.ByIdentity[LKey][0]);
  AssertEquals(3, LRes.Result.Value.ByIdentity[LKey][1]);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockProductionIdentityRange;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TResponseValue<TBlockProductionInfo>>;
  LKey: string;
begin
  LResponseData := LoadTestData('Blocks/GetBlockProductionIdentityRangeResponse.json');
  LRequestData := LoadTestData('Blocks/GetBlockProductionIdentityRangeRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetBlockProduction('Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu', 79000000, 79500000);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertTrue(LRes.Result <> nil);
  AssertEquals(1, LRes.Result.Value.ByIdentity.Count);
  AssertEquals(79000000, LRes.Result.Value.Range.FirstSlot);
  AssertEquals(79500000, LRes.Result.Value.Range.LastSlot);

  LKey := 'Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu';
  AssertTrue(LRes.Result.Value.ByIdentity.ContainsKey(LKey));
  AssertEquals(416, LRes.Result.Value.ByIdentity[LKey][0]);
  AssertEquals(341, LRes.Result.Value.ByIdentity[LKey][1]);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetTransaction;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TTransactionMetaSlotInfo>;
  LTmi: TTransactionMetaInfo;
  LTmiTransactionInfo: TTransactionInfo;
begin
  LResponseData := LoadTestData('Transaction/GetTransactionResponse.json');
  LRequestData := LoadTestData('Transaction/GetTransactionRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetTransaction(
    '5as3w4KMpY23MP5T1nkPVksjXjN7hnjHKqiDxRMxUNcw5XsCGtStayZib1kQdyR2D9w8dR11Ha9Xk38KP3kbAwM1');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertTrue(LRes.Result <> nil);
  AssertEquals(Int64(79700345), LRes.Result.Slot);
  AssertEquals(1622655364, LRes.Result.BlockTime.Value);

  LTmi := LRes.Result;
  AssertTrue(LTmi.Meta.Error = nil);
  AssertEquals(5000, LTmi.Meta.Fee);
  AssertEquals(0, LTmi.Meta.InnerInstructions.Count);
  AssertEquals(2, Length(LTmi.Meta.LogMessages));
  AssertEquals(5, Length(LTmi.Meta.PostBalances));
  AssertEquals(395383573380, LTmi.Meta.PostBalances[0]);
  AssertEquals(5, Length(LTmi.Meta.PreBalances));
  AssertEquals(395383578380, LTmi.Meta.PreBalances[0]);
  AssertEquals(0, LTmi.Meta.PostTokenBalances.Count);
  AssertEquals(0, LTmi.Meta.PreTokenBalances.Count);

  LTmiTransactionInfo := LTmi.Transaction.AsType<TTransactionInfo>;
  AssertEquals(1, Length(LTmiTransactionInfo.Signatures));
  AssertEquals(
    '5as3w4KMpY23MP5T1nkPVksjXjN7hnjHKqiDxRMxUNcw5XsCGtStayZib1kQdyR2D9w8dR11Ha9Xk38KP3kbAwM1',
    LTmiTransactionInfo.Signatures[0]);

  AssertEquals(5, Length(LTmiTransactionInfo.Message.AccountKeys));
  AssertEquals(
    'EvVrzsxoj118sxxSTrcnc9u3fRdQfCc7d4gRzzX6TSqj',
    LTmiTransactionInfo.Message.AccountKeys[0]);

  AssertEquals(0, LTmiTransactionInfo.Message.Header.NumReadonlySignedAccounts);
  AssertEquals(3, LTmiTransactionInfo.Message.Header.NumReadonlyUnsignedAccounts);
  AssertEquals(1, LTmiTransactionInfo.Message.Header.NumRequiredSignatures);

  AssertEquals(1, LTmiTransactionInfo.Message.Instructions.Count);
  AssertEquals(4, Length(LTmiTransactionInfo.Message.Instructions[0].Accounts));
  AssertEquals('2kr3BYaDkghC7rvHsQYnBNoB4dhXrUmzgYMM4kbHSG7ALa3qsMPxfC9cJTFDKyJaC8VYSjrey9pvyRivtESUJrC3qzr89pvS2o6MQ'
    + 'hyRVxmh3raQStxFFYwZ6WyKFNoQXvcchBwy8uQGfhhUqzuLNREwRmZ5U2VgTjFWX8Vikqya6iyzvALQNZEvqz7ZoGEyRtJ6AzNyWbkUyEo63rZ5w3wnxmhr3Uood',
    LTmiTransactionInfo.Message.Instructions[0].Data);

  AssertEquals(4, LTmiTransactionInfo.Message.Instructions[0].ProgramIdIndex);
  AssertEquals('6XGYfEJ5CGGBA5E8E7Gw4ToyDLDNNAyUCb7CJj1rLk21', LTmiTransactionInfo.Message.RecentBlockhash);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetTransaction2;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TTransactionMetaSlotInfo>;
  LFirst: TTransactionMetaInfo;
begin
  LResponseData := LoadTestData('Transaction/GetTransactionResponse2.json');
  LRequestData := LoadTestData('Transaction/GetTransactionRequest2.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetTransaction(
    '3Q9mu4ePvtbtQzY1kpGmaViJKyBev6hgUppyXDF9hKgWHHnecwGLE2pSoFvNUF3h7acKyFwWd65bkwr9A1jN2CdT');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertTrue(LRes.Result <> nil);

  AssertEquals(132196637, LRes.Result.Slot);
  AssertEquals(1651763621, LRes.Result.BlockTime.Value);

  LFirst := LRes.Result;

  AssertNotNull(LFirst.Meta.Error);
  AssertEquals(Ord(TTransactionErrorType.InvalidRentPayingAccount), Ord(LFirst.Meta.Error.&Type));

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetTransactionVersioned;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TTransactionMetaSlotInfo>;
  LTmi: TTransactionMetaInfo;
  LTmiTransactionInfo: TTransactionInfo;
begin
  LResponseData := LoadTestData('Transaction/GetTransactionVersionedResponse.json');
  LRequestData := LoadTestData('Transaction/GetTransactionVersionedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  // maxSupportedTransactionVersion = 0
  LRes := LRpcClient.GetTransaction(
    '2KLm7JmcMgZgNNqmsrp3vX3G7U4wg4JQ4NUydeUWJRQA9nJPkCWsMJGr5V2eQSyKe8Jpztghv6w2kDerJX16MxSz',
    0);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertTrue(LRes.Result <> nil, 'Result should not be nil');

  AssertEquals(Int64(255401968), LRes.Result.Slot);
  AssertEquals(1710963316, LRes.Result.BlockTime.Value);

  LTmi := LRes.Result;

  AssertTrue(LTmi.Meta.Error = nil, 'Meta.Error should be nil');

  AssertEquals(1005001, LTmi.Meta.Fee);
  AssertEquals(2, LTmi.Meta.InnerInstructions.Count);
  AssertEquals(110, Length(LTmi.Meta.LogMessages));
  AssertEquals(43, Length(LTmi.Meta.PostBalances));
  AssertEquals(684571363, LTmi.Meta.PostBalances[0]);
  AssertEquals(43, Length(LTmi.Meta.PreBalances));
  AssertEquals(96756112, LTmi.Meta.PreBalances[0]);
  AssertEquals(13, LTmi.Meta.PostTokenBalances.Count);
  AssertEquals(13, LTmi.Meta.PreTokenBalances.Count);

  LTmiTransactionInfo := LTmi.Transaction.AsType<TTransactionInfo>;

  AssertEquals(1, Length(LTmiTransactionInfo.Signatures));
  AssertEquals(
    '2KLm7JmcMgZgNNqmsrp3vX3G7U4wg4JQ4NUydeUWJRQA9nJPkCWsMJGr5V2eQSyKe8Jpztghv6w2kDerJX16MxSz',
    LTmiTransactionInfo.Signatures[0]);

  AssertEquals(15, Length(LTmiTransactionInfo.Message.AccountKeys));
  AssertEquals(
    '5fVwGG2By5gLcpwH1RsqxYDyMzA5FfDRsRBPEvGDsSNu',
    LTmiTransactionInfo.Message.AccountKeys[0]);

  AssertEquals(0, LTmiTransactionInfo.Message.Header.NumReadonlySignedAccounts);
  AssertEquals(8, LTmiTransactionInfo.Message.Header.NumReadonlyUnsignedAccounts);
  AssertEquals(1, LTmiTransactionInfo.Message.Header.NumRequiredSignatures);

  AssertEquals(6, LTmiTransactionInfo.Message.Instructions.Count);
  AssertEquals(6, Length(LTmiTransactionInfo.Message.Instructions[2].Accounts));
  AssertEquals('3K7fezMZDETh', LTmiTransactionInfo.Message.Instructions[1].Data);

  AssertEquals(7, LTmiTransactionInfo.Message.Instructions[0].ProgramIdIndex);

  AssertEquals('AwqZBjWfsFBE1ozAHgp8TkxSz3C82MgtA2JuT43GgVti',
    LTmiTransactionInfo.Message.RecentBlockhash);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetTransactionProcessed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TTransactionMetaSlotInfo>;
begin
  LResponseData := LoadTestData('Transaction/GetTransactionResponse.json');
  LRequestData := LoadTestData('Transaction/GetTransactionProcessedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetTransaction(
    '5as3w4KMpY23MP5T1nkPVksjXjN7hnjHKqiDxRMxUNcw5XsCGtStayZib1kQdyR2D9w8dR11Ha9Xk38KP3kbAwM1',
    0, TBinaryEncoding.Json, TCommitment.Processed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertTrue(LRes.Result <> nil);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlocks;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TList<UInt64>>;
begin
  LResponseData := LoadTestData('Blocks/GetBlocksResponse.json');
  LRequestData := LoadTestData('Blocks/GetBlocksRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetBlocks(79499950, 79500000, TCommitment.Finalized);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertTrue(LRes.Result <> nil);
  AssertEquals(39, LRes.Result.Count);
  AssertEquals(79499950, LRes.Result[0]);
  AssertEquals(79500000, LRes.Result[38]);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlocksInvalidCommitment;
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
      LRpcClient.GetBlocks(
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
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TList<UInt64>>;
begin
  LResponseData := LoadTestData('Blocks/GetBlocksWithLimitResponse.json');
  LRequestData := LoadTestData('Blocks/GetBlocksWithLimitRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetBlocksWithLimit(79699950, 2);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertTrue(LRes.Result <> nil);
  AssertEquals(2, LRes.Result.Count);
  AssertEquals(79699950, LRes.Result[0]);
  AssertEquals(79699951, LRes.Result[1]);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlocksWithLimitBadCommitment;
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
      LRpcClient.GetBlocksWithLimit(
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
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<UInt64>;
begin
  LResponseData := LoadTestData('Blocks/GetFirstAvailableBlockResponse.json');
  LRequestData := LoadTestData('Blocks/GetFirstAvailableBlockRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetFirstAvailableBlock;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertNotNull(LRes);
  AssertEquals(39368303, LRes.Result);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockHeight;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<UInt64>;
begin
  LResponseData := LoadTestData('Blocks/GetBlockHeightResponse.json');
  LRequestData := LoadTestData('Blocks/GetBlockHeightRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetBlockHeight;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertNotNull(LRes);
  AssertTrue(LRes.WasSuccessful);
  AssertEquals(1233, LRes.Result);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockHeightConfirmed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<UInt64>;
begin
  LResponseData := LoadTestData('Blocks/GetBlockHeightResponse.json');
  LRequestData := LoadTestData('Blocks/GetBlockHeightConfirmedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetBlockHeight(TCommitment.Confirmed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertNotNull(LRes);
  AssertTrue(LRes.WasSuccessful);
  AssertEquals(1233, LRes.Result);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockCommitment;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TBlockCommitment>;
begin
  LResponseData := LoadTestData('Blocks/GetBlockCommitmentResponse.json');
  LRequestData := LoadTestData('Blocks/GetBlockCommitmentRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetBlockCommitment(78561320);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertNotNull(LRes.Result);
  AssertTrue(LRes.WasSuccessful);
  AssertTrue(LRes.Result.Commitment = nil);
  AssertEquals(78380558524696194, LRes.Result.TotalStake);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetBlockTime;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<UInt64>;
begin
  LResponseData := LoadTestData('Blocks/GetBlockTimeResponse.json');
  LRequestData := LoadTestData('Blocks/GetBlockTimeRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetBlockTime(78561320);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertNotNull(LRes);
  AssertTrue(LRes.WasSuccessful);
  AssertEquals(1621971949, LRes.Result);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestGetLatestBlockHash;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TResponseValue<TLatestBlockHash>>;
begin
  LResponseData := LoadTestData('Blocks/GetLatestBlockhashResponse.json');
  LRequestData := LoadTestData('Blocks/GetLatestBlockhashRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetLatestBlockhash(TCommitment.Finalized);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertNotNull(LRes.Result);
  AssertTrue(LRes.WasSuccessful);
  AssertEquals(127140942, LRes.Result.Context.Slot);
  AssertEquals('DDFfxGAsEVcqNbCLRgvDtzcc2ZxNnqJfQJfMTRhEEPwW', LRes.Result.Value.Blockhash);
  AssertEquals(115143990, LRes.Result.Value.LastValidBlockHeight);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientBlockTests.TestIsBlockhashValid;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TResponseValue<Boolean>>;
begin
  LResponseData := LoadTestData('Blocks/IsBlockhashValidResponse.json');
  LRequestData := LoadTestData('Blocks/IsBlockhashValidRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.IsBlockhashValid('DDFfxGAsEVcqNbCLRgvDtzcc2ZxNnqJfQJfMTRhEEPwW');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson);
  AssertNotNull(LRes.Result);
  AssertTrue(LRes.WasSuccessful);
  AssertEquals(127140942, LRes.Result.Context.Slot);
  AssertTrue(LRes.Result.Value);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientBlockTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientBlockTests.Suite);
{$ENDIF}

end.
