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
    function Verify(const &Message, Signature: TBytes; AccountIndex: Integer)
      : Boolean; overload;

    /// <summary>
    /// Verify the signed message with the default account.
    /// </summary>
    function Verify(const &Message, Signature: TBytes): Boolean; overload;

    /// <summary>
    /// Sign the data with a specific account index.
    /// </summary>
    function Sign(const &Message: TBytes; AccountIndex: Integer)
      : TBytes; overload;

    /// <summary>
    /// Sign the data with the default account.
    /// </summary>
    function Sign(const &Message: TBytes): TBytes; overload;

    /// <summary>
    /// Gets the account at the passed index using the ed25519 bip32 derivation path.
    /// </summary>
    function GetAccountByIndex(Index: Integer): IAccount;

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
    function Verify(const &Message, Signature: TBytes; AccountIndex: Integer)
      : Boolean; overload;

    /// <summary>
    /// Verify the signed message with the default account.
    /// </summary>
    function Verify(const &Message, Signature: TBytes): Boolean; overload;

    /// <summary>
    /// Sign the data with a specific account index.
    /// </summary>
    function Sign(const &Message: TBytes; AccountIndex: Integer)
      : TBytes; overload;

    /// <summary>
    /// Sign the data with the default account.
    /// </summary>
    function Sign(const &Message: TBytes): TBytes; overload;

    /// <summary>
    /// Gets the account at the passed index using the ed25519 bip32 derivation path.
    /// </summary>
    function GetAccountByIndex(Index: Integer): IAccount;

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
    constructor Create(WordCount: TWordCount; const WordList: IWordList;
      const Passphrase: string = '';
      SeedMode: TSeedMode = TSeedMode.Ed25519Bip32); overload;

    /// <summary>
    /// Initialize a wallet from the passed mnemonic and passphrase.
    /// </summary>
    /// <param name="AMnemonic">The mnemonic (reference counted).</param>
    /// <param name="Passphrase">The passphrase.</param>
    /// <param name="SeedMode">The seed generation mode.</param>
    constructor Create(const AMnemonic: IMnemonic;
      const Passphrase: string = '';
      SeedMode: TSeedMode = TSeedMode.Ed25519Bip32); overload;

    /// <summary>
    /// Initialize a wallet from the passed mnemonic string and optional word list and passphrase.
    /// </summary>
    /// <param name="MnemonicWords">The mnemonic words.</param>
    /// <param name="WordList">The language of the mnemonic words. Defaults to <see cref="WordList.English"/>.</param>
    /// <param name="Passphrase">The passphrase.</param>
    /// <param name="SeedMode">The seed generation mode.</param>
    constructor Create(const MnemonicWords: string;
      const WordList: IWordList = nil; const Passphrase: string = '';
      SeedMode: TSeedMode = TSeedMode.Ed25519Bip32); overload;

    /// <summary>
    /// Initializes a wallet from the passed seed byte array.
    /// </summary>
    /// <param name="Seed">The seed used for key derivation.</param>
    /// <param name="Passphrase">The passphrase.</param>
    /// <param name="SeedMode">The seed mode.</param>
    constructor Create(const Seed: TBytes; const Passphrase: string = '';
      SeedMode: TSeedMode = TSeedMode.Ed25519Bip32); overload;

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

constructor TWallet.Create(WordCount: TWordCount; const WordList: IWordList;
  const Passphrase: string; SeedMode: TSeedMode);
begin
  inherited Create;
  if WordList = nil then
    raise EArgumentNilException.Create('WordList');

  FMnemonic := TMnemonic.Create(WordList, WordCount);
  FPassphrase := Passphrase;
  FSeedMode := SeedMode;

  InitializeSeed;
end;

constructor TWallet.Create(const AMnemonic: IMnemonic; const Passphrase: string;
  SeedMode: TSeedMode);
begin
  inherited Create;
  if AMnemonic = nil then
    raise EArgumentNilException.Create('mnemonic');

  FMnemonic := AMnemonic;
  FPassphrase := Passphrase;
  FSeedMode := SeedMode;

  InitializeSeed;
end;

constructor TWallet.Create(const MnemonicWords: string;
  const WordList: IWordList; const Passphrase: string; SeedMode: TSeedMode);
var
  WL: IWordList;
begin
  inherited Create;
  if MnemonicWords = '' then
    raise EArgumentNilException.Create('mnemonicWords');

  WL := WordList;
  if WL = nil then
    WL := TWordList.English;
  FMnemonic := TMnemonic.Create(MnemonicWords, WL);

  FPassphrase := Passphrase;
  FSeedMode := SeedMode;

  InitializeSeed;
end;

constructor TWallet.Create(const Seed: TBytes; const Passphrase: string;
  SeedMode: TSeedMode);
begin
  inherited Create;

  if Length(Seed) <> 64 then
    raise EArgumentNilException.Create('invalid seed length');

  FPassphrase := Passphrase;
  FSeedMode := SeedMode;
  FSeed := Seed;

  InitializeFirstAccount;
end;

function TWallet.Verify(const &Message, Signature: TBytes;
  AccountIndex: Integer): Boolean;
var
  Acc: IAccount;
begin
  if FSeedMode <> TSeedMode.Ed25519Bip32 then
    raise Exception.Create(
      'cannot verify bip39 signatures using ed25519 based bip32 keys'
    );

  Acc := GetAccountByIndex(AccountIndex);
  Result := Acc.Verify(&Message, Signature);
end;

function TWallet.Verify(const &Message, Signature: TBytes): Boolean;
begin
  if not Assigned(FAccount) then
    raise EInvalidOpException.Create('Account not initialized');
  Result := FAccount.Verify(&Message, Signature);
end;

function TWallet.Sign(const &Message: TBytes; AccountIndex: Integer): TBytes;
var
  Acc: IAccount;
begin
  if FSeedMode <> TSeedMode.Ed25519Bip32 then
    raise Exception.Create(
      'cannot compute bip39 signature using ed25519 based bip32 keys'
    );

  Acc := GetAccountByIndex(AccountIndex);
  Result := Acc.Sign(&Message);
end;

function TWallet.Sign(const &Message: TBytes): TBytes;
begin
  if not Assigned(FAccount) then
    raise EInvalidOpException.Create('Account not initialized');
  Result := FAccount.Sign(&Message);
end;

function TWallet.GetAccountByIndex(Index: Integer): IAccount;
var
  Path: string;
  Child: TKeyChain;
  ChildSeed: TBytes;
  SK64, PK32: TBytes;
  KeyPair: TEd25519KeyPair;
begin
  if FSeedMode <> TSeedMode.Ed25519Bip32 then
    raise Exception.CreateFmt
      ('seed mode: %s cannot derive Ed25519 based BIP32 keys',
      [GetEnumName(TypeInfo(TSeedMode), Ord(FSeedMode))]);

  if not Assigned(FEd25519Bip32) then
    raise EInvalidOpException.Create('Ed25519Bip32 not initialized');

  Path := StringReplace(DerivationPathTemplate, 'x', Index.ToString,
    [rfReplaceAll, rfIgnoreCase]);

  Child := FEd25519Bip32.DerivePath(Path);
  ChildSeed := Child.Key; // 32 bytes

  // libsodium: SecretKey64 = seed||pub; PublicKey32 derived from seed
  KeyPair := TEd25519Crypto.GenerateKeyPair(ChildSeed);
  SK64 := KeyPair.SecretKey;
  PK32 := KeyPair.PublicKey;

  Result := TAccount.Create(SK64, PK32);
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
  FirstSeed32: TBytes;
  SK64, PK32: TBytes;
  KeyPair: TEd25519KeyPair;
begin
  if FSeedMode = TSeedMode.Ed25519Bip32 then
  begin
    FEd25519Bip32 := TEd25519Bip32.Create(FSeed);
    FAccount := GetAccountByIndex(0);
  end
  else
  begin
    FirstSeed32 := TArrayUtils.Slice<Byte>(FSeed, 0, 32);

    KeyPair := TEd25519Crypto.GenerateKeyPair(FirstSeed32);
    SK64 := KeyPair.SecretKey;
    PK32 := KeyPair.PublicKey;

    FAccount := TAccount.Create(SK64, PK32);
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

