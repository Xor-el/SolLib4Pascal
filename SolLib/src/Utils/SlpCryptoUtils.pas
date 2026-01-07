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

unit SlpCryptoUtils;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  SlpCryptoProviders;

type
  {-------------------- HASH --------------------}
  THashAlgorithm = class abstract
  public
    class function HashData(const AData: TBytes): TBytes; virtual; abstract;
  end;

  /// <summary>SHA-256 hashing (bytes -> bytes), static-style.</summary>
  TSHA256 = class(THashAlgorithm)
  public
    class function HashData(const AData: TBytes): TBytes; override;
  end;

  /// <summary>SHA-512 hashing (bytes -> bytes), static-style.</summary>
  TSHA512 = class(THashAlgorithm)
  public
    class function HashData(const AData: TBytes): TBytes; override;
  end;

  /// <summary>KECCAK-256 hashing (bytes -> bytes), static-style.</summary>
  TKECCAK256 = class(THashAlgorithm)
  public
    class function HashData(const AData: TBytes): TBytes; override;
  end;

  {-------------------- HMAC --------------------}
  TMacAlgorithm = class abstract
  public
    /// <summary>Compute MAC for the given key/data (bytes -> bytes).</summary>
    class function Compute(const AKey, AData: TBytes): TBytes; virtual; abstract;
  end;

  /// <summary>HMAC over SHA-256 (bytes -> bytes), static-style.</summary>
  THmacSHA256 = class(TMacAlgorithm)
  public
    class function Compute(const AKey, AData: TBytes): TBytes; override;
  end;

  /// <summary>HMAC over SHA-512 (bytes -> bytes), static-style.</summary>
  THmacSHA512 = class(TMacAlgorithm)
  public
    class function Compute(const AKey, AData: TBytes): TBytes; override;
  end;

  {-------------------- KDF: PBKDF2 --------------------}
  TPbkdf2Algorithm = class abstract
  public
    /// <param name="Iterations">e.g., 100000+</param>
    /// <param name="DKLen">Derived key length in BYTES</param>
    class function DeriveKey(const Password, Salt: TBytes;
      Iterations, DKLen: Integer): TBytes; virtual; abstract;
  end;

  /// <summary>PBKDF2-HMAC-SHA256 (bytes -> bytes), static-style.</summary>
  TPbkdf2SHA256 = class(TPbkdf2Algorithm)
  public
    class function DeriveKey(const Password, Salt: TBytes;
      Iterations, DKLen: Integer): TBytes; override;
  end;

  /// <summary>PBKDF2-HMAC-SHA512 (bytes -> bytes), static-style.</summary>
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

  /// <summary>scrypt (bytes -> bytes), static-style.</summary>
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
  public
    /// <summary>Allocate and return <c>Size</c> random bytes.</summary>
    class function RandomBytes(Size: Integer): TBytes; static;
    /// <summary>Populates <c>Output</c> with random bytes.</summary>
    class procedure FillRandom(const Output: TBytes); static;
  end;

  {-------------------- SIGNATURES: Ed25519 (libsodium format) --------------------}
  /// <summary>
  /// Ed25519 (libsodium-style) convenience wrappers:
  ///   - SecretKey64 = Seed(32) || PublicKey(32)
  ///   - PublicKey32 = 32 bytes
  /// </summary>
  TEd25519Crypto = class sealed
  public
    /// <summary>
    /// Generate keypair from a provided 32-byte seed (libsodium-style).
    /// Outputs SecretKey64 (Seed||PublicKey) and PublicKey32.
    /// </summary>
    class function GenerateKeyPair(const Seed32: TBytes): TEd25519KeyPair; static;

    /// <summary>Sign a message using SecretKey64 (Seed||PublicKey). Returns a 64-byte signature.</summary>
    class function Sign(const SecretKey64, &Message: TBytes): TBytes; static;

    /// <summary>Verify a 64-byte signature using a 32-byte public key.</summary>
    class function Verify(const PublicKey32, &Message, Signature64: TBytes): Boolean; static;

    /// <summary>Check if a 32-byte public key is on the Ed25519 curve.</summary>
    class function IsOnCurve(const PublicKey32: TBytes): Boolean; static;
  end;

implementation

{ TSHA256 }

class function TSHA256.HashData(const AData: TBytes): TBytes;
begin
  Result := TCryptoProviders.Hash.SHA256(AData);
end;

{ TSHA512 }

class function TSHA512.HashData(const AData: TBytes): TBytes;
begin
  Result := TCryptoProviders.Hash.SHA512(AData);
end;

{ TKECCAK256 }

class function TKECCAK256.HashData(const AData: TBytes): TBytes;
begin
  Result := TCryptoProviders.Hash.Keccak256(AData);
end;

{ THmacSHA256 }

class function THmacSHA256.Compute(const AKey, AData: TBytes): TBytes;
begin
  Result := TCryptoProviders.Hmac.HmacSHA256(AKey, AData);
end;

{ THmacSHA512 }

class function THmacSHA512.Compute(const AKey, AData: TBytes): TBytes;
begin
  Result := TCryptoProviders.Hmac.HmacSHA512(AKey, AData);
end;

{ TPbkdf2SHA256 }

class function TPbkdf2SHA256.DeriveKey(const Password, Salt: TBytes;
  Iterations, DKLen: Integer): TBytes;
begin
  Result := TCryptoProviders.Kdf.Pbkdf2SHA256(Password, Salt, Iterations, DKLen);
end;

{ TPbkdf2SHA512 }

class function TPbkdf2SHA512.DeriveKey(const Password, Salt: TBytes;
  Iterations, DKLen: Integer): TBytes;
begin
  Result := TCryptoProviders.Kdf.Pbkdf2SHA512(Password, Salt, Iterations, DKLen);
end;

{ TScrypt }

class function TScrypt.DeriveKey(const Password, Salt: TBytes;
  N, R, P, DKLen: Integer): TBytes;
begin
  Result := TCryptoProviders.Kdf.Scrypt(Password, Salt, N, R, P, DKLen);
end;

{ TAesCtr }

class function TAesCtr.Encrypt(const Key, IV, Data: TBytes): TBytes;
begin
  Result := TCryptoProviders.Cipher.AesCtrEncrypt(Key, IV, Data);
end;

class function TAesCtr.Decrypt(const Key, IV, Data: TBytes): TBytes;
begin
  Result := TCryptoProviders.Cipher.AesCtrDecrypt(Key, IV, Data);
end;

{ TRandom }

class function TRandom.RandomBytes(Size: Integer): TBytes;
begin
  Result := TCryptoProviders.Random.RandomBytes(Size);
end;

class procedure TRandom.FillRandom(const Output: TBytes);
begin
  TCryptoProviders.Random.FillRandom(Output);
end;

{ TEd25519Crypto }

class function TEd25519Crypto.GenerateKeyPair(const Seed32: TBytes): TEd25519KeyPair;
begin
  Result := TCryptoProviders.Ed25519.GenerateKeyPair(Seed32);
end;

class function TEd25519Crypto.Sign(const SecretKey64, &Message: TBytes): TBytes;
begin
  Result := TCryptoProviders.Ed25519.Sign(SecretKey64, &Message);
end;

class function TEd25519Crypto.Verify(const PublicKey32, &Message, Signature64: TBytes): Boolean;
begin
  Result := TCryptoProviders.Ed25519.Verify(PublicKey32, &Message, Signature64);
end;

class function TEd25519Crypto.IsOnCurve(const PublicKey32: TBytes): Boolean;
begin
  Result := TCryptoProviders.Ed25519.IsOnCurve(PublicKey32);
end;

end.
