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
  LP, LI, LStartIdx: Integer;
  LDigits: string;
begin
  Result := False;
  ABit := -1;

  LP := Pos('Bit', APropName);
  if LP <= 0 then Exit;

  LStartIdx := LP + Length('Bit');
  LDigits := '';
  for LI := LStartIdx to Length(APropName) do
  begin
    if CharInSet(APropName[LI], ['0'..'9']) then
      LDigits := LDigits + APropName[LI]
    else
      Break;
  end;

  Result := (LDigits <> '') and TryStrToInt(LDigits, ABit);
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
  LT: TRttiType;
  LP: TRttiProperty;
  LObj: TByteFlag;
  LSut: IByteFlag;
  LVal: TValue;
begin
  LObj := TByteFlag.Create(High(Byte));
  LSut := LObj;
  LT := FRttiContext.GetType(LObj.ClassType);
  for LP in LT.GetProperties do
  begin
    if not PropIsBitBoolean(LP) then Continue;
    LVal := LP.GetValue(LObj);
    AssertTrue(LVal.AsBoolean, 'Byte ' + LP.Name + ' should be TRUE');
  end;
end;

procedure TFlagTests.TestByte_NoBitsSet;
var
  LT: TRttiType;
  LP: TRttiProperty;
  LObj: TByteFlag;
  LSut: IByteFlag;
  LVal: TValue;
begin
  LObj := TByteFlag.Create(Low(Byte));
  LSut := LObj;
  LT := FRttiContext.GetType(LObj.ClassType);
  for LP in LT.GetProperties do
  begin
    if not PropIsBitBoolean(LP) then Continue;
    LVal := LP.GetValue(LObj);
    AssertFalse(LVal.AsBoolean, 'Byte ' + LP.Name + ' should be FALSE');
  end;
end;

procedure TFlagTests.TestByte_IndividualBitSet;
var
  LT: TRttiType;
  LP: TRttiProperty;
  LObj: TByteFlag;
  LSut: IByteFlag;
  LBit: Integer;
  LMask: UInt64;
  LVal: TValue;
begin
  LT := FRttiContext.GetType(TByteFlag);
  for LP in LT.GetProperties do
  begin
    if not PropIsBitBoolean(LP) then Continue;
    if not TryExtractBitIndex(LP.Name, LBit) then Continue;
    if (LBit < 0) or (LBit > 7) then Continue;

    LMask := PowerOfTwo(LBit);
    LObj := TByteFlag.Create(Byte(LMask));
    LSut := LObj;
    LVal := LP.GetValue(LObj);
    AssertTrue(LVal.AsBoolean, Format('Byte %s should be TRUE (mask=$%.2x)', [LP.Name, Byte(LMask)]));
  end;
end;

{ --- ShortFlag ------------------------------------------------------------- }

procedure TFlagTests.TestShort_AllBitsSet;
var
  LT: TRttiType;
  LP: TRttiProperty;
  LObj: TShortFlag;
  LSut: IShortFlag;
  LVal: TValue;
begin
  LObj := TShortFlag.Create(High(Word));
  LSut := LObj;
  LT := FRttiContext.GetType(LObj.ClassType);
  for LP in LT.GetProperties do
  begin
    if not PropIsBitBoolean(LP) then Continue;
    LVal := LP.GetValue(LObj);
    AssertTrue(LVal.AsBoolean, 'Short ' + LP.Name + ' should be TRUE');
  end;
end;

procedure TFlagTests.TestShort_NoBitsSet;
var
  LT: TRttiType;
  LP: TRttiProperty;
  LObj: TShortFlag;
  LSut: IShortFlag;
  LVal: TValue;
begin
  LObj := TShortFlag.Create(Low(Word));
  LSut := LObj;
  LT := FRttiContext.GetType(LObj.ClassType);
  for LP in LT.GetProperties do
  begin
    if not PropIsBitBoolean(LP) then Continue;
    LVal := LP.GetValue(LObj);
    AssertFalse(LVal.AsBoolean, 'Short ' + LP.Name + ' should be FALSE');
  end;
end;

procedure TFlagTests.TestShort_IndividualBitSet;
var
  LT: TRttiType;
  LP: TRttiProperty;
  LObj: TShortFlag;
  LSut: IShortFlag;
  LBit: Integer;
  LMask: UInt64;
  LVal: TValue;
begin
  LT := FRttiContext.GetType(TShortFlag);
  for LP in LT.GetProperties do
  begin
    if not PropIsBitBoolean(LP) then Continue;
    if not TryExtractBitIndex(LP.Name, LBit) then Continue;
    if (LBit < 0) or (LBit > 15) then Continue;

    LMask := PowerOfTwo(LBit);
    LObj := TShortFlag.Create(Word(LMask));
    LSut := LObj;
    LVal := LP.GetValue(LObj);
    AssertTrue(LVal.AsBoolean, Format('Short %s should be TRUE (mask=$%.4x)', [LP.Name, Word(LMask)]));
  end;
end;

{ --- IntFlag --------------------------------------------------------------- }

procedure TFlagTests.TestInt_AllBitsSet;
var
  LT: TRttiType;
  LP: TRttiProperty;
  LObj: TIntFlag;
  LSut: IIntFlag;
  LVal: TValue;
begin
  LObj := TIntFlag.Create(High(Cardinal));
  LSut := LObj;
  LT := FRttiContext.GetType(LObj.ClassType);
  for LP in LT.GetProperties do
  begin
    if not PropIsBitBoolean(LP) then Continue;
    LVal := LP.GetValue(LObj);
    AssertTrue(LVal.AsBoolean, 'Int ' + LP.Name + ' should be TRUE');
  end;
end;

procedure TFlagTests.TestInt_NoBitsSet;
var
  LT: TRttiType;
  LP: TRttiProperty;
  LObj: TIntFlag;
  LSut: IIntFlag;
  LVal: TValue;
begin
  LObj := TIntFlag.Create(Low(Cardinal));
  LSut := LObj;
  LT := FRttiContext.GetType(LObj.ClassType);
  for LP in LT.GetProperties do
  begin
    if not PropIsBitBoolean(LP) then Continue;
    LVal := LP.GetValue(LObj);
    AssertFalse(LVal.AsBoolean, 'Int ' + LP.Name + ' should be FALSE');
  end;
end;

procedure TFlagTests.TestInt_IndividualBitSet;
var
  LT: TRttiType;
  LP: TRttiProperty;
  LObj: TIntFlag;
  LSut: IIntFlag;
  LBit: Integer;
  LMask: UInt64;
  LVal: TValue;
begin
  LT := FRttiContext.GetType(TIntFlag);
  for LP in LT.GetProperties do
  begin
    if not PropIsBitBoolean(LP) then Continue;
    if not TryExtractBitIndex(LP.Name, LBit) then Continue;
    if (LBit < 0) or (LBit > 31) then Continue;

    LMask := PowerOfTwo(LBit);
    LObj := TIntFlag.Create(Cardinal(LMask));
    LSut := LObj;
    LVal := LP.GetValue(LObj);
    AssertTrue(LVal.AsBoolean, Format('Int %s should be TRUE (mask=$%.8x)', [LP.Name, Cardinal(LMask)]));
  end;
end;

{ --- LongFlag -------------------------------------------------------------- }

procedure TFlagTests.TestLong_AllBitsSet;
var
  LT: TRttiType;
  LP: TRttiProperty;
  LObj: TLongFlag;
  LSut: ILongFlag;
  LVal: TValue;
begin
  LObj := TLongFlag.Create(High(UInt64));
  LSut := LObj;
  LT := FRttiContext.GetType(LObj.ClassType);
  for LP in LT.GetProperties do
  begin
    if not PropIsBitBoolean(LP) then Continue;
    LVal := LP.GetValue(LObj);
    AssertTrue(LVal.AsBoolean, 'Long ' + LP.Name + ' should be TRUE');
  end;
end;

procedure TFlagTests.TestLong_NoBitsSet;
var
  LT: TRttiType;
  LP: TRttiProperty;
  LObj: TLongFlag;
  LSut: ILongFlag;
  LVal: TValue;
begin
  LObj := TLongFlag.Create(Low(UInt64));
  LSut := LObj;
  LT := FRttiContext.GetType(LObj.ClassType);
  for LP in LT.GetProperties do
  begin
    if not PropIsBitBoolean(LP) then Continue;
    LVal := LP.GetValue(LObj);
    AssertFalse(LVal.AsBoolean, 'Long ' + LP.Name + ' should be FALSE');
  end;
end;

procedure TFlagTests.TestLong_IndividualBitSet;
var
  LT: TRttiType;
  LP: TRttiProperty;
  LObj: TLongFlag;
  LSut: ILongFlag;
  LBit: Integer;
  LMask: UInt64;
  LVal: TValue;
begin
  LT := FRttiContext.GetType(TLongFlag);
  for LP in LT.GetProperties do
  begin
    if not PropIsBitBoolean(LP) then Continue;
    if not TryExtractBitIndex(LP.Name, LBit) then Continue;
    if (LBit < 0) or (LBit > 63) then Continue;

    LMask := PowerOfTwo(LBit);
    LObj := TLongFlag.Create(LMask);
    LSut := LObj;
    LVal := LP.GetValue(LObj);
    AssertTrue(LVal.AsBoolean, Format('Long %s should be TRUE (mask=$%.16x)', [LP.Name, LMask]));
  end;
end;

initialization
  {$IFDEF FPC}
  RegisterTest(TFlagTests);
  {$ELSE}
  RegisterTest(TFlagTests.Suite);
  {$ENDIF}

end.

