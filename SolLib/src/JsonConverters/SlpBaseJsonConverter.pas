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
  SysUtils,
  TypInfo,
  Rtti,
  System.JSON,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpValueUtilities,
  SlpJsonHelpers,
  SlpValueHelpers;

type
  TBaseJsonConverter = class abstract(TJsonConverter)
  protected
    /// <summary>
    /// If AObj is a string-keyed dictionary, writes it as a JSON object and
    /// returns True. Returns False without writing anything if it is not.
    /// </summary>
    class function TryWriteDictionaryWithStringKey(const AWriter: TJsonWriter;
      const ASerializer: TJsonSerializer; const AObj: TObject): Boolean; static;

    /// <summary>
    /// If AObj is a list-like collection, writes it as a JSON array and
    /// returns True. Returns False without writing anything if it is not.
    /// </summary>
    class function TryWriteListLike(const AWriter: TJsonWriter;
      const ASerializer: TJsonSerializer; const AObj: TObject): Boolean; static;

    class procedure WriteTValue(const AWriter: TJsonWriter;
      const ASerializer: TJsonSerializer; const AValue: TValue); static;
    class procedure SkipPropertyName(const AReader: TJsonReader); static;
  public
    /// <summary>
    /// Serializes the given value to a JSON writer.
    /// </summary>
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
  end;

implementation

{ TBaseJsonConverter }

class function TBaseJsonConverter.TryWriteDictionaryWithStringKey(
  const AWriter: TJsonWriter; const ASerializer: TJsonSerializer;
  const AObj: TObject): Boolean;
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
  Result := False;
  if AObj = nil then
    Exit;

  LCtx := TRttiContext.Create;
  try
    LRT := LCtx.GetType(AObj.ClassType);
    if LRT = nil then
      Exit;

    if not TValueUtilities.IsDictionaryLikeType(LRT, LAddMethod, LKeyType, LValType, LGetEnum) then
      Exit;

    if (LKeyType = nil) or (LKeyType <> TypeInfo(string)) then
      Exit;

    // Committed to writing a JSON object
    Result := True;
    AWriter.WriteStartObject;
    LEnumObj := nil;
    try
      LEnumVal := LGetEnum.Invoke(AObj, []);
      LEnumObj := LEnumVal.AsObject;
      if LEnumObj <> nil then
      begin
        LEnumType := LCtx.GetType(LEnumObj.ClassType);
        if LEnumType <> nil then
        begin
          LMoveNext := LEnumType.GetMethod('MoveNext');
          LCurrentProp := LEnumType.GetProperty('Current');
          if (LMoveNext <> nil) and (LCurrentProp <> nil) then
          begin
            LCurrType := LCurrentProp.PropertyType;
            if (LCurrType <> nil) and (LCurrType.TypeKind = tkRecord) then
            begin
              LKeyField := LCurrType.GetField('Key');
              LValField := LCurrType.GetField('Value');
              if (LKeyField <> nil) and (LValField <> nil) then
              begin
                while LMoveNext.Invoke(LEnumObj, []).AsBoolean do
                begin
                  LCurr := LCurrentProp.GetValue(LEnumObj);
                  LKeyCell := LKeyField.GetValue(LCurr.GetReferenceToRawData);
                  LValCell := LValField.GetValue(LCurr.GetReferenceToRawData);
                  AWriter.WritePropertyName(LKeyCell.AsString);
                  WriteTValue(AWriter, ASerializer, LValCell);
                end;
              end;
            end;
          end;
        end;
      end;
    finally
      LEnumObj.Free;
      AWriter.WriteEndObject;
    end;
  finally
    LCtx.Free;
  end;
end;

class function TBaseJsonConverter.TryWriteListLike(const AWriter: TJsonWriter;
  const ASerializer: TJsonSerializer; const AObj: TObject): Boolean;
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
  Result := False;
  if AObj = nil then
    Exit;

  LCtx := TRttiContext.Create;
  try
    LRT := LCtx.GetType(AObj.ClassType);
    if (LRT = nil) or
       not TValueUtilities.IsListLikeType(LRT, LAddMethod, LElemType, LGetEnum) then
      Exit;

    // Committed to writing a JSON array
    Result := True;
    AWriter.WriteStartArray;
    LEnumObj := nil;
    try
      LEnumVal := LGetEnum.Invoke(AObj, []);
      LEnumObj := LEnumVal.AsObject;
      if LEnumObj <> nil then
      begin
        LEnumType := LCtx.GetType(LEnumObj.ClassType);
        if LEnumType <> nil then
        begin
          LMoveNext := LEnumType.GetMethod('MoveNext');
          LCurrentProp := LEnumType.GetProperty('Current');
          if (LMoveNext <> nil) and (LCurrentProp <> nil) then
          begin
            while LMoveNext.Invoke(LEnumObj, []).AsBoolean do
            begin
              LCurr := LCurrentProp.GetValue(LEnumObj);
              WriteTValue(AWriter, ASerializer, LCurr);
            end;
          end;
        end;
      end;
    finally
      LEnumObj.Free;
      AWriter.WriteEndArray;
    end;
  finally
    LCtx.Free;
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

        if TryWriteDictionaryWithStringKey(AWriter, ASerializer, LObj) then
          Exit;

        if TryWriteListLike(AWriter, ASerializer, LObj) then
          Exit;

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
