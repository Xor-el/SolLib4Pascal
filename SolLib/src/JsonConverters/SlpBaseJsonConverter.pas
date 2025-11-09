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

unit SlpBaseJsonConverter;

{$I ..\Include\SolLib.inc}

interface

uses
  System.TypInfo,
  System.Rtti,
  System.JSON,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpJsonHelpers,
  SlpValueHelpers;

type
  TBaseJsonConverter = class abstract(TJsonConverter)
  protected
    class function LooksLikeDictionaryWithStringKey(Obj: TObject): Boolean; static;
    class procedure WriteDictionaryWithStringKey(const W: TJsonWriter;
      const S: TJsonSerializer; Obj: TObject); static;
    class procedure WriteTValue(const W: TJsonWriter; const S: TJsonSerializer; const V: TValue); static;
  end;

implementation

{ TBaseJsonConverter }

class function TBaseJsonConverter.LooksLikeDictionaryWithStringKey(
  Obj: TObject): Boolean;
var
  Ctx: TRttiContext;
  RT : TRttiType;
  Inst: TRttiInstanceType;
  GetEnum: TRttiMethod;
  EnumObj: TObject;
  EnumType: TRttiType;
  CurrentProp: TRttiProperty;
  CurrType: TRttiType;
  KeyField, ValField: TRttiField;
begin
  Result := False;
  if Obj = nil then
    Exit;

  Ctx := TRttiContext.Create;
  try
    RT := Ctx.GetType(Obj.ClassType);
    if (RT = nil) or (RT.TypeKind <> tkClass) then Exit;

    Inst := RT as TRttiInstanceType;
    if Inst = nil then Exit;

    GetEnum := Inst.GetMethod('GetEnumerator');
    if GetEnum = nil then Exit;

    EnumObj := GetEnum.Invoke(Obj, []).AsObject;
    if EnumObj = nil then Exit;

    try
      EnumType := Ctx.GetType(EnumObj.ClassType);
      if EnumType = nil then Exit;

      CurrentProp := EnumType.GetProperty('Current');
      if CurrentProp = nil then Exit;

      CurrType := CurrentProp.PropertyType;
      if (CurrType = nil) or (CurrType.TypeKind <> tkRecord) then Exit;

      KeyField := CurrType.GetField('Key');
      ValField := CurrType.GetField('Value');
      if (KeyField = nil) or (ValField = nil) then Exit;

      Result := (KeyField.FieldType.Handle = TypeInfo(string));
    finally
      EnumObj.Free;
    end;
  finally
    Ctx.Free;
  end;
end;


class procedure TBaseJsonConverter.WriteDictionaryWithStringKey(
  const W: TJsonWriter; const S: TJsonSerializer; Obj: TObject);
var
  Ctx: TRttiContext;
  RT: TRttiType;
  Inst: TRttiInstanceType;
  GetEnum, MoveNext: TRttiMethod;
  EnumObj: TObject;
  EnumType: TRttiType;
  CurrentProp: TRttiProperty;

  Curr: TValue;
  CurrType: TRttiType;
  KeyField, ValField: TRttiField;

  KeyCell, ValCell: TValue;
  KeyStr: string;
  EnumInvokeRes: TValue;
  MoveRes: TValue;
begin
  W.WriteStartObject;

  Ctx := TRttiContext.Create;
  try
    RT := Ctx.GetType(Obj.ClassType);
    Inst := RT as TRttiInstanceType;

    GetEnum := Inst.GetMethod('GetEnumerator');
    EnumInvokeRes := GetEnum.Invoke(Obj, []);
    EnumObj := EnumInvokeRes.AsObject;

    try
      EnumType := Ctx.GetType(EnumObj.ClassType);
      MoveNext := EnumType.GetMethod('MoveNext');
      CurrentProp := EnumType.GetProperty('Current');

      CurrType := CurrentProp.PropertyType;
      KeyField := CurrType.GetField('Key');
      ValField := CurrType.GetField('Value');

      MoveRes := TValue.Empty;
      while True do
      begin
        MoveRes := MoveNext.Invoke(EnumObj, []);
        if not MoveRes.AsBoolean then
          Break;

        Curr := CurrentProp.GetValue(EnumObj);

        KeyCell := KeyField.GetValue(Curr.GetReferenceToRawData);
        ValCell := ValField.GetValue(Curr.GetReferenceToRawData);

        KeyStr := KeyCell.AsString;
        W.WritePropertyName(KeyStr);

        WriteTValue(W, S, ValCell.Unwrap());
      end;
    finally
      EnumObj.Free;
    end;
  finally
    Ctx.Free;
  end;

  W.WriteEndObject;
end;

class procedure TBaseJsonConverter.WriteTValue(
  const W: TJsonWriter; const S: TJsonSerializer; const V: TValue);

 procedure WriteArray(const Arr: TValue);
  var
    I, L: Integer;
  begin
    W.WriteStartArray;
    L := Arr.GetArrayLength;
    for I := 0 to L - 1 do
      WriteTValue(W, S, Arr.GetArrayElement(I).Unwrap());
    W.WriteEndArray;
  end;

var
  Obj: TObject;
begin
  if V.IsEmpty then
  begin
    W.WriteNull;
    Exit;
  end;

    case V.Kind of

    tkDynArray, tkArray:
      WriteArray(V);

    tkClass:
      begin
        Obj := V.AsObject;
        if Obj = nil then
        begin
          W.WriteNull;
          Exit;
        end;

        // DOM node → write as-is to preserve tokens (no stringification)
        if Obj is TJSONValue then
        begin
          W.WriteJsonValue(TJSONValue(Obj));
          Exit;
        end;

       if LooksLikeDictionaryWithStringKey(Obj) then
       begin
         WriteDictionaryWithStringKey(W, S, Obj);
         Exit;
       end;

        // Any other object (DTO, record-holder, etc.) → hand off to serializer
        S.Serialize(W, Obj);
      end;
  else
     S.Serialize(W, V);
  end;
end;

end.
