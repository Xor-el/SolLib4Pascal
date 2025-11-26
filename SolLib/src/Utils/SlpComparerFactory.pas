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

unit SlpComparerFactory;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Hash,
  System.Generics.Defaults;

type
  /// <summary>
  /// Factory for string equality comparers and dictionaries.
  /// </summary>
  TStringComparerFactory = class sealed
  public
    /// <summary>
    /// Case-insensitive comparer for strings.
    /// </summary>
    class function OrdinalIgnoreCase: IEqualityComparer<string>; static;
  end;

implementation

{ TStringComparerFactory }

class function TStringComparerFactory.OrdinalIgnoreCase: IEqualityComparer<string>;
begin
  // Build a comparer that treats strings case-insensitively
  Result := TEqualityComparer<string>.Construct(
    function(const Left, Right: string): Boolean
    begin
      Result := SameText(Left, Right);
    end,
    function(const Value: string): Integer
    begin
      Result := THashBobJenkins.GetHashValue(UpperCase(Value));
    end
  );
end;

end.

