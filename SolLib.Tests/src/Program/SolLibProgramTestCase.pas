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

unit SolLibProgramTestCase;

interface

uses
  System.SysUtils,
  System.Rtti,
  TestResourceLoader,
  SolLibTestCase;

type
  TSolLibProgramTestCase = class abstract(TSolLibTestCase)
  protected
    var
     FRttiContext: TRttiContext;
     FResCategory: string;

    function ResPath(const ASubPath: string): string;
    function LoadTestData(const ASubPath: string): string;

    procedure SetUp; override;
    procedure TearDown; override;
  end;

implementation

procedure TSolLibProgramTestCase.SetUp;
begin
  inherited;
  FRttiContext := TRttiContext.Create;
  FResCategory := 'Program';
end;

procedure TSolLibProgramTestCase.TearDown;
begin
  FRttiContext.Free;
  FResCategory := '';
  inherited;
end;

function TSolLibProgramTestCase.ResPath(const ASubPath: string): string;
begin
  Result := FResCategory + '/' + ASubPath;
end;

function TSolLibProgramTestCase.LoadTestData(const ASubPath: string): string;
begin
  Result := TTestResourceLoader.LoadTestData(ResPath(ASubPath));
end;

end.
