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

unit SlpJsonStringEnumConverter;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpEnumUtils,
  SlpStringTransformer,
  SlpJsonKit,
  SlpRpcEnum,
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

    function ResolveTransform(ATypeInf: PTypeInfo; out ATransform: TStringTransform): Boolean;
    function TransformName(const AStr: string; const ATransform: TStringTransform): string;
    function TryMapStringToEnum(const ATypeInf: PTypeInfo; const AStr: string; const ATransform: TStringTransform; out AEnumValue: Integer): Boolean;

    class function ComposeProviderThenPolicy(
      AProvider: TStringTransformProviderClass;
      const APolicy: TJsonNamingPolicy): TStringTransform; static;
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

  function IsExcludedEnumType(ATypeInf: PTypeInfo): Boolean; inline;
  begin
    Result :=
      (ATypeInf = TypeInfo(Boolean))  or
      (ATypeInf = TypeInfo(ByteBool)) or
      (ATypeInf = TypeInfo(WordBool)) or
      (ATypeInf = TypeInfo(LongBool)) or
      (ATypeInf = TypeInfo(TBinaryEncoding));
  end;

begin
  Result :=
    (ATypeInf <> nil) and
    (ATypeInf^.Kind = tkEnumeration) and
    not IsExcludedEnumType(ATypeInf);
end;

class function TJsonStringEnumConverter.ComposeProviderThenPolicy(
  AProvider: TStringTransformProviderClass; const APolicy: TJsonNamingPolicy): TStringTransform;
var
  LSteps: array of TStringTransform;
  LN: Integer;
  LProvT, LPolT: TStringTransform;
begin
  LProvT := nil;
  if AProvider <> nil then
    LProvT := AProvider.GetTransform();

  LPolT := APolicy.GetFunc();

  LN := 0;
  SetLength(LSteps, 0);

  if Assigned(LProvT) then
  begin
    SetLength(LSteps, LN + 1);
    LSteps[LN] := LProvT;
    Inc(LN);
  end;

  if Assigned(LPolT) then
  begin
    SetLength(LSteps, LN + 1);
    LSteps[LN] := LPolT;
    Inc(LN);
  end;

  case LN of
    0: Result := nil;
    1: Result := LSteps[0];
  else
    Result := TStringTransformer.ComposeMany(LSteps);
  end;
end;

function TJsonStringEnumConverter.ResolveTransform(ATypeInf: PTypeInfo; out ATransform: TStringTransform): Boolean;
var
  LCtx: TRttiContext;
  LRT: TRttiType;
  LAttr: TCustomAttribute;
  LTypeAttr: JsonStringEnumAttribute;
begin
  // 1) Enum-type attribute (unless suppressed)
  if not FIgnoreTypeAttributes then
  begin
    LCtx := TRttiContext.Create;
    try
      LRT := LCtx.GetType(ATypeInf);
      if LRT <> nil then
        for LAttr in LRT.GetAttributes do
          if LAttr is JsonStringEnumAttribute then
          begin
            LTypeAttr := JsonStringEnumAttribute(LAttr);

            // Provider AND Policy: Provider first, then Policy
            if (LTypeAttr.Provider <> nil) and LTypeAttr.HasExplicitPolicy then
            begin
              ATransform := ComposeProviderThenPolicy(LTypeAttr.Provider, LTypeAttr.Policy);
              Exit(Assigned(ATransform));
            end;

            // Provider-only
            if LTypeAttr.Provider <> nil then
            begin
              ATransform := LTypeAttr.Provider.GetTransform();
              Exit(Assigned(ATransform));
            end;

            // Policy-only
            if LTypeAttr.HasExplicitPolicy then
            begin
              ATransform := LTypeAttr.Policy.GetFunc();
              Exit(Assigned(ATransform));
            end;

            // Neither -> fall through (no transform)
          end;
    finally
      LCtx.Free;
    end;
  end;

  // 2) Converter’s own default (whatever ctor provided)
  ATransform := FOwnTransform;          // may be nil (no transform)
  Result := Assigned(ATransform);
end;

function TJsonStringEnumConverter.TransformName(const AStr: string; const ATransform: TStringTransform): string;
begin
  if Assigned(ATransform) then
    Result := ATransform(AStr)
  else
    Result := AStr; // no-op if no transform
end;

function TJsonStringEnumConverter.ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  LInput: string;
  LTransform: TStringTransform;
  LEnumValue: Integer;
begin
  if (AReader = nil) or (ATypeInf = nil) then
    Exit(TValue.Empty);

  LInput := AReader.Value.AsString;

  ResolveTransform(ATypeInf, LTransform);

  // Try via (maybe) transformed names
  if TryMapStringToEnum(ATypeInf, LInput, LTransform, LEnumValue) then
  begin
    TValue.Make(@LEnumValue, ATypeInf, Result);
    Exit;
  end;

  // Fallback: original Delphi enum identifier (no transform)
  if TEnumUtils.TryGetEnumValue(ATypeInf, LInput, LEnumValue) then
  begin
    TValue.Make(@LEnumValue, ATypeInf, Result);
    Exit;
  end;

  raise EJsonException.CreateFmt(SEnumStringNotMatching, [LInput, ATypeInf^.Name]);
end;

procedure TJsonStringEnumConverter.WriteJson(const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer);
var
  LTransform: TStringTransform;
  LRawName, LOutName: string;
begin
  if AValue.IsEmpty then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  ResolveTransform(AValue.TypeInfo, LTransform);

  LRawName := TEnumUtils.ToString(AValue.TypeInfo, AValue.AsOrdinal);
  LOutName := TransformName(LRawName, LTransform);

  AWriter.WriteValue(LOutName);
end;

function TJsonStringEnumConverter.TryMapStringToEnum(const ATypeInf: PTypeInfo; const AStr: string;
  const ATransform: TStringTransform; out AEnumValue: Integer): Boolean;
var
  LTD: PTypeData;
  LOrdVal: Integer;
  LRawName, LTransformed: string;
begin
  Result := False;
  AEnumValue := -1;

  LTD := GetTypeData(ATypeInf);
  if LTD = nil then Exit;

  for LOrdVal := LTD^.MinValue to LTD^.MaxValue do
  begin
    LRawName := TEnumUtils.ToString(ATypeInf, LOrdVal);
    LTransformed := TransformName(LRawName, ATransform); // if ATransform=nil, this is LRawName
    if SameText(LTransformed, AStr) then
    begin
      AEnumValue := LOrdVal;
      Exit(True);
    end;
  end;
end;

end.

