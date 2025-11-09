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

unit SlpCryptoUtils;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  ClpIDigest,
  ClpDigestUtilities,
  ClpIMac,
  ClpHMac,
  ClpIKeyParameter,
  ClpKeyParameter,
  ClpIParametersWithIV,
  ClpParametersWithIV,
  ClpIPbeParametersGenerator,
  ClpPkcs5S2ParametersGenerator,
  ClpIPkcs5S2ParametersGenerator,
  ClpICipherParameters,
  ClpIBufferedCipher,
  ClpCipherUtilities,
  ClpParameterUtilities,
  ClpISecureRandom,
  ClpSecureRandom,
  SlpEd25519Utils,
  SlpArrayUtils,
  SlpScryptImpl;

type
  {-------------------- HASH --------------------}
  THashAlgorithm = class abstract
  public
    class function HashData(const AData: TBytes): TBytes; virtual; abstract;
  end;

  /// <summary>SHA-256 hashing (bytes → bytes), static-style.</summary>
  TSHA256 = class(THashAlgorithm)
  public
    class function HashData(const AData: TBytes): TBytes; override;
  end;

  /// <summary>SHA-512 hashing (bytes → bytes), static-style.</summary>
  TSHA512 = class(THashAlgorithm)
  public
    class function HashData(const AData: TBytes): TBytes; override;
  end;

  /// <summary>KECCAK-256 hashing (bytes → bytes), static-style.</summary>
  TKECCAK256 = class(THashAlgorithm)
  public
    class function HashData(const AData: TBytes): TBytes; override;
  end;

  {-------------------- HMAC --------------------}
  TMacAlgorithm = class abstract
  public
    /// <summary>Compute MAC for the given key/data (bytes → bytes).</summary>
    class function Compute(const AKey, AData: TBytes): TBytes; virtual; abstract;
  end;

  /// <summary>HMAC over SHA-256 (bytes → bytes), static-style.</summary>
  THmacSHA256 = class(TMacAlgorithm)
  public
    class function Compute(const AKey, AData: TBytes): TBytes; override;
  end;

  /// <summary>HMAC over SHA-512 (bytes → bytes), static-style.</summary>
  THmacSHA512 = class(TMacAlgorithm)
  public
    class function Compute(const AKey, AData: TBytes): TBytes; override;
  end;

  {-------------------- KDF: PBKDF2 --------------------}
  TPbkdf2Algorithm = class abstract
  public
    /// <param name="Iterations">e.g., 100_000+</param>
    /// <param name="DKLen">Derived key length in BYTES</param>
    class function DeriveKey(const Password, Salt: TBytes;
      Iterations, DKLen: Integer): TBytes; virtual; abstract;
  end;

  /// <summary>PBKDF2-HMAC-SHA256 (bytes → bytes), static-style.</summary>
  TPbkdf2SHA256 = class(TPbkdf2Algorithm)
  public
    class function DeriveKey(const Password, Salt: TBytes;
      Iterations, DKLen: Integer): TBytes; override;
  end;

  /// <summary>PBKDF2-HMAC-SHA512 (bytes → bytes), static-style.</summary>
  TPbkdf2SHA512 = class(TPbkdf2Algorithm)
  public
    class function DeriveKey(const Password, Salt: TBytes;
      Iterations, DKLen: Integer): TBytes; override;
  end;

  {-------------------- KDF: scrypt --------------------}
  TScryptAlgorithm = class abstract
  public
    /// <param name="N">CPU/memory cost (power of two, e.g., 1 shl 15)</param>
    /// <param name="R">Block size (e.g., 8)</param>
    /// <param name="P">Parallelization (e.g., 1)</param>
    /// <param name="DKLen">Derived key length in BYTES</param>
    class function DeriveKey(const Password, Salt: TBytes;
      N, R, P, DKLen: Integer): TBytes; virtual; abstract;
  end;

  /// <summary>scrypt (bytes → bytes), static-style.</summary>
  TScrypt = class(TScryptAlgorithm)
  public
    class function DeriveKey(const Password, Salt: TBytes;
      N, R, P, DKLen: Integer): TBytes; override;
  end;

  {-------------------- CIPHERS: AES-CTR --------------------}
  TCipherAlgorithm = class abstract
  public
    /// <summary>Encrypt (or decrypt) data. Concrete modes define semantics.</summary>
    class function Encrypt(const Key, IV, Data: TBytes): TBytes; virtual; abstract;
    class function Decrypt(const Key, IV, Data: TBytes): TBytes; virtual; abstract;
  end;

  /// <summary>
  /// AES in CTR (SIC) mode. Encrypt and Decrypt are the same operation.
  /// Key sizes supported: 16/24/32 bytes. IV/Nonce must be 16 bytes.
  /// </summary>
  TAesCtr = class(TCipherAlgorithm)
  public
    class function Encrypt(const Key, IV, Data: TBytes): TBytes; override;
    class function Decrypt(const Key, IV, Data: TBytes): TBytes; override;
  end;

  {-------------------- RANDOM --------------------}
  /// <summary>Crypto-secure random bytes.</summary>
  TRandom = class
  private
    class var FInstance: ISecureRandom;

    class function GetInstance: ISecureRandom; static;

    class constructor Create();
  public

    class property Instance: ISecureRandom read GetInstance;
    /// <summary>Allocate and return <c>Size</c> random bytes.</summary>
    class function RandomBytes(Size: Integer): TBytes; static;
    /// <summary>Populates <c>Output</c> with random bytes.</summary>
    class procedure FillRandom(const Output: TBytes); static;
  end;

  type
  {-------------------- SIGNATURES: Ed25519 (libsodium format) --------------------}
  /// <summary>
  /// Ed25519 (libsodium-style) convenience wrappers:
  ///   - SecretKey64 = Seed(32) || PublicKey(32)
  ///   - PublicKey32 = 32 bytes
  /// </summary>
  TEd25519Crypto = class sealed
  public
    /// <summary>
    /// Generate keypair from a random 32-byte seed (libsodium-style).
    /// Outputs SecretKey64 (Seed||PublicKey) and PublicKey32.
    /// </summary>
    class function GenerateKeyPair(const Random: ISecureRandom): TEd25519KeyPair; overload; static;

    /// <summary>
    /// Generate keypair from a provided 32-byte seed (libsodium-style).
    /// Outputs SecretKey64 (Seed||PublicKey) and PublicKey32.
    /// </summary>
    class function GenerateKeyPair(const Seed32: TBytes): TEd25519KeyPair; overload; static;

    /// <summary>Sign a message using SecretKey64 (Seed||PublicKey). Returns a 64-byte signature.</summary>
    class function Sign(const SecretKey64, &Message: TBytes): TBytes; static;

    /// <summary>Verify a 64-byte signature using a 32-byte public key.</summary>
    class function Verify(const PublicKey32, &Message, Signature64: TBytes): Boolean; static;
  end;

  TMisc = class
  public
    class function ConstantTimeEquals(const A, B: TBytes): Boolean; static;
    class procedure Zeroize(var Arr: TBytes); static;
  end;


implementation

{ Helpers }

procedure ValidateAesKeyIv(const Key, IV: TBytes);
begin
  case Length(Key) of
    16, 24, 32: ; // ok
  else
    raise EArgumentException.Create('AES key must be 16, 24, or 32 bytes.');
  end;

  if Length(IV) <> 16 then
    raise EArgumentException.Create('AES-CTR IV/nonce must be 16 bytes.');
end;

{ TSHA256 }

class function TSHA256.HashData(const AData: TBytes): TBytes;
var
  D: IDigest;
begin
  D := TDigestUtilities.GetDigest('SHA-256');

  if Length(AData) > 0 then
    D.BlockUpdate(AData, 0, Length(AData));

  SetLength(Result, D.GetDigestSize());
  D.DoFinal(Result, 0);
end;

{ TSHA512 }

class function TSHA512.HashData(const AData: TBytes): TBytes;
var
  D: IDigest;
begin
  D := TDigestUtilities.GetDigest('SHA-512');

  if Length(AData) > 0 then
    D.BlockUpdate(AData, 0, Length(AData));

  SetLength(Result, D.GetDigestSize());
  D.DoFinal(Result, 0);
end;

{ TKECCAK256 }

class function TKECCAK256.HashData(const AData: TBytes): TBytes;
var
  D: IDigest;
begin
  D := TDigestUtilities.GetDigest('KECCAK-256');

  if Length(AData) > 0 then
    D.BlockUpdate(AData, 0, Length(AData));

  SetLength(Result, D.GetDigestSize());
  D.DoFinal(Result, 0);
end;

{ THmacSHA256 }

class function THmacSHA256.Compute(const AKey, AData: TBytes): TBytes;
var
  D: IDigest;
  H: IMac;
  KP: IKeyParameter;
begin
  D  := TDigestUtilities.GetDigest('SHA-256');
  H  := THMac.Create(D);
  KP := TKeyParameter.Create(AKey);
  H.Init(KP);

  if Length(AData) > 0 then
    H.BlockUpdate(AData, 0, Length(AData));

  SetLength(Result, H.GetMacSize());
  H.DoFinal(Result, 0);
end;

{ THmacSHA512 }

class function THmacSHA512.Compute(const AKey, AData: TBytes): TBytes;
var
  D: IDigest;
  H: IMac;
  KP: IKeyParameter;
begin
  D  := TDigestUtilities.GetDigest('SHA-512');
  H  := THMac.Create(D);
  KP := TKeyParameter.Create(AKey);
  H.Init(KP);

  if Length(AData) > 0 then
    H.BlockUpdate(AData, 0, Length(AData));

  SetLength(Result, H.GetMacSize());
  H.DoFinal(Result, 0);
end;


{ TPbkdf2SHA256 }

class function TPbkdf2SHA256.DeriveKey(const Password, Salt: TBytes;
  Iterations, DKLen: Integer): TBytes;
var
  Gen: IPkcs5S2ParametersGenerator;
  Params: ICipherParameters;
  KeyParam: IKeyParameter;
begin
  Gen := TPkcs5S2ParametersGenerator.Create(TDigestUtilities.GetDigest('SHA-256'));
  Gen.Init(Password, Salt, Iterations);

  Params := Gen.GenerateDerivedMacParameters(DKLen * 8); // bits
  KeyParam := Params as IKeyParameter;

  Result := KeyParam.GetKey();
end;

{ TPbkdf2SHA512 }

class function TPbkdf2SHA512.DeriveKey(const Password, Salt: TBytes; Iterations,
  DKLen: Integer): TBytes;
var
  Gen: IPkcs5S2ParametersGenerator;
  Params: ICipherParameters;
  KeyParam: IKeyParameter;
begin
  Gen := TPkcs5S2ParametersGenerator.Create(TDigestUtilities.GetDigest('SHA-512'));
  Gen.Init(Password, Salt, Iterations);

  Params := Gen.GenerateDerivedMacParameters(DKLen * 8); // bits
  KeyParam := Params as IKeyParameter;

  Result := KeyParam.GetKey();
end;

{ TScrypt }

class function TScrypt.DeriveKey(const Password, Salt: TBytes;
  N, R, P, DKLen: Integer): TBytes;
begin
  Result := TScryptImpl.DeriveKey(Password, Salt, N, R, P, DKLen);
end;

{ TAesCtr }

class function TAesCtr.Encrypt(const Key, IV, Data: TBytes): TBytes;
var
  Cipher: IBufferedCipher;
  KeyParams: IKeyParameter;
  KeyParamsWithIV: IParametersWithIV;
begin
  ValidateAesKeyIv(Key, IV);

  KeyParams := TParameterUtilities.CreateKeyParameter('AES', Key);
  KeyParamsWithIV := TParametersWithIV.Create(KeyParams, IV);

  Cipher := TCipherUtilities.GetCipher('AES/CTR/NoPadding');
  Cipher.Init(True, KeyParamsWithIV);
  Result := Cipher.DoFinal(Data);
end;

class function TAesCtr.Decrypt(const Key, IV, Data: TBytes): TBytes;
var
  Cipher: IBufferedCipher;
  KeyParams: IKeyParameter;
  KeyParamsWithIV: IParametersWithIV;
begin
  ValidateAesKeyIv(Key, IV);

  KeyParams := TParameterUtilities.CreateKeyParameter('AES', Key);
  KeyParamsWithIV := TParametersWithIV.Create(KeyParams, IV);

  Cipher := TCipherUtilities.GetCipher('AES/CTR/NoPadding');
  Cipher.Init(False, KeyParamsWithIV);
  Result := Cipher.DoFinal(Data);
end;

{ TRandom }

class constructor TRandom.Create;
begin
   FInstance := TSecureRandom.Create();
end;

class function TRandom.GetInstance: ISecureRandom;
begin
  if FInstance = nil then
    FInstance := TSecureRandom.Create();
  Result := FInstance;
end;

class function TRandom.RandomBytes(Size: Integer): TBytes;
begin
  if Size < 0 then
    raise EArgumentException.Create('Size must be >= 0');

  SetLength(Result, Size);
  if Size = 0 then
    Exit;

  FillRandom(Result);
end;

class procedure TRandom.FillRandom(const Output: TBytes);
begin
  if Length(Output) = 0 then
    Exit;

  FInstance.NextBytes(Output);
end;

{ TEd25519Crypto }

class function TEd25519Crypto.GenerateKeyPair(const Random: ISecureRandom): TEd25519KeyPair;
begin
  Result := TEd25519Libsodium.GenerateKeyPair(Random);
end;

class function TEd25519Crypto.GenerateKeyPair(const Seed32: TBytes): TEd25519KeyPair;
begin
  Result := TEd25519Libsodium.GenerateKeyPair(Seed32);
end;

class function TEd25519Crypto.Sign(const SecretKey64, &Message: TBytes): TBytes;
begin
  Result := TEd25519Libsodium.Sign(SecretKey64, &Message);
end;

class function TEd25519Crypto.Verify(const PublicKey32, &Message, Signature64: TBytes): Boolean;
begin
  Result := TEd25519Libsodium.Verify(PublicKey32, &Message, Signature64);
end;

{ TMisc }

class function TMisc.ConstantTimeEquals(const A, B: TBytes): Boolean;
var
  I: Integer;
  Diff: Byte;
begin
  if Length(A) <> Length(B) then
    Exit(False);
  Diff := 0;
  for I := 0 to High(A) do
    Diff := Diff or (A[I] xor B[I]);
  Result := (Diff = 0);
end;

class procedure TMisc.Zeroize(var Arr: TBytes);
begin
  if Length(Arr) = 0 then
    Exit;
  TArrayUtils.Fill<Byte>(Arr, 0, Length(Arr) * SizeOf(Byte), 0);
end;

end.

