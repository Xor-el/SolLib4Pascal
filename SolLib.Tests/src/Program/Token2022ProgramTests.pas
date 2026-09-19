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

unit Token2022ProgramTests;

interface

uses
  SysUtils,
  Rtti,
  Generics.Collections,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpPublicKey,
  SlpSysVars,
  SlpSystemProgram,
  SlpBPFLoaderProgram,
  SlpTransactionInstruction,
  SlpDecodedInstruction,
  SlpAddressLookupTableProgram,
  SlpMessageDomain,
  SlpMessageBuilder,
  SlpTokenProgram,
  SlpToken2022Program,
  SlpTokenPrograms,
  SlpToken2022ExtensionType,
  SolLibProgramTestCase;

type
  /// <summary>Byte-exact coverage for the Token-2022 / legacy Token builders and encoders.</summary>
  TToken2022ProgramTests = class(TSolLibProgramTestCase)
  private
    class function MintKey: IPublicKey; static;
    class function OwnerKey: IPublicKey; static;
    class function CloseAuthorityKey: IPublicKey; static;
    class function Token2022IdBytes: TBytes; static;
  published
    procedure TestNativeMintProgramIdKey;
    procedure TestInitializeAccount2Data;
    procedure TestInitializeAccount3Data;
    procedure TestInitializeMint2Data;
    procedure TestInitializeImmutableOwner;
    procedure TestGetAccountDataSizeData;
    procedure TestUiAmountToAmountRawUtf8;
    procedure TestUiAmountToAmountDecodeRoundTrip;
    procedure TestInitializeMintCloseAuthorityNil;
    procedure TestInitializeMintCloseAuthoritySet;
    procedure TestReallocate;
    procedure TestLegacyInitializeAccount2;
    procedure TestTokenProgramsFacadeMatchesDirect;
  end;

  /// <summary>Address Lookup Table PDA derivation coverage.</summary>
  TAddressLookupTableDeriveTests = class(TSolLibProgramTestCase)
  published
    procedure TestDeriveIsDeterministic;
    procedure TestCreateLookupTableDerivesInternally;
    procedure TestAuthorityOnlyExtendHasTwoKeys;
  end;

  /// <summary>Versioned message dynamic-prefix + round-trip coverage.</summary>
  TVersionedMessageBackportTests = class(TSolLibProgramTestCase)
  private
    function BuildVersioned(const AVersion: Byte): TBytes;
  published
    procedure TestVersion0Prefix;
    procedure TestVersion1Prefix;
    procedure TestVersionPreservedOnRoundTrip;
  end;

implementation

{ TToken2022ProgramTests }

class function TToken2022ProgramTests.MintKey: IPublicKey;
begin
  Result := TSystemProgram.ProgramIdKey;
end;

class function TToken2022ProgramTests.OwnerKey: IPublicKey;
begin
  Result := TBPFLoaderProgram.ProgramIdKey;
end;

class function TToken2022ProgramTests.CloseAuthorityKey: IPublicKey;
begin
  Result := TAddressLookupTableProgram.ProgramIdKey;
end;

class function TToken2022ProgramTests.Token2022IdBytes: TBytes;
begin
  Result := TToken2022Program.ProgramIdKey.KeyBytes;
end;

procedure TToken2022ProgramTests.TestNativeMintProgramIdKey;
begin
  AssertNotNull(TToken2022Program.NativeMintProgramIdKey, 'Native mint was nil');
  AssertEquals('9pan9bMn5HatX4EJdBwg9VgCa7Uz5HL8N1m5D3NdXejP',
    TToken2022Program.NativeMintProgramIdKey.Key, 'Native mint mismatch');
end;

procedure TToken2022ProgramTests.TestInitializeAccount2Data;
var
  LInstr: ITransactionInstruction;
  LExpected: TBytes;
begin
  LInstr := TToken2022Program.InitializeAccount2(MintKey, MintKey, OwnerKey);

  SetLength(LExpected, 33);
  LExpected[0] := 16;
  Move(OwnerKey.KeyBytes[0], LExpected[1], 32);

  AssertEquals(Token2022IdBytes, LInstr.ProgramId, 'ProgramId mismatch');
  AssertEquals(3, LInstr.Keys.Count, 'Keys.Count mismatch');
  AssertEquals(LExpected, LInstr.Data, 'Data mismatch');
end;

procedure TToken2022ProgramTests.TestInitializeAccount3Data;
var
  LInstr: ITransactionInstruction;
  LExpected: TBytes;
begin
  LInstr := TToken2022Program.InitializeAccount3(MintKey, MintKey, OwnerKey);

  SetLength(LExpected, 33);
  LExpected[0] := 18;
  Move(OwnerKey.KeyBytes[0], LExpected[1], 32);

  AssertEquals(2, LInstr.Keys.Count, 'Keys.Count mismatch');
  AssertEquals(LExpected, LInstr.Data, 'Data mismatch');
end;

procedure TToken2022ProgramTests.TestInitializeMint2Data;
var
  LInstr: ITransactionInstruction;
begin
  LInstr := TToken2022Program.InitializeMint2(MintKey, 6, OwnerKey);

  AssertEquals(1, LInstr.Keys.Count, 'Keys.Count mismatch (no Rent expected)');
  AssertEquals(67, Length(LInstr.Data), 'Data length mismatch');
  AssertEquals(20, Integer(LInstr.Data[0]), 'Discriminator mismatch');
  AssertEquals(6, Integer(LInstr.Data[1]), 'Decimals mismatch');
end;

procedure TToken2022ProgramTests.TestInitializeImmutableOwner;
var
  LInstr: ITransactionInstruction;
begin
  LInstr := TToken2022Program.InitializeImmutableOwner(MintKey);
  AssertEquals(TBytes.Create(22), LInstr.Data, 'Data mismatch');
end;

procedure TToken2022ProgramTests.TestGetAccountDataSizeData;
var
  LInstr: ITransactionInstruction;
  LExts: TArray<TToken2022ExtensionType>;
begin
  SetLength(LExts, 1);
  LExts[0] := TToken2022ExtensionType.ImmutableOwner; // ordinal 7

  LInstr := TToken2022Program.GetAccountDataSize(MintKey, LExts);
  // [21] + u16(7) little-endian
  AssertEquals(TBytes.Create(21, 7, 0), LInstr.Data, 'Data mismatch');
end;

procedure TToken2022ProgramTests.TestUiAmountToAmountRawUtf8;
var
  LInstr: ITransactionInstruction;
begin
  LInstr := TToken2022Program.UiAmountToAmount(MintKey, '1.5');
  // [24] + raw UTF-8 of "1.5" (no length prefix): '1'=49, '.'=46, '5'=53
  AssertEquals(TBytes.Create(24, 49, 46, 53), LInstr.Data, 'Data mismatch');
end;

procedure TToken2022ProgramTests.TestUiAmountToAmountDecodeRoundTrip;
var
  LInstr: ITransactionInstruction;
  LDecoded: IDecodedInstruction;
  LKeys: TArray<IPublicKey>;
  LIndices: TBytes;
  LValue: TValue;
begin
  LInstr := TToken2022Program.UiAmountToAmount(MintKey, '42.7');

  SetLength(LKeys, 1);
  LKeys[0] := MintKey;
  SetLength(LIndices, 1);
  LIndices[0] := 0;

  LDecoded := TToken2022Program.Decode(LInstr.Data, LKeys, LIndices);
  AssertNotNull(LDecoded, 'Decoded was nil');
  AssertTrue(LDecoded.Values.TryGetValue('Amount', LValue), 'Amount key missing');
  AssertEquals('42.7', LValue.AsString, 'Amount mismatch');
end;

procedure TToken2022ProgramTests.TestInitializeMintCloseAuthorityNil;
var
  LInstr: ITransactionInstruction;
begin
  LInstr := TToken2022Program.InitializeMintCloseAuthority(MintKey, nil);
  AssertEquals(TBytes.Create(25, 0), LInstr.Data, 'Data mismatch');
end;

procedure TToken2022ProgramTests.TestInitializeMintCloseAuthoritySet;
var
  LInstr: ITransactionInstruction;
  LExpected: TBytes;
begin
  LInstr := TToken2022Program.InitializeMintCloseAuthority(MintKey, CloseAuthorityKey);

  SetLength(LExpected, 34);
  LExpected[0] := 25;
  LExpected[1] := 1;
  Move(CloseAuthorityKey.KeyBytes[0], LExpected[2], 32);

  AssertEquals(LExpected, LInstr.Data, 'Data mismatch');
end;

procedure TToken2022ProgramTests.TestReallocate;
var
  LInstr: ITransactionInstruction;
  LExts: TArray<TToken2022ExtensionType>;
begin
  SetLength(LExts, 2);
  LExts[0] := TToken2022ExtensionType.ImmutableOwner; // 7
  LExts[1] := TToken2022ExtensionType.MemoTransfer;   // 8

  LInstr := TToken2022Program.Reallocate(MintKey, OwnerKey, OwnerKey, LExts);

  // account + payer + system program + owner (no extra signers)
  AssertEquals(4, LInstr.Keys.Count, 'Keys.Count mismatch');
  AssertEquals(TBytes.Create(29, 7, 0, 8, 0), LInstr.Data, 'Data mismatch');
end;

procedure TToken2022ProgramTests.TestLegacyInitializeAccount2;
var
  LInstr: ITransactionInstruction;
  LExpected: TBytes;
begin
  LInstr := TTokenProgram.InitializeAccount2(MintKey, MintKey, OwnerKey);

  SetLength(LExpected, 33);
  LExpected[0] := 16;
  Move(OwnerKey.KeyBytes[0], LExpected[1], 32);

  AssertEquals(TTokenProgram.ProgramIdKey.KeyBytes, LInstr.ProgramId, 'ProgramId mismatch');
  AssertEquals(3, LInstr.Keys.Count, 'Keys.Count mismatch');
  AssertEquals(LExpected, LInstr.Data, 'Data mismatch');
end;

procedure TToken2022ProgramTests.TestTokenProgramsFacadeMatchesDirect;
var
  LViaFacade, LDirect: ITransactionInstruction;
begin
  // The namespacing facade must resolve to the same program classes.
  AssertEquals(TTokenProgram.ProgramIdKey.Key, TTokenPrograms.Legacy.ProgramIdKey.Key,
    'Legacy program id mismatch');
  AssertEquals(TToken2022Program.ProgramIdKey.Key, TTokenPrograms.Token2022.ProgramIdKey.Key,
    'Token2022 program id mismatch');

  // An instruction built through the facade must be byte-identical to the direct call.
  LViaFacade := TTokenPrograms.Token2022.InitializeAccount2(MintKey, MintKey, OwnerKey);
  LDirect := TToken2022Program.InitializeAccount2(MintKey, MintKey, OwnerKey);
  AssertEquals(LDirect.ProgramId, LViaFacade.ProgramId, 'Token2022 ProgramId mismatch');
  AssertEquals(LDirect.Data, LViaFacade.Data, 'Token2022 Data mismatch');

  LViaFacade := TTokenPrograms.Legacy.InitializeAccount2(MintKey, MintKey, OwnerKey);
  LDirect := TTokenProgram.InitializeAccount2(MintKey, MintKey, OwnerKey);
  AssertEquals(LDirect.ProgramId, LViaFacade.ProgramId, 'Legacy ProgramId mismatch');
  AssertEquals(LDirect.Data, LViaFacade.Data, 'Legacy Data mismatch');
end;

{ TAddressLookupTableDeriveTests }

procedure TAddressLookupTableDeriveTests.TestDeriveIsDeterministic;
const
  RecentSlot: UInt64 = 123456;
var
  LAuthority: IPublicKey;
  LAddr1, LAddr2: IPublicKey;
  LBump1, LBump2: Byte;
begin
  LAuthority := TBPFLoaderProgram.ProgramIdKey;

  AssertTrue(TAddressLookupTableProgram.TryDeriveLookupTableAddress(LAuthority, RecentSlot, LAddr1, LBump1),
    'First derive failed');
  AssertTrue(TAddressLookupTableProgram.TryDeriveLookupTableAddress(LAuthority, RecentSlot, LAddr2, LBump2),
    'Second derive failed');

  AssertNotNull(LAddr1, 'Derived address was nil');
  AssertEquals(LAddr1.Key, LAddr2.Key, 'Derivation is not deterministic');
  AssertEquals(Integer(LBump1), Integer(LBump2), 'Bump is not deterministic');
end;

procedure TAddressLookupTableDeriveTests.TestCreateLookupTableDerivesInternally;
const
  RecentSlot: UInt64 = 987654;
var
  LAuthority, LPayer, LAddr: IPublicKey;
  LBump: Byte;
  LInternal, LExplicit: ITransactionInstruction;
begin
  LAuthority := TBPFLoaderProgram.ProgramIdKey;
  LPayer := TSystemProgram.ProgramIdKey;

  AssertTrue(TAddressLookupTableProgram.TryDeriveLookupTableAddress(LAuthority, RecentSlot, LAddr, LBump),
    'Derive failed');

  LInternal := TAddressLookupTableProgram.CreateLookupTable(LAuthority, LPayer, RecentSlot);
  LExplicit := TAddressLookupTableProgram.CreateLookupTable(LAuthority, LPayer, LAddr, LBump, RecentSlot);

  AssertNotNull(LInternal, 'Derive-internally instruction was nil');
  AssertEquals(4, LInternal.Keys.Count, 'Keys.Count mismatch');
  AssertEquals(LExplicit.Data, LInternal.Data, 'Encoded data mismatch');
end;

procedure TAddressLookupTableDeriveTests.TestAuthorityOnlyExtendHasTwoKeys;
var
  LInstr: ITransactionInstruction;
  LKeys: TArray<IPublicKey>;
begin
  SetLength(LKeys, 1);
  LKeys[0] := TSysVars.ClockKey;

  // Authority-only overload: no payer / system-program metas.
  LInstr := TAddressLookupTableProgram.ExtendLookupTable(
              TAddressLookupTableProgram.ProgramIdKey, TBPFLoaderProgram.ProgramIdKey, LKeys);

  AssertNotNull(LInstr, 'Instruction was nil');
  AssertEquals(2, LInstr.Keys.Count, 'Authority-only extend should have 2 keys');
end;

{ TVersionedMessageBackportTests }

function TVersionedMessageBackportTests.BuildVersioned(const AVersion: Byte): TBytes;
var
  LInstr: ITransactionInstruction;
begin
  LInstr := TAddressLookupTableProgram.FreezeLookupTable(
              TAddressLookupTableProgram.ProgramIdKey, TBPFLoaderProgram.ProgramIdKey);

  // Exercise the version-typed message facets; the emitted bytes are version-identical.
  if AVersion = 0 then
    Result := TMessageBuilders.V0
      .SetFeePayer(TBPFLoaderProgram.ProgramIdKey)
      .SetRecentBlockHash(TSystemProgram.ProgramIdKey.Key)
      .AddInstruction(LInstr)
      .Build
  else
    Result := TMessageBuilders.V1
      .SetFeePayer(TBPFLoaderProgram.ProgramIdKey)
      .SetRecentBlockHash(TSystemProgram.ProgramIdKey.Key)
      .AddInstruction(LInstr)
      .Build;
end;

procedure TVersionedMessageBackportTests.TestVersion0Prefix;
var
  LBytes: TBytes;
begin
  LBytes := BuildVersioned(0);
  AssertTrue(Length(LBytes) > 0, 'Empty message');
  AssertEquals($80, Integer(LBytes[0]), 'v0 prefix should be $80');
end;

procedure TVersionedMessageBackportTests.TestVersion1Prefix;
var
  LBytes: TBytes;
begin
  LBytes := BuildVersioned(1);
  AssertEquals($81, Integer(LBytes[0]), 'v1 prefix should be $81 ($80 or 1)');
end;

procedure TVersionedMessageBackportTests.TestVersionPreservedOnRoundTrip;
var
  LBytes, LReSerialized: TBytes;
  LMsg: IMessage;
  LVersioned: IVersionedMessage;
begin
  LBytes := BuildVersioned(1);

  LMsg := TVersionedMessage.Deserialize(LBytes);
  AssertNotNull(LMsg, 'Deserialize returned nil');

  LVersioned := LMsg as IVersionedMessage;
  AssertEquals(1, Integer(LVersioned.Version), 'Version not preserved');

  LReSerialized := LMsg.Serialize;
  AssertEquals(LBytes, LReSerialized, 'Round-trip serialization mismatch');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TToken2022ProgramTests);
  RegisterTest(TAddressLookupTableDeriveTests);
  RegisterTest(TVersionedMessageBackportTests);
{$ELSE}
  RegisterTest(TToken2022ProgramTests.Suite);
  RegisterTest(TAddressLookupTableDeriveTests.Suite);
  RegisterTest(TVersionedMessageBackportTests.Suite);
{$ENDIF}

end.
