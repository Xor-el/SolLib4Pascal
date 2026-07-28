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

unit SlpAddressLookupTableProgram;

{$I ../Include/SolLib.inc}

interface

uses
  SysUtils,
  Generics.Collections,
  Rtti,
  SlpPublicKey,
  SlpSerialization,
  SlpDeserialization,
  SlpEnumUtilities,
  SlpAccountDomain,
  SlpTransactionInstruction,
  SlpDecodedInstruction,
  SlpSystemProgram;

type
  {====================================================================================================================}
  {                                     AddressLookupTableProgramInstructions                                          }
  {====================================================================================================================}
  /// <summary>
  /// Instruction kinds for the Address Lookup Table Program.
  /// </summary>
  TAddressLookupTableProgramInstructions = class sealed
  public
    type
      TValues = (
        CreateLookupTable = 0,
        FreezeLookupTable = 1,
        ExtendLookupTable = 2,
        DeactivateLookupTable = 3,
        CloseLookupTable = 4
      );
  private
    class var FNames: TDictionary<TValues, string>;
  public
    class property Names: TDictionary<TValues, string> read FNames;

    class constructor Create;
    class destructor Destroy;
  end;

  {====================================================================================================================}
  {                                          AddressLookupTableProgramData                                             }
  {====================================================================================================================}
  /// <summary>
  /// Binary encoders for Address Lookup Table Program instructions.
  /// </summary>
  TAddressLookupTableProgramData = class sealed
  private
    const MethodOffset = 0;
    const ExtendLookupTableAddressesLengthOffset = 4;
    const ExtendLookupTableAddressesOffset = 12;
  public
    /// <summary>
    /// Encode CreateLookupTable data.
    /// Layout:
    ///   [0..3]: u32 method = CreateLookupTable
    ///   [4..11]: u64 recentSlot
    ///   [12]: u8  bump
    /// </summary>
    class function EncodeCreateAddressLookupTableData(const ARecentSlot: UInt64; const ABump: Byte): TBytes; static;

    /// <summary>
    /// Encode FreezeLookupTable data.
    /// Layout: [0..3] u32 method = FreezeLookupTable
    /// </summary>
    class function EncodeFreezeLookupTableData: TBytes; static;

    /// <summary>
    /// Encode ExtendLookupTable data.
    /// Layout:
    ///   [0..3]: u32 method = ExtendLookupTable
    ///   [4..11]: u64 keyCount
    ///   [12..]: keyCount * 32 bytes of pubkeys
    /// </summary>
    class function EncodeExtendLookupTableData(const AKeys: TArray<IPublicKey>): TBytes; static;

    /// <summary>
    /// Encode DeactivateLookupTable data.
    /// Layout: [0..3] u32 method = DeactivateLookupTable
    /// </summary>
    class function EncodeDeactivateLookupTableData: TBytes; static;

    /// <summary>
    /// Encode CloseLookupTable data.
    /// Layout: [0..3] u32 method = CloseLookupTable
    /// </summary>
    class function EncodeCloseLookupTableData: TBytes; static;

    /// <summary>
    /// Decode the addresses carried by an ExtendLookupTable instruction.
    /// Layout: [4..11] u64 keyCount, then keyCount * 32 bytes of pubkeys from offset 12.
    /// </summary>
    class function DecodeExtendLookupTableAddresses(const AData: TBytes): TArray<IPublicKey>; static;
  end;

  {====================================================================================================================}
  {                                         AddressLookupTableProgram (methods)                                        }
  {====================================================================================================================}
  /// <summary>
  /// Implements the Address Lookup Table Program methods.
  /// </summary>
  TAddressLookupTableProgram = class sealed
  private
    const ProgramName = 'Address Lookup Table Program';
    class var FProgramIdKey: IPublicKey;
    class function GetProgramIdKey: IPublicKey; static;

    /// <summary>
    /// Shared ExtendLookupTable builder. Adds the payer + System Program metas only when
    /// <paramref name="APayer"/> is assigned (authority-only path passes nil).
    /// </summary>
    class function ExtendLookupTableInternal(const ALookupTable, AAuthority, APayer: IPublicKey;
                                             const AKeys: TArray<IPublicKey>): ITransactionInstruction; static;
  public
    /// <summary>The public key of the Address Lookup Table Program.</summary>
    class property ProgramIdKey: IPublicKey read GetProgramIdKey;

    class constructor Create;
    class destructor Destroy;

    /// <summary>Derive the lookup table address for an authority and recent slot, or nil if no valid PDA exists.</summary>
    class function DeriveLookupTableAddress(const AAuthority: IPublicKey; const ARecentSlot: UInt64): IPublicKey; static;

    /// <summary>Derive the lookup table address and bump for an authority and recent slot. Seeds: [authority, recentSlot-le-u64].</summary>
    class function TryDeriveLookupTableAddress(const AAuthority: IPublicKey; const ARecentSlot: UInt64;
                                               out AAddress: IPublicKey; out ABump: Byte): Boolean; static;

    /// <summary>Create New Address Lookup Table instruction, deriving the table address internally. Returns nil if derivation fails.</summary>
    class function CreateLookupTable(const AAuthority, APayer: IPublicKey;
                                     const ARecentSlot: UInt64): ITransactionInstruction; overload; static;

    /// <summary>Create New Address Lookup Table instruction from an explicit table address and bump.</summary>
    class function CreateLookupTable(const AAuthority, APayer, ALookupTable: IPublicKey;
                                     const ABump: Byte; const ARecentSlot: UInt64): ITransactionInstruction; overload; static;

    /// <summary>Create New Address Lookup Table instruction (alias of the explicit-address CreateLookupTable overload).</summary>
    class function CreateAddressLookupTable(const AAuthority, APayer, ALookupUpTable: IPublicKey;
                                           const ABump: Byte; const ARecentSlot: UInt64): ITransactionInstruction; static;

    /// <summary>Freeze Lookup Table instruction.</summary>
    class function FreezeLookupTable(const ALookupTable, AAuthority: IPublicKey): ITransactionInstruction; static;

    /// <summary>Extend Lookup Table instruction (authority-only, no payer / System Program metas).</summary>
    class function ExtendLookupTable(const ALookupTable, AAuthority: IPublicKey;
                                     const AKeys: TArray<IPublicKey>): ITransactionInstruction; overload; static;

    /// <summary>Extend Lookup Table instruction (funded by payer).</summary>
    class function ExtendLookupTable(const ALookupTable, AAuthority, APayer: IPublicKey;
                                     const AKeys: TArray<IPublicKey>): ITransactionInstruction; overload; static;

    /// <summary>Deactivate Lookup Table instruction.</summary>
    class function DeactivateLookupTable(const ALookupTable, AAuthority: IPublicKey): ITransactionInstruction; static;

    /// <summary>Close Lookup Table instruction.</summary>
    class function CloseLookupTable(const ALookupTable, AAuthority, ARecipient: IPublicKey): ITransactionInstruction; static;

    /// <summary>Decode an Address Lookup Table Program instruction.</summary>
    class function Decode(const AData: TBytes; const AKeys: TArray<IPublicKey>;
                          const AKeyIndices: TBytes): IDecodedInstruction; static;
  end;

implementation

{ TAddressLookupTableProgramInstructions }

class constructor TAddressLookupTableProgramInstructions.Create;
begin
  FNames := TDictionary<TValues, string>.Create;
  FNames.Add(TValues.CreateLookupTable,     'Create Lookup Table');
  FNames.Add(TValues.FreezeLookupTable,     'Freeze Lookup Table');
  FNames.Add(TValues.ExtendLookupTable,     'Extend Lookup Table');
  FNames.Add(TValues.DeactivateLookupTable, 'Deactivate Lookup Table');
  FNames.Add(TValues.CloseLookupTable,      'Close Lookup Table');
end;

class destructor TAddressLookupTableProgramInstructions.Destroy;
begin
  FNames.Free;
end;

{ TAddressLookupTableProgramData }

class function TAddressLookupTableProgramData.EncodeCreateAddressLookupTableData(
  const ARecentSlot: UInt64; const ABump: Byte): TBytes;
begin
  SetLength(Result, 13);
  // u32 method id (LE)
  TSerialization.WriteU32(Result, UInt32(TAddressLookupTableProgramInstructions.TValues.CreateLookupTable), MethodOffset);
  // u64 recent slot (LE)
  TSerialization.WriteU64(Result, ARecentSlot, 4);
  // u8 bump
  TSerialization.WriteU8(Result, ABump, 12);
end;

class function TAddressLookupTableProgramData.EncodeFreezeLookupTableData: TBytes;
begin
  SetLength(Result, 4);
  TSerialization.WriteU32(Result, UInt32(TAddressLookupTableProgramInstructions.TValues.FreezeLookupTable), MethodOffset);
end;

class function TAddressLookupTableProgramData.EncodeExtendLookupTableData(
  const AKeys: TArray<IPublicKey>): TBytes;
var
  LI, LCount: Integer;
begin
  LCount := Length(AKeys);
  SetLength(Result, 12 + LCount * 32);
  // u32 method id
  TSerialization.WriteU32(Result, UInt32(TAddressLookupTableProgramInstructions.TValues.ExtendLookupTable), MethodOffset);
  // u64 key count
  TSerialization.WriteU64(Result, LCount, 4);
  // packed pubkeys
  for LI := 0 to High(AKeys) do
    TSerialization.WritePubKey(Result, AKeys[LI], 12 + LI * 32);
end;

class function TAddressLookupTableProgramData.EncodeDeactivateLookupTableData: TBytes;
begin
  SetLength(Result, 4);
  TSerialization.WriteU32(Result, UInt32(TAddressLookupTableProgramInstructions.TValues.DeactivateLookupTable), MethodOffset);
end;

class function TAddressLookupTableProgramData.EncodeCloseLookupTableData: TBytes;
begin
  SetLength(Result, 4);
  TSerialization.WriteU32(Result, UInt32(TAddressLookupTableProgramInstructions.TValues.CloseLookupTable), MethodOffset);
end;

class function TAddressLookupTableProgramData.DecodeExtendLookupTableAddresses(
  const AData: TBytes): TArray<IPublicKey>;
var
  LKeyCount, LI: Integer;
begin
  LKeyCount := Integer(TDeserialization.GetU64(AData, ExtendLookupTableAddressesLengthOffset));
  SetLength(Result, LKeyCount);
  for LI := 0 to LKeyCount - 1 do
    Result[LI] := TDeserialization.GetPubKey(AData, ExtendLookupTableAddressesOffset + LI * TPublicKey.PublicKeyLength);
end;

{ TAddressLookupTableProgram }

class constructor TAddressLookupTableProgram.Create;
begin
  FProgramIdKey := TPublicKey.Create('AddressLookupTab1e1111111111111111111111111');
end;

class destructor TAddressLookupTableProgram.Destroy;
begin
  FProgramIdKey := nil;
end;

class function TAddressLookupTableProgram.GetProgramIdKey: IPublicKey;
begin
  Result := FProgramIdKey;
end;

class function TAddressLookupTableProgram.TryDeriveLookupTableAddress(
  const AAuthority: IPublicKey; const ARecentSlot: UInt64;
  out AAddress: IPublicKey; out ABump: Byte): Boolean;
var
  LSeeds: TArray<TBytes>;
  LSlot: TBytes;
begin
  SetLength(LSlot, 8);
  TSerialization.WriteU64(LSlot, ARecentSlot, 0);

  SetLength(LSeeds, 2);
  LSeeds[0] := AAuthority.KeyBytes;
  LSeeds[1] := LSlot;

  Result := TPublicKey.TryFindProgramAddress(LSeeds, ProgramIdKey, AAddress, ABump);
end;

class function TAddressLookupTableProgram.DeriveLookupTableAddress(
  const AAuthority: IPublicKey; const ARecentSlot: UInt64): IPublicKey;
var
  LBump: Byte;
begin
  if not TryDeriveLookupTableAddress(AAuthority, ARecentSlot, Result, LBump) then
    Result := nil;
end;

class function TAddressLookupTableProgram.CreateLookupTable(
  const AAuthority, APayer: IPublicKey; const ARecentSlot: UInt64): ITransactionInstruction;
var
  LAddress: IPublicKey;
  LBump: Byte;
begin
  if not TryDeriveLookupTableAddress(AAuthority, ARecentSlot, LAddress, LBump) then
    Exit(nil);

  Result := CreateLookupTable(AAuthority, APayer, LAddress, LBump, ARecentSlot);
end;

class function TAddressLookupTableProgram.CreateLookupTable(
  const AAuthority, APayer, ALookupTable: IPublicKey; const ABump: Byte; const ARecentSlot: UInt64): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ALookupTable, False));
  LKeys.Add(TAccountMeta.ReadOnly(AAuthority, False));
  LKeys.Add(TAccountMeta.Writable(APayer, True));
  LKeys.Add(TAccountMeta.ReadOnly(TSystemProgram.ProgramIdKey, False));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    LKeys,
    TAddressLookupTableProgramData.EncodeCreateAddressLookupTableData(ARecentSlot, ABump)
  );
end;

class function TAddressLookupTableProgram.CreateAddressLookupTable(
  const AAuthority, APayer, ALookupUpTable: IPublicKey; const ABump: Byte; const ARecentSlot: UInt64): ITransactionInstruction;
begin
  Result := CreateLookupTable(AAuthority, APayer, ALookupUpTable, ABump, ARecentSlot);
end;

class function TAddressLookupTableProgram.FreezeLookupTable(
  const ALookupTable, AAuthority: IPublicKey): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ALookupTable, False));
  LKeys.Add(TAccountMeta.ReadOnly(AAuthority, True));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    LKeys,
    TAddressLookupTableProgramData.EncodeFreezeLookupTableData
  );
end;

class function TAddressLookupTableProgram.ExtendLookupTable(
  const ALookupTable, AAuthority: IPublicKey; const AKeys: TArray<IPublicKey>): ITransactionInstruction;
begin
  Result := ExtendLookupTableInternal(ALookupTable, AAuthority, nil, AKeys);
end;

class function TAddressLookupTableProgram.ExtendLookupTable(
  const ALookupTable, AAuthority, APayer: IPublicKey; const AKeys: TArray<IPublicKey>): ITransactionInstruction;
begin
  Result := ExtendLookupTableInternal(ALookupTable, AAuthority, APayer, AKeys);
end;

class function TAddressLookupTableProgram.ExtendLookupTableInternal(
  const ALookupTable, AAuthority, APayer: IPublicKey; const AKeys: TArray<IPublicKey>): ITransactionInstruction;
var
  LMeta: TList<IAccountMeta>;
begin
  LMeta := TList<IAccountMeta>.Create;
  LMeta.Add(TAccountMeta.Writable(ALookupTable, False));
  LMeta.Add(TAccountMeta.ReadOnly(AAuthority, True));

  if APayer <> nil then
  begin
    LMeta.Add(TAccountMeta.Writable(APayer, True));
    LMeta.Add(TAccountMeta.ReadOnly(TSystemProgram.ProgramIdKey, False));
  end;

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    LMeta,
    TAddressLookupTableProgramData.EncodeExtendLookupTableData(AKeys)
  );
end;

class function TAddressLookupTableProgram.DeactivateLookupTable(
  const ALookupTable, AAuthority: IPublicKey): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ALookupTable, False));
  LKeys.Add(TAccountMeta.ReadOnly(AAuthority, True));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    LKeys,
    TAddressLookupTableProgramData.EncodeDeactivateLookupTableData
  );
end;

class function TAddressLookupTableProgram.CloseLookupTable(
  const ALookupTable, AAuthority, ARecipient: IPublicKey): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ALookupTable, False));
  LKeys.Add(TAccountMeta.ReadOnly(AAuthority, True));
  LKeys.Add(TAccountMeta.Writable(ARecipient, False));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    LKeys,
    TAddressLookupTableProgramData.EncodeCloseLookupTableData
  );
end;

class function TAddressLookupTableProgram.Decode(
  const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction;
var
  LInstruction: Cardinal;
  LInstructionValue: TAddressLookupTableProgramInstructions.TValues;
begin
  // Method id is a u32 (little-endian), unlike the u8 discriminator used by some other programs.
  LInstruction := TDeserialization.GetU32(AData, TAddressLookupTableProgramData.MethodOffset);

  if not TEnumUtilities.TryGetEnumFromOrdinal<TAddressLookupTableProgramInstructions.TValues>(
       Integer(LInstruction), LInstructionValue) then
  begin
    Result := TDecodedInstruction.Create;
    Result.PublicKey := ProgramIdKey;
    Result.InstructionName := 'Unknown Instruction';
    Result.ProgramName := ProgramName;
    Result.Values := TDictionary<string, TValue>.Create;
    Result.InnerInstructions := TList<IDecodedInstruction>.Create;
    Exit;
  end;

  Result := TDecodedInstruction.Create;
  Result.PublicKey := ProgramIdKey;
  Result.InstructionName := TAddressLookupTableProgramInstructions.Names[LInstructionValue];
  Result.ProgramName := ProgramName;
  Result.Values := TDictionary<string, TValue>.Create;
  Result.InnerInstructions := TList<IDecodedInstruction>.Create;

  case LInstructionValue of
    TAddressLookupTableProgramInstructions.TValues.CreateLookupTable:
      begin
        Result.Values.Add('Lookup Table',   TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
        Result.Values.Add('Authority',      TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
        Result.Values.Add('Payer',          TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
        Result.Values.Add('System Program', TValue.From<IPublicKey>(AKeys[AKeyIndices[3]]));
        Result.Values.Add('Recent Slot',    TValue.From<UInt64>(TDeserialization.GetU64(AData, 4)));
        Result.Values.Add('Bump Seed',      TValue.From<Byte>(TDeserialization.GetU8(AData, 12)));
      end;
    TAddressLookupTableProgramInstructions.TValues.FreezeLookupTable:
      begin
        Result.Values.Add('Lookup Table', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
        Result.Values.Add('Authority',    TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
      end;
    TAddressLookupTableProgramInstructions.TValues.ExtendLookupTable:
      begin
        Result.Values.Add('Lookup Table', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
        Result.Values.Add('Authority',    TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
        if Length(AKeyIndices) > 2 then
          Result.Values.Add('Payer', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
        Result.Values.Add('Addresses',
          TValue.From<TArray<IPublicKey>>(TAddressLookupTableProgramData.DecodeExtendLookupTableAddresses(AData)));
      end;
    TAddressLookupTableProgramInstructions.TValues.DeactivateLookupTable:
      begin
        Result.Values.Add('Lookup Table', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
        Result.Values.Add('Authority',    TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
      end;
    TAddressLookupTableProgramInstructions.TValues.CloseLookupTable:
      begin
        Result.Values.Add('Lookup Table', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
        Result.Values.Add('Authority',    TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
        Result.Values.Add('Recipient',    TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
      end;
  end;
end;

end.

