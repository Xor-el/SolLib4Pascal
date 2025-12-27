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

unit SolanaKeygenKeyStoreTests;

interface

uses
  System.SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpSolanaKeyStoreService,
  SlpWallet,
  SlpWalletEnum,
  SolLibKeyStoreTestCase;

type
  TSolanaKeygenKeyStoreTests = class abstract(TSolLibKeyStoreTestCase)
  private
    class function SeedWithPassphrase: TBytes; static;
  published
    procedure TestKeyStoreFileNotFound;
    procedure TestKeyStoreInvalidEmptyFilePath;
    procedure TestKeyStoreValid;
    procedure TestKeyStoreInvalid;
    procedure TestKeyStoreFull;
    procedure TestRestoreKeyStore;
  end;

implementation

const
  ExpectedKeyStoreAddress       = '4n8BE7DHH4NudifUBrwPbvNPs2F86XcagT7C2JKdrWrR';
  ExpectedStringKeyStoreAddress = '8D6vFRiysWWBwuf3HY7RrPt8EiFoP9o94LzySZqD4HsV';

  StringKeyStoreSeedWithoutPassphrase =
    '[69,191,12,22,125,16,119,72,240,150,74,197,249,221,54,164,172,222,248,202,22,242,96,43,105,164,' +
    '101,52,155,41,46,6,107,27,120,68,31,183,113,110,148,151,206,38,195,198,108,78,97,66,196,191,82,41,240,33,253,9,89,19,75,196,171,104]';

{ TSolanaKeygenKeyStoreTests }

class function TSolanaKeygenKeyStoreTests.SeedWithPassphrase: TBytes;
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

procedure TSolanaKeygenKeyStoreTests.TestKeyStoreFileNotFound;
var
  sut: TSolanaKeyStoreService;
  path: string;
begin
  path := 'DoesNotExist.txt';
  sut := TSolanaKeyStoreService.Create;
  try
    AssertException(
      procedure
      begin
        sut.RestoreKeystoreFromFile(path);
      end,
      EFileNotFoundException
    );
  finally
    sut.Free;
  end;
end;

procedure TSolanaKeygenKeyStoreTests.TestKeyStoreInvalidEmptyFilePath;
var
  sut: TSolanaKeyStoreService;
  content: string;
begin
  // Load from embedded resource (contains whitespace for compatibility)
  content := LoadTestData('InvalidEmptyFile.txt');
  sut := TSolanaKeyStoreService.Create;
  try
    AssertException(
      procedure
      begin
        sut.RestoreKeystore(content);
      end,
      EArgumentException
    );
  finally
    sut.Free;
  end;
end;

procedure TSolanaKeygenKeyStoreTests.TestKeyStoreValid;
var
  sut: TSolanaKeyStoreService;
  content: string;
  wallet: IWallet;
begin
  content := LoadTestData('ValidSolanaKeygenKeyStore.txt');
  sut := TSolanaKeyStoreService.Create;
  try
    wallet := sut.RestoreKeystore(content);
    AssertEquals(ExpectedKeyStoreAddress, wallet.Account.PublicKey.Key,
      'Restored address mismatch');
  finally
    sut.Free;
  end;
end;

procedure TSolanaKeygenKeyStoreTests.TestKeyStoreInvalid;
var
  sut: TSolanaKeyStoreService;
  content: string;
begin
  content := LoadTestData('InvalidSolanaKeygenKeyStore.txt');
  sut := TSolanaKeyStoreService.Create;
  try
    AssertException(
      procedure
      begin
        sut.RestoreKeystore(content);
      end,
      EArgumentException
    );
  finally
    sut.Free;
  end;
end;

procedure TSolanaKeygenKeyStoreTests.TestKeyStoreFull;
var
  sut: TSolanaKeyStoreService;
  content: string;
  walletToSave, restoredWallet: IWallet;
begin
  content := LoadTestData('ValidSolanaKeygenKeyStore.txt');

  sut := TSolanaKeyStoreService.Create;
  try
    walletToSave := TWallet.Create(SeedWithPassphrase, 'bip39passphrase', TSeedMode.Bip39);

    restoredWallet := sut.RestoreKeystore(content, 'bip39passphrase');

    AssertEquals(ExpectedKeyStoreAddress, walletToSave.Account.PublicKey.Key,
      'Created wallet address mismatch');
    AssertEquals(ExpectedKeyStoreAddress, restoredWallet.Account.PublicKey.Key,
      'Restored wallet address mismatch');
  finally
    sut.Free;
  end;
end;

procedure TSolanaKeygenKeyStoreTests.TestRestoreKeyStore;
var
  sut: TSolanaKeyStoreService;
  wallet: IWallet;
begin
  sut := TSolanaKeyStoreService.Create;
  try
    wallet := sut.RestoreKeystore(StringKeyStoreSeedWithoutPassphrase);
    AssertEquals(ExpectedStringKeyStoreAddress, wallet.Account.PublicKey.Key,
      'Address mismatch (RestoreKeystore from string)');
  finally
    sut.Free;
  end;
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaKeygenKeyStoreTests);
{$ELSE}
  RegisterTest(TSolanaKeygenKeyStoreTests.Suite);
{$ENDIF}

end.

