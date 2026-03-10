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

unit SolanaRpcClientInflationTests;

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
  SlpRpcModel,
  SlpRequestResult,
  SlpSolanaRpcClient,
  RpcClientMocks,
  SolLibRpcClientTestCase;

type
  TSolanaRpcClientInflationTests = class(TSolLibRpcClientTestCase)
  published
    procedure TestGetInflationGovernor;
    procedure TestGetInflationGovernorConfirmed;
    procedure TestGetInflationRate;
    procedure TestGetInflationReward;
    procedure TestGetInflationRewardProcessed;
    procedure TestGetInflationRewardNoEpoch;
  end;

implementation

{ TSolanaRpcClientInflationTests }

procedure TSolanaRpcClientInflationTests.TestGetInflationGovernor;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TInflationGovernor>;
begin
  LResponseData := LoadTestData('Inflation/GetInflationGovernorResponse.json');
  LRequestData := LoadTestData('Inflation/GetInflationGovernorRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetInflationGovernor;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  AssertEquals(0.05,  LResult.Result.Foundation);
  AssertEquals(7,     LResult.Result.FoundationTerm);
  AssertEquals(0.15,  LResult.Result.Initial);
  AssertEquals(0.15,  LResult.Result.Taper);
  AssertEquals(0.015, LResult.Result.Terminal);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientInflationTests.TestGetInflationGovernorConfirmed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TInflationGovernor>;
begin
  LResponseData := LoadTestData('Inflation/GetInflationGovernorResponse.json');
  LRequestData := LoadTestData('Inflation/GetInflationGovernorConfirmedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetInflationGovernor(TCommitment.Confirmed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  AssertEquals(0.05,  LResult.Result.Foundation);
  AssertEquals(7,     LResult.Result.FoundationTerm);
  AssertEquals(0.15,  LResult.Result.Initial);
  AssertEquals(0.15,  LResult.Result.Taper);
  AssertEquals(0.015, LResult.Result.Terminal);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientInflationTests.TestGetInflationRate;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TInflationRate>;
begin
  LResponseData := LoadTestData('Inflation/GetInflationRateResponse.json');
  LRequestData := LoadTestData('Inflation/GetInflationRateRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetInflationRate;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  AssertEquals(100,   LResult.Result.Epoch);
  AssertEquals(0.149, LResult.Result.Total, 0.0);
  AssertEquals(0.148, LResult.Result.Validator, 0.0);
  AssertEquals(0.001, LResult.Result.Foundation, 0.0);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientInflationTests.TestGetInflationReward;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LAddrs: TArray<string>;
  LResult: IRequestResult<TObjectList<TInflationReward>>;
begin
  LResponseData := LoadTestData('Inflation/GetInflationRewardResponse.json');
  LRequestData := LoadTestData('Inflation/GetInflationRewardRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LAddrs := TArray<string>.Create(
    '6dmNQ5jwLeLk5REvio1JcMshcbvkYMwy26sJ8pbkvStu',
    'BGsqMegLpV6n6Ve146sSX2dTjUMj3M92HnU8BbNRMhF2'
  );

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetInflationReward(LAddrs, 2);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result list should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  AssertEquals(2, LResult.Result.Count);
  AssertEquals(2500,         LResult.Result[0].Amount);
  AssertEquals(224,          LResult.Result[0].EffectiveSlot);
  AssertEquals(2,            LResult.Result[0].Epoch);
  AssertEquals(499999442500, LResult.Result[0].PostBalance);
  AssertTrue(LResult.Result[1] = nil, 'Second item should be nil');

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientInflationTests.TestGetInflationRewardProcessed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LAddrs: TArray<string>;
  LResult: IRequestResult<TObjectList<TInflationReward>>;
begin
  LResponseData := LoadTestData('Inflation/GetInflationRewardResponse.json');
  LRequestData := LoadTestData('Inflation/GetInflationRewardProcessedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LAddrs := TArray<string>.Create(
    '6dmNQ5jwLeLk5REvio1JcMshcbvkYMwy26sJ8pbkvStu',
    'BGsqMegLpV6n6Ve146sSX2dTjUMj3M92HnU8BbNRMhF2'
  );

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetInflationReward(LAddrs, 2, TCommitment.Processed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result list should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  AssertEquals(2, LResult.Result.Count);
  AssertEquals(2500,         LResult.Result[0].Amount);
  AssertEquals(224,          LResult.Result[0].EffectiveSlot);
  AssertEquals(2,            LResult.Result[0].Epoch);
  AssertEquals(499999442500, LResult.Result[0].PostBalance);
  AssertTrue(LResult.Result[1] = nil, 'Second item should be nil');

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientInflationTests.TestGetInflationRewardNoEpoch;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LAddrs: TArray<string>;
  LResult: IRequestResult<TObjectList<TInflationReward>>;
begin
  LResponseData := LoadTestData('Inflation/GetInflationRewardNoEpochResponse.json');
  LRequestData := LoadTestData('Inflation/GetInflationRewardNoEpochRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LAddrs := TArray<string>.Create(
    '25xzEf8cqLLEm2wyZTEBtCDchsUFm3SVESjs6eEFHJWe',
    'GPQdoUUDQXM1gWgRVwBbYmDqAgxoZN3bhVeKr1P8jd4c'
  );

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetInflationReward(LAddrs);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result list should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  AssertEquals(2, LResult.Result.Count);
  AssertEquals(1758149777313, LResult.Result[0].Amount);
  AssertEquals(81216004,      LResult.Result[0].EffectiveSlot);
  AssertEquals(187,           LResult.Result[0].Epoch);
  AssertEquals(1759149777313, LResult.Result[0].PostBalance);
  AssertTrue(LResult.Result[1] = nil, 'Second item should be nil');

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientInflationTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientInflationTests.Suite);
{$ENDIF}

end.
