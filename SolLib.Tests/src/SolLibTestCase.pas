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

unit SolLibTestCase;

interface

uses
  System.SysUtils,
{$IFDEF FPC}
  fpcunit,
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpArrayUtils,
  JsonStructuralComparer;

type
  // A simple callable block type for tests
  TTestProc = reference to procedure;

type
  TSolLibTestCase = class abstract(TTestCase)

   protected
    const DoubleCompareDelta = 0.01;

    procedure AssertEquals(const Expected, Actual: string; const Msg: string = ''); overload;
    procedure AssertNotEquals(const Expected, Actual: string; const Msg: string = ''); overload;

    procedure AssertEquals(Expected, Actual: Integer; const Msg: string = ''); overload;
    procedure AssertNotEquals(Expected, Actual: Integer; const Msg: string = ''); overload;

    procedure AssertEquals(Expected, Actual: Int64; const Msg: string = ''); overload;
    procedure AssertNotEquals(Expected, Actual: Int64; const Msg: string = ''); overload;

    procedure AssertEquals(Expected, Actual: UInt64; const Msg: string = ''); overload;
    procedure AssertNotEquals(Expected, Actual: UInt64; const Msg: string = ''); overload;

    procedure AssertEquals(Expected, Actual: Single; Delta: Single = 0; const Msg: string = ''); overload;
    procedure AssertNotEquals(Expected, Actual: Single; Delta: Single = 0; const Msg: string = ''); overload;

    procedure AssertEquals(Expected, Actual: Double; Delta: Double = 0; const Msg: string = ''); overload;
    procedure AssertNotEquals(Expected, Actual: Double; Delta: Double = 0; const Msg: string = ''); overload;

    procedure AssertEquals<T>(const Expected, Actual: TArray<T>; const Msg: string = ''); overload;
    procedure AssertNotEquals<T>(const Expected, Actual: TArray<T>; const Msg: string = ''); overload;

    procedure AssertTrue(Condition: Boolean; Msg: string = '');
    procedure AssertFalse(Condition: Boolean; Msg: string = '');

    procedure AssertNull(const Obj: TObject; Msg: string = ''); overload;
    procedure AssertNotNull(const Obj: TObject; Msg: string = ''); overload;

    procedure AssertSame(const Expected, Actual: TObject; Msg: string = '');

    procedure AssertNull(const Obj: IInterface; Msg: string = ''); overload;
    procedure AssertNotNull(const Obj: IInterface; Msg: string = ''); overload;

    procedure AssertJsonMatch(const Expected, Actual: string; const Msg: string = ''); overload;

    procedure AssertException(const Proc: TTestProc; const ExpectedClass: ExceptClass; const ExpectedExceptionMessage: string = ''; ExactTypeMatch: Boolean = True); overload;
    procedure AssertException(const Proc: TTestProc; const ExpectedClass: ExceptClass; const ExpectedExceptionMessage: string; ExactTypeMatch: Boolean; out RaisedException: Exception); overload;

    procedure AssertIsInstanceOf(const Obj: TObject; const ClassType: TClass; const Msg: string = '');

  end;

implementation

procedure TSolLibTestCase.AssertEquals(const Expected, Actual, Msg: string);
begin
  CheckEquals(Expected, Actual, Msg);
end;

procedure TSolLibTestCase.AssertNotEquals(const Expected, Actual, Msg: string);
begin
  CheckNotEquals(Expected, Actual, Msg);
end;

procedure TSolLibTestCase.AssertEquals(Expected, Actual: Integer; const Msg: string);
begin
  CheckEquals(Expected, Actual, Msg);
end;

procedure TSolLibTestCase.AssertNotEquals(Expected, Actual: Integer;
  const Msg: string);
begin
  CheckNotEquals(Expected, Actual, Msg);
end;

procedure TSolLibTestCase.AssertEquals(Expected, Actual: Int64; const Msg: string);
begin
  CheckEquals(Expected, Actual, Msg);
end;

procedure TSolLibTestCase.AssertNotEquals(Expected, Actual: Int64;
  const Msg: string);
begin
  CheckNotEquals(Expected, Actual, Msg);
end;

procedure TSolLibTestCase.AssertEquals(Expected, Actual: UInt64; const Msg: string);
begin
  CheckEquals(Expected, Actual, Msg);
end;

procedure TSolLibTestCase.AssertNotEquals(Expected, Actual: UInt64;
  const Msg: string);
begin
  CheckNotEquals(Expected, Actual, Msg);
end;

procedure TSolLibTestCase.AssertEquals(Expected, Actual, Delta: Single; const Msg: string);
begin
  CheckEquals(Expected, Actual, Delta, Msg);
end;

procedure TSolLibTestCase.AssertNotEquals(Expected, Actual, Delta: Single;
  const Msg: string);
begin
  CheckNotEquals(Expected, Actual, Delta, Msg);
end;

procedure TSolLibTestCase.AssertEquals(Expected, Actual, Delta: Double; const Msg: string);
begin
  CheckEquals(Expected, Actual, Delta, Msg);
end;

procedure TSolLibTestCase.AssertNotEquals(Expected, Actual, Delta: Double;
  const Msg: string);
begin
  CheckNotEquals(Expected, Actual, Delta, Msg);
end;

procedure TSolLibTestCase.AssertEquals<T>(const Expected, Actual: TArray<T>;
  const Msg: string);
begin
  CheckTrue(TArrayUtils.AreArraysEqual<T>(Expected, Actual), Msg);
end;

procedure TSolLibTestCase.AssertNotEquals<T>(const Expected, Actual: TArray<T>;
  const Msg: string);
begin
  CheckFalse(TArrayUtils.AreArraysEqual<T>(Expected, Actual), Msg);
end;

procedure TSolLibTestCase.AssertTrue(Condition: Boolean; Msg: string);
begin
  CheckTrue(Condition, Msg);
end;

procedure TSolLibTestCase.AssertFalse(Condition: Boolean; Msg: string);
begin
  CheckFalse(Condition, Msg);
end;

procedure TSolLibTestCase.AssertNull(const Obj: TObject; Msg: string);
begin
  CheckNull(Obj, Msg);
end;

procedure TSolLibTestCase.AssertNotNull(const Obj: TObject; Msg: string);
begin
  CheckNotNull(Obj, Msg);
end;

procedure TSolLibTestCase.AssertSame(const Expected, Actual: TObject; Msg: string);
begin
   CheckSame(Expected, Actual, Msg)
end;

procedure TSolLibTestCase.AssertNull(const Obj: IInterface; Msg: string);
begin
  CheckNull(Obj, Msg);
end;

procedure TSolLibTestCase.AssertNotNull(const Obj: IInterface; Msg: string);
begin
  CheckNotNull(Obj, Msg);
end;

procedure TSolLibTestCase.AssertJsonMatch(const Expected, Actual, Msg: string);
begin
  CheckTrue(TJsonStructuralComparer.AreStructurallyEqual(Expected, Actual, TJsonCompareOptions.Default), Msg);
end;

procedure TSolLibTestCase.AssertException(const Proc: TTestProc;
  const ExpectedClass: ExceptClass; const ExpectedExceptionMessage: string;
  ExactTypeMatch: Boolean; out RaisedException: Exception);
begin
  RaisedException := nil;

  try
    Proc();
    Fail(Format('Expected %s, but no exception was raised.',
      [ExpectedClass.ClassName]));
  except
    on E: Exception do
    begin
      // Class match (exact or inherits)
      if ExactTypeMatch then
        CheckTrue(E.ClassType = ExpectedClass,
          Format('Expected exactly %s, but got %s.',
            [ExpectedClass.ClassName, E.ClassName]))
      else
        CheckTrue(E.InheritsFrom(ExpectedClass),
          Format('Expected %s (or descendant), but got %s.',
            [ExpectedClass.ClassName, E.ClassName]));

      if ExpectedExceptionMessage <> '' then
        CheckTrue(SameStr(E.Message, ExpectedExceptionMessage),
          Format('Exception message mismatch. Expected: "%s". Actual: "%s".',
            [ExpectedExceptionMessage, E.Message]));

      RaisedException := E; // return the actual exception instance
    end;
  end;
end;

procedure TSolLibTestCase.AssertException(const Proc: TTestProc;
  const ExpectedClass: ExceptClass; const ExpectedExceptionMessage: string;
  ExactTypeMatch: Boolean);
var
  Dummy: Exception;
begin
  AssertException(Proc, ExpectedClass, ExpectedExceptionMessage, ExactTypeMatch, Dummy);
end;

procedure TSolLibTestCase.AssertIsInstanceOf(const Obj: TObject; const ClassType: TClass;
  const Msg: string);
begin
    CheckIs(Obj, ClassType, Msg);
end;

end.
