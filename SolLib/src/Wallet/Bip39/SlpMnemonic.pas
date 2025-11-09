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

unit SlpMnemonic;

{$I ..\..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  SlpWordList,
  SlpWalletEnum,
  SlpNullable,
  SlpUTF8NoBOMEncoding,
  SlpCryptoUtils,
  SlpBitWriter,
  SlpStringUtils,
  SlpArrayUtils,
  SlpKdTable;

type

  IMnemonic = interface
    ['{38F2E4E6-4D67-4E86-9B0F-6E5B6A7A0E21}']
    function IsValidChecksum: Boolean;
    function DeriveSeed(const Passphrase: string = ''): TBytes;

    function GetWordList: IWordList;
    function GetIndices: TArray<Integer>;
    function GetWords: TArray<string>;

    function ToString: string;

    property WordList: IWordList read GetWordList;
    property Indices: TArray<Integer> read GetIndices;
    property Words: TArray<string> read GetWords;
  end;



  TMnemonic = class(TInterfacedObject, IMnemonic)
  private
    FWordList: IWordList;
    FIndices: TArray<Integer>;
    FWords  : TArray<string>;
    FMnemonic: string;
    FIsValidChecksum: TNullable<Boolean>;

    /// <summary>
    /// The word count array.
    /// </summary>
    class var FMsArray: TArray<Integer>;
    /// <summary>
    /// The bit count array.
    /// </summary>
    class var FCsArray: TArray<Integer>;
    /// <summary>
    /// The entropy value array.
    /// </summary>
    class var FEntArray: TArray<Integer>;

    function GetWordList: IWordList;
    function GetIndices: TArray<Integer>;
    function GetWords: TArray<string>;

    /// <summary>
    /// Whether the checksum of the mnemonic is valid.
    /// </summary>
    function IsValidChecksum: Boolean;

    function DeriveSeed(const Passphrase: string = ''): TBytes;

    /// <summary>
    /// Generate entropy for the given word count.
    /// </summary>
    /// <param name="AWordCount"></param>
    /// <returns></returns>
    /// <exception cref="ArgumentException">Thrown when the word count is invalid.</exception>
    function GenerateEntropy(AWordCount: TWordCount): TBytes;

    class function CorrectWordCount(MS: Integer): Boolean; static;
    class function NormalizeUtf8(const S: string): TBytes; static;

    /// <summary>
    /// Generate a mnemonic
    /// </summary>
    /// <param name="AWordList">The word list of the mnemonic.</param>
    /// <param name="Entropy">The entropy.</param>
    constructor CreateFromEntropy(AWordList: IWordList; Entropy: TBytes = nil); overload;

    class constructor Create;

  public
   /// <summary>
   /// Initialize a mnemonic from the given string and wordList type.
   /// </summary>
   /// <param name="AMnemonic">The mnemonic string.</param>
   /// <param name="AWordList">The word list type.</param>
   /// <exception cref="ArgumentNilException">Thrown when the mnemonic string is nil.</exception>
   /// <exception cref="Exception">Thrown when the word count of the mnemonic is invalid.</exception>
    constructor Create(const AMnemonic: string; AWordList: IWordList = nil); overload;

    /// <summary>
    /// Initialize a mnemonic from the given word list and word count..
    /// </summary>
    /// <param name="AWordList">The word list.</param>
    /// <param name="WordCount">The word count.</param>
    constructor Create(AWordList: IWordList; WordCount: TWordCount); overload;

    function ToString: string; override;

    class function NormalizeString(const S: string): string; static;

  end;

implementation

{ TMnemonic }

class constructor TMnemonic.Create;
begin
  FMsArray := TArray<Integer>.Create(12, 15, 18, 21, 24);
  FCsArray := TArray<Integer>.Create(4, 5, 6, 7, 8);
  FEntArray := TArray<Integer>.Create(128, 160, 192, 224, 256);
end;

constructor TMnemonic.Create(const AMnemonic: string; AWordList: IWordList);
var
  WL: IWordList;
  WordsSplit: TArray<string>;
  Sep: string;
begin
  if AMnemonic = '' then
    raise EArgumentNilException.Create('mnemonic');

  FMnemonic := Trim(AMnemonic);

  // Resolve wordlist: auto-detect from sentence, else English
  if AWordList = nil then
  begin
    WL := TWordList.AutoDetect(FMnemonic);
    if WL = nil then
      WL := TWordList.English;
  end
  else
    WL := AWordList;

  // Split on any whitespace
  WordsSplit := TStringUtils.SplitOnWhitespace(FMnemonic);

  // Re-join using WL.Space to normalize spacing
  Sep := WL.Space;
  FMnemonic := string.Join(Sep, WordsSplit);

  if not CorrectWordCount(Length(WordsSplit)) then
    raise Exception.Create('Word count should be 12,15,18,21 or 24');

  // Normalize each word according to WordList rules (WordList.ToIndices may expect normalized strings)
  FWords := WordsSplit;
  FWordList := WL;
  FIndices := WL.ToIndices(FWords);

  FIsValidChecksum := TNullable<Boolean>.None;
end;

constructor TMnemonic.CreateFromEntropy(AWordList: IWordList; Entropy: TBytes);

  function JoinInts(const A: TArray<Integer>): string;
  var
    S: TArray<string>;
    I: Integer;
  begin
    SetLength(S, Length(A));
    for I := 0 to High(A) do
      S[I] := A[I].ToString;
    Result := string.Join(',', S);
  end;

var
  WL: IWordList;
  EntBits: Integer;
  I, CS: Integer;
  Checksum: TBytes;
  Writer: TBitWriter;
begin
  // Determine which word list to use
  if AWordList = nil then
    WL := TWordList.English
  else
    WL := AWordList;

  // Default entropy if none supplied
  if Entropy = nil then
    Entropy := TRandom.RandomBytes(32);

  FWordList := WL;

  EntBits := Length(Entropy) * 8;

  if not TArrayUtils.IndexOf<Integer>(
    FEntArray,
    TFunc<Integer, Boolean>(
      function(const Value: Integer): Boolean
      begin
        Result := (Value = EntBits);
      end
    ),
    I) then
    raise EArgumentException.CreateFmt(
      'The length for entropy should be %s bits',
      [JoinInts(FEntArray)]
    );

  CS := FCsArray[I];

  Checksum := TSHA256.HashData(Entropy);

  // Write entropy || first CS bits of checksum
  Writer := TBitWriter.Create;
  try
    Writer.Write(Entropy);
    Writer.Write(Checksum, CS);
    FIndices := Writer.ToIntegers();
  finally
    Writer.Free;
  end;

  FWords := WL.GetWordsByIndices(FIndices);
  FMnemonic := WL.GetSentence(FIndices);

  FIsValidChecksum := TNullable<Boolean>.None;
end;

constructor TMnemonic.Create(AWordList: IWordList; WordCount: TWordCount);
begin
  CreateFromEntropy(AWordList, GenerateEntropy(wordCount));
end;

function TMnemonic.GenerateEntropy(AWordCount: TWordCount): TBytes;
var
  ms, idx: Integer;
begin
  ms := Ord(AWordCount);

  if not CorrectWordCount(ms) then
    raise EArgumentException.Create('Word count should be 12,15,18,21 or 24');

  if not TArrayUtils.IndexOf<Integer>(
    FMsArray,
    TFunc<Integer, Boolean>(
      function(const Value: Integer): Boolean
      begin
        Result := (Value = ms);
      end
    ),
    idx) then
    Exit(nil);

  // Convert bits → bytes and generate random entropy
  Result := TRandom.RandomBytes(FEntArray[idx] div 8);
end;


function TMnemonic.GetIndices: TArray<Integer>;
begin
  Result := FIndices;
end;

function TMnemonic.GetWordList: IWordList;
begin
  Result := FWordList;
end;

function TMnemonic.GetWords: TArray<string>;
begin
  Result := FWords;
end;

class function TMnemonic.CorrectWordCount(MS: Integer): Boolean;
begin
  Result := False;
  for var V in FMsArray do
    if V = MS then
      Exit(True);
end;

class function TMnemonic.NormalizeString(const S: string): string;
begin
  Result := TKdTable.NormalizeKd(S);
end;

class function TMnemonic.NormalizeUtf8(const S: string): TBytes;
begin
  Result := TUTF8NoBOMEncoding.Instance.GetBytes(NormalizeString(S));
end;

function TMnemonic.IsValidChecksum: Boolean;
var
  I, CS, ENT: Integer;
  Bits: TBits;
  Writer: TBitWriter;
  Entropy, Checksum: TBytes;
  ExpectedIndices: TArray<Integer>;
begin
  if FIsValidChecksum.HasValue then
    Exit(FIsValidChecksum.Value);

  if not TArrayUtils.IndexOf<Integer>(
    FMsArray,
    TFunc<Integer, Boolean>(
      function(const Value: Integer): Boolean
      begin
        Result := Value = Length(FIndices);
      end
    ),
    I
  ) then Exit(False);

  CS  := FCsArray[I];
  ENT := FEntArray[I];

  Writer := TBitWriter.Create;
  try
    Bits := TWordList.ToBits(FIndices);
    try
      Writer.Write(Bits, ENT);
    finally
      Bits.Free;
    end;

    Entropy := Writer.ToBytes();
    Checksum := TSHA256.HashData(Entropy);

    Writer.Write(Checksum, CS);
    ExpectedIndices := Writer.ToIntegers();
  finally
    Writer.Free;
  end;

  FIsValidChecksum := TArrayUtils.AreArraysEqual<Integer>(ExpectedIndices, FIndices);
  Result := FIsValidChecksum.Value;
end;

function TMnemonic.DeriveSeed(const Passphrase: string): TBytes;
var
  PP: string;
  SaltPrefix: TBytes;
  SaltTail: TBytes;
  Salt: TBytes;
  PW: TBytes;
begin
  PP := Passphrase;
  // salt = "mnemonic" || Normalize(passphrase)
  SaltPrefix := TUTF8NoBOMEncoding.Instance.GetBytes('mnemonic');
  SaltTail   := NormalizeUtf8(PP);
  Salt       := TArrayUtils.Concat<Byte>(SaltPrefix, SaltTail);

  PW := NormalizeUtf8(FMnemonic);

  Result := TPbkdf2SHA512.DeriveKey(PW, Salt, 2048, 64);
end;


function TMnemonic.ToString: string;
begin
  Result := FMnemonic;
end;

end.


