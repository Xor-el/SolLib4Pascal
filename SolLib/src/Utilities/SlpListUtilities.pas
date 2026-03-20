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

unit SlpListUtilities;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpSolLibTypes;

type
  TListUtilities = class
  public
    class function Any<T>(const AList: TList<T>; const APred: TPredicate<T>): Boolean; overload; static;
    class function Any<T: class>(const AList: TObjectList<T>; const APred: TPredicate<T>): Boolean; overload; static;

    class function Filter<T>(const AList: TList<T>; const APred: TPredicate<T>): TList<T>; overload; static;
    class function Filter<T: class>(const AList: TObjectList<T>; const APred: TPredicate<T>): TObjectList<T>; overload; static;

    class function FindIndex<T>(const AList: TList<T>; const APred: TPredicate<T>): Integer; overload; static;
    class function FindIndex<T: class>(const AList: TObjectList<T>; const APred: TPredicate<T>): Integer; overload;
  end;

implementation

{ TListUtilities }

class function TListUtilities.Any<T>(const AList: TList<T>; const APred: TPredicate<T>): Boolean;
var
  LItem: T;
begin
  for LItem in AList do
    if APred(LItem) then
      Exit(True);
  Result := False;
end;

class function TListUtilities.Any<T>(const AList: TObjectList<T>; const APred: TPredicate<T>): Boolean;
var
  LItem: T;
begin
  for LItem in AList do
    if APred(LItem) then
      Exit(True);
  Result := False;
end;

class function TListUtilities.Filter<T>(const AList: TList<T>; const APred: TPredicate<T>): TList<T>;
var
  LItem: T;
begin
  Result := TList<T>.Create;
  for LItem in AList do
    if APred(LItem) then
      Result.Add(LItem);
end;

class function TListUtilities.Filter<T>(const AList: TObjectList<T>; const APred: TPredicate<T>): TObjectList<T>;
var
  LItem: T;
begin
  Result := TObjectList<T>.Create(AList.OwnsObjects);
  for LItem in AList do
    if APred(LItem) then
      Result.Add(LItem);
end;

class function TListUtilities.FindIndex<T>(const AList: TList<T>; const APred: TPredicate<T>): Integer;
var
  LI: Integer;
begin
  for LI := 0 to AList.Count - 1 do
    if APred(AList[LI]) then
      Exit(LI);
  Result := -1;
end;

class function TListUtilities.FindIndex<T>(const AList: TObjectList<T>; const APred: TPredicate<T>): Integer;
var
  LI: Integer;
begin
  for LI := 0 to AList.Count - 1 do
    if APred(AList[LI]) then
      Exit(LI);
  Result := -1;
end;

end.

