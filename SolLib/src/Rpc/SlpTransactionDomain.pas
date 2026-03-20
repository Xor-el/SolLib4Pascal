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

unit SlpTransactionDomain;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  SlpPublicKey,
  SlpShortVectorEncoding,
  SlpArrayUtilities,
  SlpCryptoUtilities,
  SlpListUtilities,
  SlpDataEncoderUtilities,
  SlpMessageDomain,
  SlpAccount,
  SlpSysVars,
  SlpTransactionInstruction,
  SlpAccountDomain;

type

  ISignaturePubKeyPair = interface
    ['{E0521039-8A1E-43D7-8C8D-1E6D3E4B0F9E}']
    function GetPublicKey: IPublicKey;
    procedure SetPublicKey(const AValue: IPublicKey);
    function GetSignature: TBytes;
    procedure SetSignature(const AValue: TBytes);
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
    procedure SetNonce(const AValue: string);
    function GetInstruction: ITransactionInstruction;
    procedure SetInstruction(const AValue: ITransactionInstruction);

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
    procedure SetFeePayer(const AValue: IPublicKey);
    function GetInstructions: TList<ITransactionInstruction>;
    procedure SetInstructions(const AValue: TList<ITransactionInstruction>);
    function GetRecentBlockHash: string;
    procedure SetRecentBlockHash(const AValue: string);
    function GetNonceInformation: INonceInformation;
    procedure SetNonceInformation(const AValue: INonceInformation);
    function GetPriorityFeesInformation: IPriorityFeesInformation;
    procedure SetPriorityFeesInformation(const AValue: IPriorityFeesInformation);
    function GetSignatures: TList<ISignaturePubKeyPair>;
    procedure SetSignatures(const AValue: TList<ISignaturePubKeyPair>);
    function GetAccountKeys: TList<IPublicKey>;
    procedure SetAccountKeys(const AValue: TList<IPublicKey>);
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
    procedure SetAddressTableLookups(const AValue: TList<IMessageAddressTableLookup>);
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
    procedure SetPublicKey(const AValue: IPublicKey);
    function GetSignature: TBytes;
    procedure SetSignature(const AValue: TBytes);
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
    procedure SetNonce(const AValue: string);
    function GetInstruction: ITransactionInstruction;
    procedure SetInstruction(const AValue: ITransactionInstruction);

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
    FFeePayer: IPublicKey;
    FInstructions: TList<ITransactionInstruction>;
    FRecentBlockHash: string;
    FNonceInformation: INonceInformation;
    FPriorityFeesInformation: IPriorityFeesInformation;
    FSignatures: TList<ISignaturePubKeyPair>;
    FAccountKeys: TList<IPublicKey>;

    function GetFeePayer: IPublicKey;
    procedure SetFeePayer(const AValue: IPublicKey);
    function GetInstructions: TList<ITransactionInstruction>;
    procedure SetInstructions(const AValue: TList<ITransactionInstruction>);
    function GetRecentBlockHash: string;
    procedure SetRecentBlockHash(const AValue: string);
    function GetNonceInformation: INonceInformation;
    procedure SetNonceInformation(const AValue: INonceInformation);
    function GetPriorityFeesInformation: IPriorityFeesInformation;
    procedure SetPriorityFeesInformation(const AValue: IPriorityFeesInformation);
    function GetSignatures: TList<ISignaturePubKeyPair>;
    procedure SetSignatures(const AValue: TList<ISignaturePubKeyPair>);
    function GetAccountKeys: TList<IPublicKey>;
    procedure SetAccountKeys(const AValue: TList<IPublicKey>);

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
    procedure SetAddressTableLookups(const AValue: TList<IMessageAddressTableLookup>);

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

procedure TSignaturePubKeyPair.SetPublicKey(const AValue: IPublicKey);
begin
  FPublicKey := AValue;
end;

procedure TSignaturePubKeyPair.SetSignature(const AValue: TBytes);
begin
  FSignature := AValue;
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

procedure TNonceInformation.SetInstruction(const AValue: ITransactionInstruction);
begin
  FInstruction := AValue;
end;

procedure TNonceInformation.SetNonce(const AValue: string);
begin
  FNonce := AValue;
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

procedure TTransaction.SetAccountKeys(const AValue: TList<IPublicKey>);
begin
  FAccountKeys := AValue;
end;

procedure TTransaction.SetFeePayer(const AValue: IPublicKey);
begin
  FFeePayer := AValue;
end;

procedure TTransaction.SetInstructions(const AValue: TList<ITransactionInstruction>);
begin
  FInstructions := AValue;
end;

procedure TTransaction.SetNonceInformation(const AValue: INonceInformation);
begin
  FNonceInformation := AValue;
end;

procedure TTransaction.SetPriorityFeesInformation(const AValue: IPriorityFeesInformation);
begin
  FPriorityFeesInformation := AValue;
end;

procedure TTransaction.SetRecentBlockHash(const AValue: string);
begin
  FRecentBlockHash := AValue;
end;

procedure TTransaction.SetSignatures(const AValue: TList<ISignaturePubKeyPair>);
begin
  FSignatures := AValue;
end;

function TTransaction.CompileMessage: TBytes;
var
  LMessageBuilder: IMessageBuilder;
  LInstruction: ITransactionInstruction;
begin
  LMessageBuilder := TMessageBuilder.Create;

  LMessageBuilder.FeePayer := FFeePayer;
  if FRecentBlockHash <> '' then
    LMessageBuilder.RecentBlockHash := FRecentBlockHash;

  if Assigned(FNonceInformation) then
    LMessageBuilder.NonceInformation := FNonceInformation;

  if Assigned(FPriorityFeesInformation) then
    LMessageBuilder.PriorityFeesInformation := FPriorityFeesInformation;

  for LInstruction in FInstructions do
    LMessageBuilder.AddInstruction(LInstruction);

  Result := LMessageBuilder.Build;
end;

function TTransaction.VerifySignaturesInternal(const ASerializedMessage: TBytes): Boolean;
var
  LPair: ISignaturePubKeyPair;
begin
  for LPair in FSignatures do
  begin
    if not LPair.PublicKey.Verify(ASerializedMessage, LPair.Signature) then
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
  LUniqueSigners: TList<IAccount>;
  LSeen: TDictionary<IAccount, Byte>;
  LAccount: IAccount;
begin
  LUniqueSigners := TList<IAccount>.Create;
  LSeen := TDictionary<IAccount, Byte>.Create;
  try
    for LAccount in ASigners do
      if not LSeen.ContainsKey(LAccount) then
      begin
        LSeen.Add(LAccount, 0);
        LUniqueSigners.Add(LAccount);
      end;
    Result := LUniqueSigners;
  finally
    LSeen.Free;
  end;
end;

function TTransaction.Sign(const ASigners: TList<IAccount>): Boolean;
var
  LUniqueSigners: TList<IAccount>;
  LSerializedMessage, LSignatureBytes: TBytes;
  LAccount: IAccount;
  LPair: ISignaturePubKeyPair;
begin
  LUniqueSigners := DeduplicateSigners(ASigners);
  try
    LSerializedMessage := CompileMessage;
    for LAccount in LUniqueSigners do
    begin
      LSignatureBytes := LAccount.Sign(LSerializedMessage);
      LPair := TSignaturePubKeyPair.Create(
        LAccount.PublicKey,
        LSignatureBytes
      );
      FSignatures.Add(LPair);
    end;
  finally
    LUniqueSigners.Free;
  end;

  Result := VerifySignatures;
end;

function TTransaction.Sign(const ASigner: IAccount): Boolean;
var
  LSigners: TList<IAccount>;
begin
  LSigners := TList<IAccount>.Create;
  try
    LSigners.Add(ASigner);
    Result := Sign(LSigners);
  finally
    LSigners.Free;
  end;
end;

procedure TTransaction.PartialSign(const ASigners: TList<IAccount>);
var
  LUniqueSigners: TList<IAccount>;
  LSerializedMessage, LSignatureBytes: TBytes;
  LAccount: IAccount;
  LPair: ISignaturePubKeyPair;
begin
  LUniqueSigners := DeduplicateSigners(ASigners);
  try
    LSerializedMessage := CompileMessage;
    for LAccount in LUniqueSigners do
    begin
      LSignatureBytes := LAccount.Sign(LSerializedMessage);
      LPair := TSignaturePubKeyPair.Create(LAccount.PublicKey, LSignatureBytes);
      FSignatures.Add(LPair);
    end;
  finally
    LUniqueSigners.Free;
  end;
end;

procedure TTransaction.PartialSign(const ASigner: IAccount);
var
  LUniqueSigners: TList<IAccount>;
begin
  LUniqueSigners := TList<IAccount>.Create;
  try
    LUniqueSigners.Add(ASigner);
    PartialSign(LUniqueSigners);
  finally
    LUniqueSigners.Free;
  end;
end;

function TTransaction.Build(const ASigner: IAccount): TBytes;
var
  LSigners: TList<IAccount>;
begin
  LSigners := TList<IAccount>.Create;
  try
    LSigners.Add(ASigner);
    Result := Build(LSigners);
  finally
    LSigners.Free;
  end;
end;

function TTransaction.Build(const ASigners: TList<IAccount>): TBytes;
begin
  Sign(ASigners);
  Result := Serialize;
end;

procedure TTransaction.AddSignature(const APublicKey: IPublicKey; const ASignature: TBytes);
var
  LPair: ISignaturePubKeyPair;
begin
  LPair := TSignaturePubKeyPair.Create(APublicKey, ASignature);
  FSignatures.Add(LPair);
end;

function TTransaction.Add(const AInstructions: TList<ITransactionInstruction>): ITransaction;
var
  LInstruction: ITransactionInstruction;
begin
  for LInstruction in AInstructions do
    FInstructions.Add(LInstruction);
  Result := Self;
end;

function TTransaction.Add(const AInstruction: ITransactionInstruction): ITransaction;
var
  LInstructions: TList<ITransactionInstruction>;
begin
  LInstructions := TList<ITransactionInstruction>.Create;
  try
    LInstructions.Add(AInstruction);
    Result := Add(LInstructions);
  finally
    LInstructions.Free;
  end;
end;

function TTransaction.Serialize: TBytes;
var
  LSignaturesLength, LSerializedMessage: TBytes;
  LBuffer: TMemoryStream;
  LPair: ISignaturePubKeyPair;
begin
  LSignaturesLength := TShortVectorEncoding.EncodeLength(FSignatures.Count);
  LSerializedMessage := CompileMessage;
  LBuffer := TMemoryStream.Create;
  try
    LBuffer.Size := Length(LSignaturesLength) +
                   (FSignatures.Count * TTransactionBuilder.SignatureLength) +
                   Length(LSerializedMessage);
    LBuffer.Position := 0;

    LBuffer.WriteBuffer(LSignaturesLength[0], Length(LSignaturesLength));

    for LPair in FSignatures do
      if Length(LPair.Signature) > 0 then
        LBuffer.WriteBuffer(LPair.Signature[0], Length(LPair.Signature));

    if Length(LSerializedMessage) > 0 then
      LBuffer.WriteBuffer(LSerializedMessage[0], Length(LSerializedMessage));

    SetLength(Result, LBuffer.Size);
    LBuffer.Position := 0;
    LBuffer.ReadBuffer(Result[0], LBuffer.Size);
  finally
    LBuffer.Free;
  end;
end;

class function TTransaction.Populate(const AMessage: IMessage; const ASignatures: TArray<TBytes> = nil): ITransaction;
var
  LI, LJ, LK, LAccountLength: Integer;
  LAccounts: TList<IAccountMeta>;
  LCompiledInstruction: ICompiledInstruction;
  LInstruction: ITransactionInstruction;
  LMessageBytes: TBytes;
  LIsSignatureValid: Boolean;
  LSigner: IPublicKey;
  LPair: ISignaturePubKeyPair;
begin
  Result := TTransaction.Create;

  Result.RecentBlockHash := AMessage.RecentBlockhash;

  Result.AccountKeys.AddRange(AMessage.AccountKeys);

  if AMessage.Header.RequiredSignatures > 0 then
    Result.FeePayer := AMessage.AccountKeys[0];

  if Length(ASignatures) > 0 then
  begin
    for LI := 0 to High(ASignatures) do
    begin
      LMessageBytes := AMessage.Serialize;
      LIsSignatureValid := TEd25519Crypto.Verify(AMessage.AccountKeys[LI].KeyBytes, LMessageBytes, ASignatures[LI]);
      LSigner := AMessage.AccountKeys[LI];

      if not LIsSignatureValid then
      begin
        for LK := 0 to AMessage.AccountKeys.Count - 1 do
        begin
          if TEd25519Crypto.Verify(AMessage.AccountKeys[LK].KeyBytes, LMessageBytes, ASignatures[LI]) then
          begin
            LIsSignatureValid := True;
            LSigner := AMessage.AccountKeys[LK];
            Break;
          end;
        end;
      end;

      if LIsSignatureValid then
      begin
        LPair := TSignaturePubKeyPair.Create(LSigner, ASignatures[LI]);
        Result.Signatures.Add(LPair);
      end;
    end;
  end;

  for LI := 0 to AMessage.Instructions.Count - 1 do
  begin
    LCompiledInstruction := AMessage.Instructions[LI];
    LAccountLength := TShortVectorEncoding.DecodeLength(LCompiledInstruction.KeyIndicesCount).Value;

    LAccounts := TList<IAccountMeta>.Create;
    for LJ := 0 to LAccountLength - 1 do
    begin
      LK := LCompiledInstruction.KeyIndices[LJ];
      LAccounts.Add(TAccountMeta.Create(
        AMessage.AccountKeys[LK],
        AMessage.IsAccountWritable(LK),
        (TListUtilities.Any<ISignaturePubKeyPair>(Result.Signatures,
          function(APair: ISignaturePubKeyPair): Boolean
          begin
            Result := APair.PublicKey.Equals(AMessage.AccountKeys[LK]);
          end)) or AMessage.IsAccountSigner(LK)));
    end;

    LInstruction := TTransactionInstruction.Create(
      AMessage.AccountKeys[LCompiledInstruction.ProgramIdIndex].KeyBytes,
      LAccounts,
      LCompiledInstruction.Data
    );

    if (LI = 0) and TListUtilities.Any<IAccountMeta>(LAccounts,
      function(AAccMeta: IAccountMeta): Boolean
      begin
        Result := SameStr(AAccMeta.PublicKey.Key, TSysVars.RecentBlockHashesKey.Key);
      end) then
    begin
      Result.NonceInformation := TNonceInformation.Create(Result.RecentBlockHash, LInstruction);
      Continue;
    end;

    Result.Instructions.Add(LInstruction);
  end;
end;


class function TTransaction.Populate(const AMessage: string; const ASignatures: TArray<TBytes> = nil): ITransaction;
var
  LMsg: IMessage;
begin
  LMsg := TMessage.Deserialize(AMessage);
  Result := Populate(LMsg, ASignatures);
end;

class function TTransaction.Deserialize(const AData: string): ITransaction;
var
  LBytes: TBytes;
begin
  if AData = '' then
    raise EArgumentNilException.Create('data');

  try
    LBytes := TBase64Encoder.DecodeData(AData);
  except
    on E: Exception do
      raise Exception.Create('could not decode transaction data from base64');
  end;

  Result := Deserialize(LBytes);
end;

class function TTransaction.Deserialize(const AData: TBytes): ITransaction;
begin
  // Polymorphic dispatch to DoDeserialize (overridden by TVersionedTransaction)
  Result := DoDeserialize(AData);
end;

class function TTransaction.DoDeserialize(const AData: TBytes): ITransaction;
var
  LVecDecode: TShortVecDecode;
  LI: Integer;
  LSignaturesLength: Integer;
  LEncodedLength: Integer;
  LSignatures: TArray<TBytes>;
  LSignature: TBytes;
  LPrefix: Byte;
  LMaskedPrefix: Byte;
  LMsg: IMessage;
begin
  // Read number of signatures
  LVecDecode := TShortVectorEncoding.DecodeLength(
    TArrayUtilities.Slice<Byte>(AData, 0, TShortVectorEncoding.SpanLength)
  );
  LSignaturesLength := LVecDecode.Value;
  LEncodedLength := LVecDecode.Length;

  SetLength(LSignatures, LSignaturesLength);
  for LI := 0 to LSignaturesLength - 1 do
  begin
    LSignature := TArrayUtilities.Slice<Byte>(
      AData,
      LEncodedLength + (LI * TTransactionBuilder.SignatureLength),
      TTransactionBuilder.SignatureLength
    );
    LSignatures[LI] := LSignature;
  end;

  LPrefix := AData[LEncodedLength + (LSignaturesLength * TTransactionBuilder.SignatureLength)];
  LMaskedPrefix := LPrefix and TVersionedMessage.VersionPrefixMask;

  // If the transaction is a VersionedTransaction, use VersionedTransaction.Deserialize instead.
  if LPrefix <> LMaskedPrefix then
    Exit(TVersionedTransaction.Deserialize(AData));

  LMsg := TMessage.Deserialize(
    TArrayUtilities.Slice<Byte>(
      AData,
      LEncodedLength + (LSignaturesLength * TTransactionBuilder.SignatureLength)
    )
  );
  Result := Populate(LMsg, LSignatures);
end;

{ TVersionedTransaction }

constructor TVersionedTransaction.Create;
begin
  inherited Create;
  FAddressTableLookups := TList<IMessageAddressTableLookup>.Create;
  FInstructions := TList<ITransactionInstruction>.Create;
  FSignatures := TList<ISignaturePubKeyPair>.Create;
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

procedure TVersionedTransaction.SetAddressTableLookups(const AValue: TList<IMessageAddressTableLookup>);
begin
  FAddressTableLookups := AValue;
end;

function TVersionedTransaction.CompileMessage: TBytes;
var
  LMessageBuilder: IVersionedMessageBuilder;
  LInstruction: ITransactionInstruction;
begin
  LMessageBuilder := TVersionedMessageBuilder.Create;
  LMessageBuilder.FeePayer := FFeePayer;

  if FRecentBlockHash <> '' then
    LMessageBuilder.RecentBlockHash := FRecentBlockHash;

  if Assigned(FNonceInformation) then
    LMessageBuilder.NonceInformation := FNonceInformation;

  if Assigned(FPriorityFeesInformation) then
    LMessageBuilder.PriorityFeesInformation := FPriorityFeesInformation;

  for LInstruction in FInstructions do
    LMessageBuilder.AddInstruction(LInstruction);

  if Assigned(FAccountKeys) then
    LMessageBuilder.AccountKeys.AddRange(FAccountKeys);

  if Assigned(FAddressTableLookups) then
    LMessageBuilder.AddressTableLookups.AddRange(FAddressTableLookups);

  Result := LMessageBuilder.Build;
end;

class function TVersionedTransaction.Populate(AMessage: IVersionedMessage; const ASignatures: TArray<TBytes> = nil): IVersionedTransaction;
var
  LI, LJ, LK, LAccountLength: Integer;
  LAccounts: TList<IAccountMeta>;
  LCompiledInstruction: ICompiledInstruction;
  LInstruction: IVersionedTransactionInstruction;
  LPair: ISignaturePubKeyPair;
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
      for LI := 0 to High(ASignatures) do
      begin
        LPair := TSignaturePubKeyPair.Create(AMessage.AccountKeys[LI], ASignatures[LI]);
        Result.Signatures.Add(LPair);
      end;
    end;

    for LI := 0 to AMessage.Instructions.Count - 1 do
    begin
      LCompiledInstruction := AMessage.Instructions[LI];
      LAccountLength := TShortVectorEncoding.DecodeLength(LCompiledInstruction.KeyIndicesCount).Value;

      LAccounts := TList<IAccountMeta>.Create;
      for LJ := 0 to LAccountLength - 1 do
      begin
        LK := LCompiledInstruction.KeyIndices[LJ];
        if LK >= AMessage.AccountKeys.Count then
          Continue;
        LAccounts.Add(TAccountMeta.Create(
          AMessage.AccountKeys[LK],
          AMessage.IsAccountWritable(LK),
          (TListUtilities.Any<ISignaturePubKeyPair>(Result.Signatures,
            function(APair: ISignaturePubKeyPair): Boolean
            begin
              Result := APair.PublicKey.Equals(AMessage.AccountKeys[LK]);
            end)) or AMessage.IsAccountSigner(LK)));
      end;

      LInstruction := TVersionedTransactionInstruction.Create(
        AMessage.AccountKeys[LCompiledInstruction.ProgramIdIndex].KeyBytes,
        LAccounts,
        LCompiledInstruction.Data,
        LCompiledInstruction.KeyIndices
      );

      if (LI = 0) and TListUtilities.Any<IAccountMeta>(LAccounts,
        function(AAccMeta: IAccountMeta): Boolean
        begin
          Result := SameStr(AAccMeta.PublicKey.Key, TSysVars.RecentBlockHashesKey.Key);
        end) then
      begin
        Result.NonceInformation := TNonceInformation.Create(Result.GetRecentBlockHash, LInstruction);
        Continue;
      end;

      Result.Instructions.Add(LInstruction);
    end;

  except
    raise;
  end;
end;

class function TVersionedTransaction.Populate(const AMessage: string; const ASignatures: TArray<TBytes> = nil): IVersionedTransaction;
var
  LMsg: IMessage;
  LVersionedMsg: IVersionedMessage;
begin
  LMsg := TVersionedMessage.Deserialize(AMessage);
  if not Supports(LMsg, IVersionedMessage, LVersionedMsg) then
    raise EArgumentException.Create('Deserialized message does not support IVersionedMessage.');
  Result := Populate(LVersionedMsg, ASignatures);
end;

class function TVersionedTransaction.DoDeserialize(const AData: TBytes): ITransaction;
var
  LVecDecode: TShortVecDecode;
  LI: Integer;
  LSignaturesLength: Integer;
  LEncodedLength: Integer;
  LSignatures: TArray<TBytes>;
  LSignature: TBytes;
  LMessageOffset: Integer;
  LMsg: IMessage;
  LVersionedMessage: IVersionedMessage;
begin
  LVecDecode := TShortVectorEncoding.DecodeLength(
    TArrayUtilities.Slice<Byte>(AData, 0, TShortVectorEncoding.SpanLength)
  );
  LSignaturesLength := LVecDecode.Value;
  LEncodedLength := LVecDecode.Length;

  SetLength(LSignatures, LSignaturesLength);
  for LI := 0 to LSignaturesLength - 1 do
  begin
    LSignature := TArrayUtilities.Slice<Byte>(
      AData,
      LEncodedLength + (LI * TTransactionBuilder.SignatureLength),
      TTransactionBuilder.SignatureLength
    );
    LSignatures[LI] := LSignature;
  end;

  LMessageOffset := LEncodedLength + (LSignaturesLength * TTransactionBuilder.SignatureLength);
  LMsg := TVersionedMessage.Deserialize(TArrayUtilities.Slice<Byte>(AData, LMessageOffset));
  if not Supports(LMsg, IVersionedMessage, LVersionedMessage) then
    raise EArgumentException.Create('Deserialized message does not support IVersionedMessage.');
  Result := Populate(LVersionedMessage, LSignatures);
end;

end.
