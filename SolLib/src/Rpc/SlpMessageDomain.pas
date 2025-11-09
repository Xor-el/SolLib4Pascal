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

unit SlpMessageDomain;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  SlpPublicKey,
  SlpShortVectorEncoding,
  SlpDataEncoders,
  SlpTransactionInstruction,
  SlpArrayUtils;

type

  IMessageHeader = interface
    ['{2F8B0C0A-1355-49A7-B98E-98B0E4AE7A9F}']
    function GetRequiredSignatures: Byte;
    procedure SetRequiredSignatures(const Value: Byte);
    function GetReadOnlySignedAccounts: Byte;
    procedure SetReadOnlySignedAccounts(const Value: Byte);
    function GetReadOnlyUnsignedAccounts: Byte;
    procedure SetReadOnlyUnsignedAccounts(const Value: Byte);

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
    procedure SetHeader(const Value: IMessageHeader);
    function GetAccountKeys: TList<IPublicKey>;
    procedure SetAccountKeys(const Value: TList<IPublicKey>);
    function GetInstructions: TList<ICompiledInstruction>;
    procedure SetInstructions(const Value: TList<ICompiledInstruction>);
    function GetRecentBlockhash: string;
    procedure SetRecentBlockhash(const Value: string);

    /// <summary>
    /// Check whether an account is writable.
    /// </summary>
    /// <param name="index">The index of the account in the account keys.</param>
    /// <returns>true if the account is writable, false otherwise.</returns>
    function IsAccountWritable(Index: Integer): Boolean;
    /// <summary>
    /// Check whether an account is a signer.
    /// </summary>
    /// <param name="index">The index of the account in the account keys.</param>
    /// <returns>true if the account is an expected signer, false otherwise.</returns>
    function IsAccountSigner(Index: Integer): Boolean;
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
    procedure SetAccountKey(const Value: IPublicKey);
    function GetWritableIndexes: TBytes;
    procedure SetWritableIndexes(const Value: TBytes);
    function GetReadonlyIndexes: TBytes;
    procedure SetReadonlyIndexes(const Value: TBytes);

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
    procedure SetAddressTableLookups(const Value: TList<IMessageAddressTableLookup>);

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
    procedure SetRequiredSignatures(const Value: Byte);
    function GetReadOnlySignedAccounts: Byte;
    procedure SetReadOnlySignedAccounts(const Value: Byte);
    function GetReadOnlyUnsignedAccounts: Byte;
    procedure SetReadOnlyUnsignedAccounts(const Value: Byte);

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
    procedure SetHeader(const Value: IMessageHeader);
    function GetAccountKeys: TList<IPublicKey>;
    procedure SetAccountKeys(const Value: TList<IPublicKey>);
    function GetInstructions: TList<ICompiledInstruction>;
    procedure SetInstructions(const Value: TList<ICompiledInstruction>);
    function GetRecentBlockhash: string;
    procedure SetRecentBlockhash(const Value: string);

    function IsAccountWritable(Index: Integer): Boolean;
    function IsAccountSigner(Index: Integer): Boolean;
    function Serialize: TBytes;
  protected
    /// <summary>
    /// Internal virtual deserialization hook — subclasses override this to provide their parser.
    /// </summary>
    class function DoDeserialize(const Data: TBytes): IMessage; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    class function Deserialize(const Data: TBytes): IMessage; overload; static;
    class function Deserialize(const Base64: string): IMessage; overload; static;
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
      procedure SetAccountKey(const Value: IPublicKey);
      function GetWritableIndexes: TBytes;
      procedure SetWritableIndexes(const Value: TBytes);
      function GetReadonlyIndexes: TBytes;
      procedure SetReadonlyIndexes(const Value: TBytes);

      function Clone: IMessageAddressTableLookup;

      public
        constructor Create;

    end;

  private
    FAddressTableLookups: TList<IMessageAddressTableLookup>;
    function GetAddressTableLookups: TList<IMessageAddressTableLookup>;
    procedure SetAddressTableLookups(const Value: TList<IMessageAddressTableLookup>);
  protected
    class function DoDeserialize(const Data: TBytes): IMessage; override;
  public
    constructor Create; override;
    destructor Destroy; override;

    /// <summary>
    /// Deserialize the message version
    /// </summary>
    /// <param name="SerializedMessage"></param>
    /// <returns></returns>
    class function DeserializeMessageVersion(const SerializedMessage: TBytes): string; static;

  type
    TAddressTableLookupUtils = record
    public
      class function SerializeAddressTableLookups(List: TList<IMessageAddressTableLookup>): TBytes; static;
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

procedure TMessageHeader.SetReadOnlySignedAccounts(const Value: Byte);
begin
  FReadOnlySignedAccounts := Value;
end;

procedure TMessageHeader.SetReadOnlyUnsignedAccounts(const Value: Byte);
begin
  FReadOnlyUnsignedAccounts := Value;
end;

procedure TMessageHeader.SetRequiredSignatures(const Value: Byte);
begin
  FRequiredSignatures := Value;
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

procedure TMessage.SetAccountKeys(const Value: TList<IPublicKey>);
begin
  FAccountKeys := Value;
end;

procedure TMessage.SetHeader(const Value: IMessageHeader);
begin
  FHeader := Value;
end;

procedure TMessage.SetInstructions(const Value: TList<ICompiledInstruction>);
begin
  FInstructions := Value;
end;

procedure TMessage.SetRecentBlockhash(const Value: string);
begin
  FRecentBlockhash := Value;
end;

function TMessage.IsAccountSigner(Index: Integer): Boolean;
begin
  Result := Index < FHeader.RequiredSignatures;
end;

function TMessage.IsAccountWritable(Index: Integer): Boolean;
begin
  Result := (Index < (FHeader.RequiredSignatures - FHeader.ReadOnlySignedAccounts)) or
            ((Index >= FHeader.RequiredSignatures) and
             (Index < (FAccountKeys.Count - FHeader.ReadOnlyUnsignedAccounts)));
end;

function TMessage.Serialize: TBytes;
var
  AccountAddressesLength, InstructionsLength, AccountKeyBytes, Hdr: TBytes;
  AccountKeysBuf: TMemoryStream;
  MsgBuf: TMemoryStream;
  I: Integer;
  CI: ICompiledInstruction;
  BlockHashBytes: TBytes;
  EstAccountKeysSize: Integer;
  EstMsgSize: Integer;
  LProgramIdIndex: Byte;
begin
  AccountAddressesLength := TShortVectorEncoding.EncodeLength(FAccountKeys.Count);
  InstructionsLength     := TShortVectorEncoding.EncodeLength(FInstructions.Count);

  EstAccountKeysSize := FAccountKeys.Count * 32;

  AccountKeysBuf := TMemoryStream.Create;
  try
    AccountKeysBuf.Size := EstAccountKeysSize;
    AccountKeysBuf.Position := 0;

    for I := 0 to FAccountKeys.Count - 1 do
    begin
      AccountKeyBytes := FAccountKeys[I].KeyBytes;
      AccountKeysBuf.WriteBuffer(AccountKeyBytes[0], Length(AccountKeyBytes));
    end;

    BlockHashBytes := TEncoders.Base58.DecodeData(FRecentBlockhash);

    EstMsgSize := TMessageHeader.TLayout.HeaderLength +
                  TPublicKey.PublicKeyLength + Length(AccountAddressesLength) +
                  Length(InstructionsLength) + FInstructions.Count + EstAccountKeysSize;

    MsgBuf := TMemoryStream.Create;
    try
      MsgBuf.Size := EstMsgSize;
      MsgBuf.Position := 0;

      Hdr := FHeader.ToBytes();
      MsgBuf.WriteBuffer(Hdr[0], Length(Hdr));

      MsgBuf.WriteBuffer(AccountAddressesLength[0], Length(AccountAddressesLength));
      MsgBuf.WriteBuffer(AccountKeysBuf.Memory^, AccountKeysBuf.Size);
      MsgBuf.WriteBuffer(BlockHashBytes[0], Length(BlockHashBytes));
      MsgBuf.WriteBuffer(InstructionsLength[0], Length(InstructionsLength));

      for I := 0 to FInstructions.Count - 1 do
      begin
        CI := FInstructions[I];

        LProgramIdIndex := CI.ProgramIdIndex;
        MsgBuf.WriteBuffer(LProgramIdIndex, SizeOf(LProgramIdIndex));

        MsgBuf.WriteBuffer(CI.KeyIndicesCount[0], Length(CI.KeyIndicesCount));
        MsgBuf.WriteBuffer(CI.KeyIndices[0], Length(CI.KeyIndices));
        MsgBuf.WriteBuffer(CI.DataLength[0], Length(CI.DataLength));
        MsgBuf.WriteBuffer(CI.Data[0], Length(CI.Data));
      end;

      SetLength(Result, MsgBuf.Size);
      MsgBuf.Position := 0;
      MsgBuf.ReadBuffer(Result[0], MsgBuf.Size);
    finally
      MsgBuf.Free;
    end;
  finally
    AccountKeysBuf.Free;
  end;
end;

class function TMessage.Deserialize(const Base64: string): IMessage;
var
  Bytes: TBytes;
begin
  if Base64 = '' then
    raise EArgumentNilException.Create('data');

  try
    Bytes := TEncoders.Base64.DecodeData(Base64);
  except
    on E: Exception do
      raise Exception.Create('could not decode message data from base64');
  end;

  Result := Deserialize(Bytes);
end;

class function TMessage.Deserialize(const Data: TBytes): IMessage;
begin
  // Polymorphic dispatch to this class' implementation. Overrides will be used.
  Result := DoDeserialize(Data);
end;

class function TMessage.DoDeserialize(const Data: TBytes): IMessage;
const
  PKLen   = TPublicKey.PublicKeyLength;
  HLen    = TMessageHeader.TLayout.HeaderLength;
  SvesLen = TShortVectorEncoding.SpanLength;
var
  Prefix, MaskedPrefix: Byte;
  NumRequiredSignatures: Byte;
  NumReadOnlySignedAccounts: Byte;
  NumReadOnlyUnsignedAccounts: Byte;
  AccLenSlice: TBytes;
  AccLenDec: TShortVecDecode;
  AccountAddressLength: Integer;
  AccountAddressLengthEncodedLength: Integer;
  I: Integer;
  KeySlice: TBytes;
  BlockHashSlice: TBytes;
  InstrLenSlice, InstrData: TBytes;
  InstrLenDec: TShortVecDecode;
  InstructionsLength: Integer;
  InstructionsLengthEncodedLength: Integer;
  InstructionsOffset: Integer;
  CId: TCompiledInstructionDecode;
  //LMsg: IMessage;
  LPublicKey: IPublicKey;
begin
  if Length(Data) = 0 then
    raise Exception.Create('Empty message');

  // Check that the message is not a TVersionedMessage
  Prefix := Data[0];
  MaskedPrefix := Prefix and TVersionedMessage.VersionPrefixMask;
  if Prefix <> MaskedPrefix then
    raise ENotSupportedException.Create(
      'The message is a VersionedMessage, use TVersionedMessage.Deserialize instead.'
    );

  // Read message header
  NumRequiredSignatures       := Data[TMessageHeader.TLayout.RequiredSignaturesOffset];
  NumReadOnlySignedAccounts   := Data[TMessageHeader.TLayout.ReadOnlySignedAccountsOffset];
  NumReadOnlyUnsignedAccounts := Data[TMessageHeader.TLayout.ReadOnlyUnsignedAccountsOffset];

  // Read account keys
  AccLenSlice := TArrayUtils.Slice<Byte>(Data, HLen, SvesLen);
  AccLenDec := TShortVectorEncoding.DecodeLength(AccLenSlice);
  AccountAddressLength := AccLenDec.Value;
  AccountAddressLengthEncodedLength := AccLenDec.Length;

  // Create the message
  Result := TMessage.Create;
  Result.Header := TMessageHeader.Create;
  Result.AccountKeys := TList<IPublicKey>.Create;
  Result.Instructions := TList<ICompiledInstruction>.Create;

  Result.Header.RequiredSignatures := NumRequiredSignatures;
  Result.Header.ReadOnlySignedAccounts := NumReadOnlySignedAccounts;
  Result.Header.ReadOnlyUnsignedAccounts := NumReadOnlyUnsignedAccounts;

  for I := 0 to AccountAddressLength - 1 do
  begin
    KeySlice := TArrayUtils.Slice<Byte>(
      Data,
      HLen + AccountAddressLengthEncodedLength + I * PKLen,
      PKLen
    );
    LPublicKey := TPublicKey.Create(KeySlice);
    Result.AccountKeys.Add(LPublicKey);
  end;

  BlockHashSlice := TArrayUtils.Slice<Byte>(
    Data,
    HLen + AccountAddressLengthEncodedLength + AccountAddressLength * PKLen,
    PKLen
  );
  Result.RecentBlockhash := TEncoders.Base58.EncodeData(BlockHashSlice);

  InstrLenSlice := TArrayUtils.Slice<Byte>(
    Data,
    HLen + AccountAddressLengthEncodedLength + (AccountAddressLength * PKLen) + PKLen,
    SvesLen
  );
  InstrLenDec := TShortVectorEncoding.DecodeLength(InstrLenSlice);
  InstructionsLength := InstrLenDec.Value;
  InstructionsLengthEncodedLength := InstrLenDec.Length;

  InstructionsOffset :=
    HLen +
    AccountAddressLengthEncodedLength +
    (AccountAddressLength * PKLen) +
    PKLen +
    InstructionsLengthEncodedLength;

  InstrData := TArrayUtils.Slice<Byte>(Data, InstructionsOffset);

  for I := 0 to InstructionsLength - 1 do
  begin
    CId := TCompiledInstruction.Deserialize(InstrData);
    Result.Instructions.Add(CId.Instruction);
    InstrData := TArrayUtils.Slice<Byte>(InstrData, CId.Length);
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
  CopyLkp: TVersionedMessage.TMessageAddressTableLookup;
begin
  CopyLkp := TVersionedMessage.TMessageAddressTableLookup.Create;
  CopyLkp.FAccountKey := FAccountKey.Clone;
  CopyLkp.FWritableIndexes := TArrayUtils.Copy<Byte>(FWritableIndexes);
  CopyLkp.FReadonlyIndexes := TArrayUtils.Copy<Byte>(FReadonlyIndexes);
  Result := CopyLkp;
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

procedure TVersionedMessage.TMessageAddressTableLookup.SetAccountKey(const Value: IPublicKey);
begin
  FAccountKey := Value;
end;

procedure TVersionedMessage.TMessageAddressTableLookup.SetReadonlyIndexes(const Value: TBytes);
begin
  FReadonlyIndexes := Value;
end;

procedure TVersionedMessage.TMessageAddressTableLookup.SetWritableIndexes(const Value: TBytes);
begin
  FWritableIndexes := Value;
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

procedure TVersionedMessage.SetAddressTableLookups(const Value: TList<IMessageAddressTableLookup>);
begin
  FAddressTableLookups := Value;
end;

class function TVersionedMessage.DoDeserialize(const Data: TBytes): IMessage;
const
  PKLen   = TPublicKey.PublicKeyLength;
  HLen    = TMessageHeader.TLayout.HeaderLength;
  SvesLen = TShortVectorEncoding.SpanLength;
var
  Prefix, MaskedPrefix, Version: Byte;
  Body: TBytes;
  NumRequiredSignatures: Byte;
  NumReadOnlySignedAccounts: Byte;
  NumReadOnlyUnsignedAccounts: Byte;
  AccLenSlice: TBytes;
  AccLenDec: TShortVecDecode;
  AccountAddressLength: Integer;
  AccountAddressLengthEncodedLength: Integer;
  I: Integer;
  KeySlice: TBytes;
  BlockHashSlice: TBytes;
  InstrLenSlice: TBytes;
  InstrLenDec: TShortVecDecode;
  InstructionsLength: Integer;
  InstructionsLengthEncodedLength: Integer;
  InstructionsOffset: Integer;
  InstrData: TBytes;
  InstrDec: TCompiledInstructionDecode;
  InstructionsDataLength: Integer;
  TableLookupOffset: Integer;
  TableLookupData: TBytes;
  ATLCountDec: TShortVecDecode;
  AddressTableLookupsCount: Integer;
  AddressTableLookupsEncodedCount: Integer;
  Lkp: IMessageAddressTableLookup;
  AccountKeyBytes: TBytes;
  WritableLenDec, ReadonlyLenDec: TShortVecDecode;
  WritableLen, WritableEncLen: Integer;
  ReadonlyLen, ReadonlyEncLen: Integer;
  WritableSlice, ReadonlySlice: TBytes;
  Res: IVersionedMessage;
  LPublicKey: IPublicKey;
begin
  if Length(Data) = 0 then
    raise Exception.Create('Empty message');

  Prefix := Data[0];
  MaskedPrefix := Prefix and TVersionedMessage.VersionPrefixMask;

  if Prefix = MaskedPrefix then
    raise ENotSupportedException.Create('Expected versioned message but received legacy message');

  Version := MaskedPrefix;
  if Version <> 0 then
    raise ENotSupportedException.CreateFmt(
      'Expected versioned message with version 0 but found version %d', [Version]
    );

  Body := TArrayUtils.Slice<Byte>(Data, 1, Length(Data) - 1);

  // Read message header
  NumRequiredSignatures       := Body[TMessageHeader.TLayout.RequiredSignaturesOffset];
  NumReadOnlySignedAccounts   := Body[TMessageHeader.TLayout.ReadOnlySignedAccountsOffset];
  NumReadOnlyUnsignedAccounts := Body[TMessageHeader.TLayout.ReadOnlyUnsignedAccountsOffset];

  // Decode account keys
  AccLenSlice := TArrayUtils.Slice<Byte>(Body, HLen, SvesLen);
  AccLenDec := TShortVectorEncoding.DecodeLength(AccLenSlice);
  AccountAddressLength := AccLenDec.Value;
  AccountAddressLengthEncodedLength := AccLenDec.Length;

  // Create message
  Res := TVersionedMessage.Create;
  Res.Header := TMessageHeader.Create;
  Res.AccountKeys := TList<IPublicKey>.Create;
  Res.Instructions := TList<ICompiledInstruction>.Create;
  Res.AddressTableLookups := TList<IMessageAddressTableLookup>.Create;

  Res.Header.RequiredSignatures := NumRequiredSignatures;
  Res.Header.ReadOnlySignedAccounts := NumReadOnlySignedAccounts;
  Res.Header.ReadOnlyUnsignedAccounts := NumReadOnlyUnsignedAccounts;

  // Accounts
  for I := 0 to AccountAddressLength - 1 do
  begin
    KeySlice := TArrayUtils.Slice<Byte>(
      Body,
      HLen + AccountAddressLengthEncodedLength + I * PKLen,
      PKLen
    );
    LPublicKey := TPublicKey.Create(KeySlice);
    Res.AccountKeys.Add(LPublicKey);
  end;

  // Blockhash
  BlockHashSlice := TArrayUtils.Slice<Byte>(
    Body,
    HLen + AccountAddressLengthEncodedLength + AccountAddressLength * PKLen,
    PKLen
  );
  Res.RecentBlockhash := TEncoders.Base58.EncodeData(BlockHashSlice);

  // Instructions
  InstrLenSlice := TArrayUtils.Slice<Byte>(
    Body,
    HLen + AccountAddressLengthEncodedLength + (AccountAddressLength * PKLen) + PKLen,
    SvesLen
  );
  InstrLenDec := TShortVectorEncoding.DecodeLength(InstrLenSlice);
  InstructionsLength := InstrLenDec.Value;
  InstructionsLengthEncodedLength := InstrLenDec.Length;

  InstructionsOffset :=
    HLen +
    AccountAddressLengthEncodedLength +
    (AccountAddressLength * PKLen) +
    PKLen +
    InstructionsLengthEncodedLength;

  InstrData := TArrayUtils.Slice<Byte>(Body, InstructionsOffset);
  InstructionsDataLength := 0;

  for I := 0 to InstructionsLength - 1 do
  begin
    InstrDec := TCompiledInstruction.Deserialize(InstrData);
    Res.Instructions.Add(InstrDec.Instruction);
    InstrData := TArrayUtils.Slice<Byte>(InstrData, InstrDec.Length);
    Inc(InstructionsDataLength, InstrDec.Length);
  end;

  // Address table lookups
  TableLookupOffset :=
    HLen +
    AccountAddressLengthEncodedLength +
    (AccountAddressLength * PKLen) +
    PKLen +
    InstructionsLengthEncodedLength +
    InstructionsDataLength;

  TableLookupData := TArrayUtils.Slice<Byte>(Body, TableLookupOffset);
  ATLCountDec := TShortVectorEncoding.DecodeLength(TableLookupData);
  AddressTableLookupsCount := ATLCountDec.Value;
  AddressTableLookupsEncodedCount := ATLCountDec.Length;

  TableLookupData := TArrayUtils.Slice<Byte>(TableLookupData, AddressTableLookupsEncodedCount);

  for I := 0 to AddressTableLookupsCount - 1 do
  begin
    AccountKeyBytes := TArrayUtils.Slice<Byte>(TableLookupData, 0, PKLen);
    Lkp := TVersionedMessage.TMessageAddressTableLookup.Create;
    Lkp.AccountKey := TPublicKey.Create(AccountKeyBytes);

    TableLookupData := TArrayUtils.Slice<Byte>(TableLookupData, PKLen);

    WritableLenDec := TShortVectorEncoding.DecodeLength(TableLookupData);
    WritableLen := WritableLenDec.Value;
    WritableEncLen := WritableLenDec.Length;
    WritableSlice := TArrayUtils.Slice<Byte>(TableLookupData, WritableEncLen, WritableLen);
    Lkp.WritableIndexes := WritableSlice;
    TableLookupData := TArrayUtils.Slice<Byte>(TableLookupData, WritableEncLen + WritableLen);

    ReadonlyLenDec := TShortVectorEncoding.DecodeLength(TableLookupData);
    ReadonlyLen := ReadonlyLenDec.Value;
    ReadonlyEncLen := ReadonlyLenDec.Length;
    ReadonlySlice := TArrayUtils.Slice<Byte>(TableLookupData, ReadonlyEncLen, ReadonlyLen);
    Lkp.ReadonlyIndexes := ReadonlySlice;
    TableLookupData := TArrayUtils.Slice<Byte>(TableLookupData, ReadonlyEncLen + ReadonlyLen);

    Res.AddressTableLookups.Add(Lkp);
  end;

  Result := Res;
end;

class function TVersionedMessage.DeserializeMessageVersion(const SerializedMessage: TBytes): string;
var
  Prefix, Masked: Byte;
begin
  Prefix := SerializedMessage[0];
  Masked := Prefix and VersionPrefixMask;

  if Masked = Prefix then
    Exit('legacy');

  Result := Masked.ToString;
end;

class function TVersionedMessage.TAddressTableLookupUtils.SerializeAddressTableLookups(
  List: TList<IMessageAddressTableLookup>): TBytes;
var
  Buf: TMemoryStream;
  EncLen: TBytes;
  I: Integer;
  L: IMessageAddressTableLookup;
begin
  Buf := TMemoryStream.Create;
  try
    Buf.Position := 0;

    EncLen := TShortVectorEncoding.EncodeLength(List.Count);
    Buf.WriteBuffer(EncLen[0], Length(EncLen));

    for I := 0 to List.Count - 1 do
    begin
      L := List[I];

      Buf.WriteBuffer(L.AccountKey.KeyBytes[0], TPublicKey.PublicKeyLength);

      EncLen := TShortVectorEncoding.EncodeLength(Length(L.WritableIndexes));
      Buf.WriteBuffer(EncLen[0], Length(EncLen));
      if Length(L.WritableIndexes) > 0 then
        Buf.WriteBuffer(L.WritableIndexes[0], Length(L.WritableIndexes));

      EncLen := TShortVectorEncoding.EncodeLength(Length(L.ReadonlyIndexes));
      Buf.WriteBuffer(EncLen[0], Length(EncLen));
      if Length(L.ReadonlyIndexes) > 0 then
        Buf.WriteBuffer(L.ReadonlyIndexes[0], Length(L.ReadonlyIndexes));
    end;

    SetLength(Result, Buf.Size);
    Buf.Position := 0;
    Buf.ReadBuffer(Result[0], Buf.Size);
  finally
    Buf.Free;
  end;
end;

end.

