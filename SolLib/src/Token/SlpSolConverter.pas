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

unit SlpSolConverter;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Math,
  SlpMathUtils;

type
  /// <summary>
  /// class for conversion between SOL and Lamports.
  /// </summary>
  TSolConverter = class
  public
    /// <summary>
    /// Number of Lamports per SOL.
    /// </summary>
    const LAMPORTS_PER_SOL = 1000000000; // 1e9

    /// <summary>
    /// Convert Lamports value into SOL double value.
    /// </summary>
    class function ConvertToSol(const Lamports: UInt64): Double; static;

    /// <summary>
    /// Convert a SOL double value into Lamports (UInt64) value.
    /// </summary>
    class function ConvertToLamports(const Sol: Double): UInt64; static;
  end;

implementation

{ TSolConverter }

class function TSolConverter.ConvertToSol(const Lamports: UInt64): Double;
begin
  Result := SimpleRoundTo(Lamports / LAMPORTS_PER_SOL, -9);
end;

class function TSolConverter.ConvertToLamports(const Sol: Double): UInt64;
function DoubleToUInt64Safe(const D: Double): UInt64;
begin
  if IsNan(D) or IsInfinite(D) then
    raise EConvertError.Create('Invalid floating-point value');

  if (Frac(D) <> 0) or (D < 0) or (D > High(UInt64)) then
    raise EConvertError.Create('Cannot convert without loss');

  Result := TMathUtils.DoubleToUInt64(D);//UInt64(Round(D));
end;

begin
  Result := DoubleToUInt64Safe(Sol * LAMPORTS_PER_SOL);
end;

end.

