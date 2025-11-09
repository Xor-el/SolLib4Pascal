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

unit SolLibProgramTestCase;

interface

uses
  System.SysUtils,
  System.Rtti,
  TestUtils,
  SolLibTestCase;

type
  TSolLibProgramTestCase = class abstract(TSolLibTestCase)
  protected
    var
     FRttiContext: TRttiContext;
     FResDir: string;

    function ResDir: string;

    procedure SetUp; override;
    procedure TearDown; override;
  end;

implementation

procedure TSolLibProgramTestCase.SetUp;
begin
  inherited;
  FRttiContext := TRttiContext.Create;
  FResDir := ResDir;
end;

procedure TSolLibProgramTestCase.TearDown;
begin
  FRttiContext.Free;
  FResDir := '';
  inherited;
end;

function TSolLibProgramTestCase.ResDir: string;
begin
  // Marker already points to the exact resources folder → suffix empty
  Result := TTestUtils.GetSourceDirWithSuffix('src\Resources\Program', '');
  // Marker is the project folder we can reliably find on the way up
  //Result := TTestUtils.GetSourceDirWithSuffix('SolLib.Tests', 'src\Resources\Program');
end;

end.

