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
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  System.JSON,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpValueUtils,
  SlpJsonHelpers,
  SlpValueHelpers;

type
  TBaseJsonConverter = class abstract(TJsonConverter)
  protected
    class function LooksLikeList(AObj: TObject): Boolean; static;
    class function LooksLikeDictionaryWithStringKey(AObj: TObject): Boolean; static;
    class procedure WriteDictionaryWithStringKey(const AWriter: TJsonWriter;
      const ASerializer: TJsonSerializer; AObj: TObject); static;
    class procedure WriteListLike(
      const AWriter: TJsonWriter; const ASerializer: TJsonSerializer; AObj: TObject); static;
    class procedure WriteTValue(const AWriter: TJsonWriter; const ASerializer: TJsonSerializer; const AValue: TValue); static;
    class procedure SkipPropertyName(const AReader: TJsonReader); static;
  public
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
  end;

implementation

{ TBaseJsonConverter }

class function TBaseJsonConverter.LooksLikeList(AObj: TObject): Boolean;
var
  LCtx: TRttiContext;
  LRT: TRttiType;
  LAddMethod: TRttiMethod;
  LElemType: PTypeInfo;
  LGetEnum: TRttiMethod;
begin
  Result := False;
  if AObj = nil then
    Exit;

  LCtx := TRttiContext.Create;
  try
    LRT := LCtx.GetType(AObj.ClassType);
    if LRT = nil then
      Exit;

    Result := TValueUtils.IsListLikeType(LRT, LAddMethod, LElemType, LGetEnum);
  finally
    LCtx.Free;
  end;
end;

class function TBaseJsonConverter.LooksLikeDictionaryWithStringKey(
  AObj: TObject): Boolean;
var
  LCtx: TRttiContext;
  LRT: TRttiType;
  LAddMethod: TRttiMethod;
  LGetEnum: TRttiMethod;
  LKeyType: PTypeInfo;
  LValType: PTypeInfo;
begin
  Result := False;
  if AObj = nil then
    Exit;

  LCtx := TRttiContext.Create;
  try
    LRT := LCtx.GetType(AObj.ClassType);
    if LRT = nil then
      Exit;

    // Let TValueUtils do the heavy lifting:
    // - finds Add(...)
    // - finds GetEnumerator
    // - gives us KeyType / ValType / GetEnum
    if not TValueUtils.IsDictionaryLikeType(LRT, LAddMethod, LKeyType, LValType, LGetEnum) then
      Exit;

    // Now we only care that the key type is string
    Result := (LKeyType <> nil) and (LKeyType = TypeInfo(string));
  finally
    LCtx.Free;
  end;
end;

class procedure TBaseJsonConverter.WriteDictionaryWithStringKey(
  const AWriter: TJsonWriter; const ASerializer: TJsonSerializer; AObj: TObject);
var
  LCtx: TRttiContext;
  LRT: TRttiType;
  LAddMethod: TRttiMethod;
  LGetEnum: TRttiMethod;
  LKeyType: PTypeInfo;
  LValType: PTypeInfo;
  LEnumVal: TValue;
  LEnumObj: TObject;
  LEnumType: TRttiType;
  LMoveNext: TRttiMethod;
  LCurrentProp: TRttiProperty;
  LCurr: TValue;
  LCurrType: TRttiType;
  LKeyField: TRttiField;
  LValField: TRttiField;
  LKeyCell: TValue;
  LValCell: TValue;
begin
  // If the dictionary object itself is nil, write JSON null
  if AObj = nil then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  // Otherwise, always emit an object (possibly empty)
  AWriter.WriteStartObject;

  LCtx := TRttiContext.Create;
  try
    LRT := LCtx.GetType(AObj.ClassType);
    if LRT = nil then
      Exit;

    // Reuse the shared helper: detects Add(Key, Value) and GetEnumerator
    if not TValueUtils.IsDictionaryLikeType(LRT, LAddMethod, LKeyType, LValType, LGetEnum) then
      Exit;

    // This writer is specifically for string-keyed dictionaries
    if LKeyType <> TypeInfo(string) then
      Exit;

    // Get the enumerator instance
    LEnumVal := LGetEnum.Invoke(AObj, []);
    LEnumObj := LEnumVal.AsObject;
    if LEnumObj = nil then
      Exit;

    try
      LEnumType := LCtx.GetType(LEnumObj.ClassType);
      if LEnumType = nil then
        Exit;

      LMoveNext := LEnumType.GetMethod('MoveNext');
      LCurrentProp := LEnumType.GetProperty('Current');
      if (LMoveNext = nil) or (LCurrentProp = nil) then
        Exit;

      LCurrType := LCurrentProp.PropertyType;
      if (LCurrType = nil) or (LCurrType.TypeKind <> tkRecord) then
        Exit;

      LKeyField := LCurrType.GetField('Key');
      LValField := LCurrType.GetField('Value');
      if (LKeyField = nil) or (LValField = nil) then
        Exit;

      // Iterate dictionary entries
      while LMoveNext.Invoke(LEnumObj, []).AsBoolean do
      begin
        LCurr := LCurrentProp.GetValue(LEnumObj);
        LKeyCell := LKeyField.GetValue(LCurr.GetReferenceToRawData);
        LValCell := LValField.GetValue(LCurr.GetReferenceToRawData);

        AWriter.WritePropertyName(LKeyCell.AsString);
        WriteTValue(AWriter, ASerializer, LValCell);
      end;
    finally
      LEnumObj.Free;
    end;
  finally
    LCtx.Free;
    AWriter.WriteEndObject; // ensure the JSON object is always properly closed
  end;
end;

class procedure TBaseJsonConverter.WriteListLike(
  const AWriter: TJsonWriter; const ASerializer: TJsonSerializer; AObj: TObject);
var
  LCtx: TRttiContext;
  LRT: TRttiType;
  LAddMethod: TRttiMethod;
  LElemType: PTypeInfo;
  LGetEnum: TRttiMethod;
  LEnumVal: TValue;
  LEnumObj: TObject;
  LEnumType: TRttiType;
  LMoveNext: TRttiMethod;
  LCurrentProp: TRttiProperty;

  LCurr: TValue;
begin
  if AObj = nil then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  AWriter.WriteStartArray;

  LCtx := TRttiContext.Create;
  LEnumObj := nil;
  try
    LRT := LCtx.GetType(AObj.ClassType);
    if LRT = nil then
      Exit;

    if not TValueUtils.IsListLikeType(LRT, LAddMethod, LElemType, LGetEnum) then
      Exit;

    // Get the enumerator object
    LEnumVal := LGetEnum.Invoke(AObj, []);
    LEnumObj := LEnumVal.AsObject;
    if LEnumObj = nil then
      Exit;

    LEnumType := LCtx.GetType(LEnumObj.ClassType);
    if LEnumType = nil then
      Exit;

    LMoveNext := LEnumType.GetMethod('MoveNext');
    LCurrentProp := LEnumType.GetProperty('Current');
    if (LMoveNext = nil) or (LCurrentProp = nil) then
      Exit;

    // Iterate list elements
    while LMoveNext.Invoke(LEnumObj, []).AsBoolean do
    begin
      LCurr := LCurrentProp.GetValue(LEnumObj);
      WriteTValue(AWriter, ASerializer, LCurr);
    end;
  finally
    LEnumObj.Free;
    LCtx.Free;
    AWriter.WriteEndArray; // always close the array, even on early Exit
  end;
end;

class procedure TBaseJsonConverter.WriteTValue(
  const AWriter: TJsonWriter; const ASerializer: TJsonSerializer; const AValue: TValue);

 procedure WriteArray(const AArr: TValue);
  var
    LI, LLen: Integer;
  begin
    AWriter.WriteStartArray;
    LLen := AArr.GetArrayLength;
    for LI := 0 to LLen - 1 do
      WriteTValue(AWriter, ASerializer, AArr.GetArrayElement(LI));
    AWriter.WriteEndArray;
  end;

var
  LObj: TObject;
  LV: TValue;
begin
  LV := AValue.Unwrap();

  if LV.IsEmpty then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  case LV.Kind of

    tkDynArray, tkArray:
      WriteArray(LV);

    tkClass:
      begin
        LObj := LV.AsObject;
        if LObj = nil then
        begin
          AWriter.WriteNull;
          Exit;
        end;

        // DOM node - write as-is to preserve tokens (no stringification)
        if LObj is TJSONValue then
        begin
          AWriter.WriteJsonValue(TJSONValue(LObj));
          Exit;
        end;

       if LooksLikeDictionaryWithStringKey(LObj) then
       begin
         WriteDictionaryWithStringKey(AWriter, ASerializer, LObj);
         Exit;
       end;

       if LooksLikeList(LObj) then
       begin
         WriteListLike(AWriter, ASerializer, LObj);
         Exit;
       end;

        // Any other object (DTO, record-holder, etc.) -> hand off to serializer
        ASerializer.Serialize(AWriter, LObj);
      end;
  else
     ASerializer.Serialize(AWriter, LV);
  end;
end;

{ TBaseJsonConverter - helpers }

class procedure TBaseJsonConverter.SkipPropertyName(const AReader: TJsonReader);
begin
  if AReader.TokenType = TJsonToken.PropertyName then
    AReader.Read;
end;

procedure TBaseJsonConverter.WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
  const ASerializer: TJsonSerializer);
begin
  WriteTValue(AWriter, ASerializer, AValue);
end;

end.
