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

unit SlpJsonKit;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Math,
  System.Generics.Collections,
  System.Rtti,
  System.TypInfo,
  System.JSON.Serializers,
  System.JSON.Writers,
  SlpStringTransformer;

  type
  TJsonIgnoreCondition = (
    Always,            // identical to plain [JsonIgnore]
    Never,             // explicitly un-ignore
    WhenWritingDefault,// omit when value equals default(T)
    WhenWritingNull    // omit when value is nil/null
  );

  type
  TJsonNamingPolicy = (CamelCase, PascalCase, SnakeCase, KebabCase);

  JsonIgnoreWithConditionAttribute = class(JsonIgnoreAttribute)
  private
    FCondition: TJsonIgnoreCondition;
  public
    constructor Create(ACondition: TJsonIgnoreCondition);
    property Condition: TJsonIgnoreCondition read FCondition;
  end;

  type
  {----------------------------------------------------------------------------
    Attribute: callers may pass a *single pre-composed* Provider, a Policy, or BOTH.
    If BOTH are supplied, we compose as: Provider FIRST, then Policy.
    If none are supplied, no transform is applied.
  ----------------------------------------------------------------------------}
  JsonStringEnumAttribute = class(TCustomAttribute)
  private
    FPolicy: TJsonNamingPolicy;
    FProvider: TStringTransformProviderClass;
    FHasExplicitPolicy: Boolean;
  public
    // Policy-only
    constructor Create(APolicy: TJsonNamingPolicy); overload;
    // Provider-only (the provider itself may already be a composite)
    constructor Create(AProvider: TStringTransformProviderClass); overload;
    // Both (Provider first, then Policy)
    constructor Create(APolicy: TJsonNamingPolicy; AProvider: TStringTransformProviderClass); overload;

    property Policy: TJsonNamingPolicy read FPolicy;
    property Provider: TStringTransformProviderClass read FProvider;
    property HasExplicitPolicy: Boolean read FHasExplicitPolicy;
  end;

  type
  IEnhancedContractResolverAccess = interface
    ['{7A6B4E6E-2AB7-4DF7-9B9E-5B2E5B6E9C15}']
    function TryGetIgnoreCondition(const AProp: TJsonProperty; out Cond: TJsonIgnoreCondition): Boolean;
    function HasConditionalProps(AType: PTypeInfo): Boolean;
  end;

  TEnhancedContractResolver = class(TJsonDefaultContractResolver, IEnhancedContractResolverAccess)
  private
    FNamingFunc: TStringTransform;
    FPropertyConverters: TObjectList<TJsonConverter>;
    FIgnoreConds: TDictionary<TJsonProperty, TJsonIgnoreCondition>;
    FTypesWithConditional: TDictionary<PTypeInfo, Boolean>;

    // IEnhancedContractResolverAccess
    function TryGetIgnoreCondition(const AProp: TJsonProperty; out Cond: TJsonIgnoreCondition): Boolean;
    function HasConditionalProps(AType: PTypeInfo): Boolean;

    procedure MarkTypeHasConditional(const ARttiMember: TRttiMember);
    procedure ApplyJsonIgnoreConditionAttribute(const AProperty: TJsonProperty; const ARttiMember: TRttiMember);
    procedure ApplyEnumStringConverter(const AProperty: TJsonProperty);
    function  TryGetEnumNamingAttr(const AProperty: TJsonProperty; out Naming: JsonStringEnumAttribute): Boolean;

  protected
    function ResolvePropertyName(const AName: string): string; override;

    procedure SetPropertySettingsFromAttributes(
      const AProperty: TJsonProperty;
      const ARttiMember: TRttiMember;
      AMemberSerialization: TJsonMemberSerialization); override;

  public
    constructor Create; reintroduce; overload;
    constructor Create(AMembers: TJsonMemberSerialization; APolicy: TJsonNamingPolicy); overload;
    constructor Create(AMembers: TJsonMemberSerialization; const Steps: array of TStringTransform); overload;
    constructor Create(AMembers: TJsonMemberSerialization; const AFunc: TStringTransform); overload;
    destructor Destroy; override;
  end;

  type
  // Local writer that only handles objects/arrays-of-objects so we can decide
  // to omit a property before the name is written. Everything else → base.
  TEnhancedJsonSerializerWriter = class(TObject)
  private
    FSerializer: TJsonSerializer;

    function GetResolverAccess: IEnhancedContractResolverAccess;
    function ShouldSkipByCondition(const AContainer: TValue; const AProp: TJsonProperty): Boolean;

    procedure WriteObject(const AWriter: TJsonWriter; const Value: TValue; const AContract: TJsonObjectContract);
    procedure WriteProperty(const AWriter: TJsonWriter; const AContainer: TValue;
                            const AProperty: TJsonProperty);
    procedure WriteArray(const AWriter: TJsonWriter; const Value: TValue);
    procedure WriteValue(const AWriter: TJsonWriter; const AValue: TValue; const AContract: TJsonContract);
  public
    constructor Create(const ASerializer: TJsonSerializer);
    procedure Serialize(const AWriter: TJsonWriter; const AValue: TValue);
  end;

  type
  // Thin shim over the RTL serializer. It only intercepts when the resolver
  // reports a type has conditional ignore properties (JsonIgnoreWithCondition(TJsonIgnoreCondition.WhenWritingNull));
  // otherwise it defers to RTL.
  TEnhancedJsonSerializer = class(TJsonSerializer)

  protected
    procedure InternalSerialize(const AWriter: TJsonWriter; const AValue: TValue); override;

  public
    // Call the base engine (avoids recursion)
    procedure BaseInternalSerialize(const AWriter: TJsonWriter; const AValue: TValue);
  end;

  type
  /// Creates JSON serializers configured to use Public members.
  /// - Shared: cached singleton (created in class constructor, freed in class destructor)
  /// - CreateSerializer: make a fresh instance (optionally with a different MemberSerialization)
  TJsonSerializerFactory = class
  strict private
    class var FShared: TJsonSerializer;
    class function NewSerializer(const AContractResolver: IJsonContractResolver; const AConverters: TList<TJsonConverter>): TJsonSerializer; static;
  public
    class constructor Create;
    class destructor Destroy;

    /// Returns the cached singleton. Do NOT free the returned instance.
    class function Shared: TJsonSerializer; static;

    /// Fresh serializer (caller owns).
    class function CreateSerializer: TJsonSerializer; overload; static;
    class function CreateSerializer(const AContractResolver: IJsonContractResolver; const AConverters: TList<TJsonConverter>): TJsonSerializer; overload; static;
  end;

implementation

uses
 SlpJsonHelpers,
 SlpJsonStringEnumConverter;

{ JsonIgnoreWithConditionAttribute }

constructor JsonIgnoreWithConditionAttribute.Create(ACondition: TJsonIgnoreCondition);
begin
  inherited Create;
  FCondition := ACondition;
end;

{ JsonStringEnumAttribute }

constructor JsonStringEnumAttribute.Create(APolicy: TJsonNamingPolicy);
begin
  inherited Create;
  FHasExplicitPolicy := True;
  FPolicy := APolicy;
  FProvider := nil;
end;

constructor JsonStringEnumAttribute.Create(AProvider: TStringTransformProviderClass);
begin
  inherited Create;
  FHasExplicitPolicy := False;
  FProvider := AProvider;
end;

constructor JsonStringEnumAttribute.Create(APolicy: TJsonNamingPolicy; AProvider: TStringTransformProviderClass);
begin
  inherited Create;
  FHasExplicitPolicy := True;
  FPolicy := APolicy;
  FProvider := AProvider;
end;

{ TEnhancedContractResolver }

constructor TEnhancedContractResolver.Create;
begin
  Create(TJsonMemberSerialization.Public, nil);
end;

constructor TEnhancedContractResolver.Create(AMembers: TJsonMemberSerialization; APolicy: TJsonNamingPolicy);
begin
  Create(AMembers, APolicy.GetFunc);
end;

constructor TEnhancedContractResolver.Create(AMembers: TJsonMemberSerialization; const Steps: array of TStringTransform);
begin
  Create(AMembers, TStringTransformer.ComposeMany(Steps));
end;

constructor TEnhancedContractResolver.Create(AMembers: TJsonMemberSerialization; const AFunc: TStringTransform);
begin
  inherited Create(AMembers);
  if Assigned(AFunc) then
    FNamingFunc := AFunc
  else
    FNamingFunc := TStringTransformer.Identity();

  FPropertyConverters    := TObjectList<TJsonConverter>.Create(True);
  FIgnoreConds           := TDictionary<TJsonProperty, TJsonIgnoreCondition>.Create;
  FTypesWithConditional  := TDictionary<PTypeInfo, Boolean>.Create;
end;

destructor TEnhancedContractResolver.Destroy;
begin
  FTypesWithConditional.Free;
  FIgnoreConds.Free;
  FPropertyConverters.Free;
  inherited;
end;

function TEnhancedContractResolver.ResolvePropertyName(const AName: string): string;
begin
  Result := FNamingFunc(AName);
end;

procedure TEnhancedContractResolver.MarkTypeHasConditional(const ARttiMember: TRttiMember);
var
  DeclType: TRttiType;
  PT: PTypeInfo;
begin
  if ARttiMember = nil then
    Exit;
  DeclType := ARttiMember.Parent;
  if DeclType <> nil then
  begin
    PT := DeclType.Handle;
    if PT <> nil then
      FTypesWithConditional.AddOrSetValue(PT, True);
  end;
end;

function TEnhancedContractResolver.TryGetEnumNamingAttr(
  const AProperty: TJsonProperty; out Naming: JsonStringEnumAttribute): Boolean;
var
  Attr: TCustomAttribute;
begin
  Naming := nil;
  Attr := AProperty.AttributeProvider.GetAttribute(JsonStringEnumAttribute);
  Result := Attr <> nil;
  if Result then
    Naming := JsonStringEnumAttribute(Attr);
end;

procedure TEnhancedContractResolver.ApplyEnumStringConverter(
  const AProperty: TJsonProperty);
var
  EnumType  : PTypeInfo;
  Naming    : JsonStringEnumAttribute;
  Converter : TJsonStringEnumConverter;
begin
  // Respect any existing converter
  if AProperty.Converter <> nil then
    Exit;

  EnumType := AProperty.TypeInf;
  if (EnumType = nil) or (EnumType^.Kind <> tkEnumeration) then
    Exit;

  if not TryGetEnumNamingAttr(AProperty, Naming) then
    Exit;

  Converter := nil;
  if (Naming.Provider <> nil) and Naming.HasExplicitPolicy then
    Converter := TJsonStringEnumConverter.Create(Naming.Policy, Naming.Provider)
  else if (Naming.Provider <> nil) then
    Converter := TJsonStringEnumConverter.Create(Naming.Provider)
  else if Naming.HasExplicitPolicy then
    Converter := TJsonStringEnumConverter.Create(Naming.Policy);

  if Converter <> nil then
  begin
    Converter.IgnoreTypeAttributes := True;
    FPropertyConverters.Add(Converter);
    AProperty.Converter := Converter;
  end;
end;

procedure TEnhancedContractResolver.ApplyJsonIgnoreConditionAttribute(
  const AProperty: TJsonProperty; const ARttiMember: TRttiMember);
var
  Attr    : TCustomAttribute;
  CondAttr: JsonIgnoreWithConditionAttribute;
  Cond    : TJsonIgnoreCondition;
begin
  Attr := AProperty.AttributeProvider.GetAttribute(JsonIgnoreWithConditionAttribute);
  if Attr = nil then
    Exit;

  CondAttr := JsonIgnoreWithConditionAttribute(Attr);
  Cond     := CondAttr.Condition;

  if Cond = TJsonIgnoreCondition.Always then
  begin
    AProperty.Ignored := True;
    Exit;
  end;

  FIgnoreConds.AddOrSetValue(AProperty, Cond);
  MarkTypeHasConditional(ARttiMember);
end;

procedure TEnhancedContractResolver.SetPropertySettingsFromAttributes(
  const AProperty: TJsonProperty; const ARttiMember: TRttiMember;
  AMemberSerialization: TJsonMemberSerialization);
begin
  inherited; // keep stock handling (JsonConverter, JsonName, JsonIgnore, etc.)

  ApplyJsonIgnoreConditionAttribute(AProperty, ARttiMember);
  ApplyEnumStringConverter(AProperty);
end;

function TEnhancedContractResolver.TryGetIgnoreCondition(
  const AProp: TJsonProperty; out Cond: TJsonIgnoreCondition): Boolean;
begin
  Result := FIgnoreConds.TryGetValue(AProp, Cond);
end;

function TEnhancedContractResolver.HasConditionalProps(AType: PTypeInfo): Boolean;
begin
  Result := (AType <> nil) and FTypesWithConditional.ContainsKey(AType);
end;

{ TEnhancedJsonSerializerWriter }

constructor TEnhancedJsonSerializerWriter.Create(const ASerializer: TJsonSerializer);
begin
  inherited Create;
  FSerializer := ASerializer;
end;

function TEnhancedJsonSerializerWriter.GetResolverAccess: IEnhancedContractResolverAccess;
var
  R: IJsonContractResolver;
begin
  R := FSerializer.ContractResolver;
  if Supports(R, IEnhancedContractResolverAccess, Result) then
    Exit
  else
    Result := nil;
end;

function TEnhancedJsonSerializerWriter.ShouldSkipByCondition(
  const AContainer: TValue; const AProp: TJsonProperty): Boolean;

  function IsNullLike(const V: TValue): Boolean;
  begin
    // Treat empty TValue / nil class/interface as null-like
    Result := V.IsEmpty
      or ((V.Kind = tkClass) and (V.AsObject = nil))
      or ((V.Kind = tkInterface) and (V.AsInterface = nil));
  end;

  function IsDefaultOf(const V: TValue; AType: PTypeInfo): Boolean;
  begin
    case AType^.Kind of
      // Ordinals: Int, UInt32, Int64, enums, Char/WChar, Boolean (AsOrdinal=0 covers them)
      tkInteger, tkInt64, tkChar, tkWChar, tkEnumeration:
        Result := (not V.IsEmpty) and (V.AsOrdinal = 0);

      // Floats: Single/Double/Extended/Currency
      tkFloat:
        Result := (not V.IsEmpty) and SameValue(V.AsExtended, 0.0);

      // Delphi strings
      tkString, tkLString, tkWString, tkUString:
        Result := (not V.IsEmpty) and (V.AsString = '');

      // Dyn arrays: treat empty as default
      tkDynArray:
        Result := V.IsEmpty or (V.GetArrayLength = 0);

      // Sets: empty considered default
      tkSet:
        Result := V.IsEmpty;

      // References
      tkClass, tkInterface:
        Result := IsNullLike(V);

      // Records: conservative (zero-init)
      tkRecord{$IF Declared(tkMRecord)}, tkMRecord{$IFEND}:
        Result := V.IsEmpty;
    else
      Result := V.IsEmpty;
    end;
  end;

var
  Access: IEnhancedContractResolverAccess;
  Cond: TJsonIgnoreCondition;
  PropVal: TValue;
  MemberContract: TJsonContract;
begin
  Result := False;

  Access := GetResolverAccess;
  if (Access = nil) then
    Exit(False);

  if not Access.TryGetIgnoreCondition(AProp, Cond) then
    Exit(False);

  case Cond of
    TJsonIgnoreCondition.Always:
      Exit(True);

    TJsonIgnoreCondition.Never:
      Exit(False);

    TJsonIgnoreCondition.WhenWritingNull:
      begin
        PropVal := AProp.ValueProvider.GetValue(AContainer);
        Exit(IsNullLike(PropVal));
      end;

    TJsonIgnoreCondition.WhenWritingDefault:
      begin
        PropVal := AProp.ValueProvider.GetValue(AContainer);

        // Use property’s own contract/typeinfo for default comparison
        MemberContract := AProp.Contract;
        if MemberContract = nil then
          MemberContract := FSerializer.ContractResolver.ResolveContract(AProp.TypeInf);
        if (MemberContract = nil) then
          Exit(False);

        Exit(IsDefaultOf(PropVal, MemberContract.TypeInf));
      end;
  end;
end;

procedure TEnhancedJsonSerializerWriter.WriteProperty(
  const AWriter: TJsonWriter; const AContainer: TValue; const AProperty: TJsonProperty);
var
  MemberContract: TJsonContract;
  PropVal: TValue;
  Gotten: Boolean;
  Conv: TJsonConverter;
begin
  if AProperty.Ignored or not AProperty.Readable then
    Exit;

  // Our key hook: skip before writing the name or calling any converter
  if ShouldSkipByCondition(AContainer, AProperty) then
    Exit;

  // RTL-compatible ordering from here:

  // Property-level converter wins
  Conv := AProperty.Converter;
  if (Conv <> nil) then
  begin
    AWriter.WritePropertyName(AProperty.Name);
    Conv.WriteJson(AWriter, AProperty.ValueProvider.GetValue(AContainer), FSerializer);
    Exit;
  end;

  // Ensure/resolve contract
  if AProperty.Contract = nil then
    AProperty.Contract := FSerializer.ContractResolver.ResolveContract(AProperty.TypeInf);
  MemberContract := AProperty.Contract;
  if (MemberContract = nil) then
    Exit;

  Gotten := False;

  // If not sealed, re-resolve for runtime type variance
  if not MemberContract.Sealed then
  begin
    PropVal := AProperty.ValueProvider.GetValue(AContainer);
    Gotten  := True;
    if (not PropVal.IsEmpty) and (PropVal.TypeInfo <> MemberContract.TypeInf) then
    begin
      MemberContract := FSerializer.ContractResolver.ResolveContract(PropVal.TypeInfo);
      if (MemberContract = nil) or MemberContract.Ignored then
        Exit;
    end;
  end;

  if MemberContract.Ignored then
    Exit;

  // Type-converter contract?
  if MemberContract.ContractType = TJsonContractType.Converter then
  begin
    Conv := FSerializer.MatchConverter(FSerializer.Converters, MemberContract.TypeInf);
    if (Conv <> nil) and (Conv.CanWrite) then
    begin
      if not Gotten then
        PropVal := AProperty.ValueProvider.GetValue(AContainer);
      AWriter.WritePropertyName(AProperty.Name);
      Conv.WriteJson(AWriter, PropVal, FSerializer);
      Exit;
    end;
  end;

  // Otherwise write value (objects/arrays handled specially, else fall through to base)
  if not Gotten then
    PropVal := AProperty.ValueProvider.GetValue(AContainer);

  AWriter.WritePropertyName(AProperty.Name);
  WriteValue(AWriter, PropVal, MemberContract);
end;

procedure TEnhancedJsonSerializerWriter.WriteObject(
  const AWriter: TJsonWriter; const Value: TValue; const AContract: TJsonObjectContract);
var
  P: TJsonProperty;
begin
  AWriter.WriteStartObject;
  for P in AContract.Properties do
    WriteProperty(AWriter, Value, P);
  AWriter.WriteEndObject;
end;

procedure TEnhancedJsonSerializerWriter.WriteArray(
  const AWriter: TJsonWriter; const Value: TValue);
var
  Len, I: Integer;
  Elem: TValue;
  ElemContract: TJsonContract;
begin
  AWriter.WriteStartArray;
  Len := Value.GetArrayLength;
  for I := 0 to Len - 1 do
  begin
    Elem := Value.GetArrayElement(I);
    ElemContract := FSerializer.ContractResolver.ResolveContract(Elem.TypeInfo);

    if (ElemContract is TJsonObjectContract) then
      // Object elements go through our gating, so their properties can be skipped
      TEnhancedJsonSerializer(FSerializer).InternalSerialize(AWriter, Elem)
    else
      // Primitives/strings/enums/dates/**converter elements** → base engine
      TEnhancedJsonSerializer(FSerializer).BaseInternalSerialize(AWriter, Elem);
  end;
  AWriter.WriteEndArray;
end;

procedure TEnhancedJsonSerializerWriter.WriteValue(
  const AWriter: TJsonWriter; const AValue: TValue; const AContract: TJsonContract);
begin
  if (AContract is TJsonObjectContract) then
  begin
    WriteObject(AWriter, AValue, TJsonObjectContract(AContract));
    Exit;
  end;

  if (AContract is TJsonArrayContract) or (AValue.Kind = tkDynArray) then
  begin
    WriteArray(AWriter, AValue);
    Exit;
  end;

  // Anything else → base engine (avoids recursion; keeps converters working)
  TEnhancedJsonSerializer(FSerializer).BaseInternalSerialize(AWriter, AValue);
end;

procedure TEnhancedJsonSerializerWriter.Serialize(
  const AWriter: TJsonWriter; const AValue: TValue);
var
  Contract: TJsonContract;
begin
  Contract := FSerializer.ContractResolver.ResolveContract(AValue.TypeInfo);
  if (Contract = nil) or Contract.Ignored then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  if (Contract is TJsonObjectContract) then
    WriteObject(AWriter, AValue, TJsonObjectContract(Contract))
  else if (Contract is TJsonArrayContract) or (AValue.Kind = tkDynArray) then
    WriteArray(AWriter, AValue)
  else
    TEnhancedJsonSerializer(FSerializer).BaseInternalSerialize(AWriter, AValue);
end;

{ TEnhancedJsonSerializer }

(*
type
  TListSurface = record
    Inst     : TRttiInstanceType;
    AddMeth  : TRttiMethod;
    ElemType : PTypeInfo;
  end;

function TryGetListSurface(const ATI: PTypeInfo; out Surf: TListSurface): Boolean;
var
  TD : PTypeData;
  Cls: TClass;
  Ctx: TRttiContext;
  M  : TRttiMethod;
  P  : TArray<TRttiParameter>;
  Prop: TRttiProperty;
begin
  Result := False;
  FillChar(Surf, SizeOf(Surf), 0);
  if (ATI = nil) or (ATI^.Kind <> tkClass) then Exit;

  TD := GetTypeData(ATI);
  if (TD = nil) or (TD^.ClassType = nil) then Exit;
  Cls := TD^.ClassType;

  Surf.Inst := Ctx.GetType(Cls) as TRttiInstanceType;
  if Surf.Inst = nil then Exit;

  // Must expose Count: Integer and Clear
  Prop := Surf.Inst.GetProperty('Count');
  if (Prop = nil) or (Prop.PropertyType = nil) or (Prop.PropertyType.TypeKind <> tkInteger) then Exit;
  if Surf.Inst.GetMethod('Clear') = nil then Exit;

  // Must expose Add(T) -> gives element type
  for M in Surf.Inst.GetMethods do
    if (M.MethodKind = mkProcedure) and (M.Name = 'Add') then
    begin
      P := M.GetParameters;
      if (Length(P) = 1) and Assigned(P[0].ParamType) then
      begin
        Surf.AddMeth  := M;
        Surf.ElemType := P[0].ParamType.Handle;
        Break;
      end;
    end;

  Result := (Surf.AddMeth <> nil) and (Surf.ElemType <> nil);
end;

function CreateClassInstance(const ATI: PTypeInfo): TValue;
var
  TD : PTypeData;
  Cls: TClass;
begin
  Result := TValue.Empty;
  if (ATI = nil) or (ATI^.Kind <> tkClass) then Exit;
  TD := GetTypeData(ATI);
  if (TD = nil) or (TD^.ClassType = nil) then Exit;
  Cls := TD^.ClassType;
  Result := TValue.From<TObject>(Cls.Create); // default ctor; TObjectList<T> defaults OwnsObjects=True
end;

function TEnhancedJsonSerializer.InternalDeserialize(
  const AReader: TJsonReader; ATypeInf: PTypeInfo): TValue;
var
  Surf : TListSurface;
  ListV: TValue;
  Item : TValue;
  Ctx  : TRttiContext;
  InstT: TRttiType;
begin
  // If we’re on a property name (e.g., "result"), DO NOT advance – let base handle it.
  if AReader.TokenType = TJsonToken.PropertyName then
    Exit(inherited InternalDeserialize(AReader, ATypeInf));

  // Intercept ONLY when the current token IS the array value
  if (AReader.TokenType = TJsonToken.StartArray) and TryGetListSurface(ATypeInf, Surf) then
  begin
    // Create list instance and clear (harmless on new)
    ListV := CreateClassInstance(ATypeInf);
    if ListV.IsEmpty then
      Exit(inherited InternalDeserialize(AReader, ATypeInf));

    InstT := Ctx.GetType(ListV.TypeInfo);
    InstT.GetMethod('Clear').Invoke(ListV, []);

    // Move once into the array payload
    if not AReader.Read then
      Exit(ListV); // empty []

    // Loop: base consumes one element starting at current token
    while AReader.TokenType <> TJsonToken.EndArray do
    begin
      Item := inherited InternalDeserialize(AReader, Surf.ElemType);
      Surf.AddMeth.Invoke(ListV, [Item]);

      // Advance to next element or EndArray (exactly once per iteration)
      if not AReader.Read then Break;
    end;

    Exit(ListV);
  end;

  // Everything else (object roots, non-array values, primitives, etc.)
  Result := inherited InternalDeserialize(AReader, ATypeInf);
end;


 function TEnhancedJsonSerializer.BaseInternalDeserialize(
  const AReader: TJsonReader; ATypeInf: PTypeInfo): TValue;
begin
  Result := inherited InternalDeserialize(AReader, ATypeInf);
end;  *)

////////

procedure TEnhancedJsonSerializer.BaseInternalSerialize(
  const AWriter: TJsonWriter; const AValue: TValue);
begin
  inherited InternalSerialize(AWriter, AValue);
end;

procedure TEnhancedJsonSerializer.InternalSerialize(
  const AWriter: TJsonWriter; const AValue: TValue);

  function ElemTypeInfoOf(const ArrType: PTypeInfo): PTypeInfo;
  begin
    Result := nil;
    if (ArrType <> nil) and (ArrType^.Kind = tkDynArray) then
      Result := GetTypeData(ArrType)^.DynArrElType^;
  end;

var
  R: IJsonContractResolver;
  Access: IEnhancedContractResolverAccess;
  C, ElemC: TJsonContract;
  NeedConditional: Boolean;
  ElemTI: PTypeInfo;
  W: TEnhancedJsonSerializerWriter;
begin
  R := ContractResolver;
  NeedConditional := False;

  C := R.ResolveContract(AValue.TypeInfo);

  if C is TJsonObjectContract then
  begin
    // Object root: only intercept if resolver already knows about conditional props
    if Supports(R, IEnhancedContractResolverAccess, Access) then
      NeedConditional := Access.HasConditionalProps(C.TypeInf);
  end
  else if C is TJsonArrayContract then
  begin
    // Array root: intercept if element is an object (properties may be lazily built)
    ElemTI := ElemTypeInfoOf(C.TypeInf);
    if ElemTI <> nil then
    begin
      ElemC := R.ResolveContract(ElemTI);
      NeedConditional :=
        (ElemC is TJsonObjectContract) or
        (Supports(R, IEnhancedContractResolverAccess, Access) and Access.HasConditionalProps(ElemTI));
    end;
  end;

  if not NeedConditional then
  begin
    BaseInternalSerialize(AWriter, AValue);
    Exit;
  end;

  W := TEnhancedJsonSerializerWriter.Create(Self);
  try
    W.Serialize(AWriter, AValue);
  finally
    W.Free;
  end;
end;

{ TJsonSerializerFactory }

class constructor TJsonSerializerFactory.Create;
var
 ContractResolver: IJsonContractResolver;
begin
  ContractResolver := TEnhancedContractResolver.Create(TJsonMemberSerialization.Public, TJsonNamingPolicy.CamelCase);
  FShared := CreateSerializer(ContractResolver, nil);
end;

class destructor TJsonSerializerFactory.Destroy;
begin
  if Assigned(FShared) then
    FShared.Free;
end;

class function TJsonSerializerFactory.NewSerializer(const AContractResolver: IJsonContractResolver; const AConverters: TList<TJsonConverter>): TJsonSerializer;
begin
  Result := TEnhancedJsonSerializer.Create;
  try
    Result.ContractResolver := AContractResolver;

    if Assigned(AConverters) then
      Result.Converters.AddRange(AConverters);
  except
    Result.Free;
    raise;
  end;
end;

class function TJsonSerializerFactory.Shared: TJsonSerializer;
begin
  Result := FShared;
end;

class function TJsonSerializerFactory.CreateSerializer: TJsonSerializer;
var
 ContractResolver: IJsonContractResolver;
begin
  ContractResolver := TEnhancedContractResolver.Create(TJsonMemberSerialization.Public, TJsonNamingPolicy.CamelCase);
  Result := CreateSerializer(ContractResolver, nil);
end;

class function TJsonSerializerFactory.CreateSerializer(const AContractResolver: IJsonContractResolver; const AConverters: TList<TJsonConverter>): TJsonSerializer;
begin
  Result := NewSerializer(AContractResolver, AConverters);
end;


end.
