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

unit AccountTests;

interface

uses
  System.SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpAccount,
  SlpPublicKey,
  SlpPrivateKey,
  SolLibTestCase;

type
  TAccountTests = class(TSolLibTestCase)
  private
    function PrivateKeyBytes: TBytes;
    function PublicKeyBytes: TBytes;
    function InvalidPrivateKeyBytes: TBytes;
    function InvalidPublicKeyBytes: TBytes;

    function SerializedMessageBytes: TBytes;
    function SerializedMessageSignatureBytes: TBytes;

    function ExpectedPrivateKeyBytes: TBytes;
    function ExpectedPublicKeyBytes: TBytes;

  published
    procedure TestAccountNoKeys;
    procedure TestAccountInvalidKeys;
    procedure TestAccountInvalidPrivateKey;
    procedure TestAccountInvalidPublicKey;

    procedure TestAccountGetPublicKey;
    procedure TestAccountGetPrivateKey;

    procedure TestAccountSign;
    procedure TestAccountVerify;

    procedure TestAccountInitFromPair;
    procedure TestAccountToString;

    procedure Equals_ExactSameInterface_ReturnsTrue;
    procedure Equals_SamePublicKeyDifferentInstances_ReturnsTrue;
    procedure Equals_DifferentPublicKeys_ReturnsFalse;
    procedure Equals_Nil_ReturnsFalse;
  end;

implementation

const
  ExpectedEncodedPublicKey  = 'ALSzrjtGi8MZGmAZa6ZhtUZq3rwurWuJqWFdgcj9MMFL';
  ExpectedEncodedPrivateKey = '5ZD7ntKtyHrnqMhfSuKBLdqHzT5N3a2aYnCGBcz4N78b84TKpjwQ4QBsapEnpnZFchM7F1BpqDkSuLdwMZwM8hLi';

  PrivateKeyString = 'c1BzdtL4RByNQnzcaUq3WuNLuyY4tQogGT7JWwy4YGBE8FGSgWUH8eNJFyJgXNYtwTKq4emhC4V132QX9REwujm';
  PublicKeyString  = '9KmfMX4Ne5ocb8C7PwjmJTWTpQTQcPhkeD2zY35mawhq';

{ TAccountTests }

function TAccountTests.PrivateKeyBytes: TBytes;
begin
  Result := TBytes.Create(
    227, 215, 255, 79, 160, 83, 24, 167, 124, 73, 168, 45,
    235, 105, 253, 165, 194, 54, 12, 95, 5, 47, 21, 158, 120,
    155, 199, 182, 101, 212, 80, 173, 138, 180, 156, 252, 109,
    252, 108, 26, 186, 0, 196, 69, 57, 102, 15, 151, 149, 242,
    119, 181, 171, 113, 120, 224, 0, 118, 155, 61, 246, 56, 178, 47
  );
end;

function TAccountTests.PublicKeyBytes: TBytes;
begin
  Result := TBytes.Create(
    138, 180, 156, 252, 109, 252, 108, 26, 186, 0,
    196, 69, 57, 102, 15, 151, 149, 242, 119, 181,
    171, 113, 120, 224, 0, 118, 155, 61, 246, 56, 178, 47
  );
end;

function TAccountTests.InvalidPrivateKeyBytes: TBytes;
begin
  Result := TBytes.Create(
    227, 215, 255, 79, 160, 83, 24, 167, 124, 73, 168, 45,
    235, 105, 253, 165, 194, 54, 12, 95, 5, 47, 21, 158, 120,
    155, 199, 182, 101, 212, 80, 173, 138, 180, 156, 252, 109,
    252, 108, 26, 186, 0, 196, 69, 57, 242, 119, 181, 171, 113,
    120, 224, 0, 118, 155, 61, 246, 56, 178, 47
  );
end;

function TAccountTests.InvalidPublicKeyBytes: TBytes;
begin
  Result := TBytes.Create(
    138, 180, 156, 252, 109, 252, 108, 26, 186, 0,
    196, 69, 57, 102, 15, 151, 149, 242, 119, 181,
    171, 113, 120, 224, 0, 118, 155, 61
  );
end;

function TAccountTests.SerializedMessageBytes: TBytes;
begin
  Result := TBytes.Create(
    1, 0, 2, 4, 138, 180, 156, 252, 109, 252, 108, 26, 186, 0,
    196, 69, 57, 102, 15, 151, 149, 242, 119, 181, 171, 113,
    120, 224, 0, 118, 155, 61, 246, 56, 178, 47, 173, 126, 102,
    53, 246, 163, 32, 189, 27, 84, 69, 94, 217, 196, 152, 178,
    198, 116, 124, 160, 230, 94, 226, 141, 220, 221, 119, 21,
    204, 242, 204, 164, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 74, 83, 80,
    248, 93, 200, 130, 214, 20, 165, 86, 114, 120, 138, 41, 109,
    223, 30, 171, 171, 208, 166, 6, 120, 136, 73, 50, 244, 238,
    246, 160, 61, 96, 239, 228, 59, 10, 206, 186, 110, 68, 55,
    160, 108, 50, 58, 247, 220, 116, 182, 121, 237, 126, 42, 184,
    248, 125, 83, 253, 85, 181, 215, 93, 2, 2, 2, 0, 1, 12, 2, 0, 0, 0,
    128, 150, 152, 0, 0, 0, 0, 0, 3, 1, 0, 21, 72, 101, 108, 108, 111,
    32, 102, 114, 111, 109, 32, 83, 111, 108, 46, 78, 101, 116, 32, 58, 41
  );
end;

function TAccountTests.SerializedMessageSignatureBytes: TBytes;
begin
  Result := TBytes.Create(
    234, 147, 144, 17, 200, 57, 8, 154, 139, 86, 156, 12, 7, 143, 144,
    85, 27, 151, 186, 223, 246, 231, 186, 81, 69, 107, 126, 76, 119,
    14, 112, 57, 38, 5, 28, 109, 99, 30, 249, 154, 87, 241, 28, 161,
    178, 165, 146, 73, 179, 4, 71, 133, 203, 145, 125, 252, 200, 249,
    38, 105, 30, 113, 73, 8
  );
end;

function TAccountTests.ExpectedPrivateKeyBytes: TBytes;
begin
  Result := TBytes.Create(
    30, 47, 124, 64, 115, 181, 108, 148, 133, 204, 66, 60, 190,
    64, 208, 182, 169, 19, 112, 20, 186, 227, 179, 134, 96, 155,
    90, 163, 54, 6, 152, 33, 123, 172, 114, 217, 192, 233, 194,
    40, 233, 234, 173, 25, 163, 56, 237, 112, 216, 151, 21, 209,
    120, 79, 46, 85, 162, 195, 155, 97, 136, 88, 16, 64
  );
end;

function TAccountTests.ExpectedPublicKeyBytes: TBytes;
begin
  Result := TBytes.Create(
    123, 172, 114, 217, 192, 233, 194, 40, 233, 234, 173, 25,
    163, 56, 237, 112, 216, 151, 21, 209, 120, 79, 46, 85,
    162, 195, 155, 97, 136, 88, 16, 64
  );
end;

procedure TAccountTests.TestAccountNoKeys;
var
  A: IAccount;
begin
  A := TAccount.Create;

  AssertNotNull(A.PrivateKey, 'A.PrivateKey <> nil');
  AssertNotNull(A.PublicKey,  'A.PublicKey <> nil');
end;

procedure TAccountTests.TestAccountInvalidKeys;
begin
  AssertException(
    procedure
    var A: IAccount;
    begin
      A := TAccount.Create(InvalidPrivateKeyBytes, InvalidPublicKeyBytes);
    end,
    EArgumentException
  );
end;

procedure TAccountTests.TestAccountInvalidPrivateKey;
begin
  AssertException(
    procedure
    var A: IAccount;
    begin
      A := TAccount.Create(InvalidPrivateKeyBytes, PublicKeyBytes);
    end,
    EArgumentException
  );
end;

procedure TAccountTests.TestAccountInvalidPublicKey;
begin
  AssertException(
    procedure
    var A: IAccount;
    begin
      A := TAccount.Create(PrivateKeyBytes, InvalidPublicKeyBytes);
    end,
    EArgumentException
  );
end;

procedure TAccountTests.TestAccountGetPublicKey;
var
  A: IAccount;
begin
  A := TAccount.Create(PrivateKeyBytes, PublicKeyBytes);

  AssertEquals<Byte>(A.PrivateKey.KeyBytes, PrivateKeyBytes, 'PrivateKey mismatch');
  AssertEquals<Byte>(A.PublicKey.KeyBytes,  PublicKeyBytes,  'PublicKey mismatch');
  AssertEquals(ExpectedEncodedPublicKey, A.PublicKey.Key, 'Encoded public key mismatch');
end;

procedure TAccountTests.TestAccountGetPrivateKey;
var
  A: IAccount;
begin
  A := TAccount.Create(PrivateKeyBytes, PublicKeyBytes);

  AssertEquals<Byte>(A.PrivateKey.KeyBytes, PrivateKeyBytes, 'PrivateKey mismatch');
  AssertEquals<Byte>(A.PublicKey.KeyBytes,  PublicKeyBytes,  'PublicKey mismatch');
  AssertEquals(ExpectedEncodedPrivateKey, A.PrivateKey.Key, 'Encoded private key mismatch');
end;

procedure TAccountTests.TestAccountSign;
var
  A: IAccount;
  Sig: TBytes;
begin
  A := TAccount.Create(PrivateKeyBytes, PublicKeyBytes);

  AssertEquals<Byte>(A.PrivateKey.KeyBytes, PrivateKeyBytes);
  AssertEquals<Byte>(A.PublicKey.KeyBytes,  PublicKeyBytes);
  Sig := A.Sign(SerializedMessageBytes);
  AssertEquals<Byte>(Sig, SerializedMessageSignatureBytes, 'Signature mismatch');
end;

procedure TAccountTests.TestAccountVerify;
var
  A: IAccount;
  Ok: Boolean;
begin
  A := TAccount.Create(PrivateKeyBytes, PublicKeyBytes);

  AssertEquals<Byte>(A.PrivateKey.KeyBytes, PrivateKeyBytes);
  AssertEquals<Byte>(A.PublicKey.KeyBytes,  PublicKeyBytes);
  Ok := A.Verify(SerializedMessageBytes, SerializedMessageSignatureBytes);
  AssertTrue(Ok, 'Verify should return True');
end;

procedure TAccountTests.TestAccountInitFromPair;
var
  A: IAccount;
begin
  A := TAccount.Create(PrivateKeyString, PublicKeyString);

  AssertEquals<Byte>(A.PrivateKey.KeyBytes, ExpectedPrivateKeyBytes, 'Derived PrivateKey bytes mismatch');
  AssertEquals<Byte>(A.PublicKey.KeyBytes,  ExpectedPublicKeyBytes,  'Derived PublicKey bytes mismatch');
end;

procedure TAccountTests.TestAccountToString;
var
  A: IAccount;
begin
  A := TAccount.Create(PrivateKeyString, PublicKeyString);

  AssertEquals(PublicKeyString, A.ToString);
end;

procedure TAccountTests.Equals_ExactSameInterface_ReturnsTrue;
var
  A, B: IAccount;
begin
  A := TAccount.Create(PrivateKeyBytes, PublicKeyBytes);
  B := A; // same interface reference
  AssertTrue(A.Equals(B), 'Exact same interface reference should be equal');
end;

procedure TAccountTests.Equals_SamePublicKeyDifferentInstances_ReturnsTrue;
var
  A, B: IAccount;
begin
  // Two DISTINCT instances, constructed with the SAME keys
  A := TAccount.Create(PrivateKeyBytes, PublicKeyBytes);
  B := TAccount.Create(PrivateKeyBytes, PublicKeyBytes);

  AssertTrue(A.Equals(B), 'Equals should be True when public keys are equal');
  AssertTrue(B.Equals(A), 'Equals should be symmetric when public keys are equal');
end;

procedure TAccountTests.Equals_DifferentPublicKeys_ReturnsFalse;
var
  A, B: IAccount;
begin
  // A has known keys; B is random (very likely different public key)
  A := TAccount.Create(PrivateKeyBytes, PublicKeyBytes);
  B := TAccount.Create; // random seed → different keypair

  AssertFalse(A.Equals(B), 'Equals should be False when public keys differ');
  AssertFalse(B.Equals(A), 'Equals should be symmetric when public keys differ');
end;

procedure TAccountTests.Equals_Nil_ReturnsFalse;
var
  A: IAccount;
begin
  A := TAccount.Create(PrivateKeyBytes, PublicKeyBytes);
  AssertFalse(A.Equals(nil), 'Equals(nil) should be False');
end;


initialization
{$IFDEF FPC}
  RegisterTest(TAccountTests);
{$ELSE}
  RegisterTest(TAccountTests.Suite);
{$ENDIF}

end.

