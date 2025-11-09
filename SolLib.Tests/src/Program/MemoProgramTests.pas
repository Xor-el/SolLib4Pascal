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

unit MemoProgramTests;

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
  SlpTransactionInstruction,
  SlpMemoProgram,
  SlpSystemProgram,
  SolLibProgramTestCase;

type
  TMemoProgramTests = class(TSolLibProgramTestCase)
  private
    class function AccountKey: IPublicKey; static;
    class function ProgramIdBytes: TBytes; static;
    class function ProgramIdV2Bytes: TBytes; static;
  published
    // Memo v1 tests
    procedure TestWriteUtf8_ValidInput;
    procedure TestWriteUtf8_NullAccount;
    procedure TestWriteUtf8_EmptyMemo;
    procedure TestWriteUtf8_LongMemo;

    // Memo v2 tests
    procedure TestWriteUtf8V2_ValidInput_WithAccount;
    procedure TestWriteUtf8V2_ValidInput_NoAccount;
    procedure TestWriteUtf8V2_EmptyMemo;
    procedure TestWriteUtf8V2_LongMemo;
  end;

implementation

{ Helpers }

class function TMemoProgramTests.AccountKey: IPublicKey;
begin
  Result := TSystemProgram.ProgramIdKey;
end;

class function TMemoProgramTests.ProgramIdBytes: TBytes;
begin
  Result := TMemoProgram.ProgramIdKey.KeyBytes;
end;

class function TMemoProgramTests.ProgramIdV2Bytes: TBytes;
begin
  Result := TMemoProgram.ProgramIdKeyV2.KeyBytes;
end;

{ ==== Memo v1 tests ==== }

procedure TMemoProgramTests.TestWriteUtf8_ValidInput;
var
  LAccount : IPublicKey;
  LMemo    : string;
  LInstr   : ITransactionInstruction;
  LBytes   : TBytes;
begin
  LAccount := AccountKey;
  LMemo    := 'Test memo';

  LInstr := TMemoProgram.NewMemo(LAccount, LMemo);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals<Byte>(ProgramIdBytes, LInstr.ProgramId, 'ProgramId mismatch');

  AssertEquals(1, LInstr.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(LAccount.KeyBytes, LInstr.Keys[0].PublicKey.KeyBytes, 'First key public key mismatch');
  AssertTrue(LInstr.Keys[0].IsSigner,   'First key should be signer');
  AssertFalse(LInstr.Keys[0].IsWritable, 'First key should be read-only');

  LBytes := TEncoding.UTF8.GetBytes(LMemo);
  AssertEquals<Byte>(LBytes, LInstr.Data, 'Memo data mismatch');
end;

procedure TMemoProgramTests.TestWriteUtf8_NullAccount;
begin
  AssertException(
    procedure
    begin
      TMemoProgram.NewMemo(nil, 'Test memo');
    end,
    EArgumentNilException
  );
end;

procedure TMemoProgramTests.TestWriteUtf8_EmptyMemo;
var
  LAccount : IPublicKey;
begin
  LAccount := AccountKey;
  AssertException(
    procedure
    begin
      TMemoProgram.NewMemo(LAccount, '');
    end,
    EArgumentNilException
  );
end;

procedure TMemoProgramTests.TestWriteUtf8_LongMemo;
var
  LAccount : IPublicKey;
  LLong    : string;
  LInstr   : ITransactionInstruction;
  LBytes   : TBytes;
begin
  LAccount := AccountKey;
  LLong    := StringOfChar('A', 1000);

  LInstr := TMemoProgram.NewMemo(LAccount, LLong);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals<Byte>(ProgramIdBytes, LInstr.ProgramId, 'ProgramId mismatch');

  LBytes := TEncoding.UTF8.GetBytes(LLong);
  AssertEquals<Byte>(LBytes, LInstr.Data, 'Long memo data mismatch');
end;

{ ==== Memo v2 tests ==== }

procedure TMemoProgramTests.TestWriteUtf8V2_ValidInput_WithAccount;
var
  LAccount : IPublicKey;
  LMemo    : string;
  LInstr   : ITransactionInstruction;
  LBytes   : TBytes;
begin
  LAccount := AccountKey;
  LMemo    := 'Test memo v2';

  LInstr := TMemoProgram.NewMemoV2(LMemo, LAccount);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals<Byte>(ProgramIdV2Bytes, LInstr.ProgramId, 'ProgramId (v2) mismatch');

  AssertEquals(1, LInstr.Keys.Count, 'Keys.Count mismatch (v2 with account)');
  AssertEquals<Byte>(LAccount.KeyBytes, LInstr.Keys[0].PublicKey.KeyBytes, 'First key public key mismatch (v2)');
  AssertTrue(LInstr.Keys[0].IsSigner,   'First key should be signer (v2)');
  AssertFalse(LInstr.Keys[0].IsWritable, 'First key should be read-only (v2)');

  LBytes := TEncoding.UTF8.GetBytes(LMemo);
  AssertEquals<Byte>(LBytes, LInstr.Data, 'Memo v2 data mismatch');
end;

procedure TMemoProgramTests.TestWriteUtf8V2_ValidInput_NoAccount;
var
  LMemo  : string;
  LInstr : ITransactionInstruction;
  LBytes : TBytes;
begin
  LMemo  := 'Memo without account';
  LInstr := TMemoProgram.NewMemoV2(LMemo, nil);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals<Byte>(ProgramIdV2Bytes, LInstr.ProgramId, 'ProgramId (v2) mismatch');

  AssertEquals(0, LInstr.Keys.Count, 'Keys.Count should be 0 when no account is provided');
  LBytes := TEncoding.UTF8.GetBytes(LMemo);
  AssertEquals<Byte>(LBytes, LInstr.Data, 'Memo v2 data mismatch (no account)');
end;

procedure TMemoProgramTests.TestWriteUtf8V2_EmptyMemo;
begin
  AssertException(
    procedure
    begin
      TMemoProgram.NewMemoV2('', nil);
    end,
    EArgumentNilException
  );
end;

procedure TMemoProgramTests.TestWriteUtf8V2_LongMemo;
var
  LAccount : IPublicKey;
  LLong    : string;
  LInstr   : ITransactionInstruction;
  LBytes   : TBytes;
begin
  LAccount := AccountKey;
  LLong    := StringOfChar('A', 1000);

  LInstr := TMemoProgram.NewMemoV2(LLong, LAccount);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals<Byte>(ProgramIdV2Bytes, LInstr.ProgramId, 'ProgramId (v2) mismatch');

  LBytes := TEncoding.UTF8.GetBytes(LLong);
  AssertEquals<Byte>(LBytes, LInstr.Data, 'Long memo v2 data mismatch');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TMemoProgramTests);
{$ELSE}
  RegisterTest(TMemoProgramTests.Suite);
{$ENDIF}

end.

