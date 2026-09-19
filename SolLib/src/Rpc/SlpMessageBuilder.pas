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
  SysUtils,
  Classes,
  Generics.Collections,
  SlpDataEncoderUtilities,
  SlpShortVectorEncoding,
  SlpPublicKey,
  SlpAccountDomain,
  SlpTransactionInstruction,
  SlpMessageDomain,
  SlpTransactionDomain,
  SlpTransactionConfig,
  SlpArrayUtilities,
  SlpListUtilities;

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

  IVersionedMessageBuilder = interface(IMessageBuilder)
    ['{738D0C34-21BB-428F-BEFF-A9C17E3DA332}']
    function GetAddressTableLookups: TList<IMessageAddressTableLookup>;
    procedure SetAddressTableLookups(const AValue: TList<IMessageAddressTableLookup>);

    function GetAccountKeys: TList<IPublicKey>;
    procedure SetAccountKeys(const AValue: TList<IPublicKey>);

    function GetVersion: Byte;
    procedure SetVersion(const AValue: Byte);
    function GetTransactionConfig: TTransactionConfig;
    procedure SetTransactionConfig(const AValue: TTransactionConfig);

    property AddressTableLookups: TList<IMessageAddressTableLookup> read GetAddressTableLookups write SetAddressTableLookups;
    property AccountKeys: TList<IPublicKey> read GetAccountKeys write SetAccountKeys;
    /// <summary>
    /// The message version emitted in the low 7 bits of the versioned prefix.
    /// </summary>
    property Version: Byte read GetVersion write SetVersion;
    /// <summary>
    /// The in-message transaction configuration (version 1 only).
    /// </summary>
    property TransactionConfig: TTransactionConfig read GetTransactionConfig write SetTransactionConfig;
  end;


type
  /// <summary>
  /// Fluent facet for building a legacy (unversioned) message. Carries no version-specific
  /// options (no address lookup tables, no in-message transaction config).
  /// </summary>
  IMessageBuilderLegacy = interface
    ['{6B2A9C41-4D0E-4F1A-9C7B-1E2D3A4B5C60}']
    function SetRecentBlockHash(const ARecentBlockHash: string): IMessageBuilderLegacy;
    function SetNonceInformation(const ANonceInfo: INonceInformation): IMessageBuilderLegacy;
    function SetPriorityFeesInformation(const APriorityFeesInfo: IPriorityFeesInformation): IMessageBuilderLegacy;
    function SetFeePayer(const APublicKey: IPublicKey): IMessageBuilderLegacy;
    function AddInstruction(const AInstruction: ITransactionInstruction): IMessageBuilderLegacy;
    function GetAccountMetaPublicKeys: TArray<string>;
    function Build: TBytes;
  end;

  /// <summary>
  /// Fluent facet for building a version 0 message. Exposes address lookup tables and the
  /// priority-fee settings (emitted as Compute Budget instructions), and deliberately omits
  /// the in-message transaction config (a version 1 concept).
  /// </summary>
  IMessageBuilderV0 = interface
    ['{7C3BAD52-5E1F-4A2B-8D6C-2F3E4A5B6C71}']
    function SetRecentBlockHash(const ARecentBlockHash: string): IMessageBuilderV0;
    function SetNonceInformation(const ANonceInfo: INonceInformation): IMessageBuilderV0;
    function SetPriorityFeesInformation(const APriorityFeesInfo: IPriorityFeesInformation): IMessageBuilderV0;
    function SetFeePayer(const APublicKey: IPublicKey): IMessageBuilderV0;
    function AddInstruction(const AInstruction: ITransactionInstruction): IMessageBuilderV0;
    function AddAddressTableLookup(const ALookup: IMessageAddressTableLookup): IMessageBuilderV0;
    function AddAddressTableLookups(const ALookups: TList<IMessageAddressTableLookup>): IMessageBuilderV0;
    function GetAccountMetaPublicKeys: TArray<string>;
    function Build: TBytes;
  end;

  /// <summary>
  /// Fluent facet for building a version 1 message. Exposes the in-message transaction
  /// config and deliberately omits address lookup tables (a version 0 concept).
  /// </summary>
  IMessageBuilderV1 = interface
    ['{8D4CBE63-6F2A-4B3C-9E7D-3A4B5C6D7E82}']
    function SetRecentBlockHash(const ARecentBlockHash: string): IMessageBuilderV1;
    function SetNonceInformation(const ANonceInfo: INonceInformation): IMessageBuilderV1;
    function SetFeePayer(const APublicKey: IPublicKey): IMessageBuilderV1;
    function AddInstruction(const AInstruction: ITransactionInstruction): IMessageBuilderV1;
    function SetTransactionConfig(const AConfig: TTransactionConfig): IMessageBuilderV1;
    function GetAccountMetaPublicKeys: TArray<string>;
    function Build: TBytes;
  end;

  /// <summary>
  /// Entry point for the message builders. As with <c>TTransactionBuilders</c>, selecting a
  /// version yields a builder whose surface exposes only the methods valid for that version.
  /// </summary>
  TMessageBuilders = class sealed
  public
    /// <summary>Creates a builder for a legacy (unversioned) message.</summary>
    class function Legacy: IMessageBuilderLegacy; static;
    /// <summary>Creates a builder for a version 0 message (address lookup tables).</summary>
    class function V0: IMessageBuilderV0; static;
    /// <summary>Creates a builder for a version 1 message (in-message transaction config).</summary>
    class function V1: IMessageBuilderV1; static;
  end;

  /// <summary>
  /// Internal factory for the concrete message builders. The transaction core and the
  /// transaction domain compile messages internally and construct these owners directly;
  /// external code builds messages through <see cref="TMessageBuilders"/>.
  /// </summary>
  TMessageBuilderFactory = class sealed
  public
    class function NewLegacy: IMessageBuilder; static;
    class function NewVersioned: IVersionedMessageBuilder; static;
  end;


implementation

type
  /// <summary>
  /// Concrete builder for legacy (unversioned) messages. Internal: constructed only through
  /// <see cref="TMessageBuilders"/> or <see cref="TMessageBuilderFactory"/>.
  /// </summary>
  TMessageBuilder = class(TInterfacedObject, IMessageBuilder)
  private
    FInstructions: TList<ITransactionInstruction>;
    FRecentBlockHash: string;
    FNonceInformation: INonceInformation;
    FPriorityFeesInformation: IPriorityFeesInformation;
    FFeePayer: IPublicKey;

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
    FMessageHeader: IMessageHeader;
    FAccountKeysList: TAccountKeysList;
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

  /// <summary>
  /// Concrete builder for versioned (v0/v1) messages. Internal: constructed only through
  /// <see cref="TMessageBuilders"/> or <see cref="TMessageBuilderFactory"/>.
  /// </summary>
  TVersionedMessageBuilder = class(TMessageBuilder, IVersionedMessageBuilder)
  private
    FAddressTableLookups: TList<IMessageAddressTableLookup>;
    FAccountKeys: TList<IPublicKey>;
    FVersion: Byte;
    FTransactionConfig: TTransactionConfig;

    function GetAddressTableLookups: TList<IMessageAddressTableLookup>;
    procedure SetAddressTableLookups(const AValue: TList<IMessageAddressTableLookup>);
    function GetAccountKeys: TList<IPublicKey>;
    procedure SetAccountKeys(const AValue: TList<IPublicKey>);
    function GetVersion: Byte;
    procedure SetVersion(const AValue: Byte);
    function GetTransactionConfig: TTransactionConfig;
    procedure SetTransactionConfig(const AValue: TTransactionConfig);
  public
    constructor Create; override;
    destructor Destroy; override;

    function Build: TBytes; override;

    property AddressTableLookups: TList<IMessageAddressTableLookup> read FAddressTableLookups write FAddressTableLookups;
    property AccountKeys: TList<IPublicKey> read FAccountKeys write FAccountKeys;
    property Version: Byte read FVersion write FVersion;
    property TransactionConfig: TTransactionConfig read FTransactionConfig write FTransactionConfig;
  end;

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

      LAccountKeysBufferSize := FAccountKeysList.Count * TPublicKey.PublicKeyLength;
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
          LEncodedRecentBlockhash := TBase58Encoder.DecodeData(FRecentBlockHash);
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

          Result := TArrayUtilities.StreamToBytes(LBuffer);
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
  LEncoded := TBase58Encoder.EncodeData(APublicKeyBytes);
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
  LKeysList: TList<IAccountMeta>;
  LFeePayerIndex: Integer;
begin
  Result := TList<IAccountMeta>.Create;
  LKeysList := FAccountKeysList.AccountList;

  try
    try
      LFeePayerIndex :=
        TListUtilities.FindIndex<IAccountMeta>(LKeysList,
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
  if Assigned(FTransactionConfig) then
    FTransactionConfig.Free;
  if Assigned(FAccountKeys) then
    FAccountKeys.Free;
  if Assigned(FAddressTableLookups) then
    FAddressTableLookups.Free;
  inherited;
end;

function TVersionedMessageBuilder.GetTransactionConfig: TTransactionConfig;
begin
  Result := FTransactionConfig;
end;

procedure TVersionedMessageBuilder.SetTransactionConfig(const AValue: TTransactionConfig);
begin
  TTransactionConfig.ReplaceOwned(FTransactionConfig, AValue);
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

function TVersionedMessageBuilder.GetVersion: Byte;
begin
  Result := FVersion;
end;

procedure TVersionedMessageBuilder.SetVersion(const AValue: Byte);
begin
  FVersion := AValue;
end;

function TVersionedMessageBuilder.Build: TBytes;
var
  LKeysMeta: TList<IAccountMeta>;
  LCompiledInstructions: TList<ICompiledInstruction>;
  LAccountKeys: TList<IPublicKey>;
  LAtl: TList<IMessageAddressTableLookup>;
  LInstruction: ITransactionInstruction;
  LKeyCount, LI: Integer;
  LKeyIndices: TBytes;
  LAM: IAccountMeta;
  LVersioned: IVersionedTransactionInstruction;
  LMessage: IVersionedMessage;
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
    // Build the message and let it own the collections we create here; the builder keeps its own
    // FAddressTableLookups / FTransactionConfig (fresh copies are handed to the message below).
    LMessage := TVersionedMessage.Create;
    LMessage.Version := FVersion;
    LMessage.Header := FMessageHeader;
    LMessage.RecentBlockhash := FRecentBlockHash;

    LCompiledInstructions := TList<ICompiledInstruction>.Create;
    LMessage.Instructions := LCompiledInstructions;
    LAccountKeys := TList<IPublicKey>.Create;
    LMessage.AccountKeys := LAccountKeys;
    LAtl := TList<IMessageAddressTableLookup>.Create;
    LMessage.AddressTableLookups := LAtl;

    for LInstruction in FInstructions do
    begin
      LKeyCount := LInstruction.Keys.Count;

      if Supports(LInstruction, IVersionedTransactionInstruction, LVersioned) then
        LKeyIndices := LVersioned.KeyIndices
      else
      begin
        SetLength(LKeyIndices, LKeyCount);
        for LI := 0 to LKeyCount - 1 do
          LKeyIndices[LI] := FindAccountIndex(LKeysMeta, LInstruction.Keys[LI].PublicKey.Key);
      end;

      LCompiledInstructions.Add(TCompiledInstruction.Create(
        FindAccountIndex(LKeysMeta, LInstruction.ProgramId),
        TShortVectorEncoding.EncodeLength(LKeyCount),
        LKeyIndices,
        TShortVectorEncoding.EncodeLength(Length(LInstruction.Data)),
        LInstruction.Data));
    end;

    for LAM in LKeysMeta do
    begin
      LAccountKeys.Add(LAM.PublicKey);

      if LAM.IsSigner then
      begin
        FMessageHeader.RequiredSignatures := FMessageHeader.RequiredSignatures + 1;
        if not LAM.IsWritable then
          FMessageHeader.ReadOnlySignedAccounts := FMessageHeader.ReadOnlySignedAccounts + 1;
      end
      else if not LAM.IsWritable then
        FMessageHeader.ReadOnlyUnsignedAccounts := FMessageHeader.ReadOnlyUnsignedAccounts + 1;
    end;

    // Copy the address table lookups (v0) so the message owns its own list.
    if Assigned(FAddressTableLookups) then
      LAtl.AddRange(FAddressTableLookups);

    // Copy the transaction config (v1) so the message owns its own instance.
    if Assigned(FTransactionConfig) then
      LMessage.TransactionConfig := FTransactionConfig.Clone;

    // Serialize dispatches on Version (v0 = ALT trailer, v1 = in-message config).
    Result := LMessage.Serialize;
  finally
    LKeysMeta.Free;
  end;
end;

{ Message builder facets }

type
  TMessageBuilderLegacyFacet = class sealed(TInterfacedObject, IMessageBuilderLegacy)
  private
    FOwner: IMessageBuilder;
  public
    constructor Create(const AOwner: IMessageBuilder);
    function SetRecentBlockHash(const ARecentBlockHash: string): IMessageBuilderLegacy;
    function SetNonceInformation(const ANonceInfo: INonceInformation): IMessageBuilderLegacy;
    function SetPriorityFeesInformation(const APriorityFeesInfo: IPriorityFeesInformation): IMessageBuilderLegacy;
    function SetFeePayer(const APublicKey: IPublicKey): IMessageBuilderLegacy;
    function AddInstruction(const AInstruction: ITransactionInstruction): IMessageBuilderLegacy;
    function GetAccountMetaPublicKeys: TArray<string>;
    function Build: TBytes;
  end;

  TMessageBuilderV0Facet = class sealed(TInterfacedObject, IMessageBuilderV0)
  private
    FOwner: IVersionedMessageBuilder;
  public
    constructor Create(const AOwner: IVersionedMessageBuilder);
    function SetRecentBlockHash(const ARecentBlockHash: string): IMessageBuilderV0;
    function SetNonceInformation(const ANonceInfo: INonceInformation): IMessageBuilderV0;
    function SetPriorityFeesInformation(const APriorityFeesInfo: IPriorityFeesInformation): IMessageBuilderV0;
    function SetFeePayer(const APublicKey: IPublicKey): IMessageBuilderV0;
    function AddInstruction(const AInstruction: ITransactionInstruction): IMessageBuilderV0;
    function AddAddressTableLookup(const ALookup: IMessageAddressTableLookup): IMessageBuilderV0;
    function AddAddressTableLookups(const ALookups: TList<IMessageAddressTableLookup>): IMessageBuilderV0;
    function GetAccountMetaPublicKeys: TArray<string>;
    function Build: TBytes;
  end;

  TMessageBuilderV1Facet = class sealed(TInterfacedObject, IMessageBuilderV1)
  private
    FOwner: IVersionedMessageBuilder;
  public
    constructor Create(const AOwner: IVersionedMessageBuilder);
    function SetRecentBlockHash(const ARecentBlockHash: string): IMessageBuilderV1;
    function SetNonceInformation(const ANonceInfo: INonceInformation): IMessageBuilderV1;
    function SetFeePayer(const APublicKey: IPublicKey): IMessageBuilderV1;
    function AddInstruction(const AInstruction: ITransactionInstruction): IMessageBuilderV1;
    function SetTransactionConfig(const AConfig: TTransactionConfig): IMessageBuilderV1;
    function GetAccountMetaPublicKeys: TArray<string>;
    function Build: TBytes;
  end;

{ TMessageBuilderLegacyFacet }

constructor TMessageBuilderLegacyFacet.Create(const AOwner: IMessageBuilder);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TMessageBuilderLegacyFacet.AddInstruction(const AInstruction: ITransactionInstruction): IMessageBuilderLegacy;
begin
  FOwner.AddInstruction(AInstruction);
  Result := Self;
end;

function TMessageBuilderLegacyFacet.Build: TBytes;
begin
  Result := FOwner.Build;
end;

function TMessageBuilderLegacyFacet.GetAccountMetaPublicKeys: TArray<string>;
begin
  Result := FOwner.GetAccountMetaPublicKeys;
end;

function TMessageBuilderLegacyFacet.SetFeePayer(const APublicKey: IPublicKey): IMessageBuilderLegacy;
begin
  FOwner.FeePayer := APublicKey;
  Result := Self;
end;

function TMessageBuilderLegacyFacet.SetNonceInformation(const ANonceInfo: INonceInformation): IMessageBuilderLegacy;
begin
  FOwner.NonceInformation := ANonceInfo;
  Result := Self;
end;

function TMessageBuilderLegacyFacet.SetPriorityFeesInformation(const APriorityFeesInfo: IPriorityFeesInformation): IMessageBuilderLegacy;
begin
  FOwner.PriorityFeesInformation := APriorityFeesInfo;
  Result := Self;
end;

function TMessageBuilderLegacyFacet.SetRecentBlockHash(const ARecentBlockHash: string): IMessageBuilderLegacy;
begin
  FOwner.RecentBlockHash := ARecentBlockHash;
  Result := Self;
end;

{ TMessageBuilderV0Facet }

constructor TMessageBuilderV0Facet.Create(const AOwner: IVersionedMessageBuilder);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TMessageBuilderV0Facet.AddAddressTableLookup(const ALookup: IMessageAddressTableLookup): IMessageBuilderV0;
begin
  FOwner.AddressTableLookups.Add(ALookup);
  Result := Self;
end;

function TMessageBuilderV0Facet.AddAddressTableLookups(const ALookups: TList<IMessageAddressTableLookup>): IMessageBuilderV0;
begin
  FOwner.AddressTableLookups.AddRange(ALookups);
  Result := Self;
end;

function TMessageBuilderV0Facet.AddInstruction(const AInstruction: ITransactionInstruction): IMessageBuilderV0;
begin
  FOwner.AddInstruction(AInstruction);
  Result := Self;
end;

function TMessageBuilderV0Facet.Build: TBytes;
begin
  Result := FOwner.Build;
end;

function TMessageBuilderV0Facet.GetAccountMetaPublicKeys: TArray<string>;
begin
  Result := FOwner.GetAccountMetaPublicKeys;
end;

function TMessageBuilderV0Facet.SetFeePayer(const APublicKey: IPublicKey): IMessageBuilderV0;
begin
  FOwner.FeePayer := APublicKey;
  Result := Self;
end;

function TMessageBuilderV0Facet.SetNonceInformation(const ANonceInfo: INonceInformation): IMessageBuilderV0;
begin
  FOwner.NonceInformation := ANonceInfo;
  Result := Self;
end;

function TMessageBuilderV0Facet.SetPriorityFeesInformation(const APriorityFeesInfo: IPriorityFeesInformation): IMessageBuilderV0;
begin
  FOwner.PriorityFeesInformation := APriorityFeesInfo;
  Result := Self;
end;

function TMessageBuilderV0Facet.SetRecentBlockHash(const ARecentBlockHash: string): IMessageBuilderV0;
begin
  FOwner.RecentBlockHash := ARecentBlockHash;
  Result := Self;
end;

{ TMessageBuilderV1Facet }

constructor TMessageBuilderV1Facet.Create(const AOwner: IVersionedMessageBuilder);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TMessageBuilderV1Facet.AddInstruction(const AInstruction: ITransactionInstruction): IMessageBuilderV1;
begin
  FOwner.AddInstruction(AInstruction);
  Result := Self;
end;

function TMessageBuilderV1Facet.Build: TBytes;
begin
  Result := FOwner.Build;
end;

function TMessageBuilderV1Facet.GetAccountMetaPublicKeys: TArray<string>;
begin
  Result := FOwner.GetAccountMetaPublicKeys;
end;

function TMessageBuilderV1Facet.SetFeePayer(const APublicKey: IPublicKey): IMessageBuilderV1;
begin
  FOwner.FeePayer := APublicKey;
  Result := Self;
end;

function TMessageBuilderV1Facet.SetNonceInformation(const ANonceInfo: INonceInformation): IMessageBuilderV1;
begin
  FOwner.NonceInformation := ANonceInfo;
  Result := Self;
end;

function TMessageBuilderV1Facet.SetRecentBlockHash(const ARecentBlockHash: string): IMessageBuilderV1;
begin
  FOwner.RecentBlockHash := ARecentBlockHash;
  Result := Self;
end;

function TMessageBuilderV1Facet.SetTransactionConfig(const AConfig: TTransactionConfig): IMessageBuilderV1;
begin
  FOwner.TransactionConfig := AConfig;
  Result := Self;
end;

{ TMessageBuilderFactory }

class function TMessageBuilderFactory.NewLegacy: IMessageBuilder;
begin
  Result := TMessageBuilder.Create;
end;

class function TMessageBuilderFactory.NewVersioned: IVersionedMessageBuilder;
begin
  Result := TVersionedMessageBuilder.Create;
end;

{ TMessageBuilders }

class function TMessageBuilders.Legacy: IMessageBuilderLegacy;
begin
  Result := TMessageBuilderLegacyFacet.Create(TMessageBuilder.Create);
end;

class function TMessageBuilders.V0: IMessageBuilderV0;
var
  LOwner: IVersionedMessageBuilder;
begin
  LOwner := TVersionedMessageBuilder.Create;
  LOwner.Version := 0;
  Result := TMessageBuilderV0Facet.Create(LOwner);
end;

class function TMessageBuilders.V1: IMessageBuilderV1;
var
  LOwner: IVersionedMessageBuilder;
begin
  LOwner := TVersionedMessageBuilder.Create;
  LOwner.Version := 1;
  Result := TMessageBuilderV1Facet.Create(LOwner);
end;

end.

