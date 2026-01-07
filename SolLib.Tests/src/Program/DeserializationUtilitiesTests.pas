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

unit DeserializationUtilitiesTests;

interface

uses
  System.SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpDeserialization,
  SlpSerialization,
  SlpPublicKey,
  SlpArrayUtils,
  SolLibProgramTestCase;

type
  TDeserializationUtilitiesTests = class(TSolLibProgramTestCase)
  private
    class function PublicKeyBytes: TBytes; static;
    class function DoubleBytes: TBytes; static;
    class function SingleBytes: TBytes; static;
    class function EncodedStringBytes: TBytes; static;

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

    procedure TestReadDoubleException;
    procedure TestReadDouble;

    procedure TestReadSingleException;
    procedure TestReadSingle;

    procedure TestReadRustStringException;
    procedure TestReadRustString;
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

initialization
{$IFDEF FPC}
  RegisterTest(TDeserializationUtilitiesTests);
{$ELSE}
  RegisterTest(TDeserializationUtilitiesTests.Suite);
{$ENDIF}

end.

