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

unit SlpMathUtilities;

{$I ../Include/SolLib.inc}

interface

uses
  SysUtils,
  Math;

type
  TMathUtilities = class sealed
  private
    const
      /// <summary>
      /// IEEE 754 Double machine epsilon: the smallest value such that
      /// 1.0 + Eps > 1.0. This is 2^(-52) for 64-bit doubles.
      /// </summary>
      DoubleEpsilon: Double = 2.2204460492503131e-16;

      /// <summary>2^63 as Double, used as the split point for UInt64 conversion.</summary>
      Two63: Double = 9223372036854775808.0;

      /// <summary>
      /// 2^64 - 1 as Double. Not exactly representable (rounds to 2^64),
      /// but used as the clamping ceiling for UInt64 conversion.
      /// </summary>
      MaxU64AsDouble: Double = 18446744073709551615.0;

      /// <summary>
      /// Number of ULPs near MaxU64 within which we snap to High(UInt64).
      /// Accounts for the imprecision of MaxU64 as a Double.
      /// </summary>
      SnapULPs = 16;

    /// <summary>
    /// Returns the Unit in the Last Place (ULP) near AX for Double precision.
    /// ULP is the spacing between adjacent representable doubles near AX.
    /// </summary>
    class function ULPAt(const AX: Double): Double; static;
  public
    /// <summary>
    /// Converts a Double to UInt64 with safe clamping and boundary handling.
    /// NaN maps to 0. Negative values clamp to 0. Values near or above
    /// 2^64-1 snap to High(UInt64). Fractional parts are truncated.
    /// Uses a split around 2^63 to avoid Trunc overflow on large values.
    /// </summary>
    class function DoubleToUInt64(const AV: Double): UInt64; static;

    /// <summary>
    /// Converts a Double to NativeUInt with safe clamping.
    /// On 64-bit platforms, delegates to DoubleToUInt64.
    /// On 32-bit platforms, clamps to [0..High(NativeUInt)] and truncates.
    /// </summary>
    class function DoubleToNativeUInt(const AV: Double): NativeUInt; static;
  end;

implementation

{ TMathUtilities }

class function TMathUtilities.ULPAt(const AX: Double): Double;
var
  LMantissa: Double;
  LExponent: Integer;
begin
  // Decompose AX ~ LMantissa * 2^LExponent with LMantissa in [0.5, 1).
  // ULP(AX) = DoubleEpsilon * 2^LExponent
  Frexp(AX, LMantissa, LExponent);
  Result := Ldexp(1.0, LExponent) * DoubleEpsilon;
end;

class function TMathUtilities.DoubleToUInt64(const AV: Double): UInt64;
var
  LW, LSnap, LWInt: Double;
begin
  // NaN -> 0
  if IsNan(AV) then
    LW := 0.0
  else
    LW := AV;

  // Clamp to [0, MaxU64]
  LW := EnsureRange(LW, 0.0, MaxU64AsDouble);

  // Near the UInt64 ceiling, Double cannot represent all integers.
  // If we're within SnapULPs of MaxU64, snap directly to High(UInt64)
  // to avoid overflow in the Trunc path below.
  LSnap := ULPAt(MaxU64AsDouble) * SnapULPs;
  if LW >= (MaxU64AsDouble - LSnap) then
    Exit(High(UInt64));

  // Truncate fractional part
  LWInt := Int(LW);

  // Split around 2^63 to avoid Int64 overflow:
  // - Below 2^63: fits in Int64, cast directly
  // - At or above 2^63: subtract 2^63, convert remainder, add back
  if LWInt < Two63 then
    Result := UInt64(Int64(Trunc(LWInt)))
  else
    Result := (UInt64(1) shl 63) + UInt64(Int64(Trunc(LWInt - Two63)));
end;

class function TMathUtilities.DoubleToNativeUInt(const AV: Double): NativeUInt;
var
  LW, LWInt: Double;
begin
  if SizeOf(NativeUInt) = 8 then
    Exit(NativeUInt(DoubleToUInt64(AV)));

  // 32-bit path
  if IsNan(AV) then
    LW := 0.0
  else
    LW := AV;

  LW := EnsureRange(LW, 0.0, Double(High(NativeUInt)));
  LWInt := Int(LW);
  Result := NativeUInt(Cardinal(Trunc(LWInt)));
end;

end.
