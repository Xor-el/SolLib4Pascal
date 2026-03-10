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

unit SlpMnemonic;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  SlpWordList,
  SlpWalletEnum,
  SlpNullable,
  SlpCryptoUtils,
  SlpBitWriter,
  SlpArrayUtils,
  SlpKdTable,
  SlpSolLibTypes;

type

  IMnemonic = interface
    ['{38F2E4E6-4D67-4E86-9B0F-6E5B6A7A0E21}']
    function IsValidChecksum: Boolean;
    function DeriveSeed(const APassphrase: string = ''): TBytes;

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

    function DeriveSeed(const APassphrase: string = ''): TBytes;

    /// <summary>
    /// Generate entropy for the given word count.
    /// </summary>
    /// <param name="AWordCount"></param>
    /// <returns></returns>
    /// <exception cref="ArgumentException">Thrown when the word count is invalid.</exception>
    function GenerateEntropy(AWordCount: TWordCount): TBytes;

    class function CorrectWordCount(AMS: Integer): Boolean; static;
    class function NormalizeUTF8(const AStr: string): TBytes; static;

    /// <summary>
    /// Generate a mnemonic
    /// </summary>
    /// <param name="AWordList">The word list of the mnemonic.</param>
    /// <param name="AEntropy">The entropy.</param>
    constructor CreateFromEntropy(AWordList: IWordList; AEntropy: TBytes = nil); overload;

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
    /// <param name="AWordCount">The word count.</param>
    constructor Create(AWordList: IWordList; AWordCount: TWordCount); overload;

    function ToString: string; override;

    class function NormalizeString(const AStr: string): string; static;

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
const
  WHITESPACE_SEPARATORS: array[0..12] of Char = (
    Char($0009),  // TAB
    Char($000A),  // LF (Line Feed)
    Char($000B),  // VT (Vertical Tab)
    Char($000C),  // FF (Form Feed)
    Char($000D),  // CR (Carriage Return)
    Char($0020),  // SPACE
    Char($00A0),  // NBSP (Non-Breaking Space)
    Char($0085),  // NEL (Next Line)
    Char($1680),  // OGHAM SPACE MARK
    Char($2000),  // EN QUAD
    Char($2001),  // EM QUAD
    Char($2002),  // EN SPACE
    Char($3000)   // IDEOGRAPHIC SPACE (full-width space)
  );
var
  LWL: IWordList;
  LWordsSplit: TArray<string>;
  LSep: string;
begin
  if AMnemonic = '' then
    raise EArgumentNilException.Create('mnemonic');

  FMnemonic := Trim(AMnemonic);

  // Resolve wordlist: auto-detect from sentence, else English
  if AWordList = nil then
  begin
    LWL := TWordList.AutoDetect(FMnemonic);
    if LWL = nil then
      LWL := TWordList.English;
  end
  else
    LWL := AWordList;

  // Split using full whitespace list
  LWordsSplit := FMnemonic.Split(WHITESPACE_SEPARATORS, TStringSplitOptions.ExcludeEmpty);

  // Normalize using WordList.Spacing
  LSep := LWL.Space;
  FMnemonic := string.Join(LSep, LWordsSplit);

  if not CorrectWordCount(Length(LWordsSplit)) then
    raise Exception.Create('Word count should be 12,15,18,21 or 24');

  // Normalize each word according to WordList rules (WordList.ToIndices may expect normalized strings)
  FWords := LWordsSplit;
  FWordList := LWL;
  FIndices := LWL.ToIndices(FWords);

  FIsValidChecksum := TNullable<Boolean>.None;
end;

constructor TMnemonic.CreateFromEntropy(AWordList: IWordList; AEntropy: TBytes);

  function JoinInts(const AArr: TArray<Integer>): string;
  var
    LS: TArray<string>;
    LI: Integer;
  begin
    SetLength(LS, Length(AArr));
    for LI := 0 to High(AArr) do
      LS[LI] := AArr[LI].ToString;
    Result := string.Join(',', LS);
  end;

var
  LWL: IWordList;
  LEntBits: Integer;
  LIdx, LCS: Integer;
  LChecksum: TBytes;
  LWriter: TBitWriter;
begin
  // Determine which word list to use
  if AWordList = nil then
    LWL := TWordList.English
  else
    LWL := AWordList;

  // Default entropy if none supplied
  if AEntropy = nil then
    AEntropy := TRandom.RandomBytes(32);

  FWordList := LWL;

  LEntBits := Length(AEntropy) * 8;

  if not TArrayUtils.IndexOf<Integer>(
    FEntArray,
    function (AValue: Integer): Boolean
    begin
      Result := (AValue = LEntBits);
    end,
    LIdx
  ) then
    raise EArgumentException.CreateFmt(
      'The length for entropy should be %s bits',
      [JoinInts(FEntArray)]
    );

  LCS := FCsArray[LIdx];

  LChecksum := TSHA256.HashData(AEntropy);

  // Write entropy || first LCS bits of checksum
  LWriter := TBitWriter.Create;
  try
    LWriter.Write(AEntropy);
    LWriter.Write(LChecksum, LCS);
    FIndices := LWriter.ToIntegers();
  finally
    LWriter.Free;
  end;

  FWords := LWL.GetWordsByIndices(FIndices);
  FMnemonic := LWL.GetSentence(FIndices);

  FIsValidChecksum := TNullable<Boolean>.None;
end;

constructor TMnemonic.Create(AWordList: IWordList; AWordCount: TWordCount);
begin
  CreateFromEntropy(AWordList, GenerateEntropy(AWordCount));
end;

function TMnemonic.GenerateEntropy(AWordCount: TWordCount): TBytes;
var
  LMs, LIdx: Integer;
begin
  LMs := Ord(AWordCount);

  if not CorrectWordCount(LMs) then
    raise EArgumentException.Create('Word count should be 12, 15, 18, 21 or 24');

  if not TArrayUtils.IndexOf<Integer>(
    FMsArray,
    function (AValue: Integer): Boolean
    begin
      Result := (AValue = LMs);
    end,
    LIdx
  ) then
    Exit(nil);

  // Convert bits -> bytes and generate random entropy
  Result := TRandom.RandomBytes(FEntArray[LIdx] div 8);
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

class function TMnemonic.CorrectWordCount(AMS: Integer): Boolean;
var
  LV: Integer;
begin
  Result := False;
  for LV in FMsArray do
    if LV = AMS then
      Exit(True);
end;

class function TMnemonic.NormalizeString(const AStr: string): string;
begin
  Result := TKdTable.NormalizeKd(AStr);
end;

class function TMnemonic.NormalizeUTF8(const AStr: string): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(NormalizeString(AStr));
end;

function TMnemonic.IsValidChecksum: Boolean;
var
  LI, LCS, LENT: Integer;
  LBits: TBits;
  LWriter: TBitWriter;
  LEntropy, LChecksum: TBytes;
  LExpectedIndices: TArray<Integer>;
begin
  if FIsValidChecksum.HasValue then
    Exit(FIsValidChecksum.Value);

  if not TArrayUtils.IndexOf<Integer>(
    FMsArray,
      function(AValue: Integer): Boolean
      begin
        Result := AValue = Length(FIndices);
      end,
    LI
  ) then Exit(False);

  LCS  := FCsArray[LI];
  LENT := FEntArray[LI];

  LWriter := TBitWriter.Create;
  try
    LBits := TWordList.ToBits(FIndices);
    try
      LWriter.Write(LBits, LENT);
    finally
      LBits.Free;
    end;

    LEntropy := LWriter.ToBytes();
    LChecksum := TSHA256.HashData(LEntropy);

    LWriter.Write(LChecksum, LCS);
    LExpectedIndices := LWriter.ToIntegers();
  finally
    LWriter.Free;
  end;

  FIsValidChecksum := TArrayUtils.AreArraysEqual(LExpectedIndices, FIndices);
  Result := FIsValidChecksum.Value;
end;

function TMnemonic.DeriveSeed(const APassphrase: string): TBytes;
var
  LSaltPrefix: TBytes;
  LSaltTail: TBytes;
  LSalt: TBytes;
  LPW: TBytes;
begin
  // salt = "mnemonic" || Normalize(passphrase)
  LSaltPrefix := TEncoding.UTF8.GetBytes('mnemonic');
  LSaltTail   := NormalizeUTF8(APassphrase);
  LSalt       := TArrayUtils.Concat<Byte>(LSaltPrefix, LSaltTail);

  LPW := NormalizeUTF8(FMnemonic);

  Result := TPbkdf2SHA512.DeriveKey(LPW, LSalt, 2048, 64);
end;


function TMnemonic.ToString: string;
begin
  Result := FMnemonic;
end;

end.



