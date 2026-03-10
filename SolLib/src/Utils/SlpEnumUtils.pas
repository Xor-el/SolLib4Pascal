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

unit SlpEnumUtils;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.TypInfo,
  SlpSolLibTypes;

type
  /// <summary>
  /// Utility class for enum operations
  /// Works with ordinals; callers cast to their enum type e.g. TMyEnum(ordinal).
  /// </summary>
  TEnumUtils = class sealed(TObject)
  strict private
    class function DefaultReplacer(const AInput: string): string; static;
  public
    /// <summary>
    /// Returns an array of ordinals for all defined values of the enum.
    /// For enums with gaps, only ordinals that have a name are included.
    /// Caller casts: TMyEnum(GetEnumValues(TypeInfo(TMyEnum))[i]).
    /// </summary>
    class function GetEnumValues(ATypeInfo: PTypeInfo): TArray<Int32>; overload; static;
    /// <summary>
    /// Tries to parse a string as an enum ordinal. Only parses single named
    /// constants: non-empty, first character a letter, no comma. When AReplacer
    /// is nil, the input is normalized by replacing '+', '-' and '/' with '_'
    /// before parsing; when AReplacer is assigned, it is applied to the input and the
    /// result is used. Returns True and the ordinal in AResult when successful;
    /// otherwise False and AResult is undefined. Caller casts: TMyEnum(AResult).
    /// </summary>
    /// <param name="AReplacer">Optional. When nil, default normalization is used; when assigned, AReplacer(AInput) is used as the string to parse.</param>
    class function TryGetEnumValue(ATypeInfo: PTypeInfo; const AInput: String; out AResult: Int32;
      const AReplacer: TFunc<string, string> = nil): Boolean; overload; static;
    /// <summary>
    /// Converts an enum ordinal to its declared name string.
    /// Returns the result of GetEnumName(ATypeInfo, AOrdinal). Empty string if no name.
    /// </summary>
    class function ToString(ATypeInfo: PTypeInfo; AOrdinal: Int32): String; reintroduce; overload; static;

    // Generic overloads (T must be an enum); delegate to PTypeInfo versions.

    /// <summary>
    /// Returns an array of all defined values of the enum. Delegates to
    /// GetEnumValues(PTypeInfo).
    /// </summary>
    class function GetEnumValues<T>: TArray<T>; overload; static;
    /// <summary>
    /// Tries to parse a string as an enum value. When AReplacer is nil, default
    /// normalization ( '+', '-' and '/' to '_' ) is used; when assigned,
    /// AReplacer(AInput) is used. Delegates to TryGetEnumValue(PTypeInfo, AInput, out Int32, AReplacer).
    /// On failure, AResult is Default(T).
    /// </summary>
    /// <param name="AReplacer">Optional. When nil, default normalization is used; when assigned, AReplacer(AInput) is used as the string to parse.</param>
    class function TryGetEnumValue<T>(const AInput: String; out AResult: T;
      const AReplacer: TFunc<string, string> = nil): Boolean; overload; static;
    /// <summary>
    /// Tries to interpret an ordinal as a valid named value of the enum.
    /// Uses the same validity rule as ToString (ordinal has a name). On success
    /// sets AResult to T(AOrdinal) and returns True; otherwise AResult is
    /// Default(T) and returns False.
    /// </summary>
    class function TryGetEnumFromOrdinal<T>(AOrdinal: Int32; out AResult: T): Boolean; static;
    /// <summary>
    /// Converts an enum value to its declared name string.
    /// </summary>
    class function ToString<T>(const AValue: T): String; reintroduce; overload; static;
  end;

implementation

{ TEnumUtils }

class function TEnumUtils.DefaultReplacer(const AInput: string): string;
begin
  Result := StringReplace(AInput, '+', '_', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '-', '_', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '/', '_', [rfReplaceAll, rfIgnoreCase]);
end;

class function TEnumUtils.GetEnumValues(ATypeInfo: PTypeInfo): TArray<Int32>;
var
  LTypeData: PTypeData;
  I, LOrd: Int32;
  LList: TArray<Int32>;
  LCount: Int32;
begin
  if (ATypeInfo = nil) or (ATypeInfo^.Kind <> tkEnumeration) then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  LTypeData := GetTypeData(ATypeInfo);
  LCount := 0;
  SetLength(LList, LTypeData^.MaxValue - LTypeData^.MinValue + 1);
  for I := LTypeData^.MinValue to LTypeData^.MaxValue do
  begin
    if GetEnumName(ATypeInfo, I) <> '' then
    begin
      LList[LCount] := I;
      Inc(LCount);
    end;
  end;
  SetLength(Result, LCount);
  for LOrd := 0 to LCount - 1 do
    Result[LOrd] := LList[LOrd];
end;

class function TEnumUtils.TryGetEnumValue(ATypeInfo: PTypeInfo; const AInput: String;
  out AResult: Int32; const AReplacer: TFunc<string, string>): Boolean;
var
  LProcessed: String;
  LOrd: LongInt;
begin
  AResult := 0;
  if (ATypeInfo = nil) or (ATypeInfo^.Kind <> tkEnumeration) then
  begin
    Result := False;
    Exit;
  end;
  // Only parse single named constants: non-empty, first char a letter, no comma
  if (System.Length(AInput) = 0) or (Pos(',', AInput) > 0) then
  begin
    Result := False;
    Exit;
  end;
  if not CharInSet(AInput[1], ['A'..'Z', 'a'..'z']) then
  begin
    Result := False;
    Exit;
  end;
  if Assigned(AReplacer) then
    LProcessed := AReplacer(AInput)
  else
    LProcessed := DefaultReplacer(AInput);
  LOrd := GetEnumValue(ATypeInfo, LProcessed);
  if LOrd >= 0 then
  begin
    AResult := LOrd;
    Result := True;
  end
  else
    Result := False;
end;

class function TEnumUtils.GetEnumValues<T>: TArray<T>;
var
  LOrds: TArray<Int32>;
  I: Int32;
begin
  LOrds := GetEnumValues(TypeInfo(T));
  SetLength(Result, System.Length(LOrds));
  for I := 0 to System.High(LOrds) do
    Move(LOrds[I], Result[I], SizeOf(T));
end;

class function TEnumUtils.TryGetEnumValue<T>(const AInput: String;
  out AResult: T; const AReplacer: TFunc<string, string>): Boolean;
var
  LOrd: Int32;
begin
  Result := TryGetEnumValue(TypeInfo(T), AInput, LOrd, AReplacer);
  if Result then
    Move(LOrd, AResult, SizeOf(T))
  else
    AResult := Default(T);
end;

class function TEnumUtils.ToString(ATypeInfo: PTypeInfo; AOrdinal: Int32): String;
begin
  Result := '';
  if (ATypeInfo = nil) or (ATypeInfo^.Kind <> tkEnumeration) then
    Exit;
  Result := GetEnumName(ATypeInfo, AOrdinal);
end;

class function TEnumUtils.TryGetEnumFromOrdinal<T>(AOrdinal: Int32;
  out AResult: T): Boolean;
begin
  // We use `ToString` (which calls `GetEnumName`) to validate the ordinal rather than a simple Min/Max Value
  // range check because Delphi supports non-contiguous enums (e.g., A = 0, B = 5, C = 10).
  // GetEnumName returns an empty string for ordinals that fall in gaps between valid values,
  // correctly rejecting them, whereas a range check would incorrectly accept them.
  Result := ToString(TypeInfo(T), AOrdinal) <> '';
  if Result then
    Move(AOrdinal, AResult, SizeOf(T))
  else
    AResult := Default(T);
end;

class function TEnumUtils.ToString<T>(const AValue: T): String;
var
  LOrd: Byte;
begin
  Move(AValue, LOrd, SizeOf(T));
  Result := ToString(TypeInfo(T), LOrd);
end;

end.

