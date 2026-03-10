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

    procedure AssertEquals(const AExpected, AActual: string; const AMsg: string = ''); overload;
    procedure AssertNotEquals(const AExpected, AActual: string; const AMsg: string = ''); overload;

    procedure AssertEquals(AExpected, AActual: Integer; const AMsg: string = ''); overload;
    procedure AssertNotEquals(AExpected, AActual: Integer; const AMsg: string = ''); overload;

    procedure AssertEquals(AExpected, AActual: Int64; const AMsg: string = ''); overload;
    procedure AssertNotEquals(AExpected, AActual: Int64; const AMsg: string = ''); overload;

    procedure AssertEquals(AExpected, AActual: UInt64; const AMsg: string = ''); overload;
    procedure AssertNotEquals(AExpected, AActual: UInt64; const AMsg: string = ''); overload;

    procedure AssertEquals(AExpected, AActual: Single; ADelta: Single = 0; const AMsg: string = ''); overload;
    procedure AssertNotEquals(AExpected, AActual: Single; ADelta: Single = 0; const AMsg: string = ''); overload;

    procedure AssertEquals(AExpected, AActual: Boolean; const AMsg: string = ''); overload;
    procedure AssertNotEquals(AExpected, AActual: Boolean; const AMsg: string = ''); overload;

    procedure AssertEquals(AExpected, AActual: Double; ADelta: Double = 0; const AMsg: string = ''); overload;
    procedure AssertNotEquals(AExpected, AActual: Double; ADelta: Double = 0; const AMsg: string = ''); overload;

    procedure AssertEquals(const AExpected, AActual: TBytes; const AMsg: string = ''); overload;
    procedure AssertNotEquals(const AExpected, AActual: TBytes; const AMsg: string = ''); overload;

    procedure AssertTrue(ACondition: Boolean; const AMsg: string = '');
    procedure AssertFalse(ACondition: Boolean; const AMsg: string = '');

    procedure AssertNull(const AObj: TObject; const AMsg: string = ''); overload;
    procedure AssertNotNull(const AObj: TObject; const AMsg: string = ''); overload;

    procedure AssertSame(const AExpected, AActual: TObject; const AMsg: string = '');

    procedure AssertNull(const AObj: IInterface; const AMsg: string = ''); overload;
    procedure AssertNotNull(const AObj: IInterface; const AMsg: string = ''); overload;

    procedure AssertJsonMatch(const AExpected, AActual: string; const AMsg: string = ''); overload;

    procedure AssertException(const AProc: TTestProc; const AExpectedClass: ExceptClass; const AExpectedExceptionMessage: string = ''; AExactTypeMatch: Boolean = True); overload;
    procedure AssertException(const AProc: TTestProc; const AExpectedClass: ExceptClass; const AExpectedExceptionMessage: string; AExactTypeMatch: Boolean; out ARaisedException: Exception); overload;

    procedure AssertIsInstanceOf(const AObj: TObject; const AClassType: TClass; const AMsg: string = '');

  end;

implementation

procedure TSolLibTestCase.AssertEquals(const AExpected, AActual, AMsg: string);
begin
  CheckEquals(AExpected, AActual, AMsg);
end;

procedure TSolLibTestCase.AssertNotEquals(const AExpected, AActual, AMsg: string);
begin
  CheckNotEquals(AExpected, AActual, AMsg);
end;

procedure TSolLibTestCase.AssertEquals(AExpected, AActual: Integer; const AMsg: string);
begin
  CheckEquals(AExpected, AActual, AMsg);
end;

procedure TSolLibTestCase.AssertNotEquals(AExpected, AActual: Integer;
  const AMsg: string);
begin
  CheckNotEquals(AExpected, AActual, AMsg);
end;

procedure TSolLibTestCase.AssertEquals(AExpected, AActual: Int64; const AMsg: string);
begin
  CheckEquals(AExpected, AActual, AMsg);
end;

procedure TSolLibTestCase.AssertNotEquals(AExpected, AActual: Int64;
  const AMsg: string);
begin
  CheckNotEquals(AExpected, AActual, AMsg);
end;

procedure TSolLibTestCase.AssertEquals(AExpected, AActual: UInt64; const AMsg: string);
begin
  CheckEquals(AExpected, AActual, AMsg);
end;

procedure TSolLibTestCase.AssertNotEquals(AExpected, AActual: UInt64;
  const AMsg: string);
begin
  CheckNotEquals(AExpected, AActual, AMsg);
end;

procedure TSolLibTestCase.AssertEquals(AExpected, AActual: Single; ADelta: Single; const AMsg: string);
begin
  CheckEquals(AExpected, AActual, ADelta, AMsg);
end;

procedure TSolLibTestCase.AssertNotEquals(AExpected, AActual: Single; ADelta: Single;
  const AMsg: string);
begin
  CheckNotEquals(AExpected, AActual, ADelta, AMsg);
end;

procedure TSolLibTestCase.AssertEquals(AExpected, AActual: Double; ADelta: Double; const AMsg: string);
begin
  CheckEquals(AExpected, AActual, ADelta, AMsg);
end;

procedure TSolLibTestCase.AssertNotEquals(AExpected, AActual: Double; ADelta: Double;
  const AMsg: string);
begin
  CheckNotEquals(AExpected, AActual, ADelta, AMsg);
end;

procedure TSolLibTestCase.AssertEquals(AExpected, AActual: Boolean; const AMsg: string);
begin
  CheckEquals(AExpected, AActual, AMsg);
end;

procedure TSolLibTestCase.AssertNotEquals(AExpected, AActual: Boolean;
  const AMsg: string);
begin
  CheckNotEquals(AExpected, AActual, AMsg);
end;


procedure TSolLibTestCase.AssertEquals(const AExpected, AActual: TBytes;
  const AMsg: string);
begin
  CheckTrue(TArrayUtils.AreArraysEqual(AExpected, AActual), AMsg);
end;

procedure TSolLibTestCase.AssertNotEquals(const AExpected, AActual: TBytes;
  const AMsg: string);
begin
  CheckFalse(TArrayUtils.AreArraysEqual(AExpected, AActual), AMsg);
end;

procedure TSolLibTestCase.AssertTrue(ACondition: Boolean; const AMsg: string);
begin
  CheckTrue(ACondition, AMsg);
end;

procedure TSolLibTestCase.AssertFalse(ACondition: Boolean; const AMsg: string);
begin
  CheckFalse(ACondition, AMsg);
end;

procedure TSolLibTestCase.AssertNull(const AObj: TObject; const AMsg: string);
begin
  CheckNull(AObj, AMsg);
end;

procedure TSolLibTestCase.AssertNotNull(const AObj: TObject; const AMsg: string);
begin
  CheckNotNull(AObj, AMsg);
end;

procedure TSolLibTestCase.AssertSame(const AExpected, AActual: TObject; const AMsg: string);
begin
   CheckSame(AExpected, AActual, AMsg)
end;

procedure TSolLibTestCase.AssertNull(const AObj: IInterface; const AMsg: string);
begin
  CheckNull(AObj, AMsg);
end;

procedure TSolLibTestCase.AssertNotNull(const AObj: IInterface; const AMsg: string);
begin
  CheckNotNull(AObj, AMsg);
end;

procedure TSolLibTestCase.AssertJsonMatch(const AExpected, AActual: string; const AMsg: string);
begin
  CheckTrue(TJsonStructuralComparer.AreStructurallyEqual(AExpected, AActual, TJsonCompareOptions.Default), AMsg);
end;

procedure TSolLibTestCase.AssertException(const AProc: TTestProc;
  const AExpectedClass: ExceptClass; const AExpectedExceptionMessage: string;
  AExactTypeMatch: Boolean; out ARaisedException: Exception);
begin
  ARaisedException := nil;

  try
    AProc();
    Fail(Format('Expected %s, but no exception was raised.',
      [AExpectedClass.ClassName]));
  except
    on E: Exception do
    begin
      // Class match (exact or inherits)
      if AExactTypeMatch then
        CheckTrue(E.ClassType = AExpectedClass,
          Format('Expected exactly %s, but got %s.',
            [AExpectedClass.ClassName, E.ClassName]))
      else
        CheckTrue(E.InheritsFrom(AExpectedClass),
          Format('Expected %s (or descendant), but got %s.',
            [AExpectedClass.ClassName, E.ClassName]));

      if AExpectedExceptionMessage <> '' then
        CheckTrue(SameStr(E.Message, AExpectedExceptionMessage),
          Format('Exception message mismatch. Expected: "%s". Actual: "%s".',
            [AExpectedExceptionMessage, E.Message]));

      ARaisedException := E; // return the actual exception instance
    end;
  end;
end;

procedure TSolLibTestCase.AssertException(const AProc: TTestProc;
  const AExpectedClass: ExceptClass; const AExpectedExceptionMessage: string;
  AExactTypeMatch: Boolean);
var
  LDummy: Exception;
begin
  AssertException(AProc, AExpectedClass, AExpectedExceptionMessage, AExactTypeMatch, LDummy);
end;

procedure TSolLibTestCase.AssertIsInstanceOf(const AObj: TObject; const AClassType: TClass;
  const AMsg: string);
begin
    CheckIs(AObj, AClassType, AMsg);
end;

end.
