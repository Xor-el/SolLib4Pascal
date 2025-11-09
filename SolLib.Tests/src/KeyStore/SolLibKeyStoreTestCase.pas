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

unit SolLibKeyStoreTestCase;

interface

uses
  System.SysUtils,
  TestUtils,
  SolLibTestCase;

type
  TSolLibKeyStoreTestCase = class abstract(TSolLibTestCase)
  protected
    var
     FResDir: string;

    function ResDir: string;

    procedure SetUp; override;
    procedure TearDown; override;
  end;

implementation

procedure TSolLibKeyStoreTestCase.SetUp;
begin
  inherited;
  FResDir := ResDir;
end;

procedure TSolLibKeyStoreTestCase.TearDown;
begin
  FResDir := '';
  inherited;
end;

function TSolLibKeyStoreTestCase.ResDir: string;
begin
  // Marker already points to the exact resources folder → suffix empty
  Result := TTestUtils.GetSourceDirWithSuffix('src\Resources\KeyStore', '');
  // Marker is the project folder we can reliably find on the way up
  //Result := TTestUtils.GetSourceDirWithSuffix('SolLib.Tests', 'src\Resources\KeyStore');
end;

end.

