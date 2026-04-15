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
  SysUtils,
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

    procedure TestWriteBytesException;
    procedure TestWriteBytes;

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
  LSUT: TBytes;
begin
  SetLength(LSUT, 1);
  AssertException(
    procedure
    begin
      TSerialization.WriteU8(LSUT, 1, 2);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteU8;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 1);
  TSerialization.WriteU8(LSUT, 1, 0);
  AssertEquals(TBytes.Create(1), LSUT, 'WriteU8');
end;

procedure TSerializationUtilitiesTests.TestWriteU16Exception;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 2);
  AssertException(
    procedure
    begin
      TSerialization.WriteU16(LSUT, 1, 2);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteU16;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 2);
  TSerialization.WriteU16(LSUT, 1, 0);
  AssertEquals(TBytes.Create(1,0), LSUT, 'WriteU16 (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteBoolException;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 2);
  AssertException(
    procedure
    begin
      TSerialization.WriteBool(LSUT, True, 2);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteBool;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 2);
  TSerialization.WriteBool(LSUT, True, 0);
  AssertEquals(TBytes.Create(1,0), LSUT, 'WriteBool');
end;

procedure TSerializationUtilitiesTests.TestWriteU32Exception;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 4);
  AssertException(
    procedure
    begin
      TSerialization.WriteU32(LSUT, 1, 4);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteU32;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 4);
  TSerialization.WriteU32(LSUT, 1, 0);
  AssertEquals(TBytes.Create(1,0,0,0), LSUT, 'WriteU32 (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteU64Exception;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 8);
  AssertException(
    procedure
    begin
      TSerialization.WriteU64(LSUT, 1, 8);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteU64;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 8);
  TSerialization.WriteU64(LSUT, 1, 0);
  AssertEquals(TBytes.Create(1,0,0,0,0,0,0,0), LSUT, 'WriteU64 (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteS8Exception;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 1);
  AssertException(
    procedure
    begin
      TSerialization.WriteS8(LSUT, 1, 2);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteS8;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 1);
  TSerialization.WriteS8(LSUT, 1, 0);
  AssertEquals(TBytes.Create(1), LSUT, 'WriteS8');
end;

procedure TSerializationUtilitiesTests.TestWriteS16Exception;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 2);
  AssertException(
    procedure
    begin
      TSerialization.WriteS16(LSUT, 1, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteS16;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 2);
  TSerialization.WriteS16(LSUT, 1, 0);
  AssertEquals(TBytes.Create(1,0), LSUT, 'WriteS16 (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteS32Exception;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 4);
  AssertException(
    procedure
    begin
      TSerialization.WriteS32(LSUT, 1, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteS32;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 4);
  TSerialization.WriteS32(LSUT, 1, 0);
  AssertEquals(TBytes.Create(1,0,0,0), LSUT, 'WriteS32 (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteS64Exception;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 8);
  AssertException(
    procedure
    begin
      TSerialization.WriteS64(LSUT, 1, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteS64;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 8);
  TSerialization.WriteS64(LSUT, 1, 0);
  AssertEquals(TBytes.Create(1,0,0,0,0,0,0,0), LSUT, 'WriteS64 (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteBytesException;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 32);
  AssertException(
    procedure
    begin
      TSerialization.WriteBytes(LSUT, PublicKeyBytes, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteBytes;
var
  LSUT: TBytes;
begin
  SetLength(LSUT, 32);
  TSerialization.WriteBytes(LSUT, PublicKeyBytes, 0);
  AssertEquals(PublicKeyBytes, LSUT, 'WriteSpan');
end;

procedure TSerializationUtilitiesTests.TestWritePublicKeyException;
var
  LSUT: TBytes;
  LPubKey: IPublicKey;
begin
  SetLength(LSUT, 32);
  AssertException(
    procedure
    begin
      LPubKey := TPublicKey.Create(PublicKeyBytes);
      TSerialization.WritePubKey(LSUT, LPubKey, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWritePublicKey;
var
  LSUT: TBytes;
  LPubKey: IPublicKey;
begin
  SetLength(LSUT, 32);
  LPubKey := TPublicKey.Create(PublicKeyBytes);
  TSerialization.WritePubKey(LSUT, LPubKey, 0);
  AssertEquals(PublicKeyBytes, LSUT, 'WritePubKey');
end;

procedure TSerializationUtilitiesTests.TestWriteDoubleException;
var
  LBytesArr: TBytes;
begin
  SetLength(LBytesArr, 8);
  AssertException(
    procedure
    begin
      TSerialization.WriteDouble(LBytesArr, 1.34534534564565, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteDouble;
var
  LBytesArr: TBytes;
begin
  SetLength(LBytesArr, 8);
  TSerialization.WriteDouble(LBytesArr, 1.34534534564565, 0);
  AssertEquals(DoubleBytes, LBytesArr, 'WriteDouble (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteSingleException;
var
  LBytesArr: TBytes;
begin
  SetLength(LBytesArr, 4);
  AssertException(
    procedure
    begin
      TSerialization.WriteSingle(LBytesArr, 1.34534534, 1);
    end,
    EArgumentOutOfRangeException
  );
end;

procedure TSerializationUtilitiesTests.TestWriteSingle;
var
  LBytesArr: TBytes;
begin
  SetLength(LBytesArr, 4);
  TSerialization.WriteSingle(LBytesArr, 1.34534534, 0);
  AssertEquals(SingleBytes, LBytesArr, 'WriteSingle (LE)');
end;

procedure TSerializationUtilitiesTests.TestWriteRustString;
var
  LEncoded: TBytes;
begin
  LEncoded := TSerialization.EncodeBincodeString('this is a test string');
  AssertEquals(EncodedStringBytes, LEncoded, 'EncodeBincodeString');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSerializationUtilitiesTests);
{$ELSE}
  RegisterTest(TSerializationUtilitiesTests.Suite);
{$ENDIF}

end.

