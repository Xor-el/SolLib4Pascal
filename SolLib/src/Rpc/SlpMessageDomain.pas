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

unit SlpMessageDomain;

{$I ../Include/SolLib.inc}

interface

uses
  SysUtils,
  Classes,
  Generics.Collections,
  SlpPublicKey,
  SlpShortVectorEncoding,
  SlpDataEncoderUtilities,
  SlpTransactionInstruction,
  SlpTransactionConfig,
  SlpSerialization,
  SlpDeserialization,
  SlpArrayUtilities;

type

  IMessageHeader = interface
    ['{2F8B0C0A-1355-49A7-B98E-98B0E4AE7A9F}']
    function GetRequiredSignatures: Byte;
    procedure SetRequiredSignatures(const AValue: Byte);
    function GetReadOnlySignedAccounts: Byte;
    procedure SetReadOnlySignedAccounts(const AValue: Byte);
    function GetReadOnlyUnsignedAccounts: Byte;
    procedure SetReadOnlyUnsignedAccounts(const AValue: Byte);

    /// <summary>
    /// Convert the message header to byte array format.
    /// </summary>
    function ToBytes: TBytes;

    /// <summary>
    /// The number of required signatures.
    /// </summary>
    property RequiredSignatures: Byte read GetRequiredSignatures write SetRequiredSignatures;
     /// <summary>
    /// The number of read-only signed accounts.
    /// </summary>
    property ReadOnlySignedAccounts: Byte read GetReadOnlySignedAccounts write SetReadOnlySignedAccounts;
    /// <summary>
    /// The number of read-only non-signed accounts.
    /// </summary>
    property ReadOnlyUnsignedAccounts: Byte read GetReadOnlyUnsignedAccounts write SetReadOnlyUnsignedAccounts;
  end;

  IMessage = interface
    ['{C0E1C3F6-5C8E-4B0A-9E9B-2F5C5F6D2C9E}']
    function GetHeader: IMessageHeader;
    procedure SetHeader(const AValue: IMessageHeader);
    function GetAccountKeys: TList<IPublicKey>;
    procedure SetAccountKeys(const AValue: TList<IPublicKey>);
    function GetInstructions: TList<ICompiledInstruction>;
    procedure SetInstructions(const AValue: TList<ICompiledInstruction>);
    function GetRecentBlockhash: string;
    procedure SetRecentBlockhash(const AValue: string);

    /// <summary>
    /// Check whether an account is writable.
    /// </summary>
    /// <param name="index">The index of the account in the account keys.</param>
    /// <returns>true if the account is writable, false otherwise.</returns>
    function IsAccountWritable(AIndex: Integer): Boolean;
    /// <summary>
    /// Check whether an account is a signer.
    /// </summary>
    /// <param name="index">The index of the account in the account keys.</param>
    /// <returns>true if the account is an expected signer, false otherwise.</returns>
    function IsAccountSigner(AIndex: Integer): Boolean;
    /// <summary>
    /// Serialize the message into the wire format.
    /// </summary>
    /// <returns>A byte array corresponding to the serialized message.</returns>
    function Serialize: TBytes;

    /// <summary>
    /// The header of the <see cref="TMessage"/>.
    /// </summary>
    property Header: IMessageHeader read GetHeader write SetHeader;
    /// <summary>
    /// The list of account <see cref="IPublicKey"/>s present in the transaction.
    /// </summary>
    property AccountKeys: TList<IPublicKey> read GetAccountKeys write SetAccountKeys;
    /// <summary>
    /// The list of <see cref="TCompiledInstruction"/>s present in the transaction.
    /// </summary>
    property Instructions: TList<ICompiledInstruction> read GetInstructions write SetInstructions;
    /// <summary>
    /// The recent block hash for the transaction.
    /// </summary>
    property RecentBlockhash: string read GetRecentBlockhash write SetRecentBlockhash;
  end;

  IMessageAddressTableLookup = interface
    ['{B4E8D6F0-6E9C-46E3-82B5-0D96A6F3B1E0}']
    function GetAccountKey: IPublicKey;
    procedure SetAccountKey(const AValue: IPublicKey);
    function GetWritableIndexes: TBytes;
    procedure SetWritableIndexes(const AValue: TBytes);
    function GetReadonlyIndexes: TBytes;
    procedure SetReadonlyIndexes(const AValue: TBytes);

    function Clone: IMessageAddressTableLookup;
    /// <summary>
    /// Account Key
    /// </summary>
    property AccountKey: IPublicKey read GetAccountKey write SetAccountKey;
    /// <summary>
    /// Writable indexes
    /// </summary>
    property WritableIndexes: TBytes read GetWritableIndexes write SetWritableIndexes;
    /// <summary>
    /// Read only indexes
    /// </summary>
    property ReadonlyIndexes: TBytes read GetReadonlyIndexes write SetReadonlyIndexes;
  end;

  IVersionedMessage = interface(IMessage)
    ['{3B1B9D03-0F7E-4A26-9B9E-9907A2C4C91D}']
    function GetAddressTableLookups: TList<IMessageAddressTableLookup>;
    procedure SetAddressTableLookups(const AValue: TList<IMessageAddressTableLookup>);
    function GetVersion: Byte;
    procedure SetVersion(const AValue: Byte);
    function GetTransactionConfig: TTransactionConfig;
    procedure SetTransactionConfig(const AValue: TTransactionConfig);

    property AddressTableLookups: TList<IMessageAddressTableLookup> read GetAddressTableLookups write SetAddressTableLookups;
    /// <summary>
    /// The message version encoded in the low 7 bits of the versioned prefix.
    /// </summary>
    property Version: Byte read GetVersion write SetVersion;
    /// <summary>
    /// The in-message transaction configuration (version 1 only).
    /// </summary>
    property TransactionConfig: TTransactionConfig read GetTransactionConfig write SetTransactionConfig;
  end;

  /// <summary>
  /// The message header
  /// </summary>
  TMessageHeader = class(TInterfacedObject, IMessageHeader)
  private
    FRequiredSignatures: Byte;
    FReadOnlySignedAccounts: Byte;
    FReadOnlyUnsignedAccounts: Byte;

    function GetRequiredSignatures: Byte;
    procedure SetRequiredSignatures(const AValue: Byte);
    function GetReadOnlySignedAccounts: Byte;
    procedure SetReadOnlySignedAccounts(const AValue: Byte);
    function GetReadOnlyUnsignedAccounts: Byte;
    procedure SetReadOnlyUnsignedAccounts(const AValue: Byte);

    function ToBytes: TBytes;
  public
  type
    /// <summary>
    /// Represents the layout of the <see cref="TMessageHeader"/> encoded values.
    /// </summary>
    TLayout = record
    public
    /// <summary>
    /// The offset at which the byte that defines the number of required signatures begins.
    /// </summary>
      const
      RequiredSignaturesOffset = 0;

      /// <summary>
      /// The offset at which the byte that defines the number of read-only signer accounts begins.
      /// </summary>
    const
      ReadOnlySignedAccountsOffset = 1;

      /// <summary>
      /// The offset at which the byte that defines the number of read-only non-signer accounts begins.
      /// </summary>
    const
      ReadOnlyUnsignedAccountsOffset = 2;

      /// <summary>
      /// The message header length.
      /// </summary>
    const
      HeaderLength = 3;
    end;

  end;

  /// <summary>
  /// Represents the Message of a Solana <see cref="Transaction"/>.
  /// </summary>
  TMessage = class(TInterfacedObject, IMessage)
  private
    FHeader: IMessageHeader;
    FAccountKeys: TList<IPublicKey>;
    FInstructions: TList<ICompiledInstruction>;
    FRecentBlockhash: string;

    function GetHeader: IMessageHeader;
    procedure SetHeader(const AValue: IMessageHeader);
    function GetAccountKeys: TList<IPublicKey>;
    procedure SetAccountKeys(const AValue: TList<IPublicKey>);
    function GetInstructions: TList<ICompiledInstruction>;
    procedure SetInstructions(const AValue: TList<ICompiledInstruction>);
    function GetRecentBlockhash: string;
    procedure SetRecentBlockhash(const AValue: string);

    function IsAccountWritable(AIndex: Integer): Boolean;
    function IsAccountSigner(AIndex: Integer): Boolean;
    function Serialize: TBytes; virtual;
  protected
    /// <summary>
    /// Internal virtual deserialization hook — subclasses override this to provide their parser.
    /// </summary>
    class function DoDeserialize(const AData: TBytes): IMessage; virtual;

    /// <summary>
    /// Writes the shared message body — header, account keys, blockhash and compiled
    /// instructions — to <paramref name="AStream"/>. This layout is identical for legacy
    /// and version 0 messages; the versioned prefix and address-table-lookup trailer are
    /// written by the version 0 serializer around this body.
    /// </summary>
    procedure WriteMessageBody(const AStream: TStream);

    /// <summary>
    /// Reads the shared message body from <paramref name="ABody"/> (which starts at the
    /// message header, i.e. after any versioned prefix), populating
    /// <paramref name="AMessage"/>'s header, account keys, blockhash and instructions.
    /// Returns the offset within <paramref name="ABody"/> immediately after the last
    /// instruction, which the version 0 parser uses to locate the lookup-table trailer.
    /// </summary>
    class function ReadMessageBody(const ABody: TBytes; const AMessage: IMessage): Integer; static;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    class function Deserialize(const AData: TBytes): IMessage; overload;
    class function Deserialize(const ABase64: string): IMessage; overload;
  end;

type
  /// <summary>
  /// Versioned Message
  /// </summary>
  TVersionedMessage = class(TMessage, IVersionedMessage)
  public
    const VersionPrefixMask = $7F;
    const VersionPrefixBit = $80;

    /// <summary>True when a message/transaction prefix byte carries the versioned high bit.</summary>
    class function IsVersioned(APrefix: Byte): Boolean; static; inline;
    /// <summary>Builds the versioned prefix byte (high bit set) for the given version.</summary>
    class function EncodeVersionPrefix(AVersion: Byte): Byte; static; inline;
    /// <summary>Extracts the version number from a versioned prefix byte.</summary>
    class function DecodeVersion(APrefix: Byte): Byte; static; inline;
  type
    TMessageAddressTableLookup = class(TInterfacedObject, IMessageAddressTableLookup)
    private
      FAccountKey: IPublicKey;
      FWritableIndexes, FReadonlyIndexes: TBytes;

      function GetAccountKey: IPublicKey;
      procedure SetAccountKey(const AValue: IPublicKey);
      function GetWritableIndexes: TBytes;
      procedure SetWritableIndexes(const AValue: TBytes);
      function GetReadonlyIndexes: TBytes;
      procedure SetReadonlyIndexes(const AValue: TBytes);

      function Clone: IMessageAddressTableLookup;

      public
        constructor Create;

    end;

  private
    FAddressTableLookups: TList<IMessageAddressTableLookup>;
    FVersion: Byte;
    FTransactionConfig: TTransactionConfig;
    function GetAddressTableLookups: TList<IMessageAddressTableLookup>;
    procedure SetAddressTableLookups(const AValue: TList<IMessageAddressTableLookup>);
    function GetVersion: Byte;
    procedure SetVersion(const AValue: Byte);
    function GetTransactionConfig: TTransactionConfig;
    procedure SetTransactionConfig(const AValue: TTransactionConfig);

    /// <summary>Serialize a version 0 message (dynamic prefix + address-table-lookup trailer).</summary>
    function SerializeV0: TBytes;
    /// <summary>Serialize a version 1 message (in-message transaction config; SIMD-0385).</summary>
    function SerializeV1: TBytes;

    class function DeserializeV0(const AData: TBytes): IMessage; static;
    class function DeserializeV1(const AData: TBytes): IMessage; static;
  protected
    class function DoDeserialize(const AData: TBytes): IMessage; override;
  public
    constructor Create; override;
    destructor Destroy; override;

    /// <summary>
    /// Serialize the versioned message into the wire format, dispatching on <c>Version</c>.
    /// </summary>
    function Serialize: TBytes; override;

    /// <summary>The address table lookups (version 0 only).</summary>
    property AddressTableLookups: TList<IMessageAddressTableLookup> read GetAddressTableLookups write SetAddressTableLookups;
    /// <summary>The in-message transaction configuration (version 1 only).</summary>
    property TransactionConfig: TTransactionConfig read GetTransactionConfig write SetTransactionConfig;

    /// <summary>
    /// Deserialize the message version
    /// </summary>
    /// <param name="SerializedMessage"></param>
    /// <returns></returns>
    class function DeserializeMessageVersion(const ASerializedMessage: TBytes): string; static;

  type
    TAddressTableLookupUtils = record
    public
      class function SerializeAddressTableLookups(AList: TList<IMessageAddressTableLookup>): TBytes; static;
    end;
  end;

  /// <summary>
  /// Represents a version 0 message.
  /// </summary>
  TMessageV0 = class(TVersionedMessage)
  public
    constructor Create; override;
  end;

  /// <summary>
  /// Represents a version 1 message.
  /// </summary>
  TMessageV1 = class(TVersionedMessage)
  public
    constructor Create; override;
  end;

implementation

{ TMessageHeader }

function TMessageHeader.GetReadOnlySignedAccounts: Byte;
begin
  Result := FReadOnlySignedAccounts;
end;

function TMessageHeader.GetReadOnlyUnsignedAccounts: Byte;
begin
  Result := FReadOnlyUnsignedAccounts;
end;

function TMessageHeader.GetRequiredSignatures: Byte;
begin
  Result := FRequiredSignatures;
end;

procedure TMessageHeader.SetReadOnlySignedAccounts(const AValue: Byte);
begin
  FReadOnlySignedAccounts := AValue;
end;

procedure TMessageHeader.SetReadOnlyUnsignedAccounts(const AValue: Byte);
begin
  FReadOnlyUnsignedAccounts := AValue;
end;

procedure TMessageHeader.SetRequiredSignatures(const AValue: Byte);
begin
  FRequiredSignatures := AValue;
end;

function TMessageHeader.ToBytes: TBytes;
begin
  SetLength(Result, 3);
  Result[0] := FRequiredSignatures;
  Result[1] := FReadOnlySignedAccounts;
  Result[2] := FReadOnlyUnsignedAccounts;
end;

{ TMessage }

constructor TMessage.Create;
begin
  inherited Create;
  FHeader := nil;
  FAccountKeys := nil;
  FInstructions := nil;
  FRecentBlockhash := '';
end;

destructor TMessage.Destroy;
begin
  if Assigned(FInstructions) then
    FInstructions.Free;
  if Assigned(FAccountKeys) then
    FAccountKeys.Free;
  inherited;
end;

function TMessage.GetAccountKeys: TList<IPublicKey>;
begin
  Result := FAccountKeys;
end;

function TMessage.GetHeader: IMessageHeader;
begin
  Result := FHeader;
end;

function TMessage.GetInstructions: TList<ICompiledInstruction>;
begin
  Result := FInstructions;
end;

function TMessage.GetRecentBlockhash: string;
begin
  Result := FRecentBlockhash;
end;

procedure TMessage.SetAccountKeys(const AValue: TList<IPublicKey>);
begin
  FAccountKeys := AValue;
end;

procedure TMessage.SetHeader(const AValue: IMessageHeader);
begin
  FHeader := AValue;
end;

procedure TMessage.SetInstructions(const AValue: TList<ICompiledInstruction>);
begin
  FInstructions := AValue;
end;

procedure TMessage.SetRecentBlockhash(const AValue: string);
begin
  FRecentBlockhash := AValue;
end;

function TMessage.IsAccountSigner(AIndex: Integer): Boolean;
begin
  Result := AIndex < FHeader.RequiredSignatures;
end;

function TMessage.IsAccountWritable(AIndex: Integer): Boolean;
begin
  Result := (AIndex < (FHeader.RequiredSignatures - FHeader.ReadOnlySignedAccounts)) or
            ((AIndex >= FHeader.RequiredSignatures) and
             (AIndex < (FAccountKeys.Count - FHeader.ReadOnlyUnsignedAccounts)));
end;

procedure TMessage.WriteMessageBody(const AStream: TStream);
var
  LAccountAddressesLength, LInstructionsLength, LAccountKeyBytes, LHdr, LBlockHashBytes: TBytes;
  LI: Integer;
  LCI: ICompiledInstruction;
  LProgramIdIndex: Byte;
begin
  LHdr := FHeader.ToBytes();
  AStream.WriteBuffer(LHdr[0], Length(LHdr));

  LAccountAddressesLength := TShortVectorEncoding.EncodeLength(FAccountKeys.Count);
  AStream.WriteBuffer(LAccountAddressesLength[0], Length(LAccountAddressesLength));

  for LI := 0 to FAccountKeys.Count - 1 do
  begin
    LAccountKeyBytes := FAccountKeys[LI].KeyBytes;
    AStream.WriteBuffer(LAccountKeyBytes[0], Length(LAccountKeyBytes));
  end;

  LBlockHashBytes := TBase58Encoder.DecodeData(FRecentBlockhash);
  AStream.WriteBuffer(LBlockHashBytes[0], Length(LBlockHashBytes));

  LInstructionsLength := TShortVectorEncoding.EncodeLength(FInstructions.Count);
  AStream.WriteBuffer(LInstructionsLength[0], Length(LInstructionsLength));

  for LI := 0 to FInstructions.Count - 1 do
  begin
    LCI := FInstructions[LI];

    LProgramIdIndex := LCI.ProgramIdIndex;
    AStream.WriteBuffer(LProgramIdIndex, SizeOf(LProgramIdIndex));

    AStream.WriteBuffer(LCI.KeyIndicesCount[0], Length(LCI.KeyIndicesCount));
    AStream.WriteBuffer(LCI.KeyIndices[0], Length(LCI.KeyIndices));
    AStream.WriteBuffer(LCI.DataLength[0], Length(LCI.DataLength));
    AStream.WriteBuffer(LCI.Data[0], Length(LCI.Data));
  end;
end;

function TMessage.Serialize: TBytes;
var
  LMsgBuf: TMemoryStream;
begin
  LMsgBuf := TMemoryStream.Create;
  try
    WriteMessageBody(LMsgBuf);
    Result := TArrayUtilities.StreamToBytes(LMsgBuf);
  finally
    LMsgBuf.Free;
  end;
end;

class function TMessage.Deserialize(const ABase64: string): IMessage;
var
  LBytes: TBytes;
begin
  if ABase64 = '' then
    raise EArgumentNilException.Create('data');

  try
    LBytes := TBase64Encoder.DecodeData(ABase64);
  except
    on E: Exception do
      raise Exception.Create('could not decode message data from base64');
  end;

  Result := Deserialize(LBytes);
end;

class function TMessage.Deserialize(const AData: TBytes): IMessage;
begin
  // Polymorphic dispatch to this class' implementation. Overrides will be used.
  Result := DoDeserialize(AData);
end;

class function TMessage.ReadMessageBody(const ABody: TBytes; const AMessage: IMessage): Integer;
const
  PKLen = TPublicKey.PublicKeyLength;
  HLen = TMessageHeader.TLayout.HeaderLength;
  SvesLen = TShortVectorEncoding.SpanLength;
var
  LAccLenSlice, LKeySlice, LBlockHashSlice, LInstrLenSlice, LInstrData: TBytes;
  LAccLenDec, LInstrLenDec: TShortVecDecode;
  LAccountAddressLength, LAccountAddressLengthEncodedLength: Integer;
  LInstructionsLength, LInstructionsLengthEncodedLength, LInstructionsOffset: Integer;
  LInstructionsDataLength, LI: Integer;
  LCId: TCompiledInstructionDecode;
begin
  // Header
  AMessage.Header := TMessageHeader.Create;
  AMessage.Header.RequiredSignatures := ABody[TMessageHeader.TLayout.RequiredSignaturesOffset];
  AMessage.Header.ReadOnlySignedAccounts := ABody[TMessageHeader.TLayout.ReadOnlySignedAccountsOffset];
  AMessage.Header.ReadOnlyUnsignedAccounts := ABody[TMessageHeader.TLayout.ReadOnlyUnsignedAccountsOffset];

  AMessage.AccountKeys := TList<IPublicKey>.Create;
  AMessage.Instructions := TList<ICompiledInstruction>.Create;

  // Account keys
  LAccLenSlice := TArrayUtilities.Slice<Byte>(ABody, HLen, SvesLen);
  LAccLenDec := TShortVectorEncoding.DecodeLength(LAccLenSlice);
  LAccountAddressLength := LAccLenDec.Value;
  LAccountAddressLengthEncodedLength := LAccLenDec.Length;

  for LI := 0 to LAccountAddressLength - 1 do
  begin
    LKeySlice := TArrayUtilities.Slice<Byte>(
      ABody,
      HLen + LAccountAddressLengthEncodedLength + LI * PKLen,
      PKLen
    );
    AMessage.AccountKeys.Add(TPublicKey.Create(LKeySlice));
  end;

  // Blockhash
  LBlockHashSlice := TArrayUtilities.Slice<Byte>(
    ABody,
    HLen + LAccountAddressLengthEncodedLength + LAccountAddressLength * PKLen,
    PKLen
  );
  AMessage.RecentBlockhash := TBase58Encoder.EncodeData(LBlockHashSlice);

  // Instructions
  LInstrLenSlice := TArrayUtilities.Slice<Byte>(
    ABody,
    HLen + LAccountAddressLengthEncodedLength + (LAccountAddressLength * PKLen) + PKLen,
    SvesLen
  );
  LInstrLenDec := TShortVectorEncoding.DecodeLength(LInstrLenSlice);
  LInstructionsLength := LInstrLenDec.Value;
  LInstructionsLengthEncodedLength := LInstrLenDec.Length;

  LInstructionsOffset :=
    HLen +
    LAccountAddressLengthEncodedLength +
    (LAccountAddressLength * PKLen) +
    PKLen +
    LInstructionsLengthEncodedLength;

  LInstrData := TArrayUtilities.Slice<Byte>(ABody, LInstructionsOffset);
  LInstructionsDataLength := 0;

  for LI := 0 to LInstructionsLength - 1 do
  begin
    LCId := TCompiledInstruction.Deserialize(LInstrData);
    AMessage.Instructions.Add(LCId.Instruction);
    LInstrData := TArrayUtilities.Slice<Byte>(LInstrData, LCId.Length);
    Inc(LInstructionsDataLength, LCId.Length);
  end;

  // Offset (within ABody) immediately after the last instruction.
  Result := LInstructionsOffset + LInstructionsDataLength;
end;

class function TMessage.DoDeserialize(const AData: TBytes): IMessage;
begin
  if Length(AData) = 0 then
    raise Exception.Create('Empty message');

  // Check that the message is not a TVersionedMessage
  if TVersionedMessage.IsVersioned(AData[0]) then
    raise ENotSupportedException.Create(
      'The message is a VersionedMessage, use TVersionedMessage.Deserialize instead.'
    );

  Result := TMessage.Create;
  ReadMessageBody(AData, Result);
end;

{ TVersionedMessage }

class function TVersionedMessage.IsVersioned(APrefix: Byte): Boolean;
begin
  Result := (APrefix and VersionPrefixBit) <> 0;
end;

class function TVersionedMessage.EncodeVersionPrefix(AVersion: Byte): Byte;
begin
  Result := Byte(VersionPrefixBit or AVersion);
end;

class function TVersionedMessage.DecodeVersion(APrefix: Byte): Byte;
begin
  Result := APrefix and VersionPrefixMask;
end;

{ TVersionedMessage.TMessageAddressTableLookup }

constructor TVersionedMessage.TMessageAddressTableLookup.Create;
begin
  inherited Create;
  FAccountKey := nil;
  FWritableIndexes := nil;
  FReadonlyIndexes := nil;
end;

function TVersionedMessage.TMessageAddressTableLookup.Clone: IMessageAddressTableLookup;
var
  LCopyLkp: TVersionedMessage.TMessageAddressTableLookup;
begin
  LCopyLkp := TVersionedMessage.TMessageAddressTableLookup.Create;
  LCopyLkp.FAccountKey := FAccountKey.Clone;
  LCopyLkp.FWritableIndexes := TArrayUtilities.Copy<Byte>(FWritableIndexes);
  LCopyLkp.FReadonlyIndexes := TArrayUtilities.Copy<Byte>(FReadonlyIndexes);
  Result := LCopyLkp;
end;

function TVersionedMessage.TMessageAddressTableLookup.GetAccountKey: IPublicKey;
begin
  Result := FAccountKey;
end;

function TVersionedMessage.TMessageAddressTableLookup.GetReadonlyIndexes: TBytes;
begin
  Result := FReadonlyIndexes;
end;

function TVersionedMessage.TMessageAddressTableLookup.GetWritableIndexes: TBytes;
begin
  Result := FWritableIndexes;
end;

procedure TVersionedMessage.TMessageAddressTableLookup.SetAccountKey(const AValue: IPublicKey);
begin
  FAccountKey := AValue;
end;

procedure TVersionedMessage.TMessageAddressTableLookup.SetReadonlyIndexes(const AValue: TBytes);
begin
  FReadonlyIndexes := AValue;
end;

procedure TVersionedMessage.TMessageAddressTableLookup.SetWritableIndexes(const AValue: TBytes);
begin
  FWritableIndexes := AValue;
end;

{ TVersionedMessage }

constructor TVersionedMessage.Create;
begin
  inherited Create;
  FAddressTableLookups := nil;
  FTransactionConfig := nil;
end;

destructor TVersionedMessage.Destroy;
begin
  if Assigned(FTransactionConfig) then
    FTransactionConfig.Free;
  if Assigned(FAddressTableLookups) then
    FAddressTableLookups.Free;
  inherited;
end;

function TVersionedMessage.GetAddressTableLookups: TList<IMessageAddressTableLookup>;
begin
  Result := FAddressTableLookups;
end;

procedure TVersionedMessage.SetAddressTableLookups(const AValue: TList<IMessageAddressTableLookup>);
begin
  FAddressTableLookups := AValue;
end;

function TVersionedMessage.GetVersion: Byte;
begin
  Result := FVersion;
end;

procedure TVersionedMessage.SetVersion(const AValue: Byte);
begin
  FVersion := AValue;
end;

function TVersionedMessage.GetTransactionConfig: TTransactionConfig;
begin
  Result := FTransactionConfig;
end;

procedure TVersionedMessage.SetTransactionConfig(const AValue: TTransactionConfig);
begin
  TTransactionConfig.ReplaceOwned(FTransactionConfig, AValue);
end;

function TVersionedMessage.Serialize: TBytes;
begin
  case FVersion of
    0: Result := SerializeV0;
    1: Result := SerializeV1;
  else
    raise ENotSupportedException.CreateFmt('Version %d is not supported for serialization.', [FVersion]);
  end;
end;

function TVersionedMessage.SerializeV0: TBytes;
var
  LMsgBuf: TMemoryStream;
  LAtlBytes: TBytes;
  LVersionPrefix: Byte;
begin
  LMsgBuf := TMemoryStream.Create;
  try
    // Versioned prefix: high bit set, low 7 bits carry the version.
    LVersionPrefix := EncodeVersionPrefix(FVersion);
    LMsgBuf.WriteBuffer(LVersionPrefix, 1);

    // Shared header/keys/blockhash/instructions body (identical to a legacy message).
    WriteMessageBody(LMsgBuf);

    // Version 0 trailer: the address table lookups.
    LAtlBytes := TAddressTableLookupUtils.SerializeAddressTableLookups(FAddressTableLookups);
    if Length(LAtlBytes) > 0 then
      LMsgBuf.WriteBuffer(LAtlBytes[0], Length(LAtlBytes));

    Result := TArrayUtilities.StreamToBytes(LMsgBuf);
  finally
    LMsgBuf.Free;
  end;
end;

function TVersionedMessage.SerializeV1: TBytes;
var
  LMask: TTransactionConfigMask;
  LBuf: TMemoryStream;
  LI: Integer;
  LCI: ICompiledInstruction;
  LHdr, LBlockHashBytes, LAccountKeyBytes, LScratch: TBytes;
  LByte: Byte;
begin
  LMask := TTransactionConfigMask.FromConfig(FTransactionConfig);

  LBuf := TMemoryStream.Create;
  try
    // Version prefix (high bit set, low 7 bits carry the version).
    LByte := EncodeVersionPrefix(FVersion);
    LBuf.WriteBuffer(LByte, 1);

    // Message header (3 bytes).
    LHdr := FHeader.ToBytes();
    LBuf.WriteBuffer(LHdr[0], Length(LHdr));

    // Config mask (u32 LE).
    SetLength(LScratch, 4);
    TSerialization.WriteU32(LScratch, LMask.Value, 0);
    LBuf.WriteBuffer(LScratch[0], 4);

    // Lifetime specifier / blockhash (32 bytes).
    LBlockHashBytes := TBase58Encoder.DecodeData(FRecentBlockhash);
    LBuf.WriteBuffer(LBlockHashBytes[0], Length(LBlockHashBytes));

    // Counts as single bytes: instruction count first, then account count.
    LByte := Byte(FInstructions.Count);
    LBuf.WriteBuffer(LByte, 1);
    LByte := Byte(FAccountKeys.Count);
    LBuf.WriteBuffer(LByte, 1);

    // Account keys.
    for LI := 0 to FAccountKeys.Count - 1 do
    begin
      LAccountKeyBytes := FAccountKeys[LI].KeyBytes;
      LBuf.WriteBuffer(LAccountKeyBytes[0], Length(LAccountKeyBytes));
    end;

    // Config values, in mask order, only when present.
    if Assigned(FTransactionConfig) then
    begin
      if FTransactionConfig.PriorityFee.HasValue then
      begin
        SetLength(LScratch, 8);
        TSerialization.WriteU64(LScratch, FTransactionConfig.PriorityFee.Value, 0);
        LBuf.WriteBuffer(LScratch[0], 8);
      end;
      if FTransactionConfig.ComputeUnitLimit.HasValue then
      begin
        SetLength(LScratch, 4);
        TSerialization.WriteU32(LScratch, FTransactionConfig.ComputeUnitLimit.Value, 0);
        LBuf.WriteBuffer(LScratch[0], 4);
      end;
      if FTransactionConfig.LoadedAccountsDataSizeLimit.HasValue then
      begin
        SetLength(LScratch, 4);
        TSerialization.WriteU32(LScratch, FTransactionConfig.LoadedAccountsDataSizeLimit.Value, 0);
        LBuf.WriteBuffer(LScratch[0], 4);
      end;
      if FTransactionConfig.HeapSize.HasValue then
      begin
        SetLength(LScratch, 4);
        TSerialization.WriteU32(LScratch, FTransactionConfig.HeapSize.Value, 0);
        LBuf.WriteBuffer(LScratch[0], 4);
      end;
    end;

    // Instruction headers: programIdIndex (u8), key-indices length (u8), data length (u16 LE).
    for LI := 0 to FInstructions.Count - 1 do
    begin
      LCI := FInstructions[LI];
      LByte := LCI.ProgramIdIndex;
      LBuf.WriteBuffer(LByte, 1);
      LByte := Byte(Length(LCI.KeyIndices));
      LBuf.WriteBuffer(LByte, 1);
      SetLength(LScratch, 2);
      TSerialization.WriteU16(LScratch, Word(Length(LCI.Data)), 0);
      LBuf.WriteBuffer(LScratch[0], 2);
    end;

    // Instruction payloads: key indices then data.
    for LI := 0 to FInstructions.Count - 1 do
    begin
      LCI := FInstructions[LI];
      if Length(LCI.KeyIndices) > 0 then
        LBuf.WriteBuffer(LCI.KeyIndices[0], Length(LCI.KeyIndices));
      if Length(LCI.Data) > 0 then
        LBuf.WriteBuffer(LCI.Data[0], Length(LCI.Data));
    end;

    Result := TArrayUtilities.StreamToBytes(LBuf);
  finally
    LBuf.Free;
  end;
end;

class function TVersionedMessage.DoDeserialize(const AData: TBytes): IMessage;
var
  LPrefix, LMaskedPrefix, LVersion: Byte;
begin
  if Length(AData) = 0 then
    raise Exception.Create('Empty message');

  LPrefix := AData[0];
  LMaskedPrefix := LPrefix and TVersionedMessage.VersionPrefixMask;

  if LPrefix = LMaskedPrefix then
    raise ENotSupportedException.Create('Expected versioned message but received legacy message');

  LVersion := LMaskedPrefix;

  case LVersion of
    0: Result := DeserializeV0(AData);
    1: Result := DeserializeV1(AData);
  else
    raise ENotSupportedException.CreateFmt('Version %d is not supported for deserialization.', [LVersion]);
  end;
end;

class function TVersionedMessage.DeserializeV0(const AData: TBytes): IMessage;
const
  PKLen = TPublicKey.PublicKeyLength;
var
  LPrefix: Byte;
  LBody: TBytes;
  LI: Integer;
  LTableLookupOffset: Integer;
  LTableLookupData: TBytes;
  LATLCountDec: TShortVecDecode;
  LAddressTableLookupsCount: Integer;
  LAddressTableLookupsEncodedCount: Integer;
  LLkp: IMessageAddressTableLookup;
  LAccountKeyBytes: TBytes;
  LWritableLenDec, LReadonlyLenDec: TShortVecDecode;
  LWritableLen, LWritableEncLen: Integer;
  LReadonlyLen, LReadonlyEncLen: Integer;
  LWritableSlice, LReadonlySlice: TBytes;
  LRes: IVersionedMessage;
begin
  if Length(AData) = 0 then
    raise Exception.Create('Empty message');

  LPrefix := AData[0];
  if not TVersionedMessage.IsVersioned(LPrefix) then
    raise ENotSupportedException.Create('Expected versioned message but received legacy message');

  LBody := TArrayUtilities.Slice<Byte>(AData, 1, Length(AData) - 1);

  // Create message; the shared reader fills header/keys/blockhash/instructions.
  LRes := TVersionedMessage.Create;
  LRes.AddressTableLookups := TList<IMessageAddressTableLookup>.Create;
  // Preserve the decoded version (v0, v1, ...); no longer reject non-v0 messages.
  LRes.Version := TVersionedMessage.DecodeVersion(LPrefix);

  LTableLookupOffset := TMessage.ReadMessageBody(LBody, LRes);

  // v0 messages may omit the address-table-lookup section entirely. Guard against
  // slicing past the end of the body.
  if LTableLookupOffset >= Length(LBody) then
  begin
    Result := LRes;
    Exit;
  end;

  LTableLookupData := TArrayUtilities.Slice<Byte>(LBody, LTableLookupOffset);
  LATLCountDec := TShortVectorEncoding.DecodeLength(LTableLookupData);
  LAddressTableLookupsCount := LATLCountDec.Value;
  LAddressTableLookupsEncodedCount := LATLCountDec.Length;

  LTableLookupData := TArrayUtilities.Slice<Byte>(LTableLookupData, LAddressTableLookupsEncodedCount);

  for LI := 0 to LAddressTableLookupsCount - 1 do
  begin
    LAccountKeyBytes := TArrayUtilities.Slice<Byte>(LTableLookupData, 0, PKLen);
    LLkp := TVersionedMessage.TMessageAddressTableLookup.Create;
    LLkp.AccountKey := TPublicKey.Create(LAccountKeyBytes);

    LTableLookupData := TArrayUtilities.Slice<Byte>(LTableLookupData, PKLen);

    LWritableLenDec := TShortVectorEncoding.DecodeLength(LTableLookupData);
    LWritableLen := LWritableLenDec.Value;
    LWritableEncLen := LWritableLenDec.Length;
    LWritableSlice := TArrayUtilities.Slice<Byte>(LTableLookupData, LWritableEncLen, LWritableLen);
    LLkp.WritableIndexes := LWritableSlice;
    LTableLookupData := TArrayUtilities.Slice<Byte>(LTableLookupData, LWritableEncLen + LWritableLen);

    LReadonlyLenDec := TShortVectorEncoding.DecodeLength(LTableLookupData);
    LReadonlyLen := LReadonlyLenDec.Value;
    LReadonlyEncLen := LReadonlyLenDec.Length;
    LReadonlySlice := TArrayUtilities.Slice<Byte>(LTableLookupData, LReadonlyEncLen, LReadonlyLen);
    LLkp.ReadonlyIndexes := LReadonlySlice;
    LTableLookupData := TArrayUtilities.Slice<Byte>(LTableLookupData, LReadonlyEncLen + LReadonlyLen);

    LRes.AddressTableLookups.Add(LLkp);
  end;

  Result := LRes;
end;

class function TVersionedMessage.DeserializeV1(const AData: TBytes): IMessage;
const
  PKLen = TPublicKey.PublicKeyLength;
var
  LOffset: Integer;
  LVersion: Byte;
  LMask: TTransactionConfigMask;
  LConfig: TTransactionConfig;
  LRes: IVersionedMessage;
  LInstructionCount, LAccountCount: Byte;
  LI: Integer;
  LKeySlice, LBlockHashSlice, LKeyIndices, LData: TBytes;
  LProgramIds, LAccCounts: TArray<Byte>;
  LDataLengths: TArray<Word>;
begin
  LOffset := 0;
  LVersion := AData[LOffset] and TVersionedMessage.VersionPrefixMask;
  Inc(LOffset); // version prefix

  LRes := TVersionedMessage.Create;
  LRes.Header := TMessageHeader.Create;
  LRes.AccountKeys := TList<IPublicKey>.Create;
  LRes.Instructions := TList<ICompiledInstruction>.Create;
  LRes.Version := LVersion;

  // Message header (3 bytes).
  LRes.Header.RequiredSignatures := AData[LOffset]; Inc(LOffset);
  LRes.Header.ReadOnlySignedAccounts := AData[LOffset]; Inc(LOffset);
  LRes.Header.ReadOnlyUnsignedAccounts := AData[LOffset]; Inc(LOffset);

  // Config mask (u32 LE).
  LMask := TTransactionConfigMask.Create(TDeserialization.GetU32(AData, LOffset));
  Inc(LOffset, 4);
  if LMask.HasUnknownBits or LMask.HasInvalidPriorityFeeBits then
    raise EArgumentException.Create('Invalid transaction config mask.');

  // Lifetime specifier / blockhash (32 bytes).
  LBlockHashSlice := TArrayUtilities.Slice<Byte>(AData, LOffset, PKLen);
  LRes.RecentBlockhash := TBase58Encoder.EncodeData(LBlockHashSlice);
  Inc(LOffset, PKLen);

  // Counts (single bytes): instruction count first, then account count.
  LInstructionCount := AData[LOffset]; Inc(LOffset);
  LAccountCount := AData[LOffset]; Inc(LOffset);

  // Account keys.
  for LI := 0 to LAccountCount - 1 do
  begin
    LKeySlice := TArrayUtilities.Slice<Byte>(AData, LOffset, PKLen);
    LRes.AccountKeys.Add(TPublicKey.Create(LKeySlice));
    Inc(LOffset, PKLen);
  end;

  // Config values, in mask order.
  LConfig := TTransactionConfig.Create;
  if LMask.HasPriorityFee then
  begin
    LConfig.PriorityFee := TDeserialization.GetU64(AData, LOffset);
    Inc(LOffset, 8);
  end;
  if LMask.HasComputeUnitLimit then
  begin
    LConfig.ComputeUnitLimit := TDeserialization.GetU32(AData, LOffset);
    Inc(LOffset, 4);
  end;
  if LMask.HasLoadedAccountsDataSize then
  begin
    LConfig.LoadedAccountsDataSizeLimit := TDeserialization.GetU32(AData, LOffset);
    Inc(LOffset, 4);
  end;
  if LMask.HasHeapSize then
  begin
    LConfig.HeapSize := TDeserialization.GetU32(AData, LOffset);
    Inc(LOffset, 4);
  end;
  LRes.TransactionConfig := LConfig;

  // Instruction headers: programIdIndex (u8), key-indices length (u8), data length (u16 LE).
  SetLength(LProgramIds, LInstructionCount);
  SetLength(LAccCounts, LInstructionCount);
  SetLength(LDataLengths, LInstructionCount);
  for LI := 0 to LInstructionCount - 1 do
  begin
    LProgramIds[LI] := AData[LOffset]; Inc(LOffset);
    LAccCounts[LI] := AData[LOffset]; Inc(LOffset);
    LDataLengths[LI] := TDeserialization.GetU16(AData, LOffset); Inc(LOffset, 2);
  end;

  // Instruction payloads: key indices then data.
  for LI := 0 to LInstructionCount - 1 do
  begin
    LKeyIndices := TArrayUtilities.Slice<Byte>(AData, LOffset, LAccCounts[LI]);
    Inc(LOffset, LAccCounts[LI]);
    LData := TArrayUtilities.Slice<Byte>(AData, LOffset, LDataLengths[LI]);
    Inc(LOffset, LDataLengths[LI]);

    LRes.Instructions.Add(TCompiledInstruction.Create(
      LProgramIds[LI],
      TShortVectorEncoding.EncodeLength(LAccCounts[LI]),
      LKeyIndices,
      TShortVectorEncoding.EncodeLength(LDataLengths[LI]),
      LData));
  end;

  Result := LRes;
end;

class function TVersionedMessage.DeserializeMessageVersion(const ASerializedMessage: TBytes): string;
var
  LPrefix, LMasked: Byte;
begin
  if Length(ASerializedMessage) = 0 then
    raise Exception.Create('Empty message');

  LPrefix := ASerializedMessage[0];
  LMasked := LPrefix and VersionPrefixMask;

  if LMasked = LPrefix then
    Exit('legacy');

  Result := LMasked.ToString;
end;

class function TVersionedMessage.TAddressTableLookupUtils.SerializeAddressTableLookups(
  AList: TList<IMessageAddressTableLookup>): TBytes;
var
  LBuf: TMemoryStream;
  LEncLen: TBytes;
  LI, LCount: Integer;
  LLkp: IMessageAddressTableLookup;
begin
  // Null-safe: a nil list serializes as a zero-length short-vec.
  if AList <> nil then
    LCount := AList.Count
  else
    LCount := 0;

  LBuf := TMemoryStream.Create;
  try
    LBuf.Position := 0;

    LEncLen := TShortVectorEncoding.EncodeLength(LCount);
    LBuf.WriteBuffer(LEncLen[0], Length(LEncLen));

    for LI := 0 to LCount - 1 do
    begin
      LLkp := AList[LI];

      LBuf.WriteBuffer(LLkp.AccountKey.KeyBytes[0], TPublicKey.PublicKeyLength);

      LEncLen := TShortVectorEncoding.EncodeLength(Length(LLkp.WritableIndexes));
      LBuf.WriteBuffer(LEncLen[0], Length(LEncLen));
      if Length(LLkp.WritableIndexes) > 0 then
        LBuf.WriteBuffer(LLkp.WritableIndexes[0], Length(LLkp.WritableIndexes));

      LEncLen := TShortVectorEncoding.EncodeLength(Length(LLkp.ReadonlyIndexes));
      LBuf.WriteBuffer(LEncLen[0], Length(LEncLen));
      if Length(LLkp.ReadonlyIndexes) > 0 then
        LBuf.WriteBuffer(LLkp.ReadonlyIndexes[0], Length(LLkp.ReadonlyIndexes));
    end;

    Result := TArrayUtilities.StreamToBytes(LBuf);
  finally
    LBuf.Free;
  end;
end;

{ TMessageV0 }

constructor TMessageV0.Create;
begin
  inherited Create;
  FVersion := 0;
end;

{ TMessageV1 }

constructor TMessageV1.Create;
begin
  inherited Create;
  FVersion := 1;
end;

end.

