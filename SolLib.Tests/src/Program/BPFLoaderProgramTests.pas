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

unit BPFLoaderProgramTests;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpAccount,
  SlpPublicKey,
  SlpTransactionInstruction,
  SlpDeserialization,
  SlpBPFLoaderProgram,
  SolLibProgramTestCase;

type
  TBPFLoaderProgramTests = class(TSolLibProgramTestCase)
  private
    class function ProgramIdBytes: TBytes; static;
  published
    procedure TestInitializeBuffer;
    procedure TestWrite;
    procedure TestDeployWithMaxDataLen;
    procedure TestUpgrade;
    procedure TestSetAuthority;
  end;

implementation

{ Helpers }

class function TBPFLoaderProgramTests.ProgramIdBytes: TBytes;
begin
  Result := TBPFLoaderProgram.ProgramIdKey.KeyBytes;
end;

{ Tests }

procedure TBPFLoaderProgramTests.TestInitializeBuffer;
var
  LPayer, LBuffer: IAccount;
  LInstr: ITransactionInstruction;
begin
  LPayer  := TAccount.Create;
  LBuffer := TAccount.Create;

  LInstr := TBPFLoaderProgram.InitializeBuffer(LBuffer.PublicKey, LPayer.PublicKey);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals<Byte>(ProgramIdBytes, LInstr.ProgramId, 'ProgramId mismatch');

  AssertEquals(2, LInstr.Keys.Count, 'Keys.Count mismatch');
  // Our encoder uses u32 tag → 4 bytes; LE first byte = 0
  AssertEquals(4, Length(LInstr.Data), 'Data length mismatch');
  CheckEquals(0, LInstr.Data[0], 'Tag (byte 0) should be 0 (InitializeBuffer)');
end;

procedure TBPFLoaderProgramTests.TestWrite;
var
  LPayer, LBuffer: IAccount;
  LData: TBytes;
  LInstr: ITransactionInstruction;
  LOffset: UInt32;
begin
  LPayer  := TAccount.Create;
  LBuffer := TAccount.Create;

  LData := TBytes.Create(1,2,3,4,5);
  LOffset := 10;

  LInstr := TBPFLoaderProgram.Write(LBuffer.PublicKey, LPayer.PublicKey, LData, LOffset);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals<Byte>(ProgramIdBytes, LInstr.ProgramId, 'ProgramId mismatch');
  AssertEquals(2, LInstr.Keys.Count, 'Keys.Count mismatch');

  // Data layout (our encoder):
  // 0..3: u32(tag=1), 4..7: u32(offset), 8.. : borsh byte-vector (len + bytes)
  CheckEquals(1, LInstr.Data[0], 'Tag (byte 0) should be 1 (Write)');
  CheckTrue(Length(LInstr.Data) >= 4+4+4+Length(LData), 'Data too short for Write layout');

  // Verify offset
  CheckEquals(LOffset, TDeserialization.GetU32(LInstr.Data, 4), 'Offset mismatch');
end;

procedure TBPFLoaderProgramTests.TestDeployWithMaxDataLen;
var
  LPayer, LProgData, LProg, LBuffer, LAuth: IAccount;
  LInstr: ITransactionInstruction;
  LMaxLen: UInt64;
begin
  LPayer    := TAccount.Create;
  LProgData := TAccount.Create;
  LProg     := TAccount.Create;
  LBuffer   := TAccount.Create;
  LAuth     := TAccount.Create;

  LMaxLen := 1000;

  LInstr := TBPFLoaderProgram.DeployWithMaxDataLen(
              LPayer.PublicKey,
              LProgData.PublicKey,
              LProg.PublicKey,
              LBuffer.PublicKey,
              LAuth.PublicKey,
              LMaxLen);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals<Byte>(ProgramIdBytes, LInstr.ProgramId, 'ProgramId mismatch');

  // payer*, programData(w), program(w), buffer(w), rent, clock, system, authority*
  AssertEquals(8, LInstr.Keys.Count, 'Keys.Count mismatch');

  // Our encoder: u32(tag=2) + u64(maxlen) = 12 bytes (LE, first byte still 2)
  AssertEquals(12, Length(LInstr.Data), 'Data length mismatch');
  CheckEquals(2, LInstr.Data[0], 'Tag (byte 0) should be 2 (DeployWithMaxDataLen)');
end;

procedure TBPFLoaderProgramTests.TestUpgrade;
var
  LProgData, LProg, LBuffer, LSpill, LAuth: IAccount;
  LInstr: ITransactionInstruction;
begin
  LProgData := TAccount.Create;
  LProg     := TAccount.Create;
  LBuffer   := TAccount.Create;
  LSpill    := TAccount.Create;
  LAuth     := TAccount.Create;

  LInstr := TBPFLoaderProgram.Upgrade(
              LProgData.PublicKey,
              LProg.PublicKey,
              LBuffer.PublicKey,
              LSpill.PublicKey,
              LAuth.PublicKey);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals<Byte>(ProgramIdBytes, LInstr.ProgramId, 'ProgramId mismatch');

  // programData(w), program(w), buffer(w), spill(w), rent, clock, authority*
  AssertEquals(7, LInstr.Keys.Count, 'Keys.Count mismatch');

  // u32(tag=3)
  AssertEquals(4, Length(LInstr.Data), 'Data length mismatch');
  CheckEquals(3, LInstr.Data[0], 'Tag (byte 0) should be 3 (Upgrade)');
end;

procedure TBPFLoaderProgramTests.TestSetAuthority;
var
  LAcct, LAuth, LNewAuth: IAccount;
  LInstr: ITransactionInstruction;
begin
  LAcct    := TAccount.Create;
  LAuth    := TAccount.Create;
  LNewAuth := TAccount.Create;

  LInstr := TBPFLoaderProgram.SetAuthority(LAcct.PublicKey, LAuth.PublicKey, LNewAuth.PublicKey);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals<Byte>(ProgramIdBytes, LInstr.ProgramId, 'ProgramId mismatch');

  AssertEquals(3, LInstr.Keys.Count, 'Keys.Count mismatch');

  // u32(tag=4)
  AssertEquals(4, Length(LInstr.Data), 'Data length mismatch');
  CheckEquals(4, LInstr.Data[0], 'Tag (byte 0) should be 4 (SetAuthority)');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TBPFLoaderProgramTests);
{$ELSE}
  RegisterTest(TBPFLoaderProgramTests.Suite);
{$ENDIF}

end.

