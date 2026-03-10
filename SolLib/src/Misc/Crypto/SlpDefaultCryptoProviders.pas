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
  /// Default Hash provider using CryptoLib4Pascal.
  /// </summary>
  TDefaultHashProvider = class(TInterfacedObject, IHashProvider)
  public
    function SHA256(const AData: TBytes): TBytes;
    function SHA512(const AData: TBytes): TBytes;
    function Keccak256(const AData: TBytes): TBytes;
  end;

  /// <summary>
  /// Default HMAC provider using CryptoLib4Pascal.
  /// </summary>
  TDefaultHmacProvider = class(TInterfacedObject, IHmacProvider)
  public
    function HmacSHA256(const AKey, AData: TBytes): TBytes;
    function HmacSHA512(const AKey, AData: TBytes): TBytes;
  end;

  /// <summary>
  /// Default KDF provider using CryptoLib4Pascal.
  /// </summary>
  TDefaultKdfProvider = class(TInterfacedObject, IKdfProvider)
  public
    function Pbkdf2SHA256(const APassword, ASalt: TBytes; AIterations, ADKLen: Integer): TBytes;
    function Pbkdf2SHA512(const APassword, ASalt: TBytes; AIterations, ADKLen: Integer): TBytes;
    function Scrypt(const APassword, ASalt: TBytes; AN, AR, AP, ADKLen: Integer): TBytes;
  end;

  /// <summary>
  /// Default Cipher provider using CryptoLib4Pascal.
  /// </summary>
  TDefaultCipherProvider = class(TInterfacedObject, ICipherProvider)
  private
    procedure ValidateAesKeyIv(const AKey, AIV: TBytes);
  public
    function AesCtrEncrypt(const AKey, AIV, AData: TBytes): TBytes;
    function AesCtrDecrypt(const AKey, AIV, AData: TBytes): TBytes;
  end;

  /// <summary>
  /// Default Random provider using CryptoLib4Pascal.
  /// </summary>
  TDefaultRandomProvider = class(TInterfacedObject, IRandomProvider)
  strict private
    class var FSecureRandom: ISecureRandom;
    class constructor Create;
  public
    function RandomBytes(ASize: Integer): TBytes;
    procedure FillRandom(const AOutput: TBytes);
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
    class function GetExpandedPrivateKeyFromSeed(const ASeed32: TBytes): TBytes; static;
    // IsOnCurve helpers
    class function ExpMod(const ANumber, AExponent, AModulo: TBigInteger): TBigInteger; static;
    class function Inv(const AX: TBigInteger): TBigInteger; static;
    class function IsEven(const AX: TBigInteger): Boolean; static;
    class function RecoverX(const AY: TBigInteger): TBigInteger; static;
    class function IsOnCurveXY(const AX, AY: TBigInteger): Boolean; static;
    class function BigIntFromLEUnsigned(const AKey: TBytes): TBigInteger; static;
  public
    function GenerateKeyPair(const ASeed32: TBytes): TEd25519KeyPair;
    function Sign(const ASecretKey64, AMessage: TBytes): TBytes;
    function Verify(const APublicKey32, AMessage, ASignature64: TBytes): Boolean;
    function IsOnCurve(const APublicKey32: TBytes): Boolean;
  end;

  /// <summary>
  /// Scrypt key derivation implementation.
  /// </summary>
  TScryptImpl = class sealed
  strict private
    class function SingleIterationPbkdf2(const APassword, ASalt: TBytes; DKLen: Integer): TBytes; static;
    class procedure BulkCopy(ADst, ASrc: Pointer; ALen: NativeInt); static;
    class procedure BulkXor(ADst, ASrc: Pointer; ALen: NativeInt); static;
    class procedure Encode32(AP: PByte; AX: Cardinal); static;
    class function Decode32(AP: PByte): Cardinal; static;
    class function RotateLeft32(AA: Cardinal; AB: Integer): Cardinal; static; inline;
    class procedure Salsa208(AB: PCardinal); static;
    class procedure BlockMix(ABin, ABout, AX: PCardinal; ARoundsR: Integer); static;
    class function Integerify(AB: PCardinal; ARoundsR: Integer): UInt64; static;
    class procedure SMix(AB: PByte; ARoundsR, AN: Integer; AV, AXY: PCardinal); static;
  public
    class function DeriveKey(const APassword, ASalt: TBytes;
      AN, AR, AP, ADKLen: Integer): TBytes; static;
  end;

implementation

{ TDefaultHashProvider }

function TDefaultHashProvider.SHA256(const AData: TBytes): TBytes;
var
  LDigest: IDigest;
begin
  LDigest := TDigestUtilities.GetDigest('SHA-256');
  if Length(AData) > 0 then
    LDigest.BlockUpdate(AData, 0, Length(AData));
  SetLength(Result, LDigest.GetDigestSize);
  LDigest.DoFinal(Result, 0);
end;

function TDefaultHashProvider.SHA512(const AData: TBytes): TBytes;
var
  LDigest: IDigest;
begin
  LDigest := TDigestUtilities.GetDigest('SHA-512');
  if Length(AData) > 0 then
    LDigest.BlockUpdate(AData, 0, Length(AData));
  SetLength(Result, LDigest.GetDigestSize);
  LDigest.DoFinal(Result, 0);
end;

function TDefaultHashProvider.Keccak256(const AData: TBytes): TBytes;
var
  LDigest: IDigest;
begin
  LDigest := TDigestUtilities.GetDigest('KECCAK-256');
  if Length(AData) > 0 then
    LDigest.BlockUpdate(AData, 0, Length(AData));
  SetLength(Result, LDigest.GetDigestSize);
  LDigest.DoFinal(Result, 0);
end;

{ TDefaultHmacProvider }

function TDefaultHmacProvider.HmacSHA256(const AKey, AData: TBytes): TBytes;
var
  LDigest: IDigest;
  LMac: IMac;
  LKeyParam: IKeyParameter;
begin
  LDigest := TDigestUtilities.GetDigest('SHA-256');
  LMac := THMac.Create(LDigest);
  LKeyParam := TKeyParameter.Create(AKey);
  LMac.Init(LKeyParam);
  if Length(AData) > 0 then
    LMac.BlockUpdate(AData, 0, Length(AData));
  SetLength(Result, LMac.GetMacSize);
  LMac.DoFinal(Result, 0);
end;

function TDefaultHmacProvider.HmacSHA512(const AKey, AData: TBytes): TBytes;
var
  LDigest: IDigest;
  LMac: IMac;
  LKeyParam: IKeyParameter;
begin
  LDigest := TDigestUtilities.GetDigest('SHA-512');
  LMac := THMac.Create(LDigest);
  LKeyParam := TKeyParameter.Create(AKey);
  LMac.Init(LKeyParam);
  if Length(AData) > 0 then
    LMac.BlockUpdate(AData, 0, Length(AData));
  SetLength(Result, LMac.GetMacSize);
  LMac.DoFinal(Result, 0);
end;

{ TDefaultKdfProvider }

function TDefaultKdfProvider.Pbkdf2SHA256(const APassword, ASalt: TBytes;
  AIterations, ADKLen: Integer): TBytes;
var
  LGen: IPkcs5S2ParametersGenerator;
  LParams: ICipherParameters;
  LKeyParam: IKeyParameter;
begin
  LGen := TPkcs5S2ParametersGenerator.Create(TDigestUtilities.GetDigest('SHA-256'));
  LGen.Init(APassword, ASalt, AIterations);
  LParams := LGen.GenerateDerivedMacParameters(ADKLen * 8);
  if not Supports(LParams, IKeyParameter, LKeyParam) then
    raise EArgumentException.Create('Derived parameters do not support IKeyParameter.');
  Result := LKeyParam.GetKey;
end;

function TDefaultKdfProvider.Pbkdf2SHA512(const APassword, ASalt: TBytes;
  AIterations, ADKLen: Integer): TBytes;
var
  LGen: IPkcs5S2ParametersGenerator;
  LParams: ICipherParameters;
  LKeyParam: IKeyParameter;
begin
  LGen := TPkcs5S2ParametersGenerator.Create(TDigestUtilities.GetDigest('SHA-512'));
  LGen.Init(APassword, ASalt, AIterations);
  LParams := LGen.GenerateDerivedMacParameters(ADKLen * 8);
  if not Supports(LParams, IKeyParameter, LKeyParam) then
    raise EArgumentException.Create('Derived parameters do not support IKeyParameter.');
  Result := LKeyParam.GetKey;
end;

function TDefaultKdfProvider.Scrypt(const APassword, ASalt: TBytes;
  AN, AR, AP, ADKLen: Integer): TBytes;
begin
  Result := TScryptImpl.DeriveKey(APassword, ASalt, AN, AR, AP, ADKLen);
end;

{ TDefaultCipherProvider }

procedure TDefaultCipherProvider.ValidateAesKeyIv(const AKey, AIV: TBytes);
begin
  case Length(AKey) of
    16, 24, 32: ; // ok
  else
    raise EArgumentException.Create('AES key must be 16, 24, or 32 bytes.');
  end;

  if Length(AIV) <> 16 then
    raise EArgumentException.Create('AES-CTR IV/nonce must be 16 bytes.');
end;

function TDefaultCipherProvider.AesCtrEncrypt(const AKey, AIV, AData: TBytes): TBytes;
var
  LCipher: IBufferedCipher;
  LKeyParams: IKeyParameter;
  LKeyParamsWithIV: IParametersWithIV;
begin
  ValidateAesKeyIv(AKey, AIV);
  LKeyParams := TParameterUtilities.CreateKeyParameter('AES', AKey);
  LKeyParamsWithIV := TParametersWithIV.Create(LKeyParams, AIV);
  LCipher := TCipherUtilities.GetCipher('AES/CTR/NoPadding');
  LCipher.Init(True, LKeyParamsWithIV);
  Result := LCipher.DoFinal(AData);
end;

function TDefaultCipherProvider.AesCtrDecrypt(const AKey, AIV, AData: TBytes): TBytes;
var
  LCipher: IBufferedCipher;
  LKeyParams: IKeyParameter;
  LKeyParamsWithIV: IParametersWithIV;
begin
  ValidateAesKeyIv(AKey, AIV);
  LKeyParams := TParameterUtilities.CreateKeyParameter('AES', AKey);
  LKeyParamsWithIV := TParametersWithIV.Create(LKeyParams, AIV);
  LCipher := TCipherUtilities.GetCipher('AES/CTR/NoPadding');
  LCipher.Init(False, LKeyParamsWithIV);
  Result := LCipher.DoFinal(AData);
end;

{ TDefaultRandomProvider }

class constructor TDefaultRandomProvider.Create;
begin
  FSecureRandom := TSecureRandom.Create;
end;

function TDefaultRandomProvider.RandomBytes(ASize: Integer): TBytes;
begin
  if ASize < 0 then
    raise EArgumentException.Create('Size must be >= 0');
  SetLength(Result, ASize);
  if ASize > 0 then
    FillRandom(Result);
end;

procedure TDefaultRandomProvider.FillRandom(const AOutput: TBytes);
begin
  if Length(AOutput) > 0 then
    FSecureRandom.NextBytes(AOutput);
end;

{ TDefaultEd25519Provider }

class function TDefaultEd25519Provider.GetEd25519Instance: IEd25519;
begin
  Result := TEd25519.Create;
end;

function TDefaultEd25519Provider.GenerateKeyPair(const ASeed32: TBytes): TEd25519KeyPair;
var
  LPriv: IEd25519PrivateKeyParameters;
  LPub: IEd25519PublicKeyParameters;
  LPk: TBytes;
begin
  if Length(ASeed32) <> 32 then
    raise EArgumentException.Create('Seed must be exactly 32 bytes');

  // Private key from seed
  LPriv := TEd25519PrivateKeyParameters.Create(GetEd25519Instance, ASeed32, 0);

  // Derive public key (32 bytes)
  LPub := LPriv.GeneratePublicKey;
  LPk := LPub.GetEncoded;

  // SecretKey = Seed || PublicKey
  SetLength(Result.SecretKey, 64);
  if Length(ASeed32) > 0 then
    TArrayUtils.Copy<Byte>(ASeed32, 0, Result.SecretKey, 0, 32);
  if Length(LPk) > 0 then
    TArrayUtils.Copy<Byte>(LPk, 0, Result.SecretKey, 32, 32);

  Result.PublicKey := LPk;
end;

function TDefaultEd25519Provider.Sign(const ASecretKey64, AMessage: TBytes): TBytes;
var
  LSeed: TBytes;
  LPriv: IEd25519PrivateKeyParameters;
  LSigner: ISigner;
begin
  if Length(ASecretKey64) <> 64 then
    raise EArgumentException.Create('SecretKey must be 64 bytes [Seed||PublicKey]');

  // First 32 bytes are the seed
  SetLength(LSeed, 32);
  TArrayUtils.Copy<Byte>(ASecretKey64, 0, LSeed, 0, 32);

  // Private key from seed
  LPriv := TEd25519PrivateKeyParameters.Create(GetEd25519Instance, LSeed, 0);

  // Sign
  LSigner := TEd25519Signer.Create(GetEd25519Instance) as IEd25519Signer;
  LSigner.Init(True, LPriv);
  if Length(AMessage) > 0 then
    LSigner.BlockUpdate(AMessage, 0, Length(AMessage));

  Result := LSigner.GenerateSignature; // 64 bytes
end;

function TDefaultEd25519Provider.Verify(const APublicKey32, AMessage, ASignature64: TBytes): Boolean;
var
  LPub: IEd25519PublicKeyParameters;
  LVerifier: ISigner;
begin
  if Length(APublicKey32) <> 32 then
    raise EArgumentException.Create('PublicKey must be 32 bytes');
  if Length(ASignature64) <> 64 then
    raise EArgumentException.Create('Signature must be 64 bytes');

  LPub := TEd25519PublicKeyParameters.Create(APublicKey32, 0);

  LVerifier := TEd25519Signer.Create(GetEd25519Instance) as IEd25519Signer;
  LVerifier.Init(False, LPub);
  if Length(AMessage) > 0 then
    LVerifier.BlockUpdate(AMessage, 0, Length(AMessage));

  Result := LVerifier.VerifySignature(ASignature64);
end;

class constructor TDefaultEd25519Provider.Create;
  function BI(const AStr: string): TBigInteger; inline;
  begin
    Result := TBigInteger.Create(AStr);
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

class function TDefaultEd25519Provider.GetExpandedPrivateKeyFromSeed(const ASeed32: TBytes): TBytes;
var
  LDigest: IDigest;
begin
  if Length(ASeed32) <> 32 then
    raise EArgumentException.Create('Seed must be 32 bytes');

  // SHA-512 of seed
  LDigest := TDigestUtilities.GetDigest('SHA-512');
  LDigest.BlockUpdate(ASeed32, 0, 32);
  SetLength(Result, LDigest.GetDigestSize);
  LDigest.DoFinal(Result, 0);

  if Length(Result) <> 64 then
    raise EInvalidOpException.Create('SHA-512 did not return 64 bytes');

  // RFC8032 clamping on Result[0..31]
  Result[0] := Result[0] and $F8;
  Result[31] := Result[31] and $3F;
  Result[31] := Result[31] or $40;
end;

class function TDefaultEd25519Provider.ExpMod(const ANumber, AExponent, AModulo: TBigInteger): TBigInteger;
begin
  Result := ANumber.ModPow(AExponent, AModulo);
end;

class function TDefaultEd25519Provider.Inv(const AX: TBigInteger): TBigInteger;
begin
  // Fermat: x^(q-2) mod q
  Result := ExpMod(AX, FQm2, FQ);
end;

class function TDefaultEd25519Provider.IsEven(const AX: TBigInteger): Boolean;
begin
  Result := not AX.TestBit(0);
end;

class function TDefaultEd25519Provider.RecoverX(const AY: TBigInteger): TBigInteger;
var
  LY2, LXX, LX, LChk: TBigInteger;
begin
  // LXX = (y^2 - 1) * inv(d*y^2 + 1) (mod q)
  LY2 := AY.Multiply(AY);
  LXX := LY2.Subtract(TBigInteger.One);
  LXX := LXX.Multiply(Inv(FD.Multiply(LY2).Add(TBigInteger.One)));
  LXX := LXX.&Mod(FQ);

  // LX = LXX^((q+3)/8) mod q
  LX := LXX.ModPow(FQp3.Divide(FEight), FQ);

  // if (LX^2 - LXX) mod q != 0 then LX = (LX * i) mod q
  LChk := LX.Multiply(LX).Subtract(LXX).&Mod(FQ);
  if not LChk.Equals(TBigInteger.Zero) then
    LX := LX.Multiply(FI).&Mod(FQ);

  // choose the even representative
  if not IsEven(LX) then
    LX := FQ.Subtract(LX);

  Result := LX;
end;

class function TDefaultEd25519Provider.IsOnCurveXY(const AX, AY: TBigInteger): Boolean;
var
  LXX, LYY, LDxxyy: TBigInteger;
begin
  // LYY - LXX - d*LYY*LXX - 1 == 0 (mod q)
  LXX := AX.Multiply(AX);
  LYY := AY.Multiply(AY);
  LDxxyy := FD.Multiply(LYY).Multiply(LXX);

  Result := LYY.Subtract(LXX).Subtract(LDxxyy).Subtract(TBigInteger.One).&Mod(FQ)
    .Equals(TBigInteger.Zero);
end;

class function TDefaultEd25519Provider.BigIntFromLEUnsigned(const AKey: TBytes): TBigInteger;
var
  LBe: TBytes;
  LI, LLen: Integer;
begin
  // Little-endian unsigned -> big-endian magnitude -> positive BigInteger
  LLen := Length(AKey);
  SetLength(LBe, LLen);

  for LI := 0 to LLen - 1 do
    LBe[LI] := AKey[LLen - 1 - LI];
  // Use ctor (sign, magnitude) to force positive
  Result := TBigInteger.Create(1, LBe);
end;

function TDefaultEd25519Provider.IsOnCurve(const APublicKey32: TBytes): Boolean;
var
  LY, LX: TBigInteger;
begin
  if Length(APublicKey32) <> 32 then
    raise EArgumentException.Create('PublicKey must be 32 bytes');

  // LY = (LE 32 bytes) & (2^255 - 1)
  LY := BigIntFromLEUnsigned(APublicKey32).&And(FUn);
  LX := RecoverX(LY);
  Result := IsOnCurveXY(LX, LY);
end;

{ TScryptImpl }

class function TScryptImpl.SingleIterationPbkdf2(const APassword, ASalt: TBytes; DKLen: Integer): TBytes;
var
  LGen: IPkcs5S2ParametersGenerator;
  LParams: ICipherParameters;
  LKeyParam: IKeyParameter;
begin
  LGen := TPkcs5S2ParametersGenerator.Create(TDigestUtilities.GetDigest('SHA-256'));
  LGen.Init(APassword, ASalt, 1);
  LParams := LGen.GenerateDerivedMacParameters(DKLen * 8);
  if not Supports(LParams, IKeyParameter, LKeyParam) then
    raise EArgumentException.Create('Derived parameters do not support IKeyParameter.');
  Result := LKeyParam.GetKey;
end;

class procedure TScryptImpl.BulkCopy(ADst, ASrc: Pointer; ALen: NativeInt);
begin
  Move(ASrc^, ADst^, ALen);
end;

class procedure TScryptImpl.BulkXor(ADst, ASrc: Pointer; ALen: NativeInt);
var
  LDst, LSrc: PByte;
  LLen: NativeInt;
begin
  LDst := ADst; LSrc := ASrc; LLen := ALen;
  while LLen >= 8 do
  begin
    PUInt64(LDst)^ := PUInt64(LDst)^ xor PUInt64(LSrc)^;
    Inc(LDst, 8); Inc(LSrc, 8); Dec(LLen, 8);
  end;
  if LLen >= 4 then
  begin
    PCardinal(LDst)^ := PCardinal(LDst)^ xor PCardinal(LSrc)^;
    Inc(LDst, 4); Inc(LSrc, 4); Dec(LLen, 4);
  end;
  if LLen >= 2 then
  begin
    PWord(LDst)^ := PWord(LDst)^ xor PWord(LSrc)^;
    Inc(LDst, 2); Inc(LSrc, 2); Dec(LLen, 2);
  end;
  if LLen >= 1 then
    LDst^ := LDst^ xor LSrc^;
end;

class procedure TScryptImpl.Encode32(AP: PByte; AX: Cardinal);
begin
  AP[0] := Byte(AX and $FF);
  AP[1] := Byte((AX shr 8) and $FF);
  AP[2] := Byte((AX shr 16) and $FF);
  AP[3] := Byte((AX shr 24) and $FF);
end;

class function TScryptImpl.Decode32(AP: PByte): Cardinal;
begin
  Result :=
    Cardinal(AP[0]) or
    (Cardinal(AP[1]) shl 8) or
    (Cardinal(AP[2]) shl 16) or
    (Cardinal(AP[3]) shl 24);
end;

class function TScryptImpl.RotateLeft32(AA: Cardinal; AB: Integer): Cardinal;
begin
  Result := TBits.RotateLeft32(AA, AB);
end;

class procedure TScryptImpl.Salsa208(AB: PCardinal);
var
  LX0, LX1, LX2, LX3, LX4, LX5, LX6, LX7, LX8, LX9, LX10, LX11, LX12, LX13, LX14, LX15: Cardinal;
  LI: Integer;
begin
  LX0 := AB[0];  LX1 := AB[1];  LX2 := AB[2];  LX3 := AB[3];
  LX4 := AB[4];  LX5 := AB[5];  LX6 := AB[6];  LX7 := AB[7];
  LX8 := AB[8];  LX9 := AB[9];  LX10 := AB[10]; LX11 := AB[11];
  LX12 := AB[12]; LX13 := AB[13]; LX14 := AB[14]; LX15 := AB[15];

  for LI := 0 to 3 do
  begin
    // Operate on columns
    LX4 := LX4  xor RotateLeft32(LX0 + LX12, 7);
    LX8 := LX8  xor RotateLeft32(LX4 + LX0, 9);

    LX12 := LX12 xor RotateLeft32(LX8 + LX4, 13);
    LX0 := LX0  xor RotateLeft32(LX12 + LX8, 18);

    LX9 := LX9  xor RotateLeft32(LX5 + LX1, 7);
    LX13 := LX13 xor RotateLeft32(LX9 + LX5, 9);

    LX1 := LX1  xor RotateLeft32(LX13 + LX9, 13);
    LX5 := LX5  xor RotateLeft32(LX1 + LX13, 18);

    LX14 := LX14 xor RotateLeft32(LX10 + LX6, 7);
    LX2 := LX2  xor RotateLeft32(LX14 + LX10, 9);

    LX6 := LX6  xor RotateLeft32(LX2 + LX14, 13);
    LX10 := LX10 xor RotateLeft32(LX6 + LX2, 18);

    LX3 := LX3  xor RotateLeft32(LX15 + LX11, 7);
    LX7 := LX7  xor RotateLeft32(LX3 + LX15, 9);

    LX11 := LX11 xor RotateLeft32(LX7 + LX3, 13);
    LX15 := LX15 xor RotateLeft32(LX11 + LX7, 18);

    // Operate on rows
    LX1 := LX1  xor RotateLeft32(LX0 + LX3, 7);
    LX2 := LX2  xor RotateLeft32(LX1 + LX0, 9);

    LX3 := LX3  xor RotateLeft32(LX2 + LX1, 13);
    LX0 := LX0  xor RotateLeft32(LX3 + LX2, 18);

    LX6 := LX6  xor RotateLeft32(LX5 + LX4, 7);
    LX7 := LX7  xor RotateLeft32(LX6 + LX5, 9);

    LX4 := LX4  xor RotateLeft32(LX7 + LX6, 13);
    LX5 := LX5  xor RotateLeft32(LX4 + LX7, 18);

    LX11 := LX11 xor RotateLeft32(LX10 + LX9, 7);
    LX8 := LX8  xor RotateLeft32(LX11 + LX10, 9);

    LX9 := LX9  xor RotateLeft32(LX8 + LX11, 13);
    LX10 := LX10 xor RotateLeft32(LX9 + LX8, 18);

    LX12 := LX12 xor RotateLeft32(LX15 + LX14, 7);
    LX13 := LX13 xor RotateLeft32(LX12 + LX15, 9);

    LX14 := LX14 xor RotateLeft32(LX13 + LX12, 13);
    LX15 := LX15 xor RotateLeft32(LX14 + LX13, 18);
  end;

  AB[0] := AB[0]  + LX0;   AB[1] := AB[1]  + LX1;   AB[2] := AB[2]  + LX2;   AB[3] := AB[3]  + LX3;
  AB[4] := AB[4]  + LX4;   AB[5] := AB[5]  + LX5;   AB[6] := AB[6]  + LX6;   AB[7] := AB[7]  + LX7;
  AB[8] := AB[8]  + LX8;   AB[9] := AB[9]  + LX9;   AB[10] := AB[10] + LX10;  AB[11] := AB[11] + LX11;
  AB[12] := AB[12] + LX12;  AB[13] := AB[13] + LX13;  AB[14] := AB[14] + LX14;  AB[15] := AB[15] + LX15;
end;

class procedure TScryptImpl.BlockMix(ABin, ABout, AX: PCardinal; ARoundsR: Integer);
var
  LI: Integer;
begin
  // AX <- B_{2r-1}
  BulkCopy(AX, @ABin[(2 * ARoundsR - 1) * 16], 64);

  LI := 0;
  while LI <= (2 * ARoundsR - 1) do
  begin
    // even half (LI even)
    BulkXor(AX, @ABin[LI * 16], 64);
    Salsa208(AX);
    // Y_even -> ABout[(LI div 2) * 16]
    BulkCopy(@ABout[(LI div 2) * 16], AX, 64);

    Inc(LI);
    if LI >= 2 * ARoundsR then Break;

    // odd half (LI odd, LI is the next block)
    BulkXor(AX, @ABin[LI * 16], 64);
    Salsa208(AX);
    // Y_odd -> ABout[r*16 + (LI div 2) * 16]
    BulkCopy(@ABout[ARoundsR * 16 + (LI div 2) * 16], AX, 64);

    Inc(LI);
  end;
end;

class function TScryptImpl.Integerify(AB: PCardinal; ARoundsR: Integer): UInt64;
var
  LX: PCardinal;
begin
  // LX points to the last 64-byte chunk (B_{2r-1})
  LX := PCardinal(PByte(AB) + (2 * ARoundsR - 1) * 64);
  Result := (UInt64(LX[1]) shl 32) or UInt64(LX[0]);
end;

class procedure TScryptImpl.SMix(AB: PByte; ARoundsR, AN: Integer; AV, AXY: PCardinal);
var
  LX, LY, LZ: PCardinal;
  LI, LK: Integer;
  LJ, LIdx: Integer;
begin
  LX := AXY;
  LY := @AXY[32 * ARoundsR];
  LZ := @AXY[64 * ARoundsR];

  // 1: LX <- AB
  for LK := 0 to (32 * ARoundsR - 1) do
    LX[LK] := Decode32(@AB[4 * LK]);

  // 2: for LI = 0..AN-1
  LI := 0;
  while LI < AN do
  begin
    BulkCopy(@AV[LI * (32 * ARoundsR)], LX, 128 * ARoundsR);
    BlockMix(LX, LY, LZ, ARoundsR);

    Inc(LI);
    BulkCopy(@AV[LI * (32 * ARoundsR)], LY, 128 * ARoundsR);
    BlockMix(LY, LX, LZ, ARoundsR);

    Inc(LI);
  end;

  // 6: for LI = 0..AN-1
  LI := 0;
  while LI < AN do
  begin
    LJ := Integer(Integerify(LX, ARoundsR) and UInt64(AN - 1));
    LIdx := LJ * (32 * ARoundsR);
    BulkXor(LX, @AV[LIdx], 128 * ARoundsR);
    BlockMix(LX, LY, LZ, ARoundsR);

    LJ := Integer(Integerify(LY, ARoundsR) and UInt64(AN - 1));
    LIdx := LJ * (32 * ARoundsR);
    BulkXor(LY, @AV[LIdx], 128 * ARoundsR);
    BlockMix(LY, LX, LZ, ARoundsR);

    Inc(LI, 2);
  end;

  // 10: B' <- LX
  for LK := 0 to (32 * ARoundsR - 1) do
    Encode32(@AB[4 * LK], LX[LK]);
end;

class function TScryptImpl.DeriveKey(const APassword, ASalt: TBytes;
  AN, AR, AP, ADKLen: Integer): TBytes;
var
  LBA: TBytes;
  LXY: TArray<Cardinal>;
  LV: TArray<Cardinal>;
  LI, LBlockLen: Integer;
  LBi: PByte;
begin
  if (AN <= 1) or ((AN and (AN - 1)) <> 0) then
    raise EArgumentException.Create('N must be > 1 and a power of 2');

  if (AR <= 0) or (AP <= 0) then
    raise EArgumentException.Create('r and p must be > 0');

  // 1: B <- PBKDF2(P, S, 1, p*128*r)
  LBlockLen := 128 * AR;
  LBA := SingleIterationPbkdf2(APassword, ASalt, AP * LBlockLen);

  // temp buffers
  SetLength(LXY, 32 * AR * 2 + 16);
  SetLength(LV, 32 * AR * AN);

  // 2: for LI = 0..p-1: SMix(B_i, r, N)
  for LI := 0 to AP - 1 do
  begin
    LBi := @LBA[LI * LBlockLen];
    SMix(LBi, AR, AN, @LV[0], @LXY[0]);
  end;

  // 5: DK <- PBKDF2(P, B, 1, dkLen)
  Result := SingleIterationPbkdf2(APassword, LBA, ADKLen);
end;

end.
