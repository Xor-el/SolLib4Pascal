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
    procedure SetRecentBlockHash(const AValue: string);
    function GetNonceInformation: INonceInformation;
    procedure SetNonceInformation(const AValue: INonceInformation);
    function GetPriorityFeesInformation: IPriorityFeesInformation;
    procedure SetPriorityFeesInformation(const AValue: IPriorityFeesInformation);
    function GetFeePayer: IPublicKey;
    procedure SetFeePayer(const AValue: IPublicKey);

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
    procedure SetRecentBlockHash(const AValue: string);
    function GetNonceInformation: INonceInformation;
    procedure SetNonceInformation(const AValue: INonceInformation);
    function GetPriorityFeesInformation: IPriorityFeesInformation;
    procedure SetPriorityFeesInformation(const AValue: IPriorityFeesInformation);
    function GetFeePayer: IPublicKey;
    procedure SetFeePayer(const AValue: IPublicKey);
  protected
    FMessageHeader     : IMessageHeader;
    FAccountKeysList   : TAccountKeysList;
  const
    BlockHashLength = 32;
    function GetAccountKeysMeta: TList<IAccountMeta>; virtual;

    procedure ApplyNonceInformation;
    procedure ApplyPriorityFeeInformation;

    class function FindAccountIndex(const AAccountMetas: TList<IAccountMeta>; const APublicKeyBytes: TBytes): Byte; overload; static;
    class function FindAccountIndex(const AAccountMetas: TList<IAccountMeta>; const APublicKeyBase58: string): Byte; overload; static;
  public
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  type
  IVersionedMessageBuilder = interface(IMessageBuilder)
    ['{738D0C34-21BB-428F-BEFF-A9C17E3DA332}']
    function GetAddressTableLookups: TList<IMessageAddressTableLookup>;
    procedure SetAddressTableLookups(const AValue: TList<IMessageAddressTableLookup>);

    function GetAccountKeys: TList<IPublicKey>;
    procedure SetAccountKeys(const AValue: TList<IPublicKey>);

    property AddressTableLookups: TList<IMessageAddressTableLookup> read GetAddressTableLookups write SetAddressTableLookups;
    property AccountKeys: TList<IPublicKey> read GetAccountKeys write SetAccountKeys;
  end;


type
  TVersionedMessageBuilder = class(TMessageBuilder, IVersionedMessageBuilder)
  private
    FAddressTableLookups: TList<IMessageAddressTableLookup>;
    FAccountKeys: TList<IPublicKey>;

    function GetAddressTableLookups: TList<IMessageAddressTableLookup>;
    procedure SetAddressTableLookups(const AValue: TList<IMessageAddressTableLookup>);
    function GetAccountKeys: TList<IPublicKey>;
    procedure SetAccountKeys(const AValue: TList<IPublicKey>);
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

  // 2) Extend account metas with the nonce instruction keys and program id
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
  LKeysMeta: TList<IAccountMeta>;
  LAccountAddressesLength: TBytes;
  LCompiledInstructionsLength: Integer;
  LCompiledInstructions: TList<ICompiledInstruction>;
  LInstruction: ITransactionInstruction;
  LKeyCount, LI: Integer;
  LKeyIndices: TBytes;
  LCompiledInstruction: ICompiledInstruction;
  LAccountKeysBuffer, LBuffer: TMemoryStream;
  LInstructionsLength: TBytes;
  LAM: IAccountMeta;
  LMessageBufferSize, LAccountKeysBufferSize: Integer;
  LMessageHeaderBytes: TBytes;
  LEncodedRecentBlockhash: TBytes;
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

  LKeysMeta := GetAccountKeysMeta;
  try
    LAccountAddressesLength := TShortVectorEncoding.EncodeLength(LKeysMeta.Count);
    LCompiledInstructionsLength := 0;
    LCompiledInstructions := TList<ICompiledInstruction>.Create;
    try
      for LInstruction in FInstructions do
      begin
        LKeyCount := LInstruction.Keys.Count;
        SetLength(LKeyIndices, LKeyCount);
        for LI := 0 to LKeyCount - 1 do
          LKeyIndices[LI] := FindAccountIndex(LKeysMeta, LInstruction.Keys[LI].PublicKey.Key);

        LCompiledInstruction := TCompiledInstruction.Create(
          FindAccountIndex(LKeysMeta, LInstruction.ProgramId),
          TShortVectorEncoding.EncodeLength(LKeyCount),
          LKeyIndices,
          TShortVectorEncoding.EncodeLength(Length(LInstruction.Data)),
          LInstruction.Data
        );
        LCompiledInstructions.Add(LCompiledInstruction);
        Inc(LCompiledInstructionsLength, LCompiledInstruction.ItemCount);
      end;

      LAccountKeysBufferSize := FAccountKeysList.Count * 32;
      LAccountKeysBuffer := TMemoryStream.Create;
      try
        LAccountKeysBuffer.Size := LAccountKeysBufferSize;
        LInstructionsLength := TShortVectorEncoding.EncodeLength(LCompiledInstructions.Count);

        for LAM in LKeysMeta do
        begin
          LAccountKeysBuffer.WriteBuffer(LAM.PublicKey.KeyBytes[0], Length(LAM.PublicKey.KeyBytes));

          if LAM.IsSigner then
          begin
            FMessageHeader.RequiredSignatures := FMessageHeader.RequiredSignatures + 1;
            if not LAM.IsWritable then
              FMessageHeader.ReadOnlySignedAccounts := FMessageHeader.ReadOnlySignedAccounts + 1;
          end
          else
          begin
            if not LAM.IsWritable then
              FMessageHeader.ReadOnlyUnsignedAccounts := FMessageHeader.ReadOnlyUnsignedAccounts + 1;
          end;
        end;

        LMessageBufferSize := TMessageHeader.TLayout.HeaderLength + BlockHashLength +
                             Length(LAccountAddressesLength) + Length(LInstructionsLength) +
                             LCompiledInstructionsLength + LAccountKeysBufferSize;
        LBuffer := TMemoryStream.Create;
        try
          LBuffer.Size := LMessageBufferSize;
          LMessageHeaderBytes := FMessageHeader.ToBytes;

          LBuffer.WriteBuffer(LMessageHeaderBytes[0], Length(LMessageHeaderBytes));
          LBuffer.WriteBuffer(LAccountAddressesLength[0], Length(LAccountAddressesLength));
          LBuffer.WriteBuffer(LAccountKeysBuffer.Memory^, LAccountKeysBuffer.Size);
          LEncodedRecentBlockhash := TEncoders.Base58.DecodeData(FRecentBlockHash);
          LBuffer.WriteBuffer(LEncodedRecentBlockhash[0], Length(LEncodedRecentBlockhash));
          LBuffer.WriteBuffer(LInstructionsLength[0], Length(LInstructionsLength));

          for LCompiledInstruction in LCompiledInstructions do
          begin
            LProgramIdIndex := LCompiledInstruction.ProgramIdIndex;

            LBuffer.WriteBuffer(LProgramIdIndex, SizeOf(LProgramIdIndex));
            LBuffer.WriteBuffer(LCompiledInstruction.KeyIndicesCount[0], Length(LCompiledInstruction.KeyIndicesCount));
            LBuffer.WriteBuffer(LCompiledInstruction.KeyIndices[0], Length(LCompiledInstruction.KeyIndices));
            LBuffer.WriteBuffer(LCompiledInstruction.DataLength[0], Length(LCompiledInstruction.DataLength));
            LBuffer.WriteBuffer(LCompiledInstruction.Data[0], Length(LCompiledInstruction.Data));
          end;

          SetLength(Result, LBuffer.Size);
          LBuffer.Position := 0;
          LBuffer.ReadBuffer(Result[0], LBuffer.Size);
        finally
          LBuffer.Free;
        end;
      finally
        LAccountKeysBuffer.Free;
      end;
    finally
      LCompiledInstructions.Free;
    end;
  finally
    LKeysMeta.Free;
  end;
end;

class function TMessageBuilder.FindAccountIndex(
  const AAccountMetas: TList<IAccountMeta>;
  const APublicKeyBytes: TBytes): Byte;
var
  LEncoded: string;
begin
  LEncoded := TEncoders.Base58.EncodeData(APublicKeyBytes);
  Result := FindAccountIndex(AAccountMetas, LEncoded);
end;

class function TMessageBuilder.FindAccountIndex(
  const AAccountMetas: TList<IAccountMeta>;
  const APublicKeyBase58: string): Byte;
var
  LIndex: Byte;
begin
  for LIndex := 0 to AAccountMetas.Count - 1 do
    if SameStr(AAccountMetas[LIndex].PublicKey.Key, APublicKeyBase58) then
      Exit(LIndex);
  raise Exception.CreateFmt('Something went wrong encoding this transaction. Account `%s` was not found among list of accounts. Should be impossible.', [APublicKeyBase58]);
end;

function TMessageBuilder.GetAccountKeysMeta: TList<IAccountMeta>;
var
  LKeysList     : TList<IAccountMeta>;
  LFeePayerIndex: Integer;
begin
  Result := TList<IAccountMeta>.Create;
  LKeysList := FAccountKeysList.AccountList;

  try
    try
      LFeePayerIndex :=
        TListUtils.FindIndex<IAccountMeta>(LKeysList,
          function(AAccMeta: IAccountMeta): Boolean
          begin
            Result := AAccMeta.PublicKey.Equals(FFeePayer);
          end);

      // Ensure fee payer is first (writable, signer)
      if LFeePayerIndex <> -1 then
        LKeysList.Delete(LFeePayerIndex);

      Result.Add(TAccountMeta.Writable(FFeePayer, True));

      // Append the remaining keys
      Result.AddRange(LKeysList);
    except
      Result.Free;
      raise;
    end;
  finally
    LKeysList.Free;
  end;
end;

function TMessageBuilder.GetAccountMetaPublicKeys: TArray<string>;
var
  LMetas: TList<IAccountMeta>;
  LI: Integer;
begin
  LMetas := GetAccountKeysMeta;
  try
    SetLength(Result, LMetas.Count);
    for LI := 0 to LMetas.Count - 1 do
      Result[LI] := LMetas[LI].PublicKey.Key;
  finally
    LMetas.Free;
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

procedure TMessageBuilder.SetRecentBlockHash(const AValue: string);
begin
  FRecentBlockHash := AValue;
end;

function TMessageBuilder.GetNonceInformation: INonceInformation;
begin
  Result := FNonceInformation;
end;

procedure TMessageBuilder.SetNonceInformation(const AValue: INonceInformation);
begin
  FNonceInformation := AValue;
end;

function TMessageBuilder.GetPriorityFeesInformation: IPriorityFeesInformation;
begin
 Result := FPriorityFeesInformation;
end;

procedure TMessageBuilder.SetPriorityFeesInformation(
  const AValue: IPriorityFeesInformation);
begin
  FPriorityFeesInformation := AValue;
end;

function TMessageBuilder.GetFeePayer: IPublicKey;
begin
  Result := FFeePayer;
end;

procedure TMessageBuilder.SetFeePayer(const AValue: IPublicKey);
begin
  FFeePayer := AValue;
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

procedure TVersionedMessageBuilder.SetAddressTableLookups(const AValue: TList<IMessageAddressTableLookup>);
begin
  FAddressTableLookups := AValue;
end;

function TVersionedMessageBuilder.GetAccountKeys: TList<IPublicKey>;
begin
  Result := FAccountKeys;
end;

procedure TVersionedMessageBuilder.SetAccountKeys(const AValue: TList<IPublicKey>);
begin
  FAccountKeys := AValue;
end;

function TVersionedMessageBuilder.Build: TBytes;
var
  LKeysMeta: TList<IAccountMeta>;
  LAccountAddressesLength: TBytes;
  LCompiledInstructionsLength: Integer;
  LCompiledInstructions: TList<ICompiledInstruction>;
  LInstruction: ITransactionInstruction;
  LKeyCount, LI: Integer;
  LKeyIndices: TBytes;
  LCompiledInstruction: ICompiledInstruction;
  LAccountKeysBuffer, LBuffer: TMemoryStream;
  LInstructionsLength: TBytes;
  LAM: IAccountMeta;
  LMessageBufferSize, LAccountKeysBufferSize: Integer;
  LMessageHeaderBytes: TBytes;
  LEncodedRecentBlockhash, LAtl: TBytes;
  LVersionPrefix, LProgramIdIndex: Byte;
  LVersioned: IVersionedTransactionInstruction;
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

  LKeysMeta := GetAccountKeysMeta;
  try
    LAccountAddressesLength := TShortVectorEncoding.EncodeLength(LKeysMeta.Count);
    LCompiledInstructionsLength := 0;
    LCompiledInstructions := TList<ICompiledInstruction>.Create;
    try
      for LInstruction in FInstructions do
      begin
        LKeyCount := LInstruction.Keys.Count;

        if Supports(LInstruction, IVersionedTransactionInstruction, LVersioned) then
        begin
          LKeyIndices := LVersioned.KeyIndices;
        end
        else
        begin
          SetLength(LKeyIndices, LKeyCount);
          for LI := 0 to LKeyCount - 1 do
            LKeyIndices[LI] := FindAccountIndex(LKeysMeta, LInstruction.Keys[LI].PublicKey.Key);
        end;

        LCompiledInstruction := TCompiledInstruction.Create(
          FindAccountIndex(LKeysMeta, LInstruction.ProgramId),
          TShortVectorEncoding.EncodeLength(LKeyCount),
          LKeyIndices,
          TShortVectorEncoding.EncodeLength(Length(LInstruction.Data)),
          LInstruction.Data
        );
        LCompiledInstructions.Add(LCompiledInstruction);
        Inc(LCompiledInstructionsLength, LCompiledInstruction.ItemCount);
      end;

      LAccountKeysBufferSize := FAccountKeysList.Count * 32;
      LAccountKeysBuffer := TMemoryStream.Create;
      try
        LAccountKeysBuffer.Size := LAccountKeysBufferSize;
        LInstructionsLength := TShortVectorEncoding.EncodeLength(LCompiledInstructions.Count);

        for LAM in LKeysMeta do
        begin
          LAccountKeysBuffer.WriteBuffer(LAM.PublicKey.KeyBytes[0], Length(LAM.PublicKey.KeyBytes));

          if LAM.IsSigner then
          begin
            FMessageHeader.RequiredSignatures := FMessageHeader.RequiredSignatures + 1;
            if not LAM.IsWritable then
              FMessageHeader.ReadOnlySignedAccounts := FMessageHeader.ReadOnlySignedAccounts + 1;
          end
          else
          begin
            if not LAM.IsWritable then
              FMessageHeader.ReadOnlyUnsignedAccounts := FMessageHeader.ReadOnlyUnsignedAccounts + 1;
          end;
        end;

        LMessageBufferSize := TMessageHeader.TLayout.HeaderLength + BlockHashLength +
                             Length(LAccountAddressesLength) + Length(LInstructionsLength) +
                             LCompiledInstructionsLength + LAccountKeysBufferSize;
        LBuffer := TMemoryStream.Create;
        try
          LBuffer.Size := LMessageBufferSize;
          LMessageHeaderBytes := FMessageHeader.ToBytes;

          // versioned prefix 0x80
          LVersionPrefix := Byte($80);
          LBuffer.WriteBuffer(LVersionPrefix, 1);

          LBuffer.WriteBuffer(LMessageHeaderBytes[0], Length(LMessageHeaderBytes));
          LBuffer.WriteBuffer(LAccountAddressesLength[0], Length(LAccountAddressesLength));
          LBuffer.WriteBuffer(LAccountKeysBuffer.Memory^, LAccountKeysBuffer.Size);
          LEncodedRecentBlockhash := TEncoders.Base58.DecodeData(FRecentBlockHash);
          LBuffer.WriteBuffer(LEncodedRecentBlockhash[0], Length(LEncodedRecentBlockhash));
          LBuffer.WriteBuffer(LInstructionsLength[0], Length(LInstructionsLength));

          for LCompiledInstruction in LCompiledInstructions do
          begin
            LProgramIdIndex := LCompiledInstruction.ProgramIdIndex;
            LBuffer.WriteBuffer(LProgramIdIndex, SizeOf(LProgramIdIndex));
            LBuffer.WriteBuffer(LCompiledInstruction.KeyIndicesCount[0], Length(LCompiledInstruction.KeyIndicesCount));
            LBuffer.WriteBuffer(LCompiledInstruction.KeyIndices[0], Length(LCompiledInstruction.KeyIndices));
            LBuffer.WriteBuffer(LCompiledInstruction.DataLength[0], Length(LCompiledInstruction.DataLength));
            LBuffer.WriteBuffer(LCompiledInstruction.Data[0], Length(LCompiledInstruction.Data));
          end;

          // address table lookups
          LAtl := TVersionedMessage.TAddressTableLookupUtils.SerializeAddressTableLookups(FAddressTableLookups);
          LBuffer.WriteBuffer(LAtl[0], Length(LAtl));

          SetLength(Result, LBuffer.Size);
          LBuffer.Position := 0;
          LBuffer.ReadBuffer(Result[0], LBuffer.Size);
        finally
          LBuffer.Free;
        end;
      finally
        LAccountKeysBuffer.Free;
      end;
    finally
      LCompiledInstructions.Free;
    end;
  finally
    LKeysMeta.Free;
  end;
end;

end.

