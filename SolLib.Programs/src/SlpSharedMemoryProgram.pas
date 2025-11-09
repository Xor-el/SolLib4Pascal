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

unit SlpSharedMemoryProgram;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  SlpPublicKey,
  SlpSerialization,
  SlpDeserialization,
  SlpAccountDomain,
  SlpTransactionInstruction,
  SlpDecodedInstruction;

type
  /// <summary>
  /// Implements the Shared Memory Program data encodings.
  /// <remarks>
  /// This program writes arbitrary bytes into the data of a target account at a given offset.
  /// Note: this program may be inactive on some clusters.
  /// </remarks>
  /// </summary>
  TSharedMemoryProgramData = class sealed
  private
    /// <summary>The offset at which the 64-bit write offset is encoded.</summary>
    const OffsetFieldPos = 0;
    /// <summary>The byte index at which the payload begins.</summary>
    const PayloadPos = 8;
  public
    /// <summary>
    /// Encode instruction data for a Shared Memory write.
    /// Layout: [u64 offset][payload bytes...]
    /// </summary>
    /// <param name="APayload">The bytes to write.</param>
    /// <param name="AOffset">The destination account data offset.</param>
    /// <returns>Instruction data buffer.</returns>
    class function EncodeWriteData(const APayload: TBytes; const AOffset: UInt64): TBytes; static;

    /// <summary>
    /// Decodes the instruction data for the Shared Memory "Write" method.
    /// Adds:
    ///   'Offset' : UInt64
    ///   'Data'   : TBytes
    /// </summary>
    class procedure DecodeWriteData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes); static;
  end;

  /// <summary>
  /// Implements the Shared Memory Program methods.
  /// </summary>
  TSharedMemoryProgram = class sealed
  private
    const ProgramName = 'Shared Memory Program';
    const InstructionName = 'Write';
    class var FProgramIdKey: IPublicKey;

    class function GetProgramIdKey: IPublicKey; static;
  public
    /// <summary>The address of the Shared Memory Program.</summary>
    class property ProgramIdKey: IPublicKey read GetProgramIdKey;

    class constructor Create;
    class destructor Destroy;

    /// <summary>
    /// Creates an instruction that writes <paramref name="APayload"/> to <paramref name="ADest"/>
    /// starting at byte offset <paramref name="AOffset"/>.
    /// </summary>
    /// <param name="ADest">The public key of the account to write into.</param>
    /// <param name="APayload">The data to be written.</param>
    /// <param name="AOffset">The destination byte offset within the account data.</param>
    /// <returns>The transaction instruction.</returns>
    class function Write(const ADest: IPublicKey; const APayload: TBytes; const AOffset: UInt64): ITransactionInstruction; static;

    /// <summary>
    /// Decodes an instruction created for the Shared Memory Program.
    /// Values:
    ///  - 'Offset': UInt64
    ///  - 'Data'  : TBytes
    /// </summary>
    /// <param name="AData">The raw instruction data.</param>
    /// <param name="AKeys">The account keys (if any) referenced by the instruction.</param>
    /// <param name="AKeyIndices">The key index mapping (if any).</param>
    /// <returns>A decoded instruction object.</returns>
    class function Decode(const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction; static;
  end;

implementation

{ TSharedMemoryProgramData }

class function TSharedMemoryProgramData.EncodeWriteData(
  const APayload: TBytes; const AOffset: UInt64): TBytes;
var
  LLen: Integer;
begin
  LLen := PayloadPos + Length(APayload);
  SetLength(Result, LLen);

  // Write u64 offset at position 0
  TSerialization.WriteU64(Result, AOffset, OffsetFieldPos);

  // Write payload bytes at position 8
  TSerialization.WriteSpan(Result, APayload, PayloadPos);
end;

class procedure TSharedMemoryProgramData.DecodeWriteData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes);
var
  LOffset: UInt64;
  LPayload: TBytes;
  LPayloadLen: Integer;
begin
  if Length(AData) < PayloadPos then
    raise Exception.Create('SharedMemory decode error: data too short');

  LOffset := TDeserialization.GetU64(AData, OffsetFieldPos);

  LPayloadLen := Length(AData) - PayloadPos;

  LPayload := TDeserialization.GetBytes(AData, PayloadPos, LPayloadLen);

  ADecodedInstruction.Values.Add('Offset', LOffset);
  ADecodedInstruction.Values.Add('Data', TValue.From<TBytes>(LPayload));
end;

{ TSharedMemoryProgram }

class constructor TSharedMemoryProgram.Create;
begin
  FProgramIdKey := TPublicKey.Create('shmem4EWT2sPdVGvTZCzXXRAURL9G5vpPxNwSeKhHUL');
end;

class destructor TSharedMemoryProgram.Destroy;
begin
  FProgramIdKey := nil;
end;

class function TSharedMemoryProgram.GetProgramIdKey: IPublicKey;
begin
  Result := FProgramIdKey;
end;

class function TSharedMemoryProgram.Write(
  const ADest: IPublicKey; const APayload: TBytes; const AOffset: UInt64): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
begin
  // 1 writable account: the destination buffer account
  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.Writable(ADest, False));

  Result := TTransactionInstruction.Create(
    ProgramIdKey.KeyBytes,
    LKeys,
    TSharedMemoryProgramData.EncodeWriteData(APayload, AOffset)
  );
end;

class function TSharedMemoryProgram.Decode(
  const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction;
begin
  // Only one instruction ("Write") for this program.
  Result := TDecodedInstruction.Create;
  Result.PublicKey         := ProgramIdKey;
  Result.InstructionName   := InstructionName;  // 'Write'
  Result.ProgramName       := ProgramName;      // 'Shared Memory Program'
  Result.Values            := TDictionary<string, TValue>.Create;
  Result.InnerInstructions := TList<IDecodedInstruction>.Create;

  TSharedMemoryProgramData.DecodeWriteData(Result, AData);
end;

end.

