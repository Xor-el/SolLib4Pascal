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

unit SlpBaseJsonConverter;

{$I ../Include/SolLib.inc}

interface

uses
  System.TypInfo,
  System.Rtti,
  System.JSON,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpValueUtils,
  SlpJsonHelpers,
  SlpValueHelpers;

type
  TBaseJsonConverter = class abstract(TJsonConverter)
  protected
    class function LooksLikeList(Obj: TObject): Boolean; static;
    class function LooksLikeDictionaryWithStringKey(Obj: TObject): Boolean; static;
    class procedure WriteDictionaryWithStringKey(const W: TJsonWriter;
      const S: TJsonSerializer; Obj: TObject); static;
      class procedure WriteListLike(
  const W: TJsonWriter; const S: TJsonSerializer; Obj: TObject); static;
    class procedure WriteTValue(const W: TJsonWriter; const S: TJsonSerializer; const AValue: TValue); static;
  end;

implementation

{ TBaseJsonConverter }

class function TBaseJsonConverter.LooksLikeList(Obj: TObject): Boolean;
var
  Ctx      : TRttiContext;
  RT       : TRttiType;
  AddMethod: TRttiMethod;
  ElemType : PTypeInfo;
begin
  Result := False;
  if Obj = nil then
    Exit;

  Ctx := TRttiContext.Create;
  try
    RT := Ctx.GetType(Obj.ClassType);
    if RT = nil then
      Exit;

    // Let TValueUtils do the heavy lifting:
    // - find Add(...)
    // - extract ElemType (ignored here, but can be used later if needed)
    Result := TValueUtils.IsListLikeType(RT, AddMethod, ElemType);
  finally
    Ctx.Free;
  end;
end;

class function TBaseJsonConverter.LooksLikeDictionaryWithStringKey(
  Obj: TObject): Boolean;
var
  Ctx      : TRttiContext;
  RT       : TRttiType;
  AddMethod: TRttiMethod;
  GetEnum  : TRttiMethod;
  KeyType  : PTypeInfo;
  ValType  : PTypeInfo;
begin
  Result := False;
  if Obj = nil then
    Exit;

  Ctx := TRttiContext.Create;
  try
    RT := Ctx.GetType(Obj.ClassType);
    if RT = nil then
      Exit;

    // Let TValueUtils do the heavy lifting:
    // - finds Add(...)
    // - finds GetEnumerator
    // - gives us KeyType / ValType / GetEnum
    if not TValueUtils.IsDictionaryLikeType(RT, AddMethod, KeyType, ValType, GetEnum) then
      Exit;

    // Now we only care that the key type is string
    Result := (KeyType <> nil) and (KeyType = TypeInfo(string));
  finally
    Ctx.Free;
  end;
end;

class procedure TBaseJsonConverter.WriteDictionaryWithStringKey(
  const W: TJsonWriter; const S: TJsonSerializer; Obj: TObject);
var
  Ctx      : TRttiContext;
  RT       : TRttiType;
  AddMethod: TRttiMethod;
  GetEnum  : TRttiMethod;
  KeyType  : PTypeInfo;
  ValType  : PTypeInfo;

  EnumVal    : TValue;
  EnumObj    : TObject;
  EnumType   : TRttiType;
  MoveNext   : TRttiMethod;
  CurrentProp: TRttiProperty;

  Curr      : TValue;
  CurrType  : TRttiType;
  KeyField  : TRttiField;
  ValField  : TRttiField;

  KeyCell   : TValue;
  ValCell   : TValue;
begin
  // If the dictionary object itself is nil, write JSON null
  if Obj = nil then
  begin
    W.WriteNull;
    Exit;
  end;

  // Otherwise, always emit an object (possibly empty)
  W.WriteStartObject;

  Ctx := TRttiContext.Create;
  try
    RT := Ctx.GetType(Obj.ClassType);
    if RT = nil then
      Exit;

    // Reuse the shared helper: detects Add(Key, Value) and GetEnumerator
    if not TValueUtils.IsDictionaryLikeType(RT, AddMethod, KeyType, ValType, GetEnum) then
      Exit;

    // This writer is specifically for string-keyed dictionaries
    if KeyType <> TypeInfo(string) then
      Exit;

    // Get the enumerator instance
    EnumVal := GetEnum.Invoke(Obj, []);
    EnumObj := EnumVal.AsObject;
    if EnumObj = nil then
      Exit;

    try
      EnumType := Ctx.GetType(EnumObj.ClassType);
      if EnumType = nil then
        Exit;

      MoveNext    := EnumType.GetMethod('MoveNext');
      CurrentProp := EnumType.GetProperty('Current');
      if (MoveNext = nil) or (CurrentProp = nil) then
        Exit;

      CurrType := CurrentProp.PropertyType;
      if (CurrType = nil) or (CurrType.TypeKind <> tkRecord) then
        Exit;

      KeyField := CurrType.GetField('Key');
      ValField := CurrType.GetField('Value');
      if (KeyField = nil) or (ValField = nil) then
        Exit;

      // Iterate dictionary entries
      while MoveNext.Invoke(EnumObj, []).AsBoolean do
      begin
        Curr    := CurrentProp.GetValue(EnumObj);
        KeyCell := KeyField.GetValue(Curr.GetReferenceToRawData);
        ValCell := ValField.GetValue(Curr.GetReferenceToRawData);

        W.WritePropertyName(KeyCell.AsString);
        WriteTValue(W, S, ValCell);
      end;
    finally
      EnumObj.Free;
    end;
  finally
    Ctx.Free;
    W.WriteEndObject; // ensure the JSON object is always properly closed
  end;
end;

class procedure TBaseJsonConverter.WriteListLike(
  const W: TJsonWriter; const S: TJsonSerializer; Obj: TObject);
var
  Ctx      : TRttiContext;
  RT       : TRttiType;
  AddMethod: TRttiMethod;
  ElemType : PTypeInfo;

  Inst      : TRttiInstanceType;
  GetEnum   : TRttiMethod;
  EnumVal   : TValue;
  EnumObj   : TObject;
  EnumType  : TRttiType;
  MoveNext  : TRttiMethod;
  CurrentProp: TRttiProperty;

  Curr      : TValue;
begin
  if Obj = nil then
  begin
    W.WriteNull;
    Exit;
  end;

  W.WriteStartArray;

  Ctx := TRttiContext.Create;
  EnumObj := nil;
  try
    RT := Ctx.GetType(Obj.ClassType);
    if RT = nil then
      Exit;

    // Let the helper detect list-like types and element type
    if not TValueUtils.IsListLikeType(RT, AddMethod, ElemType) then
      Exit;

    Inst := RT as TRttiInstanceType;
    if Inst = nil then
      Exit;

    GetEnum := Inst.GetMethod('GetEnumerator');
    if (GetEnum = nil) or (Length(GetEnum.GetParameters) <> 0) then
      Exit;

    // Get the enumerator object
    EnumVal := GetEnum.Invoke(Obj, []);
    EnumObj := EnumVal.AsObject;
    if EnumObj = nil then
      Exit;

    EnumType := Ctx.GetType(EnumObj.ClassType);
    if EnumType = nil then
      Exit;

    MoveNext := EnumType.GetMethod('MoveNext');
    CurrentProp := EnumType.GetProperty('Current');
    if (MoveNext = nil) or (CurrentProp = nil) then
      Exit;

    // Iterate list elements
    while MoveNext.Invoke(EnumObj, []).AsBoolean do
    begin
      Curr := CurrentProp.GetValue(EnumObj);
      WriteTValue(W, S, Curr);
    end;
  finally
    EnumObj.Free;
    Ctx.Free;
    W.WriteEndArray; // always close the array, even on early Exit
  end;
end;

class procedure TBaseJsonConverter.WriteTValue(
  const W: TJsonWriter; const S: TJsonSerializer; const AValue: TValue);

 procedure WriteArray(const Arr: TValue);
  var
    I, L: Integer;
  begin
    W.WriteStartArray;
    L := Arr.GetArrayLength;
    for I := 0 to L - 1 do
      WriteTValue(W, S, Arr.GetArrayElement(I));
    W.WriteEndArray;
  end;

var
  Obj: TObject;
  V: TValue;
begin
  V := AValue.Unwrap();

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

        // DOM node - write as-is to preserve tokens (no stringification)
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

       if LooksLikeList(Obj) then
       begin
         WriteListLike(W, S, Obj);
         Exit;
       end;

        // Any other object (DTO, record-holder, etc.) -> hand off to serializer
        S.Serialize(W, Obj);
      end;
  else
     S.Serialize(W, V);
  end;
end;

end.
