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
  SlpDataEncoders,
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
  sut: TSecretKeyStoreService;
  path: string;
begin
  path := 'DoesNotExist.json';
  sut := TSecretKeyStoreService.Create;
  try
    AssertException(
      procedure
      begin
        sut.DecryptKeyStoreFromFile('randomPassword', path);
      end,
      EFileNotFoundException
    );
  finally
    sut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestKeyStoreInvalidEmptyFilePath;
var
  sut: TSecretKeyStoreService;
  json: string;
begin
  json := LoadTestData('InvalidEmptyFile.json');
  sut := TSecretKeyStoreService.Create;
  try
    // Note: Resource contains whitespace (for embedding compatibility), 
    // so it throws EJSONParseException instead of EArgumentNilException
    AssertException(
      procedure
      begin
        sut.DecryptKeyStoreFromJson('randomPassword', json);
      end,
      EJSONParseException
    );
  finally
    sut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestKeyStoreValid;
var
  sut: TSecretKeyStoreService;
  json: string;
  seed: TBytes;
begin
  json := LoadTestData('ValidKeyStore.json');
  sut := TSecretKeyStoreService.Create;
  try
    seed := sut.DecryptKeyStoreFromJson('randomPassword', json);
    AssertEquals<Byte>(SeedWithPassphrase, seed, 'Seed mismatch');
  finally
    sut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestKeyStoreInvalidPassword;
var
  sut: TSecretKeyStoreService;
  json: string;
begin
  json := LoadTestData('ValidKeyStore.json');
  sut := TSecretKeyStoreService.Create;
  try
    AssertException(
      procedure
      begin
        sut.DecryptKeyStoreFromJson('randomPassworasdd', json);
      end,
      EDecryptionException
    );
  finally
    sut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestKeyStoreInvalid;
var
  sut: TSecretKeyStoreService;
  json: string;
begin
  json := LoadTestData('InvalidKeyStore.json');
  sut := TSecretKeyStoreService.Create;
  try
    AssertException(
      procedure
      begin
        sut.DecryptKeyStoreFromJson('randomPassword', json);
      end,
      EArgumentException
    );
  finally
    sut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestKeyStoreSerialize;
var
  sut: TSecretKeyStoreService;
  json: string;
  addr: string;
begin
  sut := TSecretKeyStoreService.Create;
  try
    json := sut.EncryptAndGenerateDefaultKeyStoreAsJson('randomPassword', SeedWithPassphrase, ExpectedKeyStoreAddress);
    addr := TSecretKeyStoreService.GetAddressFromKeyStore(json);
    AssertEquals(ExpectedKeyStoreAddress, addr, 'Address mismatch after serialize');
  finally
    sut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestKeyStoreGenerateKeyStore;
var
  sut: TSecretKeyStoreService;
  json: string;
  addr: string;
begin
  sut := TSecretKeyStoreService.Create;
  try
    json := sut.EncryptAndGenerateDefaultKeyStoreAsJson('randomPassword', SeedWithPassphrase, ExpectedKeyStoreAddress);
    addr := TSecretKeyStoreService.GetAddressFromKeyStore(json);
    AssertEquals(ExpectedKeyStoreAddress, addr, 'Address mismatch from generated keystore');
  finally
    sut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestKeyStoreGetAddress;
var
  fileJson: string;
  addr: string;
begin
  fileJson := LoadTestData('ValidPbkdf2KeyStore.json');
  addr := TSecretKeyStoreService.GetAddressFromKeyStore(fileJson);
  AssertEquals(ExpectedKeyStoreAddress, addr, 'Address mismatch from file');
end;

procedure TSecretKeyStoreServiceTests.TestValidPbkdf2KeyStore;
var
  ks: TKeyStorePbkdf2Service;
  fileJson: string;
  seed: TBytes;
begin
  fileJson := LoadTestData('ValidPbkdf2KeyStore.json');

  ks := TKeyStorePbkdf2Service.Create;
  try
    seed := ks.DecryptKeyStoreFromJson('randomPassword', fileJson);
    AssertEquals<Byte>(SeedWithPassphrase, seed, 'Seed mismatch (pbkdf2, with passphrase)');
  finally
    ks.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestValidPbkdf2KeyStoreSerialize;
var
  ks: TKeyStorePbkdf2Service;
  json, addr: string;
begin
  ks := TKeyStorePbkdf2Service.Create;
  try
    json := ks.EncryptAndGenerateKeyStoreAsJson('randomPassword', SeedWithPassphrase, ExpectedKeyStoreAddress);
    addr := TSecretKeyStoreService.GetAddressFromKeyStore(json);
    AssertEquals(ExpectedKeyStoreAddress, addr, 'PBKDF2 serialize address mismatch');
  finally
    ks.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestInvalidPbkdf2KeyStore;
var
  ks: TKeyStorePbkdf2Service;
  fileJson: string;
begin
  fileJson := LoadTestData('InvalidPbkdf2KeyStore.json');

  ks := TKeyStorePbkdf2Service.Create;
  try
    AssertException(
      procedure
      begin
        ks.DecryptKeyStoreFromJson('randomPassword', fileJson);
      end,
      EArgumentException
    );
  finally
    ks.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestValidScryptKeyStoreWithEthTestVector;
var
  sut: TKeyStoreScryptService;
  fileJson: string;
  seed: TBytes;
begin
  fileJson := LoadTestData('ValidScryptKeyStoreWithEthTestVector.json');

  sut := TKeyStoreScryptService.Create;
  try
    seed := sut.DecryptKeyStoreFromJson('testpassword', fileJson);
    AssertEquals<Byte>(TEncoders.Hex.DecodeData(EthTestVectorSecret), seed, 'Seed mismatch (scrypt, with passphrase)');
  finally
    sut.Free;
  end;
end;

procedure TSecretKeyStoreServiceTests.TestValidPbkdf2KeyStoreWithEthTestVector;

var
  ks: TKeyStorePbkdf2Service;
  fileJson: string;
  seed: TBytes;
begin
  fileJson := LoadTestData('ValidPbkdf2KeyStoreWithEthTestVector.json');

  ks := TKeyStorePbkdf2Service.Create;
  try
    seed := ks.DecryptKeyStoreFromJson('testpassword', fileJson);
    AssertEquals<Byte>(TEncoders.Hex.DecodeData(EthTestVectorSecret), seed, 'Seed mismatch (pbkdf2, with passphrase)');
  finally
    ks.Free;
  end;
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSecretKeyStoreServiceTests);
{$ELSE}
  RegisterTest(TSecretKeyStoreServiceTests.Suite);
{$ENDIF}

end.

