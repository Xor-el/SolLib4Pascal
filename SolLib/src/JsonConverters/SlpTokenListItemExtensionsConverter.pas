{ * ************************************************************************ * }
{ *                              SolLib Library                              * }
{ *                  Copyright (c) 2025 Ugochukwu Mmaduekwe                  * }
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

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.TypInfo,
  System.Rtti,
  System.JSON,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
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
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
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
  Dict: TDictionary<string, TValue>;
  JV  : TJSONValue;
  Obj : TJSONObject;
  P   : TJSONPair;
begin
  if AReader.TokenType = TJsonToken.Null then
    Exit(nil);

  if AReader.TokenType <> TJsonToken.StartObject then
  begin
    AReader.Skip;
    Exit(nil);
  end;

  JV := AReader.ReadJsonValue; // consumes entire object
  try
    if not (JV is TJSONObject) then
      Exit(nil);

    Obj := TJSONObject(JV);
    Dict := TDictionary<string, TValue>.Create;
    try
      for P in Obj do
        Dict.Add(P.JsonString.Value, P.JsonValue.ToTValue());

      Result := TValue.From<TDictionary<string, TValue>>(Dict);
    except
      Dict.Free;
      raise;
    end;
  finally
    JV.Free;
  end;
end;

procedure TTokenListItemExtensionsConverter.WriteJson(
  const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer);
var
  Dict: TDictionary<string, TValue>;
  KVP : TPair<string, TValue>;
begin
  if AValue.IsEmpty then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  Dict := TDictionary<string, TValue>(AValue.AsObject);
  if Dict = nil then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  AWriter.WriteStartObject;
  for KVP in Dict do
  begin
    AWriter.WritePropertyName(KVP.Key);
    WriteTValue(AWriter, ASerializer, KVP.Value.Unwrap());
  end;
  AWriter.WriteEndObject;
end;

end.

