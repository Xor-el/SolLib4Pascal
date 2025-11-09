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

unit SlpValueHelpers;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  SlpValueUtils;

type
  /// Helper for TValue with utilities such as unboxing nested TValue wrappers.
  TValueHelper = record helper for TValue
  public
    /// Peel off up to a few layers of TValue->TValue boxing and return the innermost value.
    function Unwrap: TValue;

    function Clone(): TValue;

    function ToStringExtended: string;
  end;

implementation

{ TValueHelper }

function TValueHelper.Unwrap: TValue;
begin
  Result := TValueUtils.UnwrapValue(Self);
end;

function TValueHelper.Clone: TValue;
begin
   Result := TValueUtils.CloneValue(Self);
end;

function TValueHelper.ToStringExtended: string;
begin
  Result := TValueUtils.ToStringExtended(Self);
end;

end.

