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

unit CryptoProviderTests;

interface

uses
  SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpCryptoUtilities,
  SolLibTestCase;

type

  // -----------------------------------------------------------------------
  //  Test-vector record
  //
  //  Every vector was verified against @solana/web3.js v1.98.4
  //  (PublicKey.isOnCurve) on 2026-03-19 unless noted otherwise.
  //
  //  Source legend:
  //    real-world            = address observed on Solana mainnet / official docs
  //    real-world (GH#17106) = from solana-labs/solana issue #17106
  //    well-known            = cryptographically well-known constant
  //    real-world (RFC 8032) = public key from RFC 8032 Section 7.1
  //    generated (Solana)    = produced by Keypair.generate / findProgramAddress
  //    generated             = hand-crafted for edge-case coverage
  //
  //  NOTE: Small-order / torsion points and mixed-torsion points are
  //  intentionally omitted.  Solana (curve25519-dalek) and CryptoLib4Pascal
  //  (ValidatePublicKeyPartial) diverge on those, but Ed25519 key generation
  //  (RFC 8032 Section 5.1.5) arithmetically guarantees that all wallet-
  //  generated public keys are non-identity elements of the prime-order
  //  subgroup, so these edge cases never arise in practice.
  // -----------------------------------------------------------------------

  TIsOnCurveVector = record
    Hex: string;
    ExpectedOnCurve: Boolean;
    Label_: string;   // trailing underscore avoids reserved-word clash
    Source: string;
  end;

  TCryptoProviderTests = class(TSolLibTestCase)
  private
    procedure RunVectors(const AVectors: array of TIsOnCurveVector);
  published

    // Category 1: Real-world Solana addresses
    procedure TestRealWorldSolanaAddresses;

    // Category 2: Non-canonical y encodings (y >= p)
    // Both Solana and CryptoLib4Pascal reject these.
    procedure TestNonCanonicalYEncodings;

    // Category 3: Off-curve byte strings
    procedure TestOffCurveByteStrings;

    // Category 4: RFC 8032 test-vector public keys
    procedure TestRFC8032PublicKeys;

    // Category 5: Solana PDAs (guaranteed off-curve)
    procedure TestSolanaPDAs;

    // Category 6: Well-known curve points & edge cases
    procedure TestWellKnownCurvePointsAndEdgeCases;

    // Category 7: Input-length guard
    procedure TestRejectPublicKeyNotExactly32Bytes;
  end;

implementation

// =========================================================================
//  Vector tables
//
//  Hex strings are UPPER-CASE, 64 characters (32 bytes).
//  Every result was captured from:
//     const { PublicKey } = require('@solana/web3.js');
//     PublicKey.isOnCurve(Buffer.from(hex, 'hex'));
// =========================================================================

const

  // Category 1: Real-world Solana addresses

  RealWorldVectors: array[0..8] of TIsOnCurveVector = (
    ( Hex: '474F7335D5399E496566FCFE89B06DDF2F9DF31FAB601AAFBF9AFE5574A596AD';
      ExpectedOnCurve: True;
      Label_: 'Solana Cookbook on-curve key (5oNDL3swdJJF1g9DzJiZ4ynHXgszjAEpUkxVYejchzrY)';
      Source: 'real-world' ),

    ( Hex: '2F36AFB4AB51F55A29712488EB3D44BFE77B7228F26028BDF2662650F5B7629F';
      ExpectedOnCurve: False;
      Label_: 'Solana Cookbook off-curve PDA (4BJXYkfvg37zEmBbsacZjeQDpTNx91KppxFJxRqrz48e)';
      Source: 'real-world' ),

    ( Hex: '06DDF6E1D765A193D9CBE146CEEB79AC1CB485ED5F5B37913A8CF5857EFF00A9';
      ExpectedOnCurve: True;
      Label_: 'SPL Token Program (TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA)';
      Source: 'real-world' ),

    ( Hex: '8C97258F4E2489F1BB3D1029148E0D830B5A1399DAFF1084048E7BD8DBE9F859';
      ExpectedOnCurve: True;
      Label_: 'Associated Token Account Program (ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL)';
      Source: 'real-world' ),

    ( Hex: '054A535A992921064D24E87160DA387C7C35B5DDBC92BB81E41FA8404105448D';
      ExpectedOnCurve: True;
      Label_: 'Memo Program v2 (MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr)';
      Source: 'real-world' ),

    ( Hex: '0B7065B1E3D17C45389D527F6B04C3CD58B86C731AA0FDB549B6D1BC03F82946';
      ExpectedOnCurve: True;
      Label_: 'Metaplex Token Metadata (metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s)';
      Source: 'real-world' ),

    ( Hex: '850F2D6E02A47AF824D09AB69DC42D70CB28CBFA249FB7EE57B9D256C12762EF';
      ExpectedOnCurve: True;
      Label_: 'Serum DEX v3 (9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin)';
      Source: 'real-world' ),

    // From solana-labs/solana issue #17106 - this point is on the Ed25519
    // curve and Solana accepts it, but pynacl/libsodium rejects it because
    // libsodium's crypto_core_ed25519_is_valid_point() performs a full
    // prime-order subgroup check that Solana intentionally does not.
    ( Hex: 'C14DCE1EA4863CF1BCFC12F4F2E259F48DE456B7F9D45C217B04896A1FFE41DC';
      ExpectedOnCurve: True;
      Label_: 'On-curve point rejected by libsodium (E1aVpiFNTpeSK61ZgwUtpRZgT6cPPgMDw2ydHKkQuP95)';
      Source: 'real-world (GH#17106)' ),

    ( Hex: 'DEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEFF';
      ExpectedOnCurve: True;
      Label_: '0xDEADBEEF pattern with high bit set - happens to land on curve';
      Source: 'generated' )
  );

  // Category 2: Non-canonical y encodings (y >= p)
  //  p = 2^255 - 19.  These are rejected by both Solana and CryptoLib4Pascal.

  NonCanonicalVectors: array[0..3] of TIsOnCurveVector = (
    ( Hex: 'EDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7F';
      ExpectedOnCurve: False;
      Label_: 'y = p (non-canonical encoding of y=0)';
      Source: 'generated' ),

    ( Hex: 'EEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7F';
      ExpectedOnCurve: False;
      Label_: 'y = p+1 (non-canonical encoding of y=1)';
      Source: 'generated' ),

    ( Hex: 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7F';
      ExpectedOnCurve: False;
      Label_: 'y = 2^255-1 = p+18 (max 255-bit y value)';
      Source: 'generated' ),

    ( Hex: 'F2FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7F';
      ExpectedOnCurve: False;
      Label_: 'y = p+5';
      Source: 'generated' )
  );

  // Category 3: Off-curve byte strings

  OffCurveVectors: array[0..2] of TIsOnCurveVector = (
    ( Hex: 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF';
      ExpectedOnCurve: False;
      Label_: 'All 0xFF bytes';
      Source: 'generated' ),

    ( Hex: '0200000000000000000000000000000000000000000000000000000000000000';
      ExpectedOnCurve: False;
      Label_: 'y = 2 (no valid x for this y)';
      Source: 'generated' ),

    ( Hex: 'DEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF';
      ExpectedOnCurve: False;
      Label_: '0xDEADBEEF repeating pattern';
      Source: 'generated' )
  );

  // Category 4: RFC 8032 test-vector public keys

  RFC8032Vectors: array[0..3] of TIsOnCurveVector = (
    ( Hex: 'D75A980182B10AB7D54BFED3C964073A0EE172F3DAA62325AF021A68F707511A';
      ExpectedOnCurve: True;
      Label_: 'RFC 8032 Section 7.1 Test Vector 1';
      Source: 'real-world (RFC 8032)' ),

    ( Hex: '3D4017C3E843895A92B70AA74D1B7EBC9C982CCF2EC4968CC0CD55F12AF4660C';
      ExpectedOnCurve: True;
      Label_: 'RFC 8032 Section 7.1 Test Vector 2';
      Source: 'real-world (RFC 8032)' ),

    ( Hex: 'FC51CD8E6218A1A38DA47ED00230F0580816ED13BA3303AC5DEB911548908025';
      ExpectedOnCurve: True;
      Label_: 'RFC 8032 Section 7.1 Test Vector 3';
      Source: 'real-world (RFC 8032)' ),

    ( Hex: '278117FC144C72340F67D0F2316E8386CEFFBF2B2428C9C51FEF7C597F1D426E';
      ExpectedOnCurve: True;
      Label_: 'RFC 8032 Section 7.1 - 1024-byte message test';
      Source: 'real-world (RFC 8032)' )
  );

  // Category 5: Solana PDAs (guaranteed off-curve)
  //  Produced by PublicKey.findProgramAddress with the Token Program as
  //  program_id and deterministic seed strings.

  PDAVectors: array[0..2] of TIsOnCurveVector = (
    ( Hex: 'D941DC76752BE8FB4036BC84A9CB34B331EBF6F0B1412DFEFD2017B5815C7FB4';
      ExpectedOnCurve: False;
      Label_: 'PDA from Token Program (seed: test_seed_255)';
      Source: 'generated (Solana)' ),

    ( Hex: '068CE3DD45E4CFFF94BA4EBC29CA6FBCAA06B1B56337D10D4E5BA8474B69C630';
      ExpectedOnCurve: False;
      Label_: 'PDA from Token Program (seed: test_seed_254)';
      Source: 'generated (Solana)' ),

    ( Hex: 'A10B547FF108B96251CF5515CC56415E42FB016F4D3C0DEC22AC8F18476FEF1B';
      ExpectedOnCurve: False;
      Label_: 'PDA from Token Program (seed: test_seed_253)';
      Source: 'generated (Solana)' )
  );

  // Category 6: Well-known curve points & edge cases

  WellKnownVectors: array[0..4] of TIsOnCurveVector = (
    ( Hex: '5866666666666666666666666666666666666666666666666666666666666666';
      ExpectedOnCurve: True;
      Label_: 'Ed25519 basepoint B (compressed Y = 4/5 mod p)';
      Source: 'well-known' ),

    ( Hex: 'C9A3F86AAE465F0E56513864510F3997561FA2C9E85EA21DC2292309F3CD6022';
      ExpectedOnCurve: True;
      Label_: '[2]B - doubled basepoint';
      Source: 'well-known' ),

    ( Hex: '0300000000000000000000000000000000000000000000000000000000000000';
      ExpectedOnCurve: True;
      Label_: 'y = 3 (valid x exists - on curve)';
      Source: 'generated' ),

    ( Hex: '0500000000000000000000000000000000000000000000000000000000000000';
      ExpectedOnCurve: True;
      Label_: 'y = 5 (valid x exists - on curve)';
      Source: 'generated' ),

    ( Hex: '0000000000000000000000000000000000000000000000000000000000000001';
      ExpectedOnCurve: False;
      Label_: 'y = 2^248 in little-endian - not a valid curve point';
      Source: 'generated' )
  );

// =========================================================================
//  Helper: run a vector array through the SUT
// =========================================================================

procedure TCryptoProviderTests.RunVectors(
  const AVectors: array of TIsOnCurveVector);
var
  I: Integer;
  LBytes: TBytes;
begin
  for I := Low(AVectors) to High(AVectors) do
  begin
    LBytes := DecodeHex(AVectors[I].Hex);
    if AVectors[I].ExpectedOnCurve then
      CheckTrue(
        TEd25519Crypto.IsOnCurve(LBytes),
        Format('[%d] Expected TRUE : %s', [I, AVectors[I].Label_]))
    else
      CheckFalse(
        TEd25519Crypto.IsOnCurve(LBytes),
        Format('[%d] Expected FALSE: %s', [I, AVectors[I].Label_]));
  end;
end;

// =========================================================================
//  Test methods
// =========================================================================

{ TCryptoProviderTests }

procedure TCryptoProviderTests.TestRealWorldSolanaAddresses;
begin
  RunVectors(RealWorldVectors);
end;

procedure TCryptoProviderTests.TestNonCanonicalYEncodings;
begin
  RunVectors(NonCanonicalVectors);
end;

procedure TCryptoProviderTests.TestOffCurveByteStrings;
begin
  RunVectors(OffCurveVectors);
end;

procedure TCryptoProviderTests.TestRFC8032PublicKeys;
begin
  RunVectors(RFC8032Vectors);
end;

procedure TCryptoProviderTests.TestSolanaPDAs;
begin
  RunVectors(PDAVectors);
end;

procedure TCryptoProviderTests.TestWellKnownCurvePointsAndEdgeCases;
begin
  RunVectors(WellKnownVectors);
end;

procedure TCryptoProviderTests.TestRejectPublicKeyNotExactly32Bytes;
begin
  AssertException(
    procedure
    begin
      TEd25519Crypto.IsOnCurve(nil);
    end,
    EArgumentException
  );

  AssertException(
    procedure
    begin
      TEd25519Crypto.IsOnCurve(DecodeHex('00'));
    end,
    EArgumentException
  );

  AssertException(
    procedure
    begin
      TEd25519Crypto.IsOnCurve(DecodeHex(
        '0000000000000000000000000000000000000000000000000000000000000000FF'));
    end,
    EArgumentException
  );
end;

initialization
{$IFDEF FPC}
  RegisterTest(TCryptoProviderTests);
{$ELSE}
  RegisterTest(TCryptoProviderTests.Suite);
{$ENDIF}

end.
