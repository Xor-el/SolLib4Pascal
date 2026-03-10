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
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TDictionary<string, TList<UInt64>>>;
  LKey: string;
begin
  LResponseData := LoadTestData('LeaderSchedule/GetLeaderScheduleResponse.json');
  LRequestData  := LoadTestData('LeaderSchedule/GetLeaderScheduleSlotArgsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetLeaderSchedule(79700000);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LRes.Result <> nil, 'Result should not be nil');
  AssertTrue(LRes.WasSuccessful, 'Should be successful');

  AssertEquals(2, LRes.Result.Count);
  LKey := '4Qkev8aNZcqFNSRhQzwyLMFSsi94jHqE8WNVTJzTP99F';
  AssertTrue(LRes.Result.ContainsKey(LKey), 'Expected identity key not present');

  AssertEquals(7, LRes.Result.Items[LKey].Count);
  AssertEquals(0, LRes.Result.Items[LKey][0]);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientLeaderScheduleTests.TestGetLeaderSchedule_IdentityArgsRequest;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TDictionary<string, TList<UInt64>>>;
  LKey: string;
begin
  LResponseData := LoadTestData('LeaderSchedule/GetLeaderScheduleResponse.json');
  LRequestData  := LoadTestData('LeaderSchedule/GetLeaderScheduleIdentityArgsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetLeaderSchedule(0, 'Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LRes.Result <> nil);
  AssertTrue(LRes.WasSuccessful);

  AssertEquals(2, LRes.Result.Count);
  LKey := '4Qkev8aNZcqFNSRhQzwyLMFSsi94jHqE8WNVTJzTP99F';
  AssertTrue(LRes.Result.ContainsKey(LKey));

  AssertEquals(7, LRes.Result.Items[LKey].Count);
  AssertEquals(0, LRes.Result.Items[LKey][0]);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientLeaderScheduleTests.TestGetLeaderSchedule_SlotIdentityArgsRequest;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TDictionary<string, TList<UInt64>>>;
  LKey: string;
begin
  LResponseData := LoadTestData('LeaderSchedule/GetLeaderScheduleResponse.json');
  LRequestData  := LoadTestData('LeaderSchedule/GetLeaderScheduleSlotIdentityArgsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetLeaderSchedule(79700000, 'Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LRes.Result <> nil);
  AssertTrue(LRes.WasSuccessful);

  AssertEquals(2, LRes.Result.Count);
  LKey := '4Qkev8aNZcqFNSRhQzwyLMFSsi94jHqE8WNVTJzTP99F';
  AssertTrue(LRes.Result.ContainsKey(LKey));

  AssertEquals(7, LRes.Result.Items[LKey].Count);
  AssertEquals(0, LRes.Result.Items[LKey][0]);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientLeaderScheduleTests.TestGetLeaderSchedule_NoArgsRequest;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LRes: IRequestResult<TDictionary<string, TList<UInt64>>>;
  LKey: string;
begin
  LResponseData := LoadTestData('LeaderSchedule/GetLeaderScheduleResponse.json');
  LRequestData  := LoadTestData('LeaderSchedule/GetLeaderScheduleNoArgsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LRes := LRpcClient.GetLeaderSchedule;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LRes.Result <> nil);
  AssertTrue(LRes.WasSuccessful);

  AssertEquals(2, LRes.Result.Count);
  LKey := '4Qkev8aNZcqFNSRhQzwyLMFSsi94jHqE8WNVTJzTP99F';
  AssertTrue(LRes.Result.ContainsKey(LKey));

  AssertEquals(7, LRes.Result.Items[LKey].Count);
  AssertEquals(0, LRes.Result.Items[LKey][0]);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientLeaderScheduleTests.TestGetLeaderSchedule_CommitmentFinalizedRequest;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TDictionary<string, TList<UInt64>>>;
  LKey: string;
begin
  LResponseData := LoadTestData('LeaderSchedule/GetLeaderScheduleResponse.json');
  LRequestData  := LoadTestData('LeaderSchedule/GetLeaderScheduleNoArgsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetLeaderSchedule(0, '', TCommitment.Finalized);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(2, LResult.Result.Count);
  LKey := '4Qkev8aNZcqFNSRhQzwyLMFSsi94jHqE8WNVTJzTP99F';
  AssertTrue(LResult.Result.ContainsKey(LKey));

  AssertEquals(7, LResult.Result.Items[LKey].Count);
  AssertEquals(0, LResult.Result.Items[LKey][0]);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientLeaderScheduleTests.TestGetLeaderSchedule_CommitmentProcessedRequest;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TDictionary<string, TList<UInt64>>>;
  LKey: string;
begin
  LResponseData := LoadTestData('LeaderSchedule/GetLeaderScheduleResponse.json');
  LRequestData  := LoadTestData('LeaderSchedule/GetLeaderScheduleProcessedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetLeaderSchedule(0, '', TCommitment.Processed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(2, LResult.Result.Count);
  LKey := '4Qkev8aNZcqFNSRhQzwyLMFSsi94jHqE8WNVTJzTP99F';
  AssertTrue(LResult.Result.ContainsKey(LKey));

  AssertEquals(7, LResult.Result.Items[LKey].Count);
  AssertEquals(UInt64(0), LResult.Result.Items[LKey][0]);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientLeaderScheduleTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientLeaderScheduleTests.Suite);
{$ENDIF}

end.
