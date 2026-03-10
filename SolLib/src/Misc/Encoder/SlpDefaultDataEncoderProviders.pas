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

unit SlpDefaultDataEncoderProviders;

{$I ../../Include/SolLib.inc}

interface

uses
{$IFDEF FPC}
  StrUtils, // FPC needs StrUtils for BinToHex/HexToBin
{$ENDIF}
  System.SysUtils,
  System.NetEncoding,
  System.Classes,
  SlpDataEncoderProviders;

type
  /// <summary>
  /// Default Base58 encoder provider implementation.
  /// Uses the Bitcoin alphabet: 123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
  /// </summary>
  TDefaultBase58EncoderProvider = class(TInterfacedObject, IDataEncoderProvider)
  private
    const
      /// <summary>
      /// Base58 alphabet (Bitcoin).
      /// </summary>
      Alphabet: array[0..57] of Char = (
        '1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','G',
        'H','J','K','L','M','N','P','Q','R','S','T','U','V','W','X','Y',
        'Z','a','b','c','d','e','f','g','h','i','j','k','m','n','o','p',
        'q','r','s','t','u','v','w','x','y','z'
      );
      /// <summary>
      /// Reverse lookup: Ord(char) -> Base58 digit value, or -1 if invalid.
      /// </summary>
      CharMap: array[0..255] of Integer = (
        -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
        -1, 0, 1, 2, 3, 4, 5, 6,  7, 8,-1,-1,-1,-1,-1,-1,
        -1, 9,10,11,12,13,14,15, 16,-1,17,18,19,20,21,-1,
        22,23,24,25,26,27,28,29, 30,31,32,-1,-1,-1,-1,-1,
        -1,33,34,35,36,37,38,39, 40,41,42,43,-1,44,45,46,
        47,48,49,50,51,52,53,54, 55,56,57,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1
      );
    /// <summary>
    /// Core big-number multiply-and-add used by both encode and decode.
    /// Treats ABuf[0..ASize-1] as a big-endian number in base ADivisor,
    /// multiplies it by AMultiplier, adds ACarryIn, and stores the result
    /// back into ABuf. Updates AWorkLen with the number of active digits.
    /// </summary>
    class procedure BigNumMultiplyAdd(var ABuf: TBytes; ASize, AMultiplier,
      ADivisor, ACarryIn: Integer; var AWorkLen: Integer); static;
    /// <summary>
    /// Counts leading elements equal to AValue in ABuf[AFrom..ATo-1].
    /// </summary>
    class function CountLeadingBytes(const ABuf: TBytes;
      AFrom, ATo: Integer; AValue: Byte): Integer; static;
    /// <summary>
    /// Counts leading occurrences of AChar in AStr[AFrom..ATo-1].
    /// </summary>
    class function CountLeadingChars(const AStr: string;
      AFrom, ATo: Integer; AChar: Char): Integer; static;
    /// <summary>
    /// Builds a byte array with ALeadCount leading bytes of ALeadValue
    /// followed by ABuf[ASrcStart..ASrcStart+ALen-1].
    /// </summary>
    class function BuildResult(const ABuf: TBytes; ASrcStart, ALen,
      ALeadCount: Integer; ALeadValue: Byte): TBytes; static;
  public
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
    function DecodeData(const AEncoded: string): TBytes;
    function IsValid(const AEncoded: string): Boolean;
  end;

  /// <summary>
  /// Default Base64 encoder provider implementation.
  /// Enforces strict validation: no whitespace, correct padding, valid alphabet.
  /// </summary>
  TDefaultBase64EncoderProvider = class(TInterfacedObject, IDataEncoderProvider)
  private
    function ValidateBase64Strict(const AStr: string): Boolean;
  public
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
    function DecodeData(const AEncoded: string): TBytes;
    function IsValid(const AEncoded: string): Boolean;
  end;

  /// <summary>
  /// Default Hex encoder provider implementation.
  /// Produces uppercase hex. Accepts both upper and lower case on decode/validate.
  /// </summary>
  TDefaultHexEncoderProvider = class(TInterfacedObject, IDataEncoderProvider)
  public
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
    function DecodeData(const AEncoded: string): TBytes;
    function IsValid(const AEncoded: string): Boolean;
  end;

  /// <summary>
  /// Solana keypair JSON array encoder provider.
  /// Encodes/decodes the JSON byte array format used by solana-keygen CLI
  /// keypair files, e.g. [12,45,200,...] (64-byte Ed25519 seed||pubkey).
  /// </summary>
  TDefaultSolanaKeyPairJsonEncoderProvider = class(TInterfacedObject, IDataEncoderProvider)
  private
    const SolanaKeyPairLength = 64;
    function TryParse(const AEncoded: string; out ABytes: TBytes): Boolean;
  public
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
    function DecodeData(const AEncoded: string): TBytes;
    function IsValid(const AEncoded: string): Boolean;
  end;

implementation

{ Shared helper }

/// <summary>
/// Validates offset/count parameters against a byte array.
/// Raises EArgumentNilException if AData is nil.
/// Raises ERangeError if offset/count are out of bounds.
/// </summary>
procedure ValidateRange(const AData: TBytes; AOffset, ACount: Integer);
begin
  if AData = nil then
    raise EArgumentNilException.Create('data');
  if (AOffset < 0) or (ACount < 0) or (AOffset + ACount > Length(AData)) then
    raise ERangeError.Create('Invalid offset/count');
end;

{ TDefaultBase58EncoderProvider }

class procedure TDefaultBase58EncoderProvider.BigNumMultiplyAdd(var ABuf: TBytes;
  ASize, AMultiplier, ADivisor, ACarryIn: Integer; var AWorkLen: Integer);
var
  LCarry, LI, LIt: Integer;
begin
  LCarry := ACarryIn;
  LI := 0;
  for LIt := ASize - 1 downto 0 do
  begin
    if (LCarry = 0) and (LI >= AWorkLen) then
      if LIt < (ASize - 1) then
        Break;
    LCarry := LCarry + AMultiplier * ABuf[LIt];
    ABuf[LIt] := Byte(LCarry mod ADivisor);
    LCarry := LCarry div ADivisor;
    Inc(LI);
  end;
  AWorkLen := LI;
end;

class function TDefaultBase58EncoderProvider.CountLeadingBytes(const ABuf: TBytes;
  AFrom, ATo: Integer; AValue: Byte): Integer;
begin
  Result := 0;
  while (AFrom < ATo) and (ABuf[AFrom] = AValue) do
  begin
    Inc(AFrom);
    Inc(Result);
  end;
end;

class function TDefaultBase58EncoderProvider.CountLeadingChars(const AStr: string;
  AFrom, ATo: Integer; AChar: Char): Integer;
begin
  Result := 0;
  while (AFrom < ATo) and (AStr[AFrom] = AChar) do
  begin
    Inc(AFrom);
    Inc(Result);
  end;
end;

class function TDefaultBase58EncoderProvider.BuildResult(const ABuf: TBytes;
  ASrcStart, ALen, ALeadCount: Integer; ALeadValue: Byte): TBytes;
var
  LI: Integer;
begin
  SetLength(Result, ALeadCount + ALen);
  for LI := 0 to ALeadCount - 1 do
    Result[LI] := ALeadValue;
  if ALen > 0 then
    Move(ABuf[ASrcStart], Result[ALeadCount], ALen);
end;

function TDefaultBase58EncoderProvider.EncodeData(const AData: TBytes;
  AOffset, ACount: Integer): string;
var
  LZeroes, LWorkLen, LSize, LStart, LPos, LEnd: Integer;
  LB58: TBytes;
begin
  ValidateRange(AData, AOffset, ACount);

  LEnd := AOffset + ACount;
  LZeroes := CountLeadingBytes(AData, AOffset, LEnd, 0);
  Inc(AOffset, LZeroes);

  // log(256)/log(58) ~ 1.3863; 138/100 is a safe integer approximation
  LSize := (LEnd - AOffset) * 138 div 100 + 1;
  SetLength(LB58, LSize);

  LWorkLen := 0;
  while AOffset < LEnd do
  begin
    BigNumMultiplyAdd(LB58, LSize, 256, 58, AData[AOffset], LWorkLen);
    Inc(AOffset);
  end;

  // Skip leading zero digits in the base58 buffer
  LStart := LSize - LWorkLen;
  LStart := LStart + CountLeadingBytes(LB58, LStart, LSize, 0);

  // Build result: leading '1's + encoded characters
  SetLength(Result, LZeroes + LSize - LStart);
  for LPos := 1 to LZeroes do
    Result[LPos] := '1';
  LPos := LZeroes + 1;
  while LStart < LSize do
  begin
    Result[LPos] := Alphabet[LB58[LStart]];
    Inc(LPos);
    Inc(LStart);
  end;
end;

function TDefaultBase58EncoderProvider.DecodeData(const AEncoded: string): TBytes;
var
  LPos, LEnd, LZeroes, LWorkLen, LSize, LStart, LDigit: Integer;
  LB256: TBytes;
begin
  if AEncoded = '' then
    raise EArgumentException.Create('encoded');

  LPos := 1;
  LEnd := Length(AEncoded) + 1;

  // Skip leading whitespace
  while (LPos < LEnd) and (AEncoded[LPos] <= #32) do
    Inc(LPos);

  LZeroes := CountLeadingChars(AEncoded, LPos, LEnd, '1');
  Inc(LPos, LZeroes);

  // log(58)/log(256) ~ 0.7329; 733/1000 is a safe integer approximation
  LSize := (LEnd - LPos) * 733 div 1000 + 1;
  SetLength(LB256, LSize);

  LWorkLen := 0;
  while (LPos < LEnd) and (AEncoded[LPos] > #32) do
  begin
    LDigit := CharMap[Ord(AEncoded[LPos]) and $FF];
    if LDigit = -1 then
      raise EArgumentException.Create('Invalid base58 character');
    BigNumMultiplyAdd(LB256, LSize, 58, 256, LDigit, LWorkLen);
    Inc(LPos);
  end;

  // Skip trailing whitespace; reject if non-whitespace remains
  while (LPos < LEnd) and (AEncoded[LPos] <= #32) do
    Inc(LPos);
  if LPos < LEnd then
    raise EArgumentException.Create('Invalid base58 character');

  LStart := LSize - LWorkLen;
  Result := BuildResult(LB256, LStart, LSize - LStart, LZeroes, 0);
end;

function TDefaultBase58EncoderProvider.IsValid(const AEncoded: string): Boolean;
var
  LI: Integer;
begin
  if AEncoded = '' then
    Exit(False);
  for LI := 1 to Length(AEncoded) do
    if CharMap[Ord(AEncoded[LI]) and $FF] = -1 then
      Exit(False);
  Result := True;
end;

{ TDefaultBase64EncoderProvider }

function TDefaultBase64EncoderProvider.ValidateBase64Strict(const AStr: string): Boolean;

  function IsB64Char(ACh: Char): Boolean; inline;
  begin
    Result :=
      ((ACh >= 'A') and (ACh <= 'Z')) or
      ((ACh >= 'a') and (ACh <= 'z')) or
      ((ACh >= '0') and (ACh <= '9')) or
      (ACh = '+') or (ACh = '/');
  end;

var
  LLen, LI, LEqPos, LPadCount: Integer;
begin
  LLen := Length(AStr);
  if (LLen = 0) or ((LLen and 3) <> 0) then
    Exit(False);

  // Reject any control characters or whitespace
  for LI := 1 to LLen do
    if AStr[LI] <= #32 then
      Exit(False);

  LEqPos := Pos('=', AStr);
  if LEqPos = 0 then
  begin
    // No padding: every character must be a valid base64 char
    for LI := 1 to LLen do
      if not IsB64Char(AStr[LI]) then
        Exit(False);
  end
  else
  begin
    // Characters before padding must be valid
    for LI := 1 to LEqPos - 1 do
      if not IsB64Char(AStr[LI]) then
        Exit(False);
    // Padding must be 1 or 2 '=' chars at the end
    LPadCount := LLen - LEqPos + 1;
    if (LPadCount < 1) or (LPadCount > 2) then
      Exit(False);
    for LI := LEqPos to LLen do
      if AStr[LI] <> '=' then
        Exit(False);
  end;
  Result := True;
end;

function TDefaultBase64EncoderProvider.EncodeData(const AData: TBytes;
  AOffset, ACount: Integer): string;
var
  LEncoder: TBase64Encoding;
begin
  ValidateRange(AData, AOffset, ACount);
  LEncoder := TBase64Encoding.Create(0);
  try
    Result := LEncoder.EncodeBytesToString(@AData[AOffset], ACount);
  finally
    LEncoder.Free;
  end;
end;

function TDefaultBase64EncoderProvider.DecodeData(const AEncoded: string): TBytes;
begin
  if not ValidateBase64Strict(AEncoded) then
    raise EArgumentException.Create('Invalid Base64 data');
  Result := TNetEncoding.Base64.DecodeStringToBytes(AEncoded);
end;

function TDefaultBase64EncoderProvider.IsValid(const AEncoded: string): Boolean;
begin
  Result := ValidateBase64Strict(AEncoded);
end;

{ TDefaultHexEncoderProvider }

function TDefaultHexEncoderProvider.EncodeData(const AData: TBytes;
  AOffset, ACount: Integer): string;
begin
  ValidateRange(AData, AOffset, ACount);
  SetLength(Result, ACount * 2);
  if ACount > 0 then
    {$IFDEF FPC}StrUtils.{$ENDIF}BinToHex(@AData[AOffset], PChar(Result), ACount);
end;

function TDefaultHexEncoderProvider.DecodeData(const AEncoded: string): TBytes;
var
  LLen: Integer;
begin
  if AEncoded = '' then
    raise EArgumentException.Create('encoded');
  LLen := Length(AEncoded);
  if (LLen mod 2) <> 0 then
    raise EArgumentException.Create('Invalid hex string length (must be even)');
  SetLength(Result, LLen div 2);
  if {$IFDEF FPC}StrUtils.{$ENDIF}HexToBin(PChar(AEncoded), @Result[0], Length(Result)) <> Length(Result) then
    raise EArgumentException.Create('Invalid hex character in input');
end;

function TDefaultHexEncoderProvider.IsValid(const AEncoded: string): Boolean;
var
  LLen, LI: Integer;
begin
  LLen := Length(AEncoded);
  if (LLen = 0) or ((LLen mod 2) <> 0) then
    Exit(False);
  for LI := 1 to LLen do
    case AEncoded[LI] of
      '0'..'9', 'A'..'F', 'a'..'f': ;
    else
      Exit(False);
    end;
  Result := True;
end;

{ TDefaultSolanaKeyPairJsonEncoderProvider }

function TDefaultSolanaKeyPairJsonEncoderProvider.EncodeData(const AData: TBytes;
  AOffset, ACount: Integer): string;
var
  LI, LEnd: Integer;
  LBuilder: TStringBuilder;
begin
  ValidateRange(AData, AOffset, ACount);
  LEnd := AOffset + ACount;
  LBuilder := TStringBuilder.Create((ACount * 4) + 2); // pre-size: up to "255," per byte + brackets
  try
    LBuilder.Append('[');
    for LI := AOffset to LEnd - 1 do
    begin
      if LI > AOffset then
        LBuilder.Append(',');
      LBuilder.Append(AData[LI].ToString);
    end;
    LBuilder.Append(']');
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function TDefaultSolanaKeyPairJsonEncoderProvider.TryParse(const AEncoded: string;
  out ABytes: TBytes): Boolean;
var
  LTrimmed, LNumStr: string;
  LList: TStringList;
  LI, LVal: Integer;
begin
  ABytes := nil;
  if AEncoded = '' then
    Exit(False);

  LTrimmed := Trim(AEncoded);
  if (Length(LTrimmed) < 2) or (LTrimmed[1] <> '[')
    or (LTrimmed[Length(LTrimmed)] <> ']') then
    Exit(False);

  LTrimmed := Copy(LTrimmed, 2, Length(LTrimmed) - 2);
  LList := TStringList.Create;
  try
    LList.StrictDelimiter := True;
    LList.Delimiter := ',';
    LList.DelimitedText := LTrimmed;

    if LList.Count <> SolanaKeyPairLength then
      Exit(False);

    SetLength(ABytes, SolanaKeyPairLength);
    for LI := 0 to SolanaKeyPairLength - 1 do
    begin
      LNumStr := Trim(LList[LI]);
      if not TryStrToInt(LNumStr, LVal) then
        Exit(False);
      if (LVal < 0) or (LVal > 255) then
        Exit(False);
      ABytes[LI] := Byte(LVal);
    end;
    Result := True;
  finally
    LList.Free;
  end;
end;

function TDefaultSolanaKeyPairJsonEncoderProvider.DecodeData(const AEncoded: string): TBytes;
begin
  if not TryParse(AEncoded, Result) then
    raise EArgumentException.Create('Invalid Solana keypair JSON');
end;

function TDefaultSolanaKeyPairJsonEncoderProvider.IsValid(const AEncoded: string): Boolean;
var
  LDummy: TBytes;
begin
  Result := TryParse(AEncoded, LDummy);
end;

end.
