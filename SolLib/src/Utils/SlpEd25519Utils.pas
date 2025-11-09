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

unit SlpEd25519Utils;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  ClpBigInteger,
  ClpISecureRandom,
  ClpIEd25519,
  ClpEd25519,
  ClpISigner,
  ClpIEd25519Signer,
  ClpEd25519Signer,
  ClpIEd25519PublicKeyParameters,
  ClpEd25519PublicKeyParameters,
  ClpIEd25519PrivateKeyParameters,
  ClpEd25519PrivateKeyParameters,
  SlpArrayUtils;

type
  TEd25519KeyPair = record
    SecretKey: TBytes; // 64 bytes: Seed(32) || PublicKey(32)
    PublicKey: TBytes; // 32 bytes
  end;

  {
    Ed25519 � libsodium-format utilities (generate, sign, verify).

    - Keypair format (libsodium-style):
    * SecretKey (64 bytes) = Seed(32) || PublicKey(32)
    * PublicKey (32 bytes)
    - API:
    * TEd25519Libsodium.GenerateKeyPair: random seed -> (SecretKey, PublicKey)
    * TEd25519Libsodium.GenerateKeyPair(Seed32): explicit 32-byte seed
    * TEd25519Libsodium.Sign(SecretKey, Message) -> 64-byte signature
    * TEd25519Libsodium.Verify(PublicKey, Message, Signature) -> Boolean
    * TEd25519Libsodium.GetExpandedPrivateKeyFromSeed(Seed32): SHA-512(seed) with RFC8032 clamping
    - First 32 bytes = clamped scalar
    - Next 32 bytes  = prefix
  }
  TEd25519Libsodium = class sealed

  private

    class function GetEd25519Instance(): IEd25519; static;
  public
    /// <summary>
    /// Generate keypair from a random 32-byte seed (libsodium-style).
    /// SecretKey = Seed || PublicKey.
    /// </summary>
    class function GenerateKeyPair(const Random: ISecureRandom)
      : TEd25519KeyPair; overload; static;

    /// <summary>
    /// Generate keypair from a provided 32-byte seed (libsodium-style).
    /// SecretKey = Seed || PublicKey.
    /// </summary>
    class function GenerateKeyPair(const Seed32: TBytes): TEd25519KeyPair;
      overload; static;

    /// <summary>
    /// Sign a message using libsodium-style SecretKey (64 bytes: Seed||PublicKey).
    /// Returns a 64-byte signature.
    /// </summary>
    class function Sign(const SecretKey64, MessageBytes: TBytes)
      : TBytes; static;

    /// <summary>
    /// Verify a 64-byte signature using a 32-byte Ed25519 public key.
    /// </summary>
    class function Verify(const PublicKey32, MessageBytes, Signature64: TBytes)
      : Boolean; static;

    /// <summary>
    /// Expand a 32-byte seed using SHA-512 and clamp per RFC8032.
    /// First 32 bytes = clamped scalar; next 32 bytes = prefix.
    /// </summary>
    class function GetExpandedPrivateKeyFromSeed(const Seed32: TBytes)
      : TBytes; static;
  end;

  {
    Endianness & sign:
    - Ed25519 public key bytes (encoded Y) are 32-byte little-endian with the MSB of the last
    byte used for the sign of X. We:
    * convert to positive big-endian magnitude,
    * mask with Un = 2^255 - 1 to clear the sign bit,
    * recover X and check curve equation.
  }
type
  /// <summary>
  /// Helper methods for ED25519 checks
  /// Edwards-curve Digital Signature Algorithm (EdDSA)
  /// https://en.wikipedia.org/wiki/EdDSA#Ed25519
  /// </summary>
  TEd25519Utils = class sealed
  strict private
    // Big integer constants as CLASS VARs; initialized in class constructor
    class var FQ, FQm2, FQp3, FD, FI, FUn, FTwo, FEight: TBigInteger;

    class function ExpMod(const number, exponent, modulo: TBigInteger)
      : TBigInteger; static;
    class function Inv(const x: TBigInteger): TBigInteger; static;
    class function RecoverX(const y: TBigInteger): TBigInteger; static;
    class function IsOnCurveXY(const x, y: TBigInteger): Boolean; static;
    class function BigIntFromLEUnsigned(const Key: TBytes): TBigInteger; static;
    class function IsEven(const x: TBigInteger): Boolean; static;
    // class function ModNonNeg(const num, modulo: TBigInteger): TBigInteger; static;
  public
    /// <summary>
    /// Checks whether the PublicKey bytes are 'On The Curve'
    /// </summary>
    /// <param name="Key">PublicKey as byte array (32 bytes, little-endian y with x-sign bit in MSB).</param>
    /// <returns>True if point lies on the ed25519 curve.</returns>
    class function IsOnCurve(const Key: TBytes): Boolean; static;

    /// <summary>Static constructor initializes big integer constants.</summary>
    class constructor Create;
  end;

implementation

uses
  SlpCryptoUtils;

{ TEd25519Libsodium }

class function TEd25519Libsodium.GetEd25519Instance: IEd25519;
begin
  Result := TEd25519.Create();
end;

class function TEd25519Libsodium.GenerateKeyPair(const Random: ISecureRandom)
  : TEd25519KeyPair;
var
  Seed: TBytes;
begin
  SetLength(Seed, 32);
  if Length(Seed) > 0 then
    Random.NextBytes(Seed);

  Result := GenerateKeyPair(Seed);
end;

class function TEd25519Libsodium.GenerateKeyPair(const Seed32: TBytes)
  : TEd25519KeyPair;
var
  Priv: IEd25519PrivateKeyParameters;
  Pub: IEd25519PublicKeyParameters;
  Pk: TBytes;
begin
  if Length(Seed32) <> 32 then
    raise EArgumentException.Create('Seed must be exactly 32 bytes');

  // Private key from seed
  Priv := TEd25519PrivateKeyParameters.Create(GetEd25519Instance(), Seed32, 0);

  // Derive public key (32 bytes)
  Pub := Priv.GeneratePublicKey;
  Pk := Pub.GetEncoded; // 32

  // SecretKey = Seed || PublicKey

  SetLength(Result.SecretKey, 64);
  if Length(Seed32) > 0 then
    TArrayUtils.Copy<Byte>(Seed32, 0, Result.SecretKey, 0, 32);

  if Length(Pk) > 0 then
    TArrayUtils.Copy<Byte>(Pk, 0, Result.SecretKey, 32, 32);

  Result.PublicKey := Pk;
end;

class function TEd25519Libsodium.Sign(const SecretKey64,
  MessageBytes: TBytes): TBytes;
var
  Seed: TBytes;
  Priv: IEd25519PrivateKeyParameters;
  Signer: ISigner;
begin
  if Length(SecretKey64) <> 64 then
    raise EArgumentException.Create
      ('SecretKey must be 64 bytes [Seed||PublicKey]');

  // First 32 bytes are the seed
  SetLength(Seed, 32);
  TArrayUtils.Copy<Byte>(SecretKey64, 0, Seed, 0, 32);

  // Private key from seed
  Priv := TEd25519PrivateKeyParameters.Create(GetEd25519Instance(), Seed, 0);

  // Sign
  Signer := TEd25519Signer.Create(GetEd25519Instance()) as IEd25519Signer;
  Signer.Init(True, Priv);
  if Length(MessageBytes) > 0 then
    Signer.BlockUpdate(MessageBytes, 0, Length(MessageBytes));

  Result := Signer.GenerateSignature; // 64 bytes
end;

class function TEd25519Libsodium.Verify(const PublicKey32, MessageBytes,
  Signature64: TBytes): Boolean;
var
  Pub: IEd25519PublicKeyParameters;
  Verifier: ISigner;
begin
  if Length(PublicKey32) <> 32 then
    raise EArgumentException.Create('PublicKey must be 32 bytes');
  if Length(Signature64) <> 64 then
    raise EArgumentException.Create('Signature must be 64 bytes');

  Pub := TEd25519PublicKeyParameters.Create(PublicKey32, 0);

  Verifier := TEd25519Signer.Create(GetEd25519Instance()) as IEd25519Signer;
  Verifier.Init(False, Pub);
  if Length(MessageBytes) > 0 then
    Verifier.BlockUpdate(MessageBytes, 0, Length(MessageBytes));

  Result := Verifier.VerifySignature(Signature64);
end;

class function TEd25519Libsodium.GetExpandedPrivateKeyFromSeed
  (const Seed32: TBytes): TBytes;
begin
  if Length(Seed32) <> 32 then
    raise EArgumentException.Create('Seed must be 32 bytes');

  Result := TSHA512.HashData(Seed32); // 64 bytes

  if Length(Result) <> 64 then
    raise EInvalidOpException.Create('SHA-512 did not return 64 bytes');

  // RFC8032 clamping on Result[0..31]
  Result[0] := Result[0] and $F8; // &= 248
  Result[31] := Result[31] and $3F; // &= 63
  Result[31] := Result[31] or $40; // |= 64
end;

{ TEd25519Utils }

class constructor TEd25519Utils.Create;
  function BI(const S: string): TBigInteger; inline;
  begin
    Result := TBigInteger.Create(S);
  end;

begin
  // Prime field order q
  FQ := BI('57896044618658097711785492504343953926634992332820282019728792003956564819949');
  // q - 2
  FQm2 := BI(
    '57896044618658097711785492504343953926634992332820282019728792003956564819947');
  // q + 3
  FQp3 := BI(
    '57896044618658097711785492504343953926634992332820282019728792003956564819952');
  // Edwards curve constant d (for ed25519)
  FD := BI('-4513249062541557337682894930092624173785641285191125241628941591882900924598840740');
  // sqrt(-1) mod q
  FI := BI('19681161376707505956807079304988542015446066515923890162744021073123829784752');
  // 2^255 - 1  (mask to clear x-sign bit in encoded Y)
  FUn := BI('57896044618658097711785492504343953926634992332820282019728792003956564819967');
  // small ints
  FTwo := TBigInteger.ValueOf(2);
  FEight := TBigInteger.ValueOf(8);
end;

class function TEd25519Utils.ExpMod(const number, exponent, modulo: TBigInteger)
  : TBigInteger;
begin
  // Efficient modular exponentiation
  Result := number.ModPow(exponent, modulo);
end;

class function TEd25519Utils.Inv(const x: TBigInteger): TBigInteger;
begin
  // Fermat: x^(q-2) mod q
  Result := ExpMod(x, FQm2, FQ);
end;

class function TEd25519Utils.IsEven(const x: TBigInteger): Boolean;
begin
  // true if LSB == 0
  Result := not x.TestBit(0);
end;

class function TEd25519Utils.RecoverX(const y: TBigInteger): TBigInteger;
var
  y2, xx, x, chk: TBigInteger;
begin
  // xx = (y^2 - 1) * inv(d*y^2 + 1)  (mod q)
  y2 := y.Multiply(y);
  xx := y2.Subtract(TBigInteger.One);
  xx := xx.Multiply(Inv(FD.Multiply(y2).Add(TBigInteger.One)));
  xx := xx.&Mod(FQ);

  // x = xx^((q+3)/8) mod q
  x := xx.ModPow(FQp3.Divide(FEight), FQ);

  // if (x^2 - xx) mod q != 0 then x = (x * i) mod q
  chk := x.Multiply(x).Subtract(xx).&Mod(FQ);
  if not chk.Equals(TBigInteger.Zero) then
    x := x.Multiply(FI).&Mod(FQ);

  // choose the even representative
  if not IsEven(x) then
    x := FQ.Subtract(x);

  Result := x;
end;

class function TEd25519Utils.IsOnCurveXY(const x, y: TBigInteger): Boolean;
var
  xx, yy, dxxyy: TBigInteger;
begin
  // yy - xx - d*yy*xx - 1 == 0 (mod q)
  xx := x.Multiply(x);
  yy := y.Multiply(y);
  dxxyy := FD.Multiply(yy).Multiply(xx);

  Result := yy.Subtract(xx).Subtract(dxxyy).Subtract(TBigInteger.One).&Mod(FQ)
    .Equals(TBigInteger.Zero);
end;

class function TEd25519Utils.BigIntFromLEUnsigned(const Key: TBytes)
  : TBigInteger;
var
  be: TBytes;
  i, L: Integer;
begin
  // Little-endian unsigned -> big-endian magnitude -> positive BigInteger
  L := Length(Key);
  SetLength(be, L);

  for i := 0 to L - 1 do
    be[i] := Key[L - 1 - i];
  // Use ctor (sign, magnitude) to force positive
  Result := TBigInteger.Create(1, be);
end;

class function TEd25519Utils.IsOnCurve(const Key: TBytes): Boolean;
var
  y, x: TBigInteger;
begin
  // y = (LE 32 bytes) & (2^255 - 1)
  y := BigIntFromLEUnsigned(Key).&And(FUn);
  x := RecoverX(y);
  Result := IsOnCurveXY(x, y);
end;

end.
