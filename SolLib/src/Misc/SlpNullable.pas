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

unit SlpNullable;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Defaults,
  System.TypInfo,
  SlpEnumUtils;

type
  /// <summary>
  /// Generic nullable wrapper restricted at runtime to value types (non-class).
  /// Accepted kinds: Integer/Int64, Float, Enumeration, Set, Char/WChar, Record.
  /// Rejected kinds: Class, Interface, String types, Dynamic array, Variant, Method, etc.
  /// </summary>
  TNullable<T> = record
  private
    FHasValue: Boolean;
    FValue: T;

    class constructor Create; // runs once per closed generic (e.g., TNullable<Int64>)
    class procedure AssertSupported; static;

  public
    class function Some(const AValue: T): TNullable<T>; static;
    class function None: TNullable<T>; static;

    function HasValue: Boolean; inline;
    function Value: T;
    function TryGetValue(out AValue: T): Boolean; inline;
    function ValueOrDefault(const ADefaultValue: T): T; inline;

    procedure Clear; inline;

    class operator Implicit(const AValue: T): TNullable<T>;
    class operator Explicit(const ANullable: TNullable<T>): T;

    class operator Equal(const ALeft, ARight: TNullable<T>): Boolean;
    class operator NotEqual(const ALeft, ARight: TNullable<T>): Boolean;

    class operator Equal(const ALeft: TNullable<T>; const ARight: T): Boolean;
    class operator NotEqual(const ALeft: TNullable<T>; const ARight: T): Boolean;
    class operator Equal(const ALeft: T; const ARight: TNullable<T>): Boolean;
    class operator NotEqual(const ALeft: T; const ARight: TNullable<T>): Boolean;
  end;

implementation

class procedure TNullable<T>.AssertSupported;
var
  LK: TTypeKind;
begin
  LK := PTypeInfo(TypeInfo(T)).Kind;

  case LK of
    tkInteger, tkInt64, tkEnumeration, tkFloat, tkSet, tkChar, tkWChar, tkRecord:
      Exit; // OK
  else
    raise EInvalidOp.CreateFmt(
      'TNullable<%s> only supports value types (got %s). ' +
      'Disallowed: class/interface/string/dyn array/variant/etc.',
      [GetTypeName(TypeInfo(T)), TEnumUtils.ToString<TTypeKind>(LK)]
    );
  end;
end;

class constructor TNullable<T>.Create;
begin
  AssertSupported; // fires once per T
end;

class function TNullable<T>.Some(const AValue: T): TNullable<T>;
begin
  Result.FHasValue := True;
  Result.FValue := AValue;
end;

class function TNullable<T>.None: TNullable<T>;
begin
  Result.FHasValue := False;
  Result.FValue := Default(T);
end;

function TNullable<T>.HasValue: Boolean;
begin
  Result := FHasValue;
end;

function TNullable<T>.Value: T;
begin
  if not FHasValue then
    raise EInvalidOp.Create('TNullable: value is null');
  Result := FValue;
end;

function TNullable<T>.TryGetValue(out AValue: T): Boolean;
begin
  Result := FHasValue;
  if Result then
    AValue := FValue
  else
    AValue := Default(T);
end;

function TNullable<T>.ValueOrDefault(const ADefaultValue: T): T;
begin
  if FHasValue then
    Result := FValue
  else
    Result := ADefaultValue;
end;

procedure TNullable<T>.Clear;
begin
  FHasValue := False;
  FValue := Default(T);
end;

class operator TNullable<T>.Implicit(const AValue: T): TNullable<T>;
begin
  Result := Some(AValue);
end;

class operator TNullable<T>.Explicit(const ANullable: TNullable<T>): T;
begin
  Result := ANullable.Value; // will raise if FHasValue = false
end;

class operator TNullable<T>.Equal(const ALeft, ARight: TNullable<T>): Boolean;
var
  LCmp: IEqualityComparer<T>;
begin
  if ALeft.FHasValue <> ARight.FHasValue then
    Exit(False);
  if not ALeft.FHasValue then
    Exit(True); // both null
  LCmp := TEqualityComparer<T>.Default;
  Result := LCmp.Equals(ALeft.FValue, ARight.FValue);
end;

class operator TNullable<T>.NotEqual(const ALeft, ARight: TNullable<T>): Boolean;
begin
  Result := not (ALeft = ARight);
end;

class operator TNullable<T>.Equal(const ALeft: TNullable<T>; const ARight: T): Boolean;
begin
  Result := ALeft.FHasValue and TEqualityComparer<T>.Default.Equals(ALeft.FValue, ARight);
end;

class operator TNullable<T>.NotEqual(const ALeft: TNullable<T>; const ARight: T): Boolean;
begin
  Result := not (ALeft = ARight);
end;

class operator TNullable<T>.Equal(const ALeft: T; const ARight: TNullable<T>): Boolean;
begin
  Result := ARight = ALeft;
end;

class operator TNullable<T>.NotEqual(const ALeft: T; const ARight: TNullable<T>): Boolean;
begin
  Result := not (ALeft = ARight);
end;

end.

