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

unit JsonStructuralComparerTests;

interface

uses
  System.SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  System.Generics.Collections,
  JsonStructuralComparer,
  SolLibTestCase;

type
  TJsonStructuralComparerTests = class(TSolLibTestCase)
  published
    // Basic equality / mismatch
    procedure Test_IdenticalJson;
    procedure Test_StringMismatch;
    procedure Test_DifferentNumbers;
    procedure Test_BooleanMismatch;
    procedure Test_TypeMismatch;
    procedure Test_NullAndMissingProperty;

    // Arrays
    procedure Test_ArrayLengthMismatch;
    procedure Test_ArrayOrderAgnostic;
    procedure Test_ArrayOrderAgnosticWithDuplicates;
    procedure Test_ArrayOfMixedTypes;
    procedure Test_NestedArraysAndObjects;

    // Nested objects
    procedure Test_NestedObjects;
    procedure Test_DeeplyNestedNullsAndMissing;
    procedure Test_NestedMismatch;

    // Numbers with/without tolerance
    procedure Test_NumericMismatchWithoutTolerance;
    procedure Test_NumericMismatchWithTolerance;

    // Diff string output
    procedure Test_DiffStringOutput;
  end;

implementation

{ ---------------- Basic JSON equality / mismatch ---------------- }

procedure TJsonStructuralComparerTests.Test_IdenticalJson;
var
  JsonA, JsonB: string;
begin
  JsonA := '{"name":"Alice","age":30,"active":true}';
  JsonB := '{"name":"Alice","age":30,"active":true}';
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(JsonA, JsonB, TJsonCompareOptions.Default));
end;

procedure TJsonStructuralComparerTests.Test_StringMismatch;
var
  JsonA, JsonB: string;
  Differences: TList<string>;
begin
  JsonA := '{"name":"Alice"}';
  JsonB := '{"name":"Bob"}';
  Differences := TList<string>.Create;
  try
    AssertFalse(TJsonStructuralComparer.AreStructurallyEqualWithDiff(JsonA, JsonB, TJsonCompareOptions.Default, Differences));
    AssertEquals(1, Differences.Count);
  finally
    Differences.Free;
  end;
end;

procedure TJsonStructuralComparerTests.Test_DifferentNumbers;
var
  JsonA, JsonB: string;
  Options: TJsonCompareOptions;
begin
  JsonA := '{"value":1.0}';
  JsonB := '{"value":1.0000001}';
  Options := TJsonCompareOptions.Default;
  Options.EnableNumericTolerance := True;
  Options.NumericTolerance := 1e-6;
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(JsonA, JsonB, Options));
end;

procedure TJsonStructuralComparerTests.Test_BooleanMismatch;
var
  JsonA, JsonB: string;
  Differences: TList<string>;
begin
  JsonA := '{"active":true}';
  JsonB := '{"active":false}';
  Differences := TList<string>.Create;
  try
    AssertFalse(TJsonStructuralComparer.AreStructurallyEqualWithDiff(JsonA, JsonB, TJsonCompareOptions.Default, Differences));
    AssertEquals(1, Differences.Count);
  finally
    Differences.Free;
  end;
end;

procedure TJsonStructuralComparerTests.Test_TypeMismatch;
var
  JsonA, JsonB: string;
  Differences: TList<string>;
begin
  JsonA := '{"value":123}';
  JsonB := '{"value":"123"}';
  Differences := TList<string>.Create;
  try
    AssertFalse(TJsonStructuralComparer.AreStructurallyEqualWithDiff(JsonA, JsonB, TJsonCompareOptions.Default, Differences));
    AssertEquals(1, Differences.Count);
  finally
    Differences.Free;
  end;
end;

procedure TJsonStructuralComparerTests.Test_NullAndMissingProperty;
var
  JsonA, JsonB: string;
  Options: TJsonCompareOptions;
begin
  JsonA := '{"a":null,"b":2}';
  JsonB := '{"b":2}';
  Options := TJsonCompareOptions.Default;
  Options.TreatNullAndMissingPropertyAsEqual := True;
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(JsonA, JsonB, Options));
end;

{ ---------------- Array tests ---------------- }

procedure TJsonStructuralComparerTests.Test_ArrayLengthMismatch;
var
  JsonA, JsonB: string;
  Differences: TList<string>;
begin
  JsonA := '[1,2,3]';
  JsonB := '[1,2]';
  Differences := TList<string>.Create;
  try
    AssertFalse(TJsonStructuralComparer.AreStructurallyEqualWithDiff(JsonA, JsonB, TJsonCompareOptions.Default, Differences));
    AssertEquals(1, Differences.Count);
  finally
    Differences.Free;
  end;
end;

procedure TJsonStructuralComparerTests.Test_ArrayOrderAgnostic;
var
  JsonA, JsonB: string;
  Options: TJsonCompareOptions;
begin
  JsonA := '[1,2,3]';
  JsonB := '[3,2,1]';
  Options := TJsonCompareOptions.Default;
  Options.ArrayOrderAgnostic := True;
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(JsonA, JsonB, Options));
end;

procedure TJsonStructuralComparerTests.Test_ArrayOrderAgnosticWithDuplicates;
var
  JsonA, JsonB: string;
  Options: TJsonCompareOptions;
begin
  JsonA := '[{"id":1},{"id":2},{"id":2},{"id":3}]';
  JsonB := '[{"id":2},{"id":1},{"id":3},{"id":2}]';
  Options := TJsonCompareOptions.Default;
  Options.ArrayOrderAgnostic := True;
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(JsonA, JsonB, Options));
end;

procedure TJsonStructuralComparerTests.Test_ArrayOfMixedTypes;
var
  JsonA, JsonB: string;
begin
  JsonA := '[1, "text", true, null, {"id":5}]';
  JsonB := '[1, "text", true, null, {"id":5}]';
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(JsonA, JsonB, TJsonCompareOptions.Default));
end;

procedure TJsonStructuralComparerTests.Test_NestedArraysAndObjects;
var
  JsonA, JsonB: string;
begin
  JsonA := '{"users":[{"id":1,"tags":["admin","active"]},{"id":2,"tags":[]}] }';
  JsonB := '{"users":[{"id":1,"tags":["admin","active"]},{"id":2,"tags":[]}] }';
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(JsonA, JsonB, TJsonCompareOptions.Default));
end;

{ ---------------- Nested objects ---------------- }

procedure TJsonStructuralComparerTests.Test_NestedObjects;
var
  JsonA, JsonB: string;
begin
  JsonA := '{"user":{"name":"Alice","stats":{"score":100,"level":5}}}';
  JsonB := '{"user":{"name":"Alice","stats":{"score":100,"level":5}}}';
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(JsonA, JsonB, TJsonCompareOptions.Default));
end;

procedure TJsonStructuralComparerTests.Test_DeeplyNestedNullsAndMissing;
var
  JsonA, JsonB: string;
  Options: TJsonCompareOptions;
begin
  JsonA := '{"a":null,"b":{"c":null}}';
  JsonB := '{"b":{}}';
  Options := TJsonCompareOptions.Default;
  Options.TreatNullAndMissingPropertyAsEqual := True;
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(JsonA, JsonB, Options));
end;

procedure TJsonStructuralComparerTests.Test_NestedMismatch;
var
  JsonA, JsonB: string;
  Differences: TList<string>;
begin
  JsonA := '{"user":{"id":1,"tags":["admin","active"]}}';
  JsonB := '{"user":{"id":2,"tags":["admin","inactive"]}}';
  Differences := TList<string>.Create;
  try
    AssertFalse(TJsonStructuralComparer.AreStructurallyEqualWithDiff(JsonA, JsonB, TJsonCompareOptions.Default, Differences));
    AssertEquals(2, Differences.Count);
  finally
    Differences.Free;
  end;
end;

{ ---------------- Numeric tolerance tests ---------------- }

procedure TJsonStructuralComparerTests.Test_NumericMismatchWithoutTolerance;
var
  JsonA, JsonB: string;
  Differences: TList<string>;
begin
  JsonA := '{"score":100.0001}';
  JsonB := '{"score":100.0}';
  Differences := TList<string>.Create;
  try
    AssertFalse(TJsonStructuralComparer.AreStructurallyEqualWithDiff(JsonA, JsonB, TJsonCompareOptions.Default, Differences));
    AssertEquals(1, Differences.Count);
  finally
    Differences.Free;
  end;
end;

procedure TJsonStructuralComparerTests.Test_NumericMismatchWithTolerance;
var
  JsonA, JsonB: string;
  Options: TJsonCompareOptions;
  Differences: TList<string>;
begin
  JsonA := '{"score":100.000001}';
  JsonB := '{"score":100.0}';
  Differences := TList<string>.Create;
  Options := TJsonCompareOptions.Default;
  Options.EnableNumericTolerance := True;
  Options.NumericTolerance := 1e-5;
  try
    AssertTrue(TJsonStructuralComparer.AreStructurallyEqualWithDiff(JsonA, JsonB, Options, Differences));
    AssertEquals(0, Differences.Count);
  finally
    Differences.Free;
  end;
end;

{ ---------------- Diff string output ---------------- }

procedure TJsonStructuralComparerTests.Test_DiffStringOutput;
var
  JsonA, JsonB: string;
  DiffStr: string;
  Options: TJsonCompareOptions;
begin
  JsonA := '{"name":"Alice","score":10}';
  JsonB := '{"name":"Bob","score":20}';
  Options := TJsonCompareOptions.Default;
  Options.Diff.EnableDiff := True;
  DiffStr := TJsonStructuralComparer.AreStructurallyEqualWithDiffString(JsonA, JsonB, Options);
  AssertTrue(DiffStr.Contains('String mismatch'));
  AssertTrue(DiffStr.Contains('Number mismatch'));
end;

initialization
{$IFDEF FPC}
  RegisterTest(TJsonStructuralCompareTests);
{$ELSE}
  RegisterTest(TJsonStructuralComparerTests.Suite);
{$ENDIF}

end.
