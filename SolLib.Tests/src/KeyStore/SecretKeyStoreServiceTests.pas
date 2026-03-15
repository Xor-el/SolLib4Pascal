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

unit SecretKeyStoreServiceTests;

interface

uses
  System.SysUtils,
  System.JSON,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpSolLibExceptions,
  SlpSecretKeyStoreService,
  SlpKeyStoreService,
  SolLibKeyStoreTestCase;

type
  TSecretKeyStoreServiceTests = class(TSolLibKeyStoreTestCase)
  private
    class function SeedWithPassphrase: TBytes; static;
  published
    procedure TestKeyStorePathNotFound;
    procedure TestKeyStoreInvalidEmptyFilePath;

    procedure TestKeyStoreValid;
    procedure TestKeyStoreInvalidPassword;
    procedure TestKeyStoreInvalid;

    procedure TestKeyStoreSerialize;
    procedure TestKeyStoreGenerateKeyStore;
    procedure TestKeyStoreGetAddress;

    procedure TestValidPbkdf2KeyStore;
    procedure TestValidPbkdf2KeyStoreSerialize;
    procedure TestInvalidPbkdf2KeyStore;

    //https://ethereum.org/developers/docs/data-structures-and-encoding/web3-secret-storage/
    procedure TestValidScryptKeyStoreWithEthTestVector;
    procedure TestValidPbkdf2KeyStoreWithEthTestVector;
  end;

implementation

const
  ExpectedKeyStoreAddress = '4n8BE7DHH4NudifUBrwPbvNPs2F86XcagT7C2JKdrWrR';
  OriginalAddress = '008aeeda4d805471df9b2a5b0f38a0c3bcba786b';
  EthTestVectorSecret = '7a28b5ba57c53603b0b07b56bba752f7784bf506fa95edc395f5cf6c7514fe9d';

{ TSecretKeyStoreServiceTests }

class function TSecretKeyStoreServiceTests.SeedWithPassphrase: TBytes;
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

procedure TSecretKeyStoreServiceTests.TestKeyStorePathNotFound;
var
  LSut: TSecretKeyStoreService;
  LPath: string;
begin
  LPath := 'DoesNotExist.json';
  LSut := TSecretKeyStoreService.Create;
  try
    AssertException(
      procedure
      begin
        LSut.DecryptKeyStoreFromFile('randomPassword', LPath);
      end,
      EFileNotFoundException
    );
  finally
    LSut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestKeyStoreInvalidEmptyFilePath;
var
  LSut: TSecretKeyStoreService;
  LJson: string;
begin
  LJson := LoadTestData('InvalidEmptyFile.json');
  LSut := TSecretKeyStoreService.Create;
  try
    // Note: Resource contains whitespace (for embedding compatibility), 
    // so it throws EJSONParseException instead of EArgumentNilException
    AssertException(
      procedure
      begin
        LSut.DecryptKeyStoreFromJson('randomPassword', LJson);
      end,
      EJSONParseException
    );
  finally
    LSut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestKeyStoreValid;
var
  LSut: TSecretKeyStoreService;
  LJson: string;
  LSeed: TBytes;
begin
  LJson := LoadTestData('ValidKeyStore.json');
  LSut := TSecretKeyStoreService.Create;
  try
    LSeed := LSut.DecryptKeyStoreFromJson('randomPassword', LJson);
    AssertEquals(SeedWithPassphrase, LSeed, 'Seed mismatch');
  finally
    LSut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestKeyStoreInvalidPassword;
var
  LSut: TSecretKeyStoreService;
  LJson: string;
begin
  LJson := LoadTestData('ValidKeyStore.json');
  LSut := TSecretKeyStoreService.Create;
  try
    AssertException(
      procedure
      begin
        LSut.DecryptKeyStoreFromJson('randomPassworasdd', LJson);
      end,
      EDecryptionException
    );
  finally
    LSut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestKeyStoreInvalid;
var
  LSut: TSecretKeyStoreService;
  LJson: string;
begin
  LJson := LoadTestData('InvalidKeyStore.json');
  LSut := TSecretKeyStoreService.Create;
  try
    AssertException(
      procedure
      begin
        LSut.DecryptKeyStoreFromJson('randomPassword', LJson);
      end,
      EArgumentException
    );
  finally
    LSut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestKeyStoreSerialize;
var
  LSut: TSecretKeyStoreService;
  LJson: string;
  LAddr: string;
begin
  LSut := TSecretKeyStoreService.Create;
  try
    LJson := LSut.EncryptAndGenerateDefaultKeyStoreAsJson('randomPassword', SeedWithPassphrase, ExpectedKeyStoreAddress);
    LAddr := TSecretKeyStoreService.GetAddressFromKeyStore(LJson);
    AssertEquals(ExpectedKeyStoreAddress, LAddr, 'Address mismatch after serialize');
  finally
    LSut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestKeyStoreGenerateKeyStore;
var
  LSut: TSecretKeyStoreService;
  LJson: string;
  LAddr: string;
begin
  LSut := TSecretKeyStoreService.Create;
  try
    LJson := LSut.EncryptAndGenerateDefaultKeyStoreAsJson('randomPassword', SeedWithPassphrase, ExpectedKeyStoreAddress);
    LAddr := TSecretKeyStoreService.GetAddressFromKeyStore(LJson);
    AssertEquals(ExpectedKeyStoreAddress, LAddr, 'Address mismatch from generated keystore');
  finally
    LSut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestKeyStoreGetAddress;
var
  LFileJson: string;
  LAddr: string;
begin
  LFileJson := LoadTestData('ValidPbkdf2KeyStore.json');
  LAddr := TSecretKeyStoreService.GetAddressFromKeyStore(LFileJson);
  AssertEquals(ExpectedKeyStoreAddress, LAddr, 'Address mismatch from file');
end;

procedure TSecretKeyStoreServiceTests.TestValidPbkdf2KeyStore;
var
  LKs: TKeyStorePbkdf2Service;
  LFileJson: string;
  LSeed: TBytes;
begin
  LFileJson := LoadTestData('ValidPbkdf2KeyStore.json');

  LKs := TKeyStorePbkdf2Service.Create;
  try
    LSeed := LKs.DecryptKeyStoreFromJson('randomPassword', LFileJson);
    AssertEquals(SeedWithPassphrase, LSeed, 'Seed mismatch (pbkdf2, with passphrase)');
  finally
    LKs.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestValidPbkdf2KeyStoreSerialize;
var
  LKs: TKeyStorePbkdf2Service;
  LJson, LAddr: string;
begin
  LKs := TKeyStorePbkdf2Service.Create;
  try
    LJson := LKs.EncryptAndGenerateKeyStoreAsJson('randomPassword', SeedWithPassphrase, ExpectedKeyStoreAddress);
    LAddr := TSecretKeyStoreService.GetAddressFromKeyStore(LJson);
    AssertEquals(ExpectedKeyStoreAddress, LAddr, 'PBKDF2 serialize address mismatch');
  finally
    LKs.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestInvalidPbkdf2KeyStore;
var
  LKs: TKeyStorePbkdf2Service;
  LFileJson: string;
begin
  LFileJson := LoadTestData('InvalidPbkdf2KeyStore.json');

  LKs := TKeyStorePbkdf2Service.Create;
  try
    AssertException(
      procedure
      begin
        LKs.DecryptKeyStoreFromJson('randomPassword', LFileJson);
      end,
      EArgumentException
    );
  finally
    LKs.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestValidScryptKeyStoreWithEthTestVector;
var
  LSut: TKeyStoreScryptService;
  LFileJson: string;
  LSeed: TBytes;
begin
  LFileJson := LoadTestData('ValidScryptKeyStoreWithEthTestVector.json');

  LSut := TKeyStoreScryptService.Create;
  try
    LSeed := LSut.DecryptKeyStoreFromJson('testpassword', LFileJson);
    AssertEquals(DecodeHex(EthTestVectorSecret), LSeed, 'Seed mismatch (scrypt, with passphrase)');
  finally
    LSut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestValidPbkdf2KeyStoreWithEthTestVector;

var
  LKs: TKeyStorePbkdf2Service;
  LFileJson: string;
  LSeed: TBytes;
begin
  LFileJson := LoadTestData('ValidPbkdf2KeyStoreWithEthTestVector.json');

  LKs := TKeyStorePbkdf2Service.Create;
  try
    LSeed := LKs.DecryptKeyStoreFromJson('testpassword', LFileJson);
    AssertEquals(DecodeHex(EthTestVectorSecret), LSeed, 'Seed mismatch (pbkdf2, with passphrase)');
  finally
    LKs.Free;
  end;
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSecretKeyStoreServiceTests);
{$ELSE}
  RegisterTest(TSecretKeyStoreServiceTests.Suite);
{$ENDIF}

end.

