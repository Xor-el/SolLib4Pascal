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

unit SlpDefaultCryptoProviders;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  ClpBits,
  ClpBigInteger,
  ClpIDigest,
  ClpDigestUtilities,
  ClpIMac,
  ClpHMac,
  ClpIKeyParameter,
  ClpKeyParameter,
  ClpIParametersWithIV,
  ClpParametersWithIV,
  ClpIPkcs5S2ParametersGenerator,
  ClpPkcs5S2ParametersGenerator,
  ClpICipherParameters,
  ClpIBufferedCipher,
  ClpCipherUtilities,
  ClpParameterUtilities,
  ClpISecureRandom,
  ClpSecureRandom,
  ClpIEd25519,
  ClpEd25519,
  ClpISigner,
  ClpIEd25519Signer,
  ClpEd25519Signer,
  ClpIEd25519PublicKeyParameters,
  ClpEd25519PublicKeyParameters,
  ClpIEd25519PrivateKeyParameters,
  ClpEd25519PrivateKeyParameters,
  SlpArrayUtils,
  SlpCryptoProviders;

type
  /// <summary>
  /// Default hash provider using CryptoLib4Pascal.
  /// </summary>
  TDefaultHashProvider = class(TInterfacedObject, IHashProvider)
  public
    function SHA256(const Data: TBytes): TBytes;
    function SHA512(const Data: TBytes): TBytes;
    function Keccak256(const Data: TBytes): TBytes;
  end;

  /// <summary>
  /// Default HMAC provider using CryptoLib4Pascal.
  /// </summary>
  TDefaultHmacProvider = class(TInterfacedObject, IHmacProvider)
  public
    function HmacSHA256(const Key, Data: TBytes): TBytes;
    function HmacSHA512(const Key, Data: TBytes): TBytes;
  end;

  /// <summary>
  /// Default KDF provider using CryptoLib4Pascal.
  /// </summary>
  TDefaultKdfProvider = class(TInterfacedObject, IKdfProvider)
  public
    function Pbkdf2SHA256(const Password, Salt: TBytes; Iterations, DKLen: Integer): TBytes;
    function Pbkdf2SHA512(const Password, Salt: TBytes; Iterations, DKLen: Integer): TBytes;
    function Scrypt(const Password, Salt: TBytes; N, R, P, DKLen: Integer): TBytes;
  end;

  /// <summary>
  /// Default cipher provider using CryptoLib4Pascal.
  /// </summary>
  TDefaultCipherProvider = class(TInterfacedObject, ICipherProvider)
  private
    procedure ValidateAesKeyIv(const Key, IV: TBytes);
  public
    function AesCtrEncrypt(const Key, IV, Data: TBytes): TBytes;
    function AesCtrDecrypt(const Key, IV, Data: TBytes): TBytes;
  end;

  /// <summary>
  /// Default random provider using CryptoLib4Pascal.
  /// </summary>
  TDefaultRandomProvider = class(TInterfacedObject, IRandomProvider)
  strict private
    class var FSecureRandom: ISecureRandom;
    class constructor Create;
  public
    function RandomBytes(Size: Integer): TBytes;
    procedure FillRandom(const Output: TBytes);
  end;

  /// <summary>
  /// Default Ed25519 provider using CryptoLib4Pascal.
  /// </summary>
  TDefaultEd25519Provider = class(TInterfacedObject, IEd25519Provider)
  strict private
    // Curve constants for IsOnCurve
    class var FQ, FQm2, FQp3, FD, FI, FUn, FTwo, FEight: TBigInteger;
    class constructor Create;
    class function GetEd25519Instance: IEd25519; static;
    // SHA-512(seed) with RFC8032 clamping
    // - First 32 bytes = clamped scalar
    // - Next 32 bytes  = prefix
    class function GetExpandedPrivateKeyFromSeed(const Seed32: TBytes): TBytes; static;
    // IsOnCurve helpers
    class function ExpMod(const number, exponent, modulo: TBigInteger): TBigInteger; static;
    class function Inv(const x: TBigInteger): TBigInteger; static;
    class function IsEven(const x: TBigInteger): Boolean; static;
    class function RecoverX(const y: TBigInteger): TBigInteger; static;
    class function IsOnCurveXY(const x, y: TBigInteger): Boolean; static;
    class function BigIntFromLEUnsigned(const Key: TBytes): TBigInteger; static;
  public
    function GenerateKeyPair(const Seed32: TBytes): TEd25519KeyPair;
    function Sign(const SecretKey64, Message: TBytes): TBytes;
    function Verify(const PublicKey32, Message, Signature64: TBytes): Boolean;
    function IsOnCurve(const PublicKey32: TBytes): Boolean;
  end;

  /// <summary>
  /// Scrypt key derivation implementation.
  /// </summary>
  TScryptImpl = class sealed
  strict private
    class function SingleIterationPbkdf2(const P, S: TBytes; DKLen: Integer): TBytes; static;
    class procedure BulkCopy(Dst, Src: Pointer; Len: NativeInt); static;
    class procedure BulkXor(Dst, Src: Pointer; Len: NativeInt); static;
    class procedure Encode32(P: PByte; X: Cardinal); static;
    class function Decode32(P: PByte): Cardinal; static;
    class function RotateLeft32(A: Cardinal; B: Integer): Cardinal; static; inline;
    class procedure Salsa208(B: PCardinal); static;
    class procedure BlockMix(Bin, Bout, X: PCardinal; RoundsR: Integer); static;
    class function Integerify(B: PCardinal; RoundsR: Integer): UInt64; static;
    class procedure SMix(B: PByte; RoundsR, N: Integer; V, XY: PCardinal); static;
  public
    class function DeriveKey(const Password, Salt: TBytes;
      N, RoundsR, PCount, DKLen: Integer): TBytes; static;
  end;

implementation

{ TDefaultHashProvider }

function TDefaultHashProvider.SHA256(const Data: TBytes): TBytes;
var
  D: IDigest;
begin
  D := TDigestUtilities.GetDigest('SHA-256');
  if Length(Data) > 0 then
    D.BlockUpdate(Data, 0, Length(Data));
  SetLength(Result, D.GetDigestSize);
  D.DoFinal(Result, 0);
end;

function TDefaultHashProvider.SHA512(const Data: TBytes): TBytes;
var
  D: IDigest;
begin
  D := TDigestUtilities.GetDigest('SHA-512');
  if Length(Data) > 0 then
    D.BlockUpdate(Data, 0, Length(Data));
  SetLength(Result, D.GetDigestSize);
  D.DoFinal(Result, 0);
end;

function TDefaultHashProvider.Keccak256(const Data: TBytes): TBytes;
var
  D: IDigest;
begin
  D := TDigestUtilities.GetDigest('KECCAK-256');
  if Length(Data) > 0 then
    D.BlockUpdate(Data, 0, Length(Data));
  SetLength(Result, D.GetDigestSize);
  D.DoFinal(Result, 0);
end;

{ TDefaultHmacProvider }

function TDefaultHmacProvider.HmacSHA256(const Key, Data: TBytes): TBytes;
var
  D: IDigest;
  H: IMac;
  KP: IKeyParameter;
begin
  D := TDigestUtilities.GetDigest('SHA-256');
  H := THMac.Create(D);
  KP := TKeyParameter.Create(Key);
  H.Init(KP);
  if Length(Data) > 0 then
    H.BlockUpdate(Data, 0, Length(Data));
  SetLength(Result, H.GetMacSize);
  H.DoFinal(Result, 0);
end;

function TDefaultHmacProvider.HmacSHA512(const Key, Data: TBytes): TBytes;
var
  D: IDigest;
  H: IMac;
  KP: IKeyParameter;
begin
  D := TDigestUtilities.GetDigest('SHA-512');
  H := THMac.Create(D);
  KP := TKeyParameter.Create(Key);
  H.Init(KP);
  if Length(Data) > 0 then
    H.BlockUpdate(Data, 0, Length(Data));
  SetLength(Result, H.GetMacSize);
  H.DoFinal(Result, 0);
end;

{ TDefaultKdfProvider }

function TDefaultKdfProvider.Pbkdf2SHA256(const Password, Salt: TBytes;
  Iterations, DKLen: Integer): TBytes;
var
  Gen: IPkcs5S2ParametersGenerator;
  Params: ICipherParameters;
  KeyParam: IKeyParameter;
begin
  Gen := TPkcs5S2ParametersGenerator.Create(TDigestUtilities.GetDigest('SHA-256'));
  Gen.Init(Password, Salt, Iterations);
  Params := Gen.GenerateDerivedMacParameters(DKLen * 8);
  KeyParam := Params as IKeyParameter;
  Result := KeyParam.GetKey;
end;

function TDefaultKdfProvider.Pbkdf2SHA512(const Password, Salt: TBytes;
  Iterations, DKLen: Integer): TBytes;
var
  Gen: IPkcs5S2ParametersGenerator;
  Params: ICipherParameters;
  KeyParam: IKeyParameter;
begin
  Gen := TPkcs5S2ParametersGenerator.Create(TDigestUtilities.GetDigest('SHA-512'));
  Gen.Init(Password, Salt, Iterations);
  Params := Gen.GenerateDerivedMacParameters(DKLen * 8);
  KeyParam := Params as IKeyParameter;
  Result := KeyParam.GetKey;
end;

function TDefaultKdfProvider.Scrypt(const Password, Salt: TBytes;
  N, R, P, DKLen: Integer): TBytes;
begin
  Result := TScryptImpl.DeriveKey(Password, Salt, N, R, P, DKLen);
end;

{ TDefaultCipherProvider }

procedure TDefaultCipherProvider.ValidateAesKeyIv(const Key, IV: TBytes);
begin
  case Length(Key) of
    16, 24, 32: ; // ok
  else
    raise EArgumentException.Create('AES key must be 16, 24, or 32 bytes.');
  end;

  if Length(IV) <> 16 then
    raise EArgumentException.Create('AES-CTR IV/nonce must be 16 bytes.');
end;

function TDefaultCipherProvider.AesCtrEncrypt(const Key, IV, Data: TBytes): TBytes;
var
  Cipher: IBufferedCipher;
  KeyParams: IKeyParameter;
  KeyParamsWithIV: IParametersWithIV;
begin
  ValidateAesKeyIv(Key, IV);
  KeyParams := TParameterUtilities.CreateKeyParameter('AES', Key);
  KeyParamsWithIV := TParametersWithIV.Create(KeyParams, IV);
  Cipher := TCipherUtilities.GetCipher('AES/CTR/NoPadding');
  Cipher.Init(True, KeyParamsWithIV);
  Result := Cipher.DoFinal(Data);
end;

function TDefaultCipherProvider.AesCtrDecrypt(const Key, IV, Data: TBytes): TBytes;
var
  Cipher: IBufferedCipher;
  KeyParams: IKeyParameter;
  KeyParamsWithIV: IParametersWithIV;
begin
  ValidateAesKeyIv(Key, IV);
  KeyParams := TParameterUtilities.CreateKeyParameter('AES', Key);
  KeyParamsWithIV := TParametersWithIV.Create(KeyParams, IV);
  Cipher := TCipherUtilities.GetCipher('AES/CTR/NoPadding');
  Cipher.Init(False, KeyParamsWithIV);
  Result := Cipher.DoFinal(Data);
end;

{ TDefaultRandomProvider }

class constructor TDefaultRandomProvider.Create;
begin
  FSecureRandom := TSecureRandom.Create;
end;

function TDefaultRandomProvider.RandomBytes(Size: Integer): TBytes;
begin
  if Size < 0 then
    raise EArgumentException.Create('Size must be >= 0');
  SetLength(Result, Size);
  if Size > 0 then
    FillRandom(Result);
end;

procedure TDefaultRandomProvider.FillRandom(const Output: TBytes);
begin
  if Length(Output) > 0 then
    FSecureRandom.NextBytes(Output);
end;

{ TDefaultEd25519Provider }

class function TDefaultEd25519Provider.GetEd25519Instance: IEd25519;
begin
  Result := TEd25519.Create;
end;

function TDefaultEd25519Provider.GenerateKeyPair(const Seed32: TBytes): TEd25519KeyPair;
var
  Priv: IEd25519PrivateKeyParameters;
  Pub: IEd25519PublicKeyParameters;
  Pk: TBytes;
begin
  if Length(Seed32) <> 32 then
    raise EArgumentException.Create('Seed must be exactly 32 bytes');

  // Private key from seed
  Priv := TEd25519PrivateKeyParameters.Create(GetEd25519Instance, Seed32, 0);

  // Derive public key (32 bytes)
  Pub := Priv.GeneratePublicKey;
  Pk := Pub.GetEncoded;

  // SecretKey = Seed || PublicKey
  SetLength(Result.SecretKey, 64);
  if Length(Seed32) > 0 then
    TArrayUtils.Copy<Byte>(Seed32, 0, Result.SecretKey, 0, 32);
  if Length(Pk) > 0 then
    TArrayUtils.Copy<Byte>(Pk, 0, Result.SecretKey, 32, 32);

  Result.PublicKey := Pk;
end;

function TDefaultEd25519Provider.Sign(const SecretKey64, Message: TBytes): TBytes;
var
  Seed: TBytes;
  Priv: IEd25519PrivateKeyParameters;
  Signer: ISigner;
begin
  if Length(SecretKey64) <> 64 then
    raise EArgumentException.Create('SecretKey must be 64 bytes [Seed||PublicKey]');

  // First 32 bytes are the seed
  SetLength(Seed, 32);
  TArrayUtils.Copy<Byte>(SecretKey64, 0, Seed, 0, 32);

  // Private key from seed
  Priv := TEd25519PrivateKeyParameters.Create(GetEd25519Instance, Seed, 0);

  // Sign
  Signer := TEd25519Signer.Create(GetEd25519Instance) as IEd25519Signer;
  Signer.Init(True, Priv);
  if Length(Message) > 0 then
    Signer.BlockUpdate(Message, 0, Length(Message));

  Result := Signer.GenerateSignature; // 64 bytes
end;

function TDefaultEd25519Provider.Verify(const PublicKey32, Message, Signature64: TBytes): Boolean;
var
  Pub: IEd25519PublicKeyParameters;
  Verifier: ISigner;
begin
  if Length(PublicKey32) <> 32 then
    raise EArgumentException.Create('PublicKey must be 32 bytes');
  if Length(Signature64) <> 64 then
    raise EArgumentException.Create('Signature must be 64 bytes');

  Pub := TEd25519PublicKeyParameters.Create(PublicKey32, 0);

  Verifier := TEd25519Signer.Create(GetEd25519Instance) as IEd25519Signer;
  Verifier.Init(False, Pub);
  if Length(Message) > 0 then
    Verifier.BlockUpdate(Message, 0, Length(Message));

  Result := Verifier.VerifySignature(Signature64);
end;

class constructor TDefaultEd25519Provider.Create;
  function BI(const S: string): TBigInteger; inline;
  begin
    Result := TBigInteger.Create(S);
  end;
begin
  // Prime field order q
  FQ := BI('57896044618658097711785492504343953926634992332820282019728792003956564819949');
  // q - 2
  FQm2 := BI('57896044618658097711785492504343953926634992332820282019728792003956564819947');
  // q + 3
  FQp3 := BI('57896044618658097711785492504343953926634992332820282019728792003956564819952');
  // Edwards curve constant d (for ed25519)
  FD := BI('-4513249062541557337682894930092624173785641285191125241628941591882900924598840740');
  // sqrt(-1) mod q
  FI := BI('19681161376707505956807079304988542015446066515923890162744021073123829784752');
  // 2^255 - 1 (mask to clear x-sign bit in encoded Y)
  FUn := BI('57896044618658097711785492504343953926634992332820282019728792003956564819967');
  // small ints
  FTwo := TBigInteger.ValueOf(2);
  FEight := TBigInteger.ValueOf(8);
end;

class function TDefaultEd25519Provider.GetExpandedPrivateKeyFromSeed(const Seed32: TBytes): TBytes;
var
  D: IDigest;
begin
  if Length(Seed32) <> 32 then
    raise EArgumentException.Create('Seed must be 32 bytes');

  // SHA-512 of seed
  D := TDigestUtilities.GetDigest('SHA-512');
  D.BlockUpdate(Seed32, 0, 32);
  SetLength(Result, D.GetDigestSize);
  D.DoFinal(Result, 0);

  if Length(Result) <> 64 then
    raise EInvalidOpException.Create('SHA-512 did not return 64 bytes');

  // RFC8032 clamping on Result[0..31]
  Result[0] := Result[0] and $F8;
  Result[31] := Result[31] and $3F;
  Result[31] := Result[31] or $40;
end;

class function TDefaultEd25519Provider.ExpMod(const number, exponent, modulo: TBigInteger): TBigInteger;
begin
  Result := number.ModPow(exponent, modulo);
end;

class function TDefaultEd25519Provider.Inv(const x: TBigInteger): TBigInteger;
begin
  // Fermat: x^(q-2) mod q
  Result := ExpMod(x, FQm2, FQ);
end;

class function TDefaultEd25519Provider.IsEven(const x: TBigInteger): Boolean;
begin
  Result := not x.TestBit(0);
end;

class function TDefaultEd25519Provider.RecoverX(const y: TBigInteger): TBigInteger;
var
  y2, xx, x, chk: TBigInteger;
begin
  // xx = (y^2 - 1) * inv(d*y^2 + 1) (mod q)
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

class function TDefaultEd25519Provider.IsOnCurveXY(const x, y: TBigInteger): Boolean;
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

class function TDefaultEd25519Provider.BigIntFromLEUnsigned(const Key: TBytes): TBigInteger;
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

function TDefaultEd25519Provider.IsOnCurve(const PublicKey32: TBytes): Boolean;
var
  y, x: TBigInteger;
begin
  if Length(PublicKey32) <> 32 then
    raise EArgumentException.Create('PublicKey must be 32 bytes');

  // y = (LE 32 bytes) & (2^255 - 1)
  y := BigIntFromLEUnsigned(PublicKey32).&And(FUn);
  x := RecoverX(y);
  Result := IsOnCurveXY(x, y);
end;

{ TScryptImpl }

class function TScryptImpl.SingleIterationPbkdf2(const P, S: TBytes; DKLen: Integer): TBytes;
var
  Gen: IPkcs5S2ParametersGenerator;
  Params: ICipherParameters;
  KeyParam: IKeyParameter;
begin
  Gen := TPkcs5S2ParametersGenerator.Create(TDigestUtilities.GetDigest('SHA-256'));
  Gen.Init(P, S, 1);
  Params := Gen.GenerateDerivedMacParameters(DKLen * 8);
  KeyParam := Params as IKeyParameter;
  Result := KeyParam.GetKey;
end;

class procedure TScryptImpl.BulkCopy(Dst, Src: Pointer; Len: NativeInt);
begin
  Move(Src^, Dst^, Len);
end;

class procedure TScryptImpl.BulkXor(Dst, Src: Pointer; Len: NativeInt);
var
  d, s: PByte;
  L: NativeInt;
begin
  d := Dst; s := Src; L := Len;
  while L >= 8 do
  begin
    PUInt64(d)^ := PUInt64(d)^ xor PUInt64(s)^;
    Inc(d, 8); Inc(s, 8); Dec(L, 8);
  end;
  if L >= 4 then
  begin
    PCardinal(d)^ := PCardinal(d)^ xor PCardinal(s)^;
    Inc(d, 4); Inc(s, 4); Dec(L, 4);
  end;
  if L >= 2 then
  begin
    PWord(d)^ := PWord(d)^ xor PWord(s)^;
    Inc(d, 2); Inc(s, 2); Dec(L, 2);
  end;
  if L >= 1 then
    d^ := d^ xor s^;
end;

class procedure TScryptImpl.Encode32(P: PByte; X: Cardinal);
begin
  P[0] := Byte(X and $FF);
  P[1] := Byte((X shr 8) and $FF);
  P[2] := Byte((X shr 16) and $FF);
  P[3] := Byte((X shr 24) and $FF);
end;

class function TScryptImpl.Decode32(P: PByte): Cardinal;
begin
  Result :=
    Cardinal(P[0]) or
    (Cardinal(P[1]) shl 8) or
    (Cardinal(P[2]) shl 16) or
    (Cardinal(P[3]) shl 24);
end;

class function TScryptImpl.RotateLeft32(A: Cardinal; B: Integer): Cardinal;
begin
  Result := TBits.RotateLeft32(A, B);
end;

class procedure TScryptImpl.Salsa208(B: PCardinal);
var
  x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15: Cardinal;
  i: Integer;
begin
  x0 := B[0];  x1 := B[1];  x2 := B[2];  x3 := B[3];
  x4 := B[4];  x5 := B[5];  x6 := B[6];  x7 := B[7];
  x8 := B[8];  x9 := B[9];  x10 := B[10]; x11 := B[11];
  x12 := B[12]; x13 := B[13]; x14 := B[14]; x15 := B[15];

  for i := 0 to 3 do
  begin
    // Operate on columns
    x4  := x4  xor RotateLeft32(x0 + x12, 7);   x8  := x8  xor RotateLeft32(x4 + x0, 9);
    x12 := x12 xor RotateLeft32(x8 + x4, 13);   x0  := x0  xor RotateLeft32(x12 + x8, 18);

    x9  := x9  xor RotateLeft32(x5 + x1, 7);    x13 := x13 xor RotateLeft32(x9 + x5, 9);
    x1  := x1  xor RotateLeft32(x13 + x9, 13);  x5  := x5  xor RotateLeft32(x1 + x13, 18);

    x14 := x14 xor RotateLeft32(x10 + x6, 7);   x2  := x2  xor RotateLeft32(x14 + x10, 9);
    x6  := x6  xor RotateLeft32(x2 + x14, 13);  x10 := x10 xor RotateLeft32(x6 + x2, 18);

    x3  := x3  xor RotateLeft32(x15 + x11, 7);  x7  := x7  xor RotateLeft32(x3 + x15, 9);
    x11 := x11 xor RotateLeft32(x7 + x3, 13);   x15 := x15 xor RotateLeft32(x11 + x7, 18);

    // Operate on rows
    x1  := x1  xor RotateLeft32(x0 + x3, 7);    x2  := x2  xor RotateLeft32(x1 + x0, 9);
    x3  := x3  xor RotateLeft32(x2 + x1, 13);   x0  := x0  xor RotateLeft32(x3 + x2, 18);

    x6  := x6  xor RotateLeft32(x5 + x4, 7);    x7  := x7  xor RotateLeft32(x6 + x5, 9);
    x4  := x4  xor RotateLeft32(x7 + x6, 13);   x5  := x5  xor RotateLeft32(x4 + x7, 18);

    x11 := x11 xor RotateLeft32(x10 + x9, 7);   x8  := x8  xor RotateLeft32(x11 + x10, 9);
    x9  := x9  xor RotateLeft32(x8 + x11, 13);  x10 := x10 xor RotateLeft32(x9 + x8, 18);

    x12 := x12 xor RotateLeft32(x15 + x14, 7);  x13 := x13 xor RotateLeft32(x12 + x15, 9);
    x14 := x14 xor RotateLeft32(x13 + x12, 13); x15 := x15 xor RotateLeft32(x14 + x13, 18);
  end;

  B[0]  := B[0]  + x0;   B[1]  := B[1]  + x1;   B[2]  := B[2]  + x2;   B[3]  := B[3]  + x3;
  B[4]  := B[4]  + x4;   B[5]  := B[5]  + x5;   B[6]  := B[6]  + x6;   B[7]  := B[7]  + x7;
  B[8]  := B[8]  + x8;   B[9]  := B[9]  + x9;   B[10] := B[10] + x10;  B[11] := B[11] + x11;
  B[12] := B[12] + x12;  B[13] := B[13] + x13;  B[14] := B[14] + x14;  B[15] := B[15] + x15;
end;

class procedure TScryptImpl.BlockMix(Bin, Bout, X: PCardinal; RoundsR: Integer);
var
  i: Integer;
begin
  // X <- B_{2r-1}
  BulkCopy(X, @Bin[(2 * RoundsR - 1) * 16], 64);

  i := 0;
  while i <= (2 * RoundsR - 1) do
  begin
    // even half (i even)
    BulkXor(X, @Bin[i * 16], 64);
    Salsa208(X);
    // Y_even -> Bout[(i div 2) * 16]
    BulkCopy(@Bout[(i div 2) * 16], X, 64);

    Inc(i);
    if i >= 2 * RoundsR then Break;

    // odd half (i odd, i is the next block)
    BulkXor(X, @Bin[i * 16], 64);
    Salsa208(X);
    // Y_odd -> Bout[r*16 + (i div 2) * 16]
    BulkCopy(@Bout[RoundsR * 16 + (i div 2) * 16], X, 64);

    Inc(i);
  end;
end;

class function TScryptImpl.Integerify(B: PCardinal; RoundsR: Integer): UInt64;
var
  X: PCardinal;
begin
  // X points to the last 64-byte chunk (B_{2r-1})
  X := PCardinal(PByte(B) + (2 * RoundsR - 1) * 64);
  Result := (UInt64(X[1]) shl 32) or UInt64(X[0]);
end;

class procedure TScryptImpl.SMix(B: PByte; RoundsR, N: Integer; V, XY: PCardinal);
var
  X, Y, Z: PCardinal;
  i, k: Integer;
  j, idx: Integer;
begin
  X := XY;
  Y := @XY[32 * RoundsR];
  Z := @XY[64 * RoundsR];

  // 1: X <- B
  for k := 0 to (32 * RoundsR - 1) do
    X[k] := Decode32(@B[4 * k]);

  // 2: for i = 0..N-1
  i := 0;
  while i < N do
  begin
    BulkCopy(@V[i * (32 * RoundsR)], X, 128 * RoundsR);
    BlockMix(X, Y, Z, RoundsR);

    Inc(i);
    BulkCopy(@V[i * (32 * RoundsR)], Y, 128 * RoundsR);
    BlockMix(Y, X, Z, RoundsR);

    Inc(i);
  end;

  // 6: for i = 0..N-1
  i := 0;
  while i < N do
  begin
    j := Integer(Integerify(X, RoundsR) and UInt64(N - 1));
    idx := j * (32 * RoundsR);
    BulkXor(X, @V[idx], 128 * RoundsR);
    BlockMix(X, Y, Z, RoundsR);

    j := Integer(Integerify(Y, RoundsR) and UInt64(N - 1));
    idx := j * (32 * RoundsR);
    BulkXor(Y, @V[idx], 128 * RoundsR);
    BlockMix(Y, X, Z, RoundsR);

    Inc(i, 2);
  end;

  // 10: B' <- X
  for k := 0 to (32 * RoundsR - 1) do
    Encode32(@B[4 * k], X[k]);
end;

class function TScryptImpl.DeriveKey(const Password, Salt: TBytes;
  N, RoundsR, PCount, DKLen: Integer): TBytes;
var
  BA: TBytes;
  XY: TArray<Cardinal>;
  V: TArray<Cardinal>;
  i, BlockLen: Integer;
  Bi: PByte;
begin
  if (N <= 1) or ((N and (N - 1)) <> 0) then
    raise EArgumentException.Create('N must be > 1 and a power of 2');

  if (RoundsR <= 0) or (PCount <= 0) then
    raise EArgumentException.Create('r and p must be > 0');

  // 1: B <- PBKDF2(P, S, 1, p*128*r)
  BlockLen := 128 * RoundsR;
  BA := SingleIterationPbkdf2(Password, Salt, PCount * BlockLen);

  // temp buffers
  SetLength(XY, 32 * RoundsR * 2 + 16);
  SetLength(V, 32 * RoundsR * N);

  // 2: for i = 0..p-1: SMix(B_i, r, N)
  for i := 0 to PCount - 1 do
  begin
    Bi := @BA[i * BlockLen];
    SMix(Bi, RoundsR, N, @V[0], @XY[0]);
  end;

  // 5: DK <- PBKDF2(P, B, 1, dkLen)
  Result := SingleIterationPbkdf2(Password, BA, DKLen);
end;

end.
