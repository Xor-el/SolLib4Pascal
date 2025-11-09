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

unit ComputeBudgetProgramTests;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpTransactionInstruction,
  SlpComputeBudgetProgram,
  SolLibProgramTestCase;

type
  TComputeBudgetProgramTests = class(TSolLibProgramTestCase)
  private
    class function ComputeBudgetProgramIdBytes: TBytes; static;
    class function RequestHeapFrameInstructionBytes: TBytes; static;
    class function SetComputeUnitLimitInstructionBytes: TBytes; static;
    class function SetComputeUnitPriceInstructionBytes: TBytes; static;
    class function SetLoadedAccountsDataSizeLimitInstructionBytes: TBytes; static;
  published
    procedure TestComputeBudgetProgramRequestHeapFrame;
    procedure TestComputeBudgetProgramSetComputeUnitLimit;
    procedure TestComputeBudgetProgramSetComputeUnitPrice;
    procedure TestComputeBudgetProgramSetLoadedAccountsDataSizeLimit;
  end;

implementation

{ TComputeBudgetProgramTests }

class function TComputeBudgetProgramTests.ComputeBudgetProgramIdBytes: TBytes;
begin
  Result := TBytes.Create(
    3, 6, 70, 111, 229, 33, 23, 50, 255, 236, 173, 186, 114, 195, 155, 231,
    188, 140, 229, 187, 197, 247, 18, 107, 44, 67, 155, 58, 64, 0, 0, 0
  );
end;

class function TComputeBudgetProgramTests.RequestHeapFrameInstructionBytes: TBytes;
begin
  Result := TBytes.Create(
    1, 0, 128, 0, 0
  );
end;

class function TComputeBudgetProgramTests.SetComputeUnitLimitInstructionBytes: TBytes;
begin
  Result := TBytes.Create(
    2, 64, 13, 3, 0
  );
end;

class function TComputeBudgetProgramTests.SetComputeUnitPriceInstructionBytes: TBytes;
begin
  Result := TBytes.Create(
    3, 160, 134, 1, 0, 0, 0, 0, 0
  );
end;

class function TComputeBudgetProgramTests.SetLoadedAccountsDataSizeLimitInstructionBytes: TBytes;
begin
  Result := TBytes.Create(
    4, 48, 87, 5, 0
  );
end;

procedure TComputeBudgetProgramTests.TestComputeBudgetProgramRequestHeapFrame;
var
  Tx: ITransactionInstruction;
begin
  Tx := TComputeBudgetProgram.RequestHeapFrame(32768);
  AssertEquals(0, Tx.Keys.Count, 'Keys.Count');
  AssertEquals<Byte>(RequestHeapFrameInstructionBytes, Tx.Data, 'Data');
  AssertEquals<Byte>(ComputeBudgetProgramIdBytes,      Tx.ProgramId, 'ProgramId');
end;

procedure TComputeBudgetProgramTests.TestComputeBudgetProgramSetComputeUnitLimit;
var
  Tx: ITransactionInstruction;
begin
  Tx := TComputeBudgetProgram.SetComputeUnitLimit(200000);
  AssertEquals(0, Tx.Keys.Count, 'Keys.Count');
  AssertEquals<Byte>(SetComputeUnitLimitInstructionBytes, Tx.Data, 'Data');
  AssertEquals<Byte>(ComputeBudgetProgramIdBytes,         Tx.ProgramId, 'ProgramId');
end;

procedure TComputeBudgetProgramTests.TestComputeBudgetProgramSetComputeUnitPrice;
var
  Tx: ITransactionInstruction;
begin
  Tx := TComputeBudgetProgram.SetComputeUnitPrice(100000);
  AssertEquals(0, Tx.Keys.Count, 'Keys.Count');
  AssertEquals<Byte>(SetComputeUnitPriceInstructionBytes, Tx.Data, 'Data');
  AssertEquals<Byte>(ComputeBudgetProgramIdBytes,         Tx.ProgramId, 'ProgramId');
end;

procedure TComputeBudgetProgramTests.TestComputeBudgetProgramSetLoadedAccountsDataSizeLimit;
var
  Tx: ITransactionInstruction;
begin
  Tx := TComputeBudgetProgram.SetLoadedAccountsDataSizeLimit(350000);
  AssertEquals(0, Tx.Keys.Count, 'Keys.Count');
  AssertEquals<Byte>(SetLoadedAccountsDataSizeLimitInstructionBytes, Tx.Data, 'Data');
  AssertEquals<Byte>(ComputeBudgetProgramIdBytes,                    Tx.ProgramId, 'ProgramId');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TComputeBudgetProgramTests);
{$ELSE}
  RegisterTest(TComputeBudgetProgramTests.Suite);
{$ENDIF}

end.

