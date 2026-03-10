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

unit TransactionTests;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpDataEncoders,
  SlpWallet,
  SlpAccount,
  SlpPublicKey,
  SlpMessageDomain,
  SlpTransactionDomain,
  SlpTransactionInstruction,
  SlpArrayUtils,
  SlpTokenProgram,
  SlpMemoProgram,
  SlpSysVars,
  SlpSystemProgram,
  SolLibTestCase;

type
  TTransactionTests = class(TSolLibTestCase)
  private
      const MnemonicWords =
              'route clerk disease box emerge airport loud waste attitude film army tray ' +
              'forward deal onion eight catalog surface unit card window walnut wealth medal';

    class function GetCompiledMessageBytes: TBytes; static;
    class function GetCompiledAndSignedBytes: TBytes; static;
    class function GetCraftTransactionBytes: TBytes; static;
    class function GetCraftTransactionTail: TBytes; static;
  published
    procedure TransactionDeserializeExceptionTest;
    procedure TransactionDeserializeArgumentNullExceptionTest;
    procedure TransactionDurableNonceDeserializeTest;
    procedure PopulateTest;
    procedure CompileMessageTest;
    procedure SignTest;
    procedure BuildTest;
    procedure AddSignatureTest;
   procedure AddInstructionsTest;
    procedure PartialSignTest;
  end;

implementation

{ === Private helpers ======================================================= }

class function TTransactionTests.GetCompiledMessageBytes: TBytes;
begin
  Result := TBytes.Create(
    1, 0, 2, 5, 71, 105, 171, 151, 32, 75, 168, 63, 176, 202, 238, 23, 247, 134, 143, 30, 7, 78, 82, 21,
    129, 160, 216, 157, 148, 55, 157, 170, 101, 183, 23, 178, 132, 220, 206, 171, 228, 52, 112, 149, 218,
    174, 194, 90, 142, 185, 112, 195, 57, 102, 90, 129, 121, 155, 30, 112, 20, 223, 14, 67, 131, 142, 36,
    162, 223, 244, 229, 56, 86, 243, 0, 74, 86, 58, 56, 142, 17, 130, 113, 147, 61, 1, 136, 126, 243, 22,
    226, 173, 108, 74, 212, 104, 81, 199, 120, 180, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 167, 213, 23, 25, 44, 86, 142, 224, 138, 132, 95, 115, 210,
    151, 136, 207, 3, 92, 49, 69, 178, 26, 179, 68, 216, 6, 46, 169, 64, 0, 0, 21, 68, 15, 82, 0, 49, 0,
    146, 241, 176, 13, 84, 249, 55, 39, 9, 212, 80, 57, 8, 193, 89, 211, 49, 162, 144, 45, 140, 117, 21, 46,
    83, 2, 3, 3, 2, 4, 0, 4, 4, 0, 0, 0, 3, 2, 0, 1, 12, 2, 0, 0, 0, 0, 202, 154, 59, 0, 0, 0, 0
  );
end;

class function TTransactionTests.GetCompiledAndSignedBytes: TBytes;
begin
  Result := TBytes.Create(
    1, 13, 18, 225, 68, 176, 254, 183, 157, 106, 29, 87, 152, 179, 104, 244, 139, 151, 193, 221, 38, 99,
    232, 152, 59, 58, 18, 54, 171, 174, 187, 41, 186, 131, 84, 185, 215, 182, 192, 38, 72, 229, 186, 195,
    119, 94, 63, 210, 160, 176, 79, 194, 101, 224, 221, 6, 127, 153, 218, 31, 223, 31, 118, 4, 6, 1, 0, 2,
    5, 71, 105, 171, 151, 32, 75, 168, 63, 176, 202, 238, 23, 247, 134, 143, 30, 7, 78, 82, 21, 129, 160,
    216, 157, 148, 55, 157, 170, 101, 183, 23, 178, 132, 220, 206, 171, 228, 52, 112, 149, 218, 174, 194,
    90, 142, 185, 112, 195, 57, 102, 90, 129, 121, 155, 30, 112, 20, 223, 14, 67, 131, 142, 36, 162, 223,
    244, 229, 56, 86, 243, 0, 74, 86, 58, 56, 142, 17, 130, 113, 147, 61, 1, 136, 126, 243, 22, 226, 173,
    108, 74, 212, 104, 81, 199, 120, 180, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 167, 213, 23, 25, 44, 86, 142, 224, 138, 132, 95, 115, 210, 151, 136,
    207, 3, 92, 49, 69, 178, 26, 179, 68, 216, 6, 46, 169, 64, 0, 0, 21, 68, 15, 82, 0, 49, 0, 146, 241,
    176, 13, 84, 249, 55, 39, 9, 212, 80, 57, 8, 193, 89, 211, 49, 162, 144, 45, 140, 117, 21, 46, 83, 2, 3,
    3, 2, 4, 0, 4, 4, 0, 0, 0, 3, 2, 0, 1, 12, 2, 0, 0, 0, 0, 202, 154, 59, 0, 0, 0, 0
  );
end;

class function TTransactionTests.GetCraftTransactionBytes: TBytes;
begin
  Result := TBytes.Create(
    3, 246, 102, 170, 66, 210, 74, 133, 0, 162, 12, 21, 81, 39, 65, 193, 31, 148, 240, 48, 83, 193, 182, 61,
    91, 89, 37, 128, 230, 33, 210, 251, 124, 90, 13, 81, 43, 253, 122, 96, 35, 222, 188, 13, 14, 19, 96, 189,
    106, 46, 35, 245, 223, 179, 85, 90, 35, 6, 115, 10, 46, 145, 246, 27, 14, 30, 93, 148, 249, 228, 30, 250,
    168, 246, 173, 207, 54, 188, 234, 103, 253, 23, 12, 201, 134, 141, 32, 155, 83, 228, 32, 155, 219, 63, 244,
    202, 1, 252, 200, 42, 5, 20, 131, 121, 72, 103, 100, 217, 221, 178, 212, 119, 249, 132, 76, 81, 31, 23, 239,
    69, 208, 5, 65, 233, 120, 245, 113, 187, 8, 237, 92, 233, 129, 13, 12, 136, 148, 196, 252, 64, 225, 163, 38,
    89, 81, 62, 160, 4, 46, 129, 79, 78, 168, 98, 147, 114, 247, 194, 1, 3, 51, 47, 179, 188, 130, 47, 6, 95, 90,
    186, 146, 242, 1, 28, 57, 10, 177, 138, 21, 246, 143, 231, 187, 100, 138, 226, 26, 236, 73, 147, 168, 22, 0,
    3, 0, 4, 7, 71, 105, 171, 151, 32, 75, 168, 63, 176, 202, 238, 23, 247, 134, 143, 30, 7, 78, 82, 21, 129, 160,
    216, 157, 148, 55, 157, 170, 101, 183, 23, 178, 205, 251, 13, 211, 102, 148, 169, 147, 62, 156, 122, 35, 98,
    20, 157, 88, 150, 56, 27, 74, 223, 168, 25, 163, 120, 95, 11, 3, 42, 184, 239, 59, 215, 137, 216, 107, 200,
    181, 124, 152, 190, 73, 13, 182, 204, 46, 141, 8, 127, 222, 225, 79, 199, 135, 152, 53, 129, 239, 152, 82,
    141, 143, 98, 133, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 5, 74, 83, 80, 248, 93, 200, 130, 214, 20, 165, 86, 114, 120, 138, 41, 109, 223, 30, 171, 171, 208, 166,
    6, 120, 136, 73, 50, 244, 238, 246, 160, 6, 167, 213, 23, 25, 44, 92, 81, 33, 140, 201, 76, 61, 74, 241, 127,
    88, 218, 238, 8, 155, 161, 253, 68, 227, 219, 217, 138, 0, 0, 0, 0, 6, 221, 246, 225, 215, 101, 161, 147, 217,
    203, 225, 70, 206, 235, 121, 172, 28, 180, 133, 237, 95, 91, 55, 145, 58, 140, 245, 133, 126, 255, 0, 169, 206,
    78, 169, 189, 0, 235, 196, 10, 163, 190, 178, 243, 194, 80, 1, 89, 248, 166, 252, 150, 61, 65, 187, 142, 133, 205,
    198, 253, 19, 241, 15, 248, 6, 3, 2, 0, 2, 52, 0, 0, 0, 0, 96, 77, 22, 0, 0, 0, 0, 0, 82, 0, 0, 0, 0, 0, 0, 0, 6,
    221, 246, 225, 215, 101, 161, 147, 217, 203, 225, 70, 206, 235, 121, 172, 28, 180, 133, 237, 95, 91, 55, 145, 58,
    140, 245, 133, 126, 255, 0, 169, 6, 2, 2, 5, 67, 0, 2, 71, 105, 171, 151, 32, 75, 168, 63, 176, 202, 238, 23, 247,
    134, 143, 30, 7, 78, 82, 21, 129, 160, 216, 157, 148, 55, 157, 170, 101, 183, 23, 178, 1, 71, 105, 171, 151, 32, 75,
    168, 63, 176, 202, 238, 23, 247, 134, 143, 30, 7, 78, 82, 21, 129, 160, 216, 157, 148, 55, 157, 170, 101, 183, 23,
    178, 3, 2, 0, 1, 52, 0, 0, 0, 0, 240, 29, 31, 0, 0, 0, 0, 0, 165, 0, 0, 0, 0, 0, 0, 0, 6, 221, 246, 225, 215, 101,
    161, 147, 217, 203, 225, 70, 206, 235, 121, 172, 28, 180, 133, 237, 95, 91, 55, 145, 58, 140, 245, 133, 126, 255, 0,
    169, 6, 4, 1, 2, 0, 5, 1, 1, 6, 3, 2, 1, 0, 9, 7, 64, 66, 15, 0, 0, 0, 0, 0, 4, 1, 1, 17, 72, 101, 108, 108, 111, 32,
    102, 114, 111, 109, 32, 83, 111, 108, 76, 105, 98
  );
end;

class function TTransactionTests.GetCraftTransactionTail: TBytes;
var
  LFull: TBytes;
begin
  LFull := GetCraftTransactionBytes;
  Result := TArrayUtils.Slice<Byte>(LFull, 193);
end;

procedure TTransactionTests.TransactionDeserializeExceptionTest;
const
  InvalidBase64Transaction =
    'AQ0S4USBAYBAAIFR2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7KE3M6r5DRwldquwlqOuXDDOWZagXmbHnAU3w5Dg44kot' +
    '/05ThW8wBKVjo4jhGCcZM9AYh+8xbirWxK1GhRx3i0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGp9UXGSxWjuCKhF9' +
    'z0peIzwNcMUWyGrNE2AYuqUAAABVED1IAMQCS8bANVPk3JwnUUDkIwVnTMaKQLYx1FS5TAgMDAgQABAQAAAADAgABDAIAAAAAypo7AAAAAA==';
begin
  AssertException(
    procedure
    var
      LTx: ITransaction;
    begin
      // should raise on invalid base64 (base64 length must be divisible by 4)
      LTx := TTransaction.Deserialize(InvalidBase64Transaction);
    end,
    Exception
  );
end;

procedure TTransactionTests.TransactionDeserializeArgumentNullExceptionTest;
begin
  AssertException(
    procedure
    var
      LTx: ITransaction;
    begin
      LTx := TTransaction.Deserialize('');
    end,
    EArgumentNilException
  );
end;

procedure TTransactionTests.TransactionDurableNonceDeserializeTest;
const
  Base64Transaction =
    'AQ0S4USw/redah1XmLNo9IuXwd0mY+iYOzoSNquuuym6g1S517bAJkjlusN3Xj/SoLBPwmXg3QZ/mdof3x92BAYBAAIFR2mrlyBL' +
    'qD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7KE3M6r5DRwldquwlqOuXDDOWZagXmbHnAU3w5Dg44kot/05ThW8wBKVjo4jhGCcZM9A' +
    'Yh+8xbirWxK1GhRx3i0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGp9UXGSxWjuCKhF9z0peIzwNcMUWyGrNE2AYuqU' +
    'AAABVED1IAMQCS8bANVPk3JwnUUDkIwVnTMaKQLYx1FS5TAgMDAgQABAQAAAADAgABDAIAAAAAypo7AAAAAA==';
var
  LTx: ITransaction;
begin
  LTx := TTransaction.Deserialize(Base64Transaction);

  AssertNotNull(LTx);

  // Fee payer & blockhash
  AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LTx.FeePayer.Key);
  AssertEquals('2S1kjspXLPs6jpNVXQfNMqZzzSrKLbGdr9Fxap5h1DLN', LTx.RecentBlockHash);

  // Signatures
  AssertEquals(1, LTx.Signatures.Count);
  AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LTx.Signatures[0].PublicKey.Key);
  AssertEquals(
    'GAJa8rLiVeTHYTcbwjLmVnxVH986Vwxz4PXDEPaZKz4BEcmv9rvMF2Sw2xLzbu8mwNHA8ZZ6Es5Thf8yQrwjLv9',
    TEncoders.Base58.EncodeData(LTx.Signatures[0].Signature)
  );

  // This is 1 because the transaction uses durable nonce.
  AssertEquals(1, LTx.Instructions.Count);
  AssertEquals('2S1kjspXLPs6jpNVXQfNMqZzzSrKLbGdr9Fxap5h1DLN', LTx.NonceInformation.Nonce);
  AssertEquals(3, LTx.NonceInformation.Instruction.Keys.Count);
  AssertEquals('11111111111111111111111111111111', TEncoders.Base58.EncodeData(LTx.NonceInformation.Instruction.ProgramId));
  AssertEquals('G5EWCBwDM5GzVNwrG9LbgpTdQBD9PEAaey82ttuJJ7Qo', LTx.NonceInformation.Instruction.Keys[0].PublicKey.Key);
  AssertTrue(LTx.NonceInformation.Instruction.Keys[0].IsWritable);
  AssertFalse(LTx.NonceInformation.Instruction.Keys[0].IsSigner);

  AssertEquals(TSysVars.RecentBlockHashesKey.Key, LTx.NonceInformation.Instruction.Keys[1].PublicKey.Key);
  AssertFalse(LTx.NonceInformation.Instruction.Keys[1].IsWritable);
  AssertFalse(LTx.NonceInformation.Instruction.Keys[1].IsSigner);

  AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LTx.NonceInformation.Instruction.Keys[2].PublicKey.Key);
  AssertTrue(LTx.NonceInformation.Instruction.Keys[2].IsWritable);
  AssertTrue(LTx.NonceInformation.Instruction.Keys[2].IsSigner);
  AssertEquals('BAAAAA==', TEncoders.Base64.EncodeData(LTx.NonceInformation.Instruction.Data));

  // Nonce-unrelated instruction
  AssertEquals(2, LTx.Instructions[0].Keys.Count);
  AssertEquals('11111111111111111111111111111111', TEncoders.Base58.EncodeData(LTx.Instructions[0].ProgramId));
  AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LTx.Instructions[0].Keys[0].PublicKey.Key);
  AssertTrue(LTx.Instructions[0].Keys[0].IsWritable);
  AssertTrue(LTx.Instructions[0].Keys[0].IsSigner);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', LTx.Instructions[0].Keys[1].PublicKey.Key);
  AssertTrue(LTx.Instructions[0].Keys[1].IsWritable);
  AssertFalse(LTx.Instructions[0].Keys[1].IsSigner);
  AssertEquals('AgAAAADKmjsAAAAA', TEncoders.Base64.EncodeData(LTx.Instructions[0].Data));
end;

procedure TTransactionTests.PopulateTest;
const
  Base64Message =
    'AwAEB0dpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyzfsN02aUqZM+nHojYhSdWJY4G0rfqBmjeF8LAyq47zvXidhry' +
    'LV8mL5JDbbMLo0If97hT8eHmDWB75hSjY9ihQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcn' +
    'iKKW3fHqur0KYGeIhJMvTu9qAGp9UXGSxcUSGMyUw9SvF/WNruCJuh/UTj29mKAAAAAAbd9uHXZaGT2cvhRs7reawctIXtX1s' +
    '3kTqM9YV+/wCpzk6pvQDrxAqjvrLzwlABWfim/JY9QbuOhc3G/RPxD/gGAwIAAjQAAAAAYE0WAAAAAABSAAAAAAAAAAbd9uHX' +
    'ZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCpBgICBUMAAkdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyAUdpq5cgS' +
    '6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyAwIAATQAAAAA8B0fAAAAAAClAAAAAAAAAAbd9uHXZaGT2cvhRs7reawctIXtX1' +
    's3kTqM9YV+/wCpBgQBAgAFAQEGAwIBAAkHQEIPAAAAAAAEAQERSGVsbG8gZnJvbSBTb2xMaWI=';
var
  LTx: ITransaction;
  LSigList: TList<TBytes>;
  LTxBytes: TBytes;
begin
  LSigList := TList<TBytes>.Create;
  try
    LSigList.Add(TEncoders.Base58.DecodeData('5vjECoK7kVSJ1MvYuZtyDAmYZxh8ZRbwyFtr4JGsUzTiaPqEbfTTMJqYsBUNLWqQnvytFxm7A2Gw32p3sFBqznzh'));
    LSigList.Add(TEncoders.Base58.DecodeData('cDJQq6WQMiX2bMpam2btyuRwCtNLRF778UsjWpQqX3DHdr8nUTog8CGwanGHDQMzpuW3iDQx1mkR6dBzNDJNLpX'));
    LSigList.Add(TEncoders.Base58.DecodeData('5kFMN7jNmPtnZfUidcCVYaDiRqFV1Wz3wA7cya8CXmAyDoMiGQqiZpUbDas6q2jmiMfizBpe6oDbqKgUvCCNn9iX'));

    LTx := TTransaction.Populate(Base64Message, LSigList.ToArray());
    LTxBytes := LTx.Serialize;
    AssertEquals(LTxBytes, GetCraftTransactionBytes, 'Populate() serialized bytes mismatch');
  finally
    LSigList.Free;
  end;
end;

procedure TTransactionTests.CompileMessageTest;
var
  LMsg: IMessage;
  LTx: ITransaction;
  LOutBytes: TBytes;
begin
  LMsg := TMessage.Deserialize(GetCompiledMessageBytes);
  LTx := TTransaction.Populate(LMsg);

  LOutBytes := LTx.CompileMessage;
  AssertEquals(LOutBytes, GetCompiledMessageBytes, 'CompileMessage mismatch');
end;

procedure TTransactionTests.SignTest;
var
  LWallet: IWallet;
  LOwner: IAccount;
  LMsg: IMessage;
  LTx: ITransaction;
  LTxBytes: TBytes;
begin
  LWallet := TWallet.Create(MnemonicWords);
  LOwner := LWallet.GetAccountByIndex(10);
  LMsg := TMessage.Deserialize(GetCompiledMessageBytes);

  LTx := TTransaction.Populate(LMsg);
  AssertTrue(LTx.Sign(LOwner), 'Sign should succeed');
  LTxBytes := LTx.Serialize;
  AssertEquals(LTxBytes, GetCompiledAndSignedBytes, 'Signed bytes mismatch');
end;

procedure TTransactionTests.BuildTest;
var
  LWallet: IWallet;
  LOwner: IAccount;
  LMsg: IMessage;
  LTx: ITransaction;
  LTxBytes: TBytes;
begin
  LWallet := TWallet.Create(MnemonicWords);
  LOwner := LWallet.GetAccountByIndex(10);
  LMsg := TMessage.Deserialize(GetCompiledMessageBytes);

  LTx := TTransaction.Populate(LMsg);
  LTxBytes := LTx.Build(LOwner);
  AssertEquals(LTxBytes, GetCompiledAndSignedBytes, 'Build bytes mismatch');
end;

procedure TTransactionTests.AddSignatureTest;
var
  LWallet: IWallet;
  LOwner: IAccount;
  LMsg: IMessage;
  LTx: ITransaction;
  LSig: TBytes;
  LTxBytes: TBytes;
begin
  LWallet := TWallet.Create(MnemonicWords);
  LOwner := LWallet.GetAccountByIndex(10);
  LMsg := TMessage.Deserialize(GetCompiledMessageBytes);

  LTx := TTransaction.Populate(LMsg);
  LSig := LOwner.Sign(LTx.CompileMessage);
  LTx.AddSignature(LOwner.PublicKey, LSig);
  LTxBytes := LTx.Serialize;
  AssertEquals(LTxBytes, GetCompiledAndSignedBytes, 'AddSignature bytes mismatch');
end;


procedure TTransactionTests.AddInstructionsTest;
var
  LWallet: IWallet;
  LOwner, LMint, LInitial: IAccount;
  LTx: ITransaction;
  LTxBytes, LExpectedTail: TBytes;
begin
  LWallet := TWallet.Create(MnemonicWords);

  LOwner := LWallet.GetAccountByIndex(10);
  LMint := LWallet.GetAccountByIndex(1002);
  LInitial := LWallet.GetAccountByIndex(1102);
  LTx := TTransaction.Create;

  LTx.FeePayer := LOwner.PublicKey;
  LTx.RecentBlockHash := 'EtLZEUfN1sSsaHRzTtrGW6N62hagTXjc5jokiWqZ9qQ3';

  LTxBytes := LTx
    .Add(TSystemProgram.CreateAccount(
      LOwner.PublicKey, LMint.PublicKey, 1461600, TTokenProgram.MintAccountDataSize, TTokenProgram.ProgramIdKey))
    .Add(TTokenProgram.InitializeMint(
      LMint.PublicKey, 2, LOwner.PublicKey, LOwner.PublicKey))
    .Add(TSystemProgram.CreateAccount(
      LOwner.PublicKey, LInitial.PublicKey, 2039280, TTokenProgram.TokenAccountDataSize, TTokenProgram.ProgramIdKey))
    .Add(TTokenProgram.InitializeAccount(
      LInitial.PublicKey, LMint.PublicKey, LOwner.PublicKey))
    .Add(TTokenProgram.MintTo(
      LMint.PublicKey, LInitial.PublicKey, 1000000, LOwner.PublicKey))
    .Add(TMemoProgram.NewMemo(LInitial.PublicKey, 'Hello from SolLib'))
    .CompileMessage;

  LExpectedTail := GetCraftTransactionTail;
  AssertEquals(LTxBytes, LExpectedTail, 'Compiled message tail mismatch');
end;


procedure TTransactionTests.PartialSignTest;
var
  LWallet: IWallet;
  LOwner, LMint, LInitial: IAccount;
  LTx: ITransaction;
  LMsgBytes, LSerialized: TBytes;
  LSigners: TList<IAccount>;
begin
  LWallet := TWallet.Create(MnemonicWords);

  LOwner := LWallet.GetAccountByIndex(10);
  LMint := LWallet.GetAccountByIndex(1002);
  LInitial := LWallet.GetAccountByIndex(1102);
  LTx := TTransaction.Create;

  LTx.FeePayer := LOwner.PublicKey;
  LTx.RecentBlockHash := 'EtLZEUfN1sSsaHRzTtrGW6N62hagTXjc5jokiWqZ9qQ3';

  LMsgBytes := LTx
    .Add(TSystemProgram.CreateAccount(
      LOwner.PublicKey, LMint.PublicKey, 1461600, TTokenProgram.MintAccountDataSize, TTokenProgram.ProgramIdKey))
    .Add(TTokenProgram.InitializeMint(
      LMint.PublicKey, 2, LOwner.PublicKey, LOwner.PublicKey))
    .Add(TSystemProgram.CreateAccount(
      LOwner.PublicKey, LInitial.PublicKey, 2039280, TTokenProgram.TokenAccountDataSize, TTokenProgram.ProgramIdKey))
    .Add(TTokenProgram.InitializeAccount(
      LInitial.PublicKey, LMint.PublicKey, LOwner.PublicKey))
    .Add(TTokenProgram.MintTo(
      LMint.PublicKey, LInitial.PublicKey, 1000000, LOwner.PublicKey))
    .Add(TMemoProgram.NewMemo(LInitial.PublicKey, 'Hello from SolLib'))
    .CompileMessage;

  // partial sign
  LSigners := TList<IAccount>.Create;
  try
    LSigners.AddRange([LOwner, LOwner]);
    LTx.PartialSign(LSigners);
  finally
    LSigners.Free;
  end;

  LTx.PartialSign(LMint);

  // final signature
  LTx.AddSignature(LInitial.PublicKey, LInitial.Sign(LMsgBytes));

  LSerialized := LTx.Serialize;
  AssertEquals(LSerialized, GetCraftTransactionBytes, 'PartialSign serialized bytes mismatch');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TTransactionTests);
{$ELSE}
  RegisterTest(TTransactionTests.Suite);
{$ENDIF}

end.

