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
  strict private
    class var FOrdinalIgnoreCase: IEqualityComparer<string>;
    class constructor Create;
  public
    /// <summary>
    /// Case-insensitive comparer for strings.
    /// </summary>
    class function OrdinalIgnoreCase: IEqualityComparer<string>; static; inline;
  end;

implementation

{ TStringComparerFactory }

class constructor TStringComparerFactory.Create;
begin
  FOrdinalIgnoreCase := TEqualityComparer<string>.Construct(
    function(const Left, Right: string): Boolean
    begin
      Result := SameText(Left, Right);
    end,
    function(const Value: string):{$IFDEF FPC}UInt32{$ELSE}Integer{$ENDIF}
    begin
      Result := THashBobJenkins.GetHashValue(UpperCase(Value));
    end
  );
end;

class function TStringComparerFactory.OrdinalIgnoreCase: IEqualityComparer<string>;
begin
  Result := FOrdinalIgnoreCase;
end;

end.

