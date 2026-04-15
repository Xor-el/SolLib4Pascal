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

unit JsonStructuralComparer;

interface

uses
  SysUtils,
  Generics.Collections,
  System.JSON,
  Math;

type
  TJsonCompareDiffOptions = record
    EnableDiff: Boolean;
    LineBreak: string;
    IndentSpaces: Integer;
    class function Default: TJsonCompareDiffOptions; static;
  end;

  TJsonCompareOptions = record
    ArrayOrderAgnostic: Boolean;
    TreatNullAndMissingPropertyAsEqual: Boolean;
    EnableNumericTolerance: Boolean;
    NumericTolerance: Double;
    PropertyNameCaseSensitive: Boolean;
    Diff: TJsonCompareDiffOptions;
    class function Default: TJsonCompareOptions; static;
  end;

  TJsonStructuralComparer = class sealed
  private
    class function ObjectsEqual(const ALeft, ARight: TJSONObject; const AOptions: TJsonCompareOptions;
      const APath: string; const ADifferences: TList<string>): Boolean; static;

    class function ArraysEqual(const ALeft, ARight: TJSONArray; const AOptions: TJsonCompareOptions;
      const APath: string; const ADifferences: TList<string>): Boolean; static;

    class function NumbersEqual(const ALeft, ARight: TJSONNumber; const AOptions: TJsonCompareOptions;
      const APath: string; const ADifferences: TList<string>): Boolean; static;

    class function StringsEqual(const ALeft, ARight: TJSONString; const AOptions: TJsonCompareOptions;
      const APath: string; const ADifferences: TList<string>): Boolean; static;

    class function IsJsonNull(const AV: TJSONValue): Boolean; static;
    class function GetJsonBoolean(const AV: TJSONValue; out AValue: Boolean): Boolean; static;
    class function Indent(const AOptions: TJsonCompareOptions; ALevel: Integer): string; static;
    class function PathDepth(const APath: string): Integer; static;

    class function ValuesAreNil(const ALeft, ARight: TJSONValue; const AOptions: TJsonCompareOptions;
      const APath: string; ADifferences: TList<string>): Boolean; static;

    class function BooleanValuesAreEqual(const ALeft, ARight: TJSONValue; const AOptions: TJsonCompareOptions;
      const APath: string; ADifferences: TList<string>): Boolean; static;

    class function ValuesHaveTypeMismatch(const ALeft, ARight: TJSONValue; const AOptions: TJsonCompareOptions;
      const APath: string; ADifferences: TList<string>): Boolean; static;

  public
    class function AreStructurallyEqual(const AJsonA, AJsonB: string;
      const AOptions: TJsonCompareOptions): Boolean; overload; static;

    class function AreStructurallyEqual(const ALeft, ARight: TJSONValue;
      const AOptions: TJsonCompareOptions): Boolean; overload; static;

    class function AreStructurallyEqualWithDiff(const AJsonA, AJsonB: string;
      const AOptions: TJsonCompareOptions; ADifferences: TList<string>): Boolean; overload; static;

    class function AreStructurallyEqualWithDiffString(const AJsonA, AJsonB: string;
      const AOptions: TJsonCompareOptions): string; static;

    class function AreStructurallyEqualWithDiff(const ALeft, ARight: TJSONValue;
      const AOptions: TJsonCompareOptions; const APath: string;
      ADifferences: TList<string>): Boolean; overload; static;
  end;

implementation

{ TJsonCompareDiffOptions }

class function TJsonCompareDiffOptions.Default: TJsonCompareDiffOptions;
begin
  Result.EnableDiff := False;
  Result.LineBreak := sLineBreak;
  Result.IndentSpaces := 2;
end;

{ TJsonCompareOptions }

class function TJsonCompareOptions.Default: TJsonCompareOptions;
begin
  Result.ArrayOrderAgnostic := False;
  Result.TreatNullAndMissingPropertyAsEqual := False;
  Result.EnableNumericTolerance := False;
  Result.NumericTolerance := 1e-9;
  Result.PropertyNameCaseSensitive := True;
  Result.Diff := TJsonCompareDiffOptions.Default;
end;

{ Helpers }

class function TJsonStructuralComparer.Indent(const AOptions: TJsonCompareOptions; ALevel: Integer): string;
begin
  Result := StringOfChar(' ', ALevel * AOptions.Diff.IndentSpaces);
end;

class function TJsonStructuralComparer.PathDepth(const APath: string): Integer;
var
  LI: Integer;
begin
  Result := 0;
  for LI := 1 to Length(APath) do
    if CharInSet(APath[LI], ['.', '[']) then
      Inc(Result);
end;

class function TJsonStructuralComparer.IsJsonNull(const AV: TJSONValue): Boolean;
begin
  Result := (AV = nil) or (AV is TJSONNull);
end;

class function TJsonStructuralComparer.GetJsonBoolean(const AV: TJSONValue; out AValue: Boolean): Boolean;
begin
  if AV is TJSONTrue then
  begin
    AValue := True;
    Exit(True);
  end
  else if AV is TJSONFalse then
  begin
    AValue := False;
    Exit(True);
  end;
  Result := False;
end;

{ Nil / Boolean / Type checks }

class function TJsonStructuralComparer.ValuesAreNil(const ALeft, ARight: TJSONValue;
  const AOptions: TJsonCompareOptions; const APath: string;
  ADifferences: TList<string>): Boolean;
var
  LLevel: Integer;
begin
  LLevel := PathDepth(APath);
  if IsJsonNull(ALeft) and IsJsonNull(ARight) then
    Exit(True);

  if IsJsonNull(ALeft) or IsJsonNull(ARight) then
  begin
    if AOptions.TreatNullAndMissingPropertyAsEqual then
      Exit(True);

    if ADifferences <> nil then
      ADifferences.Add(Format('%sOne value is null or missing at %s', [Indent(AOptions, LLevel), APath]));
    Exit(False);
  end;

  Result := False;
end;

class function TJsonStructuralComparer.BooleanValuesAreEqual(const ALeft, ARight: TJSONValue;
  const AOptions: TJsonCompareOptions; const APath: string;
  ADifferences: TList<string>): Boolean;
var
  LBoolA, LBoolB: Boolean;
  LLevel: Integer;
  LIsBoolA, LIsBoolB: Boolean;
begin
  LLevel := PathDepth(APath);
  LIsBoolA := GetJsonBoolean(ALeft, LBoolA);
  LIsBoolB := GetJsonBoolean(ARight, LBoolB);

  if not (LIsBoolA and LIsBoolB) then
    Exit(False);

  Result := LBoolA = LBoolB;
  if (ADifferences <> nil) and not Result then
    ADifferences.Add(Format('%sBoolean mismatch %s vs %s at %s',
      [Indent(AOptions, LLevel), BoolToStr(LBoolA, True), BoolToStr(LBoolB, True), APath]));
end;

class function TJsonStructuralComparer.ValuesHaveTypeMismatch(const ALeft, ARight: TJSONValue;
  const AOptions: TJsonCompareOptions; const APath: string;
  ADifferences: TList<string>): Boolean;
var
  LLevel: Integer;
  LTypeA, LTypeB: string;
begin
  LLevel := PathDepth(APath);
  if (ALeft = nil) or (ARight = nil) then
    Exit(False);

  if (ALeft is TJSONTrue) or (ALeft is TJSONFalse) then LTypeA := 'Boolean'
  else if ALeft is TJSONNumber then LTypeA := 'Number'
  else if ALeft is TJSONString then LTypeA := 'String'
  else if ALeft is TJSONArray then LTypeA := 'Array'
  else if ALeft is TJSONObject then LTypeA := 'Object'
  else if IsJsonNull(ALeft) then LTypeA := 'Null'
  else LTypeA := 'Unknown';

  if (ARight is TJSONTrue) or (ARight is TJSONFalse) then LTypeB := 'Boolean'
  else if ARight is TJSONNumber then LTypeB := 'Number'
  else if ARight is TJSONString then LTypeB := 'String'
  else if ARight is TJSONArray then LTypeB := 'Array'
  else if ARight is TJSONObject then LTypeB := 'Object'
  else if IsJsonNull(ARight) then LTypeB := 'Null'
  else LTypeB := 'Unknown';

  Result := LTypeA <> LTypeB;
  if Result and (ADifferences <> nil) then
    ADifferences.Add(Format('%sType mismatch %s vs %s at %s', [Indent(AOptions, LLevel), LTypeA, LTypeB, APath]));
end;

{ Numbers }

class function TJsonStructuralComparer.NumbersEqual(const ALeft, ARight: TJSONNumber;
  const AOptions: TJsonCompareOptions; const APath: string; const ADifferences: TList<string>): Boolean;
var
  LDA, LDB: Double;
  LLevel: Integer;
begin
  LLevel := PathDepth(APath);
  LDA := ALeft.AsDouble;
  LDB := ARight.AsDouble;

  if AOptions.EnableNumericTolerance then
    Result := SameValue(LDA, LDB, AOptions.NumericTolerance)
  else
    Result := LDA = LDB;

  if (ADifferences <> nil) and not Result then
    ADifferences.Add(Format('%sNumber mismatch %g vs %g at %s', [Indent(AOptions, LLevel), LDA, LDB, APath]));
end;

{ Strings }

class function TJsonStructuralComparer.StringsEqual(const ALeft, ARight: TJSONString;
  const AOptions: TJsonCompareOptions; const APath: string; const ADifferences: TList<string>): Boolean;
var
  LLevel: Integer;
begin
  LLevel := PathDepth(APath);
  Result := ALeft.Value = ARight.Value;
  if (ADifferences <> nil) and not Result then
    ADifferences.Add(Format('%sString mismatch "%s" vs "%s" at %s', [Indent(AOptions, LLevel), ALeft.Value, ARight.Value, APath]));
end;

{ Arrays }

class function TJsonStructuralComparer.ArraysEqual(const ALeft, ARight: TJSONArray;
  const AOptions: TJsonCompareOptions; const APath: string; const ADifferences: TList<string>): Boolean;
var
  LI, LJ: Integer;
  LMatched: Boolean;
  LUsed: TArray<Boolean>;
  LLevel: Integer;
begin
  LLevel := PathDepth(APath);
  if ALeft.Count <> ARight.Count then
  begin
    if ADifferences <> nil then
      ADifferences.Add(Format('%sArray length mismatch %d vs %d at %s', [Indent(AOptions, LLevel), ALeft.Count, ARight.Count, APath]));
    Exit(False);
  end;

  Result := True;

  if not AOptions.ArrayOrderAgnostic then
  begin
    for LI := 0 to ALeft.Count - 1 do
      if not AreStructurallyEqualWithDiff(ALeft.Items[LI], ARight.Items[LI], AOptions, Format('%s[%d]', [APath, LI]), ADifferences) then
        Result := False;
    Exit;
  end;

  SetLength(LUsed, ARight.Count);
  for LI := 0 to ALeft.Count - 1 do
  begin
    LMatched := False;
    for LJ := 0 to ARight.Count - 1 do
    begin
      if LUsed[LJ] then Continue;
      if AreStructurallyEqualWithDiff(ALeft.Items[LI], ARight.Items[LJ], AOptions, Format('%s[%d]', [APath, LI]), nil) then
      begin
        LUsed[LJ] := True;
        LMatched := True;
        Break;
      end;
    end;
    if not LMatched then
    begin
      Result := False;
      if ADifferences <> nil then
        ADifferences.Add(Format('%sNo matching element for %s[%d]', [Indent(AOptions, LLevel), APath, LI]));
    end;
  end;
end;

{ Objects }

class function TJsonStructuralComparer.ObjectsEqual(const ALeft, ARight: TJSONObject;
  const AOptions: TJsonCompareOptions; const APath: string; const ADifferences: TList<string>): Boolean;
var
  LMapA, LMapB: TDictionary<string, TJSONValue>;
  LPair: TJSONPair;
  LName: string;
  LVa, LVb: TJSONValue;
  LLevel: Integer;

  function KeyOf(const AStr: string): string;
  begin
    if AOptions.PropertyNameCaseSensitive then
      Result := AStr
    else
      Result := UpperCase(AStr, loInvariantLocale);
  end;

begin
  LLevel := PathDepth(APath);
  LMapA := TDictionary<string, TJSONValue>.Create;
  LMapB := TDictionary<string, TJSONValue>.Create;
  try
    for LPair in ALeft do LMapA.AddOrSetValue(KeyOf(LPair.JsonString.Value), LPair.JsonValue);
    for LPair in ARight do LMapB.AddOrSetValue(KeyOf(LPair.JsonString.Value), LPair.JsonValue);

    Result := True;

    for LName in LMapA.Keys do
    begin
      if not LMapB.TryGetValue(LName, LVb) then
      begin
        if not AOptions.TreatNullAndMissingPropertyAsEqual then
        begin
          if ADifferences <> nil then
            ADifferences.Add(Format('%sMissing property %s in second JSON', [Indent(AOptions, LLevel), APath + '.' + LName]));
          Result := False;
        end;
        Continue;
      end;

      LVa := LMapA[LName];
      if not AreStructurallyEqualWithDiff(LVa, LVb, AOptions, APath + '.' + LName, ADifferences) then
        Result := False;
    end;

    for LName in LMapB.Keys do
      if not LMapA.ContainsKey(LName) then
      begin
        if not AOptions.TreatNullAndMissingPropertyAsEqual then
        begin
          if ADifferences <> nil then
            ADifferences.Add(Format('%sExtra property %s in second JSON', [Indent(AOptions, LLevel), APath + '.' + LName]));
          Result := False;
        end;
      end;

  finally
    LMapA.Free;
    LMapB.Free;
  end;
end;

{ Public - string overload that returns boolean only or creates diffs when enabled }

class function TJsonStructuralComparer.AreStructurallyEqual(
  const AJsonA, AJsonB: string; const AOptions: TJsonCompareOptions): Boolean;
var
  LVA, LVB: TJSONValue;
begin
  // Fast boolean-only path if diffs disabled: avoid allocating list
  if not AOptions.Diff.EnableDiff then
  begin
    LVA := TJSONObject.ParseJSONValue(AJsonA);
    LVB := TJSONObject.ParseJSONValue(AJsonB);
    try
      if (LVA = nil) or (LVB = nil) then
        Exit(False);

      Result := AreStructurallyEqualWithDiff(LVA, LVB, AOptions, 'Root', nil);
    finally
      LVA.Free;
      LVB.Free;
    end;
    Exit;
  end;

  // Diff enabled -> create list, pass it in, then free
  var LDifferences := TList<string>.Create;
  try
    LVA := TJSONObject.ParseJSONValue(AJsonA);
    LVB := TJSONObject.ParseJSONValue(AJsonB);
    try
      if (LVA = nil) or (LVB = nil) then
      begin
        LDifferences.Add('JsonA or JsonB is nil or invalid');
        Exit(False);
      end;
      Result := AreStructurallyEqualWithDiff(LVA, LVB, AOptions, 'Root', LDifferences);
    finally
      LVA.Free;
      LVB.Free;
    end;
  finally
    LDifferences.Free;
  end;
end;

class function TJsonStructuralComparer.AreStructurallyEqual(const ALeft, ARight: TJSONValue;
  const AOptions: TJsonCompareOptions): Boolean;
begin
  // boolean-only overload: callers expect a boolean, we don't create diffs here
  Result := AreStructurallyEqualWithDiff(ALeft, ARight, AOptions, 'Root', nil);
end;

{ string overload that returns diffs into caller's list (may be nil) }
class function TJsonStructuralComparer.AreStructurallyEqualWithDiff(
  const AJsonA, AJsonB: string; const AOptions: TJsonCompareOptions;
  ADifferences: TList<string>): Boolean;
var
  LVA, LVB: TJSONValue;
  LOwnDifferences: TList<string>;
  LUseOwn: Boolean;
  LDiffTarget: TList<string>;
begin
  // If caller passed nil but EnableDiff is True, create a local list so we can still produce diffs.
  LUseOwn := (ADifferences = nil) and AOptions.Diff.EnableDiff;
  if LUseOwn then
    LOwnDifferences := TList<string>.Create
  else
    LOwnDifferences := nil;

  LVA := TJSONObject.ParseJSONValue(AJsonA);
  LVB := TJSONObject.ParseJSONValue(AJsonB);
  try
    if (LVA = nil) or (LVB = nil) then
    begin
      if AOptions.Diff.EnableDiff then
      begin
        if LUseOwn then
          LOwnDifferences.Add('JsonA or JsonB is nil or invalid')
        else if ADifferences <> nil then
          ADifferences.Add('JsonA or JsonB is nil or invalid');
      end;
      Exit(False);
    end;

    // choose which list to pass to deeper comparison
    if LUseOwn then
      LDiffTarget := LOwnDifferences
    else
      LDiffTarget := ADifferences;

    Result := AreStructurallyEqualWithDiff(LVA, LVB, AOptions, 'Root', LDiffTarget);
  finally
    LVA.Free;
    LVB.Free;
    if LUseOwn then
      LOwnDifferences.Free;
  end;
end;

class function TJsonStructuralComparer.AreStructurallyEqualWithDiffString(
  const AJsonA, AJsonB: string; const AOptions: TJsonCompareOptions): string;
var
  LDiff: TList<string>;
begin
  if not AOptions.Diff.EnableDiff then
  begin
    if AreStructurallyEqual(AJsonA, AJsonB, AOptions) then
      Exit('')
    else
      Exit('JSONs differ (diff disabled)');
  end;

  LDiff := TList<string>.Create;
  try
    AreStructurallyEqualWithDiff(AJsonA, AJsonB, AOptions, LDiff);
    Result := String.Join(AOptions.Diff.LineBreak, LDiff.ToArray);
  finally
    LDiff.Free;
  end;
end;

class function TJsonStructuralComparer.AreStructurallyEqualWithDiff(const ALeft, ARight: TJSONValue;
  const AOptions: TJsonCompareOptions; const APath: string;
  ADifferences: TList<string>): Boolean;
begin
  if ValuesAreNil(ALeft, ARight, AOptions, APath, ADifferences) then
    Exit(True);

  if ValuesHaveTypeMismatch(ALeft, ARight, AOptions, APath, ADifferences) then
    Exit(False);

  if (ALeft is TJSONTrue) or (ALeft is TJSONFalse) then
    Exit(BooleanValuesAreEqual(ALeft, ARight, AOptions, APath, ADifferences));

  if ALeft is TJSONNumber then
    Exit(NumbersEqual(TJSONNumber(ALeft), TJSONNumber(ARight), AOptions, APath, ADifferences))
  else if ALeft is TJSONString then
    Exit(StringsEqual(TJSONString(ALeft), TJSONString(ARight), AOptions, APath, ADifferences))
  else if ALeft is TJSONArray then
    Exit(ArraysEqual(TJSONArray(ALeft), TJSONArray(ARight), AOptions, APath, ADifferences))
  else if ALeft is TJSONObject then
    Exit(ObjectsEqual(TJSONObject(ALeft), TJSONObject(ARight), AOptions, APath, ADifferences))
  else if IsJsonNull(ALeft) and IsJsonNull(ARight) then
    Exit(True)
  else
  begin
    if ADifferences <> nil then
      ADifferences.Add(Format('%sUnknown JSON type mismatch at %s', [Indent(AOptions, PathDepth(APath)), APath]));
    Exit(False);
  end;
end;

end.

