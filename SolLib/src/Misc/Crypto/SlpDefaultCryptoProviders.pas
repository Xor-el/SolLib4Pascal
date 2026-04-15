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
  SysUtils,
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
  ClpIScryptParametersGenerator,
  ClpScryptParametersGenerator,
  ClpICipherParameters,
  ClpIBufferedCipher,
  ClpCipherUtilities,
  ClpParameterUtilities,
  ClpISecureRandom,
  ClpSecureRandom,
  ClpEd25519,
  ClpISigner,
  ClpEd25519Signer,
  ClpIEd25519Parameters,
  ClpEd25519Parameters,
  SlpArrayUtilities,
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
  public
    function GenerateKeyPair(const ASeed32: TBytes): TEd25519KeyPair;
    function Sign(const ASecretKey64, AMessage: TBytes): TBytes;
    function Verify(const APublicKey32, AMessage, ASignature64: TBytes): Boolean;
    function IsOnCurve(const APublicKey32: TBytes): Boolean;
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
var
  LGen: IScryptParametersGenerator;
  LParams: ICipherParameters;
  LKeyParam: IKeyParameter;
begin
  // ARelaxCostRestriction = True: the Ethereum Web3 Secret Storage standard
  // uses N=262144, r=1, p=8 which violates the erroneous RFC 7914 constraint
  // N < 2^(128*r/8). The RFC author confirmed this was accidental.
  // See: https://github.com/golang/go/issues/33703#issuecomment-568198927
  LGen := TScryptParametersGenerator.Create;
  LGen.Init(APassword, ASalt, AN, AR, AP, True);
  LParams := LGen.GenerateDerivedMacParameters(ADKLen * 8);
  if not Supports(LParams, IKeyParameter, LKeyParam) then
    raise EArgumentException.Create('Derived parameters do not support IKeyParameter.');
  Result := LKeyParam.GetKey;
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

function TDefaultEd25519Provider.GenerateKeyPair(const ASeed32: TBytes): TEd25519KeyPair;
var
  LPriv: IEd25519PrivateKeyParameters;
  LPub: IEd25519PublicKeyParameters;
  LPk: TBytes;
begin
  if Length(ASeed32) <> 32 then
    raise EArgumentException.Create('Seed must be exactly 32 bytes');

  // Private key from seed
  LPriv := TEd25519PrivateKeyParameters.Create(ASeed32, 0);

  // Derive public key (32 bytes)
  LPub := LPriv.GeneratePublicKey;
  LPk := LPub.GetEncoded;

  // SecretKey = Seed || PublicKey
  SetLength(Result.SecretKey, 64);
  if Length(ASeed32) > 0 then
    TArrayUtilities.Copy<Byte>(ASeed32, 0, Result.SecretKey, 0, 32);
  if Length(LPk) > 0 then
    TArrayUtilities.Copy<Byte>(LPk, 0, Result.SecretKey, 32, 32);

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
  TArrayUtilities.Copy<Byte>(ASecretKey64, 0, LSeed, 0, 32);

  // Private key from seed
  LPriv := TEd25519PrivateKeyParameters.Create(LSeed, 0);

  // Sign
  LSigner := TEd25519Signer.Create();
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

  LVerifier := TEd25519Signer.Create();
  LVerifier.Init(False, LPub);
  if Length(AMessage) > 0 then
    LVerifier.BlockUpdate(AMessage, 0, Length(AMessage));

  Result := LVerifier.VerifySignature(ASignature64);
end;

function TDefaultEd25519Provider.IsOnCurve(const APublicKey32: TBytes): Boolean;
begin
  if Length(APublicKey32) <> 32 then
    raise EArgumentException.Create('PublicKey must be 32 bytes');
  Result := TEd25519.ValidatePublicKeyPartial(APublicKey32, 0);
end;

end.
