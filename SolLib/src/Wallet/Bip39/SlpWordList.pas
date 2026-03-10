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
  System.Generics.Defaults,
  System.Character,
  SlpWalletEnum,
  SlpArrayUtils,
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
    FWords: TArray<string>;
    FName: string;
    FSpace: Char;

    class var FWordlistSource: IWordlistSource;
    class var FLoadedLists: TDictionary<string, IWordList>;
    class var FLoadedLock, FSingletonLock: TCriticalSection;

    class var FJapanese, FChineseSimplified, FChineseTraditional, FSpanish, FEnglish, FFrench, FPortugueseBrazil, FCzech: IWordList;

    class function GetLanguageFileName(ALanguage: TLanguage): string; static;
    class function NormalizeString(const AStr: string): string; static;

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

    function WordExists(const AWord: string; out AIndex: Integer): Boolean;
    function WordCount: Integer;
    function GetWords: TArray<string>;
    function GetWordsByIndices(const AIndices: TArray<Integer>): TArray<string>;
    function GetSentence(const AIndices: TArray<Integer>): string;
    function ToIndices(const AWords: TArray<string>): TArray<Integer>;

  public
    constructor Create(const AWords: TArray<string>; ASpace: Char; const AName: string); overload;

    class function AutoDetect(const ASentence: string): IWordList; overload; static;
    class function AutoDetectLanguage(const ASentence: string): TLanguage; overload; static;
    class function AutoDetectLanguage(const AWords: TArray<string>): TLanguage; overload; static;

    // Map integers in [0..2047] to a compact TBits (11 bits per value, MSB first)
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
begin
  // Initialize locks and caches
  FLoadedLock := TCriticalSection.Create;
  FSingletonLock := TCriticalSection.Create;
  FLoadedLists := TDictionary<string, IWordList>.Create;

  FWordlistSource := THardcodedWordListSource.Create;

  FJapanese := nil;
  FChineseSimplified := nil;
  FChineseTraditional:= nil;
  FSpanish := nil;
  FEnglish := nil;
  FFrench := nil;
  FPortugueseBrazil := nil;
  FCzech := nil;
end;

class destructor TWordList.Destroy;
begin
  if Assigned(FLoadedLists) then
    FLoadedLists.Free;

  if Assigned(FSingletonLock) then
    FSingletonLock.Free;

  if Assigned(FLoadedLock) then
    FLoadedLock.Free;
end;

constructor TWordList.Create(const AWords: TArray<string>; ASpace: Char; const AName: string);
var
  LI: Integer;
begin
  inherited Create;
  SetLength(FWords, Length(AWords));
  for LI := 0 to High(AWords) do
    FWords[LI] := NormalizeString(AWords[LI]);
  FName := AName;
  FSpace := ASpace;
end;

class function TWordList.NormalizeString(const AStr: string): string;
begin
  Result := TMnemonic.NormalizeString(AStr);
end;

class function TWordList.GetLanguageFileName(ALanguage: TLanguage): string;
begin
  case ALanguage of
    TLanguage.ChineseTraditional: Result := 'chinese_traditional';
    TLanguage.ChineseSimplified: Result := 'chinese_simplified';
    TLanguage.English: Result := 'english';
    TLanguage.Japanese: Result := 'japanese';
    TLanguage.Spanish: Result := 'spanish';
    TLanguage.French: Result := 'french';
    TLanguage.PortugueseBrazil: Result := 'portuguese_brazil';
    TLanguage.Czech: Result := 'czech';
    TLanguage.Unknown: raise ENotSupportedException.Create('Unknown language');
  else
    raise ENotSupportedException.Create('Unsupported language');
  end;
end;

function TWordList.WordExists(const AWord: string; out AIndex: Integer): Boolean;
var
  LN: string;
begin
  LN := NormalizeString(AWord);

  Result := TArrayUtils.IndexOf<string>(
    FWords,
    function (AStr: string): Boolean
    begin
      Result := SameStr(LN, AStr);
    end,
    AIndex
  );
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
  LL: TList<string>;
  LI, LIdx: Integer;
begin
  LL := TList<string>.Create;
  try
    LL.Capacity := Length(AIndices);
    for LI := 0 to High(AIndices) do
    begin
      LIdx := AIndices[LI];
      if (LIdx < 0) or (LIdx >= Length(FWords)) then
        raise ERangeError.CreateFmt('Index %d out of range', [LIdx]);
      LL.Add(FWords[LIdx]);
    end;
    Result := LL.ToArray;
  finally
    LL.Free;
  end;
end;

function TWordList.GetSentence(const AIndices: TArray<Integer>): string;
var
  LParts: TArray<string>;
begin
  LParts := GetWordsByIndices(AIndices);
  Result := string.Join(FSpace, LParts);
end;

function TWordList.ToIndices(const AWords: TArray<string>): TArray<Integer>;
var
  LI, LIdx: Integer;
begin
  SetLength(Result, Length(AWords));
  for LI := 0 to High(AWords) do
  begin
    if not WordExists(AWords[LI], LIdx) then
      raise Exception.CreateFmt(
        'Word "%s" is not in the wordlist for this language, cannot continue to rebuild entropy from wordlist',
        [AWords[LI]]);
    Result[LI] := LIdx;
  end;
end;

class function TWordList.ToBits(const AValues: TArray<Integer>): TBits;
var
  LV: Integer;
  LBitIndex, LP, LI: Integer;
begin
  // Validate: each index must be < 2048 (11 bits)
  for LV in AValues do
    if (LV < 0) or (LV >= 2048) then
      raise EArgumentException.Create('values should be between 0 and 2048');

  Result := TBits.Create;
  // 11 bits per value
  Result.Size := Length(AValues) * 11;

  LBitIndex := 0;
  for LI := 0 to High(AValues) do
  begin
    LV := AValues[LI];
    // MSB first: (bit 10) .. (bit 0)
    for LP := 0 to 10 do
    begin
      Result[LBitIndex] := ((LV and (1 shl (10 - LP))) <> 0);
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
    raise EArgumentNilException.Create('Word list name is nil/empty');

  FLoadedLock.Acquire;
  try
    if FLoadedLists.TryGetValue(AName, Result) then
      Exit;

    if FWordlistSource = nil then
      raise EInvalidOperation.Create(
        'WordList.WordlistSource is not initialized, could not fetch word list.');

    LLoaded := FWordlistSource.Load(AName);
    if not Supports(LLoaded, IWordList, LWordList) then
      raise EInvalidOperation.Create('Wordlist source did not return IWordList.');
    Result := LWordList;
    FLoadedLists.Add(AName, LWordList);
  finally
    FLoadedLock.Release;
  end;
end;

class function TWordList.GetJapanese: IWordList;
begin
  if FJapanese <> nil then
    Exit(FJapanese);

  FSingletonLock.Acquire;
  try
    if FJapanese = nil then
      FJapanese := LoadWordList(TLanguage.Japanese);
    Result := FJapanese;
  finally
    FSingletonLock.Release;
  end;
end;

class function TWordList.GetChineseSimplified: IWordList;
begin
  if FChineseSimplified <> nil then
    Exit(FChineseSimplified);

  FSingletonLock.Acquire;
  try
    if FChineseSimplified = nil then
      FChineseSimplified := LoadWordList(TLanguage.ChineseSimplified);
    Result := FChineseSimplified;
  finally
    FSingletonLock.Release;
  end;
end;

class function TWordList.GetChineseTraditional: IWordList;
begin
  if FChineseTraditional <> nil then
    Exit(FChineseTraditional);

  FSingletonLock.Acquire;
  try
    if FChineseTraditional = nil then
      FChineseTraditional := LoadWordList(TLanguage.ChineseTraditional);
    Result := FChineseTraditional;
  finally
    FSingletonLock.Release;
  end;
end;

class function TWordList.GetSpanish: IWordList;
begin
  if FSpanish <> nil then
    Exit(FSpanish);

  FSingletonLock.Acquire;
  try
    if FSpanish = nil then
      FSpanish := LoadWordList(TLanguage.Spanish);
    Result := FSpanish;
  finally
    FSingletonLock.Release;
  end;
end;

class function TWordList.GetEnglish: IWordList;
begin
  if FEnglish <> nil then
    Exit(FEnglish);

  FSingletonLock.Acquire;
  try
    if FEnglish = nil then
      FEnglish := LoadWordList(TLanguage.English);
    Result := FEnglish;
  finally
    FSingletonLock.Release;
  end;
end;

class function TWordList.GetFrench: IWordList;
begin
  if FFrench <> nil then
    Exit(FFrench);

  FSingletonLock.Acquire;
  try
    if FFrench = nil then
      FFrench := LoadWordList(TLanguage.French);
    Result := FFrench;
  finally
    FSingletonLock.Release;
  end;
end;

class function TWordList.GetPortugueseBrazil: IWordList;
begin
  if FPortugueseBrazil <> nil then
    Exit(FPortugueseBrazil);

  FSingletonLock.Acquire;
  try
    if FPortugueseBrazil = nil then
      FPortugueseBrazil := LoadWordList(TLanguage.PortugueseBrazil);
    Result := FPortugueseBrazil;
  finally
    FSingletonLock.Release;
  end;
end;

class function TWordList.GetCzech: IWordList;
begin
  if FCzech <> nil then
    Exit(FCzech);

  FSingletonLock.Acquire;
  try
    if FCzech = nil then
      FCzech := LoadWordList(TLanguage.Czech);
    Result := FCzech;
  finally
    FSingletonLock.Release;
  end;
end;

class function TWordList.AutoDetect(const ASentence: string): IWordList;
begin
  Result := LoadWordList(AutoDetectLanguage(ASentence));
end;

class function TWordList.AutoDetectLanguage(const ASentence: string): TLanguage;
var
  LWords: TArray<string>;
begin
  LWords := ASentence.Split([Char($0020), Char($3000)]);  //normal space and JP space
  Result := AutoDetectLanguage(LWords);
end;

class function TWordList.AutoDetectLanguage(const AWords: TArray<string>): TLanguage;
var
  LLanguageCount: array[0..7] of Integer; // EN, JP, ES, ZH-S, ZH-T, FR, PT-BR, CZ
  LS: string;

  procedure Bump(AIndex: Integer);
  begin
    Inc(LLanguageCount[AIndex]);
  end;

  function MaxIndex: Integer;
  var
    LI, LM, LMI: Integer;
  begin
    LM := 0;     // start at 0 so we can detect "no hits"
    LMI := -1;   // -1 means "none"
    for LI := Low(LLanguageCount) to High(LLanguageCount) do
      if LLanguageCount[LI] > LM then
      begin
        LM := LLanguageCount[LI];
        LMI := LI;
      end;
    // If LM stayed 0, there were no hits -> Unknown
    if LM = 0 then
      Exit(-1);
    Result := LMI;
  end;


var
  LDummy: Integer;
begin
  FillChar(LLanguageCount, SizeOf(LLanguageCount), 0);

  for LS in AWords do
  begin
    if English.WordExists(LS, LDummy) then Bump(0);
    if Japanese.WordExists(LS, LDummy) then Bump(1);
    if Spanish.WordExists(LS, LDummy) then Bump(2);
    if ChineseSimplified.WordExists(LS, LDummy) then Bump(3);
    if ChineseTraditional.WordExists(LS, LDummy) and (not ChineseSimplified.WordExists(LS, LDummy)) then Bump(4);
    if French.WordExists(LS, LDummy) then Bump(5);
    if PortugueseBrazil.WordExists(LS, LDummy) then Bump(6);
    if Czech.WordExists(LS, LDummy) then Bump(7);
  end;

  // If no hits, Unknown
  if MaxIndex = -1 then
    Exit(TLanguage.Unknown);

  case MaxIndex of
    0: Result := TLanguage.English;
    1: Result := TLanguage.Japanese;
    2: Result := TLanguage.Spanish;
    3:
      begin
        // if traditional had hits too (LLanguageCount[4] > 0), prefer traditional
        if LLanguageCount[4] > 0 then
          Result := TLanguage.ChineseTraditional
        else
          Result := TLanguage.ChineseSimplified;
      end;
    4: Result := TLanguage.ChineseTraditional;
    5: Result := TLanguage.French;
    6: Result := TLanguage.PortugueseBrazil;
    7: Result := TLanguage.Czech;
  else
    Result := TLanguage.Unknown;
  end;
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


