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

unit SlpTokenListItemExtensionsConverter;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.TypInfo,
  System.Rtti,
  System.JSON,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Serializers,
  SlpBaseJsonConverter,
  SlpValueHelpers,
  SlpJsonHelpers;

type
  /// Converts a JSON object <-> TDictionary<string, TValue>
  /// Primitive JSON becomes native Delphi types.
  /// Object/Array JSON becomes a cloned TJSONValue wrapped in a TValue (the owner frees it later).
  TTokenListItemExtensionsConverter = class(TBaseJsonConverter)
  public
    function CanConvert(ATypeInfo: PTypeInfo): Boolean; override;
    function ReadJson(const AReader: TJsonReader; ATypeInfo: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
  end;

implementation

function TTokenListItemExtensionsConverter.CanConvert(ATypeInfo: PTypeInfo): Boolean;
begin
  Result := ATypeInfo = TypeInfo(TDictionary<string, TValue>);
end;

function TTokenListItemExtensionsConverter.ReadJson(
  const AReader: TJsonReader; ATypeInfo: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  LDict: TDictionary<string, TValue>;
  LJV  : TJSONValue;
  LObj : TJSONObject;
  LPair: TJSONPair;
begin
  if AReader.TokenType = TJsonToken.Null then
    Exit(nil);

  if AReader.TokenType <> TJsonToken.StartObject then
  begin
    AReader.Skip;
    Exit(nil);
  end;

  LJV := AReader.ReadJsonValue; // consumes entire object
  try
    if not (LJV is TJSONObject) then
      Exit(nil);

    LObj := TJSONObject(LJV);
    LDict := TDictionary<string, TValue>.Create;
    try
      for LPair in LObj do
        LDict.Add(LPair.JsonString.Value, LPair.JsonValue.ToTValue());

      Result := TValue.From<TDictionary<string, TValue>>(LDict);
    except
      LDict.Free;
      raise;
    end;
  finally
    LJV.Free;
  end;
end;

end.

