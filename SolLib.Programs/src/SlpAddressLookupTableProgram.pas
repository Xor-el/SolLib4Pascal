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

unit SlpAddressLookupTableProgram;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpPublicKey,
  SlpSerialization,
  SlpAccountDomain,
  SlpTransactionInstruction,
  SlpSystemProgram;

type
  {====================================================================================================================}
  {                                     AddressLookupTableProgramInstructions                                          }
  {====================================================================================================================}
  /// <summary>
  /// Instruction kinds for the Address Lookup Table Program, with user-friendly names.
  /// </summary>
  TAddressLookupTableProgramInstructions = class sealed
  public
    type
      TValues = (
        CreateLookupTable      = 0,
        FreezeLookupTable      = 1,
        ExtendLookupTable      = 2,
        DeactivateLookupTable  = 3,
        CloseLookupTable       = 4
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
  public
    /// <summary>
    /// Encode CreateLookupTable data.
    /// Layout:
    ///   [0..3]   : u32 method = CreateLookupTable
    ///   [4..11]  : u64 recentSlot
    ///   [12]     : u8  bump
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
    ///   [0..3]   : u32 method = ExtendLookupTable
    ///   [4..11]  : u64 keyCount
    ///   [12..]   : keyCount * 32 bytes of pubkeys
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
  public
    /// <summary>The public key of the Address Lookup Table Program.</summary>
    class property ProgramIdKey: IPublicKey read GetProgramIdKey;

    class constructor Create;
    class destructor Destroy;

    /// <summary>Create New Address Lookup Table instruction.</summary>
    class function CreateAddressLookupTable(const AAuthority, APayer, ALookupUpTable: IPublicKey;
                                           const ABump: Byte; const ARecentSlot: UInt64): ITransactionInstruction; static;

    /// <summary>Freeze Lookup Table instruction.</summary>
    class function FreezeLookupTable(const ALookupTable, AAuthority: IPublicKey): ITransactionInstruction; static;

    /// <summary>Extend Lookup Table instruction.</summary>
    class function ExtendLookupTable(const ALookupTable, AAuthority, APayer: IPublicKey;
                                     const AKeys: TArray<IPublicKey>): ITransactionInstruction; static;

    /// <summary>Deactivate Lookup Table instruction.</summary>
    class function DeactivateLookupTable(const ALookupTable, AAuthority: IPublicKey): ITransactionInstruction; static;

    /// <summary>Close Lookup Table instruction.</summary>
    class function CloseLookupTable(const ALookupTable, AAuthority, ARecipient: IPublicKey): ITransactionInstruction; static;
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
  I, LCount: Integer;
begin
  LCount := Length(AKeys);
  SetLength(Result, 12 + LCount * 32);
  // u32 method id
  TSerialization.WriteU32(Result, UInt32(TAddressLookupTableProgramInstructions.TValues.ExtendLookupTable), MethodOffset);
  // u64 key count
  TSerialization.WriteU64(Result, LCount, 4);
  // packed pubkeys
  for I := 0 to High(AKeys) do
    TSerialization.WritePubKey(Result, AKeys[I], 12 + I * 32);
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

class function TAddressLookupTableProgram.CreateAddressLookupTable(
  const AAuthority, APayer, ALookupUpTable: IPublicKey; const ABump: Byte; const ARecentSlot: UInt64): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ALookupUpTable, False));
  LKeys.Add(TAccountMeta.ReadOnly(AAuthority, False));
  LKeys.Add(TAccountMeta.Writable(APayer, True));
  LKeys.Add(TAccountMeta.ReadOnly(TSystemProgram.ProgramIdKey, False));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    LKeys,
    TAddressLookupTableProgramData.EncodeCreateAddressLookupTableData(ARecentSlot, ABump)
  );
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
  const ALookupTable, AAuthority, APayer: IPublicKey; const AKeys: TArray<IPublicKey>): ITransactionInstruction;
var
  LMeta: TList<IAccountMeta>;
begin
  LMeta := TList<IAccountMeta>.Create;
  LMeta.Add(TAccountMeta.Writable(ALookupTable, False));
  LMeta.Add(TAccountMeta.ReadOnly(AAuthority, True));
  LMeta.Add(TAccountMeta.Writable(APayer, True));
  LMeta.Add(TAccountMeta.ReadOnly(TSystemProgram.ProgramIdKey, False));

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

end.

