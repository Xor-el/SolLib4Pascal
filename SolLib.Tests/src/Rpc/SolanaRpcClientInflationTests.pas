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
  TestUtils,
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
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TInflationGovernor>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Inflation', 'GetInflationGovernorResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Inflation', 'GetInflationGovernorRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetInflationGovernor;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  AssertEquals(0.05,  result.Result.Foundation);
  AssertEquals(7,     result.Result.FoundationTerm);
  AssertEquals(0.15,  result.Result.Initial);
  AssertEquals(0.15,  result.Result.Taper);
  AssertEquals(0.015, result.Result.Terminal);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientInflationTests.TestGetInflationGovernorConfirmed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TInflationGovernor>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Inflation', 'GetInflationGovernorResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Inflation', 'GetInflationGovernorConfirmedRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetInflationGovernor(TCommitment.Confirmed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  AssertEquals(0.05,  result.Result.Foundation);
  AssertEquals(7,     result.Result.FoundationTerm);
  AssertEquals(0.15,  result.Result.Initial);
  AssertEquals(0.15,  result.Result.Taper);
  AssertEquals(0.015, result.Result.Terminal);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientInflationTests.TestGetInflationRate;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TInflationRate>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Inflation', 'GetInflationRateResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Inflation', 'GetInflationRateRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetInflationRate;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  AssertEquals(100,   result.Result.Epoch);
  AssertEquals(0.149, result.Result.Total, 0.0);
  AssertEquals(0.148, result.Result.Validator, 0.0);
  AssertEquals(0.001, result.Result.Foundation, 0.0);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientInflationTests.TestGetInflationReward;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  addrs: TArray<string>;
  result: IRequestResult<TObjectList<TInflationReward>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Inflation', 'GetInflationRewardResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Inflation', 'GetInflationRewardRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  addrs := TArray<string>.Create(
    '6dmNQ5jwLeLk5REvio1JcMshcbvkYMwy26sJ8pbkvStu',
    'BGsqMegLpV6n6Ve146sSX2dTjUMj3M92HnU8BbNRMhF2'
  );

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetInflationReward(addrs, 2);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result list should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  AssertEquals(2, result.Result.Count);
  AssertEquals(2500,         result.Result[0].Amount);
  AssertEquals(224,          result.Result[0].EffectiveSlot);
  AssertEquals(2,            result.Result[0].Epoch);
  AssertEquals(499999442500, result.Result[0].PostBalance);
  AssertTrue(result.Result[1] = nil, 'Second item should be nil');

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientInflationTests.TestGetInflationRewardProcessed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  addrs: TArray<string>;
  result: IRequestResult<TObjectList<TInflationReward>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Inflation', 'GetInflationRewardResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Inflation', 'GetInflationRewardProcessedRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  addrs := TArray<string>.Create(
    '6dmNQ5jwLeLk5REvio1JcMshcbvkYMwy26sJ8pbkvStu',
    'BGsqMegLpV6n6Ve146sSX2dTjUMj3M92HnU8BbNRMhF2'
  );

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetInflationReward(addrs, 2, TCommitment.Processed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result list should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  AssertEquals(2, result.Result.Count);
  AssertEquals(2500,         result.Result[0].Amount);
  AssertEquals(224,          result.Result[0].EffectiveSlot);
  AssertEquals(2,            result.Result[0].Epoch);
  AssertEquals(499999442500, result.Result[0].PostBalance);
  AssertTrue(result.Result[1] = nil, 'Second item should be nil');

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientInflationTests.TestGetInflationRewardNoEpoch;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  addrs: TArray<string>;
  result: IRequestResult<TObjectList<TInflationReward>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Inflation', 'GetInflationRewardNoEpochResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Inflation', 'GetInflationRewardNoEpochRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  addrs := TArray<string>.Create(
    '25xzEf8cqLLEm2wyZTEBtCDchsUFm3SVESjs6eEFHJWe',
    'GPQdoUUDQXM1gWgRVwBbYmDqAgxoZN3bhVeKr1P8jd4c'
  );

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetInflationReward(addrs);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result list should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  AssertEquals(2, result.Result.Count);
  AssertEquals(1758149777313, result.Result[0].Amount);
  AssertEquals(81216004,      result.Result[0].EffectiveSlot);
  AssertEquals(187,           result.Result[0].Epoch);
  AssertEquals(1759149777313, result.Result[0].PostBalance);
  AssertTrue(result.Result[1] = nil, 'Second item should be nil');

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientInflationTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientInflationTests.Suite);
{$ENDIF}

end.
