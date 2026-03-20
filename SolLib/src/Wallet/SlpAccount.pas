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

unit SlpAccount;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpArrayUtilities,
  SlpCryptoUtilities,
  SlpDataEncoderUtilities,
  SlpPrivateKey,
  SlpPublicKey,
  SlpCryptoProviders;

type
  IAccount = interface
    ['{C4A1B0A4-1A8A-4F0C-9E4C-2B9F0B8E7E77}']
    function GetPrivateKey: IPrivateKey;
    function GetPublicKey: IPublicKey;

    function Verify(const AMessage, ASignature: TBytes): Boolean;
    function Sign(const AMessage: TBytes): TBytes;

    function Equals(const AOther: IAccount): Boolean;
    function ToString: string;

    property PrivateKey: IPrivateKey read GetPrivateKey;
    property PublicKey: IPublicKey  read GetPublicKey;
  end;

  TAccount = class(TInterfacedObject, IAccount)
  private
    FPrivateKey: IPrivateKey;
    FPublicKey: IPublicKey;

    function GetPrivateKey: IPrivateKey;
    function GetPublicKey: IPublicKey;

    /// Verify the signed message.
    function Verify(const AMessage, ASignature: TBytes): Boolean;
    /// Sign the data.
    function Sign(const AMessage: TBytes): TBytes;

    /// Equality compares public keys.
    function Equals(const AOther: IAccount): Boolean; reintroduce;

    class function GenerateRandomSeed: TBytes; static;
  public
    /// Initialize an account. Generates a random seed for the Ed25519 key pair.
    constructor Create; overload;
    /// Initialize from base58 keys.
    constructor Create(const APrivateKeyB58, APublicKeyB58: string); overload;
    /// Initialize from raw key bytes.
    constructor Create(const APrivateKeyBytes, APublicKeyBytes: TBytes); overload;

    function ToString: string; override;

    /// Initialize from base58 64-byte libsodium secret key.
    class function FromSecretKey(const ASecretKeyB58: string): IAccount; static;

    /// Import many accounts from base58 secret keys.
    class function ImportMany(const AKeys: TList<string>): TList<IAccount>; overload; static;
    /// Import many accounts from raw secret key bytes.
    class function ImportMany(const AKeys: TList<TBytes>): TList<IAccount>; overload; static;
  end;

implementation

{ TAccount }

class function TAccount.GenerateRandomSeed: TBytes;
begin
  Result := TRandom.RandomBytes(32);
end;

function TAccount.GetPrivateKey: IPrivateKey;
begin
  Result := FPrivateKey;
end;

function TAccount.GetPublicKey: IPublicKey;
begin
  Result := FPublicKey;
end;

constructor TAccount.Create;
var
  LSeed: TBytes;
  LKP: TEd25519KeyPair;
begin
  inherited Create;
  // Derive keypair from random seed (libsodium format)
  LSeed := GenerateRandomSeed;
  LKP := TEd25519Crypto.GenerateKeyPair(LSeed);
  FPrivateKey := TPrivateKey.Create(LKP.SecretKey);  // 64 bytes
  FPublicKey := TPublicKey.Create(LKP.PublicKey);   // 32 bytes
end;

constructor TAccount.Create(const APrivateKeyB58, APublicKeyB58: string);
begin
  inherited Create;
  FPrivateKey := TPrivateKey.Create(APrivateKeyB58);
  FPublicKey := TPublicKey.Create(APublicKeyB58);
end;

constructor TAccount.Create(const APrivateKeyBytes, APublicKeyBytes: TBytes);
begin
  inherited Create;
  FPrivateKey := TPrivateKey.Create(APrivateKeyBytes);
  FPublicKey := TPublicKey.Create(APublicKeyBytes);
end;

class function TAccount.FromSecretKey(const ASecretKeyB58: string): IAccount;
var
  LSK: TBytes;
  LPK: TBytes;
begin
  LSK := TBase58Encoder.DecodeData(ASecretKeyB58);

  if Length(LSK) <> 64 then
    raise EArgumentException.Create('Not a secret key');

  SetLength(LPK, 32);
  if Length(LPK) > 0 then
    TArrayUtilities.Copy<Byte>(LSK, 32, LPK, 0, 32);

  Result := TAccount.Create(LSK, LPK);
end;

function TAccount.Verify(const AMessage, ASignature: TBytes): Boolean;
begin
  Result := FPublicKey.Verify(AMessage, ASignature);
end;

function TAccount.Sign(const AMessage: TBytes): TBytes;
begin
  Result := FPrivateKey.Sign(AMessage);
end;

function TAccount.Equals(const AOther: IAccount): Boolean;
var
  LSelfAsI: IAccount;
begin
  if AOther = nil then
    Exit(False);

  // 1) Exact same IAccount reference?
  if Supports(Self, IAccount, LSelfAsI) then
  begin
   if LSelfAsI = AOther then
    Exit(True);
  end;

  // 2) Value equality: same public key
  Result := AOther.PublicKey.Equals(FPublicKey);
end;


function TAccount.ToString: string;
begin
  Result := FPublicKey.ToString;
end;

class function TAccount.ImportMany(const AKeys: TList<string>): TList<IAccount>;
var
  LS: string;
  LAcc: IAccount;
begin
  Result := TList<IAccount>.Create;
  try
    for LS in AKeys do
    begin
      LAcc := FromSecretKey(LS);
      Result.Add(LAcc);
    end;
  except
    Result.Free;
    raise;
  end;
end;

class function TAccount.ImportMany(const AKeys: TList<TBytes>): TList<IAccount>;
var
  LKeyBytes: TBytes;
  LPK: TBytes;
  LAcc: IAccount;
begin
  Result := TList<IAccount>.Create;
  try
    for LKeyBytes in AKeys do
    begin
      SetLength(LPK, 32);
      if Length(LPK) > 0 then
        TArrayUtilities.Copy<Byte>(LKeyBytes, 32, LPK, 0, 32);

      LAcc := TAccount.Create(LKeyBytes, LPK);
      Result.Add(LAcc);
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.

