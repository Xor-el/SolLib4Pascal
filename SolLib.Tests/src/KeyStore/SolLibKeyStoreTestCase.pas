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

unit SolLibKeyStoreTestCase;

interface

uses
  System.SysUtils,
  TestResourceLoader,
  SolLibTestCase;

type
  TSolLibKeyStoreTestCase = class abstract(TSolLibTestCase)
  protected
    var
     FResCategory: string;

    function ResPath(const AFileName: string): string;
    function LoadTestData(const AFileName: string): string;

    procedure SetUp; override;
    procedure TearDown; override;
  end;

implementation

procedure TSolLibKeyStoreTestCase.SetUp;
begin
  inherited;
  FResCategory := 'KeyStore';
end;

procedure TSolLibKeyStoreTestCase.TearDown;
begin
  FResCategory := '';
  inherited;
end;

function TSolLibKeyStoreTestCase.ResPath(const AFileName: string): string;
begin
  Result := FResCategory + '/' + AFileName;
end;

function TSolLibKeyStoreTestCase.LoadTestData(const AFileName: string): string;
begin
  Result := TTestResourceLoader.LoadTestData(ResPath(AFileName));
end;

end.

