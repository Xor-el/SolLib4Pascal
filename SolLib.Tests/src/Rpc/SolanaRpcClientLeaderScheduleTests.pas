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

unit SolanaRpcClientLeaderScheduleTests;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpHttpApiClient,
  SlpHttpApiResponse,
  SlpRpcEnum,
  SlpRpcModel,
  SlpRequestResult,
  SlpSolanaRpcClient,
  RpcClientMocks,
  SolLibRpcClientTestCase;

type
  TSolanaRpcClientLeaderScheduleTests = class(TSolLibRpcClientTestCase)
  published
    procedure TestGetLeaderSchedule_SlotArgsRequest;
    procedure TestGetLeaderSchedule_IdentityArgsRequest;
    procedure TestGetLeaderSchedule_SlotIdentityArgsRequest;
    procedure TestGetLeaderSchedule_NoArgsRequest;
    procedure TestGetLeaderSchedule_CommitmentFinalizedRequest;
    procedure TestGetLeaderSchedule_CommitmentProcessedRequest;
  end;

implementation

{ TSolanaRpcClientLeaderScheduleTests }

procedure TSolanaRpcClientLeaderScheduleTests.TestGetLeaderSchedule_SlotArgsRequest;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  res: IRequestResult<TDictionary<string, TList<UInt64>>>;
  key: string;
begin
  responseData := LoadTestData('LeaderSchedule/GetLeaderScheduleResponse.json');
  requestData  := LoadTestData('LeaderSchedule/GetLeaderScheduleSlotArgsRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetLeaderSchedule(79700000);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(res.Result <> nil, 'Result should not be nil');
  AssertTrue(res.WasSuccessful, 'Should be successful');

  AssertEquals(2, res.Result.Count);
  key := '4Qkev8aNZcqFNSRhQzwyLMFSsi94jHqE8WNVTJzTP99F';
  AssertTrue(res.Result.ContainsKey(key), 'Expected identity key not present');

  AssertEquals(7, res.Result.Items[key].Count);
  AssertEquals(0, res.Result.Items[key][0]);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientLeaderScheduleTests.TestGetLeaderSchedule_IdentityArgsRequest;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  res: IRequestResult<TDictionary<string, TList<UInt64>>>;
  key: string;
begin
  responseData := LoadTestData('LeaderSchedule/GetLeaderScheduleResponse.json');
  requestData  := LoadTestData('LeaderSchedule/GetLeaderScheduleIdentityArgsRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetLeaderSchedule(0, 'Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(res.Result <> nil);
  AssertTrue(res.WasSuccessful);

  AssertEquals(2, res.Result.Count);
  key := '4Qkev8aNZcqFNSRhQzwyLMFSsi94jHqE8WNVTJzTP99F';
  AssertTrue(res.Result.ContainsKey(key));

  AssertEquals(7, res.Result.Items[key].Count);
  AssertEquals(0, res.Result.Items[key][0]);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientLeaderScheduleTests.TestGetLeaderSchedule_SlotIdentityArgsRequest;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  res: IRequestResult<TDictionary<string, TList<UInt64>>>;
  key: string;
begin
  responseData := LoadTestData('LeaderSchedule/GetLeaderScheduleResponse.json');
  requestData  := LoadTestData('LeaderSchedule/GetLeaderScheduleSlotIdentityArgsRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetLeaderSchedule(79700000, 'Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(res.Result <> nil);
  AssertTrue(res.WasSuccessful);

  AssertEquals(2, res.Result.Count);
  key := '4Qkev8aNZcqFNSRhQzwyLMFSsi94jHqE8WNVTJzTP99F';
  AssertTrue(res.Result.ContainsKey(key));

  AssertEquals(7, res.Result.Items[key].Count);
  AssertEquals(0, res.Result.Items[key][0]);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientLeaderScheduleTests.TestGetLeaderSchedule_NoArgsRequest;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  res: IRequestResult<TDictionary<string, TList<UInt64>>>;
  key: string;
begin
  responseData := LoadTestData('LeaderSchedule/GetLeaderScheduleResponse.json');
  requestData  := LoadTestData('LeaderSchedule/GetLeaderScheduleNoArgsRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  res := rpcClient.GetLeaderSchedule;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(res.Result <> nil);
  AssertTrue(res.WasSuccessful);

  AssertEquals(2, res.Result.Count);
  key := '4Qkev8aNZcqFNSRhQzwyLMFSsi94jHqE8WNVTJzTP99F';
  AssertTrue(res.Result.ContainsKey(key));

  AssertEquals(7, res.Result.Items[key].Count);
  AssertEquals(0, res.Result.Items[key][0]);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientLeaderScheduleTests.TestGetLeaderSchedule_CommitmentFinalizedRequest;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TDictionary<string, TList<UInt64>>>;
  key: string;
begin
  responseData := LoadTestData('LeaderSchedule/GetLeaderScheduleResponse.json');
  requestData  := LoadTestData('LeaderSchedule/GetLeaderScheduleNoArgsRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetLeaderSchedule(0, '', TCommitment.Finalized);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil);
  AssertTrue(result.WasSuccessful);

  AssertEquals(2, result.Result.Count);
  key := '4Qkev8aNZcqFNSRhQzwyLMFSsi94jHqE8WNVTJzTP99F';
  AssertTrue(result.Result.ContainsKey(key));

  AssertEquals(7, result.Result.Items[key].Count);
  AssertEquals(0, result.Result.Items[key][0]);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientLeaderScheduleTests.TestGetLeaderSchedule_CommitmentProcessedRequest;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TDictionary<string, TList<UInt64>>>;
  key: string;
begin
  responseData := LoadTestData('LeaderSchedule/GetLeaderScheduleResponse.json');
  requestData  := LoadTestData('LeaderSchedule/GetLeaderScheduleProcessedRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetLeaderSchedule(0, '', TCommitment.Processed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil);
  AssertTrue(result.WasSuccessful);

  AssertEquals(2, result.Result.Count);
  key := '4Qkev8aNZcqFNSRhQzwyLMFSsi94jHqE8WNVTJzTP99F';
  AssertTrue(result.Result.ContainsKey(key));

  AssertEquals(7, result.Result.Items[key].Count);
  AssertEquals(UInt64(0), result.Result.Items[key][0]);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientLeaderScheduleTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientLeaderScheduleTests.Suite);
{$ENDIF}

end.
