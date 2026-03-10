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

unit SlpDataEncoders;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.NetEncoding,
  System.Classes;

type
  /// <summary>
  /// Interface for data encoding operations.
  /// </summary>
  IDataEncoder = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    /// <summary>
    /// Encode the data.
    /// </summary>
    /// <param name="data">The data to encode.</param>
    /// <returns>The data encoded.</returns>
    function EncodeData(const AData: TBytes): string; overload;

    /// <summary>
    /// Encode the data.
    /// </summary>
    /// <param name="data">The data to encode.</param>
    /// <param name="offset">The offset at which to start encoding.</param>
    /// <param name="count">The number of bytes to encode.</param>
    /// <returns>The encoded data.</returns>
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string; overload;

    /// <summary>
    /// Decode the data.
    /// </summary>
    /// <param name="encoded">The data to decode.</param>
    /// <returns>The decoded data.</returns>
    function DecodeData(const AEncoded: string): TBytes;

    /// <summary>
    /// Check if the encoded string is valid for this encoding.
    /// </summary>
    /// <param name="encoded">The encoded string to validate.</param>
    /// <returns>True if valid, false otherwise.</returns>
    function IsValid(const AEncoded: string): Boolean;
  end;

  /// <summary>
  /// Abstract data encoder class.
  /// </summary>
  TDataEncoder = class abstract(TInterfacedObject, IDataEncoder)
  public
    /// <summary>
    /// Check if the character is a space...
    /// </summary>
    /// <param name="c">The character.</param>
    /// <returns>True if it is, otherwise false.</returns>
    class function IsSpace(ACh: Char): Boolean; static;

    /// <summary>
    /// Initialize the data encoder.
    /// </summary>
    constructor Create; virtual;

    /// <summary>
    /// Encode the data.
    /// </summary>
    /// <param name="data">The data to encode.</param>
    /// <returns>The data encoded.</returns>
    function EncodeData(const AData: TBytes): string; overload;

    /// <summary>
    /// Encode the data.
    /// </summary>
    /// <param name="data">The data to encode.</param>
    /// <param name="offset">The offset at which to start encoding.</param>
    /// <param name="count">The number of bytes to encode.</param>
    /// <returns>The encoded data.</returns>
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string; overload; virtual; abstract;

    /// <summary>
    /// Decode the data.
    /// </summary>
    /// <param name="encoded">The data to decode.</param>
    /// <returns>The decoded data.</returns>
    function DecodeData(const AEncoded: string): TBytes; virtual; abstract;

    /// <summary>
    /// Check if the encoded string is valid for this encoding.
    /// </summary>
    /// <param name="encoded">The encoded string to validate.</param>
    /// <returns>True if valid, false otherwise.</returns>
    function IsValid(const AEncoded: string): Boolean; virtual; abstract;
  end;

  /// <summary>
  /// Implements a base58 encoder.
  /// </summary>
  TBase58Encoder = class sealed(TDataEncoder)
  private
    class function GetAlphaChar(AIndex: Integer): Char; static;
  public
    /// <summary>
    /// The base58 characters.
    /// </summary>
    const PszBase58: string = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

    /// <inheritdoc />
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string; override;

    /// <inheritdoc />
    function DecodeData(const AEncoded: string): TBytes; override;

    /// <inheritdoc />
    function IsValid(const AEncoded: string): Boolean; override;
  end;

  /// <summary>
  /// Implements a base64 encoder.
  /// </summary>
  TBase64Encoder = class sealed(TDataEncoder)
  private
    function ValidateBase64Strict(const AStr: string): Boolean;
  public
    /// <inheritdoc />
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string; override;

    /// <inheritdoc />
    function DecodeData(const AEncoded: string): TBytes; override;

    /// <inheritdoc />
    function IsValid(const AEncoded: string): Boolean; override;
  end;

  /// <summary>
  /// Implements a hexadecimal encoder.
  /// </summary>
  THexEncoder = class sealed(TDataEncoder)
  public
    /// <inheritdoc />
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string; override;

    /// <inheritdoc />
    function DecodeData(const AEncoded: string): TBytes; override;

    /// <inheritdoc />
    function IsValid(const AEncoded: string): Boolean; override;
  end;

  /// <summary>
  /// Implements the original solana-keygen encoder.
  /// </summary>
  TSolanaEncoder = class sealed(TDataEncoder)
  private
    /// <summary>
    /// Shared parsing logic for DecodeData and IsValid.
    /// </summary>
    function TryParse(const AEncoded: string; out ABytes: TBytes): Boolean;
  public
    /// <summary>
    /// Formats a byte array into a string in order to be compatible with the original solana-keygen made in rust.
    /// </summary>
    /// <param name="data">The byte array to be formatted.</param>
    /// <param name="data">The offset to start from.</param>
    /// <param name="data">The count to process.</param>
    /// <returns>A formatted string.</returns>
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string; override;

    /// <summary>
    /// Formats a string into a byte array in order to be compatible with the original solana-keygen made in rust.
    /// </summary>
    /// <param name="encoded">The string to be formatted.</param>
    /// <returns>A formatted byte array.</returns>
    function DecodeData(const AEncoded: string): TBytes; override;

    /// <inheritdoc />
    function IsValid(const AEncoded: string): Boolean; override;
  end;

  /// <summary>
  /// A static encoder instance.
  /// </summary>
  TEncoders = class sealed
  strict private
    class var FBase58: IDataEncoder;
    class var FBase64: IDataEncoder;
    class var FHex: IDataEncoder;
    class var FSolana: IDataEncoder;
  public
    /// <summary>
    /// The encoders. Can be replaced with custom implementations.
    /// </summary>
    class property Base58: IDataEncoder read FBase58 write FBase58;
    class property Base64: IDataEncoder read FBase64 write FBase64;
    class property Hex: IDataEncoder read FHex write FHex;
    class property Solana: IDataEncoder read FSolana write FSolana;

    class constructor Create;
  end;

// =============================================================================
// Example: Providing a custom encoder implementation
// =============================================================================
//
// To use a custom encoder, create a class implementing IDataEncoder and assign
// it to the appropriate TEncoders property:
//
//   type
//     TMyCustomBase58Encoder = class(TInterfacedObject, IDataEncoder)
//     public
//       function EncodeData(const AData: TBytes): string; overload;
//       function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string; overload;
//       function DecodeData(const AEncoded: string): TBytes;
//       function IsValid(const AEncoded: string): Boolean;
//     end;
//
//   function TMyCustomBase58Encoder.EncodeData(const AData: TBytes): string;
//   begin
//     Result := EncodeData(data, 0, Length(data));
//   end;
//
//   function TMyCustomBase58Encoder.EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
//   begin
//     // Custom encoding logic here
//   end;
//
//   function TMyCustomBase58Encoder.DecodeData(const AEncoded: string): TBytes;
//   begin
//     // Custom decoding logic here
//   end;
//
//   function TMyCustomBase58Encoder.IsValid(const AEncoded: string): Boolean;
//   begin
//     // Custom validation logic here
//   end;
//
//   // At application startup:
//   TEncoders.Base58 := TMyCustomBase58Encoder.Create;
//
// =============================================================================

implementation

// Decoding map (ASCII -> Base58 index or -1 if invalid)

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

{ TDataEncoder }

constructor TDataEncoder.Create;
begin
  inherited Create;
end;

class function TDataEncoder.IsSpace(ACh: Char): Boolean;
begin
  case ACh of
    ' ', #9, #10, #11, #12, #13: Exit(True); // space, \t, \n, \v, \f, \r
  end;
  Result := False;
end;

function TDataEncoder.EncodeData(const AData: TBytes): string;
begin
  Result := EncodeData(AData, 0, Length(AData));
end;

{ TBase58Encoder }

class function TBase58Encoder.GetAlphaChar(AIndex: Integer): Char;
begin
  // PszBase58 is 1-based when indexed as a Delphi string; AIndex is 0..57
  Result := PszBase58[AIndex + 1];
end;

function TBase58Encoder.EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
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

  // Allocate enough space in big-endian base58 representation.
  // log(256) / log(58), rounded up.
  LSize := (ACount - AOffset) * 138 div 100 + 1;
  SetLength(LB58, LSize);

  LWorkingLength := 0;
  while AOffset <> ACount do
  begin
    LCarry := AData[AOffset];
    LI := 0;

    // Apply "b58 = b58 * 256 + ch".
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

  // Skip leading zeroes in
  LIt2 := (LSize - LWorkingLength);
  while (LIt2 <> LSize) and (LB58[LIt2] = 0) do
    Inc(LIt2);

  LOutLen := LZeroes + LSize - LIt2;
  SetLength(Result, LOutLen);

  // Fill leading zeroes with '1'
  for LI2 := 1 to LZeroes do
    Result[LI2] := '1';

  // Remaining characters
  LI2 := LZeroes + 1;
  while LIt2 <> LSize do
  begin
    Result[LI2] := GetAlphaChar(LB58[LIt2]);
    Inc(LI2);
    Inc(LIt2);
  end;
end;

function TBase58Encoder.DecodeData(const AEncoded: string): TBytes;
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
  while (LPsz <= AEncoded.Length) and TDataEncoder.IsSpace(AEncoded[LPsz]) do
    Inc(LPsz);

  LZeroes := 0;
  LLength := 0;
  while (LPsz <= AEncoded.Length) and (AEncoded[LPsz] = '1') do
  begin
    Inc(LZeroes);
    Inc(LPsz);
  end;

  // Allocate enough space in big-endian base256 representation.
  // log(58) / log(256), rounded up.
  LSize := (AEncoded.Length - (LPsz - 1)) * 733 div 1000 + 1;
  SetLength(LB256, LSize);

  // Process the characters.
  while (LPsz <= AEncoded.Length) and (not TDataEncoder.IsSpace(AEncoded[LPsz])) do
  begin
    LCh := AEncoded[LPsz];
    LCarry := MapBase58[Ord(LCh) and $FF]; // invalid -> -1
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

  // Skip trailing spaces.
  while (LPsz <= AEncoded.Length) and TDataEncoder.IsSpace(AEncoded[LPsz]) do
    Inc(LPsz);
  if LPsz <= AEncoded.Length then
    raise Exception.Create('Invalid base58 data');

  // Skip leading zeroes in b256.
  LIt2 := LSize - LLength;

  // Copy result into output vector.
  SetLength(Result, LZeroes + LSize - LIt2);

  // Fill leading zero bytes with 0x00
  for LI2 := 0 to LZeroes - 1 do
    Result[LI2] := 0;

  // Copy the rest
  LI2 := LZeroes;
  while LIt2 <> LSize do
  begin
    Result[LI2] := LB256[LIt2];
    Inc(LI2);
    Inc(LIt2);
  end;
end;

function TBase58Encoder.IsValid(const AEncoded: string): Boolean;
var
  LI: Integer;
  LC: Char;
begin
  if AEncoded = '' then
    Exit(False);
  for LI := 1 to AEncoded.Length do
  begin
    LC := AEncoded[LI];

    // reject whitespace and any char not in Base58 map
    if TDataEncoder.IsSpace(LC) or (MapBase58[Ord(LC) and $FF] = -1) then
      Exit(False);
  end;
  Result := True;
end;

{ TBase64Encoder }

function TBase64Encoder.ValidateBase64Strict(const AStr: string): Boolean;

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

  // no whitespace or control chars
  for LI := 1 to LLen do
    if AStr[LI] <= #32 then
      Exit(False);

  // total length must be a multiple of 4 (including padding)
  if (LLen and 3) <> 0 then
    Exit(False);

  // locate first '=' (padding), if any
  LEqPos := Pos('=', AStr);
  if LEqPos = 0 then
  begin
    // no padding at all: every char must be a Base64 alphabet char
    for LI := 1 to LLen do
      if not IsB64Char(AStr[LI]) then
        Exit(False);
  end
  else
  begin
    // ensure all chars before '=' are valid Base64
    for LI := 1 to LEqPos - 1 do
      if not IsB64Char(AStr[LI]) then
        Exit(False);

    // only '=' allowed from first '=' to the end; length of padding must be 1 or 2
    LPadCount := LLen - LEqPos + 1;
    if (LPadCount <> 1) and (LPadCount <> 2) then
      Exit(False);

    for LI := LEqPos to LLen do
      if AStr[LI] <> '=' then
        Exit(False);
  end;
  Result := True;
end;

function TBase64Encoder.DecodeData(const AEncoded: string): TBytes;
begin
  if not ValidateBase64Strict(AEncoded) then
    raise Exception.Create('Invalid Base64 data');
  Result := TNetEncoding.Base64.DecodeStringToBytes(AEncoded);
end;

function TBase64Encoder.IsValid(const AEncoded: string): Boolean;
begin
  Result := ValidateBase64Strict(AEncoded);
end;

function TBase64Encoder.EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
var
  LEncoder: TBase64Encoding;
begin
  LEncoder := TBase64Encoding.Create(0); // 0 = No line breaks every 76 characters
  try
    Result := LEncoder.EncodeBytesToString(@AData[AOffset], ACount);
  finally
    LEncoder.Free;
  end;
end;

{ THexEncoder }

function THexEncoder.EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
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

function THexEncoder.DecodeData(const AEncoded: string): TBytes;
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

function THexEncoder.IsValid(const AEncoded: string): Boolean;
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
      '0'..'9', 'A'..'F', 'a'..'f': ; // valid
    else
      Exit(False);
    end;
  end;
  Result := True;
end;

{ TSolanaEncoder }

function TSolanaEncoder.EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
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

function TSolanaEncoder.TryParse(const AEncoded: string; out ABytes: TBytes): Boolean;
var
  LCleanStr, LNumStr: string;
  LList: TStringList;
  LI, LVal: Integer;
begin
  SetLength(ABytes, 0);

  if AEncoded = '' then
    Exit(False);

  LCleanStr := Trim(AEncoded);
  if (Length(LCleanStr) < 2) or (LCleanStr[1] <> '[') or (LCleanStr[High(LCleanStr)] <> ']') then
    Exit(False);

  LCleanStr := Copy(LCleanStr, 2, Length(LCleanStr) - 2); // remove [ and ]

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

function TSolanaEncoder.DecodeData(const AEncoded: string): TBytes;
begin
  if not TryParse(AEncoded, Result) then
    raise EArgumentException.Create('Invalid Solana encoded string');
end;

function TSolanaEncoder.IsValid(const AEncoded: string): Boolean;
var
  LBytes: TBytes;
begin
  Result := TryParse(AEncoded, LBytes);
end;

{ TEncoders }

class constructor TEncoders.Create;
begin
  FBase58 := TBase58Encoder.Create;
  FBase64 := TBase64Encoder.Create;
  FHex := THexEncoder.Create;
  FSolana := TSolanaEncoder.Create;
end;

end.

