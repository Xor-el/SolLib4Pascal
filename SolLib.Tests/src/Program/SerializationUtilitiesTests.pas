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

unit SerializationUtilitiesTests;

interface

uses
  System.SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpPublicKey,
  SlpSerialization,
  SolLibProgramTestCase;

type
  TSerializationUtilitiesTests = class(TSolLibProgramTestCase)
  private

    class function PublicKeyBytes: TBytes; static;
    class function DoubleBytes: TBytes; static;
    class function SingleBytes: TBytes; static;
    class function EncodedStringBytes: TBytes; static;
  published
    procedure TestWriteU8Exception;
    procedure TestWriteU8;

    procedure TestWriteU16Exception;
    procedure TestWriteU16;

    procedure TestWriteBoolException;
    procedure TestWriteBool;

    procedure TestWriteU32Exception;
    procedure TestWriteU32;

    procedure TestWriteU64Exception;
    procedure TestWriteU64;

    procedure TestWriteS8Exception;
    procedure TestWriteS8;

    procedure TestWriteS16Exception;
    procedure TestWriteS16;

    procedure TestWriteS32Exception;
    procedure TestWriteS32;

    procedure TestWriteS64Exception;
    procedure TestWriteS64;

    procedure TestWriteSpanException;
    procedure TestWriteSpan;

    procedure TestWritePublicKeyException;
    procedure TestWritePublicKey;

    procedure TestWriteDoubleException;
    procedure TestWriteDouble;

    procedure TestWriteSingleException;
    procedure TestWriteSingle;

    procedure TestWriteRustString;
  end;

implementation

{ TSerializationUtilitiesTests }

class function TSerializationUtilitiesTests.PublicKeyBytes: TBytes;
begin
  Result := TBytes.Create(
    6,221,246,225,215,101,161,147,217,203,225,70,206,235,121,172,
    28,180,133,237,95,91,55,145,58,140,245,133,126,255,0,169
  );
end;

class function TSerializationUtilitiesTests.DoubleBytes: TBytes;
begin
  // little-endian IEEE-754 of 1.34534534564565 (8 bytes)
  Result := TBytes.Create(108,251,85,215,136,134,245,63);
end;

class function TSerializationUtilitiesTests.SingleBytes: TBytes;
begin
  // little-endian IEEE-754 of 1.34534534f (4 bytes)
  Result := TBytes.Create(71,52,172,63);
end;

class function TSerializationUtilitiesTests.EncodedStringBytes: TBytes;
begin
  // bincode-style: u64 length (LE) + UTF-8 bytes
  // len("this is a test string") = 21 -> 8 bytes LE: 21,0,0,0,0,0,0,0
  Result := TBytes.Create(
    21,0,0,0,0,0,0,0,
    116,104,105,115,32,105,115,32,97,32,116,101,115,116,32,115,116,114,105,110,103
  );
end;

procedure TSerializationUtilitiesTests.TestWriteU8Exception;
var
  SUT: TBytes;
begin
  SetLength(SUT, 1);
  AssertException(
    procedure
    begin
      TSerialization.WriteU8(SUT, 1, 2);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteU8;
var
  SUT: TBytes;
begin
  SetLength(SUT, 1);
  TSerialization.WriteU8(SUT, 1, 0);
  AssertEquals<Byte>(TBytes.Create(1), SUT, 'WriteU8');
end;

procedure TSerializationUtilitiesTests.TestWriteU16Exception;
var
  SUT: TBytes;
begin
  SetLength(SUT, 2);
  AssertException(
    procedure
    begin
      TSerialization.WriteU16(SUT, 1, 2);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteU16;
var
  SUT: TBytes;
begin
  SetLength(SUT, 2);
  TSerialization.WriteU16(SUT, 1, 0);
  AssertEquals<Byte>(TBytes.Create(1,0), SUT, 'WriteU16 (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteBoolException;
var
  SUT: TBytes;
begin
  SetLength(SUT, 2);
  AssertException(
    procedure
    begin
      TSerialization.WriteBool(SUT, True, 2);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteBool;
var
  SUT: TBytes;
begin
  SetLength(SUT, 2);
  TSerialization.WriteBool(SUT, True, 0);
  AssertEquals<Byte>(TBytes.Create(1,0), SUT, 'WriteBool');
end;

procedure TSerializationUtilitiesTests.TestWriteU32Exception;
var
  SUT: TBytes;
begin
  SetLength(SUT, 4);
  AssertException(
    procedure
    begin
      TSerialization.WriteU32(SUT, 1, 4);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteU32;
var
  SUT: TBytes;
begin
  SetLength(SUT, 4);
  TSerialization.WriteU32(SUT, 1, 0);
  AssertEquals<Byte>(TBytes.Create(1,0,0,0), SUT, 'WriteU32 (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteU64Exception;
var
  SUT: TBytes;
begin
  SetLength(SUT, 8);
  AssertException(
    procedure
    begin
      TSerialization.WriteU64(SUT, 1, 8);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteU64;
var
  SUT: TBytes;
begin
  SetLength(SUT, 8);
  TSerialization.WriteU64(SUT, 1, 0);
  AssertEquals<Byte>(TBytes.Create(1,0,0,0,0,0,0,0), SUT, 'WriteU64 (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteS8Exception;
var
  SUT: TBytes;
begin
  SetLength(SUT, 1);
  AssertException(
    procedure
    begin
      TSerialization.WriteS8(SUT, 1, 2);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteS8;
var
  SUT: TBytes;
begin
  SetLength(SUT, 1);
  TSerialization.WriteS8(SUT, 1, 0);
  AssertEquals<Byte>(TBytes.Create(1), SUT, 'WriteS8');
end;

procedure TSerializationUtilitiesTests.TestWriteS16Exception;
var
  SUT: TBytes;
begin
  SetLength(SUT, 2);
  AssertException(
    procedure
    begin
      TSerialization.WriteS16(SUT, 1, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteS16;
var
  SUT: TBytes;
begin
  SetLength(SUT, 2);
  TSerialization.WriteS16(SUT, 1, 0);
  AssertEquals<Byte>(TBytes.Create(1,0), SUT, 'WriteS16 (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteS32Exception;
var
  SUT: TBytes;
begin
  SetLength(SUT, 4);
  AssertException(
    procedure
    begin
      TSerialization.WriteS32(SUT, 1, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteS32;
var
  SUT: TBytes;
begin
  SetLength(SUT, 4);
  TSerialization.WriteS32(SUT, 1, 0);
  AssertEquals<Byte>(TBytes.Create(1,0,0,0), SUT, 'WriteS32 (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteS64Exception;
var
  SUT: TBytes;
begin
  SetLength(SUT, 8);
  AssertException(
    procedure
    begin
      TSerialization.WriteS64(SUT, 1, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteS64;
var
  SUT: TBytes;
begin
  SetLength(SUT, 8);
  TSerialization.WriteS64(SUT, 1, 0);
  AssertEquals<Byte>(TBytes.Create(1,0,0,0,0,0,0,0), SUT, 'WriteS64 (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteSpanException;
var
  SUT: TBytes;
begin
  SetLength(SUT, 32);
  AssertException(
    procedure
    begin
      TSerialization.WriteSpan(SUT, PublicKeyBytes, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteSpan;
var
  SUT: TBytes;
begin
  SetLength(SUT, 32);
  TSerialization.WriteSpan(SUT, PublicKeyBytes, 0);
  AssertEquals<Byte>(PublicKeyBytes, SUT, 'WriteSpan');
end;

procedure TSerializationUtilitiesTests.TestWritePublicKeyException;
var
  SUT: TBytes;
  LPubKey: IPublicKey;
begin
  SetLength(SUT, 32);
  AssertException(
    procedure
    begin
      LPubKey := TPublicKey.Create(PublicKeyBytes);
      TSerialization.WritePubKey(SUT, LPubKey, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWritePublicKey;
var
  SUT: TBytes;
  LPubKey: IPublicKey;
begin
  SetLength(SUT, 32);
  LPubKey := TPublicKey.Create(PublicKeyBytes);
  TSerialization.WritePubKey(SUT, LPubKey, 0);
  AssertEquals<Byte>(PublicKeyBytes, SUT, 'WritePubKey');
end;

procedure TSerializationUtilitiesTests.TestWriteDoubleException;
var
  BytesArr: TBytes;
begin
  SetLength(BytesArr, 8);
  AssertException(
    procedure
    begin
      TSerialization.WriteDouble(BytesArr, 1.34534534564565, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteDouble;
var
  BytesArr: TBytes;
begin
  SetLength(BytesArr, 8);
  TSerialization.WriteDouble(BytesArr, 1.34534534564565, 0);
  AssertEquals<Byte>(DoubleBytes, BytesArr, 'WriteDouble (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteSingleException;
var
  BytesArr: TBytes;
begin
  SetLength(BytesArr, 4);
  AssertException(
    procedure
    begin
      TSerialization.WriteSingle(BytesArr, 1.34534534, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteSingle;
var
  BytesArr: TBytes;
begin
  SetLength(BytesArr, 4);
  TSerialization.WriteSingle(BytesArr, 1.34534534, 0);
  AssertEquals<Byte>(SingleBytes, BytesArr, 'WriteSingle (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteRustString;
var
  Encoded: TBytes;
begin
  Encoded := TSerialization.EncodeBincodeString('this is a test string');
  AssertEquals<Byte>(EncodedStringBytes, Encoded, 'EncodeBincodeString');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSerializationUtilitiesTests);
{$ELSE}
  RegisterTest(TSerializationUtilitiesTests.Suite);
{$ENDIF}

end.

