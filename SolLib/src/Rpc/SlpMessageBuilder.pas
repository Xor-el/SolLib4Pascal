{ ****************************************************************************** }
{ *                            SolLib Library                                  * }
{ *               Copyright (c) 2025 Ugochukwu Mmaduekwe                       * }
{ *                Github Repository <https://github.com/Xor-el>               * }
{ *                                                                            * }
{ *   Distributed under the MIT software license, see the accompanying file    * }
{ *   LICENSE or visit http://www.opensource.org/licenses/mit-license.php.     * }
{ *                                                                            * }
{ *                            Acknowledgements:                               * }
{ *                                                                            * }
{ *     Thanks to InstallAware (https://www.installaware.com/) for sponsoring  * }
{ *                   the development of this library                          * }
{ ****************************************************************************** }

(* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& *)

unit SlpMessageBuilder;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  SlpDataEncoders,
  SlpShortVectorEncoding,
  SlpPublicKey,
  SlpAccountDomain,
  SlpTransactionInstruction,
  SlpMessageDomain,
  SlpTransactionDomain,
  SlpListUtils;

type
  IMessageBuilder = interface
    ['{2D9F4B28-8A9F-4B12-A6A6-2F7B4F2E9B6C}']
    function AddInstruction(const AInstruction: ITransactionInstruction): IMessageBuilder;
    function Build: TBytes;
    function GetAccountMetaPublicKeys: TArray<string>;
    function GetInstructions: TList<ITransactionInstruction>;
    function GetRecentBlockHash: string;
    procedure SetRecentBlockHash(const Value: string);
    function GetNonceInformation: INonceInformation;
    procedure SetNonceInformation(const Value: INonceInformation);
    function GetPriorityFeesInformation: IPriorityFeesInformation;
    procedure SetPriorityFeesInformation(const Value: IPriorityFeesInformation);
    function GetFeePayer: IPublicKey;
    procedure SetFeePayer(const Value: IPublicKey);

    property Instructions: TList<ITransactionInstruction> read GetInstructions;
    property RecentBlockHash: string read GetRecentBlockHash write SetRecentBlockHash;
    property NonceInformation: INonceInformation read GetNonceInformation write SetNonceInformation;
    property PriorityFeesInformation: IPriorityFeesInformation read GetPriorityFeesInformation write SetPriorityFeesInformation;
    property FeePayer: IPublicKey read GetFeePayer write SetFeePayer;
  end;

  TMessageBuilder = class(TInterfacedObject, IMessageBuilder)
  private
    FInstructions      : TList<ITransactionInstruction>;
    FRecentBlockHash   : string;
    FNonceInformation  : INonceInformation;
    FPriorityFeesInformation : IPriorityFeesInformation;
    FFeePayer          : IPublicKey;

    function AddInstruction(const AInstruction: ITransactionInstruction): IMessageBuilder;
    function Build: TBytes; virtual;
    function GetAccountMetaPublicKeys: TArray<string>;

    function GetInstructions: TList<ITransactionInstruction>;
    function GetRecentBlockHash: string;
    procedure SetRecentBlockHash(const Value: string);
    function GetNonceInformation: INonceInformation;
    procedure SetNonceInformation(const Value: INonceInformation);
    function GetPriorityFeesInformation: IPriorityFeesInformation;
    procedure SetPriorityFeesInformation(const Value: IPriorityFeesInformation);
    function GetFeePayer: IPublicKey;
    procedure SetFeePayer(const Value: IPublicKey);
  protected
    FMessageHeader     : IMessageHeader;
    FAccountKeysList   : TAccountKeysList;
  const
    BlockHashLength = 32;
    function GetAccountKeysMeta: TList<IAccountMeta>; virtual;

    procedure ApplyNonceInformation;
    procedure ApplyPriorityFeeInformation;

    class function FindAccountIndex(const AccountMetas: TList<IAccountMeta>; const PublicKeyBytes: TBytes): Byte; overload; static;
    class function FindAccountIndex(const AccountMetas: TList<IAccountMeta>; const PublicKeyBase58: string): Byte; overload; static;
  public
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  type
  IVersionedMessageBuilder = interface(IMessageBuilder)
    ['{738D0C34-21BB-428F-BEFF-A9C17E3DA332}']
    function GetAddressTableLookups: TList<IMessageAddressTableLookup>;
    procedure SetAddressTableLookups(const Value: TList<IMessageAddressTableLookup>);

    function GetAccountKeys: TList<IPublicKey>;
    procedure SetAccountKeys(const Value: TList<IPublicKey>);

    property AddressTableLookups: TList<IMessageAddressTableLookup> read GetAddressTableLookups write SetAddressTableLookups;
    property AccountKeys: TList<IPublicKey> read GetAccountKeys write SetAccountKeys;
  end;


type
  TVersionedMessageBuilder = class(TMessageBuilder, IVersionedMessageBuilder)
  private
    FAddressTableLookups: TList<IMessageAddressTableLookup>;
    FAccountKeys: TList<IPublicKey>;

    function GetAddressTableLookups: TList<IMessageAddressTableLookup>;
    procedure SetAddressTableLookups(const Value: TList<IMessageAddressTableLookup>);
    function GetAccountKeys: TList<IPublicKey>;
    procedure SetAccountKeys(const Value: TList<IPublicKey>);
  public
    constructor Create; override;
    destructor Destroy; override;

    function Build: TBytes; override;

    property AddressTableLookups: TList<IMessageAddressTableLookup> read FAddressTableLookups write FAddressTableLookups;
    property AccountKeys: TList<IPublicKey> read FAccountKeys write FAccountKeys;
  end;


implementation

{ TMessageBuilder }

constructor TMessageBuilder.Create;
begin
  inherited Create;
  FAccountKeysList := TAccountKeysList.Create;
  FInstructions := TList<ITransactionInstruction>.Create;
  FMessageHeader := nil;
  FRecentBlockHash := '';
  FNonceInformation := nil;
  FPriorityFeesInformation := NIL;
  FFeePayer := nil;
end;

destructor TMessageBuilder.Destroy;
begin
  if Assigned(FAccountKeysList) then
    FAccountKeysList.Free;
  if Assigned(FInstructions) then
    FInstructions.Free;

  inherited;
end;

function TMessageBuilder.AddInstruction(const AInstruction: ITransactionInstruction): IMessageBuilder;
var
  LPublicKey: IPublicKey;
begin
  FAccountKeysList.Add(AInstruction.Keys);
  LPublicKey := TPublicKey.Create(AInstruction.ProgramId);
  FAccountKeysList.Add(TAccountMeta.ReadOnly(LPublicKey, False));
  FInstructions.Add(AInstruction);
  Result := Self;
end;

procedure TMessageBuilder.ApplyNonceInformation;
var
  LNonceInstruction: ITransactionInstruction;
  LProgPk: IPublicKey;
begin
  if FNonceInformation = nil then
    Exit;

  // 1) Update recent blockhash from nonce info
  FRecentBlockHash := FNonceInformation.Nonce;

  // 2) Extend account metas with the nonce instruction�s keys and program id
  LNonceInstruction := FNonceInformation.Instruction;
  if Assigned(LNonceInstruction) then
  begin
    FAccountKeysList.Add(LNonceInstruction.Keys);
    LProgPk := TPublicKey.Create(LNonceInstruction.ProgramId);
    FAccountKeysList.Add(TAccountMeta.ReadOnly(LProgPk, False));
  end;

  // 3) Ensure the nonce instruction is the first instruction
  FInstructions.Insert(0, LNonceInstruction);
end;

procedure TMessageBuilder.ApplyPriorityFeeInformation;
var
  LComputeUnitPriceInstruction, LComputeUnitLimitInstruction: ITransactionInstruction;
  LComputeUnitPriceProgPk, LComputeUnitLimitProgPk: IPublicKey;
begin
  if FPriorityFeesInformation = nil then
    Exit;

  // First: ComputeUnitPrice (prepended)
  LComputeUnitPriceInstruction := FPriorityFeesInformation.ComputeUnitPriceInstruction;
  if Assigned(LComputeUnitPriceInstruction) then
  begin
    FAccountKeysList.Add(LComputeUnitPriceInstruction.Keys);
    LComputeUnitPriceProgPk := TPublicKey.Create(LComputeUnitPriceInstruction.ProgramId);
    FAccountKeysList.Add(TAccountMeta.ReadOnly(LComputeUnitPriceProgPk, False));
    FInstructions.Insert(0, LComputeUnitPriceInstruction);
  end;

  // Second: ComputeUnitLimit (also prepended, ends up before price until nonce is added)
  LComputeUnitLimitInstruction := FPriorityFeesInformation.ComputeUnitLimitInstruction;
  if Assigned(LComputeUnitLimitInstruction) then
  begin
    FAccountKeysList.Add(LComputeUnitLimitInstruction.Keys);
    LComputeUnitLimitProgPk := TPublicKey.Create(LComputeUnitLimitInstruction.ProgramId);
    FAccountKeysList.Add(TAccountMeta.ReadOnly(LComputeUnitLimitProgPk, False));
    FInstructions.Insert(0, LComputeUnitLimitInstruction);
  end;
end;

function TMessageBuilder.Build: TBytes;
var
  KeysMeta: TList<IAccountMeta>;
  AccountAddressesLength: TBytes;
  CompiledInstructionsLength: Integer;
  CompiledInstructions: TList<ICompiledInstruction>;
  Instruction: ITransactionInstruction;
  KeyCount, I: Integer;
  KeyIndices: TBytes;
  CompiledInstruction: ICompiledInstruction;
  AccountKeysBuffer, Buffer: TMemoryStream;
  InstructionsLength: TBytes;
  AM: IAccountMeta;
  MessageBufferSize, AccountKeysBufferSize: Integer;
  MessageHeaderBytes: TBytes;
  EncodedRecentBlockhash: TBytes;
  LProgramIdIndex: Byte;
begin
  if (FRecentBlockHash = '') and (FNonceInformation = nil) then
    raise Exception.Create('recent block hash or nonce information is required');
  if (FInstructions = nil) then
    raise Exception.Create('instructions cannot be nil');

  // In case the user specifies priority fee information, we'll use it.
  ApplyPriorityFeeInformation;
  // In case the user specifies nonce information, we'll use it.
  ApplyNonceInformation;

  FMessageHeader := TMessageHeader.Create;

  KeysMeta := GetAccountKeysMeta;
  try
    AccountAddressesLength := TShortVectorEncoding.EncodeLength(KeysMeta.Count);
    CompiledInstructionsLength := 0;
    CompiledInstructions := TList<ICompiledInstruction>.Create;
    try
      for Instruction in FInstructions do
      begin
        KeyCount := Instruction.Keys.Count;
        SetLength(KeyIndices, KeyCount);
        for I := 0 to KeyCount - 1 do
          KeyIndices[I] := FindAccountIndex(KeysMeta, Instruction.Keys[I].PublicKey.Key);

        CompiledInstruction := TCompiledInstruction.Create(
          FindAccountIndex(KeysMeta, Instruction.ProgramId),
          TShortVectorEncoding.EncodeLength(KeyCount),
          KeyIndices,
          TShortVectorEncoding.EncodeLength(Length(Instruction.Data)),
          Instruction.Data
        );
        CompiledInstructions.Add(CompiledInstruction);
        Inc(CompiledInstructionsLength, CompiledInstruction.ItemCount);
      end;

      AccountKeysBufferSize := FAccountKeysList.Count * 32;
      AccountKeysBuffer := TMemoryStream.Create;
      try
        AccountKeysBuffer.Size := AccountKeysBufferSize;
        InstructionsLength := TShortVectorEncoding.EncodeLength(CompiledInstructions.Count);

        for AM in KeysMeta do
        begin
          AccountKeysBuffer.WriteBuffer(AM.PublicKey.KeyBytes[0], Length(AM.PublicKey.KeyBytes));

          if AM.IsSigner then
          begin
            FMessageHeader.RequiredSignatures := FMessageHeader.RequiredSignatures + 1;
            if not AM.IsWritable then
              FMessageHeader.ReadOnlySignedAccounts := FMessageHeader.ReadOnlySignedAccounts + 1;
          end
          else
          begin
            if not AM.IsWritable then
              FMessageHeader.ReadOnlyUnsignedAccounts := FMessageHeader.ReadOnlyUnsignedAccounts + 1;
          end;
        end;

        MessageBufferSize := TMessageHeader.TLayout.HeaderLength + BlockHashLength +
                             Length(AccountAddressesLength) + Length(InstructionsLength) +
                             CompiledInstructionsLength + AccountKeysBufferSize;
        Buffer := TMemoryStream.Create;
        try
          Buffer.Size := MessageBufferSize;
          MessageHeaderBytes := FMessageHeader.ToBytes;

          Buffer.WriteBuffer(MessageHeaderBytes[0], Length(MessageHeaderBytes));
          Buffer.WriteBuffer(AccountAddressesLength[0], Length(AccountAddressesLength));
          Buffer.WriteBuffer(AccountKeysBuffer.Memory^, AccountKeysBuffer.Size);
          EncodedRecentBlockhash := TEncoders.Base58.DecodeData(FRecentBlockHash);
          Buffer.WriteBuffer(EncodedRecentBlockhash[0], Length(EncodedRecentBlockhash));
          Buffer.WriteBuffer(InstructionsLength[0], Length(InstructionsLength));

          for CompiledInstruction in CompiledInstructions do
          begin
            LProgramIdIndex := CompiledInstruction.ProgramIdIndex;

            Buffer.WriteBuffer(LProgramIdIndex, SizeOf(LProgramIdIndex));
            Buffer.WriteBuffer(CompiledInstruction.KeyIndicesCount[0], Length(CompiledInstruction.KeyIndicesCount));
            Buffer.WriteBuffer(CompiledInstruction.KeyIndices[0], Length(CompiledInstruction.KeyIndices));
            Buffer.WriteBuffer(CompiledInstruction.DataLength[0], Length(CompiledInstruction.DataLength));
            Buffer.WriteBuffer(CompiledInstruction.Data[0], Length(CompiledInstruction.Data));
          end;

          SetLength(Result, Buffer.Size);
          Buffer.Position := 0;
          Buffer.ReadBuffer(Result[0], Buffer.Size);
        finally
          Buffer.Free;
        end;
      finally
        AccountKeysBuffer.Free;
      end;
    finally
      CompiledInstructions.Free;
    end;
  finally
    KeysMeta.Free;
  end;
end;

class function TMessageBuilder.FindAccountIndex(
  const AccountMetas: TList<IAccountMeta>;
  const PublicKeyBytes: TBytes): Byte;
var
  Encoded: string;
begin
  Encoded := TEncoders.Base58.EncodeData(PublicKeyBytes);
  Result := FindAccountIndex(AccountMetas, Encoded);
end;

class function TMessageBuilder.FindAccountIndex(
  const AccountMetas: TList<IAccountMeta>;
  const PublicKeyBase58: string): Byte;
var
  Index: Byte;
begin
  for Index := 0 to AccountMetas.Count - 1 do
    if SameStr(AccountMetas[Index].PublicKey.Key, PublicKeyBase58) then
      Exit(Index);
  raise Exception.CreateFmt('Something went wrong encoding this transaction. Account `%s` was not found among list of accounts. Should be impossible.', [PublicKeyBase58]);
end;

function TMessageBuilder.GetAccountKeysMeta: TList<IAccountMeta>;
var
  KeysList     : TList<IAccountMeta>;
  FeePayerIndex: Integer;
begin
  Result := TList<IAccountMeta>.Create;
  KeysList := FAccountKeysList.AccountList;

  try
    try
      FeePayerIndex :=
        TListUtils.FindIndex<IAccountMeta>(KeysList,
          function(AccMeta: IAccountMeta): Boolean
          begin
            Result := AccMeta.PublicKey.Equals(FFeePayer);
          end);

      // Ensure fee payer is first (writable, signer)
      if FeePayerIndex <> -1 then
        KeysList.Delete(FeePayerIndex);

      Result.Add(TAccountMeta.Writable(FFeePayer, True));

      // Append the remaining keys
      Result.AddRange(KeysList);
    except
      Result.Free;
      raise;
    end;
  finally
    KeysList.Free;
  end;
end;

function TMessageBuilder.GetAccountMetaPublicKeys: TArray<string>;
var
  Metas: TList<IAccountMeta>;
  I: Integer;
begin
  Metas := GetAccountKeysMeta;
  try
    SetLength(Result, Metas.Count);
    for I := 0 to Metas.Count - 1 do
      Result[I] := Metas[I].PublicKey.Key;
  finally
    Metas.Free;
  end;
end;

function TMessageBuilder.GetInstructions: TList<ITransactionInstruction>;
begin
  Result := FInstructions;
end;

function TMessageBuilder.GetRecentBlockHash: string;
begin
  Result := FRecentBlockHash;
end;

procedure TMessageBuilder.SetRecentBlockHash(const Value: string);
begin
  FRecentBlockHash := Value;
end;

function TMessageBuilder.GetNonceInformation: INonceInformation;
begin
  Result := FNonceInformation;
end;

procedure TMessageBuilder.SetNonceInformation(const Value: INonceInformation);
begin
  FNonceInformation := Value;
end;

function TMessageBuilder.GetPriorityFeesInformation: IPriorityFeesInformation;
begin
 Result := FPriorityFeesInformation;
end;

procedure TMessageBuilder.SetPriorityFeesInformation(
  const Value: IPriorityFeesInformation);
begin
  FPriorityFeesInformation := Value;
end;

function TMessageBuilder.GetFeePayer: IPublicKey;
begin
  Result := FFeePayer;
end;

procedure TMessageBuilder.SetFeePayer(const Value: IPublicKey);
begin
  FFeePayer := Value;
end;

{ TVersionedMessageBuilder }

constructor TVersionedMessageBuilder.Create;
begin
  inherited Create;
  FAddressTableLookups := TList<IMessageAddressTableLookup>.Create;
  FAccountKeys := TList<IPublicKey>.Create;
end;

destructor TVersionedMessageBuilder.Destroy;
begin
  if Assigned(FAccountKeys) then
    FAccountKeys.Free;
  if Assigned(FAddressTableLookups) then
    FAddressTableLookups.Free;
  inherited;
end;

function TVersionedMessageBuilder.GetAddressTableLookups: TList<IMessageAddressTableLookup>;
begin
  Result := FAddressTableLookups;
end;

procedure TVersionedMessageBuilder.SetAddressTableLookups(const Value: TList<IMessageAddressTableLookup>);
begin
  FAddressTableLookups := Value;
end;

function TVersionedMessageBuilder.GetAccountKeys: TList<IPublicKey>;
begin
  Result := FAccountKeys;
end;

procedure TVersionedMessageBuilder.SetAccountKeys(const Value: TList<IPublicKey>);
begin
  FAccountKeys := Value;
end;

function TVersionedMessageBuilder.Build: TBytes;
var
  KeysMeta: TList<IAccountMeta>;
  AccountAddressesLength: TBytes;
  CompiledInstructionsLength: Integer;
  CompiledInstructions: TList<ICompiledInstruction>;
  Instruction: ITransactionInstruction;
  KeyCount, I: Integer;
  KeyIndices: TBytes;
  CompiledInstruction: ICompiledInstruction;
  AccountKeysBuffer, Buffer: TMemoryStream;
  InstructionsLength: TBytes;
  AM: IAccountMeta;
  MessageBufferSize, AccountKeysBufferSize: Integer;
  MessageHeaderBytes: TBytes;
  EncodedRecentBlockhash, ATL: TBytes;
  VersionPrefix, LProgramIdIndex: Byte;
  Versioned: IVersionedTransactionInstruction;
begin
  if (FRecentBlockHash = '') and (FNonceInformation = nil) then
    raise Exception.Create('recent block hash or nonce information is required');
  if (FInstructions = nil) then
    raise Exception.Create('instructions cannot be nil');

  // In case the user specifies priority fee information, we'll use it.
  ApplyPriorityFeeInformation;
  // In case the user specifies nonce information, we'll use it.
  ApplyNonceInformation;

  FMessageHeader := TMessageHeader.Create;

  KeysMeta := GetAccountKeysMeta;
  try
    AccountAddressesLength := TShortVectorEncoding.EncodeLength(KeysMeta.Count);
    CompiledInstructionsLength := 0;
    CompiledInstructions := TList<ICompiledInstruction>.Create;
    try
      for Instruction in FInstructions do
      begin
        KeyCount := Instruction.Keys.Count;

        if Supports(Instruction, IVersionedTransactionInstruction, Versioned) then
        begin
          KeyIndices := Versioned.KeyIndices;
        end
        else
        begin
          SetLength(KeyIndices, KeyCount);
          for i := 0 to KeyCount - 1 do
            KeyIndices[i] := FindAccountIndex(KeysMeta, Instruction.Keys[i].PublicKey.Key);
        end;

        CompiledInstruction := TCompiledInstruction.Create(
          FindAccountIndex(KeysMeta, Instruction.ProgramId),
          TShortVectorEncoding.EncodeLength(KeyCount),
          KeyIndices,
          TShortVectorEncoding.EncodeLength(Length(Instruction.Data)),
          Instruction.Data
        );
        CompiledInstructions.Add(CompiledInstruction);
        Inc(CompiledInstructionsLength, CompiledInstruction.ItemCount);
      end;

      AccountKeysBufferSize := FAccountKeysList.Count * 32;
      AccountKeysBuffer := TMemoryStream.Create;
      try
        AccountKeysBuffer.Size := AccountKeysBufferSize;
        InstructionsLength := TShortVectorEncoding.EncodeLength(CompiledInstructions.Count);

        for AM in KeysMeta do
        begin
          AccountKeysBuffer.WriteBuffer(AM.PublicKey.KeyBytes[0], Length(AM.PublicKey.KeyBytes));

          if AM.IsSigner then
          begin
            FMessageHeader.RequiredSignatures := FMessageHeader.RequiredSignatures + 1;
            if not AM.IsWritable then
              FMessageHeader.ReadOnlySignedAccounts := FMessageHeader.ReadOnlySignedAccounts + 1;
          end
          else
          begin
            if not AM.IsWritable then
              FMessageHeader.ReadOnlyUnsignedAccounts := FMessageHeader.ReadOnlyUnsignedAccounts + 1;
          end;
        end;

        MessageBufferSize := TMessageHeader.TLayout.HeaderLength + BlockHashLength +
                             Length(AccountAddressesLength) + Length(InstructionsLength) +
                             CompiledInstructionsLength + AccountKeysBufferSize;
        Buffer := TMemoryStream.Create;
        try
          Buffer.Size := MessageBufferSize;
          MessageHeaderBytes := FMessageHeader.ToBytes;

          // versioned prefix 0x80
          VersionPrefix := Byte($80);
          Buffer.WriteBuffer(VersionPrefix, 1);

          Buffer.WriteBuffer(MessageHeaderBytes[0], Length(MessageHeaderBytes));
          Buffer.WriteBuffer(AccountAddressesLength[0], Length(AccountAddressesLength));
          Buffer.WriteBuffer(AccountKeysBuffer.Memory^, AccountKeysBuffer.Size);
          EncodedRecentBlockhash := TEncoders.Base58.DecodeData(FRecentBlockHash);
          Buffer.WriteBuffer(EncodedRecentBlockhash[0], Length(EncodedRecentBlockhash));
          Buffer.WriteBuffer(InstructionsLength[0], Length(InstructionsLength));

          for CompiledInstruction in CompiledInstructions do
          begin
            LProgramIdIndex := CompiledInstruction.ProgramIdIndex;
            Buffer.WriteBuffer(LProgramIdIndex, SizeOf(LProgramIdIndex));
            Buffer.WriteBuffer(CompiledInstruction.KeyIndicesCount[0], Length(CompiledInstruction.KeyIndicesCount));
            Buffer.WriteBuffer(CompiledInstruction.KeyIndices[0], Length(CompiledInstruction.KeyIndices));
            Buffer.WriteBuffer(CompiledInstruction.DataLength[0], Length(CompiledInstruction.DataLength));
            Buffer.WriteBuffer(CompiledInstruction.Data[0], Length(CompiledInstruction.Data));
          end;

          // address table lookups
          ATL := TVersionedMessage.TAddressTableLookupUtils.SerializeAddressTableLookups(FAddressTableLookups);
          Buffer.WriteBuffer(ATL[0], Length(ATL));

          SetLength(Result, Buffer.Size);
          Buffer.Position := 0;
          Buffer.ReadBuffer(Result[0], Buffer.Size);
        finally
          Buffer.Free;
        end;
      finally
        AccountKeysBuffer.Free;
      end;
    finally
      CompiledInstructions.Free;
    end;
  finally
    KeysMeta.Free;
  end;
end;

end.

