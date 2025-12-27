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
    function BytesToHexLower(const B: TBytes): string;
    function LoadJsonArrayFromFile(const FileName: string): TJSONArray;

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

function TBip39Tests.BytesToHexLower(const B: TBytes): string;
begin
  if Length(B) = 0 then
    Exit('');
  Result := TEncoders.Hex.EncodeData(B).ToLower();
end;

function TBip39Tests.LoadJsonArrayFromFile(const FileName: string): TJSONArray;
var
  Text: string;
  V: TJSONValue;
begin
  Text := LoadTestData(FileName);

  V := TJSONObject.ParseJSONValue(Text);
  if not Assigned(V) then
    raise Exception.CreateFmt('Invalid JSON in resource: %s', [FileName]);
  try
    if V is TJSONArray then
      Exit(TJSONArray(V).Clone as TJSONArray) // own a clone
    else
      raise Exception.CreateFmt('Expected JSON array in resource: %s', [FileName]);
  finally
    V.Free;
  end;
end;

procedure TBip39Tests.CanGenerateMnemonicOfSpecificLength;
var
  Counts: array[0..4] of TWordCount;
  I: Integer;
  M: IMnemonic;
begin
  Counts[0] := TWordCount.Twelve;
  Counts[1] := TWordCount.TwentyFour;
  Counts[2] := TWordCount.TwentyOne;
  Counts[3] := TWordCount.Fifteen;
  Counts[4] := TWordCount.Eighteen;

  for I := Low(Counts) to High(Counts) do
  begin
    M := TMnemonic.Create(TWordList.English, Counts[I]);
    AssertEquals(Ord(Counts[I]), Length(M.Words));
  end;
end;

procedure TBip39Tests.CanDetectBadChecksum;
var
  M: IMnemonic;
begin
  M := TMnemonic.Create(
    'turtle front uncle idea crush write shrug there lottery flower risk shell',
    TWordList.English
  );
  AssertTrue(M.IsValidChecksum, 'Checksum should be valid');

  M := TMnemonic.Create(
    'front front uncle idea crush write shrug there lottery flower risk shell',
    TWordList.English
  );
  AssertFalse(M.IsValidChecksum, 'Checksum should be invalid');
end;

procedure TBip39Tests.CanNormalizeMnemonicString;
var
  M1, M2: IMnemonic;
begin
  M1 := TMnemonic.Create(
    'turtle front uncle idea crush write shrug there lottery flower risk shell',
    TWordList.English
  );
  M2 := TMnemonic.Create(
    'turtle    front	uncle　 idea crush write shrug there lottery flower risk shell',
    TWordList.English
  );

  AssertEquals(M1.ToString, M2.ToString);
end;

procedure TBip39Tests.EnglishTest;
var
  A: TJSONArray;
  I: Integer;
  UnitTest: TJSONArray;
  MnemonicStr, SeedStr, Derived: string;
  M: IMnemonic;
begin
  // Each element is an array: [entropyText, mnemonic, seed]
  A := LoadJsonArrayFromFile('Bip39Vectors.json');
  try
    for I := 0 to A.Count - 1 do
    begin
      UnitTest := A.Items[I] as TJSONArray;
      MnemonicStr := UnitTest.Items[1].Value;
      SeedStr     := UnitTest.Items[2].Value;

      M := TMnemonic.Create(MnemonicStr, TWordList.English);
      AssertTrue(M.IsValidChecksum, 'Checksum should be valid');
      Derived := BytesToHexLower(M.DeriveSeed('TREZOR'));
      AssertEquals(SeedStr, Derived);
    end;
  finally
    A.Free;
  end;
end;

procedure TBip39Tests.CanReturnTheListOfWords;
var
  Lang: IWordList;
  Words: TArray<string>;
  W: string;
  Idx: Integer;
begin
  Lang := TWordList.English;
  Words := Lang.GetWords;
  for W in Words do
  begin
    AssertTrue(Lang.WordExists(W, Idx), 'Word should exist');
    AssertTrue(Idx >= 0, 'Index should be non-negative');
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
  A: TJSONArray;
  I: Integer;
  Obj: TJSONObject;
  MnemonicStr, SeedStr, Passphrase, Derived: string;
  M: IMnemonic;
begin
  // Each element is an object: { "mnemonic": "...", "seed": "...", "passphrase": "..." }
  A := LoadJsonArrayFromFile('Bip39Japanese.json');
  try
    for I := 0 to A.Count - 1 do
    begin
      Obj := A.Items[I] as TJSONObject;
      MnemonicStr := Obj.GetValue('mnemonic').Value;
      SeedStr     := Obj.GetValue('seed').Value;
      Passphrase  := Obj.GetValue('passphrase').Value;

      M := TMnemonic.Create(MnemonicStr, TWordList.Japanese);
      AssertTrue(M.IsValidChecksum, 'Checksum should be valid');
      Derived := BytesToHexLower(M.DeriveSeed(Passphrase));
      AssertEquals(SeedStr, Derived);
      AssertTrue(M.IsValidChecksum, 'Checksum should still be valid');
    end;
  finally
    A.Free;
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

