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

unit WalletTests;

interface

uses
  System.SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpWallet,
  SlpWordList,
  SlpAccount,
  SlpMnemonic,
  SlpWalletEnum,
  SolLibTestCase;

type
  TWalletTests = class(TSolLibTestCase)
  private
type
  TKeyPair = record
    PublicKey: string;
    PrivateKey: string;
    class function Create(const APublicKey, APrivateKey: string): TKeyPair; static;
  end;
   const
    MnemonicWords = 'lens scheme misery search address destroy shallow police picture gown ' +
          'apart rural cotton vivid cage disagree enrich govern history kit early near cloth alarm';
    Bip39Passphrase = 'bip39passphrase';

    /// <summary>
    /// Expected key pair from wallet initialization using the above parameters (MnemonicWords, Bip39Passphrase), as output from solana-keygen cli tool
    /// </summary>
    ExpectedSolanaKeygenPrivateKey = '4G39ryne39vSdXj8v2dVEuN7jMrbMLRD6BtPXydtHoqHHs8SyTAvtjScrzGxvUDo4p6Fz3QaxqF3FUHxn3k68D6M';
    ExpectedSolanaKeygenPublicKey = '4n8BE7DHH4NudifUBrwPbvNPs2F86XcagT7C2JKdrWrR';

    class function SeedWithoutPassphrase: TBytes; static;
    class function SeedWithPassphrase: TBytes; static;
    class function SerializedMessage: TBytes; static;
    class function SerializedMessageSignature: TBytes; static;
    class function SerializedMessageSignatureBip39: TBytes; static;

    /// <summary>
    /// Expected key pairs from wallet initialization using the above parameters (MnemonicWords, Bip39Passphrase), as output from sollet.io
    /// </summary>
    class function ExpectedSolletKeys: TArray<TKeyPair>; static;

    class function SetupWalletFromMnemonicWords(ASeedMode: TSeedMode): IWallet; static;
    class function SetupWalletFromSeed(ASeedMode: TSeedMode): IWallet; static;
    class function SetupWalletFromMnemonic(ASeedMode: TSeedMode): IWallet; static;
  published
    procedure TestWallet;
    procedure TestWalletEd25519Bip32FromWords;
    procedure TestWalletBip39FromWords;
    procedure TestWalletEd25519Bip32FromSeed;
    procedure TestWalletBip39FromSeed;
    procedure TestWalletEd25519Bip32FromMnemonic;
    procedure TestWalletBip39FromMnemonic;

    procedure TestAccountSignEd25519Bip32;
    procedure TestWalletSignEd25519Bip32;
    procedure TestAccountVerifyEd25519Bip32;
    procedure TestWalletVerifyEd25519Bip32;

    procedure TestWalletSignBip39;
    procedure TestAccountSignBip39;
    procedure TestWalletVerifyBip39;
  end;

implementation

{ TWalletTests.TKeyPair }

class function TWalletTests.TKeyPair.Create(const APublicKey, APrivateKey: string): TKeyPair;
begin
  Result.PublicKey := APublicKey;
  Result.PrivateKey := APrivateKey;
end;

{ TWalletTests }

class function TWalletTests.ExpectedSolletKeys: TArray<TKeyPair>;
begin
  Result := TArray<TKeyPair>.Create(
    TKeyPair.Create(
      'ALSzrjtGi8MZGmAZa6ZhtUZq3rwurWuJqWFdgcj9MMFL',
      '5ZD7ntKtyHrnqMhfSuKBLdqHzT5N3a2aYnCGBcz4N78b84TKpjwQ4QBsapEnpnZFchM7F1BpqDkSuLdwMZwM8hLi'),
    TKeyPair.Create(
      'CgFKZ1VLJvip93rh7qKqiGwZjxXb4XXC4GhBGBizuWUb',
      '5hTHMuq5vKJachfenfKeAoDhMttXFfN77G51L8KiVRsZqRmzFvNLUdMFDRYgTfuX6yy9g6gCpatzray4XFX5B8xb'),
    TKeyPair.Create(
      'C6jL32xjsGr9fmMdd56TF9oQURN19EfemFxkdpzRoyxm',
      'UYhpZrPoRGvHur6ZunZT6VraiTC85NjGsFDrm8LLx3kZkThHEUGSkAuJhn2KUAt2o2Nf3EeFhEW52REzmD3iPgV')
  );
end;

class function TWalletTests.SeedWithoutPassphrase: TBytes;
begin
  Result := TBytes.Create(
    124,36,217,106,151,19,165,102,96,101,74,81,
    237,254,232,133,28,167,31,35,119,188,66,40,
    101,104,25,103,139,83,57,7,19,215,6,113,22,
    145,107,209,208,107,159,40,223,19,82,53,136,
    255,40,171,137,93,9,205,28,7,207,88,194,91,
    219,232
  );
end;

class function TWalletTests.SeedWithPassphrase: TBytes;
begin
  Result := TBytes.Create(
    163,4,184,24,182,219,174,214,13,54,158,198,
    63,202,76,3,190,224,76,202,160,96,124,95,89,
    155,113,10,46,218,154,74,125,7,103,78,0,51,
    244,192,221,12,200,148,9,252,4,117,193,123,
    102,56,255,105,167,180,125,222,19,111,219,18,
    115,0
  );
end;

class function TWalletTests.SerializedMessage: TBytes;
begin
  Result := TBytes.Create(
    1, 0, 2, 4, 138, 180, 156, 252, 109, 252, 108, 26, 186, 0,
    196, 69, 57, 102, 15, 151, 149, 242, 119, 181, 171, 113,
    120, 224, 0, 118, 155, 61, 246, 56, 178, 47, 173, 126, 102,
    53, 246, 163, 32, 189, 27, 84, 69, 94, 217, 196, 152, 178,
    198, 116, 124, 160, 230, 94, 226, 141, 220, 221, 119, 21,
    204, 242, 204, 164, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 74, 83, 80,
    248, 93, 200, 130, 214, 20, 165, 86, 114, 120, 138, 41, 109,
    223, 30, 171, 171, 208, 166, 6, 120, 136, 73, 50, 244, 238,
    246, 160, 61, 96, 239, 228, 59, 10, 206, 186, 110, 68, 55,
    160, 108, 50, 58, 247, 220, 116, 182, 121, 237, 126, 42, 184,
    248, 125, 83, 253, 85, 181, 215, 93, 2, 2, 2, 0, 1, 12, 2, 0, 0, 0,
    128, 150, 152, 0, 0, 0, 0, 0, 3, 1, 0, 21, 72, 101, 108, 108, 111,
    32, 102, 114, 111, 109, 32, 83, 111, 108, 46, 78, 101, 116, 32, 58, 41
  );
end;

class function TWalletTests.SerializedMessageSignature: TBytes;
begin
  Result := TBytes.Create(
    234, 147, 144, 17, 200, 57, 8, 154, 139, 86, 156, 12, 7, 143, 144,
    85, 27, 151, 186, 223, 246, 231, 186, 81, 69, 107, 126, 76, 119,
    14, 112, 57, 38, 5, 28, 109, 99, 30, 249, 154, 87, 241, 28, 161,
    178, 165, 146, 73, 179, 4, 71, 133, 203, 145, 125, 252, 200, 249,
    38, 105, 30, 113, 73, 8
  );
end;

class function TWalletTests.SerializedMessageSignatureBip39: TBytes;
begin
  Result := TBytes.Create(
    28, 126, 243, 240, 127, 153, 168, 18, 202, 11, 27, 255, 242, 180, 193, 230, 100,
    109, 213, 104, 22, 230, 164, 231, 20, 10, 64, 213, 212, 108, 210, 59, 174, 106,
    61, 254, 120, 250, 15, 109, 254, 142, 88, 176, 145, 111, 0, 231, 29, 225, 10, 193,
    135, 130, 54, 21, 25, 48, 147, 4, 138, 171, 252, 15
  );
end;

class function TWalletTests.SetupWalletFromMnemonicWords(ASeedMode: TSeedMode): IWallet;
var
  LWL: IWordList;
begin
  LWL := TWordList.English;
  case ASeedMode of
    TSeedMode.Bip39: Result := TWallet.Create(MnemonicWords, LWL, Bip39Passphrase, TSeedMode.Bip39);
    TSeedMode.Ed25519Bip32: Result := TWallet.Create(MnemonicWords, LWL);
  else
    raise EArgumentOutOfRangeException.Create('this should never happen');
  end;
end;

class function TWalletTests.SetupWalletFromSeed(ASeedMode: TSeedMode): IWallet;
begin
  case ASeedMode of
    TSeedMode.Bip39: Result := TWallet.Create(SeedWithPassphrase, Bip39Passphrase, TSeedMode.Bip39);
    TSeedMode.Ed25519Bip32: Result := TWallet.Create(SeedWithoutPassphrase);
  else
    raise EArgumentOutOfRangeException.Create('this should never happen');
  end;
end;

class function TWalletTests.SetupWalletFromMnemonic(ASeedMode: TSeedMode): IWallet;
var
  LMnemonic: IMnemonic;
begin
  LMnemonic := TMnemonic.Create(MnemonicWords);

  case ASeedMode of
    TSeedMode.Bip39: Result := TWallet.Create(LMnemonic, Bip39Passphrase, TSeedMode.Bip39);
    TSeedMode.Ed25519Bip32: Result := TWallet.Create(LMnemonic);
  else
    raise EArgumentOutOfRangeException.Create('this should never happen');
  end;
end;

procedure TWalletTests.TestWallet;
var
  LWallet: IWallet;
  LSig, LSig2: TBytes;
begin
  LWallet := TWallet.Create(TWordCount.TwentyFour, TWordList.English);

  AssertNotNull(LWallet.Account, 'Wallet.Account should not be nil');
  AssertNotNull(LWallet.Account.PrivateKey, 'Wallet.Account.PrivateKey should not be nil');
  AssertNotNull(LWallet.Account.PublicKey, 'Wallet.Account.PublicKey should not be nil');
  AssertTrue(LWallet.Account.PrivateKey.KeyBytes <> nil, 'Wallet.Account.PrivateKeyBytes should not be nil');
  AssertTrue(LWallet.Account.PublicKey.KeyBytes  <> nil, 'Wallet.Account.PublicKeyBytes should not be nil');

  LSig := LWallet.Account.Sign(SerializedMessage);
  AssertTrue(LWallet.Account.Verify(SerializedMessage, LSig), 'Account.Verify failed');

  LSig2 := LWallet.Sign(SerializedMessage, 2);
  AssertTrue(LWallet.Verify(SerializedMessage, LSig2, 2), 'Wallet.Verify(2) failed');
end;


procedure TWalletTests.TestWalletEd25519Bip32FromWords;
var
  LWallet: IWallet;
  LI: Integer;
  LPairs: TArray<TKeyPair>;
  LAcc: IAccount;
begin
  LWallet := SetupWalletFromMnemonicWords(TSeedMode.Ed25519Bip32);

  AssertEquals(SeedWithoutPassphrase, LWallet.DeriveMnemonicSeed, 'seed mismatch');

  LPairs := ExpectedSolletKeys;
  for LI := 0 to High(LPairs) do
  begin
    LAcc := LWallet.GetAccountByIndex(LI);
    AssertEquals(LPairs[LI].PublicKey,  LAcc.PublicKey.Key);
    AssertEquals(LPairs[LI].PrivateKey, LAcc.PrivateKey.Key);
  end;
end;

procedure TWalletTests.TestWalletBip39FromWords;
var
  LWallet: IWallet;
begin
  LWallet := SetupWalletFromMnemonicWords(TSeedMode.Bip39);

  AssertEquals(SeedWithPassphrase, LWallet.DeriveMnemonicSeed, 'seed mismatch');
  AssertEquals(ExpectedSolanaKeygenPublicKey,  LWallet.Account.PublicKey.Key);
  AssertEquals(ExpectedSolanaKeygenPrivateKey, LWallet.Account.PrivateKey.Key);
end;


procedure TWalletTests.TestWalletEd25519Bip32FromSeed;
var
  LWallet: IWallet;
  LI: Integer;
  LPairs: TArray<TKeyPair>;
  LAcc: IAccount;
begin
  LWallet := SetupWalletFromSeed(TSeedMode.Ed25519Bip32);

  AssertEquals(SeedWithoutPassphrase, LWallet.DeriveMnemonicSeed, 'seed mismatch');

  LPairs := ExpectedSolletKeys;
  for LI := 0 to High(LPairs) do
  begin
    LAcc := LWallet.GetAccountByIndex(LI);
    AssertEquals(LPairs[LI].PublicKey,  LAcc.PublicKey.Key);
    AssertEquals(LPairs[LI].PrivateKey, LAcc.PrivateKey.Key);
  end;
end;

procedure TWalletTests.TestWalletBip39FromSeed;
var
  LWallet: IWallet;
begin
  LWallet := SetupWalletFromSeed(TSeedMode.Bip39);

  AssertEquals(SeedWithPassphrase, LWallet.DeriveMnemonicSeed, 'seed mismatch');
  AssertEquals(ExpectedSolanaKeygenPublicKey,  LWallet.Account.PublicKey.Key);
  AssertEquals(ExpectedSolanaKeygenPrivateKey, LWallet.Account.PrivateKey.Key);
end;

procedure TWalletTests.TestWalletEd25519Bip32FromMnemonic;
var
  LWallet: IWallet;
  LI: Integer;
  LPairs: TArray<TKeyPair>;
  LAcc: IAccount;
begin
  LWallet := SetupWalletFromMnemonic(TSeedMode.Ed25519Bip32);

  AssertEquals(SeedWithoutPassphrase, LWallet.DeriveMnemonicSeed, 'seed mismatch');

  LPairs := ExpectedSolletKeys;
  for LI := 0 to High(LPairs) do
  begin
    LAcc := LWallet.GetAccountByIndex(LI);
    AssertEquals(LPairs[LI].PublicKey,  LAcc.PublicKey.Key);
    AssertEquals(LPairs[LI].PrivateKey, LAcc.PrivateKey.Key);
  end;
end;

procedure TWalletTests.TestWalletBip39FromMnemonic;
var
  LWallet: IWallet;
begin
  LWallet := SetupWalletFromMnemonic(TSeedMode.Bip39);

  AssertEquals(SeedWithPassphrase, LWallet.DeriveMnemonicSeed, 'seed mismatch');
  AssertEquals(ExpectedSolanaKeygenPublicKey,  LWallet.Account.PublicKey.Key);
  AssertEquals(ExpectedSolanaKeygenPrivateKey, LWallet.Account.PrivateKey.Key);
end;

procedure TWalletTests.TestAccountSignEd25519Bip32;
var
  LWallet: IWallet;
  LAcc: IAccount;
begin
  LWallet := SetupWalletFromMnemonicWords(TSeedMode.Ed25519Bip32);

  AssertEquals(SerializedMessageSignature, LWallet.Account.Sign(SerializedMessage), 'acct sig mismatch');

  LAcc := LWallet.GetAccountByIndex(0);
  AssertEquals(SerializedMessageSignature, LAcc.Sign(SerializedMessage), 'acct[0] sig mismatch');
end;

procedure TWalletTests.TestWalletSignEd25519Bip32;
var
  LWallet: IWallet;
begin
  LWallet := SetupWalletFromMnemonicWords(TSeedMode.Ed25519Bip32);

  AssertEquals(SerializedMessageSignature, LWallet.Account.Sign(SerializedMessage), 'acct sig mismatch');
  AssertEquals(SerializedMessageSignature, LWallet.Sign(SerializedMessage), 'wallet sig mismatch');
end;

procedure TWalletTests.TestAccountVerifyEd25519Bip32;
var
  LWallet: IWallet;
  LAcc: IAccount;
begin
  LWallet := SetupWalletFromMnemonicWords(TSeedMode.Ed25519Bip32);

  AssertTrue(LWallet.Account.Verify(SerializedMessage, SerializedMessageSignature), 'acct verify failed');

  LAcc := LWallet.GetAccountByIndex(0);
  AssertTrue(LAcc.Verify(SerializedMessage, SerializedMessageSignature), 'acct[0] verify failed');
end;

procedure TWalletTests.TestWalletVerifyEd25519Bip32;
var
  LWallet: IWallet;
begin
  LWallet := SetupWalletFromMnemonicWords(TSeedMode.Ed25519Bip32);

  AssertTrue(LWallet.Account.Verify(SerializedMessage, SerializedMessageSignature), 'acct verify failed');
  AssertTrue(LWallet.Verify(SerializedMessage, SerializedMessageSignature), 'wallet verify failed');
end;


procedure TWalletTests.TestWalletSignBip39;
var
  LWallet: IWallet;
begin
  LWallet := SetupWalletFromMnemonicWords(TSeedMode.Bip39);

  // Wallet-level sign with explicit index should raise
  AssertException(
    procedure
    begin
      LWallet.Sign(SerializedMessage, 1);
    end,
    Exception
  );

  // Account-level sign should also raise
  AssertException(
    procedure
    var
      LAcc: IAccount;
    begin
      LAcc := LWallet.GetAccountByIndex(0);
      LAcc.Sign(SerializedMessage);
    end,
    Exception
  );

  // Default wallet sign (index 0 under Bip39) should match expected signature
  AssertEquals(SerializedMessageSignatureBip39, LWallet.Sign(SerializedMessage), 'bip39 wallet sig mismatch');
end;

procedure TWalletTests.TestAccountSignBip39;
var
  LWallet: IWallet;
begin
  LWallet := SetupWalletFromMnemonicWords(TSeedMode.Bip39);

  AssertException(
    procedure
    begin
      LWallet.Sign(SerializedMessage, 1);
    end,
    Exception
  );

  AssertException(
    procedure
    var
      LAcc: IAccount;
    begin
      LAcc := LWallet.GetAccountByIndex(0);
      LAcc.Sign(SerializedMessage);
    end,
    Exception
  );

  AssertEquals(SerializedMessageSignatureBip39, LWallet.Account.Sign(SerializedMessage), 'bip39 acct sig mismatch');
end;

procedure TWalletTests.TestWalletVerifyBip39;
var
  LWallet: IWallet;
begin
  LWallet := SetupWalletFromMnemonicWords(TSeedMode.Bip39);

  AssertException(
    procedure
    begin
      LWallet.Verify(SerializedMessage, SerializedMessageSignature, 1);
    end,
    Exception
  );

  AssertException(
    procedure
    var
      LAcc: IAccount;
    begin
      LAcc := LWallet.GetAccountByIndex(0);
      LAcc.Verify(SerializedMessage, SerializedMessageSignature);
    end,
    Exception
  );

  AssertTrue(LWallet.Account.Verify(SerializedMessage, SerializedMessageSignatureBip39), 'bip39 acct verify failed');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TWalletTests);
{$ELSE}
  RegisterTest(TWalletTests.Suite);
{$ENDIF}

end.

