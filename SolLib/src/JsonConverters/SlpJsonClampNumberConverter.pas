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
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpBaseJsonConverter,
  SlpMathUtils;

type
  TJsonClampNumberConverter<T> = class(TBaseJsonConverter)
  public
    function CanConvert(ATypeInfo: PTypeInfo): Boolean; override;
    function ReadJson(const AReader: TJsonReader; ATypeInfo: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
  end;

  TJsonUInt64ClampNumberConverter = class(TJsonClampNumberConverter<UInt64>)
  end;

function IsNumericToken(const AToken: TJsonToken): Boolean;
function GetTypeBounds(const ATypeInfo: PTypeInfo; out AMin, AMax: Double): Boolean;
function CreateValueFromDouble(const ATypeInfo: PTypeInfo; const V: Double): TValue;

implementation

function IsNumericToken(const AToken: TJsonToken): Boolean;
begin
  Result := AToken in [TJsonToken.Float, TJsonToken.Integer];
end;

function GetTypeBounds(const ATypeInfo: PTypeInfo; out AMin, AMax: Double): Boolean;
var
  LTypeData: PTypeData;
  Ctx: TRttiContext;
  RT : TRttiType;
begin
  Result := False;
  Ctx := TRttiContext.Create;
  RT := Ctx.GetType(ATypeInfo);
  case RT.TypeKind of
    tkInteger, tkInt64, tkFloat:
      begin
        LTypeData := GetTypeData(ATypeInfo);
        AMin := LTypeData^.MinValue;
        AMax := LTypeData^.MaxValue;
        Result := True;
      end;
  end;
end;

function CreateValueFromDouble(const ATypeInfo: PTypeInfo; const V: Double): TValue;
var
  W, MinVal, MaxVal: Double;

  function NaNFix(const X: Double): Double; inline;
  begin
    if IsNan(X) then Result := 0.0 else Result := X;
  end;

begin
  // Integer/ordinal types: clamp then truncate toward zero
  if ATypeInfo = TypeInfo(Byte) then
  begin
    MinVal := Byte.MinValue; MaxVal := Byte.MaxValue;
    W := EnsureRange(NaNFix(V), MinVal, MaxVal);
    Exit(TValue.From<Byte>(Byte(Trunc(W))));
  end
  else if ATypeInfo = TypeInfo(ShortInt) then
  begin
    MinVal := ShortInt.MinValue; MaxVal := ShortInt.MaxValue;
    W := EnsureRange(NaNFix(V), MinVal, MaxVal);
    Exit(TValue.From<ShortInt>(ShortInt(Trunc(W))));
  end
  else if ATypeInfo = TypeInfo(SmallInt) then
  begin
    MinVal := SmallInt.MinValue; MaxVal := SmallInt.MaxValue;
    W := EnsureRange(NaNFix(V), MinVal, MaxVal);
    Exit(TValue.From<SmallInt>(SmallInt(Trunc(W))));
  end
  else if ATypeInfo = TypeInfo(Word) then
  begin
    MinVal := Word.MinValue; MaxVal := Word.MaxValue;
    W := EnsureRange(NaNFix(V), MinVal, MaxVal);
    Exit(TValue.From<Word>(Word(Trunc(W))));
  end
  else if ATypeInfo = TypeInfo(Integer) then
  begin
    MinVal := Integer.MinValue; MaxVal := Integer.MaxValue;
    W := EnsureRange(NaNFix(V), MinVal, MaxVal);
    Exit(TValue.From<Integer>(Integer(Trunc(W))));
  end
  else if ATypeInfo = TypeInfo(Cardinal) then
  begin
    MinVal := Cardinal.MinValue; MaxVal := Cardinal.MaxValue;
    W := EnsureRange(NaNFix(V), MinVal, MaxVal);
    Exit(TValue.From<Cardinal>(Cardinal(Trunc(W))));
  end
  else if ATypeInfo = TypeInfo(Int64) then
  begin
    MinVal := Int64.MinValue; MaxVal := Int64.MaxValue;
    W := EnsureRange(NaNFix(V), MinVal, MaxVal);
    Exit(TValue.From<Int64>(Int64(Trunc(W))));
  end
  else if ATypeInfo = TypeInfo(UInt64) then
  begin
    Exit(TValue.From<UInt64>(TMathUtils.DoubleToUInt64(V)));
  end
  else if ATypeInfo = TypeInfo(NativeInt) then
  begin
    MinVal := NativeInt.MinValue; MaxVal := NativeInt.MaxValue;
    W := EnsureRange(NaNFix(V), MinVal, MaxVal);
    Exit(TValue.From<NativeInt>(NativeInt(Trunc(W))));
  end
  else if ATypeInfo = TypeInfo(NativeUInt) then
  begin
    Exit(TValue.From<UInt64>(TMathUtils.DoubleToNativeUInt(V)));
  end
  // Floating types: clamp to finite range and preserve fraction
  else if ATypeInfo = TypeInfo(Single) then
  begin
    MinVal := Single.MinValue; MaxVal := Single.MaxValue;
    W := EnsureRange(NaNFix(V), MinVal, MaxVal);
    Exit(TValue.From<Single>(Single(W)));
  end
  else if ATypeInfo = TypeInfo(Double) then
  begin
    MinVal := Double.MinValue; MaxVal := Double.MaxValue;
    W := EnsureRange(NaNFix(V), MinVal, MaxVal);
    Exit(TValue.From<Double>(NaNFix(W)));
  end
  else
  begin
    // Fallback
    Exit(TValue.FromVariant(Variant(NaNFix(V))));
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

procedure TJsonClampNumberConverter<T>.WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
  const ASerializer: TJsonSerializer);
begin
  WriteTValue(AWriter, ASerializer, AValue);
end;

end.

