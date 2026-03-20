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
  SlpCryptoUtilities,
  SlpArrayUtilities,
  SlpBinaryPrimitives;

type
  /// <summary>Pair of key material and chain code.</summary>
  TKeyChain = record
    /// <summary>
    /// 32-byte SLIP-0010 child key seed (IL). For Ed25519 this is fed into
    /// the Ed25519 keypair generator, which performs its own hashing+clamping
    /// to produce the private scalar.
    /// </summary>
    Key: TBytes;
    /// <summary>32-byte chain code (IR) used as the HMAC key for the next derivation step.</summary>
    ChainCode: TBytes;
    /// <summary>Zeroes both Key and ChainCode in place.</summary>
    procedure Wipe;
  end;

  /// <summary>An implementation of Ed25519-based BIP32 (SLIP-0010) hardened-only derivation.</summary>
  /// <remarks>
  /// Master: I = HMAC-SHA512(key="ed25519 seed", data=seed) -> IL (Key), IR (ChainCode).<br/>
  /// Child (hardened): I = HMAC-SHA512(key=ChainCode, data=0x00 || Key || ser32(index|0x80000000)).<br/>
  /// The returned <c>Key</c> is IL (32 bytes) and must be passed to an Ed25519 key generator
  /// to obtain the actual keypair.
  /// </remarks>
  TEd25519Bip32 = class
  private
    const
      /// <summary>
      /// Pre-computed UTF-8 encoding of "ed25519 seed", the HMAC key for
      /// the SLIP-0010 master key derivation.
      /// </summary>
      CurveKey: array[0..11] of Byte = (
        $65, $64, $32, $35, $35, $31, $39, $20,  // "ed25519 "
        $73, $65, $65, $64                         // "seed"
      );
      /// <summary>Hardened child offset (BIP32).</summary>
      HardenedOffset: Cardinal = $80000000;
      /// <summary>Expected HMAC-SHA512 output length.</summary>
      HmacLen = 64;
      /// <summary>Key and chain code length (each half of HMAC output).</summary>
      HalfLen = 32;

    var
      FMasterKey: TBytes;
      FChainCode: TBytes;

    class function GetMasterKeyFromSeed(const ASeed: TBytes): TKeyChain; static;
    class function GetChildKeyDerivation(const AKey, AChainCode: TBytes;
      AIndex: Cardinal): TKeyChain; static;
    class function SplitHmac(const AKeyBuffer, AData: TBytes): TKeyChain; static;
    /// <summary>
    /// Parses and validates a SLIP-0010 derivation path.
    /// Returns the parsed hardened indices (without the hardened offset applied).
    /// Raises on invalid paths.
    /// </summary>
    class function ParsePath(const APath: string): TArray<UInt32>; static;
  public
    /// <summary>Initialize the Ed25519-based SLIP-0010 generator with the passed seed.</summary>
    constructor Create(const ASeed: TBytes);

    /// <summary>Derives a child key from the passed derivation path.</summary>
    /// <param name="APath">The derivation path (e.g., m/44'/501'/0'/0'). All segments must be hardened.</param>
    /// <returns>The key and chain code.</returns>
    function DerivePath(const APath: string): TKeyChain;

    /// <summary>Access the computed master key (IL) after construction.</summary>
    property MasterKey: TBytes read FMasterKey;
    /// <summary>Access the computed master chain code (IR) after construction.</summary>
    property ChainCode: TBytes read FChainCode;
  end;

implementation

{ TKeyChain }

procedure TKeyChain.Wipe;
begin
  if Key <> nil then
    TArrayUtilities.Fill<Byte>(Key, 0);
  if ChainCode <> nil then
    TArrayUtilities.Fill<Byte>(ChainCode, 0);
end;

{ TEd25519Bip32 }

constructor TEd25519Bip32.Create(const ASeed: TBytes);
var
  LMaster: TKeyChain;
begin
  inherited Create;
  LMaster := GetMasterKeyFromSeed(ASeed);
  FMasterKey := LMaster.Key;
  FChainCode := LMaster.ChainCode;
end;

class function TEd25519Bip32.GetMasterKeyFromSeed(const ASeed: TBytes): TKeyChain;
var
  LKeyBuf: TBytes;
begin
  // HMAC-SHA512(key = "ed25519 seed", data = seed)
  SetLength(LKeyBuf, Length(CurveKey));
  Move(CurveKey[0], LKeyBuf[0], Length(CurveKey));
  try
    Result := SplitHmac(LKeyBuf, ASeed);
  finally
    TArrayUtilities.Fill<Byte>(LKeyBuf, 0);
  end;
end;

class function TEd25519Bip32.GetChildKeyDerivation(const AKey, AChainCode: TBytes;
  AIndex: Cardinal): TKeyChain;
var
  LBuf: TBytes;
begin
  // Data = 0x00 || Key(32) || BigEndian(Index)
  SetLength(LBuf, 1 + HalfLen + 4);
  try
    LBuf[0] := 0;
    Move(AKey[0], LBuf[1], HalfLen);
    TBinaryPrimitives.WriteUInt32BigEndian(LBuf, 1 + HalfLen, AIndex);
    Result := SplitHmac(AChainCode, LBuf);
  finally
    TArrayUtilities.Fill<Byte>(LBuf, 0);
  end;
end;

class function TEd25519Bip32.SplitHmac(const AKeyBuffer, AData: TBytes): TKeyChain;
var
  LMac: TBytes;
begin
  LMac := THmacSHA512.Compute(AKeyBuffer, AData);
  try
    if Length(LMac) <> HmacLen then
      raise EInvalidOpException.Create('HMAC-SHA512 returned unexpected length');
    SetLength(Result.Key, HalfLen);
    SetLength(Result.ChainCode, HalfLen);
    Move(LMac[0], Result.Key[0], HalfLen);
    Move(LMac[HalfLen], Result.ChainCode[0], HalfLen);
  finally
    TArrayUtilities.Fill<Byte>(LMac, 0);
  end;
end;

class function TEd25519Bip32.ParsePath(const APath: string): TArray<UInt32>;
var
  LTrimmed: string;
  LParts: TArray<string>;
  LI, LJ: Integer;
  LSegment, LNum: string;
  LVal64: UInt64;
begin
  LTrimmed := Trim(APath);

  // Must start with 'm' and contain at least one segment
  if (LTrimmed = '') or (LTrimmed[1] <> 'm') then
    raise EArgumentException.Create('Invalid derivation path');

  LParts := LTrimmed.Split(['/'], TStringSplitOptions.ExcludeEmpty);
  if (Length(LParts) < 2) or (LParts[0] <> 'm') then
    raise EArgumentException.Create('Invalid derivation path');

  SetLength(Result, Length(LParts) - 1);
  for LI := 1 to High(LParts) do
  begin
    LSegment := LParts[LI];

    // Each segment must end with apostrophe (hardened)
    if (LSegment = '') or (LSegment[Length(LSegment)] <> '''') then
      raise EArgumentException.Create('All derivation segments must be hardened');

    // Extract numeric part
    LNum := Copy(LSegment, 1, Length(LSegment) - 1);
    if LNum = '' then
      raise EArgumentException.Create('Empty derivation index');

    // Validate all digits
    for LJ := 1 to Length(LNum) do
      if (LNum[LJ] < '0') or (LNum[LJ] > '9') then
        raise EArgumentException.CreateFmt('Invalid derivation index "%s"', [LNum]);

    LVal64 := StrToUInt64(LNum);
    if LVal64 > High(UInt32) then
      raise ERangeError.CreateFmt('Derivation index %s exceeds UInt32 range', [LNum]);

    Result[LI - 1] := UInt32(LVal64);
  end;
end;

function TEd25519Bip32.DerivePath(const APath: string): TKeyChain;
var
  LSegs: TArray<UInt32>;
  LI: Integer;
  LPrev: TKeyChain;
begin
  LSegs := ParsePath(APath);

  Result.Key := Copy(FMasterKey);
  Result.ChainCode := Copy(FChainCode);

  for LI := 0 to High(LSegs) do
  begin
    LPrev := Result;
    try
      Result := GetChildKeyDerivation(LPrev.Key, LPrev.ChainCode,
        LSegs[LI] + HardenedOffset);
    finally
      LPrev.Wipe;
    end;
  end;
end;

end.
