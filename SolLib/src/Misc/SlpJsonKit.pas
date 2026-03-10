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

    function TryGetIgnoreCondition(const AProp: TJsonProperty; out ACond: TJsonIgnoreCondition): Boolean;
    function HasConditionalProps(AType: PTypeInfo): Boolean;
  end;

  TEnhancedContractResolver = class(TJsonDefaultContractResolver, IEnhancedContractResolverAccess)
  private
    FNamingFunc: TStringTransform;
    FPropertyConverters: TObjectList<TJsonConverter>;
    FIgnoreConds: TDictionary<TJsonProperty, TJsonIgnoreCondition>;
    FTypesWithConditional: TDictionary<PTypeInfo, Boolean>;

    // IEnhancedContractResolverAccess
    function TryGetIgnoreCondition(const AProp: TJsonProperty; out ACond: TJsonIgnoreCondition): Boolean;
    function HasConditionalProps(AType: PTypeInfo): Boolean;

    procedure MarkTypeHasConditional(const ARttiMember: TRttiMember);
    procedure ApplyJsonIgnoreConditionAttribute(const AProperty: TJsonProperty; const ARttiMember: TRttiMember);
    procedure ApplyEnumStringConverter(const AProperty: TJsonProperty);
    function TryGetEnumNamingAttr(const AProperty: TJsonProperty; out ANaming: JsonStringEnumAttribute): Boolean;

  protected
    function ResolvePropertyName(const AName: string): string; override;

    procedure SetPropertySettingsFromAttributes(const AProperty: TJsonProperty; const ARttiMember: TRttiMember; AMemberSerialization: TJsonMemberSerialization); override;

  public
    constructor Create; reintroduce; overload;
    constructor Create(AMembers: TJsonMemberSerialization; APolicy: TJsonNamingPolicy); overload;
    constructor Create(AMembers: TJsonMemberSerialization; const ASteps: array of TStringTransform); overload;
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
    procedure WriteObject(const AWriter: TJsonWriter; const AValue: TValue; const AContract: TJsonObjectContract);
    procedure WriteProperty(const AWriter: TJsonWriter; const AContainer: TValue; const AProperty: TJsonProperty);
    procedure WriteArray(const AWriter: TJsonWriter; const AValue: TValue);
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

constructor TEnhancedContractResolver.Create(AMembers: TJsonMemberSerialization; const ASteps: array of TStringTransform);
begin
  Create(AMembers, TStringTransformer.ComposeMany(ASteps));
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
  LDeclType: TRttiType;
  PT: PTypeInfo;
begin
  if ARttiMember = nil then
    Exit;
  LDeclType := ARttiMember.Parent;
  if LDeclType <> nil then
  begin
    PT := LDeclType.Handle;
    if PT <> nil then
      FTypesWithConditional.AddOrSetValue(PT, True);
  end;
end;

function TEnhancedContractResolver.TryGetEnumNamingAttr(
  const AProperty: TJsonProperty; out ANaming: JsonStringEnumAttribute): Boolean;
var
  LAttr: TCustomAttribute;
begin
  ANaming := nil;
  LAttr := AProperty.AttributeProvider.GetAttribute(JsonStringEnumAttribute);
  Result := LAttr <> nil;
  if Result then
    ANaming := JsonStringEnumAttribute(LAttr);
end;

procedure TEnhancedContractResolver.ApplyEnumStringConverter(
  const AProperty: TJsonProperty);
var
  LEnumType  : PTypeInfo;
  LNaming    : JsonStringEnumAttribute;
  LConverter : TJsonStringEnumConverter;
begin
  // Respect any existing converter
  if AProperty.Converter <> nil then
    Exit;

  LEnumType := AProperty.TypeInf;
  if (LEnumType = nil) or (LEnumType^.Kind <> tkEnumeration) then
    Exit;

  if not TryGetEnumNamingAttr(AProperty, LNaming) then
    Exit;

  LConverter := nil;
  if (LNaming.Provider <> nil) and LNaming.HasExplicitPolicy then
    LConverter := TJsonStringEnumConverter.Create(LNaming.Policy, LNaming.Provider)
  else if (LNaming.Provider <> nil) then
    LConverter := TJsonStringEnumConverter.Create(LNaming.Provider)
  else if LNaming.HasExplicitPolicy then
    LConverter := TJsonStringEnumConverter.Create(LNaming.Policy);

  if LConverter <> nil then
  begin
    LConverter.IgnoreTypeAttributes := True;
    FPropertyConverters.Add(LConverter);
    AProperty.Converter := LConverter;
  end;
end;

procedure TEnhancedContractResolver.ApplyJsonIgnoreConditionAttribute(
  const AProperty: TJsonProperty; const ARttiMember: TRttiMember);
var
  LAttr    : TCustomAttribute;
  LCondAttr: JsonIgnoreWithConditionAttribute;
  LCond    : TJsonIgnoreCondition;
begin
  LAttr := AProperty.AttributeProvider.GetAttribute(JsonIgnoreWithConditionAttribute);
  if LAttr = nil then
    Exit;

  LCondAttr := JsonIgnoreWithConditionAttribute(LAttr);
  LCond     := LCondAttr.Condition;

  if LCond = TJsonIgnoreCondition.Always then
  begin
    AProperty.Ignored := True;
    Exit;
  end;

  FIgnoreConds.AddOrSetValue(AProperty, LCond);
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
  const AProp: TJsonProperty; out ACond: TJsonIgnoreCondition): Boolean;
begin
  Result := FIgnoreConds.TryGetValue(AProp, ACond);
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

  function IsNullLike(const AValue: TValue): Boolean;
  begin
    Result := AValue.IsEmpty
      or ((AValue.Kind = tkClass) and (AValue.AsObject = nil))
      or ((AValue.Kind = tkInterface) and (AValue.AsInterface = nil));
  end;

  function IsDefaultOf(const AValue: TValue; AType: PTypeInfo): Boolean;
  begin
    case AType^.Kind of
      tkInteger, tkInt64, tkChar, tkWChar, tkEnumeration:
        Result := (not AValue.IsEmpty) and (AValue.AsOrdinal = 0);

      tkFloat:
        Result := (not AValue.IsEmpty) and SameValue(AValue.AsExtended, 0.0);

      tkString, tkLString, tkWString, tkUString:
        Result := (not AValue.IsEmpty) and (AValue.AsString = '');

      tkDynArray:
        Result := AValue.IsEmpty or (AValue.GetArrayLength = 0);

      tkSet:
        Result := AValue.IsEmpty;

      tkClass, tkInterface:
        Result := IsNullLike(AValue);

      tkRecord:
        Result := AValue.IsEmpty;
    else
      Result := AValue.IsEmpty;
    end;
  end;

var
  LAccess: IEnhancedContractResolverAccess;
  LCond: TJsonIgnoreCondition;
  LPropVal: TValue;
  LMemberContract: TJsonContract;
begin
  Result := False;

  LAccess := GetResolverAccess;
  if not Assigned(LAccess) then
    Exit(False);

  if not LAccess.TryGetIgnoreCondition(AProp, LCond) then
    Exit(False);

  case LCond of
    TJsonIgnoreCondition.Always:
      Exit(True);

    TJsonIgnoreCondition.Never:
      Exit(False);

    TJsonIgnoreCondition.WhenWritingNull:
      begin
        LPropVal := AProp.ValueProvider.GetValue(AContainer);
        Exit(IsNullLike(LPropVal));
      end;

    TJsonIgnoreCondition.WhenWritingDefault:
      begin
        LPropVal := AProp.ValueProvider.GetValue(AContainer);

        LMemberContract := AProp.Contract;
        if LMemberContract = nil then
          LMemberContract := ContractResolver.ResolveContract(AProp.TypeInf);
        if (LMemberContract = nil) then
          Exit(False);

        Exit(IsDefaultOf(LPropVal, LMemberContract.TypeInf));
      end;
  end;
end;

procedure TEnhancedJsonSerializer.WriteProperty(
  const AWriter: TJsonWriter; const AContainer: TValue; const AProperty: TJsonProperty);
var
  LMemberContract: TJsonContract;
  LPropVal: TValue;
  LGotten: Boolean;
  LConv: TJsonConverter;
begin
  if AProperty.Ignored or not AProperty.Readable then
    Exit;

  if ShouldSkipByCondition(AContainer, AProperty) then
    Exit;

  LConv := AProperty.Converter;
  if (LConv <> nil) then
  begin
    AWriter.WritePropertyName(AProperty.Name);
    LConv.WriteJson(AWriter, AProperty.ValueProvider.GetValue(AContainer), Self);
    Exit;
  end;

  if AProperty.Contract = nil then
    AProperty.Contract := ContractResolver.ResolveContract(AProperty.TypeInf);
  LMemberContract := AProperty.Contract;
  if (LMemberContract = nil) then
    Exit;

  LGotten := False;

  if not LMemberContract.Sealed then
  begin
    LPropVal := AProperty.ValueProvider.GetValue(AContainer);
    LGotten  := True;
    if (not LPropVal.IsEmpty) and (LPropVal.TypeInfo <> LMemberContract.TypeInf) then
    begin
      LMemberContract := ContractResolver.ResolveContract(LPropVal.TypeInfo);
      if (LMemberContract = nil) or LMemberContract.Ignored then
        Exit;
    end;
  end;

  if LMemberContract.Ignored then
    Exit;

  if LMemberContract.ContractType = TJsonContractType.Converter then
  begin
    LConv := MatchConverter(Converters, LMemberContract.TypeInf);
    if (LConv <> nil) and (LConv.CanWrite) then
    begin
      if not LGotten then
        LPropVal := AProperty.ValueProvider.GetValue(AContainer);
      AWriter.WritePropertyName(AProperty.Name);
      LConv.WriteJson(AWriter, LPropVal, Self);
      Exit;
    end;
  end;

  if not LGotten then
    LPropVal := AProperty.ValueProvider.GetValue(AContainer);

  AWriter.WritePropertyName(AProperty.Name);
  WriteValue(AWriter, LPropVal, LMemberContract);
end;

procedure TEnhancedJsonSerializer.WriteObject(
  const AWriter: TJsonWriter; const AValue: TValue; const AContract: TJsonObjectContract);
var
  LProp: TJsonProperty;
begin
  AWriter.WriteStartObject;
  for LProp in AContract.Properties do
    WriteProperty(AWriter, AValue, LProp);
  AWriter.WriteEndObject;
end;

procedure TEnhancedJsonSerializer.WriteArray(
  const AWriter: TJsonWriter; const AValue: TValue);
var
  LLen, LI: Integer;
  LElem: TValue;
  LElemContract: TJsonContract;
begin
  AWriter.WriteStartArray;
  LLen := AValue.GetArrayLength;
  for LI := 0 to LLen - 1 do
  begin
    LElem := AValue.GetArrayElement(LI);

    if LElem.IsEmpty or (LElem.TypeInfo = nil) then
    begin
      AWriter.WriteNull;
      Continue;
    end;

    LElemContract := ContractResolver.ResolveContract(LElem.TypeInfo);

    if (LElemContract is TJsonObjectContract) then
      InternalSerialize(AWriter, LElem)
    else
      inherited InternalSerialize(AWriter, LElem);
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
  LContract: TJsonContract;
begin
  if AValue.IsEmpty or (AValue.TypeInfo = nil) then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  LContract := ContractResolver.ResolveContract(AValue.TypeInfo);
  if (LContract = nil) or LContract.Ignored then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  if (LContract is TJsonObjectContract) then
    WriteObject(AWriter, AValue, TJsonObjectContract(LContract))
  else if (LContract is TJsonArrayContract) or (AValue.Kind = tkDynArray) then
    WriteArray(AWriter, AValue)
  else
    inherited InternalSerialize(AWriter, AValue);
end;

procedure TEnhancedJsonSerializer.InternalSerialize(
  const AWriter: TJsonWriter; const AValue: TValue);

  function ElemTypeInfoOf(const AArrType: PTypeInfo): PTypeInfo;
  begin
    Result := nil;
    if (AArrType <> nil) and (AArrType^.Kind = tkDynArray) then
    begin
      {$IFDEF FPC}
      Result := GetTypeData(AArrType)^.ElType2;
      {$ELSE}
      Result := GetTypeData(AArrType)^.DynArrElType^;
      {$ENDIF}
    end;
  end;

var
  LR: IJsonContractResolver;
  LAccess: IEnhancedContractResolverAccess;
  LC, LElemC: TJsonContract;
  LNeedConditional: Boolean;
  LElemTI: PTypeInfo;
begin
  LR := ContractResolver;
  LNeedConditional := False;

  LC := LR.ResolveContract(AValue.TypeInfo);

  if LC is TJsonObjectContract then
  begin
    LAccess := GetResolverAccess;
    if Assigned(LAccess) then
      LNeedConditional := LAccess.HasConditionalProps(LC.TypeInf);
  end
  else if LC is TJsonArrayContract then
  begin
    LElemTI := ElemTypeInfoOf(LC.TypeInf);
    if LElemTI <> nil then
    begin
      LElemC := LR.ResolveContract(LElemTI);
      LAccess := GetResolverAccess;
      LNeedConditional :=
        (LElemC is TJsonObjectContract) or
        (Assigned(LAccess) and LAccess.HasConditionalProps(LElemTI));
    end;
  end;

  if not LNeedConditional then
  begin
    inherited InternalSerialize(AWriter, AValue);
    Exit;
  end;

  SerializeEnhanced(AWriter, AValue);
end;

{ TJsonSerializerFactory }

class constructor TJsonSerializerFactory.Create;
var
  LContractResolver: IJsonContractResolver;
begin
  LContractResolver := TEnhancedContractResolver.Create(TJsonMemberSerialization.Public, TJsonNamingPolicy.CamelCase);
  FShared := CreateSerializer(LContractResolver, nil);
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
  LContractResolver: IJsonContractResolver;
begin
  LContractResolver := TEnhancedContractResolver.Create(TJsonMemberSerialization.Public, TJsonNamingPolicy.CamelCase);
  Result := CreateSerializer(LContractResolver, nil);
end;

class function TJsonSerializerFactory.CreateSerializer(const AContractResolver: IJsonContractResolver; const AConverters: TList<TJsonConverter>): TJsonSerializer;
begin
  Result := NewSerializer(AContractResolver, AConverters);
end;


end.
