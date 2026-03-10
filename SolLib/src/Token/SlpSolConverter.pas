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
    const LAMPORTS_PER_SOL = 1000000000; // 10^9 lamports per SOL

    /// <summary>
    /// Convert Lamports value into SOL double value.
    /// </summary>
    class function ConvertToSol(const ALamports: UInt64): Double; static;

    /// <summary>
    /// Convert a SOL double value into Lamports (UInt64) value.
    /// </summary>
    class function ConvertToLamports(const ASol: Double): UInt64; static;
  end;

implementation

{ TSolConverter }

class function TSolConverter.ConvertToSol(const ALamports: UInt64): Double;
begin
  Result := SimpleRoundTo(ALamports / LAMPORTS_PER_SOL, -9);
end;

class function TSolConverter.ConvertToLamports(const ASol: Double): UInt64;
function DoubleToUInt64Safe(const AD: Double): UInt64;
begin
  if IsNan(AD) or IsInfinite(AD) then
    raise EConvertError.Create('Invalid floating-point value');

  if (Frac(AD) <> 0) or (AD < 0) or (AD > High(UInt64)) then
    raise EConvertError.Create('Cannot convert without loss');

  Result := TMathUtils.DoubleToUInt64(AD);//UInt64(Round(D));
end;

begin
  Result := DoubleToUInt64Safe(ASol * LAMPORTS_PER_SOL);
end;

end.

