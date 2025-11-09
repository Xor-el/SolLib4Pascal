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

unit SlpTransactionDomain;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  SlpPublicKey,
  SlpShortVectorEncoding,
  SlpArrayUtils,
  SlpCryptoUtils,
  SlpListUtils,
  SlpDataEncoders,
  SlpMessageDomain,
  SlpAccount,
  SlpSysVars,
  SlpTransactionInstruction,
  SlpAccountDomain;

type

  ISignaturePubKeyPair = interface
    ['{E0521039-8A1E-43D7-8C8D-1E6D3E4B0F9E}']
    function GetPublicKey: IPublicKey;
    procedure SetPublicKey(const Value: IPublicKey);
    function GetSignature: TBytes;
    procedure SetSignature(const Value: TBytes);
    /// <summary>
    /// The public key to verify the signature against.
    /// </summary>
    property PublicKey: IPublicKey read GetPublicKey write SetPublicKey;
    /// <summary>
    /// The signature created by the corresponding <see cref="PrivateKey"/> of this pair's <see cref="PublicKey"/>.
    /// </summary>
    property Signature: TBytes read GetSignature write SetSignature;
  end;

  INonceInformation = interface
    ['{0AF2A2A6-3C8B-4285-8F2C-985B6C77C2E7}']
    function GetNonce: string;
    procedure SetNonce(const Value: string);
    function GetInstruction: ITransactionInstruction;
    procedure SetInstruction(const Value: ITransactionInstruction);

    function Clone: INonceInformation;
    /// <summary>
    /// The current blockhash stored in the nonce account.
    /// </summary>
    property Nonce: string read GetNonce write SetNonce;
    /// <summary>
    /// An AdvanceNonceAccount instruction.
    /// </summary>
    property Instruction: ITransactionInstruction read GetInstruction write SetInstruction;
  end;

  /// <summary>
  /// Priority fees information to be used on a transaction.
  /// </summary>
  IPriorityFeesInformation = interface
    ['{4C0B39C8-2A6C-4A2B-9C53-4F28B2A730C8}']

    function GetComputeUnitLimitInstruction: ITransactionInstruction;
    procedure SetComputeUnitLimitInstruction(const AValue: ITransactionInstruction);

    function GetComputeUnitPriceInstruction: ITransactionInstruction;
    procedure SetComputeUnitPriceInstruction(const AValue: ITransactionInstruction);

    /// <summary>
    /// ComputeUnitLimitInstruction instruction for priority fees on a transaction.
    /// </summary>
    property ComputeUnitLimitInstruction: ITransactionInstruction
      read GetComputeUnitLimitInstruction write SetComputeUnitLimitInstruction;

    /// <summary>
    /// ComputeUnitPriceInstruction for priority fees on a transaction.
    /// </summary>
    property ComputeUnitPriceInstruction: ITransactionInstruction
      read GetComputeUnitPriceInstruction write SetComputeUnitPriceInstruction;

    function Clone: IPriorityFeesInformation;
  end;

  ITransaction = interface
    ['{6F2C9D9A-1E7B-4F3B-9F8B-7C16B7A5E3C4}']
    function GetFeePayer: IPublicKey;
    procedure SetFeePayer(const Value: IPublicKey);
    function GetInstructions: TList<ITransactionInstruction>;
    procedure SetInstructions(const Value: TList<ITransactionInstruction>);
    function GetRecentBlockHash: string;
    procedure SetRecentBlockHash(const Value: string);
    function GetNonceInformation: INonceInformation;
    procedure SetNonceInformation(const Value: INonceInformation);
    function GetPriorityFeesInformation: IPriorityFeesInformation;
    procedure SetPriorityFeesInformation(const Value: IPriorityFeesInformation);
    function GetSignatures: TList<ISignaturePubKeyPair>;
    procedure SetSignatures(const Value: TList<ISignaturePubKeyPair>);
    function GetAccountKeys: TList<IPublicKey>;
    procedure SetAccountKeys(const Value: TList<IPublicKey>);
    /// <summary>
    /// Compile the transaction data.
    /// </summary>
    function CompileMessage: TBytes;
    /// <summary>
    /// Verifies the signatures of a complete and signed transaction.
    /// </summary>
    /// <returns>true if they are valid, false otherwise.</returns>
    function VerifySignatures: Boolean;
    /// <summary>
    /// Sign the transaction with the specified signers. Multiple signatures may be applied to a transaction.
    /// The first signature is considered primary and is used to identify and confirm transaction.
    /// <remarks>
    /// <para>
    /// If the transaction <c>FeePayer</c> is not set, the first signer will be used as the transaction fee payer account.
    /// </para>
    /// <para>
    /// Transaction fields SHOULD NOT be modified after the first call to <c>Sign</c> or an externally created signature
    /// has been added to the transaction object, doing so will invalidate the signature and cause the transaction to be
    /// rejected by the cluster.
    /// </para>
    /// <para>
    /// The transaction must have been assigned a valid <c>RecentBlockHash</c> or <c>NonceInformation</c> before invoking this method.
    /// </para>
    /// </remarks>
    /// </summary>
    /// <param name="ASigners">The signer accounts.</param>
    function Sign(const ASigners: TList<IAccount>): Boolean; overload;
    /// <summary>
    /// Sign the transaction with the specified signer. Multiple signatures may be applied to a transaction.
    /// The first signature is considered primary and is used to identify and confirm transaction.
    /// <remarks>
    /// <para>
    /// If the transaction <c>FeePayer</c> is not set, the first signer will be used as the transaction fee payer account.
    /// </para>
    /// <para>
    /// Transaction fields SHOULD NOT be modified after the first call to <c>Sign</c> or an externally created signature
    /// has been added to the transaction object, doing so will invalidate the signature and cause the transaction to be
    /// rejected by the cluster.
    /// </para>
    /// <para>
    /// The transaction must have been assigned a valid <c>RecentBlockHash</c> or <c>NonceInformation</c> before invoking this method.
    /// </para>
    /// </remarks>
    /// </summary>
    /// <param name="signer">The signer account.</param>
    function Sign(const ASigner: IAccount): Boolean; overload;
    /// <summary>
    /// Partially sign a transaction with the specified accounts.
    /// All accounts must correspond to either the fee payer or a signer account in the transaction instructions.
    /// </summary>
    /// <param name="ASigners">The signer accounts.</param>
    procedure PartialSign(const ASigners: TList<IAccount>); overload;
    /// <summary>
    /// Partially sign a transaction with the specified account.
    /// The account must correspond to either the fee payer or a signer account in the transaction instructions.
    /// </summary>
    /// <param name="ASigner">The signer account.</param>
    procedure PartialSign(const ASigner: IAccount); overload;
    /// <summary>
    /// Signs the transaction's message with the passed signer and add it to the transaction, serializing it.
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
    /// <summary>
    /// Adds an externally created signature to the transaction.
    /// The public key must correspond to either the fee payer or a signer account in the transaction instructions.
    /// </summary>
    /// <param name="APublicKey">The public key of the account that signed the transaction.</param>
    /// <param name="ASignature">The transaction signature.</param>
    procedure AddSignature(const APublicKey: IPublicKey; const ASignature: TBytes);
    /// <summary>
    /// Adds one or more instructions to the transaction.
    /// </summary>
    /// <param name="AInstructions">The instructions to add.</param>
    /// <returns>The transaction instance.</returns>
    function Add(const AInstructions: TList<ITransactionInstruction>): ITransaction; overload;
    /// <summary>
    /// Adds an instruction to the transaction.
    /// </summary>
    /// <param name="AInstruction">The instruction to add.</param>
    /// <returns>The transaction instance.</returns>
    function Add(const AInstruction: ITransactionInstruction): ITransaction; overload;
    /// <summary>
    /// Serializes the transaction into wire format.
        /// </summary>
    /// <returns>The transaction encoded in wire format.</returns>
    function Serialize: TBytes;
    /// <summary>
    /// The transaction's fee payer.
    /// </summary>
    property FeePayer: IPublicKey read GetFeePayer write SetFeePayer;
    /// <summary>
    /// The list of <see cref="TransactionInstruction"/>s present in the transaction.
    /// </summary>
    property Instructions: TList<ITransactionInstruction> read GetInstructions write SetInstructions;
    /// <summary>
    /// The recent block hash for the transaction.
    /// </summary>
    property RecentBlockHash: string read GetRecentBlockHash write SetRecentBlockHash;
    /// <summary>
    /// The nonce information of the transaction.
    /// <remarks>
    /// When this is set, the <see cref="NonceInformation"/>'s Nonce is used as the <c>RecentBlockhash</c>.
    /// </remarks>
    /// </summary>
    property NonceInformation: INonceInformation read GetNonceInformation write SetNonceInformation;
    /// <summary>
    /// The priority fees information of the transaction.
    /// <remarks>
    /// When this is set, the <see cref="PriorityFeesInformation"/>'s instructions are added at the beginning of the transaction.
    /// </remarks>
    /// </summary>
    property PriorityFeesInformation: IPriorityFeesInformation read GetPriorityFeesInformation write SetPriorityFeesInformation;
    /// <summary>
    /// The signatures for the transaction.
    /// <remarks>
    /// These are typically created by invoking the <c>Build(IList{Account} signers)</c> method of the <see cref="TransactionBuilder"/>,
    /// but can be created by deserializing a Transaction and adding signatures manually.
    /// </remarks>
    /// </summary>
    property Signatures: TList<ISignaturePubKeyPair> read GetSignatures write SetSignatures;
    property AccountKeys: TList<IPublicKey> read GetAccountKeys write SetAccountKeys;
  end;

  IVersionedTransaction = interface(ITransaction)
    ['{E2A6EAB2-C5D5-4E8F-86AB-523C9B7D5A71}']
    function GetAddressTableLookups: TList<IMessageAddressTableLookup>;
    procedure SetAddressTableLookups(const Value: TList<IMessageAddressTableLookup>);
    /// <summary>
    /// Address Table Lookups
    /// </summary>
    property AddressTableLookups: TList<IMessageAddressTableLookup> read GetAddressTableLookups write SetAddressTableLookups;
  end;

  /// <summary>
  /// A pair corresponding of a public key and it's verifiable signature.
  /// </summary>
  TSignaturePubKeyPair = class(TInterfacedObject, ISignaturePubKeyPair)
  private
    FPublicKey: IPublicKey;
    FSignature: TBytes;

    function GetPublicKey: IPublicKey;
    procedure SetPublicKey(const Value: IPublicKey);
    function GetSignature: TBytes;
    procedure SetSignature(const Value: TBytes);
  public
    constructor Create(const APublicKey: IPublicKey; const ASignature: TBytes);

  end;

  /// <summary>
  /// Nonce information to be used to build an offline transaction.
  /// </summary>
  TNonceInformation = class(TInterfacedObject, INonceInformation)
  private
    FNonce: string;
    FInstruction: ITransactionInstruction;

    function GetNonce: string;
    procedure SetNonce(const Value: string);
    function GetInstruction: ITransactionInstruction;
    procedure SetInstruction(const Value: ITransactionInstruction);

    function Clone: INonceInformation;
  public
    constructor Create(const ANonce: string; const AInstruction: ITransactionInstruction);

  end;

  /// <summary>
  /// Priority fees information to be used on a transaction.
  /// </summary>
  TPriorityFeesInformation = class(TInterfacedObject, IPriorityFeesInformation)
  private
    FComputeUnitLimitInstruction: ITransactionInstruction;
    FComputeUnitPriceInstruction: ITransactionInstruction;

    function GetComputeUnitLimitInstruction: ITransactionInstruction;
    procedure SetComputeUnitLimitInstruction(const AValue: ITransactionInstruction);

    function GetComputeUnitPriceInstruction: ITransactionInstruction;
    procedure SetComputeUnitPriceInstruction(const AValue: ITransactionInstruction);

    function Clone: IPriorityFeesInformation;
  public
    /// <summary>
    /// Initializes a new instance with the given instructions
    /// </summary>
    constructor Create(
      const AComputeUnitLimitInstruction: ITransactionInstruction;
      const AComputeUnitPriceInstruction: ITransactionInstruction);
  end;

  /// <summary>
  /// Represents a Transaction in Solana.
  /// </summary>
  TTransaction = class(TInterfacedObject, ITransaction)
  private
    FFeePayer        : IPublicKey;
    FInstructions    : TList<ITransactionInstruction>;
    FRecentBlockHash : string;
    FNonceInformation: INonceInformation;
    FPriorityFeesInformation : IPriorityFeesInformation;
    FSignatures      : TList<ISignaturePubKeyPair>;
    FAccountKeys     : TList<IPublicKey>;

    function GetFeePayer: IPublicKey;
    procedure SetFeePayer(const Value: IPublicKey);
    function GetInstructions: TList<ITransactionInstruction>;
    procedure SetInstructions(const Value: TList<ITransactionInstruction>);
    function GetRecentBlockHash: string;
    procedure SetRecentBlockHash(const Value: string);
    function GetNonceInformation: INonceInformation;
    procedure SetNonceInformation(const Value: INonceInformation);
    function GetPriorityFeesInformation: IPriorityFeesInformation;
    procedure SetPriorityFeesInformation(const Value: IPriorityFeesInformation);
    function GetSignatures: TList<ISignaturePubKeyPair>;
    procedure SetSignatures(const Value: TList<ISignaturePubKeyPair>);
    function GetAccountKeys: TList<IPublicKey>;
    procedure SetAccountKeys(const Value: TList<IPublicKey>);

    function VerifySignatures: Boolean;

    function Sign(const ASigners: TList<IAccount>): Boolean; overload;
    function Sign(const ASigner: IAccount): Boolean; overload;

    procedure PartialSign(const ASigners: TList<IAccount>); overload;
    procedure PartialSign(const ASigner: IAccount); overload;

    function Build(const ASigner: IAccount): TBytes; overload;
    function Build(const ASigners: TList<IAccount>): TBytes; overload;

    procedure AddSignature(const APublicKey: IPublicKey; const ASignature: TBytes);

    function Add(const AInstructions: TList<ITransactionInstruction>): ITransaction; overload;
    function Add(const AInstruction: ITransactionInstruction): ITransaction; overload;
    /// <summary>
    /// Verifies the signatures a given serialized message.
    /// </summary>
    /// <returns>true if they are valid, false otherwise.</returns>
    function VerifySignaturesInternal(const ASerializedMessage: TBytes): Boolean;
    /// <summary>
    /// Deduplicate the list of given signers.
    /// </summary>
    /// <param name="ASigners">The signer accounts.</param>
    /// <returns>The signer accounts with removed duplicates</returns>
    class function DeduplicateSigners(const ASigners: TList<IAccount>): TList<IAccount>; static;
  protected

    function CompileMessage: TBytes; virtual;
    function Serialize: TBytes; virtual;

    /// <summary>
    /// Deserialize a wire format transaction into a Transaction object.
    /// </summary>
    /// <param name="AData">The data to deserialize into the Transaction object.</param>
    /// <returns>The Transaction object.</returns>
    class function DoDeserialize(const AData: TBytes): ITransaction; virtual;

  public
    constructor Create; virtual;
    destructor Destroy; override;
    /// <summary>
    /// Populate the Transaction from the given message and signatures.
    /// </summary>
    /// <param name="AMessage">The <see cref="Message"/> object.</param>
    /// <param name="ASignatures">The list of signatures.</param>
    /// <returns>The Transaction object.</returns>
    class function Populate(const AMessage: IMessage; const ASignatures: TArray<TBytes> = nil): ITransaction; overload; static;
    /// <summary>
    /// Populate the Transaction from the given compiled message and signatures.
    /// </summary>
    /// <param name="AMessage">The compiled message, as base-64 encoded string.</param>
    /// <param name="ASignatures">The list of signatures.</param>
    /// <returns>The Transaction object.</returns>
    class function Populate(const AMessage: string; const ASignatures: TArray<TBytes> = nil): ITransaction; overload; static;
    /// <summary>
    /// Deserialize a wire format transaction into a Transaction object.
    /// </summary>
    /// <param name="AData">The data to deserialize into the Transaction object.</param>
    /// <returns>The Transaction object.</returns>
    class function Deserialize(const AData: TBytes): ITransaction; overload; static;
    /// <summary>
    /// Deserialize a transaction encoded as base-64 into a Transaction object.
    /// </summary>
    /// <param name="AData">The data to deserialize into the Transaction object.</param>
    /// <returns>The Transaction object.</returns>
    /// <exception cref="ArgumentNilException">Thrown when the given string is empty.</exception>
    class function Deserialize(const AData: string): ITransaction; overload; static;
  end;

  TVersionedTransaction = class(TTransaction, IVersionedTransaction)
  private
    FAddressTableLookups: TList<IMessageAddressTableLookup>;

    function GetAddressTableLookups: TList<IMessageAddressTableLookup>;
    procedure SetAddressTableLookups(const Value: TList<IMessageAddressTableLookup>);

  protected
    function CompileMessage: TBytes; override;
    /// <summary>
    /// Deserialize a wire format transaction into a Transaction object.
    /// </summary>
    /// <param name="AData">The data to deserialize into the Transaction object.</param>
    /// <returns>The Transaction object.</returns>
    class function DoDeserialize(const AData: TBytes): ITransaction; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    /// <summary>
    /// Populate the Transaction from the given message and signatures.
    /// </summary>
    /// <param name="AMessage">The <see cref="Message"/> object.</param>
    /// <param name="ASignatures">The list of signatures.</param>
    /// <returns>The Transaction object.</returns>
    class function Populate(AMessage: IVersionedMessage; const ASignatures: TArray<TBytes> = nil): IVersionedTransaction; overload; static;
    /// <summary>
    /// Populate the Transaction from the given compiled message and signatures.
    /// </summary>
    /// <param name="AMessage">The compiled message, as base-64 encoded string.</param>
    /// <param name="ASignatures">The list of signatures.</param>
    /// <returns>The Transaction object.</returns>
    class function Populate(const AMessage: string; const ASignatures: TArray<TBytes> = nil): IVersionedTransaction; overload; static;
  end;

implementation

uses
  SlpMessageBuilder,
  SlpTransactionBuilder;

{ TSignaturePubKeyPair }

constructor TSignaturePubKeyPair.Create(const APublicKey: IPublicKey; const ASignature: TBytes);
begin
  inherited Create;
  FPublicKey := APublicKey;
  FSignature := ASignature;
end;

function TSignaturePubKeyPair.GetPublicKey: IPublicKey;
begin
  Result := FPublicKey;
end;

function TSignaturePubKeyPair.GetSignature: TBytes;
begin
  Result := FSignature;
end;

procedure TSignaturePubKeyPair.SetPublicKey(const Value: IPublicKey);
begin
  FPublicKey := Value;
end;

procedure TSignaturePubKeyPair.SetSignature(const Value: TBytes);
begin
  FSignature := Value;
end;

{ TNonceInformation }

constructor TNonceInformation.Create(const ANonce: string; const AInstruction: ITransactionInstruction);
begin
  inherited Create;
  FNonce := ANonce;
  FInstruction := AInstruction;
end;

function TNonceInformation.Clone: INonceInformation;
begin
  Result := TNonceInformation.Create(FNonce, FInstruction.Clone);
end;

function TNonceInformation.GetInstruction: ITransactionInstruction;
begin
  Result := FInstruction;
end;

function TNonceInformation.GetNonce: string;
begin
  Result := FNonce;
end;

procedure TNonceInformation.SetInstruction(const Value: ITransactionInstruction);
begin
  FInstruction := Value;
end;

procedure TNonceInformation.SetNonce(const Value: string);
begin
  FNonce := Value;
end;

{ TPriorityFeesInformation }

constructor TPriorityFeesInformation.Create(
  const AComputeUnitLimitInstruction: ITransactionInstruction;
  const AComputeUnitPriceInstruction: ITransactionInstruction);
begin
  inherited Create;
  FComputeUnitLimitInstruction := AComputeUnitLimitInstruction;
  FComputeUnitPriceInstruction := AComputeUnitPriceInstruction;
end;

function TPriorityFeesInformation.Clone: IPriorityFeesInformation;
begin
  Result := TPriorityFeesInformation.Create(
    FComputeUnitLimitInstruction.Clone,
    FComputeUnitPriceInstruction.Clone
  );
end;

function TPriorityFeesInformation.GetComputeUnitLimitInstruction: ITransactionInstruction;
begin
  Result := FComputeUnitLimitInstruction;
end;

procedure TPriorityFeesInformation.SetComputeUnitLimitInstruction(
  const AValue: ITransactionInstruction);
begin
  FComputeUnitLimitInstruction := AValue;
end;

function TPriorityFeesInformation.GetComputeUnitPriceInstruction: ITransactionInstruction;
begin
  Result := FComputeUnitPriceInstruction;
end;

procedure TPriorityFeesInformation.SetComputeUnitPriceInstruction(
  const AValue: ITransactionInstruction);
begin
  FComputeUnitPriceInstruction := AValue;
end;

{ TTransaction }

constructor TTransaction.Create;
begin
  inherited Create;
  FFeePayer := nil;
  FNonceInformation := nil;
  FPriorityFeesInformation := nil;
  FSignatures := TList<ISignaturePubKeyPair>.Create();
  FInstructions := TList<ITransactionInstruction>.Create();
  FAccountKeys := TList<IPublicKey>.Create();
end;

destructor TTransaction.Destroy;
begin
  if Assigned(FSignatures) then
    FSignatures.Free;
  if Assigned(FInstructions) then
    FInstructions.Free;
  if Assigned(FAccountKeys) then
    FAccountKeys.Free;
  inherited;
end;

function TTransaction.GetAccountKeys: TList<IPublicKey>;
begin
  Result := FAccountKeys;
end;

function TTransaction.GetFeePayer: IPublicKey;
begin
  Result := FFeePayer;
end;

function TTransaction.GetInstructions: TList<ITransactionInstruction>;
begin
  Result := FInstructions;
end;

function TTransaction.GetNonceInformation: INonceInformation;
begin
  Result := FNonceInformation;
end;

function TTransaction.GetPriorityFeesInformation: IPriorityFeesInformation;
begin
  Result := FPriorityFeesInformation;
end;

function TTransaction.GetRecentBlockHash: string;
begin
  Result := FRecentBlockHash;
end;

function TTransaction.GetSignatures: TList<ISignaturePubKeyPair>;
begin
  Result := FSignatures;
end;

procedure TTransaction.SetAccountKeys(const Value: TList<IPublicKey>);
begin
  FAccountKeys := Value;
end;

procedure TTransaction.SetFeePayer(const Value: IPublicKey);
begin
  FFeePayer := Value;
end;

procedure TTransaction.SetInstructions(const Value: TList<ITransactionInstruction>);
begin
  FInstructions := Value;
end;

procedure TTransaction.SetNonceInformation(const Value: INonceInformation);
begin
  FNonceInformation := Value;
end;

procedure TTransaction.SetPriorityFeesInformation(const Value: IPriorityFeesInformation);
begin
  FPriorityFeesInformation := Value;
end;

procedure TTransaction.SetRecentBlockHash(const Value: string);
begin
  FRecentBlockHash := Value;
end;

procedure TTransaction.SetSignatures(const Value: TList<ISignaturePubKeyPair>);
begin
  FSignatures := Value;
end;

function TTransaction.CompileMessage: TBytes;
var
  MessageBuilder: IMessageBuilder;
  Instruction: ITransactionInstruction;
begin
  MessageBuilder := TMessageBuilder.Create;

  MessageBuilder.FeePayer := FFeePayer;
  if FRecentBlockHash <> '' then
    MessageBuilder.RecentBlockHash := FRecentBlockHash;

  if Assigned(FNonceInformation) then
    MessageBuilder.NonceInformation := FNonceInformation;

  if Assigned(FPriorityFeesInformation) then
    MessageBuilder.PriorityFeesInformation := FPriorityFeesInformation;

  for Instruction in FInstructions do
    MessageBuilder.AddInstruction(Instruction);

  Result := MessageBuilder.Build;
end;

function TTransaction.VerifySignaturesInternal(const ASerializedMessage: TBytes): Boolean;
var
  Pair: ISignaturePubKeyPair;
begin
  for Pair in FSignatures do
  begin
    if not Pair.PublicKey.Verify(ASerializedMessage, Pair.Signature) then
      Exit(False);
  end;
  Result := True;
end;

function TTransaction.VerifySignatures: Boolean;
begin
  Result := VerifySignaturesInternal(CompileMessage);
end;

class function TTransaction.DeduplicateSigners(const ASigners: TList<IAccount>): TList<IAccount>;
var
  UniqueSigners: TList<IAccount>;
  Seen: TDictionary<IAccount, Byte>;
  Account: IAccount;
begin
  UniqueSigners := TList<IAccount>.Create;
  Seen := TDictionary<IAccount, Byte>.Create;
  try
    for Account in ASigners do
      if not Seen.ContainsKey(Account) then
      begin
        Seen.Add(Account, 0);
        UniqueSigners.Add(Account);
      end;
    Result := UniqueSigners;
  finally
    Seen.Free;
  end;
end;

function TTransaction.Sign(const ASigners: TList<IAccount>): Boolean;
var
  UniqueSigners: TList<IAccount>;
  SerializedMessage, SignatureBytes: TBytes;
  Account: IAccount;
  Pair: ISignaturePubKeyPair;
begin
  UniqueSigners := DeduplicateSigners(ASigners);
  try
    SerializedMessage := CompileMessage;
    for Account in UniqueSigners do
    begin
      SignatureBytes := Account.Sign(SerializedMessage);
      Pair := TSignaturePubKeyPair.Create(
        Account.PublicKey,
        SignatureBytes
      );
      FSignatures.Add(Pair);
    end;
  finally
    UniqueSigners.Free;
  end;

  Result := VerifySignatures;
end;

function TTransaction.Sign(const ASigner: IAccount): Boolean;
var
  Signers: TList<IAccount>;
begin
  Signers := TList<IAccount>.Create;
  try
    Signers.Add(ASigner);
    Result := Sign(Signers);
  finally
    Signers.Free;
  end;
end;

procedure TTransaction.PartialSign(const ASigners: TList<IAccount>);
var
  UniqueSigners: TList<IAccount>;
  SerializedMessage, SignatureBytes: TBytes;
  Account: IAccount;
  Pair: ISignaturePubKeyPair;
begin
  UniqueSigners := DeduplicateSigners(ASigners);
  try
    SerializedMessage := CompileMessage;
    for Account in UniqueSigners do
    begin
      SignatureBytes := Account.Sign(SerializedMessage);
      Pair := TSignaturePubKeyPair.Create(Account.PublicKey, SignatureBytes);
      FSignatures.Add(Pair);
    end;
  finally
    UniqueSigners.Free;
  end;
end;

procedure TTransaction.PartialSign(const ASigner: IAccount);
var
  UniqueSigners: TList<IAccount>;
begin
  UniqueSigners := TList<IAccount>.Create;
  try
    UniqueSigners.Add(ASigner);
    PartialSign(UniqueSigners);
  finally
    UniqueSigners.Free;
  end;
end;

function TTransaction.Build(const ASigner: IAccount): TBytes;
var
  Signers: TList<IAccount>;
begin
  Signers := TList<IAccount>.Create;
  try
    Signers.Add(ASigner);
    Result := Build(Signers);
  finally
    Signers.Free;
  end;
end;

function TTransaction.Build(const ASigners: TList<IAccount>): TBytes;
begin
  Sign(ASigners);
  Result := Serialize;
end;

procedure TTransaction.AddSignature(const APublicKey: IPublicKey; const ASignature: TBytes);
var
  Pair: ISignaturePubKeyPair;
begin
  Pair := TSignaturePubKeyPair.Create(APublicKey, ASignature);
  FSignatures.Add(Pair);
end;

function TTransaction.Add(const AInstructions: TList<ITransactionInstruction>): ITransaction;
var
  Instruction: ITransactionInstruction;
begin
  for Instruction in AInstructions do
    FInstructions.Add(Instruction);
  Result := Self;
end;

function TTransaction.Add(const AInstruction: ITransactionInstruction): ITransaction;
var
  Instructions: TList<ITransactionInstruction>;
begin
  Instructions := TList<ITransactionInstruction>.Create;
  try
    Instructions.Add(AInstruction);
    Result := Add(Instructions);
  finally
    Instructions.Free;
  end;
end;

function TTransaction.Serialize: TBytes;
var
  SignaturesLength, SerializedMessage: TBytes;
  Buffer: TMemoryStream;
  Pair: ISignaturePubKeyPair;
begin
  SignaturesLength := TShortVectorEncoding.EncodeLength(FSignatures.Count);
  SerializedMessage := CompileMessage;
  Buffer := TMemoryStream.Create;
  try
    Buffer.Size := Length(SignaturesLength) +
                   (FSignatures.Count * TTransactionBuilder.SignatureLength) +
                   Length(SerializedMessage);
    Buffer.Position := 0;

    Buffer.WriteBuffer(SignaturesLength[0], Length(SignaturesLength));

    for Pair in FSignatures do
      if Length(Pair.Signature) > 0 then
        Buffer.WriteBuffer(Pair.Signature[0], Length(Pair.Signature));

    if Length(SerializedMessage) > 0 then
      Buffer.WriteBuffer(SerializedMessage[0], Length(SerializedMessage));

    SetLength(Result, Buffer.Size);
    Buffer.Position := 0;
    Buffer.ReadBuffer(Result[0], Buffer.Size);
  finally
    Buffer.Free;
  end;
end;

class function TTransaction.Populate(const AMessage: IMessage; const ASignatures: TArray<TBytes> = nil): ITransaction;
var
  I, J, K, AccountLength: Integer;
  Accounts: TList<IAccountMeta>;
  CompiledInstruction: ICompiledInstruction;
  Instruction: ITransactionInstruction;
  MessageBytes: TBytes;
  IsSignatureValid: Boolean;
  Signer: IPublicKey;
  Pair: ISignaturePubKeyPair;
begin
  Result := TTransaction.Create;

  Result.RecentBlockHash := AMessage.RecentBlockhash;

  Result.AccountKeys.AddRange(AMessage.AccountKeys);

  if AMessage.Header.RequiredSignatures > 0 then
    Result.FeePayer := AMessage.AccountKeys[0];

  if Length(ASignatures) > 0 then
  begin
    for I := 0 to High(ASignatures) do
    begin
      MessageBytes := AMessage.Serialize;
      IsSignatureValid := TEd25519Crypto.Verify(AMessage.AccountKeys[I].KeyBytes, MessageBytes, ASignatures[I]);
      Signer := AMessage.AccountKeys[I];

      if not IsSignatureValid then
      begin
        for K := 0 to AMessage.AccountKeys.Count - 1 do
        begin
          if TEd25519Crypto.Verify(AMessage.AccountKeys[K].KeyBytes, MessageBytes, ASignatures[I]) then
          begin
            IsSignatureValid := True;
            Signer := AMessage.AccountKeys[K];
            Break;
          end;
        end;
      end;

      if IsSignatureValid then
      begin
        Pair := TSignaturePubKeyPair.Create(Signer, ASignatures[I]);
        Result.Signatures.Add(Pair);
      end;
    end;
  end;

  for I := 0 to AMessage.Instructions.Count - 1 do
  begin
    CompiledInstruction := AMessage.Instructions[I];
    AccountLength := TShortVectorEncoding.DecodeLength(CompiledInstruction.KeyIndicesCount).Value;

    Accounts := TList<IAccountMeta>.Create;
    for J := 0 to AccountLength - 1 do
    begin
      K := CompiledInstruction.KeyIndices[J];
      Accounts.Add(TAccountMeta.Create(
        AMessage.AccountKeys[K],
        AMessage.IsAccountWritable(K),
        (TListUtils.Any<ISignaturePubKeyPair>(Result.Signatures,
          function(pair: ISignaturePubKeyPair): Boolean
          begin
            Result := pair.PublicKey.Equals(AMessage.AccountKeys[K]);
          end)) or AMessage.IsAccountSigner(K)));
    end;

    Instruction := TTransactionInstruction.Create(
      AMessage.AccountKeys[CompiledInstruction.ProgramIdIndex].KeyBytes,
      Accounts,
      CompiledInstruction.Data
    );

    if (I = 0) and TListUtils.Any<IAccountMeta>(Accounts,
      function(AccMeta: IAccountMeta): Boolean
      begin
        Result := SameStr(AccMeta.PublicKey.Key, TSysVars.RecentBlockHashesKey.Key);
      end) then
    begin
      Result.NonceInformation := TNonceInformation.Create(Result.RecentBlockHash, Instruction);
      Continue;
    end;

    Result.Instructions.Add(Instruction);
  end;
end;


class function TTransaction.Populate(const AMessage: string; const ASignatures: TArray<TBytes> = nil): ITransaction;
var
  Msg: IMessage;
begin
  Msg := TMessage.Deserialize(AMessage);
  Result := Populate(Msg, ASignatures);
end;

class function TTransaction.Deserialize(const AData: string): ITransaction;
var
  Bytes: TBytes;
begin
  if AData = '' then
    raise EArgumentNilException.Create('data');

  try
    Bytes := TEncoders.Base64.DecodeData(AData);
  except
    on E: Exception do
      raise Exception.Create('could not decode transaction data from base64');
  end;

  Result := Deserialize(Bytes);
end;

class function TTransaction.Deserialize(const AData: TBytes): ITransaction;
begin
  // Polymorphic dispatch to DoDeserialize (overridden by TVersionedTransaction)
  Result := DoDeserialize(AData);
end;

class function TTransaction.DoDeserialize(const AData: TBytes): ITransaction;
var
  VecDecode       : TShortVecDecode;
  I               : Integer;
  SignaturesLength: Integer;
  EncodedLength   : Integer;
  Signatures      : TArray<TBytes>;
  Signature       : TBytes;
  Prefix          : Byte;
  MaskedPrefix    : Byte;
  Msg             : IMessage;
begin
  // Read number of signatures
  VecDecode := TShortVectorEncoding.DecodeLength(
    TArrayUtils.Slice<Byte>(AData, 0, TShortVectorEncoding.SpanLength)
  );
  SignaturesLength := VecDecode.Value;
  EncodedLength    := VecDecode.Length;

  SetLength(Signatures, SignaturesLength);
  for I := 0 to SignaturesLength - 1 do
  begin
    Signature := TArrayUtils.Slice<Byte>(
      AData,
      EncodedLength + (I * TTransactionBuilder.SignatureLength),
      TTransactionBuilder.SignatureLength
    );
    Signatures[I] := Signature;
  end;

  Prefix       := AData[EncodedLength + (SignaturesLength * TTransactionBuilder.SignatureLength)];
  MaskedPrefix := Prefix and TVersionedMessage.VersionPrefixMask;

  // If the transaction is a VersionedTransaction, use VersionedTransaction.Deserialize instead.
  if Prefix <> MaskedPrefix then
    Exit(TVersionedTransaction.Deserialize(AData));

  Msg := TMessage.Deserialize(
    TArrayUtils.Slice<Byte>(
      AData,
      EncodedLength + (SignaturesLength * TTransactionBuilder.SignatureLength)
    )
  );
  Result := Populate(Msg, Signatures);
end;

{ TVersionedTransaction }

constructor TVersionedTransaction.Create;
begin
  inherited Create;
  FAddressTableLookups := TList<IMessageAddressTableLookup>.Create;
  FInstructions := TList<ITransactionInstruction>.Create;
  FSignatures   := TList<ISignaturePubKeyPair>.Create;
  FAddressTableLookups := TList<IMessageAddressTableLookup>.Create;
  FAccountKeys := TList<IPublicKey>.Create;
end;

destructor TVersionedTransaction.Destroy;
begin
  if Assigned(FAddressTableLookups) then
    FAddressTableLookups.Free;
  inherited;
end;

function TVersionedTransaction.GetAddressTableLookups: TList<IMessageAddressTableLookup>;
begin
  Result := FAddressTableLookups;
end;

procedure TVersionedTransaction.SetAddressTableLookups(const Value: TList<IMessageAddressTableLookup>);
begin
  FAddressTableLookups := Value;
end;

function TVersionedTransaction.CompileMessage: TBytes;
var
  MessageBuilder: IVersionedMessageBuilder;
  Instruction: ITransactionInstruction;
begin
  MessageBuilder := TVersionedMessageBuilder.Create;
  MessageBuilder.FeePayer := FFeePayer;

  if FRecentBlockHash <> '' then
    MessageBuilder.RecentBlockHash := FRecentBlockHash;

  if Assigned(FNonceInformation) then
    MessageBuilder.NonceInformation := FNonceInformation;

  if Assigned(FPriorityFeesInformation) then
    MessageBuilder.PriorityFeesInformation := FPriorityFeesInformation;

  for Instruction in FInstructions do
    MessageBuilder.AddInstruction(Instruction);

  if Assigned(FAccountKeys) then
    MessageBuilder.AccountKeys.AddRange(FAccountKeys);

  if Assigned(FAddressTableLookups) then
    MessageBuilder.AddressTableLookups.AddRange(FAddressTableLookups);

  Result := MessageBuilder.Build;
end;

class function TVersionedTransaction.Populate(AMessage: IVersionedMessage; const ASignatures: TArray<TBytes> = nil): IVersionedTransaction;
var
  I, J, K, AccountLength: Integer;
  Accounts: TList<IAccountMeta>;
  CompiledInstruction: ICompiledInstruction;
  Instruction: IVersionedTransactionInstruction;
  Pair: ISignaturePubKeyPair;
begin
  Result := TVersionedTransaction.Create;
  try
    Result.RecentBlockHash := AMessage.RecentBlockhash;

    Result.AccountKeys.AddRange(AMessage.AccountKeys);
    Result.AddressTableLookups.AddRange(AMessage.AddressTableLookups);

    if AMessage.Header.RequiredSignatures > 0 then
      Result.FeePayer := AMessage.AccountKeys[0];

    if Length(ASignatures) > 0 then
    begin
      for I := 0 to High(ASignatures) do
      begin
        Pair := TSignaturePubKeyPair.Create(AMessage.AccountKeys[I], ASignatures[I]);
        Result.Signatures.Add(Pair);
      end;
    end;

    for I := 0 to AMessage.Instructions.Count - 1 do
    begin
      CompiledInstruction := AMessage.Instructions[I];
      AccountLength := TShortVectorEncoding.DecodeLength(CompiledInstruction.KeyIndicesCount).Value;

      Accounts := TList<IAccountMeta>.Create;
      for J := 0 to AccountLength - 1 do
      begin
        K := CompiledInstruction.KeyIndices[J];
        if K >= AMessage.AccountKeys.Count then
          Continue;
        Accounts.Add(TAccountMeta.Create(
          AMessage.AccountKeys[K],
          AMessage.IsAccountWritable(K),
          (TListUtils.Any<ISignaturePubKeyPair>(Result.Signatures,
            function(Pair: ISignaturePubKeyPair): Boolean
            begin
              Result := Pair.PublicKey.Equals(AMessage.AccountKeys[K]);
            end)) or AMessage.IsAccountSigner(K)));
      end;

      Instruction := TVersionedTransactionInstruction.Create(
        AMessage.AccountKeys[CompiledInstruction.ProgramIdIndex].KeyBytes,
        Accounts,
        CompiledInstruction.Data,
        CompiledInstruction.KeyIndices
      );

      if (I = 0) and TListUtils.Any<IAccountMeta>(Accounts,
        function(AccMeta: IAccountMeta): Boolean
        begin
          Result := SameStr(AccMeta.PublicKey.Key, TSysVars.RecentBlockHashesKey.Key);
        end) then
      begin
        Result.NonceInformation := TNonceInformation.Create(Result.GetRecentBlockHash, Instruction);
        Continue;
      end;

      Result.Instructions.Add(Instruction);
    end;

  except
    raise;
  end;
end;

class function TVersionedTransaction.Populate(const AMessage: string; const ASignatures: TArray<TBytes> = nil): IVersionedTransaction;
var
  Msg: IVersionedMessage;
begin
  Msg := TVersionedMessage.Deserialize(AMessage) as IVersionedMessage;
  Result := Populate(Msg, ASignatures);
end;

class function TVersionedTransaction.DoDeserialize(const AData: TBytes): ITransaction;
var
  VecDecode       : TShortVecDecode;
  I               : Integer;
  SignaturesLength: Integer;
  EncodedLength   : Integer;
  Signatures      : TArray<TBytes>;
  Signature       : TBytes;
  MessageOffset   : Integer;
  VersionedMessage: IVersionedMessage;
begin
  VecDecode := TShortVectorEncoding.DecodeLength(
    TArrayUtils.Slice<Byte>(AData, 0, TShortVectorEncoding.SpanLength)
  );
  SignaturesLength := VecDecode.Value;
  EncodedLength    := VecDecode.Length;

  SetLength(Signatures, SignaturesLength);
  for I := 0 to SignaturesLength - 1 do
  begin
    Signature := TArrayUtils.Slice<Byte>(
      AData,
      EncodedLength + (I * TTransactionBuilder.SignatureLength),
      TTransactionBuilder.SignatureLength
    );
    Signatures[I] := Signature;
  end;

  MessageOffset := EncodedLength + (SignaturesLength * TTransactionBuilder.SignatureLength);
  VersionedMessage := TVersionedMessage.Deserialize(TArrayUtils.Slice<Byte>(AData, MessageOffset)) as IVersionedMessage;
  Result := Populate(VersionedMessage, Signatures);
end;

end.
