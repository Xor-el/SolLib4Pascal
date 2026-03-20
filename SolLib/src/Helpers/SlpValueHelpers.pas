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

unit SlpValueHelpers;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  SlpValueUtilities;

type
  /// Helper for TValue with utilities such as unboxing nested TValue wrappers.
  TValueHelper = record helper for TValue
  public
    /// <summary>Peels off up to a few layers of TValue->TValue boxing and returns the innermost value.</summary>
    function Unwrap: TValue;

    /// <summary>Returns a deep clone of this value. See TValueUtils.CloneValue.</summary>
    function Clone: TValue;

    /// <summary>Converts this value to a string, including type-specific formatting. See TValueUtils.ToStringExtended.</summary>
    function ToStringExtended: string;
  end;

implementation

{ TValueHelper }

function TValueHelper.Unwrap: TValue;
begin
  Result := TValueUtilities.UnwrapValue(Self);
end;

function TValueHelper.Clone: TValue;
begin
  Result := TValueUtilities.CloneValue(Self);
end;

function TValueHelper.ToStringExtended: string;
begin
  Result := TValueUtilities.ToStringExtended(Self);
end;

end.

