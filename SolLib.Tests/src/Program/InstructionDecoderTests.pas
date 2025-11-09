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

unit InstructionDecoderTests;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
  System.JSON.Serializers,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpJsonKit,
  SlpJsonStringEnumConverter,
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
    FSerializer: TJsonSerializer;

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

    function BuildSerializer: TJsonSerializer;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

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

    procedure DecodeDurableNonceMessageTest;

    procedure DecodeCreateAccountWithSeedTest;
    procedure DecodeAllocateAndTransferWithSeedTest;
    procedure DecodeAssignWithSeedAndWithdrawNonceTest;

    procedure DecodeCreateNonceAccountTest;
    procedure DecodeAuthorizeNonceAccountTest;
  end;

implementation

{ TInstructionDecoderTests }

function TInstructionDecoderTests.BuildSerializer: TJsonSerializer;
var
  Converters: TList<TJsonConverter>;
begin
  Converters := TList<TJsonConverter>.Create;
  try
    Converters.Add(TJsonStringEnumConverter.Create(TJsonNamingPolicy.CamelCase));
    Result := TJsonSerializerFactory.CreateSerializer(
      TEnhancedContractResolver.Create(
        TJsonMemberSerialization.Public,
        TJsonNamingPolicy.CamelCase
      ),
      Converters
    );
  finally
    Converters.Free;
  end;
end;

procedure TInstructionDecoderTests.SetUp;
begin
  inherited;
  FSerializer := BuildSerializer;
end;

procedure TInstructionDecoderTests.TearDown;
var
 I: Integer;
begin
  if Assigned(FSerializer) then
  begin
    if Assigned(FSerializer.Converters) then
    begin
      for I := 0 to FSerializer.Converters.Count - 1 do
        if Assigned(FSerializer.Converters[I]) then
          FSerializer.Converters[I].Free;
      FSerializer.Converters.Clear;
    end;
    FSerializer.Free;
  end;

  inherited;
end;

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

{ === Message-based decode tests =========================================== }

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
  LTxMeta := FSerializer.Deserialize<TTransactionMetaInfo>(LJson);

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
  LTxMeta := FSerializer.Deserialize<TTransactionMetaSlotInfo>(LJson);

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
  LTxMeta := FSerializer.Deserialize<TTransactionMetaSlotInfo>(LJson);

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

{ === System Program: Durable Nonce & Seeded ops =========================== }

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

{ === Nonce Account ops ===================================================== }

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

initialization
{$IFDEF FPC}
  RegisterTest(TInstructionDecoderTests);
{$ELSE}
  RegisterTest(TInstructionDecoderTests.Suite);
{$ENDIF}

end.

