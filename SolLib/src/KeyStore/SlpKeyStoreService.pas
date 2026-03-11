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

unit SlpKeyStoreService;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.JSON.Serializers,
  SlpKeyStoreModel,
  SlpJsonKeyStoreSerializer,
  SlpCryptoUtils,
  SlpArrayUtils,
  SlpDataEncoderUtils,
  SlpKeyStoreCrypto;

type
  /// <summary>
  /// Decrypt/serialize/encrypt keystore services for a specific KDF param type.
  /// </summary>
  ISecretKeyStoreService<T: TKdfParams> = interface
    ['{B40091D6-CEAD-4E27-ADEC-3A6520D7C9B4}']
    function DecryptKeyStore(const APassword: string; const AKeyStore: TKeyStore<T>): TBytes;
    function DeserializeKeyStoreFromJson(const AJson: string): TKeyStore<T>;
    function EncryptAndGenerateKeyStore(const APassword: string; const APrivateKey: TBytes;
      const AAddress: string): TKeyStore<T>;
    function EncryptAndGenerateKeyStoreAsJson(const APassword: string; const APrivateKey: TBytes;
      const AAddress: string): string;
    function GetCipherType: string;
    function GetKdfType: string;
  end;

  /// <summary>
  /// Abstract base class for keystore services (v3).
  /// </summary>
  TKeyStoreServiceBase<T: TKdfParams> = class(TInterfacedObject, ISecretKeyStoreService<T>)
  public
    const
      CurrentVersion = 3;
  private
    class function GenerateRandomSalt: TBytes; static;
    class function GenerateRandomInitializationVector: TBytes; static;
  protected
    function GenerateCipher(const APrivateKey, AIV, ACipherKey: TBytes): TBytes; virtual;
    function GenerateDerivedKey(const APassword: string; const ASalt: TBytes; const AKdfParams: T): TBytes; virtual; abstract;
    function GetDefaultParams: T; virtual; abstract;
  public
    function EncryptAndGenerateKeyStore(const APassword: string; const APrivateKey: TBytes;
      const AAddress: string): TKeyStore<T>; overload;
    function EncryptAndGenerateKeyStore(const APassword: string; const APrivateKey: TBytes;
      const AAddress: string; const AKdfParams: T): TKeyStore<T>; overload; virtual;
    function EncryptAndGenerateKeyStoreAsJson(const APassword: string; const APrivateKey: TBytes;
      const AAddress: string): string; overload;
    function EncryptAndGenerateKeyStoreAsJson(const APassword: string; const APrivateKey: TBytes;
      const AAddress: string; const AKdfParams: T): string; overload;
    function DeserializeKeyStoreFromJson(const AJson: string): TKeyStore<T>; virtual; abstract;
    function SerializeKeyStoreToJson(const AKeyStore: TKeyStore<T>): string; virtual; abstract;
    function DecryptKeyStore(const APassword: string; const AKeyStore: TKeyStore<T>): TBytes; virtual; abstract;
    function GetKdfType: string; virtual; abstract;
    function GetCipherType: string; virtual;
    function DecryptKeyStoreFromJson(const APassword, AJson: string): TBytes; virtual;
  end;

  /// <summary>Keystore service using PBKDF2-SHA256.</summary>
  TKeyStorePbkdf2Service = class(TKeyStoreServiceBase<TPbkdf2Params>)
  protected
    function GenerateDerivedKey(const APassword: string; const ASalt: TBytes;
      const AKdfParams: TPbkdf2Params): TBytes; override;
    function GetDefaultParams: TPbkdf2Params; override;
  public
    const KdfType = 'pbkdf2';
    function GetKdfType: string; override;
    function DeserializeKeyStoreFromJson(const AJson: string): TKeyStore<TPbkdf2Params>; override;
    function SerializeKeyStoreToJson(const AKeyStore: TKeyStore<TPbkdf2Params>): string; override;
    function DecryptKeyStore(const APassword: string; const AKeyStore: TKeyStore<TPbkdf2Params>): TBytes; override;
  end;

  /// <summary>Keystore service using scrypt.</summary>
  TKeyStoreScryptService = class(TKeyStoreServiceBase<TScryptParams>)
  protected
    function GenerateDerivedKey(const APassword: string; const ASalt: TBytes;
      const AKdfParams: TScryptParams): TBytes; override;
    function GetDefaultParams: TScryptParams; override;
  public
    const KdfType = 'scrypt';
    function GetKdfType: string; override;
    function DeserializeKeyStoreFromJson(const AJson: string): TKeyStore<TScryptParams>; override;
    function SerializeKeyStoreToJson(const AKeyStore: TKeyStore<TScryptParams>): string; override;
    function DecryptKeyStore(const APassword: string; const AKeyStore: TKeyStore<TScryptParams>): TBytes; override;
  end;

implementation

{ TKeyStoreServiceBase<T> }

class function TKeyStoreServiceBase<T>.GenerateRandomInitializationVector: TBytes;
begin
  Result := TRandom.RandomBytes(16);
end;

class function TKeyStoreServiceBase<T>.GenerateRandomSalt: TBytes;
begin
  Result := TRandom.RandomBytes(32);
end;

function TKeyStoreServiceBase<T>.GetCipherType: string;
begin
  Result := 'aes-128-ctr';
end;

function TKeyStoreServiceBase<T>.GenerateCipher(const APrivateKey, AIV, ACipherKey: TBytes): TBytes;
begin
  Result := TKeyStoreCrypto.GenerateAesCtrCipher(AIV, ACipherKey, APrivateKey);
end;

function TKeyStoreServiceBase<T>.EncryptAndGenerateKeyStore(const APassword: string;
  const APrivateKey: TBytes; const AAddress: string): TKeyStore<T>;
begin
  Result := EncryptAndGenerateKeyStore(APassword, APrivateKey, AAddress, GetDefaultParams);
end;

function TKeyStoreServiceBase<T>.EncryptAndGenerateKeyStore(const APassword: string;
  const APrivateKey: TBytes; const AAddress: string; const AKdfParams: T): TKeyStore<T>;
var
  LSalt, LDerivedKey, LCipherKey, LIV, LCipherText, LMac: TBytes;
  LCryptoInfo: TCryptoInfo<T>;
  LId: string;
begin
  if APassword = '' then raise EArgumentNilException.Create('password');
  if Length(APrivateKey) = 0 then raise EArgumentNilException.Create('privateKey');
  if AAddress = '' then raise EArgumentNilException.Create('address');
  if AKdfParams = nil then raise EArgumentNilException.Create('kdfParams');

  LSalt := GenerateRandomSalt;
  LIV := GenerateRandomInitializationVector;
  LDerivedKey := GenerateDerivedKey(APassword, LSalt, AKdfParams);
  try
    LCipherKey := TKeyStoreCrypto.GenerateCipherKey(LDerivedKey);
    try
      LCipherText := GenerateCipher(APrivateKey, LIV, LCipherKey);
    finally
      TArrayUtils.Fill<Byte>(LCipherKey);
    end;
    LMac := TKeyStoreCrypto.GenerateMac(LDerivedKey, LCipherText);
  finally
    TArrayUtils.Fill<Byte>(LDerivedKey);
  end;

  LCryptoInfo := TCryptoInfo<T>.Create(GetCipherType, LCipherText, LIV, LMac, LSalt, AKdfParams, GetKdfType);

  LId := TGuid.NewGuid.ToString();
  LId := Copy(LId, 2, Length(LId) - 2);

  Result := TKeyStore<T>.Create;
  try
    Result.Version := CurrentVersion;
    Result.Address := AAddress;
    Result.Id := LId.ToLower;
    Result.Crypto := LCryptoInfo;
  except
    Result.Free;
    raise;
  end;
end;

function TKeyStoreServiceBase<T>.EncryptAndGenerateKeyStoreAsJson(const APassword: string;
  const APrivateKey: TBytes; const AAddress: string): string;
var
  LKeyStore: TKeyStore<T>;
begin
  LKeyStore := EncryptAndGenerateKeyStore(APassword, APrivateKey, AAddress);
  try
    Result := SerializeKeyStoreToJson(LKeyStore);
  finally
    LKeyStore.Free;
  end;
end;

function TKeyStoreServiceBase<T>.EncryptAndGenerateKeyStoreAsJson(const APassword: string;
  const APrivateKey: TBytes; const AAddress: string; const AKdfParams: T): string;
var
  LKeyStore: TKeyStore<T>;
begin
  LKeyStore := EncryptAndGenerateKeyStore(APassword, APrivateKey, AAddress, AKdfParams);
  try
    Result := SerializeKeyStoreToJson(LKeyStore);
  finally
    LKeyStore.Free;
  end;
end;

function TKeyStoreServiceBase<T>.DecryptKeyStoreFromJson(const APassword, AJson: string): TBytes;
var
  LKeyStore: TKeyStore<T>;
begin
  LKeyStore := DeserializeKeyStoreFromJson(AJson);
  try
    Result := DecryptKeyStore(APassword, LKeyStore);
  finally
    LKeyStore.Free;
  end;
end;

{ TKeyStorePbkdf2Service }

function TKeyStorePbkdf2Service.GenerateDerivedKey(const APassword: string;
  const ASalt: TBytes; const AKdfParams: TPbkdf2Params): TBytes;
begin
  Result := TKeyStoreCrypto.GeneratePbkdf2Sha256DerivedKey(
    APassword, ASalt, AKdfParams.Count, AKdfParams.DkLen);
end;

function TKeyStorePbkdf2Service.GetDefaultParams: TPbkdf2Params;
begin
  Result := TPbkdf2Params.Create;
  Result.DkLen := 32;
  Result.Count := 262144;
  Result.Prf := 'hmac-sha256';
end;

function TKeyStorePbkdf2Service.DeserializeKeyStoreFromJson(
  const AJson: string): TKeyStore<TPbkdf2Params>;
begin
  Result := TJsonKeyStoreSerializer.TPbkdf2.Deserialize(AJson);
end;

function TKeyStorePbkdf2Service.SerializeKeyStoreToJson(
  const AKeyStore: TKeyStore<TPbkdf2Params>): string;
begin
  Result := TJsonKeyStoreSerializer.TPbkdf2.Serialize(AKeyStore);
end;

function TKeyStorePbkdf2Service.DecryptKeyStore(const APassword: string;
  const AKeyStore: TKeyStore<TPbkdf2Params>): TBytes;
var
  LMac, LIV, LCipherText, LSalt: TBytes;
begin
  if APassword = '' then raise EArgumentNilException.Create('password');
  if AKeyStore = nil then raise EArgumentNilException.Create('keyStore');
  if AKeyStore.Crypto.KdfParams.DkLen <= 0 then
    raise EArgumentException.Create('DkLen must be greater than zero');

  LMac := THexEncoder.DecodeData(AKeyStore.Crypto.Mac);
  LIV := THexEncoder.DecodeData(AKeyStore.Crypto.CipherParams.Iv);
  LCipherText := THexEncoder.DecodeData(AKeyStore.Crypto.CipherText);
  LSalt := THexEncoder.DecodeData(AKeyStore.Crypto.KdfParams.Salt);

  Result := TKeyStoreCrypto.DecryptPbkdf2Sha256(
    APassword, LMac, LIV, LCipherText,
    AKeyStore.Crypto.KdfParams.Count,
    LSalt,
    AKeyStore.Crypto.KdfParams.DkLen);
end;

function TKeyStorePbkdf2Service.GetKdfType: string;
begin
  Result := KdfType;
end;

{ TKeyStoreScryptService }

function TKeyStoreScryptService.GenerateDerivedKey(const APassword: string;
  const ASalt: TBytes; const AKdfParams: TScryptParams): TBytes;
begin
  Result := TKeyStoreCrypto.GenerateDerivedScryptKey(
    TKeyStoreCrypto.GetPasswordAsBytes(APassword),
    ASalt,
    AKdfParams.N, AKdfParams.R, AKdfParams.P,
    AKdfParams.DkLen);
end;

function TKeyStoreScryptService.GetDefaultParams: TScryptParams;
begin
  Result := TScryptParams.Create;
  Result.DkLen := 32;
  Result.N := 262144;
  Result.R := 1;
  Result.P := 8;
end;

function TKeyStoreScryptService.DeserializeKeyStoreFromJson(
  const AJson: string): TKeyStore<TScryptParams>;
begin
  Result := TJsonKeyStoreSerializer.TScrypt.Deserialize(AJson);
end;

function TKeyStoreScryptService.SerializeKeyStoreToJson(
  const AKeyStore: TKeyStore<TScryptParams>): string;
begin
  Result := TJsonKeyStoreSerializer.TScrypt.Serialize(AKeyStore);
end;

function TKeyStoreScryptService.DecryptKeyStore(const APassword: string;
  const AKeyStore: TKeyStore<TScryptParams>): TBytes;
var
  LMac, LIV, LCipherText, LSalt: TBytes;
begin
  if APassword = '' then raise EArgumentNilException.Create('password');
  if AKeyStore = nil then raise EArgumentNilException.Create('keyStore');
  if AKeyStore.Crypto.KdfParams.DkLen <= 0 then
    raise EArgumentException.Create('DkLen must be greater than zero');

  LMac := THexEncoder.DecodeData(AKeyStore.Crypto.Mac);
  LIV := THexEncoder.DecodeData(AKeyStore.Crypto.CipherParams.Iv);
  LCipherText := THexEncoder.DecodeData(AKeyStore.Crypto.CipherText);
  LSalt := THexEncoder.DecodeData(AKeyStore.Crypto.KdfParams.Salt);

  Result := TKeyStoreCrypto.DecryptScrypt(
    APassword, LMac, LIV, LCipherText,
    AKeyStore.Crypto.KdfParams.N,
    AKeyStore.Crypto.KdfParams.R,
    AKeyStore.Crypto.KdfParams.P,
    LSalt,
    AKeyStore.Crypto.KdfParams.DkLen);
end;

function TKeyStoreScryptService.GetKdfType: string;
begin
  Result := KdfType;
end;

end.

