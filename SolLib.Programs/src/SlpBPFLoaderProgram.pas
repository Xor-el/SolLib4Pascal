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

unit SlpBPFLoaderProgram;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpPublicKey,
  SlpAccountDomain,
  SlpTransactionInstruction,
  SlpSysVars,
  SlpSystemProgram,
  SlpSerialization;

type
  {====================================================================================================================}
  {                                          BPFLoaderProgramInstructions                                             }
  {====================================================================================================================}
  /// <summary>
  /// Represents the instruction types for the Upgradeable BPF Loader along with a friendly name.
  /// <remarks>
  /// See: solana sdk UpgradeableLoaderInstruction.
  /// </remarks>
  /// </summary>
  TBPFLoaderProgramInstructions = class sealed
  public
    type
      /// <summary>Instruction tags for the Upgradeable BPF Loader program.</summary>
      TValues = (
        /// <summary>Initialize a Buffer account.</summary>
        InitializeBuffer = 0,
        /// <summary>Write bytes into a Buffer account.</summary>
        Write = 1,
        /// <summary>Deploy a program with a maximum data length.</summary>
        DeployWithMaxDataLen = 2,
        /// <summary>Upgrade a deployed program from a Buffer.</summary>
        Upgrade = 3,
        /// <summary>Set or clear authority on a Buffer/ProgramData account.</summary>
        SetAuthority = 4,
        /// <summary>Close an account owned by the upgradeable loader.</summary>
        Close = 5
      );
  private
    class var FNames: TDictionary<TValues, string>;
  public
    /// <summary>User-friendly names for instruction types.</summary>
    class property Names: TDictionary<TValues, string> read FNames;

    class constructor Create;
    class destructor Destroy;
  end;

  {====================================================================================================================}
  {                                              BPFLoaderProgramData                                                 }
  {====================================================================================================================}
  /// <summary>
  /// Implements the Upgradeable BPF Loader data encodings.
  /// </summary>
  TBPFLoaderProgramData = class sealed
  private
    /// <summary>Method tag offset (always zero).</summary>
    const MethodOffset = 0;
  public
    {---------------------------- Encoders ---------------------------------------------}
    /// <summary>Encode data for <c>InitializeBuffer</c>.</summary>
    class function EncodeInitializeBuffer: TBytes; static;

    /// <summary>
    /// Encode data for <c>Write</c>.
    /// <param name="AOffset">Offset (u32) where data should be written.</param>
    /// <param name="AData">Raw program bytes to write.</param>
    /// </summary>
    class function EncodeWrite(AOffset: UInt32; const AData: TBytes): TBytes; static;

    /// <summary>
    /// Encode data for <c>DeployWithMaxDataLen</c>.
    /// <param name="AMaxDataLen">Maximum upgradable size (u64).</param>
    /// </summary>
    class function EncodeDeployWithMaxDataLen(const AMaxDataLen: UInt64): TBytes; static;

    /// <summary>Encode data for <c>Upgrade</c>.</summary>
    class function EncodeUpgrade: TBytes; static;

    /// <summary>Encode data for <c>SetAuthority</c>.</summary>
    class function EncodeSetAuthority: TBytes; static;

    /// <summary>Encode data for <c>Close</c>.</summary>
    class function EncodeClose: TBytes; static;
  end;

  {====================================================================================================================}
  {                                                BPFLoaderProgram                                                   }
  {====================================================================================================================}
  /// <summary>
  /// Implements the Upgradeable BPF Loader Program methods.
  /// <remarks>
  /// For more information see the SDK�s <c>UpgradeableLoaderInstruction</c>.
  /// </remarks>
  /// </summary>
  TBPFLoaderProgram = class sealed
  private
    const ProgramName = 'BPF Loader Program';
    class var FProgramIdKey: IPublicKey;

    class function GetProgramIdKey: IPublicKey; static;
  public
    /// <summary>The public key of the Upgradeable BPF Loader program.</summary>
    class property ProgramIdKey: IPublicKey read GetProgramIdKey;

    class constructor Create;
    class destructor Destroy;

    /// <summary>
    /// Initialize a Buffer account.
    /// A Buffer account is an intermediary that, once fully populated, is used with the
    /// DeployWithMaxDataLen instruction to populate the program�s ProgramData account.
    /// The InitializeBuffer instruction requires no signers and MUST be included within the
    /// same Transaction as the system program�s CreateAccount instruction that creates the
    /// account being initialized. Otherwise, another party may initialize the account.
    /// </summary>
    /// <param name="ASourceAccount">Public key of the account to initialize.</param>
    /// <param name="AAuthority">Public key of the authority over the account.</param>
    /// <returns>The transaction instruction.</returns>
    class function InitializeBuffer(const ASourceAccount: IPublicKey; const AAuthority: IPublicKey = nil): ITransactionInstruction; static;

    /// <summary>
    /// Write program data into a Buffer account.
    /// </summary>
    /// <param name="ABufferAccount">Public key of the buffer account.</param>
    /// <param name="ABufferAuthority">Public key of the authority over the buffer account.</param>
    /// <param name="AData">Data to write to the buffer account (serialized program data).</param>
    /// <param name="AOffset">Offset at which to write the given data.</param>
    /// <returns>The transaction instruction.</returns>
    class function Write(const ABufferAccount, ABufferAuthority: IPublicKey; const AData: TBytes; const AOffset: UInt32): ITransactionInstruction; static;

    /// <summary>
    /// A program consists of a Program and ProgramData account pair.
    /// The Program account�s address serves as the program ID for any instructions
    /// that execute this program.
    /// The ProgramData account remains mutable by the loader only and holds the
    /// program data and authority information. The ProgramData account�s address
    /// is derived from the Program account�s address and created by the
    /// DeployWithMaxDataLen instruction.
    /// </summary>
    /// <param name="APayer">Payer account that will pay to create the ProgramData account.</param>
    /// <param name="AProgramDataAccount">Uninitialized ProgramData account.</param>
    /// <param name="AProgramAccount">Uninitialized Program account.</param>
    /// <param name="ABufferAccount">
    /// Buffer account where the program data has been written. The buffer account�s
    /// authority must match the program�s authority.
    /// </param>
    /// <param name="AAuthority">Public key of the authority.</param>
    /// <param name="AMaxDataLength">Maximum length that the program can be upgraded to.</param>
    /// <returns>The transaction instruction.</returns>
    class function DeployWithMaxDataLen(const APayer, AProgramDataAccount, AProgramAccount, ABufferAccount, AAuthority: IPublicKey;
                                        const AMaxDataLength: UInt64): ITransactionInstruction; static;

    /// <summary>
    /// Upgrade a program.
    /// A program can be updated as long as the program�s authority has not been set to None.
    /// The Buffer account must contain sufficient lamports to fund the ProgramData account
    /// to be rent-exempt. Any additional lamports left over will be transferred to the spill
    /// account, leaving the Buffer account balance at zero.
    /// </summary>
    /// <param name="AProgramDataAccount">ProgramData account.</param>
    /// <param name="AProgramAccount">Program account.</param>
    /// <param name="ABufferAccount">Buffer account containing the new program data.</param>
    /// <param name="ASpillAccount">Account to receive any excess lamports from the buffer.</param>
    /// <param name="AAuthority">Public key of the program authority.</param>
    /// <returns>The transaction instruction.</returns>
    class function Upgrade(const AProgramDataAccount, AProgramAccount, ABufferAccount, ASpillAccount, AAuthority: IPublicKey): ITransactionInstruction; static;

    /// <summary>
    /// Set a new authority that is allowed to write to the buffer or upgrade the program.
    /// To permanently make the buffer immutable or disable program updates, omit the new authority.
    /// </summary>
    /// <param name="ABufferOrProgramDataAccount">
    /// The Buffer or ProgramData account whose authority is being updated.
    /// </param>
    /// <param name="AAuthority">Current authority of the buffer or program.</param>
    /// <param name="ANewAuthority">
    /// New authority to assign. If omitted, the buffer or program becomes immutable.
    /// </param>
    /// <returns>The transaction instruction.</returns>
    class function SetAuthority(const ABufferOrProgramDataAccount, AAuthority: IPublicKey; const ANewAuthority: IPublicKey = nil): ITransactionInstruction; static;

    /// <summary>
    /// Close an account owned by the upgradeable loader and withdraw all its lamports.
    /// </summary>
    /// <param name="AAccountToClose">Public key of the account to close.</param>
    /// <param name="ADepositAccount">Public key of the account to receive the remaining lamports.</param>
    /// <param name="AAssociatedProgramAccount">Public key of the associated program account.</param>
    /// <param name="AAuthority">Public key of the authority for the account to close.</param>
    /// <returns>The transaction instruction.</returns>
    class function Close(const AAccountToClose, ADepositAccount: IPublicKey; const AAssociatedProgramAccount: IPublicKey = nil;
                         const AAuthority: IPublicKey = nil): ITransactionInstruction; static;
  end;

implementation

{ TBPFLoaderProgramInstructions }

class constructor TBPFLoaderProgramInstructions.Create;
begin
  FNames := TDictionary<TValues, string>.Create;
  FNames.Add(TValues.InitializeBuffer,      'Initialize');
  FNames.Add(TValues.Write,                 'Write');
  FNames.Add(TValues.DeployWithMaxDataLen,  'Deploy With Max Data Length');
  FNames.Add(TValues.Upgrade,               'Upgrade');
  FNames.Add(TValues.SetAuthority,          'SetAuthority');
  FNames.Add(TValues.Close,                 'Close');
end;

class destructor TBPFLoaderProgramInstructions.Destroy;
begin
  FNames.Free;
end;

{ TBPFLoaderProgramData }

class function TBPFLoaderProgramData.EncodeInitializeBuffer: TBytes;
begin
  SetLength(Result, 4);
  TSerialization.WriteU32(Result, Ord(TBPFLoaderProgramInstructions.TValues.InitializeBuffer), MethodOffset);
end;

class function TBPFLoaderProgramData.EncodeWrite(AOffset: UInt32; const AData: TBytes): TBytes;
var
  LCursor: Integer;
begin
  // size = u32(tag) + u32(offset) + (borsh vec header) + payload
  SetLength(Result, 4 + 4 + 8 + Length(AData));

  // tag
  TSerialization.WriteU32(Result, Ord(TBPFLoaderProgramInstructions.TValues.Write), MethodOffset);

  // offset (u32)
  TSerialization.WriteU32(Result, AOffset, MethodOffset + SizeOf(UInt32));

  // Borsh byte-vector (length + bytes) starting at offset 8
  LCursor := MethodOffset + SizeOf(UInt32) + SizeOf(UInt32);
  TSerialization.WriteBorshByteVector(Result, AData, LCursor);
end;

class function TBPFLoaderProgramData.EncodeDeployWithMaxDataLen(const AMaxDataLen: UInt64): TBytes;
begin
  // tag (u32) + max_len (u64)
  SetLength(Result, 4 + 8);
  TSerialization.WriteU32(Result, Ord(TBPFLoaderProgramInstructions.TValues.DeployWithMaxDataLen), MethodOffset);
  TSerialization.WriteU64(Result, AMaxDataLen, MethodOffset + SizeOf(UInt32));
end;

class function TBPFLoaderProgramData.EncodeUpgrade: TBytes;
begin
  SetLength(Result, 4);
  TSerialization.WriteU32(Result, Ord(TBPFLoaderProgramInstructions.TValues.Upgrade), MethodOffset);
end;

class function TBPFLoaderProgramData.EncodeSetAuthority: TBytes;
begin
  SetLength(Result, 4);
  TSerialization.WriteU32(Result, Ord(TBPFLoaderProgramInstructions.TValues.SetAuthority), MethodOffset);
end;

class function TBPFLoaderProgramData.EncodeClose: TBytes;
begin
  SetLength(Result, 4);
  TSerialization.WriteU32(Result, Ord(TBPFLoaderProgramInstructions.TValues.Close), MethodOffset);
end;

{ TBPFLoaderProgram }

class constructor TBPFLoaderProgram.Create;
begin
  FProgramIdKey := TPublicKey.Create('BPFLoaderUpgradeab1e11111111111111111111111');
end;

class destructor TBPFLoaderProgram.Destroy;
begin
  FProgramIdKey := nil;
end;

class function TBPFLoaderProgram.GetProgramIdKey: IPublicKey;
begin
  Result := FProgramIdKey;
end;

class function TBPFLoaderProgram.InitializeBuffer(
  const ASourceAccount, AAuthority: IPublicKey
): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ASourceAccount, False));
  if AAuthority <> nil then
    LKeys.Add(TAccountMeta.ReadOnly(AAuthority, False));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TBPFLoaderProgramData.EncodeInitializeBuffer);
end;

class function TBPFLoaderProgram.Write(
  const ABufferAccount, ABufferAuthority: IPublicKey; const AData: TBytes; const AOffset: UInt32
): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ABufferAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(ABufferAuthority, True));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes, LKeys, TBPFLoaderProgramData.EncodeWrite(AOffset, AData));
end;

class function TBPFLoaderProgram.DeployWithMaxDataLen(
  const APayer, AProgramDataAccount, AProgramAccount, ABufferAccount, AAuthority: IPublicKey;
  const AMaxDataLength: UInt64
): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.ReadOnly(APayer, True));
  LKeys.Add(TAccountMeta.Writable(AProgramDataAccount, False));
  LKeys.Add(TAccountMeta.Writable(AProgramAccount, False));
  LKeys.Add(TAccountMeta.Writable(ABufferAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));
  LKeys.Add(TAccountMeta.ReadOnly(TSysVars.ClockKey, False));
  LKeys.Add(TAccountMeta.ReadOnly(TSystemProgram.ProgramIdKey, False));
  LKeys.Add(TAccountMeta.ReadOnly(AAuthority, True));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes, LKeys, TBPFLoaderProgramData.EncodeDeployWithMaxDataLen(AMaxDataLength));
end;

class function TBPFLoaderProgram.Upgrade(
  const AProgramDataAccount, AProgramAccount, ABufferAccount, ASpillAccount, AAuthority: IPublicKey
): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AProgramDataAccount, False));
  LKeys.Add(TAccountMeta.Writable(AProgramAccount, False));
  LKeys.Add(TAccountMeta.Writable(ABufferAccount, False));
  LKeys.Add(TAccountMeta.Writable(ASpillAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));
  LKeys.Add(TAccountMeta.ReadOnly(TSysVars.ClockKey, False));
  LKeys.Add(TAccountMeta.ReadOnly(AAuthority, True));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes, LKeys, TBPFLoaderProgramData.EncodeUpgrade);
end;

class function TBPFLoaderProgram.SetAuthority(
  const ABufferOrProgramDataAccount, AAuthority, ANewAuthority: IPublicKey
): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ABufferOrProgramDataAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(AAuthority, True));
  if ANewAuthority <> nil then
    LKeys.Add(TAccountMeta.ReadOnly(ANewAuthority, False));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes, LKeys, TBPFLoaderProgramData.EncodeSetAuthority);
end;

class function TBPFLoaderProgram.Close(
  const AAccountToClose, ADepositAccount, AAssociatedProgramAccount, AAuthority: IPublicKey
): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccountToClose, False));
  LKeys.Add(TAccountMeta.Writable(ADepositAccount, False));
  if AAuthority <> nil then
    LKeys.Add(TAccountMeta.ReadOnly(AAuthority, True));
  if AAssociatedProgramAccount <> nil then
    LKeys.Add(TAccountMeta.Writable(AAssociatedProgramAccount, False));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes, LKeys, TBPFLoaderProgramData.EncodeClose);
end;

end.

