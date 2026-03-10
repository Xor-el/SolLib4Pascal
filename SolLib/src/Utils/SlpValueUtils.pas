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

unit SlpValueUtils;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  System.JSON;

type
  TEnumeratorInfo = record
    EnumObject: TObject;
    MoveNext: TRttiMethod;
    CurrentProp: TRttiProperty;
    CurrentField: TRttiField;

    function IsValid: Boolean;
    function HasCurrent: Boolean;
    function GetCurrentValue: TValue;
    procedure FreeEnumObject;
  end;

  TValueUtils = class sealed
  private
    class function FindParameterlessCtor(const AInstT: TRttiInstanceType): TRttiMethod; static;
    class function CreateCollectionInstance(const AType: TRttiType): TObject; static;

    { enumeration & helpers }
    class function GetEnumeratorInfo(const ARType: TRttiType; const AInstance: TObject): TEnumeratorInfo; static;

    class function ExtractPairKV(const APairValue: TValue; out AKey, AVal: TValue): Boolean; static;

    { assign/clone primitives }
    class procedure AssignObjectProps(ADstObj, ASrcObj: TObject; const ADstType: TRttiType); static;
    class procedure AssignObjectFields(ADstObj, ASrcObj: TObject; const ADstType: TRttiType); static;
    class procedure AssignListLike(ADstList, ASrcList: TObject; const AListType: TRttiType); static;
    class procedure AssignDictionaryLike(ADstDict, ASrcDict: TObject; const ADictType: TRttiType); static;
    class function CloneDynArray(const ASrc: TValue; ATypeInfo: PTypeInfo): TValue; static;

    { ownership flags for TObjectList / TObjectDictionary }
    class procedure CopyOwnershipFlags(const ASrcObj, ADstObj: TObject); static;

    { free helpers }
    class function TryGetBooleanProperty(const AObj: TObject; const APropName: string;
      out AB: Boolean): Boolean; static;

    class procedure FreeRecordFields(const ARecVal: TValue; const ASeen: TDictionary<Pointer, Byte>); static;
    class procedure FreePairKeyValue(const APairValue: TValue;
      const AFreeKey, AFreeVal: Boolean; const ASeen: TDictionary<Pointer, Byte>); static;

    class procedure DrainList(const AObj: TObject; const ASeen: TDictionary<Pointer, Byte>); static;
    class procedure DrainDict(const AObj: TObject; const AFreeKeys, AFreeValues: Boolean;
      const ASeen: TDictionary<Pointer, Byte>); static;

    class procedure DetectListOwnership(const AObj: TObject;
      out AOwnsItems, AHasOwnsProp: Boolean); static;

    class procedure DetectDictOwnership(const AObj: TObject;
      out AOwnsKeys, AOwnsValues, AHasKeysProp, AHasValuesProp: Boolean); static;

    class function HasAddWithArity(const AObj: TObject; const AArity: Integer): Boolean; static;
    class function IsListLikeObject(const AObj: TObject): Boolean; static;
    class function IsDictionaryLikeObject(const AObj: TObject): Boolean; static;

    class function MarkVisited(const APtr: Pointer; const ASeen: TDictionary<Pointer, Byte>): Boolean; static;
    class procedure FreeValueTree(const AValue: TValue; const ASeen: TDictionary<Pointer, Byte>); static;
    class procedure FreeParameterInternal(const AParam: TValue; const ASeen: TDictionary<Pointer, Byte>); static;

    /// Assign ASrc into ADest (recursively). Instantiates ADest as needed.
    class procedure AssignValue(var ADest: TValue; const ASrc: TValue); static;

    /// Create a new instance of ANativeType and copy/morph ASource into it.
    class function CloneObjectToType(const ASource: TValue; ANativeType: PTypeInfo): TValue; static;

  public
    { detection }
    class function IsListLikeType(const ARType: TRttiType;
      out AAddMethod: TRttiMethod; out AElemType: PTypeInfo): Boolean; static;

    class function IsDictionaryLikeType(const ARType: TRttiType;
      out AAddMethod: TRttiMethod; out AKeyType, AValType: PTypeInfo;
      out AGetEnum: TRttiMethod): Boolean; static;
      /// <summary>
    /// Creates an instance of the given class type for population.
    /// - Prefers a parameterless constructor if available.
    /// - Falls back to raw allocation for DTOs with no constructor.
    /// </summary>
    class function MakeInstanceForPopulate(ANativeType: PTypeInfo): TValue; static;

    /// Deep-clone a TValue (DTOs, dyn arrays, generic lists/dictionaries supported).
    class function CloneValue(const AValue: TValue): TValue; static;

    class function CloneValueList(const AParams: TList<TValue>): TList<TValue>; static;

    class function UnwrapValue(const AValue: TValue): TValue; static;

    // Recursively frees anything reachable from AParam that is a class instance.
    // - Arrays: recurse elements
    // - JSON DOM (TJSONValue): free the root (children go with it)
    // - Generic containers (lists/dictionaries via GetEnumerator):
    //     * Recurse into yielded items (TPair<K,V> -> both Key & Value)
    //     * TObjectList<T>: only free container if OwnsObjects=True
    //     * TObjectDictionary<K,V>: only free container if (OwnsKeys or OwnsValues)=True
    class procedure FreeParameter(var AParam: TValue); static;
    class procedure FreeParameters(var AParams: TList<TValue>); overload; static;
    class procedure FreeParameters(var AParams: TDictionary<string, TValue>); overload; static;

    class function ToStringExtended(const AValue: TValue): string; static;
  end;

implementation

const
  SKey = 'Key';
  SValue = 'Value';
  SAdd = 'Add';
  SCreate = 'Create';
  SGetEnumerator = 'GetEnumerator';
  SMoveNext = 'MoveNext';
  SCurrent = 'Current';
  SOwnsObjects = 'OwnsObjects';
  SOwnsKeys = 'OwnsKeys';
  SOwnsValues = 'OwnsValues';
  SOwnerships = 'Ownerships';

function TypedNil(ATypeInfo: PTypeInfo): TValue;
begin
  if ATypeInfo = nil then
    Exit(TValue.Empty);
  Result := TValue.From<TObject>(nil);
  Result := Result.Cast(ATypeInfo);
end;

{ TEnumeratorInfo }

function TEnumeratorInfo.IsValid: Boolean;
begin
  Result := Assigned(EnumObject) and Assigned(MoveNext) and HasCurrent;
end;

function TEnumeratorInfo.HasCurrent: Boolean;
begin
  Result := Assigned(CurrentProp) or Assigned(CurrentField);
end;

function TEnumeratorInfo.GetCurrentValue: TValue;
begin
  if Assigned(CurrentProp) then
    Result := CurrentProp.GetValue(EnumObject)
  else if Assigned(CurrentField) then
    Result := CurrentField.GetValue(EnumObject)
  else
    Result := TValue.Empty;
end;

procedure TEnumeratorInfo.FreeEnumObject;
begin
  EnumObject.Free;
  EnumObject := nil;
  MoveNext := nil;
  CurrentProp := nil;
  CurrentField := nil;
end;

{=== Core RTTI helpers ===}

class function TValueUtils.TryGetBooleanProperty(const AObj: TObject; const APropName: string;
  out AB: Boolean): Boolean;
var
  LCtx: TRttiContext;
  LT: TRttiType;
  LP: TRttiProperty;
  LV: TValue;
begin
  Result := False;
  AB := False;
  if AObj = nil then
    Exit;

  LCtx := TRttiContext.Create;
  try
    LT := LCtx.GetType(AObj.ClassType);
    if LT = nil then Exit;
    LP := LT.GetProperty(APropName);
    if (LP <> nil) and LP.IsReadable and (LP.PropertyType <> nil) and
       (LP.PropertyType.Handle = TypeInfo(Boolean)) then
    begin
      LV := LP.GetValue(AObj);
      AB := LV.AsBoolean;
      Result := True;
    end;
  finally
    LCtx.Free;
  end;
end;

class function TValueUtils.MarkVisited(const APtr: Pointer; const ASeen: TDictionary<Pointer, Byte>): Boolean;
begin
  if (APtr = nil) or (ASeen = nil) then
    Exit(False);
  Result := ASeen.ContainsKey(APtr);
  if not Result then
    ASeen.Add(APtr, 0);
end;

class function TValueUtils.FindParameterlessCtor(const AInstT: TRttiInstanceType): TRttiMethod;
var
  LMethod: TRttiMethod;
begin
  Result := nil;
  for LMethod in AInstT.GetMethods do
    if (LMethod.MethodKind = mkConstructor) and SameText(LMethod.Name, SCreate) and
       (Length(LMethod.GetParameters) = 0) then
      Exit(LMethod);
end;

class function TValueUtils.MakeInstanceForPopulate(ANativeType: PTypeInfo): TValue;
var
  LCtx: TRttiContext;
  LRType: TRttiType;
  LInstT: TRttiInstanceType;
  LCtor: TRttiMethod;
  LObj: TObject;
begin
  Result := TValue.Empty;

  if (ANativeType = nil) or (ANativeType^.Kind <> tkClass) then
    Exit;

  LCtx := TRttiContext.Create;
  try
    LRType := LCtx.GetType(ANativeType);
    if not (LRType is TRttiInstanceType) then
      Exit;

    LInstT := TRttiInstanceType(LRType);
    LCtor := FindParameterlessCtor(LInstT);

    if Assigned(LCtor) then
      Result := LCtor.Invoke(LInstT.MetaclassType, [])
    else
    begin
      LObj := LInstT.MetaclassType.NewInstance;
      TValue.Make(@LObj, ANativeType, Result);
    end;
  finally
    LCtx.Free;
  end;
end;

class function TValueUtils.CreateCollectionInstance(const AType: TRttiType): TObject;
var
  LInstT: TRttiInstanceType;
  LCtor: TRttiMethod;
begin
  Result := nil;
  if not (AType is TRttiInstanceType) then Exit;

  LInstT := TRttiInstanceType(AType);
  LCtor := FindParameterlessCtor(LInstT);

  if not Assigned(LCtor) then
    raise EInvalidOp.CreateFmt('Type %s requires a parameterless Create constructor.',
      [AType.QualifiedName]);

  Result := LCtor.Invoke(LInstT.MetaclassType, []).AsObject;
end;

{=== Detection ===}

class function TValueUtils.IsListLikeType(const ARType: TRttiType;
  out AAddMethod: TRttiMethod; out AElemType: PTypeInfo): Boolean;
var
  LMethod: TRttiMethod;
  LParams: TArray<TRttiParameter>;
begin
  Result := False;
  AAddMethod := nil;
  AElemType := nil;
  for LMethod in ARType.GetMethods do
    if (LMethod.Name = SAdd) and (LMethod.MethodKind in [mkProcedure, mkFunction]) then
    begin
      LParams := LMethod.GetParameters;
      if Length(LParams) = 1 then
      begin
        AAddMethod := LMethod;
        AElemType := LParams[0].ParamType.Handle;
        Exit(True);
      end;
    end;
end;

class function TValueUtils.IsDictionaryLikeType(const ARType: TRttiType;
  out AAddMethod: TRttiMethod; out AKeyType, AValType: PTypeInfo;
  out AGetEnum: TRttiMethod): Boolean;
var
  LMethod: TRttiMethod;
  LParams: TArray<TRttiParameter>;
begin
  AAddMethod := nil;
  AKeyType := nil;
  AValType := nil;
  AGetEnum := nil;

  for LMethod in ARType.GetMethods do
  begin
    if (LMethod.Name = SAdd) and (LMethod.MethodKind in [mkProcedure, mkFunction]) then
    begin
      LParams := LMethod.GetParameters;
      if Length(LParams) = 2 then
      begin
        AAddMethod := LMethod;
        AKeyType := LParams[0].ParamType.Handle;
        AValType := LParams[1].ParamType.Handle;
      end;
    end
    else if (LMethod.Name = SGetEnumerator) and (Length(LMethod.GetParameters) = 0) then
      AGetEnum := LMethod;
  end;

  Result := Assigned(AAddMethod) and Assigned(AGetEnum);
end;

{=== Enumeration helpers ===}

class function TValueUtils.GetEnumeratorInfo(const ARType: TRttiType; const AInstance: TObject): TEnumeratorInfo;
var
  LGetEnum: TRttiMethod;
  LLocalEnum: TObject;
  LCtx: TRttiContext;
  LEnumT: TRttiType;
  LMoveNext: TRttiMethod;
  LCurrentProp: TRttiProperty;
  LCurrentField: TRttiField;
begin
  Result.EnumObject := nil;
  Result.MoveNext := nil;
  Result.CurrentProp := nil;
  Result.CurrentField := nil;

  if (ARType = nil) or (AInstance = nil) then
    Exit;

  LGetEnum := ARType.GetMethod(SGetEnumerator);
  if LGetEnum = nil then
    Exit;

  LLocalEnum := LGetEnum.Invoke(AInstance, []).AsObject;
  if LLocalEnum = nil then
    Exit;

  LCtx := TRttiContext.Create;
  try
    LEnumT := LCtx.GetType(LLocalEnum.ClassType);
    LCurrentField := nil;

    if LEnumT <> nil then
    begin
      LMoveNext := LEnumT.GetMethod(SMoveNext);
      LCurrentProp := LEnumT.GetProperty(SCurrent);
      if LCurrentProp = nil then
        LCurrentField := LEnumT.GetField(SCurrent);

      if Assigned(LMoveNext) and (Assigned(LCurrentProp) or Assigned(LCurrentField)) then
      begin
        Result.EnumObject := LLocalEnum;
        Result.MoveNext := LMoveNext;
        Result.CurrentProp := LCurrentProp;
        Result.CurrentField := LCurrentField;
        LLocalEnum := nil; // ownership transferred
      end;
    end;
  finally
    LCtx.Free;
    if Assigned(LLocalEnum) then
      LLocalEnum.Free;
  end;
end;

class function TValueUtils.ExtractPairKV(const APairValue: TValue; out AKey, AVal: TValue): Boolean;
var
  LCtx: TRttiContext;
  LPairT: TRttiType;
  LPropKey, LPropVal: TRttiProperty;
  LFieldKey, LFieldVal: TRttiField;
  LPData: Pointer;
begin
  Result := False;
  AKey := TValue.Empty;
  AVal := TValue.Empty;

  if APairValue.IsEmpty or (APairValue.Kind <> tkRecord) then Exit;

  LCtx := TRttiContext.Create;
  try
    LPairT := LCtx.GetType(APairValue.TypeInfo);

    // prefer properties
    LPropKey := LPairT.GetProperty(SKey);
    LPropVal := LPairT.GetProperty(SValue);
    if Assigned(LPropKey) and Assigned(LPropVal) then
    begin
      AKey := LPropKey.GetValue(APairValue.GetReferenceToRawData);
      AVal := LPropVal.GetValue(APairValue.GetReferenceToRawData);
      Exit(True);
    end;

    // fallback to fields
    LFieldKey := LPairT.GetField(SKey);
    LFieldVal := LPairT.GetField(SValue);
    if Assigned(LFieldKey) and Assigned(LFieldVal) then
    begin
      LPData := APairValue.GetReferenceToRawData;
      AKey := LFieldKey.GetValue(LPData);
      AVal := LFieldVal.GetValue(LPData);
      Exit(True);
    end;
  finally
    LCtx.Free;
  end;
end;

{=== Assign / Clone primitives ===}

class procedure TValueUtils.AssignListLike(ADstList, ASrcList: TObject; const AListType: TRttiType);
var
  LAddM: TRttiMethod;
  LElemTI: PTypeInfo;
  LEnumInfo: TEnumeratorInfo;
  LCur, LToAdd: TValue;
begin
  if (ADstList = nil) or (ASrcList = nil) then Exit;
  if not IsListLikeType(AListType, LAddM, LElemTI) then Exit;

  LEnumInfo := GetEnumeratorInfo(AListType, ASrcList);
  if not LEnumInfo.IsValid then
    Exit;

  try
    while LEnumInfo.MoveNext.Invoke(LEnumInfo.EnumObject, []).AsBoolean do
    begin
      LCur := LEnumInfo.GetCurrentValue;
      LToAdd := CloneValue(LCur);
      if Assigned(LElemTI) and (not LToAdd.IsEmpty) and (LToAdd.TypeInfo <> LElemTI) then
        LToAdd := LToAdd.Cast(LElemTI);
      LAddM.Invoke(ADstList, [LToAdd]);
    end;
  finally
    LEnumInfo.FreeEnumObject;
  end;
end;

class procedure TValueUtils.AssignDictionaryLike(ADstDict, ASrcDict: TObject; const ADictType: TRttiType);
var
  LAddM, LGetEnumM: TRttiMethod;
  LKeyTI, LValTI: PTypeInfo;
  LEnumInfo: TEnumeratorInfo;
  LPair, LK, LV, LCK, LCV: TValue;
begin
  if (ADstDict = nil) or (ASrcDict = nil) then Exit;
  if not IsDictionaryLikeType(ADictType, LAddM, LKeyTI, LValTI, LGetEnumM) then Exit;

  LEnumInfo := GetEnumeratorInfo(ADictType, ASrcDict);
  if not LEnumInfo.IsValid then
    Exit;

  try
    while LEnumInfo.MoveNext.Invoke(LEnumInfo.EnumObject, []).AsBoolean do
    begin
      LPair := LEnumInfo.GetCurrentValue;
      if not ExtractPairKV(LPair, LK, LV) then
        raise EInvalidOp.Create('Enumerator Current is not a TPair<K,V>.');

      LCK := CloneValue(LK);
      LCV := CloneValue(LV);

      if Assigned(LKeyTI) and (not LCK.IsEmpty) and (LCK.TypeInfo <> LKeyTI) then
        LCK := LCK.Cast(LKeyTI);
      if Assigned(LValTI) and (not LCV.IsEmpty) and (LCV.TypeInfo <> LValTI) then
        LCV := LCV.Cast(LValTI);

      LAddM.Invoke(ADstDict, [LCK, LCV]);
    end;
  finally
    LEnumInfo.FreeEnumObject;
  end;
end;

class function TValueUtils.CloneDynArray(const ASrc: TValue; ATypeInfo: PTypeInfo): TValue;
var
  LCtx: TRttiContext;
  LArrT: TRttiDynamicArrayType;
  LElemTI: PTypeInfo;
  LLen, LI: Integer;
  LElem, LCloned: TValue;
  LTemp: TArray<TValue>;
begin
  Result := TValue.Empty;
  if (ATypeInfo = nil) or (ATypeInfo^.Kind <> tkDynArray) or ASrc.IsEmpty then Exit;

  LCtx := TRttiContext.Create;
  try
    LArrT := LCtx.GetType(ATypeInfo) as TRttiDynamicArrayType;
    if LArrT = nil then Exit;

    LElemTI := nil;
    if Assigned(LArrT.ElementType) then
      LElemTI := LArrT.ElementType.Handle;

    LLen := ASrc.GetArrayLength;
    SetLength(LTemp, LLen);

    for LI := 0 to LLen - 1 do
    begin
      LElem := ASrc.GetArrayElement(LI);
      LCloned := CloneValue(LElem);

      // Ensure typed value compatible with LElemTI, including nils
      if Assigned(LElemTI) then
      begin
        if LCloned.IsEmpty then
          LCloned := TypedNil(LElemTI)
        else if LCloned.TypeInfo <> LElemTI then
          LCloned := LCloned.Cast(LElemTI);
      end;

      LTemp[LI] := LCloned;
    end;

    Result := TValue.FromArray(ATypeInfo, LTemp);
  finally
    LCtx.Free;
  end;
end;

{=== Ownership flags ===}

class procedure TValueUtils.CopyOwnershipFlags(const ASrcObj, ADstObj: TObject);
var
  LCtx: TRttiContext;
  LSrcT, LDstT: TRttiType;
  LPSrc, LPDst: TRttiProperty;
  LV: TValue;
begin
  if (ASrcObj = nil) or (ADstObj = nil) then Exit;

  LCtx := TRttiContext.Create;
  try
    LSrcT := LCtx.GetType(ASrcObj.ClassType);
    LDstT := LCtx.GetType(ADstObj.ClassType);

    // TObjectList<T>: OwnsObjects: Boolean
    LPSrc := LSrcT.GetProperty(SOwnsObjects);
    LPDst := LDstT.GetProperty(SOwnsObjects);
    if Assigned(LPSrc) and LPSrc.IsReadable and Assigned(LPDst) and LPDst.IsWritable then
    begin
      LV := LPSrc.GetValue(ASrcObj);
      LPDst.SetValue(ADstObj, LV);
    end;

    // TObjectDictionary<TKey,TValue>: Ownerships: set; or OwnsKeys/OwnsValues
    LPSrc := LSrcT.GetProperty(SOwnerships);
    LPDst := LDstT.GetProperty(SOwnerships);
    if Assigned(LPSrc) and LPSrc.IsReadable and Assigned(LPDst) and LPDst.IsWritable then
    begin
      LV := LPSrc.GetValue(ASrcObj);
      LPDst.SetValue(ADstObj, LV);
    end
    else
    begin
      LPSrc := LSrcT.GetProperty(SOwnsKeys);
      LPDst := LDstT.GetProperty(SOwnsKeys);
      if Assigned(LPSrc) and LPSrc.IsReadable and Assigned(LPDst) and LPDst.IsWritable then
      begin
        LV := LPSrc.GetValue(ASrcObj);
        LPDst.SetValue(ADstObj, LV);
      end;

      LPSrc := LSrcT.GetProperty(SOwnsValues);
      LPDst := LDstT.GetProperty(SOwnsValues);
      if Assigned(LPSrc) and LPSrc.IsReadable and Assigned(LPDst) and LPDst.IsWritable then
      begin
        LV := LPSrc.GetValue(ASrcObj);
        LPDst.SetValue(ADstObj, LV);
      end;
    end;
  finally
    LCtx.Free;
  end;
end;

{=== Public API ===}

class function TValueUtils.CloneValue(const AValue: TValue): TValue;
var
  LCtx: TRttiContext;
  LRType: TRttiType;
  LAddM: TRttiMethod;
  LElemTI, LKeyTI, LValTI: PTypeInfo;
  LGetEnumM: TRttiMethod;
  LNewObj: TObject;
  LCur: TValue;
begin
  if AValue.IsEmpty then
    Exit(TypedNil(AValue.TypeInfo));

  LCur := UnwrapValue(AValue);

  case LCur.Kind of
    tkClass:
      begin
        if LCur.AsObject = nil then
          Exit(TypedNil(LCur.TypeInfo));

        LCtx := TRttiContext.Create;
        try
          LRType := LCtx.GetType(LCur.TypeInfo);

          // JSON DOM (TJSONValue and descendants): use their inbuilt Clone
          if LCur.AsObject is TJSONValue then
          begin
            LNewObj := TJSONValue(LCur.AsObject).Clone;
            TValue.Make(@LNewObj, LCur.TypeInfo, Result);
            Exit;
          end;

          // Generic list?
          if IsListLikeType(LRType, LAddM, LElemTI) then
          begin
            LNewObj := CreateCollectionInstance(LRType);
            CopyOwnershipFlags(LCur.AsObject, LNewObj);
            TValue.Make(@LNewObj, LCur.TypeInfo, Result);
            AssignListLike(Result.AsObject, LCur.AsObject, LRType);
            Exit;
          end;

          // Generic dictionary?
          if IsDictionaryLikeType(LRType, LAddM, LKeyTI, LValTI, LGetEnumM) then
          begin
            LNewObj := CreateCollectionInstance(LRType);
            CopyOwnershipFlags(LCur.AsObject, LNewObj);
            TValue.Make(@LNewObj, LCur.TypeInfo, Result);
            AssignDictionaryLike(Result.AsObject, LCur.AsObject, LRType);
            Exit;
          end;

          // Regular DTO class
          Result := MakeInstanceForPopulate(LCur.TypeInfo);
          AssignObjectProps(Result.AsObject, LCur.AsObject, LRType);
          AssignObjectFields(Result.AsObject, LCur.AsObject, LRType);
          Exit;
        finally
          LCtx.Free;
        end;
      end;

    tkDynArray:
      Exit(CloneDynArray(LCur, LCur.TypeInfo));
  else
    // scalars/records/sets/enums: copy by value
    Exit(LCur);
  end;
end;

class procedure TValueUtils.AssignObjectProps(ADstObj, ASrcObj: TObject; const ADstType: TRttiType);
var
  LP: TRttiProperty;
  LSrcVal, LDstVal: TValue;
  LK: TTypeKind;
  LAddM: TRttiMethod;
  LElemTI, LKeyTI, LValTI: PTypeInfo;
  LGetEnum: TRttiMethod;
  LNewObj: TObject;
begin
  if (ADstObj = nil) or (ASrcObj = nil) then Exit;

  for LP in ADstType.GetProperties do
  begin
    if (LP.PropertyType = nil) or (not LP.IsWritable) then
      Continue;
    //if not (LP.Visibility in [mvPublic, mvPublished]) then
    //  Continue;

    try
      LSrcVal := LP.GetValue(ASrcObj);
    except
      Continue;
    end;

    LK := LP.PropertyType.Handle^.Kind;

    case LK of
      tkClass:
        begin
          if LSrcVal.IsEmpty or (LSrcVal.AsObject = nil) then
          begin
            LP.SetValue(ADstObj, TypedNil(LP.PropertyType.Handle));
            Continue;
          end;

          // list-like?
          if IsListLikeType(LP.PropertyType, LAddM, LElemTI) then
          begin
            LNewObj := CreateCollectionInstance(LP.PropertyType);
            CopyOwnershipFlags(LSrcVal.AsObject, LNewObj);
            TValue.Make(@LNewObj, LP.PropertyType.Handle, LDstVal);
            AssignListLike(LDstVal.AsObject, LSrcVal.AsObject, LP.PropertyType);
            LP.SetValue(ADstObj, LDstVal);
          end
          // dictionary-like?
          else if IsDictionaryLikeType(LP.PropertyType, LAddM, LKeyTI, LValTI, LGetEnum) then
          begin
            LNewObj := CreateCollectionInstance(LP.PropertyType);
            CopyOwnershipFlags(LSrcVal.AsObject, LNewObj);
            TValue.Make(@LNewObj, LP.PropertyType.Handle, LDstVal);
            AssignDictionaryLike(LDstVal.AsObject, LSrcVal.AsObject, LP.PropertyType);
            LP.SetValue(ADstObj, LDstVal);
          end
          else
          begin
            // nested DTO
            LDstVal := MakeInstanceForPopulate(LP.PropertyType.Handle);
            AssignValue(LDstVal, LSrcVal);
            LP.SetValue(ADstObj, LDstVal);
          end;
        end;

      tkDynArray:
        begin
          if not LSrcVal.IsEmpty then
            LDstVal := CloneDynArray(LSrcVal, LP.PropertyType.Handle)
          else
            LDstVal := LSrcVal;
          LP.SetValue(ADstObj, LDstVal);
        end;

    else
      // scalar/enum/set/record by value
      LP.SetValue(ADstObj, LSrcVal);
    end;
  end;
end;

class procedure TValueUtils.AssignObjectFields(ADstObj, ASrcObj: TObject; const ADstType: TRttiType);
var
  LF: TRttiField;
  LSrcVal, LDstVal: TValue;
begin
  if (ADstObj = nil) or (ASrcObj = nil) or (ADstType = nil) then Exit;

  for LF in ADstType.GetFields do
  begin
    // only instance fields; skip class vars and non-public
    if LF.FieldType = nil then
      Continue;
    //if not (LF.Visibility in [mvPublic, mvPublished]) then
    //  Continue;

    LSrcVal := LF.GetValue(ASrcObj);

    case LF.FieldType.Handle^.Kind of
      tkClass:
        begin
          if LSrcVal.IsEmpty or (LSrcVal.AsObject = nil) then
          begin
            LF.SetValue(ADstObj, TypedNil(LF.FieldType.Handle));
            Continue;
          end;

          // deep clone nested class
          LDstVal := MakeInstanceForPopulate(LF.FieldType.Handle);
          AssignValue(LDstVal, LSrcVal);
          LF.SetValue(ADstObj, LDstVal);
        end;

      tkDynArray:
        begin
          if not LSrcVal.IsEmpty then
            LDstVal := CloneDynArray(LSrcVal, LF.FieldType.Handle)
          else
            LDstVal := LSrcVal;
          LF.SetValue(ADstObj, LDstVal);
        end;

    else
      // scalar/enum/set/record by value
      LF.SetValue(ADstObj, LSrcVal);
    end;
  end;
end;

class procedure TValueUtils.AssignValue(var ADest: TValue; const ASrc: TValue);
var
  LCtx: TRttiContext;
  LDstType: TRttiType;
begin
  if ASrc.IsEmpty then Exit;

  // ensure destination object is instantiated
  if (ADest.Kind = tkClass) and (ADest.AsObject = nil) then
    ADest := MakeInstanceForPopulate(ADest.TypeInfo);

  case ADest.Kind of
    tkClass:
      begin
        if ASrc.Kind <> tkClass then Exit;
        LCtx := TRttiContext.Create;
        try
          LDstType := LCtx.GetType(ADest.TypeInfo);
          AssignObjectProps(ADest.AsObject, ASrc.AsObject, LDstType);
          AssignObjectFields(ADest.AsObject, ASrc.AsObject, LDstType);
        finally
          LCtx.Free;
        end;
      end;

    tkDynArray:
      ADest := CloneDynArray(ASrc, ADest.TypeInfo);

  else
    if (not ASrc.IsEmpty) and (ASrc.TypeInfo <> ADest.TypeInfo) then
      ADest := ASrc.Cast(ADest.TypeInfo)
    else
      ADest := ASrc;
  end;
end;

class function TValueUtils.CloneObjectToType(const ASource: TValue; ANativeType: PTypeInfo): TValue;
begin
  Result := MakeInstanceForPopulate(ANativeType);
  AssignValue(Result, ASource);
end;

class function TValueUtils.CloneValueList(const AParams: TList<TValue>): TList<TValue>;
var
  LV: TValue;
begin
  if not Assigned(AParams) then
    Exit(nil);
  Result := TList<TValue>.Create;
  for LV in AParams do
    Result.Add(CloneValue(LV));
end;

class function TValueUtils.UnwrapValue(const AValue: TValue): TValue;
const
  MAX_UNWRAPS = 4; // guard to avoid infinite unboxing loops
var
  LCur: TValue;
  LGuard: Integer;
begin
  LCur := AValue;
  LGuard := 0;

  // If the value itself is a boxed TValue, unwrap it.
  // Repeat a few times to handle accidental double/triple boxing.
  while LCur.IsType<TValue> do
  begin
    LCur := LCur.AsType<TValue>;
    Inc(LGuard);
    if LGuard >= MAX_UNWRAPS then
      Break; // safety guard
  end;

  Result := LCur;
end;

{=== Free helpers (records, pairs, containers) ===}

class procedure TValueUtils.FreeRecordFields(const ARecVal: TValue; const ASeen: TDictionary<Pointer, Byte>);
var
  LCtx: TRttiContext;
  LT: TRttiType;
  LF: TRttiField;
  LP: Pointer;
begin
  LCtx := TRttiContext.Create;
  try
    LT := LCtx.GetType(ARecVal.TypeInfo);
    if LT = nil then Exit;
    LP := ARecVal.GetReferenceToRawData;
    for LF in LT.GetFields do
      FreeValueTree(LF.GetValue(LP), ASeen);
  finally
    LCtx.Free;
  end;
end;

class procedure TValueUtils.FreePairKeyValue(const APairValue: TValue;
  const AFreeKey, AFreeVal: Boolean; const ASeen: TDictionary<Pointer, Byte>);
var
  LK, LV: TValue;
begin
  if APairValue.Kind <> tkRecord then Exit;
  if not ExtractPairKV(APairValue, LK, LV) then
    Exit;

  if AFreeKey then
    FreeValueTree(LK, ASeen);
  if AFreeVal then
    FreeValueTree(LV, ASeen);
end;

class procedure TValueUtils.DetectListOwnership(const AObj: TObject;
      out AOwnsItems, AHasOwnsProp: Boolean);
var
  LB: Boolean;
begin
  AOwnsItems := False;
  AHasOwnsProp := False;
  if TryGetBooleanProperty(AObj, SOwnsObjects, LB) then
  begin
    AHasOwnsProp := True;
    AOwnsItems := LB;
  end;
end;

class procedure TValueUtils.DetectDictOwnership(const AObj: TObject;
      out AOwnsKeys, AOwnsValues, AHasKeysProp, AHasValuesProp: Boolean);
var
  LB: Boolean;
begin
  AOwnsKeys := False;
  AOwnsValues := False;
  AHasKeysProp := False;
  AHasValuesProp := False;

  if TryGetBooleanProperty(AObj, SOwnsKeys, LB) then
  begin
    AHasKeysProp := True;
    AOwnsKeys := LB;
  end;

  if TryGetBooleanProperty(AObj, SOwnsValues, LB) then
  begin
    AHasValuesProp := True;
    AOwnsValues := LB;
  end;
end;

class function TValueUtils.HasAddWithArity(const AObj: TObject; const AArity: Integer): Boolean;
var
  LCtx: TRttiContext;
  LT: TRttiType;
  LMethod: TRttiMethod;
begin
  Result := False;
  if AObj = nil then Exit;

  LCtx := TRttiContext.Create;
  try
    LT := LCtx.GetType(AObj.ClassType);
    if LT = nil then Exit;
    for LMethod in LT.GetMethods do
      if (LMethod.Name = SAdd) and (Length(LMethod.GetParameters) = AArity) then
        Exit(True);
  finally
    LCtx.Free;
  end;
end;

class function TValueUtils.IsListLikeObject(const AObj: TObject): Boolean;
begin
  Result := HasAddWithArity(AObj, 1);
end;

class function TValueUtils.IsDictionaryLikeObject(const AObj: TObject): Boolean;
begin
  Result := HasAddWithArity(AObj, 2);
end;

class procedure TValueUtils.DrainList(const AObj: TObject; const ASeen: TDictionary<Pointer, Byte>);
var
  LCtx: TRttiContext;
  LRType: TRttiType;
  LEnumInfo: TEnumeratorInfo;
  LCurrVal: TValue;
begin
  if AObj = nil then Exit;

  LCtx := TRttiContext.Create;
  try
    LRType := LCtx.GetType(AObj.ClassType);
    LEnumInfo := GetEnumeratorInfo(LRType, AObj);
    if not LEnumInfo.IsValid then
      Exit;

    try
      while LEnumInfo.MoveNext.Invoke(LEnumInfo.EnumObject, []).AsBoolean do
      begin
        LCurrVal := LEnumInfo.GetCurrentValue;
        FreeValueTree(LCurrVal, ASeen);
      end;
    finally
      LEnumInfo.FreeEnumObject;
    end;
  finally
    LCtx.Free;
  end;
end;

class procedure TValueUtils.DrainDict(const AObj: TObject; const AFreeKeys, AFreeValues: Boolean;
  const ASeen: TDictionary<Pointer, Byte>);
var
  LCtx: TRttiContext;
  LRType: TRttiType;
  LEnumInfo: TEnumeratorInfo;
  LCurrVal: TValue;
begin
  if AObj = nil then Exit;

  LCtx := TRttiContext.Create;
  try
    LRType := LCtx.GetType(AObj.ClassType);
    LEnumInfo := GetEnumeratorInfo(LRType, AObj);
    if not LEnumInfo.IsValid then
      Exit;

    try
      while LEnumInfo.MoveNext.Invoke(LEnumInfo.EnumObject, []).AsBoolean do
      begin
        LCurrVal := LEnumInfo.GetCurrentValue;
        if LCurrVal.Kind = tkRecord then
          FreePairKeyValue(LCurrVal, AFreeKeys, AFreeValues, ASeen)
        else
          FreeValueTree(LCurrVal, ASeen);
      end;
    finally
      LEnumInfo.FreeEnumObject;
    end;
  finally
    LCtx.Free;
  end;
end;

class procedure TValueUtils.FreeValueTree(const AValue: TValue; const ASeen: TDictionary<Pointer, Byte>);
var
  LCur: TValue;
  LI, LN: Integer;
  LObj: TObject;
  LOwnsItems, LHasOwnsProp: Boolean;
  LOwnsKeys, LOwnsValues, LHasKeysProp, LHasValuesProp: Boolean;
  LCtx: TRttiContext;
  LRType: TRttiType;
  LEnumInfo: TEnumeratorInfo;
begin
  LCur := UnwrapValue(AValue);

  // Arrays
  if LCur.IsArray then
  begin
    LN := LCur.GetArrayLength;
    for LI := 0 to LN - 1 do
      FreeValueTree(LCur.GetArrayElement(LI), ASeen);
    Exit;
  end;

  // Records (generic): walk all fields
  if (LCur.Kind = tkRecord) then
  begin
    FreeRecordFields(LCur, ASeen);
    Exit;
  end;

  // Objects
  if LCur.IsObject then
  begin
    LObj := LCur.AsObject;
    if LObj = nil then Exit;
    if MarkVisited(LObj, ASeen) then Exit;

    // JSON DOM
    if LObj is TJSONValue then
    begin
      LObj.Free;
      Exit;
    end;

    // TObjectList<T>
    DetectListOwnership(LObj, LOwnsItems, LHasOwnsProp);
    if LHasOwnsProp then
    begin
      if LOwnsItems then
      begin
        LObj.Free;   // owns -> free container only
        Exit;
      end
      else
      begin
        DrainList(LObj, ASeen); // non-owning -> free items
        LObj.Free;             // then free container
        Exit;
      end;
    end;

    // TObjectDictionary<K,V>
    DetectDictOwnership(LObj, LOwnsKeys, LOwnsValues, LHasKeysProp, LHasValuesProp);
    if LHasKeysProp or LHasValuesProp then
    begin
      if (not LOwnsKeys) and (not LOwnsValues) then
      begin
        // both False -> free K & V, then container
        DrainDict(LObj, True, True, ASeen);
        LObj.Free;
        Exit;
      end
      else
      begin
        // owns one/both -> do NOT free owned sides; drain only non-owned, then container
        DrainDict(LObj, not LOwnsKeys, not LOwnsValues, ASeen);
        LObj.Free;
        Exit;
      end;
    end;

    // Regular list/dictionary
    if IsListLikeObject(LObj) then
    begin
      DrainList(LObj, ASeen);
      LObj.Free;
      Exit;
    end;

    if IsDictionaryLikeObject(LObj) then
    begin
      DrainDict(LObj, True, True, ASeen);
      LObj.Free;
      Exit;
    end;

    // Generic enumerable fallback
    LCtx := TRttiContext.Create;
    try
      LRType := LCtx.GetType(LObj.ClassType);
      LEnumInfo := GetEnumeratorInfo(LRType, LObj);
      if LEnumInfo.IsValid then
      try
        while LEnumInfo.MoveNext.Invoke(LEnumInfo.EnumObject, []).AsBoolean do
          FreeValueTree(LEnumInfo.GetCurrentValue, ASeen);
        LObj.Free;
        Exit;
      finally
        LEnumInfo.FreeEnumObject;
      end;
    finally
      LCtx.Free;
    end;

    // Plain DTO
    LObj.Free;
    Exit;
  end;

  // Non-object scalars/strings/etc.: nothing to free
end;

class procedure TValueUtils.FreeParameterInternal(const AParam: TValue; const ASeen: TDictionary<Pointer, Byte>);
begin
  if AParam.IsEmpty then Exit;
  FreeValueTree(AParam, ASeen);
end;

class procedure TValueUtils.FreeParameter(var AParam: TValue);
var
  LSeen: TDictionary<Pointer, Byte>;
begin
  if AParam.IsEmpty then Exit;
  LSeen := TDictionary<Pointer, Byte>.Create;
  try
    FreeParameterInternal(AParam, LSeen);
  finally
    LSeen.Free;
  end;
  AParam := TValue.Empty;
end;

class procedure TValueUtils.FreeParameters(var AParams: TList<TValue>);
var
  LI: Integer;
  LSeen: TDictionary<Pointer, Byte>;
  LV: TValue;
begin
  if not Assigned(AParams) then Exit;

  LSeen := TDictionary<Pointer, Byte>.Create;
  try
    for LI := 0 to AParams.Count - 1 do
    begin
      LV := AParams[LI];
      if not LV.IsEmpty then
        FreeParameterInternal(LV, LSeen);  // shared LSeen across all params
      AParams[LI] := TValue.Empty;
    end;
  finally
    LSeen.Free;
  end;

  AParams.Clear;
  AParams.Free;
end;

class procedure TValueUtils.FreeParameters(var AParams: TDictionary<string, TValue>);
var
  LSeen: TDictionary<Pointer, Byte>;
  LPair: TPair<string, TValue>;
begin
  if not Assigned(AParams) then Exit;

  LSeen := TDictionary<Pointer, Byte>.Create;
  try
    for LPair in AParams do
      FreeParameterInternal(LPair.Value, LSeen);
  finally
    LSeen.Free;
  end;

  AParams.Clear;
  AParams.Free;
end;

class function TValueUtils.ToStringExtended(const AValue: TValue): string;

  // try to recover implementing object from an interface
  function BackingObjectFromInterface(const AIntf: IInterface): TObject;
  var
    LUnknown: IInterface;
  begin
    Result := nil;
    if AIntf = nil then
      Exit;

    // If the interface is from a class implementing IInterface
    if AIntf.QueryInterface(IInterface, LUnknown) = S_OK then
    begin
      // Safe: this only works if it’s a class implementing IInterface
      if TObject(LUnknown) is TObject then
        Result := TObject(LUnknown);
    end;
  end;

var
  LU: TValue;
  LObj: TObject;
  LIntf: IInterface;
begin
  // Handle empty/nil: calling .ToString on null would NRE,
  // but since we're formatting, return '' for nil references.
  if AValue.IsEmpty then
    Exit('');

  // Unwrap boxed TValue
  LU := UnwrapValue(AValue);

  case LU.Kind of
    tkClass:
      begin
        LObj := LU.AsObject;
        if LObj = nil then
          Exit('');
        Exit(LObj.ToString);  // honors overrides
      end;

    tkInterface:
      begin
        LIntf := LU.AsInterface;
        LObj := BackingObjectFromInterface(LIntf);
        if LObj <> nil then
          Exit(LObj.ToString)  // call the implementing object's ToString
        else
          // Fallback: interface type name
          Exit(GetTypeName(LU.TypeInfo));
      end;

    tkUString, tkWString, tkLString, tkString:
      Exit(LU.AsString);

  else
    // For numerics, enums, sets, records, etc., use TValue.ToString
    Exit(LU.ToString);
  end;
end;

end.

