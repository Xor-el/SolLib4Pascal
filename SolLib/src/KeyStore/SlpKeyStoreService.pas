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

unit SlpKeyStoreService;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.JSON.Serializers,
  SlpKeyStoreModel,
  SlpJsonKeyStoreSerializer,
  SlpCryptoUtils,
  SlpDataEncoders,
  SlpKeyStoreCrypto;

type
  /// <summary>
  /// Decrypt/serialize/encrypt keystore services for a specific KDF param type.
  /// </summary>
  /// <typeparam name="T">KDF params type (e.g., TPbkdf2Params or TScryptParams)</typeparam>
  ISecretKeyStoreService<T: TKdfParams> = interface
    ['{B40091D6-CEAD-4E27-ADEC-3A6520D7C9B4}']
    /// <summary>
    /// Decrypt the keystore.
    /// </summary>
    /// <param name="APassword"></param>
    /// <param name="AKeyStore"></param>
    /// <returns></returns>
    function DecryptKeyStore(const APassword: string; const AKeyStore: TKeyStore<T>): TBytes;

    /// <summary>
    /// Deserialize keystore from json.
    /// </summary>
    /// <param name="AJson"></param>
    /// <returns></returns>
    function DeserializeKeyStoreFromJson(const AJson: string): TKeyStore<T>;

    /// <summary>
    /// Encrypt and generate the keystore.
    /// </summary>
    /// <param name="APassword"></param>
    /// <param name="APrivateKey"></param>
    /// <param name="AAddress"></param>
    /// <returns></returns>
    function EncryptAndGenerateKeyStore(const APassword: string; const APrivateKey: TBytes;
      const AAddress: string): TKeyStore<T>;

    /// <summary>
    /// Encrypt and generate the keystore as json.
    /// </summary>
    /// <param name="APassword"></param>
    /// <param name="APrivateKey"></param>
    /// <param name="AAddress"></param>
    /// <returns></returns>
    function EncryptAndGenerateKeyStoreAsJson(const APassword: string; const APrivateKey: TBytes;
      const AAddress: string): string;

    /// <summary>
    /// Get keystore cipher type.
    /// </summary>
    /// <returns></returns>
    function GetCipherType: string;

    /// <summary>
    /// Get keystore key derivation function.
    /// </summary>
    /// <returns></returns>
    function GetKdfType: string;
  end;

  /// <summary>
  /// Abstract base class for keystore services (v3).
  /// </summary>
  /// <typeparam name="T">KDF params type</typeparam>
  TKeyStoreServiceBase<T: TKdfParams> = class(TInterfacedObject, ISecretKeyStoreService<T>)
  public
   const
     CurrentVersion = 3;
  private
    FKeyStoreCrypto: TKeyStoreCrypto;

    /// <summary>Generate cryptographic random salt (32 bytes).</summary>
    class function GenerateRandomSalt: TBytes; static;
    /// <summary>Generate cryptographic IV for AES-CTR (16 bytes).</summary>
    class function GenerateRandomInitializationVector: TBytes; static;
  protected
    /// <summary>Generate AES-CTR cipher text.</summary>
    function GenerateCipher(const APrivateKey, AIV, ACipherKey: TBytes): TBytes; virtual;

    /// <summary>Derive key (implemented by subclasses).</summary>
    function GenerateDerivedKey(const APassword: string; const ASalt: TBytes; const AKdfParams: T): TBytes; virtual; abstract;

    /// <summary>Default params for this KDF (implemented by subclasses).</summary>
    function GetDefaultParams: T; virtual; abstract;

    /// <summary>Create with a new TKeyStoreCrypto.</summary>
    constructor Create; overload; virtual;
    /// <summary>Create with provided TKeyStoreCrypto (owned).</summary>
    constructor Create(const ACrypto: TKeyStoreCrypto); overload; virtual;

  public

    destructor Destroy; override;

    /// <summary>Encrypt and generate the keystore.</summary>
    function EncryptAndGenerateKeyStore(const APassword: string; const APrivateKey: TBytes;
      const AAddress: string): TKeyStore<T>; overload;

    /// <summary>Encrypt and generate the keystore with explicit KDF params.</summary>
    function EncryptAndGenerateKeyStore(const APassword: string; const APrivateKey: TBytes;
      const AAddress: string; const AKdfParams: T): TKeyStore<T>; overload; virtual;

    /// <summary>Encrypt and generate the keystore as json.</summary>
    function EncryptAndGenerateKeyStoreAsJson(const APassword: string; const APrivateKey: TBytes;
      const AAddress: string): string; overload;

    /// <summary>Encrypt and generate the keystore as json with explicit KDF params.</summary>
    function EncryptAndGenerateKeyStoreAsJson(const APassword: string; const APrivateKey: TBytes;
      const AAddress: string; const AKdfParams: T): string; overload;

    /// <summary>Deserialize keystore.</summary>
    function DeserializeKeyStoreFromJson(const AJson: string): TKeyStore<T>; virtual; abstract;

    /// <summary>Serialize keystore.</summary>
    function SerializeKeyStoreToJson(const AKeyStore: TKeyStore<T>): string; virtual; abstract;

    /// <summary>Decrypt keystore.</summary>
    function DecryptKeyStore(const APassword: string; const AKeyStore: TKeyStore<T>): TBytes; virtual; abstract;

    /// <summary>Return KDF type string (implemented by subclasses).</summary>
    function GetKdfType: string; virtual; abstract;

    /// <summary>Return 'aes-128-ctr' by default.</summary>
    function GetCipherType: string; virtual;

    /// <summary>Decrypt keystore from json.</summary>
    function DecryptKeyStoreFromJson(const APassword, AJson: string): TBytes; virtual;
  end;

  /// <summary>
  /// Keystore service using PBKDF2-SHA256.
  /// </summary>
  TKeyStorePbkdf2Service = class(TKeyStoreServiceBase<TPbkdf2Params>)
  protected
    function GenerateDerivedKey(const APassword: string; const ASalt: TBytes; const AKdfParams: TPbkdf2Params): TBytes; override;
    function GetDefaultParams: TPbkdf2Params; override;

  public
   const
    KdfType = 'pbkdf2';

    constructor Create(const ACrypto: TKeyStoreCrypto); override;
    destructor Destroy; override;

    function GetKdfType: string; override;
    function DeserializeKeyStoreFromJson(const AJson: string): TKeyStore<TPbkdf2Params>; override;
    function SerializeKeyStoreToJson(const AKeyStore: TKeyStore<TPbkdf2Params>): string; override;
    function DecryptKeyStore(const APassword: string; const AKeyStore: TKeyStore<TPbkdf2Params>): TBytes; override;
  end;

  /// <summary>
  /// Keystore service using scrypt.
  /// </summary>
  TKeyStoreScryptService = class(TKeyStoreServiceBase<TScryptParams>)
  protected
    function GenerateDerivedKey(const APassword: string; const ASalt: TBytes; const AKdfParams: TScryptParams): TBytes; override;
    function GetDefaultParams: TScryptParams; override;

  public
   const
    KdfType = 'scrypt';

    constructor Create(const ACrypto: TKeyStoreCrypto); override;
    destructor Destroy; override;

    function GetKdfType: string; override;
    function DeserializeKeyStoreFromJson(const AJson: string): TKeyStore<TScryptParams>; override;
    function SerializeKeyStoreToJson(const AKeyStore: TKeyStore<TScryptParams>): string; override;
    function DecryptKeyStore(const APassword: string; const AKeyStore: TKeyStore<TScryptParams>): TBytes; override;
  end;

implementation

{ TKeyStoreServiceBase<T> }

constructor TKeyStoreServiceBase<T>.Create;
begin
  Create(TKeyStoreCrypto.Create);
end;

constructor TKeyStoreServiceBase<T>.Create(const ACrypto: TKeyStoreCrypto);
begin
  inherited Create;
  FKeyStoreCrypto := ACrypto
end;

destructor TKeyStoreServiceBase<T>.Destroy;
begin
 if Assigned(FKeyStoreCrypto) then
   FKeyStoreCrypto.Free;
  inherited;
end;

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
  Result := FKeyStoreCrypto.GenerateAesCtrCipher(AIV, ACipherKey, APrivateKey);
end;

function TKeyStoreServiceBase<T>.EncryptAndGenerateKeyStore(const APassword: string;
  const APrivateKey: TBytes; const AAddress: string): TKeyStore<T>;
var
  KdfParams: T;
begin
  KdfParams := GetDefaultParams;
  Result := EncryptAndGenerateKeyStore(APassword, APrivateKey, AAddress, KdfParams);
end;

function TKeyStoreServiceBase<T>.EncryptAndGenerateKeyStore(const APassword: string;
  const APrivateKey: TBytes; const AAddress: string; const AKdfParams: T): TKeyStore<T>;
var
  Salt, DerivedKey, CipherKey, IV, CipherText, Mac: TBytes;
  CryptoInfo: TCryptoInfo<T>;
  Id: string;
begin
  if APassword = '' then raise EArgumentNilException.Create('password');
  if Length(APrivateKey) = 0 then raise EArgumentNilException.Create('privateKey');
  if AAddress = '' then raise EArgumentNilException.Create('address');
  if AKdfParams = nil then raise EArgumentNilException.Create('kdfParams');

  // Random salt & IV
  Salt := GenerateRandomSalt;
  IV   := GenerateRandomInitializationVector;

  // KDF
  DerivedKey := GenerateDerivedKey(APassword, Salt, AKdfParams);
  // AES-128-CTR cipher key is first 16 bytes of derived key
  CipherKey  := FKeyStoreCrypto.GenerateCipherKey(DerivedKey);

  // Encrypt
  CipherText := GenerateCipher(APrivateKey, IV, CipherKey);

  // MAC
  Mac := FKeyStoreCrypto.GenerateMac(DerivedKey, CipherText);

  // Build crypto section (ownership of AKdfParams transfers here)
  CryptoInfo := TCryptoInfo<T>.Create(GetCipherType, CipherText, IV, Mac, Salt, AKdfParams, GetKdfType);

  Id := TGuid.NewGuid.ToString();
  Id := Copy(Id, 2, Length(Id) - 2); // remove { and }

  // Build keystore
  Result := TKeyStore<T>.Create;
  try
    Result.Version := CurrentVersion;
    Result.Address := AAddress;
    Result.Id      := Id.ToLower;
    Result.Crypto  := CryptoInfo;
  except
    Result.Free;
    raise;
  end;
end;

function TKeyStoreServiceBase<T>.EncryptAndGenerateKeyStoreAsJson(const APassword: string;
  const APrivateKey: TBytes; const AAddress: string): string;
var
  KS: TKeyStore<T>;
begin
  KS := EncryptAndGenerateKeyStore(APassword, APrivateKey, AAddress);
  try
    Result := SerializeKeyStoreToJson(KS);
  finally
    KS.Free;
  end;
end;

function TKeyStoreServiceBase<T>.EncryptAndGenerateKeyStoreAsJson(const APassword: string;
  const APrivateKey: TBytes; const AAddress: string; const AKdfParams: T): string;
var
  KS: TKeyStore<T>;
begin
  KS := EncryptAndGenerateKeyStore(APassword, APrivateKey, AAddress, AKdfParams);
  try
    Result := SerializeKeyStoreToJson(KS);
  finally
    KS.Free;
  end;
end;

function TKeyStoreServiceBase<T>.DecryptKeyStoreFromJson(const APassword, AJson: string): TBytes;
var
  KS: TKeyStore<T>;
begin
  KS := DeserializeKeyStoreFromJson(AJson);
  try
    Result := DecryptKeyStore(APassword, KS);
  finally
    KS.Free;
  end;
end;

{ TKeyStorePbkdf2Service }

constructor TKeyStorePbkdf2Service.Create(const ACrypto: TKeyStoreCrypto);
begin
  inherited Create(ACrypto);
end;

destructor TKeyStorePbkdf2Service.Destroy;
begin

  inherited;
end;

function TKeyStorePbkdf2Service.GenerateDerivedKey(const APassword: string; const ASalt: TBytes;
  const AKdfParams: TPbkdf2Params): TBytes;
begin
  Result := FKeyStoreCrypto.GeneratePbkdf2Sha256DerivedKey(APassword, ASalt, AKdfParams.Count, AKdfParams.DkLen);
end;

function TKeyStorePbkdf2Service.GetDefaultParams: TPbkdf2Params;
begin
  Result := TPbkdf2Params.Create;
  Result.DkLen := 32;
  Result.Count := 262144;
  Result.Prf   := 'hmac-sha256';
end;

function TKeyStorePbkdf2Service.DeserializeKeyStoreFromJson(const AJson: string): TKeyStore<TPbkdf2Params>;
begin
  Result := TJsonKeyStoreSerializer.TPbkdf2.Deserialize(AJson);
end;

function TKeyStorePbkdf2Service.SerializeKeyStoreToJson(const AKeyStore: TKeyStore<TPbkdf2Params>): string;
begin
  Result := TJsonKeyStoreSerializer.TPbkdf2.Serialize(AKeyStore);
end;

function TKeyStorePbkdf2Service.DecryptKeyStore(const APassword: string;
  const AKeyStore: TKeyStore<TPbkdf2Params>): TBytes;
var
  Mac, IV, CipherText, Salt: TBytes;
  DkLen: Integer;
begin
  if APassword = '' then raise EArgumentNilException.Create('password');
  if AKeyStore = nil then raise EArgumentNilException.Create('keyStore');

  Mac        := TEncoders.Hex.DecodeData(AKeyStore.Crypto.Mac);
  IV         := TEncoders.Hex.DecodeData(AKeyStore.Crypto.CipherParams.Iv);
  CipherText := TEncoders.Hex.DecodeData(AKeyStore.Crypto.CipherText);
  Salt       := TEncoders.Hex.DecodeData(AKeyStore.Crypto.KdfParams.Salt);

  DkLen := AKeyStore.Crypto.KdfParams.DkLen;

  if DkLen <= 0 then
    raise EArgumentException.Create('KeyLengthToDerive must be greater than zero');

  Result := FKeyStoreCrypto.DecryptPbkdf2Sha256(
    APassword, Mac, IV, CipherText,
    AKeyStore.Crypto.KdfParams.Count,
    Salt,
    AKeyStore.Crypto.KdfParams.DkLen
  );
end;

function TKeyStorePbkdf2Service.GetKdfType: string;
begin
  Result := KdfType;
end;

{ TKeyStoreScryptService }

constructor TKeyStoreScryptService.Create(const ACrypto: TKeyStoreCrypto);
begin
  inherited Create(ACrypto);
end;

destructor TKeyStoreScryptService.Destroy;
begin

  inherited;
end;

function TKeyStoreScryptService.GenerateDerivedKey(const APassword: string; const ASalt: TBytes;
  const AKdfParams: TScryptParams): TBytes;
begin
  Result := FKeyStoreCrypto.GenerateDerivedScryptKey(
    FKeyStoreCrypto.GetPasswordAsBytes(APassword),
    ASalt,
    AKdfParams.N, AKdfParams.R, AKdfParams.P,
    AKdfParams.DkLen
  );
end;

function TKeyStoreScryptService.GetDefaultParams: TScryptParams;
begin
  Result := TScryptParams.Create;
  Result.DkLen := 32;
  Result.N     := 262144;
  Result.R     := 1;
  Result.P     := 8;
end;

function TKeyStoreScryptService.DeserializeKeyStoreFromJson(const AJson: string): TKeyStore<TScryptParams>;
begin
  Result := TJsonKeyStoreSerializer.TScrypt.Deserialize(AJson);
end;

function TKeyStoreScryptService.SerializeKeyStoreToJson(const AKeyStore: TKeyStore<TScryptParams>): string;
begin
  Result := TJsonKeyStoreSerializer.TScrypt.Serialize(AKeyStore);
end;

function TKeyStoreScryptService.DecryptKeyStore(const APassword: string;
  const AKeyStore: TKeyStore<TScryptParams>): TBytes;
var
  Mac, IV, CipherText, Salt: TBytes;
  DkLen: Integer;
begin
  if APassword = '' then raise EArgumentNilException.Create('password');
  if AKeyStore = nil then raise EArgumentNilException.Create('keyStore');

  Mac        := TEncoders.Hex.DecodeData(AKeyStore.Crypto.Mac);
  IV         := TEncoders.Hex.DecodeData(AKeyStore.Crypto.CipherParams.Iv);
  CipherText := TEncoders.Hex.DecodeData(AKeyStore.Crypto.CipherText);
  Salt       := TEncoders.Hex.DecodeData(AKeyStore.Crypto.KdfParams.Salt);

  DkLen := AKeyStore.Crypto.KdfParams.DkLen;

  if DkLen <= 0 then
    raise EArgumentException.Create('DkLen must be greater than zero');

  Result := FKeyStoreCrypto.DecryptScrypt(
    APassword, Mac, IV, CipherText,
    AKeyStore.Crypto.KdfParams.N,
    AKeyStore.Crypto.KdfParams.P,
    AKeyStore.Crypto.KdfParams.R,
    Salt,
    AKeyStore.Crypto.KdfParams.DkLen
  );
end;

function TKeyStoreScryptService.GetKdfType: string;
begin
  Result := KdfType;
end;

end.

