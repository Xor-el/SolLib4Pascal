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

unit SlpToken2022Program;

{$I ../Include/SolLib.inc}

interface

uses
  SysUtils,
  Generics.Collections,
  Rtti,
  TypInfo,
  SlpEnumUtilities,
  SlpPublicKey,
  SlpAccount,
  SlpAccountDomain,
  SlpTransactionInstruction,
  SlpSysVars,
  SlpDeserialization,
  SlpSerialization,
  SlpDecodedInstruction,
  SlpSystemProgram,
  SlpTokenProgram,
  SlpToken2022ExtensionType;

type
  {====================================================================================================================}
  {                                               Token2022ProgramInstructions                                         }
  {====================================================================================================================}
  /// <summary>
  /// Represents the instruction types for the Token (and Token-2022) Program along with a friendly name.
  /// <remarks>
  /// For more information see:
  /// https://spl.solana.com/token
  /// https://docs.rs/spl-token/3.2.0/spl_token/
  /// Token-2022 uses the same core instruction discriminants.
  /// </remarks>
  /// </summary>
  TToken2022ProgramInstructions = class sealed
  public
    /// <summary>
    /// Represents the instruction types for the TokenProgram.
    /// </summary>
    type
      tValues = (
        /// <summary>
        /// Initialize a token mint.
        /// </summary>
        InitializeMint = 0,

        /// <summary>
        /// Initialize a token account.
        /// </summary>
        InitializeAccount = 1,

        /// <summary>
        /// Initialize a multi signature token account.
        /// </summary>
        InitializeMultiSignature = 2,

        /// <summary>
        /// Transfer token transaction.
        /// </summary>
        Transfer = 3,

        /// <summary>
        /// Approve token transaction.
        /// </summary>
        Approve = 4,

        /// <summary>
        /// Revoke token transaction.
        /// </summary>
        Revoke = 5,

        /// <summary>
        /// Set token authority transaction.
        /// </summary>
        SetAuthority = 6,

        /// <summary>
        /// MintTo token account transaction.
        /// </summary>
        MintTo = 7,

        /// <summary>
        /// Burn token transaction.
        /// </summary>
        Burn = 8,

        /// <summary>
        /// Close token account transaction.
        /// </summary>
        CloseAccount = 9,

        /// <summary>
        /// Freeze token account transaction.
        /// </summary>
        FreezeAccount = 10,

        /// <summary>
        /// Thaw token account transaction.
        /// </summary>
        ThawAccount = 11,

        /// <summary>
        /// Transfer checked token transaction.
        /// <remarks>Differs from Transfer in that the decimals value is asserted by the caller.</remarks>
        /// </summary>
        TransferChecked = 12,

        /// <summary>
        /// Approve checked token transaction.
        /// <remarks>Differs from Approve in that the decimals value is asserted by the caller.</remarks>
        /// </summary>
        ApproveChecked = 13,

        /// <summary>
        /// MintTo checked token transaction.
        /// <remarks>Differs from MintTo in that the decimals value is asserted by the caller.</remarks>
        /// </summary>
        MintToChecked = 14,

        /// <summary>
        /// Burn checked token transaction.
        /// <remarks>Differs from Burn in that the decimals value is asserted by the caller.</remarks>
        /// </summary>
        BurnChecked = 15,

        /// <summary>
        /// Like InitializeAccount, but the owner pubkey is passed via instruction data
        /// rather than the accounts list. This variant may be preferable when using
        /// Cross Program Invocation from an instruction that does not need the owner's
        /// AccountInfo otherwise.
        /// </summary>
        InitializeAccount2 = 16,

        /// <summary>
        /// SyncNative token transaction.
        /// Given a wrapped / native token account (a token account containing SOL)
        /// updates its amount field based on the account's underlying lamports.
        /// This is useful if a non-wrapped SOL account uses system_instruction::transfer
        /// to move lamports to a wrapped token account, and needs to have its token
        /// amount field updated.
        /// </summary>
        SyncNative = 17,

        /// <summary>
        /// Like InitializeAccount2, but does not require the Rent sysvar to be provided.
        /// </summary>
        InitializeAccount3 = 18,

        /// <summary>
        /// Like InitializeMultisig, but does not require the Rent sysvar to be provided.
        /// </summary>
        InitializeMultiSignature2 = 19,

        /// <summary>
        /// Like InitializeMint, but does not require the Rent sysvar to be provided.
        /// </summary>
        InitializeMint2 = 20,

        /// <summary>
        /// Gets the required size of an account for the given mint as a little-endian u64.
        /// </summary>
        GetAccountDataSize = 21,

        /// <summary>
        /// Initialize the Immutable Owner extension for the given token account.
        /// </summary>
        InitializeImmutableOwner = 22,

        /// <summary>
        /// Convert an Amount of tokens to a UiAmount string, using the given mint.
        /// In this version of the program, the mint can only specify the number of decimals.
        /// </summary>
        AmountToUiAmount = 23,

        /// <summary>
        /// Convert a UiAmount of tokens to a little-endian u64 raw Amount, using the given mint.
        /// In this version of the program, the mint can only specify the number of decimals.
        /// </summary>
        UiAmountToAmount = 24,

        /// <summary>
        /// Initialize the close authority on a mint.
        /// </summary>
        InitializeMintCloseAuthority = 25,

        /// <summary>Transfer fee extension instruction gate (unimplemented).</summary>
        TransferFeeExtension = 26,

        /// <summary>Confidential transfer extension instruction gate (unimplemented).</summary>
        ConfidentialTransferExtension = 27,

        /// <summary>Default account state extension instruction gate (unimplemented).</summary>
        DefaultAccountStateExtension = 28,

        /// <summary>
        /// Reallocate a token account to fit the given extension types.
        /// </summary>
        Reallocate = 29
      );

  private
    class var FNames: TDictionary<TValues, string>;
  public
    /// <summary>Represents the user-friendly names for the instruction types.</summary>
    class property Names: TDictionary<TValues, string> read FNames;

    class constructor Create;
    class destructor Destroy;
  end;


  {====================================================================================================================}
  {                                                   Token2022Program                                                }
  {====================================================================================================================}
  /// <summary>
  /// Implements the Token 2022 Program methods.
  /// </summary>
  TToken2022Program = class sealed
  private
    const ProgramName = 'Token 2022 Program';
    class var FProgramIdKey: IPublicKey;
    class var FNativeMintProgramIdKey: IPublicKey;
    class function GetProgramIdKey: IPublicKey; static;
    class function GetNativeMintProgramIdKey: IPublicKey; static;

    /// <summary>
    /// Adds the list of signers to the list of keys.
    /// </summary>
    /// <param name="AKeys">The instruction's list of keys.</param>
    /// <param name="AAuthority">The public key of the authority account.</param>
    /// <param name="ASigners">The list of signers.</param>
    /// <returns>The list of keys with the added signers.</returns>
    class function AddSigners(const AKeys: TList<IAccountMeta>;
                              const AAuthority: IPublicKey;
                              const ASigners: TArray<IPublicKey> = nil): TList<IAccountMeta>; static;
  public
    /// <summary>The public key of the Token 2022 Program.</summary>
    class property ProgramIdKey: IPublicKey read GetProgramIdKey;

    /// <summary>The public key of the Token-2022 native mint.</summary>
    class property NativeMintProgramIdKey: IPublicKey read GetNativeMintProgramIdKey;

    /// <summary>Mint account layout size.</summary>
    const MintAccountDataSize = 82;
    /// <summary>Token account layout size.</summary>
    const TokenAccountDataSize = 165;
    /// <summary>Multisig account layout size.</summary>
    const MultisigAccountDataSize = 355;

    class constructor Create;
    class destructor Destroy;

    /// <summary>
    /// Initializes an instruction to transfer tokens from one account to another either directly or via a delegate.
    /// If this account is associated with the native mint then equal amounts of SOL and Tokens will be transferred to the destination account.
    /// </summary>
    /// <param name="ASource">The public key of the account to transfer tokens from.</param>
    /// <param name="ADestination">The public key of the account to account to transfer tokens to.</param>
    /// <param name="AAmount">The amount of tokens to transfer.</param>
    /// <param name="AAuthority">The public key of the authority.</param>
    /// <param name="ASigners">Signing accounts if the <c>authority</c> is a multi signature.</param>
    /// <returns>The transaction instruction.</returns>
    class function Transfer(const ASource, ADestination: IPublicKey; const AAmount: UInt64;
                            const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>
    /// <para>
    /// Initializes an instruction to transfer tokens from one account to another either directly or via a delegate.
    /// If this account is associated with the native mint then equal amounts of SOL and Tokens will be transferred to the destination account.
    /// </para>
    /// <para>
    /// This instruction differs from Transfer in that the token mint and decimals value is checked by the caller.
    /// This may be useful when creating transactions offline or within a hardware wallet.
    /// </para>
    /// </summary>
    /// <param name="ASource">The public key of the account to transfer tokens from.</param>
    /// <param name="ADestination">The public key of the account to account to transfer tokens to.</param>
    /// <param name="AAmount">The amount of tokens to transfer.</param>
    /// <param name="ADecimals">The token decimals.</param>
    /// <param name="AAuthority">The public key of the authority account.</param>
    /// <param name="ATokenMint">The public key of the token mint.</param>
    /// <param name="ASigners">Signing accounts if the <c>authority</c> is a multi signature.</param>
    /// <returns>The transaction instruction.</returns>
    class function TransferChecked(const ASource, ADestination: IPublicKey; const AAmount: UInt64; const ADecimals: Integer;
                                   const AAuthority, ATokenMint: IPublicKey; const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>
    /// <para>Initializes an instruction to initialize a new account to hold tokens.
    /// If this account is associated with the native mint then the token balance of the initialized account will be equal to the amount of SOL in the account.
    /// If this account is associated with another mint, that mint must be initialized before this command can succeed.
    /// </para>
    /// <para>
    /// The InitializeAccount instruction requires no signers and MUST be included within the same Transaction
    /// as the system program's <see cref="SystemProgram.CreateAccount(PublicKey,PublicKey,ulong,ulong,PublicKey)"/>"/>
    /// instruction that creates the account being initialized.
    /// Otherwise another party can acquire ownership of the uninitialized account.
    /// </para>
    /// </summary>
    /// <param name="AAccount">The public key of the account to initialize.</param>
    /// <param name="AMint">The public key of the token mint.</param>
    /// <param name="AAuthority">The public key of the account to set as authority of the initialized account.</param>
    /// <returns>The transaction instruction.</returns>
    class function InitializeAccount(const AAccount, AMint, AAuthority: IPublicKey): ITransactionInstruction; static;

    /// <summary>
    /// Initializes an instruction to initialize a multi signature token account.
    /// </summary>
    /// <param name="AMultiSignature">Public key of the multi signature account.</param>
    /// <param name="ASigners">Addresses of multi signature signers.</param>
    /// <param name="AM">The number of signatures required to validate this multi signature account.</param>
    class function InitializeMultiSignature(const AMultiSignature: IPublicKey; const ASigners: TArray<IPublicKey>;
                                            const AM: Integer): ITransactionInstruction; static;
    /// <summary>
    /// Initializes an instruction to transfer tokens from one account to another either directly or via a delegate.
    /// If this account is associated with the native mint then equal amounts of SOL and Tokens will be transferred to the destination account.
    /// </summary>
    /// <param name="AMint">The public key of the token mint.</param>
    /// <param name="ADecimals">The token decimals.</param>
    /// <param name="AMintAuthority">The public key of the token mint authority.</param>
    /// <param name="AFreezeAuthority">The token freeze authority.</param>
    class function InitializeMint(const AMint: IPublicKey; const ADecimals: Integer;
                                  const AMintAuthority: IPublicKey; const AFreezeAuthority: IPublicKey = nil): ITransactionInstruction; static;
    /// <summary>
    /// Initializes an instruction to mint tokens to a destination account.
    /// </summary>
    /// <param name="AMint">The public key token mint.</param>
    /// <param name="ADestination">The public key of the account to mint tokens to.</param>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <param name="AMintAuthority">The token mint authority account.</param>
    /// <param name="ASigners">Signing accounts if the <c>authority</c> is a multi signature.</param>
    /// <returns>The transaction instruction.</returns>
    class function MintTo(const AMint, ADestination: IPublicKey; const AAmount: UInt64;
                          const AMintAuthority: IPublicKey; const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>
    /// Initializes an instruction to approve a transaction.
    /// </summary>
    /// <param name="ASource">The public key source account.</param>
    /// <param name="ADelegatePublicKey">The public key of the delegate account authorized to perform a transfer from the source account.</param>
    /// <param name="AAuthority">The public key of the authority of the source account.</param>
    /// <param name="AAmount">The maximum amount of tokens the delegate may transfer.</param>
    /// <param name="ASigners">Signing accounts if the <c>authority</c> is a multi signature.</param>
    /// <returns>The transaction instruction.</returns>
    class function Approve(const ASource, ADelegate, AAuthority: IPublicKey; const AAmount: UInt64;
                           const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>
    /// Initializes an instruction to revoke a transaction.
    /// </summary>
    /// <param name="ASource">The public key source account.</param>
    /// <param name="AAuthority">The public key of the authority of the source account.</param>
    /// <param name="ASigners">Signing accounts if the <c>authority</c> is a multi signature.</param>
    /// <returns>The transaction instruction.</returns>
    class function Revoke(const ASource, AAuthority: IPublicKey; const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>
    /// Initialize an instruction to set an authority on an account.
    /// </summary>
    /// <param name="AAccount">The public key of the account to set the authority on.</param>
    /// <param name="AAuthority">The type of authority to set.</param>
    /// <param name="ACurrentAuthority">The public key of the current authority of the specified type.</param>
    /// <param name="ANewAuthority">The public key of the new authority.</param>
    /// <param name="ASigners">Signing accounts if the <c>authority</c> is a multi signature.</param>
    /// <returns>The transaction instruction.</returns>
    class function SetAuthority(const AAccount: IPublicKey; const AAuthorityType: TAuthorityType;
                                const ACurrentAuthority: IPublicKey; const ANewAuthority: IPublicKey = nil;
                                const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;
    /// <summary>
    /// Initialize an instruction to burn tokens.
    /// </summary>
    /// <param name="ASource">The public key of the account to burn tokens from.</param>
    /// <param name="AMint">The public key of the token mint.</param>
    /// <param name="AAmount">The amount of tokens to burn.</param>
    /// <param name="AAuthority">The public key of the authority of the source account.</param>
    /// <param name="ASigners">Signing accounts if the <c>authority</c> is a multi signature.</param>
    /// <returns>The transaction instruction.</returns>
    class function Burn(const ASource, AMint: IPublicKey; const AAmount: UInt64;
                        const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>
    /// Initialize an instruction to close an account.
    /// </summary>
    /// <param name="AAccount">The public key of the account to close.</param>
    /// <param name="ADestination">The public key of the account that will receive the SOL.</param>
    /// <param name="AAuthority">The public key of the authority of the source account.</param>
    /// <param name="AProgramId">The public key which represents the associated program id.</param>
    /// <param name="ASigners">Signing accounts if the <c>authority</c> is a multi signature.</param>
    /// <returns>The transaction instruction.</returns>
    class function CloseAccount(const AAccount, ADestination, AAuthority, AProgramId: IPublicKey;
                                const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>
    /// Initialize an instruction to freeze a token account.
    /// </summary>
    /// <param name="AAccount">The public key of the account to freeze.</param>
    /// <param name="AMint">The public key of the token mint.</param>
    /// <param name="AFreezeAuthority">The public key of the authority of the freeze authority for the token mint.</param>
    /// <param name="AProgramId">The public key which represents the associated program id.</param>
    /// <param name="ASigners">Signing accounts if the <c>freezeAuthority</c> is a multi signature.</param>
    /// <returns>The transaction instruction.</returns>
    class function FreezeAccount(const AAccount, AMint, AFreezeAuthority, AProgramId: IPublicKey;
                                 const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;
    /// <summary>
    /// Initialize an instruction to thaw a token account.
    /// </summary>
    /// <param name="AAccount">The public key of the account to thaw.</param>
    /// <param name="AMint">The public key of the token mint.</param>
    /// <param name="AFreezeAuthority">The public key of the freeze authority for the token mint.</param>
    /// <param name="AProgramId">The public key which represents the associated program id.</param>
    /// <param name="ASigners">Signing accounts if the <c>authority</c> is a multi signature.</param>
    /// <returns>The transaction instruction.</returns>
    class function ThawAccount(const AAccount, AMint, AFreezeAuthority, AProgramId: IPublicKey;
                               const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;
    /// <summary>
    /// Initialize an instruction to approve a transaction.
    /// <para>
    /// This instruction differs from Approve in that the amount and decimals value is checked by the caller.
    /// This may be useful when creating transactions offline or within a hardware wallet.
    /// </para>
    /// </summary>
    /// <param name="ASource">The public key of the source account.</param>
    /// <param name="ADelegatePublicKey">The public key of the delegate account authorized to perform a transfer from the source account.</param>
    /// <param name="AAuthority">The public key of the authority of the source account.</param>
    /// <param name="AAmount">The maximum amount of tokens the delegate may transfer.</param>
    /// <param name="ASigners">Signing accounts if the <c>authority</c> is a multi signature.</param>
    /// <param name="ADecimals">The token decimals.</param>
    /// <param name="AMint">The public key of the token mint.</param>
    /// <returns>The transaction instruction.</returns>
    class function ApproveChecked(const ASource, ADelegate: IPublicKey; const AAmount: UInt64; const ADecimals: Byte;
                                  const AAuthority, AMint: IPublicKey; const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>
    /// Initialize an instruction to approve a transaction.
    /// <para>
    /// This instruction differs from MintTo in that the amount and decimals value is checked by the caller.
    /// This may be useful when creating transactions offline or within a hardware wallet.
    /// </para>
    /// </summary>
    /// <param name="AMint">The public key of the token mint.</param>
    /// <param name="ADestination">The public key of the account to mint tokens to.</param>
    /// <param name="AMintAuthority">The public key of the token's mint authority account.</param>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <param name="ADecimals">The token decimals.</param>
    /// <param name="ASigners">Signing accounts if the <c>mintAuthority</c> is a multi signature.</param>
    /// <returns>The transaction instruction.</returns>
    class function MintToChecked(const AMint, ADestination, AMintAuthority: IPublicKey;
                                 const AAmount: UInt64; const ADecimals: Integer;
                                 const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>
    /// Initialize an instruction to burn tokens.
    /// <para>
    /// This instruction differs from Burn in that the amount and decimals value is checked by the caller.
    /// This may be useful when creating transactions offline or within a hardware wallet.
    /// </para>
    /// </summary>
    /// <param name="AMint">The public key of the token mint.</param>
    /// <param name="AAccount">The public key of the account to burn from.</param>
    /// <param name="AAuthority">The public key of the authority of the source account.</param>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <param name="ADecimals">The token decimals.</param>
    /// <param name="ASigners">Signing accounts if the <c>authority</c> is a multi signature.</param>
    /// <returns>The transaction instruction.</returns>
    class function BurnChecked(const AMint, AAccount, AAuthority: IPublicKey;
                               const AAmount: UInt64; const ADecimals: Integer;
                               const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;
    /// <summary>
    /// Initialize an instruction to sync native tokens.
    /// </summary>
    /// <param name="AAccount">The public key of the token account.</param>
    /// <returns>The transaction instruction.</returns>
    class function SyncNative(const AAccount: IPublicKey): ITransactionInstruction; static;

    /// <summary>Initializes a token account whose owner is passed in the instruction data (requires the Rent sysvar).</summary>
    class function InitializeAccount2(const AAccount, AMint, AOwner: IPublicKey): ITransactionInstruction; static;

    /// <summary>Initializes a token account whose owner is passed in the instruction data (no Rent sysvar).</summary>
    class function InitializeAccount3(const AAccount, AMint, AOwner: IPublicKey): ITransactionInstruction; static;

    /// <summary>Initializes a multi signature token account without the Rent sysvar.</summary>
    class function InitializeMultiSignature2(const AMultiSignature: IPublicKey; const ASigners: TArray<IPublicKey>;
                                             const AM: Integer): ITransactionInstruction; static;

    /// <summary>Initializes a mint without the Rent sysvar.</summary>
    class function InitializeMint2(const AMint: IPublicKey; const ADecimals: Integer;
                                   const AMintAuthority: IPublicKey; const AFreezeAuthority: IPublicKey = nil): ITransactionInstruction; static;

    /// <summary>Initializes the immutable owner extension for a token account.</summary>
    class function InitializeImmutableOwner(const AAccount: IPublicKey): ITransactionInstruction; static;

    /// <summary>Returns the required account data size for the given mint and extension types.</summary>
    class function GetAccountDataSize(const AMint: IPublicKey;
                                      const AExtensionTypes: TArray<TToken2022ExtensionType>): ITransactionInstruction; static;

    /// <summary>Converts a raw amount to a UI amount string, using the given mint.</summary>
    class function AmountToUiAmount(const AMint: IPublicKey; const AAmount: UInt64): ITransactionInstruction; static;

    /// <summary>Converts a UI amount string to a raw amount, using the given mint.</summary>
    class function UiAmountToAmount(const AMint: IPublicKey; const AUiAmount: string): ITransactionInstruction; static;

    /// <summary>Initializes the close authority on a mint (a nil authority clears it).</summary>
    class function InitializeMintCloseAuthority(const AMint: IPublicKey;
                                                const ACloseAuthority: IPublicKey = nil): ITransactionInstruction; static;

    /// <summary>Reallocates a token account to fit the given extension types.</summary>
    class function Reallocate(const AAccount, APayer, AOwner: IPublicKey;
                             const AExtensionTypes: TArray<TToken2022ExtensionType>;
                             const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>
    /// Decodes an instruction created by the System Program.
    /// </summary>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    /// <returns>A decoded instruction.</returns>
    class function Decode(const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction; static;
  end;

implementation

{ TTokenProgramInstructions }

class constructor TToken2022ProgramInstructions.Create;
begin
  FNames := TDictionary<TValues, string>.Create;
  FNames.Add(TValues.InitializeMint, 'Initialize Mint');
  FNames.Add(TValues.InitializeAccount, 'Initialize Account');
  FNames.Add(TValues.InitializeMultiSignature, 'Initialize Multisig');
  FNames.Add(TValues.Transfer, 'Transfer');
  FNames.Add(TValues.Approve, 'Approve');
  FNames.Add(TValues.Revoke, 'Revoke');
  FNames.Add(TValues.SetAuthority, 'Set Authority');
  FNames.Add(TValues.MintTo, 'Mint To');
  FNames.Add(TValues.Burn, 'Burn');
  FNames.Add(TValues.CloseAccount, 'Close Account');
  FNames.Add(TValues.FreezeAccount, 'Freeze Account');
  FNames.Add(TValues.ThawAccount, 'Thaw Account');
  FNames.Add(TValues.TransferChecked, 'Transfer Checked');
  FNames.Add(TValues.ApproveChecked, 'Approve Checked');
  FNames.Add(TValues.MintToChecked, 'Mint To Checked');
  FNames.Add(TValues.BurnChecked, 'Burn Checked');
  FNames.Add(TValues.SyncNative, 'Sync Native');
  FNames.Add(TValues.InitializeAccount2, 'Initialize Account 2');
  FNames.Add(TValues.InitializeAccount3, 'Initialize Account 3');
  FNames.Add(TValues.InitializeMultiSignature2, 'Initialize Multisig 2');
  FNames.Add(TValues.InitializeMint2, 'Initialize Mint 2');
  FNames.Add(TValues.GetAccountDataSize, 'Get Account Data Size');
  FNames.Add(TValues.InitializeImmutableOwner, 'Initialize Immutable Owner');
  FNames.Add(TValues.AmountToUiAmount, 'Amount To Ui Amount');
  FNames.Add(TValues.UiAmountToAmount, 'Ui Amount To Amount');
  FNames.Add(TValues.InitializeMintCloseAuthority, 'Initialize Mint Close Authority');
  FNames.Add(TValues.TransferFeeExtension, 'Transfer Fee Extension');
  FNames.Add(TValues.ConfidentialTransferExtension, 'Confidential Transfer Extension');
  FNames.Add(TValues.DefaultAccountStateExtension, 'Default Account State Extension');
  FNames.Add(TValues.Reallocate, 'Reallocate');
end;

class destructor TToken2022ProgramInstructions.Destroy;
begin
  FNames.Free;
end;


{ TToken2022Program }

class constructor TToken2022Program.Create;
begin
  FProgramIdKey := TPublicKey.Create('TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb');
  FNativeMintProgramIdKey := TPublicKey.Create('9pan9bMn5HatX4EJdBwg9VgCa7Uz5HL8N1m5D3NdXejP');
end;

class destructor TToken2022Program.Destroy;
begin
  FProgramIdKey := nil;
  FNativeMintProgramIdKey := nil;
end;

class function TToken2022Program.GetProgramIdKey: IPublicKey;
begin
  Result := FProgramIdKey;
end;

class function TToken2022Program.GetNativeMintProgramIdKey: IPublicKey;
begin
  Result := FNativeMintProgramIdKey;
end;

class function TToken2022Program.AddSigners(const AKeys: TList<IAccountMeta>;
  const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): TList<IAccountMeta>;
var
  LSigner: IPublicKey;
begin
  Result := AKeys;
  if (ASigners <> nil) then
  begin
    Result.Add(TAccountMeta.ReadOnly(AAuthority, False));
    for LSigner in ASigners do
      Result.Add(TAccountMeta.ReadOnly(LSigner, True));
  end
  else
  begin
    Result.Add(TAccountMeta.ReadOnly(AAuthority, True));
  end;
end;

class function TToken2022Program.Transfer(const ASource, ADestination: IPublicKey; const AAmount: UInt64;
  const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ASource, False));
  LKeys.Add(TAccountMeta.Writable(ADestination, False));
  LKeys := AddSigners(LKeys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeTransferData(AAmount));
end;

class function TToken2022Program.TransferChecked(const ASource, ADestination: IPublicKey; const AAmount: UInt64; const ADecimals: Integer;
  const AAuthority, ATokenMint: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ASource, False));
  LKeys.Add(TAccountMeta.ReadOnly(ATokenMint, False));
  LKeys.Add(TAccountMeta.Writable(ADestination, False));
  LKeys := AddSigners(LKeys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeTransferCheckedData(AAmount, ADecimals));
end;

class function TToken2022Program.InitializeAccount(const AAccount, AMint, AAuthority: IPublicKey): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(AMint, False));
  LKeys.Add(TAccountMeta.ReadOnly(AAuthority, False));
  LKeys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeInitializeAccountData);
end;

class function TToken2022Program.InitializeMultiSignature(const AMultiSignature: IPublicKey; const ASigners: TArray<IPublicKey>;
  const AM: Integer): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
  LSigner: IPublicKey;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AMultiSignature, False));
  LKeys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));
  for LSigner in ASigners do
    LKeys.Add(TAccountMeta.ReadOnly(LSigner, False));
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeInitializeMultiSignatureData(AM));
end;

class function TToken2022Program.InitializeMint(const AMint: IPublicKey; const ADecimals: Integer;
  const AMintAuthority, AFreezeAuthority: IPublicKey): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
  LFreezeOpt: Integer;
  LFreezeKey: IPublicKey;
  LAccount: IAccount;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AMint, False));
  LKeys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));

  LFreezeOpt := Ord(Assigned(AFreezeAuthority));
  if Assigned(AFreezeAuthority) then
    LFreezeKey := AFreezeAuthority
  else
  begin
    LAccount := TAccount.Create;
    LFreezeKey := LAccount.PublicKey;
  end;

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys,
    TTokenProgramData.EncodeInitializeMintData(AMintAuthority, LFreezeKey, ADecimals, LFreezeOpt));
end;

class function TToken2022Program.MintTo(const AMint, ADestination: IPublicKey; const AAmount: UInt64;
  const AMintAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AMint, False));
  LKeys.Add(TAccountMeta.Writable(ADestination, False));
  LKeys := AddSigners(LKeys, AMintAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeMintToData(AAmount));
end;

class function TToken2022Program.Approve(const ASource, ADelegate, AAuthority: IPublicKey; const AAmount: UInt64;
  const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ASource, False));
  LKeys.Add(TAccountMeta.ReadOnly(ADelegate, False));
  LKeys := AddSigners(LKeys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeApproveData(AAmount));
end;

class function TToken2022Program.Revoke(const ASource, AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ASource, False));
  LKeys := AddSigners(LKeys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeRevokeData);
end;

class function TToken2022Program.SetAuthority(const AAccount: IPublicKey; const AAuthorityType: TAuthorityType;
  const ACurrentAuthority, ANewAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
  LOpt: Integer;
  LNewAuth: IPublicKey;
  LAccount: IAccount;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  LKeys := AddSigners(LKeys, ACurrentAuthority, ASigners);

  LOpt := Ord(Assigned(ANewAuthority));
  if Assigned(ANewAuthority) then
    LNewAuth := ANewAuthority
  else
  begin
    LAccount := TAccount.Create;
    LNewAuth := LAccount.PublicKey;
  end;

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys,
    TTokenProgramData.EncodeSetAuthorityData(AAuthorityType, LOpt, LNewAuth));
end;

class function TToken2022Program.Burn(const ASource, AMint: IPublicKey; const AAmount: UInt64;
  const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ASource, False));
  LKeys.Add(TAccountMeta.Writable(AMint, False));
  LKeys := AddSigners(LKeys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeBurnData(AAmount));
end;

class function TToken2022Program.CloseAccount(const AAccount, ADestination, AAuthority, AProgramId: IPublicKey;
  const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  LKeys.Add(TAccountMeta.Writable(ADestination, False));
  LKeys := AddSigners(LKeys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeCloseAccountData);
end;

class function TToken2022Program.FreezeAccount(const AAccount, AMint, AFreezeAuthority, AProgramId: IPublicKey;
  const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(AMint, False));
  LKeys := AddSigners(LKeys, AFreezeAuthority, ASigners);
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeFreezeAccountData);
end;

class function TToken2022Program.ThawAccount(const AAccount, AMint, AFreezeAuthority, AProgramId: IPublicKey;
  const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(AMint, False));
  LKeys := AddSigners(LKeys, AFreezeAuthority, ASigners);
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeThawAccountData);
end;

class function TToken2022Program.ApproveChecked(const ASource, ADelegate: IPublicKey; const AAmount: UInt64; const ADecimals: Byte;
  const AAuthority, AMint: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ASource, False));
  LKeys.Add(TAccountMeta.ReadOnly(AMint, False));
  LKeys.Add(TAccountMeta.ReadOnly(ADelegate, False));
  LKeys := AddSigners(LKeys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeApproveCheckedData(AAmount, ADecimals));
end;

class function TToken2022Program.MintToChecked(const AMint, ADestination, AMintAuthority: IPublicKey;
  const AAmount: UInt64; const ADecimals: Integer; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AMint, False));
  LKeys.Add(TAccountMeta.Writable(ADestination, False));
  LKeys := AddSigners(LKeys, AMintAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeMintToCheckedData(AAmount, ADecimals));
end;

class function TToken2022Program.BurnChecked(const AMint, AAccount, AAuthority: IPublicKey;
  const AAmount: UInt64; const ADecimals: Integer; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  LKeys.Add(TAccountMeta.Writable(AMint, False));
  LKeys := AddSigners(LKeys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeBurnCheckedData(AAmount, ADecimals));
end;

class function TToken2022Program.SyncNative(const AAccount: IPublicKey): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeSyncNativeData);
end;

class function TToken2022Program.InitializeAccount2(const AAccount, AMint, AOwner: IPublicKey): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(AMint, False));
  LKeys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeInitializeAccount2Data(AOwner));
end;

class function TToken2022Program.InitializeAccount3(const AAccount, AMint, AOwner: IPublicKey): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(AMint, False));
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeInitializeAccount3Data(AOwner));
end;

class function TToken2022Program.InitializeMultiSignature2(const AMultiSignature: IPublicKey; const ASigners: TArray<IPublicKey>;
  const AM: Integer): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
  LSigner: IPublicKey;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AMultiSignature, False));
  for LSigner in ASigners do
    LKeys.Add(TAccountMeta.ReadOnly(LSigner, False));
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeInitializeMultiSignature2Data(AM));
end;

class function TToken2022Program.InitializeMint2(const AMint: IPublicKey; const ADecimals: Integer;
  const AMintAuthority, AFreezeAuthority: IPublicKey): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
  LFreezeOpt: Integer;
  LFreezeKey: IPublicKey;
  LAccount: IAccount;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AMint, False));

  LFreezeOpt := Ord(Assigned(AFreezeAuthority));
  if Assigned(AFreezeAuthority) then
    LFreezeKey := AFreezeAuthority
  else
  begin
    LAccount := TAccount.Create;
    LFreezeKey := LAccount.PublicKey;
  end;

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys,
    TTokenProgramData.EncodeInitializeMint2Data(AMintAuthority, LFreezeKey, ADecimals, LFreezeOpt));
end;

class function TToken2022Program.InitializeImmutableOwner(const AAccount: IPublicKey): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeInitializeImmutableOwnerData);
end;

class function TToken2022Program.GetAccountDataSize(const AMint: IPublicKey;
  const AExtensionTypes: TArray<TToken2022ExtensionType>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.ReadOnly(AMint, False));
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeGetAccountDataSizeData(AExtensionTypes));
end;

class function TToken2022Program.AmountToUiAmount(const AMint: IPublicKey; const AAmount: UInt64): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.ReadOnly(AMint, False));
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeAmountToUiAmountData(AAmount));
end;

class function TToken2022Program.UiAmountToAmount(const AMint: IPublicKey; const AUiAmount: string): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.ReadOnly(AMint, False));
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeUiAmountToAmountData(AUiAmount));
end;

class function TToken2022Program.InitializeMintCloseAuthority(const AMint: IPublicKey;
  const ACloseAuthority: IPublicKey): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AMint, False));
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeInitializeMintCloseAuthorityData(ACloseAuthority));
end;

class function TToken2022Program.Reallocate(const AAccount, APayer, AOwner: IPublicKey;
  const AExtensionTypes: TArray<TToken2022ExtensionType>; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  LKeys.Add(TAccountMeta.Writable(APayer, True));
  LKeys.Add(TAccountMeta.ReadOnly(TSystemProgram.ProgramIdKey, False));
  LKeys := AddSigners(LKeys, AOwner, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, TTokenProgramData.EncodeReallocateData(AExtensionTypes));
end;

class function TToken2022Program.Decode(const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction;
var
  LInstruction: Byte;
  LInstructionValue: TToken2022ProgramInstructions.TValues;
begin
  LInstruction := TDeserialization.GetU8(AData, TTokenProgramData.MethodOffset);

  if not TEnumUtilities.TryGetEnumFromOrdinal<TToken2022ProgramInstructions.TValues>(LInstruction, LInstructionValue) then
  begin
    Result := TDecodedInstruction.Create;
    Result.PublicKey := ProgramIdKey;
    Result.InstructionName := 'Unknown Instruction';
    Result.ProgramName := ProgramName;
    Result.Values := TDictionary<string, TValue>.Create;
    Result.InnerInstructions := TList<IDecodedInstruction>.Create();
    Exit;
  end;

  Result := TDecodedInstruction.Create;
  Result.PublicKey := ProgramIdKey;
  Result.InstructionName := TToken2022ProgramInstructions.Names[LInstructionValue];
  Result.ProgramName := ProgramName;
  Result.Values := TDictionary<string, TValue>.Create;
  Result.InnerInstructions := TList<IDecodedInstruction>.Create();

  case LInstructionValue of
    TToken2022ProgramInstructions.TValues.InitializeMint:
      TTokenProgramData.DecodeInitializeMintData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.InitializeAccount:
      TTokenProgramData.DecodeInitializeAccountData(Result, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.InitializeMultiSignature:
      TTokenProgramData.DecodeInitializeMultiSignatureData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.Transfer:
      TTokenProgramData.DecodeTransferData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.Approve:
      TTokenProgramData.DecodeApproveData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.Revoke:
      TTokenProgramData.DecodeRevokeData(Result, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.SetAuthority:
      TTokenProgramData.DecodeSetAuthorityData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.MintTo:
      TTokenProgramData.DecodeMintToData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.Burn:
      TTokenProgramData.DecodeBurnData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.CloseAccount:
      TTokenProgramData.DecodeCloseAccountData(Result, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.FreezeAccount:
      TTokenProgramData.DecodeFreezeAccountData(Result, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.ThawAccount:
      TTokenProgramData.DecodeThawAccountData(Result, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.TransferChecked:
      TTokenProgramData.DecodeTransferCheckedData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.ApproveChecked:
      TTokenProgramData.DecodeApproveCheckedData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.MintToChecked:
      TTokenProgramData.DecodeMintToCheckedData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.BurnChecked:
      TTokenProgramData.DecodeBurnCheckedData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.SyncNative:
      TTokenProgramData.DecodeSyncNativeData(Result, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.InitializeAccount2:
      TTokenProgramData.DecodeInitializeAccount2(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.InitializeAccount3:
      TTokenProgramData.DecodeInitializeAccount3(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.InitializeMint2:
      TTokenProgramData.DecodeInitializeMint2(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.InitializeMultiSignature2:
      TTokenProgramData.DecodeInitializeMultiSignature2(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.GetAccountDataSize:
      TTokenProgramData.DecodeGetAccountDataSize(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.InitializeImmutableOwner:
      TTokenProgramData.DecodeInitializeImmutableOwner(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.AmountToUiAmount:
      TTokenProgramData.DecodeAmountToUiAmount(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.UiAmountToAmount:
      TTokenProgramData.DecodeUiAmountToAmount(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.InitializeMintCloseAuthority:
      TTokenProgramData.DecodeInitializeMintCloseAuthority(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.Reallocate:
      TTokenProgramData.DecodeReallocate(Result, AData, AKeys, AKeyIndices);
  end;
end;

end.

