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
  LJsonA, LJsonB: string;
begin
  LJsonA := '{"name":"Alice","age":30,"active":true}';
  LJsonB := '{"name":"Alice","age":30,"active":true}';
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(LJsonA, LJsonB, TJsonCompareOptions.Default));
end;

procedure TJsonStructuralComparerTests.Test_StringMismatch;
var
  LJsonA, LJsonB: string;
  LDifferences: TList<string>;
begin
  LJsonA := '{"name":"Alice"}';
  LJsonB := '{"name":"Bob"}';
  LDifferences := TList<string>.Create;
  try
    AssertFalse(TJsonStructuralComparer.AreStructurallyEqualWithDiff(LJsonA, LJsonB, TJsonCompareOptions.Default, LDifferences));
    AssertEquals(1, LDifferences.Count);
  finally
    LDifferences.Free;
  end;
end;

procedure TJsonStructuralComparerTests.Test_DifferentNumbers;
var
  LJsonA, LJsonB: string;
  LOptions: TJsonCompareOptions;
begin
  LJsonA := '{"value":1.0}';
  LJsonB := '{"value":1.0000001}';
  LOptions := TJsonCompareOptions.Default;
  LOptions.EnableNumericTolerance := True;
  LOptions.NumericTolerance := 1e-6;
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(LJsonA, LJsonB, LOptions));
end;

procedure TJsonStructuralComparerTests.Test_BooleanMismatch;
var
  LJsonA, LJsonB: string;
  LDifferences: TList<string>;
begin
  LJsonA := '{"active":true}';
  LJsonB := '{"active":false}';
  LDifferences := TList<string>.Create;
  try
    AssertFalse(TJsonStructuralComparer.AreStructurallyEqualWithDiff(LJsonA, LJsonB, TJsonCompareOptions.Default, LDifferences));
    AssertEquals(1, LDifferences.Count);
  finally
    LDifferences.Free;
  end;
end;

procedure TJsonStructuralComparerTests.Test_TypeMismatch;
var
  LJsonA, LJsonB: string;
  LDifferences: TList<string>;
begin
  LJsonA := '{"value":123}';
  LJsonB := '{"value":"123"}';
  LDifferences := TList<string>.Create;
  try
    AssertFalse(TJsonStructuralComparer.AreStructurallyEqualWithDiff(LJsonA, LJsonB, TJsonCompareOptions.Default, LDifferences));
    AssertEquals(1, LDifferences.Count);
  finally
    LDifferences.Free;
  end;
end;

procedure TJsonStructuralComparerTests.Test_NullAndMissingProperty;
var
  LJsonA, LJsonB: string;
  LOptions: TJsonCompareOptions;
begin
  LJsonA := '{"a":null,"b":2}';
  LJsonB := '{"b":2}';
  LOptions := TJsonCompareOptions.Default;
  LOptions.TreatNullAndMissingPropertyAsEqual := True;
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(LJsonA, LJsonB, LOptions));
end;

{ ---------------- Array tests ---------------- }

procedure TJsonStructuralComparerTests.Test_ArrayLengthMismatch;
var
  LJsonA, LJsonB: string;
  LDifferences: TList<string>;
begin
  LJsonA := '[1,2,3]';
  LJsonB := '[1,2]';
  LDifferences := TList<string>.Create;
  try
    AssertFalse(TJsonStructuralComparer.AreStructurallyEqualWithDiff(LJsonA, LJsonB, TJsonCompareOptions.Default, LDifferences));
    AssertEquals(1, LDifferences.Count);
  finally
    LDifferences.Free;
  end;
end;

procedure TJsonStructuralComparerTests.Test_ArrayOrderAgnostic;
var
  LJsonA, LJsonB: string;
  LOptions: TJsonCompareOptions;
begin
  LJsonA := '[1,2,3]';
  LJsonB := '[3,2,1]';
  LOptions := TJsonCompareOptions.Default;
  LOptions.ArrayOrderAgnostic := True;
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(LJsonA, LJsonB, LOptions));
end;

procedure TJsonStructuralComparerTests.Test_ArrayOrderAgnosticWithDuplicates;
var
  LJsonA, LJsonB: string;
  LOptions: TJsonCompareOptions;
begin
  LJsonA := '[{"id":1},{"id":2},{"id":2},{"id":3}]';
  LJsonB := '[{"id":2},{"id":1},{"id":3},{"id":2}]';
  LOptions := TJsonCompareOptions.Default;
  LOptions.ArrayOrderAgnostic := True;
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(LJsonA, LJsonB, LOptions));
end;

procedure TJsonStructuralComparerTests.Test_ArrayOfMixedTypes;
var
  LJsonA, LJsonB: string;
begin
  LJsonA := '[1, "text", true, null, {"id":5}]';
  LJsonB := '[1, "text", true, null, {"id":5}]';
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(LJsonA, LJsonB, TJsonCompareOptions.Default));
end;

procedure TJsonStructuralComparerTests.Test_NestedArraysAndObjects;
var
  LJsonA, LJsonB: string;
begin
  LJsonA := '{"users":[{"id":1,"tags":["admin","active"]},{"id":2,"tags":[]}] }';
  LJsonB := '{"users":[{"id":1,"tags":["admin","active"]},{"id":2,"tags":[]}] }';
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(LJsonA, LJsonB, TJsonCompareOptions.Default));
end;

{ ---------------- Nested objects ---------------- }

procedure TJsonStructuralComparerTests.Test_NestedObjects;
var
  LJsonA, LJsonB: string;
begin
  LJsonA := '{"user":{"name":"Alice","stats":{"score":100,"level":5}}}';
  LJsonB := '{"user":{"name":"Alice","stats":{"score":100,"level":5}}}';
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(LJsonA, LJsonB, TJsonCompareOptions.Default));
end;

procedure TJsonStructuralComparerTests.Test_DeeplyNestedNullsAndMissing;
var
  LJsonA, LJsonB: string;
  LOptions: TJsonCompareOptions;
begin
  LJsonA := '{"a":null,"b":{"c":null}}';
  LJsonB := '{"b":{}}';
  LOptions := TJsonCompareOptions.Default;
  LOptions.TreatNullAndMissingPropertyAsEqual := True;
  AssertTrue(TJsonStructuralComparer.AreStructurallyEqual(LJsonA, LJsonB, LOptions));
end;

procedure TJsonStructuralComparerTests.Test_NestedMismatch;
var
  LJsonA, LJsonB: string;
  LDifferences: TList<string>;
begin
  LJsonA := '{"user":{"id":1,"tags":["admin","active"]}}';
  LJsonB := '{"user":{"id":2,"tags":["admin","inactive"]}}';
  LDifferences := TList<string>.Create;
  try
    AssertFalse(TJsonStructuralComparer.AreStructurallyEqualWithDiff(LJsonA, LJsonB, TJsonCompareOptions.Default, LDifferences));
    AssertEquals(2, LDifferences.Count);
  finally
    LDifferences.Free;
  end;
end;

{ ---------------- Numeric tolerance tests ---------------- }

procedure TJsonStructuralComparerTests.Test_NumericMismatchWithoutTolerance;
var
  LJsonA, LJsonB: string;
  LDifferences: TList<string>;
begin
  LJsonA := '{"score":100.0001}';
  LJsonB := '{"score":100.0}';
  LDifferences := TList<string>.Create;
  try
    AssertFalse(TJsonStructuralComparer.AreStructurallyEqualWithDiff(LJsonA, LJsonB, TJsonCompareOptions.Default, LDifferences));
    AssertEquals(1, LDifferences.Count);
  finally
    LDifferences.Free;
  end;
end;

procedure TJsonStructuralComparerTests.Test_NumericMismatchWithTolerance;
var
  LJsonA, LJsonB: string;
  LOptions: TJsonCompareOptions;
  LDifferences: TList<string>;
begin
  LJsonA := '{"score":100.000001}';
  LJsonB := '{"score":100.0}';
  LDifferences := TList<string>.Create;
  LOptions := TJsonCompareOptions.Default;
  LOptions.EnableNumericTolerance := True;
  LOptions.NumericTolerance := 1e-5;
  try
    AssertTrue(TJsonStructuralComparer.AreStructurallyEqualWithDiff(LJsonA, LJsonB, LOptions, LDifferences));
    AssertEquals(0, LDifferences.Count);
  finally
    LDifferences.Free;
  end;
end;

{ ---------------- Diff string output ---------------- }

procedure TJsonStructuralComparerTests.Test_DiffStringOutput;
var
  LJsonA, LJsonB: string;
  LDiffStr: string;
  LOptions: TJsonCompareOptions;
begin
  LJsonA := '{"name":"Alice","score":10}';
  LJsonB := '{"name":"Bob","score":20}';
  LOptions := TJsonCompareOptions.Default;
  LOptions.Diff.EnableDiff := True;
  LDiffStr := TJsonStructuralComparer.AreStructurallyEqualWithDiffString(LJsonA, LJsonB, LOptions);
  AssertTrue(LDiffStr.Contains('String mismatch'));
  AssertTrue(LDiffStr.Contains('Number mismatch'));
end;

initialization
{$IFDEF FPC}
  RegisterTest(TJsonStructuralComparerTests);
{$ELSE}
  RegisterTest(TJsonStructuralComparerTests.Suite);
{$ENDIF}

end.
