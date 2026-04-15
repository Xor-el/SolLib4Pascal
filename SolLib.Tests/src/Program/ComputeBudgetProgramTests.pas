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

unit ComputeBudgetProgramTests;

interface

uses
  SysUtils,
  Generics.Collections,
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
  LTx: ITransactionInstruction;
begin
  LTx := TComputeBudgetProgram.RequestHeapFrame(32768);
  AssertEquals(0, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(RequestHeapFrameInstructionBytes, LTx.Data, 'Data');
  AssertEquals(ComputeBudgetProgramIdBytes,      LTx.ProgramId, 'ProgramId');
end;

procedure TComputeBudgetProgramTests.TestComputeBudgetProgramSetComputeUnitLimit;
var
  LTx: ITransactionInstruction;
begin
  LTx := TComputeBudgetProgram.SetComputeUnitLimit(200000);
  AssertEquals(0, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(SetComputeUnitLimitInstructionBytes, LTx.Data, 'Data');
  AssertEquals(ComputeBudgetProgramIdBytes,         LTx.ProgramId, 'ProgramId');
end;

procedure TComputeBudgetProgramTests.TestComputeBudgetProgramSetComputeUnitPrice;
var
  LTx: ITransactionInstruction;
begin
  LTx := TComputeBudgetProgram.SetComputeUnitPrice(100000);
  AssertEquals(0, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(SetComputeUnitPriceInstructionBytes, LTx.Data, 'Data');
  AssertEquals(ComputeBudgetProgramIdBytes,         LTx.ProgramId, 'ProgramId');
end;

procedure TComputeBudgetProgramTests.TestComputeBudgetProgramSetLoadedAccountsDataSizeLimit;
var
  LTx: ITransactionInstruction;
begin
  LTx := TComputeBudgetProgram.SetLoadedAccountsDataSizeLimit(350000);
  AssertEquals(0, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(SetLoadedAccountsDataSizeLimitInstructionBytes, LTx.Data, 'Data');
  AssertEquals(ComputeBudgetProgramIdBytes,                    LTx.ProgramId, 'ProgramId');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TComputeBudgetProgramTests);
{$ELSE}
  RegisterTest(TComputeBudgetProgramTests.Suite);
{$ENDIF}

end.

