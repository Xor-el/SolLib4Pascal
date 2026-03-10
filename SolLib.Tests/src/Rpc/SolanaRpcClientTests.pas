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

unit SolanaRpcClientTests;


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
  RpcClientMocks,
  SolLibRpcClientTestCase;

type
  TSolanaRpcClientTests = class(TSolLibRpcClientTestCase)
  published
    procedure TestEmptyPayloadRequest;
    procedure TestStringErrorResponse;
    procedure TestBadAddressExceptionRequest;
    procedure TestGetBalance;
    procedure TestGetBalanceConfirmed;
    procedure TestGetClusterNodes;
    procedure TestGetEpochInfo;
    procedure TestGetEpochInfoProcessed;
    procedure TestGetEpochSchedule;
    procedure TestGetGenesisHash;
    procedure TestGetIdentity;
    procedure TestGetMaxRetransmitSlot;
    procedure TestGetShredInsertSlot;
    procedure TestGetSlotLeadersEmpty;
    procedure TestGetSlotLeaders;
    procedure TestGetSlotLeader;
    procedure TestGetSlot;
    procedure TestGetSlotProcessed;
    procedure TestGetRecentPerformanceSamples;
    procedure TestGetHighestSnapshotSlot;
    procedure TestGetSupply;
    procedure TestGetSupplyProcessed;
    procedure TestGetMinimumLedgerSlot;
    procedure TestGetVersion;
    procedure TestGetHealth_HealthyResponse;
    procedure TestGetHealth_UnhealthyResponse;
    procedure TestGetMinimumBalanceForRentExemption;
    procedure TestGetMinimumBalanceForRentExemptionConfirmed;
    procedure TestRequestAirdrop;
    procedure TestFailHttp410Gone;
    procedure TestFailHttp415UnsupportedMediaType;
  end;

implementation

{ TSolanaRpcClientTests }

procedure TSolanaRpcClientTests.TestEmptyPayloadRequest;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<UInt64>>;
begin
  LResponseData := LoadTestData('EmptyPayloadResponse.json');
  LRequestData := LoadTestData('EmptyPayloadRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200, 'OK');
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetBalance('');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult <> nil, 'Result should not be nil');
  AssertTrue(LResult.Result = nil, 'Result.Result should be empty/nil');
  AssertTrue(LResult.WasHttpRequestSuccessful, 'WasHttpRequestSuccessful should be True');
  AssertFalse(LResult.WasRequestSuccessfullyHandled, 'WasRequestSuccessfullyHandled should be False');
  AssertFalse(LResult.WasSuccessful, 'WasSuccessful should be False');
  AssertEquals('Invalid param: WrongSize', LResult.Reason);
  AssertEquals(-32602, LResult.ServerErrorCode);
  AssertTrue(LResult.RawRpcRequest <> '', 'RawRpcRequest should be present');
  AssertTrue(LResult.RawRpcResponse <> '', 'RawRpcResponse should be present');
  AssertJsonMatch(LRequestData, LResult.RawRpcRequest);
  AssertJsonMatch(LResponseData, LResult.RawRpcResponse);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestStringErrorResponse;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<UInt64>>;
begin
  LResponseData := LoadTestData('StringErrorResponse.json');
  LRequestData := LoadTestData('EmptyPayloadRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetBalance('');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult <> nil, 'Result should not be nil');
  AssertTrue(LResult.Result = nil, 'Result.Result should be nil');
  AssertTrue(LResult.WasHttpRequestSuccessful, 'HTTP should be successful');
  AssertFalse(LResult.WasRequestSuccessfullyHandled, 'RPC should not be handled');
  AssertFalse(LResult.WasSuccessful, 'Overall should be unsuccessful');
  AssertEquals('something wrong', LResult.Reason);
  AssertEquals(0, LResult.ServerErrorCode);
  AssertNull(LResult.ErrorData);
  AssertTrue(LResult.RawRpcRequest <> '', 'RawRpcRequest should be present');
  AssertTrue(LResult.RawRpcResponse <> '', 'RawRpcResponse should be present');
  AssertJsonMatch(LRequestData, LResult.RawRpcRequest);
  AssertJsonMatch(LResponseData, LResult.RawRpcResponse);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestBadAddressExceptionRequest;
var
  LMsg, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<UInt64>>;
begin
  LMsg := 'something bad happenned';
  LRequestData := LoadTestData('EmptyPayloadRequest.json');

  LMockRpcHttpClient := SetupTestForThrow(LMsg);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create('https://non.existing.adddress.com', LRpcHttpClient);
  LResult := LRpcClient.GetBalance('');

  AssertEquals(400, LResult.HttpStatusCode);
  AssertEquals(LMsg, LResult.Reason);
  AssertFalse(LResult.WasHttpRequestSuccessful, 'HTTP should fail');
  AssertFalse(LResult.WasRequestSuccessfullyHandled, 'RPC should not be handled');
  AssertTrue(LResult.RawRpcRequest <> '', 'RawRpcRequest should be present');
  AssertEquals('', LResult.RawRpcResponse);
  AssertJsonMatch(LRequestData, LResult.RawRpcRequest);
end;

procedure TSolanaRpcClientTests.TestGetBalance;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<UInt64>>;
begin
  LResponseData := LoadTestData('GetBalanceResponse.json');
  LRequestData := LoadTestData('GetBalanceRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetBalance('hoakwpFB8UoLnPpLC56gsjpY7XbVwaCuRQRMQzN5TVh');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(79274779, LResult.Result.Context.Slot);
  AssertEquals(168855000000, LResult.Result.Value);

  AssertTrue(LResult.RawRpcRequest <> '', 'RawRpcRequest present');
  AssertTrue(LResult.RawRpcResponse <> '', 'RawRpcResponse present');
  AssertJsonMatch(LRequestData, LResult.RawRpcRequest);
  AssertEquals(LResponseData, LResult.RawRpcResponse);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetBalanceConfirmed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<UInt64>>;
begin
  LResponseData := LoadTestData('GetBalanceResponse.json');
  LRequestData := LoadTestData('GetBalanceConfirmedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetBalance('hoakwpFB8UoLnPpLC56gsjpY7XbVwaCuRQRMQzN5TVh', TCommitment.Confirmed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(79274779, LResult.Result.Context.Slot);
  AssertEquals(168855000000, LResult.Result.Value);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetClusterNodes;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TObjectList<TClusterNode>>;
begin
  LResponseData := LoadTestData('GetClusterNodesResponse.json');
  LRequestData := LoadTestData('GetClusterNodesRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetClusterNodes;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(5, LResult.Result.Count);
  AssertEquals(3533521759, LResult.Result[0].FeatureSet.Value);
  AssertEquals('216.24.140.155:8001', LResult.Result[0].Gossip);
  AssertEquals('5D1fNXzvv5NjV1ysLjirC4WY92RNsVH18vjmcszZd8on', LResult.Result[0].PublicKey);
  AssertEquals('216.24.140.155:8899', LResult.Result[0].Rpc);
  AssertEquals(18122, LResult.Result[0].ShredVersion);
  AssertEquals('216.24.140.155:8004', LResult.Result[0].Tpu);
  AssertEquals('1.7.0', LResult.Result[0].Version);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetEpochInfo;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TEpochInfo>;
begin
  LResponseData := LoadTestData('Epoch/GetEpochInfoResponse.json');
  LRequestData := LoadTestData('Epoch/GetEpochInfoRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetEpochInfo;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(166598, LResult.Result.AbsoluteSlot);
  AssertEquals(166500, LResult.Result.BlockHeight);
  AssertEquals(27, LResult.Result.Epoch);
  AssertEquals(2790, LResult.Result.SlotIndex);
  AssertEquals(8192, LResult.Result.SlotsInEpoch);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetEpochInfoProcessed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TEpochInfo>;
begin
  LResponseData := LoadTestData('Epoch/GetEpochInfoResponse.json');
  LRequestData := LoadTestData('Epoch/GetEpochInfoProcessedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetEpochInfo(TCommitment.Processed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(166598, LResult.Result.AbsoluteSlot);
  AssertEquals(166500, LResult.Result.BlockHeight);
  AssertEquals(27, LResult.Result.Epoch);
  AssertEquals(2790, LResult.Result.SlotIndex);
  AssertEquals(8192, LResult.Result.SlotsInEpoch);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetEpochSchedule;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TEpochScheduleInfo>;
begin
  LResponseData := LoadTestData('Epoch/GetEpochScheduleResponse.json');
  LRequestData := LoadTestData('Epoch/GetEpochScheduleRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetEpochSchedule;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(8, LResult.Result.FirstNormalEpoch);
  AssertEquals(8160, LResult.Result.FirstNormalSlot);
  AssertEquals(8192, LResult.Result.LeaderScheduleSlotOffset);
  AssertEquals(8192, LResult.Result.SlotsPerEpoch);
  AssertTrue(LResult.Result.Warmup, 'Warmup should be true');

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetGenesisHash;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<string>;
begin
  LResponseData := LoadTestData('GetGenesisHashResponse.json');
  LRequestData := LoadTestData('GetGenesisHashRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetGenesisHash;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> '', 'Result should not be empty');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals('4uhcVJyU9pJkvQyS88uRDiswHXSCkY3zQawwpjk2NsNY', LResult.Result);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetIdentity;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TNodeIdentity>;
begin
  LResponseData := LoadTestData('GetIdentityResponse.json');
  LRequestData := LoadTestData('GetIdentityRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetIdentity;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals('2r1F4iWqVcb8M1DbAjQuFpebkQHY9hcVU4WuW2DJBppN', LResult.Result.Identity);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetMaxRetransmitSlot;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<UInt64>;
begin
  LResponseData := LoadTestData('GetMaxRetransmitSlotResponse.json');
  LRequestData := LoadTestData('GetMaxRetransmitSlotRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetMaxRetransmitSlot;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result = 1234, 'Value mismatch');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetShredInsertSlot;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<UInt64>;
begin
  LResponseData := LoadTestData('GetMaxShredInsertSlotResponse.json');
  LRequestData := LoadTestData('GetMaxShredInsertSlotRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetMaxShredInsertSlot;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result = 1234, 'Value mismatch');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetSlotLeadersEmpty;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TList<string>>;
begin
  LResponseData := LoadTestData('Slot/GetSlotLeadersEmptyResponse.json');
  LRequestData := LoadTestData('Slot/GetSlotLeadersEmptyRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetSlotLeaders(0, 0);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetSlotLeaders;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TList<string>>;
begin
  LResponseData := LoadTestData('Slot/GetSlotLeadersResponse.json');
  LRequestData := LoadTestData('Slot/GetSlotLeadersRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetSlotLeaders(100, 10);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(10, LResult.Result.Count);
  AssertEquals('ChorusmmK7i1AxXeiTtQgQZhQNiXYU84ULeaYF1EH15n', LResult.Result[0]);
  AssertEquals('Awes4Tr6TX8JDzEhCZY2QVNimT6iD1zWHzf1vNyGvpLM', LResult.Result[4]);
  AssertEquals('DWvDTSh3qfn88UoQTEKRV2JnLt5jtJAVoiCo3ivtMwXP', LResult.Result[8]);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetSlotLeader;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<string>;
begin
  LResponseData := LoadTestData('Slot/GetSlotLeaderResponse.json');
  LRequestData := LoadTestData('Slot/GetSlotLeaderRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetSlotLeader();

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> '', 'Result should not be empty');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals('ENvAW7JScgYq6o4zKZwewtkzzJgDzuJAFxYasvmEQdpS', LResult.Result);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetSlot;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<UInt64>;
begin
  LResponseData := LoadTestData('Slot/GetSlotResponse.json');
  LRequestData := LoadTestData('Slot/GetSlotRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetSlot;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result = 1234, 'Value mismatch');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetSlotProcessed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<UInt64>;
begin
  LResponseData := LoadTestData('Slot/GetSlotResponse.json');
  LRequestData := LoadTestData('Slot/GetSlotProcessedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetSlot(TCommitment.Processed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result = 1234, 'Value mismatch');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetRecentPerformanceSamples;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TObjectList<TPerformanceSample>>;
begin
  LResponseData := LoadTestData('GetRecentPerformanceSamplesResponse.json');
  LRequestData := LoadTestData('GetRecentPerformanceSamplesRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetRecentPerformanceSamples(4);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(4, LResult.Result.Count);
  AssertEquals(126, LResult.Result[0].NumSlots);
  AssertEquals(348125, LResult.Result[0].Slot);
  AssertEquals(126, LResult.Result[0].NumTransactions);
  AssertEquals(60, LResult.Result[0].SamplePeriodSecs);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetHighestSnapshotSlot;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TSnapshotSlotInfo>;
begin
  LResponseData := LoadTestData('GetHighestSnapshotSlotResponse.json');
  LRequestData := LoadTestData('GetHighestSnapshotSlotRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetHighestSnapshotSlot;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(132174097, LResult.Result.Full);
  AssertFalse(LResult.Result.Incremental.HasValue, 'Incremental should be nil');

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetSupply;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TSupply>>;
begin
  LResponseData := LoadTestData('GetSupplyResponse.json');
  LRequestData := LoadTestData('GetSupplyRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetSupply;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(79266564, LResult.Result.Context.Slot);
  AssertEquals(1359481823340465122, LResult.Result.Value.Circulating);
  AssertEquals(122260000000, LResult.Result.Value.NonCirculating);
  AssertEquals(16, Length(LResult.Result.Value.NonCirculatingAccounts));

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetSupplyProcessed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TSupply>>;
begin
  LResponseData := LoadTestData('GetSupplyResponse.json');
  LRequestData := LoadTestData('GetSupplyProcessedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetSupply(TCommitment.Processed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(79266564, LResult.Result.Context.Slot);
  AssertEquals(1359481823340465122, LResult.Result.Value.Circulating);
  AssertEquals(122260000000, LResult.Result.Value.NonCirculating);
  AssertEquals(16, Length(LResult.Result.Value.NonCirculatingAccounts));

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetMinimumLedgerSlot;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<UInt64>;
begin
  LResponseData := LoadTestData('GetMinimumLedgerSlotResponse.json');
  LRequestData := LoadTestData('GetMinimumLedgerSlotRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetMinimumLedgerSlot();

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(78969229, LResult.Result);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetVersion;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TNodeVersion>;
begin
  LResponseData := LoadTestData('GetVersionResponse.json');
  LRequestData := LoadTestData('GetVersionRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetVersion;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(1082270801, LResult.Result.FeatureSet.Value);
  AssertEquals('1.6.11', LResult.Result.SolanaCore);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetHealth_HealthyResponse;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<string>;
begin
  LResponseData := LoadTestData('Health/GetHealthHealthyResponse.json');
  LRequestData := LoadTestData('Health/GetHealthRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetHealth;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertEquals('ok', LResult.Result);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetHealth_UnhealthyResponse;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<string>;
begin
  LResponseData := LoadTestData('Health/GetHealthUnhealthyResponse.json');
  LRequestData := LoadTestData('Health/GetHealthRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetHealth;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result = '', 'Result should be empty');
  AssertTrue(LResult.WasHttpRequestSuccessful, 'HTTP should be successful');
  AssertFalse(LResult.WasRequestSuccessfullyHandled, 'RPC should not be handled');
  AssertEquals(-32005, LResult.ServerErrorCode);
  AssertEquals('Node is behind by 42 slots', LResult.Reason);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetMinimumBalanceForRentExemption;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<UInt64>;
begin
  LResponseData := LoadTestData('GetMinimumBalanceForRateExemptionResponse.json');
  LRequestData := LoadTestData('GetMinimumBalanceForRateExemptionRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetMinimumBalanceForRentExemption(50);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(500, LResult.Result);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetMinimumBalanceForRentExemptionConfirmed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<UInt64>;
begin
  LResponseData := LoadTestData('GetMinimumBalanceForRateExemptionResponse.json');
  LRequestData := LoadTestData('GetMinimumBalanceForRateExemptionConfirmedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetMinimumBalanceForRentExemption(50, TCommitment.Confirmed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(500, LResult.Result);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestRequestAirdrop;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<string>;
begin
  LResponseData := LoadTestData('RequestAirdropResult.json');
  LRequestData := LoadTestData('RequestAirdropRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.RequestAirdrop('6bhhceZToGG9RsTe1nfNFXEMjavhj6CV55EsvearAt2z', 100000000000);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals('2iyRQZmksTfkmyH9Fnho61x4Y7TeSN8g3GRZCHmQjzzFB1e3DwKEVrYfR7AnKjiE5LiDEfCowtzoE2Pau646g1Vf', LResult.Result);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestFailHttp410Gone;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LFilter: TMemCmp;
  LFilters: TArray<TMemCmp>;
  LResult: IRequestResult<TObjectList<TAccountKeyPair>>;
begin
  LResponseData := LoadTestData('GetProgramAccountsResponse-Fail-410.json');
  LRequestData := LoadTestData('GetProgramAccountsRequest-Fail-410.json');

  // Simulate HTTP 410 Gone
  LMockRpcHttpClient := SetupTest(LResponseData, 410);
  LRpcHttpClient := LMockRpcHttpClient;

  LFilter := TMemCmp.Create;
  try
    LFilter.Offset := 45;
    LFilter.Bytes := '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5';

    SetLength(LFilters, 1);
    LFilters[0] := LFilter;

    LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
    LResult := LRpcClient.GetProgramAccounts(
      '9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin',
      3228,
      nil,
      LFilters
    );

    AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
    AssertTrue(LResult <> nil, 'Result should not be nil');
    AssertEquals(410, LResult.HttpStatusCode);
    AssertEquals(LResponseData, LResult.RawRpcResponse);
    AssertFalse(LResult.WasSuccessful, 'Should not be successful');
    AssertTrue(LResult.Result = nil, 'Result should be nil');

    FinishTest(LMockRpcHttpClient, TestnetUrl);
  finally
    LFilter.Free;
    if Length(LFilters) > 0 then LFilters[0] := nil;
  end;
end;

procedure TSolanaRpcClientTests.TestFailHttp415UnsupportedMediaType;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<UInt64>>;
begin
  LResponseData := 'Supplied content type is not allowed. Content-Type: application/json is required';
  LRequestData := LoadTestData('GetBalanceRequest.json');

  // Simulate HTTP 415 Unsupported Media Type
  LMockRpcHttpClient := SetupTest(LResponseData, 415);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetBalance('hoakwpFB8UoLnPpLC56gsjpY7XbVwaCuRQRMQzN5TVh');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult <> nil, 'Result should not be nil');
  AssertEquals(415, LResult.HttpStatusCode);
  AssertEquals(LResponseData, LResult.RawRpcResponse);
  AssertFalse(LResult.WasSuccessful, 'Should not be successful');
  AssertTrue(LResult.Result = nil, 'Result should be nil');

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientTests.Suite);
{$ENDIF}

end.


