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

unit SolLibRpcHttpMockTestCase;

interface

uses
  System.SysUtils,
  System.StrUtils,
{$IFDEF FPC}
  URIParser,
{$ELSE}
  System.Net.URLClient,
{$ENDIF}
  RpcClientMocks,
  SolLibTestCase;

type
  TSolLibRpcHttpMockTestCase = class abstract(TSolLibTestCase)
  protected
    const TestnetUrl = 'https://api.testnet.solana.com';

    function SetupTest(
      const ResponseContent: string;
      StatusCode: Integer = 200;
      const StatusText: string = ''
    ): TMockRpcHttpClient;

    function SetupTestForThrow(
      const StatusText: string = ''
    ): TMockRpcHttpClient;

    procedure FinishTest(const Mock: TMockRpcHttpClient; const ExpectedUrl: string; const ExpectedCallCount: Integer = 1);
  end;

implementation

function TSolLibRpcHttpMockTestCase.SetupTest(const ResponseContent: string; StatusCode: Integer;
  const StatusText: string
): TMockRpcHttpClient;
begin
  Result := TMockRpcHttpClient.Create(TestnetUrl, StatusCode, StatusText, ResponseContent);
end;

function TSolLibRpcHttpMockTestCase.SetupTestForThrow(const StatusText: string
): TMockRpcHttpClient;
begin
  Result := TMockRpcHttpClient.CreateForThrow(TestnetUrl, StatusText);
end;

procedure TSolLibRpcHttpMockTestCase.FinishTest(
  const Mock: TMockRpcHttpClient; const ExpectedUrl: string; const ExpectedCallCount: Integer);
begin
  AssertEquals(ExpectedCallCount, Mock.CallCount,
  Format('Exactly %d Hit%s expected',
    [ExpectedCallCount, IfThen(ExpectedCallCount <> 1, 's', '')]));

  AssertEquals(TURI.Create(ExpectedUrl).ToString, Mock.LastUrl, 'URL mismatch');
end;

end.

