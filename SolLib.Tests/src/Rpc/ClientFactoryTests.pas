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
  LRpcClient: IRpcClient;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
begin
  LMockRpcHttpClient := SetupTest('', 200);
  LRpcHttpClient := LMockRpcHttpClient;
  LRpcClient := TClientFactory.GetClient(TCluster.DevNet, LRpcHttpClient);
  AssertNotNull(LRpcClient, 'GetClient(TCluster.DevNet) should return a client instance');
end;

procedure TClientFactoryTests.TestBuildRpcClientFromString;
var
  LRpcClient: IRpcClient;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
begin
  LMockRpcHttpClient := SetupTest('', 200);
  LRpcHttpClient := LMockRpcHttpClient;
  LRpcClient := TClientFactory.GetClient(TestnetUrl, LRpcHttpClient);
  AssertNotNull(LRpcClient, 'GetClient(url) should return a client instance');
  AssertEquals(TURI.Create(TestnetUrl).ToString, LRpcClient.NodeAddress.ToString, 'NodeAddress mismatch');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TClientFactoryTests);
{$ELSE}
  RegisterTest(TClientFactoryTests.Suite);
{$ENDIF}

end.

