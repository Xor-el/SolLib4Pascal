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
  System.Character,
  System.SysUtils,
  System.NetEncoding,
  System.Classes,
  SlpDataEncoderProviders;

type
  /// <summary>
  /// Default Base58 encoder provider implementation.
  /// </summary>
  TDefaultBase58EncoderProvider = class(TInterfacedObject, IDataEncoderProvider)
  private
    class function GetAlphaChar(AIndex: Integer): Char; static;
  public
    const PszBase58: string = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
    function DecodeData(const AEncoded: string): TBytes;
    function IsValid(const AEncoded: string): Boolean;
  end;

  /// <summary>
  /// Default Base64 encoder provider implementation.
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
  /// </summary>
  TDefaultHexEncoderProvider = class(TInterfacedObject, IDataEncoderProvider)
  public
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
    function DecodeData(const AEncoded: string): TBytes;
    function IsValid(const AEncoded: string): Boolean;
  end;

  /// <summary>
  /// Default Solana (array-style) encoder provider implementation.
  /// </summary>
  TDefaultSolanaCliKeyPairEncoderProvider = class(TInterfacedObject, IDataEncoderProvider)
  private
    function TryParse(const AEncoded: string; out ABytes: TBytes): Boolean;
  public
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
    function DecodeData(const AEncoded: string): TBytes;
    function IsValid(const AEncoded: string): Boolean;
  end;

implementation

const
  MapBase58: array[0..255] of Integer = (
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

{ TDefaultBase58EncoderProvider }

class function TDefaultBase58EncoderProvider.GetAlphaChar(AIndex: Integer): Char;
begin
  Result := PszBase58[AIndex + 1];
end;

function TDefaultBase58EncoderProvider.EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
var
  LZeroes, LWorkingLength, LSize: Integer;
  LB58: TBytes;
  LCarry, LI, LIt: Integer;
  LIt2, LI2: Integer;
  LOutLen: Integer;
begin
  if AData = nil then
    raise EArgumentNilException.Create('data');

  if (AOffset < 0) or (ACount < 0) or (AOffset > ACount) or (ACount > Length(AData)) then
    raise ERangeError.Create('Invalid offset/count');

  LZeroes := 0;
  while (AOffset <> ACount) and (AData[AOffset] = 0) do
  begin
    Inc(AOffset);
    Inc(LZeroes);
  end;

  LSize := (ACount - AOffset) * 138 div 100 + 1;
  SetLength(LB58, LSize);

  LWorkingLength := 0;
  while AOffset <> ACount do
  begin
    LCarry := AData[AOffset];
    LI := 0;

    for LIt := LSize - 1 downto 0 do
    begin
      if (LCarry <> 0) or (LI < LWorkingLength) then
      begin
        LCarry := LCarry + 256 * LB58[LIt];
        LB58[LIt] := Byte(LCarry mod 58);
        LCarry := LCarry div 58;
        Inc(LI);
      end;
      if (LCarry = 0) and (LI >= LWorkingLength) then
        if LIt < (LSize - 1) then
          Break;
    end;

    LWorkingLength := LI;
    Inc(AOffset);
  end;

  LIt2 := (LSize - LWorkingLength);
  while (LIt2 <> LSize) and (LB58[LIt2] = 0) do
    Inc(LIt2);

  LOutLen := LZeroes + LSize - LIt2;
  SetLength(Result, LOutLen);

  for LI2 := 1 to LZeroes do
    Result[LI2] := '1';

  LI2 := LZeroes + 1;
  while LIt2 <> LSize do
  begin
    Result[LI2] := GetAlphaChar(LB58[LIt2]);
    Inc(LI2);
    Inc(LIt2);
  end;
end;

function TDefaultBase58EncoderProvider.DecodeData(const AEncoded: string): TBytes;
var
  LPsz, LZeroes, LLength, LSize: Integer;
  LB256: TBytes;
  LCarry, LI, LIt: Integer;
  LIt2, LI2: Integer;
  LCh: Char;
begin
  if AEncoded = '' then
    raise EArgumentException.Create('encoded');

  LPsz := 1;
  while (LPsz <= AEncoded.Length) and AEncoded[LPsz].IsWhiteSpace() do
    Inc(LPsz);

  LZeroes := 0;
  LLength := 0;
  while (LPsz <= AEncoded.Length) and (AEncoded[LPsz] = '1') do
  begin
    Inc(LZeroes);
    Inc(LPsz);
  end;

  LSize := (AEncoded.Length - (LPsz - 1)) * 733 div 1000 + 1;
  SetLength(LB256, LSize);

  while (LPsz <= AEncoded.Length) and (not AEncoded[LPsz].IsWhiteSpace()) do
  begin
    LCh := AEncoded[LPsz];
    LCarry := MapBase58[Ord(LCh) and $FF];
    if LCarry = -1 then
      raise Exception.Create('Invalid base58 data');

    LI := 0;
    for LIt := LSize - 1 downto 0 do
    begin
      if (LCarry <> 0) or (LI < LLength) then
      begin
        LCarry := LCarry + 58 * LB256[LIt];
        LB256[LIt] := Byte(LCarry mod 256);
        LCarry := LCarry div 256;
        Inc(LI);
      end;
      if (LCarry = 0) and (LI >= LLength) then
        if LIt < (LSize - 1) then
          Break;
    end;

    LLength := LI;
    Inc(LPsz);
  end;

  while (LPsz <= AEncoded.Length) and AEncoded[LPsz].IsWhiteSpace() do
    Inc(LPsz);
  if LPsz <= AEncoded.Length then
    raise Exception.Create('Invalid base58 data');

  LIt2 := LSize - LLength;

  SetLength(Result, LZeroes + LSize - LIt2);

  for LI2 := 0 to LZeroes - 1 do
    Result[LI2] := 0;

  LI2 := LZeroes;
  while LIt2 <> LSize do
  begin
    Result[LI2] := LB256[LIt2];
    Inc(LI2);
    Inc(LIt2);
  end;
end;

function TDefaultBase58EncoderProvider.IsValid(const AEncoded: string): Boolean;
var
  LI: Integer;
  LC: Char;
begin
  if AEncoded = '' then
    Exit(False);
  for LI := 1 to AEncoded.Length do
  begin
    LC := AEncoded[LI];
    if LC.IsWhiteSpace() or (MapBase58[Ord(LC) and $FF] = -1) then
      Exit(False);
  end;
  Result := True;
end;

{ TDefaultBase64EncoderProvider }

function TDefaultBase64EncoderProvider.ValidateBase64Strict(const AStr: string): Boolean;

  function IsB64Char(const ACh: Char): Boolean; inline;
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
  if LLen = 0 then
    Exit(False);

  for LI := 1 to LLen do
    if AStr[LI] <= #32 then
      Exit(False);

  if (LLen and 3) <> 0 then
    Exit(False);

  LEqPos := Pos('=', AStr);
  if LEqPos = 0 then
  begin
    for LI := 1 to LLen do
      if not IsB64Char(AStr[LI]) then
        Exit(False);
  end
  else
  begin
    for LI := 1 to LEqPos - 1 do
      if not IsB64Char(AStr[LI]) then
        Exit(False);

    LPadCount := LLen - LEqPos + 1;
    if (LPadCount <> 1) and (LPadCount <> 2) then
      Exit(False);

    for LI := LEqPos to LLen do
      if AStr[LI] <> '=' then
        Exit(False);
  end;
  Result := True;
end;

function TDefaultBase64EncoderProvider.DecodeData(const AEncoded: string): TBytes;
begin
  if not ValidateBase64Strict(AEncoded) then
    raise Exception.Create('Invalid Base64 data');
  Result := TNetEncoding.Base64.DecodeStringToBytes(AEncoded);
end;

function TDefaultBase64EncoderProvider.IsValid(const AEncoded: string): Boolean;
begin
  Result := ValidateBase64Strict(AEncoded);
end;

function TDefaultBase64EncoderProvider.EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
var
  LEncoder: TBase64Encoding;
begin
  LEncoder := TBase64Encoding.Create(0);
  try
    Result := LEncoder.EncodeBytesToString(@AData[AOffset], ACount);
  finally
    LEncoder.Free;
  end;
end;

{ TDefaultHexEncoderProvider }

function TDefaultHexEncoderProvider.EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
const
  HexChars: array[0..15] of Char = ('0','1','2','3','4','5','6','7',
                                    '8','9','A','B','C','D','E','F');
var
  LI, LJ: Integer;
  LB: Byte;
begin
  if AData = nil then
    raise EArgumentNilException.Create('data');

  if (AOffset < 0) or (ACount < 0) or (AOffset > ACount) or (ACount > Length(AData)) then
    raise ERangeError.Create('Invalid offset/count');

  SetLength(Result, ACount * 2);
  LJ := 1;
  for LI := AOffset to ACount - 1 do
  begin
    LB := AData[LI];
    Result[LJ] := HexChars[LB shr 4];
    Result[LJ + 1] := HexChars[LB and $0F];
    Inc(LJ, 2);
  end;
end;

function TDefaultHexEncoderProvider.DecodeData(const AEncoded: string): TBytes;
var
  LLen, LI, LJ: Integer;

  function HexCharToValue(AChar: Char): Integer;
  begin
    case AChar of
      '0'..'9': Result := Ord(AChar) - Ord('0');
      'A'..'F': Result := Ord(AChar) - Ord('A') + 10;
      'a'..'f': Result := Ord(AChar) - Ord('a') + 10;
    else
      raise Exception.CreateFmt('Invalid hex character "%s"', [AChar]);
    end;
  end;
begin
  if AEncoded = '' then
    raise EArgumentException.Create('encoded');

  LLen := AEncoded.Length;
  if (LLen mod 2) <> 0 then
    raise Exception.Create('Invalid hex string length (must be even)');

  SetLength(Result, LLen div 2);
  LJ := 0;
  LI := 1;
  while LI <= LLen do
  begin
    Result[LJ] := (HexCharToValue(AEncoded[LI]) shl 4)
               or  HexCharToValue(AEncoded[LI + 1]);
    Inc(LJ);
    Inc(LI, 2);
  end;
end;

function TDefaultHexEncoderProvider.IsValid(const AEncoded: string): Boolean;
var
  LLen, LI: Integer;
  LC: Char;
begin
  LLen := Length(AEncoded);
  if (LLen = 0) or ((LLen mod 2) <> 0) then
    Exit(False);

  for LI := 1 to LLen do
  begin
    LC := AEncoded[LI];
    case LC of
      '0'..'9', 'A'..'F', 'a'..'f': ;
    else
      Exit(False);
    end;
  end;
  Result := True;
end;

{ TDefaultSolanaCliKeyPairEncoderProvider }

function TDefaultSolanaCliKeyPairEncoderProvider.EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
var
  LI: Integer;
  LParts: TStringBuilder;
begin
  if AData = nil then
    raise EArgumentNilException.Create('data');

  if (AOffset < 0) or (ACount < 0) or (AOffset + ACount > Length(AData)) then
    raise ERangeError.Create('Invalid offset/count');

  LParts := TStringBuilder.Create;
  try
    LParts.Append('[');
    for LI := AOffset to AOffset + ACount - 1 do
    begin
      LParts.Append(AData[LI].ToString);
      if LI < AOffset + ACount - 1 then
        LParts.Append(',');
    end;
    LParts.Append(']');
    Result := LParts.ToString;
  finally
    LParts.Free;
  end;
end;

function TDefaultSolanaCliKeyPairEncoderProvider.TryParse(const AEncoded: string; out ABytes: TBytes): Boolean;
var
  LCleanStr, LNumStr: string;
  LList: TStringList;
  LI, LVal: Integer;
begin
  ABytes := nil;

  if AEncoded = '' then
    Exit(False);

  LCleanStr := Trim(AEncoded);
  if (Length(LCleanStr) < 2) or (LCleanStr[1] <> '[') or (LCleanStr[High(LCleanStr)] <> ']') then
    Exit(False);

  LCleanStr := Copy(LCleanStr, 2, Length(LCleanStr) - 2);

  LList := TStringList.Create;
  try
    LList.StrictDelimiter := True;
    LList.Delimiter := ',';
    LList.DelimitedText := LCleanStr;

    if LList.Count <> 64 then
      Exit(False);

    SetLength(ABytes, LList.Count);
    for LI := 0 to LList.Count - 1 do
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

function TDefaultSolanaCliKeyPairEncoderProvider.DecodeData(const AEncoded: string): TBytes;
begin
  if not TryParse(AEncoded, Result) then
    raise EArgumentException.Create('Invalid Solana encoded string');
end;

function TDefaultSolanaCliKeyPairEncoderProvider.IsValid(const AEncoded: string): Boolean;
var
  LBytes: TBytes;
begin
  Result := TryParse(AEncoded, LBytes);
end;

end.
