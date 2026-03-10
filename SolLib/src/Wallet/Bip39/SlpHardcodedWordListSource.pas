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

unit SlpHardcodedWordlistSource;

{$I ../../Include/SolLib.inc}

{$IFDEF USE_EMBEDDED_RESOURCES}
{$R '../../Resources/WordLists.res'}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.Types,
  System.Generics.Defaults,
  System.Generics.Collections,
  SlpComparerFactory;

type
  IWordlistSource = interface
    ['{5D35A5B3-711F-4B1E-A1B2-5F5A9A3E2A01}']
    function Load(const AName: string): IInterface;
  end;

  THardcodedWordlistSource = class(TInterfacedObject, IWordlistSource)
  private
    class var FWordLists: TDictionary<string, string>;
    class constructor Create;
    class destructor Destroy;

    class function LoadAllFromResources(const AEncoding: TEncoding): TDictionary<string, string>;
  public
    function Load(const AName: string): IInterface;
  end;

implementation

uses
  SlpWordList,
  SlpResourceLoader;

class constructor THardcodedWordlistSource.Create;
begin
  FWordLists := LoadAllFromResources(TEncoding.UTF8);
end;

class destructor THardcodedWordlistSource.Destroy;
begin
 if Assigned(FWordLists) then
   FWordLists.Free;
end;

function THardcodedWordlistSource.Load(const AName: string): IInterface;
var
  LRaw: string;
  LWords: TArray<string>;
  LSpace: Char;
  LWordList: IWordList;
begin
  // Return nil if the name is not found
  if not FWordLists.TryGetValue(AName, LRaw) then
    Exit(nil);

  // Split on LF only, exclude empty entries
  LWords := LRaw.Split([#10], TStringSplitOptions.ExcludeEmpty);

  if SameText(AName, 'japanese') then
    LSpace := Char($3000) //IDEOGRAPHIC SPACE U+$3000
  else
    LSpace := Char($0020); //SPACE U+$0020

  LWordList := TWordList.Create(LWords, LSpace, AName);
  Result := LWordList;
end;

class function THardcodedWordlistSource.LoadAllFromResources(
  const AEncoding: TEncoding): TDictionary<string, string>;
const
  RESOURCE_NAMES: array[0..7] of string = (
    'BIP39_CHINESE_SIMPLIFIED_WORDLIST',
    'BIP39_CHINESE_TRADITIONAL_WORDLIST',
    'BIP39_CZECH_WORDLIST',
    'BIP39_ENGLISH_WORDLIST',
    'BIP39_FRENCH_WORDLIST',
    'BIP39_JAPANESE_WORDLIST',
    'BIP39_PORTUGUESE_BRAZIL_WORDLIST',
    'BIP39_SPANISH_WORDLIST'
  );
var
  LDict: TDictionary<string, string>;
  LResName, LKey, LRaw: string;

  function MakeKeyFromResourceName(const AFullName: string): string;
  var
    LStr: string;
    LParts: TArray<string>;
    LI: Integer;
    LPart: string;
  begin
    LStr := AFullName;
    LStr := LStr.Replace('BIP39_', '', [rfReplaceAll, rfIgnoreCase]);
    LStr := LStr.Replace('_WORDLIST', '', [rfReplaceAll, rfIgnoreCase]);
    LStr := LStr.Trim.ToLower;

    LParts := LStr.Split(['_']);
    for LI := 0 to High(LParts) do
    begin
      LPart := LParts[LI];
      if LPart = '' then
        Continue;

      if Length(LPart) = 1 then
        LPart := LPart.ToUpper
      else
        LPart := LPart.Substring(0, 1).ToUpper + LPart.Substring(1).ToLower;

      LParts[LI] := LPart;
    end;

    Result := string.Join('_', LParts);
  end;

begin
  LDict := TDictionary<string,string>.Create(TStringComparerFactory.OrdinalIgnoreCase);
  try
    for LResName in RESOURCE_NAMES do
    begin
      // Skip if resource doesn't exist
      if not TSlpResourceLoader.Instance.ResourceExists(LResName) then
        Continue;

      try
        LRaw := TSlpResourceLoader.Instance.LoadAsString(LResName, AEncoding);
        LKey := MakeKeyFromResourceName(LResName);
        LDict.AddOrSetValue(LKey, LRaw);
      except
        on E: Exception do
          Continue; // Skip on error
      end;
    end;

    Result := LDict;
  except
    LDict.Free;
    raise;
  end;
end;

end.

