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

unit InstructionDecoderTests;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpRpcModel,
  SlpPublicKey,
  SlpMessageDomain,
  SlpDecodedInstruction,
  SlpInstructionDecoder,
  TestUtils,
  SolLibProgramTestCase;

type
  TInstructionDecoderTests = class(TSolLibProgramTestCase)
  private
    const
      Base64Message =
        'AgAEBmeEU5GowlV7Ug3Y0gjKv+31fvJ5iq+FC+pj+blJfEu615Bs5Vo6mnXZXvh35ULmThtyhwH8xzD' +
        'k8CgGqB1ISymLH0tOe6K/10n8jVYmg9CCzfFJ7Q/PtKWCWZjI/MJBiQan1RcZLFxRIYzJTD1K8X9Y2u4I' +
        'm6H9ROPb2YoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAG3fbh12Whk9nL4UbO63msHL' +
        'SF7V9bN5E6jPWFfv8AqeIfQzb6ERv8S2AqP3kpqFe1rhOi8a8q+HoB5Z/4WUfiAgQCAAE0AAAAAPAdHwAA' +
        'AAAApQAAAAAAAAAG3fbh12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqQUEAQIAAwEB';

      UnknownInstructionMessage =
        'AwEGCUdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyCPOc5WStiVWB4ReLWRVhjoAuppEeHwUSMtbx8Hmno' +
        'KY5g1hGR0SDr+x4hAd1OcuUEXP1Qyz3cU0b269EfBZb0gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAie' +
        '4Ib1GlNzTEd9tj6EsaSwCA+dBgbKr3clv2+RhHVDMGp9UXGSxcUSGMyUw9SvF/WNruCJuh/UTj29mKAAAAAAbd9uH' +
        'XZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCp99LcpEIowBKqPubkZpgpqc6op2m6ZVvkvRXPi79K+JMFSlNQ+F3I' +
        'gtYUpVZyeIopbd8eq6vQpgZ4iEky9O72oNgehyYY23GSdVDMiMrfxgbHc/HskbbAJqVQk2Dp67h1BAMCAAE0AAAAAP' +
        'AdHwAAAAAApQAAAAAAAAAG3fbh12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqQYEAQQABQEBBwEABQEADxlNCAE' +
        'CEkhlbGxvIGZyb20gU29sLk5ldA==';

      SharedMemoryWriteMessage =
        'AwEGCkdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyCPOc5WStiVWB4ReLWRVhjoAuppEeHwUSMtbx8Hmno' +
        'KY5g1hGR0SDr+x4hAd1OcuUEXP1Qyz3cU0b269EfBZb0vfS3KRCKMASqj7m5GaYKanOqKdpumVb5L0Vz4u/SviTAA' +
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACJ7ghvUaU3NMR322PoSxpLAID50GBsqvdyW/b5GEdUMwan1Rc' +
        'ZLFxRIYzJTD1K8X9Y2u4Im6H9ROPb2YoAAAAABt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKkM/SOZwBqi' +
        'laVYsFyh41xY7e10qTG6fOOim2gK/x/4MQVKU1D4XciC1hSlVnJ4iilt3x6rq9CmBniISTL07vag3QptoQFT2idlV' +
        'hj784S1Z6y6aq7mtGY0w6DA4CNAT+8EBAIAATQAAAAA8B0fAAAAAAClAAAAAAAAAAbd9uHXZaGT2cvhRs7reawctI' +
        'XtX1s3kTqM9YV+/wCpBwQBBQAGAQEIAQMNIwAAAAAAAAABAA8ZTQkBAhJIZWxsbyBmcm9tIFNvbC5OZXQ=';

      DurableNonceMessage =
        'AQACBUdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyhNzOq+Q0cJXarsJajrlwwzlmWoF5mx5wFN8OQ4OOJK' +
        'Lf9OU4VvMASlY6OI4RgnGTPQGIfvMW4q1sStRoUcd4tAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABqfV' +
        'FxksVo7gioRfc9KXiM8DXDFFshqzRNgGLqlAAACZ4OYEN7QEC8ChfqU50z8BgjxTJ0SwSF/AQXoalEjsRgIDAwIEAA' +
        'QEAAAAAwIAAQwCAAAAAMqaOwAAAAA=';

      CreateWithSeedTransferCheckedMessage =
        'AQAFCEdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyOYMO0iFs4aMUVosQrrL+aWspebSXbUiMaf5/Vser1b0OnC1i7fbauPEwr4QPwO60eHE6R2A3RGXr8HuhWwwwbgAAAAAAAAAAAAAAAAA' +
        'AAAAAAAAAAAAAAAAAAAAAAAAA9LBeJnW7+BRnPyXA+KjPgyVxNJPg4ZjZj7vDCLaxcn6cN8HIDWf0F04DfWvktjd8c9zUrzgeo+yKgZUYC424xwan1RcZLFxRIYzJTD1K8X9Y2u4Im6H9ROPb2YoAAAAABt32' +
        '4ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKm2aEncf4Mlb+sGgWJlGolxMb+4adawnHuBSBv1aK+CtQMDAgABZQMAAABHaauXIEuoP7DK7hf3ho8eB05SFYGg2J2UN52qZbcXsgkAAAAAAAAAU29tZSBTZWVk8B0' +
        'fAAAAAAClAAAAAAAAAAbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCpBwQBBAUGAQEHBAIEAQAKDBAnAAAAAAAACg==';

      AllocateAndTransferWithSeedMessage =
        'AwIECUdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyxlZoHQB4RdUzPilsIbwW5CqatIYqbsEwlDlAxlbUberN+w3TZpSpkz6ceiNiFJ1YljgbSt+oGaN4XwsDKrjvO9eJ2GvItXyYvkkNtswujQh/3uFPx4eYNYHvm' +
        'FKNj2KF6Nz9cBhJOumlXLZpUvE8AzAtBfGMn1dZQnsmstBxblEGp9UXGSxcUSGMyUw9SvF/WNruCJuh/UTj29mKAAAAAAbd9uHXZaGT2cvhRs7' +
        'reawctIXtX1s3kTqM9YV+/wCpAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFSlNQ+F3IgtYUpVZyeIopbd8eq6vQpgZ4iEky9O72oIgZj6RKWuBs9/ZF9SblFNX1Nfndq/bZbd1zKevX07NqBgYCAwVDAAJHaauXIEuoP7DK7hf3ho8eB05SFYGg2J2UN52qZbcXsgFHaauXIEuoP7DK7hf3ho8eB05SFYGg2J2UN52qZbcXsgc' +
        'CAQRdCQAAAOjc/XAYSTrppVy2aVLxPAMwLQXxjJ9XWUJ7JrLQcW5RCQAAAAAAAABTb21lIFNlZWSlAAAAAAAAAP4AAajK+Dt7AHzpNyQpMLfMDxb3r2T1UUbVQedlcfEvBwMEAQE9CwAAAKhhAAAAAA' +
        'AACQAAAAAAAABTb21lIFNlZWRHaauXIEuoP7DK7hf3ho8eB05SFYGg2J2UN52qZbcXsgYEAgMABQEBBgMDAgAJB0BCDwAAAAAACAECEkhlbGxvIGZyb20gU29sLk5ldA==';

      AssignWithSeedAndWithdrawNonceMessage =
        'AgEFCkdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyzfsN02aUqZM+nHojYhSdWJY4G0rfqBmjeF8LAyq47zvXidhryLV8mL5JDbbMLo0If97hT8eHmDWB75hSjY9ihcZWaB0AeEXVMz4pbCG8FuQqmrSGKm7BMJQ5QMZW1G3q6Nz' +
        '9cBhJOumlXLZpUvE8AzAtBfGMn1dZQnsmstBxblEGp9UXGSxcUSGMyUw9SvF/WNruCJuh/UTj29mKAAAAAAbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCpAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGp9UXGSxWjuCKhF' +
        '9z0peIzwNcMUWyGrNE2AYuqUAAAAVKU1D4XciC1hSlVnJ4iilt3x6rq9CmBniISTL07vagtJ8Jx8NOgvPxbiEudqErtkdKNjEMCpOGKmW34JXG2P8GBgICBUMAAkdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyAUdpq5cgS6g/sMruF/eGj' +
        'x4HTlIVgaDYnZQ3napltxeyBwIDBFUKAAAA6Nz9cBhJOumlXLZpUvE8AzAtBfGMn1dZQnsmstBxblEJAAAAAAAAAFNvbWUgU2VlZP4AAajK+Dt7AHzpNyQpMLfMDxb3r2T1UUbVQedlcfEvBwUEAwgFAAwFAAAAqGEAAAAAAAAGBAECAAUBAQYDAgEACQdAQg8AAAAAAAkBARJIZWxsbyBmcm9tIFNvbC5OZXQ=';

      CreateNonceAccountMessage =
        'AgADBUdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxey3/TlOFbzAEpWOjiOEYJxkz0BiH7zFuKtbErUaFHHeLQA' +
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAan1RcZLFaO4IqEX3PSl4jPA1wxRbIas0TYBi6pQAAABqfVFxk' +
        'sXFEhjMlMPUrxf1ja7gibof1E49vZigAAAACHEetpR5UtsSacYYjH7rp2SZreGmXDVinNPeuZO1XQ8AICAgABNAAAAAA' +
        'AFxYAAAAAAFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAwEDBCQGAAAAR2mrlyBLqD+wyu4' +
        'X94aPHgdOUhWBoNidlDedqmW3F7I=';

      AuthorizeNonceAccountMessage =
        'AQABA0dpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxey3/TlOFbzAEpWOjiOEYJxkz0BiH7zFuKtbErUaFHHeLQA' +
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAkF38bO8K2XOUFDq7VOkCaRObsKUZyPb587Rcoo4eivAQICAQAkB' +
        'wAAACqCAIOtweetcVDQTjbgtE+ULaVRy1/RIR5APIhz/3J6';

      InitializeMessage =
        'AgAHC1MuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft3/FflD5yxhXv/GyRPQxWneSI1' +
        '9VP2k43gUpVYG2jNHwarv91zFFZ0BDXh2dnixS0rka8rnVm8/lwluHEzfmVwaq9yV5EkRlspI5d' +
        'TBei2pTw72+yOOEUXqFwgg1djn1hXAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
        'AAAAAD0E4aXqh2tQhGa5IVDemLCaLk5I4fWxHtDzbxweno50QGqkt1zAcrZOVxGCNL6Xm7' +
        'NI3/Bm+44+nxDHxEdV6rYjoSyYQV+btxvbXHxDsERTxTz2CLMUCdl3qxnNxEiIzEl6yl4BybR' +
        'MuKQsQucwG8zcPF4h2aVMSq1AidCfnxnLgbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+' +
        '/wCpBqU6rja/SG+12TgmTuZF10tgFuD0euuz7BZDi/e/++Hmyh7pP4homUV4nZbFzDiNooTfV0' +
        'TICDNPFy0DXREIwgIEAgABNAAAAADAADAAAAAAAEQBAAAAAAAABqU6rja/SG+12TgmT' +
        'uZF10tgFuD0euuz7BZDi/e/++EKCAEFBgcCCAMJYwD9GQAAAAAAAAAQJwAAAAAAAAUAA' +
        'AAAAAAAECcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFAAAAAAAAABkAAAAAAAAAAAAA' +
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==';

      SwapMessage =
        'AQAEC1MuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft37QqyFDtQcH7hIYXKOEvkCQa+' +
        'SmTK5A6OGMeeZooUoakBqpLdcwHK2TlcRgjS+l5uzSN/wZvuOPp8Qx8RHVeq2I6EsmEFfm7cb' +
        '21x8Q7BEU8U89gizFAnZd6sZzcRIiMxwQavoWObAlxFe84OJSfFUsLJIhR4Q2+v+4N9Vt58Vla' +
        'rv91zFFZ0BDXh2dnixS0rka8rnVm8/lwluHEzfmVwaiXrKXgHJtEy4pCxC5zAbzNw8XiHZpUxKr' +
        'UCJ0J+fGcu/FflD5yxhXv/GyRPQxWneSI19VP2k43gUpVYG2jNHwb0E4aXqh2tQhGa5IVDemL' +
        'CaLk5I4fWxHtDzbxweno50Qbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCpBqU6rja/SG' +
        '+12TgmTuZF10tgFuD0euuz7BZDi/e/++H0144NBdw24rNWa3osyQqbSeyvVJGFXla9Rpj5nnnRRQ' +
        'EKCgcIAAECAwQFBgkRAQDKmjsAAAAAIKEHAAAAAAA=';

      DepositAllTokenTypesMessage =
        'AQAEC1MuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft37QqyFDtQcH7hIYXKOEvkCQa+S' +
        'mTK5A6OGMeeZooUoanBBq+hY5sCXEV7zg4lJ8VSwskiFHhDb6/7g31W3nxWVgGqkt1zAcrZOV' +
        'xGCNL6Xm7NI3/Bm+44+nxDHxEdV6rYjoSyYQV+btxvbXHxDsERTxTz2CLMUCdl3qxnNxEiIzGr' +
        'v91zFFZ0BDXh2dnixS0rka8rnVm8/lwluHEzfmVwaq9yV5EkRlspI5dTBei2pTw72+yOOEUXqFwg' +
        'g1djn1hX/FflD5yxhXv/GyRPQxWneSI19VP2k43gUpVYG2jNHwb0E4aXqh2tQhGa5IVDemLCaLk' +
        '5I4fWxHtDzbxweno50Qbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCpBqU6rja/SG+12' +
        'TgmTuZF10tgFuD0euuz7BZDi/e/++G/iXGArXvtQXqAznGhXSmATofHCuoBlpHxgPk4SfhBjwEKCg' +
        'cIAAECAwQFBgkZAkBCDwAAAAAAAOh2SBcAAAAA6HZIFwAAAA==';

      WithdrawAllTokenTypesMessage =
        'AQAEDFMuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft3q7/dcxRWdAQ14dnZ4sUtK5GvK' +
        '51ZvP5cJbhxM35lcGqvcleRJEZbKSOXUwXotqU8O9vsjjhFF6hcIINXY59YVwGqkt1zAcrZOVxGC' +
        'NL6Xm7NI3/Bm+44+nxDHxEdV6rYjoSyYQV+btxvbXHxDsERTxTz2CLMUCdl3qxnNxEiIzHtCrI' +
        'UO1BwfuEhhco4S+QJBr5KZMrkDo4Yx55mihShqcEGr6FjmwJcRXvODiUnxVLCySIUeENvr/uD' +
        'fVbefFZWJespeAcm0TLikLELnMBvM3DxeIdmlTEqtQInQn58Zy78V+UPnLGFe/8bJE9DFad5Ij' +
        'X1U/aTjeBSlVgbaM0fBvQThpeqHa1CEZrkhUN6YsJouTkjh9bEe0PNvHB6ejnRBt324ddloZPZy+' +
        'FGzut5rBy0he1fWzeROoz1hX7/AKkGpTquNr9Ib7XZOCZO5kXXS2AW4PR667PsFkOL97/74RgZ' +
        'qeIKqmWN9s3Opx7A0mQO3EPmMmA+8ndUoI0JQ3gfAQsLCAkAAQIDBAUGBwoZA0BCDwAA' +
        'AAAA6AMAAAAAAADoAwAAAAAAAA==';

      DepositSingleTokenTypeExactAmountInMessage =
        'AQAEClMuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft37QqyFDtQcH7hIYXKOEvkCQa+' +
        'SmTK5A6OGMeeZooUoakBqpLdcwHK2TlcRgjS+l5uzSN/wZvuOPp8Qx8RHVeq2I6EsmEFfm7c' +
        'b21x8Q7BEU8U89gizFAnZd6sZzcRIiMxq7/dcxRWdAQ14dnZ4sUtK5GvK51ZvP5cJbhxM35lc' +
        'GqvcleRJEZbKSOXUwXotqU8O9vsjjhFF6hcIINXY59YV/xX5Q+csYV7/xskT0MVp3kiNfVT9p' +
        'ON4FKVWBtozR8G9BOGl6odrUIRmuSFQ3piwmi5OSOH1sR7Q828cHp6OdEG3fbh12Whk9nL4' +
        'UbO63msHLSF7V9bN5E6jPWFfv8AqQalOq42v0hvtdk4Jk7mRddLYBbg9Hrrs+wWQ4v3v/vhzr' +
        'NmDrCfcB0Cg6zcl3Vo7qSZvl3ypatPmPfURasFfUABCQkGBwABAgMEBQgRBADKmjsAAAAA6A' +
        'MAAAAAAAA=';

      WithdrawSingleTokenTypeExactAmountOutMessage =
        'AQAEC1MuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft3q7/dcxRWdAQ14dnZ4sUtK5Gv' +
        'K51ZvP5cJbhxM35lcGqvcleRJEZbKSOXUwXotqU8O9vsjjhFF6hcIINXY59YVwGqkt1zAcrZOV' +
        'xGCNL6Xm7NI3/Bm+44+nxDHxEdV6rYjoSyYQV+btxvbXHxDsERTxTz2CLMUCdl3qxnNxEiIz' +
        'HtCrIUO1BwfuEhhco4S+QJBr5KZMrkDo4Yx55mihShqSXrKXgHJtEy4pCxC5zAbzNw8XiHZp' +
        'UxKrUCJ0J+fGcu/FflD5yxhXv/GyRPQxWneSI19VP2k43gUpVYG2jNHwb0E4aXqh2tQhGa5I' +
        'VDemLCaLk5I4fWxHtDzbxweno50Qbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCpBq' +
        'U6rja/SG+12TgmTuZF10tgFuD0euuz7BZDi/e/++G6sYz49vuFr7rLN/dMfUEvpaHxP6DxaNZa' +
        'SUp0zrIUswEKCgcIAAECAwQFBgkRBUBCDwAAAAAAoIYBAAAAAAA=';

  published
    // registration tests
    procedure InstructionDecoderRegisterTest;
    procedure InstructionDecoderRegisterNullTest;

    // decode from base64 message tests
    procedure DecodeInstructionsFromMessageTest;
    procedure DecodeInstructionsFromTransactionMetaTest;
    procedure DecodeInstructionsFromTransactionUnknownInstructionTest;
    procedure DecodeInstructionsFromTransactionUnknownInnerInstructionTest;
    procedure DecodeUnknownInstructionFromMessageTest;

    procedure DecodeSharedMemoryProgramTest;

    procedure DecodeDurableNonceMessageTest;

    procedure DecodeCreateAccountWithSeedTest;
    procedure DecodeAllocateAndTransferWithSeedTest;
    procedure DecodeAssignWithSeedAndWithdrawNonceTest;

    procedure DecodeCreateNonceAccountTest;
    procedure DecodeAuthorizeNonceAccountTest;

    procedure InitializeDecodeTokenSwapProgramTest;
    procedure SwapDecodeTokenSwapProgramTest;
    procedure DepositAllTokenTypesDecodeTokenSwapProgramTest;
    procedure WithdrawAllTokenTypesDecodeTokenSwapProgramTest;
    procedure DepositSingleTokenTypeExactAmountInDecodeTokenSwapProgramTest;
    procedure WithdrawSingleTokenTypeExactAmountOutDecodeTokenSwapProgramTest;
  end;

implementation

{ TInstructionDecoderTests }

procedure TInstructionDecoderTests.InstructionDecoderRegisterTest;
var
  LRes : IDecodedInstruction;
  LPubKeyOne, LPubKeyTwo: IPublicKey;
begin
  // register a dummy decoder for a dummy program id
  LPubKeyOne := TPublicKey.Create('11111111111111111111111111111112');
  TInstructionDecoder.Register(
    LPubKeyOne,
    function (const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction
    begin
      Result := TDecodedInstruction.Create;
    end
  );

  LPubKeyTwo := TPublicKey.Create('11111111111111111111111111111112');
  LRes := TInstructionDecoder.Decode(
            LPubKeyTwo,
            nil,
            nil,
            nil
          );
  AssertTrue(LRes <> nil, 'Decode should return a decoded instruction');
end;

procedure TInstructionDecoderTests.InstructionDecoderRegisterNullTest;
var
  LRes : IDecodedInstruction;
  LPubKeyOne, LPubKeyTwo: IPublicKey;
begin
  LPubKeyOne := TPublicKey.Create('11111111111111111111111111111122');
  TInstructionDecoder.Register(
    LPubKeyOne,
    function (const AData: TBytes; const AKeys: TArray<IPublicKey>; const AIdx: TBytes): IDecodedInstruction
    begin
      Result := TDecodedInstruction.Create;
    end
  );

  LPubKeyTwo := TPublicKey.Create('11111111111111111111111111111123');
  LRes := TInstructionDecoder.Decode(
            LPubKeyTwo,
            nil,
            nil,
            nil
          );
  AssertTrue(LRes = nil, 'Decode should return nil for unregistered program id');
end;

procedure TInstructionDecoderTests.DecodeInstructionsFromMessageTest;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  LMsg     := TMessage.Deserialize(Base64Message);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    AssertEquals(2, LDecoded.Count, 'Count');

    // I0 � System: Create Account
    AssertEquals('Create Account',  LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('System Program',  LDecoded[0].ProgramName,     'I0 program');
    AssertEquals('11111111111111111111111111111111', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Owner Account', LVal), 'I0 missing "Owner Account"');
    AssertEquals('7y62LXLwANaN9g3KJPxQFYwMxSdZraw5PkqwtqY9zLDF', LVal.AsType<IPublicKey>.Key, 'I0 Owner Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('New Account', LVal), 'I0 missing "New Account"');
    AssertEquals('FWUPMzrLbAEuH83cf1QphoFdyUdhenDF5oHftwd9Vjyr', LVal.AsType<IPublicKey>.Key, 'I0 New Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('Amount', LVal), 'I0 missing "Amount"');
    AssertEquals(2039280, LVal.AsType<UInt64>, 'I0 Amount');

    AssertTrue(LDecoded[0].Values.TryGetValue('Space', LVal), 'I0 missing "Space"');
    AssertEquals(165, LVal.AsType<UInt64>, 'I0 Space');

    // I1 � Token: Initialize Account
    AssertEquals('Initialize Account', LDecoded[1].InstructionName, 'I1 name');
    AssertEquals('Token Program',      LDecoded[1].ProgramName,     'I1 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[1].PublicKey.Key, 'I1 program id');
    AssertEquals(0, LDecoded[1].InnerInstructions.Count, 'I1 inner count');

    AssertTrue(LDecoded[1].Values.TryGetValue('Account', LVal), 'I1 missing "Account"');
    AssertEquals('FWUPMzrLbAEuH83cf1QphoFdyUdhenDF5oHftwd9Vjyr', LVal.AsType<IPublicKey>.Key, 'I1 Account');

    AssertTrue(LDecoded[1].Values.TryGetValue('Authority', LVal), 'I1 missing "Authority"');
    AssertEquals('7y62LXLwANaN9g3KJPxQFYwMxSdZraw5PkqwtqY9zLDF', LVal.AsType<IPublicKey>.Key, 'I1 Authority');

    AssertTrue(LDecoded[1].Values.TryGetValue('Mint', LVal), 'I1 missing "Mint"');
    AssertEquals('AN5M7KvEFiZFxgEUWFdZUdR5i4b96HjXawADpqjxjXCL', LVal.AsType<IPublicKey>.Key, 'I1 Mint');
  finally
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.DecodeInstructionsFromTransactionMetaTest;
var
  LJson    : string;
  LTxMeta  : TTransactionMetaInfo;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  // arrange
  LJson   := TTestUtils.ReadAllText(
               TTestUtils.CombineAll([FResDir, 'AssociatedTokenAccount', 'TestDecodeInstructionFromBlockTransactionMetaInfo.json'])
             );
  LTxMeta := TTestUtils.Deserialize<TTransactionMetaInfo>(LJson);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LTxMeta);
  try
    // assert
    AssertEquals(3, LDecoded.Count, 'Decoded instruction count');

    // I0 � Associated Token Account Program: Create Associated Token Account
    AssertEquals('Create Associated Token Account', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('Associated Token Account Program', LDecoded[0].ProgramName, 'I0 program');
    AssertEquals('ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(4, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Payer', LVal), 'I0 missing "Payer"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I0 Payer');

    AssertTrue(LDecoded[0].Values.TryGetValue('Associated Token Account Address', LVal), 'I0 missing "Associated Token Account Address"');
    AssertEquals('BrvPSQpe6rYdvsS4idWPSKdUzyF8v3ZySVYYTuyCJnH5', LVal.AsType<IPublicKey>.Key, 'I0 Associated');

    AssertTrue(LDecoded[0].Values.TryGetValue('Owner', LVal), 'I0 missing "Owner"');
    AssertEquals('65EoWs57dkMEWbK4TJkPDM76rnbumq7r3fiZJnxggj2G', LVal.AsType<IPublicKey>.Key, 'I0 Owner');

    AssertTrue(LDecoded[0].Values.TryGetValue('Mint', LVal), 'I0 missing "Mint"');
    AssertEquals('4NtWFCwJDebDw16pEPh9JJo9XkuufK1tvY8A2MmkrsRP', LVal.AsType<IPublicKey>.Key, 'I0 Mint');

    // I1 � Token Program: Transfer
    AssertEquals('Transfer', LDecoded[1].InstructionName, 'I1 name');
    AssertEquals('Token Program', LDecoded[1].ProgramName, 'I1 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[1].PublicKey.Key, 'I1 program id');
    AssertEquals(0, LDecoded[1].InnerInstructions.Count, 'I1 inner count');

    AssertTrue(LDecoded[1].Values.TryGetValue('Source', LVal), 'I1 missing "Source"');
    AssertEquals('DEy4VaFFqTn6MweESovsbA5mUDMD2a99qnT8YMKSrCF3', LVal.AsType<IPublicKey>.Key, 'I1 Source');

    AssertTrue(LDecoded[1].Values.TryGetValue('Destination', LVal), 'I1 missing "Destination"');
    AssertEquals('BrvPSQpe6rYdvsS4idWPSKdUzyF8v3ZySVYYTuyCJnH5', LVal.AsType<IPublicKey>.Key, 'I1 Destination');

    AssertTrue(LDecoded[1].Values.TryGetValue('Authority', LVal), 'I1 missing "Authority"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I1 Authority');

    AssertTrue(LDecoded[1].Values.TryGetValue('Amount', LVal), 'I1 missing "Amount"');
    AssertEquals(25000, LVal.AsType<UInt64>, 'I1 Amount');

    // I2 � Memo Program: New Memo
    AssertEquals('New Memo', LDecoded[2].InstructionName, 'I2 name');
    AssertEquals('Memo Program', LDecoded[2].ProgramName, 'I2 program');
    AssertEquals('Memo1UhkJRfHyvLMcVucJwxXeuD728EqVDDwQDxFMNo', LDecoded[2].PublicKey.Key, 'I2 program id');
    AssertEquals(0, LDecoded[2].InnerInstructions.Count, 'I2 inner count');

    AssertTrue(LDecoded[2].Values.TryGetValue('Signer', LVal), 'I2 missing "Signer"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I2 Signer');

    AssertTrue(LDecoded[2].Values.TryGetValue('Memo', LVal), 'I2 missing "Memo"');
    AssertEquals('Hello from SolLib', LVal.AsString, 'I2 Memo');
  finally
    LTxMeta.Free;
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.DecodeInstructionsFromTransactionUnknownInstructionTest;
var
  LJson    : string;
  LTxMeta  : TTransactionMetaSlotInfo;
  LDecoded : TList<IDecodedInstruction>;
begin
  // arrange
  LJson   := TTestUtils.ReadAllText(
               TTestUtils.CombineAll([FResDir, 'Unknown', 'TestDecodeFromTransactionUnknownInstruction.json'])
             );
  LTxMeta := TTestUtils.Deserialize<TTransactionMetaSlotInfo>(LJson);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LTxMeta);
  try
    // assert
    AssertEquals(4, LDecoded.Count, 'Decoded instruction count');

    AssertEquals('Unknown', LDecoded[2].InstructionName, 'I2 name');
    AssertEquals('Unknown', LDecoded[2].ProgramName, 'I2 program');
    AssertEquals('auctxRXPeJoc4817jDhf4HbjnhEcr1cCXenosMhK5R8', LDecoded[2].PublicKey.Key, 'I2 program id');
    AssertEquals(1, LDecoded[2].InnerInstructions.Count, 'I2 inner count');
  finally
    LTxMeta.Free;
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.DecodeInstructionsFromTransactionUnknownInnerInstructionTest;
var
  LJson    : string;
  LTxMeta  : TTransactionMetaSlotInfo;
  LDecoded : TList<IDecodedInstruction>;
begin
  // arrange
  LJson   := TTestUtils.ReadAllText(
               TTestUtils.CombineAll([FResDir, 'Unknown', 'TestDecodeFromTransactionUnknownInnerInstruction.json'])
             );
  LTxMeta := TTestUtils.Deserialize<TTransactionMetaSlotInfo>(LJson);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LTxMeta);
  try
    // assert
    AssertEquals(2, LDecoded.Count, 'Decoded instruction count');

    // I0
    AssertEquals('Unknown', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('Unknown', LDecoded[0].ProgramName, 'I0 program');
    AssertEquals('675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(3, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertEquals('Unknown', LDecoded[0].InnerInstructions[0].InstructionName, 'I0.0 name');
    AssertEquals('Unknown', LDecoded[0].InnerInstructions[0].ProgramName, 'I0.0 program');
    AssertEquals('9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin',
                 LDecoded[0].InnerInstructions[0].PublicKey.Key, 'I0.0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions[0].InnerInstructions.Count, 'I0.0 inner count');

    // I1
    AssertEquals('Unknown', LDecoded[1].InstructionName, 'I1 name');
    AssertEquals('Unknown', LDecoded[1].ProgramName, 'I1 program');
    AssertEquals('675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8', LDecoded[1].PublicKey.Key, 'I1 program id');
    AssertEquals(3, LDecoded[1].InnerInstructions.Count, 'I1 inner count');

    AssertEquals('Unknown', LDecoded[1].InnerInstructions[0].InstructionName, 'I1.0 name');
    AssertEquals('Unknown', LDecoded[1].InnerInstructions[0].ProgramName, 'I1.0 program');
    AssertEquals('9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin',
                 LDecoded[1].InnerInstructions[0].PublicKey.Key, 'I1.0 program id');
    AssertEquals(0, LDecoded[1].InnerInstructions[0].InnerInstructions.Count, 'I1.0 inner count');
  finally
    LTxMeta.Free;
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.DecodeUnknownInstructionFromMessageTest;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
begin
  LMsg     := TMessage.Deserialize(UnknownInstructionMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    AssertEquals(4, LDecoded.Count, 'Count');
    AssertEquals('Unknown', LDecoded[2].InstructionName, 'I2 name');
    AssertEquals('Unknown', LDecoded[2].ProgramName,     'I2 program');
    AssertEquals('HgQBwfas29FTc2hFw2KfdtrhChYVfk5LmMraSHUTTh9L', LDecoded[2].PublicKey.Key, 'I2 program id');
    AssertEquals(0, LDecoded[2].InnerInstructions.Count, 'I2 inner count');
  finally
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.DecodeSharedMemoryProgramTest;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
  LDataExp, LDataAct: TBytes;
begin
  // arrange
  LMsg     := TMessage.Deserialize(SharedMemoryWriteMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    // assert
    AssertEquals(4, LDecoded.Count, 'Count');

    // I2 — Shared Memory: Write
    AssertEquals('Write',                  LDecoded[2].InstructionName, 'I2 name');
    AssertEquals('Shared Memory Program',  LDecoded[2].ProgramName,     'I2 program');
    AssertEquals('shmem4EWT2sPdVGvTZCzXXRAURL9G5vpPxNwSeKhHUL',
                 LDecoded[2].PublicKey.Key,                              'I2 program id');
    AssertEquals(0, LDecoded[2].InnerInstructions.Count,                 'I2 inner count');

    // values: Offset (UInt64) and Data (TBytes)
    AssertTrue(LDecoded[2].Values.TryGetValue('Offset', LVal), 'I2 missing "Offset"');
    AssertEquals(UInt64(35), LVal.AsType<UInt64>,             'I2 Offset');

    AssertTrue(LDecoded[2].Values.TryGetValue('Data', LVal),  'I2 missing "Data"');
    LDataAct := LVal.AsType<TBytes>;
    LDataExp := TBytes.Create(1, 0, 15, 25, 77);
    AssertEquals<Byte>(LDataExp, LDataAct, 'I2 Data');
  finally
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.DecodeDurableNonceMessageTest;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  LMsg     := TMessage.Deserialize(DurableNonceMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    AssertEquals(2, LDecoded.Count, 'Count');
    AssertEquals('Advance Nonce Account', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('System Program',        LDecoded[0].ProgramName,     'I0 program');
    AssertEquals('11111111111111111111111111111111', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Nonce Account', LVal), 'I0 missing "Nonce Account"');
    AssertEquals('G5EWCBwDM5GzVNwrG9LbgpTdQBD9PEAaey82ttuJJ7Qo', LVal.AsType<IPublicKey>.Key, 'I0 Nonce Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('Authority', LVal), 'I0 missing "Authority"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I0 Authority');
  finally
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.DecodeCreateAccountWithSeedTest;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  LMsg     := TMessage.Deserialize(CreateWithSeedTransferCheckedMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    AssertEquals(3, LDecoded.Count, 'Count');

    // I0 � System: Create Account With Seed
    AssertEquals('Create Account With Seed', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('System Program',           LDecoded[0].ProgramName,     'I0 program');
    AssertEquals('11111111111111111111111111111111', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('From Account', LVal), 'I0 missing "From Account"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I0 From Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('To Account', LVal), 'I0 missing "To Account"');
    AssertEquals('4sW9XdttQsm1QrfQoRW95jMX4Q5jWYjKkSPEAmkndDUY', LVal.AsType<IPublicKey>.Key, 'I0 To Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('Base Account', LVal), 'I0 missing "Base Account"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I0 Base Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('Owner', LVal), 'I0 missing "Owner"');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LVal.AsType<IPublicKey>.Key, 'I0 Owner');

    AssertTrue(LDecoded[0].Values.TryGetValue('Amount', LVal), 'I0 missing "Amount"');
    AssertEquals(2039280, LVal.AsType<UInt64>, 'I0 Amount');

    AssertTrue(LDecoded[0].Values.TryGetValue('Space', LVal), 'I0 missing "Space"');
    AssertEquals(165, LVal.AsType<UInt64>, 'I0 Space');

    AssertTrue(LDecoded[0].Values.TryGetValue('Seed', LVal), 'I0 missing "Seed"');
    AssertEquals('Some Seed', LVal.AsString, 'I0 Seed');

    // I2 � Token: Transfer Checked
    AssertEquals('Transfer Checked', LDecoded[2].InstructionName, 'I2 name');
    AssertEquals('Token Program',    LDecoded[2].ProgramName,     'I2 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[2].PublicKey.Key, 'I2 program id');

    AssertTrue(LDecoded[2].Values.TryGetValue('Source', LVal), 'I2 missing "Source"');
    AssertEquals('z2qF2eWM89sQrXP2ygrLkYkhc58182KqPVRETjv8Dch', LVal.AsType<IPublicKey>.Key, 'I2 Source');

    AssertTrue(LDecoded[2].Values.TryGetValue('Mint', LVal), 'I2 missing "Mint"');
    AssertEquals('HUATcRqk8qaNHTfRjBePt9mUZ16dDN1cbpWQDk7QFUGm', LVal.AsType<IPublicKey>.Key, 'I2 Mint');

    AssertTrue(LDecoded[2].Values.TryGetValue('Destination', LVal), 'I2 missing "Destination"');
    AssertEquals('4sW9XdttQsm1QrfQoRW95jMX4Q5jWYjKkSPEAmkndDUY', LVal.AsType<IPublicKey>.Key, 'I2 Destination');

    AssertTrue(LDecoded[2].Values.TryGetValue('Authority', LVal), 'I2 missing "Authority"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I2 Authority');

    AssertTrue(LDecoded[2].Values.TryGetValue('Amount', LVal), 'I2 missing "Amount"');
    AssertEquals(10000, LVal.AsType<UInt64>, 'I2 Amount');

    AssertTrue(LDecoded[2].Values.TryGetValue('Decimals', LVal), 'I2 missing "Decimals"');
    AssertEquals(10, LVal.AsType<Byte>, 'I2 Decimals');
  finally
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.DecodeAllocateAndTransferWithSeedTest;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  LMsg     := TMessage.Deserialize(AllocateAndTransferWithSeedMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    AssertEquals(6, LDecoded.Count, 'Count');

    // I1 � System: Allocate With Seed
    AssertEquals('Allocate With Seed', LDecoded[1].InstructionName, 'I1 name');
    AssertEquals('System Program',     LDecoded[1].ProgramName,     'I1 program');
    AssertEquals('11111111111111111111111111111111', LDecoded[1].PublicKey.Key, 'I1 program id');
    AssertEquals(0, LDecoded[1].InnerInstructions.Count, 'I1 inner count');

    AssertTrue(LDecoded[1].Values.TryGetValue('Account', LVal), 'I1 missing "Account"');
    AssertEquals('EME9GxLahsC1mjopepKMJg9RtbUu37aeLaQyHVdEd7vZ', LVal.AsType<IPublicKey>.Key, 'I1 Account');

    AssertTrue(LDecoded[1].Values.TryGetValue('Base Account', LVal), 'I1 missing "Base Account"');
    AssertEquals('Gg12mmahG97PDACxKiBta7ch2kkqDkXUzjn5oAcbPZct', LVal.AsType<IPublicKey>.Key, 'I1 Base Account');

    AssertTrue(LDecoded[1].Values.TryGetValue('Owner', LVal), 'I1 missing "Owner"');
    AssertEquals('J6WZY5nuYGJmfFtBGZaXgwZSRVuLWxNR6gd4d3XTHqTk', LVal.AsType<IPublicKey>.Key, 'I1 Owner');

    AssertTrue(LDecoded[1].Values.TryGetValue('Seed', LVal), 'I1 missing "Seed"');
    AssertEquals('Some Seed', LVal.AsString, 'I1 Seed');

    AssertTrue(LDecoded[1].Values.TryGetValue('Space', LVal), 'I1 missing "Space"');
    AssertEquals(165, LVal.AsType<UInt64>, 'I1 Space');

    // I2 � System: Transfer With Seed
    AssertEquals('Transfer With Seed', LDecoded[2].InstructionName, 'I2 name');
    AssertEquals('System Program',     LDecoded[2].ProgramName,     'I2 program');
    AssertEquals('11111111111111111111111111111111', LDecoded[2].PublicKey.Key, 'I2 program id');
    AssertEquals(0, LDecoded[2].InnerInstructions.Count, 'I2 inner count');

    AssertTrue(LDecoded[2].Values.TryGetValue('From Account', LVal), 'I2 missing "From Account"');
    AssertEquals('Gg12mmahG97PDACxKiBta7ch2kkqDkXUzjn5oAcbPZct', LVal.AsType<IPublicKey>.Key, 'I2 From Account');

    AssertTrue(LDecoded[2].Values.TryGetValue('From Base Account', LVal), 'I2 missing "From Base Account"');
    AssertEquals('EME9GxLahsC1mjopepKMJg9RtbUu37aeLaQyHVdEd7vZ', LVal.AsType<IPublicKey>.Key, 'I2 From Base Account');

    AssertTrue(LDecoded[2].Values.TryGetValue('To Account', LVal), 'I2 missing "To Account"');
    AssertEquals('EME9GxLahsC1mjopepKMJg9RtbUu37aeLaQyHVdEd7vZ', LVal.AsType<IPublicKey>.Key, 'I2 To Account');

    AssertTrue(LDecoded[2].Values.TryGetValue('From Owner', LVal), 'I2 missing "From Owner"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I2 From Owner');

    AssertTrue(LDecoded[2].Values.TryGetValue('Amount', LVal), 'I2 missing "Amount"');
    AssertEquals(25000, LVal.AsType<UInt64>, 'I2 Amount');

    AssertTrue(LDecoded[2].Values.TryGetValue('Seed', LVal), 'I2 missing "Seed"');
    AssertEquals('Some Seed', LVal.AsString, 'I2 Seed');
  finally
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.DecodeAssignWithSeedAndWithdrawNonceTest;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  LMsg     := TMessage.Deserialize(AssignWithSeedAndWithdrawNonceMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    AssertEquals(6, LDecoded.Count, 'Count');

    // I1 � System: Assign With Seed
    AssertEquals('Assign With Seed', LDecoded[1].InstructionName, 'I1 name');
    AssertEquals('System Program',   LDecoded[1].ProgramName,     'I1 program');
    AssertEquals('11111111111111111111111111111111', LDecoded[1].PublicKey.Key, 'I1 program id');
    AssertEquals(0, LDecoded[1].InnerInstructions.Count, 'I1 inner count');

    AssertTrue(LDecoded[1].Values.TryGetValue('Account', LVal), 'I1 missing "Account"');
    AssertEquals('EME9GxLahsC1mjopepKMJg9RtbUu37aeLaQyHVdEd7vZ', LVal.AsType<IPublicKey>.Key, 'I1 Account');

    AssertTrue(LDecoded[1].Values.TryGetValue('Base Account', LVal), 'I1 missing "Base Account"');
    AssertEquals('Gg12mmahG97PDACxKiBta7ch2kkqDkXUzjn5oAcbPZct', LVal.AsType<IPublicKey>.Key, 'I1 Base Account');

    AssertTrue(LDecoded[1].Values.TryGetValue('Owner', LVal), 'I1 missing "Owner"');
    AssertEquals('J6WZY5nuYGJmfFtBGZaXgwZSRVuLWxNR6gd4d3XTHqTk', LVal.AsType<IPublicKey>.Key, 'I1 Owner');

    AssertTrue(LDecoded[1].Values.TryGetValue('Seed', LVal), 'I1 missing "Seed"');
    AssertEquals('Some Seed', LVal.AsString, 'I1 Seed');

    // I2 � System: Withdraw Nonce Account
    AssertEquals('Withdraw Nonce Account', LDecoded[2].InstructionName, 'I2 name');
    AssertEquals('System Program',         LDecoded[2].ProgramName,     'I2 program');
    AssertEquals('11111111111111111111111111111111', LDecoded[2].PublicKey.Key, 'I2 program id');
    AssertEquals(0, LDecoded[2].InnerInstructions.Count, 'I2 inner count');

    AssertTrue(LDecoded[2].Values.TryGetValue('Nonce Account', LVal), 'I2 missing "Nonce Account"');
    AssertEquals('Gg12mmahG97PDACxKiBta7ch2kkqDkXUzjn5oAcbPZct', LVal.AsType<IPublicKey>.Key, 'I2 Nonce Account');

    AssertTrue(LDecoded[2].Values.TryGetValue('To Account', LVal), 'I2 missing "To Account"');
    AssertEquals('EME9GxLahsC1mjopepKMJg9RtbUu37aeLaQyHVdEd7vZ', LVal.AsType<IPublicKey>.Key, 'I2 To Account');

    AssertTrue(LDecoded[2].Values.TryGetValue('Authority', LVal), 'I2 missing "Authority"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I2 Authority');

    AssertTrue(LDecoded[2].Values.TryGetValue('Amount', LVal), 'I2 missing "Amount"');
    AssertEquals(25000, LVal.AsType<UInt64>, 'I2 Amount');
  finally
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.DecodeCreateNonceAccountTest;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  LMsg     := TMessage.Deserialize(CreateNonceAccountMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    AssertEquals(2, LDecoded.Count, 'Count');

    AssertEquals('Initialize Nonce Account', LDecoded[1].InstructionName, 'I1 name');
    AssertEquals('System Program',           LDecoded[1].ProgramName,     'I1 program');
    AssertEquals('11111111111111111111111111111111', LDecoded[1].PublicKey.Key, 'I1 program id');
    AssertEquals(0, LDecoded[1].InnerInstructions.Count, 'I1 inner count');

    AssertTrue(LDecoded[1].Values.TryGetValue('Nonce Account', LVal), 'I1 missing "Nonce Account"');
    AssertEquals('G5EWCBwDM5GzVNwrG9LbgpTdQBD9PEAaey82ttuJJ7Qo', LVal.AsType<IPublicKey>.Key, 'I1 Nonce Account');

    AssertTrue(LDecoded[1].Values.TryGetValue('Authority', LVal), 'I1 missing "Authority"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I1 Authority');
  finally
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.DecodeAuthorizeNonceAccountTest;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  LMsg     := TMessage.Deserialize(AuthorizeNonceAccountMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    AssertEquals(1, LDecoded.Count, 'Count');

    AssertEquals('Authorize Nonce Account', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('System Program',          LDecoded[0].ProgramName,     'I0 program');
    AssertEquals('11111111111111111111111111111111', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Nonce Account', LVal), 'I0 missing "Nonce Account"');
    AssertEquals('G5EWCBwDM5GzVNwrG9LbgpTdQBD9PEAaey82ttuJJ7Qo', LVal.AsType<IPublicKey>.Key, 'I0 Nonce Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('Current Authority', LVal), 'I0 missing "Current Authority"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I0 Current Authority');

    AssertTrue(LDecoded[0].Values.TryGetValue('New Authority', LVal), 'I0 missing "New Authority"');
    AssertEquals('3rw6fodqaBQHQZgMuFzbkfz7KNd1H999PphPMJwbqV53', LVal.AsType<IPublicKey>.Key, 'I0 New Authority');
  finally
    LDecoded.Free;
  end;
end;


procedure TInstructionDecoderTests.InitializeDecodeTokenSwapProgramTest;
var
  LMsg: IMessage;
  LDecoded: TList<IDecodedInstruction>;
  LVal: TValue;
  D: IDecodedInstruction;
begin
  LMsg     := TMessage.Deserialize(InitializeMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    // [0] is System CreateAccount, [1] is TokenSwap Initialize.
    D := LDecoded[1];
    AssertEquals('Initialize Swap', D.InstructionName, 'name');
    AssertEquals('Token Swap Program', D.ProgramName, 'program');

    AssertTrue(D.Values.TryGetValue('Token Swap Account', LVal), 'Missing "Token Swap Account"');
    AssertEquals('Hz3UWwAR4z7TZmzMW2TFjjzDtxEveiZZbJ4sg1LEuvKo', LVal.AsType<IPublicKey>.Key, 'Token Swap Account');

    AssertTrue(D.Values.TryGetValue('Swap Authority', LVal), 'Missing "Swap Authority"');
    AssertEquals('HRmkKfXbHcvNhWHw47zqoexKiLHmowR8o7hdwwWdaHoW', LVal.AsType<IPublicKey>.Key, 'Swap Authority');

    AssertTrue(D.Values.TryGetValue('Token A Account', LVal), 'Missing "Token A Account"');
    AssertEquals('7WGJswQpwuNePUiEFBqCMKnGcpkNoX7fFeAdM16o1wV', LVal.AsType<IPublicKey>.Key, 'Token A Account');

    AssertTrue(D.Values.TryGetValue('Token B Account', LVal), 'Missing "Token B Account"');
    AssertEquals('AbLFYgniLdGWikGJX3dT4iTWoX1FbFBwu2sjGDQN7nfa', LVal.AsType<IPublicKey>.Key, 'Token B Account');

    AssertTrue(D.Values.TryGetValue('Pool Token Mint', LVal), 'Missing "Pool Token Mint"');
    AssertEquals('CZSQMnD4jTvRfEuApDAmjWvz1AWpFpXqoePPXwZpmk1F', LVal.AsType<IPublicKey>.Key, 'Pool Token Mint');

    AssertTrue(D.Values.TryGetValue('Pool Token Fee Account', LVal), 'Missing "Pool Token Fee Account"');
    AssertEquals('3Z24fqykBPn1wNSXGz7SA5MXqGGk3DPSDpmxQoERMHrM', LVal.AsType<IPublicKey>.Key, 'Pool Token Fee Account');

    AssertTrue(D.Values.TryGetValue('Pool Token Account', LVal), 'Missing "Pool Token Account"');
    AssertEquals('CosUN9gxk8M6gdSDHYvaKKKCbX2VL73z1mJ66tYFsnSA', LVal.AsType<IPublicKey>.Key, 'Pool Token Account');

    AssertTrue(D.Values.TryGetValue('Token Program ID', LVal), 'Missing "Token Program ID"');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LVal.AsType<IPublicKey>.Key, 'Token Program ID');

    AssertTrue(D.Values.TryGetValue('Nonce', LVal), 'Missing "Nonce"');
    AssertEquals(Byte(253), LVal.AsType<Byte>, 'Nonce');

    AssertTrue(D.Values.TryGetValue('Trade Fee Numerator', LVal), 'Missing "Trade Fee Numerator"');
    AssertEquals(UInt64(25), LVal.AsType<UInt64>, 'Trade Fee Numerator');

    AssertTrue(D.Values.TryGetValue('Trade Fee Denominator', LVal), 'Missing "Trade Fee Denominator"');
    AssertEquals(UInt64(10000), LVal.AsType<UInt64>, 'Trade Fee Denominator');

    AssertTrue(D.Values.TryGetValue('Owner Trade Fee Numerator', LVal), 'Missing "Owner Trade Fee Numerator"');
    AssertEquals(UInt64(5), LVal.AsType<UInt64>, 'Owner Trade Fee Numerator');

    AssertTrue(D.Values.TryGetValue('Owner Trade Fee Denominator', LVal), 'Missing "Owner Trade Fee Denominator"');
    AssertEquals(UInt64(10000), LVal.AsType<UInt64>, 'Owner Trade Fee Denominator');

    AssertTrue(D.Values.TryGetValue('Owner Withraw Fee Numerator', LVal), 'Missing "Owner Withraw Fee Numerator"');
    AssertEquals(UInt64(0), LVal.AsType<UInt64>, 'Owner Withraw Fee Numerator');

    AssertTrue(D.Values.TryGetValue('Owner Withraw Fee Denominator', LVal), 'Missing "Owner Withraw Fee Denominator"');
    AssertEquals(UInt64(0), LVal.AsType<UInt64>, 'Owner Withraw Fee Denominator');

    AssertTrue(D.Values.TryGetValue('Host Fee Numerator', LVal), 'Missing "Host Fee Numerator"');
    AssertEquals(UInt64(20), LVal.AsType<UInt64>, 'Host Fee Numerator');

    AssertTrue(D.Values.TryGetValue('Host Fee Denominator', LVal), 'Missing "Host Fee Denominator"');
    AssertEquals(UInt64(100), LVal.AsType<UInt64>, 'Host Fee Denominator');

    AssertTrue(D.Values.TryGetValue('Curve Type', LVal), 'Missing "Curve Type"');
    AssertEquals(Byte(0), LVal.AsType<Byte>, 'Curve Type should be (TCurveType.ConstantProduct = 0)');
  finally
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.SwapDecodeTokenSwapProgramTest;
var
  LMsg    : IMessage;
  LDecoded: TList<IDecodedInstruction>;
  D       : IDecodedInstruction;
  LVal    : TValue;
begin
  LMsg     := TMessage.Deserialize(SwapMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    D := LDecoded[0];

    AssertEquals('Swap', D.InstructionName, 'name');

    AssertTrue(D.Values.TryGetValue('Token Swap Account', LVal), 'Missing "Token Swap Account"');
    AssertEquals('Hz3UWwAR4z7TZmzMW2TFjjzDtxEveiZZbJ4sg1LEuvKo', LVal.AsType<IPublicKey>.Key, 'Token Swap Account');

    AssertTrue(D.Values.TryGetValue('Swap Authority', LVal), 'Missing "Swap Authority"');
    AssertEquals('HRmkKfXbHcvNhWHw47zqoexKiLHmowR8o7hdwwWdaHoW', LVal.AsType<IPublicKey>.Key, 'Swap Authority');

    AssertTrue(D.Values.TryGetValue('User Transfer Authority', LVal), 'Missing "User Transfer Authority"');
    AssertEquals('6bhhceZToGG9RsTe1nfNFXEMjavhj6CV55EsvearAt2z', LVal.AsType<IPublicKey>.Key, 'User Transfer Authority');

    AssertTrue(D.Values.TryGetValue('User Source Account', LVal), 'Missing "User Source Account"');
    AssertEquals('GxK5rLRGx1AnE9BZzQBP6SVenavuZqRUXbE6QTzL3jjW', LVal.AsType<IPublicKey>.Key, 'User Source Account');

    AssertTrue(D.Values.TryGetValue('Token Base Into Account', LVal), 'Missing "Token Base Into Account"');
    AssertEquals('7WGJswQpwuNePUiEFBqCMKnGcpkNoX7fFeAdM16o1wV', LVal.AsType<IPublicKey>.Key, 'Token Base Into Account');

    AssertTrue(D.Values.TryGetValue('Token Base From Account', LVal), 'Missing "Token Base From Account"');
    AssertEquals('AbLFYgniLdGWikGJX3dT4iTWoX1FbFBwu2sjGDQN7nfa', LVal.AsType<IPublicKey>.Key, 'Token Base From Account');

    AssertTrue(D.Values.TryGetValue('User Destination Account', LVal), 'Missing "User Destination Account"');
    AssertEquals('DzVbjXqE9oFMJ4dWa9PqCA2bmiARtSURpmijux3PkC45', LVal.AsType<IPublicKey>.Key, 'User Destination Account');

    AssertTrue(D.Values.TryGetValue('Pool Token Mint', LVal), 'Missing "Pool Token Mint"');
    AssertEquals('CZSQMnD4jTvRfEuApDAmjWvz1AWpFpXqoePPXwZpmk1F', LVal.AsType<IPublicKey>.Key, 'Pool Token Mint');

    AssertTrue(D.Values.TryGetValue('Fee Account', LVal), 'Missing "Fee Account"');
    AssertEquals('3Z24fqykBPn1wNSXGz7SA5MXqGGk3DPSDpmxQoERMHrM', LVal.AsType<IPublicKey>.Key, 'Fee Account');

    AssertTrue(D.Values.TryGetValue('Token Program ID', LVal), 'Missing "Token Program ID"');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LVal.AsType<IPublicKey>.Key, 'Token Program ID');

    AssertTrue(D.Values.TryGetValue('Amount In', LVal), 'Missing "Amount In"');
    AssertEquals(UInt64(1000000000), LVal.AsType<UInt64>, 'Amount In');

    AssertTrue(D.Values.TryGetValue('Amount Out', LVal), 'Missing "Amount Out"');
    AssertEquals(UInt64(500000), LVal.AsType<UInt64>, 'Amount Out');
  finally
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.DepositAllTokenTypesDecodeTokenSwapProgramTest;
var
  LMsg    : IMessage;
  LDecoded: TList<IDecodedInstruction>;
  D       : IDecodedInstruction;
  LVal    : TValue;
begin
  LMsg     := TMessage.Deserialize(DepositAllTokenTypesMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    D := LDecoded[0];

    AssertEquals('Deposit Both', D.InstructionName, 'name');

    AssertTrue(D.Values.TryGetValue('Token Swap Account', LVal), 'Missing "Token Swap Account"');
    AssertEquals('Hz3UWwAR4z7TZmzMW2TFjjzDtxEveiZZbJ4sg1LEuvKo', LVal.AsType<IPublicKey>.Key, 'Token Swap Account');

    AssertTrue(D.Values.TryGetValue('Swap Authority', LVal), 'Missing "Swap Authority"');
    AssertEquals('HRmkKfXbHcvNhWHw47zqoexKiLHmowR8o7hdwwWdaHoW', LVal.AsType<IPublicKey>.Key, 'Swap Authority');

    AssertTrue(D.Values.TryGetValue('User Transfer Authority', LVal), 'Missing "User Transfer Authority"');
    AssertEquals('6bhhceZToGG9RsTe1nfNFXEMjavhj6CV55EsvearAt2z', LVal.AsType<IPublicKey>.Key, 'User Transfer Authority');

    AssertTrue(D.Values.TryGetValue('User Token A Account', LVal), 'Missing "User Token A Account"');
    AssertEquals('GxK5rLRGx1AnE9BZzQBP6SVenavuZqRUXbE6QTzL3jjW', LVal.AsType<IPublicKey>.Key, 'User Token A Account');

    AssertTrue(D.Values.TryGetValue('User Token B Account', LVal), 'Missing "User Token B Account"');
    AssertEquals('DzVbjXqE9oFMJ4dWa9PqCA2bmiARtSURpmijux3PkC45', LVal.AsType<IPublicKey>.Key, 'User Token B Account');

    AssertTrue(D.Values.TryGetValue('Pool Token A Account', LVal), 'Missing "Pool Token A Account"');
    AssertEquals('7WGJswQpwuNePUiEFBqCMKnGcpkNoX7fFeAdM16o1wV', LVal.AsType<IPublicKey>.Key, 'Pool Token A Account');

    AssertTrue(D.Values.TryGetValue('Pool Token B Account', LVal), 'Missing "Pool Token B Account"');
    AssertEquals('AbLFYgniLdGWikGJX3dT4iTWoX1FbFBwu2sjGDQN7nfa', LVal.AsType<IPublicKey>.Key, 'Pool Token B Account');

    AssertTrue(D.Values.TryGetValue('Pool Token Mint', LVal), 'Missing "Pool Token Mint"');
    AssertEquals('CZSQMnD4jTvRfEuApDAmjWvz1AWpFpXqoePPXwZpmk1F', LVal.AsType<IPublicKey>.Key, 'Pool Token Mint');

    AssertTrue(D.Values.TryGetValue('User Pool Token Account', LVal), 'Missing "User Pool Token Account"');
    AssertEquals('CosUN9gxk8M6gdSDHYvaKKKCbX2VL73z1mJ66tYFsnSA', LVal.AsType<IPublicKey>.Key, 'User Pool Token Account');

    AssertTrue(D.Values.TryGetValue('Token Program ID', LVal), 'Missing "Token Program ID"');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LVal.AsType<IPublicKey>.Key, 'Token Program ID');

    AssertTrue(D.Values.TryGetValue('Pool Tokens', LVal), 'Missing "Pool Tokens"');
    AssertEquals(UInt64(1000000), LVal.AsType<UInt64>, 'Pool Tokens');

    AssertTrue(D.Values.TryGetValue('Max Token A', LVal), 'Missing "Max Token A"');
    AssertEquals(UInt64(100000000000), LVal.AsType<UInt64>, 'Max Token A');

    AssertTrue(D.Values.TryGetValue('Max Token B', LVal), 'Missing "Max Token B"');
    AssertEquals(UInt64(100000000000), LVal.AsType<UInt64>, 'Max Token B');
  finally
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.WithdrawAllTokenTypesDecodeTokenSwapProgramTest;
var
  LMsg    : IMessage;
  LDecoded: TList<IDecodedInstruction>;
  D       : IDecodedInstruction;
  LVal    : TValue;
begin
  LMsg     := TMessage.Deserialize(WithdrawAllTokenTypesMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    D := LDecoded[0];

    AssertEquals('Withdraw Both', D.InstructionName, 'name');

    AssertTrue(D.Values.TryGetValue('Token Swap Account', LVal), 'Missing "Token Swap Account"');
    AssertEquals('Hz3UWwAR4z7TZmzMW2TFjjzDtxEveiZZbJ4sg1LEuvKo', LVal.AsType<IPublicKey>.Key, 'Token Swap Account');

    AssertTrue(D.Values.TryGetValue('Swap Authority', LVal), 'Missing "Swap Authority"');
    AssertEquals('HRmkKfXbHcvNhWHw47zqoexKiLHmowR8o7hdwwWdaHoW', LVal.AsType<IPublicKey>.Key, 'Swap Authority');

    AssertTrue(D.Values.TryGetValue('User Transfer Authority', LVal), 'Missing "User Transfer Authority"');
    AssertEquals('6bhhceZToGG9RsTe1nfNFXEMjavhj6CV55EsvearAt2z', LVal.AsType<IPublicKey>.Key, 'User Transfer Authority');

    AssertTrue(D.Values.TryGetValue('Pool Token Account', LVal), 'Missing "Pool Token Account"');
    AssertEquals('CZSQMnD4jTvRfEuApDAmjWvz1AWpFpXqoePPXwZpmk1F', LVal.AsType<IPublicKey>.Key, 'Pool Token Account');

    AssertTrue(D.Values.TryGetValue('User Pool Token Account', LVal), 'Missing "User Pool Token Account"');
    AssertEquals('CosUN9gxk8M6gdSDHYvaKKKCbX2VL73z1mJ66tYFsnSA', LVal.AsType<IPublicKey>.Key, 'User Pool Token Account');

    AssertTrue(D.Values.TryGetValue('Pool Token A Account', LVal), 'Missing "Pool Token A Account"');
    AssertEquals('7WGJswQpwuNePUiEFBqCMKnGcpkNoX7fFeAdM16o1wV', LVal.AsType<IPublicKey>.Key, 'Pool Token A Account');

    AssertTrue(D.Values.TryGetValue('Pool Token B Account', LVal), 'Missing "Pool Token B Account"');
    AssertEquals('AbLFYgniLdGWikGJX3dT4iTWoX1FbFBwu2sjGDQN7nfa', LVal.AsType<IPublicKey>.Key, 'Pool Token B Account');

    AssertTrue(D.Values.TryGetValue('User Token A Account', LVal), 'Missing "User Token A Account"');
    AssertEquals('GxK5rLRGx1AnE9BZzQBP6SVenavuZqRUXbE6QTzL3jjW', LVal.AsType<IPublicKey>.Key, 'User Token A Account');

    AssertTrue(D.Values.TryGetValue('User Token B Account', LVal), 'Missing "User Token B Account"');
    AssertEquals('DzVbjXqE9oFMJ4dWa9PqCA2bmiARtSURpmijux3PkC45', LVal.AsType<IPublicKey>.Key, 'User Token B Account');

    AssertTrue(D.Values.TryGetValue('Fee Account', LVal), 'Missing "Fee Account"');
    AssertEquals('3Z24fqykBPn1wNSXGz7SA5MXqGGk3DPSDpmxQoERMHrM', LVal.AsType<IPublicKey>.Key, 'Fee Account');

    AssertTrue(D.Values.TryGetValue('Token Program ID', LVal), 'Missing "Token Program ID"');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LVal.AsType<IPublicKey>.Key, 'Token Program ID');

    AssertTrue(D.Values.TryGetValue('Pool Tokens', LVal), 'Missing "Pool Tokens"');
    AssertEquals(UInt64(1000000), LVal.AsType<UInt64>, 'Pool Tokens');

    AssertTrue(D.Values.TryGetValue('Min Token A', LVal), 'Missing "Min Token A"');
    AssertEquals(UInt64(1000), LVal.AsType<UInt64>, 'Min Token A');

    AssertTrue(D.Values.TryGetValue('Min Token B', LVal), 'Missing "Min Token B"');
    AssertEquals(UInt64(1000), LVal.AsType<UInt64>, 'Min Token B');
  finally
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.DepositSingleTokenTypeExactAmountInDecodeTokenSwapProgramTest;
var
  LMsg    : IMessage;
  LDecoded: TList<IDecodedInstruction>;
  D       : IDecodedInstruction;
  LVal    : TValue;
begin
  LMsg     := TMessage.Deserialize(DepositSingleTokenTypeExactAmountInMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    D := LDecoded[0];

    AssertEquals('Deposit Single', D.InstructionName, 'name');

    AssertTrue(D.Values.TryGetValue('Token Swap Account', LVal), 'Missing "Token Swap Account"');
    AssertEquals('Hz3UWwAR4z7TZmzMW2TFjjzDtxEveiZZbJ4sg1LEuvKo', LVal.AsType<IPublicKey>.Key, 'Token Swap Account');

    AssertTrue(D.Values.TryGetValue('Swap Authority', LVal), 'Missing "Swap Authority"');
    AssertEquals('HRmkKfXbHcvNhWHw47zqoexKiLHmowR8o7hdwwWdaHoW', LVal.AsType<IPublicKey>.Key, 'Swap Authority');

    AssertTrue(D.Values.TryGetValue('User Transfer Authority', LVal), 'Missing "User Transfer Authority"');
    AssertEquals('6bhhceZToGG9RsTe1nfNFXEMjavhj6CV55EsvearAt2z', LVal.AsType<IPublicKey>.Key, 'User Transfer Authority');

    AssertTrue(D.Values.TryGetValue('User Source Token Account', LVal), 'Missing "User Source Token Account"');
    AssertEquals('GxK5rLRGx1AnE9BZzQBP6SVenavuZqRUXbE6QTzL3jjW', LVal.AsType<IPublicKey>.Key, 'User Source Token Account');

    AssertTrue(D.Values.TryGetValue('Token A Swap Account', LVal), 'Missing "Token A Swap Account"');
    AssertEquals('7WGJswQpwuNePUiEFBqCMKnGcpkNoX7fFeAdM16o1wV', LVal.AsType<IPublicKey>.Key, 'Token A Swap Account');

    AssertTrue(D.Values.TryGetValue('Token B Swap Account', LVal), 'Missing "Token B Swap Account"');
    AssertEquals('AbLFYgniLdGWikGJX3dT4iTWoX1FbFBwu2sjGDQN7nfa', LVal.AsType<IPublicKey>.Key, 'Token B Swap Account');

    AssertTrue(D.Values.TryGetValue('Pool Mint Account', LVal), 'Missing "Pool Mint Account"');
    AssertEquals('CZSQMnD4jTvRfEuApDAmjWvz1AWpFpXqoePPXwZpmk1F', LVal.AsType<IPublicKey>.Key, 'Pool Mint Account');

    AssertTrue(D.Values.TryGetValue('User Pool Token Account', LVal), 'Missing "User Pool Token Account"');
    AssertEquals('CosUN9gxk8M6gdSDHYvaKKKCbX2VL73z1mJ66tYFsnSA', LVal.AsType<IPublicKey>.Key, 'User Pool Token Account');

    AssertTrue(D.Values.TryGetValue('Token Program ID', LVal), 'Missing "Token Program ID"');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LVal.AsType<IPublicKey>.Key, 'Token Program ID');

    AssertTrue(D.Values.TryGetValue('Source Token Amount', LVal), 'Missing "Source Token Amount"');
    AssertEquals(UInt64(1000000000), LVal.AsType<UInt64>, 'Source Token Amount');

    AssertTrue(D.Values.TryGetValue('Min Pool Token Amount', LVal), 'Missing "Min Pool Token Amount"');
    AssertEquals(UInt64(1000), LVal.AsType<UInt64>, 'Min Pool Token Amount');
  finally
    LDecoded.Free;
  end;
end;

procedure TInstructionDecoderTests.WithdrawSingleTokenTypeExactAmountOutDecodeTokenSwapProgramTest;
var
  LMsg    : IMessage;
  LDecoded: TList<IDecodedInstruction>;
  D       : IDecodedInstruction;
  LVal    : TValue;
begin
  LMsg     := TMessage.Deserialize(WithdrawSingleTokenTypeExactAmountOutMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    D := LDecoded[0];

    AssertEquals('Withdraw Single', D.InstructionName, 'name');

    AssertTrue(D.Values.TryGetValue('Token Swap Account', LVal), 'Missing "Token Swap Account"');
    AssertEquals('Hz3UWwAR4z7TZmzMW2TFjjzDtxEveiZZbJ4sg1LEuvKo', LVal.AsType<IPublicKey>.Key, 'Token Swap Account');

    AssertTrue(D.Values.TryGetValue('Swap Authority', LVal), 'Missing "Swap Authority"');
    AssertEquals('HRmkKfXbHcvNhWHw47zqoexKiLHmowR8o7hdwwWdaHoW', LVal.AsType<IPublicKey>.Key, 'Swap Authority');

    AssertTrue(D.Values.TryGetValue('User Transfer Authority', LVal), 'Missing "User Transfer Authority"');
    AssertEquals('6bhhceZToGG9RsTe1nfNFXEMjavhj6CV55EsvearAt2z', LVal.AsType<IPublicKey>.Key, 'User Transfer Authority');

    AssertTrue(D.Values.TryGetValue('Pool Mint Account', LVal), 'Missing "Pool Mint Account"');
    AssertEquals('CZSQMnD4jTvRfEuApDAmjWvz1AWpFpXqoePPXwZpmk1F', LVal.AsType<IPublicKey>.Key, 'Pool Mint Account');

    AssertTrue(D.Values.TryGetValue('User Pool Token Account', LVal), 'Missing "User Pool Token Account"');
    AssertEquals('CosUN9gxk8M6gdSDHYvaKKKCbX2VL73z1mJ66tYFsnSA', LVal.AsType<IPublicKey>.Key, 'User Pool Token Account');

    AssertTrue(D.Values.TryGetValue('Token A Swap Account', LVal), 'Missing "Token A Swap Account"');
    AssertEquals('7WGJswQpwuNePUiEFBqCMKnGcpkNoX7fFeAdM16o1wV', LVal.AsType<IPublicKey>.Key, 'Token A Swap Account');

    AssertTrue(D.Values.TryGetValue('Token B Swap Account', LVal), 'Missing "Token B Swap Account"');
    AssertEquals('AbLFYgniLdGWikGJX3dT4iTWoX1FbFBwu2sjGDQN7nfa', LVal.AsType<IPublicKey>.Key, 'Token B Swap Account');

    AssertTrue(D.Values.TryGetValue('User Token Account', LVal), 'Missing "User Token Account"');
    AssertEquals('GxK5rLRGx1AnE9BZzQBP6SVenavuZqRUXbE6QTzL3jjW', LVal.AsType<IPublicKey>.Key, 'User Token Account');

    AssertTrue(D.Values.TryGetValue('Fee Account', LVal), 'Missing "Fee Account"');
    AssertEquals('3Z24fqykBPn1wNSXGz7SA5MXqGGk3DPSDpmxQoERMHrM', LVal.AsType<IPublicKey>.Key, 'Fee Account');

    AssertTrue(D.Values.TryGetValue('Token Program ID', LVal), 'Missing "Token Program ID"');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LVal.AsType<IPublicKey>.Key, 'Token Program ID');

    AssertTrue(D.Values.TryGetValue('Destination Token Amount', LVal), 'Missing "Destination Token Amount"');
    AssertEquals(UInt64(1000000), LVal.AsType<UInt64>, 'Destination Token Amount');

    AssertTrue(D.Values.TryGetValue('Max Pool Token Amount', LVal), 'Missing "Max Pool Token Amount"');
    AssertEquals(UInt64(100000), LVal.AsType<UInt64>, 'Max Pool Token Amount');
  finally
    LDecoded.Free;
  end;
end;

initialization
{$IFDEF FPC}
  RegisterTest(TInstructionDecoderTests);
{$ELSE}
  RegisterTest(TInstructionDecoderTests.Suite);
{$ENDIF}

end.

