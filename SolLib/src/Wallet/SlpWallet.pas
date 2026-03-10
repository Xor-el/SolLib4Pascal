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

unit SlpWallet;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.TypInfo,
  SlpWalletEnum,
  SlpWordList,
  SlpAccount,
  SlpArrayUtils,
  SlpCryptoUtils,
  SlpEd25519Bip32,
  SlpMnemonic,
  SlpCryptoProviders;

type
  IWallet = interface
    ['{B7F4A38A-6D7B-4F0A-9F2F-9F4A0B3B7E52}']

    function GetAccount: IAccount;
    function GetMnemonic: IMnemonic;
    function GetSeedMode: TSeedMode;
    function GetPassphrase: string;

    /// <summary>
    /// Verify the signed message.
    /// </summary>
    function Verify(const AMessage, ASignature: TBytes; AAccountIndex: Integer)
      : Boolean; overload;

    /// <summary>
    /// Verify the signed message with the default account.
    /// </summary>
    function Verify(const AMessage, ASignature: TBytes): Boolean; overload;

    /// <summary>
    /// Sign the data with a specific account index.
    /// </summary>
    function Sign(const AMessage: TBytes; AAccountIndex: Integer)
      : TBytes; overload;

    /// <summary>
    /// Sign the data with the default account.
    /// </summary>
    function Sign(const AMessage: TBytes): TBytes; overload;

    /// <summary>
    /// Gets the account at the passed index using the ed25519 bip32 derivation path.
    /// </summary>
    function GetAccountByIndex(AIndex: Integer): IAccount;

    /// <summary>
    /// Derive a seed from the passed mnemonic and/or passphrase, depending on <see cref="SeedMode"/>.
    /// </summary>
    function DeriveMnemonicSeed: TBytes;

    /// <summary>The key pair (account).</summary>
    property Account: IAccount read GetAccount;

    /// <summary>The mnemonic words.</summary>
    property Mnemonic: IMnemonic read GetMnemonic;

    /// <summary>The configured seed mode.</summary>
    property SeedMode: TSeedMode read GetSeedMode;

    /// <summary>The passphrase string (used for BIP39 seed derivation).</summary>
    property Passphrase: string read GetPassphrase;
  end;

  TWallet = class(TInterfacedObject, IWallet)
  private const
    DerivationPathTemplate = 'm/44''/501''/x''/0''';

  private
    FSeedMode: TSeedMode;
    FSeed: TBytes;
    FEd25519Bip32: TEd25519Bip32;
    FPassphrase: string;
    FAccount: IAccount;
    FMnemonic: IMnemonic;

    /// <summary>
    /// Initializes the first account with a key pair derived from the initialized seed.
    /// </summary>
    procedure InitializeFirstAccount;
    /// <summary>
    /// Derive a seed from the passed mnemonic and/or passphrase, depending on <see cref="SeedMode"/>.
    /// </summary>
    /// <returns>The seed.</returns>
    procedure InitializeSeed;

    function GetAccount: IAccount;
    function GetMnemonic: IMnemonic;
    function GetSeedMode: TSeedMode;
    function GetPassphrase: string;

    /// <summary>
    /// Verify the signed message.
    /// </summary>
    function Verify(const AMessage, ASignature: TBytes; AAccountIndex: Integer)
      : Boolean; overload;

    /// <summary>
    /// Verify the signed message with the default account.
    /// </summary>
    function Verify(const AMessage, ASignature: TBytes): Boolean; overload;

    /// <summary>
    /// Sign the data with a specific account index.
    /// </summary>
    function Sign(const AMessage: TBytes; AAccountIndex: Integer)
      : TBytes; overload;

    /// <summary>
    /// Sign the data with the default account.
    /// </summary>
    function Sign(const AMessage: TBytes): TBytes; overload;

    /// <summary>
    /// Gets the account at the passed index using the ed25519 bip32 derivation path.
    /// </summary>
    function GetAccountByIndex(AIndex: Integer): IAccount;

    /// <summary>
    /// Derive a seed from the passed mnemonic and/or passphrase, depending on <see cref="SeedMode"/>.
    /// </summary>
    function DeriveMnemonicSeed: TBytes;

  public
    /// <summary>
    /// Initialize a wallet from passed word count and word list for the mnemonic and passphrase.
    /// </summary>
    /// <param name="WordCount">The mnemonic word count.</param>
    /// <param name="WordList">The language of the mnemonic words.</param>
    /// <param name="Passphrase">The passphrase.</param>
    /// <param name="SeedMode">The seed generation mode.</param>
    constructor Create(AWordCount: TWordCount; const AWordList: IWordList;
      const APassphrase: string = '';
      ASeedMode: TSeedMode = TSeedMode.Ed25519Bip32); overload;

    /// <summary>
    /// Initialize a wallet from the passed mnemonic and passphrase.
    /// </summary>
    /// <param name="AMnemonic">The mnemonic (reference counted).</param>
    /// <param name="APassphrase">The passphrase.</param>
    /// <param name="ASeedMode">The seed generation mode.</param>
    constructor Create(const AMnemonic: IMnemonic;
      const APassphrase: string = '';
      ASeedMode: TSeedMode = TSeedMode.Ed25519Bip32); overload;

    /// <summary>
    /// Initialize a wallet from the passed mnemonic string and optional word list and passphrase.
    /// </summary>
    /// <param name="AMnemonicWords">The mnemonic words.</param>
    /// <param name="AWordList">The language of the mnemonic words. Defaults to <see cref="WordList.English"/>.</param>
    /// <param name="APassphrase">The passphrase.</param>
    /// <param name="ASeedMode">The seed generation mode.</param>
    constructor Create(const AMnemonicWords: string;
      const AWordList: IWordList = nil; const APassphrase: string = '';
      ASeedMode: TSeedMode = TSeedMode.Ed25519Bip32); overload;

    /// <summary>
    /// Initializes a wallet from the passed seed byte array.
    /// </summary>
    /// <param name="ASeed">The seed used for key derivation.</param>
    /// <param name="APassphrase">The passphrase.</param>
    /// <param name="ASeedMode">The seed mode.</param>
    constructor Create(const ASeed: TBytes; const APassphrase: string = '';
      ASeedMode: TSeedMode = TSeedMode.Ed25519Bip32); overload;

    destructor Destroy; override;
  end;

implementation

{ TWallet }

function TWallet.GetAccount: IAccount;
begin
  Result := FAccount;
end;

function TWallet.GetMnemonic: IMnemonic;
begin
  Result := FMnemonic;
end;

function TWallet.GetSeedMode: TSeedMode;
begin
  Result := FSeedMode;
end;

function TWallet.GetPassphrase: string;
begin
  Result := FPassphrase;
end;

constructor TWallet.Create(AWordCount: TWordCount; const AWordList: IWordList;
  const APassphrase: string; ASeedMode: TSeedMode);
begin
  inherited Create;
  if AWordList = nil then
    raise EArgumentNilException.Create('WordList');

  FMnemonic := TMnemonic.Create(AWordList, AWordCount);
  FPassphrase := APassphrase;
  FSeedMode := ASeedMode;

  InitializeSeed;
end;

constructor TWallet.Create(const AMnemonic: IMnemonic; const APassphrase: string;
  ASeedMode: TSeedMode);
begin
  inherited Create;
  if AMnemonic = nil then
    raise EArgumentNilException.Create('mnemonic');

  FMnemonic := AMnemonic;
  FPassphrase := APassphrase;
  FSeedMode := ASeedMode;

  InitializeSeed;
end;

constructor TWallet.Create(const AMnemonicWords: string;
  const AWordList: IWordList; const APassphrase: string; ASeedMode: TSeedMode);
var
  LWL: IWordList;
begin
  inherited Create;
  if AMnemonicWords = '' then
    raise EArgumentNilException.Create('mnemonicWords');

  LWL := AWordList;
  if LWL = nil then
    LWL := TWordList.English;
  FMnemonic := TMnemonic.Create(AMnemonicWords, LWL);

  FPassphrase := APassphrase;
  FSeedMode := ASeedMode;

  InitializeSeed;
end;

constructor TWallet.Create(const ASeed: TBytes; const APassphrase: string;
  ASeedMode: TSeedMode);
begin
  inherited Create;

  if Length(ASeed) <> 64 then
    raise EArgumentNilException.Create('invalid seed length');

  FPassphrase := APassphrase;
  FSeedMode := ASeedMode;
  FSeed := ASeed;

  InitializeFirstAccount;
end;

function TWallet.Verify(const AMessage, ASignature: TBytes;
  AAccountIndex: Integer): Boolean;
var
  LAcc: IAccount;
begin
  if FSeedMode <> TSeedMode.Ed25519Bip32 then
    raise Exception.Create(
      'cannot verify bip39 signatures using ed25519 based bip32 keys'
    );

  LAcc := GetAccountByIndex(AAccountIndex);
  Result := LAcc.Verify(AMessage, ASignature);
end;

function TWallet.Verify(const AMessage, ASignature: TBytes): Boolean;
begin
  if not Assigned(FAccount) then
    raise EInvalidOpException.Create('Account not initialized');
  Result := FAccount.Verify(AMessage, ASignature);
end;

function TWallet.Sign(const AMessage: TBytes; AAccountIndex: Integer): TBytes;
var
  LAcc: IAccount;
begin
  if FSeedMode <> TSeedMode.Ed25519Bip32 then
    raise Exception.Create(
      'cannot compute bip39 signature using ed25519 based bip32 keys'
    );

  LAcc := GetAccountByIndex(AAccountIndex);
  Result := LAcc.Sign(AMessage);
end;

function TWallet.Sign(const AMessage: TBytes): TBytes;
begin
  if not Assigned(FAccount) then
    raise EInvalidOpException.Create('Account not initialized');
  Result := FAccount.Sign(AMessage);
end;

function TWallet.GetAccountByIndex(AIndex: Integer): IAccount;
var
  LPath: string;
  LChild: TKeyChain;
  LChildSeed: TBytes;
  LSK64, LPK32: TBytes;
  LKeyPair: TEd25519KeyPair;
begin
  if FSeedMode <> TSeedMode.Ed25519Bip32 then
    raise Exception.CreateFmt
      ('seed mode: %s cannot derive Ed25519 based BIP32 keys',
      [GetEnumName(TypeInfo(TSeedMode), Ord(FSeedMode))]);

  if not Assigned(FEd25519Bip32) then
    raise EInvalidOpException.Create('Ed25519Bip32 not initialized');

  LPath := StringReplace(DerivationPathTemplate, 'x', AIndex.ToString,
    [rfReplaceAll, rfIgnoreCase]);

  LChild := FEd25519Bip32.DerivePath(LPath);
  LChildSeed := LChild.Key; // 32 bytes

  // libsodium: SecretKey64 = seed||pub; PublicKey32 derived from seed
  LKeyPair := TEd25519Crypto.GenerateKeyPair(LChildSeed);
  LSK64 := LKeyPair.SecretKey;
  LPK32 := LKeyPair.PublicKey;

  Result := TAccount.Create(LSK64, LPK32);
end;

function TWallet.DeriveMnemonicSeed: TBytes;
begin
  if FSeed <> nil then
    Exit(FSeed);

  case FSeedMode of
    TSeedMode.Ed25519Bip32:
      // Ed25519-BIP32 mode: we need a 32-byte seed for master (child derivations follow).
      Result := FMnemonic.DeriveSeed;

    TSeedMode.Bip39:
      // Standard BIP39: returns a 64-byte seed from mnemonic+passphrase
      Result := FMnemonic.DeriveSeed(FPassphrase);
  else
    // Fallback same as Ed25519Bip32
    Result := FMnemonic.DeriveSeed;
  end;
end;

procedure TWallet.InitializeFirstAccount;
var
  LFirstSeed32: TBytes;
  LSK64, LPK32: TBytes;
  LKeyPair: TEd25519KeyPair;
begin
  if FSeedMode = TSeedMode.Ed25519Bip32 then
  begin
    FEd25519Bip32 := TEd25519Bip32.Create(FSeed);
    FAccount := GetAccountByIndex(0);
  end
  else
  begin
    LFirstSeed32 := TArrayUtils.Slice<Byte>(FSeed, 0, 32);

    LKeyPair := TEd25519Crypto.GenerateKeyPair(LFirstSeed32);
    LSK64 := LKeyPair.SecretKey;
    LPK32 := LKeyPair.PublicKey;

    FAccount := TAccount.Create(LSK64, LPK32);
  end;
end;

procedure TWallet.InitializeSeed;
begin
  FSeed := DeriveMnemonicSeed;
  InitializeFirstAccount;
end;

destructor TWallet.Destroy;
begin
  if Assigned(FEd25519Bip32) then
    FEd25519Bip32.Free;

  inherited;
end;

end.

