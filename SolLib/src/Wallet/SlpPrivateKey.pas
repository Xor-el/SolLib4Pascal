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

unit SlpPrivateKey;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  SlpDataEncoders,
  SlpArrayUtils,
  SlpCryptoUtils;

type
  IPrivateKey = interface
    ['{B7C3A3B7-8C7E-4D0E-9B6E-6B7E0F9B6D31}']

    function GetKey: string;
    procedure SetKey(const Value: string);
    function GetKeyBytes: TBytes;
    procedure SetKeyBytes(const Value: TBytes);

    /// <summary>
    /// Sign the data.
    /// </summary>
    /// <param name="message">The data to sign.</param>
    /// <returns>The signature of the data (64 bytes).</returns>
    function Sign(const &Message: TBytes): TBytes;

    function Clone(): IPrivateKey;

    /// <inheritdoc cref="Equals(object)"/>
    function Equals(const Other: IPrivateKey): Boolean;
    function ToString: string;

    function ToBytes: TBytes;

    /// <summary>
    /// The key as base-58 encoded string.
    /// </summary>
    property Key: string read GetKey write SetKey;

    /// <summary>
    /// The bytes of the key.
    /// </summary>
    property KeyBytes: TBytes read GetKeyBytes write SetKeyBytes;
  end;

  TPrivateKey = class(TInterfacedObject, IPrivateKey)
  strict private
    FKey: string;
    FKeyBytes: TBytes;

    function GetKey: string;
    procedure SetKey(const Value: string);
    function GetKeyBytes: TBytes;
    procedure SetKeyBytes(const Value: TBytes);

    /// <summary>
    /// Sign the data.
    /// </summary>
    /// <param name="message">The data to sign.</param>
    /// <returns>The signature of the data (64 bytes).</returns>
    function Sign(const &Message: TBytes): TBytes;

    function Clone(): IPrivateKey;

    function Equals(const Other: IPrivateKey): Boolean; reintroduce;

    function ToBytes: TBytes;
  public const
    /// <summary>Private key length.</summary>
    PrivateKeyLength = 64; // Seed(32) || PublicKey(32)

    /// <summary>
    /// Initialize the private key from the given byte array.
    /// </summary>
    /// <param name="AKey">The private key as byte array (64 bytes: Seed||PublicKey).</param>
    constructor Create(const AKey: TBytes); overload;

    /// <summary>
    /// Initialize the private key from the given string.
    /// </summary>
    /// <param name="AKey">The private key as base58 encoded string.</param>
    constructor Create(const AKey: string); overload;

    function ToString: string; override;

    class function FromString(const S: string): IPrivateKey; static;
    class function FromBytes(const B: TBytes): IPrivateKey; static;
  end;

implementation

{ TPrivateKey }

constructor TPrivateKey.Create(const AKey: TBytes);
begin
  inherited Create;
  if AKey = nil then
    raise EArgumentNilException.Create('key');
  if Length(AKey) <> PrivateKeyLength then
    raise EArgumentException.Create('invalid key length, key');

  SetLength(FKeyBytes, PrivateKeyLength);
  TArrayUtils.Copy<Byte>(AKey, 0, FKeyBytes, 0, PrivateKeyLength);
end;

constructor TPrivateKey.Create(const AKey: string);
begin
  inherited Create;
  if AKey = '' then
    raise EArgumentNilException.Create('key');
  FKey := AKey;
end;

function TPrivateKey.Clone: IPrivateKey;
begin
  Result := TPrivateKey.Create();
  Result.Key := FKey;
  Result.KeyBytes := TArrayUtils.Copy<Byte>(FKeyBytes);
end;

function TPrivateKey.GetKey: string;
begin
  if FKey = '' then
  begin
    FKey := TEncoders.Base58.EncodeData(GetKeyBytes);
  end;
  Result := FKey;
end;

procedure TPrivateKey.SetKey(const Value: string);
begin
  FKey := Value;
end;

function TPrivateKey.GetKeyBytes: TBytes;
begin
  if Length(FKeyBytes) = 0 then
  begin
    FKeyBytes := TEncoders.Base58.DecodeData(GetKey);
  end;
  Result := FKeyBytes;
end;

procedure TPrivateKey.SetKeyBytes(const Value: TBytes);
begin
  FKeyBytes := Value;
end;

function TPrivateKey.Sign(const &Message: TBytes): TBytes;
begin
  // Expects SecretKey64 = Seed(32)||PublicKey(32)
  Result := TEd25519Crypto.Sign(GetKeyBytes, &Message);
end;

function TPrivateKey.Equals(const Other: IPrivateKey): Boolean;
var
  SelfAsI: IPrivateKey;
begin
  if Other = nil then
    Exit(False);

  // 1) Exact same IPrivateKey reference?
  if Supports(Self, IPrivateKey, SelfAsI) then
  begin
   if SelfAsI = Other then
    Exit(True);
  end;

  // 2) Value equality: same key
  Result := SameStr(SelfAsI.Key, Other.Key);
end;

function TPrivateKey.ToString: string;
begin
  Result := GetKey;
end;

function TPrivateKey.ToBytes: TBytes;
begin
  Result := GetKeyBytes;
end;

class function TPrivateKey.FromString(const S: string): IPrivateKey;
begin
  Result := TPrivateKey.Create(S);
end;

class function TPrivateKey.FromBytes(const B: TBytes): IPrivateKey;
begin
  Result := TPrivateKey.Create(B);
end;

end.

