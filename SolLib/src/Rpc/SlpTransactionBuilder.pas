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
  /// Concrete builder for legacy (unversioned) transactions. Internal: instances are created
  /// only through <see cref="TTransactionBuilders.Legacy"/>.
  /// </summary>
  TTransactionBuilder = class(TInterfacedObject, ITransactionBuilder)
  private
    FMessageBuilder: IMessageBuilder;
    FSignatures: TList<string>;
    FSerializedMessage: TBytes;

    procedure Sign(const ASigners: TList<IAccount>);
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
    destructor Destroy; override;
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

  TVersionedTxCore = class(TInterfacedObject, IVersionedTxCore)
  private
    FMessageBuilder: IVersionedMessageBuilder;
    FSignatures: TList<string>;
    FSerializedMessage: TBytes;
    FIsV1: Boolean;
  public
    constructor Create(const AVersion: TTransactionVersion);
    destructor Destroy; override;

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

{ Shared helpers }

/// <summary>
/// Signs <paramref name="AMessageBuilder"/> with each signer and appends the Base58
/// signatures to <paramref name="ASignatures"/> in the exact order (and multiplicity)
/// the runtime expects, caching one signature per pubkey. Sets
/// <paramref name="ASerializedMessage"/> to the canonical message all signatures cover.
/// </summary>
procedure SignInto(const AMessageBuilder: IMessageBuilder;
  const ASigners: TList<IAccount>; const ASignatures: TList<string>;
  out ASerializedMessage: TBytes);
var
  LI, LUsedCount: Integer;
  LOrderedKeys: TArray<string>;
  LGroupedSignersByKey: TObjectDictionary<string, TList<IAccount>>;
  LNextIndexByKey: TDictionary<string, Integer>;
  LSignatureCacheByKey: TDictionary<string, string>;
  LSigner, LSignerToUse: IAccount;
  LPubKey, LKey, LSigBase58: string;
  LSignersForKey: TList<IAccount>;
  LSigBytes: TBytes;
begin
  if (ASigners = nil) or (ASigners.Count = 0) then
    raise Exception.Create('no signers for the transaction');

  if AMessageBuilder.FeePayer = nil then
    raise Exception.Create('fee payer is required');

  // Build the canonical message once; all signatures must verify against this
  ASerializedMessage := AMessageBuilder.Build;

  // Keys in the exact order (and multiplicity) the runtime expects for signatures.
  LOrderedKeys := AMessageBuilder.GetAccountMetaPublicKeys;

  // ---- Build: pubkey -> list of matching signer accounts -------------------
  LGroupedSignersByKey := TObjectDictionary<string, TList<IAccount>>.Create([doOwnsValues]);
  LNextIndexByKey := TDictionary<string, Integer>.Create;
  LSignatureCacheByKey := TDictionary<string, string>.Create;
  try
    // Group ASigners by their pubkey, preserving duplicates & input order
    for LI := 0 to ASigners.Count - 1 do
    begin
      LSigner := ASigners[LI];
      if LSigner = nil then
        Continue;

      LPubKey := LSigner.PublicKey.Key;

      if not LGroupedSignersByKey.TryGetValue(LPubKey, LSignersForKey) then
      begin
        LSignersForKey := TList<IAccount>.Create;
        LGroupedSignersByKey.Add(LPubKey, LSignersForKey);
      end;
      LSignersForKey.Add(LSigner);
    end;

    // ---- Produce signatures strictly in message order ----------------------
    for LKey in LOrderedKeys do
    begin
      // If no signer provided for this key, skip (caller may enforce required count later)
      if not LGroupedSignersByKey.TryGetValue(LKey, LSignersForKey) or (LSignersForKey.Count = 0) then
        Continue;

      // If we've already signed this pubkey for this message, reuse the cached signature
      if LSignatureCacheByKey.TryGetValue(LKey, LSigBase58) then
      begin
        ASignatures.Add(LSigBase58);

        // Still advance the attribution cursor so duplicates in ASigners are "consumed" in order
        if LNextIndexByKey.TryGetValue(LKey, LUsedCount) then
          LNextIndexByKey[LKey] := LUsedCount + 1
        else
          LNextIndexByKey.Add(LKey, 1);

        Continue;
      end;

      // First time we encounter this key: pick the next unused signer for this key (or reuse the first if exhausted)
      if not LNextIndexByKey.TryGetValue(LKey, LUsedCount) then
        LUsedCount := 0;

      if LUsedCount < LSignersForKey.Count then
        LSignerToUse := LSignersForKey[LUsedCount]
      else
        LSignerToUse := LSignersForKey[0];

      LNextIndexByKey.AddOrSetValue(LKey, LUsedCount + 1);

      // Sign ONCE for this pubkey and cache (Ed25519 is deterministic; later duplicates reuse the same signature)
      LSigBytes := LSignerToUse.Sign(ASerializedMessage);
      LSigBase58 := TBase58Encoder.EncodeData(LSigBytes);

      LSignatureCacheByKey.Add(LKey, LSigBase58);
      ASignatures.Add(LSigBase58);
    end;

  finally
    LSignatureCacheByKey.Free;
    LNextIndexByKey.Free;
    LGroupedSignersByKey.Free;
  end;
end;

/// <summary>
/// Assembles the transaction envelope from the Base58 signatures and the serialized
/// message. Legacy and version 0 emit a short-vector signature count followed by the
/// signatures then the message; version 1 emits the message followed by the raw
/// signatures with no count.
/// </summary>
function WriteEnvelope(const ASignatures: TList<string>;
  const ASerializedMessage: TBytes; AIsV1: Boolean): TBytes;
var
  LSigLenEnc: TBytes;
  LMS: TMemoryStream;
  LSig: string;
  LSigBytes: TBytes;
  LCapacity: Integer;
begin
  if AIsV1 then
  begin
    // Version 1: message bytes followed by raw signatures, no signature count prefix.
    LSigLenEnc := nil;
    LCapacity := (ASignatures.Count * SignatureLength) + Length(ASerializedMessage);
  end
  else
  begin
    LSigLenEnc := TShortVectorEncoding.EncodeLength(ASignatures.Count);
    LCapacity := Length(LSigLenEnc) + (ASignatures.Count * SignatureLength) + Length(ASerializedMessage);
  end;

  LMS := TMemoryStream.Create;
  try
    LMS.Size := LCapacity;

    if AIsV1 then
      LMS.WriteBuffer(ASerializedMessage[0], Length(ASerializedMessage))
    else
      LMS.WriteBuffer(LSigLenEnc[0], Length(LSigLenEnc));

    for LSig in ASignatures do
    begin
      LSigBytes := TBase58Encoder.DecodeData(LSig);
      LMS.WriteBuffer(LSigBytes[0], Length(LSigBytes));
    end;

    if not AIsV1 then
      LMS.WriteBuffer(ASerializedMessage[0], Length(ASerializedMessage));

    Result := TArrayUtilities.StreamToBytes(LMS);
  finally
    LMS.Free;
  end;
end;

{ TTransactionBuilder }

constructor TTransactionBuilder.Create;
begin
  inherited Create;
  FMessageBuilder := TMessageBuilderFactory.NewLegacy;
  FSignatures := TList<string>.Create;
  FSerializedMessage := nil;
end;

destructor TTransactionBuilder.Destroy;
begin
  if Assigned(FSignatures) then
    FSignatures.Free;
  inherited;
end;

function TTransactionBuilder.Serialize: TBytes;
begin
  if Length(FSerializedMessage) = 0 then
    FSerializedMessage := FMessageBuilder.Build;
  Result := WriteEnvelope(FSignatures, FSerializedMessage, False);
end;

function TTransactionBuilder.AddInstruction(const AInstruction: ITransactionInstruction): ITransactionBuilder;
begin
  FMessageBuilder.AddInstruction(AInstruction);
  Result := Self;
end;

function TTransactionBuilder.AddSignature(const ASignature: TBytes): ITransactionBuilder;
begin
  FSignatures.Add(TBase58Encoder.EncodeData(ASignature));
  Result := Self;
end;

function TTransactionBuilder.AddSignature(const ASignature: string): ITransactionBuilder;
begin
  FSignatures.Add(ASignature);
  Result := Self;
end;

function TTransactionBuilder.Build(const ASigner: IAccount): TBytes;
var
  LSigners: TList<IAccount>;
begin
  LSigners := TListUtilities.Singleton<IAccount>(ASigner);
  try
    Result := Build(LSigners);
  finally
    LSigners.Free;
  end;
end;

function TTransactionBuilder.Build(const ASigners: TList<IAccount>): TBytes;
begin
  Sign(ASigners);
  Result := Serialize;
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

procedure TTransactionBuilder.Sign(const ASigners: TList<IAccount>);
begin
  SignInto(FMessageBuilder, ASigners, FSignatures, FSerializedMessage);
end;

{ TVersionedTxCore }

constructor TVersionedTxCore.Create(const AVersion: TTransactionVersion);
begin
  inherited Create;
  FMessageBuilder := TMessageBuilderFactory.NewVersioned;
  case AVersion of
    TTransactionVersion.V0:
      begin
        FMessageBuilder.Version := 0;
        FIsV1 := False;
      end;
    TTransactionVersion.V1:
      begin
        FMessageBuilder.Version := 1;
        FIsV1 := True;
      end;
  else
    raise EArgumentException.Create('A versioned transaction builder requires version V0 or V1.');
  end;
  FSignatures := TList<string>.Create;
  FSerializedMessage := nil;
end;

destructor TVersionedTxCore.Destroy;
begin
  if Assigned(FSignatures) then
    FSignatures.Free;
  inherited;
end;

procedure TVersionedTxCore.AddAddressTableLookup(const ALookup: IMessageAddressTableLookup);
begin
  FMessageBuilder.AddressTableLookups.Add(ALookup);
end;

procedure TVersionedTxCore.AddAddressTableLookups(const ALookups: TList<IMessageAddressTableLookup>);
begin
  FMessageBuilder.AddressTableLookups.AddRange(ALookups);
end;

procedure TVersionedTxCore.AddInstruction(const AInstruction: ITransactionInstruction);
begin
  FMessageBuilder.AddInstruction(AInstruction);
end;

procedure TVersionedTxCore.AddSignature(const ASignature: TBytes);
begin
  FSignatures.Add(TBase58Encoder.EncodeData(ASignature));
end;

procedure TVersionedTxCore.AddSignature(const ASignature: string);
begin
  FSignatures.Add(ASignature);
end;

function TVersionedTxCore.Build(const ASigners: TList<IAccount>): TBytes;
begin
  SignInto(FMessageBuilder, ASigners, FSignatures, FSerializedMessage);
  Result := Serialize;
end;

function TVersionedTxCore.CompileMessage: TBytes;
begin
  Result := FMessageBuilder.Build;
end;

function TVersionedTxCore.Serialize: TBytes;
begin
  if Length(FSerializedMessage) = 0 then
    FSerializedMessage := FMessageBuilder.Build;
  Result := WriteEnvelope(FSignatures, FSerializedMessage, FIsV1);
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
  FMessageBuilder.TransactionConfig := AConfig;
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
