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

unit Bip39Tests;

interface

uses
  System.SysUtils,
  System.JSON,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpWordList,
  SlpMnemonic,
  SlpKdTable,
  SlpWalletEnum,
  SlpDataEncoders,
  SolLibWalletTestCase;

type
  TBip39Tests = class(TSolLibWalletTestCase)
  private
    function BytesToHexLower(const ABytes: TBytes): string;
    function LoadJsonArrayFromFile(const AFileName: string): TJSONArray;

  published
    procedure CanGenerateMnemonicOfSpecificLength;
    procedure CanDetectBadChecksum;
    procedure CanNormalizeMnemonicString;

    procedure EnglishTest;   // Bip39Vectors.json
    procedure JapaneseTest;  // Bip39Japanese.json

    procedure CanReturnTheListOfWords;
    procedure KdTableCanNormalize;

    procedure TestKnownEnglish;
    procedure TestKnownJapanese;
    procedure TestKnownSpanish;
    procedure TestKnownFrench;
    procedure TestKnownChineseSimplified;
    procedure TestKnownChineseTraditional;
    procedure TestKnownUnknown;
  end;

implementation

{ TBip39Tests }

function TBip39Tests.BytesToHexLower(const ABytes: TBytes): string;
begin
  if Length(ABytes) = 0 then
    Exit('');
  Result := TEncoders.Hex.EncodeData(ABytes).ToLower();
end;

function TBip39Tests.LoadJsonArrayFromFile(const AFileName: string): TJSONArray;
var
  LText: string;
  LValue: TJSONValue;
begin
  LText := LoadTestData(AFileName);

  LValue := TJSONObject.ParseJSONValue(LText);
  if not Assigned(LValue) then
    raise Exception.CreateFmt('Invalid JSON in resource: %s', [AFileName]);
  try
    if LValue is TJSONArray then
      Exit(TJSONArray(LValue).Clone as TJSONArray) // own a clone
    else
      raise Exception.CreateFmt('Expected JSON array in resource: %s', [AFileName]);
  finally
    LValue.Free;
  end;
end;

procedure TBip39Tests.CanGenerateMnemonicOfSpecificLength;
var
  LCounts: array[0..4] of TWordCount;
  LI: Integer;
  LMnemonic: IMnemonic;
begin
  LCounts[0] := TWordCount.Twelve;
  LCounts[1] := TWordCount.TwentyFour;
  LCounts[2] := TWordCount.TwentyOne;
  LCounts[3] := TWordCount.Fifteen;
  LCounts[4] := TWordCount.Eighteen;

  for LI := Low(LCounts) to High(LCounts) do
  begin
    LMnemonic := TMnemonic.Create(TWordList.English, LCounts[LI]);
    AssertEquals(Ord(LCounts[LI]), Length(LMnemonic.Words));
  end;
end;

procedure TBip39Tests.CanDetectBadChecksum;
var
  LMnemonic: IMnemonic;
begin
  LMnemonic := TMnemonic.Create(
    'turtle front uncle idea crush write shrug there lottery flower risk shell',
    TWordList.English
  );
  AssertTrue(LMnemonic.IsValidChecksum, 'Checksum should be valid');

  LMnemonic := TMnemonic.Create(
    'front front uncle idea crush write shrug there lottery flower risk shell',
    TWordList.English
  );
  AssertFalse(LMnemonic.IsValidChecksum, 'Checksum should be invalid');
end;

procedure TBip39Tests.CanNormalizeMnemonicString;
var
  LMnemonic1, LMnemonic2: IMnemonic;
begin
  LMnemonic1 := TMnemonic.Create(
    'turtle front uncle idea crush write shrug there lottery flower risk shell',
    TWordList.English
  );
  LMnemonic2 := TMnemonic.Create(
    'turtle    front	uncle　 idea crush write shrug there lottery flower risk shell',
    TWordList.English
  );

  AssertEquals(LMnemonic1.ToString, LMnemonic2.ToString);
end;

procedure TBip39Tests.EnglishTest;
var
  LArray: TJSONArray;
  LI: Integer;
  LUnitTest: TJSONArray;
  LMnemonicStr, LSeedStr, LDerived: string;
  LMnemonic: IMnemonic;
begin
  // Each element is an array: [entropyText, mnemonic, seed]
  LArray := LoadJsonArrayFromFile('Bip39Vectors.json');
  try
    for LI := 0 to LArray.Count - 1 do
    begin
      LUnitTest := LArray.Items[LI] as TJSONArray;
      LMnemonicStr := LUnitTest.Items[1].Value;
      LSeedStr     := LUnitTest.Items[2].Value;

      LMnemonic := TMnemonic.Create(LMnemonicStr, TWordList.English);
      AssertTrue(LMnemonic.IsValidChecksum, 'Checksum should be valid');
      LDerived := BytesToHexLower(LMnemonic.DeriveSeed('TREZOR'));
      AssertEquals(LSeedStr, LDerived);
    end;
  finally
    LArray.Free;
  end;
end;

procedure TBip39Tests.CanReturnTheListOfWords;
var
  LLang: IWordList;
  LWords: TArray<string>;
  LWord: string;
  LIdx: Integer;
begin
  LLang := TWordList.English;
  LWords := LLang.GetWords;
  for LWord in LWords do
  begin
    AssertTrue(LLang.WordExists(LWord, LIdx), 'Word should exist');
    AssertTrue(LIdx >= 0, 'Index should be non-negative');
  end;
end;

procedure TBip39Tests.KdTableCanNormalize;
const
  Input    = 'あおぞら';
  Expected = 'あおぞら';
begin
  AssertNotEquals(Input, Expected, 'Precondition: strings must differ in composition');
  AssertEquals(Expected, TKdTable.NormalizeKd(Input));
end;

procedure TBip39Tests.JapaneseTest;
var
  LArray: TJSONArray;
  LI: Integer;
  LObj: TJSONObject;
  LMnemonicStr, LSeedStr, LPassphrase, LDerived: string;
  LMnemonic: IMnemonic;
begin
  // Each element is an object: { "mnemonic": "...", "seed": "...", "passphrase": "..." }
  LArray := LoadJsonArrayFromFile('Bip39Japanese.json');
  try
    for LI := 0 to LArray.Count - 1 do
    begin
      LObj := LArray.Items[LI] as TJSONObject;
      LMnemonicStr := LObj.GetValue('mnemonic').Value;
      LSeedStr     := LObj.GetValue('seed').Value;
      LPassphrase  := LObj.GetValue('passphrase').Value;

      LMnemonic := TMnemonic.Create(LMnemonicStr, TWordList.Japanese);
      AssertTrue(LMnemonic.IsValidChecksum, 'Checksum should be valid');
      LDerived := BytesToHexLower(LMnemonic.DeriveSeed(LPassphrase));
      AssertEquals(LSeedStr, LDerived);
      AssertTrue(LMnemonic.IsValidChecksum, 'Checksum should still be valid');
    end;
  finally
    LArray.Free;
  end;
end;

procedure TBip39Tests.TestKnownEnglish;
begin
  AssertEquals(
    Ord(TLanguage.English),
    Ord(TWordList.AutoDetectLanguage(
      TArray<string>.Create('abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about')
    ))
  );
end;

procedure TBip39Tests.TestKnownJapanese;
begin
  AssertEquals(
    Ord(TLanguage.Japanese),
    Ord(TWordList.AutoDetectLanguage(
      TArray<string>.Create('あいこくしん','あいさつ','あいだ','あおぞら','あかちゃん','あきる','あけがた','あける','あこがれる','あさい',
         'あさひ','あしあと','あじわう','あずかる','あずき','あそぶ','あたえる','あたためる','あたりまえ','あたる','あつい','あつかう','あっしゅく',
         'あつまり','あつめる','あてな','あてはまる','あひる','あぶら','あぶる','あふれる','あまい','あまど','あまやかす','あまり','あみもの','あめりか')
    ))
  );
end;

procedure TBip39Tests.TestKnownSpanish;
begin
  AssertEquals(
    Ord(TLanguage.Spanish),
    Ord(TWordList.AutoDetectLanguage(
      TArray<string>.Create('yoga','yogur','zafiro','zanja','zapato','zarza','zona','zorro','zumo','zurdo')
    ))
  );
end;

procedure TBip39Tests.TestKnownFrench;
begin
  AssertEquals(
    Ord(TLanguage.French),
    Ord(TWordList.AutoDetectLanguage(
      TArray<string>.Create('abusif','antidote')
    ))
  );
end;

procedure TBip39Tests.TestKnownChineseSimplified;
begin
  AssertEquals(
    Ord(TLanguage.ChineseSimplified),
    Ord(TWordList.AutoDetectLanguage(
      TArray<string>.Create('的','一','是','在','不','了','有','和','人','这')
    ))
  );
end;

procedure TBip39Tests.TestKnownChineseTraditional;
begin
  AssertEquals(
    Ord(TLanguage.ChineseTraditional),
    Ord(TWordList.AutoDetectLanguage(
      TArray<string>.Create('的','一','是','在','不','了','有','和','載')
    ))
  );
end;

procedure TBip39Tests.TestKnownUnknown;
begin
  AssertEquals(
    Ord(TLanguage.Unknown),
    Ord(TWordList.AutoDetectLanguage(
      TArray<string>.Create('gffgfg','khjkjk','kjkkj')
    ))
  );
end;

initialization
{$IFDEF FPC}
  RegisterTest(TBip39Tests);
{$ELSE}
  RegisterTest(TBip39Tests.Suite);
{$ENDIF}

end.

