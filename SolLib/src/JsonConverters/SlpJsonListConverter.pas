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

unit SlpJsonListConverter;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.TypInfo,
  System.Rtti,
  System.JSON,
  System.JSON.Utils,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  System.JSON.Converters,
  SlpJsonHelpers;

type
  TPreserveNullOnReadJsonListConverter<V> = class(TJsonListConverter<V>)
  public
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer)
      : TValue; override;
  end;

  TJsonObjectListConverter<V: class> = class(TJsonConverter)
  public
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer)
      : TValue; override;
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
  end;

  TPreserveNullOnReadJsonObjectListConverter<V: class> = class
    (TJsonObjectListConverter<V>)
  public
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer)
      : TValue; override;
  end;

implementation

{ TPreserveNullOnReadJsonListConverter<V> }

function TPreserveNullOnReadJsonListConverter<V>.ReadJson
  (const AReader: TJsonReader; ATypeInf: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  List: TList<V>;
  JV: TJSONValue;
  Item: V;
begin
  if AReader.TokenType = TJsonToken.Null then
    Result := nil
  else
  begin
    if AExistingValue.IsEmpty then
      List := TList<V>.Create()
    else
      List := AExistingValue.AsType<TList<V>>;

    while AReader.ReadNextArrayElement(JV) do
    begin
      try
        if (JV.Null) then
          Item := Default (V)
        else
          Item := ASerializer.Deserialize<V>(JV.ToJSON);

        List.Add(Item);

      finally
        JV.Free;
      end;
    end;
    Result := TValue.From(List);
  end;
end;

{ TJsonObjectListConverter<V> }

function TJsonObjectListConverter<V>.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := TJsonTypeUtils.InheritsFrom(ATypeInf, TObjectList<V>);
end;

function TJsonObjectListConverter<V>.ReadJson(const AReader: TJsonReader;
  ATypeInf: PTypeInfo; const AExistingValue: TValue;
  const ASerializer: TJsonSerializer): TValue;
var
  List: TObjectList<V>;
  Arr: TArray<V>;
begin
  if AReader.TokenType = TJsonToken.Null then
    Result := nil
  else
  begin
    ASerializer.Populate(AReader, Arr);
    if AExistingValue.IsEmpty then
      List := TObjectList<V>.Create(True)
    else
      List := AExistingValue.AsType<TObjectList<V>>;
    List.AddRange(Arr);
    Result := TValue.From(List);
  end;
end;

procedure TJsonObjectListConverter<V>.WriteJson(const AWriter: TJsonWriter;
  const AValue: TValue; const ASerializer: TJsonSerializer);
var
  List: TObjectList<V>;
begin
  if AValue.TryAsType(List) then
    ASerializer.Serialize(AWriter, List.ToArray)
  else
    raise EJsonException.CreateFmt
      ('Type of Value "%s" does not match with the expected type: "%s"',
      [AValue.TypeInfo^.Name, TObjectList<V>.ClassName]);
end;

{ TPreserveNullOnReadJsonObjectListConverter<V> }

function TPreserveNullOnReadJsonObjectListConverter<V>.ReadJson
  (const AReader: TJsonReader; ATypeInf: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  List: TObjectList<V>;
  JV: TJSONValue;
  Item: V;
begin
  if AReader.TokenType = TJsonToken.Null then
    Result := nil
  else
  begin
    if AExistingValue.IsEmpty then
      List := TObjectList<V>.Create(True)
    else
      List := AExistingValue.AsType<TObjectList<V>>;

    while AReader.ReadNextArrayElement(JV) do
    begin
      try
        if (JV.Null) then
          Item := Default(V)
        else
          Item := ASerializer.Deserialize<V>(JV.ToJSON);

        List.Add(Item);

      finally
        JV.Free;
      end;
    end;
    Result := TValue.From(List);
  end;
end;

end.
