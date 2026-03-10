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
    class function Make(const APair1: TKeyValue): TDictionary<string, TValue>; overload; static;
    class function Make(const APair1, APair2: TKeyValue): TDictionary<string, TValue>; overload; static;
    class function Make(const APair1, APair2, APair3: TKeyValue): TDictionary<string, TValue>; overload; static;
    class function Make(const APair1, APair2, APair3, APair4: TKeyValue): TDictionary<string, TValue>; overload; static;
    class function Make(const APair1, APair2, APair3, APair4, APair5: TKeyValue): TDictionary<string, TValue>; overload; static;
  end;

  /// <summary>
  /// Helper class that creates a List of parameters and filters out "nullish" values.
  /// Returns nil if no valid entries.
  /// </summary>
  TParameters = class sealed
    class function IsNullish(const AValue: TValue): Boolean; static;
  public
    class function Make(const V1: TValue): TList<TValue>; overload; static;
    class function Make(const V1, V2: TValue): TList<TValue>; overload; static;
    class function Make(const V1, V2, V3: TValue): TList<TValue>; overload; static;
  end;

implementation

{ Utilities }

function IsNullishValue(const AValue: TValue): Boolean;
var
  LCtx: TRttiContext;
  LRType: TRttiType;
  LHasValueMeth: TRttiMethod;
  LRet: TValue;
  LDynArray: Pointer;
begin
  // Uninitialized TValue
  if AValue.IsEmpty then
    Exit(True);

  // Nil object/interface wrapped in TValue
  case AValue.Kind of
    tkClass:
      Exit(AValue.AsObject = nil);
    tkInterface:
      Exit(IInterface(AValue.AsInterface) = nil);
    tkString, tkLString, tkWString, tkUString:
      Exit(AValue.AsString = '');
    tkDynArray:
      begin
        LDynArray := AValue.GetReferenceToRawData;
        if (LDynArray = nil) or (AValue.GetArrayLength = 0) then
          Exit(True);
      end;
  end;

  // Handle TNullable<T> and TKeyValue (record with HasValue: Boolean)
  if (AValue.Kind = tkRecord) then
  begin
    LCtx := TRttiContext.Create;
    try
      LRType := LCtx.GetType(AValue.TypeInfo);
      // Look for a parameterless method named "HasValue" returning Boolean
      LHasValueMeth := LRType.GetMethod('HasValue');
      if Assigned(LHasValueMeth)
        and (Length(LHasValueMeth.GetParameters) = 0)
        and Assigned(LHasValueMeth.ReturnType)
        and (LHasValueMeth.ReturnType.Handle = TypeInfo(Boolean)) then
      begin
        LRet := LHasValueMeth.Invoke(AValue, []);
        Exit(not LRet.AsBoolean); // nullish if NOT HasValue
      end;
    finally
      LCtx.Free;
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

class function TConfigObject.Make(const APair1: TKeyValue): TDictionary<string, TValue>;
begin
  if APair1.IsValid then
  begin
    Result := TDictionary<string, TValue>.Create;
    Result.Add(APair1.Key, APair1.Value);
  end
  else
    Result := nil;
end;

class function TConfigObject.Make(const APair1, APair2: TKeyValue): TDictionary<string, TValue>;
begin
  Result := Make(APair1);
  if not Assigned(Result) then
    Result := TDictionary<string, TValue>.Create;

  if APair2.IsValid then
    Result.Add(APair2.Key, APair2.Value);

  if Result.Count = 0 then
  begin
    Result.Free;
    Result := nil;
  end;
end;

class function TConfigObject.Make(const APair1, APair2, APair3: TKeyValue): TDictionary<string, TValue>;
begin
  Result := Make(APair1, APair2);
  if not Assigned(Result) then
    Result := TDictionary<string, TValue>.Create;

  if APair3.IsValid then
    Result.Add(APair3.Key, APair3.Value);

  if Result.Count = 0 then
  begin
    Result.Free;
    Result := nil;
  end;
end;

class function TConfigObject.Make(const APair1, APair2, APair3, APair4: TKeyValue): TDictionary<string, TValue>;
begin
  Result := Make(APair1, APair2, APair3);
  if not Assigned(Result) then
    Result := TDictionary<string, TValue>.Create;

  if APair4.IsValid then
    Result.Add(APair4.Key, APair4.Value);

  if Result.Count = 0 then
  begin
    Result.Free;
    Result := nil;
  end;
end;

class function TConfigObject.Make(const APair1, APair2, APair3, APair4, APair5: TKeyValue): TDictionary<string, TValue>;
begin
  Result := Make(APair1, APair2, APair3, APair4);
  if not Assigned(Result) then
    Result := TDictionary<string, TValue>.Create;

  if APair5.IsValid then
    Result.Add(APair5.Key, APair5.Value);

  if Result.Count = 0 then
  begin
    Result.Free;
    Result := nil;
  end;
end;

{ TParameters }

class function TParameters.IsNullish(const AValue: TValue): Boolean;
begin
  Result := IsNullishValue(AValue);
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

