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

unit SlpInstructionDecoder;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Rtti,
  SlpDataEncoders,
  SlpPublicKey,
  SlpRpcModel,
  SlpMessageDomain,
  SlpTransactionInstruction,
  SlpDecodedInstruction,
  SlpMemoProgram,
  SlpSystemProgram,
  SlpTokenProgram,
  SlpToken2022Program,
  SlpAssociatedTokenAccountProgram,
  SlpSharedMemoryProgram,
  SlpComputeBudgetProgram;

type
  /// <summary>
  /// Implements instruction decoder functionality.
  /// </summary>
  TInstructionDecoder = class
   public
     type
      /// <summary>
      /// The method type which is used to perform instruction decoding.
      /// </summary>
      TDecodeMethodType = reference to function(
        const AData: TBytes;
        const AKeys: TArray<IPublicKey>;
        const AKeyIndices: TBytes
      ): IDecodedInstruction;
    private
    /// <summary>
    /// The dictionary which maps the program public keys to their decoding method.
    /// </summary>
    class var FInstructionDictionary: TDictionary<string, TDecodeMethodType>;
    /// <summary>
    /// Adds an unknown instruction to the given list of decoded instructions, with the given instruction info.
    /// </summary>
    class function AddUnknownInstruction(
      const AInstructionInfo: TInstructionInfo;
      const AProgramKey: string;
      const AKeys: TArray<string>;
      const AKeyIndices: TArray<Integer>
    ): IDecodedInstruction; static;

  public
    /// <summary>
    /// Initialize the instruction decoder instance.
    /// </summary>
    class constructor Create;
    class destructor Destroy;

    /// <summary>
    /// Register the public key of a program and its method used for instruction decoding.
    /// </summary>
    /// <param name="AProgramKey">The public key of the program to decode data from.</param>
    /// <param name="ADecodingMethod">The method which is called to perform instruction decoding for the program.</param>
    class procedure &Register(const AProgramKey: IPublicKey; const ADecodingMethod: TDecodeMethodType); static;

    /// <summary>
    /// Decodes the given instruction data for a given program key.
    /// </summary>
    /// <param name="AProgramKey">The public key of the program to decode data from.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    /// <returns>The decoded instruction data.</returns>
    class function Decode(
      const AProgramKey: IPublicKey;
      const AData: TBytes;
      const AKeys: TArray<IPublicKey>;
      const AKeyIndices: TBytes
    ): IDecodedInstruction; static;

    /// <summary>
    /// Decodes the instructions present in the given transaction and its metadata information.
    /// </summary>
    /// <param name="ATxMetaInfo">The transaction metadata info object.</param>
    /// <returns>The decoded instructions data.</returns>
    class function DecodeInstructions(const ATxMetaInfo: TTransactionMetaInfo): TList<IDecodedInstruction>; overload; static;

    /// <summary>
    /// Decodes the instructions present in the given message and its metadata information.
    /// </summary>
    /// <param name="AMessage">The message object.</param>
    /// <returns>The decoded instructions data.</returns>
    class function DecodeInstructions(const AMessage: IMessage): TList<IDecodedInstruction>; overload; static;
  end;

implementation

{ TInstructionDecoder }

class constructor TInstructionDecoder.Create;
begin
  FInstructionDictionary := TDictionary<string, TDecodeMethodType>.Create;

  // Memo v1 & v2
  FInstructionDictionary.Add(TMemoProgram.ProgramIdKey.Key, TMemoProgram.Decode);
  FInstructionDictionary.Add(TMemoProgram.ProgramIdKeyV2.Key, TMemoProgram.Decode);

  // System
  FInstructionDictionary.Add(TSystemProgram.ProgramIdKey.Key, TSystemProgram.Decode);

  // SPL Token
  FInstructionDictionary.Add(TTokenProgram.ProgramIdKey.Key, TTokenProgram.Decode);
  FInstructionDictionary.Add(TToken2022Program.ProgramIdKey.Key, TToken2022Program.Decode);

  // Associated Token Account
  FInstructionDictionary.Add(TAssociatedTokenAccountProgram.ProgramIdKey.Key, TAssociatedTokenAccountProgram.Decode);

  // Shared Memory Program
  FInstructionDictionary.Add(TSharedMemoryProgram.ProgramIdKey.Key, TSharedMemoryProgram.Decode);

  // Compute Budget
  FInstructionDictionary.Add(TComputeBudgetProgram.ProgramIdKey.Key, TComputeBudgetProgram.Decode);
end;

class destructor TInstructionDecoder.Destroy;
begin
  FInstructionDictionary.Free;
end;

class procedure TInstructionDecoder.Register(
  const AProgramKey: IPublicKey;
  const ADecodingMethod: TDecodeMethodType);
begin
  if (AProgramKey = nil) then
    raise EArgumentNilException.Create('AProgramKey');
  if not Assigned(ADecodingMethod) then
    raise EArgumentNilException.Create('ADecodingMethod');

  FInstructionDictionary.AddOrSetValue(AProgramKey.Key, ADecodingMethod);
end;

class function TInstructionDecoder.Decode(
  const AProgramKey: IPublicKey;
  const AData: TBytes;
  const AKeys: TArray<IPublicKey>;
  const AKeyIndices: TBytes
): IDecodedInstruction;
var
  LMethod: TDecodeMethodType;
begin
  if (AProgramKey = nil) then
    raise EArgumentNilException.Create('AProgramKey');

  if not FInstructionDictionary.TryGetValue(AProgramKey.Key, LMethod) then
    Exit(nil);

  if not Assigned(LMethod) then
    Exit(nil);

  Result := LMethod(AData, AKeys, AKeyIndices);
end;


class function TInstructionDecoder.DecodeInstructions(
  const ATxMetaInfo: TTransactionMetaInfo
): TList<IDecodedInstruction>;
var
  I, X, Y: Integer;
  LDecodedInstruction, LInnerDecodedInstruction: IDecodedInstruction;
  LInstructionInfo: TInstructionInfo;
  LMethod: TDecodeMethodType;
  LTxInfo: TTransactionInfo;
  LMsg: TTransactionContentInfo;
  LKeysList: TList<IPublicKey>;
  LKeyIndices, LData: TBytes;
  LInnerInstruction: TInnerInstruction;
  LInnerInstructionInfo: TInstructionInfo;
  LAccountKey, LProgramKey: string;
begin
  Result := TList<IDecodedInstruction>.Create;

  LTxInfo := ATxMetaInfo.Transaction.AsType<TTransactionInfo>;
  LMsg := LTxInfo.Message;

  for I := 0 to LMsg.Instructions.Count - 1 do
  begin
    LDecodedInstruction := nil;
    LInstructionInfo := LMsg.Instructions[I];
    LProgramKey := LMsg.AccountKeys[LInstructionInfo.ProgramIdIndex];

    if not FInstructionDictionary.TryGetValue(LProgramKey, LMethod) then
    begin
      LDecodedInstruction := AddUnknownInstruction(
        LInstructionInfo,
        LProgramKey,
        LMsg.AccountKeys,
        LMsg.Instructions[I].Accounts
      );
    end
    else
    begin
      // Build keys list: AccountKeys (TArray<string>) -> TList<IPublicKey>
      LKeysList := TList<IPublicKey>.Create;
      try
        for LAccountKey in LMsg.AccountKeys do
          LKeysList.Add(TPublicKey.Create(LAccountKey));

        // Convert KeyIndices -> Bytes
        SetLength(LKeyIndices, Length(LInstructionInfo.Accounts));
        for X := 0 to High(LKeyIndices) do
          LKeyIndices[X] := Byte(LInstructionInfo.Accounts[X]);

        if LInstructionInfo.Data = '' then
          LData := nil
        else
          LData := TEncoders.Base58.DecodeData(LInstructionInfo.Data);

        LDecodedInstruction := LMethod(
          LData,
          LKeysList.ToArray,
          LKeyIndices
        );
      finally
        LKeysList.Free;
      end;
    end;

    if (ATxMetaInfo.Meta.InnerInstructions <> nil) then
    begin
      for LInnerInstruction in ATxMetaInfo.Meta.InnerInstructions do
      begin
        if LInnerInstruction.Index <> I then
          Continue;

        for LInnerInstructionInfo in LInnerInstruction.Instructions do
        begin
          LInnerDecodedInstruction := nil;
          LProgramKey := LMsg.AccountKeys[LInnerInstructionInfo.ProgramIdIndex];

          if not FInstructionDictionary.TryGetValue(LProgramKey, LMethod) then
          begin
            LInnerDecodedInstruction := AddUnknownInstruction(
              LInnerInstructionInfo,
              LProgramKey,
              LMsg.AccountKeys,
              LMsg.Instructions[I].Accounts
            );
          end
          else
          begin
            // Build keys list: AccountKeys (TArray<string>) -> TList<IPublicKey>
            LKeysList := TList<IPublicKey>.Create;
            try
              for LAccountKey in LMsg.AccountKeys do
                LKeysList.Add(TPublicKey.Create(LAccountKey));

              // Convert indices for inner call -> TBytes
              SetLength(LKeyIndices, Length(LInnerInstructionInfo.Accounts));
              for Y := 0 to High(LKeyIndices) do
                LKeyIndices[Y] := Byte(LInnerInstructionInfo.Accounts[Y]);

              if LInnerInstructionInfo.Data = '' then
                LData := nil
              else
                LData := TEncoders.Base58.DecodeData(LInnerInstructionInfo.Data);

              LInnerDecodedInstruction := LMethod(
                LData,
                LKeysList.ToArray,
                LKeyIndices
              );
            finally
              LKeysList.Free;
            end;
          end;

          if LDecodedInstruction.InnerInstructions <> nil then
            LDecodedInstruction.InnerInstructions.Add(LInnerDecodedInstruction);
        end;
      end;
    end;

    if LDecodedInstruction <> nil then
      Result.Add(LDecodedInstruction);
  end;
end;

class function TInstructionDecoder.DecodeInstructions(
  const AMessage: IMessage
): TList<IDecodedInstruction>;
var
  LCompiled: ICompiledInstruction;
  LProgramKey: IPublicKey;
  LMethod: TDecodeMethodType;
  LDecoded: IDecodedInstruction;
  I: Integer;
begin
  Result := TList<IDecodedInstruction>.Create;

  for LCompiled in AMessage.Instructions do
  begin
    LProgramKey := AMessage.AccountKeys[LCompiled.ProgramIdIndex];

    if not FInstructionDictionary.TryGetValue(LProgramKey.Key, LMethod) then
    begin
      LDecoded := TDecodedInstruction.Create;
      LDecoded.InstructionName := 'Unknown';
      LDecoded.ProgramName := 'Unknown';
      LDecoded.Values := TDictionary<string, TValue>.Create;
      LDecoded.Values.Add('Data', TValue.From<string>(TEncoders.Base58.EncodeData(LCompiled.Data)));
      LDecoded.InnerInstructions := TList<IDecodedInstruction>.Create;
      LDecoded.PublicKey := LProgramKey;

      for I := 0 to Length(LCompiled.KeyIndices) - 1 do
        LDecoded.Values.Add(Format('Account %d', [I + 1]), TValue.From<string>(AMessage.AccountKeys[I].Key));

      Result.Add(LDecoded);
      Continue;
    end;

    Result.Add(
      LMethod(LCompiled.Data, AMessage.AccountKeys.ToArray, LCompiled.KeyIndices)
    );
  end;
end;

class function TInstructionDecoder.AddUnknownInstruction(
  const AInstructionInfo: TInstructionInfo;
  const AProgramKey: string;
  const AKeys: TArray<string>;
  const AKeyIndices: TArray<Integer>
): IDecodedInstruction;
var
  J: Integer;
begin
  Result := TDecodedInstruction.Create;

  Result.Values := TDictionary<string, TValue>.Create;
  Result.Values.Add('Data', TValue.From<string>(AInstructionInfo.Data));
  Result.InnerInstructions := TList<IDecodedInstruction>.Create;
  Result.InstructionName := 'Unknown';
  Result.ProgramName := 'Unknown';
  Result.PublicKey := TPublicKey.Create(AProgramKey);

  for J := 0 to Length(AKeyIndices) - 1 do
    Result.Values.Add(Format('Account %d', [J + 1]), TValue.From<string>(AKeys[AKeyIndices[J]]));
end;

end.

