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

unit SolLibRpcHttpMockTestCase;

interface

uses
  SysUtils,
  StrUtils,
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
      const AResponseContent: string;
      AStatusCode: Integer = 200;
      const AStatusText: string = ''
    ): TMockRpcHttpClient;

    function SetupTestForThrow(
      const AStatusText: string = ''
    ): TMockRpcHttpClient;

    procedure FinishTest(const AMock: TMockRpcHttpClient; const AExpectedUrl: string; const AExpectedCallCount: Integer = 1);
  end;

implementation

function TSolLibRpcHttpMockTestCase.SetupTest(const AResponseContent: string; AStatusCode: Integer;
  const AStatusText: string
): TMockRpcHttpClient;
begin
  Result := TMockRpcHttpClient.Create(TestnetUrl, AStatusCode, AStatusText, AResponseContent);
end;

function TSolLibRpcHttpMockTestCase.SetupTestForThrow(const AStatusText: string
): TMockRpcHttpClient;
begin
  Result := TMockRpcHttpClient.CreateForThrow(TestnetUrl, AStatusText);
end;

procedure TSolLibRpcHttpMockTestCase.FinishTest(
  const AMock: TMockRpcHttpClient; const AExpectedUrl: string; const AExpectedCallCount: Integer);
begin
  AssertEquals(AExpectedCallCount, AMock.CallCount,
  Format('Exactly %d Hit%s expected',
    [AExpectedCallCount, IfThen(AExpectedCallCount <> 1, 's', '')]));

  AssertEquals(TURI.Create(AExpectedUrl).ToString, AMock.LastUrl, 'URL mismatch');
end;

end.

