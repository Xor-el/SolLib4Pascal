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

unit SlpAccount;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpArrayUtils,
  SlpCryptoUtils,
  SlpDataEncoders,
  SlpPrivateKey,
  SlpPublicKey,
  SlpEd25519Utils;

type
  IAccount = interface
    ['{C4A1B0A4-1A8A-4F0C-9E4C-2B9F0B8E7E77}']
    function GetPrivateKey: IPrivateKey;
    function GetPublicKey: IPublicKey;

    function Verify(const &Message, Signature: TBytes): Boolean;
    function Sign(const &Message: TBytes): TBytes;

    function Equals(const Other: IAccount): Boolean;
    function ToString: string;

    property PrivateKey: IPrivateKey read GetPrivateKey;
    property PublicKey: IPublicKey  read GetPublicKey;
  end;

  TAccount = class(TInterfacedObject, IAccount)
  private
    FPrivateKey: IPrivateKey;
    FPublicKey : IPublicKey;

    function GetPrivateKey: IPrivateKey;
    function GetPublicKey: IPublicKey;

    /// Verify the signed message.
    function Verify(const &Message, Signature: TBytes): Boolean;
    /// Sign the data.
    function Sign(const &Message: TBytes): TBytes;

    /// Equality compares public keys.
    function Equals(const Other: IAccount): Boolean; reintroduce;

    class function GenerateRandomSeed: TBytes; static;
  public
    /// Initialize an account. Generates a random seed for the Ed25519 key pair.
    constructor Create; overload;
    /// Initialize from base58 keys.
    constructor Create(const PrivateKeyB58, PublicKeyB58: string); overload;
    /// Initialize from raw key bytes.
    constructor Create(const PrivateKeyBytes, PublicKeyBytes: TBytes); overload;

    function ToString: string; override;

    /// Initialize from base58 64-byte libsodium secret key.
    class function FromSecretKey(const SecretKeyB58: string): IAccount; static;

    /// Import many accounts from base58 secret keys.
    class function ImportMany(const Keys: TList<string>): TList<IAccount>; overload; static;
    /// Import many accounts from raw secret key bytes.
    class function ImportMany(const Keys: TList<TBytes>): TList<IAccount>; overload; static;
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
  Seed: TBytes;
  KP: TEd25519KeyPair;
begin
  inherited Create;
  // Derive keypair from random seed (libsodium format)
  Seed := GenerateRandomSeed;
  KP := TEd25519Crypto.GenerateKeyPair(Seed);
  FPrivateKey := TPrivateKey.Create(KP.SecretKey);  // 64 bytes
  FPublicKey  := TPublicKey.Create(KP.PublicKey);   // 32 bytes
end;

constructor TAccount.Create(const PrivateKeyB58, PublicKeyB58: string);
begin
  inherited Create;
  FPrivateKey := TPrivateKey.Create(PrivateKeyB58);
  FPublicKey  := TPublicKey.Create(PublicKeyB58);
end;

constructor TAccount.Create(const PrivateKeyBytes, PublicKeyBytes: TBytes);
begin
  inherited Create;
  FPrivateKey := TPrivateKey.Create(PrivateKeyBytes);
  FPublicKey  := TPublicKey.Create(PublicKeyBytes);
end;

class function TAccount.FromSecretKey(const SecretKeyB58: string): IAccount;
var
  SK: TBytes;
  PK: TBytes;
begin
  SK := TEncoders.Base58.DecodeData(SecretKeyB58);

  if Length(SK) <> 64 then
    raise EArgumentException.Create('Not a secret key');

  SetLength(PK, 32);
  if Length(PK) > 0 then
    TArrayUtils.Copy<Byte>(SK, 32, PK, 0, 32);

  Result := TAccount.Create(SK, PK);
end;

function TAccount.Verify(const &Message, Signature: TBytes): Boolean;
begin
  Result := FPublicKey.Verify(&Message, Signature);
end;

function TAccount.Sign(const &Message: TBytes): TBytes;
begin
  Result := FPrivateKey.Sign(&Message);
end;

function TAccount.Equals(const Other: IAccount): Boolean;
var
  SelfAsI: IAccount;
begin
  if Other = nil then
    Exit(False);

  // 1) Exact same IAccount reference?
  if Supports(Self, IAccount, SelfAsI) then
  begin
   if SelfAsI = Other then
    Exit(True);
  end;

  // 2) Value equality: same public key
  Result := Other.PublicKey.Equals(FPublicKey);
end;

function TAccount.ToString: string;
begin
  Result := FPublicKey.ToString;
end;

class function TAccount.ImportMany(const Keys: TList<string>): TList<IAccount>;
var
  S: string;
  Acc: IAccount;
begin
  Result := TList<IAccount>.Create;
  try
    for S in Keys do
    begin
      Acc := FromSecretKey(S);
      Result.Add(Acc);
    end;
  except
    Result.Free;
    raise;
  end;
end;

class function TAccount.ImportMany(const Keys: TList<TBytes>): TList<IAccount>;
var
  SK, PK: TBytes;
  Acc: IAccount;
begin
  Result := TList<IAccount>.Create;
  try
    for SK in Keys do
    begin
      SetLength(PK, 32);
      if Length(PK) > 0 then
        TArrayUtils.Copy<Byte>(SK, 32, PK, 0, 32);

      Acc := TAccount.Create(SK, PK);
      Result.Add(Acc);
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.

