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

unit SlpSolConverter;

{$I ../Include/SolLib.inc}

interface

uses
  SysUtils,
  Math,
  SlpMathUtilities;

type
  /// <summary>
  /// Conversion between SOL and Lamports.
  /// 1 SOL = 10^9 Lamports.
  /// </summary>
  TSolConverter = class sealed
  private
    /// <summary>
    /// Safely converts a Double to UInt64 after rounding.
    /// Raises EConvertError for NaN, Infinity, negative values,
    /// or values exceeding High(UInt64).
    /// </summary>
    class function RoundToUInt64(const AValue: Double): UInt64; static;
  public
    /// <summary>Number of Lamports per SOL (10^9).</summary>
    const LamportsPerSol: UInt64 = 1000000000;

    /// <summary>
    /// Convert a Lamports value to SOL.
    /// The result has at most 9 meaningful decimal digits (lamport precision).
    /// </summary>
    class function ConvertToSol(const ALamports: UInt64): Double; static;

    /// <summary>
    /// Convert a SOL value to Lamports.
    /// The Double is multiplied by 10^9, rounded to the nearest integer,
    /// then validated and converted to UInt64.
    /// Raises EConvertError for NaN, Infinity, negative, or out-of-range values.
    /// </summary>
    class function ConvertToLamports(const ASol: Double): UInt64; static;
  end;

implementation

{ TSolConverter }

class function TSolConverter.RoundToUInt64(const AValue: Double): UInt64;
var
  LRounded: Double;
begin
  if IsNan(AValue) or IsInfinite(AValue) then
    raise EConvertError.Create('Invalid floating-point value');
  if AValue < 0 then
    raise EConvertError.Create('Value must be non-negative');

  LRounded := Round(AValue);

  if LRounded > High(UInt64) then
    raise EConvertError.Create('Value exceeds UInt64 range');

  Result := TMathUtilities.DoubleToUInt64(LRounded);
end;

class function TSolConverter.ConvertToSol(const ALamports: UInt64): Double;
begin
  Result := ALamports / LamportsPerSol;
end;

class function TSolConverter.ConvertToLamports(const ASol: Double): UInt64;
begin
  Result := RoundToUInt64(ASol * LamportsPerSol);
end;

end.
