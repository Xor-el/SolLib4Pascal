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

unit SlpKeyStoreCrypto;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  SlpCryptoUtils,
  SlpArrayUtils,
  SlpSolLibExceptions;

type
  /// <summary>
  /// Web3 Secret Storage helpers
  /// https://ethereum.org/developers/docs/data-structures-and-encoding/web3-secret-storage/
  /// </summary>
  TKeyStoreCrypto = class
  private
    procedure ValidateMac(const AMac, ACipherText, ADerivedKey: TBytes);
  public
    // --- KDFs ---
    function GenerateDerivedScryptKey(const APassword, ASalt: TBytes;
      const N, R, P, DKLen: Integer; const ACheckRandN: Boolean = False): TBytes;

    function GeneratePbkdf2Sha256DerivedKey(const APassword: string; const ASalt: TBytes;
      const ACount, ADKLen: Integer): TBytes;

    // --- Hash/MAC ---
    function CalculateKeccakHash(const AValue: TBytes): TBytes;
    function GenerateMac(const ADerivedKey, ACipherText: TBytes): TBytes;

    // --- AES-CTR ---
    function GenerateCipherKey(const ADerivedKey: TBytes): TBytes; // first 16 bytes of derived key
    function GenerateAesCtrCipher(const AIV, AEncryptKey, AInput: TBytes): TBytes;

    // --- Decrypt paths (with MAC validation) ---
    function DecryptScrypt(const APassword: string; const AMac, AIV, ACipherText: TBytes;
      const N, P, R: Integer; const ASalt: TBytes; const ADKLen: Integer): TBytes;

    function DecryptPbkdf2Sha256(const APassword: string; const AMac, AIV, ACipherText: TBytes;
      const ACount: Integer; const ASalt: TBytes; const ADKLen: Integer): TBytes;

    function Decrypt(const AMac, AIV, ACipherText, ADerivedKey: TBytes): TBytes;

    // --- Util ---
    function GetPasswordAsBytes(const APassword: string): TBytes;
  end;

implementation

{ TKeyStoreCrypto }

function TKeyStoreCrypto.CalculateKeccakHash(const AValue: TBytes): TBytes;
begin
  Result := TKECCAK256.HashData(AValue);
end;

function TKeyStoreCrypto.Decrypt(const AMac, AIV, ACipherText, ADerivedKey: TBytes): TBytes;
var
  EncryptKey: TBytes;
begin
  // Validate MAC before decryption
  ValidateMac(AMac, ACipherText, ADerivedKey);

  // AES-CTR key = first 16 bytes of derived key
  EncryptKey := GenerateCipherKey(ADerivedKey);

  // CTR is symmetric; for clarity we call Decrypt
  Result := TAesCtr.Decrypt(EncryptKey, AIV, ACipherText);
end;

function TKeyStoreCrypto.DecryptPbkdf2Sha256(const APassword: string; const AMac, AIV,
  ACipherText: TBytes; const ACount: Integer; const ASalt: TBytes; const ADKLen: Integer): TBytes;
var
  DerivedKey: TBytes;
begin
  DerivedKey := GeneratePbkdf2Sha256DerivedKey(APassword, ASalt, ACount, ADKLen);
  Result := Decrypt(AMac, AIV, ACipherText, DerivedKey);
end;

function TKeyStoreCrypto.DecryptScrypt(const APassword: string; const AMac, AIV,
  ACipherText: TBytes; const N, P, R: Integer; const ASalt: TBytes; const ADKLen: Integer): TBytes;
var
  DerivedKey, PwdBytes: TBytes;
begin
  PwdBytes := GetPasswordAsBytes(APassword);
  DerivedKey := GenerateDerivedScryptKey(PwdBytes, ASalt, N, R, P, ADKLen, False);
  Result := Decrypt(AMac, AIV, ACipherText, DerivedKey);
end;

function TKeyStoreCrypto.GenerateAesCtrCipher(const AIV, AEncryptKey, AInput: TBytes): TBytes;
begin
  Result := TAesCtr.Encrypt(AEncryptKey, AIV, AInput);
end;

function TKeyStoreCrypto.GenerateCipherKey(const ADerivedKey: TBytes): TBytes;
const
  KeyLen = 16;
begin
  if Length(ADerivedKey) < KeyLen then
    raise EArgumentException.Create('Derived key too short for AES-CTR (need >= 16 bytes).');
  SetLength(Result, KeyLen);
  if KeyLen > 0 then
    TArrayUtils.Copy<Byte>(ADerivedKey, 0, Result, 0, KeyLen);
end;

function TKeyStoreCrypto.GenerateDerivedScryptKey(const APassword, ASalt: TBytes;
  const N, R, P, DKLen: Integer; const ACheckRandN: Boolean): TBytes;
begin
  if ACheckRandN then
  begin
    if (R = 1) and (N >= 65536) then
      raise EArgumentException.Create('Cost parameter N must be > 1 and < 65536.');
  end;

  Result := TScrypt.DeriveKey(APassword, ASalt, N, R, P, DKLen);
end;

function TKeyStoreCrypto.GenerateMac(const ADerivedKey, ACipherText: TBytes): TBytes;
var
  Buf: TBytes;
  TailLen: Integer;
begin
  // MAC = keccak256( derivedKey[16..31] || cipherText )
  TailLen := 16;
  SetLength(Buf, TailLen + Length(ACipherText));

  TArrayUtils.Copy<Byte>(ADerivedKey, 16, Buf, 0, TailLen);
  if Length(ACipherText) > 0 then
    TArrayUtils.Copy<Byte>(ACipherText, 0, Buf, TailLen, Length(ACipherText));

  Result := CalculateKeccakHash(Buf);
end;

function TKeyStoreCrypto.GeneratePbkdf2Sha256DerivedKey(const APassword: string;
  const ASalt: TBytes; const ACount, ADKLen: Integer): TBytes;
var
  Pwd: TBytes;
begin
  Pwd := GetPasswordAsBytes(APassword);
  Result := TPbkdf2SHA256.DeriveKey(Pwd, ASalt, ACount, ADKLen);
end;

function TKeyStoreCrypto.GetPasswordAsBytes(const APassword: string): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(APassword);
end;

procedure TKeyStoreCrypto.ValidateMac(const AMac, ACipherText, ADerivedKey: TBytes);
var
  GeneratedMac: TBytes;
begin
  if AMac = nil then
    raise EArgumentNilException.Create('AMac');
  if ACipherText = nil then
    raise EArgumentNilException.Create('ACipherText');
  if ADerivedKey = nil then
    raise EArgumentNilException.Create('ADerivedKey');

  GeneratedMac := GenerateMac(ADerivedKey, ACipherText);
  if not TMisc.ConstantTimeEquals(GeneratedMac, AMac) then
    raise EDecryptionException.Create(
      'Cannot derive the same MAC from cipher and derived key.'
    );
end;


end.

