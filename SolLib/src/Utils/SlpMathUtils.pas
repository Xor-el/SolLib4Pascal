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

unit SlpMathUtils;

{$I ..\Include\SolLib.inc}

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
    class function ULPAt(const X: Double): Double; static;
  public
    class function DoubleToUInt64(const V: Double): UInt64; static;
    class function DoubleToNativeUInt(const V: Double): NativeUInt; static;
  end;

implementation

{ TMathUtils }

class constructor TMathUtils.Create;
var
  eps, one: Double;
begin
  // Compute machine epsilon for Double: smallest eps where 1 + eps > 1
  one := 1.0;
  eps := 1.0;
  repeat
    eps := eps * 0.5;
  until (one + eps = one);
  FEps := eps * 2.0; // last eps that still changed 1.0
end;

class function TMathUtils.ULPAt(const X: Double): Double;
var
  m: Double;
  e: Integer;
begin
  // Decompose X ≈ m * 2^e with m in [0.5, 1). ULP(X) ≈ FEps * 2^e for Double.
  Frexp(X, m, e);
  Result := Ldexp(1.0, e) * FEps; // FEps scaled by exponent near X
end;

class function TMathUtils.DoubleToUInt64(const V: Double): UInt64;
const
  TWO63  : Double = 9223372036854775808.0;    // 2^63
  MAXU64 : Double = 18446744073709551615.0;   // 2^64 - 1 (not exact as Double)
  K_SNAP : Integer = 16;                      // snap window = 16 ULPs
var
  W, snap, wInt: Double;
  ulp: Double;
begin
  // Treat NaN as 0.0
  if IsNan(V) then
    W := 0.0
  else
    W := V;

  // Clamp in floating space first
  W := EnsureRange(W, 0.0, MAXU64);

  // Adaptive snap: if we're within K * ULP of the ceiling, snap to exact High(UInt64)
  ulp  := ULPAt(MAXU64);
  snap := ulp * K_SNAP;
  if W >= (MAXU64 - snap) then
  begin
    Exit(High(UInt64));
  end;

  // Drop fraction; avoid overflow by splitting around 2^63
  wInt := Int(W); // Int(Double) -> Double
  if wInt < TWO63 then
    Result := UInt64(Int64(Trunc(wInt)))
  else
    Result := (UInt64(1) shl 63) + UInt64(Int64(Trunc(wInt - TWO63)));
end;

class function TMathUtils.DoubleToNativeUInt(const V: Double): NativeUInt;
var
  W, wInt: Double;
begin
  if SizeOf(NativeUInt) = 8 then
    Exit(NativeUInt(DoubleToUInt64(V)));

  if IsNan(V) then
    W := 0.0
  else
    W := V;

  W := EnsureRange(W, 0.0, Double(High(NativeUInt)));
  wInt := Int(W);
  Result := NativeUInt(Cardinal(Trunc(wInt)));
end;

end.
