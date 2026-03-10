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

unit SlpMathUtils;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Math;

type
  TMathUtils = class
  private
    // Machine epsilon for Double at 1.0, computed at runtime.
    class var FEps: Double;
    class constructor Create;
    class function ULPAt(const AX: Double): Double; static;
  public
    class function DoubleToUInt64(const AV: Double): UInt64; static;
    class function DoubleToNativeUInt(const AV: Double): NativeUInt; static;
  end;

implementation

{ TMathUtils }

class constructor TMathUtils.Create;
var
  LEps, LOne: Double;
begin
  // Compute machine epsilon for Double: smallest LEps where 1 + LEps > 1
  LOne := 1.0;
  LEps := 1.0;
  repeat
    LEps := LEps * 0.5;
  until (LOne + LEps = LOne);
  FEps := LEps * 2.0; // last LEps that still changed 1.0
end;

class function TMathUtils.ULPAt(const AX: Double): Double;
var
  LM: Double;
  LE: Integer;
begin
  // Decompose AX ~ LM * 2^LE with LM in [0.5, 1). ULP(AX) ~ FEps * 2^LE for Double.
  Frexp(AX, LM, LE);
  Result := Ldexp(1.0, LE) * FEps; // FEps scaled by exponent near AX
end;

class function TMathUtils.DoubleToUInt64(const AV: Double): UInt64;
const
  TWO63: Double = 9223372036854775808.0;    // 2^63
  MAXU64: Double = 18446744073709551615.0;   // 2^64 - 1 (not exact as Double)
  K_SNAP: Integer = 16;                      // snap window = 16 ULPs
var
  LW, LSnap, LWInt: Double;
  LUlp: Double;
begin
  // Treat NaN as 0.0
  if IsNan(AV) then
    LW := 0.0
  else
    LW := AV;

  // Clamp in floating space first
  LW := EnsureRange(LW, 0.0, MAXU64);

  // Adaptive snap: if we're within K * ULP of the ceiling, snap to exact High(UInt64)
  LUlp := ULPAt(MAXU64);
  LSnap := LUlp * K_SNAP;
  if LW >= (MAXU64 - LSnap) then
  begin
    Exit(High(UInt64));
  end;

  // Drop fraction; avoid overflow by splitting around 2^63
  LWInt := Int(LW); // Int(Double) -> Double
  if LWInt < TWO63 then
    Result := UInt64(Int64(Trunc(LWInt)))
  else
    Result := (UInt64(1) shl 63) + UInt64(Int64(Trunc(LWInt - TWO63)));
end;

class function TMathUtils.DoubleToNativeUInt(const AV: Double): NativeUInt;
var
  LW, LWInt: Double;
begin
  if SizeOf(NativeUInt) = 8 then
    Exit(NativeUInt(DoubleToUInt64(AV)));

  if IsNan(AV) then
    LW := 0.0
  else
    LW := AV;

  LW := EnsureRange(LW, 0.0, Double(High(NativeUInt)));
  LWInt := Int(LW);
  Result := NativeUInt(Cardinal(Trunc(LWInt)));
end;

end.
