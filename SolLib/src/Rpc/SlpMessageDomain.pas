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
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  SlpPublicKey,
  SlpShortVectorEncoding,
  SlpDataEncoderUtilities,
  SlpTransactionInstruction,
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

    property AddressTableLookups: TList<IMessageAddressTableLookup> read GetAddressTableLookups write SetAddressTableLookups;
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
    function Serialize: TBytes;
  protected
    /// <summary>
    /// Internal virtual deserialization hook — subclasses override this to provide their parser.
    /// </summary>
    class function DoDeserialize(const AData: TBytes): IMessage; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    class function Deserialize(const AData: TBytes): IMessage; overload; static;
    class function Deserialize(const ABase64: string): IMessage; overload; static;
  end;

type
  /// <summary>
  /// Versioned Message
  /// </summary>
  TVersionedMessage = class(TMessage, IVersionedMessage)
  public
    const VersionPrefixMask = $7F;
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
    function GetAddressTableLookups: TList<IMessageAddressTableLookup>;
    procedure SetAddressTableLookups(const AValue: TList<IMessageAddressTableLookup>);
  protected
    class function DoDeserialize(const AData: TBytes): IMessage; override;
  public
    constructor Create; override;
    destructor Destroy; override;

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

function TMessage.Serialize: TBytes;
var
  LAccountAddressesLength, LInstructionsLength, LAccountKeyBytes, LHdr: TBytes;
  LAccountKeysBuf: TMemoryStream;
  LMsgBuf: TMemoryStream;
  LI: Integer;
  LCI: ICompiledInstruction;
  LBlockHashBytes: TBytes;
  LEstAccountKeysSize: Integer;
  LEstMsgSize: Integer;
  LProgramIdIndex: Byte;
begin
  LAccountAddressesLength := TShortVectorEncoding.EncodeLength(FAccountKeys.Count);
  LInstructionsLength := TShortVectorEncoding.EncodeLength(FInstructions.Count);

  LEstAccountKeysSize := FAccountKeys.Count * 32;

  LAccountKeysBuf := TMemoryStream.Create;
  try
    LAccountKeysBuf.Size := LEstAccountKeysSize;
    LAccountKeysBuf.Position := 0;

    for LI := 0 to FAccountKeys.Count - 1 do
    begin
      LAccountKeyBytes := FAccountKeys[LI].KeyBytes;
      LAccountKeysBuf.WriteBuffer(LAccountKeyBytes[0], Length(LAccountKeyBytes));
    end;

    LBlockHashBytes := TBase58Encoder.DecodeData(FRecentBlockhash);

    LEstMsgSize := TMessageHeader.TLayout.HeaderLength +
                  TPublicKey.PublicKeyLength + Length(LAccountAddressesLength) +
                  Length(LInstructionsLength) + FInstructions.Count + LEstAccountKeysSize;

    LMsgBuf := TMemoryStream.Create;
    try
      LMsgBuf.Size := LEstMsgSize;
      LMsgBuf.Position := 0;

      LHdr := FHeader.ToBytes();
      LMsgBuf.WriteBuffer(LHdr[0], Length(LHdr));

      LMsgBuf.WriteBuffer(LAccountAddressesLength[0], Length(LAccountAddressesLength));
      LMsgBuf.WriteBuffer(LAccountKeysBuf.Memory^, LAccountKeysBuf.Size);
      LMsgBuf.WriteBuffer(LBlockHashBytes[0], Length(LBlockHashBytes));
      LMsgBuf.WriteBuffer(LInstructionsLength[0], Length(LInstructionsLength));

      for LI := 0 to FInstructions.Count - 1 do
      begin
        LCI := FInstructions[LI];

        LProgramIdIndex := LCI.ProgramIdIndex;
        LMsgBuf.WriteBuffer(LProgramIdIndex, SizeOf(LProgramIdIndex));

        LMsgBuf.WriteBuffer(LCI.KeyIndicesCount[0], Length(LCI.KeyIndicesCount));
        LMsgBuf.WriteBuffer(LCI.KeyIndices[0], Length(LCI.KeyIndices));
        LMsgBuf.WriteBuffer(LCI.DataLength[0], Length(LCI.DataLength));
        LMsgBuf.WriteBuffer(LCI.Data[0], Length(LCI.Data));
      end;

      SetLength(Result, LMsgBuf.Size);
      LMsgBuf.Position := 0;
      LMsgBuf.ReadBuffer(Result[0], LMsgBuf.Size);
    finally
      LMsgBuf.Free;
    end;
  finally
    LAccountKeysBuf.Free;
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

class function TMessage.DoDeserialize(const AData: TBytes): IMessage;
const
  PKLen = TPublicKey.PublicKeyLength;
  HLen = TMessageHeader.TLayout.HeaderLength;
  SvesLen = TShortVectorEncoding.SpanLength;
var
  LPrefix, LMaskedPrefix: Byte;
  LNumRequiredSignatures: Byte;
  LNumReadOnlySignedAccounts: Byte;
  LNumReadOnlyUnsignedAccounts: Byte;
  LAccLenSlice: TBytes;
  LAccLenDec: TShortVecDecode;
  LAccountAddressLength: Integer;
  LAccountAddressLengthEncodedLength: Integer;
  LI: Integer;
  LKeySlice: TBytes;
  LBlockHashSlice: TBytes;
  LInstrLenSlice, LInstrData: TBytes;
  LInstrLenDec: TShortVecDecode;
  LInstructionsLength: Integer;
  LInstructionsLengthEncodedLength: Integer;
  LInstructionsOffset: Integer;
  LCId: TCompiledInstructionDecode;
  LPublicKey: IPublicKey;
begin
  if Length(AData) = 0 then
    raise Exception.Create('Empty message');

  // Check that the message is not a TVersionedMessage
  LPrefix := AData[0];
  LMaskedPrefix := LPrefix and TVersionedMessage.VersionPrefixMask;
  if LPrefix <> LMaskedPrefix then
    raise ENotSupportedException.Create(
      'The message is a VersionedMessage, use TVersionedMessage.Deserialize instead.'
    );

  // Read message header
  LNumRequiredSignatures := AData[TMessageHeader.TLayout.RequiredSignaturesOffset];
  LNumReadOnlySignedAccounts := AData[TMessageHeader.TLayout.ReadOnlySignedAccountsOffset];
  LNumReadOnlyUnsignedAccounts := AData[TMessageHeader.TLayout.ReadOnlyUnsignedAccountsOffset];

  // Read account keys
  LAccLenSlice := TArrayUtilities.Slice<Byte>(AData, HLen, SvesLen);
  LAccLenDec := TShortVectorEncoding.DecodeLength(LAccLenSlice);
  LAccountAddressLength := LAccLenDec.Value;
  LAccountAddressLengthEncodedLength := LAccLenDec.Length;

  // Create the message
  Result := TMessage.Create;
  Result.Header := TMessageHeader.Create;
  Result.AccountKeys := TList<IPublicKey>.Create;
  Result.Instructions := TList<ICompiledInstruction>.Create;

  Result.Header.RequiredSignatures := LNumRequiredSignatures;
  Result.Header.ReadOnlySignedAccounts := LNumReadOnlySignedAccounts;
  Result.Header.ReadOnlyUnsignedAccounts := LNumReadOnlyUnsignedAccounts;

  for LI := 0 to LAccountAddressLength - 1 do
  begin
    LKeySlice := TArrayUtilities.Slice<Byte>(
      AData,
      HLen + LAccountAddressLengthEncodedLength + LI * PKLen,
      PKLen
    );
    LPublicKey := TPublicKey.Create(LKeySlice);
    Result.AccountKeys.Add(LPublicKey);
  end;

  LBlockHashSlice := TArrayUtilities.Slice<Byte>(
    AData,
    HLen + LAccountAddressLengthEncodedLength + LAccountAddressLength * PKLen,
    PKLen
  );
  Result.RecentBlockhash := TBase58Encoder.EncodeData(LBlockHashSlice);

  LInstrLenSlice := TArrayUtilities.Slice<Byte>(
    AData,
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

  LInstrData := TArrayUtilities.Slice<Byte>(AData, LInstructionsOffset);

  for LI := 0 to LInstructionsLength - 1 do
  begin
    LCId := TCompiledInstruction.Deserialize(LInstrData);
    Result.Instructions.Add(LCId.Instruction);
    LInstrData := TArrayUtilities.Slice<Byte>(LInstrData, LCId.Length);
  end;
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
end;

destructor TVersionedMessage.Destroy;
begin
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

class function TVersionedMessage.DoDeserialize(const AData: TBytes): IMessage;
const
  PKLen = TPublicKey.PublicKeyLength;
  HLen = TMessageHeader.TLayout.HeaderLength;
  SvesLen = TShortVectorEncoding.SpanLength;
var
  LPrefix, LMaskedPrefix, LVersion: Byte;
  LBody: TBytes;
  LNumRequiredSignatures: Byte;
  LNumReadOnlySignedAccounts: Byte;
  LNumReadOnlyUnsignedAccounts: Byte;
  LAccLenSlice: TBytes;
  LAccLenDec: TShortVecDecode;
  LAccountAddressLength: Integer;
  LAccountAddressLengthEncodedLength: Integer;
  LI: Integer;
  LKeySlice: TBytes;
  LBlockHashSlice: TBytes;
  LInstrLenSlice: TBytes;
  LInstrLenDec: TShortVecDecode;
  LInstructionsLength: Integer;
  LInstructionsLengthEncodedLength: Integer;
  LInstructionsOffset: Integer;
  LInstrData: TBytes;
  LInstrDec: TCompiledInstructionDecode;
  LInstructionsDataLength: Integer;
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
  LPublicKey: IPublicKey;
begin
  if Length(AData) = 0 then
    raise Exception.Create('Empty message');

  LPrefix := AData[0];
  LMaskedPrefix := LPrefix and TVersionedMessage.VersionPrefixMask;

  if LPrefix = LMaskedPrefix then
    raise ENotSupportedException.Create('Expected versioned message but received legacy message');

  LVersion := LMaskedPrefix;
  if LVersion <> 0 then
    raise ENotSupportedException.CreateFmt(
      'Expected versioned message with version 0 but found version %d', [LVersion]
    );

  LBody := TArrayUtilities.Slice<Byte>(AData, 1, Length(AData) - 1);

  // Read message header
  LNumRequiredSignatures := LBody[TMessageHeader.TLayout.RequiredSignaturesOffset];
  LNumReadOnlySignedAccounts := LBody[TMessageHeader.TLayout.ReadOnlySignedAccountsOffset];
  LNumReadOnlyUnsignedAccounts := LBody[TMessageHeader.TLayout.ReadOnlyUnsignedAccountsOffset];

  // Decode account keys
  LAccLenSlice := TArrayUtilities.Slice<Byte>(LBody, HLen, SvesLen);
  LAccLenDec := TShortVectorEncoding.DecodeLength(LAccLenSlice);
  LAccountAddressLength := LAccLenDec.Value;
  LAccountAddressLengthEncodedLength := LAccLenDec.Length;

  // Create message
  LRes := TVersionedMessage.Create;
  LRes.Header := TMessageHeader.Create;
  LRes.AccountKeys := TList<IPublicKey>.Create;
  LRes.Instructions := TList<ICompiledInstruction>.Create;
  LRes.AddressTableLookups := TList<IMessageAddressTableLookup>.Create;

  LRes.Header.RequiredSignatures := LNumRequiredSignatures;
  LRes.Header.ReadOnlySignedAccounts := LNumReadOnlySignedAccounts;
  LRes.Header.ReadOnlyUnsignedAccounts := LNumReadOnlyUnsignedAccounts;

  // Accounts
  for LI := 0 to LAccountAddressLength - 1 do
  begin
    LKeySlice := TArrayUtilities.Slice<Byte>(
      LBody,
      HLen + LAccountAddressLengthEncodedLength + LI * PKLen,
      PKLen
    );
    LPublicKey := TPublicKey.Create(LKeySlice);
    LRes.AccountKeys.Add(LPublicKey);
  end;

  // Blockhash
  LBlockHashSlice := TArrayUtilities.Slice<Byte>(
    LBody,
    HLen + LAccountAddressLengthEncodedLength + LAccountAddressLength * PKLen,
    PKLen
  );
  LRes.RecentBlockhash := TBase58Encoder.EncodeData(LBlockHashSlice);

  // Instructions
  LInstrLenSlice := TArrayUtilities.Slice<Byte>(
    LBody,
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

  LInstrData := TArrayUtilities.Slice<Byte>(LBody, LInstructionsOffset);
  LInstructionsDataLength := 0;

  for LI := 0 to LInstructionsLength - 1 do
  begin
    LInstrDec := TCompiledInstruction.Deserialize(LInstrData);
    LRes.Instructions.Add(LInstrDec.Instruction);
    LInstrData := TArrayUtilities.Slice<Byte>(LInstrData, LInstrDec.Length);
    Inc(LInstructionsDataLength, LInstrDec.Length);
  end;

  // Address table lookups
  LTableLookupOffset :=
    HLen +
    LAccountAddressLengthEncodedLength +
    (LAccountAddressLength * PKLen) +
    PKLen +
    LInstructionsLengthEncodedLength +
    LInstructionsDataLength;

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

class function TVersionedMessage.DeserializeMessageVersion(const ASerializedMessage: TBytes): string;
var
  LPrefix, LMasked: Byte;
begin
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
  LI: Integer;
  LLkp: IMessageAddressTableLookup;
begin
  LBuf := TMemoryStream.Create;
  try
    LBuf.Position := 0;

    LEncLen := TShortVectorEncoding.EncodeLength(AList.Count);
    LBuf.WriteBuffer(LEncLen[0], Length(LEncLen));

    for LI := 0 to AList.Count - 1 do
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

    SetLength(Result, LBuf.Size);
    LBuf.Position := 0;
    LBuf.ReadBuffer(Result[0], LBuf.Size);
  finally
    LBuf.Free;
  end;
end;

end.

