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

unit SolLibStreamingRpcClientTestCase;

interface

uses
  System.SysUtils,
  TestUtils,
  SolLibRpcSocketMockTestCase;

type
  TSolLibStreamingRpcClientTestCase = class abstract(TSolLibRpcSocketMockTestCase)
  protected
    var
     FResDir: string;

    function ResDir: string;

    procedure SetUp; override;
    procedure TearDown; override;
  end;

implementation

procedure TSolLibStreamingRpcClientTestCase.SetUp;
begin
  inherited;
  FResDir := ResDir;
end;

procedure TSolLibStreamingRpcClientTestCase.TearDown;
begin
  FResDir := '';
  inherited;
end;

function TSolLibStreamingRpcClientTestCase.ResDir: string;
begin
  // Marker already points to the exact resources folder → suffix empty
  Result := TTestUtils.GetSourceDirWithSuffix('src\Resources\Rpc', 'Streaming');
  // Marker is the project folder we can reliably find on the way up
  //Result := TTestUtils.GetSourceDirWithSuffix('SolLib.Tests', 'src\Resources\Rpc\Streaming');
end;

end.

