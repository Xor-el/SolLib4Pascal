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

unit SlpTokenProgram;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
  System.TypInfo,
  SlpPublicKey,
  SlpAccount,
  SlpAccountDomain,
  SlpTransactionInstruction,
  SlpSysVars,
  SlpDeserialization,
  SlpSerialization,
  SlpDecodedInstruction;

type
  /// <summary>
  /// Represents the types of authorities for <see cref="TTokenProgram.SetAuthority"/> instructions.
  /// </summary>
  TAuthorityType = (
    /// <summary>
    /// Authority to mint new tokens.
    /// </summary>
    MintTokens = 0,

    /// <summary>
    /// Authority to freeze any account associated with the mint.
    /// </summary>
    FreezeAccount = 1,

    /// <summary>
    /// Owner of a given account token.
    /// </summary>
    AccountOwner = 2,

    /// <summary>
    /// Authority to close a given account.
    /// </summary>
    CloseAccount = 3
  );
  {====================================================================================================================}
  {                                                TokenProgramInstructions                                            }
  {====================================================================================================================}
  /// <summary>
  /// Represents the instruction types for the Token Program along with a friendly name
  /// <remarks>
  /// For more information see:
  /// https://spl.solana.com/token
  /// https://docs.rs/spl-token/3.2.0/spl_token/
  /// </remarks>
  /// </summary>
  TTokenProgramInstructions = class sealed
  public
    type
      /// <summary>
      /// Represents the instruction types for the <c>TokenProgram</c>.
      /// </summary>
      TValues = (
        /// <summary>Initialize a token mint.</summary>
        InitializeMint = 0,
        /// <summary>Initialize a token account.</summary>
        InitializeAccount = 1,
        /// <summary>Initialize a multi signature token account.</summary>
        InitializeMultiSignature = 2,
        /// <summary>Transfer token transaction.</summary>
        Transfer = 3,
        /// <summary>Approve token transaction.</summary>
        Approve = 4,
        /// <summary>Revoke token transaction.</summary>
        Revoke = 5,
        /// <summary>Set token authority transaction.</summary>
        SetAuthority = 6,
        /// <summary>MintTo token account transaction.</summary>
        MintTo = 7,
        /// <summary>Burn token transaction.</summary>
        Burn = 8,
        /// <summary>Close token account transaction.</summary>
        CloseAccount = 9,
        /// <summary>Freeze token account transaction.</summary>
        FreezeAccount = 10,
        /// <summary>Thaw token account transaction.</summary>
        ThawAccount = 11,
        /// <summary>
        /// Transfer checked token transaction.
        /// <remarks>Differs from <see cref="Transfer"/> in that the decimals value is asserted by the caller.</remarks>
        /// </summary>
        TransferChecked = 12,
        /// <summary>
        /// Approve checked token transaction.
        /// <remarks>Differs from <see cref="Approve"/> in that the decimals value is asserted by the caller.</remarks>
        /// </summary>
        ApproveChecked = 13,
        /// <summary>
        /// MintTo checked token transaction.
        /// <remarks>Differs from <see cref="MintTo"/> in that the decimals value is asserted by the caller.</remarks>
        /// </summary>
        MintToChecked = 14,
        /// <summary>
        /// Burn checked token transaction.
        /// <remarks>Differs from <see cref="Burn"/> in that the decimals value is asserted by the caller.</remarks>
        /// </summary>
        BurnChecked = 15,
        /// <summary>
        /// Like InitializeAccount, but the owner pubkey is passed via instruction data.
        /// </summary>
        InitializeAccount2 = 16,
        /// <summary>
        /// SyncNative token transaction (updates amount based on underlying lamports).
        /// </summary>
        SyncNative = 17,
        /// <summary>Like InitializeAccount2, but does not require the Rent sysvar.</summary>
        InitializeAccount3 = 18,
        /// <summary>Like InitializeMultisig, but does not require the Rent sysvar.</summary>
        InitializeMultiSignature2 = 19,
        /// <summary>Like InitializeMint, but does not require the Rent sysvar.</summary>
        InitializeMint2 = 20,
        /// <summary>Gets the required size of an account for the given mint as a LE u64.</summary>
        GetAccountDataSize = 21,
        /// <summary>Initialize the Immutable Owner extension for the given token account.</summary>
        InitializeImmutableOwner = 22,
        /// <summary>Convert an Amount to UiAmount string, using the given mint.</summary>
        AmountToUiAmount = 23,
        /// <summary>Convert a UiAmount (string) to a raw u64 Amount, using the given mint.</summary>
        UiAmountToAmount = 24
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
  {                                                    TokenProgramData                                               }
  {====================================================================================================================}
  /// <summary>
  /// Implements the token program data encodings.
  /// </summary>
  TTokenProgramData = class sealed
  private
    /// <summary>
    /// The offset at which the value which defines the method begins.
    /// </summary>
    const MethodOffset = 0;
    /// <summary>
    /// Encodes the transaction instruction data for the methods which only require the amount.
    /// </summary>
    /// <param name="AMethod">The method identifier.</param>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeAmountLayout(AMethod: Byte; const AAmount: UInt64): TBytes; static;
    /// <summary>
    /// Encodes the transaction instruction data for the methods which only require the amount and the number of decimals.
    /// </summary>
    /// <param name="AMethod">The method identifier.</param>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <param name="ADecimals">The decimals of the token.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeAmountCheckedLayout(AMethod: Byte; const AAmount: UInt64; ADecimals: Byte): TBytes; static;
  public
   {---------------------------- Encoders ---------------------------------------------}
    /// <summary>
    /// Encode the transaction instruction data for <see cref="TTokenProgramInstructions.TValues.Revoke"/>.
    /// </summary>
    class function EncodeRevokeData: TBytes; static;

    /// <summary>
    /// Encode the data for <see cref="TTokenProgramInstructions.TValues.Approve"/>.
    /// </summary>
    /// <param name="AAmount">The amount of tokens to approve the transfer of.</param>
    class function EncodeApproveData(const AAmount: UInt64): TBytes; static;

    /// <summary>
    /// Encode the data for <see cref="TTokenProgramInstructions.TValues.InitializeAccount"/>.
    /// </summary>
    class function EncodeInitializeAccountData: TBytes; static;

    /// <summary>
    /// Encode the data for <see cref="TTokenProgramInstructions.TValues.InitializeMint"/>.
    /// </summary>
    /// <param name="AMintAuthority">The mint authority for the token.</param>
    /// <param name="AFreezeAuthority">The freeze authority for the token.</param>
    /// <param name="ADecimals">The token decimals.</param>
    /// <param name="AFreezeAuthorityOption">Freeze authority option (1 if present, 0 if not).</param>
    class function EncodeInitializeMintData(const AMintAuthority, AFreezeAuthority: IPublicKey;
      const ADecimals, AFreezeAuthorityOption: Integer): TBytes; static;

    /// <summary>Encode the data for <see cref="TTokenProgramInstructions.TValues.Transfer"/>.</summary>
    class function EncodeTransferData(const AAmount: UInt64): TBytes; static;

    /// <summary>Encode the data for <see cref="TTokenProgramInstructions.TValues.TransferChecked"/>.</summary>
    class function EncodeTransferCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes; static;

    /// <summary>Encode the data for <see cref="TTokenProgramInstructions.TValues.MintTo"/>.</summary>
    class function EncodeMintToData(const AAmount: UInt64): TBytes; static;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.InitializeMultiSignature"/> method.
    /// </summary>
    /// <param name="AM">The number of signers necessary to validate the account.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeInitializeMultiSignatureData(const AM: Integer): TBytes; static;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.SetAuthority"/> method.
    /// </summary>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeSetAuthorityData(const AAuthorityType: TAuthorityType; const ANewAuthorityOption: Integer; ANewAuthority: IPublicKey): TBytes;

    /// <summary>Encode the data for <see cref="TTokenProgramInstructions.TValues.Burn"/>.</summary>
    class function EncodeBurnData(const AAmount: UInt64): TBytes; static;

    /// <summary>Encode the data for <see cref="TTokenProgramInstructions.TValues.ThawAccount"/>.</summary>
    class function EncodeThawAccountData: TBytes; static;

    /// <summary>Encode the data for <see cref="TTokenProgramInstructions.TValues.ApproveChecked"/>.</summary>
    class function EncodeApproveCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes; static;

    /// <summary>Encode the data for <see cref="TTokenProgramInstructions.TValues.MintToChecked"/>.</summary>
    class function EncodeMintToCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes;

    /// <summary>Encode the data for <see cref="TTokenProgramInstructions.TValues.BurnChecked"/>.</summary>
    class function EncodeBurnCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes;

    /// <summary>Encode the data for <see cref="TTokenProgramInstructions.TValues.CloseAccount"/>.</summary>
    class function EncodeCloseAccountData: TBytes;

    /// <summary>Encode the data for <see cref="TTokenProgramInstructions.TValues.FreezeAccount"/>.</summary>
    class function EncodeFreezeAccountData: TBytes; static;

    /// <summary>Encode the data for <see cref="TTokenProgramInstructions.TValues.SyncNative"/>.</summary>
    class function EncodeSyncNativeData: TBytes; static;


    /// <summary>Decode InitializeMint.</summary>
    class procedure DecodeInitializeMintData(const ADecoded: IDecodedInstruction;
      const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>Decode InitializeAccount.</summary>
    class procedure DecodeInitializeAccountData(const ADecoded: IDecodedInstruction;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>Decode InitializeMultiSignature.</summary>
    class procedure DecodeInitializeMultiSignatureData(const ADecoded: IDecodedInstruction;
       const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>Decode Transfer.</summary>
    class procedure DecodeTransferData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>Decode Approve.</summary>
    class procedure DecodeApproveData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>Decode Revoke.</summary>
    class procedure DecodeRevokeData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes); static;

    /// <summary>Decode SetAuthority.</summary>
    class procedure DecodeSetAuthorityData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>Decode MintTo.</summary>
    class procedure DecodeMintToData(const ADecoded: IDecodedInstruction;
      const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);

    /// <summary>Decode Burn.</summary>
    class procedure DecodeBurnData(const ADecoded: IDecodedInstruction;
      const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);

    /// <summary>Decode CloseAccount.</summary>
    class procedure DecodeCloseAccountData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes); static;

    /// <summary>Decode FreezeAccount.</summary>
    class procedure DecodeFreezeAccountData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes); static;

    /// <summary>Decode ThawAccount.</summary>
    class procedure DecodeThawAccountData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes); static;

    /// <summary>Decode TransferChecked.</summary>
    class procedure DecodeTransferCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>Decode ApproveChecked.</summary>
    class procedure DecodeApproveCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>Decode MintToChecked.</summary>
    class procedure DecodeMintToCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>Decode BurnChecked.</summary>
    class procedure DecodeBurnCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>Decode SyncNative.</summary>
    class procedure DecodeSyncNativeData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes); static;

    /// <summary>Decode InitializeAccount2.</summary>
    class procedure DecodeInitializeAccount2(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>Decode InitializeAccount3.</summary>
    class procedure DecodeInitializeAccount3(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>Decode InitializeMultiSignature2.</summary>
    class procedure DecodeInitializeMultiSignature2(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>Decode InitializeMint2.</summary>
    class procedure DecodeInitializeMint2(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>Decode AmountToUiAmount.</summary>
    class procedure DecodeAmountToUiAmount(const ADecoded: IDecodedInstruction;
      const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);

    /// <summary>Decode UiAmountToAmount.</summary>
    class procedure DecodeUiAmountToAmount(const ADecoded: IDecodedInstruction;
      const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);

    /// <summary>Decode GetAccountDataSize.</summary>
    class procedure DecodeGetAccountDataSize(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>Decode InitializeImmutableOwner.</summary>
    class procedure DecodeInitializeImmutableOwner(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
  end;

  {====================================================================================================================}
  {                                                      TokenProgram                                                 }
  {====================================================================================================================}
  /// <summary>
  /// Implements the Token Program methods.
  /// <remarks>
  /// For more information see:
  /// https://spl.solana.com/token
  /// https://docs.rs/spl-token/3.2.0/spl_token/
  /// </remarks>
  /// </summary>
  TTokenProgram = class sealed
  private
    const ProgramName = 'Token Program';
    class var FProgramIdKey: IPublicKey;

    class function GetProgramIdKey: IPublicKey; static;

    /// <summary>Adds the authority and optional multisig signers to the key list.</summary>
    /// <param name="AKeys">The instruction's list of keys.</param>
    /// <param name="AAuthority">The authority public key.</param>
    /// <param name="ASigners">Optional multisig signer keys.</param>
    /// <returns>The same list with the added signers.</returns>
    class function AddSigners(const AKeys: TList<IAccountMeta>;
                              const AAuthority: IPublicKey;
                              const ASigners: TArray<IPublicKey> = nil): TList<IAccountMeta>; static;
  public
    /// <summary>The public key of the Token Program.</summary>
    class property ProgramIdKey: IPublicKey read GetProgramIdKey;

    /// <summary>Mint account layout size.</summary>
    const MintAccountDataSize = 82;
    /// <summary>Token account layout size.</summary>
    const TokenAccountDataSize = 165;
    /// <summary>Multisig account layout size.</summary>
    const MultisigAccountDataSize = 355;

    class constructor Create;
    class destructor Destroy;

    /// <summary>Transfer tokens from one account to another (direct or via delegate).</summary>
    /// <param name="ASource">Account to transfer from.</param>
    /// <param name="ADestination">Account to transfer to.</param>
    /// <param name="AAmount">Amount of tokens to transfer.</param>
    /// <param name="AAuthority">Authority public key.</param>
    /// <param name="ASigners">Optional multisig signer keys.</param>
    /// <returns>The transaction instruction.</returns>
    class function Transfer(const ASource, ADestination: IPublicKey; const AAmount: UInt64;
                            const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>Transfer tokens with caller-checked mint/decimals.</summary>
    /// <param name="ASource">Account to transfer from.</param>
    /// <param name="ADestination">Account to transfer to.</param>
    /// <param name="AAmount">Amount of tokens to transfer.</param>
    /// <param name="ADecimals">Token decimals.</param>
    /// <param name="AAuthority">Authority public key.</param>
    /// <param name="ATokenMint">Token mint public key.</param>
    /// <param name="ASigners">Optional multisig signer keys.</param>
    /// <returns>The transaction instruction.</returns>
    class function TransferChecked(const ASource, ADestination: IPublicKey; const AAmount: UInt64; const ADecimals: Integer;
                                   const AAuthority, ATokenMint: IPublicKey; const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>Initialize a new token account.</summary>
    /// <param name="AAccount">Account to initialize.</param>
    /// <param name="AMint">Token mint.</param>
    /// <param name="AAuthority">Account authority to set.</param>
    /// <returns>The transaction instruction.</returns>
    class function InitializeAccount(const AAccount, AMint, AAuthority: IPublicKey): ITransactionInstruction; static;

    /// <summary>Initialize a multisignature account.</summary>
    /// <param name="AMultiSignature">Multisig account public key.</param>
    /// <param name="ASigners">Signer addresses.</param>
    /// <param name="AM">Number of required signatures.</param>
    /// <returns>The transaction instruction.</returns>
    class function InitializeMultiSignature(const AMultiSignature: IPublicKey; const ASigners: TArray<IPublicKey>;
                                            const AM: Integer): ITransactionInstruction; static;

    /// <summary>Initialize a token mint.</summary>
    /// <param name="AMint">Mint account.</param>
    /// <param name="ADecimals">Token decimals.</param>
    /// <param name="AMintAuthority">Mint authority.</param>
    /// <param name="AFreezeAuthority">Optional freeze authority.</param>
    /// <returns>The transaction instruction.</returns>
    class function InitializeMint(const AMint: IPublicKey; const ADecimals: Integer;
                                  const AMintAuthority: IPublicKey; const AFreezeAuthority: IPublicKey = nil): ITransactionInstruction; static;

    /// <summary>Mint tokens to a destination account.</summary>
    /// <param name="AMint">Token mint.</param>
    /// <param name="ADestination">Destination account.</param>
    /// <param name="AAmount">Amount to mint.</param>
    /// <param name="AMintAuthority">Mint authority.</param>
    /// <param name="ASigners">Optional multisig signer keys.</param>
    /// <returns>The transaction instruction.</returns>
    class function MintTo(const AMint, ADestination: IPublicKey; const AAmount: UInt64;
                          const AMintAuthority: IPublicKey; const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>Approve a delegate to transfer up to a specified amount.</summary>
    /// <param name="ASource">Source account.</param>
    /// <param name="ADelegate">Delegate account.</param>
    /// <param name="AAuthority">Source authority.</param>
    /// <param name="AAmount">Maximum transferable amount.</param>
    /// <param name="ASigners">Optional multisig signer keys.</param>
    /// <returns>The transaction instruction.</returns>
    class function Approve(const ASource, ADelegate, AAuthority: IPublicKey; const AAmount: UInt64;
                           const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>Revoke a previously approved delegation.</summary>
    /// <param name="ASource">Source account.</param>
    /// <param name="AAuthority">Source authority.</param>
    /// <param name="ASigners">Optional multisig signer keys.</param>
    /// <returns>The transaction instruction.</returns>
    class function Revoke(const ASource, AAuthority: IPublicKey; const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>Set an authority on an account.</summary>
    /// <param name="AAccount">Target account.</param>
    /// <param name="AAuthorityType">Authority type to set.</param>
    /// <param name="ACurrentAuthority">Current authority of that type.</param>
    /// <param name="ANewAuthority">New authority (optional).</param>
    /// <param name="ASigners">Optional multisig signer keys.</param>
    /// <returns>The transaction instruction.</returns>
    class function SetAuthority(const AAccount: IPublicKey; const AAuthorityType: TAuthorityType;
                                const ACurrentAuthority: IPublicKey; const ANewAuthority: IPublicKey = nil;
                                const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>Burn tokens.</summary>
    /// <param name="ASource">Account to burn from.</param>
    /// <param name="AMint">Token mint.</param>
    /// <param name="AAmount">Amount to burn.</param>
    /// <param name="AAuthority">Source authority.</param>
    /// <param name="ASigners">Optional multisig signer keys.</param>
    /// <returns>The transaction instruction.</returns>
    class function Burn(const ASource, AMint: IPublicKey; const AAmount: UInt64;
                        const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>Close a token account and send its SOL to the destination.</summary>
    /// <param name="AAccount">Account to close.</param>
    /// <param name="ADestination">Recipient of SOL.</param>
    /// <param name="AAuthority">Account authority.</param>
    /// <param name="AProgramId">Associated program id.</param>
    /// <param name="ASigners">Optional multisig signer keys.</param>
    /// <returns>The transaction instruction.</returns>
    class function CloseAccount(const AAccount, ADestination, AAuthority, AProgramId: IPublicKey;
                                const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>Freeze a token account.</summary>
    /// <param name="AAccount">Account to freeze.</param>
    /// <param name="AMint">Token mint.</param>
    /// <param name="AFreezeAuthority">Freeze authority.</param>
    /// <param name="AProgramId">Associated program id.</param>
    /// <param name="ASigners">Optional multisig signer keys.</param>
    /// <returns>The transaction instruction.</returns>
    class function FreezeAccount(const AAccount, AMint, AFreezeAuthority, AProgramId: IPublicKey;
                                 const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>Thaw a frozen token account.</summary>
    /// <param name="AAccount">Account to thaw.</param>
    /// <param name="AMint">Token mint.</param>
    /// <param name="AFreezeAuthority">Freeze authority.</param>
    /// <param name="AProgramId">Associated program id.</param>
    /// <param name="ASigners">Optional multisig signer keys.</param>
    /// <returns>The transaction instruction.</returns>
    class function ThawAccount(const AAccount, AMint, AFreezeAuthority, AProgramId: IPublicKey;
                               const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>Approve a delegate (caller-checked amount/decimals).</summary>
    /// <param name="ASource">Source account.</param>
    /// <param name="ADelegate">Delegate account.</param>
    /// <param name="AAmount">Maximum transferable amount.</param>
    /// <param name="ADecimals">Token decimals.</param>
    /// <param name="AAuthority">Source authority.</param>
    /// <param name="AMint">Token mint.</param>
    /// <param name="ASigners">Optional multisig signer keys.</param>
    /// <returns>The transaction instruction.</returns>
    class function ApproveChecked(const ASource, ADelegate: IPublicKey; const AAmount: UInt64; const ADecimals: Byte;
                                  const AAuthority, AMint: IPublicKey; const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>Mint tokens with caller-checked decimals.</summary>
    /// <param name="AMint">Token mint.</param>
    /// <param name="ADestination">Destination account.</param>
    /// <param name="AMintAuthority">Mint authority.</param>
    /// <param name="AAmount">Amount to mint.</param>
    /// <param name="ADecimals">Token decimals.</param>
    /// <param name="ASigners">Optional multisig signer keys.</param>
    /// <returns>The transaction instruction.</returns>
    class function MintToChecked(const AMint, ADestination, AMintAuthority: IPublicKey;
                                 const AAmount: UInt64; const ADecimals: Integer;
                                 const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>Burn tokens with caller-checked decimals.</summary>
    /// <param name="AMint">Token mint.</param>
    /// <param name="AAccount">Account to burn from.</param>
    /// <param name="AAuthority">Source authority.</param>
    /// <param name="AAmount">Amount to burn.</param>
    /// <param name="ADecimals">Token decimals.</param>
    /// <param name="ASigners">Optional multisig signer keys.</param>
    /// <returns>The transaction instruction.</returns>
    class function BurnChecked(const AMint, AAccount, AAuthority: IPublicKey;
                               const AAmount: UInt64; const ADecimals: Integer;
                               const ASigners: TArray<IPublicKey> = nil): ITransactionInstruction; static;

    /// <summary>Sync a native token account.</summary>
    /// <param name="AAccount">Token account.</param>
    /// <returns>The transaction instruction.</returns>
    class function SyncNative(const AAccount: IPublicKey): ITransactionInstruction; static;

    /// <summary>Decode a token program instruction.</summary>
    /// <param name="AData">Instruction data.</param>
    /// <param name="AKeys">Transaction account keys.</param>
    /// <param name="AKeyIndices">Instruction key indices into <paramref name="AKeys"/>.</param>
    /// <returns>A decoded instruction.</returns>
    class function Decode(const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction; static;
  end;

implementation

{ TokenProgramInstructions }

class constructor TTokenProgramInstructions.Create;
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
end;

class destructor TTokenProgramInstructions.Destroy;
begin
  FNames.Free;
end;

{ TokenProgramData }

{=== TokenProgramData � Encoders ===}

class function TTokenProgramData.EncodeAmountLayout(AMethod: Byte; const AAmount: UInt64): TBytes;
begin
  SetLength(Result, 9);
  TSerialization.WriteU8(Result, AMethod, MethodOffset);
  TSerialization.WriteU64(Result, AAmount, 1);
end;

class function TTokenProgramData.EncodeAmountCheckedLayout(AMethod: Byte;
  const AAmount: UInt64; ADecimals: Byte): TBytes;
begin
  SetLength(Result, 10);
  TSerialization.WriteU8(Result, AMethod, MethodOffset);
  TSerialization.WriteU64(Result, AAmount, 1);
  TSerialization.WriteU8(Result, ADecimals, 9);
end;

class function TTokenProgramData.EncodeRevokeData: TBytes;
begin
  Result := TBytes.Create(Byte(TTokenProgramInstructions.TValues.Revoke));
end;

class function TTokenProgramData.EncodeApproveData(const AAmount: UInt64): TBytes;
begin
  Result := EncodeAmountLayout(Byte(TTokenProgramInstructions.TValues.Approve), AAmount)
end;

class function TTokenProgramData.EncodeInitializeAccountData: TBytes;
begin
  Result := TBytes.Create(Byte(TTokenProgramInstructions.TValues.InitializeAccount));
end;

class function TTokenProgramData.EncodeInitializeMintData(const AMintAuthority, AFreezeAuthority: IPublicKey;
  const ADecimals, AFreezeAuthorityOption: Integer): TBytes;
begin
  SetLength(Result, 67);
  TSerialization.WriteU8(Result, Byte(TTokenProgramInstructions.TValues.InitializeMint), MethodOffset);
  TSerialization.WriteU8(Result, Byte(ADecimals), 1);
  TSerialization.WritePubKey(Result, AMintAuthority, 2);
  TSerialization.WriteU8(Result, Byte(AFreezeAuthorityOption), 34);
  TSerialization.WritePubKey(Result, AFreezeAuthority, 35);
end;

class function TTokenProgramData.EncodeTransferData(const AAmount: UInt64): TBytes;
begin
  Result := EncodeAmountLayout(Byte(TTokenProgramInstructions.TValues.Transfer), AAmount);
end;

class function TTokenProgramData.EncodeTransferCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes;
begin
  Result := EncodeAmountCheckedLayout(Byte(TTokenProgramInstructions.TValues.TransferChecked), AAmount, Byte(ADecimals));
end;

class function TTokenProgramData.EncodeMintToData(const AAmount: UInt64): TBytes;
begin
  Result := EncodeAmountLayout(Byte(TTokenProgramInstructions.TValues.MintTo), AAmount);
end;

class function TTokenProgramData.EncodeInitializeMultiSignatureData(const AM: Integer): TBytes;
begin
  SetLength(Result, 2);
  TSerialization.WriteU8(Result, Byte(TTokenProgramInstructions.TValues.InitializeMultiSignature), MethodOffset);
  TSerialization.WriteU8(Result, Byte(AM), 1);
end;

class function TTokenProgramData.EncodeSetAuthorityData(const AAuthorityType: TAuthorityType;
  const ANewAuthorityOption: Integer; ANewAuthority: IPublicKey): TBytes;
begin
  SetLength(Result, 35);
  TSerialization.WriteU8(Result, Byte(TTokenProgramInstructions.TValues.SetAuthority), MethodOffset);
  TSerialization.WriteU8(Result, Byte(AAuthorityType), 1);
  TSerialization.WriteU8(Result, ANewAuthorityOption, 2);
  TSerialization.WritePubKey(Result, ANewAuthority, 3);
end;

class function TTokenProgramData.EncodeBurnData(const AAmount: UInt64): TBytes;
begin
  Result := EncodeAmountLayout(Byte(TTokenProgramInstructions.TValues.Burn), AAmount);
end;

class function TTokenProgramData.EncodeThawAccountData: TBytes;
begin
  Result := TBytes.Create(Byte(TTokenProgramInstructions.TValues.ThawAccount));
end;

class function TTokenProgramData.EncodeApproveCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes;
begin
  Result := EncodeAmountCheckedLayout(Byte(TTokenProgramInstructions.TValues.ApproveChecked), AAmount, Byte(ADecimals));
end;

class function TTokenProgramData.EncodeMintToCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes;
begin
  Result := EncodeAmountCheckedLayout(Byte(TTokenProgramInstructions.TValues.MintToChecked), AAmount, Byte(ADecimals));
end;

class function TTokenProgramData.EncodeBurnCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes;
begin
  Result := EncodeAmountCheckedLayout(Byte(TTokenProgramInstructions.TValues.BurnChecked), AAmount, Byte(ADecimals));
end;

class function TTokenProgramData.EncodeCloseAccountData: TBytes;
begin
  Result := TBytes.Create(Byte(TTokenProgramInstructions.TValues.CloseAccount));
end;

class function TTokenProgramData.EncodeFreezeAccountData: TBytes;
begin
  Result := TBytes.Create(Byte(TTokenProgramInstructions.TValues.FreezeAccount));
end;

class function TTokenProgramData.EncodeSyncNativeData: TBytes;
begin
  Result := TBytes.Create(Byte(TTokenProgramInstructions.TValues.SyncNative));
end;

{=== TokenProgramData � Decoders ===}

class procedure TTokenProgramData.DecodeInitializeMintData(const ADecoded: IDecodedInstruction;
  const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
var
  LHasFreeze: Boolean;
begin
  ADecoded.Values.Add('Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Decimals', TValue.From<Byte>(TDeserialization.GetU8(AData, 1)));
  ADecoded.Values.Add('Mint Authority', TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 2)));
  LHasFreeze := TDeserialization.GetBool(AData, 34);
  ADecoded.Values.Add('Freeze Authority Option', TValue.From<Boolean>(LHasFreeze));
  if LHasFreeze then
    ADecoded.Values.Add('Freeze Authority', TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 35)));
end;

class procedure TTokenProgramData.DecodeInitializeAccountData(const ADecoded: IDecodedInstruction;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint', TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
end;

class procedure TTokenProgramData.DecodeInitializeMultiSignatureData(const ADecoded: IDecodedInstruction;
  const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
var
  I: Integer;
  LNum: Byte;
begin
  ADecoded.Values.Add('Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  LNum := TDeserialization.GetU8(AData, 1);
  ADecoded.Values.Add('Required Signers', LNum);
  for I := 2 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 1]), TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TTokenProgramData.DecodeTransferData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  I: Integer;
  LAmount: UInt64;
begin
  ADecoded.Values.Add('Source',      TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Destination', TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority',   TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));

  LAmount := TDeserialization.GetU64(AData, 1);
  ADecoded.Values.Add('Amount', LAmount);

  for I := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TTokenProgramData.DecodeApproveData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  I: Integer;
  LAmount: UInt64;
begin
  ADecoded.Values.Add('Source',    TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Delegate',  TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));

  LAmount := TDeserialization.GetU64(AData, 1);
  ADecoded.Values.Add('Amount', LAmount);

  for I := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;


class procedure TTokenProgramData.DecodeRevokeData(
  const ADecoded: IDecodedInstruction;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  I: Integer;
begin
  ADecoded.Values.Add('Source',    TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  for I := 2 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 1]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TTokenProgramData.DecodeSetAuthorityData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LAuthType: TAuthorityType;
begin
  ADecoded.Values.Add('Account',           TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Current Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));

  LAuthType := TAuthorityType(TDeserialization.GetU8(AData, 1));
  ADecoded.Values.Add('Authority Type', TValue.From<TAuthorityType>(LAuthType));

  ADecoded.Values.Add('New Authority Option', TValue.From<Byte>(TDeserialization.GetU8(AData, 2)));

  if Length(AData) >= 34 then
    ADecoded.Values.Add('New Authority',
      TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 3)));

  // Signers (starting from index 2)
  var I: Integer;
  for I := 2 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 1]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TTokenProgramData.DecodeMintToData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LAmount: UInt64;
  I: Integer;
begin
  ADecoded.Values.Add('Mint',           TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Destination',    TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Mint Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));

  LAmount := TDeserialization.GetU64(AData, 1);
  ADecoded.Values.Add('Amount', LAmount);

  for I := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TTokenProgramData.DecodeBurnData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LAmount: UInt64;
  I: Integer;
begin
  ADecoded.Values.Add('Account',   TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',      TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));

  LAmount := TDeserialization.GetU64(AData, 1);
  ADecoded.Values.Add('Amount', LAmount);

  for I := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TTokenProgramData.DecodeCloseAccountData(
  const ADecoded: IDecodedInstruction;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  I: Integer;
begin
  ADecoded.Values.Add('Account',     TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Destination', TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority',   TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  for I := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TTokenProgramData.DecodeFreezeAccountData(
  const ADecoded: IDecodedInstruction;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  I: Integer;
begin
  ADecoded.Values.Add('Account',         TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',            TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Freeze Authority',TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  for I := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TTokenProgramData.DecodeThawAccountData(
  const ADecoded: IDecodedInstruction;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  I: Integer;
begin
  ADecoded.Values.Add('Account',         TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',            TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Freeze Authority',TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  for I := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TTokenProgramData.DecodeTransferCheckedData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  I: Integer;
begin
  ADecoded.Values.Add('Source',      TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',        TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Destination', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  ADecoded.Values.Add('Authority',   TValue.From<IPublicKey>(AKeys[AKeyIndices[3]]));

  ADecoded.Values.Add('Amount',   TValue.From<UInt64>(TDeserialization.GetU64(AData, 1)));
  ADecoded.Values.Add('Decimals', TValue.From<Byte>(TDeserialization.GetU8(AData, 9)));

  for I := 4 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 3]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TTokenProgramData.DecodeApproveCheckedData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  I: Integer;
begin
  ADecoded.Values.Add('Source',    TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',      TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Delegate',  TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[3]]));

  ADecoded.Values.Add('Amount',   TValue.From<UInt64>(TDeserialization.GetU64(AData, 1)));
  ADecoded.Values.Add('Decimals', TValue.From<Byte>(TDeserialization.GetU8(AData, 9)));

  for I := 4 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 3]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TTokenProgramData.DecodeMintToCheckedData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LAmount : UInt64;
  LDec    : Byte;
  I: Integer;
begin
  ADecoded.Values.Add('Mint',           TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Destination',    TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Mint Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));

  LAmount := TDeserialization.GetU64(AData, 1);
  LDec    := TDeserialization.GetU8(AData, 9);
  ADecoded.Values.Add('Amount',   LAmount);
  ADecoded.Values.Add('Decimals', LDec);

  for I := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TTokenProgramData.DecodeBurnCheckedData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  I: Integer;
begin
  ADecoded.Values.Add('Account',   TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',      TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));

  ADecoded.Values.Add('Amount',   TValue.From<UInt64>(TDeserialization.GetU64(AData, 1)));
  ADecoded.Values.Add('Decimals', TValue.From<Byte>(TDeserialization.GetU8(AData, 9)));

  for I := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TTokenProgramData.DecodeSyncNativeData(
  const ADecoded: IDecodedInstruction;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
end;

class procedure TTokenProgramData.DecodeInitializeAccount2(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Account',   TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',      TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 1)));
end;

class procedure TTokenProgramData.DecodeInitializeAccount3(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Account',   TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',      TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 1)));
end;

class procedure TTokenProgramData.DecodeInitializeMultiSignature2(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  I: Integer;
begin
  ADecoded.Values.Add('Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Required Signers', TValue.From<Byte>(TDeserialization.GetU8(AData, 1)));

  for I := 1 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 1]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TTokenProgramData.DecodeInitializeMint2(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LHasFreeze: Boolean;
begin
  ADecoded.Values.Add('Account',        TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Decimals',       TValue.From<Byte>(TDeserialization.GetU8(AData, 1)));
  ADecoded.Values.Add('Mint Authority', TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 2)));

  LHasFreeze := TDeserialization.GetBool(AData, 34);
  ADecoded.Values.Add('Freeze Authority Option', TValue.From<Boolean>(LHasFreeze));
  if LHasFreeze then
    ADecoded.Values.Add('Freeze Authority',
      TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 35)));
end;

class procedure TTokenProgramData.DecodeAmountToUiAmount(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Mint',   TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Amount', TValue.From<UInt64>(TDeserialization.GetU64(AData, 1)));
end;

class procedure TTokenProgramData.DecodeUiAmountToAmount(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Mint',   TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Amount', TValue.From<string>(TDeserialization.DecodeBincodeString(AData, 1).EncodedString));
end;

class procedure TTokenProgramData.DecodeGetAccountDataSize(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Mint', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
end;

class procedure TTokenProgramData.DecodeInitializeImmutableOwner(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
end;


{ TTokenProgram }

class constructor TTokenProgram.Create;
begin
  FProgramIdKey := TPublicKey.Create('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');
end;

class destructor TTokenProgram.Destroy;
begin
  FProgramIdKey := nil;
end;

class function TTokenProgram.GetProgramIdKey: IPublicKey;
begin
  Result := FProgramIdKey;
end;

class function TTokenProgram.AddSigners(const AKeys: TList<IAccountMeta>;
                                        const AAuthority: IPublicKey;
                                        const ASigners: TArray<IPublicKey>): TList<IAccountMeta>;
var
  S: IPublicKey;
begin
  Result := AKeys;
  if (ASigners <> nil) and (Length(ASigners) > 0) then
  begin
    Result.Add(TAccountMeta.ReadOnly(AAuthority, False));
    for S in ASigners do
      Result.Add(TAccountMeta.ReadOnly(S, True));
  end
  else
  begin
    Result.Add(TAccountMeta.ReadOnly(AAuthority, True));
  end;
end;

class function TTokenProgram.Transfer(const ASource, ADestination: IPublicKey; const AAmount: UInt64;
                                      const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ASource, False));
  Keys.Add(TAccountMeta.Writable(ADestination, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TTokenProgramData.EncodeTransferData(AAmount));
end;

class function TTokenProgram.TransferChecked(const ASource, ADestination: IPublicKey; const AAmount: UInt64; const ADecimals: Integer;
                                             const AAuthority, ATokenMint: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ASource, False));
  Keys.Add(TAccountMeta.ReadOnly(ATokenMint, False));
  Keys.Add(TAccountMeta.Writable(ADestination, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TTokenProgramData.EncodeTransferCheckedData(AAmount, ADecimals));
end;

class function TTokenProgram.InitializeAccount(const AAccount, AMint, AAuthority: IPublicKey): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, False));
  Keys.Add(TAccountMeta.ReadOnly(AMint, False));
  Keys.Add(TAccountMeta.ReadOnly(AAuthority, False));
  Keys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TTokenProgramData.EncodeInitializeAccountData);
end;

class function TTokenProgram.InitializeMultiSignature(const AMultiSignature: IPublicKey; const ASigners: TArray<IPublicKey>;
                                                      const AM: Integer): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
  S: IPublicKey;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AMultiSignature, False));
  Keys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));
  for S in ASigners do
    Keys.Add(TAccountMeta.ReadOnly(S, False));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TTokenProgramData.EncodeInitializeMultiSignatureData(AM));
end;

class function TTokenProgram.InitializeMint(const AMint: IPublicKey; const ADecimals: Integer;
                                            const AMintAuthority, AFreezeAuthority: IPublicKey): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
  FreezeOpt: Integer;
  FreezeKey: IPublicKey;
  Account: IAccount;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AMint, False));
  Keys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));

  FreezeOpt := Ord(Assigned(AFreezeAuthority));

  if Assigned(AFreezeAuthority) then
    FreezeKey := AFreezeAuthority
  else
  begin
    Account := TAccount.Create;
    FreezeKey := Account.PublicKey;
  end;

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TTokenProgramData.EncodeInitializeMintData(AMintAuthority, FreezeKey, ADecimals, FreezeOpt));
end;

class function TTokenProgram.MintTo(const AMint, ADestination: IPublicKey; const AAmount: UInt64;
                                    const AMintAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AMint, False));
  Keys.Add(TAccountMeta.Writable(ADestination, False));
  Keys := AddSigners(Keys, AMintAuthority, ASigners);

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TTokenProgramData.EncodeMintToData(AAmount));
end;

class function TTokenProgram.Approve(const ASource, ADelegate, AAuthority: IPublicKey; const AAmount: UInt64;
                                     const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ASource, False));
  Keys.Add(TAccountMeta.ReadOnly(ADelegate, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TTokenProgramData.EncodeApproveData(AAmount));
end;

class function TTokenProgram.Revoke(const ASource, AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ASource, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TTokenProgramData.EncodeRevokeData);
end;

class function TTokenProgram.SetAuthority(const AAccount: IPublicKey; const AAuthorityType: TAuthorityType;
                                          const ACurrentAuthority, ANewAuthority: IPublicKey;
                                          const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
  Opt: Integer;
  NewAuth: IPublicKey;
  Account: IAccount;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, False));
  Keys := AddSigners(Keys, ACurrentAuthority, ASigners);

  Opt := Ord(Assigned(ANewAuthority));

  if Assigned(ANewAuthority) then
    NewAuth := ANewAuthority
  else
  begin
    Account := TAccount.Create;
    NewAuth := Account.PublicKey;
  end;

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TTokenProgramData.EncodeSetAuthorityData(AAuthorityType, Opt, NewAuth));
end;

class function TTokenProgram.Burn(const ASource, AMint: IPublicKey; const AAmount: UInt64;
                                  const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ASource, False));
  Keys.Add(TAccountMeta.Writable(AMint, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TTokenProgramData.EncodeBurnData(AAmount));
end;

class function TTokenProgram.CloseAccount(const AAccount, ADestination, AAuthority, AProgramId: IPublicKey;
                                          const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, False));
  Keys.Add(TAccountMeta.Writable(ADestination, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);

  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, Keys, TTokenProgramData.EncodeCloseAccountData);
end;

class function TTokenProgram.FreezeAccount(const AAccount, AMint, AFreezeAuthority, AProgramId: IPublicKey;
                                           const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, False));
  Keys.Add(TAccountMeta.ReadOnly(AMint, False));
  Keys := AddSigners(Keys, AFreezeAuthority, ASigners);

  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, Keys, TTokenProgramData.EncodeFreezeAccountData);
end;

class function TTokenProgram.ThawAccount(const AAccount, AMint, AFreezeAuthority, AProgramId: IPublicKey;
                                         const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, False));
  Keys.Add(TAccountMeta.ReadOnly(AMint, False));
  Keys := AddSigners(Keys, AFreezeAuthority, ASigners);

  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, Keys, TTokenProgramData.EncodeThawAccountData);
end;

class function TTokenProgram.ApproveChecked(const ASource, ADelegate: IPublicKey; const AAmount: UInt64; const ADecimals: Byte;
                                            const AAuthority, AMint: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ASource, False));
  Keys.Add(TAccountMeta.ReadOnly(AMint, False));
  Keys.Add(TAccountMeta.ReadOnly(ADelegate, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TTokenProgramData.EncodeApproveCheckedData(AAmount, ADecimals));
end;

class function TTokenProgram.MintToChecked(const AMint, ADestination, AMintAuthority: IPublicKey;
                                           const AAmount: UInt64; const ADecimals: Integer;
                                           const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AMint, False));
  Keys.Add(TAccountMeta.Writable(ADestination, False));
  Keys := AddSigners(Keys, AMintAuthority, ASigners);

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TTokenProgramData.EncodeMintToCheckedData(AAmount, ADecimals));
end;

class function TTokenProgram.BurnChecked(const AMint, AAccount, AAuthority: IPublicKey;
                                         const AAmount: UInt64; const ADecimals: Integer;
                                         const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, False));
  Keys.Add(TAccountMeta.Writable(AMint, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TTokenProgramData.EncodeBurnCheckedData(AAmount, ADecimals));
end;

class function TTokenProgram.SyncNative(const AAccount: IPublicKey): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, False));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TTokenProgramData.EncodeSyncNativeData);
end;

{ ==== Decoder entrypoint ==== }

class function TTokenProgram.Decode(const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction;

var
  Instruction: Byte;
  InstructionValue: TTokenProgramInstructions.TValues;
begin
  Instruction := TDeserialization.GetU8(AData, TTokenProgramData.MethodOffset);

  if GetEnumName(TypeInfo(TTokenProgramInstructions.TValues), Instruction) = '' then
  begin
    Result := TDecodedInstruction.Create;
    Result.PublicKey        := ProgramIdKey;
    Result.InstructionName  := 'Unknown Instruction';
    Result.ProgramName      := ProgramName;
    Result.Values             := TDictionary<string, TValue>.Create;
    Result.InnerInstructions  := TList<IDecodedInstruction>.Create();
    Exit;
  end;

  InstructionValue := TTokenProgramInstructions.TValues(Instruction);

  Result := TDecodedInstruction.Create;
  Result.PublicKey       := ProgramIdKey;
  Result.InstructionName := TTokenProgramInstructions.Names[InstructionValue];
  Result.ProgramName     := ProgramName;
  Result.Values          := TDictionary<string, TValue>.Create;
  Result.InnerInstructions := TList<IDecodedInstruction>.Create();

  case InstructionValue of
    TTokenProgramInstructions.TValues.InitializeMint:
      TTokenProgramData.DecodeInitializeMintData(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.InitializeAccount:
      TTokenProgramData.DecodeInitializeAccountData(Result, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.InitializeMultiSignature:
      TTokenProgramData.DecodeInitializeMultiSignatureData(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.Transfer:
      TTokenProgramData.DecodeTransferData(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.Approve:
      TTokenProgramData.DecodeApproveData(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.Revoke:
      TTokenProgramData.DecodeRevokeData(Result, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.SetAuthority:
      TTokenProgramData.DecodeSetAuthorityData(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.MintTo:
      TTokenProgramData.DecodeMintToData(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.Burn:
      TTokenProgramData.DecodeBurnData(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.CloseAccount:
      TTokenProgramData.DecodeCloseAccountData(Result, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.FreezeAccount:
      TTokenProgramData.DecodeFreezeAccountData(Result, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.ThawAccount:
      TTokenProgramData.DecodeThawAccountData(Result, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.TransferChecked:
      TTokenProgramData.DecodeTransferCheckedData(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.ApproveChecked:
      TTokenProgramData.DecodeApproveCheckedData(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.MintToChecked:
      TTokenProgramData.DecodeMintToCheckedData(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.BurnChecked:
      TTokenProgramData.DecodeBurnCheckedData(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.SyncNative:
      TTokenProgramData.DecodeSyncNativeData(Result, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.InitializeAccount2:
      TTokenProgramData.DecodeInitializeAccount2(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.InitializeAccount3:
      TTokenProgramData.DecodeInitializeAccount3(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.InitializeMint2:
      TTokenProgramData.DecodeInitializeMint2(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.InitializeMultiSignature2:
      TTokenProgramData.DecodeInitializeMultiSignature2(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.GetAccountDataSize:
      TTokenProgramData.DecodeGetAccountDataSize(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.InitializeImmutableOwner:
      TTokenProgramData.DecodeInitializeImmutableOwner(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.AmountToUiAmount:
      TTokenProgramData.DecodeAmountToUiAmount(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.UiAmountToAmount:
      TTokenProgramData.DecodeUiAmountToAmount(Result, AData, AKeys, AKeyIndices);
  end;
end;

end.

