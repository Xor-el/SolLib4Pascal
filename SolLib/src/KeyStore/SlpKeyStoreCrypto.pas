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

unit SlpKeyStoreCrypto;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  SlpCryptoUtils,
  SlpArrayUtils,
  SlpSolLibExceptions;

type
  /// <summary>
  /// Web3 Secret Storage helpers.
  /// https://ethereum.org/developers/docs/data-structures-and-encoding/web3-secret-storage/
  /// </summary>
  TKeyStoreCrypto = class sealed
  private
    const
      /// <summary>AES-128-CTR key length in bytes.</summary>
      AesCtrKeyLen = 16;
      /// <summary>
      /// Offset into the derived key where the MAC input starts.
      /// MAC = keccak256( derivedKey[MacKeyOffset .. MacKeyOffset+AesCtrKeyLen-1] || cipherText )
      /// </summary>
      MacKeyOffset = 16;
      /// <summary>Minimum derived key length required (AES key + MAC key).</summary>
      MinDerivedKeyLen = MacKeyOffset + AesCtrKeyLen; // 32

    class procedure ValidateMac(const AMac, ACipherText, ADerivedKey: TBytes); static;
  public
    // --- KDFs ---

    class function GenerateDerivedScryptKey(const APassword, ASalt: TBytes;
      AN, AR, AP, ADKLen: Integer): TBytes; static;

    class function GeneratePbkdf2Sha256DerivedKey(const APassword: string;
      const ASalt: TBytes; ACount, ADKLen: Integer): TBytes; static;

    // --- Hash/MAC ---

    class function CalculateKeccakHash(const AValue: TBytes): TBytes; static;
    class function GenerateMac(const ADerivedKey, ACipherText: TBytes): TBytes; static;

    // --- AES-CTR ---

    /// <summary>Extracts the first 16 bytes of the derived key for AES-128-CTR.</summary>
    class function GenerateCipherKey(const ADerivedKey: TBytes): TBytes; static;
    class function GenerateAesCtrCipher(const AIV, AEncryptKey, AInput: TBytes): TBytes; static;

    // --- Decrypt paths (with MAC validation) ---

    class function DecryptScrypt(const APassword: string; const AMac, AIV,
      ACipherText: TBytes; AN, AR, AP: Integer; const ASalt: TBytes;
      ADKLen: Integer): TBytes; static;

    class function DecryptPbkdf2Sha256(const APassword: string; const AMac, AIV,
      ACipherText: TBytes; ACount: Integer; const ASalt: TBytes;
      ADKLen: Integer): TBytes; static;

    class function Decrypt(const AMac, AIV, ACipherText, ADerivedKey: TBytes): TBytes; static;

    // --- Util ---

    class function GetPasswordAsBytes(const APassword: string): TBytes; static;
  end;

implementation

{ TKeyStoreCrypto }

class function TKeyStoreCrypto.CalculateKeccakHash(const AValue: TBytes): TBytes;
begin
  Result := TKECCAK256.HashData(AValue);
end;

class function TKeyStoreCrypto.Decrypt(const AMac, AIV, ACipherText,
  ADerivedKey: TBytes): TBytes;
var
  LEncryptKey: TBytes;
begin
  ValidateMac(AMac, ACipherText, ADerivedKey);
  LEncryptKey := GenerateCipherKey(ADerivedKey);
  try
    Result := TAesCtr.Decrypt(LEncryptKey, AIV, ACipherText);
  finally
    TArrayUtils.Fill<Byte>(LEncryptKey);
  end;
end;

class function TKeyStoreCrypto.DecryptPbkdf2Sha256(const APassword: string;
  const AMac, AIV, ACipherText: TBytes; ACount: Integer; const ASalt: TBytes;
  ADKLen: Integer): TBytes;
var
  LDerivedKey: TBytes;
begin
  LDerivedKey := GeneratePbkdf2Sha256DerivedKey(APassword, ASalt, ACount, ADKLen);
  try
    Result := Decrypt(AMac, AIV, ACipherText, LDerivedKey);
  finally
    TArrayUtils.Fill<Byte>(LDerivedKey);
  end;
end;

class function TKeyStoreCrypto.DecryptScrypt(const APassword: string;
  const AMac, AIV, ACipherText: TBytes; AN, AR, AP: Integer;
  const ASalt: TBytes; ADKLen: Integer): TBytes;
var
  LDerivedKey, LPwdBytes: TBytes;
begin
  LPwdBytes := GetPasswordAsBytes(APassword);
  try
    LDerivedKey := GenerateDerivedScryptKey(LPwdBytes, ASalt, AN, AR, AP, ADKLen);
    try
      Result := Decrypt(AMac, AIV, ACipherText, LDerivedKey);
    finally
      TArrayUtils.Fill<Byte>(LDerivedKey);
    end;
  finally
    TArrayUtils.Fill<Byte>(LPwdBytes);
  end;
end;

class function TKeyStoreCrypto.GenerateAesCtrCipher(const AIV, AEncryptKey,
  AInput: TBytes): TBytes;
begin
  Result := TAesCtr.Encrypt(AEncryptKey, AIV, AInput);
end;

class function TKeyStoreCrypto.GenerateCipherKey(const ADerivedKey: TBytes): TBytes;
begin
  if Length(ADerivedKey) < AesCtrKeyLen then
    raise EArgumentException.Create('Derived key too short for AES-128-CTR');
  SetLength(Result, AesCtrKeyLen);
  Move(ADerivedKey[0], Result[0], AesCtrKeyLen);
end;

class function TKeyStoreCrypto.GenerateDerivedScryptKey(const APassword, ASalt: TBytes;
  AN, AR, AP, ADKLen: Integer): TBytes;
begin
  Result := TScrypt.DeriveKey(APassword, ASalt, AN, AR, AP, ADKLen);
end;

class function TKeyStoreCrypto.GenerateMac(const ADerivedKey, ACipherText: TBytes): TBytes;
var
  LBuf: TBytes;
begin
  if Length(ADerivedKey) < MinDerivedKeyLen then
    raise EArgumentException.Create('Derived key too short for MAC generation');

  // MAC = keccak256( derivedKey[16..31] || cipherText )
  SetLength(LBuf, AesCtrKeyLen + Length(ACipherText));
  try
    Move(ADerivedKey[MacKeyOffset], LBuf[0], AesCtrKeyLen);
    if Length(ACipherText) > 0 then
      Move(ACipherText[0], LBuf[AesCtrKeyLen], Length(ACipherText));
    Result := CalculateKeccakHash(LBuf);
  finally
    TArrayUtils.Fill<Byte>(LBuf);
  end;
end;

class function TKeyStoreCrypto.GeneratePbkdf2Sha256DerivedKey(
  const APassword: string; const ASalt: TBytes;
  ACount, ADKLen: Integer): TBytes;
var
  LPwd: TBytes;
begin
  LPwd := GetPasswordAsBytes(APassword);
  try
    Result := TPbkdf2SHA256.DeriveKey(LPwd, ASalt, ACount, ADKLen);
  finally
    TArrayUtils.Fill<Byte>(LPwd);
  end;
end;

class function TKeyStoreCrypto.GetPasswordAsBytes(const APassword: string): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(APassword);
end;

class procedure TKeyStoreCrypto.ValidateMac(const AMac, ACipherText,
  ADerivedKey: TBytes);
var
  LGeneratedMac: TBytes;
begin
  if AMac = nil then
    raise EArgumentNilException.Create('AMac');
  if ACipherText = nil then
    raise EArgumentNilException.Create('ACipherText');
  if ADerivedKey = nil then
    raise EArgumentNilException.Create('ADerivedKey');

  LGeneratedMac := GenerateMac(ADerivedKey, ACipherText);
  try
    if not TArrayUtils.ConstantTimeEquals(LGeneratedMac, AMac) then
      raise EDecryptionException.Create(
        'Cannot derive the same MAC from cipher and derived key.');
  finally
    TArrayUtils.Fill<Byte>(LGeneratedMac);
  end;
end;

end.

