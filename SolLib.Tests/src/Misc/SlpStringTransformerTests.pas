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

unit SlpStringTransformerTests;

{$SCOPEDENUMS ON}

interface

uses
  SysUtils,
  Generics.Collections,
  System.JSON.Readers,
  System.JSON.Serializers,
{$IFDEF FPC}
  fpcunit,
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpStringTransformer,
  SlpJsonHelpers,
  SlpJsonKit,
  SlpJsonStringEnumConverter,
  SlpRpcEnum,
  SolLibTestCase,
  TestUtils;

type
  [JsonStringEnum(TJsonNamingPolicy.CamelCase)]
  TPolicyEnum = (Unknown, HttpServer, JsonRpc);

  [JsonStringEnum(TCamelCaseTransformProvider)]
  TProviderEnum = (FooBar, HttpServer);

  [JsonStringEnum(TJsonNamingPolicy.SnakeCase, TAcronymNormalizerTransformProvider)]
  TPolicyAndProviderEnum = (HttpServer, HttpRequest);

  TNoAttributeEnum = (Alpha, BetaGamma, DeltaEpsilon);

type
  TEnumForProperty = (HttpServerProp, JsonRpcProp);

  TPropertyAttrDto = class
  private
    FPolicyEnum: TEnumForProperty;
    FProviderEnum: TEnumForProperty;
  public
    [JsonStringEnum(TJsonNamingPolicy.CamelCase)]
    property PolicyEnum: TEnumForProperty read FPolicyEnum write FPolicyEnum;

    [JsonStringEnum(TAcronymNormalizerTransformProvider)]
    property ProviderEnum: TEnumForProperty read FProviderEnum write FProviderEnum;
  end;

type
  TStringTransformerTests = class(TSolLibTestCase)
  published
    // Core TStringTransformer tests
    procedure Identity_ReturnsInputUnchanged;
    procedure Compose_AppliesFirstThenSecond;
    procedure ComposeMany_EmptyAndSingle;
    procedure ComposeMany_SkipsNilSteps;
    procedure NormalizeAcronymsThenSnake_Composed;
    procedure ToCamel_And_ToPascal_Basic;
    procedure ToSnake_And_ToKebab_SplitOnUppercase;
    procedure ToSnake_And_ToKebab_EdgeInputs;
    procedure NormalizeAcronyms_CommonCases;
    procedure NormalizeAcronyms_EdgeInputs;
    procedure MakeSeparatedNamer_And_MakeAcronymNormalizer;

    // Provider classes and naming policy helper
    procedure Providers_MatchCoreTransforms;
    procedure NamingPolicyHelper_MapsToExpectedTransforms;

    // JsonStringEnumAttribute on enum types
    procedure EnumAttribute_PolicyOnly_CamelCase_Roundtrip;
    procedure EnumAttribute_PolicyOnly_AllValues_Roundtrip;
    procedure EnumAttribute_ProviderOnly_CamelCase_Roundtrip;
    procedure EnumAttribute_ProviderThenPolicy_Composed;
    procedure EnumAttribute_NoAttribute_FallsBackToConverterDefault;
    procedure EnumAttribute_IgnoreTypeAttributes_UsesConverterDefault;

    // JsonStringEnumAttribute on properties
    procedure PropertyAttribute_PolicyAndProvider_Roundtrip;

    // Negative / edge cases for TJsonStringEnumConverter
    procedure EnumConverter_UnmatchedString_RaisesMeaningfulError;
    procedure ReadJson_FallbackToRawIdentifier;
  end;

implementation

{ TStringTransformerTests - core transforms }

procedure TStringTransformerTests.Identity_ReturnsInputUnchanged;
var
  LFn: TStringTransform;
  LInputs, LOutputs: array[0..4] of string;
  I: Integer;
begin
  LFn := TStringTransformer.Identity();

  LInputs[0] := '';
  LInputs[1] := 'a';
  LInputs[2] := 'Hello';
  LInputs[3] := 'MiXeD123';
  LInputs[4] := 'üñîçødé';

  for I := Low(LInputs) to High(LInputs) do
  begin
    LOutputs[I] := LFn(LInputs[I]);
    AssertEquals(LInputs[I], LOutputs[I], 'Identity must return input unchanged');
  end;
end;

procedure TStringTransformerTests.Compose_AppliesFirstThenSecond;
var
  LUpper, LAddSuffix, LComposed: TStringTransform;
begin
  LUpper :=
    function(const S: string): string
    begin
      Result := UpperCase(S);
    end;

  LAddSuffix :=
    function(const S: string): string
    begin
      Result := S + '!';
    end;

  LComposed := TStringTransformer.Compose(LUpper, LAddSuffix);

  AssertEquals('HTTP!', LComposed('http'));
end;

procedure TStringTransformerTests.ComposeMany_EmptyAndSingle;
var
  LEmpty, LSingle: TStringTransform;
begin
  LEmpty := TStringTransformer.ComposeMany([]);
  AssertEquals('HTTPServer', LEmpty('HTTPServer'));

  LSingle := TStringTransformer.ComposeMany([TStringTransformer.ToCamel]);
  AssertEquals(TStringTransformer.ToCamel('HTTPServer'), LSingle('HTTPServer'));
end;

procedure TStringTransformerTests.ComposeMany_SkipsNilSteps;
var
  LFn: TStringTransform;
begin
  LFn := TStringTransformer.ComposeMany([nil, TStringTransformer.ToCamel, nil]);
  AssertEquals('hTTPServer', LFn('HTTPServer'),
    'Nil steps should be filtered; only ToCamel should apply');
end;

procedure TStringTransformerTests.NormalizeAcronymsThenSnake_Composed;
var
  LFn: TStringTransform;
begin
  LFn := TStringTransformer.ComposeMany([
    TStringTransformer.MakeAcronymNormalizer(),
    TStringTransformer.MakeSeparatedNamer('_')
  ]);
  AssertEquals('http_server', LFn('HTTPServer'));
  AssertEquals('my_http_server', LFn('MyHTTPServer'));
  AssertEquals('json', LFn('JSON'));
end;

procedure TStringTransformerTests.ToCamel_And_ToPascal_Basic;
begin
  // ToCamel
  AssertEquals('', TStringTransformer.ToCamel(''));
  AssertEquals('a', TStringTransformer.ToCamel('A'));
  AssertEquals('a', TStringTransformer.ToCamel('a'));
  AssertEquals('hello', TStringTransformer.ToCamel('Hello'));

  // ToPascal
  AssertEquals('', TStringTransformer.ToPascal(''));
  AssertEquals('A', TStringTransformer.ToPascal('a'));
  AssertEquals('A', TStringTransformer.ToPascal('A'));
  AssertEquals('Hello', TStringTransformer.ToPascal('hello'));
end;

procedure TStringTransformerTests.ToSnake_And_ToKebab_SplitOnUppercase;
begin
  // Snake
  AssertEquals('http_server', TStringTransformer.ToSnake('HttpServer'));
  AssertEquals('http_server', TStringTransformer.ToSnake('HTTPServer'));
  AssertEquals('json', TStringTransformer.ToSnake('JSON'));

  // Kebab
  AssertEquals('http-server', TStringTransformer.ToKebab('HttpServer'));
  AssertEquals('http-server', TStringTransformer.ToKebab('HTTPServer'));
  AssertEquals('json', TStringTransformer.ToKebab('JSON'));
end;

procedure TStringTransformerTests.ToSnake_And_ToKebab_EdgeInputs;
begin
  // Empty
  AssertEquals('', TStringTransformer.ToSnake(''));
  AssertEquals('', TStringTransformer.ToKebab(''));

  // Single character
  AssertEquals('a', TStringTransformer.ToSnake('a'));
  AssertEquals('a', TStringTransformer.ToSnake('A'));
  AssertEquals('a', TStringTransformer.ToKebab('A'));

  // All lowercase (no boundaries)
  AssertEquals('hello', TStringTransformer.ToSnake('hello'));
  AssertEquals('hello', TStringTransformer.ToKebab('hello'));

  // Mixed with digits
  AssertEquals('item2_count', TStringTransformer.ToSnake('Item2Count'));
  AssertEquals('item2-count', TStringTransformer.ToKebab('Item2Count'));
end;

procedure TStringTransformerTests.NormalizeAcronyms_CommonCases;
begin
  AssertEquals('HttpServer', TStringTransformer.NormalizeAcronyms('HTTPServer'));
  AssertEquals('Http', TStringTransformer.NormalizeAcronyms('HTTP'));
  AssertEquals('X', TStringTransformer.NormalizeAcronyms('X'));
  AssertEquals('MyHttpServer', TStringTransformer.NormalizeAcronyms('MyHTTPServer'));
end;

procedure TStringTransformerTests.NormalizeAcronyms_EdgeInputs;
begin
  // Empty
  AssertEquals('', TStringTransformer.NormalizeAcronyms(''));

  // All lowercase (nothing to normalize)
  AssertEquals('hello', TStringTransformer.NormalizeAcronyms('hello'));

  // No acronym (single leading upper)
  AssertEquals('Hello', TStringTransformer.NormalizeAcronyms('Hello'));

  // Trailing acronym
  AssertEquals('ServerHttp', TStringTransformer.NormalizeAcronyms('ServerHTTP'));

  // Adjacent acronyms
  AssertEquals('HttpsServer', TStringTransformer.NormalizeAcronyms('HTTPSServer'));
end;

procedure TStringTransformerTests.MakeSeparatedNamer_And_MakeAcronymNormalizer;
var
  LSep: TStringTransform;
  LAcr: TStringTransform;
begin
  LSep := TStringTransformer.MakeSeparatedNamer('/');
  AssertEquals('http/server', LSep('HttpServer'));

  LAcr := TStringTransformer.MakeAcronymNormalizer();
  AssertEquals(TStringTransformer.NormalizeAcronyms('HTTPServer'), LAcr('HTTPServer'));
end;

{ Providers and naming policies }

procedure TStringTransformerTests.Providers_MatchCoreTransforms;
var
  LFn: TStringTransform;
begin
  // Identity provider
  LFn := TIdentityTransformProvider.GetTransform();
  AssertEquals('HTTP', LFn('HTTP'));

  // Camel case provider
  LFn := TCamelCaseTransformProvider.GetTransform();
  AssertEquals(TStringTransformer.ToCamel('HTTPServer'), LFn('HTTPServer'));

  // Pascal case provider
  LFn := TPascalCaseTransformProvider.GetTransform();
  AssertEquals(TStringTransformer.ToPascal('httpServer'), LFn('httpServer'));

  // Snake case provider
  LFn := TSnakeCaseTransformProvider.GetTransform();
  AssertEquals(TStringTransformer.ToSnake('HTTPServer'), LFn('HTTPServer'));

  // Kebab case provider
  LFn := TKebabCaseTransformProvider.GetTransform();
  AssertEquals(TStringTransformer.ToKebab('HTTPServer'), LFn('HTTPServer'));

  // Acronym normalizer provider
  LFn := TAcronymNormalizerTransformProvider.GetTransform();
  AssertEquals(TStringTransformer.NormalizeAcronyms('HTTPServer'), LFn('HTTPServer'));
end;

procedure TStringTransformerTests.NamingPolicyHelper_MapsToExpectedTransforms;
var
  LFn: TStringTransform;
begin
  LFn := TJsonNamingPolicy.CamelCase.GetFunc();
  AssertEquals(TStringTransformer.ToCamel('HTTPServer'), LFn('HTTPServer'));

  LFn := TJsonNamingPolicy.PascalCase.GetFunc();
  AssertEquals(TStringTransformer.ToPascal('httpServer'), LFn('httpServer'));

  LFn := TJsonNamingPolicy.SnakeCase.GetFunc();
  AssertEquals(TStringTransformer.ToSnake('HTTPServer'), LFn('HTTPServer'));

  LFn := TJsonNamingPolicy.KebabCase.GetFunc();
  AssertEquals(TStringTransformer.ToKebab('HTTPServer'), LFn('HTTPServer'));
end;

{ JsonStringEnumAttribute on enums }

procedure TStringTransformerTests.EnumAttribute_PolicyOnly_CamelCase_Roundtrip;
var
  LValue: TPolicyEnum;
  LJson: string;
begin
  LValue := TPolicyEnum.HttpServer;
  LJson := TTestUtils.Serialize<TPolicyEnum>(LValue);
  // Expect a bare JSON string \"httpServer\"
  AssertTrue(Pos('httpServer', LJson) > 0, 'CamelCase policy should be applied');

  LValue := TTestUtils.Deserialize<TPolicyEnum>(LJson);
  AssertEquals(Ord(TPolicyEnum.HttpServer), Ord(LValue));
end;

procedure TStringTransformerTests.EnumAttribute_ProviderOnly_CamelCase_Roundtrip;
var
  LValue: TProviderEnum;
  LJson: string;
begin
  LValue := TProviderEnum.HttpServer;
  LJson := TTestUtils.Serialize<TProviderEnum>(LValue);
  // Provider is TCamelCaseTransformProvider
  AssertTrue(Pos('httpServer', LJson) > 0, 'CamelCase provider should be applied');

  LValue := TTestUtils.Deserialize<TProviderEnum>(LJson);
  AssertEquals(Ord(TProviderEnum.HttpServer), Ord(LValue));
end;

procedure TStringTransformerTests.EnumAttribute_ProviderThenPolicy_Composed;
var
  LValue: TPolicyAndProviderEnum;
  LJson: string;
begin
  LValue := TPolicyAndProviderEnum.HttpServer;
  LJson := TTestUtils.Serialize<TPolicyAndProviderEnum>(LValue);
  AssertTrue(Pos('"http_server"', LJson) > 0,
    'NormalizeAcronyms then SnakeCase should produce http_server');

  LValue := TTestUtils.Deserialize<TPolicyAndProviderEnum>(LJson);
  AssertEquals(Ord(TPolicyAndProviderEnum.HttpServer), Ord(LValue));
end;

procedure TStringTransformerTests.EnumAttribute_NoAttribute_FallsBackToConverterDefault;
var
  LValue: TNoAttributeEnum;
  LJson: string;
begin
  LValue := TNoAttributeEnum.BetaGamma;
  LJson := TTestUtils.Serialize<TNoAttributeEnum>(LValue);
  AssertTrue(Pos('"betaGamma"', LJson) > 0,
    'No type attribute -> converter''s own CamelCase default should apply');

  LValue := TTestUtils.Deserialize<TNoAttributeEnum>(LJson);
  AssertEquals(Ord(TNoAttributeEnum.BetaGamma), Ord(LValue));
end;

procedure TStringTransformerTests.EnumAttribute_PolicyOnly_AllValues_Roundtrip;
var
  LValue: TPolicyEnum;
  LJson: string;
  LExpected: array[0..2] of string;
  I: Integer;
begin
  LExpected[0] := 'unknown';
  LExpected[1] := 'httpServer';
  LExpected[2] := 'jsonRpc';

  for I := Ord(TPolicyEnum.Unknown) to Ord(TPolicyEnum.JsonRpc) do
  begin
    LValue := TPolicyEnum(I);
    LJson := TTestUtils.Serialize<TPolicyEnum>(LValue);
    AssertTrue(Pos('"' + LExpected[I] + '"', LJson) > 0,
      'CamelCase mismatch for ordinal ' + IntToStr(I));

    LValue := TTestUtils.Deserialize<TPolicyEnum>(LJson);
    AssertEquals(I, Ord(LValue), 'Roundtrip mismatch for ordinal ' + IntToStr(I));
  end;
end;

procedure TStringTransformerTests.EnumAttribute_IgnoreTypeAttributes_UsesConverterDefault;
var
  LConverter: TJsonStringEnumConverter;
  LConverters: TList<TJsonConverter>;
  LSerializer: TJsonSerializer;
  LJson: string;
  LValue: TPolicyEnum;
begin
  LConverter := TJsonStringEnumConverter.Create(TJsonNamingPolicy.SnakeCase);
  LConverter.IgnoreTypeAttributes := True;
  LConverters := TList<TJsonConverter>.Create;
  try
    LConverters.Add(LConverter);
    LSerializer := TJsonSerializerFactory.CreateSerializer(
      TEnhancedContractResolver.Create(
        TJsonMemberSerialization.Public,
        TJsonNamingPolicy.CamelCase),
      LConverters);
    try
      LJson := LSerializer.Serialize<TPolicyEnum>(TPolicyEnum.HttpServer);
      AssertTrue(Pos('"http_server"', LJson) > 0,
        'IgnoreTypeAttributes should bypass CamelCase attribute and use SnakeCase');

      LValue := LSerializer.Deserialize<TPolicyEnum>(LJson);
      AssertEquals(Ord(TPolicyEnum.HttpServer), Ord(LValue));
    finally
      LSerializer.Free;
    end;
  finally
    LConverter.Free;
    LConverters.Free;
  end;
end;

{ JsonStringEnumAttribute on properties }

procedure TStringTransformerTests.PropertyAttribute_PolicyAndProvider_Roundtrip;
var
  LDto: TPropertyAttrDto;
  LJson: string;
  LDto2: TPropertyAttrDto;
begin
  LDto := TPropertyAttrDto.Create;
  try
    LDto.PolicyEnum := TEnumForProperty.HttpServerProp;
    LDto.ProviderEnum := TEnumForProperty.JsonRpcProp;

    LJson := TTestUtils.Serialize<TPropertyAttrDto>(LDto);

    // PolicyEnum uses CamelCase: HttpServerProp -> httpServerProp
    AssertTrue(Pos('"httpServerProp"', LJson) > 0,
      'CamelCase should produce httpServerProp');

    // ProviderEnum uses acronym normalizer: JsonRpcProp -> JsonRpcProp (no acronym)
    AssertTrue(Pos('"JsonRpcProp"', LJson) > 0,
      'AcronymNormalizer should leave JsonRpcProp unchanged');

    LDto2 := TTestUtils.Deserialize<TPropertyAttrDto>(LJson);
    try
      AssertEquals(Ord(TEnumForProperty.HttpServerProp), Ord(LDto2.PolicyEnum));
      AssertEquals(Ord(TEnumForProperty.JsonRpcProp), Ord(LDto2.ProviderEnum));
    finally
      LDto2.Free;
    end;
  finally
    LDto.Free;
  end;
end;

{ Negative / edge cases }

procedure TStringTransformerTests.EnumConverter_UnmatchedString_RaisesMeaningfulError;
begin
  AssertException(
    procedure
    begin
      TTestUtils.Deserialize<TPolicyEnum>('\"doesNotExist\"');
    end,
    EJsonReaderException
  );
end;

procedure TStringTransformerTests.ReadJson_FallbackToRawIdentifier;
var
  LValue: TPolicyAndProviderEnum;
begin
  // TPolicyAndProviderEnum transforms to snake_case (e.g. "http_server"),
  // but ReadJson should also accept the raw Delphi identifier as a fallback
  LValue := TTestUtils.Deserialize<TPolicyAndProviderEnum>('"HttpServer"');
  AssertEquals(Ord(TPolicyAndProviderEnum.HttpServer), Ord(LValue));

  LValue := TTestUtils.Deserialize<TPolicyAndProviderEnum>('"HttpRequest"');
  AssertEquals(Ord(TPolicyAndProviderEnum.HttpRequest), Ord(LValue));
end;

initialization
{$IFDEF FPC}
  RegisterTest(TStringTransformerTests);
{$ELSE}
  RegisterTest(TStringTransformerTests.Suite);
{$ENDIF}

end.

