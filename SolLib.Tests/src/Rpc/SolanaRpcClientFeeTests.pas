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

unit SolanaRpcClientFeeTests;

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
  SlpRpcMessage,
  SlpRpcModel,
  SlpRequestResult,
  SlpSolanaRpcClient,
  RpcClientMocks,
  SolLibRpcClientTestCase;

type
  TSolanaRpcClientFeeTests = class(TSolLibRpcClientTestCase)
  published
    procedure TestGetFeeForMessage;
    procedure TestGetRecentPrioritizationFees;
  end;

implementation

{ TSolanaRpcClientFeeTests }

procedure TSolanaRpcClientFeeTests.TestGetFeeForMessage;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<UInt64>>;
  LMsg: string;
begin
  LResponseData := LoadTestData('Fees/GetFeeForMessageResponse.json');
  LRequestData := LoadTestData('Fees/GetFeeForMessageRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LMsg :=
    'AQABAu+OVfa66vZfLI0xdX9GcGk/+U65+dox+iHABM3DOSGuBUpTWpkpIQZNJOhxYNo4fHw1td28kruB5B+oQEEFRI3tj0g2caCBX14VjqrxK4Daz/4WvmWxU698Okvp8lYDjAEBACNIZWxsbyBTb2xhbmEgV29ybGQsIHVzaW5nIFNvbG5ldCA6KQ==';

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetFeeForMessage(LMsg);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertEquals(132177311, LResult.Result.Context.Slot);
  AssertEquals(5000, LResult.Result.Value);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientFeeTests.TestGetRecentPrioritizationFees;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TObjectList<TPrioritizationFeeItem>>;
  LAccounts: TArray<string>;
begin
  LResponseData := LoadTestData('Fees/GetRecentPrioritizationFeesResponse.json');
  LRequestData := LoadTestData('Fees/GetRecentPrioritizationFeesRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LAccounts := TArray<string>.Create(
    'CxELquR1gPP8wHe33gZ4QxqGB3sZ9RSwsJ2KshVewkFY',
    'BQ72nSv9f3PRyRKCBnHLVrerrv37CYTHm5h3s9VSGQDV'
  );

  LResult := LRpcClient.GetRecentPrioritizationFees(LAccounts);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');

  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');
  AssertTrue(LResult.Result.Count > 0, 'Expected at least one fee item');
  AssertTrue(LResult.Result[0] <> nil, 'First item should not be nil');

  AssertEquals(259311457, LResult.Result[0].Slot);
  AssertEquals(0, LResult.Result[0].PrioritizationFee);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientFeeTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientFeeTests.Suite);
{$ENDIF}

end.

