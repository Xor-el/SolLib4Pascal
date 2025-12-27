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
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<UInt64>>;
  msg: string;
begin
  responseData := LoadTestData('Fees/GetFeeForMessageResponse.json');
  requestData  := LoadTestData('Fees/GetFeeForMessageRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  msg :=
    'AQABAu+OVfa66vZfLI0xdX9GcGk/+U65+dox+iHABM3DOSGuBUpTWpkpIQZNJOhxYNo4fHw1td28kruB5B+oQEEFRI3tj0g2caCBX14VjqrxK4Daz/4WvmWxU698Okvp8lYDjAEBACNIZWxsbyBTb2xhbmEgV29ybGQsIHVzaW5nIFNvbG5ldCA6KQ==';

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetFeeForMessage(msg);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertEquals(132177311, result.Result.Context.Slot);
  AssertEquals(5000, result.Result.Value);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientFeeTests.TestGetRecentPrioritizationFees;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TObjectList<TPrioritizationFeeItem>>;
  accounts: TArray<string>;
begin
  responseData := LoadTestData('Fees/GetRecentPrioritizationFeesResponse.json');
  requestData := LoadTestData('Fees/GetRecentPrioritizationFeesRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  accounts := TArray<string>.Create(
    'CxELquR1gPP8wHe33gZ4QxqGB3sZ9RSwsJ2KshVewkFY',
    'BQ72nSv9f3PRyRKCBnHLVrerrv37CYTHm5h3s9VSGQDV'
  );

  result := rpcClient.GetRecentPrioritizationFees(accounts);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');

  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');
  AssertTrue(result.Result.Count > 0, 'Expected at least one fee item');
  AssertTrue(result.Result[0] <> nil, 'First item should not be nil');

  AssertEquals(259311457, result.Result[0].Slot);
  AssertEquals(0, result.Result[0].PrioritizationFee);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientFeeTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientFeeTests.Suite);
{$ENDIF}

end.

