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

unit KeysTests;

interface

uses
  System.SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpPublicKey,
  SlpPrivateKey,
  SlpDataEncoders,
  SolLibTestCase;

type
  TKeysTests = class(TSolLibTestCase)
  private
   const
    PrivateKeyString = '5ZD7ntKtyHrnqMhfSuKBLdqHzT5N3a2aYnCGBcz4N78b84TKpjwQ4QBsapEnpnZFchM7F1BpqDkSuLdwMZwM8hLi';
    ExpectedPrivateKey = 'c1BzdtL4RByNQnzcaUq3WuNLuyY4tQogGT7JWwy4YGBE8FGSgWUH8eNJFyJgXNYtwTKq4emhC4V132QX9REwujm';
    PublicKeyString = '9KmfMX4Ne5ocb8C7PwjmJTWTpQTQcPhkeD2zY35mawhq';
    LoaderProgramIdStr = 'BPFLoader1111111111111111111111111111111111';

    class function ExpectedPrivateKeyBytes: TBytes; static;
    class function PrivateKeyBytes: TBytes; static;
    class function InvalidPrivateKeyBytes: TBytes; static;

    class function PublicKeyBytes: TBytes; static;
    class function InvalidPublicKeyBytes: TBytes; static;
  published
    procedure TestPrivateKey;
    procedure TestPrivateKeyToString;

    procedure TestInvalidPrivateKeyBytes;
    procedure TestNullPrivateKeyBytes;
    procedure TestEmptyPrivateKeyString;

    procedure TestPublicKeyToString;
    procedure TestInvalidPublicKeyBytes;
    procedure TestNullPublicKeyString;
    procedure TestNullPublicKeyBytes;

    procedure TryCreateWithSeed;
    procedure TryCreateWithSeed_False;

    procedure TestCreateProgramAddressException;
    procedure TestCreateProgramAddress;
    procedure TestFindProgramAddress;

    procedure TestIsValid;
    procedure TestIsValidOnCurve_False;
    procedure TestIsValidOnCurve_True;
    procedure TestIsValidOnCurveSpan_False;
    procedure TestIsValidOnCurveSpan_True;
    procedure TestIsValid_False;
    procedure TestIsValid_Empty_False;
    procedure TestIsValid_InvalidB58_False;

    procedure TestCreateBadPublicKeyFatal_1;
    procedure TestCreateBadPublicKeyFatal_2;

    procedure Equals_PublicKey_ExactSameInterface_ReturnsTrue;
    procedure Equals_PublicKey_SameKeyDifferentInstances_ReturnsTrue;
    procedure Equals_PublicKey_DifferentKeys_ReturnsFalse;
    procedure Equals_PublicKey_Nil_ReturnsFalse;

    procedure Equals_PrivateKey_ExactSameInterface_ReturnsTrue;
    procedure Equals_PrivateKey_SameKeyDifferentInstances_ReturnsTrue;
    procedure Equals_PrivateKey_DifferentKeys_ReturnsFalse;
    procedure Equals_PrivateKey_Nil_ReturnsFalse;
  end;

implementation

{ TKeysTests }

class function TKeysTests.ExpectedPrivateKeyBytes: TBytes;
begin
  Result := TBytes.Create(
    227, 215, 255, 79, 160, 83, 24, 167, 124, 73, 168, 45,
    235, 105, 253, 165, 194, 54, 12, 95, 5, 47, 21, 158, 120,
    155, 199, 182, 101, 212, 80, 173, 138, 180, 156, 252, 109,
    252, 108, 26, 186, 0, 196, 69, 57, 102, 15, 151, 149, 242,
    119, 181, 171, 113, 120, 224, 0, 118, 155, 61, 246, 56, 178, 47
  );
end;

class function TKeysTests.PrivateKeyBytes: TBytes;
begin
  Result := TBytes.Create(
    30, 47, 124, 64, 115, 181, 108, 148, 133, 204, 66, 60, 190,
    64, 208, 182, 169, 19, 112, 20, 186, 227, 179, 134, 96, 155,
    90, 163, 54, 6, 152, 33, 123, 172, 114, 217, 192, 233, 194,
    40, 233, 234, 173, 25, 163, 56, 237, 112, 216, 151, 21, 209,
    120, 79, 46, 85, 162, 195, 155, 97, 136, 88, 16, 64
  );
end;

class function TKeysTests.InvalidPrivateKeyBytes: TBytes;
begin
  Result := TBytes.Create(
    30, 47, 124, 64, 115, 181, 108, 148, 133, 204, 66, 60, 190,
    64, 208, 182, 169, 19, 112, 20, 186, 227, 179, 134, 96, 155,
    90, 163, 54, 6, 152, 33, 123, 172, 114, 217, 192, 233, 194,
    40, 233, 234, 173, 25, 163, 56, 237, 112, 216, 151, 21, 209,
    120, 79, 46, 85, 162, 195, 155, 97, 136, 88, 16, 64, 0
  );
end;

class function TKeysTests.PublicKeyBytes: TBytes;
begin
  Result := TBytes.Create(
    123, 172, 114, 217, 192, 233, 194, 40, 233, 234, 173, 25,
    163, 56, 237, 112, 216, 151, 21, 209, 120, 79, 46, 85,
    162, 195, 155, 97, 136, 88, 16, 64
  );
end;

class function TKeysTests.InvalidPublicKeyBytes: TBytes;
begin
  Result := TBytes.Create(
    123, 172, 114, 217, 192, 233, 194, 40, 233, 234, 173, 25,
    163, 56, 237, 112, 216, 151, 21, 209, 120, 79, 46, 85,
    162, 195, 155, 97, 136, 88, 16, 64, 0
  );
end;

procedure TKeysTests.TestPrivateKey;
var
  PK: IPrivateKey;
begin
  PK := TPrivateKey.Create(PrivateKeyString);
  AssertEquals<Byte>(ExpectedPrivateKeyBytes, PK.KeyBytes, 'PrivateKey bytes mismatch');
end;

procedure TKeysTests.TestPrivateKeyToString;
var
  PK: IPrivateKey;
begin
  PK := TPrivateKey.Create(PrivateKeyBytes);
  AssertEquals(ExpectedPrivateKey, PK.ToString, 'PrivateKey.Text mismatch');
end;

procedure TKeysTests.TestInvalidPrivateKeyBytes;
begin
  AssertException(
    procedure
    var PK: IPrivateKey;
    begin
      PK := TPrivateKey.Create(InvalidPrivateKeyBytes);
    end,
    EArgumentException
  );
end;

procedure TKeysTests.TestNullPrivateKeyBytes;
begin
  AssertException(
    procedure
    var PK: IPrivateKey; Empty: TBytes;
    begin
      Empty := nil;
      PK := TPrivateKey.Create(Empty);
    end,
    EArgumentNilException
  );
end;

procedure TKeysTests.TestEmptyPrivateKeyString;
begin
  AssertException(
    procedure
    var PK: IPrivateKey;
    begin
      PK := TPrivateKey.Create('');
    end,
    EArgumentNilException
  );
end;

procedure TKeysTests.TestPublicKeyToString;
var
  PK: IPublicKey;
begin
  PK := TPublicKey.Create(PublicKeyBytes);

  AssertEquals(PK.Key, PK.ToString, 'PublicKey.ToString mismatch');
end;

procedure TKeysTests.TestInvalidPublicKeyBytes;
begin
  AssertException(
    procedure
    var PK: IPublicKey;
    begin
      PK := TPublicKey.Create(InvalidPublicKeyBytes);
    end,
    EArgumentException
  );
end;

procedure TKeysTests.TestNullPublicKeyString;
begin
  AssertException(
    procedure
    var PK: IPublicKey;
    begin
      PK := TPublicKey.Create('');
    end,
    EArgumentNilException
  );
end;

procedure TKeysTests.TestNullPublicKeyBytes;
begin
  AssertException(
    procedure
    var PK: IPublicKey; Empty: TBytes;
    begin
      Empty := nil;
      PK := TPublicKey.Create(Empty);
    end,
    EArgumentNilException
  );
end;

procedure TKeysTests.TryCreateWithSeed;
var
  Success: Boolean;
  Res, Base, ProgramId: IPublicKey;
begin
  Res := nil;
  Base := TPublicKey.Create('11111111111111111111111111111111');
  ProgramId := TPublicKey.Create('11111111111111111111111111111111');

  Success := TPublicKey.TryCreateWithSeed(
    Base,
    'limber chicken: 4/45',
    ProgramId,
    Res
  );
  AssertTrue(Success, 'TryCreateWithSeed failed');
  AssertEquals('9h1HyLCW5dZnBVap8C5egQ9Z6pHyjsh5MNy83iPqqRuq', Res.Key);
end;

procedure TKeysTests.TryCreateWithSeed_False;
var
  Success: Boolean;
  Res, Base, ProgramId: IPublicKey;
begin
  Res := nil;
  Base := TPublicKey.Create('11111111111111111111111111111111');
  ProgramId := TPublicKey.Create(TEncoding.UTF8.GetBytes('aaaaaaaaaaaProgramDerivedAddress'));

  Success := TPublicKey.TryCreateWithSeed(
    Base,
    'limber chicken: 4/45',
    ProgramId,
    Res
  );
  AssertFalse(Success, 'TryCreateWithSeed should fail');
end;

procedure TKeysTests.TestCreateProgramAddressException;
begin
  AssertException(
    procedure
    var
      Dummy, Loader: IPublicKey;
    begin
      Dummy := nil;
      Loader := TPublicKey.Create(LoaderProgramIdStr);
      TPublicKey.TryCreateProgramAddress(
        [TEncoding.UTF8.GetBytes('SeedPubey1111111111111111111111111111111111')],
        Loader,
        Dummy
      );
    end,
    EArgumentException
  );
end;

procedure TKeysTests.TestCreateProgramAddress;
var
  Loader, PubKey: IPublicKey;
  Ok: Boolean;
  B58Seed: TBytes;
begin
  Loader := TPublicKey.Create(LoaderProgramIdStr);
  PubKey := nil;

  // 1) Base58-decoded seed
  B58Seed := TEncoders.Base58.DecodeData('SeedPubey1111111111111111111111111111111111');
  Ok := TPublicKey.TryCreateProgramAddress([B58Seed], Loader, PubKey);
  AssertTrue(Ok, 'TryCreateProgramAddress #1 failed');
  AssertEquals('GUs5qLUfsEHkcMB9T38vjr18ypEhRuNWiePW2LoK4E3K', PubKey.Key);
  PubKey := nil;

  // 2) "", 0x01
  Ok := TPublicKey.TryCreateProgramAddress(
    [TEncoding.UTF8.GetBytes(''), TBytes.Create(Byte(1))],
    Loader,
    PubKey
  );
  AssertTrue(Ok, 'TryCreateProgramAddress #2 failed');
  AssertEquals('3gF2KMe9KiC6FNVBmfg9i267aMPvK37FewCip4eGBFcT', PubKey.Key);
  PubKey := nil;

  // 3) "☉"
  Ok := TPublicKey.TryCreateProgramAddress([TEncoding.UTF8.GetBytes('☉')], Loader, PubKey);
  AssertTrue(Ok, 'TryCreateProgramAddress #3 failed');
  AssertEquals('7ytmC1nT1xY4RfxCV2ZgyA7UakC93do5ZdyhdF3EtPj7', PubKey.Key);
end;

procedure TKeysTests.TestFindProgramAddress;
var
  Loader, Derived, Recreated: IPublicKey;
  Nonce: Byte;
  Ok: Boolean;
begin
  Loader := TPublicKey.Create(LoaderProgramIdStr);
  Derived := nil;
  Recreated := nil;

  Ok := TPublicKey.TryFindProgramAddress([TEncoding.UTF8.GetBytes('')], Loader, Derived, Nonce);
  AssertTrue(Ok, 'TryFindProgramAddress failed');

  Ok := TPublicKey.TryCreateProgramAddress([TEncoding.UTF8.GetBytes(''), TBytes.Create(Nonce)], Loader, Recreated);
  AssertTrue(Ok, 'TryCreateProgramAddress recreate failed');
  AssertEquals(Derived.Key, Recreated.Key);
end;

procedure TKeysTests.TestIsValid;
begin
  AssertTrue(TPublicKey.IsValid('GUs5qLUfsEHkcMB9T38vjr18ypEhRuNWiePW2LoK4E3K'));
  AssertFalse(TPublicKey.IsValid('GUs5qLUfsEHkcMB9T38vj*18ypEhRuNWiePW2LoK4E3K'));
  AssertFalse(TPublicKey.IsValid('GUs5qLUfsEHkcMB9T38vjr18ypEhRuNWiePW2LoK4E3K '));
end;

procedure TKeysTests.TestIsValidOnCurve_False;
begin
  AssertFalse(TPublicKey.IsValid('GUs5qLUfsEHkcMB9T38vjr18ypEhRuNWiePW2LoK4E3K', True));
end;

procedure TKeysTests.TestIsValidOnCurve_True;
begin
  AssertTrue(TPublicKey.IsValid('oaksGKfwkFZwCniyCF35ZVxHDPexQ3keXNTiLa7RCSp', True));
end;

procedure TKeysTests.TestIsValidOnCurveSpan_False;
begin
  AssertFalse(TPublicKey.IsValid(TEncoders.Base58.DecodeData('GUs5qLUfsEHkcMB9T38vjr18ypEhRuNWiePW2LoK4E3K'), True));
end;

procedure TKeysTests.TestIsValidOnCurveSpan_True;
begin
  AssertTrue(TPublicKey.IsValid(TEncoders.Base58.DecodeData('oaksGKfwkFZwCniyCF35ZVxHDPexQ3keXNTiLa7RCSp'), True));
end;

procedure TKeysTests.TestIsValid_False;
begin
  AssertFalse(TPublicKey.IsValid('GUs5qLUfsEHkcMB9T3ePW2LoK4E3K'));
end;

procedure TKeysTests.TestIsValid_Empty_False;
begin
  AssertFalse(TPublicKey.IsValid(''));
  AssertFalse(TPublicKey.IsValid('  '));
end;

procedure TKeysTests.TestIsValid_InvalidB58_False;
begin
  AssertFalse(TPublicKey.IsValid('lllllll'));
end;

procedure TKeysTests.TestCreateBadPublicKeyFatal_1;
begin
  AssertException(
    procedure
    var PK: IPublicKey;
    begin
      PK := TPublicKey.Create('GUs5qLUfsEHkcMB9T38vjr18ypEhRuNWiePW2LoK4E3K ');
    end,
    EArgumentException
  );
end;

procedure TKeysTests.TestCreateBadPublicKeyFatal_2;
begin
  AssertException(
    procedure
    var PK: IPublicKey;
    begin
      PK := TPublicKey.Create('GUs5qLU&sEHkcMB9T38vjr18ypEhRuNWiePW2LoK4E3K');
    end,
    EArgumentException
  );
end;

procedure TKeysTests.Equals_PublicKey_ExactSameInterface_ReturnsTrue;
var
  A, B: IPublicKey;
begin
  A := TPublicKey.Create(PublicKeyString);
  B := A; // same interface reference
  AssertTrue(A.Equals(B), 'Exact same interface reference should be equal');
end;

procedure TKeysTests.Equals_PublicKey_SameKeyDifferentInstances_ReturnsTrue;
var
  A, B: IPublicKey;
begin
  // Two DISTINCT instances, constructed with the SAME keys
  A := TPublicKey.Create(PublicKeyString);
  B := TPublicKey.Create(PublicKeyString);

  AssertTrue(A.Equals(B), 'Equals should be True when public keys are equal');
  AssertTrue(B.Equals(A), 'Equals should be symmetric when public keys are equal');
end;

procedure TKeysTests.Equals_PublicKey_DifferentKeys_ReturnsFalse;
var
  A, B: IPublicKey;
begin
  A := TPublicKey.Create(PublicKeyString);
  B := TPublicKey.Create(LoaderProgramIdStr);

  AssertFalse(A.Equals(B), 'Equals should be False when public keys differ');
  AssertFalse(B.Equals(A), 'Equals should be symmetric when public keys differ');
end;

procedure TKeysTests.Equals_PublicKey_Nil_ReturnsFalse;
var
  A: IPublicKey;
begin
  A := TPublicKey.Create(PublicKeyString);
  AssertFalse(A.Equals(nil), 'Equals(nil) should be False');
end;

procedure TKeysTests.Equals_PrivateKey_ExactSameInterface_ReturnsTrue;
var
  A, B: IPrivateKey;
begin
  A := TPrivateKey.Create(PrivateKeyString);
  B := A; // same interface reference
  AssertTrue(A.Equals(B), 'Exact same interface reference should be equal');
end;

procedure TKeysTests.Equals_PrivateKey_SameKeyDifferentInstances_ReturnsTrue;
var
  A, B: IPrivateKey;
begin
  // Two DISTINCT instances, constructed with the SAME keys
  A := TPrivateKey.Create(PrivateKeyString);
  B := TPrivateKey.Create(PrivateKeyString);

  AssertTrue(A.Equals(B), 'Equals should be True when private keys are equal');
  AssertTrue(B.Equals(A), 'Equals should be symmetric when private keys are equal');
end;

procedure TKeysTests.Equals_PrivateKey_DifferentKeys_ReturnsFalse;
var
  A, B: IPrivateKey;
begin
  A := TPrivateKey.Create(PrivateKeyString);
  B := TPrivateKey.Create(ExpectedPrivateKey);

  AssertFalse(A.Equals(B), 'Equals should be False when private keys differ');
  AssertFalse(B.Equals(A), 'Equals should be symmetric when private keys differ');
end;

procedure TKeysTests.Equals_PrivateKey_Nil_ReturnsFalse;
var
  A: IPrivateKey;
begin
  A := TPrivateKey.Create(PrivateKeyString);
  AssertFalse(A.Equals(nil), 'Equals(nil) should be False');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TKeysTests);
{$ELSE}
  RegisterTest(TKeysTests.Suite);
{$ENDIF}

end.

