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

unit DataEncoderProviderTests;

interface

uses
  System.SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpDataEncoderUtils,
  SolLibTestCase;

type
  TDataEncoderProviderTests = class(TSolLibTestCase)
  published
    procedure ShouldAcceptBase58Charset;
    procedure ShouldRejectBase58InvalidCharsetCharacters;
    procedure ShouldRejectBase58DecodeInvalidCharsetCharacters;
    procedure ShouldRoundTripBase58KnownVectors;

    procedure ShouldAcceptBase64Charset;
    procedure ShouldRejectBase64DecodeStructuralErrors;
    procedure ShouldRejectBase64InvalidCharsetCharacters;
    procedure ShouldRejectBase64DecodeInvalidCharsetCharacters;
    procedure ShouldRoundTripBase64KnownRfcVectors;

    procedure ShouldRejectHexInvalidCharsetCharacters;
    procedure ShouldRejectHexDecodeInvalidCharacters;
    procedure ShouldEncodeHexUppercaseInvariant;

    procedure ShouldAcceptSolanaKeyPairJsonCharset;
    procedure ShouldRejectSolanaKeyPairJsonInvalidCharsetCharacters;
    procedure ShouldRejectSolanaKeyPairJsonDecodeStructuralErrors;
  end;

implementation

type
  TBase58Pair = record
    Hex: string;
    B58: string;
  end;

  TBase64Pair = record
    Hex: string;
    B64: string;
  end;

const
  Base58Vectors: array[0..3] of TBase58Pair = (
    (Hex: '61'; B58: '2g'),
    (Hex: '626262'; B58: 'a3gV'),
    (Hex: '636363'; B58: 'aPEr'),
    (Hex: '00000000000000000000'; B58: '1111111111')
  );

  Base64RfcVectors: array[0..5] of TBase64Pair = (
    (Hex: '66'; B64: 'Zg=='),
    (Hex: '666F'; B64: 'Zm8='),
    (Hex: '666F6F'; B64: 'Zm9v'),
    (Hex: '666F6F62'; B64: 'Zm9vYg=='),
    (Hex: '666F6F6261'; B64: 'Zm9vYmE='),
    (Hex: '666F6F626172'; B64: 'Zm9vYmFy')
  );

procedure TDataEncoderProviderTests.ShouldAcceptBase58Charset;
begin
  AssertTrue(TBase58Encoder.IsValidCharset(''));
  AssertTrue(TBase58Encoder.IsValidCharset('2g'));
  AssertTrue(TBase58Encoder.IsValidCharset('1111111111'));
  AssertTrue(TBase58Encoder.IsValidCharset('skip'));
end;

procedure TDataEncoderProviderTests.ShouldRejectBase58InvalidCharsetCharacters;
begin
  AssertFalse(TBase58Encoder.IsValidCharset('0'));
  AssertFalse(TBase58Encoder.IsValidCharset('O'));
  AssertFalse(TBase58Encoder.IsValidCharset('I'));
  AssertFalse(TBase58Encoder.IsValidCharset('l'));
  AssertFalse(TBase58Encoder.IsValidCharset('a b'));
  AssertFalse(TBase58Encoder.IsValidCharset('a*'));
end;

procedure TDataEncoderProviderTests.ShouldRejectBase58DecodeInvalidCharsetCharacters;
begin
  AssertException(
    procedure
    begin
      DecodeBase58('a*');
    end,
    EArgumentException
  );
end;

procedure TDataEncoderProviderTests.ShouldRoundTripBase58KnownVectors;
var
  LI: Integer;
  LDecoded, LExpected: TBytes;
begin
  for LI := Low(Base58Vectors) to High(Base58Vectors) do
  begin
    LExpected := DecodeHex(Base58Vectors[LI].Hex);
    AssertEquals(Base58Vectors[LI].B58, EncodeBase58(LExpected));

    LDecoded := DecodeBase58(Base58Vectors[LI].B58);
    AssertEquals(LExpected, LDecoded);
  end;
end;

procedure TDataEncoderProviderTests.ShouldAcceptBase64Charset;
begin
  AssertTrue(TBase64Encoder.IsValidCharset(''));
  AssertTrue(TBase64Encoder.IsValidCharset('Z'));
  AssertTrue(TBase64Encoder.IsValidCharset('Zg'));
  AssertTrue(TBase64Encoder.IsValidCharset('Zm9'));
  AssertTrue(TBase64Encoder.IsValidCharset('Zm=8'));
  AssertTrue(TBase64Encoder.IsValidCharset('Zm9v=YmFy'));
  AssertTrue(TBase64Encoder.IsValidCharset('Zm9v===='));
end;

procedure TDataEncoderProviderTests.ShouldRejectBase64DecodeStructuralErrors;
begin
  AssertException(
    procedure
    begin
      DecodeBase64('');
    end,
    EArgumentException
  );

  AssertException(
    procedure
    begin
      DecodeBase64('Z');
    end,
    EArgumentException
  );
  AssertException(
    procedure
    begin
      DecodeBase64('Zg');
    end,
    EArgumentException
  );
  AssertException(
    procedure
    begin
      DecodeBase64('Zm9');
    end,
    EArgumentException
  );
end;

procedure TDataEncoderProviderTests.ShouldRejectBase64InvalidCharsetCharacters;
begin
  AssertFalse(TBase64Encoder.IsValidCharset('Zm9v*'));
  AssertFalse(TBase64Encoder.IsValidCharset('Zm9v-z'));
  AssertFalse(TBase64Encoder.IsValidCharset('Zm9v z'));
end;

procedure TDataEncoderProviderTests.ShouldRejectBase64DecodeInvalidCharsetCharacters;
begin
  AssertException(
    procedure
    begin
      DecodeBase64('Zm9v*');
    end,
    EArgumentException
  );
  AssertException(
    procedure
    begin
      DecodeBase64('Zm9v-z');
    end,
    EArgumentException
  );
  AssertException(
    procedure
    begin
      DecodeBase64('Zm9v z');
    end,
    EArgumentException
  );
end;

procedure TDataEncoderProviderTests.ShouldRoundTripBase64KnownRfcVectors;
var
  LI: Integer;
  LDecoded, LExpected: TBytes;
begin
  for LI := Low(Base64RfcVectors) to High(Base64RfcVectors) do
  begin
    LExpected := DecodeHex(Base64RfcVectors[LI].Hex);
    AssertEquals(Base64RfcVectors[LI].B64, EncodeBase64(LExpected));

    LDecoded := DecodeBase64(Base64RfcVectors[LI].B64);
    AssertEquals(LExpected, LDecoded);
  end;
end;

procedure TDataEncoderProviderTests.ShouldRejectHexInvalidCharsetCharacters;
begin
  AssertFalse(THexEncoder.IsValidCharset('GG'));
  AssertFalse(THexEncoder.IsValidCharset('A='));
  AssertFalse(THexEncoder.IsValidCharset('00ZZ'));
end;

procedure TDataEncoderProviderTests.ShouldRejectHexDecodeInvalidCharacters;
begin
  AssertException(
    procedure
    begin
      DecodeHex('GG');
    end,
    EArgumentException
  );
  AssertException(
    procedure
    begin
      DecodeHex('A=');
    end,
    EArgumentException
  );
  AssertException(
    procedure
    begin
      DecodeHex('00ZZ');
    end,
    EArgumentException
  );
end;

procedure TDataEncoderProviderTests.ShouldEncodeHexUppercaseInvariant;
var
  LBytes: TBytes;
begin
  LBytes := DecodeHex('abcdef0123456789');
  AssertEquals('ABCDEF0123456789', EncodeHex(LBytes));
end;

procedure TDataEncoderProviderTests.ShouldAcceptSolanaKeyPairJsonCharset;
begin
  AssertTrue(TSolanaKeyPairJsonEncoder.IsValidCharset(''));
  AssertTrue(TSolanaKeyPairJsonEncoder.IsValidCharset('[1,2,3]'));
  AssertTrue(TSolanaKeyPairJsonEncoder.IsValidCharset('[ 1, 2, 3 ]'));
  AssertTrue(TSolanaKeyPairJsonEncoder.IsValidCharset(#10'[1,2,3]'#13#10));
end;

procedure TDataEncoderProviderTests.ShouldRejectSolanaKeyPairJsonInvalidCharsetCharacters;
begin
  AssertFalse(TSolanaKeyPairJsonEncoder.IsValidCharset('["1",2,3]'));
  AssertFalse(TSolanaKeyPairJsonEncoder.IsValidCharset('[1,2,3.]'));
  AssertFalse(TSolanaKeyPairJsonEncoder.IsValidCharset('[1,2,3-]'));
  AssertFalse(TSolanaKeyPairJsonEncoder.IsValidCharset('[1;2;3]'));
  AssertFalse(TSolanaKeyPairJsonEncoder.IsValidCharset('[1,a,3]'));
end;

procedure TDataEncoderProviderTests.ShouldRejectSolanaKeyPairJsonDecodeStructuralErrors;
begin
  AssertException(
    procedure
    begin
      TSolanaKeyPairJsonEncoder.DecodeData('[]');
    end,
    EArgumentException
  );

  AssertException(
    procedure
    begin
      TSolanaKeyPairJsonEncoder.DecodeData('[1,2,3]');
    end,
    EArgumentException
  );
end;

initialization
{$IFDEF FPC}
  RegisterTest(TDataEncoderProviderTests);
{$ELSE}
  RegisterTest(TDataEncoderProviderTests.Suite);
{$ENDIF}

end.
