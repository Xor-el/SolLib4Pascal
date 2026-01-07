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
    function EncodeData(const data: TBytes): string; overload;

    /// <summary>
    /// Encode the data.
    /// </summary>
    /// <param name="data">The data to encode.</param>
    /// <param name="offset">The offset at which to start encoding.</param>
    /// <param name="count">The number of bytes to encode.</param>
    /// <returns>The encoded data.</returns>
    function EncodeData(const data: TBytes; offset, count: Integer): string; overload;

    /// <summary>
    /// Decode the data.
    /// </summary>
    /// <param name="encoded">The data to decode.</param>
    /// <returns>The decoded data.</returns>
    function DecodeData(const encoded: string): TBytes;

    /// <summary>
    /// Check if the encoded string is valid for this encoding.
    /// </summary>
    /// <param name="encoded">The encoded string to validate.</param>
    /// <returns>True if valid, false otherwise.</returns>
    function IsValid(const encoded: string): Boolean;
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
    class function IsSpace(c: Char): Boolean; static;

    /// <summary>
    /// Initialize the data encoder.
    /// </summary>
    constructor Create; virtual;

    /// <summary>
    /// Encode the data.
    /// </summary>
    /// <param name="data">The data to encode.</param>
    /// <returns>The data encoded.</returns>
    function EncodeData(const data: TBytes): string; overload;

    /// <summary>
    /// Encode the data.
    /// </summary>
    /// <param name="data">The data to encode.</param>
    /// <param name="offset">The offset at which to start encoding.</param>
    /// <param name="count">The number of bytes to encode.</param>
    /// <returns>The encoded data.</returns>
    function EncodeData(const data: TBytes; offset, count: Integer): string; overload; virtual; abstract;

    /// <summary>
    /// Decode the data.
    /// </summary>
    /// <param name="encoded">The data to decode.</param>
    /// <returns>The decoded data.</returns>
    function DecodeData(const encoded: string): TBytes; virtual; abstract;

    /// <summary>
    /// Check if the encoded string is valid for this encoding.
    /// </summary>
    /// <param name="encoded">The encoded string to validate.</param>
    /// <returns>True if valid, false otherwise.</returns>
    function IsValid(const encoded: string): Boolean; virtual; abstract;
  end;

  /// <summary>
  /// Implements a base58 encoder.
  /// </summary>
  TBase58Encoder = class sealed(TDataEncoder)
  private
    class function GetAlphaChar(Index: Integer): Char; static;
  public
    /// <summary>
    /// The base58 characters.
    /// </summary>
    const PszBase58: string = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

    /// <inheritdoc />
    function EncodeData(const data: TBytes; offset, count: Integer): string; override;

    /// <inheritdoc />
    function DecodeData(const encoded: string): TBytes; override;

    /// <inheritdoc />
    function IsValid(const encoded: string): Boolean; override;
  end;

  /// <summary>
  /// Implements a base64 encoder.
  /// </summary>
  TBase64Encoder = class sealed(TDataEncoder)
  private
    function ValidateBase64Strict(const S: string): Boolean;
  public
    /// <inheritdoc />
    function EncodeData(const data: TBytes; offset, count: Integer): string; override;

    /// <inheritdoc />
    function DecodeData(const encoded: string): TBytes; override;

    /// <inheritdoc />
    function IsValid(const encoded: string): Boolean; override;
  end;

  /// <summary>
  /// Implements a hexadecimal encoder.
  /// </summary>
  THexEncoder = class sealed(TDataEncoder)
  public
    /// <inheritdoc />
    function EncodeData(const data: TBytes; offset, count: Integer): string; override;

    /// <inheritdoc />
    function DecodeData(const encoded: string): TBytes; override;

    /// <inheritdoc />
    function IsValid(const encoded: string): Boolean; override;
  end;

  /// <summary>
  /// Implements the original solana-keygen encoder.
  /// </summary>
  TSolanaEncoder = class sealed(TDataEncoder)
  private
    /// <summary>
    /// Shared parsing logic for DecodeData and IsValid.
    /// </summary>
    function TryParse(const encoded: string; out Bytes: TBytes): Boolean;
  public
    /// <summary>
    /// Formats a byte array into a string in order to be compatible with the original solana-keygen made in rust.
    /// </summary>
    /// <param name="data">The byte array to be formatted.</param>
    /// <param name="data">The offset to start from.</param>
    /// <param name="data">The count to process.</param>
    /// <returns>A formatted string.</returns>
    function EncodeData(const data: TBytes; offset, count: Integer): string; override;

    /// <summary>
    /// Formats a string into a byte array in order to be compatible with the original solana-keygen made in rust.
    /// </summary>
    /// <param name="encoded">The string to be formatted.</param>
    /// <returns>A formatted byte array.</returns>
    function DecodeData(const encoded: string): TBytes; override;

    /// <inheritdoc />
    function IsValid(const encoded: string): Boolean; override;
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
//       function EncodeData(const data: TBytes): string; overload;
//       function EncodeData(const data: TBytes; offset, count: Integer): string; overload;
//       function DecodeData(const encoded: string): TBytes;
//       function IsValid(const encoded: string): Boolean;
//     end;
//
//   function TMyCustomBase58Encoder.EncodeData(const data: TBytes): string;
//   begin
//     Result := EncodeData(data, 0, Length(data));
//   end;
//
//   function TMyCustomBase58Encoder.EncodeData(const data: TBytes; offset, count: Integer): string;
//   begin
//     // Custom encoding logic here
//   end;
//
//   function TMyCustomBase58Encoder.DecodeData(const encoded: string): TBytes;
//   begin
//     // Custom decoding logic here
//   end;
//
//   function TMyCustomBase58Encoder.IsValid(const encoded: string): Boolean;
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

class function TDataEncoder.IsSpace(c: Char): Boolean;
begin
  case c of
    ' ', #9, #10, #11, #12, #13: Exit(True); // space, \t, \n, \v, \f, \r
  end;
  Result := False;
end;

function TDataEncoder.EncodeData(const data: TBytes): string;
begin
  Result := EncodeData(data, 0, Length(data));
end;

{ TBase58Encoder }

class function TBase58Encoder.GetAlphaChar(Index: Integer): Char;
begin
  // PszBase58 is 1-based when indexed as a Delphi string; Index is 0..57
  Result := PszBase58[Index + 1];
end;

function TBase58Encoder.EncodeData(const data: TBytes; offset, count: Integer): string;
var
  zeroes, workingLength, size: Integer;
  b58: TBytes;
  carry, i, it: Integer;
  it2, i2: Integer;
  outLen: Integer;
begin
  if data = nil then
    raise EArgumentNilException.Create('data');

  if (offset < 0) or (count < 0) or (offset > count) or (count > Length(data)) then
    raise ERangeError.Create('Invalid offset/count');

  zeroes := 0;
  while (offset <> count) and (data[offset] = 0) do
  begin
    Inc(offset);
    Inc(zeroes);
  end;

  // Allocate enough space in big-endian base58 representation.
  // log(256) / log(58), rounded up.
  size := (count - offset) * 138 div 100 + 1;
  SetLength(b58, size);

  workingLength := 0;
  while offset <> count do
  begin
    carry := data[offset];
    i := 0;

    // Apply "b58 = b58 * 256 + ch".
    for it := size - 1 downto 0 do
    begin
      if (carry <> 0) or (i < workingLength) then
      begin
        carry := carry + 256 * b58[it];
        b58[it] := Byte(carry mod 58);
        carry := carry div 58;
        Inc(i);
      end;
      if (carry = 0) and (i >= workingLength) then
        if it < (size - 1) then
          Break;
    end;

    workingLength := i;
    Inc(offset);
  end;

  // Skip leading zeroes in
  it2 := (size - workingLength);
  while (it2 <> size) and (b58[it2] = 0) do
    Inc(it2);

  outLen := zeroes + size - it2;
  SetLength(Result, outLen);

  // Fill leading zeroes with '1'
  for i2 := 1 to zeroes do
    Result[i2] := '1';

  // Remaining characters
  i2 := zeroes + 1;
  while it2 <> size do
  begin
    Result[i2] := GetAlphaChar(b58[it2]);
    Inc(i2);
    Inc(it2);
  end;
end;

function TBase58Encoder.DecodeData(const encoded: string): TBytes;
var
  psz, zeroes, length, size: Integer;
  b256: TBytes;
  carry, i, it: Integer;
  it2, i2: Integer;
  ch: Char;
begin
  if encoded = '' then
    raise EArgumentException.Create('encoded');

  psz := 1;
  while (psz <= encoded.Length) and TDataEncoder.IsSpace(encoded[psz]) do
    Inc(psz);

  zeroes := 0;
  length := 0;
  while (psz <= encoded.Length) and (encoded[psz] = '1') do
  begin
    Inc(zeroes);
    Inc(psz);
  end;

  // Allocate enough space in big-endian base256 representation.
  // log(58) / log(256), rounded up.
  size := (encoded.Length - (psz - 1)) * 733 div 1000 + 1;
  SetLength(b256, size);

  // Process the characters.
  while (psz <= encoded.Length) and (not TDataEncoder.IsSpace(encoded[psz])) do
  begin
    ch := encoded[psz];
    carry := MapBase58[Ord(ch) and $FF]; // invalid -> -1
    if carry = -1 then
      raise Exception.Create('Invalid base58 data');

    i := 0;
    for it := size - 1 downto 0 do
    begin
      if (carry <> 0) or (i < length) then
      begin
        carry := carry + 58 * b256[it];
        b256[it] := Byte(carry mod 256);
        carry := carry div 256;
        Inc(i);
      end;
      if (carry = 0) and (i >= length) then
        if it < (size - 1) then
          Break;
    end;

    length := i;
    Inc(psz);
  end;

  // Skip trailing spaces.
  while (psz <= encoded.Length) and TDataEncoder.IsSpace(encoded[psz]) do
    Inc(psz);
  if psz <= encoded.Length then
    raise Exception.Create('Invalid base58 data');

  // Skip leading zeroes in b256.
  it2 := size - length;

  // Copy result into output vector.
  SetLength(Result, zeroes + size - it2);

  // Fill leading zero bytes with 0x00
  for i2 := 0 to zeroes - 1 do
    Result[i2] := 0;

  // Copy the rest
  i2 := zeroes;
  while it2 <> size do
  begin
    Result[i2] := b256[it2];
    Inc(i2);
    Inc(it2);
  end;
end;

function TBase58Encoder.IsValid(const encoded: string): Boolean;
var
  i: Integer;
  c: Char;
begin
  if encoded = '' then
    Exit(False);
  for i := 1 to encoded.Length do
  begin
    c := encoded[i];

    // reject whitespace and any char not in Base58 map
    if TDataEncoder.IsSpace(c) or (MapBase58[Ord(c) and $FF] = -1) then
      Exit(False);
  end;
  Result := True;
end;

{ TBase64Encoder }

function TBase64Encoder.ValidateBase64Strict(const S: string): Boolean;

function IsB64Char(const Ch: Char): Boolean; inline;
begin
  Result :=
    ((Ch >= 'A') and (Ch <= 'Z')) or
    ((Ch >= 'a') and (Ch <= 'z')) or
    ((Ch >= '0') and (Ch <= '9')) or
    (Ch = '+') or (Ch = '/');
end;

var
  L, I, EqPos, PadCount: Integer;
begin
  L := Length(S);
  if L = 0 then
    Exit(False);

  // no whitespace or control chars
  for I := 1 to L do
    if S[I] <= #32 then
      Exit(False);

  // total length must be a multiple of 4 (including padding)
  if (L and 3) <> 0 then
    Exit(False);

  // locate first '=' (padding), if any
  EqPos := Pos('=', S);
  if EqPos = 0 then
  begin
    // no padding at all: every char must be a Base64 alphabet char
    for I := 1 to L do
      if not IsB64Char(S[I]) then
        Exit(False);
  end
  else
  begin
    // ensure all chars before '=' are valid Base64
    for I := 1 to EqPos - 1 do
      if not IsB64Char(S[I]) then
        Exit(False);

    // only '=' allowed from first '=' to the end; length of padding must be 1 or 2
    PadCount := L - EqPos + 1;
    if (PadCount <> 1) and (PadCount <> 2) then
      Exit(False);

    for I := EqPos to L do
      if S[I] <> '=' then
        Exit(False);
  end;
  Result := True;
end;

function TBase64Encoder.DecodeData(const encoded: string): TBytes;
begin
  if not ValidateBase64Strict(encoded) then
    raise Exception.Create('Invalid Base64 data');
  Result := TNetEncoding.Base64.DecodeStringToBytes(encoded);
end;

function TBase64Encoder.IsValid(const encoded: string): Boolean;
begin
  Result := ValidateBase64Strict(encoded);
end;

function TBase64Encoder.EncodeData(const data: TBytes; offset, count: Integer): string;
var
  Encoder: TBase64Encoding;
begin
  Encoder := TBase64Encoding.Create(0); // 0 = No line breaks every 76 characters
  try
    Result := Encoder.EncodeBytesToString(@data[offset], count);
  finally
    Encoder.Free;
  end;
end;

{ THexEncoder }

function THexEncoder.EncodeData(const data: TBytes; offset, count: Integer): string;
const
  HexChars: array[0..15] of Char = ('0','1','2','3','4','5','6','7',
                                    '8','9','A','B','C','D','E','F');
var
  i, j: Integer;
  b: Byte;
begin
  if data = nil then
    raise EArgumentNilException.Create('data');

  if (offset < 0) or (count < 0) or (offset > count) or (count > Length(data)) then
    raise ERangeError.Create('Invalid offset/count');

  SetLength(Result, count * 2);
  j := 1;
  for i := offset to count - 1 do
  begin
    b := data[i];
    Result[j] := HexChars[b shr 4];
    Result[j + 1] := HexChars[b and $0F];
    Inc(j, 2);
  end;
end;

function THexEncoder.DecodeData(const encoded: string): TBytes;
var
  len, i, j: Integer;
  function HexCharToValue(C: Char): Integer;
  begin
    case C of
      '0'..'9': Result := Ord(C) - Ord('0');
      'A'..'F': Result := Ord(C) - Ord('A') + 10;
      'a'..'f': Result := Ord(C) - Ord('a') + 10;
    else
      raise Exception.CreateFmt('Invalid hex character "%s"', [C]);
    end;
  end;
begin
  if encoded = '' then
    raise EArgumentException.Create('encoded');

  len := encoded.Length;
  if (len mod 2) <> 0 then
    raise Exception.Create('Invalid hex string length (must be even)');

  SetLength(Result, len div 2);
  j := 0;
  i := 1;
  while i <= len do
  begin
    Result[j] := (HexCharToValue(encoded[i]) shl 4)
               or  HexCharToValue(encoded[i + 1]);
    Inc(j);
    Inc(i, 2);
  end;
end;

function THexEncoder.IsValid(const encoded: string): Boolean;
var
  len, i: Integer;
  c: Char;
begin
  len := Length(encoded);
  if (len = 0) or ((len mod 2) <> 0) then
    Exit(False);

  for i := 1 to len do
  begin
    c := encoded[i];
    case c of
      '0'..'9', 'A'..'F', 'a'..'f': ; // valid
    else
      Exit(False);
    end;
  end;
  Result := True;
end;

{ TSolanaEncoder }

function TSolanaEncoder.EncodeData(const data: TBytes; offset, count: Integer): string;
var
  i: Integer;
  parts: TStringBuilder;
begin
  if data = nil then
    raise EArgumentNilException.Create('data');

  if (offset < 0) or (count < 0) or (offset + count > Length(data)) then
    raise ERangeError.Create('Invalid offset/count');

  parts := TStringBuilder.Create;
  try
    parts.Append('[');
    for i := offset to offset + count - 1 do
    begin
      parts.Append(data[i].ToString);
      if i < offset + count - 1 then
        parts.Append(',');
    end;
    parts.Append(']');
    Result := parts.ToString;
  finally
    parts.Free;
  end;
end;

function TSolanaEncoder.TryParse(const encoded: string; out Bytes: TBytes): Boolean;
var
  cleanStr, numStr: string;
  list: TStringList;
  i, val: Integer;
begin
  SetLength(Bytes, 0);

  if encoded = '' then
    Exit(False);

  cleanStr := Trim(encoded);
  if (Length(cleanStr) < 2) or (cleanStr[1] <> '[') or (cleanStr[High(cleanStr)] <> ']') then
    Exit(False);

  cleanStr := Copy(cleanStr, 2, Length(cleanStr) - 2); // remove [ and ]

  list := TStringList.Create;
  try
    list.StrictDelimiter := True;
    list.Delimiter := ',';
    list.DelimitedText := cleanStr;

    if list.Count <> 64 then
      Exit(False);

    SetLength(Bytes, list.Count);
    for i := 0 to list.Count - 1 do
    begin
      numStr := Trim(list[i]);
      if not TryStrToInt(numStr, val) then
        Exit(False);
      if (val < 0) or (val > 255) then
        Exit(False);
      Bytes[i] := Byte(val);
    end;
    Result := True;
  finally
    list.Free;
  end;
end;

function TSolanaEncoder.DecodeData(const encoded: string): TBytes;
begin
  if not TryParse(encoded, Result) then
    raise EArgumentException.Create('Invalid Solana encoded string');
end;

function TSolanaEncoder.IsValid(const encoded: string): Boolean;
var
  Bytes: TBytes;
begin
  Result := TryParse(encoded, Bytes);
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

