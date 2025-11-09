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

unit ClientFactoryTests;

interface

uses
{$IFDEF FPC}
  testregistry,
  URIParser,
{$ELSE}
  System.Net.URLClient,
  TestFramework,
{$ENDIF}
  SlpSolanaRpcClient,
  SlpClientFactory,
  SlpRpcEnum,
  SlpHttpApiClient,
  RpcClientMocks,
  SolLibRpcClientTestCase;

type
  TClientFactoryTests = class(TSolLibRpcClientTestCase)
  published
    procedure TestBuildRpcClient;
    procedure TestBuildRpcClientFromString;
  end;

implementation

{ TClientFactoryTests }

procedure TClientFactoryTests.TestBuildRpcClient;
var
  C: IRpcClient;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
begin
  mockRpcHttpClient := SetupTest('', 200);
  rpcHttpClient := mockRpcHttpClient;
  C := TClientFactory.GetClient(TCluster.DevNet, rpcHttpClient);
  AssertNotNull(C, 'GetClient(TCluster.DevNet) should return a client instance');
end;

procedure TClientFactoryTests.TestBuildRpcClientFromString;
var
  C: IRpcClient;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
begin
  mockRpcHttpClient := SetupTest('', 200);
  rpcHttpClient := mockRpcHttpClient;
  C := TClientFactory.GetClient(TestnetUrl, rpcHttpClient);
  AssertNotNull(C, 'GetClient(url) should return a client instance');
  AssertEquals(TURI.Create(TestnetUrl).ToString, C.NodeAddress.ToString, 'NodeAddress mismatch');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TClientFactoryTests);
{$ELSE}
  RegisterTest(TClientFactoryTests.Suite);
{$ENDIF}

end.

