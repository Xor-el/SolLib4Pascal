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
  SysUtils,
  Classes,
  Generics.Collections,
  SlpDataEncoderUtilities,
  SlpCryptoUtilities,
  SlpArrayUtilities;

type
  IPublicKey = interface
    ['{A1F2B3C4-D5E6-47A8-9B0C-1D2E3F4A5B6C}']

    function GetKey: string;
    procedure SetKey(const AValue: string);
    function GetKeyBytes: TBytes;
    procedure SetKeyBytes(const AValue: TBytes);

    function Verify(const AMessage, ASignature: TBytes): Boolean;
    function IsOnCurve: Boolean;
    function IsValid: Boolean;
    function ToBytes: TBytes;
    function Clone: IPublicKey;

    function Equals(const AOther: IPublicKey): Boolean;
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

    class function FastCheck(const AValue: string): Boolean; static;

    function GetKey: string;
    procedure SetKey(const AValue: string);
    function GetKeyBytes: TBytes;
    procedure SetKeyBytes(const AValue: TBytes);

    /// <summary>
    /// Verify the signed message.
    /// </summary>
    /// <param name="message">The signed message.</param>
    /// <param name="signature">The signature of the message.</param>
    function Verify(const AMessage, ASignature: TBytes): Boolean;

    function Clone(): IPublicKey;

    /// Equality compares public keys.
    function Equals(const AOther: IPublicKey): Boolean; reintroduce;

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
    class function IsValid(const AKey: string; AValidateCurve: Boolean = False): Boolean; overload; static;

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
    class function IsValid(const AKey: TBytes; AValidateCurve: Boolean = False): Boolean; overload; static;

    { #region KeyDerivation }

    /// <summary>
    /// Derives a program address.
    /// </summary>
    /// <param name="Seeds">The address seeds.</param>
    /// <param name="ProgramId">The program Id.</param>
    /// <param name="PublicKey">The derived public key, returned as inline out.</param>
    /// <returns>true if it could derive the program address for the given seeds, otherwise false..</returns>
    /// <exception cref="ArgumentException">Throws exception when one of the seeds has an invalid length.</exception>
    class function TryCreateProgramAddress(const ASeeds: TArray<TBytes>;
      const AProgramId: IPublicKey; out APublicKey: IPublicKey): Boolean; static;

    /// <summary>
    /// Attempts to find a program address for the passed seeds and program Id.
    /// </summary>
    /// <param name="Seeds">The address seeds.</param>
    /// <param name="ProgramId">The program Id.</param>
    /// <param name="Address">The derived address, returned as inline out.</param>
    /// <param name="Bump">The bump used to derive the address, returned as inline out.</param>
    /// <returns>True whenever the address for a nonce was found, otherwise false.</returns>
    class function TryFindProgramAddress(const ASeeds: TArray<TBytes>;
      const AProgramId: IPublicKey; out AAddress: IPublicKey; out ABump: Byte): Boolean; static;

    /// <summary>
    /// Derives a new public key from an existing public key and seed
    /// </summary>
    /// <param name="FromPublicKey">The extant pubkey</param>
    /// <param name="Seed">The seed</param>
    /// <param name="ProgramId">The programid</param>
    /// <param name="PublicKeyOut">The derived public key</param>
    /// <returns>True whenever the address was successfully created, otherwise false.</returns>
    /// <remarks>To fail address creation, means the created address was a PDA.</remarks>
    class function TryCreateWithSeed(const AFromPublicKey: IPublicKey; const ASeed: string; const AProgramId: IPublicKey; out APublicKeyOut: IPublicKey): Boolean; static;

    class function FromString(const AStr: string): IPublicKey; static;

    class function FromBytes(const ABytes: TBytes): IPublicKey; static;

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
  TArrayUtilities.Copy<Byte>(AKey, 0, FKeyBytes, 0, PublicKeyLength);
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
  Result.KeyBytes := TArrayUtilities.Copy<Byte>(FKeyBytes);
end;

function TPublicKey.GetKey: string;
begin
  if FKey = '' then
  begin
    FKey := TBase58Encoder.EncodeData(GetKeyBytes);
  end;
  Result := FKey;
end;

procedure TPublicKey.SetKey(const AValue: string);
begin
  FKey := AValue;
end;

function TPublicKey.GetKeyBytes: TBytes;
begin
  if Length(FKeyBytes) = 0 then
  begin
    FKeyBytes := TBase58Encoder.DecodeData(GetKey);
  end;
  Result := FKeyBytes;
end;

procedure TPublicKey.SetKeyBytes(const AValue: TBytes);
begin
  FKeyBytes := AValue;
end;

function TPublicKey.Verify(const AMessage, ASignature: TBytes): Boolean;
begin
  Result := TEd25519Crypto.Verify(GetKeyBytes, AMessage, ASignature);
end;

function TPublicKey.Equals(const AOther: IPublicKey): Boolean;
var
  LSelfAsI: IPublicKey;
begin
  if AOther = nil then
    Exit(False);

  // 1) Exact same IPublicKey reference?
  if Supports(Self, IPublicKey, LSelfAsI) then
  begin
   if LSelfAsI = AOther then
    Exit(True);
  end;

  // 2) Value equality: same key
  Result := SameStr(LSelfAsI.Key, AOther.Key);
end;

function TPublicKey.ToString: string;
begin
  Result := GetKey;
end;

function TPublicKey.IsOnCurve: Boolean;
begin
  Result := TEd25519Crypto.IsOnCurve(GetKeyBytes);
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
  LBytes: TBytes;
begin
  if AKey = '' then
    Exit(False);
  try
    if not FastCheck(AKey) then
      Exit(False);
    LBytes := TBase58Encoder.DecodeData(AKey);
    Result := IsValid(LBytes, AValidateCurve);
  except
    Result := False;
  end;
end;

class function TPublicKey.IsValid(const AKey: TBytes;
  AValidateCurve: Boolean): Boolean;
begin
  Result := (Length(AKey) = PublicKeyLength) and
    (not AValidateCurve or TEd25519Crypto.IsOnCurve(AKey));
end;

class function TPublicKey.FastCheck(const AValue: string): Boolean;
begin
  Result := TBase58Encoder.IsValidCharset(AValue);
end;

class function TPublicKey.TryCreateProgramAddress(const ASeeds: TArray<TBytes>;
  const AProgramId: IPublicKey; out APublicKey: IPublicKey): Boolean;
var
  LMS: TMemoryStream;
  LSeed, LHash, LBuf: TBytes;
begin
  APublicKey := nil;

  LMS := TMemoryStream.Create();
  try
    LMS.Position := 0;
    // Validate seeds length constraint
    for LSeed in ASeeds do
    begin
      if Length(LSeed) > PublicKeyLength then
        raise EArgumentException.Create('max seed length exceeded, seeds');

      if Length(LSeed) > 0 then
        LMS.WriteBuffer(LSeed[0], Length(LSeed));
    end;

    // programId bytes
    if Length(AProgramId.KeyBytes) > 0 then
      LMS.WriteBuffer(AProgramId.KeyBytes[0], Length(AProgramId.KeyBytes));

    // "ProgramDerivedAddress"
    LMS.WriteBuffer(ProgramDerivedAddressBytes[0],
      Length(ProgramDerivedAddressBytes));

    // read stream into bytes
    SetLength(LBuf, LMS.Size);
    if LMS.Size > 0 then
    begin
      LMS.Position := 0;
      LMS.ReadBuffer(LBuf[0], LMS.Size);
    end;

    LHash := TSHA256.HashData(LBuf);
  finally
    LMS.Free;
  end;

  if TEd25519Crypto.IsOnCurve(LHash) then
  begin
    APublicKey := nil;
    Exit(False);
  end;

  APublicKey := TPublicKey.Create(LHash);
  Result := True;
end;

class function TPublicKey.TryFindProgramAddress(const ASeeds: TArray<TBytes>;
  const AProgramId: IPublicKey; out AAddress: IPublicKey; out ABump: Byte): Boolean;
var
  LSeedBump: Byte;
  LBuf: TList<TBytes>;
  LAllSeeds: TArray<TBytes>;
  LBumpArr: TBytes;
  LOk: Boolean;
  LDerivedAddress: IPublicKey;
begin
  LSeedBump := 255;
  AAddress := nil;
  ABump := 0;

  LBuf := TList<TBytes>.Create;
  try
    // copy initial seeds
    LBuf.AddRange(ASeeds);

    SetLength(LBumpArr, 1);
    LBuf.Add(LBumpArr);
    LAllSeeds := LBuf.ToArray;

    while LSeedBump <> 0 do
    begin
      LBumpArr[0] := LSeedBump;

      LOk := TryCreateProgramAddress(LAllSeeds, AProgramId, LDerivedAddress);
      if LOk then
      begin
        AAddress := LDerivedAddress;
        ABump := LSeedBump;
        Exit(True);
      end;

      Dec(LSeedBump);
    end;

    // not found
    AAddress := nil;
    ABump := 0;
    Result := False;
  finally
    LBuf.Free;
  end;
end;

class function TPublicKey.TryCreateWithSeed(const AFromPublicKey: IPublicKey; const ASeed: string; const AProgramId: IPublicKey; out APublicKeyOut: IPublicKey): Boolean;
var
  LMS: TMemoryStream;
  LSeeds, LSlice, LHash, LUtf8: TBytes;
  LLen: Integer;
begin
  APublicKeyOut := nil;

  LMS := TMemoryStream.Create;
  try
    LMS.Position := 0;
    // seeds = fromPublicKey || UTF8(seed) || programId
    if Length(AFromPublicKey.KeyBytes) > 0 then
      LMS.WriteBuffer(AFromPublicKey.KeyBytes[0], Length(AFromPublicKey.KeyBytes));

    LUtf8 := TEncoding.UTF8.GetBytes(ASeed);
    if Length(LUtf8) > 0 then
      LMS.WriteBuffer(LUtf8[0], Length(LUtf8));

    if Length(AProgramId.KeyBytes) > 0 then
      LMS.WriteBuffer(AProgramId.KeyBytes[0], Length(AProgramId.KeyBytes));

    SetLength(LSeeds, LMS.Size);
    if LMS.Size > 0 then
    begin
      LMS.Position := 0;
      LMS.ReadBuffer(LSeeds[0], LMS.Size);
    end;
  finally
    LMS.Free;
  end;

  // if seeds ends with "ProgramDerivedAddress", fail (PDA)
  LLen := Length(LSeeds);
  if LLen >= Length(ProgramDerivedAddressBytes) then
  begin
    LSlice := TArrayUtilities.Slice<Byte>(LSeeds, LLen - Length(ProgramDerivedAddressBytes));

    if Length(LSlice) <> Length(ProgramDerivedAddressBytes) then
    Exit(False);

    if CompareMem(@LSlice[0], @ProgramDerivedAddressBytes[0], Length(LSlice)) then
      Exit(False);
  end;

  LHash := TSHA256.HashData(LSeeds);
  APublicKeyOut := TPublicKey.Create(LHash);
  Result := True;
end;

class function TPublicKey.FromString(const AStr: string): IPublicKey;
begin
  Result := TPublicKey.Create(AStr);
end;

class function TPublicKey.FromBytes(const ABytes: TBytes): IPublicKey;
begin
  Result := TPublicKey.Create(ABytes);
end;

end.

