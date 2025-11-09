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

unit AddressLookupTableProgramTests;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpPublicKey,
  SlpSysVars,
  SlpTransactionInstruction,
  SlpSystemProgram,
  SlpAddressLookupTableProgram,
  SlpBPFLoaderProgram,
  SolLibProgramTestCase;

type
  TAddressLookupTableProgramTests = class(TSolLibProgramTestCase)
  private
    class function AuthorityKey: IPublicKey; static;
    class function PayerKey: IPublicKey; static;
    class function LookupTableKey: IPublicKey; static;
    class function ClockSysvarKey: IPublicKey; static;
    class function RentSysvarKey: IPublicKey; static;
    class function ProgramIdBytes: TBytes; static;
  published
    procedure TestCreateLookupTable;
    procedure TestFreezeLookupTable;
    procedure TestExtendLookupTable;
    procedure TestDeactivateLookupTable;
    procedure TestCloseLookupTable;
  end;

implementation

{ Helpers }

class function TAddressLookupTableProgramTests.AuthorityKey: IPublicKey;
begin
  Result := TBPFLoaderProgram.ProgramIdKey;
end;

class function TAddressLookupTableProgramTests.PayerKey: IPublicKey;
begin
  Result := TSystemProgram.ProgramIdKey;
end;

class function TAddressLookupTableProgramTests.LookupTableKey: IPublicKey;
begin
  Result := TAddressLookupTableProgram.ProgramIdKey;
end;

class function TAddressLookupTableProgramTests.ClockSysvarKey: IPublicKey;
begin
  Result := TSysVars.ClockKey;
end;

class function TAddressLookupTableProgramTests.RentSysvarKey: IPublicKey;
begin
  Result := TSysVars.RentKey;
end;

class function TAddressLookupTableProgramTests.ProgramIdBytes: TBytes;
begin
  Result := TAddressLookupTableProgram.ProgramIdKey.KeyBytes;
end;

{ Tests }

procedure TAddressLookupTableProgramTests.TestCreateLookupTable;
const
  RecentSlot: UInt64 = 123456;
  Bump: Byte = 1;
var
  LInstr: ITransactionInstruction;
begin
  LInstr := TAddressLookupTableProgram.CreateAddressLookupTable(
              AuthorityKey, PayerKey, LookupTableKey, Bump, RecentSlot);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals<Byte>(ProgramIdBytes, LInstr.ProgramId, 'ProgramId mismatch');
  AssertEquals(4, LInstr.Keys.Count, 'Keys.Count mismatch');
end;

procedure TAddressLookupTableProgramTests.TestFreezeLookupTable;
var
  LInstr: ITransactionInstruction;
begin
  LInstr := TAddressLookupTableProgram.FreezeLookupTable(LookupTableKey, AuthorityKey);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals<Byte>(ProgramIdBytes, LInstr.ProgramId, 'ProgramId mismatch');
  AssertEquals(2, LInstr.Keys.Count, 'Keys.Count mismatch');
end;

procedure TAddressLookupTableProgramTests.TestExtendLookupTable;
var
  LInstr: ITransactionInstruction;
  LKeys: TArray<IPublicKey>;
begin
  SetLength(LKeys, 1);
  LKeys[0] := ClockSysvarKey;

  LInstr := TAddressLookupTableProgram.ExtendLookupTable(
              LookupTableKey, AuthorityKey, PayerKey, LKeys);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals<Byte>(ProgramIdBytes, LInstr.ProgramId, 'ProgramId mismatch');
  AssertEquals(4, LInstr.Keys.Count, 'Keys.Count mismatch');
end;

procedure TAddressLookupTableProgramTests.TestDeactivateLookupTable;
var
  LInstr: ITransactionInstruction;
begin
  LInstr := TAddressLookupTableProgram.DeactivateLookupTable(LookupTableKey, AuthorityKey);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals<Byte>(ProgramIdBytes, LInstr.ProgramId, 'ProgramId mismatch');
  AssertEquals(2, LInstr.Keys.Count, 'Keys.Count mismatch');
end;

procedure TAddressLookupTableProgramTests.TestCloseLookupTable;
var
  LInstr: ITransactionInstruction;
begin
  LInstr := TAddressLookupTableProgram.CloseLookupTable(LookupTableKey, AuthorityKey, RentSysvarKey);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals<Byte>(ProgramIdBytes, LInstr.ProgramId, 'ProgramId mismatch');
  AssertEquals(3, LInstr.Keys.Count, 'Keys.Count mismatch');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TAddressLookupTableProgramTests);
{$ELSE}
  RegisterTest(TAddressLookupTableProgramTests.Suite);
{$ENDIF}

end.

