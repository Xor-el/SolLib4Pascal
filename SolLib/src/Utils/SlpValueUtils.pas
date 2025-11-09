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

unit SlpValueUtils;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  System.JSON;

type
  TValueUtils = class sealed
  private
    class function NewContainerInstanceRequireCtor(const AType: TRttiType): TObject; static;

    { detection }
    class function IsListLikeType(const RType: TRttiType;
      out AddMethod: TRttiMethod; out ElemType: PTypeInfo): Boolean; static;

    class function IsDictionaryLikeType(const RType: TRttiType;
      out AddMethod: TRttiMethod; out KeyType, ValType: PTypeInfo;
      out GetEnum: TRttiMethod): Boolean; static;

    { enumeration & helpers }
    class function GetEnumeratorTriple(const RType: TRttiType; const AInstance: TObject;
      out EnumObj: TObject; out MoveNext: TRttiMethod; out CurrentGetter: TRttiProperty): Boolean; static;

    class function ExtractPairKV(const PairValue: TValue; out Key, Val: TValue): Boolean; static;

    { assign/clone primitives }
    class procedure AssignObjectProps(ADstObj, ASrcObj: TObject; const ADstType: TRttiType); static;
    class procedure AssignObjectFields(ADstObj, ASrcObj: TObject; const ADstType: TRttiType); static;
    class procedure AssignListLike(ADstList, ASrcList: TObject; const AListType: TRttiType); static;
    class procedure AssignDictionaryLike(ADstDict, ASrcDict: TObject; const ADictType: TRttiType); static;
    class function CloneDynArray(const ASrc: TValue; ATypeInfo: PTypeInfo): TValue; static;

    { ownership flags for TObjectList / TObjectDictionary }
    class procedure CopyOwnershipFlags(const SrcObj, DstObj: TObject); static;

    class procedure FreeParamCore(const AParam: TValue; const Seen: TDictionary<Pointer, Byte>); static;

  public
    /// Deep-clone a TValue (DTOs, dyn arrays, generic lists/dictionaries supported).
    class function CloneValue(const V: TValue): TValue; static;

    /// Assign ASrc into ADest (recursively). Instantiates ADest as needed.
    class procedure AssignValue(var ADest: TValue; const ASrc: TValue); static;

    /// Create a new instance of ANativeType and copy/morph ASource into it.
    class function CloneObjectToType(const ASource: TValue; ANativeType: PTypeInfo): TValue; static;

    /// <summary>
    /// Creates an instance of the given class type for population.
    /// - Prefers a parameterless constructor if available.
    /// - Falls back to raw allocation for DTOs with no constructor.
    /// </summary>
    class function MakeInstanceForPopulate(ANativeType: PTypeInfo): TValue; static;

    class function CloneValueList(const AParams: TList<TValue>): TList<TValue>; static;

    class function UnwrapValue(const AValue: TValue): TValue; static;

        // Recursively frees anything reachable from AParam that is a class instance.
    // - Arrays: recurse elements
    // - JSON DOM (TJSONValue): free the root (children go with it)
    // - Generic containers (lists/dictionaries via GetEnumerator):
    //     * Recurse into yielded items (TPair<K,V> → both Key & Value)
    //     * TObjectList<T>  : free container only if OwnsObjects=True
    //     * TObjectDictionary<K,V> : free container only if (OwnsKeys or OwnsValues)=True
    //     * If enumerator Current type is TValue, after draining we free the container
    //     * If ownership is unknown and not TValue items → do NOT free container
    class procedure FreeParameter(var AParam: TValue); static;
    class procedure FreeParameters(var AParams: TList<TValue>); overload; static;
    class procedure FreeParameters(var AParams: TDictionary<string, TValue>); overload; static;

    class function ToStringExtended(const V: TValue): string; static;
  end;

implementation

const
  SKey = 'Key';
  SValue = 'Value';
  SAdd = 'Add';

{ TValueUtils }

function TypedNil(ATypeInfo: PTypeInfo): TValue;
begin
  if ATypeInfo = nil then
    Exit(TValue.Empty);
  Result := TValue.From<TObject>(nil);
  Result := Result.Cast(ATypeInfo);
end;

class function TValueUtils.MakeInstanceForPopulate(ANativeType: PTypeInfo): TValue;
var
  Ctx: TRttiContext;
  RType: TRttiType;
  InstT: TRttiInstanceType;
  M, Ctor: TRttiMethod;
  Obj: TObject;
begin
  Result := TValue.Empty;

  if (ANativeType = nil) or (ANativeType^.Kind <> tkClass) then
    Exit;

  Ctx := TRttiContext.Create;
  try
    RType := Ctx.GetType(ANativeType);
    if not (RType is TRttiInstanceType) then
      Exit;

    InstT := TRttiInstanceType(RType);

    // 1) Prefer a parameterless "Create" constructor
    Ctor := nil;
    for M in InstT.GetMethods do
      if (M.MethodKind = mkConstructor) and SameText(M.Name, 'Create') and
         (Length(M.GetParameters) = 0) then
      begin
        Ctor := M;
        Break;
      end;

    if Assigned(Ctor) then
      Result := Ctor.Invoke(InstT.MetaclassType, [])
    else
    begin
      // 2) Fallback allocation without running constructors
      Obj := InstT.MetaclassType.NewInstance;
      TValue.Make(@Obj, ANativeType, Result);
    end;
  finally
    Ctx.Free;
  end;
end;

class function TValueUtils.NewContainerInstanceRequireCtor(const AType: TRttiType): TObject;
var
  InstT: TRttiInstanceType;
  M, Ctor: TRttiMethod;
begin
  Result := nil;
  if not (AType is TRttiInstanceType) then Exit;

  InstT := TRttiInstanceType(AType);
  Ctor := nil;
  for M in InstT.GetMethods do
    if (M.MethodKind = mkConstructor) and SameText(M.Name, 'Create') and
       (Length(M.GetParameters) = 0) then
    begin
      Ctor := M; Break;
    end;

  if not Assigned(Ctor) then
    raise EInvalidOp.CreateFmt('Type %s requires a parameterless Create constructor.',
      [AType.QualifiedName]);

  Result := Ctor.Invoke(InstT.MetaclassType, []).AsObject;
end;

{=== Detection ===}

class function TValueUtils.IsListLikeType(const RType: TRttiType;
  out AddMethod: TRttiMethod; out ElemType: PTypeInfo): Boolean;
var
  M: TRttiMethod;
  Params: TArray<TRttiParameter>;
begin
  Result := False;
  AddMethod := nil;
  ElemType := nil;
  for M in RType.GetMethods do
    if (M.Name = 'Add') and (M.MethodKind in [mkProcedure, mkFunction]) then
    begin
      Params := M.GetParameters;
      if Length(Params) = 1 then
      begin
        AddMethod := M;
        ElemType := Params[0].ParamType.Handle;
        Exit(True);
      end;
    end;
end;

class function TValueUtils.IsDictionaryLikeType(const RType: TRttiType;
  out AddMethod: TRttiMethod; out KeyType, ValType: PTypeInfo;
  out GetEnum: TRttiMethod): Boolean;
var
  M: TRttiMethod;
  Params: TArray<TRttiParameter>;
begin
  AddMethod := nil;
  KeyType := nil;
  ValType := nil;
  GetEnum := nil;

  for M in RType.GetMethods do
  begin
    if (M.Name = 'Add') and (M.MethodKind in [mkProcedure, mkFunction]) then
    begin
      Params := M.GetParameters;
      if Length(Params) = 2 then
      begin
        AddMethod := M;
        KeyType := Params[0].ParamType.Handle;
        ValType := Params[1].ParamType.Handle;
      end;
    end
    else if (M.Name = 'GetEnumerator') and (Length(M.GetParameters) = 0) then
      GetEnum := M;
  end;

  Result := Assigned(AddMethod) and Assigned(GetEnum);
end;

{=== Enumeration helpers ===}

class function TValueUtils.GetEnumeratorTriple(const RType: TRttiType; const AInstance: TObject;
  out EnumObj: TObject; out MoveNext: TRttiMethod; out CurrentGetter: TRttiProperty): Boolean;
var
  Ctx: TRttiContext;
  EnumT: TRttiType;
  GetEnum: TRttiMethod;
  LocalEnum: TObject;
begin
  Result := False;
  EnumObj := nil;
  MoveNext := nil;
  CurrentGetter := nil;

  if (RType = nil) or (AInstance = nil) then
    Exit;

  GetEnum := RType.GetMethod('GetEnumerator');
  if GetEnum = nil then
    Exit;

  LocalEnum := GetEnum.Invoke(AInstance, []).AsObject;
  if LocalEnum = nil then
    Exit;

  Ctx := TRttiContext.Create;
  try
    EnumT := Ctx.GetType(LocalEnum.ClassType);
    if EnumT <> nil then
    begin
      MoveNext := EnumT.GetMethod('MoveNext');
      CurrentGetter := EnumT.GetProperty('Current');
      if Assigned(MoveNext) and Assigned(CurrentGetter) then
      begin
        // success: transfer ownership to caller
        EnumObj := LocalEnum;
        LocalEnum := nil;
        Result := True;
      end;
    end;
  finally
    Ctx.Free;
    if Assigned(LocalEnum) then
      LocalEnum.Free;
  end;
end;

class function TValueUtils.ExtractPairKV(const PairValue: TValue; out Key, Val: TValue): Boolean;
var
  Ctx: TRttiContext;
  PairT: TRttiType;
  PropKey, PropVal: TRttiProperty;
  FieldKey, FieldVal: TRttiField;
  PData: Pointer;
begin
  Result := False;
  Key := TValue.Empty;
  Val := TValue.Empty;

  if PairValue.IsEmpty or (PairValue.Kind <> tkRecord) then Exit;

  Ctx := TRttiContext.Create;
  try
    PairT := Ctx.GetType(PairValue.TypeInfo);

    // prefer properties
    PropKey := PairT.GetProperty(SKey);
    PropVal := PairT.GetProperty(SValue);
    if Assigned(PropKey) and Assigned(PropVal) then
    begin
      Key := PropKey.GetValue(PairValue.GetReferenceToRawData);
      Val := PropVal.GetValue(PairValue.GetReferenceToRawData);
      Exit(True);
    end;

    // fallback to fields
    FieldKey := PairT.GetField(SKey);
    FieldVal := PairT.GetField(SValue);
    if Assigned(FieldKey) and Assigned(FieldVal) then
    begin
      PData := PairValue.GetReferenceToRawData;
      Key := FieldKey.GetValue(PData);
      Val := FieldVal.GetValue(PData);
      Exit(True);
    end;
  finally
    Ctx.Free;
  end;
end;

{=== Assign / Clone primitives ===}

class procedure TValueUtils.AssignListLike(ADstList, ASrcList: TObject; const AListType: TRttiType);
var
  AddM: TRttiMethod;
  ElemTI: PTypeInfo;
  EnumObj: TObject;
  MoveNext: TRttiMethod;
  Current: TRttiProperty;
  Cur, ToAdd: TValue;
begin
  if (ADstList = nil) or (ASrcList = nil) then Exit;
  if not IsListLikeType(AListType, AddM, ElemTI) then Exit;
  if not GetEnumeratorTriple(AListType, ASrcList, EnumObj, MoveNext, Current) then Exit;

  try
    while MoveNext.Invoke(EnumObj, []).AsBoolean do
    begin
      Cur := Current.GetValue(EnumObj);
      ToAdd := CloneValue(Cur);
      if Assigned(ElemTI) and (not ToAdd.IsEmpty) and (ToAdd.TypeInfo <> ElemTI) then
        ToAdd := ToAdd.Cast(ElemTI);
      AddM.Invoke(ADstList, [ToAdd]);
    end;
  finally
    EnumObj.Free; // ensure no leak
  end;
end;

class procedure TValueUtils.AssignDictionaryLike(ADstDict, ASrcDict: TObject; const ADictType: TRttiType);
var
  AddM, GetEnumM: TRttiMethod;
  KeyTI, ValTI: PTypeInfo;
  EnumObj: TObject;
  MoveNext: TRttiMethod;
  Current: TRttiProperty;
  Pair, K, V, CK, CV: TValue;
begin
  if (ADstDict = nil) or (ASrcDict = nil) then Exit;
  if not IsDictionaryLikeType(ADictType, AddM, KeyTI, ValTI, GetEnumM) then Exit;
  if not GetEnumeratorTriple(ADictType, ASrcDict, EnumObj, MoveNext, Current) then Exit;

  try
    while MoveNext.Invoke(EnumObj, []).AsBoolean do
    begin
      Pair := Current.GetValue(EnumObj);
      if not ExtractPairKV(Pair, K, V) then
        raise EInvalidOp.Create('Enumerator Current is not a TPair<K,V>.');

      CK := CloneValue(K);
      CV := CloneValue(V);

      if Assigned(KeyTI) and (not CK.IsEmpty) and (CK.TypeInfo <> KeyTI) then
        CK := CK.Cast(KeyTI);
      if Assigned(ValTI) and (not CV.IsEmpty) and (CV.TypeInfo <> ValTI) then
        CV := CV.Cast(ValTI);

      AddM.Invoke(ADstDict, [CK, CV]);
    end;
  finally
    EnumObj.Free;
  end;
end;

class function TValueUtils.CloneDynArray(const ASrc: TValue; ATypeInfo: PTypeInfo): TValue;
var
  Ctx: TRttiContext;
  ArrT: TRttiDynamicArrayType;
  ElemTI: PTypeInfo;
  Len, I: Integer;
  Elem, Cloned: TValue;
  Temp: TArray<TValue>;
begin
  Result := TValue.Empty;
  if (ATypeInfo = nil) or (ATypeInfo^.Kind <> tkDynArray) or ASrc.IsEmpty then Exit;

  Ctx := TRttiContext.Create;
  try
    ArrT := Ctx.GetType(ATypeInfo) as TRttiDynamicArrayType;
    if ArrT = nil then Exit;

    ElemTI := nil;
    if Assigned(ArrT.ElementType) then
      ElemTI := ArrT.ElementType.Handle;

    Len := ASrc.GetArrayLength;
    SetLength(Temp, Len);

    for I := 0 to Len - 1 do
    begin
      Elem   := ASrc.GetArrayElement(I);
      Cloned := CloneValue(Elem);

      // Ensure typed value compatible with ElemTI, including nils
      if Assigned(ElemTI) then
      begin
        if Cloned.IsEmpty then
          Cloned := TypedNil(ElemTI)
        else if Cloned.TypeInfo <> ElemTI then
          Cloned := Cloned.Cast(ElemTI);
      end;

      Temp[I] := Cloned;
    end;

    Result := TValue.FromArray(ATypeInfo, Temp);
  finally
    Ctx.Free;
  end;
end;

{=== Ownership flags ===}

class procedure TValueUtils.CopyOwnershipFlags(const SrcObj, DstObj: TObject);
var
  Ctx: TRttiContext;
  SrcT, DstT: TRttiType;
  PSrc, PDst: TRttiProperty;
  V: TValue;
begin
  if (SrcObj = nil) or (DstObj = nil) then Exit;

  Ctx := TRttiContext.Create;
  try
    SrcT := Ctx.GetType(SrcObj.ClassType);
    DstT := Ctx.GetType(DstObj.ClassType);

    // TObjectList<T> : OwnsObjects: Boolean
    PSrc := SrcT.GetProperty('OwnsObjects');
    PDst := DstT.GetProperty('OwnsObjects');
    if Assigned(PSrc) and PSrc.IsReadable and Assigned(PDst) and PDst.IsWritable then
    begin
      V := PSrc.GetValue(SrcObj);
      PDst.SetValue(DstObj, V);
    end;

    // TObjectDictionary<TKey,TValue> : Ownerships: set; or OwnsKeys/OwnsValues
    PSrc := SrcT.GetProperty('Ownerships');
    PDst := DstT.GetProperty('Ownerships');
    if Assigned(PSrc) and PSrc.IsReadable and Assigned(PDst) and PDst.IsWritable then
    begin
      V := PSrc.GetValue(SrcObj);
      PDst.SetValue(DstObj, V);
    end
    else
    begin
      PSrc := SrcT.GetProperty('OwnsKeys');
      PDst := DstT.GetProperty('OwnsKeys');
      if Assigned(PSrc) and PSrc.IsReadable and Assigned(PDst) and PDst.IsWritable then
      begin
        V := PSrc.GetValue(SrcObj);
        PDst.SetValue(DstObj, V);
      end;

      PSrc := SrcT.GetProperty('OwnsValues');
      PDst := DstT.GetProperty('OwnsValues');
      if Assigned(PSrc) and PSrc.IsReadable and Assigned(PDst) and PDst.IsWritable then
      begin
        V := PSrc.GetValue(SrcObj);
        PDst.SetValue(DstObj, V);
      end;
    end;
  finally
    Ctx.Free;
  end;
end;

{=== Public API ===}

class function TValueUtils.CloneValue(const V: TValue): TValue;
var
  Ctx: TRttiContext;
  RType: TRttiType;
  AddM: TRttiMethod;
  ElemTI, KeyTI, ValTI: PTypeInfo;
  GetEnumM: TRttiMethod;
  NewObj: TObject;
  Cur: TValue;
begin
  if V.IsEmpty then
    Exit(TypedNil(V.TypeInfo));

  Cur := UnwrapValue(V);

  case Cur.Kind of
    tkClass:
      begin
        if Cur.AsObject = nil then
          Exit(TypedNil(Cur.TypeInfo));

        Ctx := TRttiContext.Create;
        try
          RType := Ctx.GetType(Cur.TypeInfo);

          // JSON DOM (TJSONValue and descendants): use their inbuilt Clone
          if Cur.AsObject is TJSONValue then
          begin
            NewObj := TJSONValue(Cur.AsObject).Clone;
            TValue.Make(@NewObj, Cur.TypeInfo, Result);
            Exit;
          end;

          // Generic list?
          if IsListLikeType(RType, AddM, ElemTI) then
          begin
            NewObj := NewContainerInstanceRequireCtor(RType);
            CopyOwnershipFlags(Cur.AsObject, NewObj);
            TValue.Make(@NewObj, Cur.TypeInfo, Result);
            AssignListLike(Result.AsObject, Cur.AsObject, RType);
            Exit;
          end;

          // Generic dictionary?
          if IsDictionaryLikeType(RType, AddM, KeyTI, ValTI, GetEnumM) then
          begin
            NewObj := NewContainerInstanceRequireCtor(RType);
            CopyOwnershipFlags(Cur.AsObject, NewObj);
            TValue.Make(@NewObj, Cur.TypeInfo, Result);
            AssignDictionaryLike(Result.AsObject, Cur.AsObject, RType);
            Exit;
          end;

          // Regular DTO class
          Result := MakeInstanceForPopulate(Cur.TypeInfo);
          AssignObjectProps(Result.AsObject, Cur.AsObject, RType);
          AssignObjectFields(Result.AsObject, Cur.AsObject, RType);
          Exit;
        finally
          Ctx.Free;
        end;
      end;

    tkDynArray:
      Exit(CloneDynArray(Cur, Cur.TypeInfo));
  else
    // scalars/records/sets/enums: copy by value
    Exit(Cur);
  end;
end;

class procedure TValueUtils.AssignObjectProps(ADstObj, ASrcObj: TObject; const ADstType: TRttiType);
var
  P: TRttiProperty;
  SrcVal, DstVal: TValue;
  K: TTypeKind;
  AddM: TRttiMethod;
  ElemTI, KeyTI, ValTI: PTypeInfo;
  GetEnum: TRttiMethod;
  NewObj: TObject;
begin
  if (ADstObj = nil) or (ASrcObj = nil) then Exit;

  for P in ADstType.GetProperties do
  begin
    if (P.PropertyType = nil) or (not P.IsWritable) then
      Continue;
    if not (P.Visibility in [mvPublic, mvPublished]) then
      Continue;

    try
      SrcVal := P.GetValue(ASrcObj);
    except
      Continue;
    end;

    K := P.PropertyType.Handle^.Kind;

    case K of
      tkClass:
        begin
          if SrcVal.IsEmpty or (SrcVal.AsObject = nil) then
          begin
            P.SetValue(ADstObj, TypedNil(P.PropertyType.Handle));
            Continue;
          end;

          // list-like?
          if IsListLikeType(P.PropertyType, AddM, ElemTI) then
          begin
            NewObj := NewContainerInstanceRequireCtor(P.PropertyType);
            CopyOwnershipFlags(SrcVal.AsObject, NewObj);
            TValue.Make(@NewObj, P.PropertyType.Handle, DstVal);
            AssignListLike(DstVal.AsObject, SrcVal.AsObject, P.PropertyType);
            P.SetValue(ADstObj, DstVal);
          end
          // dictionary-like?
          else if IsDictionaryLikeType(P.PropertyType, AddM, KeyTI, ValTI, GetEnum) then
          begin
            NewObj := NewContainerInstanceRequireCtor(P.PropertyType);
            CopyOwnershipFlags(SrcVal.AsObject, NewObj);
            TValue.Make(@NewObj, P.PropertyType.Handle, DstVal);
            AssignDictionaryLike(DstVal.AsObject, SrcVal.AsObject, P.PropertyType);
            P.SetValue(ADstObj, DstVal);
          end
          else
          begin
            // nested DTO
            DstVal := MakeInstanceForPopulate(P.PropertyType.Handle);
            AssignValue(DstVal, SrcVal);
            P.SetValue(ADstObj, DstVal);
          end;
        end;

      tkDynArray:
        begin
          if not SrcVal.IsEmpty then
            DstVal := CloneDynArray(SrcVal, P.PropertyType.Handle)
          else
            DstVal := SrcVal;
          P.SetValue(ADstObj, DstVal);
        end;

    else
      // scalar/enum/set/record by value
      P.SetValue(ADstObj, SrcVal);
    end;
  end;
end;

class procedure TValueUtils.AssignObjectFields(ADstObj, ASrcObj: TObject; const ADstType: TRttiType);
var
  F: TRttiField;
  SrcVal, DstVal: TValue;
begin
  if (ADstObj = nil) or (ASrcObj = nil) or (ADstType = nil) then Exit;

  for F in ADstType.GetFields do
  begin
    // only instance fields; skip class vars and non-public
    if F.FieldType = nil then
      Continue;
    //if not (F.Visibility in [mvPublic, mvPublished]) then
      //Continue;

    SrcVal := F.GetValue(ASrcObj);

    case F.FieldType.Handle^.Kind of
      tkClass:
        begin
          if SrcVal.IsEmpty or (SrcVal.AsObject = nil) then
          begin
            F.SetValue(ADstObj, TypedNil(F.FieldType.Handle));
            Continue;
          end;

          // deep clone nested class
          DstVal := MakeInstanceForPopulate(F.FieldType.Handle);
          AssignValue(DstVal, SrcVal);
          F.SetValue(ADstObj, DstVal);
        end;

      tkDynArray:
        begin
          if not SrcVal.IsEmpty then
            DstVal := CloneDynArray(SrcVal, F.FieldType.Handle)
          else
            DstVal := SrcVal;
          F.SetValue(ADstObj, DstVal);
        end;

      else
        // scalar/enum/set/record by value
        F.SetValue(ADstObj, SrcVal);
    end;
  end;
end;


class procedure TValueUtils.AssignValue(var ADest: TValue; const ASrc: TValue);
var
  Ctx: TRttiContext;
  DstType: TRttiType;
begin
  if ASrc.IsEmpty then Exit;

  // ensure destination object is instantiated
  if (ADest.Kind = tkClass) and (ADest.AsObject = nil) then
    ADest := MakeInstanceForPopulate(ADest.TypeInfo);

  case ADest.Kind of
    tkClass:
      begin
        if ASrc.Kind <> tkClass then Exit;
        Ctx := TRttiContext.Create;
        try
          DstType := Ctx.GetType(ADest.TypeInfo);
          AssignObjectProps(ADest.AsObject, ASrc.AsObject, DstType);
          AssignObjectFields(ADest.AsObject, ASrc.AsObject, DstType);
        finally
          Ctx.Free;
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
  V: TValue;
begin
  if not Assigned(AParams) then
    Exit(nil);
  Result := TList<TValue>.Create;
  for V in AParams do
    Result.Add(CloneValue(V));
end;

class function TValueUtils.UnwrapValue(const AValue: TValue): TValue;
const
  MAX_UNWRAPS = 4;
var
  Cur: TValue;
  Guard: Integer;
begin
  Cur := AValue;
  Guard := 0;

  // If the value itself is a boxed TValue, unwrap it.
  // Repeat a few times to handle accidental double/triple boxing.
  while Cur.IsType<TValue> do
  begin
    Cur := Cur.AsType<TValue>;
    Inc(Guard);
    if Guard >= MAX_UNWRAPS then
      Break; // safety guard
  end;

  Result := Cur;
end;

class procedure TValueUtils.FreeParamCore(const AParam: TValue; const Seen: TDictionary<Pointer, Byte>);

  function MarkVisited(const Ptr: Pointer): Boolean;
  begin
    if Ptr = nil then Exit(False);
    Result := Seen.ContainsKey(Ptr);
    if not Result then Seen.Add(Ptr, 0);
  end;

  function TryGetBoolProp(const Obj: TObject; const PropName: string;
    out B: Boolean; out Known: Boolean): Boolean;
  var
    Ctx: TRttiContext; T: TRttiType; P: TRttiProperty; V: TValue;
  begin
    Result := False; Known := False; B := False;
    Ctx := TRttiContext.Create;
    try
      T := Ctx.GetType(Obj.ClassType);
      if T = nil then Exit(False);
      P := T.GetProperty(PropName);
      if (P <> nil) and P.IsReadable and (P.PropertyType <> nil) and
         (P.PropertyType.Handle = TypeInfo(Boolean)) then
      begin
        Known := True;
        V := P.GetValue(Obj);
        B := V.AsBoolean;
        Exit(True);
      end;
    finally
      Ctx.Free;
    end;
  end;

  function SafeGetType(const Ctx: TRttiContext; const Obj: TObject): TRttiType;
  begin
    if Obj = nil then Exit(nil);
    Result := Ctx.GetType(Obj.ClassType);
  end;

  // Detect generic list-like: an Add with 1 parameter
  // Helper: check if type has an 'Add' method with a given arity
  function HasAddWithArity(const Obj: TObject; const Arity: Integer): Boolean;
  var
    Ctx: TRttiContext; T: TRttiType; M: TRttiMethod;
  begin
    if Obj = nil then Exit(False);
    Result := False;
    Ctx := TRttiContext.Create;
    try
      T := SafeGetType(Ctx, Obj);
      if T = nil then Exit(False);
      for M in T.GetMethods do
        if (M.Name = SAdd) and (Length(M.GetParameters) = Arity) then
          Exit(True);
    finally
      Ctx.Free;
    end;
  end;

  function IsListLike(const Obj: TObject): Boolean;
  begin
    if Obj = nil then Exit(False);
    Result := HasAddWithArity(Obj, 1);

  end;

  // Detect dictionary-like: an Add with 2 parameters
  function IsDictionaryLike(const Obj: TObject): Boolean;
  begin
    if Obj = nil then Exit(False);
    Result := HasAddWithArity(Obj, 2);

  end;

  procedure ProbeListOwnership(const Obj: TObject; out OwnsItems, HasProp: Boolean);
  begin
    OwnsItems := False; HasProp := False;
    TryGetBoolProp(Obj, 'OwnsObjects', OwnsItems, HasProp);
  end;

  procedure ProbeDictOwnership(const Obj: TObject;
                               out OwnsKeys, OwnsValues, HasKeysProp, HasValuesProp: Boolean);
  begin
    OwnsKeys := False; OwnsValues := False;
    HasKeysProp := False; HasValuesProp := False;
    TryGetBoolProp(Obj, 'OwnsKeys',   OwnsKeys,   HasKeysProp);
    TryGetBoolProp(Obj, 'OwnsValues', OwnsValues, HasValuesProp);
  end;

  // Enumerator lookup: supports Current as PROPERTY or FIELD
  function GetEnumeratorQuad(const RType: TRttiType; const Inst: TObject;
    out EnumObj: TObject; out MoveNext: TRttiMethod; out CurrentProp: TRttiProperty; out CurrentField: TRttiField): Boolean;
  var
    GetEnum: TRttiMethod; Ctx: TRttiContext; EnumT: TRttiType;
  begin
    Result := False;
    EnumObj := nil; MoveNext := nil; CurrentProp := nil; CurrentField := nil;
    if (RType = nil) or (Inst = nil) then Exit;
    GetEnum := RType.GetMethod('GetEnumerator');
    if GetEnum = nil then Exit;

    EnumObj := GetEnum.Invoke(Inst, []).AsObject;
    if EnumObj = nil then Exit;

    Ctx := TRttiContext.Create;
    try
      EnumT := Ctx.GetType(EnumObj.ClassType);
      if EnumT <> nil then
      begin
        MoveNext    := EnumT.GetMethod('MoveNext');
        CurrentProp := EnumT.GetProperty('Current');
        if CurrentProp = nil then
          CurrentField := EnumT.GetField('Current');
        Result := Assigned(MoveNext) and (Assigned(CurrentProp) or Assigned(CurrentField));
      end;
      if not Result then
        EnumObj.Free;
    finally
      Ctx.Free;
    end;
  end;

  function GetCurrentValue(const EnumObj: TObject; const CurrentProp: TRttiProperty; const CurrentField: TRttiField): TValue;
  begin
    if Assigned(CurrentProp) then Exit(CurrentProp.GetValue(EnumObj));
    if Assigned(CurrentField) then Exit(CurrentField.GetValue(EnumObj));
    Result := TValue.Empty;
  end;

function TryGetProp(const T: TRttiType; const Name: string; out P: TRttiProperty): Boolean;
begin
  P := T.GetProperty(Name);
  Result := Assigned(P);
end;

function TryGetCurrentValue(EnumObj: TObject; CurProp: TRttiProperty; CurField: TRttiField; out V: TValue): Boolean;
begin
  if (CurProp = nil) and (CurField = nil) then Exit(False);
  V := GetCurrentValue(EnumObj, CurProp, CurField);
  Result := True;
end;

function TryGetField(const T: TRttiType; const Name: string; out F: TRttiField): Boolean;
begin
  F := T.GetField(Name);
  Result := Assigned(F);
end;

  procedure FreePairKV(const PairValue: TValue; const FreeKey, FreeVal: Boolean);
  var
    Ctx: TRttiContext; T: TRttiType;
    Pk, Pv: TRttiProperty; Fk, Fv: TRttiField;
    K, V: TValue;
  begin
    if PairValue.Kind <> tkRecord then Exit;
    Ctx := TRttiContext.Create;
    try
      T := Ctx.GetType(PairValue.TypeInfo);
      if TryGetProp(T, SKey, Pk) and TryGetProp(T, SValue, Pv) then
      if TryGetProp(T, SKey, Pk) and TryGetProp(T, SValue, Pv) then
      begin
        if FreeKey then begin K := Pk.GetValue(PairValue.GetReferenceToRawData); FreeParamCore(K, Seen); end;
        if FreeVal then begin V := Pv.GetValue(PairValue.GetReferenceToRawData); FreeParamCore(V, Seen); end;
        Exit;
      end;
      if TryGetField(T, SKey, Fk) and TryGetField(T, SValue, Fv) then
      if TryGetField(T, SKey, Fk) and TryGetField(T, SValue, Fv) then
      begin
        if FreeKey then begin K := Fk.GetValue(PairValue.GetReferenceToRawData); FreeParamCore(K, Seen); end;
        if FreeVal then begin V := Fv.GetValue(PairValue.GetReferenceToRawData); FreeParamCore(V, Seen); end;
      end;
    finally
      Ctx.Free;
    end;

  end;

  procedure DrainList(const Obj: TObject);
  var
    Ctx: TRttiContext; RType: TRttiType; EnumObj: TObject;
    MoveNext: TRttiMethod; CurProp: TRttiProperty; CurField: TRttiField;
    CurrVal: TValue;
  begin
    Ctx := TRttiContext.Create;
    try
      RType := SafeGetType(Ctx, Obj);
      EnumObj := nil;
      if GetEnumeratorQuad(RType, Obj, EnumObj, MoveNext, CurProp, CurField) then      {$IFDEF DEBUG} Assert(Assigned(MoveNext)); {$ENDIF}

      try
        while MoveNext.Invoke(EnumObj, []).AsBoolean do
        begin
          if TryGetCurrentValue(EnumObj, CurProp, CurField, CurrVal) then
          begin
            FreeParamCore(CurrVal, Seen);
          end;
        end;
      finally
        EnumObj.Free;
      end;
    finally
      Ctx.Free;
    end;
  end;

  procedure DrainDict(const Obj: TObject; const FreeKeys, FreeValues: Boolean);
  var
    Ctx: TRttiContext; RType: TRttiType; EnumObj: TObject;
    MoveNext: TRttiMethod; CurProp: TRttiProperty; CurField: TRttiField;
    CurrVal: TValue;
  begin
    Ctx := TRttiContext.Create;
    try
      RType := SafeGetType(Ctx, Obj);
      EnumObj := nil;
      if GetEnumeratorQuad(RType, Obj, EnumObj, MoveNext, CurProp, CurField) then      {$IFDEF DEBUG} Assert(Assigned(MoveNext)); {$ENDIF}

      try
        while MoveNext.Invoke(EnumObj, []).AsBoolean do
        begin
          CurrVal := GetCurrentValue(EnumObj, CurProp, CurField);
          if CurrVal.Kind = tkRecord then
            FreePairKV(CurrVal, FreeKeys, FreeValues)
          else
            FreeParamCore(CurrVal, Seen); // unusual, but recurse anyway
        end;
      finally
        EnumObj.Free;
      end;
    finally
      Ctx.Free;
    end;
  end;

  procedure FreeRecordFields(const RecVal: TValue);
  var
    Ctx: TRttiContext; T: TRttiType; F: TRttiField; P: Pointer;
  begin
    Ctx := TRttiContext.Create;
    try
      T := Ctx.GetType(RecVal.TypeInfo);
      if T = nil then Exit;
      P := RecVal.GetReferenceToRawData;
      for F in T.GetFields do
        FreeParamCore(F.GetValue(P), Seen);
    finally
      Ctx.Free;
    end;
  end;

  procedure FreeValueTree(const V: TValue);
  var
    Cur: TValue;
    I, N: Integer;
    Obj: TObject;
    OwnsItems, HasOwnsProp: Boolean;
    OwnsKeys, OwnsValues, HasKeysProp, HasValuesProp: Boolean;
    Ctx: TRttiContext; RType: TRttiType;
    EnumObj: TObject; MoveNext: TRttiMethod; CurProp: TRttiProperty; CurField: TRttiField;
    HadEnum: Boolean;
  begin
    Cur := UnwrapValue(V);

    // Arrays
    if Cur.IsArray then
    begin
      N := Cur.GetArrayLength;
      for I := 0 to N - 1 do
      begin
        FreeValueTree(Cur.GetArrayElement(I));
      end;
      Exit;
    end;

    // Records (generic): walk all fields
    if (Cur.Kind = tkRecord) or (Cur.Kind = tkMRecord)
    then
    begin
      FreeRecordFields(Cur);
      Exit;
    end;

    // Objects
    if Cur.IsObject then
    begin
      Obj := Cur.AsObject;
      if Obj = nil then Exit;
      if MarkVisited(Obj) then Exit;

      // JSON DOM
      if Obj is TJSONValue then
      begin
        Obj.Free;
        Exit;
      end;

      // TObjectList<T>
      ProbeListOwnership(Obj, OwnsItems, HasOwnsProp);
      if HasOwnsProp then
      begin
        if OwnsItems then
        begin
          Obj.Free;   // owns → free container only
          Exit;
        end
        else
        begin
          DrainList(Obj); // non-owning → free items
          Obj.Free;       // then free container
          Exit;
        end;
      end;

      // TObjectDictionary<K,V>
      ProbeDictOwnership(Obj, OwnsKeys, OwnsValues, HasKeysProp, HasValuesProp);
      if HasKeysProp or HasValuesProp then
      begin
        if (not OwnsKeys) and (not OwnsValues) then
        begin
          // both False → free K & V, then container
          DrainDict(Obj, True, True);
          Obj.Free;
          Exit;
        end
        else
        begin
          // owns one/both → do NOT free owned sides; drain only non-owned, then container
          DrainDict(Obj, not OwnsKeys, not OwnsValues);
          Obj.Free;
          Exit;
        end;
      end;

      // Regular list/dictionary
      if IsListLike(Obj) then
      begin
        DrainList(Obj);
        Obj.Free;
        Exit;
      end;

      if IsDictionaryLike(Obj) then
      begin
        DrainDict(Obj, True, True);
        Obj.Free;
        Exit;
      end;

      // Generic enumerable fallback
      Ctx := TRttiContext.Create;
      try
        RType := SafeGetType(Ctx, Obj);
        EnumObj := nil; HadEnum := False;
        if GetEnumeratorQuad(RType, Obj, EnumObj, MoveNext, CurProp, CurField) then
        try
          HadEnum := True;
          while MoveNext.Invoke(EnumObj, []).AsBoolean do
            FreeValueTree(GetCurrentValue(EnumObj, CurProp, CurField));
        finally
          EnumObj.Free;
        end;
      finally
        Ctx.Free;
      end;

      if HadEnum then
      begin
        Obj.Free;
        Exit;
      end;

      // Plain DTO
      Obj.Free;
      Exit;
    end;

    // Non-object scalars/strings/etc.: nothing to free
  end;

begin
  if AParam.IsEmpty then Exit;
  FreeValueTree(AParam);
end;

class procedure TValueUtils.FreeParameter(var AParam: TValue);
var
  Seen: TDictionary<Pointer, Byte>;
begin
  if AParam.IsEmpty then Exit;
  Seen := TDictionary<Pointer, Byte>.Create;
  try
    FreeParamCore(AParam, Seen);
  finally
    Seen.Free;
  end;
  AParam := TValue.Empty;
end;

class procedure TValueUtils.FreeParameters(var AParams: TList<TValue>);
var
  I: Integer;
  Seen: TDictionary<Pointer, Byte>;
  V: TValue;
begin
  if not Assigned(AParams) then Exit;

  Seen := TDictionary<Pointer, Byte>.Create;
  try
    for I := 0 to AParams.Count - 1 do
    begin
      V := AParams[I];
      if not V.IsEmpty then
        FreeParamCore(V, Seen);  // shared Seen across all params
      AParams[I] := TValue.Empty;
    end;
  finally
    Seen.Free;
  end;

  AParams.Clear;
  AParams.Free;
end;

class procedure TValueUtils.FreeParameters(var AParams: TDictionary<string, TValue>);
var
  Seen: TDictionary<Pointer, Byte>;
  Pair: TPair<string, TValue>;
begin
  if not Assigned(AParams) then Exit;

  Seen := TDictionary<Pointer, Byte>.Create;
  try
    for Pair in AParams do
    begin
     FreeParamCore(Pair.Value, Seen);
    end;
  finally
    Seen.Free;
  end;

  AParams.Clear;
  AParams.Free;
end;

class function TValueUtils.ToStringExtended(const V: TValue): string;

  // try to recover implementing object from an interface
  function BackingObjectFromInterface(const I: IInterface): TObject;
  var
    Unknown: IInterface;
  begin
    Result := nil;
    if I = nil then
      Exit;

    // If the interface is from a class implementing IInterface
    if I.QueryInterface(IInterface, Unknown) = S_OK then
    begin
      // Safe: this only works if it’s a Delphi class implementing IInterface
      if TObject(Unknown) is TObject then
        Result := TObject(Unknown);
    end;
  end;

var
  U: TValue;
  Obj: TObject;
  Intf: IInterface;
begin
  // Handle empty/nil: calling .ToString on null would NRE,
  // but since we're formatting, return '' for nil references.
  if V.IsEmpty then
    Exit('');

  // Unwrap boxed TValue
  U := UnwrapValue(V);

  case U.Kind of
    tkClass:
      begin
        Obj := U.AsObject;
        if Obj = nil then
          Exit('');
        Exit(Obj.ToString);  // honors overrides
      end;

    tkInterface:
      begin
        Intf := U.AsInterface;
        Obj := BackingObjectFromInterface(Intf);
        if Obj <> nil then
          Exit(Obj.ToString)  // call the implementing object's ToString
        else
          // Fallback: interface type name
          Exit(GetTypeName(U.TypeInfo));
      end;

    tkUString, tkWString, tkLString, tkString:
      Exit(U.AsString);

  else
    // For numerics, enums, sets, records, etc., use TValue.ToString
    Exit(U.ToString);
  end;
end;

end.
