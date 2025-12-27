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

unit SolLibTokenTestCase;

interface

uses
  System.SysUtils,
  TestResourceLoader,
  SolLibRpcHttpMockTestCase;

type
  TSolLibTokenTestCase = class abstract(TSolLibRpcHttpMockTestCase)
  protected
    var
     FResCategory: string;

    function ResPath(const ASubPath: string): string;
    function LoadTestData(const ASubPath: string): string;

    procedure SetUp; override;
    procedure TearDown; override;
  end;

implementation

procedure TSolLibTokenTestCase.SetUp;
begin
  inherited;
  FResCategory := 'Token';
end;

procedure TSolLibTokenTestCase.TearDown;
begin
  FResCategory := '';
  inherited;
end;

function TSolLibTokenTestCase.ResPath(const ASubPath: string): string;
begin
  Result := FResCategory + '/' + ASubPath;
end;

function TSolLibTokenTestCase.LoadTestData(const ASubPath: string): string;
begin
  Result := TTestResourceLoader.LoadTestData(ResPath(ASubPath));
end;

end.
