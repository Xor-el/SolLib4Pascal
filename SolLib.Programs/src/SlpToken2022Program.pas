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

unit SlpToken2022Program;

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

/// <summary>
/// Represents the types of authorities for Token2022Program.SetAuthority instructions.
/// </summary>
type
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
    CloseAccount = 3,

    /// <summary>
    /// Authority to set the transfer fee.
    /// </summary>
    TransferFeeConfig = 4,

    /// <summary>
    /// Authority to withdraw withheld tokens from a mint.
    /// </summary>
    WithheldWithdraw = 5,

    /// <summary>
    /// Authority to close a mint account.
    /// </summary>
    CloseMint = 6,

    /// <summary>
    /// Authority to set the interest rate.
    /// </summary>
    InterestRate = 7,

    /// <summary>
    /// Authority to transfer or burn any tokens for a mint.
    /// </summary>
    PermanentDelegate = 8,

    /// <summary>
    /// Authority to update confidential transfer mint and approve accounts for confidential transfers.
    /// </summary>
    ConfidentialTransferMint = 9,

    /// <summary>
    /// Authority to set the transfer hook program id.
    /// </summary>
    TransferHookProgramId = 10,

    /// <summary>
    /// Authority to set the withdraw withheld authority encryption key.
    /// </summary>
    ConfidentialTransferFeeConfig = 11,

    /// <summary>
    /// Authority to set the metadata address.
    /// </summary>
    MetadataPointer = 12,

    /// <summary>
    /// Authority to set the group address.
    /// </summary>
    GroupPointer = 13,

    /// <summary>
    /// Authority to set the group member address.
    /// </summary>
    GroupMemberPointer = 14,

    /// <summary>
    /// Authority to set the UI amount scale.
    /// </summary>
    ScaledUiAmount = 15,

    /// <summary>
    /// Authority to pause or resume minting / transferring / burning.
    /// </summary>
    Pause = 16
  );

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
  {                                                 Token2022ProgramData                                              }
  {====================================================================================================================}
  /// <summary>
  /// Implements the token program data encodings.
  /// </summary>
  TToken2022ProgramData = class sealed
  public const
    /// <summary>
    /// The offset at which the value which defines the method begins.
    /// </summary>
    MethodOffset = 0;
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
  public
    {---------------------------- Encoders ---------------------------------------------}

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.Revoke"/> method.
    /// </summary>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeRevokeData: TBytes; static;
    /// <summary>
    /// Encode the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.Approve"/> method.
    /// </summary>
    /// <param name="AAmount">The amount of tokens to approve the transfer of.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeApproveData(const AAmount: UInt64): TBytes; static;
    /// <summary>
    /// Encode the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.InitializeAccount"/> method.
    /// </summary>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeInitializeAccountData: TBytes; static;
    /// <summary>
    /// Encode the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.InitializeMint"/> method.
    /// </summary>
    /// <param name="AMintAuthority">The mint authority for the token.</param>
    /// <param name="AFreezeAuthority">The freeze authority for the token.</param>
    /// <param name="ADecimals">The amount of decimals.</param>
    /// <param name="AFreezeAuthorityOption">The freeze authority option for the token.</param>
    /// <remarks>The <c>FreezeAuthorityOption</c> parameter is related to the existence or not of a freeze authority.</remarks>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeInitializeMintData(const AMintAuthority, AFreezeAuthority: IPublicKey;
      const ADecimals, AFreezeAuthorityOption: Integer): TBytes; static;
      /// <summary>
      /// Encode the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.Transfer"/> method.
      /// </summary>
      /// <param name="AAmount">The amount of tokens.</param>
      /// <returns>The byte array with the encoded data.</returns>
    class function EncodeTransferData(const AAmount: UInt64): TBytes; static;
    /// <summary>
    /// Encode the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.TransferChecked"/> method.
    /// </summary>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <param name="ADecimals">The number of decimals of the token.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeTransferCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes; static;
    /// <summary>
    /// Encode the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.MintTo"/> method.
    /// </summary>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeMintToData(const AAmount: UInt64): TBytes; static;
    /// <summary>
    /// Encode the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.InitializeMultiSignature"/> method.
    /// </summary>
    /// <param name="AM">The number of signers necessary to validate the account.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeInitializeMultiSignatureData(const AM: Integer): TBytes; static;
    /// <summary>
    /// Encode the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.SetAuthority"/> method.
    /// </summary>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeSetAuthorityData(const AAuthorityType: TAuthorityType; const ANewAuthorityOption: Integer;
      ANewAuthority: IPublicKey): TBytes; static;
    /// <summary>
    /// Encode the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.Burn"/> method.
    /// </summary>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeBurnData(const AAmount: UInt64): TBytes; static;
    /// <summary>
    /// Encode the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.CloseAccount"/> method.
    /// </summary>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeCloseAccountData: TBytes; static;
    /// <summary>
    /// Encode the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.FreezeAccount"/> method.
    /// </summary>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeFreezeAccountData: TBytes; static;
    /// <summary>
    /// Encode the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.ThawAccount"/> method.
    /// </summary>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeThawAccountData: TBytes; static;
    /// <summary>
    /// Encodes the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.ApproveChecked"/> method.
    /// </summary>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <param name="ADecimals">The decimals of the token.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeApproveCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes; static;
    /// <summary>
    /// Encodes the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.MintToChecked"/> method.
    /// </summary>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <param name="ADecimals">The decimals of the token.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeMintToCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes; static;
    /// <summary>
    /// Encodes the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.BurnChecked"/> method.
    /// </summary>
    /// <param name="AAmount">The amount of tokens.</param>
    /// <param name="ADecimals">The decimals of the token.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeBurnCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes; static;
    /// <summary>
    /// Encodes the transaction instruction data for the <see cref="Token2022ProgramInstructions.Values.SyncNative"/> method.
    /// </summary>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeSyncNativeData: TBytes; static;

    {---------------------------- Decoders ---------------------------------------------}

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.InitializeMint"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeMintData(const ADecoded: IDecodedInstruction;
      const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.InitializeAccount"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeAccountData(const ADecoded: IDecodedInstruction;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.InitializeMultiSignature"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeMultiSignatureData(const ADecoded: IDecodedInstruction;
      const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.Transfer"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeTransferData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.Approve"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeApproveData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.Revoke"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeRevokeData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.SetAuthority"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeSetAuthorityData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.MintTo"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeMintToData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.Burn"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeBurnData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.CloseAccount"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeCloseAccountData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.FreezeAccount"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeFreezeAccountData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.ThawAccount"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeThawAccountData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.TransferChecked"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeTransferCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.ApproveChecked"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeApproveCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.MintToChecked"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeMintToCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.BurnChecked"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeBurnCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.SyncNative"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeSyncNativeData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.InitializeAccount2"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeAccount2(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.InitializeAccount3"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeAccount3(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.InitializeMultiSignature2"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeMultiSignature2(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.InitializeMint2"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeMint2(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.AmountToUiAmount"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="keyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeAmountToUiAmount(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.UiAmountToAmount"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeUiAmountToAmount(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.UiAmountToAmount"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeGetAccountDataSize(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="Token2022ProgramInstructions.Values.UiAmountToAmount"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeImmutableOwner(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
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
    class function GetProgramIdKey: IPublicKey; static;

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
end;

class destructor TToken2022ProgramInstructions.Destroy;
begin
  FNames.Free;
end;

{=== Token2022ProgramData � Encoders ===}

class function TToken2022ProgramData.EncodeAmountLayout(AMethod: Byte; const AAmount: UInt64): TBytes;
begin
  SetLength(Result, 9);
  TSerialization.WriteU8(Result, AMethod, MethodOffset);
  TSerialization.WriteU64(Result, AAmount, 1);
end;

class function TToken2022ProgramData.EncodeAmountCheckedLayout(AMethod: Byte; const AAmount: UInt64; ADecimals: Byte): TBytes;
begin
  SetLength(Result, 10);
  TSerialization.WriteU8(Result, AMethod, MethodOffset);
  TSerialization.WriteU64(Result, AAmount, 1);
  TSerialization.WriteU8(Result, ADecimals, 9);
end;

class function TToken2022ProgramData.EncodeRevokeData: TBytes;
begin
  Result := TBytes.Create(Byte(TToken2022ProgramInstructions.TValues.Revoke));
end;

class function TToken2022ProgramData.EncodeApproveData(const AAmount: UInt64): TBytes;
begin
  Result := EncodeAmountLayout(Byte(TToken2022ProgramInstructions.TValues.Approve), AAmount)
end;

class function TToken2022ProgramData.EncodeInitializeAccountData: TBytes;
begin
  Result := TBytes.Create(Byte(TToken2022ProgramInstructions.TValues.InitializeAccount));
end;

class function TToken2022ProgramData.EncodeInitializeMintData(const AMintAuthority, AFreezeAuthority: IPublicKey;
  const ADecimals, AFreezeAuthorityOption: Integer): TBytes;
begin
  SetLength(Result, 67);
  TSerialization.WriteU8(Result, Byte(TToken2022ProgramInstructions.TValues.InitializeMint), MethodOffset);
  TSerialization.WriteU8(Result, Byte(ADecimals), 1);
  TSerialization.WritePubKey(Result, AMintAuthority, 2);
  TSerialization.WriteU8(Result, Byte(AFreezeAuthorityOption), 34);
  TSerialization.WritePubKey(Result, AFreezeAuthority, 35);
end;

class function TToken2022ProgramData.EncodeTransferData(const AAmount: UInt64): TBytes;
begin
  Result := EncodeAmountLayout(Byte(TToken2022ProgramInstructions.TValues.Transfer), AAmount);
end;

class function TToken2022ProgramData.EncodeTransferCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes;
begin
  Result := EncodeAmountCheckedLayout(Byte(TToken2022ProgramInstructions.TValues.TransferChecked), AAmount, Byte(ADecimals));
end;

class function TToken2022ProgramData.EncodeMintToData(const AAmount: UInt64): TBytes;
begin
  Result := EncodeAmountLayout(Byte(TToken2022ProgramInstructions.TValues.MintTo), AAmount);
end;

class function TToken2022ProgramData.EncodeInitializeMultiSignatureData(const AM: Integer): TBytes;
begin
  SetLength(Result, 2);
  TSerialization.WriteU8(Result, Byte(TToken2022ProgramInstructions.TValues.InitializeMultiSignature), MethodOffset);
  TSerialization.WriteU8(Result, Byte(AM), 1);
end;

class function TToken2022ProgramData.EncodeSetAuthorityData(const AAuthorityType: TAuthorityType;
  const ANewAuthorityOption: Integer; ANewAuthority: IPublicKey): TBytes;
begin
  SetLength(Result, 35);
  TSerialization.WriteU8(Result, Byte(TToken2022ProgramInstructions.TValues.SetAuthority), MethodOffset);
  TSerialization.WriteU8(Result, Byte(AAuthorityType), 1);
  TSerialization.WriteU8(Result, ANewAuthorityOption, 2);
  TSerialization.WritePubKey(Result, ANewAuthority, 3);
end;

class function TToken2022ProgramData.EncodeBurnData(const AAmount: UInt64): TBytes;
begin
  Result := EncodeAmountLayout(Byte(TToken2022ProgramInstructions.TValues.Burn), AAmount);
end;

class function TToken2022ProgramData.EncodeCloseAccountData: TBytes;
begin
  Result := TBytes.Create(Byte(TToken2022ProgramInstructions.TValues.CloseAccount));
end;

class function TToken2022ProgramData.EncodeFreezeAccountData: TBytes;
begin
  Result := TBytes.Create(Byte(TToken2022ProgramInstructions.TValues.FreezeAccount));
end;

class function TToken2022ProgramData.EncodeThawAccountData: TBytes;
begin
  Result := TBytes.Create(Byte(TToken2022ProgramInstructions.TValues.ThawAccount));
end;

class function TToken2022ProgramData.EncodeApproveCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes;
begin
  Result := EncodeAmountCheckedLayout(Byte(TToken2022ProgramInstructions.TValues.ApproveChecked), AAmount, Byte(ADecimals));
end;

class function TToken2022ProgramData.EncodeMintToCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes;
begin
  Result := EncodeAmountCheckedLayout(Byte(TToken2022ProgramInstructions.TValues.MintToChecked), AAmount, Byte(ADecimals));
end;

class function TToken2022ProgramData.EncodeBurnCheckedData(const AAmount: UInt64; const ADecimals: Byte): TBytes;
begin
  Result := EncodeAmountCheckedLayout(Byte(TToken2022ProgramInstructions.TValues.BurnChecked), AAmount, Byte(ADecimals));
end;

class function TToken2022ProgramData.EncodeSyncNativeData: TBytes;
begin
  Result := TBytes.Create(Byte(TToken2022ProgramInstructions.TValues.SyncNative));
end;

{=== Token2022ProgramData � Decoders ===}

class procedure TToken2022ProgramData.DecodeInitializeMintData(const ADecoded: IDecodedInstruction;
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

class procedure TToken2022ProgramData.DecodeInitializeAccountData(const ADecoded: IDecodedInstruction;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint', TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
end;

class procedure TToken2022ProgramData.DecodeInitializeMultiSignatureData(const ADecoded: IDecodedInstruction;
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

class procedure TToken2022ProgramData.DecodeTransferData(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
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
    ADecoded.Values.Add(Format('Signer %d', [I - 2]), TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TToken2022ProgramData.DecodeApproveData(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
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
    ADecoded.Values.Add(Format('Signer %d', [I - 2]), TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TToken2022ProgramData.DecodeRevokeData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  I: Integer;
begin
  ADecoded.Values.Add('Source',    TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  for I := 2 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 1]), TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TToken2022ProgramData.DecodeSetAuthorityData(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
var
  LAuthType: TAuthorityType;
  I: Integer;
begin
  ADecoded.Values.Add('Account',           TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Current Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));

  LAuthType := TAuthorityType(TDeserialization.GetU8(AData, 1));
  ADecoded.Values.Add('Authority Type', TValue.From<TAuthorityType>(LAuthType));
  ADecoded.Values.Add('New Authority Option', TValue.From<Byte>(TDeserialization.GetU8(AData, 2)));

  if Length(AData) >= 34 then
    ADecoded.Values.Add('New Authority', TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 3)));

  for I := 2 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 1]), TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TToken2022ProgramData.DecodeMintToData(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
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
    ADecoded.Values.Add(Format('Signer %d', [I - 2]), TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TToken2022ProgramData.DecodeBurnData(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
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
    ADecoded.Values.Add(Format('Signer %d', [I - 2]), TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TToken2022ProgramData.DecodeCloseAccountData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  I: Integer;
begin
  ADecoded.Values.Add('Account',     TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Destination', TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority',   TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  for I := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 2]), TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TToken2022ProgramData.DecodeFreezeAccountData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  I: Integer;
begin
  ADecoded.Values.Add('Account',         TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',            TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Freeze Authority',TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  for I := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 2]), TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TToken2022ProgramData.DecodeThawAccountData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
var
  I: Integer;
begin
  ADecoded.Values.Add('Account',         TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',            TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Freeze Authority',TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  for I := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 2]), TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TToken2022ProgramData.DecodeTransferCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
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
    ADecoded.Values.Add(Format('Signer %d', [I - 3]), TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TToken2022ProgramData.DecodeApproveCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
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
    ADecoded.Values.Add(Format('Signer %d', [I - 3]), TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TToken2022ProgramData.DecodeMintToCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
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
    ADecoded.Values.Add(Format('Signer %d', [I - 2]), TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TToken2022ProgramData.DecodeBurnCheckedData(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
var
  I: Integer;
begin
  ADecoded.Values.Add('Account',   TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',      TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));

  ADecoded.Values.Add('Amount',   TValue.From<UInt64>(TDeserialization.GetU64(AData, 1)));
  ADecoded.Values.Add('Decimals', TValue.From<Byte>(TDeserialization.GetU8(AData, 9)));

  for I := 3 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 2]), TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TToken2022ProgramData.DecodeSyncNativeData(const ADecoded: IDecodedInstruction; const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
end;

class procedure TToken2022ProgramData.DecodeInitializeAccount2(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Account',   TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',      TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 1)));
end;

class procedure TToken2022ProgramData.DecodeInitializeAccount3(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Account',   TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Mint',      TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Authority', TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 1)));
end;

class procedure TToken2022ProgramData.DecodeInitializeMultiSignature2(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
var
  I: Integer;
begin
  ADecoded.Values.Add('Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Required Signers', TValue.From<Byte>(TDeserialization.GetU8(AData, 1)));
  for I := 1 to High(AKeyIndices) do
    ADecoded.Values.Add(Format('Signer %d', [I - 1]), TValue.From<IPublicKey>(AKeys[AKeyIndices[I]]));
end;

class procedure TToken2022ProgramData.DecodeInitializeMint2(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
var
  LHasFreeze: Boolean;
begin
  ADecoded.Values.Add('Account',        TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Decimals',       TValue.From<Byte>(TDeserialization.GetU8(AData, 1)));
  ADecoded.Values.Add('Mint Authority', TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 2)));

  LHasFreeze := TDeserialization.GetBool(AData, 34);
  ADecoded.Values.Add('Freeze Authority Option', TValue.From<Boolean>(LHasFreeze));
  if LHasFreeze then
    ADecoded.Values.Add('Freeze Authority', TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 35)));
end;

class procedure TToken2022ProgramData.DecodeAmountToUiAmount(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Mint',   TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Amount', TValue.From<UInt64>(TDeserialization.GetU64(AData, 1)));
end;

class procedure TToken2022ProgramData.DecodeUiAmountToAmount(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Mint',   TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Amount', TValue.From<string>(TDeserialization.DecodeBincodeString(AData, 1).EncodedString));
end;

class procedure TToken2022ProgramData.DecodeGetAccountDataSize(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Mint', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
end;

class procedure TToken2022ProgramData.DecodeInitializeImmutableOwner(const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
end;

{ TToken2022Program }

class constructor TToken2022Program.Create;
begin
  FProgramIdKey := TPublicKey.Create('TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb');
end;

class destructor TToken2022Program.Destroy;
begin
  FProgramIdKey := nil;
end;

class function TToken2022Program.GetProgramIdKey: IPublicKey;
begin
  Result := FProgramIdKey;
end;

class function TToken2022Program.AddSigners(const AKeys: TList<IAccountMeta>;
  const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): TList<IAccountMeta>;
var
  S: IPublicKey;
begin
  Result := AKeys;
  if (ASigners <> nil) then
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

class function TToken2022Program.Transfer(const ASource, ADestination: IPublicKey; const AAmount: UInt64;
  const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ASource, False));
  Keys.Add(TAccountMeta.Writable(ADestination, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TToken2022ProgramData.EncodeTransferData(AAmount));
end;

class function TToken2022Program.TransferChecked(const ASource, ADestination: IPublicKey; const AAmount: UInt64; const ADecimals: Integer;
  const AAuthority, ATokenMint: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ASource, False));
  Keys.Add(TAccountMeta.ReadOnly(ATokenMint, False));
  Keys.Add(TAccountMeta.Writable(ADestination, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TToken2022ProgramData.EncodeTransferCheckedData(AAmount, ADecimals));
end;

class function TToken2022Program.InitializeAccount(const AAccount, AMint, AAuthority: IPublicKey): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, False));
  Keys.Add(TAccountMeta.ReadOnly(AMint, False));
  Keys.Add(TAccountMeta.ReadOnly(AAuthority, False));
  Keys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TToken2022ProgramData.EncodeInitializeAccountData);
end;

class function TToken2022Program.InitializeMultiSignature(const AMultiSignature: IPublicKey; const ASigners: TArray<IPublicKey>;
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
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TToken2022ProgramData.EncodeInitializeMultiSignatureData(AM));
end;

class function TToken2022Program.InitializeMint(const AMint: IPublicKey; const ADecimals: Integer;
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

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys,
    TToken2022ProgramData.EncodeInitializeMintData(AMintAuthority, FreezeKey, ADecimals, FreezeOpt));
end;

class function TToken2022Program.MintTo(const AMint, ADestination: IPublicKey; const AAmount: UInt64;
  const AMintAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AMint, False));
  Keys.Add(TAccountMeta.Writable(ADestination, False));
  Keys := AddSigners(Keys, AMintAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TToken2022ProgramData.EncodeMintToData(AAmount));
end;

class function TToken2022Program.Approve(const ASource, ADelegate, AAuthority: IPublicKey; const AAmount: UInt64;
  const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ASource, False));
  Keys.Add(TAccountMeta.ReadOnly(ADelegate, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TToken2022ProgramData.EncodeApproveData(AAmount));
end;

class function TToken2022Program.Revoke(const ASource, AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ASource, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TToken2022ProgramData.EncodeRevokeData);
end;

class function TToken2022Program.SetAuthority(const AAccount: IPublicKey; const AAuthorityType: TAuthorityType;
  const ACurrentAuthority, ANewAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
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

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys,
    TToken2022ProgramData.EncodeSetAuthorityData(AAuthorityType, Opt, NewAuth));
end;

class function TToken2022Program.Burn(const ASource, AMint: IPublicKey; const AAmount: UInt64;
  const AAuthority: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ASource, False));
  Keys.Add(TAccountMeta.Writable(AMint, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TToken2022ProgramData.EncodeBurnData(AAmount));
end;

class function TToken2022Program.CloseAccount(const AAccount, ADestination, AAuthority, AProgramId: IPublicKey;
  const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, False));
  Keys.Add(TAccountMeta.Writable(ADestination, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, Keys, TToken2022ProgramData.EncodeCloseAccountData);
end;

class function TToken2022Program.FreezeAccount(const AAccount, AMint, AFreezeAuthority, AProgramId: IPublicKey;
  const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, False));
  Keys.Add(TAccountMeta.ReadOnly(AMint, False));
  Keys := AddSigners(Keys, AFreezeAuthority, ASigners);
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, Keys, TToken2022ProgramData.EncodeFreezeAccountData);
end;

class function TToken2022Program.ThawAccount(const AAccount, AMint, AFreezeAuthority, AProgramId: IPublicKey;
  const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, False));
  Keys.Add(TAccountMeta.ReadOnly(AMint, False));
  Keys := AddSigners(Keys, AFreezeAuthority, ASigners);
  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, Keys, TToken2022ProgramData.EncodeThawAccountData);
end;

class function TToken2022Program.ApproveChecked(const ASource, ADelegate: IPublicKey; const AAmount: UInt64; const ADecimals: Byte;
  const AAuthority, AMint: IPublicKey; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ASource, False));
  Keys.Add(TAccountMeta.ReadOnly(AMint, False));
  Keys.Add(TAccountMeta.ReadOnly(ADelegate, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TToken2022ProgramData.EncodeApproveCheckedData(AAmount, ADecimals));
end;

class function TToken2022Program.MintToChecked(const AMint, ADestination, AMintAuthority: IPublicKey;
  const AAmount: UInt64; const ADecimals: Integer; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AMint, False));
  Keys.Add(TAccountMeta.Writable(ADestination, False));
  Keys := AddSigners(Keys, AMintAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TToken2022ProgramData.EncodeMintToCheckedData(AAmount, ADecimals));
end;

class function TToken2022Program.BurnChecked(const AMint, AAccount, AAuthority: IPublicKey;
  const AAmount: UInt64; const ADecimals: Integer; const ASigners: TArray<IPublicKey>): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, False));
  Keys.Add(TAccountMeta.Writable(AMint, False));
  Keys := AddSigners(Keys, AAuthority, ASigners);
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TToken2022ProgramData.EncodeBurnCheckedData(AAmount, ADecimals));
end;

class function TToken2022Program.SyncNative(const AAccount: IPublicKey): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, False));
  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TToken2022ProgramData.EncodeSyncNativeData);
end;

class function TToken2022Program.Decode(const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction;
var
  Instruction: Byte;
  InstructionValue: TToken2022ProgramInstructions.TValues;
begin
  Instruction := TDeserialization.GetU8(AData, TToken2022ProgramData.MethodOffset);

  if GetEnumName(TypeInfo(TToken2022ProgramInstructions.TValues), Instruction) = '' then
  begin
    Result := TDecodedInstruction.Create;
    Result.PublicKey       := ProgramIdKey;
    Result.InstructionName := 'Unknown Instruction';
    Result.ProgramName     := ProgramName;
    Result.Values          := TDictionary<string, TValue>.Create;
    Result.InnerInstructions := TList<IDecodedInstruction>.Create();
    Exit;
  end;

  InstructionValue := TToken2022ProgramInstructions.TValues(Instruction);

  Result := TDecodedInstruction.Create;
  Result.PublicKey       := ProgramIdKey;
  Result.InstructionName := TToken2022ProgramInstructions.Names[InstructionValue];
  Result.ProgramName     := ProgramName;
  Result.Values          := TDictionary<string, TValue>.Create;
  Result.InnerInstructions := TList<IDecodedInstruction>.Create();

  case InstructionValue of
    TToken2022ProgramInstructions.TValues.InitializeMint:
      TToken2022ProgramData.DecodeInitializeMintData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.InitializeAccount:
      TToken2022ProgramData.DecodeInitializeAccountData(Result, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.InitializeMultiSignature:
      TToken2022ProgramData.DecodeInitializeMultiSignatureData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.Transfer:
      TToken2022ProgramData.DecodeTransferData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.Approve:
      TToken2022ProgramData.DecodeApproveData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.Revoke:
      TToken2022ProgramData.DecodeRevokeData(Result, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.SetAuthority:
      TToken2022ProgramData.DecodeSetAuthorityData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.MintTo:
      TToken2022ProgramData.DecodeMintToData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.Burn:
      TToken2022ProgramData.DecodeBurnData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.CloseAccount:
      TToken2022ProgramData.DecodeCloseAccountData(Result, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.FreezeAccount:
      TToken2022ProgramData.DecodeFreezeAccountData(Result, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.ThawAccount:
      TToken2022ProgramData.DecodeThawAccountData(Result, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.TransferChecked:
      TToken2022ProgramData.DecodeTransferCheckedData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.ApproveChecked:
      TToken2022ProgramData.DecodeApproveCheckedData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.MintToChecked:
      TToken2022ProgramData.DecodeMintToCheckedData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.BurnChecked:
      TToken2022ProgramData.DecodeBurnCheckedData(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.SyncNative:
      TToken2022ProgramData.DecodeSyncNativeData(Result, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.InitializeAccount2:
      TToken2022ProgramData.DecodeInitializeAccount2(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.InitializeAccount3:
      TToken2022ProgramData.DecodeInitializeAccount3(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.InitializeMint2:
      TToken2022ProgramData.DecodeInitializeMint2(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.InitializeMultiSignature2:
      TToken2022ProgramData.DecodeInitializeMultiSignature2(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.GetAccountDataSize:
      TToken2022ProgramData.DecodeGetAccountDataSize(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.InitializeImmutableOwner:
      TToken2022ProgramData.DecodeInitializeImmutableOwner(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.AmountToUiAmount:
      TToken2022ProgramData.DecodeAmountToUiAmount(Result, AData, AKeys, AKeyIndices);
    TToken2022ProgramInstructions.TValues.UiAmountToAmount:
      TToken2022ProgramData.DecodeUiAmountToAmount(Result, AData, AKeys, AKeyIndices);
  end;
end;

end.

