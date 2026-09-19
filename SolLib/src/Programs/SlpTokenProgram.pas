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

unit SlpTokenProgram;

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
  SlpToken2022ExtensionType;

type
  /// <summary>
  /// Represents the types of authorities for <see cref="TTokenProgram.SetAuthority"/> and
  /// <see cref="TToken2022Program.SetAuthority"/> instructions.
  /// </summary>
  TAuthorityType = (
    /// <summary>Authority to mint new tokens.</summary>
    MintTokens = 0,
    /// <summary>Authority to freeze any account associated with the mint.</summary>
    FreezeAccount = 1,
    /// <summary>Owner of a given account token.</summary>
    AccountOwner = 2,
    /// <summary>Authority to close a given account.</summary>
    CloseAccount = 3,
    /// <summary>Authority to set the transfer fee.</summary>
    TransferFeeConfig = 4,
    /// <summary>Authority to withdraw withheld tokens from a mint.</summary>
    WithheldWithdraw = 5,
    /// <summary>Authority to close a mint account.</summary>
    CloseMint = 6,
    /// <summary>Authority to set the interest rate.</summary>
    InterestRate = 7,
    /// <summary>Authority to transfer or burn any tokens for a mint.</summary>
    PermanentDelegate = 8,
    /// <summary>Authority to update confidential transfer mint and approve accounts for confidential transfers.</summary>
    ConfidentialTransferMint = 9,
    /// <summary>Authority to set the transfer hook program id.</summary>
    TransferHookProgramId = 10,
    /// <summary>Authority to set the withdraw withheld authority encryption key.</summary>
    ConfidentialTransferFeeConfig = 11,
    /// <summary>Authority to set the metadata address.</summary>
    MetadataPointer = 12,
    /// <summary>Authority to set the group address.</summary>
    GroupPointer = 13,
    /// <summary>Authority to set the group member address.</summary>
    GroupMemberPointer = 14,
    /// <summary>Authority to set the UI amount scale.</summary>
    ScaledUiAmount = 15,
    /// <summary>Authority to pause or resume minting / transferring / burning.</summary>
    Pause = 16
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
        UiAmountToAmount = 24,
        /// <summary>Initialize the close authority on a mint.</summary>
        InitializeMintCloseAuthority = 25,
        /// <summary>Transfer fee extension instruction gate (unimplemented).</summary>
        TransferFeeExtension = 26,
        /// <summary>Confidential transfer extension instruction gate (unimplemented).</summary>
        ConfidentialTransferExtension = 27,
        /// <summary>Default account state extension instruction gate (unimplemented).</summary>
        DefaultAccountStateExtension = 28,
        /// <summary>Reallocate a token account to fit the given extension types.</summary>
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
  {                                                    TokenProgramData                                               }
  {====================================================================================================================}
  /// <summary>
  /// Implements the token program data encodings.
  /// </summary>
  TTokenProgramData = class sealed
  public
    /// <summary>
    /// The offset at which the value which defines the method begins.
    /// </summary>
    const MethodOffset = 0;
  private
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
    /// <summary>
    /// Encodes the data for methods that require only an owner public key (discriminator + 32-byte owner).
    /// </summary>
    class function EncodeInitializeAccountOwnerData(AMethod: Byte; const AOwner: IPublicKey): TBytes; static;
  public
   {---------------------------- Encoders ---------------------------------------------}
    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.Revoke"/> method.
    /// </summary>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeRevokeData: TBytes; static;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.Approve"/> method.
    /// </summary>
    /// <param name="AAmount">The amount of tokens to approve the transfer of.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeApproveData(const AAmount: UInt64): TBytes; static;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.InitializeAccount"/> method.
    /// </summary>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeInitializeAccountData: TBytes; static;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.InitializeMint"/> method.
    /// </summary>
    /// <param name="AMintAuthority">The mint authority for the token.</param>
    /// <param name="AFreezeAuthority">The freeze authority for the token.</param>
    /// <param name="ADecimals">The amount of decimals.</param>
    /// <param name="AFreezeAuthorityOption">The freeze authority option for the token.</param>
    /// <remarks>The <c>AFreezeAuthorityOption</c> parameter is related to the existence or not of a freeze authority.</remarks>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeInitializeMintData(const AMintAuthority, AFreezeAuthority: IPublicKey;
      const ADecimals, AFreezeAuthorityOption: Integer): TBytes; static;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.Transfer"/> method.
    /// </summary>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeTransferData(const AAmount: UInt64): TBytes; static;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.TransferChecked"/> method.
    /// </summary>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <param name="ADecimals">The number of decimals of the token.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeTransferCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes; static;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.MintTo"/> method.
    /// </summary>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <returns>The byte array with the encoded data.</returns>
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
    /// <param name="AAuthorityType">The authority type.</param>
    /// <param name="ANewAuthorityOption">The new authority option.</param>
    /// <param name="ANewAuthority">The new authority public key.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeSetAuthorityData(const AAuthorityType: TAuthorityType; const ANewAuthorityOption: Integer; ANewAuthority: IPublicKey): TBytes;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.Burn"/> method.
    /// </summary>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeBurnData(const AAmount: UInt64): TBytes; static;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.ThawAccount"/> method.
    /// </summary>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeThawAccountData: TBytes; static;

    /// <summary>
    /// Encodes the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.ApproveChecked"/> method.
    /// </summary>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <param name="ADecimals">The decimals of the token.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeApproveCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes; static;

    /// <summary>
    /// Encodes the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.MintToChecked"/> method.
    /// </summary>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <param name="ADecimals">The decimals of the token.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeMintToCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes;

    /// <summary>
    /// Encodes the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.BurnChecked"/> method.
    /// </summary>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <param name="ADecimals">The decimals of the token.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeBurnCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.CloseAccount"/> method.
    /// </summary>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeCloseAccountData: TBytes;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.FreezeAccount"/> method.
    /// </summary>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeFreezeAccountData: TBytes; static;

    /// <summary>
    /// Encodes the transaction instruction data for the <see cref="TTokenProgramInstructions.TValues.SyncNative"/> method.
    /// </summary>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeSyncNativeData: TBytes; static;

    /// <summary>Encode the data for the <see cref="TTokenProgramInstructions.TValues.InitializeAccount2"/> method (discriminator + 32-byte owner).</summary>
    class function EncodeInitializeAccount2Data(const AOwner: IPublicKey): TBytes; static;
    /// <summary>Encode the data for the <see cref="TTokenProgramInstructions.TValues.InitializeAccount3"/> method (discriminator + 32-byte owner).</summary>
    class function EncodeInitializeAccount3Data(const AOwner: IPublicKey): TBytes; static;
    /// <summary>Encode the data for the <see cref="TTokenProgramInstructions.TValues.InitializeMultiSignature2"/> method.</summary>
    class function EncodeInitializeMultiSignature2Data(const AM: Integer): TBytes; static;
    /// <summary>Encode the data for the <see cref="TTokenProgramInstructions.TValues.InitializeMint2"/> method.</summary>
    class function EncodeInitializeMint2Data(const AMintAuthority, AFreezeAuthority: IPublicKey;
      const ADecimals, AFreezeAuthorityOption: Integer): TBytes; static;
    /// <summary>Encode the data for the <see cref="TTokenProgramInstructions.TValues.GetAccountDataSize"/> method (discriminator + u16 per extension).</summary>
    class function EncodeGetAccountDataSizeData(const AExtensionTypes: TArray<TToken2022ExtensionType>): TBytes; static;
    /// <summary>Encode the data for the <see cref="TTokenProgramInstructions.TValues.InitializeImmutableOwner"/> method.</summary>
    class function EncodeInitializeImmutableOwnerData: TBytes; static;
    /// <summary>Encode the data for the <see cref="TTokenProgramInstructions.TValues.AmountToUiAmount"/> method.</summary>
    class function EncodeAmountToUiAmountData(const AAmount: UInt64): TBytes; static;
    /// <summary>Encode the data for the <see cref="TTokenProgramInstructions.TValues.UiAmountToAmount"/> method (discriminator + raw UTF-8 bytes).</summary>
    class function EncodeUiAmountToAmountData(const AUiAmount: string): TBytes; static;
    /// <summary>Encode the data for the <see cref="TTokenProgramInstructions.TValues.InitializeMintCloseAuthority"/> method.</summary>
    class function EncodeInitializeMintCloseAuthorityData(const ACloseAuthority: IPublicKey): TBytes; static;
    /// <summary>Encode the data for the <see cref="TTokenProgramInstructions.TValues.Reallocate"/> method (discriminator + u16 per extension).</summary>
    class function EncodeReallocateData(const AExtensionTypes: TArray<TToken2022ExtensionType>): TBytes; static;

    {---------------------------- Decoders ---------------------------------------------}

    /// <summary>
    /// Decodes a token instruction for either token program: reads the method discriminator,
    /// dispatches to the matching decoder, and returns the populated instruction tagged with the
    /// supplied program name and id. The classic Token program and the Token-2022 program share
    /// this dispatch since their instruction layouts are identical.
    /// </summary>
    class function DispatchDecode(const AProgramName: string; const AProgramIdKey: IPublicKey;
      const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction; static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.InitializeMint"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeMintData(const ADecoded: IDecodedInstruction;
      const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.InitializeAccount"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeAccountData(const ADecoded: IDecodedInstruction;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.InitializeMultiSignature"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeMultiSignatureData(const ADecoded: IDecodedInstruction;
       const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.Transfer"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeTransferData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.Approve"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeApproveData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.Revoke"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeRevokeData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.SetAuthority"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeSetAuthorityData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.MintTo"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeMintToData(const ADecoded: IDecodedInstruction;
      const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.Burn"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeBurnData(const ADecoded: IDecodedInstruction;
      const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.CloseAccount"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeCloseAccountData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.FreezeAccount"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeFreezeAccountData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.ThawAccount"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeThawAccountData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.TransferChecked"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeTransferCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.ApproveChecked"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeApproveCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.MintToChecked"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeMintToCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.BurnChecked"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeBurnCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.SyncNative"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeSyncNativeData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.InitializeAccount2"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeAccount2(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.InitializeAccount3"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeAccount3(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.InitializeMultiSignature2"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeMultiSignature2(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.InitializeMint2"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeMint2(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.AmountToUiAmount"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeAmountToUiAmount(const ADecoded: IDecodedInstruction;
      const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.UiAmountToAmount"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeUiAmountToAmount(const ADecoded: IDecodedInstruction;
      const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.GetAccountDataSize"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeGetAccountDataSize(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="TTokenProgramInstructions.TValues.InitializeImmutableOwner"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeImmutableOwner(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction data for the <see cref="TTokenProgramInstructions.TValues.InitializeMintCloseAuthority"/> method.
    /// </summary>
    class procedure DecodeInitializeMintCloseAuthority(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction data for the <see cref="TTokenProgramInstructions.TValues.Reallocate"/> method.
    /// </summary>
    class procedure DecodeReallocate(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
  end;

  {====================================================================================================================}
  {                                                      TokenProgram                                                 }
  {====================================================================================================================}
  /// <summary>
  /// Implements the Token Program methods.
  /// <remarks>
  /// <summary>
  /// Shared instruction-builder core for the SPL token programs. The classic Token
  /// program and the Token-2022 program emit byte-identical instructions apart from the
  /// program id they target, so both delegate here, passing their own program id. This is
  /// the single source of truth for the token instruction layouts (and for the signer
  /// convention: an empty or absent multisig signer set means a single signing authority).
  /// </summary>
  TTokenProgramCore = class sealed
  public
    class function AddSigners(const AKeys: TList<IAccountMeta>; const AAuthority: IPublicKey;
      const ASigners: TArray<IPublicKey>): TList<IAccountMeta>; static;
    class function Transfer(const AProgramId, ASource, ADestination: IPublicKey; const AAmount: UInt64;
      const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction; static;
    class function TransferChecked(const AProgramId, ASource, ADestination: IPublicKey; const AAmount: UInt64;
      const ADecimals: Integer; const AAuthority, ATokenMint: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction; static;
    class function InitializeAccount(const AProgramId, AAccount, AMint, AAuthority: IPublicKey): ITransactionInstruction; static;
    class function InitializeAccount2(const AProgramId, AAccount, AMint, AOwner: IPublicKey): ITransactionInstruction; static;
    class function InitializeAccount3(const AProgramId, AAccount, AMint, AOwner: IPublicKey): ITransactionInstruction; static;
    class function InitializeMultiSignature(const AProgramId, AMultiSignature: IPublicKey;
      const ASigners: TArray<IPublicKey>; const AM: Integer): ITransactionInstruction; static;
    class function InitializeMint(const AProgramId, AMint: IPublicKey; const ADecimals: Integer;
      const AMintAuthority, AFreezeAuthority: IPublicKey): ITransactionInstruction; static;
    class function InitializeMint2(const AProgramId, AMint: IPublicKey; const ADecimals: Integer;
      const AMintAuthority, AFreezeAuthority: IPublicKey): ITransactionInstruction; static;
    class function MintTo(const AProgramId, AMint, ADestination: IPublicKey; const AAmount: UInt64;
      const AMintAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction; static;
    class function Approve(const AProgramId, ASource, ADelegate, AAuthority: IPublicKey; const AAmount: UInt64;
      const ASigners: TArray<IPublicKey>): ITransactionInstruction; static;
    class function Revoke(const AProgramId, ASource, AAuthority: IPublicKey;
      const ASigners: TArray<IPublicKey>): ITransactionInstruction; static;
    class function SetAuthority(const AProgramId, AAccount: IPublicKey; const AAuthorityType: TAuthorityType;
      const ACurrentAuthority, ANewAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction; static;
    class function Burn(const AProgramId, ASource, AMint: IPublicKey; const AAmount: UInt64;
      const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction; static;
    class function CloseAccount(const AProgramId, AAccount, ADestination, AAuthority: IPublicKey;
      const ASigners: TArray<IPublicKey>): ITransactionInstruction; static;
    class function FreezeAccount(const AProgramId, AAccount, AMint, AFreezeAuthority: IPublicKey;
      const ASigners: TArray<IPublicKey>): ITransactionInstruction; static;
    class function ThawAccount(const AProgramId, AAccount, AMint, AFreezeAuthority: IPublicKey;
      const ASigners: TArray<IPublicKey>): ITransactionInstruction; static;
    class function ApproveChecked(const AProgramId, ASource, ADelegate: IPublicKey; const AAmount: UInt64;
      const ADecimals: Byte; const AAuthority, AMint: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction; static;
    class function MintToChecked(const AProgramId, AMint, ADestination, AMintAuthority: IPublicKey;
      const AAmount: UInt64; const ADecimals: Integer; const ASigners: TArray<IPublicKey>): ITransactionInstruction; static;
    class function BurnChecked(const AProgramId, AMint, AAccount, AAuthority: IPublicKey;
      const AAmount: UInt64; const ADecimals: Integer; const ASigners: TArray<IPublicKey>): ITransactionInstruction; static;
    class function SyncNative(const AProgramId, AAccount: IPublicKey): ITransactionInstruction; static;
  end;

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
    /// Initializes an instruction to initialize a new token account whose owner is passed in the
    /// instruction data (requires the Rent sysvar).
    /// </summary>
    /// <param name="AAccount">The public key of the account to initialize.</param>
    /// <param name="AMint">The public key of the token mint.</param>
    /// <param name="AOwner">The owner passed via instruction data.</param>
    /// <returns>The transaction instruction.</returns>
    class function InitializeAccount2(const AAccount, AMint, AOwner: IPublicKey): ITransactionInstruction; static;

    /// <summary>
    /// Initializes an instruction to initialize a new token account whose owner is passed in the
    /// instruction data (does not require the Rent sysvar).
    /// </summary>
    /// <param name="AAccount">The public key of the account to initialize.</param>
    /// <param name="AMint">The public key of the token mint.</param>
    /// <param name="AOwner">The owner passed via instruction data.</param>
    /// <returns>The transaction instruction.</returns>
    class function InitializeAccount3(const AAccount, AMint, AOwner: IPublicKey): ITransactionInstruction; static;

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
    /// Initializes an instruction to initialize a mint that does not require the Rent sysvar.
    /// </summary>
    /// <param name="AMint">The public key of the token mint.</param>
    /// <param name="ADecimals">The token decimals.</param>
    /// <param name="AMintAuthority">The public key of the token mint authority.</param>
    /// <param name="AFreezeAuthority">The token freeze authority.</param>
    class function InitializeMint2(const AMint: IPublicKey; const ADecimals: Integer;
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
    /// <param name="ADelegate">The public key of the delegate account authorized to perform a transfer from the source account.</param>
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
    /// <param name="AAuthorityType">The type of authority to set.</param>
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
    /// <param name="ADelegate">The public key of the delegate account authorized to perform a transfer from the source account.</param>
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
  FNames.Add(TValues.InitializeMintCloseAuthority, 'Initialize Mint Close Authority');
  FNames.Add(TValues.TransferFeeExtension, 'Transfer Fee Extension');
  FNames.Add(TValues.ConfidentialTransferExtension, 'Confidential Transfer Extension');
  FNames.Add(TValues.DefaultAccountStateExtension, 'Default Account State Extension');
  FNames.Add(TValues.Reallocate, 'Reallocate');
end;

class destructor TTokenProgramInstructions.Destroy;
begin
  FNames.Free;
end;

{ TokenProgramData }

{=== TokenProgramData - Encoders ===}

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

class function TTokenProgramData.EncodeInitializeAccountOwnerData(AMethod: Byte; const AOwner: IPublicKey): TBytes;
begin
  SetLength(Result, 33);
  TSerialization.WriteU8(Result, AMethod, MethodOffset);
  TSerialization.WritePubKey(Result, AOwner, 1);
end;

class function TTokenProgramData.EncodeInitializeAccount2Data(const AOwner: IPublicKey): TBytes;
begin
  Result := EncodeInitializeAccountOwnerData(Byte(TTokenProgramInstructions.TValues.InitializeAccount2), AOwner);
end;

class function TTokenProgramData.EncodeInitializeAccount3Data(const AOwner: IPublicKey): TBytes;
begin
  Result := EncodeInitializeAccountOwnerData(Byte(TTokenProgramInstructions.TValues.InitializeAccount3), AOwner);
end;

class function TTokenProgramData.EncodeInitializeMultiSignature2Data(const AM: Integer): TBytes;
begin
  SetLength(Result, 2);
  TSerialization.WriteU8(Result, Byte(TTokenProgramInstructions.TValues.InitializeMultiSignature2), MethodOffset);
  TSerialization.WriteU8(Result, Byte(AM), 1);
end;

class function TTokenProgramData.EncodeInitializeMint2Data(const AMintAuthority, AFreezeAuthority: IPublicKey;
  const ADecimals, AFreezeAuthorityOption: Integer): TBytes;
begin
  SetLength(Result, 67);
  TSerialization.WriteU8(Result, Byte(TTokenProgramInstructions.TValues.InitializeMint2), MethodOffset);
  TSerialization.WriteU8(Result, Byte(ADecimals), 1);
  TSerialization.WritePubKey(Result, AMintAuthority, 2);
  TSerialization.WriteU8(Result, Byte(AFreezeAuthorityOption), 34);
  TSerialization.WritePubKey(Result, AFreezeAuthority, 35);
end;

class function TTokenProgramData.EncodeGetAccountDataSizeData(const AExtensionTypes: TArray<TToken2022ExtensionType>): TBytes;
var
  LI: Integer;
begin
  SetLength(Result, 1 + Length(AExtensionTypes) * 2);
  TSerialization.WriteU8(Result, Byte(TTokenProgramInstructions.TValues.GetAccountDataSize), MethodOffset);
  for LI := 0 to High(AExtensionTypes) do
    TSerialization.WriteU16(Result, Word(Ord(AExtensionTypes[LI])), 1 + LI * 2);
end;

class function TTokenProgramData.EncodeInitializeImmutableOwnerData: TBytes;
begin
  Result := TBytes.Create(Byte(TTokenProgramInstructions.TValues.InitializeImmutableOwner));
end;

class function TTokenProgramData.EncodeAmountToUiAmountData(const AAmount: UInt64): TBytes;
begin
  Result := EncodeAmountLayout(Byte(TTokenProgramInstructions.TValues.AmountToUiAmount), AAmount);
end;

class function TTokenProgramData.EncodeUiAmountToAmountData(const AUiAmount: string): TBytes;
var
  LUiAmountBytes: TBytes;
begin
  LUiAmountBytes := TEncoding.UTF8.GetBytes(AUiAmount);
  SetLength(Result, 1 + Length(LUiAmountBytes));
  TSerialization.WriteU8(Result, Byte(TTokenProgramInstructions.TValues.UiAmountToAmount), MethodOffset);
  if Length(LUiAmountBytes) > 0 then
    Move(LUiAmountBytes[0], Result[1], Length(LUiAmountBytes));
end;

class function TTokenProgramData.EncodeInitializeMintCloseAuthorityData(const ACloseAuthority: IPublicKey): TBytes;
begin
  if ACloseAuthority = nil then
  begin
    SetLength(Result, 2);
    TSerialization.WriteU8(Result, Byte(TTokenProgramInstructions.TValues.InitializeMintCloseAuthority), MethodOffset);
    TSerialization.WriteU8(Result, 0, 1);
    Exit;
  end;

  SetLength(Result, 34);
  TSerialization.WriteU8(Result, Byte(TTokenProgramInstructions.TValues.InitializeMintCloseAuthority), MethodOffset);
  TSerialization.WriteU8(Result, 1, 1);
  TSerialization.WritePubKey(Result, ACloseAuthority, 2);
end;

class function TTokenProgramData.EncodeReallocateData(const AExtensionTypes: TArray<TToken2022ExtensionType>): TBytes;
var
  LI: Integer;
begin
  SetLength(Result, 1 + Length(AExtensionTypes) * 2);
  TSerialization.WriteU8(Result, Byte(TTokenProgramInstructions.TValues.Reallocate), MethodOffset);
  for LI := 0 to High(AExtensionTypes) do
    TSerialization.WriteU16(Result, Word(Ord(AExtensionTypes[LI])), 1 + LI * 2);
end;

{=== TokenProgramData - Decoders ===}

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
  LI: Integer;
  LNum: Byte;
begin
  ADecoded.Values.Add('Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  LNum := TDeserialization.GetU8(AData, 1);
  ADecoded.Values.Add('Required Signers', LNum);
  for LI := 2 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [LI - 1]), TValue.From<IPublicKey>(AKeys[AKeyIndices[LI]]));
end;

class procedure TTokenProgramData.DecodeTransferData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LI: Integer;
  LAmount: UInt64;
begin
  ADecoded.Values.Add('Source',      TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Destination', TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority',   TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));

  LAmount := TDeserialization.GetU64(AData, 1);
  ADecoded.Values.Add('Amount', LAmount);

  for LI := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [LI - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[LI]]));
end;

class procedure TTokenProgramData.DecodeApproveData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LI: Integer;
  LAmount: UInt64;
begin
  ADecoded.Values.Add('Source',    TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Delegate',  TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));

  LAmount := TDeserialization.GetU64(AData, 1);
  ADecoded.Values.Add('Amount', LAmount);

  for LI := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [LI - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[LI]]));
end;


class procedure TTokenProgramData.DecodeRevokeData(
  const ADecoded: IDecodedInstruction;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LI: Integer;
begin
  ADecoded.Values.Add('Source',    TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  for LI := 2 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [LI - 1]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[LI]]));
end;

class procedure TTokenProgramData.DecodeSetAuthorityData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LAuthType: TAuthorityType;
  LI: Integer;
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
  for LI := 2 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [LI - 1]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[LI]]));
end;

class procedure TTokenProgramData.DecodeMintToData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LAmount: UInt64;
  LI: Integer;
begin
  ADecoded.Values.Add('Mint',           TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Destination',    TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Mint Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));

  LAmount := TDeserialization.GetU64(AData, 1);
  ADecoded.Values.Add('Amount', LAmount);

  for LI := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [LI - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[LI]]));
end;

class procedure TTokenProgramData.DecodeBurnData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LAmount: UInt64;
  LI: Integer;
begin
  ADecoded.Values.Add('Account',   TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',      TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));

  LAmount := TDeserialization.GetU64(AData, 1);
  ADecoded.Values.Add('Amount', LAmount);

  for LI := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [LI - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[LI]]));
end;

class procedure TTokenProgramData.DecodeCloseAccountData(
  const ADecoded: IDecodedInstruction;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LI: Integer;
begin
  ADecoded.Values.Add('Account',     TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Destination', TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority',   TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  for LI := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [LI - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[LI]]));
end;

class procedure TTokenProgramData.DecodeFreezeAccountData(
  const ADecoded: IDecodedInstruction;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LI: Integer;
begin
  ADecoded.Values.Add('Account',         TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',            TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Freeze Authority',TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  for LI := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [LI - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[LI]]));
end;

class procedure TTokenProgramData.DecodeThawAccountData(
  const ADecoded: IDecodedInstruction;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LI: Integer;
begin
  ADecoded.Values.Add('Account',         TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',            TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Freeze Authority',TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  for LI := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [LI - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[LI]]));
end;

class procedure TTokenProgramData.DecodeTransferCheckedData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LI: Integer;
begin
  ADecoded.Values.Add('Source',      TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',        TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Destination', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  ADecoded.Values.Add('Authority',   TValue.From<IPublicKey>(AKeys[AKeyIndices[3]]));

  ADecoded.Values.Add('Amount',   TValue.From<UInt64>(TDeserialization.GetU64(AData, 1)));
  ADecoded.Values.Add('Decimals', TValue.From<Byte>(TDeserialization.GetU8(AData, 9)));

  for LI := 4 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [LI - 3]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[LI]]));
end;

class procedure TTokenProgramData.DecodeApproveCheckedData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LI: Integer;
begin
  ADecoded.Values.Add('Source',    TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',      TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Delegate',  TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[3]]));

  ADecoded.Values.Add('Amount',   TValue.From<UInt64>(TDeserialization.GetU64(AData, 1)));
  ADecoded.Values.Add('Decimals', TValue.From<Byte>(TDeserialization.GetU8(AData, 9)));

  for LI := 4 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [LI - 3]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[LI]]));
end;

class procedure TTokenProgramData.DecodeMintToCheckedData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LAmount: UInt64;
  LDec: Byte;
  LI: Integer;
begin
  ADecoded.Values.Add('Mint',           TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Destination',    TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Mint Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));

  LAmount := TDeserialization.GetU64(AData, 1);
  LDec := TDeserialization.GetU8(AData, 9);
  ADecoded.Values.Add('Amount',   LAmount);
  ADecoded.Values.Add('Decimals', LDec);

  for LI := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [LI - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[LI]]));
end;

class procedure TTokenProgramData.DecodeBurnCheckedData(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LI: Integer;
begin
  ADecoded.Values.Add('Account',   TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',      TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));

  ADecoded.Values.Add('Amount',   TValue.From<UInt64>(TDeserialization.GetU64(AData, 1)));
  ADecoded.Values.Add('Decimals', TValue.From<Byte>(TDeserialization.GetU8(AData, 9)));

  for LI := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [LI - 2]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[LI]]));
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
  LI: Integer;
begin
  ADecoded.Values.Add('Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Required Signers', TValue.From<Byte>(TDeserialization.GetU8(AData, 1)));

  for LI := 1 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [LI - 1]),
      TValue.From<IPublicKey>(AKeys[AKeyIndices[LI]]));
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
var
  LLen: Integer;
  LAmount: string;
begin
  ADecoded.Values.Add('Mint', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));

  // The amount is a raw UTF-8 string that runs from offset 1 to the end (no length prefix).
  LLen := Length(AData) - 1;
  if LLen > 0 then
    LAmount := TEncoding.UTF8.GetString(Copy(AData, 1, LLen))
  else
    LAmount := '';
  ADecoded.Values.Add('Amount', TValue.From<string>(LAmount));
end;

class procedure TTokenProgramData.DecodeGetAccountDataSize(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LExtensions: TArray<TToken2022ExtensionType>;
  LOffset, LCount: Integer;
  LValue: Word;
  LExt: TToken2022ExtensionType;
begin
  ADecoded.Values.Add('Mint', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));

  LCount := 0;
  SetLength(LExtensions, 0);
  LOffset := 1;
  while LOffset + 1 < Length(AData) do
  begin
    LValue := TDeserialization.GetU16(AData, LOffset);
    if TEnumUtilities.TryGetEnumFromOrdinal<TToken2022ExtensionType>(LValue, LExt) then
    begin
      SetLength(LExtensions, LCount + 1);
      LExtensions[LCount] := LExt;
      Inc(LCount);
    end;
    Inc(LOffset, 2);
  end;
  ADecoded.Values.Add('Extension Types', TValue.From<TArray<TToken2022ExtensionType>>(LExtensions));
end;

class procedure TTokenProgramData.DecodeInitializeImmutableOwner(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
end;

class procedure TTokenProgramData.DecodeInitializeMintCloseAuthority(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LHasCloseAuthority: Boolean;
begin
  ADecoded.Values.Add('Mint', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  LHasCloseAuthority := (Length(AData) > 1) and (TDeserialization.GetU8(AData, 1) = 1);
  ADecoded.Values.Add('Close Authority Option', TValue.From<Boolean>(LHasCloseAuthority));
  if LHasCloseAuthority then
    ADecoded.Values.Add('Close Authority', TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 2)));
end;

class procedure TTokenProgramData.DecodeReallocate(
  const ADecoded: IDecodedInstruction;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  LExtensions: TArray<TToken2022ExtensionType>;
  LOffset, LCount: Integer;
  LValue: Word;
  LExt: TToken2022ExtensionType;
begin
  ADecoded.Values.Add('Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Payer',   TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Owner',   TValue.From<IPublicKey>(AKeys[AKeyIndices[3]]));

  LCount := 0;
  SetLength(LExtensions, 0);
  LOffset := 1;
  while LOffset + 1 < Length(AData) do
  begin
    LValue := TDeserialization.GetU16(AData, LOffset);
    if TEnumUtilities.TryGetEnumFromOrdinal<TToken2022ExtensionType>(LValue, LExt) then
    begin
      SetLength(LExtensions, LCount + 1);
      LExtensions[LCount] := LExt;
      Inc(LCount);
    end;
    Inc(LOffset, 2);
  end;
  ADecoded.Values.Add('Extension Types', TValue.From<TArray<TToken2022ExtensionType>>(LExtensions));
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

{ TTokenProgramCore }

class function TTokenProgramCore.AddSigners(const AKeys: TList<IAccountMeta>;
  const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): TList<IAccountMeta>;
var
  LS: IPublicKey;
begin
  Result := AKeys;
  if (ASigners <> nil) and (Length(ASigners) > 0) then
  begin
    Result.Add(TAccountMeta.ReadOnly(AAuthority, False));
    for LS in ASigners do
      Result.Add(TAccountMeta.ReadOnly(LS, True));
  end
  else
    Result.Add(TAccountMeta.ReadOnly(AAuthority, True));
end;

class function TTokenProgramCore.Transfer(const AProgramId, ASource, ADestination: IPublicKey;
  const AAmount: UInt64; const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ASource, False));
  LKeys.Add(TAccountMeta.Writable(ADestination, False));
  LKeys := AddSigners(LKeys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeTransferData(AAmount));
end;

class function TTokenProgramCore.TransferChecked(const AProgramId, ASource, ADestination: IPublicKey;
  const AAmount: UInt64; const ADecimals: Integer; const AAuthority, ATokenMint: IPublicKey;
  const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ASource, False));
  LKeys.Add(TAccountMeta.ReadOnly(ATokenMint, False));
  LKeys.Add(TAccountMeta.Writable(ADestination, False));
  LKeys := AddSigners(LKeys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeTransferCheckedData(AAmount, ADecimals));
end;

class function TTokenProgramCore.InitializeAccount(const AProgramId, AAccount, AMint, AAuthority: IPublicKey): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(AMint, False));
  LKeys.Add(TAccountMeta.ReadOnly(AAuthority, False));
  LKeys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeInitializeAccountData);
end;

class function TTokenProgramCore.InitializeAccount2(const AProgramId, AAccount, AMint, AOwner: IPublicKey): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(AMint, False));
  LKeys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeInitializeAccount2Data(AOwner));
end;

class function TTokenProgramCore.InitializeAccount3(const AProgramId, AAccount, AMint, AOwner: IPublicKey): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(AMint, False));
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeInitializeAccount3Data(AOwner));
end;

class function TTokenProgramCore.InitializeMultiSignature(const AProgramId, AMultiSignature: IPublicKey;
  const ASigners: TArray<IPublicKey>; const AM: Integer): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
  LS: IPublicKey;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AMultiSignature, False));
  LKeys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));
  for LS in ASigners do
    LKeys.Add(TAccountMeta.ReadOnly(LS, False));
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeInitializeMultiSignatureData(AM));
end;

class function TTokenProgramCore.InitializeMint(const AProgramId, AMint: IPublicKey; const ADecimals: Integer;
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

  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys,
    TTokenProgramData.EncodeInitializeMintData(AMintAuthority, LFreezeKey, ADecimals, LFreezeOpt));
end;

class function TTokenProgramCore.InitializeMint2(const AProgramId, AMint: IPublicKey; const ADecimals: Integer;
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

  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys,
    TTokenProgramData.EncodeInitializeMint2Data(AMintAuthority, LFreezeKey, ADecimals, LFreezeOpt));
end;

class function TTokenProgramCore.MintTo(const AProgramId, AMint, ADestination: IPublicKey; const AAmount: UInt64;
  const AMintAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AMint, False));
  LKeys.Add(TAccountMeta.Writable(ADestination, False));
  LKeys := AddSigners(LKeys, AMintAuthority, ASigners);
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeMintToData(AAmount));
end;

class function TTokenProgramCore.Approve(const AProgramId, ASource, ADelegate, AAuthority: IPublicKey;
  const AAmount: UInt64; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ASource, False));
  LKeys.Add(TAccountMeta.ReadOnly(ADelegate, False));
  LKeys := AddSigners(LKeys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeApproveData(AAmount));
end;

class function TTokenProgramCore.Revoke(const AProgramId, ASource, AAuthority: IPublicKey;
  const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ASource, False));
  LKeys := AddSigners(LKeys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeRevokeData);
end;

class function TTokenProgramCore.SetAuthority(const AProgramId, AAccount: IPublicKey; const AAuthorityType: TAuthorityType;
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

  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys,
    TTokenProgramData.EncodeSetAuthorityData(AAuthorityType, LOpt, LNewAuth));
end;

class function TTokenProgramCore.Burn(const AProgramId, ASource, AMint: IPublicKey; const AAmount: UInt64;
  const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ASource, False));
  LKeys.Add(TAccountMeta.Writable(AMint, False));
  LKeys := AddSigners(LKeys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeBurnData(AAmount));
end;

class function TTokenProgramCore.CloseAccount(const AProgramId, AAccount, ADestination, AAuthority: IPublicKey;
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

class function TTokenProgramCore.FreezeAccount(const AProgramId, AAccount, AMint, AFreezeAuthority: IPublicKey;
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

class function TTokenProgramCore.ThawAccount(const AProgramId, AAccount, AMint, AFreezeAuthority: IPublicKey;
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

class function TTokenProgramCore.ApproveChecked(const AProgramId, ASource, ADelegate: IPublicKey; const AAmount: UInt64;
  const ADecimals: Byte; const AAuthority, AMint: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ASource, False));
  LKeys.Add(TAccountMeta.ReadOnly(AMint, False));
  LKeys.Add(TAccountMeta.ReadOnly(ADelegate, False));
  LKeys := AddSigners(LKeys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeApproveCheckedData(AAmount, ADecimals));
end;

class function TTokenProgramCore.MintToChecked(const AProgramId, AMint, ADestination, AMintAuthority: IPublicKey;
  const AAmount: UInt64; const ADecimals: Integer; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AMint, False));
  LKeys.Add(TAccountMeta.Writable(ADestination, False));
  LKeys := AddSigners(LKeys, AMintAuthority, ASigners);
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeMintToCheckedData(AAmount, ADecimals));
end;

class function TTokenProgramCore.BurnChecked(const AProgramId, AMint, AAccount, AAuthority: IPublicKey;
  const AAmount: UInt64; const ADecimals: Integer; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  LKeys.Add(TAccountMeta.Writable(AMint, False));
  LKeys := AddSigners(LKeys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeBurnCheckedData(AAmount, ADecimals));
end;

class function TTokenProgramCore.SyncNative(const AProgramId, AAccount: IPublicKey): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(AAccount, False));
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, LKeys, TTokenProgramData.EncodeSyncNativeData);
end;

{ TTokenProgram }

class function TTokenProgram.AddSigners(const AKeys: TList<IAccountMeta>;
                                        const AAuthority: IPublicKey;
                                        const ASigners: TArray<IPublicKey>): TList<IAccountMeta>;
begin
  Result := TTokenProgramCore.AddSigners(AKeys, AAuthority, ASigners);
end;

class function TTokenProgram.Transfer(const ASource, ADestination: IPublicKey; const AAmount: UInt64;
                                      const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
begin
  Result := TTokenProgramCore.Transfer(ProgramIdKey, ASource, ADestination, AAmount, AAuthority, ASigners);
end;

class function TTokenProgram.TransferChecked(const ASource, ADestination: IPublicKey; const AAmount: UInt64; const ADecimals: Integer;
                                             const AAuthority, ATokenMint: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
begin
  Result := TTokenProgramCore.TransferChecked(ProgramIdKey, ASource, ADestination, AAmount, ADecimals, AAuthority, ATokenMint, ASigners);
end;

class function TTokenProgram.InitializeAccount(const AAccount, AMint, AAuthority: IPublicKey): ITransactionInstruction;
begin
  Result := TTokenProgramCore.InitializeAccount(ProgramIdKey, AAccount, AMint, AAuthority);
end;

class function TTokenProgram.InitializeAccount2(const AAccount, AMint, AOwner: IPublicKey): ITransactionInstruction;
begin
  Result := TTokenProgramCore.InitializeAccount2(ProgramIdKey, AAccount, AMint, AOwner);
end;

class function TTokenProgram.InitializeAccount3(const AAccount, AMint, AOwner: IPublicKey): ITransactionInstruction;
begin
  Result := TTokenProgramCore.InitializeAccount3(ProgramIdKey, AAccount, AMint, AOwner);
end;

class function TTokenProgram.InitializeMultiSignature(const AMultiSignature: IPublicKey; const ASigners: TArray<IPublicKey>;
                                                      const AM: Integer): ITransactionInstruction;
begin
  Result := TTokenProgramCore.InitializeMultiSignature(ProgramIdKey, AMultiSignature, ASigners, AM);
end;

class function TTokenProgram.InitializeMint(const AMint: IPublicKey; const ADecimals: Integer;
                                            const AMintAuthority, AFreezeAuthority: IPublicKey): ITransactionInstruction;
begin
  Result := TTokenProgramCore.InitializeMint(ProgramIdKey, AMint, ADecimals, AMintAuthority, AFreezeAuthority);
end;

class function TTokenProgram.InitializeMint2(const AMint: IPublicKey; const ADecimals: Integer;
  const AMintAuthority, AFreezeAuthority: IPublicKey): ITransactionInstruction;
begin
  Result := TTokenProgramCore.InitializeMint2(ProgramIdKey, AMint, ADecimals, AMintAuthority, AFreezeAuthority);
end;

class function TTokenProgram.MintTo(const AMint, ADestination: IPublicKey; const AAmount: UInt64;
                                    const AMintAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
begin
  Result := TTokenProgramCore.MintTo(ProgramIdKey, AMint, ADestination, AAmount, AMintAuthority, ASigners);
end;

class function TTokenProgram.Approve(const ASource, ADelegate, AAuthority: IPublicKey; const AAmount: UInt64;
                                     const ASigners: TArray<IPublicKey>): ITransactionInstruction;
begin
  Result := TTokenProgramCore.Approve(ProgramIdKey, ASource, ADelegate, AAuthority, AAmount, ASigners);
end;

class function TTokenProgram.Revoke(const ASource, AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
begin
  Result := TTokenProgramCore.Revoke(ProgramIdKey, ASource, AAuthority, ASigners);
end;

class function TTokenProgram.SetAuthority(const AAccount: IPublicKey; const AAuthorityType: TAuthorityType;
                                          const ACurrentAuthority, ANewAuthority: IPublicKey;
                                          const ASigners: TArray<IPublicKey>): ITransactionInstruction;
begin
  Result := TTokenProgramCore.SetAuthority(ProgramIdKey, AAccount, AAuthorityType, ACurrentAuthority, ANewAuthority, ASigners);
end;

class function TTokenProgram.Burn(const ASource, AMint: IPublicKey; const AAmount: UInt64;
                                  const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
begin
  Result := TTokenProgramCore.Burn(ProgramIdKey, ASource, AMint, AAmount, AAuthority, ASigners);
end;

class function TTokenProgram.CloseAccount(const AAccount, ADestination, AAuthority, AProgramId: IPublicKey;
                                          const ASigners: TArray<IPublicKey>): ITransactionInstruction;
begin
  Result := TTokenProgramCore.CloseAccount(AProgramId, AAccount, ADestination, AAuthority, ASigners);
end;

class function TTokenProgram.FreezeAccount(const AAccount, AMint, AFreezeAuthority, AProgramId: IPublicKey;
                                           const ASigners: TArray<IPublicKey>): ITransactionInstruction;
begin
  Result := TTokenProgramCore.FreezeAccount(AProgramId, AAccount, AMint, AFreezeAuthority, ASigners);
end;

class function TTokenProgram.ThawAccount(const AAccount, AMint, AFreezeAuthority, AProgramId: IPublicKey;
                                         const ASigners: TArray<IPublicKey>): ITransactionInstruction;
begin
  Result := TTokenProgramCore.ThawAccount(AProgramId, AAccount, AMint, AFreezeAuthority, ASigners);
end;

class function TTokenProgram.ApproveChecked(const ASource, ADelegate: IPublicKey; const AAmount: UInt64; const ADecimals: Byte;
                                            const AAuthority, AMint: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
begin
  Result := TTokenProgramCore.ApproveChecked(ProgramIdKey, ASource, ADelegate, AAmount, ADecimals, AAuthority, AMint, ASigners);
end;

class function TTokenProgram.MintToChecked(const AMint, ADestination, AMintAuthority: IPublicKey;
                                           const AAmount: UInt64; const ADecimals: Integer;
                                           const ASigners: TArray<IPublicKey>): ITransactionInstruction;
begin
  Result := TTokenProgramCore.MintToChecked(ProgramIdKey, AMint, ADestination, AMintAuthority, AAmount, ADecimals, ASigners);
end;

class function TTokenProgram.BurnChecked(const AMint, AAccount, AAuthority: IPublicKey;
                                         const AAmount: UInt64; const ADecimals: Integer;
                                         const ASigners: TArray<IPublicKey>): ITransactionInstruction;
begin
  Result := TTokenProgramCore.BurnChecked(ProgramIdKey, AMint, AAccount, AAuthority, AAmount, ADecimals, ASigners);
end;

class function TTokenProgram.SyncNative(const AAccount: IPublicKey): ITransactionInstruction;
begin
  Result := TTokenProgramCore.SyncNative(ProgramIdKey, AAccount);
end;

{ ==== Decoder entrypoint ==== }

class function TTokenProgramData.DispatchDecode(const AProgramName: string; const AProgramIdKey: IPublicKey;
  const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction;
var
  LInstruction: Byte;
  LInstructionValue: TTokenProgramInstructions.TValues;
begin
  LInstruction := TDeserialization.GetU8(AData, TTokenProgramData.MethodOffset);

  if not TEnumUtilities.TryGetEnumFromOrdinal<TTokenProgramInstructions.TValues>(LInstruction, LInstructionValue) then
  begin
    Result := TDecodedInstruction.Create;
    Result.PublicKey := AProgramIdKey;
    Result.InstructionName := 'Unknown Instruction';
    Result.ProgramName := AProgramName;
    Result.Values := TDictionary<string, TValue>.Create;
    Result.InnerInstructions := TList<IDecodedInstruction>.Create();
    Exit;
  end;

  Result := TDecodedInstruction.Create;
  Result.PublicKey := AProgramIdKey;
  Result.InstructionName := TTokenProgramInstructions.Names[LInstructionValue];
  Result.ProgramName := AProgramName;
  Result.Values := TDictionary<string, TValue>.Create;
  Result.InnerInstructions := TList<IDecodedInstruction>.Create();

  case LInstructionValue of
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
    TTokenProgramInstructions.TValues.InitializeMintCloseAuthority:
      TTokenProgramData.DecodeInitializeMintCloseAuthority(Result, AData, AKeys, AKeyIndices);
    TTokenProgramInstructions.TValues.Reallocate:
      TTokenProgramData.DecodeReallocate(Result, AData, AKeys, AKeyIndices);
  end;
end;

class function TTokenProgram.Decode(const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction;
begin
  Result := TTokenProgramData.DispatchDecode(ProgramName, ProgramIdKey, AData, AKeys, AKeyIndices);
end;

end.

