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
  SlpPublicKey,
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
    procedure TestReadBytes;

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
  LSut: TBytes;
begin
  LSut := TBytes.Create(1);
  AssertException(
    procedure
    begin
      TDeserialization.GetU8(LSut, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadU8;
var
  LSut: TBytes;
  LV: Byte;
begin
  LSut := TBytes.Create(1);
  LV := TDeserialization.GetU8(LSut, 0);
  AssertEquals(1, LV, 'GetU8');
end;

procedure TDeserializationUtilitiesTests.TestReadU16Exception;
var
  LSut: TBytes;
begin
  LSut := TBytes.Create(1,0);
  AssertException(
    procedure
    begin
      TDeserialization.GetU16(LSut, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadU16;
var
  LSut: TBytes;
  LV: Word;
begin
  LSut := TBytes.Create(1,0);
  LV := TDeserialization.GetU16(LSut, 0);
  AssertEquals(1, LV, 'GetU16 (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadU32Exception;
var
  LSut: TBytes;
begin
  LSut := TBytes.Create(1,0,0,0);
  AssertException(
    procedure
    begin
      TDeserialization.GetU32(LSut, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadU32;
var
  LSut: TBytes;
  LV: Cardinal;
begin
  LSut := TBytes.Create(1,0,0,0);
  LV := TDeserialization.GetU32(LSut, 0);
  AssertEquals(1, LV, 'GetU32 (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadU64Exception;
var
  LSut: TBytes;
begin
  LSut := TBytes.Create(1,0,0,0,0,0,0,0);
  AssertException(
    procedure
    begin
      TDeserialization.GetU64(LSut, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadU64;
var
  LSut: TBytes;
  LV: UInt64;
begin
  LSut := TBytes.Create(1,0,0,0,0,0,0,0);
  LV := TDeserialization.GetU64(LSut, 0);
  AssertEquals(1, LV, 'GetU64 (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadS8Exception;
var
  LSut: TBytes;
begin
  LSut := TBytes.Create(1);
  AssertException(
    procedure
    begin
      TDeserialization.GetS8(LSut, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadS8;
var
  LSut: TBytes;
  LV: ShortInt;
begin
  LSut := TBytes.Create(1);
  LV := TDeserialization.GetS8(LSut, 0);
  AssertEquals(1, LV, 'GetS8');
end;

procedure TDeserializationUtilitiesTests.TestReadS16Exception;
var
  LSut: TBytes;
begin
  LSut := TBytes.Create(1,0);
  AssertException(
    procedure
    begin
      TDeserialization.GetS16(LSut, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadS16;
var
  LSut: TBytes;
  LV: SmallInt;
begin
  LSut := TBytes.Create(1,0);
  LV := TDeserialization.GetS16(LSut, 0);
  AssertEquals(1, LV, 'GetS16 (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadS32Exception;
var
  LSut: TBytes;
begin
  LSut := TBytes.Create(1,0,0,0);
  AssertException(
    procedure
    begin
      TDeserialization.GetS32(LSut, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadS32;
var
  LSut: TBytes;
  LV: Integer;
begin
  LSut := TBytes.Create(1,0,0,0);
  LV := TDeserialization.GetS32(LSut, 0);
  AssertEquals(1, LV, 'GetS32 (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadS64Exception;
var
  LSut: TBytes;
begin
  LSut := TBytes.Create(1,0,0,0,0,0,0,0);
  AssertException(
    procedure
    begin
      TDeserialization.GetS64(LSut, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadS64;
var
  LSut: TBytes;
  LV: Int64;
begin
  LSut := TBytes.Create(1,0,0,0,0,0,0,0);
  LV := TDeserialization.GetS64(LSut, 0);
  AssertEquals(1, LV, 'GetS64 (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadSpanException;
var
  LPk: TBytes;
begin
  LPk := PublicKeyBytes;
  AssertException(
    procedure
    begin
      TDeserialization.GetBytes(LPk, 1, 32);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadBytes;
var
  LPk, LSpan: TBytes;
begin
  LPk := PublicKeyBytes;
  LSpan := TDeserialization.GetBytes(LPk, 0, 32);
  AssertEquals(LPk, LSpan, 'GetBytes');
end;

procedure TDeserializationUtilitiesTests.TestReadPublicKeyException;
var
  LPk: TBytes;
begin
  LPk := PublicKeyBytes;
  AssertException(
    procedure
    begin
      TDeserialization.GetPubKey(LPk, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadPublicKey;
var
  LPk: TBytes;
  LPub: IPublicKey;
begin
  LPk := PublicKeyBytes;
  LPub := TDeserialization.GetPubKey(LPk, 0);
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LPub.Key, 'GetPubKey');
end;

procedure TDeserializationUtilitiesTests.TestReadDoubleException;
var
  LB: TBytes;
begin
  LB := DoubleBytes;
  AssertException(
    procedure
    begin
      TDeserialization.GetDouble(LB, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadDouble;
var
  LB: TBytes;
  LV: Double;
begin
  LB := DoubleBytes;
  LV := TDeserialization.GetDouble(LB, 0);
  AssertEquals(1.34534534564565, LV, 0.0, 'GetDouble (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadSingleException;
var
  LB: TBytes;
begin
  LB := SingleBytes;
  AssertException(
    procedure
    begin
      TDeserialization.GetSingle(LB, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadSingle;
var
  LB: TBytes;
  LV: Single;
begin
  LB := SingleBytes;
  LV := TDeserialization.GetSingle(LB, 0);
  AssertEquals(1.34534534, LV, 0.0, 'GetSingle (LE)');
end;

procedure TDeserializationUtilitiesTests.TestReadRustStringException;
var
  LEnc: TBytes;
begin
  LEnc := EncodedStringBytes;
  AssertException(
    procedure
    begin
      TDeserialization.DecodeBincodeString(LEnc, 22);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TDeserializationUtilitiesTests.TestReadRustString;
var
  LEnc: TBytes;
  LDec: TDecodedBincodeString;
  LExpected: string;
  LExpectedLen: Integer;
begin
  LEnc := EncodedStringBytes;
  LExpected := 'this is a test string';
  LExpectedLen := Length(TEncoding.UTF8.GetBytes(LExpected)) + SizeOf(UInt64);
  LDec := TDeserialization.DecodeBincodeString(LEnc, 0);
  AssertEquals(LExpected, LDec.EncodedString, 'DecodeBincodeString text');
  AssertEquals(LExpectedLen, LDec.Length, 'DecodeBincodeString length');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TDeserializationUtilitiesTests);
{$ELSE}
  RegisterTest(TDeserializationUtilitiesTests.Suite);
{$ENDIF}

end.

