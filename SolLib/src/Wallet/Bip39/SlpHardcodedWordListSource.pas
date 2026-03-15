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
  System.Generics.Collections;

type
  IWordlistSource = interface
    ['{5D35A5B3-711F-4B1E-A1B2-5F5A9A3E2A01}']
    function Load(const AName: string): IInterface;
  end;

  THardcodedWordlistSource = class(TInterfacedObject, IWordlistSource)
  private
    type
      /// <summary>
      /// Maps a Win32 resource name to the dictionary key used by TWordList.LoadWordList.
      /// </summary>
      TResourceEntry = record
        ResourceName: string;
        Key: string;
      end;

    const
      /// <summary>
      /// Static mapping of embedded resource names to their wordlist dictionary keys.
      /// Keys must match exactly what TWordList.GetLanguageFileName returns.
      /// </summary>
      Resources: array[0..7] of TResourceEntry = (
        (ResourceName: 'BIP39_CHINESE_SIMPLIFIED_WORDLIST';  Key: 'chinese_simplified'),
        (ResourceName: 'BIP39_CHINESE_TRADITIONAL_WORDLIST'; Key: 'chinese_traditional'),
        (ResourceName: 'BIP39_CZECH_WORDLIST';               Key: 'czech'),
        (ResourceName: 'BIP39_ENGLISH_WORDLIST';             Key: 'english'),
        (ResourceName: 'BIP39_FRENCH_WORDLIST';              Key: 'french'),
        (ResourceName: 'BIP39_JAPANESE_WORDLIST';            Key: 'japanese'),
        (ResourceName: 'BIP39_PORTUGUESE_BRAZIL_WORDLIST';   Key: 'portuguese_brazil'),
        (ResourceName: 'BIP39_SPANISH_WORDLIST';             Key: 'spanish')
      );

      /// <summary>Japanese uses ideographic space (U+3000) as word separator.</summary>
      JapaneseSpace = Char($3000);
      /// <summary>All other languages use standard ASCII space.</summary>
      DefaultSpace = Char($0020);

    class var FWordLists: TDictionary<string, string>;

    class function LoadAllFromResources: TDictionary<string, string>; static;

    class constructor Create;
    class destructor Destroy;
  public
    function Load(const AName: string): IInterface;
  end;

implementation

uses
  SlpWordList,
  SlpResourceLoader;

{ THardcodedWordlistSource }

class constructor THardcodedWordlistSource.Create;
begin
  FWordLists := LoadAllFromResources;
end;

class destructor THardcodedWordlistSource.Destroy;
begin
  FreeAndNil(FWordLists);
end;

class function THardcodedWordlistSource.LoadAllFromResources: TDictionary<string, string>;
var
  LI: Integer;
  LRaw: string;
begin
  Result := TDictionary<string, string>.Create(Length(Resources));
  try
    for LI := Low(Resources) to High(Resources) do
    begin
      if not TSlpResourceLoader.Instance.ResourceExists(Resources[LI].ResourceName) then
        Continue;
      LRaw := TSlpResourceLoader.Instance.LoadAsString(
        Resources[LI].ResourceName, TEncoding.UTF8);
      Result.AddOrSetValue(Resources[LI].Key, LRaw);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function THardcodedWordlistSource.Load(const AName: string): IInterface;
var
  LRaw: string;
  LWords: TArray<string>;
  LSpace: Char;
begin
  if not FWordLists.TryGetValue(AName, LRaw) then
    Exit(nil);

  LWords := LRaw.Split([#10], TStringSplitOptions.ExcludeEmpty);

  if SameText(AName, 'japanese') then
    LSpace := JapaneseSpace
  else
    LSpace := DefaultSpace;

  Result := TWordList.Create(LWords, LSpace, AName) as IWordList;
end;

end.
