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
  TestUtils,
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
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<UInt64>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'EmptyPayloadResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'EmptyPayloadRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200, 'OK');
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetBalance('');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result <> nil, 'Result should not be nil');
  AssertTrue(result.Result = nil, 'Result.Result should be empty/nil');
  AssertTrue(result.WasHttpRequestSuccessful, 'WasHttpRequestSuccessful should be True');
  AssertFalse(result.WasRequestSuccessfullyHandled, 'WasRequestSuccessfullyHandled should be False');
  AssertFalse(result.WasSuccessful, 'WasSuccessful should be False');
  AssertEquals('Invalid param: WrongSize', result.Reason);
  AssertEquals(-32602, result.ServerErrorCode);
  AssertTrue(result.RawRpcRequest <> '', 'RawRpcRequest should be present');
  AssertTrue(result.RawRpcResponse <> '', 'RawRpcResponse should be present');
  AssertJsonMatch(requestData, result.RawRpcRequest);
  AssertJsonMatch(responseData, result.RawRpcResponse);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestStringErrorResponse;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<UInt64>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'StringErrorResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'EmptyPayloadRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetBalance('');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result <> nil, 'Result should not be nil');
  AssertTrue(result.Result = nil, 'Result.Result should be nil');
  AssertTrue(result.WasHttpRequestSuccessful, 'HTTP should be successful');
  AssertFalse(result.WasRequestSuccessfullyHandled, 'RPC should not be handled');
  AssertFalse(result.WasSuccessful, 'Overall should be unsuccessful');
  AssertEquals('something wrong', result.Reason);
  AssertEquals(0, result.ServerErrorCode);
  AssertNull(result.ErrorData);
  AssertTrue(result.RawRpcRequest <> '', 'RawRpcRequest should be present');
  AssertTrue(result.RawRpcResponse <> '', 'RawRpcResponse should be present');
  AssertJsonMatch(requestData, result.RawRpcRequest);
  AssertJsonMatch(responseData, result.RawRpcResponse);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestBadAddressExceptionRequest;
var
  msg, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<UInt64>>;
begin
  msg := 'something bad happenned';
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'EmptyPayloadRequest.json']));

  mockRpcHttpClient := SetupTestForThrow(msg);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create('https://non.existing.adddress.com', rpcHttpClient);
  result := rpcClient.GetBalance('');

  AssertEquals(400, result.HttpStatusCode);
  AssertEquals(msg, result.Reason);
  AssertFalse(result.WasHttpRequestSuccessful, 'HTTP should fail');
  AssertFalse(result.WasRequestSuccessfullyHandled, 'RPC should not be handled');
  AssertTrue(result.RawRpcRequest <> '', 'RawRpcRequest should be present');
  AssertEquals('', result.RawRpcResponse);
  AssertJsonMatch(requestData, result.RawRpcRequest);
end;

procedure TSolanaRpcClientTests.TestGetBalance;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<UInt64>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetBalanceResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetBalanceRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetBalance('hoakwpFB8UoLnPpLC56gsjpY7XbVwaCuRQRMQzN5TVh');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(79274779, result.Result.Context.Slot);
  AssertEquals(168855000000, result.Result.Value);

  AssertTrue(result.RawRpcRequest <> '', 'RawRpcRequest present');
  AssertTrue(result.RawRpcResponse <> '', 'RawRpcResponse present');
  AssertJsonMatch(requestData, result.RawRpcRequest);
  AssertEquals(responseData, result.RawRpcResponse);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetBalanceConfirmed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<UInt64>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetBalanceResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetBalanceConfirmedRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetBalance('hoakwpFB8UoLnPpLC56gsjpY7XbVwaCuRQRMQzN5TVh', TCommitment.Confirmed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(79274779, result.Result.Context.Slot);
  AssertEquals(168855000000, result.Result.Value);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetClusterNodes;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TObjectList<TClusterNode>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetClusterNodesResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetClusterNodesRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetClusterNodes;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(5, result.Result.Count);
  AssertEquals(3533521759, result.Result[0].FeatureSet.Value);
  AssertEquals('216.24.140.155:8001', result.Result[0].Gossip);
  AssertEquals('5D1fNXzvv5NjV1ysLjirC4WY92RNsVH18vjmcszZd8on', result.Result[0].PublicKey);
  AssertEquals('216.24.140.155:8899', result.Result[0].Rpc);
  AssertEquals(18122, result.Result[0].ShredVersion);
  AssertEquals('216.24.140.155:8004', result.Result[0].Tpu);
  AssertEquals('1.7.0', result.Result[0].Version);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetEpochInfo;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TEpochInfo>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Epoch', 'GetEpochInfoResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Epoch', 'GetEpochInfoRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetEpochInfo;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(166598, result.Result.AbsoluteSlot);
  AssertEquals(166500, result.Result.BlockHeight);
  AssertEquals(27, result.Result.Epoch);
  AssertEquals(2790, result.Result.SlotIndex);
  AssertEquals(8192, result.Result.SlotsInEpoch);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetEpochInfoProcessed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TEpochInfo>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Epoch', 'GetEpochInfoResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Epoch', 'GetEpochInfoProcessedRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetEpochInfo(TCommitment.Processed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(166598, result.Result.AbsoluteSlot);
  AssertEquals(166500, result.Result.BlockHeight);
  AssertEquals(27, result.Result.Epoch);
  AssertEquals(2790, result.Result.SlotIndex);
  AssertEquals(8192, result.Result.SlotsInEpoch);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetEpochSchedule;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TEpochScheduleInfo>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Epoch', 'GetEpochScheduleResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Epoch', 'GetEpochScheduleRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetEpochSchedule;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(8, result.Result.FirstNormalEpoch);
  AssertEquals(8160, result.Result.FirstNormalSlot);
  AssertEquals(8192, result.Result.LeaderScheduleSlotOffset);
  AssertEquals(8192, result.Result.SlotsPerEpoch);
  AssertTrue(result.Result.Warmup, 'Warmup should be true');

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetGenesisHash;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<string>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetGenesisHashResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetGenesisHashRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetGenesisHash;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> '', 'Result should not be empty');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals('4uhcVJyU9pJkvQyS88uRDiswHXSCkY3zQawwpjk2NsNY', result.Result);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetIdentity;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TNodeIdentity>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetIdentityResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetIdentityRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetIdentity;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals('2r1F4iWqVcb8M1DbAjQuFpebkQHY9hcVU4WuW2DJBppN', result.Result.Identity);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetMaxRetransmitSlot;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<UInt64>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetMaxRetransmitSlotResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetMaxRetransmitSlotRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetMaxRetransmitSlot;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result = 1234, 'Value mismatch');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetShredInsertSlot;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<UInt64>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetMaxShredInsertSlotResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetMaxShredInsertSlotRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetMaxShredInsertSlot;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result = 1234, 'Value mismatch');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetSlotLeadersEmpty;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TList<string>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Slot', 'GetSlotLeadersEmptyResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Slot', 'GetSlotLeadersEmptyRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetSlotLeaders(0, 0);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetSlotLeaders;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TList<string>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Slot', 'GetSlotLeadersResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Slot', 'GetSlotLeadersRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetSlotLeaders(100, 10);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(10, result.Result.Count);
  AssertEquals('ChorusmmK7i1AxXeiTtQgQZhQNiXYU84ULeaYF1EH15n', result.Result[0]);
  AssertEquals('Awes4Tr6TX8JDzEhCZY2QVNimT6iD1zWHzf1vNyGvpLM', result.Result[4]);
  AssertEquals('DWvDTSh3qfn88UoQTEKRV2JnLt5jtJAVoiCo3ivtMwXP', result.Result[8]);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetSlotLeader;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<string>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Slot', 'GetSlotLeaderResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Slot', 'GetSlotLeaderRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetSlotLeader();

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> '', 'Result should not be empty');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals('ENvAW7JScgYq6o4zKZwewtkzzJgDzuJAFxYasvmEQdpS', result.Result);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetSlot;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<UInt64>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Slot', 'GetSlotResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Slot', 'GetSlotRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetSlot;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result = 1234, 'Value mismatch');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetSlotProcessed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<UInt64>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Slot', 'GetSlotResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Slot', 'GetSlotProcessedRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetSlot(TCommitment.Processed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result = 1234, 'Value mismatch');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetRecentPerformanceSamples;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TObjectList<TPerformanceSample>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetRecentPerformanceSamplesResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetRecentPerformanceSamplesRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetRecentPerformanceSamples(4);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(4, result.Result.Count);
  AssertEquals(126, result.Result[0].NumSlots);
  AssertEquals(348125, result.Result[0].Slot);
  AssertEquals(126, result.Result[0].NumTransactions);
  AssertEquals(60, result.Result[0].SamplePeriodSecs);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetHighestSnapshotSlot;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TSnapshotSlotInfo>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetHighestSnapshotSlotResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetHighestSnapshotSlotRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetHighestSnapshotSlot;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(132174097, result.Result.Full);
  AssertFalse(result.Result.Incremental.HasValue, 'Incremental should be nil');

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetSupply;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TSupply>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetSupplyResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetSupplyRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetSupply;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(79266564, result.Result.Context.Slot);
  AssertEquals(1359481823340465122, result.Result.Value.Circulating);
  AssertEquals(122260000000, result.Result.Value.NonCirculating);
  AssertEquals(16, Length(result.Result.Value.NonCirculatingAccounts));

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetSupplyProcessed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TSupply>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetSupplyResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetSupplyProcessedRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetSupply(TCommitment.Processed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(79266564, result.Result.Context.Slot);
  AssertEquals(1359481823340465122, result.Result.Value.Circulating);
  AssertEquals(122260000000, result.Result.Value.NonCirculating);
  AssertEquals(16, Length(result.Result.Value.NonCirculatingAccounts));

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetMinimumLedgerSlot;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<UInt64>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetMinimumLedgerSlotResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetMinimumLedgerSlotRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetMinimumLedgerSlot();

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(78969229, result.Result);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetVersion;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TNodeVersion>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetVersionResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetVersionRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetVersion;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(1082270801, result.Result.FeatureSet.Value);
  AssertEquals('1.6.11', result.Result.SolanaCore);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetHealth_HealthyResponse;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<string>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Health', 'GetHealthHealthyResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Health', 'GetHealthRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetHealth;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertEquals('ok', result.Result);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetHealth_UnhealthyResponse;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<string>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Health', 'GetHealthUnhealthyResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Health', 'GetHealthRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetHealth;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result = '', 'Result should be empty');
  AssertTrue(result.WasHttpRequestSuccessful, 'HTTP should be successful');
  AssertFalse(result.WasRequestSuccessfullyHandled, 'RPC should not be handled');
  AssertEquals(-32005, result.ServerErrorCode);
  AssertEquals('Node is behind by 42 slots', result.Reason);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetMinimumBalanceForRentExemption;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<UInt64>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetMinimumBalanceForRateExemptionResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetMinimumBalanceForRateExemptionRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetMinimumBalanceForRentExemption(50);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(500, result.Result);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestGetMinimumBalanceForRentExemptionConfirmed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<UInt64>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetMinimumBalanceForRateExemptionResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetMinimumBalanceForRateExemptionConfirmedRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetMinimumBalanceForRentExemption(50, TCommitment.Confirmed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(500, result.Result);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestRequestAirdrop;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<string>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'RequestAirdropResult.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'RequestAirdropRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.RequestAirdrop('6bhhceZToGG9RsTe1nfNFXEMjavhj6CV55EsvearAt2z', 100000000000);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals('2iyRQZmksTfkmyH9Fnho61x4Y7TeSN8g3GRZCHmQjzzFB1e3DwKEVrYfR7AnKjiE5LiDEfCowtzoE2Pau646g1Vf', result.Result);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTests.TestFailHttp410Gone;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  filter: TMemCmp;
  filters: TArray<TMemCmp>;
  result: IRequestResult<TObjectList<TAccountKeyPair>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetProgramAccountsResponse-Fail-410.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetProgramAccountsRequest-Fail-410.json']));

  // Simulate HTTP 410 Gone
  mockRpcHttpClient := SetupTest(responseData, 410);
  rpcHttpClient := mockRpcHttpClient;

  filter := TMemCmp.Create;
  try
    filter.Offset := 45;
    filter.Bytes  := '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5';

    SetLength(filters, 1);
    filters[0] := filter;

    rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
    result := rpcClient.GetProgramAccounts(
      '9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin',
      3228,
      nil,
      filters
    );

    AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
    AssertTrue(result <> nil, 'Result should not be nil');
    AssertEquals(410, result.HttpStatusCode);
    AssertEquals(responseData, result.RawRpcResponse);
    AssertFalse(result.WasSuccessful, 'Should not be successful');
    AssertTrue(result.Result = nil, 'Result should be nil');

    FinishTest(mockRpcHttpClient, TestnetUrl);
  finally
    filter.Free;
    if Length(filters) > 0 then filters[0] := nil;
  end;
end;

procedure TSolanaRpcClientTests.TestFailHttp415UnsupportedMediaType;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<UInt64>>;
begin
  responseData := 'Supplied content type is not allowed. Content-Type: application/json is required';
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'GetBalanceRequest.json']));

  // Simulate HTTP 415 Unsupported Media Type
  mockRpcHttpClient := SetupTest(responseData, 415);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetBalance('hoakwpFB8UoLnPpLC56gsjpY7XbVwaCuRQRMQzN5TVh');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result <> nil, 'Result should not be nil');
  AssertEquals(415, result.HttpStatusCode);
  AssertEquals(responseData, result.RawRpcResponse);
  AssertFalse(result.WasSuccessful, 'Should not be successful');
  AssertTrue(result.Result = nil, 'Result should be nil');

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientTests.Suite);
{$ENDIF}

end.


