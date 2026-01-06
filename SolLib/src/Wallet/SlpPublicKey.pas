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

unit SlpPublicKey;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  SlpDataEncoders,
  SlpCryptoUtils,
  SlpEd25519Utils,
  SlpArrayUtils;

type
  IPublicKey = interface
    ['{A1F2B3C4-D5E6-47A8-9B0C-1D2E3F4A5B6C}']

    function GetKey: string;
    procedure SetKey(const Value: string);
    function GetKeyBytes: TBytes;
    procedure SetKeyBytes(const Value: TBytes);

    function Verify(const &Message, Signature: TBytes): Boolean;
    function IsOnCurve: Boolean;
    function IsValid: Boolean;
    function ToBytes: TBytes;
    function Clone: IPublicKey;

    function Equals(const Other: IPublicKey): Boolean;
    function ToString: string;

    /// <summary>
    /// The key as base-58 encoded string.
    /// </summary>
    property Key: string read GetKey write SetKey;

    /// <summary>
    /// The bytes of the key.
    /// </summary>
    property KeyBytes: TBytes read GetKeyBytes write SetKeyBytes;
  end;

  /// <summary>
  /// Implements the public key functionality.
  /// </summary>
  TPublicKey = class(TInterfacedObject, IPublicKey)
  strict private
    FKey: string;
    FKeyBytes: TBytes;

  const
    // The bytes of the `ProgramDerivedAddress` string.
    ProgramDerivedAddressBytes: array [0 .. 20] of Byte = (Ord('P'), Ord('r'),
      Ord('o'), Ord('g'), Ord('r'), Ord('a'), Ord('m'), Ord('D'), Ord('e'),
      Ord('r'), Ord('i'), Ord('v'), Ord('e'), Ord('d'), Ord('A'), Ord('d'),
      Ord('d'), Ord('r'), Ord('e'), Ord('s'), Ord('s'));

    class function FastCheck(const Value: string): Boolean; static;

    function GetKey: string;
    procedure SetKey(const Value: string);
    function GetKeyBytes: TBytes;
    procedure SetKeyBytes(const Value: TBytes);

    /// <summary>
    /// Verify the signed message.
    /// </summary>
    /// <param name="message">The signed message.</param>
    /// <param name="signature">The signature of the message.</param>
    function Verify(const &Message, Signature: TBytes): Boolean;

    function Clone(): IPublicKey;

    /// Equality compares public keys.
    function Equals(const Other: IPublicKey): Boolean; reintroduce;

    /// <summary>
    /// Checks if this object is a valid Ed25519 PublicKey.
    /// </summary>
    /// <returns>Returns true if it is a valid key, false otherwise.</returns>
    function IsOnCurve: Boolean;

    /// <summary>
    /// Checks if this object is a valid Solana PublicKey.
    /// </summary>
    /// <returns>Returns true if it is a valid key, false otherwise.</returns>
    function IsValid: Boolean; overload;

    function ToBytes: TBytes;

  public const
    /// <summary>Public key length.</summary>
    PublicKeyLength = 32;

    /// <summary>
    /// Initialize the public key from the given byte array.
    /// </summary>
    /// <param name="AKey">The public key as byte array.</param>
    constructor Create(const AKey: TBytes); overload;

    /// <summary>
    /// Initialize the public key from the given string.
    /// </summary>
    /// <param name="AKey">The public key as base58 encoded string.</param>
    constructor Create(const AKey: string); overload;

    function ToString: string; override;

    /// <summary>
    /// Checks if a given string forms a valid PublicKey in base58.
    /// </summary>
    /// <remarks>
    /// Any set of 32 bytes can constitute a valid solana public key. However, not all 32-byte public keys are valid Ed25519 public keys. <br/>
    /// Two concrete examples: <br/>
    /// - A user wallet key must be on the curve (otherwise a user wouldn't be able to sign transactions).  <br/>
    /// - A program derived address must NOT be on the curve.
    /// </remarks>
    /// <param name="AKey">The base58 encoded public key.</param>
    /// <param name="AValidateCurve">Whether or not to validate if the public key belongs to the Ed25519 curve.</param>
    /// <returns>Returns true if the input is a valid key, false otherwise.</returns>
    class function IsValid(const AKey: string; AValidateCurve: Boolean = False)
      : Boolean; overload; static;

    /// <summary>
    /// Checks if a given set of bytes forms a valid PublicKey.
    /// </summary>
    /// <remarks>
    /// Any set of 32 bytes can constitute a valid solana public key. However, not all 32-byte public keys are valid Ed25519 public keys. <br/>
    /// Two concrete examples: <br/>
    /// - A user wallet key must be on the curve (otherwise a user wouldn't be able to sign transactions).  <br/>
    /// - A program derived address must NOT be on the curve.
    /// </remarks>
    /// <param name="AKey">The key bytes.</param>
    /// <param name="AValidateCurve">Whether or not to validate if the public key belongs to the Ed25519 curve.</param>
    /// <returns>Returns true if the input is a valid key, false otherwise.</returns>
    class function IsValid(const AKey: TBytes; AValidateCurve: Boolean = False)
      : Boolean; overload; static;

    { #region KeyDerivation }

    /// <summary>
    /// Derives a program address.
    /// </summary>
    /// <param name="Seeds">The address seeds.</param>
    /// <param name="ProgramId">The program Id.</param>
    /// <param name="PublicKey">The derived public key, returned as inline out.</param>
    /// <returns>true if it could derive the program address for the given seeds, otherwise false..</returns>
    /// <exception cref="ArgumentException">Throws exception when one of the seeds has an invalid length.</exception>
    class function TryCreateProgramAddress(const Seeds: TArray<TBytes>;
      const ProgramId: IPublicKey; out PublicKey: IPublicKey): Boolean; static;

    /// <summary>
    /// Attempts to find a program address for the passed seeds and program Id.
    /// </summary>
    /// <param name="Seeds">The address seeds.</param>
    /// <param name="ProgramId">The program Id.</param>
    /// <param name="Address">The derived address, returned as inline out.</param>
    /// <param name="Bump">The bump used to derive the address, returned as inline out.</param>
    /// <returns>True whenever the address for a nonce was found, otherwise false.</returns>
    class function TryFindProgramAddress(const Seeds: TArray<TBytes>;
      const ProgramId: IPublicKey; out Address: IPublicKey; out Bump: Byte)
      : Boolean; static;

    /// <summary>
    /// Derives a new public key from an existing public key and seed
    /// </summary>
    /// <param name="FromPublicKey">The extant pubkey</param>
    /// <param name="Seed">The seed</param>
    /// <param name="ProgramId">The programid</param>
    /// <param name="PublicKeyOut">The derived public key</param>
    /// <returns>True whenever the address was successfully created, otherwise false.</returns>
    /// <remarks>To fail address creation, means the created address was a PDA.</remarks>
    class function TryCreateWithSeed(const FromPublicKey: IPublicKey; const Seed: string; const ProgramId: IPublicKey; out PublicKeyOut: IPublicKey): Boolean; static;

    class function FromString(const S: string): IPublicKey; static;

    class function FromBytes(const B: TBytes): IPublicKey; static;

  end;

implementation

{ TPublicKey }

constructor TPublicKey.Create(const AKey: TBytes);
begin
  inherited Create;
  if AKey = nil then
    raise EArgumentNilException.Create('key');
  if Length(AKey) <> PublicKeyLength then
    raise EArgumentException.Create('invalid key length, key');

  SetLength(FKeyBytes, PublicKeyLength);
  TArrayUtils.Copy<Byte>(AKey, 0, FKeyBytes, 0, PublicKeyLength);
end;

constructor TPublicKey.Create(const AKey: string);
begin
  inherited Create;
  if AKey = '' then
    raise EArgumentNilException.Create('key');
  if not FastCheck(AKey) then
    raise EArgumentException.Create
      ('publickey contains a non-base58 character, key');
  FKey := AKey;
end;

function TPublicKey.Clone: IPublicKey;
begin
  Result := TPublicKey.Create();
  Result.Key := FKey;
  Result.KeyBytes := TArrayUtils.Copy<Byte>(FKeyBytes);
end;

function TPublicKey.GetKey: string;
begin
  if FKey = '' then
  begin
    FKey := TEncoders.Base58.EncodeData(GetKeyBytes);
  end;
  Result := FKey;
end;

procedure TPublicKey.SetKey(const Value: string);
begin
  FKey := Value;
end;

function TPublicKey.GetKeyBytes: TBytes;
begin
  if Length(FKeyBytes) = 0 then
  begin
    FKeyBytes := TEncoders.Base58.DecodeData(GetKey);
  end;
  Result := FKeyBytes;
end;

procedure TPublicKey.SetKeyBytes(const Value: TBytes);
begin
  FKeyBytes := Value;
end;

function TPublicKey.Verify(const &Message, Signature: TBytes): Boolean;
begin
  Result := TEd25519Crypto.Verify(GetKeyBytes, &Message, Signature);
end;

function TPublicKey.Equals(const Other: IPublicKey): Boolean;
var
  SelfAsI: IPublicKey;
begin
  if Other = nil then
    Exit(False);

  // 1) Exact same IPublicKey reference?
  if Supports(Self, IPublicKey, SelfAsI) then
  begin
   if SelfAsI = Other then
    Exit(True);
  end;

  // 2) Value equality: same key
  Result := SameStr(SelfAsI.Key, Other.Key);
end;

function TPublicKey.ToString: string;
begin
  Result := GetKey;
end;

function TPublicKey.IsOnCurve: Boolean;
begin
  Result := TEd25519Utils.IsOnCurve(GetKeyBytes);
end;

function TPublicKey.IsValid: Boolean;
begin
  Result := (Length(GetKeyBytes) = PublicKeyLength);
end;

function TPublicKey.ToBytes: TBytes;
begin
  Result := GetKeyBytes;
end;

class function TPublicKey.IsValid(const AKey: string;
  AValidateCurve: Boolean): Boolean;
var
  Bytes: TBytes;
begin
  if AKey = '' then
    Exit(False);
  try
    if not FastCheck(AKey) then
      Exit(False);
    Bytes := TEncoders.Base58.DecodeData(AKey);
    Result := IsValid(Bytes, AValidateCurve);
  except
    Result := False;
  end;
end;

class function TPublicKey.IsValid(const AKey: TBytes;
  AValidateCurve: Boolean): Boolean;
begin
  Result := (Length(AKey) = PublicKeyLength) and
    (not AValidateCurve or TEd25519Utils.IsOnCurve(AKey));
end;

class function TPublicKey.FastCheck(const Value: string): Boolean;
begin
  Result := TEncoders.Base58.IsValid(Value);
end;

class function TPublicKey.TryCreateProgramAddress(const Seeds: TArray<TBytes>;
  const ProgramId: IPublicKey; out PublicKey: IPublicKey): Boolean;
var
  MS: TMemoryStream;
  Seed, Hash, Buf: TBytes;
begin
  PublicKey := nil;

  MS := TMemoryStream.Create();
  try
    MS.Position := 0;
    // Validate seeds length constraint
    for Seed in Seeds do
    begin
      if Length(Seed) > PublicKeyLength then
        raise EArgumentException.Create('max seed length exceeded, seeds');

      if Length(Seed) > 0 then
        MS.WriteBuffer(Seed[0], Length(Seed));
    end;

    // programId bytes
    if Length(ProgramId.KeyBytes) > 0 then
      MS.WriteBuffer(ProgramId.KeyBytes[0], Length(ProgramId.KeyBytes));

    // "ProgramDerivedAddress"
    MS.WriteBuffer(ProgramDerivedAddressBytes[0],
      Length(ProgramDerivedAddressBytes));

    // read stream into bytes
    SetLength(Buf, MS.Size);
    if MS.Size > 0 then
    begin
      MS.Position := 0;
      MS.ReadBuffer(Buf[0], MS.Size);
    end;

    Hash := TSHA256.HashData(Buf);
  finally
    MS.Free;
  end;

  if TEd25519Utils.IsOnCurve(Hash) then
  begin
    PublicKey := nil;
    Exit(False);
  end;

  PublicKey := TPublicKey.Create(Hash);
  Result := True;
end;

class function TPublicKey.TryFindProgramAddress(const Seeds: TArray<TBytes>;
  const ProgramId: IPublicKey; out Address: IPublicKey; out Bump: Byte)
  : Boolean;
var
  SeedBump: Byte;
  Buf: TList<TBytes>;
  AllSeeds: TArray<TBytes>;
  BumpArr: TBytes;
  Ok: Boolean;
  DerivedAddress: IPublicKey;
begin
  SeedBump := 255;
  Address := nil;
  Bump := 0;

  Buf := TList<TBytes>.Create;
  try
    // copy initial seeds
    Buf.AddRange(Seeds);

    SetLength(BumpArr, 1);
    Buf.Add(BumpArr);
    AllSeeds := Buf.ToArray;

    while SeedBump <> 0 do
    begin
      BumpArr[0] := SeedBump;

      Ok := TryCreateProgramAddress(AllSeeds, ProgramId, DerivedAddress);
      if Ok then
      begin
        Address := DerivedAddress;
        Bump := SeedBump;
        Exit(True);
      end;

      Dec(SeedBump);
    end;

    // not found
    Address := nil;
    Bump := 0;
    Result := False;
  finally
    Buf.Free;
  end;
end;

class function TPublicKey.TryCreateWithSeed(const FromPublicKey: IPublicKey; const Seed: string; const ProgramId: IPublicKey; out PublicKeyOut: IPublicKey): Boolean;
var
  MS: TMemoryStream;
  Seeds, Slice, Hash, Utf8: TBytes;
  L: Integer;
begin
  PublicKeyOut := nil;

  MS := TMemoryStream.Create;
  try
    MS.Position := 0;
    // seeds = fromPublicKey || UTF8(seed) || programId
    if Length(FromPublicKey.KeyBytes) > 0 then
      MS.WriteBuffer(FromPublicKey.KeyBytes[0], Length(FromPublicKey.KeyBytes));

    Utf8 := TEncoding.UTF8.GetBytes(Seed);
    if Length(Utf8) > 0 then
      MS.WriteBuffer(Utf8[0], Length(Utf8));

    if Length(ProgramId.KeyBytes) > 0 then
      MS.WriteBuffer(ProgramId.KeyBytes[0], Length(ProgramId.KeyBytes));

    SetLength(Seeds, MS.Size);
    if MS.Size > 0 then
    begin
      MS.Position := 0;
      MS.ReadBuffer(Seeds[0], MS.Size);
    end;
  finally
    MS.Free;
  end;

  // if seeds ends with "ProgramDerivedAddress", fail (PDA)
  L := Length(Seeds);
  if L >= Length(ProgramDerivedAddressBytes) then
  begin
    Slice := TArrayUtils.Slice<Byte>(Seeds, L - Length(ProgramDerivedAddressBytes));

    if Length(Slice) <> Length(ProgramDerivedAddressBytes) then
    Exit(False);

    if CompareMem(@Slice[0], @ProgramDerivedAddressBytes[0], Length(Slice)) then
      Exit(False);
  end;

  Hash := TSHA256.HashData(Seeds);
  PublicKeyOut := TPublicKey.Create(Hash);
  Result := True;
end;

class function TPublicKey.FromString(const S: string): IPublicKey;
begin
  Result := TPublicKey.Create(S);
end;

class function TPublicKey.FromBytes(const B: TBytes): IPublicKey;
begin
  Result := TPublicKey.Create(B);
end;

end.

