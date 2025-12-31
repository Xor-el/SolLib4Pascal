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
    function WordExists(const AWord: string; out Index: Integer): Boolean;
    function WordCount: Integer;
    function GetWords: TArray<string>;
    function GetWordsByIndices(const Indices: TArray<Integer>): TArray<string>;
    function GetSentence(const Indices: TArray<Integer>): string;
    function ToIndices(const Words: TArray<string>): TArray<Integer>;

    property Name: string read GetName;
    property Space: Char read GetSpace;
  end;

  TWordList = class(TInterfacedObject, IWordList)
  private
    FWords: TArray<string>;
    FName : string;
    FSpace: Char;

    class var FWordlistSource: IWordlistSource;
    class var FLoadedLists: TDictionary<string, IWordList>;
    class var FLoadedLock, FSingletonLock : TCriticalSection;

    class var FJapanese, FChineseSimplified, FChineseTraditional, FSpanish, FEnglish, FFrench, FPortugueseBrazil, FCzech: IWordList;

    class function GetLanguageFileName(ALanguage: TLanguage): string; static;
    class function NormalizeString(const S: string): string; static;

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

    function WordExists(const AWord: string; out Index: Integer): Boolean;
    function WordCount: Integer;
    function GetWords: TArray<string>;
    function GetWordsByIndices(const Indices: TArray<Integer>): TArray<string>;
    function GetSentence(const Indices: TArray<Integer>): string;
    function ToIndices(const Words: TArray<string>): TArray<Integer>;

  public
    constructor Create(const AWords: TArray<string>; ASpace: Char; const AName: string); overload;

    class function AutoDetect(const Sentence: string): IWordList; overload; static;
    class function AutoDetectLanguage(const Sentence: string): TLanguage; overload; static;
    class function AutoDetectLanguage(const Words: TArray<string>): TLanguage; overload; static;

    // Map integers in [0..2047] to a compact TBits (11 bits per value, MSB first)
    class function ToBits(const Values: TArray<Integer>): TBits; static;

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
  FLoadedLock    := TCriticalSection.Create;
  FSingletonLock := TCriticalSection.Create;
  FLoadedLists := TDictionary<string, IWordList>.Create;

  FWordlistSource := THardcodedWordListSource.Create;

  FJapanese          := nil;
  FChineseSimplified := nil;
  FChineseTraditional:= nil;
  FSpanish           := nil;
  FEnglish           := nil;
  FFrench            := nil;
  FPortugueseBrazil  := nil;
  FCzech             := nil;
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
  I: Integer;
begin
  inherited Create;
  SetLength(FWords, Length(AWords));
  for I := 0 to High(AWords) do
    FWords[I] := NormalizeString(AWords[I]);
  FName  := AName;
  FSpace := ASpace;
end;

class function TWordList.NormalizeString(const S: string): string;
begin
  Result := TMnemonic.NormalizeString(S);
end;

class function TWordList.GetLanguageFileName(ALanguage: TLanguage): string;
begin
  case ALanguage of
    TLanguage.ChineseTraditional: Result := 'chinese_traditional';
    TLanguage.ChineseSimplified : Result := 'chinese_simplified';
    TLanguage.English           : Result := 'english';
    TLanguage.Japanese          : Result := 'japanese';
    TLanguage.Spanish           : Result := 'spanish';
    TLanguage.French            : Result := 'french';
    TLanguage.PortugueseBrazil  : Result := 'portuguese_brazil';
    TLanguage.Czech             : Result := 'czech';
    TLanguage.Unknown           : raise ENotSupportedException.Create('Unknown language');
  else
    raise ENotSupportedException.Create('Unsupported language');
  end;
end;

function TWordList.WordExists(const AWord: string; out Index: Integer): Boolean;
var
  N: string;
begin
  N := NormalizeString(AWord);

  Result := TArrayUtils.IndexOf<string>(
    FWords,
    function (S: string): Boolean
    begin
      Result := SameStr(N, S);
    end,
    Index
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

function TWordList.GetWordsByIndices(const Indices: TArray<Integer>): TArray<string>;
var
  L: TList<string>;
  I, Idx: Integer;
begin
  L := TList<string>.Create;
  try
    L.Capacity := Length(Indices);
    for I := 0 to High(Indices) do
    begin
      Idx := Indices[I];
      if (Idx < 0) or (Idx >= Length(FWords)) then
        raise ERangeError.CreateFmt('Index %d out of range', [Idx]);
      L.Add(FWords[Idx]);
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TWordList.GetSentence(const Indices: TArray<Integer>): string;
var
  Parts: TArray<string>;
begin
  Parts := GetWordsByIndices(Indices);
  Result := string.Join(FSpace, Parts);
end;

function TWordList.ToIndices(const Words: TArray<string>): TArray<Integer>;
var
  I, Idx: Integer;
begin
  SetLength(Result, Length(Words));
  for I := 0 to High(Words) do
  begin
    if not WordExists(Words[I], Idx) then
      raise Exception.CreateFmt(
        'Word "%s" is not in the wordlist for this language, cannot continue to rebuild entropy from wordlist',
        [Words[I]]);
    Result[I] := Idx;
  end;
end;

class function TWordList.ToBits(const Values: TArray<Integer>): TBits;
var
  V: Integer;
  BitIndex, P, I: Integer;
begin
  // Validate: each index must be < 2048 (11 bits)
  for V in Values do
    if (V < 0) or (V >= 2048) then
      raise EArgumentException.Create('values should be between 0 and 2048');

  Result := TBits.Create;
  // 11 bits per value
  Result.Size := Length(Values) * 11;

  BitIndex := 0;
  for I := 0 to High(Values) do
  begin
    V := Values[I];
    // MSB first: (bit 10) .. (bit 0)
    for P := 0 to 10 do
    begin
      Result[BitIndex] := ((V and (1 shl (10 - P))) <> 0);
      Inc(BitIndex);
    end;
  end;
end;

class function TWordList.LoadWordList(ALanguage: TLanguage): IWordList;
begin
  Result := LoadWordList(GetLanguageFileName(ALanguage));
end;

class function TWordList.LoadWordList(const AName: string): IWordList;
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

    Result := FWordlistSource.Load(AName) as IWordList;
    FLoadedLists.Add(AName, Result);
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

class function TWordList.AutoDetect(const Sentence: string): IWordList;
begin
  Result := LoadWordList(AutoDetectLanguage(Sentence));
end;

class function TWordList.AutoDetectLanguage(const Sentence: string): TLanguage;
var
  Words: TArray<string>;
begin
  Words := Sentence.Split([Char($0020), Char($3000)]);  //normal space and JP space
  Result := AutoDetectLanguage(Words);
end;

class function TWordList.AutoDetectLanguage(const Words: TArray<string>): TLanguage;
var
  LanguageCount: array[0..7] of Integer; // EN, JP, ES, ZH-S, ZH-T, FR, PT-BR, CZ
  S: string;

  procedure Bump(Index: Integer);
  begin
    Inc(LanguageCount[Index]);
  end;

  function MaxIndex: Integer;
  var
    I, M, MI: Integer;
  begin
    M := 0;     // start at 0 so we can detect "no hits"
    MI := -1;   // -1 means "none"
    for I := Low(LanguageCount) to High(LanguageCount) do
      if LanguageCount[I] > M then
      begin
        M := LanguageCount[I];
        MI := I;
      end;
    // If M stayed 0, there were no hits -> Unknown
    if M = 0 then
      Exit(-1);
    Result := MI;
  end;


var
  Dummy: Integer;
begin
  FillChar(LanguageCount, SizeOf(LanguageCount), 0);

  for S in Words do
  begin
    if English.WordExists(S, Dummy) then Bump(0);
    if Japanese.WordExists(S, Dummy) then Bump(1);
    if Spanish.WordExists(S, Dummy) then Bump(2);
    if ChineseSimplified.WordExists(S, Dummy) then Bump(3);
    if ChineseTraditional.WordExists(S, Dummy) and (not ChineseSimplified.WordExists(S, Dummy)) then Bump(4);
    if French.WordExists(S, Dummy) then Bump(5);
    if PortugueseBrazil.WordExists(S, Dummy) then Bump(6);
    if Czech.WordExists(S, Dummy) then Bump(7);
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
        // if traditional had hits too (languageCount[4] > 0), prefer traditional
        if LanguageCount[4] > 0 then
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


