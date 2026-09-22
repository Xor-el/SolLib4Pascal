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

unit SlpTransactionBuilder;

{$I ../Include/SolLib.inc}

interface

uses
  SysUtils,
  Classes,
  Generics.Collections,
  SlpMessageBuilder,
  SlpMessageDomain,
  SlpAccount,
  SlpTransactionInstruction,
  SlpPublicKey,
  SlpTransactionDomain,
  SlpTransactionConfig,
  SlpRpcEnum,
  SlpShortVectorEncoding,
  SlpArrayUtilities,
  SlpListUtilities,
  SlpDataEncoderUtilities;

type
  /// <summary>
  /// Defines the interface for transaction builders.
  /// </summary>
  ITransactionBuilder = interface
    ['{A49B5B03-39F5-4B9A-93A5-9DA205B7D902}']

    /// <summary>
    /// Serializes the message into a byte array.
    /// </summary>
    function Serialize: TBytes;

    /// <summary>
    /// Adds a signature to the current transaction.
    /// </summary>
    /// <param name="ASignature">The signature (bytes).</param>
    function AddSignature(const ASignature: TBytes): ITransactionBuilder; overload;

    /// <summary>
    /// Adds a signature to the current transaction.
    /// </summary>
    /// <param name="ASignature">The signature (Base58 string).</param>
    function AddSignature(const ASignature: string): ITransactionBuilder; overload;

    /// <summary>
    /// Sets the recent block hash for the transaction.
    /// </summary>
    /// <param name="ARecentBlockHash">The recent block hash as a base58 encoded string.</param>
    /// <returns>The transaction builder, so instruction addition can be chained.</returns>
    function SetRecentBlockHash(const ARecentBlockHash: string): ITransactionBuilder;

    /// <summary>
    /// Sets the nonce information for the transaction.
    /// <remarks>Whenever this is set, it is used instead of the blockhash.</remarks>
    /// </summary>
    /// <param name="ANonceInfo">The nonce information object to use.</param>
    /// <returns>The transaction builder, so instruction addition can be chained.</returns>
    function SetNonceInformation(const ANonceInfo: INonceInformation): ITransactionBuilder;

    /// <summary>
    /// Sets the priority fees information for the transaction.
    /// </summary>
    /// <param name="APriorityFeesInfo">The priority fees information object to use.</param>
    /// <returns>The transaction builder, so instruction addition can be chained.</returns>
    function SetPriorityFeesInformation(const APriorityFeesInfo: IPriorityFeesInformation): ITransactionBuilder;

    /// <summary>
    /// Sets the fee payer for the transaction.
    /// </summary>
    /// <param name="APublicKey">The public key of the account that will pay the transaction fee.</param>
    /// <returns>The transaction builder, so instruction addition can be chained.</returns>
    function SetFeePayer(const APublicKey: IPublicKey): ITransactionBuilder;

    /// <summary>
    /// Adds a new instruction to the transaction.
    /// </summary>
    /// <param name="AInstruction">The instruction to add.</param>
    /// <returns>The transaction builder, so instruction addition can be chained.</returns>
    function AddInstruction(const AInstruction: ITransactionInstruction): ITransactionBuilder;

    /// <summary>
    /// Compiles the transaction's message into wire format, ready to be signed.
    /// </summary>
    /// <returns>The serialized message.</returns>
    function CompileMessage: TBytes;

    /// <summary>
    /// Signs the transaction's message with the passed signer and adds it to the transaction, serializing it.
    /// </summary>
    /// <param name="ASigner">The signer.</param>
    /// <returns>The serialized transaction.</returns>
    function Build(const ASigner: IAccount): TBytes; overload;

    /// <summary>
    /// Signs the transaction's message with the passed list of signers and adds them to the transaction, serializing it.
    /// </summary>
    /// <param name="ASigners">The list of signers.</param>
    /// <returns>The serialized transaction.</returns>
    function Build(const ASigners: TList<IAccount>): TBytes; overload;
  end;

  /// <summary>
  /// Fluent builder for version 0 transactions. Version 0 messages carry address lookup
  /// tables, and their compute-budget and priority-fee settings are expressed as Compute
  /// Budget Program instructions (via <c>SetPriorityFeesInformation</c>), so this surface
  /// deliberately omits <c>SetTransactionConfig</c> (which is a version 1 concept).
  /// </summary>
  IVersionedTxV0Builder = interface
    ['{C1E4A2D0-1F3B-4A6E-9B2C-7D8E5F0A1B23}']

    /// <summary>Serializes the transaction (signature count + signatures + message) into a byte array.</summary>
    function Serialize: TBytes;

    /// <summary>Adds a signature to the current transaction (bytes, Base58-encoded internally).</summary>
    function AddSignature(const ASignature: TBytes): IVersionedTxV0Builder; overload;

    /// <summary>Adds a signature to the current transaction (already Base58-encoded).</summary>
    function AddSignature(const ASignature: string): IVersionedTxV0Builder; overload;

    /// <summary>Sets the recent block hash for the transaction.</summary>
    function SetRecentBlockHash(const ARecentBlockHash: string): IVersionedTxV0Builder;

    /// <summary>Sets the durable nonce information (overrides the blockhash if present).</summary>
    function SetNonceInformation(const ANonceInfo: INonceInformation): IVersionedTxV0Builder;

    /// <summary>Sets the priority fees information (emitted as Compute Budget instructions).</summary>
    function SetPriorityFeesInformation(const APriorityFeesInfo: IPriorityFeesInformation): IVersionedTxV0Builder;

    /// <summary>Sets the fee payer.</summary>
    function SetFeePayer(const APublicKey: IPublicKey): IVersionedTxV0Builder;

    /// <summary>Adds an instruction to the message.</summary>
    function AddInstruction(const AInstruction: ITransactionInstruction): IVersionedTxV0Builder;

    /// <summary>Adds a single address table lookup to the message.</summary>
    function AddAddressTableLookup(const ALookup: IMessageAddressTableLookup): IVersionedTxV0Builder;

    /// <summary>Adds multiple address table lookups to the message.</summary>
    function AddAddressTableLookups(const ALookups: TList<IMessageAddressTableLookup>): IVersionedTxV0Builder;

    /// <summary>Compiles the versioned message bytes without signing.</summary>
    function CompileMessage: TBytes;

    /// <summary>Signs and builds with a single signer.</summary>
    function Build(const ASigner: IAccount): TBytes; overload;

    /// <summary>Signs and builds with multiple signers.</summary>
    function Build(const ASigners: TList<IAccount>): TBytes; overload;
  end;

  /// <summary>
  /// Fluent builder for version 1 transactions. Version 1 messages carry the
  /// compute-budget and priority-fee settings directly via <c>SetTransactionConfig</c>
  /// and do not support address lookup tables, so this surface deliberately omits the
  /// <c>AddAddressTableLookup</c> methods (which are a version 0 concept).
  /// </summary>
  IVersionedTxV1Builder = interface
    ['{D2F5B3E1-2A4C-4B7F-8C3D-9E0F1A2B3C45}']

    /// <summary>Serializes the transaction (message followed by raw signatures) into a byte array.</summary>
    function Serialize: TBytes;

    /// <summary>Adds a signature to the current transaction (bytes, Base58-encoded internally).</summary>
    function AddSignature(const ASignature: TBytes): IVersionedTxV1Builder; overload;

    /// <summary>Adds a signature to the current transaction (already Base58-encoded).</summary>
    function AddSignature(const ASignature: string): IVersionedTxV1Builder; overload;

    /// <summary>Sets the recent block hash for the transaction.</summary>
    function SetRecentBlockHash(const ARecentBlockHash: string): IVersionedTxV1Builder;

    /// <summary>Sets the durable nonce information (overrides the blockhash if present).</summary>
    function SetNonceInformation(const ANonceInfo: INonceInformation): IVersionedTxV1Builder;

    /// <summary>Sets the fee payer.</summary>
    function SetFeePayer(const APublicKey: IPublicKey): IVersionedTxV1Builder;

    /// <summary>Sets the in-message transaction configuration.</summary>
    function SetTransactionConfig(const AConfig: TTransactionConfig): IVersionedTxV1Builder;

    /// <summary>Adds an instruction to the message.</summary>
    function AddInstruction(const AInstruction: ITransactionInstruction): IVersionedTxV1Builder;

    /// <summary>Compiles the versioned message bytes without signing.</summary>
    function CompileMessage: TBytes;

    /// <summary>Signs and builds with a single signer.</summary>
    function Build(const ASigner: IAccount): TBytes; overload;

    /// <summary>Signs and builds with multiple signers.</summary>
    function Build(const ASigners: TList<IAccount>): TBytes; overload;
  end;

  /// <summary>
  /// The single entry point for building transactions. Each method returns a builder whose
  /// surface exposes only the methods valid for that kind, so an invalid combination (an
  /// address table lookup on version 1, or an in-message transaction config on version 0)
  /// cannot be expressed. The concrete builders are internal; this facade is the only way to
  /// construct one.
  /// </summary>
  TTransactionBuilders = class sealed
  public
    /// <summary>Creates a builder for a legacy (unversioned) transaction.</summary>
    class function Legacy: ITransactionBuilder; static;

    /// <summary>Creates a builder for a version 0 transaction (address lookup tables).</summary>
    class function V0: IVersionedTxV0Builder; static;

    /// <summary>Creates a builder for a version 1 transaction (in-message transaction config).</summary>
    class function V1: IVersionedTxV1Builder; static;
  end;

implementation

const
  /// <summary>The length of an Ed25519 signature.</summary>
  SignatureLength = 64;

type
  /// <summary>
  /// Shared state and logic for the transaction builders: the pending Base58 signatures, the
  /// cached serialized message, and the signing + envelope-assembly algorithms. The legacy and
  /// versioned builders derive from this and add their own version-appropriate surface.
  /// </summary>
  TTransactionBuilderBase = class(TInterfacedObject)
  strict protected
    FMessageBuilder: IMessageBuilder;
    FSignatures: TList<string>;
    FSerializedMessage: TBytes;

    /// <summary>Whether the transaction serializes with the version 1 envelope (message first, no signature count).</summary>
    function IsVersion1: Boolean; virtual;
    /// <summary>Appends a raw signature, Base58-encoding it.</summary>
    procedure AppendSignature(const ASignature: TBytes); overload;
    /// <summary>Appends an already Base58-encoded signature.</summary>
    procedure AppendSignature(const ASignature: string); overload;
    /// <summary>
    /// Signs the compiled message with each signer, appending the Base58 signatures in the exact
    /// order (and multiplicity) the runtime expects, and caching one signature per pubkey.
    /// </summary>
    procedure SignMessage(const ASigners: TList<IAccount>);
    /// <summary>
    /// Assembles the transaction envelope. Legacy and version 0 emit a short-vector signature
    /// count followed by the signatures then the message; version 1 emits the message followed
    /// by the raw signatures with no count.
    /// </summary>
    function SerializeEnvelope: TBytes;
    /// <summary>Signs with the given signers and returns the serialized transaction.</summary>
    function BuildWith(const ASigners: TList<IAccount>): TBytes;
  public
    constructor Create(const AMessageBuilder: IMessageBuilder);
    destructor Destroy; override;
  end;

  /// <summary>
  /// Concrete builder for legacy (unversioned) transactions. Internal: instances are created
  /// only through <see cref="TTransactionBuilders.Legacy"/>.
  /// </summary>
  TTransactionBuilder = class(TTransactionBuilderBase, ITransactionBuilder)
  private
    function Serialize: TBytes;
    function AddSignature(const ASignature: TBytes): ITransactionBuilder; overload;
    function AddSignature(const ASignature: string): ITransactionBuilder; overload;
    function SetRecentBlockHash(const ARecentBlockHash: string): ITransactionBuilder;
    function SetNonceInformation(const ANonceInfo: INonceInformation): ITransactionBuilder;
    function SetPriorityFeesInformation(const APriorityFeesInfo: IPriorityFeesInformation): ITransactionBuilder;
    function SetFeePayer(const APublicKey: IPublicKey): ITransactionBuilder;
    function AddInstruction(const AInstruction: ITransactionInstruction): ITransactionBuilder;
    function CompileMessage: TBytes;
    function Build(const ASigner: IAccount): TBytes; overload;
    function Build(const ASigners: TList<IAccount>): TBytes; overload;
  public
    constructor Create;
  end;

  /// <summary>
  /// The shared state and logic behind the versioned transaction facets. A single core
  /// is created for a fixed version and is driven through a thin version-specific facet;
  /// the facet holds the core, so it stays alive for the lifetime of the returned builder.
  /// </summary>
  IVersionedTxCore = interface
    ['{E3A6C4F2-3B5D-4C8A-9D4E-0F1A2B3C4D56}']
    procedure SetRecentBlockHash(const AValue: string);
    procedure SetNonceInformation(const AValue: INonceInformation);
    procedure SetPriorityFeesInformation(const AValue: IPriorityFeesInformation);
    procedure SetFeePayer(const AValue: IPublicKey);
    procedure AddInstruction(const AInstruction: ITransactionInstruction);
    procedure AddSignature(const ASignature: TBytes); overload;
    procedure AddSignature(const ASignature: string); overload;
    procedure AddAddressTableLookup(const ALookup: IMessageAddressTableLookup);
    procedure AddAddressTableLookups(const ALookups: TList<IMessageAddressTableLookup>);
    procedure SetTransactionConfig(const AConfig: TTransactionConfig);
    function CompileMessage: TBytes;
    function Serialize: TBytes;
    function Build(const ASigners: TList<IAccount>): TBytes;
  end;

  TVersionedTxCore = class(TTransactionBuilderBase, IVersionedTxCore)
  strict private
    FVersioned: IVersionedMessageBuilder;
    FIsV1: Boolean;
  strict protected
    function IsVersion1: Boolean; override;
  public
    constructor Create(const AVersion: TTransactionVersion);

    procedure SetRecentBlockHash(const AValue: string);
    procedure SetNonceInformation(const AValue: INonceInformation);
    procedure SetPriorityFeesInformation(const AValue: IPriorityFeesInformation);
    procedure SetFeePayer(const AValue: IPublicKey);
    procedure AddInstruction(const AInstruction: ITransactionInstruction);
    procedure AddSignature(const ASignature: TBytes); overload;
    procedure AddSignature(const ASignature: string); overload;
    procedure AddAddressTableLookup(const ALookup: IMessageAddressTableLookup);
    procedure AddAddressTableLookups(const ALookups: TList<IMessageAddressTableLookup>);
    procedure SetTransactionConfig(const AConfig: TTransactionConfig);
    function CompileMessage: TBytes;
    function Serialize: TBytes;
    function Build(const ASigners: TList<IAccount>): TBytes;
  end;

  /// <summary>Version 0 facet: forwards to the core and returns itself so chaining stays version-typed.</summary>
  TVersionedTxV0Facet = class sealed(TInterfacedObject, IVersionedTxV0Builder)
  private
    FCore: IVersionedTxCore;
  public
    constructor Create(const ACore: IVersionedTxCore);
    function Serialize: TBytes;
    function AddSignature(const ASignature: TBytes): IVersionedTxV0Builder; overload;
    function AddSignature(const ASignature: string): IVersionedTxV0Builder; overload;
    function SetRecentBlockHash(const ARecentBlockHash: string): IVersionedTxV0Builder;
    function SetNonceInformation(const ANonceInfo: INonceInformation): IVersionedTxV0Builder;
    function SetPriorityFeesInformation(const APriorityFeesInfo: IPriorityFeesInformation): IVersionedTxV0Builder;
    function SetFeePayer(const APublicKey: IPublicKey): IVersionedTxV0Builder;
    function AddInstruction(const AInstruction: ITransactionInstruction): IVersionedTxV0Builder;
    function AddAddressTableLookup(const ALookup: IMessageAddressTableLookup): IVersionedTxV0Builder;
    function AddAddressTableLookups(const ALookups: TList<IMessageAddressTableLookup>): IVersionedTxV0Builder;
    function CompileMessage: TBytes;
    function Build(const ASigner: IAccount): TBytes; overload;
    function Build(const ASigners: TList<IAccount>): TBytes; overload;
  end;

  /// <summary>Version 1 facet: forwards to the core and returns itself so chaining stays version-typed.</summary>
  TVersionedTxV1Facet = class sealed(TInterfacedObject, IVersionedTxV1Builder)
  private
    FCore: IVersionedTxCore;
  public
    constructor Create(const ACore: IVersionedTxCore);
    function Serialize: TBytes;
    function AddSignature(const ASignature: TBytes): IVersionedTxV1Builder; overload;
    function AddSignature(const ASignature: string): IVersionedTxV1Builder; overload;
    function SetRecentBlockHash(const ARecentBlockHash: string): IVersionedTxV1Builder;
    function SetNonceInformation(const ANonceInfo: INonceInformation): IVersionedTxV1Builder;
    function SetFeePayer(const APublicKey: IPublicKey): IVersionedTxV1Builder;
    function SetTransactionConfig(const AConfig: TTransactionConfig): IVersionedTxV1Builder;
    function AddInstruction(const AInstruction: ITransactionInstruction): IVersionedTxV1Builder;
    function CompileMessage: TBytes;
    function Build(const ASigner: IAccount): TBytes; overload;
    function Build(const ASigners: TList<IAccount>): TBytes; overload;
  end;

{ TTransactionBuilderBase }

constructor TTransactionBuilderBase.Create(const AMessageBuilder: IMessageBuilder);
begin
  inherited Create;
  FMessageBuilder := AMessageBuilder;
  FSignatures := TList<string>.Create;
  FSerializedMessage := nil;
end;

destructor TTransactionBuilderBase.Destroy;
begin
  FSignatures.Free;
  inherited;
end;

function TTransactionBuilderBase.IsVersion1: Boolean;
begin
  Result := False;
end;

procedure TTransactionBuilderBase.AppendSignature(const ASignature: TBytes);
begin
  FSignatures.Add(TBase58Encoder.EncodeData(ASignature));
end;

procedure TTransactionBuilderBase.AppendSignature(const ASignature: string);
begin
  FSignatures.Add(ASignature);
end;

procedure TTransactionBuilderBase.SignMessage(const ASigners: TList<IAccount>);
var
  LSignerByKey: TDictionary<string, IAccount>;
  LSigner: IAccount;
  LKey: string;
  LI: Integer;
begin
  if (ASigners = nil) or (ASigners.Count = 0) then
    raise Exception.Create('no signers for the transaction');

  if FMessageBuilder.FeePayer = nil then
    raise Exception.Create('fee payer is required');

  // Build the canonical message once; all signatures must verify against this.
  FSerializedMessage := FMessageBuilder.Build;

  // Map each signing pubkey to a signer (first occurrence wins). Ed25519 signatures are
  // deterministic, so any account with a given pubkey produces the same signature - there is
  // no need to group duplicates or cache.
  LSignerByKey := TDictionary<string, IAccount>.Create;
  try
    for LI := 0 to ASigners.Count - 1 do
    begin
      LSigner := ASigners[LI];
      if (LSigner <> nil) and not LSignerByKey.ContainsKey(LSigner.PublicKey.Key) then
        LSignerByKey.Add(LSigner.PublicKey.Key, LSigner);
    end;

    // Emit signatures strictly in the account order the runtime expects, one per key that
    // has a matching signer.
    for LKey in FMessageBuilder.GetAccountMetaPublicKeys do
      if LSignerByKey.TryGetValue(LKey, LSigner) then
        FSignatures.Add(TBase58Encoder.EncodeData(LSigner.Sign(FSerializedMessage)));
  finally
    LSignerByKey.Free;
  end;
end;

function TTransactionBuilderBase.SerializeEnvelope: TBytes;
var
  LSigLenEnc, LSigBytes: TBytes;
  LMS: TMemoryStream;
  LSig: string;
  LCapacity: Integer;
  LIsV1: Boolean;
begin
  if Length(FSerializedMessage) = 0 then
    FSerializedMessage := FMessageBuilder.Build;

  LIsV1 := IsVersion1;
  if LIsV1 then
  begin
    // Version 1: message bytes followed by raw signatures, no signature count prefix.
    LSigLenEnc := nil;
    LCapacity := (FSignatures.Count * SignatureLength) + Length(FSerializedMessage);
  end
  else
  begin
    LSigLenEnc := TShortVectorEncoding.EncodeLength(FSignatures.Count);
    LCapacity := Length(LSigLenEnc) + (FSignatures.Count * SignatureLength) + Length(FSerializedMessage);
  end;

  LMS := TMemoryStream.Create;
  try
    LMS.Size := LCapacity;

    if LIsV1 then
      LMS.WriteBuffer(FSerializedMessage[0], Length(FSerializedMessage))
    else
      LMS.WriteBuffer(LSigLenEnc[0], Length(LSigLenEnc));

    for LSig in FSignatures do
    begin
      LSigBytes := TBase58Encoder.DecodeData(LSig);
      LMS.WriteBuffer(LSigBytes[0], Length(LSigBytes));
    end;

    if not LIsV1 then
      LMS.WriteBuffer(FSerializedMessage[0], Length(FSerializedMessage));

    Result := TArrayUtilities.StreamToBytes(LMS);
  finally
    LMS.Free;
  end;
end;

function TTransactionBuilderBase.BuildWith(const ASigners: TList<IAccount>): TBytes;
begin
  SignMessage(ASigners);
  Result := SerializeEnvelope;
end;

{ TTransactionBuilder }

constructor TTransactionBuilder.Create;
begin
  inherited Create(TMessageBuilderFactory.NewLegacy);
end;

function TTransactionBuilder.Serialize: TBytes;
begin
  Result := SerializeEnvelope;
end;

function TTransactionBuilder.AddInstruction(const AInstruction: ITransactionInstruction): ITransactionBuilder;
begin
  FMessageBuilder.AddInstruction(AInstruction);
  Result := Self;
end;

function TTransactionBuilder.AddSignature(const ASignature: TBytes): ITransactionBuilder;
begin
  AppendSignature(ASignature);
  Result := Self;
end;

function TTransactionBuilder.AddSignature(const ASignature: string): ITransactionBuilder;
begin
  AppendSignature(ASignature);
  Result := Self;
end;

function TTransactionBuilder.Build(const ASigner: IAccount): TBytes;
var
  LSigners: TList<IAccount>;
begin
  LSigners := TListUtilities.Singleton<IAccount>(ASigner);
  try
    Result := BuildWith(LSigners);
  finally
    LSigners.Free;
  end;
end;

function TTransactionBuilder.Build(const ASigners: TList<IAccount>): TBytes;
begin
  Result := BuildWith(ASigners);
end;

function TTransactionBuilder.CompileMessage: TBytes;
begin
  Result := FMessageBuilder.Build;
end;

function TTransactionBuilder.SetFeePayer(const APublicKey: IPublicKey): ITransactionBuilder;
begin
  FMessageBuilder.FeePayer := APublicKey;
  Result := Self;
end;

function TTransactionBuilder.SetNonceInformation(const ANonceInfo: INonceInformation): ITransactionBuilder;
begin
  FMessageBuilder.NonceInformation := ANonceInfo;
  Result := Self;
end;

function TTransactionBuilder.SetPriorityFeesInformation(const APriorityFeesInfo: IPriorityFeesInformation): ITransactionBuilder;
begin
  FMessageBuilder.PriorityFeesInformation := APriorityFeesInfo;
  Result := Self;
end;

function TTransactionBuilder.SetRecentBlockHash(const ARecentBlockHash: string): ITransactionBuilder;
begin
  FMessageBuilder.RecentBlockHash := ARecentBlockHash;
  Result := Self;
end;

{ TVersionedTxCore }

constructor TVersionedTxCore.Create(const AVersion: TTransactionVersion);
var
  LVersioned: IVersionedMessageBuilder;
begin
  LVersioned := TMessageBuilderFactory.NewVersioned;
  inherited Create(LVersioned);
  FVersioned := LVersioned;
  case AVersion of
    TTransactionVersion.V0:
      begin
        LVersioned.Version := 0;
        FIsV1 := False;
      end;
    TTransactionVersion.V1:
      begin
        LVersioned.Version := 1;
        FIsV1 := True;
      end;
  else
    raise EArgumentException.Create('A versioned transaction builder requires version V0 or V1.');
  end;
end;

function TVersionedTxCore.IsVersion1: Boolean;
begin
  Result := FIsV1;
end;

procedure TVersionedTxCore.AddAddressTableLookup(const ALookup: IMessageAddressTableLookup);
begin
  FVersioned.AddressTableLookups.Add(ALookup);
end;

procedure TVersionedTxCore.AddAddressTableLookups(const ALookups: TList<IMessageAddressTableLookup>);
begin
  FVersioned.AddressTableLookups.AddRange(ALookups);
end;

procedure TVersionedTxCore.AddInstruction(const AInstruction: ITransactionInstruction);
begin
  FMessageBuilder.AddInstruction(AInstruction);
end;

procedure TVersionedTxCore.AddSignature(const ASignature: TBytes);
begin
  AppendSignature(ASignature);
end;

procedure TVersionedTxCore.AddSignature(const ASignature: string);
begin
  AppendSignature(ASignature);
end;

function TVersionedTxCore.Build(const ASigners: TList<IAccount>): TBytes;
begin
  Result := BuildWith(ASigners);
end;

function TVersionedTxCore.CompileMessage: TBytes;
begin
  Result := FMessageBuilder.Build;
end;

function TVersionedTxCore.Serialize: TBytes;
begin
  Result := SerializeEnvelope;
end;

procedure TVersionedTxCore.SetFeePayer(const AValue: IPublicKey);
begin
  FMessageBuilder.FeePayer := AValue;
end;

procedure TVersionedTxCore.SetNonceInformation(const AValue: INonceInformation);
begin
  FMessageBuilder.NonceInformation := AValue;
end;

procedure TVersionedTxCore.SetPriorityFeesInformation(const AValue: IPriorityFeesInformation);
begin
  FMessageBuilder.PriorityFeesInformation := AValue;
end;

procedure TVersionedTxCore.SetRecentBlockHash(const AValue: string);
begin
  FMessageBuilder.RecentBlockHash := AValue;
end;

procedure TVersionedTxCore.SetTransactionConfig(const AConfig: TTransactionConfig);
begin
  FVersioned.TransactionConfig := AConfig;
end;

{ TVersionedTxV0Facet }

constructor TVersionedTxV0Facet.Create(const ACore: IVersionedTxCore);
begin
  inherited Create;
  FCore := ACore;
end;

function TVersionedTxV0Facet.AddAddressTableLookup(const ALookup: IMessageAddressTableLookup): IVersionedTxV0Builder;
begin
  FCore.AddAddressTableLookup(ALookup);
  Result := Self;
end;

function TVersionedTxV0Facet.AddAddressTableLookups(const ALookups: TList<IMessageAddressTableLookup>): IVersionedTxV0Builder;
begin
  FCore.AddAddressTableLookups(ALookups);
  Result := Self;
end;

function TVersionedTxV0Facet.AddInstruction(const AInstruction: ITransactionInstruction): IVersionedTxV0Builder;
begin
  FCore.AddInstruction(AInstruction);
  Result := Self;
end;

function TVersionedTxV0Facet.AddSignature(const ASignature: TBytes): IVersionedTxV0Builder;
begin
  FCore.AddSignature(ASignature);
  Result := Self;
end;

function TVersionedTxV0Facet.AddSignature(const ASignature: string): IVersionedTxV0Builder;
begin
  FCore.AddSignature(ASignature);
  Result := Self;
end;

function TVersionedTxV0Facet.Build(const ASigner: IAccount): TBytes;
var
  LSigners: TList<IAccount>;
begin
  LSigners := TListUtilities.Singleton<IAccount>(ASigner);
  try
    Result := FCore.Build(LSigners);
  finally
    LSigners.Free;
  end;
end;

function TVersionedTxV0Facet.Build(const ASigners: TList<IAccount>): TBytes;
begin
  Result := FCore.Build(ASigners);
end;

function TVersionedTxV0Facet.CompileMessage: TBytes;
begin
  Result := FCore.CompileMessage;
end;

function TVersionedTxV0Facet.Serialize: TBytes;
begin
  Result := FCore.Serialize;
end;

function TVersionedTxV0Facet.SetFeePayer(const APublicKey: IPublicKey): IVersionedTxV0Builder;
begin
  FCore.SetFeePayer(APublicKey);
  Result := Self;
end;

function TVersionedTxV0Facet.SetNonceInformation(const ANonceInfo: INonceInformation): IVersionedTxV0Builder;
begin
  FCore.SetNonceInformation(ANonceInfo);
  Result := Self;
end;

function TVersionedTxV0Facet.SetPriorityFeesInformation(const APriorityFeesInfo: IPriorityFeesInformation): IVersionedTxV0Builder;
begin
  FCore.SetPriorityFeesInformation(APriorityFeesInfo);
  Result := Self;
end;

function TVersionedTxV0Facet.SetRecentBlockHash(const ARecentBlockHash: string): IVersionedTxV0Builder;
begin
  FCore.SetRecentBlockHash(ARecentBlockHash);
  Result := Self;
end;

{ TVersionedTxV1Facet }

constructor TVersionedTxV1Facet.Create(const ACore: IVersionedTxCore);
begin
  inherited Create;
  FCore := ACore;
end;

function TVersionedTxV1Facet.AddInstruction(const AInstruction: ITransactionInstruction): IVersionedTxV1Builder;
begin
  FCore.AddInstruction(AInstruction);
  Result := Self;
end;

function TVersionedTxV1Facet.AddSignature(const ASignature: TBytes): IVersionedTxV1Builder;
begin
  FCore.AddSignature(ASignature);
  Result := Self;
end;

function TVersionedTxV1Facet.AddSignature(const ASignature: string): IVersionedTxV1Builder;
begin
  FCore.AddSignature(ASignature);
  Result := Self;
end;

function TVersionedTxV1Facet.Build(const ASigner: IAccount): TBytes;
var
  LSigners: TList<IAccount>;
begin
  LSigners := TListUtilities.Singleton<IAccount>(ASigner);
  try
    Result := FCore.Build(LSigners);
  finally
    LSigners.Free;
  end;
end;

function TVersionedTxV1Facet.Build(const ASigners: TList<IAccount>): TBytes;
begin
  Result := FCore.Build(ASigners);
end;

function TVersionedTxV1Facet.CompileMessage: TBytes;
begin
  Result := FCore.CompileMessage;
end;

function TVersionedTxV1Facet.Serialize: TBytes;
begin
  Result := FCore.Serialize;
end;

function TVersionedTxV1Facet.SetFeePayer(const APublicKey: IPublicKey): IVersionedTxV1Builder;
begin
  FCore.SetFeePayer(APublicKey);
  Result := Self;
end;

function TVersionedTxV1Facet.SetNonceInformation(const ANonceInfo: INonceInformation): IVersionedTxV1Builder;
begin
  FCore.SetNonceInformation(ANonceInfo);
  Result := Self;
end;

function TVersionedTxV1Facet.SetRecentBlockHash(const ARecentBlockHash: string): IVersionedTxV1Builder;
begin
  FCore.SetRecentBlockHash(ARecentBlockHash);
  Result := Self;
end;

function TVersionedTxV1Facet.SetTransactionConfig(const AConfig: TTransactionConfig): IVersionedTxV1Builder;
begin
  FCore.SetTransactionConfig(AConfig);
  Result := Self;
end;

{ TTransactionBuilders }

class function TTransactionBuilders.Legacy: ITransactionBuilder;
begin
  Result := TTransactionBuilder.Create;
end;

class function TTransactionBuilders.V0: IVersionedTxV0Builder;
begin
  Result := TVersionedTxV0Facet.Create(TVersionedTxCore.Create(TTransactionVersion.V0));
end;

class function TTransactionBuilders.V1: IVersionedTxV1Builder;
begin
  Result := TVersionedTxV1Facet.Create(TVersionedTxCore.Create(TTransactionVersion.V1));
end;

end.
