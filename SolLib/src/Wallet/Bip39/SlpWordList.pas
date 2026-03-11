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

unit SlpWordList;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  System.Classes,
  System.Generics.Collections,
  SlpWalletEnum,
  SlpHardcodedWordlistSource;

type
  IWordList = interface(IInterface)
    ['{3E3CFA0C-AC10-4A8A-8B0C-0D6E3F8A1B9E}']
    function GetName: string;
    function GetSpace: Char;
    function WordExists(const AWord: string; out AIndex: Integer): Boolean;
    function WordCount: Integer;
    function GetWords: TArray<string>;
    function GetWordsByIndices(const AIndices: TArray<Integer>): TArray<string>;
    function GetSentence(const AIndices: TArray<Integer>): string;
    function ToIndices(const AWords: TArray<string>): TArray<Integer>;

    property Name: string read GetName;
    property Space: Char read GetSpace;
  end;

  TWordList = class(TInterfacedObject, IWordList)
  private
    const
      BitsPerWord = 11;
      MaxWordValue = (1 shl BitsPerWord) - 1; // 2047
      LanguageCount = 8;

    type
      TLanguageIndex = 0..LanguageCount - 1;

    var
      FWords: TArray<string>;
      FWordMap: TDictionary<string, Integer>;
      FName: string;
      FSpace: Char;

    class var
      FWordlistSource: IWordlistSource;
      FLoadedLists: TDictionary<string, IWordList>;
      FLock: TCriticalSection;
      FSingletons: array[TLanguageIndex] of IWordList;

    class function GetLanguageFileName(ALanguage: TLanguage): string; static;
    class function LanguageToIndex(ALanguage: TLanguage): TLanguageIndex; static;
    class function NormalizeString(const AStr: string): string; static;

    /// <summary>
    /// Thread-safe lazy singleton accessor. Returns the cached wordlist for
    /// the given language, loading it on first access.
    /// </summary>
    class function GetSingleton(ALanguage: TLanguage): IWordList; static;

    class function GetJapanese: IWordList; static;
    class function GetChineseSimplified: IWordList; static;
    class function GetChineseTraditional: IWordList; static;
    class function GetSpanish: IWordList; static;
    class function GetEnglish: IWordList; static;
    class function GetFrench: IWordList; static;
    class function GetPortugueseBrazil: IWordList; static;
    class function GetCzech: IWordList; static;

    function GetName: string;
    function GetSpace: Char;

    /// <summary>
    /// O(1) dictionary lookup for AWord in the normalized word map.
    /// Returns True if found, with AIndex set to the position in FWords.
    /// </summary>
    function WordExists(const AWord: string; out AIndex: Integer): Boolean;
    function WordCount: Integer;
    function GetWords: TArray<string>;
    function GetWordsByIndices(const AIndices: TArray<Integer>): TArray<string>;
    function GetSentence(const AIndices: TArray<Integer>): string;
    function ToIndices(const AWords: TArray<string>): TArray<Integer>;
  public
    constructor Create(const AWords: TArray<string>; ASpace: Char; const AName: string); overload;
    destructor Destroy; override;

    class function AutoDetect(const ASentence: string): IWordList; overload; static;
    class function AutoDetectLanguage(const ASentence: string): TLanguage; overload; static;
    class function AutoDetectLanguage(const AWords: TArray<string>): TLanguage; overload; static;

    /// <summary>
    /// Map integers in [0..2047] to a compact TBits (11 bits per value, MSB first).
    /// </summary>
    class function ToBits(const AValues: TArray<Integer>): TBits; static;

    class function LoadWordList(ALanguage: TLanguage): IWordList; overload; static;
    class function LoadWordList(const AName: string): IWordList; overload; static;

    class property Japanese: IWordList read GetJapanese;
    class property ChineseSimplified: IWordList read GetChineseSimplified;
    class property ChineseTraditional: IWordList read GetChineseTraditional;
    class property Spanish: IWordList read GetSpanish;
    class property English: IWordList read GetEnglish;
    class property French: IWordList read GetFrench;
    class property PortugueseBrazil: IWordList read GetPortugueseBrazil;
    class property Czech: IWordList read GetCzech;

    class constructor Create;
    class destructor Destroy;
  end;

implementation

uses
  SlpMnemonic;

{ TWordList }

class constructor TWordList.Create;
var
  LI: TLanguageIndex;
begin
  FLock := TCriticalSection.Create;
  FLoadedLists := TDictionary<string, IWordList>.Create;
  FWordlistSource := THardcodedWordListSource.Create;
  for LI := Low(TLanguageIndex) to High(TLanguageIndex) do
    FSingletons[LI] := nil;
end;

class destructor TWordList.Destroy;
var
  LI: TLanguageIndex;
begin
  // Release singleton references before freeing infrastructure
  for LI := Low(TLanguageIndex) to High(TLanguageIndex) do
    FSingletons[LI] := nil;
  FWordlistSource := nil;
  FreeAndNil(FLoadedLists);
  FreeAndNil(FLock);
end;

constructor TWordList.Create(const AWords: TArray<string>; ASpace: Char; const AName: string);
var
  LI: Integer;
  LNorm: string;
begin
  inherited Create;
  SetLength(FWords, Length(AWords));
  FWordMap := TDictionary<string, Integer>.Create(Length(AWords));
  for LI := 0 to High(AWords) do
  begin
    LNorm := NormalizeString(AWords[LI]);
    FWords[LI] := LNorm;
    FWordMap.AddOrSetValue(LNorm, LI);
  end;
  FName := AName;
  FSpace := ASpace;
end;

destructor TWordList.Destroy;
begin
  FWordMap.Free;
  inherited Destroy;
end;

class function TWordList.NormalizeString(const AStr: string): string;
begin
  Result := TMnemonic.NormalizeString(AStr);
end;

class function TWordList.LanguageToIndex(ALanguage: TLanguage): TLanguageIndex;
begin
  case ALanguage of
    TLanguage.English:            Result := 0;
    TLanguage.Japanese:           Result := 1;
    TLanguage.Spanish:            Result := 2;
    TLanguage.ChineseSimplified:  Result := 3;
    TLanguage.ChineseTraditional: Result := 4;
    TLanguage.French:             Result := 5;
    TLanguage.PortugueseBrazil:   Result := 6;
    TLanguage.Czech:              Result := 7;
  else
    raise ENotSupportedException.Create('Unsupported language');
  end;
end;

class function TWordList.GetLanguageFileName(ALanguage: TLanguage): string;
begin
  case ALanguage of
    TLanguage.ChineseTraditional: Result := 'chinese_traditional';
    TLanguage.ChineseSimplified:  Result := 'chinese_simplified';
    TLanguage.English:            Result := 'english';
    TLanguage.Japanese:           Result := 'japanese';
    TLanguage.Spanish:            Result := 'spanish';
    TLanguage.French:             Result := 'french';
    TLanguage.PortugueseBrazil:   Result := 'portuguese_brazil';
    TLanguage.Czech:              Result := 'czech';
    TLanguage.Unknown:            raise ENotSupportedException.Create('Unknown language');
  else
    raise ENotSupportedException.Create('Unsupported language');
  end;
end;

class function TWordList.GetSingleton(ALanguage: TLanguage): IWordList;
var
  LIdx: TLanguageIndex;
begin
  LIdx := LanguageToIndex(ALanguage);

  // Double-checked locking: fast path without lock
  Result := FSingletons[LIdx];
  if Result <> nil then
    Exit;

  FLock.Acquire;
  try
    if FSingletons[LIdx] = nil then
      FSingletons[LIdx] := LoadWordList(ALanguage);
    Result := FSingletons[LIdx];
  finally
    FLock.Release;
  end;
end;

class function TWordList.GetJapanese: IWordList;
begin
  Result := GetSingleton(TLanguage.Japanese);
end;

class function TWordList.GetChineseSimplified: IWordList;
begin
  Result := GetSingleton(TLanguage.ChineseSimplified);
end;

class function TWordList.GetChineseTraditional: IWordList;
begin
  Result := GetSingleton(TLanguage.ChineseTraditional);
end;

class function TWordList.GetSpanish: IWordList;
begin
  Result := GetSingleton(TLanguage.Spanish);
end;

class function TWordList.GetEnglish: IWordList;
begin
  Result := GetSingleton(TLanguage.English);
end;

class function TWordList.GetFrench: IWordList;
begin
  Result := GetSingleton(TLanguage.French);
end;

class function TWordList.GetPortugueseBrazil: IWordList;
begin
  Result := GetSingleton(TLanguage.PortugueseBrazil);
end;

class function TWordList.GetCzech: IWordList;
begin
  Result := GetSingleton(TLanguage.Czech);
end;

function TWordList.WordExists(const AWord: string; out AIndex: Integer): Boolean;
begin
  Result := FWordMap.TryGetValue(NormalizeString(AWord), AIndex);
  if not Result then
    AIndex := -1;
end;

function TWordList.WordCount: Integer;
begin
  Result := Length(FWords);
end;

function TWordList.GetWords: TArray<string>;
begin
  Result := FWords;
end;

function TWordList.GetWordsByIndices(const AIndices: TArray<Integer>): TArray<string>;
var
  LI, LIdx: Integer;
begin
  SetLength(Result, Length(AIndices));
  for LI := 0 to High(AIndices) do
  begin
    LIdx := AIndices[LI];
    if (LIdx < 0) or (LIdx >= Length(FWords)) then
      raise ERangeError.CreateFmt('Index %d out of range', [LIdx]);
    Result[LI] := FWords[LIdx];
  end;
end;

function TWordList.GetSentence(const AIndices: TArray<Integer>): string;
begin
  Result := string.Join(FSpace, GetWordsByIndices(AIndices));
end;

function TWordList.ToIndices(const AWords: TArray<string>): TArray<Integer>;
var
  LI, LIdx: Integer;
begin
  SetLength(Result, Length(AWords));
  for LI := 0 to High(AWords) do
  begin
    if not WordExists(AWords[LI], LIdx) then
      raise EArgumentException.CreateFmt(
        'Word "%s" is not in the wordlist, cannot rebuild entropy', [AWords[LI]]);
    Result[LI] := LIdx;
  end;
end;

class function TWordList.ToBits(const AValues: TArray<Integer>): TBits;
var
  LV, LBitIndex, LP, LI: Integer;
begin
  for LV in AValues do
    if (LV < 0) or (LV > MaxWordValue) then
      raise EArgumentException.CreateFmt(
        'Word index %d out of range [0..%d]', [LV, MaxWordValue]);

  Result := TBits.Create;
  Result.Size := Length(AValues) * BitsPerWord;

  LBitIndex := 0;
  for LI := 0 to High(AValues) do
  begin
    LV := AValues[LI];
    for LP := 0 to BitsPerWord - 1 do
    begin
      Result[LBitIndex] := (LV and (1 shl (BitsPerWord - 1 - LP))) <> 0;
      Inc(LBitIndex);
    end;
  end;
end;

class function TWordList.LoadWordList(ALanguage: TLanguage): IWordList;
begin
  Result := LoadWordList(GetLanguageFileName(ALanguage));
end;

class function TWordList.LoadWordList(const AName: string): IWordList;
var
  LLoaded: IInterface;
  LWordList: IWordList;
begin
  if AName = '' then
    raise EArgumentException.Create('Word list name is empty');

  FLock.Acquire;
  try
    if FLoadedLists.TryGetValue(AName, Result) then
      Exit;

    if FWordlistSource = nil then
      raise EInvalidOpException.Create(
        'WordList source is not initialized');

    LLoaded := FWordlistSource.Load(AName);
    if not Supports(LLoaded, IWordList, LWordList) then
      raise EInvalidOpException.Create('Wordlist source did not return IWordList');
    Result := LWordList;
    FLoadedLists.Add(AName, LWordList);
  finally
    FLock.Release;
  end;
end;

class function TWordList.AutoDetect(const ASentence: string): IWordList;
begin
  Result := LoadWordList(AutoDetectLanguage(ASentence));
end;

class function TWordList.AutoDetectLanguage(const ASentence: string): TLanguage;
begin
  // Split on normal space ($0020) and Japanese ideographic space ($3000)
  Result := AutoDetectLanguage(ASentence.Split([Char($0020), Char($3000)]));
end;

class function TWordList.AutoDetectLanguage(const AWords: TArray<string>): TLanguage;
const
  IndexToLanguage: array[TLanguageIndex] of TLanguage = (
    TLanguage.English, TLanguage.Japanese, TLanguage.Spanish,
    TLanguage.ChineseSimplified, TLanguage.ChineseTraditional,
    TLanguage.French, TLanguage.PortugueseBrazil, TLanguage.Czech
  );
  AllLists: array[TLanguageIndex] of TLanguage = (
    TLanguage.English, TLanguage.Japanese, TLanguage.Spanish,
    TLanguage.ChineseSimplified, TLanguage.ChineseTraditional,
    TLanguage.French, TLanguage.PortugueseBrazil, TLanguage.Czech
  );
var
  LHits: array[TLanguageIndex] of Integer;
  LI: TLanguageIndex;
  LBestIdx: Integer;
  LBestCount: Integer;
  LS: string;
  LDummy: Integer;
  LInSimplified: Boolean;
begin
  FillChar(LHits, SizeOf(LHits), 0);

  for LS in AWords do
  begin
    LInSimplified := False;
    for LI := Low(TLanguageIndex) to High(TLanguageIndex) do
    begin
      if GetSingleton(AllLists[LI]).WordExists(LS, LDummy) then
      begin
        // ChineseTraditional only counts if the word is NOT in ChineseSimplified
        if AllLists[LI] = TLanguage.ChineseSimplified then
          LInSimplified := True;
        if (AllLists[LI] = TLanguage.ChineseTraditional) and LInSimplified then
          Continue;
        Inc(LHits[LI]);
      end;
    end;
  end;

  // Find the language with the most hits
  LBestIdx := -1;
  LBestCount := 0;
  for LI := Low(TLanguageIndex) to High(TLanguageIndex) do
    if LHits[LI] > LBestCount then
    begin
      LBestCount := LHits[LI];
      LBestIdx := LI;
    end;

  if LBestIdx = -1 then
    Exit(TLanguage.Unknown);

  // If best is ChineseSimplified but Traditional also had exclusive hits, prefer Traditional
  if (IndexToLanguage[LBestIdx] = TLanguage.ChineseSimplified) and
     (LHits[LanguageToIndex(TLanguage.ChineseTraditional)] > 0) then
    Exit(TLanguage.ChineseTraditional);

  Result := IndexToLanguage[LBestIdx];
end;

function TWordList.GetName: string;
begin
  Result := FName;
end;

function TWordList.GetSpace: Char;
begin
  Result := FSpace;
end;

end.
