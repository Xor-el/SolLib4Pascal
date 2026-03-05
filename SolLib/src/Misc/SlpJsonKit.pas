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

unit SlpJsonKit;

{$I ../Include/SolLib.inc}

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
  /// <summary>
  /// Allows callers to specify how enum values should be transformed during
  /// JSON serialization. A caller may pass a single pre-composed Provider,
  /// a Naming Policy, or both.
  /// </summary>
  /// <remarks>
  /// If both a Provider and a Policy are supplied, the transformation is
  /// composed in this order: the Provider is applied first, followed by
  /// the Naming Policy. If neither is supplied, no transformation is applied.
  /// </remarks>
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
    function TryGetEnumNamingAttr(const AProperty: TJsonProperty; out Naming: JsonStringEnumAttribute): Boolean;

  protected
    function ResolvePropertyName(const AName: string): string; override;

    procedure SetPropertySettingsFromAttributes(const AProperty: TJsonProperty; const ARttiMember: TRttiMember; AMemberSerialization: TJsonMemberSerialization); override;

  public
    constructor Create; reintroduce; overload;
    constructor Create(AMembers: TJsonMemberSerialization; APolicy: TJsonNamingPolicy); overload;
    constructor Create(AMembers: TJsonMemberSerialization; const Steps: array of TStringTransform); overload;
    constructor Create(AMembers: TJsonMemberSerialization; const AFunc: TStringTransform); overload;
    destructor Destroy; override;
  end;

type
  /// <summary>
  /// Thin wrapper around the RTL JSON serializer that intercepts serialization
  /// only when the resolver identifies properties with conditional ignore rules.
  /// </summary>
  /// <remarks>
  /// Interception occurs when a type includes <c>JsonIgnoreWithCondition</c>
  /// attributes such as <c>TJsonIgnoreCondition.WhenWritingNull</c>. All other
  /// cases are passed directly to the underlying RTL serializer.
  /// Object and array structures are intercepted for conditional property
  /// omission; all other value types are delegated to the base serializer.
  /// </remarks>
  TEnhancedJsonSerializer = class(TJsonSerializer)
  private
    FResolverAccess: IEnhancedContractResolverAccess;

    function GetResolverAccess: IEnhancedContractResolverAccess;
    function ShouldSkipByCondition(const AContainer: TValue; const AProp: TJsonProperty): Boolean;

    procedure SerializeEnhanced(const AWriter: TJsonWriter; const AValue: TValue);
    procedure WriteObject(const AWriter: TJsonWriter; const Value: TValue; const AContract: TJsonObjectContract);
    procedure WriteProperty(const AWriter: TJsonWriter; const AContainer: TValue; const AProperty: TJsonProperty);
    procedure WriteArray(const AWriter: TJsonWriter; const Value: TValue);
    procedure WriteValue(const AWriter: TJsonWriter; const AValue: TValue; const AContract: TJsonContract);

  protected
    procedure InternalSerialize(const AWriter: TJsonWriter; const AValue: TValue); override;
  end;

type
  /// <summary>
  /// Creates JSON serializer instances configured to use public members.
  /// Provides both a shared cached serializer and factory methods for creating
  /// new serializer instances.
  /// </summary>
  /// <remarks>
  /// <para>
  /// <c>Shared</c> returns a cached singleton created in the class constructor
  /// and freed in the class destructor.
  /// </para>
  /// <para>
  /// <c>CreateSerializer</c> returns a new serializer instance, optionally using
  /// a custom <c>TJsonMemberSerialization</c> setting.
  /// </para>
  /// </remarks>
  TJsonSerializerFactory = class
  strict private
    class var FShared: TJsonSerializer;

    class function NewSerializer(const AContractResolver: IJsonContractResolver; const AConverters: TList<TJsonConverter>): TJsonSerializer; static;
  public
    class constructor Create;
    class destructor Destroy;

    /// <summary>
    /// Returns the cached singleton serializer instance.
    /// </summary>
    /// <remarks>
    /// The caller must not free the returned instance.
    /// </remarks>
    class function Shared: TJsonSerializer; static;

    /// <summary>
    /// Creates and returns a new serializer instance.
    /// </summary>
    /// <remarks>
    /// The caller owns the returned instance and is responsible for freeing it.
    /// </remarks>
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

{ TEnhancedJsonSerializer }

function TEnhancedJsonSerializer.GetResolverAccess: IEnhancedContractResolverAccess;
begin
  if Assigned(FResolverAccess)
    or Supports(ContractResolver, IEnhancedContractResolverAccess, FResolverAccess) then
    Result := FResolverAccess
  else
    Result := nil;
end;

function TEnhancedJsonSerializer.ShouldSkipByCondition(
  const AContainer: TValue; const AProp: TJsonProperty): Boolean;

  function IsNullLike(const V: TValue): Boolean;
  begin
    Result := V.IsEmpty
      or ((V.Kind = tkClass) and (V.AsObject = nil))
      or ((V.Kind = tkInterface) and (V.AsInterface = nil));
  end;

  function IsDefaultOf(const V: TValue; AType: PTypeInfo): Boolean;
  begin
    case AType^.Kind of
      tkInteger, tkInt64, tkChar, tkWChar, tkEnumeration:
        Result := (not V.IsEmpty) and (V.AsOrdinal = 0);

      tkFloat:
        Result := (not V.IsEmpty) and SameValue(V.AsExtended, 0.0);

      tkString, tkLString, tkWString, tkUString:
        Result := (not V.IsEmpty) and (V.AsString = '');

      tkDynArray:
        Result := V.IsEmpty or (V.GetArrayLength = 0);

      tkSet:
        Result := V.IsEmpty;

      tkClass, tkInterface:
        Result := IsNullLike(V);

      tkRecord:
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
  if not Assigned(Access) then
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

        MemberContract := AProp.Contract;
        if MemberContract = nil then
          MemberContract := ContractResolver.ResolveContract(AProp.TypeInf);
        if (MemberContract = nil) then
          Exit(False);

        Exit(IsDefaultOf(PropVal, MemberContract.TypeInf));
      end;
  end;
end;

procedure TEnhancedJsonSerializer.WriteProperty(
  const AWriter: TJsonWriter; const AContainer: TValue; const AProperty: TJsonProperty);
var
  MemberContract: TJsonContract;
  PropVal: TValue;
  Gotten: Boolean;
  Conv: TJsonConverter;
begin
  if AProperty.Ignored or not AProperty.Readable then
    Exit;

  if ShouldSkipByCondition(AContainer, AProperty) then
    Exit;

  Conv := AProperty.Converter;
  if (Conv <> nil) then
  begin
    AWriter.WritePropertyName(AProperty.Name);
    Conv.WriteJson(AWriter, AProperty.ValueProvider.GetValue(AContainer), Self);
    Exit;
  end;

  if AProperty.Contract = nil then
    AProperty.Contract := ContractResolver.ResolveContract(AProperty.TypeInf);
  MemberContract := AProperty.Contract;
  if (MemberContract = nil) then
    Exit;

  Gotten := False;

  if not MemberContract.Sealed then
  begin
    PropVal := AProperty.ValueProvider.GetValue(AContainer);
    Gotten  := True;
    if (not PropVal.IsEmpty) and (PropVal.TypeInfo <> MemberContract.TypeInf) then
    begin
      MemberContract := ContractResolver.ResolveContract(PropVal.TypeInfo);
      if (MemberContract = nil) or MemberContract.Ignored then
        Exit;
    end;
  end;

  if MemberContract.Ignored then
    Exit;

  if MemberContract.ContractType = TJsonContractType.Converter then
  begin
    Conv := MatchConverter(Converters, MemberContract.TypeInf);
    if (Conv <> nil) and (Conv.CanWrite) then
    begin
      if not Gotten then
        PropVal := AProperty.ValueProvider.GetValue(AContainer);
      AWriter.WritePropertyName(AProperty.Name);
      Conv.WriteJson(AWriter, PropVal, Self);
      Exit;
    end;
  end;

  if not Gotten then
    PropVal := AProperty.ValueProvider.GetValue(AContainer);

  AWriter.WritePropertyName(AProperty.Name);
  WriteValue(AWriter, PropVal, MemberContract);
end;

procedure TEnhancedJsonSerializer.WriteObject(
  const AWriter: TJsonWriter; const Value: TValue; const AContract: TJsonObjectContract);
var
  P: TJsonProperty;
begin
  AWriter.WriteStartObject;
  for P in AContract.Properties do
    WriteProperty(AWriter, Value, P);
  AWriter.WriteEndObject;
end;

procedure TEnhancedJsonSerializer.WriteArray(
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

    if Elem.IsEmpty or (Elem.TypeInfo = nil) then
    begin
      AWriter.WriteNull;
      Continue;
    end;

    ElemContract := ContractResolver.ResolveContract(Elem.TypeInfo);

    if (ElemContract is TJsonObjectContract) then
      InternalSerialize(AWriter, Elem)
    else
      inherited InternalSerialize(AWriter, Elem);
  end;
  AWriter.WriteEndArray;
end;

procedure TEnhancedJsonSerializer.WriteValue(
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

  inherited InternalSerialize(AWriter, AValue);
end;

procedure TEnhancedJsonSerializer.SerializeEnhanced(
  const AWriter: TJsonWriter; const AValue: TValue);
var
  Contract: TJsonContract;
begin
  if AValue.IsEmpty or (AValue.TypeInfo = nil) then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  Contract := ContractResolver.ResolveContract(AValue.TypeInfo);
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
    inherited InternalSerialize(AWriter, AValue);
end;

procedure TEnhancedJsonSerializer.InternalSerialize(
  const AWriter: TJsonWriter; const AValue: TValue);

  function ElemTypeInfoOf(const ArrType: PTypeInfo): PTypeInfo;
  begin
    Result := nil;
    if (ArrType <> nil) and (ArrType^.Kind = tkDynArray) then
    begin
      {$IFDEF FPC}
      Result := GetTypeData(ArrType)^.ElType2;
      {$ELSE}
      Result := GetTypeData(ArrType)^.DynArrElType^;
      {$ENDIF}
    end;
  end;

var
  R: IJsonContractResolver;
  Access: IEnhancedContractResolverAccess;
  C, ElemC: TJsonContract;
  NeedConditional: Boolean;
  ElemTI: PTypeInfo;
begin
  R := ContractResolver;
  NeedConditional := False;

  C := R.ResolveContract(AValue.TypeInfo);

  if C is TJsonObjectContract then
  begin
    Access := GetResolverAccess;
    if Assigned(Access) then
      NeedConditional := Access.HasConditionalProps(C.TypeInf);
  end
  else if C is TJsonArrayContract then
  begin
    ElemTI := ElemTypeInfoOf(C.TypeInf);
    if ElemTI <> nil then
    begin
      ElemC := R.ResolveContract(ElemTI);
      Access := GetResolverAccess;
      NeedConditional :=
        (ElemC is TJsonObjectContract) or
        (Assigned(Access) and Access.HasConditionalProps(ElemTI));
    end;
  end;

  if not NeedConditional then
  begin
    inherited InternalSerialize(AWriter, AValue);
    Exit;
  end;

  SerializeEnhanced(AWriter, AValue);
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
