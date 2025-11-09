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

unit JsonStructuralComparer;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.JSON,
  System.Math;

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
    class function ObjectsEqual(const A, B: TJSONObject; const Options: TJsonCompareOptions;
      const Path: string; const Differences: TList<string>): Boolean; static;

    class function ArraysEqual(const A, B: TJSONArray; const Options: TJsonCompareOptions;
      const Path: string; const Differences: TList<string>): Boolean; static;

    class function NumbersEqual(const A, B: TJSONNumber; const Options: TJsonCompareOptions;
      const Path: string; const Differences: TList<string>): Boolean; static;

    class function StringsEqual(const A, B: TJSONString; const Options: TJsonCompareOptions;
      const Path: string; const Differences: TList<string>): Boolean; static;

    class function IsJsonNull(const V: TJSONValue): Boolean; static;
    class function GetJsonBoolean(const V: TJSONValue; out Value: Boolean): Boolean; static;
    class function Indent(const Options: TJsonCompareOptions; Level: Integer): string; static;
    class function PathDepth(const Path: string): Integer; static;

    class function ValuesAreNil(const A, B: TJSONValue; const Options: TJsonCompareOptions;
      const Path: string; Differences: TList<string>): Boolean; static;

    class function BooleanValuesAreEqual(const A, B: TJSONValue; const Options: TJsonCompareOptions;
      const Path: string; Differences: TList<string>): Boolean; static;

    class function ValuesHaveTypeMismatch(const A, B: TJSONValue; const Options: TJsonCompareOptions;
      const Path: string; Differences: TList<string>): Boolean; static;

  public
    class function AreStructurallyEqual(const JsonA, JsonB: string;
      const Options: TJsonCompareOptions): Boolean; overload; static;

    class function AreStructurallyEqual(const A, B: TJSONValue;
      const Options: TJsonCompareOptions): Boolean; overload; static;

    class function AreStructurallyEqualWithDiff(const JsonA, JsonB: string;
      const Options: TJsonCompareOptions; Differences: TList<string>): Boolean; overload; static;

    class function AreStructurallyEqualWithDiffString(const JsonA, JsonB: string;
      const Options: TJsonCompareOptions): string; static;

    class function AreStructurallyEqualWithDiff(const A, B: TJSONValue;
      const Options: TJsonCompareOptions; const Path: string;
      Differences: TList<string>): Boolean; overload; static;
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

class function TJsonStructuralComparer.Indent(const Options: TJsonCompareOptions; Level: Integer): string;
begin
  Result := StringOfChar(' ', Level * Options.Diff.IndentSpaces);
end;

class function TJsonStructuralComparer.PathDepth(const Path: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to Length(Path) do
    if CharInSet(Path[I], ['.', '[']) then
      Inc(Result);
end;

class function TJsonStructuralComparer.IsJsonNull(const V: TJSONValue): Boolean;
begin
  Result := (V = nil) or (V is TJSONNull);
end;

class function TJsonStructuralComparer.GetJsonBoolean(const V: TJSONValue; out Value: Boolean): Boolean;
begin
  if V is TJSONTrue then
  begin
    Value := True;
    Exit(True);
  end
  else if V is TJSONFalse then
  begin
    Value := False;
    Exit(True);
  end;
  Result := False;
end;

{ Nil / Boolean / Type checks }

class function TJsonStructuralComparer.ValuesAreNil(const A, B: TJSONValue;
  const Options: TJsonCompareOptions; const Path: string;
  Differences: TList<string>): Boolean;
var
  Level: Integer;
begin
  Level := PathDepth(Path);
  if IsJsonNull(A) and IsJsonNull(B) then
    Exit(True);

  if IsJsonNull(A) or IsJsonNull(B) then
  begin
    if Options.TreatNullAndMissingPropertyAsEqual then
      Exit(True);

    if Differences <> nil then
      Differences.Add(Format('%sOne value is null or missing at %s', [Indent(Options, Level), Path]));
    Exit(False);
  end;

  Result := False;
end;

class function TJsonStructuralComparer.BooleanValuesAreEqual(const A, B: TJSONValue;
  const Options: TJsonCompareOptions; const Path: string;
  Differences: TList<string>): Boolean;
var
  BA, BB: Boolean;
  Level: Integer;
  AIsBool, BIsBool: Boolean;
begin
  Level := PathDepth(Path);
  AIsBool := GetJsonBoolean(A, BA);
  BIsBool := GetJsonBoolean(B, BB);

  if not (AIsBool and BIsBool) then
    Exit(False);

  Result := BA = BB;
  if (Differences <> nil) and not Result then
    Differences.Add(Format('%sBoolean mismatch %s vs %s at %s',
      [Indent(Options, Level), BoolToStr(BA, True), BoolToStr(BB, True), Path]));
end;

class function TJsonStructuralComparer.ValuesHaveTypeMismatch(const A, B: TJSONValue;
  const Options: TJsonCompareOptions; const Path: string;
  Differences: TList<string>): Boolean;
var
  Level: Integer;
  TypeA, TypeB: string;
begin
  Level := PathDepth(Path);
  if (A = nil) or (B = nil) then
    Exit(False);

  if (A is TJSONTrue) or (A is TJSONFalse) then TypeA := 'Boolean'
  else if A is TJSONNumber then TypeA := 'Number'
  else if A is TJSONString then TypeA := 'String'
  else if A is TJSONArray then TypeA := 'Array'
  else if A is TJSONObject then TypeA := 'Object'
  else if IsJsonNull(A) then TypeA := 'Null'
  else TypeA := 'Unknown';

  if (B is TJSONTrue) or (B is TJSONFalse) then TypeB := 'Boolean'
  else if B is TJSONNumber then TypeB := 'Number'
  else if B is TJSONString then TypeB := 'String'
  else if B is TJSONArray then TypeB := 'Array'
  else if B is TJSONObject then TypeB := 'Object'
  else if IsJsonNull(B) then TypeB := 'Null'
  else TypeB := 'Unknown';

  Result := TypeA <> TypeB;
  if Result and (Differences <> nil) then
    Differences.Add(Format('%sType mismatch %s vs %s at %s', [Indent(Options, Level), TypeA, TypeB, Path]));
end;

{ Numbers }

class function TJsonStructuralComparer.NumbersEqual(const A, B: TJSONNumber;
  const Options: TJsonCompareOptions; const Path: string; const Differences: TList<string>): Boolean;
var
  DA, DB: Double;
  Level: Integer;
begin
  Level := PathDepth(Path);
  DA := A.AsDouble;
  DB := B.AsDouble;

  if Options.EnableNumericTolerance then
    Result := SameValue(DA, DB, Options.NumericTolerance)
  else
    Result := DA = DB;

  if (Differences <> nil) and not Result then
    Differences.Add(Format('%sNumber mismatch %g vs %g at %s', [Indent(Options, Level), DA, DB, Path]));
end;

{ Strings }

class function TJsonStructuralComparer.StringsEqual(const A, B: TJSONString;
  const Options: TJsonCompareOptions; const Path: string; const Differences: TList<string>): Boolean;
var
  Level: Integer;
begin
  Level := PathDepth(Path);
  Result := A.Value = B.Value;
  if (Differences <> nil) and not Result then
    Differences.Add(Format('%sString mismatch "%s" vs "%s" at %s', [Indent(Options, Level), A.Value, B.Value, Path]));
end;

{ Arrays }

class function TJsonStructuralComparer.ArraysEqual(const A, B: TJSONArray;
  const Options: TJsonCompareOptions; const Path: string; const Differences: TList<string>): Boolean;
var
  I, J: Integer;
  Matched: Boolean;
  Used: TArray<Boolean>;
  Level: Integer;
begin
  Level := PathDepth(Path);
  if A.Count <> B.Count then
  begin
    if Differences <> nil then
      Differences.Add(Format('%sArray length mismatch %d vs %d at %s', [Indent(Options, Level), A.Count, B.Count, Path]));
    Exit(False);
  end;

  Result := True;

  if not Options.ArrayOrderAgnostic then
  begin
    for I := 0 to A.Count - 1 do
      if not AreStructurallyEqualWithDiff(A.Items[I], B.Items[I], Options, Format('%s[%d]', [Path, I]), Differences) then
        Result := False;
    Exit;
  end;

  SetLength(Used, B.Count);
  for I := 0 to A.Count - 1 do
  begin
    Matched := False;
    for J := 0 to B.Count - 1 do
    begin
      if Used[J] then Continue;
      if AreStructurallyEqualWithDiff(A.Items[I], B.Items[J], Options, Format('%s[%d]', [Path, I]), nil) then
      begin
        Used[J] := True;
        Matched := True;
        Break;
      end;
    end;
    if not Matched then
    begin
      Result := False;
      if Differences <> nil then
        Differences.Add(Format('%sNo matching element for %s[%d]', [Indent(Options, Level), Path, I]));
    end;
  end;
end;

{ Objects }

class function TJsonStructuralComparer.ObjectsEqual(const A, B: TJSONObject;
  const Options: TJsonCompareOptions; const Path: string; const Differences: TList<string>): Boolean;
var
  MapA, MapB: TDictionary<string, TJSONValue>;
  Pair: TJSONPair;
  Name: string;
  Va, Vb: TJSONValue;
  Level: Integer;

  function KeyOf(const S: string): string;
  begin
    if Options.PropertyNameCaseSensitive then
      Result := S
    else
      Result := UpperCase(S, loInvariantLocale);
  end;

begin
  Level := PathDepth(Path);
  MapA := TDictionary<string, TJSONValue>.Create;
  MapB := TDictionary<string, TJSONValue>.Create;
  try
    for Pair in A do MapA.AddOrSetValue(KeyOf(Pair.JsonString.Value), Pair.JsonValue);
    for Pair in B do MapB.AddOrSetValue(KeyOf(Pair.JsonString.Value), Pair.JsonValue);

    Result := True;

    for Name in MapA.Keys do
    begin
      if not MapB.TryGetValue(Name, Vb) then
      begin
        if not Options.TreatNullAndMissingPropertyAsEqual then
        begin
          if Differences <> nil then
            Differences.Add(Format('%sMissing property %s in second JSON', [Indent(Options, Level), Path + '.' + Name]));
          Result := False;
        end;
        Continue;
      end;

      Va := MapA[Name];
      if not AreStructurallyEqualWithDiff(Va, Vb, Options, Path + '.' + Name, Differences) then
        Result := False;
    end;

    for Name in MapB.Keys do
      if not MapA.ContainsKey(Name) then
      begin
        if not Options.TreatNullAndMissingPropertyAsEqual then
        begin
          if Differences <> nil then
            Differences.Add(Format('%sExtra property %s in second JSON', [Indent(Options, Level), Path + '.' + Name]));
          Result := False;
        end;
      end;

  finally
    MapA.Free;
    MapB.Free;
  end;
end;

{ Public - string overload that returns boolean only or creates diffs when enabled }

class function TJsonStructuralComparer.AreStructurallyEqual(
  const JsonA, JsonB: string; const Options: TJsonCompareOptions): Boolean;
var
  VA, VB: TJSONValue;
begin
  // Fast boolean-only path if diffs disabled: avoid allocating list
  if not Options.Diff.EnableDiff then
  begin
    VA := TJSONObject.ParseJSONValue(JsonA);
    VB := TJSONObject.ParseJSONValue(JsonB);
    try
      if (VA = nil) or (VB = nil) then
        Exit(False);

      Result := AreStructurallyEqualWithDiff(VA, VB, Options, 'Root', nil);
    finally
      VA.Free;
      VB.Free;
    end;
    Exit;
  end;

  // Diff enabled -> create list, pass it in, then free
  var LocalDifferences := TList<string>.Create;
  try
    VA := TJSONObject.ParseJSONValue(JsonA);
    VB := TJSONObject.ParseJSONValue(JsonB);
    try
      if (VA = nil) or (VB = nil) then
      begin
        LocalDifferences.Add('JsonA or JsonB is nil or invalid');
        Exit(False);
      end;
      Result := AreStructurallyEqualWithDiff(VA, VB, Options, 'Root', LocalDifferences);
    finally
      VA.Free;
      VB.Free;
    end;
  finally
    LocalDifferences.Free;
  end;
end;

class function TJsonStructuralComparer.AreStructurallyEqual(const A, B: TJSONValue;
  const Options: TJsonCompareOptions): Boolean;
begin
  // boolean-only overload: callers expect a boolean, we don't create diffs here
  Result := AreStructurallyEqualWithDiff(A, B, Options, 'Root', nil);
end;

{ string overload that returns diffs into caller's list (may be nil) }
class function TJsonStructuralComparer.AreStructurallyEqualWithDiff(
  const JsonA, JsonB: string; const Options: TJsonCompareOptions;
  Differences: TList<string>): Boolean;
var
  VA, VB: TJSONValue;
  OwnDifferences: TList<string>;
  UseOwn: Boolean;
  DiffTarget: TList<string>;
begin
  // If caller passed nil but EnableDiff is True, create a local list so we can still produce diffs.
  UseOwn := (Differences = nil) and Options.Diff.EnableDiff;
  if UseOwn then
    OwnDifferences := TList<string>.Create
  else
    OwnDifferences := nil;

  VA := TJSONObject.ParseJSONValue(JsonA);
  VB := TJSONObject.ParseJSONValue(JsonB);
  try
    if (VA = nil) or (VB = nil) then
    begin
      if Options.Diff.EnableDiff then
      begin
        if UseOwn then
          OwnDifferences.Add('JsonA or JsonB is nil or invalid')
        else if Differences <> nil then
          Differences.Add('JsonA or JsonB is nil or invalid');
      end;
      Exit(False);
    end;

    // choose which list to pass to deeper comparison
    if UseOwn then
      DiffTarget := OwnDifferences
    else
      DiffTarget := Differences;

    Result := AreStructurallyEqualWithDiff(VA, VB, Options, 'Root', DiffTarget);
  finally
    VA.Free;
    VB.Free;
    if UseOwn then
      OwnDifferences.Free;
  end;
end;

class function TJsonStructuralComparer.AreStructurallyEqualWithDiffString(
  const JsonA, JsonB: string; const Options: TJsonCompareOptions): string;
var
  Diff: TList<string>;
begin
  if not Options.Diff.EnableDiff then
  begin
    if AreStructurallyEqual(JsonA, JsonB, Options) then
      Exit('')
    else
      Exit('JSONs differ (diff disabled)');
  end;

  Diff := TList<string>.Create;
  try
    AreStructurallyEqualWithDiff(JsonA, JsonB, Options, Diff);
    Result := String.Join(Options.Diff.LineBreak, Diff.ToArray);
  finally
    Diff.Free;
  end;
end;

class function TJsonStructuralComparer.AreStructurallyEqualWithDiff(const A, B: TJSONValue;
  const Options: TJsonCompareOptions; const Path: string;
  Differences: TList<string>): Boolean;
begin
  if ValuesAreNil(A, B, Options, Path, Differences) then
    Exit(True);

  if ValuesHaveTypeMismatch(A, B, Options, Path, Differences) then
    Exit(False);

  if (A is TJSONTrue) or (A is TJSONFalse) then
    Exit(BooleanValuesAreEqual(A, B, Options, Path, Differences));

  if A is TJSONNumber then
    Exit(NumbersEqual(TJSONNumber(A), TJSONNumber(B), Options, Path, Differences))
  else if A is TJSONString then
    Exit(StringsEqual(TJSONString(A), TJSONString(B), Options, Path, Differences))
  else if A is TJSONArray then
    Exit(ArraysEqual(TJSONArray(A), TJSONArray(B), Options, Path, Differences))
  else if A is TJSONObject then
    Exit(ObjectsEqual(TJSONObject(A), TJSONObject(B), Options, Path, Differences))
  else if IsJsonNull(A) and IsJsonNull(B) then
    Exit(True)
  else
  begin
    if Differences <> nil then
      Differences.Add(Format('%sUnknown JSON type mismatch at %s', [Indent(Options, PathDepth(Path)), Path]));
    Exit(False);
  end;
end;

end.

