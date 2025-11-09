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

unit DeserializationUtilitiesTests;

interface

uses
  System.SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  ClpBigInteger,
  SlpDeserialization,
  SlpSerialization,
  SlpPublicKey,
  SlpArrayUtils,
  SolLibProgramTestCase;

type
  TDeserializationUtilitiesTests = class(TSolLibProgramTestCase)
  private
    class function PublicKeyBytes: TBytes; static;
    class function BigIntBytes: TBytes; static;
    class function DoubleBytes: TBytes; static;
    class function SingleBytes: TBytes; static;
    class function EncodedStringBytes: TBytes; static;

    class function OneNegBytes: TBytes; static;
    class function OneBytes: TBytes; static;
    class function OneNegBEBytes: TBytes; static;
    class function OneBEBytes: TBytes; static;

    class function ZeroValueBytes: TBytes; static;
    class function NegValueBytes: TBytes; static;
    class function PosValueBytes: TBytes; static;

    class function LowNegValueBytes: TBytes; static;
    class function HighPosValueBytes: TBytes; static;

    class function LowNegValueBEBytes: TBytes; static;
    class function HighPosValueBEBytes: TBytes; static;

  published
    procedure TestReadU8Exception;
    procedure TestReadU8;

    procedure TestReadU16Exception;
    procedure TestReadU16;

    procedure TestReadU32Exception;
    procedure TestReadU32;

    procedure TestReadU64Exception;
    procedure TestReadU64;

    procedure TestReadS8Exception;
    procedure TestReadS8;

    procedure TestReadS16Exception;
    procedure TestReadS16;

    procedure TestReadS32Exception;
    procedure TestReadS32;

    procedure TestReadS64Exception;
    procedure TestReadS64;

    procedure TestReadSpanException;
    procedure TestReadSpan;

    procedure TestReadPublicKeyException;
    procedure TestReadPublicKey;

    procedure TestReadBigIntegerException;
    procedure TestReadBigInteger;

    procedure TestReadArbitraryBigEndianBigIntegers;
    procedure TestReadArbitraryLittleEndianBigIntegers;

    procedure TestReadDoubleException;
    procedure TestReadDouble;

    procedure TestReadSingleException;
    procedure TestReadSingle;

    procedure TestReadRustStringException;
    procedure TestReadRustString;

    procedure TestBigIntSerDes;
  end;

implementation

{ TDeserializationUtilitiesTests }

class function TDeserializationUtilitiesTests.PublicKeyBytes: TBytes;
begin
  Result := TBytes.Create(
    6,221,246,225,215,101,161,147,217,203,
    225,70,206,235,121,172,28,180,133,237,
    95,91,55,145,58,140,245,133,126,255,0,169
  );
end;

class function TDeserializationUtilitiesTests.BigIntBytes: TBytes;
begin
  Result := TBytes.Create(
    153,153,153,153,153,153,153,153,
    153,153,153,153,153,153,153,25
  );
end;

class function TDeserializationUtilitiesTests.DoubleBytes: TBytes;
begin
  // little-endian IEEE-754 of 1.34534534564565 (8 bytes)
  Result := TBytes.Create(108,251,85,215,136,134,245,63);
end;

class function TDeserializationUtilitiesTests.SingleBytes: TBytes;
begin
  // little-endian IEEE-754 of 1.34534534f (4 bytes)
  Result := TBytes.Create(71,52,172,63);
end;

class function TDeserializationUtilitiesTests.EncodedStringBytes: TBytes;
begin
  // bincode: u64 len (LE) + UTF-8("this is a test string")
  Result := TBytes.Create(
    21,0,0,0,0,0,0,0,
    116,104,105,115,32,105,115,32,97,32,116,101,115,116,32,115,116,114,105,110,103
  );
end;

class function TDeserializationUtilitiesTests.OneNegBytes: TBytes;
begin
  Result := TBytes.Create(
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
  );
end;

class function TDeserializationUtilitiesTests.OneBytes: TBytes;
begin
  Result := TBytes.Create(
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  );
end;

class function TDeserializationUtilitiesTests.OneNegBEBytes: TBytes;
begin
  Result := TBytes.Create(
    255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
  );
end;

class function TDeserializationUtilitiesTests.OneBEBytes: TBytes;
begin
  Result := TBytes.Create(
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
  );
end;

class function TDeserializationUtilitiesTests.ZeroValueBytes: TBytes;
begin
  Result := TBytes.Create(
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  );
end;

class function TDeserializationUtilitiesTests.NegValueBytes: TBytes;
begin
  Result := TBytes.Create(
    0,0,0,0,0,0,255,255,255,255,255,255,255,255,255,255
  );
end;

class function TDeserializationUtilitiesTests.PosValueBytes: TBytes;
begin
  Result := TBytes.Create(
    0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0
  );
end;

class function TDeserializationUtilitiesTests.LowNegValueBytes: TBytes;
begin
  Result := TBytes.Create(
    0,0,0,0,0,0,0,0,0,0,0,0,0,255,255,255
  );
end;

class function TDeserializationUtilitiesTests.HighPosValueBytes: TBytes;
begin
  Result := TBytes.Create(
    0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0
  );
end;

class function TDeserializationUtilitiesTests.LowNegValueBEBytes: TBytes;
begin
  Result := TBytes.Create(
    255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  );
end;

class function TDeserializationUtilitiesTests.HighPosValueBEBytes: TBytes;
begin
  Result := TBytes.Create(
    0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
  );
end;

procedure TDeserializationUtilitiesTests.TestReadU8Exception;
var
  SUT: TBytes;
begin
  SUT := TBytes.Create(1);
  AssertException(
    procedure
    begin
      TDeserialization.GetU8(SUT, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadU8;
var
  SUT: TBytes;
  v: Byte;
begin
  SUT := TBytes.Create(1);
  v := TDeserialization.GetU8(SUT, 0);
  AssertEquals(1, v, 'GetU8');
end;

procedure TDeserializationUtilitiesTests.TestReadU16Exception;
var
  SUT: TBytes;
begin
  SUT := TBytes.Create(1,0);
  AssertException(
    procedure
    begin
      TDeserialization.GetU16(SUT, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadU16;
var
  SUT: TBytes;
  v: Word;
begin
  SUT := TBytes.Create(1,0);
  v := TDeserialization.GetU16(SUT, 0);
  AssertEquals(1, v, 'GetU16 (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadU32Exception;
var
  SUT: TBytes;
begin
  SUT := TBytes.Create(1,0,0,0);
  AssertException(
    procedure
    begin
      TDeserialization.GetU32(SUT, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadU32;
var
  SUT: TBytes;
  v: Cardinal;
begin
  SUT := TBytes.Create(1,0,0,0);
  v := TDeserialization.GetU32(SUT, 0);
  AssertEquals(1, v, 'GetU32 (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadU64Exception;
var
  SUT: TBytes;
begin
  SUT := TBytes.Create(1,0,0,0,0,0,0,0);
  AssertException(
    procedure
    begin
      TDeserialization.GetU64(SUT, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadU64;
var
  SUT: TBytes;
  v: UInt64;
begin
  SUT := TBytes.Create(1,0,0,0,0,0,0,0);
  v := TDeserialization.GetU64(SUT, 0);
  AssertEquals(1, v, 'GetU64 (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadS8Exception;
var
  SUT: TBytes;
begin
  SUT := TBytes.Create(1);
  AssertException(
    procedure
    begin
      TDeserialization.GetS8(SUT, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadS8;
var
  SUT: TBytes;
  v: ShortInt;
begin
  SUT := TBytes.Create(1);
  v := TDeserialization.GetS8(SUT, 0);
  AssertEquals(1, v, 'GetS8');
end;

procedure TDeserializationUtilitiesTests.TestReadS16Exception;
var
  SUT: TBytes;
begin
  SUT := TBytes.Create(1,0);
  AssertException(
    procedure
    begin
      TDeserialization.GetS16(SUT, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadS16;
var
  SUT: TBytes;
  v: SmallInt;
begin
  SUT := TBytes.Create(1,0);
  v := TDeserialization.GetS16(SUT, 0);
  AssertEquals(1, v, 'GetS16 (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadS32Exception;
var
  SUT: TBytes;
begin
  SUT := TBytes.Create(1,0,0,0);
  AssertException(
    procedure
    begin
      TDeserialization.GetS32(SUT, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadS32;
var
  SUT: TBytes;
  v: Integer;
begin
  SUT := TBytes.Create(1,0,0,0);
  v := TDeserialization.GetS32(SUT, 0);
  AssertEquals(1, v, 'GetS32 (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadS64Exception;
var
  SUT: TBytes;
begin
  SUT := TBytes.Create(1,0,0,0,0,0,0,0);
  AssertException(
    procedure
    begin
      TDeserialization.GetS64(SUT, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadS64;
var
  SUT: TBytes;
  v: Int64;
begin
  SUT := TBytes.Create(1,0,0,0,0,0,0,0);
  v := TDeserialization.GetS64(SUT, 0);
  AssertEquals(1, v, 'GetS64 (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadSpanException;
var
  PK: TBytes;
begin
  PK := PublicKeyBytes;
  AssertException(
    procedure
    begin
      TDeserialization.GetSpan(PK, 1, 32);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadSpan;
var
  PK, Span: TBytes;
begin
  PK := PublicKeyBytes;
  Span := TDeserialization.GetSpan(PK, 0, 32);
  AssertEquals<Byte>(PK, Span, 'GetSpan');
end;

procedure TDeserializationUtilitiesTests.TestReadPublicKeyException;
var
  PK: TBytes;
begin
  PK := PublicKeyBytes;
  AssertException(
    procedure
    begin
      TDeserialization.GetPubKey(PK, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadPublicKey;
var
  PK: TBytes;
  Pub: IPublicKey;
begin
  PK := PublicKeyBytes;
  Pub := TDeserialization.GetPubKey(PK, 0);
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', Pub.Key, 'GetPubKey');
end;

procedure TDeserializationUtilitiesTests.TestReadBigIntegerException;
var
  B: TBytes;
begin
  B := BigIntBytes;
  AssertException(
    procedure
    begin
      TDeserialization.GetBigInt(B, 1, 16);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadBigInteger;
var
  B, BE: TBytes;
  Expected, Actual: TBigInteger;
begin
  B := BigIntBytes;
    // NOTE: Our TBigInteger expects BIG-ENDIAN. The bytes are coming as as LITTLE-ENDIAN two's complement.
   // we reverse the LE fixture to BE before constructing TBigInteger.
  BE := TArrayUtils.Reverse<Byte>(B);
  Expected := TBigInteger.Create(BE);
  Actual := TDeserialization.GetBigInt(B, 0, 16); // default: little-endian
  AssertTrue(Expected.Equals(Actual), 'GetBigInt basic (LE bytes) mismatch');
end;

procedure TDeserializationUtilitiesTests.TestReadArbitraryBigEndianBigIntegers;
var
  HighPosBE, LowNegBE, OneBE, OneNegBE: TBytes;
  Actual, BI: TBigInteger;
begin
  HighPosBE := HighPosValueBEBytes;
  LowNegBE  := LowNegValueBEBytes;
  OneBE     := OneBEBytes;
  OneNegBE  := OneNegBEBytes;

  // signed big-endian
  Actual := TBigInteger.Create(HighPosBE);
  BI := TDeserialization.GetBigInt(HighPosBE, 0, 16, False, True);
  AssertTrue(Actual.Equals(BI), 'BE high positive (signed)');
  AssertTrue(BI.Equals(TBigInteger.Create('20282409603651670423947251286016')), 'BE high positive value');

  // unsigned big-endian
  Actual := TBigInteger.Create(1, HighPosBE); // signum=+1, magnitude (BE)
  BI := TDeserialization.GetBigInt(HighPosBE, 0, 16, True, True);
  AssertTrue(Actual.Equals(BI), 'BE high positive (unsigned)');
  AssertTrue(BI.Equals(TBigInteger.Create('20282409603651670423947251286016')), 'BE high positive unsigned value');

  // signed big-endian negative
  BI := TDeserialization.GetBigInt(LowNegBE, 0, 16, False, True);
  AssertTrue(BI.Equals(TBigInteger.Create('-20282409603651670423947251286016')), 'BE low negative value');

  // +1 (signed BE)
  Actual := TBigInteger.Create(OneBE);
  BI := TDeserialization.GetBigInt(OneBE, 0, 16, False, True);
  AssertTrue(Actual.Equals(BI), 'BE +1 (signed)');
  AssertTrue(BI.Equals(TBigInteger.One), 'BE +1 value');

  // -1 (all 0xFF, signed BE)
  Actual := TBigInteger.Create(OneNegBE);
  BI := TDeserialization.GetBigInt(OneNegBE, 0, 16, False, True);
  AssertTrue(Actual.Equals(BI), 'BE -1 (signed)');
  AssertTrue(BI.Equals(TBigInteger.ValueOf(-1)), 'BE -1 value');
end;

procedure TDeserializationUtilitiesTests.TestReadArbitraryLittleEndianBigIntegers;
var
  ZeroLE, PosLE, NegLE, LowNegLE, HighPosLE, OneLE, OneNegLE: TBytes;
  Actual, BI: TBigInteger;
begin
  ZeroLE    := ZeroValueBytes;
  PosLE     := PosValueBytes;
  NegLE     := NegValueBytes;
  LowNegLE  := LowNegValueBytes;
  HighPosLE := HighPosValueBytes;
  OneLE     := OneBytes;
  OneNegLE  := OneNegBytes;

  // NOTE: Our TBigInteger expects BIG-ENDIAN. The bytes are coming as as LITTLE-ENDIAN two's complement.
  // we reverse the LE fixture to BE before constructing TBigInteger.

  // 0
  Actual := TBigInteger.Create(TArrayUtils.Reverse<Byte>(ZeroLE));
  BI := TDeserialization.GetBigInt(ZeroLE, 0, 16); // default: LE signed
  AssertTrue(Actual.Equals(BI), 'LE zero equality');
  AssertTrue(BI.Equals(TBigInteger.Zero), 'LE zero value');

  // +2^48 = 281474976710656
  Actual := TBigInteger.Create(TArrayUtils.Reverse<Byte>(PosLE));
  BI := TDeserialization.GetBigInt(PosLE, 0, 16);
  AssertTrue(Actual.Equals(BI), 'LE +2^48 equality');
  AssertTrue(BI.Equals(TBigInteger.Create('281474976710656')), 'LE +2^48 value');

  // -2^48 = -281474976710656
  BI := TDeserialization.GetBigInt(NegLE, 0, 16);
  AssertTrue(BI.Equals(TBigInteger.Create('-281474976710656')), 'LE -2^48 value');

  // large positive (signed LE)
  Actual := TBigInteger.Create(TArrayUtils.Reverse<Byte>(HighPosLE));
  BI := TDeserialization.GetBigInt(HighPosLE, 0, 16);
  AssertTrue(Actual.Equals(BI), 'LE large + (signed) equality');
  AssertTrue(BI.Equals(TBigInteger.Create('20282409603651670423947251286016')), 'LE large + (signed) value');

  // large positive (unsigned LE)
  Actual := TBigInteger.Create(1, TArrayUtils.Reverse<Byte>(HighPosLE)); // signum=+1, magnitude (BE)
  BI := TDeserialization.GetBigInt(HighPosLE, 0, 16, True);
  AssertTrue(Actual.Equals(BI), 'LE large + (unsigned) equality');
  AssertTrue(BI.Equals(TBigInteger.Create('20282409603651670423947251286016')), 'LE large + (unsigned) value');

  // large negative (signed LE)
  BI := TDeserialization.GetBigInt(LowNegLE, 0, 16);
  AssertTrue(BI.Equals(TBigInteger.Create('-20282409603651670423947251286016')), 'LE large - (signed) value');

  // +1
  Actual := TBigInteger.Create(TArrayUtils.Reverse<Byte>(OneLE));
  BI := TDeserialization.GetBigInt(OneLE, 0, 16);
  AssertTrue(Actual.Equals(BI), 'LE +1 equality');
  AssertTrue(BI.Equals(TBigInteger.One), 'LE +1 value');

  // -1
  Actual := TBigInteger.Create(TArrayUtils.Reverse<Byte>(OneNegLE));
  BI := TDeserialization.GetBigInt(OneNegLE, 0, 16);
  AssertTrue(Actual.Equals(BI), 'LE -1 equality');
  AssertTrue(BI.Equals(TBigInteger.ValueOf(-1)), 'LE -1 value');
end;



procedure TDeserializationUtilitiesTests.TestReadDoubleException;
var
  B: TBytes;
begin
  B := DoubleBytes;
  AssertException(
    procedure
    begin
      TDeserialization.GetDouble(B, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadDouble;
var
  B: TBytes;
  v: Double;
begin
  B := DoubleBytes;
  v := TDeserialization.GetDouble(B, 0);
  AssertEquals(1.34534534564565, v, 0.0, 'GetDouble (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadSingleException;
var
  B: TBytes;
begin
  B := SingleBytes;
  AssertException(
    procedure
    begin
      TDeserialization.GetSingle(B, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadSingle;
var
  B: TBytes;
  v: Single;
begin
  B := SingleBytes;
  v := TDeserialization.GetSingle(B, 0);
  AssertEquals(1.34534534, v, 0.0, 'GetSingle (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadRustStringException;
var
  Enc: TBytes;
begin
  Enc := EncodedStringBytes;
  AssertException(
    procedure
    begin
      TDeserialization.DecodeBincodeString(Enc, 22);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadRustString;
var
  Enc: TBytes;
  Dec: TDecodedBincodeString;
  Expected: string;
  ExpectedLen: Integer;
begin
  Enc := EncodedStringBytes;
  Expected := 'this is a test string';
  ExpectedLen := Length(TEncoding.UTF8.GetBytes(Expected)) + SizeOf(UInt64);
  Dec := TDeserialization.DecodeBincodeString(Enc, 0);
  AssertEquals(Expected, Dec.EncodedString, 'DecodeBincodeString text');
  AssertEquals(ExpectedLen, Dec.Length, 'DecodeBincodeString length');
end;

procedure TDeserializationUtilitiesTests.TestBigIntSerDes;
var
  BI, BI2: TBigInteger;
  Buf: TBytes;
begin
  BI := TBigInteger.ValueOf(Low(Int64));
  SetLength(Buf, 16);
  TSerialization.WriteBigInt(Buf, BI, 0, 16);
  BI2 := TDeserialization.GetBigInt(Buf, 0, 16);
  AssertTrue(BI.Equals(BI2), 'BigInt round-trip');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TDeserializationUtilitiesTests);
{$ELSE}
  RegisterTest(TDeserializationUtilitiesTests.Suite);
{$ENDIF}

end.

