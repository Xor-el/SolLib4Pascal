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
  System.SysUtils,
  System.Classes,
  SbpBase16,
  SbpBase16Alphabet,
  SbpBase58,
  SbpBase58Alphabet,
  SbpBase64,
  SbpBase64Alphabet,
  SbpSimpleBaseLibTypes,
  SlpSolLibTypes,
  SlpDataEncoderProviders;

type
  /// <summary>
  /// Default Base58 encoder provider implementation.
  /// Uses the Bitcoin alphabet: 123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
  /// </summary>
  TDefaultBase58EncoderProvider = class(TInterfacedObject, IDataEncoderProvider)
  public
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
    function DecodeData(const AEncoded: string): TBytes;
    function IsValidCharset(const AEncoded: string): Boolean;
  end;

  /// <summary>
  /// Default Base64 encoder provider implementation.
  /// Enforces strict validation: no whitespace, correct padding, valid alphabet.
  /// </summary>
  TDefaultBase64EncoderProvider = class(TInterfacedObject, IDataEncoderProvider)
  public
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
    function DecodeData(const AEncoded: string): TBytes;
    function IsValidCharset(const AEncoded: string): Boolean;
  end;

  /// <summary>
  /// Default Hex encoder provider implementation.
  /// Produces uppercase hex. Accepts both upper and lower case on decode/validate.
  /// </summary>
  TDefaultHexEncoderProvider = class(TInterfacedObject, IDataEncoderProvider)
  public
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
    function DecodeData(const AEncoded: string): TBytes;
    function IsValidCharset(const AEncoded: string): Boolean;
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
    function IsValidCharset(const AEncoded: string): Boolean;
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

function IsCharInAlphabet(ACh: Char; const AAlphabet: string): Boolean;
begin
  Result := Pos(ACh, AAlphabet) > 0;
end;

function IsJsonWhitespace(ACh: Char): Boolean;
begin
  Result := (ACh = #9) or (ACh = #10) or (ACh = #13) or (ACh = #32);
end;

{ TDefaultBase58EncoderProvider }

function TDefaultBase58EncoderProvider.EncodeData(const AData: TBytes;
  AOffset, ACount: Integer): string;
var
  LSlice: TBytes;
begin
  ValidateRange(AData, AOffset, ACount);
  LSlice := Copy(AData, AOffset, ACount);
  Result := TBase58.Bitcoin.Encode(LSlice);
end;

function TDefaultBase58EncoderProvider.DecodeData(const AEncoded: string): TBytes;
var
  LTrimmed: string;
begin
  if AEncoded = '' then
    raise EArgumentException.Create('encoded');

  LTrimmed := Trim(AEncoded);
  try
    Result := TBase58.Bitcoin.Decode(LTrimmed);
  except
    on E: EArgumentSimpleBaseLibException do
      raise EArgumentException.Create('Invalid base58 character');
  end;
end;

function TDefaultBase58EncoderProvider.IsValidCharset(const AEncoded: string): Boolean;
var
  LI: Integer;
  LAlphabet: string;
begin
  LAlphabet := TBase58Alphabet.Bitcoin.Value;
  for LI := 1 to Length(AEncoded) do
  begin
    if not IsCharInAlphabet(AEncoded[LI], LAlphabet) then
      Exit(False);
  end;
  Result := True;
end;

{ TDefaultBase64EncoderProvider }

function TDefaultBase64EncoderProvider.EncodeData(const AData: TBytes;
  AOffset, ACount: Integer): string;
var
  LSlice: TBytes;
begin
  ValidateRange(AData, AOffset, ACount);
  LSlice := Copy(AData, AOffset, ACount);
  Result := TBase64.Default.Encode(LSlice);
end;

function TDefaultBase64EncoderProvider.DecodeData(const AEncoded: string): TBytes;
begin
  if AEncoded = '' then
    raise EArgumentException.Create('Invalid Base64 data');
  try
    Result := TBase64.Default.Decode(AEncoded);
  except
    on E: EArgumentSimpleBaseLibException do
      raise EArgumentException.Create('Invalid Base64 data');
  end;
end;

function TDefaultBase64EncoderProvider.IsValidCharset(const AEncoded: string): Boolean;
var
  LI: Integer;
  LAlphabet: string;
  LChar: Char;
begin
  LAlphabet := TBase64Alphabet.Default.Value;
  for LI := 1 to Length(AEncoded) do
  begin
    LChar := AEncoded[LI];
    if (LChar <> '=') and (not IsCharInAlphabet(LChar, LAlphabet)) then
      Exit(False);
  end;
  Result := True;
end;

{ TDefaultHexEncoderProvider }

function TDefaultHexEncoderProvider.EncodeData(const AData: TBytes;
  AOffset, ACount: Integer): string;
var
  LSlice: TBytes;
begin
  ValidateRange(AData, AOffset, ACount);
  LSlice := Copy(AData, AOffset, ACount);
  Result := TBase16.UpperCase.Encode(LSlice);
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
  try
    Result := TBase16.UpperCase.Decode(AEncoded);
  except
    on E: EArgumentSimpleBaseLibException do
      raise EArgumentException.Create('Invalid hex character in input');
  end;
end;

function TDefaultHexEncoderProvider.IsValidCharset(const AEncoded: string): Boolean;
var
  LI: Integer;
  LUpperAlphabet, LLowerAlphabet: string;
begin
  LUpperAlphabet := TBase16Alphabet.UpperCase.Value;
  LLowerAlphabet := TBase16Alphabet.LowerCase.Value;
  for LI := 1 to Length(AEncoded) do
    if (not IsCharInAlphabet(AEncoded[LI], LUpperAlphabet))
      and (not IsCharInAlphabet(AEncoded[LI], LLowerAlphabet)) then
      Exit(False);
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

function TDefaultSolanaKeyPairJsonEncoderProvider.IsValidCharset(const AEncoded: string): Boolean;
var
  LI: Integer;
  LCh: Char;
begin
  for LI := 1 to Length(AEncoded) do
  begin
    LCh := AEncoded[LI];
    if (not IsJsonWhitespace(LCh))
      and (not CharInSet(LCh, ['[', ']', ',', '0'..'9'])) then
      Exit(False);
  end;
  Result := True;
end;

end.
