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

unit SlpEd25519Bip32;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  SlpCryptoUtils,
  SlpArrayUtils,
  SlpBinaryPrimitives;

type
  /// <summary>Pair of key material and chain code.</summary>
  TKeyChain = record
    /// <summary>
    /// 32-byte **SLIP-0010 child key seed** (IL). For Ed25519 this is fed into the Ed25519 keypair generator,
    /// which performs its own hashing+clamping to produce the private scalar.
    /// </summary>
    Key: TBytes;
    /// <summary>32-byte chain code (IR) used as the HMAC key for the next derivation step.</summary>
    ChainCode: TBytes;
  end;

type
  /// <summary>An implementation of Ed25519-based BIP32 (SLIP-0010) hardened-only derivation.</summary>
  /// <remarks>
  /// Master: I = HMAC-SHA512(key="ed25519 seed", data=seed) → IL (Key), IR (ChainCode).<br/>
  /// Child (hardened): I = HMAC-SHA512(key=ChainCode, data=0x00 || Key || ser32(index|0x80000000)).<br/>
  /// The returned <c>Key</c> is IL (32 bytes) and must be passed to an Ed25519 key generator to obtain the actual keypair.
  /// </remarks>
  TEd25519Bip32 = class
  public

  private const
    /// <summary>The seed for the Ed25519 BIP32 HMAC-SHA512 master key calculation.</summary>
    Curve: string = 'ed25519 seed';
    /// <summary>Hardened child offset.</summary>
    HardenedOffset: Cardinal = $80000000;

  private
    FMasterKey, FChainCode: TBytes;

    class function GetMasterKeyFromSeed(const Seed: TBytes): TKeyChain; static;
    class function GetChildKeyDerivation(const Key, ChainCode: TBytes;
      Index: Cardinal): TKeyChain; static;
    class function HmacSha512(const KeyBuffer, Data: TBytes): TKeyChain; static;
    /// <summary>
    /// Checks if the derivation path is valid.
    /// <remarks>Returns true if the path is valid, otherwise false.</remarks>
    /// </summary>
    /// <param name="Path">The derivation path.</param>
    /// <returns>A boolean.</returns>
    class function IsValidPath(const Path: string): Boolean; static;
    class function ParseSegments(const Path: string): TArray<UInt32>; static;

  public
    /// <summary>Initialize the ed25519-based SLIP-0010 generator with the passed seed.</summary>
    /// <param name="Seed">The seed bytes.</param>
    constructor Create(const Seed: TBytes);

    /// <summary>Derives a child key from the passed derivation path.</summary>
    /// <param name="Path">The derivation path (e.g., m/44'/501'/0'/0'). All segments must be hardened.</param>
    /// <returns>The key and chaincode.</returns>
    /// <exception cref="Exception">Thrown when the derivation path is invalid or out of range.</exception>
    function DerivePath(const Path: string): TKeyChain;

    /// <summary>Access the computed master key (IL) after construction.</summary>
    property MasterKey: TBytes read FMasterKey;
    /// <summary>Access the computed master chain code (IR) after construction.</summary>
    property ChainCode: TBytes read FChainCode;
  end;

implementation

{ TEd25519Bip32 }

constructor TEd25519Bip32.Create(const Seed: TBytes);
var
  MC: TKeyChain;
begin
  inherited Create;
  MC := GetMasterKeyFromSeed(Seed);
  FMasterKey := MC.Key;
  FChainCode := MC.ChainCode;
end;

class function TEd25519Bip32.GetMasterKeyFromSeed(const Seed: TBytes): TKeyChain;
var
  KeyBuf: TBytes;
begin
  // HMAC-SHA512(key = "ed25519 seed", data = seed)
  KeyBuf := TEncoding.UTF8.GetBytes(Curve);
  try
    Result := HmacSha512(KeyBuf, Seed);
  finally
    if Length(KeyBuf) > 0 then
      FillChar(KeyBuf[0], Length(KeyBuf), 0);
  end;
end;

class function TEd25519Bip32.GetChildKeyDerivation(const Key, ChainCode: TBytes;
  Index: Cardinal): TKeyChain;
var
  Buf: TBytes;
  Off: Integer;
begin
  // Data = 0x00 || Key || BigEndian(Index)
  SetLength(Buf, 1 + Length(Key) + 4);
  try
    Buf[0] := 0;
    if Length(Key) > 0 then
      TArrayUtils.Copy<Byte>(Key, 0, Buf, 1, Length(Key));

    Off := 1 + Length(Key);
    // write UInt32 BE at Buf[Off .. Off+3]
    TBinaryPrimitives.WriteUInt32BigEndian(Buf, Off, Index);

    Result := HmacSha512(ChainCode, Buf);
  finally
    if Length(Buf) > 0 then
      FillChar(Buf[0], Length(Buf), 0);
  end;
end;

class function TEd25519Bip32.HmacSha512(const KeyBuffer, Data: TBytes): TKeyChain;
var
  Mac: TBytes;
begin
  Mac := THmacSHA512.Compute(KeyBuffer, Data);
  try
    if Length(Mac) <> 64 then
      raise EInvalidOpException.Create('HMAC-SHA512 returned unexpected length');

    SetLength(Result.Key, 32);
    SetLength(Result.ChainCode, 32);

    if Length(Mac) > 0 then
    begin
      TArrayUtils.Copy<Byte>(Mac, 0, Result.Key, 0, 32);
      TArrayUtils.Copy<Byte>(Mac, 32, Result.ChainCode, 0, 32);
    end;
  finally
    if Length(Mac) > 0 then
      FillChar(Mac[0], Length(Mac), 0);
  end;
end;

class function TEd25519Bip32.IsValidPath(const Path: string): Boolean;
var
  Clean: string;
  Parts: TArray<string>;
  i, j: Integer;
  s, num: string;
begin
  // Normalize trivial whitespace
  Clean := Trim(Path);
  if Clean = '' then
    Exit(False);

  // must start with 'm' and have at least one '/'
  if Clean[1] <> 'm' then
    Exit(False);

  Parts := Clean.Split(['/'], TStringSplitOptions.ExcludeEmpty);
  if Length(Parts) < 2 then
    Exit(False);
  if Parts[0] <> 'm' then
    Exit(False);

  // each segment after 'm' must be "<digits>'"
  for i := 1 to High(Parts) do
  begin
    s := Parts[i];
    if s = '' then
      Exit(False);
    if s[Length(s)] <> '''' then
      Exit(False);
    num := Copy(s, 1, Length(s) - 1);
    if num = '' then
      Exit(False);
    for j := 1 to Length(num) do
      if (num[j] < '0') or (num[j] > '9') then
        Exit(False);
  end;

  Result := True;
end;

class function TEd25519Bip32.ParseSegments(const Path: string): TArray<UInt32>;
var
  Parts: TArray<string>;
  i: Integer;
  num: string;
  val64: UInt64;
begin
  Parts := Trim(Path).Split(['/']);
  SetLength(Result, Length(Parts) - 1);
  for i := 1 to High(Parts) do
  begin
    // drop trailing apostrophe
    num := Copy(Parts[i], 1, Length(Parts[i]) - 1);

    try
      val64 := StrToUInt64(num);
    except
      on E: EConvertError do
        raise EConvertError.CreateFmt('Invalid derivation index "%s".', [num]);
    end;

    // for hardened Ed25519, raw index must be <= 4294967295
    if val64 > High(UInt32) then
      raise ERangeError.Create('Derivation index must be <= 4294967295 for hardened Ed25519');

    Result[i - 1] := UInt32(val64);
  end;
end;

function TEd25519Bip32.DerivePath(const Path: string): TKeyChain;
var
  Segs: TArray<Cardinal>;
  i: Integer;
  Cur: TKeyChain;
begin
  if not IsValidPath(Path) then
    raise Exception.Create('Invalid derivation path');

  Segs := ParseSegments(Path);

  Cur.Key := Copy(FMasterKey);
  Cur.ChainCode := Copy(FChainCode);

  for i := 0 to High(Segs) do
    Cur := GetChildKeyDerivation(Cur.Key, Cur.ChainCode, Segs[i] + HardenedOffset);

  Result := Cur;
end;

end.

