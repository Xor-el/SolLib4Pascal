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
  Raw: string;
  Words: TArray<string>;
  Space: Char;
begin
  // Return nil if the name is not found
  if not FWordLists.TryGetValue(AName, Raw) then
    Exit(nil);

  // Split on LF only, exclude empty entries
  Words := Raw.Split([#10], TStringSplitOptions.ExcludeEmpty);

  if SameText(AName, 'japanese') then
    Space := Char($3000) //IDEOGRAPHIC SPACE U+$3000
  else
    Space := Char($0020); //SPACE U+$0020

  Result := TWordList.Create(Words, Space, AName) as IWordList;
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
  Dict: TDictionary<string, string>;
  ResName, Key, Raw: string;

  function MakeKeyFromResourceName(const FullName: string): string;
  var
    S: string;
    Parts: TArray<string>;
    I: Integer;
    Part: string;
  begin
    S := FullName;
    S := S.Replace('BIP39_', '', [rfReplaceAll, rfIgnoreCase]);
    S := S.Replace('_WORDLIST', '', [rfReplaceAll, rfIgnoreCase]);
    S := S.Trim.ToLower;

    Parts := S.Split(['_']);
    for I := 0 to High(Parts) do
    begin
      Part := Parts[I];
      if Part = '' then
        Continue;

      if Length(Part) = 1 then
        Part := Part.ToUpper
      else
        Part := Part.Substring(0, 1).ToUpper + Part.Substring(1).ToLower;

      Parts[I] := Part;
    end;

    Result := string.Join('_', Parts);
  end;

begin
  Dict := TDictionary<string,string>.Create(TStringComparerFactory.OrdinalIgnoreCase);
  try
    for ResName in RESOURCE_NAMES do
    begin
      // Skip if resource doesn't exist
      if not TSlpResourceLoader.Instance.ResourceExists(ResName) then
        Continue;

      try
        Raw := TSlpResourceLoader.Instance.LoadAsString(ResName, AEncoding);
        Key := MakeKeyFromResourceName(ResName);
        Dict.AddOrSetValue(Key, Raw);
      except
        on E: Exception do
          Continue; // Skip on error
      end;
    end;

    Result := Dict;
  except
    Dict.Free;
    raise;
  end;
end;

end.

