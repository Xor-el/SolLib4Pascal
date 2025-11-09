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

unit SolLibFlagProgramTestCase;

interface

uses
  System.Rtti,
  SolLibProgramTestCase;

type
  TSolLibFlagProgramTestCase = class abstract(TSolLibProgramTestCase)
  protected
    var
     FRttiContext: TRttiContext;

    procedure SetUp; override;
    procedure TearDown; override;
  end;

implementation

procedure TSolLibFlagProgramTestCase.SetUp;
begin
  inherited;
  FRttiContext := TRttiContext.Create;
end;

procedure TSolLibFlagProgramTestCase.TearDown;
begin
  FRttiContext.Free;
  inherited;
end;

end.

