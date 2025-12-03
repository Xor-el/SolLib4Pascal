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

unit SlpConfigObject;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
  System.TypInfo,
  SlpValueHelpers;

type
  /// <summary>
  /// Helper record that holds a key-value config pair that filters out null values.
  /// </summary>
  TKeyValue = record
  private
    FKey: string;
    FValue: TValue;
    FHasValue: Boolean;
  public
    class function From(const AKey: string; const AValue: TValue): TKeyValue; static;
    class function TryMake(const AKey: string; const AValue: TValue; out KV: TKeyValue): Boolean; static;
    class function Make(const AKey: string; const AValue: TValue): TKeyValue; static;

    function IsValid: Boolean;
    function HasValue: Boolean; inline;

    property Key: string read FKey;
    property Value: TValue read FValue;

  end;

  /// <summary>
  /// Helper class to create configuration objects with key-value pairs that filters out "nullish" values.
  /// Returns nil if no valid pairs.
  /// </summary>
  TConfigObject = class sealed
  public
    class function Make(const Pair1: TKeyValue): TDictionary<string, TValue>; overload; static;
    class function Make(const Pair1, Pair2: TKeyValue): TDictionary<string, TValue>; overload; static;
    class function Make(const Pair1, Pair2, Pair3: TKeyValue): TDictionary<string, TValue>; overload; static;
    class function Make(const Pair1, Pair2, Pair3, Pair4: TKeyValue): TDictionary<string, TValue>; overload; static;
    class function Make(const Pair1, Pair2, Pair3, Pair4, Pair5: TKeyValue): TDictionary<string, TValue>; overload; static;
  end;

  /// <summary>
  /// Helper class that creates a List of parameters and filters out "nullish" values.
  /// Returns nil if no valid entries.
  /// </summary>
  TParameters = class sealed
    class function IsNullish(const V: TValue): Boolean; static;
  public
    class function Make(const V1: TValue): TList<TValue>; overload; static;
    class function Make(const V1, V2: TValue): TList<TValue>; overload; static;
    class function Make(const V1, V2, V3: TValue): TList<TValue>; overload; static;
  end;

implementation

{ Utilities }

function IsNullishValue(const V: TValue): Boolean;
var
  Ctx: TRttiContext;
  RType: TRttiType;
  HasValueMeth: TRttiMethod;
  Ret: TValue;
  DynArray: Pointer;
begin
  // Uninitialized TValue
  if V.IsEmpty then
    Exit(True);

  // Nil object/interface wrapped in TValue
  case V.Kind of
    tkClass:
      Exit(V.AsObject = nil);
    tkInterface:
      Exit(IInterface(V.AsInterface) = nil);
    tkString, tkLString, tkWString, tkUString:
      Exit(V.AsString = '');
    tkDynArray:
      begin
        DynArray := V.GetReferenceToRawData;
        if (DynArray = nil) or (V.GetArrayLength = 0) then
          Exit(True);
      end;
  end;

  // Handle TNullable<T> and TKeyValue (record with HasValue: Boolean)
  if (V.Kind = tkRecord) then
  begin
    Ctx := TRttiContext.Create;
    try
      RType := Ctx.GetType(V.TypeInfo);
      // Look for a parameterless method named "HasValue" returning Boolean
      HasValueMeth := RType.GetMethod('HasValue');
      if Assigned(HasValueMeth)
        and (Length(HasValueMeth.GetParameters) = 0)
        and Assigned(HasValueMeth.ReturnType)
        and (HasValueMeth.ReturnType.Handle = TypeInfo(Boolean)) then
      begin
        Ret := HasValueMeth.Invoke(V, []);
        Exit(not Ret.AsBoolean); // nullish if NOT HasValue
      end;
    finally
      Ctx.Free;
    end;
  end;

  // Note: numeric 0, False, and other "falsy" values are NOT treated as nullish
  Result := False;
end;

{ TKeyValue }

class function TKeyValue.From(const AKey: string; const AValue: TValue): TKeyValue;
begin
  Result.FKey := AKey;
  Result.FValue := AValue;
  Result.FHasValue := True;
end;

function TKeyValue.HasValue: Boolean;
begin
  Result := FHasValue;
end;

class function TKeyValue.TryMake(const AKey: string; const AValue: TValue; out KV: TKeyValue): Boolean;
begin
  Result := not IsNullishValue(AValue);
  if Result then
    KV := TKeyValue.From(AKey, AValue)
  else
    KV := Default(TKeyValue);
end;

class function TKeyValue.Make(const AKey: string; const AValue: TValue): TKeyValue;
begin
   TKeyValue.TryMake(AKey, AValue, Result);
end;

function TKeyValue.IsValid: Boolean;
begin
  Result := not IsNullishValue(FValue);
end;

{ TConfigObject }

class function TConfigObject.Make(const Pair1: TKeyValue): TDictionary<string, TValue>;
begin
  if Pair1.IsValid then
  begin
    Result := TDictionary<string, TValue>.Create;
    Result.Add(Pair1.Key, Pair1.Value);
  end
  else
    Result := nil;
end;

class function TConfigObject.Make(const Pair1, Pair2: TKeyValue): TDictionary<string, TValue>;
begin
  Result := Make(Pair1);
  if not Assigned(Result) then
    Result := TDictionary<string, TValue>.Create;

  if Pair2.IsValid then
    Result.Add(Pair2.Key, Pair2.Value);

  if Result.Count = 0 then
  begin
    Result.Free;
    Result := nil;
  end;
end;

class function TConfigObject.Make(const Pair1, Pair2, Pair3: TKeyValue): TDictionary<string, TValue>;
begin
  Result := Make(Pair1, Pair2);
  if not Assigned(Result) then
    Result := TDictionary<string, TValue>.Create;

  if Pair3.IsValid then
    Result.Add(Pair3.Key, Pair3.Value);

  if Result.Count = 0 then
  begin
    Result.Free;
    Result := nil;
  end;
end;

class function TConfigObject.Make(const Pair1, Pair2, Pair3, Pair4: TKeyValue): TDictionary<string, TValue>;
begin
  Result := Make(Pair1, Pair2, Pair3);
  if not Assigned(Result) then
    Result := TDictionary<string, TValue>.Create;

  if Pair4.IsValid then
    Result.Add(Pair4.Key, Pair4.Value);

  if Result.Count = 0 then
  begin
    Result.Free;
    Result := nil;
  end;
end;

class function TConfigObject.Make(const Pair1, Pair2, Pair3, Pair4, Pair5: TKeyValue): TDictionary<string, TValue>;
begin
  Result := Make(Pair1, Pair2, Pair3, Pair4);
  if not Assigned(Result) then
    Result := TDictionary<string, TValue>.Create;

  if Pair5.IsValid then
    Result.Add(Pair5.Key, Pair5.Value);

  if Result.Count = 0 then
  begin
    Result.Free;
    Result := nil;
  end;
end;

{ TParameters }

class function TParameters.IsNullish(const V: TValue): Boolean;
begin
  Result := IsNullishValue(V);
end;

class function TParameters.Make(const V1: TValue): TList<TValue>;
begin
  if not IsNullish(V1) then
  begin
    Result := TList<TValue>.Create;
    Result.Add(V1);
  end
  else
    Result := nil;
end;

class function TParameters.Make(const V1, V2: TValue): TList<TValue>;
begin
  Result := Make(V1);
  if not Assigned(Result) then
    Result := TList<TValue>.Create;

  if not IsNullish(V2) then
    Result.Add(V2);

  if Result.Count = 0 then
  begin
    Result.Free;
    Result := nil;
  end;
end;

class function TParameters.Make(const V1, V2, V3: TValue): TList<TValue>;
begin
  Result := Make(V1, V2);
  if not Assigned(Result) then
    Result := TList<TValue>.Create;

  if not IsNullish(V3) then
    Result.Add(V3);

  if Result.Count = 0 then
  begin
    Result.Free;
    Result := nil;
  end;
end;

end.

