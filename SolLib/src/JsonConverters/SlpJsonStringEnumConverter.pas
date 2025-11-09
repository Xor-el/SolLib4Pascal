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

unit SlpJsonStringEnumConverter;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpStringTransformer,
  SlpJsonKit,
  SlpJsonHelpers;

type
  /// Enum <-> string converter honoring attribute and/or ctor-provided transformer(s).
  /// Resolution order:
  ///   - If not IgnoreTypeAttributes and the enum type has our attribute:
  ///       * Provider-only     -> use Provider.GetTransform
  ///       * Policy-only       -> use Policy transform
  ///       * Both              -> Provider THEN Policy
  ///   - Else use this converter’s own default (built by its constructor):
  ///       * Provider-only     -> use Provider.GetTransform
  ///       * Policy-only       -> use Policy transform
  ///       * Both              -> Provider THEN Policy
  ///       * Neither           -> no transform (raw enum identifier)
  TJsonStringEnumConverter = class(TJsonConverter)
  private
    // Single resolved default for this converter instance (nil = no transform)
    FOwnTransform: TStringTransform;
    // When True, ignore enum-type attributes
    FIgnoreTypeAttributes: Boolean;

    function ResolveTransform(ATypeInf: PTypeInfo; out Transform: TStringTransform): Boolean;
    function TransformName(const S: string; const Transform: TStringTransform): string;
    function TryMapStringToEnum(const ATypeInf: PTypeInfo; const S: string; const Transform: TStringTransform; out EnumValue: Integer): Boolean;

    class function ComposeProviderThenPolicy(
      Provider: TStringTransformProviderClass;
      const Policy: TJsonNamingPolicy): TStringTransform; static;
  public
    // No-op default (no transform unless attribute provides one)
    constructor Create; overload;
    // Policy-only default
    constructor Create(APolicy: TJsonNamingPolicy); overload;
    // Provider-only default
    constructor Create(AProvider: TStringTransformProviderClass); overload;
    // Both (compose Provider first, then Policy)
    constructor Create(APolicy: TJsonNamingPolicy; AProvider: TStringTransformProviderClass); overload;

    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;

    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue;
      const ASerializer: TJsonSerializer): TValue; override;

    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer); override;

    property IgnoreTypeAttributes: Boolean read FIgnoreTypeAttributes write FIgnoreTypeAttributes;
  end;

implementation

resourcestring
  SEnumStringNotMatching = 'Value "%s" does not match enum %s';

{ TJsonStringEnumConverter }

constructor TJsonStringEnumConverter.Create;
begin
  inherited Create;
  FOwnTransform := nil; // no default policy/provider
  FIgnoreTypeAttributes := False;
end;

constructor TJsonStringEnumConverter.Create(APolicy: TJsonNamingPolicy);
begin
  inherited Create;
  // Policy-only default
  FOwnTransform := APolicy.GetFunc();
  FIgnoreTypeAttributes := False;
end;

constructor TJsonStringEnumConverter.Create(AProvider: TStringTransformProviderClass);
begin
  inherited Create;
  // Provider-only default
  if AProvider <> nil then
    FOwnTransform := AProvider.GetTransform()
  else
    FOwnTransform := nil;
  FIgnoreTypeAttributes := False;
end;

constructor TJsonStringEnumConverter.Create(APolicy: TJsonNamingPolicy; AProvider: TStringTransformProviderClass);
begin
  inherited Create;
  // Provider THEN Policy default
  FOwnTransform := ComposeProviderThenPolicy(AProvider, APolicy);
  FIgnoreTypeAttributes := False;
end;

function TJsonStringEnumConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
function IsBooleanType(ATypeInf: PTypeInfo): Boolean; inline;
begin
  Result :=
    (ATypeInf = TypeInfo(Boolean))  or
    (ATypeInf = TypeInfo(ByteBool)) or
    (ATypeInf = TypeInfo(WordBool)) or
    (ATypeInf = TypeInfo(LongBool));
end;
begin
  Result :=
    (ATypeInf <> nil) and
    (ATypeInf^.Kind = tkEnumeration) and
    not IsBooleanType(ATypeInf);
end;

class function TJsonStringEnumConverter.ComposeProviderThenPolicy(
  Provider: TStringTransformProviderClass; const Policy: TJsonNamingPolicy): TStringTransform;
var
  steps: array of TStringTransform;
  n: Integer;
  provT, polT: TStringTransform;
begin
  provT := nil;
  if Provider <> nil then
    provT := Provider.GetTransform();

  polT := Policy.GetFunc();

  n := 0;
  SetLength(steps, 0);

  if Assigned(provT) then
  begin
    SetLength(steps, n + 1);
    steps[n] := provT;
    Inc(n);
  end;

  if Assigned(polT) then
  begin
    SetLength(steps, n + 1);
    steps[n] := polT;
    Inc(n);
  end;

  case n of
    0: Result := nil;
    1: Result := steps[0];
  else
    Result := TStringTransformer.ComposeMany(steps);
  end;
end;

function TJsonStringEnumConverter.ResolveTransform(ATypeInf: PTypeInfo; out Transform: TStringTransform): Boolean;
var
  Ctx: TRttiContext;
  RT : TRttiType;
  Attr: TCustomAttribute;
  TypeAttr: JsonStringEnumAttribute;
begin
  // 1) Enum-type attribute (unless suppressed)
  if not FIgnoreTypeAttributes then
  begin
    Ctx := TRttiContext.Create;
    try
      RT := Ctx.GetType(ATypeInf);
      if RT <> nil then
        for Attr in RT.GetAttributes do
          if Attr is JsonStringEnumAttribute then
          begin
            TypeAttr := JsonStringEnumAttribute(Attr);

            // Provider AND Policy: Provider first, then Policy
            if (TypeAttr.Provider <> nil) and TypeAttr.HasExplicitPolicy then
            begin
              Transform := ComposeProviderThenPolicy(TypeAttr.Provider, TypeAttr.Policy);
              Exit(Assigned(Transform));
            end;

            // Provider-only
            if TypeAttr.Provider <> nil then
            begin
              Transform := TypeAttr.Provider.GetTransform();
              Exit(Assigned(Transform));
            end;

            // Policy-only
            if TypeAttr.HasExplicitPolicy then
            begin
              Transform := TypeAttr.Policy.GetFunc();
              Exit(Assigned(Transform));
            end;

            // Neither → fall through (no transform)
          end;
    finally
      Ctx.Free;
    end;
  end;

  // 2) Converter’s own default (whatever ctor provided)
  Transform := FOwnTransform;          // may be nil (no transform)
  Result := Assigned(Transform);
end;

function TJsonStringEnumConverter.TransformName(const S: string; const Transform: TStringTransform): string;
begin
  if Assigned(Transform) then
    Result := Transform(S)
  else
    Result := S; // no-op if no transform
end;

function TJsonStringEnumConverter.ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  Input: string;
  Transform: TStringTransform;
  EnumValue: Integer;
begin
  if (AReader = nil) or (ATypeInf = nil) then
    Exit(TValue.Empty);

  Input := AReader.Value.AsString;

  ResolveTransform(ATypeInf, Transform);

  // Try via (maybe) transformed names
  if TryMapStringToEnum(ATypeInf, Input, Transform, EnumValue) then
  begin
    TValue.Make(@EnumValue, ATypeInf, Result);
    Exit;
  end;

  // Fallback: original Delphi enum identifier (no transform)
  EnumValue := GetEnumValue(ATypeInf, Input);
  if EnumValue >= 0 then
  begin
    TValue.Make(@EnumValue, ATypeInf, Result);
    Exit;
  end;

  raise EJsonException.CreateFmt(SEnumStringNotMatching, [Input, ATypeInf^.Name]);
end;

procedure TJsonStringEnumConverter.WriteJson(const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer);
var
  Transform: TStringTransform;
  RawName, OutName: string;
begin
  if AValue.IsEmpty then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  ResolveTransform(AValue.TypeInfo, Transform);

  RawName := GetEnumName(AValue.TypeInfo, AValue.AsOrdinal);
  OutName := TransformName(RawName, Transform);

  AWriter.WriteValue(OutName);
end;

function TJsonStringEnumConverter.TryMapStringToEnum(const ATypeInf: PTypeInfo; const S: string;
  const Transform: TStringTransform; out EnumValue: Integer): Boolean;
var
  TD: PTypeData;
  OrdVal: Integer;
  RawName, Transformed: string;
begin
  Result := False;
  EnumValue := -1;

  TD := GetTypeData(ATypeInf);
  if TD = nil then Exit;

  for OrdVal := TD^.MinValue to TD^.MaxValue do
  begin
    RawName := GetEnumName(ATypeInf, OrdVal);
    Transformed := TransformName(RawName, Transform); // if Transform=nil, this is RawName
    if SameText(Transformed, S) then
    begin
      EnumValue := OrdVal;
      Exit(True);
    end;
  end;
end;

end.

