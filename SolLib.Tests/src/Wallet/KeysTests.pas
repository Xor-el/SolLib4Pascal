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

unit KeysTests;

interface

uses
  SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpPublicKey,
  SlpPrivateKey,
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
  LPk: IPrivateKey;
begin
  LPk := TPrivateKey.Create(PrivateKeyString);
  AssertEquals(ExpectedPrivateKeyBytes, LPk.KeyBytes, 'PrivateKey bytes mismatch');
end;

procedure TKeysTests.TestPrivateKeyToString;
var
  LPk: IPrivateKey;
begin
  LPk := TPrivateKey.Create(PrivateKeyBytes);
  AssertEquals(ExpectedPrivateKey, LPk.ToString, 'PrivateKey.Text mismatch');
end;

procedure TKeysTests.TestInvalidPrivateKeyBytes;
begin
  AssertException(
    procedure
    var LPk: IPrivateKey;
    begin
      LPk := TPrivateKey.Create(InvalidPrivateKeyBytes);
    end,
    EArgumentException
  );
end;

procedure TKeysTests.TestNullPrivateKeyBytes;
begin
  AssertException(
    procedure
    var LPk: IPrivateKey; LEmpty: TBytes;
    begin
      LEmpty := nil;
      LPk := TPrivateKey.Create(LEmpty);
    end,
    EArgumentNilException
  );
end;

procedure TKeysTests.TestEmptyPrivateKeyString;
begin
  AssertException(
    procedure
    var LPk: IPrivateKey;
    begin
      LPk := TPrivateKey.Create('');
    end,
    EArgumentNilException
  );
end;

procedure TKeysTests.TestPublicKeyToString;
var
  LPk: IPublicKey;
begin
  LPk := TPublicKey.Create(PublicKeyBytes);

  AssertEquals(LPk.Key, LPk.ToString, 'PublicKey.ToString mismatch');
end;

procedure TKeysTests.TestInvalidPublicKeyBytes;
begin
  AssertException(
    procedure
    var LPk: IPublicKey;
    begin
      LPk := TPublicKey.Create(InvalidPublicKeyBytes);
    end,
    EArgumentException
  );
end;

procedure TKeysTests.TestNullPublicKeyString;
begin
  AssertException(
    procedure
    var LPk: IPublicKey;
    begin
      LPk := TPublicKey.Create('');
    end,
    EArgumentNilException
  );
end;

procedure TKeysTests.TestNullPublicKeyBytes;
begin
  AssertException(
    procedure
    var LPk: IPublicKey; LEmpty: TBytes;
    begin
      LEmpty := nil;
      LPk := TPublicKey.Create(LEmpty);
    end,
    EArgumentNilException
  );
end;

procedure TKeysTests.TryCreateWithSeed;
var
  LSuccess: Boolean;
  LRes, LBase, LProgramId: IPublicKey;
begin
  LRes := nil;
  LBase := TPublicKey.Create('11111111111111111111111111111111');
  LProgramId := TPublicKey.Create('11111111111111111111111111111111');

  LSuccess := TPublicKey.TryCreateWithSeed(
    LBase,
    'limber chicken: 4/45',
    LProgramId,
    LRes
  );
  AssertTrue(LSuccess, 'TryCreateWithSeed failed');
  AssertEquals('9h1HyLCW5dZnBVap8C5egQ9Z6pHyjsh5MNy83iPqqRuq', LRes.Key);
end;

procedure TKeysTests.TryCreateWithSeed_False;
var
  LSuccess: Boolean;
  LRes, LBase, LProgramId: IPublicKey;
begin
  LRes := nil;
  LBase := TPublicKey.Create('11111111111111111111111111111111');
  LProgramId := TPublicKey.Create(TEncoding.UTF8.GetBytes('aaaaaaaaaaaProgramDerivedAddress'));

  LSuccess := TPublicKey.TryCreateWithSeed(
    LBase,
    'limber chicken: 4/45',
    LProgramId,
    LRes
  );
  AssertFalse(LSuccess, 'TryCreateWithSeed should fail');
end;

procedure TKeysTests.TestCreateProgramAddressException;
begin
  AssertException(
    procedure
    var
      LDummy, LLoader: IPublicKey;
    begin
      LDummy := nil;
      LLoader := TPublicKey.Create(LoaderProgramIdStr);
      TPublicKey.TryCreateProgramAddress(
        [TEncoding.UTF8.GetBytes('SeedPubey1111111111111111111111111111111111')],
        LLoader,
        LDummy
      );
    end,
    EArgumentException
  );
end;

procedure TKeysTests.TestCreateProgramAddress;
const
  SunSymbol = Char($2609);
var
  LLoader, LPubKey: IPublicKey;
  LOk: Boolean;
  LB58Seed: TBytes;
begin
  LLoader := TPublicKey.Create(LoaderProgramIdStr);
  LPubKey := nil;

  // 1) Base58-decoded seed
  LB58Seed := DecodeBase58('SeedPubey1111111111111111111111111111111111');
  LOk := TPublicKey.TryCreateProgramAddress([LB58Seed], LLoader, LPubKey);
  AssertTrue(LOk, 'TryCreateProgramAddress #1 failed');
  AssertEquals('GUs5qLUfsEHkcMB9T38vjr18ypEhRuNWiePW2LoK4E3K', LPubKey.Key);
  LPubKey := nil;

  // 2) "", 0x01
  LOk := TPublicKey.TryCreateProgramAddress(
    [TEncoding.UTF8.GetBytes(''), TBytes.Create(Byte(1))],
    LLoader,
    LPubKey
  );
  AssertTrue(LOk, 'TryCreateProgramAddress #2 failed');
  AssertEquals('3gF2KMe9KiC6FNVBmfg9i267aMPvK37FewCip4eGBFcT', LPubKey.Key);
  LPubKey := nil;

  // 3) "☉"
  LOk := TPublicKey.TryCreateProgramAddress([TEncoding.UTF8.GetBytes(SunSymbol)], LLoader, LPubKey);
  AssertTrue(LOk, 'TryCreateProgramAddress #3 failed');
  AssertEquals('7ytmC1nT1xY4RfxCV2ZgyA7UakC93do5ZdyhdF3EtPj7', LPubKey.Key);
end;

procedure TKeysTests.TestFindProgramAddress;
var
  LLoader, LDerived, LRecreated: IPublicKey;
  LNonce: Byte;
  LOk: Boolean;
begin
  LLoader := TPublicKey.Create(LoaderProgramIdStr);
  LDerived := nil;
  LRecreated := nil;

  LOk := TPublicKey.TryFindProgramAddress([TEncoding.UTF8.GetBytes('')], LLoader, LDerived, LNonce);
  AssertTrue(LOk, 'TryFindProgramAddress failed');

  LOk := TPublicKey.TryCreateProgramAddress([TEncoding.UTF8.GetBytes(''), TBytes.Create(LNonce)], LLoader, LRecreated);
  AssertTrue(LOk, 'TryCreateProgramAddress recreate failed');
  AssertEquals(LDerived.Key, LRecreated.Key);
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
  AssertFalse(TPublicKey.IsValid(DecodeBase58('GUs5qLUfsEHkcMB9T38vjr18ypEhRuNWiePW2LoK4E3K'), True));
end;

procedure TKeysTests.TestIsValidOnCurveSpan_True;
begin
  AssertTrue(TPublicKey.IsValid(DecodeBase58('oaksGKfwkFZwCniyCF35ZVxHDPexQ3keXNTiLa7RCSp'), True));
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
    var LPk: IPublicKey;
    begin
      LPk := TPublicKey.Create('GUs5qLUfsEHkcMB9T38vjr18ypEhRuNWiePW2LoK4E3K ');
    end,
    EArgumentException
  );
end;

procedure TKeysTests.TestCreateBadPublicKeyFatal_2;
begin
  AssertException(
    procedure
    var LPk: IPublicKey;
    begin
      LPk := TPublicKey.Create('GUs5qLU&sEHkcMB9T38vjr18ypEhRuNWiePW2LoK4E3K');
    end,
    EArgumentException
  );
end;

procedure TKeysTests.Equals_PublicKey_ExactSameInterface_ReturnsTrue;
var
  LA, LB: IPublicKey;
begin
  LA := TPublicKey.Create(PublicKeyString);
  LB := LA; // same interface reference
  AssertTrue(LA.Equals(LB), 'Exact same interface reference should be equal');
end;

procedure TKeysTests.Equals_PublicKey_SameKeyDifferentInstances_ReturnsTrue;
var
  LA, LB: IPublicKey;
begin
  // Two DISTINCT instances, constructed with the SAME keys
  LA := TPublicKey.Create(PublicKeyString);
  LB := TPublicKey.Create(PublicKeyString);

  AssertTrue(LA.Equals(LB), 'Equals should be True when public keys are equal');
  AssertTrue(LB.Equals(LA), 'Equals should be symmetric when public keys are equal');
end;

procedure TKeysTests.Equals_PublicKey_DifferentKeys_ReturnsFalse;
var
  LA, LB: IPublicKey;
begin
  LA := TPublicKey.Create(PublicKeyString);
  LB := TPublicKey.Create(LoaderProgramIdStr);

  AssertFalse(LA.Equals(LB), 'Equals should be False when public keys differ');
  AssertFalse(LB.Equals(LA), 'Equals should be symmetric when public keys differ');
end;

procedure TKeysTests.Equals_PublicKey_Nil_ReturnsFalse;
var
  LA: IPublicKey;
begin
  LA := TPublicKey.Create(PublicKeyString);
  AssertFalse(LA.Equals(nil), 'Equals(nil) should be False');
end;

procedure TKeysTests.Equals_PrivateKey_ExactSameInterface_ReturnsTrue;
var
  LA, LB: IPrivateKey;
begin
  LA := TPrivateKey.Create(PrivateKeyString);
  LB := LA; // same interface reference
  AssertTrue(LA.Equals(LB), 'Exact same interface reference should be equal');
end;

procedure TKeysTests.Equals_PrivateKey_SameKeyDifferentInstances_ReturnsTrue;
var
  LA, LB: IPrivateKey;
begin
  // Two DISTINCT instances, constructed with the SAME keys
  LA := TPrivateKey.Create(PrivateKeyString);
  LB := TPrivateKey.Create(PrivateKeyString);

  AssertTrue(LA.Equals(LB), 'Equals should be True when private keys are equal');
  AssertTrue(LB.Equals(LA), 'Equals should be symmetric when private keys are equal');
end;

procedure TKeysTests.Equals_PrivateKey_DifferentKeys_ReturnsFalse;
var
  LA, LB: IPrivateKey;
begin
  LA := TPrivateKey.Create(PrivateKeyString);
  LB := TPrivateKey.Create(ExpectedPrivateKey);

  AssertFalse(LA.Equals(LB), 'Equals should be False when private keys differ');
  AssertFalse(LB.Equals(LA), 'Equals should be symmetric when private keys differ');
end;

procedure TKeysTests.Equals_PrivateKey_Nil_ReturnsFalse;
var
  LA: IPrivateKey;
begin
  LA := TPrivateKey.Create(PrivateKeyString);
  AssertFalse(LA.Equals(nil), 'Equals(nil) should be False');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TKeysTests);
{$ELSE}
  RegisterTest(TKeysTests.Suite);
{$ENDIF}

end.

