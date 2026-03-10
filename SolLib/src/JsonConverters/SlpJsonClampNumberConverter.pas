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

unit SlpJsonClampNumberConverter;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Math,
  System.Rtti,
  System.TypInfo,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Serializers,
  SlpBaseJsonConverter,
  SlpMathUtils;

type
  TJsonClampNumberConverter<T> = class(TBaseJsonConverter)
  public
    function CanConvert(ATypeInfo: PTypeInfo): Boolean; override;
    function ReadJson(const AReader: TJsonReader; ATypeInfo: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
  end;

  TJsonUInt64ClampNumberConverter = class(TJsonClampNumberConverter<UInt64>)
  end;

function IsNumericToken(const AToken: TJsonToken): Boolean;
function GetTypeBounds(const ATypeInfo: PTypeInfo; out AMin, AMax: Double): Boolean;
function CreateValueFromDouble(const ATypeInfo: PTypeInfo; const AValue: Double): TValue;

implementation

function IsNumericToken(const AToken: TJsonToken): Boolean;
begin
  Result := AToken in [TJsonToken.Float, TJsonToken.&Integer];
end;

function GetTypeBounds(const ATypeInfo: PTypeInfo; out AMin, AMax: Double): Boolean;
var
  LTypeData: PTypeData;
  LCtx: TRttiContext;
  LRT: TRttiType;
begin
  Result := False;
  LCtx := TRttiContext.Create;
  LRT := LCtx.GetType(ATypeInfo);
  case LRT.TypeKind of
    tkInteger, tkInt64, tkFloat:
      begin
        LTypeData := GetTypeData(ATypeInfo);
        AMin := LTypeData^.MinValue;
        AMax := LTypeData^.MaxValue;
        Result := True;
      end;
  end;
end;

function CreateValueFromDouble(const ATypeInfo: PTypeInfo; const AValue: Double): TValue;
var
  LW, LMinVal, LMaxVal: Double;

  function NaNFix(const AX: Double): Double; inline;
  begin
    if IsNan(AX) then Result := 0.0 else Result := AX;
  end;

begin
  // Integer/ordinal types: clamp then truncate toward zero
  if ATypeInfo = TypeInfo(Byte) then
  begin
    LMinVal := Byte.MinValue; LMaxVal := Byte.MaxValue;
    LW := EnsureRange(NaNFix(AValue), LMinVal, LMaxVal);
    Exit(TValue.From<Byte>(Byte(Trunc(LW))));
  end
  else if ATypeInfo = TypeInfo(ShortInt) then
  begin
    LMinVal := ShortInt.MinValue; LMaxVal := ShortInt.MaxValue;
    LW := EnsureRange(NaNFix(AValue), LMinVal, LMaxVal);
    Exit(TValue.From<ShortInt>(ShortInt(Trunc(LW))));
  end
  else if ATypeInfo = TypeInfo(SmallInt) then
  begin
    LMinVal := SmallInt.MinValue; LMaxVal := SmallInt.MaxValue;
    LW := EnsureRange(NaNFix(AValue), LMinVal, LMaxVal);
    Exit(TValue.From<SmallInt>(SmallInt(Trunc(LW))));
  end
  else if ATypeInfo = TypeInfo(Word) then
  begin
    LMinVal := Word.MinValue; LMaxVal := Word.MaxValue;
    LW := EnsureRange(NaNFix(AValue), LMinVal, LMaxVal);
    Exit(TValue.From<Word>(Word(Trunc(LW))));
  end
  else if ATypeInfo = TypeInfo(Integer) then
  begin
    LMinVal := Integer.MinValue; LMaxVal := Integer.MaxValue;
    LW := EnsureRange(NaNFix(AValue), LMinVal, LMaxVal);
    Exit(TValue.From<Integer>(Integer(Trunc(LW))));
  end
  else if ATypeInfo = TypeInfo(Cardinal) then
  begin
    LMinVal := Cardinal.MinValue; LMaxVal := Cardinal.MaxValue;
    LW := EnsureRange(NaNFix(AValue), LMinVal, LMaxVal);
    Exit(TValue.From<Cardinal>(Cardinal(Trunc(LW))));
  end
  else if ATypeInfo = TypeInfo(Int64) then
  begin
    LMinVal := Int64.MinValue; LMaxVal := Int64.MaxValue;
    LW := EnsureRange(NaNFix(AValue), LMinVal, LMaxVal);
    Exit(TValue.From<Int64>(Int64(Trunc(LW))));
  end
  else if ATypeInfo = TypeInfo(UInt64) then
  begin
    Exit(TValue.From<UInt64>(TMathUtils.DoubleToUInt64(AValue)));
  end
  else if ATypeInfo = TypeInfo(NativeInt) then
  begin
    LMinVal := NativeInt.MinValue; LMaxVal := NativeInt.MaxValue;
    LW := EnsureRange(NaNFix(AValue), LMinVal, LMaxVal);
    Exit(TValue.From<NativeInt>(NativeInt(Trunc(LW))));
  end
  else if ATypeInfo = TypeInfo(NativeUInt) then
  begin
    Exit(TValue.From<UInt64>(TMathUtils.DoubleToNativeUInt(AValue)));
  end
  // Floating types: clamp to finite range and preserve fraction
  else if ATypeInfo = TypeInfo(Single) then
  begin
    LMinVal := Single.MinValue; LMaxVal := Single.MaxValue;
    LW := EnsureRange(NaNFix(AValue), LMinVal, LMaxVal);
    Exit(TValue.From<Single>(Single(LW)));
  end
  else if ATypeInfo = TypeInfo(Double) then
  begin
    LMinVal := Double.MinValue; LMaxVal := Double.MaxValue;
    LW := EnsureRange(NaNFix(AValue), LMinVal, LMaxVal);
    Exit(TValue.From<Double>(NaNFix(LW)));
  end
  else
  begin
    // Fallback
    Exit(TValue.FromVariant(Variant(NaNFix(AValue))));
  end;
end;

{ ===== TJsonClampNumberConverter<T> ===== }

function TJsonClampNumberConverter<T>.CanConvert(ATypeInfo: PTypeInfo): Boolean;
begin
  Result := ATypeInfo.Kind in [tkInteger, tkInt64, tkFloat];
end;

function TJsonClampNumberConverter<T>.ReadJson(const AReader: TJsonReader; ATypeInfo: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  LValue: Double;
begin
  if not IsNumericToken(AReader.TokenType) then
    Exit(TValue.From<T>(Default(T)));

  try
    LValue := Double(AReader.Value.AsExtended);
  except
    Exit(TValue.From<T>(Default(T)));
  end;

  Result := CreateValueFromDouble(ATypeInfo, LValue);
end;

end.

