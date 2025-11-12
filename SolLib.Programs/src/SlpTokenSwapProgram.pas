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

unit SlpTokenSwapProgram;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
  System.TypInfo,
  SlpPublicKey,

  SlpAccountDomain,
  SlpTransactionInstruction,

  SlpDeserialization,
  SlpSerialization,
  SlpDecodedInstruction,
  SlpTokenProgram,
  SlpTokenSwapModel,
  SlpSolLibExceptions;

type
  TAuthorityPair = record
  private
    FPublicKey: IPublicKey;
    FNonce: Byte;
  public
    constructor Create(const APublicKey: IPublicKey; ANonce: Byte);
    property PublicKey: IPublicKey read FPublicKey;
    property Nonce: Byte read FNonce;
  end;

  {====================================================================================================================}
  {                                           TokenSwapProgramInstructions                                             }
  {====================================================================================================================}
  /// <summary>
  /// Represents the instruction types for the <see cref="TTokenSwapProgram"/> along with a friendly name
  /// <remarks>
  /// For more information see:
  /// https://spl.solana.com/token-swap
  /// https://docs.rs/spl-token-swap/2.1.0/spl_token_swap/
  /// </remarks>
  /// </summary>
  TTokenSwapProgramInstructions = class sealed
  public
    type
      /// <summary>
      /// Represents the instruction types for the <see cref="TTokenSwapProgram"/>.
      /// </summary>
      TValues = (
        /// <summary>Initializes a new swap.</summary>
        Initialize = 0,
        /// <summary>Swap the tokens in the pool.</summary>
        Swap = 1,
        /// <summary>Deposit both types of tokens into the pool.</summary>
        DepositAllTokenTypes = 2,
        /// <summary>Withdraw both types of tokens from the pool at the current ratio.</summary>
        WithdrawAllTokenTypes = 3,
        /// <summary>Deposit one type of tokens into the pool.</summary>
        DepositSingleTokenTypeExactAmountIn = 4,
        /// <summary>Withdraw one token type from the pool at the current ratio.</summary>
        WithdrawSingleTokenTypeExactAmountOut = 5
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
  {                                              TokenSwapProgramData                                                  }
  {====================================================================================================================}
  /// <summary>
  /// Implements the token swap program data encodings.
  /// </summary>
  TTokenSwapProgramData = class sealed
  public
    /// <summary>Offset where the method discriminator byte is written.</summary>
    const MethodOffset = 0;

    {-------------------------------- Encoders --------------------------------}

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenSwapProgramInstructions.TValues.Initialize"/> method.
    /// </summary>
    /// <param name="ANonce">nonce used to create valid program address.</param>
    /// <param name="AFees">all swap fees.</param>
    /// <param name="ASwapCurve">swap curve info for pool, including CurveType and anything else that may be required.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeInitializeData(const ANonce: Byte; const AFees: IFees; const ASwapCurve: ISwapCurve): TBytes; static;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenSwapProgramInstructions.TValues.Swap"/> method.
    /// </summary>
    /// <param name="AAmountIn">The amount of tokens in.</param>
    /// <param name="AAmountOut">The amount of tokens out.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeSwapData(const AAmountIn, AAmountOut: UInt64): TBytes; static;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenSwapProgramInstructions.TValues.DepositAllTokenTypes"/> method.
    /// </summary>
    /// <param name="APoolTokenAmount">The amount of tokens out.</param>
    /// <param name="AMaxTokenAAmount">The max amount of tokens A.</param>
    /// <param name="AMaxTokenBAmount">The max amount of tokens B.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeDepositAllTokenTypesData(const APoolTokenAmount, AMaxTokenAAmount, AMaxTokenBAmount: UInt64): TBytes; static;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenSwapProgramInstructions.TValues.WithdrawAllTokenTypes"/> method.
    /// </summary>
    /// <param name="APoolTokenAmount">The amount of tokens in.</param>
    /// <param name="AMinTokenAAmount">The maminx amount of tokens A.</param>
    /// <param name="AMinTokenBAmount">The min amount of tokens B.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeWithdrawAllTokenTypesData(const APoolTokenAmount, AMinTokenAAmount, AMinTokenBAmount: UInt64): TBytes; static;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenSwapProgramInstructions.TValues.DepositSingleTokenTypeExactAmountIn"/> method.
    /// </summary>
    /// <param name="ASourceTokenAmount">The amount of tokens in.</param>
    /// <param name="AMinPoolTokenAmount">The min amount of pool tokens out.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeDepositSingleTokenTypeExactAmountInData(const ASourceTokenAmount, AMinPoolTokenAmount: UInt64): TBytes; static;

    /// <summary>
    /// Encode the transaction instruction data for the <see cref="TTokenSwapProgramInstructions.TValues.WithdrawSingleTokenTypeExactAmountOut"/> method.
    /// </summary>
    /// <param name="ADestTokenAmount">The amount of tokens out.</param>
    /// <param name="AMaxPoolTokenAmount">The max amount of pool tokens in.</param>
    /// <returns>The byte array with the encoded data.</returns>
    class function EncodeWithdrawSingleTokenTypeExactAmountOutData(const ADestTokenAmount, AMaxPoolTokenAmount: UInt64): TBytes; static;

    {-------------------------------- Decoders --------------------------------}

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="TTokenSwapProgramInstructions.TValues.Initialize"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="TTokenSwapProgramInstructions.TValues.Swap"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeSwapData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="TTokenSwapProgramInstructions.TValues.DepositAllTokenTypes"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeDepositAllTokenTypesData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="TTokenSwapProgramInstructions.TValues.WithdrawAllTokenTypes"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeWithdrawAllTokenTypesData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="TTokenSwapProgramInstructions.TValues.DepositSingleTokenTypeExactAmountIn"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeDepositSingleTokenTypeExactAmountInData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="TTokenSwapProgramInstructions.TValues.WithdrawSingleTokenTypeExactAmountOut"/> method
    /// </summary>
    /// <param name="ADecoded">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeWithdrawSingleTokenTypeExactAmountOutData(const ADecoded: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
  end;

  {====================================================================================================================}
  {                                                 TokenSwapProgram                                                   }
  {====================================================================================================================}
  /// <summary>
  /// Implements the Token Swap Program methods.
  /// <remarks>
  /// For more information see:
  /// https://spl.solana.com/token-swap
  /// https://docs.rs/spl-token-swap/2.1.0/spl_token_swap/
  /// </remarks>
  /// </summary>
  TTokenSwapProgram = class sealed
  private
    const ProgramName = 'Token Swap Program';

    class var FProgramIdKey: IPublicKey;
    class var FOwnerKey: IPublicKey;
    class function GetProgramIdKey: IPublicKey; static;
    class function GetOwnerKey: IPublicKey; static;

  public
    /// <summary>The SPL Token Swap Program ID.</summary>
    class property ProgramIdKey: IPublicKey read GetProgramIdKey;
    /// <summary>The owner key required to use as the fee account owner.</summary>
    class property OwnerKey: IPublicKey read GetOwnerKey;

    /// <summary>
    /// Token Swap data length.
    /// </summary>
    const TokenSwapDataLength = TTokenSwapAccount.TokenSwapDataLength;

    class constructor Create;
    class destructor Destroy;

    /// <summary>
    /// Create the authority
    /// </summary>
    /// <returns>The swap authority</returns>
    /// <exception cref="EInvalidProgramException">No program account could be found (exhausted nonces)</exception>
    class function CreateAuthority(const ATokenSwapAccount: IPublicKey): TAuthorityPair; static;

    /// <summary>
    /// Initializes a new swap.
    /// </summary>
    /// <param name="ATokenSwapAccount">The token swap account to initialize.</param>
    /// <param name="ATokenAAccount">token_a Account. Must be non zero, owned by swap authority.</param>
    /// <param name="ATokenBAccount">token_b Account. Must be non zero, owned by swap authority.</param>
    /// <param name="APoolTokenMint">Pool Token Mint. Must be empty, owned by swap authority.</param>
    /// <param name="APoolTokenFeeAccount">Pool Token Account to deposit trading and withdraw fees. Must be empty, not owned by swap authority.</param>
    /// <param name="AUserPoolTokenAccount">Pool Token Account to deposit the initial pool token supply.  Must be empty, not owned by swap authority.</param>
    /// <param name="AFees">Fees to use for this token swap.</param>
    /// <param name="ASwapCurve">Curve to use for this token swap.</param>
    /// <returns>The transaction instruction.</returns>
    class function Initialize(const ATokenSwapAccount,
                              ATokenAAccount,
                              ATokenBAccount,
                              APoolTokenMint,
                              APoolTokenFeeAccount,
                              AUserPoolTokenAccount: IPublicKey;
                              const AFees: IFees; const ASwapCurve: ISwapCurve): ITransactionInstruction; static;

    /// <summary>
    /// Swap the tokens in the pool.
    /// </summary>
    /// <param name="ATokenSwapAccount">The token swap account to operate over.</param>
    /// <param name="AUserTransferAuthority">user transfer authority.</param>
    /// <param name="ATokenSourceAccount">token_(A|B) SOURCE Account, amount is transferable by user transfer authority.</param>
    /// <param name="ATokenBaseIntoAccount">token_(A|B) Base Account to swap INTO.  Must be the SOURCE token.</param>
    /// <param name="ATokenBaseFromAccount">token_(A|B) Base Account to swap FROM.  Must be the DESTINATION token.</param>
    /// <param name="ATokenDestinationAccount">token_(A|B) DESTINATION Account assigned to USER as the owner.</param>
    /// <param name="APoolTokenMint">Pool token mint, to generate trading fees.</param>
    /// <param name="APoolTokenFeeAccount">Fee account, to receive trading fees.</param>
    /// <param name="APoolTokenHostFeeAccount">Host fee account to receive additional trading fees.</param>
    /// <param name="AAmountIn">SOURCE amount to transfer, output to DESTINATION is based on the exchange rate.</param>
    /// <param name="AAmountOut">Minimum amount of DESTINATION token to output, prevents excessive slippage.</param>
    /// <returns>The transaction instruction.</returns>
    class function Swap(const ATokenSwapAccount,
                        AUserTransferAuthority,
                        ATokenSourceAccount,
                        ATokenBaseIntoAccount,
                        ATokenBaseFromAccount,
                        ATokenDestinationAccount,
                        APoolTokenMint,
                        APoolTokenFeeAccount,
                        APoolTokenHostFeeAccount: IPublicKey;
                        const AAmountIn, AAmountOut: UInt64): ITransactionInstruction; static;

    /// <summary>
    /// Deposit both types of tokens into the pool.  The output is a "pool"
    ///   token representing ownership in the pool. Inputs are converted to
    ///   the current ratio.
    /// </summary>
    /// <param name="ATokenSwapAccount">The token swap account to operate over.</param>
    /// <param name="AUserTransferAuthority">user transfer authority.</param>
    /// <param name="ATokenAUserAccount">token_a - user transfer authority can transfer amount.</param>
    /// <param name="ATokenBUserAccount">token_b - user transfer authority can transfer amount.</param>
    /// <param name="ATokenADepositAccount">token_a Base Account to deposit into.</param>
    /// <param name="ATokenBDepositAccount">token_b Base Account to deposit into.</param>
    /// <param name="APoolTokenMint">Pool MINT account, swap authority is the owner.</param>
    /// <param name="APoolTokenUserAccount">Pool Account to deposit the generated tokens, user is the owner.</param>
    /// <param name="APoolTokenAmount">Pool token amount to transfer. token_a and token_b amount are set by the current exchange rate and size of the pool.</param>
    /// <param name="AMaxTokenA">Maximum token A amount to deposit, prevents excessive slippage.</param>
    /// <param name="AMaxTokenB">Maximum token B amount to deposit, prevents excessive slippage.</param>
    /// <returns>The transaction instruction.</returns>
    class function DepositAllTokenTypes(const ATokenSwapAccount,
                                        AUserTransferAuthority,
                                        ATokenAUserAccount,
                                        ATokenBUserAccount,
                                        ATokenADepositAccount,
                                        ATokenBDepositAccount,
                                        APoolTokenMint,
                                        APoolTokenUserAccount: IPublicKey;
                                        const APoolTokenAmount, AMaxTokenA, AMaxTokenB: UInt64): ITransactionInstruction; static;

    /// <summary>
    /// Withdraw both types of tokens from the pool at the current ratio, given
    ///   pool tokens.  The pool tokens are burned in exchange for an equivalent
    ///   amount of token A and B.
    /// </summary>
    /// <param name="ATokenSwapAccount">The token swap account to operate over.</param>
    /// <param name="AUserTransferAuthority">user transfer authority.</param>
    /// <param name="APoolTokenMint">Pool MINT account, swap authority is the owner.</param>
    /// <param name="ASourcePoolAccount">SOURCE Pool account, amount is transferable by user transfer authority.</param>
    /// <param name="ATokenASwapAccount">token_a Swap Account to withdraw FROM.</param>
    /// <param name="ATokenBSwapAccount">token_b Swap Account to withdraw FROM.</param>
    /// <param name="ATokenAUserAccount">token_a user Account to credit.</param>
    /// <param name="ATokenBUserAccount">token_b user Account to credit.</param>
    /// <param name="AFeeAccount">Fee account, to receive withdrawal fees.</param>
    /// <param name="APoolTokenAmount">Amount of pool tokens to burn. User receives an output of token a and b based on the percentage of the pool tokens that are returned.</param>
    /// <param name="AMinTokenA">Minimum amount of token A to receive, prevents excessive slippage.</param>
    /// <param name="AMinTokenB">Minimum amount of token B to receive, prevents excessive slippage.</param>
    /// <returns>The transaction instruction.</returns>
    class function WithdrawAllTokenTypes(const ATokenSwapAccount,
                                         AUserTransferAuthority,
                                         APoolTokenMint,
                                         ASourcePoolAccount,
                                         ATokenASwapAccount,
                                         ATokenBSwapAccount,
                                         ATokenAUserAccount,
                                         ATokenBUserAccount,
                                         AFeeAccount: IPublicKey;
                                         const APoolTokenAmount, AMinTokenA, AMinTokenB: UInt64): ITransactionInstruction; static;

    /// <summary>
    /// Deposit one type of tokens into the pool.  The output is a "pool" token
    ///   representing ownership into the pool. Input token is converted as if
    ///   a swap and deposit all token types were performed.
    /// </summary>
    /// <param name="ATokenSwapAccount">The token swap account to operate over.</param>
    /// <param name="AUserTransferAuthority">user transfer authority.</param>
    /// <param name="ASourceAccount">token_(A|B) SOURCE Account, amount is transferable by user transfer authority.</param>
    /// <param name="ADestinationTokenAAccount">token_a Swap Account, may deposit INTO.</param>
    /// <param name="ADestinationTokenBAccount">token_b Swap Account, may deposit INTO.</param>
    /// <param name="APoolMintAccount">Pool MINT account, swap authority is the owner.</param>
    /// <param name="APoolTokenUserAccount">Pool Account to deposit the generated tokens, user is the owner.</param>
    /// <param name="ASourceTokenAmount">Token amount to deposit.</param>
    /// <param name="AMinPoolTokenAmount">Pool token amount to receive in exchange. The amount is set by the current exchange rate and size of the pool.</param>
    /// <returns>The transaction instruction.</returns>
    class function DepositSingleTokenTypeExactAmountIn(const ATokenSwapAccount,
                                                       AUserTransferAuthority,
                                                       ASourceAccount,
                                                       ADestinationTokenAAccount,
                                                       ADestinationTokenBAccount,
                                                       APoolMintAccount,
                                                       APoolTokenUserAccount: IPublicKey;
                                                       const ASourceTokenAmount, AMinPoolTokenAmount: UInt64): ITransactionInstruction; static;

    /// <summary>
    /// Withdraw one token type from the pool at the current ratio given the
    ///   exact amount out expected.
    /// </summary>
    /// <param name="ATokenSwapAccount">The token swap account to operate over.</param>
    /// <param name="AUserTransferAuthority">user transfer authority.</param>
    /// <param name="APoolMintAccount">Pool mint account, swap authority is the owner.</param>
    /// <param name="ASourceUserAccount">SOURCE Pool account, amount is transferable by user transfer authority.</param>
    /// <param name="ATokenASwapAccount">token_a Swap Account to potentially withdraw from.</param>
    /// <param name="ATokenBSwapAccount">token_b Swap Account to potentially withdraw from.</param>
    /// <param name="ATokenUserAccount">token_(A|B) User Account to credit.</param>
    /// <param name="AFeeAccount">Fee account, to receive withdrawal fees.</param>
    /// <param name="ADestTokenAmount">Amount of token A or B to receive.</param>
    /// <param name="AMaxPoolTokenAmount">Maximum amount of pool tokens to burn. User receives an output of token A or B based on the percentage of the pool tokens that are returned.</param>
    /// <returns>The transaction instruction.</returns>
    class function WithdrawSingleTokenTypeExactAmountOut(const ATokenSwapAccount,
                                                         AUserTransferAuthority,
                                                         APoolMintAccount,
                                                         ASourceUserAccount,
                                                         ATokenASwapAccount,
                                                         ATokenBSwapAccount,
                                                         ATokenUserAccount,
                                                         AFeeAccount: IPublicKey;
                                                         const ADestTokenAmount, AMaxPoolTokenAmount: UInt64): ITransactionInstruction; static;

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

{ TAuthorityPair }

constructor TAuthorityPair.Create(const APublicKey: IPublicKey; ANonce: Byte);
begin
  FPublicKey := APublicKey;
  FNonce := ANonce;
end;

{ TTokenSwapProgramInstructions }

class constructor TTokenSwapProgramInstructions.Create;
begin
  FNames := TDictionary<TValues, string>.Create;
  FNames.Add(TValues.Initialize, 'Initialize Swap');
  FNames.Add(TValues.Swap, 'Swap');
  FNames.Add(TValues.DepositAllTokenTypes, 'Deposit Both');
  FNames.Add(TValues.WithdrawAllTokenTypes, 'Withdraw Both');
  FNames.Add(TValues.DepositSingleTokenTypeExactAmountIn, 'Deposit Single');
  FNames.Add(TValues.WithdrawSingleTokenTypeExactAmountOut, 'Withdraw Single');
end;

class destructor TTokenSwapProgramInstructions.Destroy;
begin
  FNames.Free;
end;

{ TTokenSwapProgramData - Encoders }

class function TTokenSwapProgramData.EncodeInitializeData(
  const ANonce: Byte; const AFees: IFees; const ASwapCurve: ISwapCurve): TBytes;
var
  LFees: TBytes;
  LCurve: TBytes;
begin
  // 1 (op) + 1 (nonce) + 64 (fees) + 33 (curve) = 99
  LFees  := AFees.Serialize;
  LCurve := ASwapCurve.Serialize;

  SetLength(Result, 99);
  TSerialization.WriteU8(Result, Byte(TTokenSwapProgramInstructions.TValues.Initialize), MethodOffset);
  TSerialization.WriteU8(Result, ANonce, 1);
  TSerialization.WriteSpan(Result, LFees, 2);
  TSerialization.WriteSpan(Result, LCurve, 66);
end;

class function TTokenSwapProgramData.EncodeSwapData(
  const AAmountIn, AAmountOut: UInt64): TBytes;
begin
  // 1 (op) + 8 + 8 = 17
  SetLength(Result, 17);
  TSerialization.WriteU8(Result, Byte(TTokenSwapProgramInstructions.TValues.Swap), MethodOffset);
  TSerialization.WriteU64(Result, AAmountIn, 1);
  TSerialization.WriteU64(Result, AAmountOut, 9);
end;

class function TTokenSwapProgramData.EncodeDepositAllTokenTypesData(
  const APoolTokenAmount, AMaxTokenAAmount, AMaxTokenBAmount: UInt64): TBytes;
begin
  // 1 + 8 + 8 + 8 = 25
  SetLength(Result, 25);
  TSerialization.WriteU8(Result, Byte(TTokenSwapProgramInstructions.TValues.DepositAllTokenTypes), MethodOffset);
  TSerialization.WriteU64(Result, APoolTokenAmount, 1);
  TSerialization.WriteU64(Result, AMaxTokenAAmount, 9);
  TSerialization.WriteU64(Result, AMaxTokenBAmount, 17);
end;

class function TTokenSwapProgramData.EncodeWithdrawAllTokenTypesData(
  const APoolTokenAmount, AMinTokenAAmount, AMinTokenBAmount: UInt64): TBytes;
begin
  // 1 + 8 + 8 + 8 = 25
  SetLength(Result, 25);
  TSerialization.WriteU8(Result, Byte(TTokenSwapProgramInstructions.TValues.WithdrawAllTokenTypes), MethodOffset);
  TSerialization.WriteU64(Result, APoolTokenAmount, 1);
  TSerialization.WriteU64(Result, AMinTokenAAmount, 9);
  TSerialization.WriteU64(Result, AMinTokenBAmount, 17);
end;

class function TTokenSwapProgramData.EncodeDepositSingleTokenTypeExactAmountInData(
  const ASourceTokenAmount, AMinPoolTokenAmount: UInt64): TBytes;
begin
  // 1 + 8 + 8 = 17
  SetLength(Result, 17);
  TSerialization.WriteU8(Result, Byte(TTokenSwapProgramInstructions.TValues.DepositSingleTokenTypeExactAmountIn), MethodOffset);
  TSerialization.WriteU64(Result, ASourceTokenAmount, 1);
  TSerialization.WriteU64(Result, AMinPoolTokenAmount, 9);
end;

class function TTokenSwapProgramData.EncodeWithdrawSingleTokenTypeExactAmountOutData(
  const ADestTokenAmount, AMaxPoolTokenAmount: UInt64): TBytes;
begin
  // 1 + 8 + 8 = 17
  SetLength(Result, 17);
  TSerialization.WriteU8(Result, Byte(TTokenSwapProgramInstructions.TValues.WithdrawSingleTokenTypeExactAmountOut), MethodOffset);
  TSerialization.WriteU64(Result, ADestTokenAmount, 1);
  TSerialization.WriteU64(Result, AMaxPoolTokenAmount, 9);
end;

{ TTokenSwapProgramData - Decoders }

class procedure TTokenSwapProgramData.DecodeInitializeData(const ADecoded: IDecodedInstruction;
  const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Token Swap Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Swap Authority',     TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('Token A Account',    TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  ADecoded.Values.Add('Token B Account',    TValue.From<IPublicKey>(AKeys[AKeyIndices[3]]));
  ADecoded.Values.Add('Pool Token Mint',    TValue.From<IPublicKey>(AKeys[AKeyIndices[4]]));
  ADecoded.Values.Add('Pool Token Fee Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[5]]));
  ADecoded.Values.Add('Pool Token Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[6]]));
  ADecoded.Values.Add('Token Program ID',   TValue.From<IPublicKey>(AKeys[AKeyIndices[7]]));

  ADecoded.Values.Add('Nonce', TValue.From<Byte>(TDeserialization.GetU8(AData, 1)));
  ADecoded.Values.Add('Trade Fee Numerator',        TValue.From<UInt64>(TDeserialization.GetU64(AData, 2)));
  ADecoded.Values.Add('Trade Fee Denominator',      TValue.From<UInt64>(TDeserialization.GetU64(AData, 10)));
  ADecoded.Values.Add('Owner Trade Fee Numerator',  TValue.From<UInt64>(TDeserialization.GetU64(AData, 18)));
  ADecoded.Values.Add('Owner Trade Fee Denominator',TValue.From<UInt64>(TDeserialization.GetU64(AData, 26)));
  ADecoded.Values.Add('Owner Withraw Fee Numerator',TValue.From<UInt64>(TDeserialization.GetU64(AData, 34)));
  ADecoded.Values.Add('Owner Withraw Fee Denominator', TValue.From<UInt64>(TDeserialization.GetU64(AData, 42)));
  ADecoded.Values.Add('Host Fee Numerator',         TValue.From<UInt64>(TDeserialization.GetU64(AData, 50)));
  ADecoded.Values.Add('Host Fee Denominator',       TValue.From<UInt64>(TDeserialization.GetU64(AData, 58)));
  ADecoded.Values.Add('Curve Type',                 TValue.From<UInt64>(TDeserialization.GetU8(AData, 66))); // first byte of curve payload is type
end;

class procedure TTokenSwapProgramData.DecodeSwapData(const ADecoded: IDecodedInstruction;
  const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Token Swap Account',       TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Swap Authority',           TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('User Transfer Authority',  TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  ADecoded.Values.Add('User Source Account',      TValue.From<IPublicKey>(AKeys[AKeyIndices[3]]));
  ADecoded.Values.Add('Token Base Into Account',  TValue.From<IPublicKey>(AKeys[AKeyIndices[4]]));
  ADecoded.Values.Add('Token Base From Account',  TValue.From<IPublicKey>(AKeys[AKeyIndices[5]]));
  ADecoded.Values.Add('User Destination Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[6]]));
  ADecoded.Values.Add('Pool Token Mint',          TValue.From<IPublicKey>(AKeys[AKeyIndices[7]]));
  ADecoded.Values.Add('Fee Account',              TValue.From<IPublicKey>(AKeys[AKeyIndices[8]]));
  ADecoded.Values.Add('Token Program ID',         TValue.From<IPublicKey>(AKeys[AKeyIndices[9]]));

  if Length(AKeyIndices) >= 11 then
    ADecoded.Values.Add('Host Fee Account',       TValue.From<IPublicKey>(AKeys[AKeyIndices[10]]));

  ADecoded.Values.Add('Amount In',  TValue.From<UInt64>(TDeserialization.GetU64(AData, 1)));
  ADecoded.Values.Add('Amount Out', TValue.From<UInt64>(TDeserialization.GetU64(AData, 9)));
end;

class procedure TTokenSwapProgramData.DecodeDepositAllTokenTypesData(const ADecoded: IDecodedInstruction;
  const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Token Swap Account',    TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Swap Authority',        TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('User Transfer Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  ADecoded.Values.Add('User Token A Account',  TValue.From<IPublicKey>(AKeys[AKeyIndices[3]]));
  ADecoded.Values.Add('User Token B Account',  TValue.From<IPublicKey>(AKeys[AKeyIndices[4]]));
  ADecoded.Values.Add('Pool Token A Account',  TValue.From<IPublicKey>(AKeys[AKeyIndices[5]]));
  ADecoded.Values.Add('Pool Token B Account',  TValue.From<IPublicKey>(AKeys[AKeyIndices[6]]));
  ADecoded.Values.Add('Pool Token Mint',       TValue.From<IPublicKey>(AKeys[AKeyIndices[7]]));
  ADecoded.Values.Add('User Pool Token Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[8]]));
  ADecoded.Values.Add('Token Program ID',      TValue.From<IPublicKey>(AKeys[AKeyIndices[9]]));

  ADecoded.Values.Add('Pool Tokens', TValue.From<UInt64>(TDeserialization.GetU64(AData, 1)));
  ADecoded.Values.Add('Max Token A', TValue.From<UInt64>(TDeserialization.GetU64(AData, 9)));
  ADecoded.Values.Add('Max Token B', TValue.From<UInt64>(TDeserialization.GetU64(AData, 17)));
end;

class procedure TTokenSwapProgramData.DecodeWithdrawAllTokenTypesData(const ADecoded: IDecodedInstruction;
  const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Token Swap Account',    TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Swap Authority',        TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('User Transfer Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  ADecoded.Values.Add('Pool Token Account',       TValue.From<IPublicKey>(AKeys[AKeyIndices[3]]));
  ADecoded.Values.Add('User Pool Token Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[4]]));
  ADecoded.Values.Add('Pool Token A Account',  TValue.From<IPublicKey>(AKeys[AKeyIndices[5]]));
  ADecoded.Values.Add('Pool Token B Account',  TValue.From<IPublicKey>(AKeys[AKeyIndices[6]]));
  ADecoded.Values.Add('User Token A Account',  TValue.From<IPublicKey>(AKeys[AKeyIndices[7]]));
  ADecoded.Values.Add('User Token B Account',  TValue.From<IPublicKey>(AKeys[AKeyIndices[8]]));
  ADecoded.Values.Add('Fee Account',           TValue.From<IPublicKey>(AKeys[AKeyIndices[9]]));
  ADecoded.Values.Add('Token Program ID',      TValue.From<IPublicKey>(AKeys[AKeyIndices[10]]));

  ADecoded.Values.Add('Pool Tokens', TValue.From<UInt64>(TDeserialization.GetU64(AData, 1)));
  ADecoded.Values.Add('Min Token A', TValue.From<UInt64>(TDeserialization.GetU64(AData, 9)));
  ADecoded.Values.Add('Min Token B', TValue.From<UInt64>(TDeserialization.GetU64(AData, 17)));
end;

class procedure TTokenSwapProgramData.DecodeDepositSingleTokenTypeExactAmountInData(
  const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Token Swap Account',        TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Swap Authority',            TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('User Transfer Authority',   TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  ADecoded.Values.Add('User Source Token Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[3]]));
  ADecoded.Values.Add('Token A Swap Account',      TValue.From<IPublicKey>(AKeys[AKeyIndices[4]]));
  ADecoded.Values.Add('Token B Swap Account',      TValue.From<IPublicKey>(AKeys[AKeyIndices[5]]));
  ADecoded.Values.Add('Pool Mint Account',         TValue.From<IPublicKey>(AKeys[AKeyIndices[6]]));
  ADecoded.Values.Add('User Pool Token Account',   TValue.From<IPublicKey>(AKeys[AKeyIndices[7]]));
  ADecoded.Values.Add('Token Program ID',          TValue.From<IPublicKey>(AKeys[AKeyIndices[8]]));

  ADecoded.Values.Add('Source Token Amount',   TValue.From<UInt64>(TDeserialization.GetU64(AData, 1)));
  ADecoded.Values.Add('Min Pool Token Amount', TValue.From<UInt64>(TDeserialization.GetU64(AData, 9)));
end;

class procedure TTokenSwapProgramData.DecodeWithdrawSingleTokenTypeExactAmountOutData(
  const ADecoded: IDecodedInstruction; const AData: TBytes;
  const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecoded.Values.Add('Token Swap Account',      TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecoded.Values.Add('Swap Authority',          TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecoded.Values.Add('User Transfer Authority', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  ADecoded.Values.Add('Pool Mint Account',       TValue.From<IPublicKey>(AKeys[AKeyIndices[3]]));
  ADecoded.Values.Add('User Pool Token Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[4]]));
  ADecoded.Values.Add('Token A Swap Account',    TValue.From<IPublicKey>(AKeys[AKeyIndices[5]]));
  ADecoded.Values.Add('Token B Swap Account',    TValue.From<IPublicKey>(AKeys[AKeyIndices[6]]));
  ADecoded.Values.Add('User Token Account',      TValue.From<IPublicKey>(AKeys[AKeyIndices[7]]));
  ADecoded.Values.Add('Fee Account',             TValue.From<IPublicKey>(AKeys[AKeyIndices[8]]));
  ADecoded.Values.Add('Token Program ID',        TValue.From<IPublicKey>(AKeys[AKeyIndices[9]]));

  ADecoded.Values.Add('Destination Token Amount', TValue.From<UInt64>(TDeserialization.GetU64(AData, 1)));
  ADecoded.Values.Add('Max Pool Token Amount',    TValue.From<UInt64>(TDeserialization.GetU64(AData, 9)));
end;

{ TTokenSwapProgram }

class constructor TTokenSwapProgram.Create;
begin
  FProgramIdKey := TPublicKey.Create('SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8');
  FOwnerKey     := TPublicKey.Create('HfoTxFR1Tm6kGmWgYWD6J7YHVy1UwqSULUGVLXkJqaKN');
end;

class destructor TTokenSwapProgram.Destroy;
begin
  FProgramIdKey := nil;
  FOwnerKey := nil;
end;

class function TTokenSwapProgram.GetOwnerKey: IPublicKey;
begin
  Result := FOwnerKey;
end;

class function TTokenSwapProgram.GetProgramIdKey: IPublicKey;
begin
  Result := FProgramIdKey;
end;

class function TTokenSwapProgram.CreateAuthority(
  const ATokenSwapAccount: IPublicKey): TAuthorityPair;
var
  LAuth: IPublicKey;
  LNonce: Byte;
  LOk: Boolean;
begin
  // PDA: seeds = [ tokenSwapAccount.KeyBytes ]
  LOk := TPublicKey.TryFindProgramAddress(
    TArray<TBytes>.Create(ATokenSwapAccount.KeyBytes),
    ProgramIdKey,
    LAuth,
    LNonce);
  if not LOk then
    raise EInvalidProgramException.Create('No valid program address found for TokenSwap authority.');
  Result := TAuthorityPair.Create(LAuth, LNonce);
end;

class function TTokenSwapProgram.Initialize(
  const ATokenSwapAccount, ATokenAAccount, ATokenBAccount, APoolTokenMint,
        APoolTokenFeeAccount, AUserPoolTokenAccount: IPublicKey;
  const AFees: IFees; const ASwapCurve: ISwapCurve): ITransactionInstruction;
var
  LAuth: TAuthorityPair;
  LKeys: TList<IAccountMeta>;
begin
  LAuth := CreateAuthority(ATokenSwapAccount);

  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ATokenSwapAccount, True));
  LKeys.Add(TAccountMeta.ReadOnly(LAuth.PublicKey, False));
  LKeys.Add(TAccountMeta.ReadOnly(ATokenAAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(ATokenBAccount, False));
  LKeys.Add(TAccountMeta.Writable(APoolTokenMint, False));
  LKeys.Add(TAccountMeta.ReadOnly(APoolTokenFeeAccount, False));
  LKeys.Add(TAccountMeta.Writable(AUserPoolTokenAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(TTokenProgram.ProgramIdKey, False));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    LKeys,
    TTokenSwapProgramData.EncodeInitializeData(LAuth.Nonce, AFees, ASwapCurve)
  );
end;

class function TTokenSwapProgram.Swap(
  const ATokenSwapAccount, AUserTransferAuthority, ATokenSourceAccount,
        ATokenBaseIntoAccount, ATokenBaseFromAccount, ATokenDestinationAccount,
        APoolTokenMint, APoolTokenFeeAccount, APoolTokenHostFeeAccount: IPublicKey;
  const AAmountIn, AAmountOut: UInt64): ITransactionInstruction;
var
  LAuth: TAuthorityPair;
  LKeys: TList<IAccountMeta>;
begin
  LAuth := CreateAuthority(ATokenSwapAccount);

  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.ReadOnly(ATokenSwapAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(LAuth.PublicKey, False));
  LKeys.Add(TAccountMeta.ReadOnly(AUserTransferAuthority, False));
  LKeys.Add(TAccountMeta.Writable(ATokenSourceAccount, False));
  LKeys.Add(TAccountMeta.Writable(ATokenBaseIntoAccount, False));
  LKeys.Add(TAccountMeta.Writable(ATokenBaseFromAccount, False));
  LKeys.Add(TAccountMeta.Writable(ATokenDestinationAccount, False));
  LKeys.Add(TAccountMeta.Writable(APoolTokenMint, False));
  LKeys.Add(TAccountMeta.Writable(APoolTokenFeeAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(TTokenProgram.ProgramIdKey, False));

  if Assigned(APoolTokenHostFeeAccount) then
    LKeys.Add(TAccountMeta.Writable(APoolTokenHostFeeAccount, False));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    LKeys,
    TTokenSwapProgramData.EncodeSwapData(AAmountIn, AAmountOut)
  );
end;

class function TTokenSwapProgram.DepositAllTokenTypes(
  const ATokenSwapAccount, AUserTransferAuthority, ATokenAUserAccount,
        ATokenBUserAccount, ATokenADepositAccount, ATokenBDepositAccount,
        APoolTokenMint, APoolTokenUserAccount: IPublicKey;
  const APoolTokenAmount, AMaxTokenA, AMaxTokenB: UInt64): ITransactionInstruction;
var
  LAuth: TAuthorityPair;
  LKeys: TList<IAccountMeta>;
begin
  LAuth := CreateAuthority(ATokenSwapAccount);

  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.ReadOnly(ATokenSwapAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(LAuth.PublicKey, False));
  LKeys.Add(TAccountMeta.ReadOnly(AUserTransferAuthority, False));
  LKeys.Add(TAccountMeta.Writable(ATokenAUserAccount, False));
  LKeys.Add(TAccountMeta.Writable(ATokenBUserAccount, False));
  LKeys.Add(TAccountMeta.Writable(ATokenADepositAccount, False));
  LKeys.Add(TAccountMeta.Writable(ATokenBDepositAccount, False));
  LKeys.Add(TAccountMeta.Writable(APoolTokenMint, False));
  LKeys.Add(TAccountMeta.Writable(APoolTokenUserAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(TTokenProgram.ProgramIdKey, False));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    LKeys,
    TTokenSwapProgramData.EncodeDepositAllTokenTypesData(APoolTokenAmount, AMaxTokenA, AMaxTokenB)
  );
end;

class function TTokenSwapProgram.WithdrawAllTokenTypes(
  const ATokenSwapAccount, AUserTransferAuthority, APoolTokenMint, ASourcePoolAccount,
        ATokenASwapAccount, ATokenBSwapAccount, ATokenAUserAccount, ATokenBUserAccount,
        AFeeAccount: IPublicKey; const APoolTokenAmount, AMinTokenA, AMinTokenB: UInt64): ITransactionInstruction;
var
  LAuth: TAuthorityPair;
  LKeys: TList<IAccountMeta>;
begin
  LAuth := CreateAuthority(ATokenSwapAccount);

  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.ReadOnly(ATokenSwapAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(LAuth.PublicKey, False));
  LKeys.Add(TAccountMeta.ReadOnly(AUserTransferAuthority, False));
  LKeys.Add(TAccountMeta.Writable(APoolTokenMint, False));
  LKeys.Add(TAccountMeta.Writable(ASourcePoolAccount, False));
  LKeys.Add(TAccountMeta.Writable(ATokenASwapAccount, False));
  LKeys.Add(TAccountMeta.Writable(ATokenBSwapAccount, False));
  LKeys.Add(TAccountMeta.Writable(ATokenAUserAccount, False));
  LKeys.Add(TAccountMeta.Writable(ATokenBUserAccount, False));
  LKeys.Add(TAccountMeta.Writable(AFeeAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(TTokenProgram.ProgramIdKey, False));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    LKeys,
    TTokenSwapProgramData.EncodeWithdrawAllTokenTypesData(APoolTokenAmount, AMinTokenA, AMinTokenB)
  );
end;

class function TTokenSwapProgram.DepositSingleTokenTypeExactAmountIn(
  const ATokenSwapAccount, AUserTransferAuthority, ASourceAccount,
        ADestinationTokenAAccount, ADestinationTokenBAccount,
        APoolMintAccount, APoolTokenUserAccount: IPublicKey;
  const ASourceTokenAmount, AMinPoolTokenAmount: UInt64): ITransactionInstruction;
var
  LAuth: TAuthorityPair;
  LKeys: TList<IAccountMeta>;
begin
  LAuth := CreateAuthority(ATokenSwapAccount);

  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.ReadOnly(ATokenSwapAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(LAuth.PublicKey, False));
  LKeys.Add(TAccountMeta.ReadOnly(AUserTransferAuthority, False));
  LKeys.Add(TAccountMeta.Writable(ASourceAccount, False));
  LKeys.Add(TAccountMeta.Writable(ADestinationTokenAAccount, False));
  LKeys.Add(TAccountMeta.Writable(ADestinationTokenBAccount, False));
  LKeys.Add(TAccountMeta.Writable(APoolMintAccount, False));
  LKeys.Add(TAccountMeta.Writable(APoolTokenUserAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(TTokenProgram.ProgramIdKey, False));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    LKeys,
    TTokenSwapProgramData.EncodeDepositSingleTokenTypeExactAmountInData(ASourceTokenAmount, AMinPoolTokenAmount)
  );
end;

class function TTokenSwapProgram.WithdrawSingleTokenTypeExactAmountOut(
  const ATokenSwapAccount, AUserTransferAuthority, APoolMintAccount, ASourceUserAccount,
        ATokenASwapAccount, ATokenBSwapAccount, ATokenUserAccount, AFeeAccount: IPublicKey;
  const ADestTokenAmount, AMaxPoolTokenAmount: UInt64): ITransactionInstruction;
var
  LAuth: TAuthorityPair;
  LKeys: TList<IAccountMeta>;
begin
  LAuth := CreateAuthority(ATokenSwapAccount);

  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.ReadOnly(ATokenSwapAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(LAuth.PublicKey, False));
  LKeys.Add(TAccountMeta.ReadOnly(AUserTransferAuthority, False));
  LKeys.Add(TAccountMeta.Writable(APoolMintAccount, False));
  LKeys.Add(TAccountMeta.Writable(ASourceUserAccount, False));
  LKeys.Add(TAccountMeta.Writable(ATokenASwapAccount, False));
  LKeys.Add(TAccountMeta.Writable(ATokenBSwapAccount, False));
  LKeys.Add(TAccountMeta.Writable(ATokenUserAccount, False));
  LKeys.Add(TAccountMeta.Writable(AFeeAccount, False));
  LKeys.Add(TAccountMeta.ReadOnly(TTokenProgram.ProgramIdKey, False));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    LKeys,
    TTokenSwapProgramData.EncodeWithdrawSingleTokenTypeExactAmountOutData(ADestTokenAmount, AMaxPoolTokenAmount)
  );
end;

class function TTokenSwapProgram.Decode(
  const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction;
var
  LInstr: Byte;
  LVal: TTokenSwapProgramInstructions.TValues;
begin
  LInstr := TDeserialization.GetU8(AData, TTokenSwapProgramData.MethodOffset);

  if GetEnumName(TypeInfo(TTokenSwapProgramInstructions.TValues), LInstr) = '' then
  begin
    Result := TDecodedInstruction.Create;
    Result.PublicKey        := ProgramIdKey;
    Result.InstructionName  := 'Unknown Instruction';
    Result.ProgramName      := ProgramName;
    Result.Values             := TDictionary<string, TValue>.Create;
    Result.InnerInstructions  := TList<IDecodedInstruction>.Create;
    Exit;
  end;

  LVal := TTokenSwapProgramInstructions.TValues(LInstr);

  Result := TDecodedInstruction.Create;
  Result.PublicKey        := ProgramIdKey;
  Result.InstructionName  := TTokenSwapProgramInstructions.Names[LVal];
  Result.ProgramName      := ProgramName;
  Result.Values             := TDictionary<string, TValue>.Create;
  Result.InnerInstructions  := TList<IDecodedInstruction>.Create;

  case LVal of
    TTokenSwapProgramInstructions.TValues.Initialize:
      TTokenSwapProgramData.DecodeInitializeData(Result, AData, AKeys, AKeyIndices);
    TTokenSwapProgramInstructions.TValues.Swap:
      TTokenSwapProgramData.DecodeSwapData(Result, AData, AKeys, AKeyIndices);
    TTokenSwapProgramInstructions.TValues.DepositAllTokenTypes:
      TTokenSwapProgramData.DecodeDepositAllTokenTypesData(Result, AData, AKeys, AKeyIndices);
    TTokenSwapProgramInstructions.TValues.WithdrawAllTokenTypes:
      TTokenSwapProgramData.DecodeWithdrawAllTokenTypesData(Result, AData, AKeys, AKeyIndices);
    TTokenSwapProgramInstructions.TValues.DepositSingleTokenTypeExactAmountIn:
      TTokenSwapProgramData.DecodeDepositSingleTokenTypeExactAmountInData(Result, AData, AKeys, AKeyIndices);
    TTokenSwapProgramInstructions.TValues.WithdrawSingleTokenTypeExactAmountOut:
      TTokenSwapProgramData.DecodeWithdrawSingleTokenTypeExactAmountOutData(Result, AData, AKeys, AKeyIndices);
  end;
end;

end.

