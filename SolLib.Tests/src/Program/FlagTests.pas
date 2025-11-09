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

unit FlagTests;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpFlag,
  SolLibFlagProgramTestCase;

type
  TFlagTests = class(TSolLibFlagProgramTestCase)
  private
    class function PropIsBitBoolean(const AProp: TRttiProperty): Boolean; static;
    class function TryExtractBitIndex(const APropName: string; out ABit: Integer): Boolean; static;
    class function PowerOfTwo(const ABit: Integer): UInt64; static;
  published
    // --- ByteFlag -----------------------------------------------------------
    procedure TestByte_AllBitsSet;
    procedure TestByte_NoBitsSet;
    procedure TestByte_IndividualBitSet;

    // --- ShortFlag ----------------------------------------------------------
    procedure TestShort_AllBitsSet;
    procedure TestShort_NoBitsSet;
    procedure TestShort_IndividualBitSet;

    // --- IntFlag ------------------------------------------------------------
    procedure TestInt_AllBitsSet;
    procedure TestInt_NoBitsSet;
    procedure TestInt_IndividualBitSet;

    // --- LongFlag -----------------------------------------------------------
    procedure TestLong_AllBitsSet;
    procedure TestLong_NoBitsSet;
    procedure TestLong_IndividualBitSet;
  end;

implementation

{ TFlagTests }

class function TFlagTests.PropIsBitBoolean(const AProp: TRttiProperty): Boolean;
begin
  Result :=
    (AProp.Visibility = mvPublished) and
    AProp.IsReadable and
    AProp.PropertyType.IsOrdinal and
    (AProp.PropertyType.Handle = TypeInfo(Boolean)) and
    (Pos('Bit', AProp.Name) > 0);
end;

class function TFlagTests.TryExtractBitIndex(const APropName: string; out ABit: Integer): Boolean;
var
  P, I, StartIdx: Integer;
  Digits: string;
begin
  Result := False;
  ABit := -1;

  P := Pos('Bit', APropName);
  if P <= 0 then Exit;

  StartIdx := P + Length('Bit');
  Digits := '';
  for I := StartIdx to Length(APropName) do
  begin
    if CharInSet(APropName[I], ['0'..'9']) then
      Digits := Digits + APropName[I]
    else
      Break;
  end;

  Result := (Digits <> '') and TryStrToInt(Digits, ABit);
end;

class function TFlagTests.PowerOfTwo(const ABit: Integer): UInt64;
begin
  if (ABit < 0) or (ABit >= 64) then
    raise EArgumentOutOfRangeException.Create('bit out of range');
  Result := UInt64(1) shl ABit;
end;

{ --- ByteFlag -------------------------------------------------------------- }

procedure TFlagTests.TestByte_AllBitsSet;
var
  T: TRttiType;
  P: TRttiProperty;
  Obj: TByteFlag;
  SUT: IByteFlag;
  Val: TValue;
begin
  Obj := TByteFlag.Create(High(Byte));
  SUT := Obj;
  T := FRttiContext.GetType(Obj.ClassType);
  for P in T.GetProperties do
  begin
    if not PropIsBitBoolean(P) then Continue;
    Val := P.GetValue(Obj);
    AssertTrue(Val.AsBoolean, 'Byte ' + P.Name + ' should be TRUE');
  end;
end;

procedure TFlagTests.TestByte_NoBitsSet;
var
  T: TRttiType;
  P: TRttiProperty;
  Obj: TByteFlag;
  SUT: IByteFlag;
  Val: TValue;
begin
  Obj := TByteFlag.Create(Low(Byte));
  SUT := Obj;
  T := FRttiContext.GetType(Obj.ClassType);
  for P in T.GetProperties do
  begin
    if not PropIsBitBoolean(P) then Continue;
    Val := P.GetValue(Obj);
    AssertFalse(Val.AsBoolean, 'Byte ' + P.Name + ' should be FALSE');
  end;
end;

procedure TFlagTests.TestByte_IndividualBitSet;
var
  T: TRttiType;
  P: TRttiProperty;
  Obj: TByteFlag;
  SUT: IByteFlag;
  Bit: Integer;
  Mask: UInt64;
  Val: TValue;
begin
  T := FRttiContext.GetType(TByteFlag);
  for P in T.GetProperties do
  begin
    if not PropIsBitBoolean(P) then Continue;
    if not TryExtractBitIndex(P.Name, Bit) then Continue;
    if (Bit < 0) or (Bit > 7) then Continue;

    Mask := PowerOfTwo(Bit);
    Obj := TByteFlag.Create(Byte(Mask));
    SUT := Obj;
    Val := P.GetValue(Obj);
    AssertTrue(Val.AsBoolean, Format('Byte %s should be TRUE (mask=$%.2x)', [P.Name, Byte(Mask)]));
  end;
end;

{ --- ShortFlag ------------------------------------------------------------- }

procedure TFlagTests.TestShort_AllBitsSet;
var
  T: TRttiType;
  P: TRttiProperty;
  Obj: TShortFlag;
  SUT: IShortFlag;
  Val: TValue;
begin
  Obj := TShortFlag.Create(High(Word));
  SUT := Obj;
  T := FRttiContext.GetType(Obj.ClassType);
  for P in T.GetProperties do
  begin
    if not PropIsBitBoolean(P) then Continue;
    Val := P.GetValue(Obj);
    AssertTrue(Val.AsBoolean, 'Short ' + P.Name + ' should be TRUE');
  end;
end;

procedure TFlagTests.TestShort_NoBitsSet;
var
  T: TRttiType;
  P: TRttiProperty;
  Obj: TShortFlag;
  SUT: IShortFlag;
  Val: TValue;
begin
  Obj := TShortFlag.Create(Low(Word));
  SUT := Obj;
  T := FRttiContext.GetType(Obj.ClassType);
  for P in T.GetProperties do
  begin
    if not PropIsBitBoolean(P) then Continue;
    Val := P.GetValue(Obj);
    AssertFalse(Val.AsBoolean, 'Short ' + P.Name + ' should be FALSE');
  end;
end;

procedure TFlagTests.TestShort_IndividualBitSet;
var
  T: TRttiType;
  P: TRttiProperty;
  Obj: TShortFlag;
  SUT: IShortFlag;
  Bit: Integer;
  Mask: UInt64;
  Val: TValue;
begin
  T := FRttiContext.GetType(TShortFlag);
  for P in T.GetProperties do
  begin
    if not PropIsBitBoolean(P) then Continue;
    if not TryExtractBitIndex(P.Name, Bit) then Continue;
    if (Bit < 0) or (Bit > 15) then Continue;

    Mask := PowerOfTwo(Bit);
    Obj := TShortFlag.Create(Word(Mask));
    SUT := Obj;
    Val := P.GetValue(Obj);
    AssertTrue(Val.AsBoolean, Format('Short %s should be TRUE (mask=$%.4x)', [P.Name, Word(Mask)]));
  end;
end;

{ --- IntFlag --------------------------------------------------------------- }

procedure TFlagTests.TestInt_AllBitsSet;
var
  T: TRttiType;
  P: TRttiProperty;
  Obj: TIntFlag;
  SUT: IIntFlag;
  Val: TValue;
begin
  Obj := TIntFlag.Create(High(Cardinal));
  SUT := Obj;
  T := FRttiContext.GetType(Obj.ClassType);
  for P in T.GetProperties do
  begin
    if not PropIsBitBoolean(P) then Continue;
    Val := P.GetValue(Obj);
    AssertTrue(Val.AsBoolean, 'Int ' + P.Name + ' should be TRUE');
  end;
end;

procedure TFlagTests.TestInt_NoBitsSet;
var
  T: TRttiType;
  P: TRttiProperty;
  Obj: TIntFlag;
  SUT: IIntFlag;
  Val: TValue;
begin
  Obj := TIntFlag.Create(Low(Cardinal));
  SUT := Obj;
  T := FRttiContext.GetType(Obj.ClassType);
  for P in T.GetProperties do
  begin
    if not PropIsBitBoolean(P) then Continue;
    Val := P.GetValue(Obj);
    AssertFalse(Val.AsBoolean, 'Int ' + P.Name + ' should be FALSE');
  end;
end;

procedure TFlagTests.TestInt_IndividualBitSet;
var
  T: TRttiType;
  P: TRttiProperty;
  Obj: TIntFlag;
  SUT: IIntFlag;
  Bit: Integer;
  Mask: UInt64;
  Val: TValue;
begin
  T := FRttiContext.GetType(TIntFlag);
  for P in T.GetProperties do
  begin
    if not PropIsBitBoolean(P) then Continue;
    if not TryExtractBitIndex(P.Name, Bit) then Continue;
    if (Bit < 0) or (Bit > 31) then Continue;

    Mask := PowerOfTwo(Bit);
    Obj := TIntFlag.Create(Cardinal(Mask));
    SUT := Obj;
    Val := P.GetValue(Obj);
    AssertTrue(Val.AsBoolean, Format('Int %s should be TRUE (mask=$%.8x)', [P.Name, Cardinal(Mask)]));
  end;
end;

{ --- LongFlag -------------------------------------------------------------- }

procedure TFlagTests.TestLong_AllBitsSet;
var
  T: TRttiType;
  P: TRttiProperty;
  Obj: TLongFlag;
  SUT: ILongFlag;
  Val: TValue;
begin
  Obj := TLongFlag.Create(High(UInt64));
  SUT := Obj;
  T := FRttiContext.GetType(Obj.ClassType);
  for P in T.GetProperties do
  begin
    if not PropIsBitBoolean(P) then Continue;
    Val := P.GetValue(Obj);
    AssertTrue(Val.AsBoolean, 'Long ' + P.Name + ' should be TRUE');
  end;
end;

procedure TFlagTests.TestLong_NoBitsSet;
var
  T: TRttiType;
  P: TRttiProperty;
  Obj: TLongFlag;
  SUT: ILongFlag;
  Val: TValue;
begin
  Obj := TLongFlag.Create(Low(UInt64));
  SUT := Obj;
  T := FRttiContext.GetType(Obj.ClassType);
  for P in T.GetProperties do
  begin
    if not PropIsBitBoolean(P) then Continue;
    Val := P.GetValue(Obj);
    AssertFalse(Val.AsBoolean, 'Long ' + P.Name + ' should be FALSE');
  end;
end;

procedure TFlagTests.TestLong_IndividualBitSet;
var
  T: TRttiType;
  P: TRttiProperty;
  Obj: TLongFlag;
  SUT: ILongFlag;
  Bit: Integer;
  Mask: UInt64;
  Val: TValue;
begin
  T := FRttiContext.GetType(TLongFlag);
  for P in T.GetProperties do
  begin
    if not PropIsBitBoolean(P) then Continue;
    if not TryExtractBitIndex(P.Name, Bit) then Continue;
    if (Bit < 0) or (Bit > 63) then Continue;

    Mask := PowerOfTwo(Bit);
    Obj := TLongFlag.Create(Mask);
    SUT := Obj;
    Val := P.GetValue(Obj);
    AssertTrue(Val.AsBoolean, Format('Long %s should be TRUE (mask=$%.16x)', [P.Name, Mask]));
  end;
end;

initialization
  {$IFDEF FPC}
  RegisterTest(TFlagTests);
  {$ELSE}
  RegisterTest(TFlagTests.Suite);
  {$ENDIF}

end.

