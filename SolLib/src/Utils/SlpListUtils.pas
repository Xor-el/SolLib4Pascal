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

unit SlpListUtils;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpSolLibTypes;

type
  TListUtils = class
  public
    class function Any<T>(const L: TList<T>; const Pred: TPredicate<T>): Boolean; overload; static;
    class function Any<T: class>(const L: TObjectList<T>; const Pred: TPredicate<T>): Boolean; overload; static;

    class function Filter<T>(const L: TList<T>; const Pred: TPredicate<T>): TList<T>; overload; static;
    class function Filter<T: class>(const L: TObjectList<T>; const Pred: TPredicate<T>): TObjectList<T>; overload; static;

    class function FindIndex<T>(const L: TList<T>; const Pred: TPredicate<T>): Integer; overload; static;
    class function FindIndex<T: class>(const L: TObjectList<T>; const Pred: TPredicate<T>): Integer; overload;
  end;

implementation

{ TListUtils }

class function TListUtils.Any<T>(const L: TList<T>; const Pred: TPredicate<T>): Boolean;
var
  Item: T;
begin
  for Item in L do
    if Pred(Item) then
      Exit(True);
  Result := False;
end;

class function TListUtils.Any<T>(const L: TObjectList<T>; const Pred: TPredicate<T>): Boolean;
var
  Item: T;
begin
  for Item in L do
    if Pred(Item) then
      Exit(True);
  Result := False;
end;

class function TListUtils.Filter<T>(const L: TList<T>; const Pred: TPredicate<T>): TList<T>;
var
  Item: T;
begin
  Result := TList<T>.Create;
  for Item in L do
    if Pred(Item) then
      Result.Add(Item);
end;

class function TListUtils.Filter<T>(const L: TObjectList<T>; const Pred: TPredicate<T>): TObjectList<T>;
var
  Item: T;
begin
  Result := TObjectList<T>.Create(L.OwnsObjects);
  for Item in L do
    if Pred(Item) then
      Result.Add(Item);
end;

class function TListUtils.FindIndex<T>(const L: TList<T>; const Pred: TPredicate<T>): Integer;
var
  I: Integer;
begin
  for I := 0 to L.Count - 1 do
    if Pred(L[I]) then
      Exit(I);
  Result := -1;
end;

class function TListUtils.FindIndex<T>(const L: TObjectList<T>; const Pred: TPredicate<T>): Integer;
var
  I: Integer;
begin
  for I := 0 to L.Count - 1 do
    if Pred(L[I]) then
      Exit(I);
  Result := -1;
end;

end.

