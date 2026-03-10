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

unit SlpEd25519Bip32;

{$I ../Include/SolLib.inc}

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
  /// Master: I = HMAC-SHA512(key="ed25519 seed", data=seed) -> IL (Key), IR (ChainCode).<br/>
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

    class function GetMasterKeyFromSeed(const ASeed: TBytes): TKeyChain; static;
    class function GetChildKeyDerivation(const AKey, AChainCode: TBytes;
      AIndex: Cardinal): TKeyChain; static;
    class function HmacSha512(const AKeyBuffer, AData: TBytes): TKeyChain; static;
    /// <summary>
    /// Checks if the derivation path is valid.
    /// <remarks>Returns true if the path is valid, otherwise false.</remarks>
    /// </summary>
    /// <param name="Path">The derivation path.</param>
    /// <returns>A boolean.</returns>
    class function IsValidPath(const APath: string): Boolean; static;
    class function ParseSegments(const APath: string): TArray<UInt32>; static;

  public
    /// <summary>Initialize the ed25519-based SLIP-0010 generator with the passed seed.</summary>
    /// <param name="Seed">The seed bytes.</param>
    constructor Create(const ASeed: TBytes);

    /// <summary>Derives a child key from the passed derivation path.</summary>
    /// <param name="Path">The derivation path (e.g., m/44'/501'/0'/0'). All segments must be hardened.</param>
    /// <returns>The key and chaincode.</returns>
    /// <exception cref="Exception">Thrown when the derivation path is invalid or out of range.</exception>
    function DerivePath(const APath: string): TKeyChain;

    /// <summary>Access the computed master key (IL) after construction.</summary>
    property MasterKey: TBytes read FMasterKey;
    /// <summary>Access the computed master chain code (IR) after construction.</summary>
    property ChainCode: TBytes read FChainCode;
  end;

implementation

{ TEd25519Bip32 }

constructor TEd25519Bip32.Create(const ASeed: TBytes);
var
  MC: TKeyChain;
begin
  inherited Create;
  MC := GetMasterKeyFromSeed(ASeed);
  FMasterKey := MC.Key;
  FChainCode := MC.ChainCode;
end;

class function TEd25519Bip32.GetMasterKeyFromSeed(const ASeed: TBytes): TKeyChain;
var
  LKeyBuf: TBytes;
begin
  // HMAC-SHA512(key = "ed25519 seed", data = seed)
  LKeyBuf := TEncoding.UTF8.GetBytes(Curve);
  try
    Result := HmacSha512(LKeyBuf, ASeed);
  finally
    if Length(LKeyBuf) > 0 then
      FillChar(LKeyBuf[0], Length(LKeyBuf), 0);
  end;
end;

class function TEd25519Bip32.GetChildKeyDerivation(const AKey, AChainCode: TBytes;
  AIndex: Cardinal): TKeyChain;
var
  LBuf: TBytes;
  LOff: Integer;
begin
  // Data = 0x00 || Key || BigEndian(Index)
  SetLength(LBuf, 1 + Length(AKey) + 4);
  try
    LBuf[0] := 0;
    if Length(AKey) > 0 then
      TArrayUtils.Copy<Byte>(AKey, 0, LBuf, 1, Length(AKey));

    LOff := 1 + Length(AKey);
    // write UInt32 BE at LBuf[LOff .. LOff+3]
    TBinaryPrimitives.WriteUInt32BigEndian(LBuf, LOff, AIndex);

    Result := HmacSha512(AChainCode, LBuf);
  finally
    if Length(LBuf) > 0 then
      FillChar(LBuf[0], Length(LBuf), 0);
  end;
end;

class function TEd25519Bip32.HmacSha512(const AKeyBuffer, AData: TBytes): TKeyChain;
var
  LMac: TBytes;
begin
  LMac := THmacSHA512.Compute(AKeyBuffer, AData);
  try
    if Length(LMac) <> 64 then
      raise EInvalidOpException.Create('HMAC-SHA512 returned unexpected length');

    SetLength(Result.Key, 32);
    SetLength(Result.ChainCode, 32);

    if Length(LMac) > 0 then
    begin
      TArrayUtils.Copy<Byte>(LMac, 0, Result.Key, 0, 32);
      TArrayUtils.Copy<Byte>(LMac, 32, Result.ChainCode, 0, 32);
    end;
  finally
    if Length(LMac) > 0 then
      FillChar(LMac[0], Length(LMac), 0);
  end;
end;

class function TEd25519Bip32.IsValidPath(const APath: string): Boolean;
var
  LClean: string;
  LParts: TArray<string>;
  LI, LJ: Integer;
  LS, LNum: string;
begin
  // Normalize trivial whitespace
  LClean := Trim(APath);
  if LClean = '' then
    Exit(False);

  // must start with 'm' and have at least one '/'
  if LClean[1] <> 'm' then
    Exit(False);

  LParts := LClean.Split(['/'], TStringSplitOptions.ExcludeEmpty);
  if Length(LParts) < 2 then
    Exit(False);
  if LParts[0] <> 'm' then
    Exit(False);

  // each segment after 'm' must be "<digits>'"
  for LI := 1 to High(LParts) do
  begin
    LS := LParts[LI];
    if LS = '' then
      Exit(False);
    if LS[Length(LS)] <> '''' then
      Exit(False);
    LNum := Copy(LS, 1, Length(LS) - 1);
    if LNum = '' then
      Exit(False);
    for LJ := 1 to Length(LNum) do
      if (LNum[LJ] < '0') or (LNum[LJ] > '9') then
        Exit(False);
  end;

  Result := True;
end;

class function TEd25519Bip32.ParseSegments(const APath: string): TArray<UInt32>;
var
  LParts: TArray<string>;
  LI: Integer;
  LNum: string;
  LVal64: UInt64;
begin
  LParts := Trim(APath).Split(['/']);
  SetLength(Result, Length(LParts) - 1);
  for LI := 1 to High(LParts) do
  begin
    // drop trailing apostrophe
    LNum := Copy(LParts[LI], 1, Length(LParts[LI]) - 1);

    try
      LVal64 := StrToUInt64(LNum);
    except
      on E: EConvertError do
        raise EConvertError.CreateFmt('Invalid derivation index "%s".', [LNum]);
    end;

    // for hardened Ed25519, raw index must be <= 4294967295
    if LVal64 > High(UInt32) then
      raise ERangeError.Create('Derivation index must be <= 4294967295 for hardened Ed25519');

    Result[LI - 1] := UInt32(LVal64);
  end;
end;

function TEd25519Bip32.DerivePath(const APath: string): TKeyChain;
var
  LSegs: TArray<Cardinal>;
  LI: Integer;
  LCur: TKeyChain;
begin
  if not IsValidPath(APath) then
    raise Exception.Create('Invalid derivation path');

  LSegs := ParseSegments(APath);

  LCur.Key := Copy(FMasterKey);
  LCur.ChainCode := Copy(FChainCode);

  for LI := 0 to High(LSegs) do
    LCur := GetChildKeyDerivation(LCur.Key, LCur.ChainCode, LSegs[LI] + HardenedOffset);

  Result := LCur;
end;

end.

