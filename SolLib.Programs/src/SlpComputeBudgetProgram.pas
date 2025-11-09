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

unit SlpComputeBudgetProgram;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
  System.TypInfo,
  SlpPublicKey,
  SlpSerialization,
  SlpDeserialization,
  SlpAccountDomain,
  SlpTransactionInstruction,
  SlpDecodedInstruction;

type
  /// <summary>
  /// Represents the instruction types for the <see cref="ComputeBudgetProgram"/> along with a friendly name so as not to use reflection.
  /// </summary>
  TComputeBudgetProgramInstructions = class sealed
  public
    type
      /// <summary>
      /// Represents the instruction types for the <see cref="ComputeBudgetProgram"/>.
      /// </summary>
      TValues = (
        /// <summary>
        /// Unused.
        /// Deprecated variant, reserved value.
        /// </summary>
        Unused = 0,

        /// <summary>
        /// Request a heap frame.
        /// </summary>
        RequestHeapFrame = 1,

        /// <summary>
        /// Set compute unit limit.
        /// </summary>
        SetComputeUnitLimit = 2,

        /// <summary>
        /// Set compute unit price.
        /// </summary>
        SetComputeUnitPrice = 3,

        /// <summary>
        /// Set loaded accounts data size limit.
        /// </summary>
        SetLoadedAccountsDataSizeLimit = 4
      );
  private
    class var FNames: TDictionary<TValues, string>;
  public
    /// <summary>Represents the user-friendly names for the instruction types.</summary>
    class property Names: TDictionary<TValues, string> read FNames;

    class constructor Create;
    class destructor Destroy;
  end;

  /// <summary>
  /// Implements the ComputeBudget Program data encodings.
  /// <remarks>
  /// For more information see: https://spl.solana.com/memo
  /// </remarks>
  /// </summary>
  TComputeBudgetProgramData = class sealed
  private
    /// <summary>
    /// The offset at which the value which defines the program method begins.
    /// </summary>
    const MethodOffset = 0;
  public
    /// <summary>
    /// Encode transaction instruction data for the <see cref="ComputeBudgetProgramInstructions.TValues.RequestHeapFrame"/> method.
    /// </summary>
    /// <param name="ABytes">The heap region size.</param>
    /// <returns>The transaction instruction data.</returns>
    class function EncodeRequestHeapFrameData(const ABytes: UInt32): TBytes; static;

    /// <summary>
    /// Encode transaction instruction data for the <see cref="ComputeBudgetProgramInstructions.TValues.SetComputeUnitLimit"/> method.
    /// </summary>
    /// <param name="AUnits">The compute unit limit.</param>
    /// <returns>The transaction instruction data.</returns>
    class function EncodeSetComputeUnitLimitData(const AUnits: UInt32): TBytes; static;

    /// <summary>
    /// Encode transaction instruction data for the <see cref="ComputeBudgetProgramInstructions.TValues.SetComputeUnitPrice"/> method.
    /// </summary>
    /// <param name="AMicroLamports">The compute unit price.</param>
    /// <returns>The transaction instruction data.</returns>
    class function EncodeSetComputeUnitPriceData(const AMicroLamports: UInt64): TBytes; static;

    /// <summary>
    /// Encode transaction instruction data for the <see cref="ComputeBudgetProgramInstructions.TValues.SetLoadedAccountsDataSizeLimit"/> method.
    /// </summary>
    /// <param name="ABytes">The account data size limit.</param>
    /// <returns>The transaction instruction data.</returns>
    class function EncodeSetLoadedAccountsDataSizeLimit(const ABytes: UInt32): TBytes; static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="ComputeBudgetProgramInstructions.TValues.RequestHeapFrame"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    class procedure DecodeRequestHeapFrameData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="ComputeBudgetProgramInstructions.TValues.SetComputeUnitLimit"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    class procedure DecodeSetComputeUnitLimitData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="ComputeBudgetProgramInstructions.TValues.SetComputeUnitPrice"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    class procedure DecodeSetComputeUnitPriceData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data for the <see cref="ComputeBudgetProgramInstructions.TValues.SetLoadedAccountsDataSizeLimit"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    class procedure DecodeSetLoadedAccountsDataSizeLimitData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes); static;
  end;

  /// <summary>
  /// Implements the Compute Budget Program methods.
  /// <remarks>
  /// For more information see:
  /// https://docs.rs/solana-sdk/1.18.7/solana_sdk/compute_budget/enum.ComputeBudgetInstruction.html
  /// </remarks>
  /// </summary>
  TComputeBudgetProgram = class sealed
  private
    const ProgramName = 'Compute Budget Program';
    class var FProgramIdKey: IPublicKey;

    class function GetProgramIdKey: IPublicKey; static;
  public
    /// <summary>The public key of the ComputeBudget Program.</summary>
    class property ProgramIdKey: IPublicKey read GetProgramIdKey;

    class constructor Create;
    class destructor Destroy;

    /// <summary>
    /// Request a specific transaction-wide program heap region size in bytes. The value requested must be a multiple of 1024.
    /// This new heap region size applies to each program executed in the transaction, including all calls to CPIs.
    /// </summary>
    /// <param name="ABytes">The heap region size.</param>
    /// <returns>The transaction instruction.</returns>
    class function RequestHeapFrame(const ABytes: UInt32): ITransactionInstruction; static;

    /// <summary>
    /// Set a specific compute unit limit that the transaction is allowed to consume.
    /// </summary>
    /// <param name="AUnits">The compute unit limit.</param>
    /// <returns>The transaction instruction.</returns>
    class function SetComputeUnitLimit(const AUnits: UInt64): ITransactionInstruction; static;

    /// <summary>
    /// Set a compute unit price in �micro-lamports� to pay a higher transaction fee for higher transaction prioritization.
    /// </summary>
    /// <param name="AMicroLamports">The compute unit price.</param>
    /// <returns>The transaction instruction.</returns>
    class function SetComputeUnitPrice(const AMicroLamports: UInt64): ITransactionInstruction; static;

    /// <summary>
    /// Set a specific transaction-wide account data size limit, in bytes, that is allowed to load.
    /// </summary>
    /// <param name="ABytes">The account data size limit.</param>
    /// <returns>The transaction instruction.</returns>
    class function SetLoadedAccountsDataSizeLimit(const ABytes: UInt32): ITransactionInstruction; static;

    /// <summary>
    /// Decodes an instruction created by the Compute Budget Program.
    /// </summary>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys (if any) referenced by the instruction.</param>
    /// <param name="AKeyIndices">The key indices byte array (if any).</param>
    /// <returns>A decoded instruction.</returns>
    class function Decode(const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction; static;
  end;

implementation

{ TComputeBudgetProgramInstructions }

class constructor TComputeBudgetProgramInstructions.Create;
begin
  FNames := TDictionary<TValues, string>.Create;
  FNames.Add(TValues.RequestHeapFrame, 'Request Heap Frame');
  FNames.Add(TValues.SetComputeUnitLimit, 'Set Compute Unit Limit');
  FNames.Add(TValues.SetComputeUnitPrice, 'Set Compute Unit Price');
  FNames.Add(TValues.SetLoadedAccountsDataSizeLimit, 'Set Loaded Accounts Data Size Limit');
end;

class destructor TComputeBudgetProgramInstructions.Destroy;
begin
  FNames.Free;
end;

{ TComputeBudgetProgramData }

class function TComputeBudgetProgramData.EncodeRequestHeapFrameData(
  const ABytes: UInt32): TBytes;
begin
  SetLength(Result, 5);
  TSerialization.WriteU8(Result, Byte(TComputeBudgetProgramInstructions.TValues.RequestHeapFrame), MethodOffset);
  TSerialization.WriteU32(Result, ABytes, 1);
end;

class function TComputeBudgetProgramData.EncodeSetComputeUnitLimitData(
  const AUnits: UInt32): TBytes;
begin
  SetLength(Result, 5);
  TSerialization.WriteU8(Result, Byte(TComputeBudgetProgramInstructions.TValues.SetComputeUnitLimit), MethodOffset);
  TSerialization.WriteU32(Result, AUnits, 1);
end;

class function TComputeBudgetProgramData.EncodeSetComputeUnitPriceData(
  const AMicroLamports: UInt64): TBytes;
begin
  SetLength(Result, 9);
  TSerialization.WriteU8(Result, Byte(TComputeBudgetProgramInstructions.TValues.SetComputeUnitPrice), MethodOffset);
  TSerialization.WriteU64(Result, AMicroLamports, 1);
end;

class function TComputeBudgetProgramData.EncodeSetLoadedAccountsDataSizeLimit(
  const ABytes: UInt32): TBytes;
begin
  SetLength(Result, 5);
  TSerialization.WriteU8(Result, Byte(TComputeBudgetProgramInstructions.TValues.SetLoadedAccountsDataSizeLimit), MethodOffset);
  TSerialization.WriteU32(Result, ABytes, 1);
end;

class procedure TComputeBudgetProgramData.DecodeRequestHeapFrameData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes);
var
  LValue: UInt32;
begin
  LValue := TDeserialization.GetU32(AData, 1);
  ADecodedInstruction.Values.Add('Bytes', LValue);
end;

class procedure TComputeBudgetProgramData.DecodeSetComputeUnitLimitData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes);
var
  LUnits: UInt32;
begin
  LUnits := TDeserialization.GetU32(AData, 1);
  ADecodedInstruction.Values.Add('Units', LUnits);
end;

class procedure TComputeBudgetProgramData.DecodeSetComputeUnitPriceData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes);
var
  LPrice: UInt64;
begin
  LPrice := TDeserialization.GetU64(AData, 1);
  ADecodedInstruction.Values.Add('Micro Lamports', LPrice);
end;

class procedure TComputeBudgetProgramData.DecodeSetLoadedAccountsDataSizeLimitData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes);
var
  LBytes: UInt32;
begin
  LBytes := TDeserialization.GetU32(AData, 1);
  ADecodedInstruction.Values.Add('Bytes', LBytes);
end;

{ TComputeBudgetProgram }

class constructor TComputeBudgetProgram.Create;
begin
  FProgramIdKey := TPublicKey.Create('ComputeBudget111111111111111111111111111111');
end;

class destructor TComputeBudgetProgram.Destroy;
begin
  FProgramIdKey := nil;
end;

class function TComputeBudgetProgram.GetProgramIdKey: IPublicKey;
begin
  Result := FProgramIdKey;
end;

class function TComputeBudgetProgram.RequestHeapFrame(
  const ABytes: UInt32): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    Keys,
    TComputeBudgetProgramData.EncodeRequestHeapFrameData(ABytes)
  );
end;

class function TComputeBudgetProgram.SetComputeUnitLimit(
  const AUnits: UInt64): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    Keys,
    TComputeBudgetProgramData.EncodeSetComputeUnitLimitData(AUnits)
  );
end;

class function TComputeBudgetProgram.SetComputeUnitPrice(
  const AMicroLamports: UInt64): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    Keys,
    TComputeBudgetProgramData.EncodeSetComputeUnitPriceData(AMicroLamports)
  );
end;

class function TComputeBudgetProgram.SetLoadedAccountsDataSizeLimit(
  const ABytes: UInt32): ITransactionInstruction;
var
  Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    Keys,
    TComputeBudgetProgramData.EncodeSetLoadedAccountsDataSizeLimit(ABytes)
  );
end;

class function TComputeBudgetProgram.Decode(
  const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction;
var
  Instruction: Byte;
  InstructionValue: TComputeBudgetProgramInstructions.TValues;
begin
  Instruction := TDeserialization.GetU8(AData, TComputeBudgetProgramData.MethodOffset);

  if GetEnumName(TypeInfo(TComputeBudgetProgramInstructions.TValues), Instruction) = '' then
  begin
    Result := TDecodedInstruction.Create;
    Result.PublicKey         := ProgramIdKey;
    Result.InstructionName   := 'Unknown Instruction';
    Result.ProgramName       := ProgramName;
    Result.Values            := TDictionary<string, TValue>.Create;
    Result.InnerInstructions := TList<IDecodedInstruction>.Create;
    Exit;
  end;

  InstructionValue := TComputeBudgetProgramInstructions.TValues(Instruction);

  Result := TDecodedInstruction.Create;
  Result.PublicKey       := ProgramIdKey;
  Result.InstructionName := TComputeBudgetProgramInstructions.Names[InstructionValue];
  Result.ProgramName     := ProgramName;
  Result.Values          := TDictionary<string, TValue>.Create;
  Result.InnerInstructions := TList<IDecodedInstruction>.Create();

  case InstructionValue of
    TComputeBudgetProgramInstructions.TValues.RequestHeapFrame:
      TComputeBudgetProgramData.DecodeRequestHeapFrameData(Result, AData);
    TComputeBudgetProgramInstructions.TValues.SetComputeUnitLimit:
      TComputeBudgetProgramData.DecodeSetComputeUnitLimitData(Result, AData);
    TComputeBudgetProgramInstructions.TValues.SetComputeUnitPrice:
      TComputeBudgetProgramData.DecodeSetComputeUnitPriceData(Result, AData);
    TComputeBudgetProgramInstructions.TValues.SetLoadedAccountsDataSizeLimit:
      TComputeBudgetProgramData.DecodeSetLoadedAccountsDataSizeLimitData(Result, AData);
  end;
end;

end.

