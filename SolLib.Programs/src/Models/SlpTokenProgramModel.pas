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

unit SlpTokenProgramModel;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpPublicKey,
  SlpDeserialization,
  SlpSystemProgram,
  SlpNullable;

type
  {********************************************************************************************************************}
  {                                                  MultiSignatureAccount                                             }
  {********************************************************************************************************************}

  /// <summary>
  /// Represents a <c>TokenProgram</c> Multi Signature Account in Solana.
  /// </summary>
  IMultiSignatureAccount = interface
    ['{5E56F2B1-81C2-4BCE-8A9D-2E3E7CFE8E25}']

    /// <summary>Number of signers required</summary>
    function GetMinimumSigners: Byte;
    procedure SetMinimumSigners(const AValue: Byte);

    /// <summary>Number of valid signers</summary>
    function GetNumberSigners: Byte;
    procedure SetNumberSigners(const AValue: Byte);

    /// <summary>Whether the account has been initialized</summary>
    function GetIsInitialized: Boolean;
    procedure SetIsInitialized(const AValue: Boolean);

    /// <summary>Signer public keys</summary>
    function GetSigners: TList<IPublicKey>;
    procedure SetSigners(const AValue: TList<IPublicKey>);

    property MinimumSigners: Byte read GetMinimumSigners write SetMinimumSigners;
    property NumberSigners: Byte read GetNumberSigners write SetNumberSigners;
    property IsInitialized: Boolean read GetIsInitialized write SetIsInitialized;
    property Signers: TList<IPublicKey> read GetSigners write SetSigners;
  end;

  /// <summary>
  /// Represents a <c>TokenProgram</c> Multi Signature Account in Solana.
  /// </summary>
  TMultiSignatureAccount = class(TInterfacedObject, IMultiSignatureAccount)
  public
    /// <summary>
    /// The maximum number of signers.
    /// </summary>
    const MaxSigners = 11;

    /// <summary>
    /// The layout of the <see cref="TMultiSignatureAccount"/> structure.
    /// </summary>
    type
     TLayout = record
    public
      /// <summary>The length of the structure.</summary>
      const Length = 355;
      /// <summary>The offset at which the number of signers required value begins.</summary>
      const MinimumSignersOffset = 0;
      /// <summary>The offset at which the number of valid signers value begins.</summary>
      const NumberSignersOffset = 1;
      /// <summary>The offset at which the is initialized value begins.</summary>
      const IsInitializedOffset = 2;
      /// <summary>The offset at which the array with signers' public keys begins.</summary>
      const SignersOffset = 3;
    end;
  private
    FMinimumSigners: Byte;
    FNumberSigners: Byte;
    FIsInitialized: Boolean;
    FSigners: TList<IPublicKey>;

    function GetMinimumSigners: Byte;
    procedure SetMinimumSigners(const AValue: Byte);
    function GetNumberSigners: Byte;
    procedure SetNumberSigners(const AValue: Byte);
    function GetIsInitialized: Boolean;
    procedure SetIsInitialized(const AValue: Boolean);
    function GetSigners: TList<IPublicKey>;
    procedure SetSigners(const AValue: TList<IPublicKey>);
  public
    destructor Destroy; override;

    /// <summary>
    /// Deserialize the given data into the <see cref="TMultiSignatureAccount"/> structure.
    /// </summary>
    /// <param name="AData">The data.</param>
    /// <returns>The <see cref="IMultiSignatureAccount"/> structure.</returns>
    class function Deserialize(const AData: TBytes): IMultiSignatureAccount; static;
  end;

  {********************************************************************************************************************}
  {                                                     TokenAccount                                                   }
  {********************************************************************************************************************}

    /// <summary>
    /// Represents the state of a token account.
    /// </summary>
    TTokenAccountState = (
      /// <summary>Account is uninitialized.</summary>
      Uninitialized,
      /// <summary>Account is initialized. The owner and/or delegate may operate the account.</summary>
      Initialized,
      /// <summary>The account is frozen. The owner and delegate can't operate the account.</summary>
      Frozen
   );

  /// <summary>
  /// Represents a <c>TokenProgram</c> token account.
  /// </summary>
  ITokenAccount = interface
    ['{C26D8E36-42C9-4E39-8F8E-0E3F6EADD0B7}']

    /// <summary>The token mint.</summary>
    function GetMint: IPublicKey;
    procedure SetMint(const AValue: IPublicKey);

    /// <summary>The owner of the token account.</summary>
    function GetOwner: IPublicKey;
    procedure SetOwner(const AValue: IPublicKey);

    /// <summary>The amount of tokens this account holds.</summary>
    function GetAmount: UInt64;
    procedure SetAmount(const AValue: UInt64);

    /// <summary>
    /// Delegate address. If Delegate has value then DelegatedAmount represents the amount authorized by the delegate.
    /// </summary>
    function GetDelegate: IPublicKey;
    procedure SetDelegate(const AValue: IPublicKey);

    /// <summary>Represents the state of this account.</summary>
    function GetState: TTokenAccountState;
    procedure SetState(const AValue: TTokenAccountState);

    /// <summary>
    /// If IsNative has value, this is a native token and the value logs the rent-exempt reserve.
    /// </summary>
    function GetIsNative: TNullable<UInt64>;
    procedure SetIsNative(const AValue: TNullable<UInt64>);

    /// <summary>The amount delegated.</summary>
    function GetDelegatedAmount: UInt64;
    procedure SetDelegatedAmount(const AValue: UInt64);

    /// <summary>Optional authority to close the account.</summary>
    function GetCloseAuthority: IPublicKey;
    procedure SetCloseAuthority(const AValue: IPublicKey);

    property Mint: IPublicKey read GetMint write SetMint;
    property Owner: IPublicKey read GetOwner write SetOwner;
    property Amount: UInt64 read GetAmount write SetAmount;
    property Delegate: IPublicKey read GetDelegate write SetDelegate;
    property State: TTokenAccountState read GetState write SetState;
    property IsNative: TNullable<UInt64> read GetIsNative write SetIsNative;
    property DelegatedAmount: UInt64 read GetDelegatedAmount write SetDelegatedAmount;
    property CloseAuthority: IPublicKey read GetCloseAuthority write SetCloseAuthority;
  end;

  /// <summary>
  /// Represents a <c>TokenProgram</c> token account.
  /// </summary>
  TTokenAccount = class(TInterfacedObject, ITokenAccount)
  public

    /// <summary>
    /// The layout of the <see cref="TTokenAccount"/> structure.
    /// </summary>
  type
    TLayout = record
    public
      /// <summary>The length of the structure.</summary>
      const Length = 165;
      /// <summary>The offset at which the token mint pubkey begins.</summary>
      const MintOffset = 0;
      /// <summary>The offset at which the owner pubkey begins.</summary>
      const OwnerOffset = 32;
      /// <summary>The offset at which the amount value begins.</summary>
      const AmountOffset = 64;
      /// <summary>The offset at which the delegate pubkey COption value begins.</summary>
      const DelegateOptionOffset = 72;
      /// <summary>The offset at which the delegate pubkey value begins.</summary>
      const DelegateOffset = 76;
      /// <summary>The offset at which the state value begins.</summary>
      const StateOffset = 108;
      /// <summary>The offset at which the IsNative COption begins.</summary>
      const IsNativeOptionOffset = 109;
      /// <summary>The offset at which the IsNative begins.</summary>
      const IsNativeOffset = 113;
      /// <summary>The offset at which the delegated amount value begins.</summary>
      const DelegatedAmountOffset = 121;
      /// <summary>The offset at which the close authority pubkey COption begins.</summary>
      const CloseAuthorityOptionOffset = 129;
      /// <summary>The offset at which the close authority pubkey begins.</summary>
      const CloseAuthorityOffset = 133;
    end;
  private
    FMint: IPublicKey;
    FOwner: IPublicKey;
    FAmount: UInt64;
    FDelegate: IPublicKey;
    FState: TTokenAccountState;
    FIsNative: TNullable<UInt64>;
    FDelegatedAmount: UInt64;
    FCloseAuthority: IPublicKey;

    function GetMint: IPublicKey;
    procedure SetMint(const AValue: IPublicKey);
    function GetOwner: IPublicKey;
    procedure SetOwner(const AValue: IPublicKey);
    function GetAmount: UInt64;
    procedure SetAmount(const AValue: UInt64);
    function GetDelegate: IPublicKey;
    procedure SetDelegate(const AValue: IPublicKey);
    function GetState: TTokenAccountState;
    procedure SetState(const AValue: TTokenAccountState);
    function GetIsNative: TNullable<UInt64>;
    procedure SetIsNative(const AValue: TNullable<UInt64>);
    function GetDelegatedAmount: UInt64;
    procedure SetDelegatedAmount(const AValue: UInt64);
    function GetCloseAuthority: IPublicKey;
    procedure SetCloseAuthority(const AValue: IPublicKey);

  public
    /// <summary>
    /// Deserialize the given data into the <see cref="TTokenAccount"/> structure.
    /// </summary>
    /// <param name="AData">The data.</param>
    /// <returns>The <see cref="ITokenAccount"/> structure.</returns>
    class function Deserialize(const AData: TBytes): ITokenAccount; static;
  end;

  {********************************************************************************************************************}
  {                                                      TokenMint                                                    }
  {********************************************************************************************************************}

  /// <summary>
  /// Represents a <c>TokenProgram</c> token mint account.
  /// </summary>
  ITokenMint = interface
    ['{CB7D1B02-4B07-4C44-9516-6E17B7AF3C0A}']
    /// <summary>Optional authority to mint new tokens. If no mint authority is present, no new tokens can be issued.</summary>
    function GetMintAuthority: IPublicKey;
    procedure SetMintAuthority(const AValue: IPublicKey);

    /// <summary>Total supply of tokens.</summary>
    function GetSupply: UInt64;
    procedure SetSupply(const AValue: UInt64);

    /// <summary>Number of base 10 digits to the right of the decimal place.</summary>
    function GetDecimals: Byte;
    procedure SetDecimals(const AValue: Byte);

    /// <summary>Whether or not the account has been initialized.</summary>
    function GetIsInitialized: Boolean;
    procedure SetIsInitialized(const AValue: Boolean);

    /// <summary>Optional authority to freeze token accounts.</summary>
    function GetFreezeAuthority: IPublicKey;
    procedure SetFreezeAuthority(const AValue: IPublicKey);

    property MintAuthority: IPublicKey read GetMintAuthority write SetMintAuthority;
    property Supply: UInt64 read GetSupply write SetSupply;
    property Decimals: Byte read GetDecimals write SetDecimals;
    property IsInitialized: Boolean read GetIsInitialized write SetIsInitialized;
    property FreezeAuthority: IPublicKey read GetFreezeAuthority write SetFreezeAuthority;
  end;

  /// <summary>
  /// Represents a <c>TokenProgram</c> token mint account.
  /// </summary>
  TTokenMint = class(TInterfacedObject, ITokenMint)
  public
    /// <summary>
    /// The layout of the <see cref="TTokenMint"/> structure.
    /// </summary>
    type
     TLayout = record
    public
      /// <summary>The length of the structure.</summary>
      const Length = 82;
      /// <summary>The offset at which the mint authority COption begins.</summary>
      const MintAuthorityOptionOffset = 0;
      /// <summary>The offset at which the mint authority pubkey value begins.</summary>
      const MintAuthorityOffset = 4;
      /// <summary>The offset at which the supply value begins.</summary>
      const SupplyOffset = 36;
      /// <summary>The offset at which the decimals value begins.</summary>
      const DecimalsOffset = 44;
      /// <summary>The offset at which the is initialized value begins.</summary>
      const IsInitializedOffset = 45;
      /// <summary>The offset at which the freeze authority COption begins.</summary>
      const FreezeAuthorityOptionOffset = 46;
      /// <summary>The offset at which the freeze authority pubkey value begins.</summary>
      const FreezeAuthorityOffset = 50;
    end;
  private
    FMintAuthority: IPublicKey;
    FSupply: UInt64;
    FDecimals: Byte;
    FIsInitialized: Boolean;
    FFreezeAuthority: IPublicKey;

    function GetMintAuthority: IPublicKey;
    procedure SetMintAuthority(const AValue: IPublicKey);
    function GetSupply: UInt64;
    procedure SetSupply(const AValue: UInt64);
    function GetDecimals: Byte;
    procedure SetDecimals(const AValue: Byte);
    function GetIsInitialized: Boolean;
    procedure SetIsInitialized(const AValue: Boolean);
    function GetFreezeAuthority: IPublicKey;
    procedure SetFreezeAuthority(const AValue: IPublicKey);
  public
    /// <summary>
    /// Deserialize the given data into the <see cref="TTokenMint"/> structure.
    /// </summary>
    /// <param name="AData">The data.</param>
    /// <returns>The <see cref="ITokenMint"/> structure.</returns>
    class function Deserialize(const AData: TBytes): ITokenMint; static;
  end;

implementation

{ TMultiSignatureAccount }

destructor TMultiSignatureAccount.Destroy;
begin
  if Assigned(FSigners) then FSigners.Free;
  inherited;
end;

function TMultiSignatureAccount.GetIsInitialized: Boolean;
begin
  Result := FIsInitialized;
end;

function TMultiSignatureAccount.GetMinimumSigners: Byte;
begin
  Result := FMinimumSigners;
end;

function TMultiSignatureAccount.GetNumberSigners: Byte;
begin
  Result := FNumberSigners;
end;

function TMultiSignatureAccount.GetSigners: TList<IPublicKey>;
begin
  Result := FSigners;
end;

procedure TMultiSignatureAccount.SetIsInitialized(const AValue: Boolean);
begin
  FIsInitialized := AValue;
end;

procedure TMultiSignatureAccount.SetMinimumSigners(const AValue: Byte);
begin
  FMinimumSigners := AValue;
end;

procedure TMultiSignatureAccount.SetNumberSigners(const AValue: Byte);
begin
  FNumberSigners := AValue;
end;

procedure TMultiSignatureAccount.SetSigners(const AValue: TList<IPublicKey>);
begin
  FSigners := AValue;
end;

class function TMultiSignatureAccount.Deserialize(
  const AData: TBytes): IMultiSignatureAccount;
var
  I: Integer;
  LSigner: IPublicKey;
begin
  if Length(AData) <> TLayout.Length then
    raise EArgumentException.CreateFmt('%s has wrong size. Expected %d bytes, actual %d bytes.',
      ['AData', TLayout.Length, Length(AData)]);

  Result := TMultiSignatureAccount.Create;

  Result.Signers := TList<IPublicKey>.Create;

  for I := 0 to MaxSigners - 1 do
  begin
    LSigner := TDeserialization.GetPubKey(AData, TLayout.SignersOffset + I * TPublicKey.PublicKeyLength);
    if not LSigner.Equals(TSystemProgram.ProgramIdKey) then
      Result.Signers.Add(LSigner);
  end;

  Result.MinimumSigners := TDeserialization.GetU8(AData, TLayout.MinimumSignersOffset);
  Result.NumberSigners  := TDeserialization.GetU8(AData, TLayout.NumberSignersOffset);
  Result.IsInitialized  := TDeserialization.GetBool(AData, TLayout.IsInitializedOffset);
end;

{ TTokenAccount }

function TTokenAccount.GetAmount: UInt64;
begin
  Result := FAmount;
end;

function TTokenAccount.GetCloseAuthority: IPublicKey;
begin
  Result := FCloseAuthority;
end;

function TTokenAccount.GetDelegate: IPublicKey;
begin
  Result := FDelegate;
end;

function TTokenAccount.GetDelegatedAmount: UInt64;
begin
  Result := FDelegatedAmount;
end;

function TTokenAccount.GetIsNative: TNullable<UInt64>;
begin
  Result := FIsNative;
end;

function TTokenAccount.GetMint: IPublicKey;
begin
  Result := FMint;
end;

function TTokenAccount.GetOwner: IPublicKey;
begin
  Result := FOwner;
end;

function TTokenAccount.GetState: TTokenAccountState;
begin
  Result := FState;
end;

procedure TTokenAccount.SetAmount(const AValue: UInt64);
begin
  FAmount := AValue;
end;

procedure TTokenAccount.SetCloseAuthority(const AValue: IPublicKey);
begin
  FCloseAuthority := AValue;
end;

procedure TTokenAccount.SetDelegate(const AValue: IPublicKey);
begin
  FDelegate := AValue;
end;

procedure TTokenAccount.SetDelegatedAmount(const AValue: UInt64);
begin
  FDelegatedAmount := AValue;
end;

procedure TTokenAccount.SetIsNative(const AValue: TNullable<UInt64>);
begin
  FIsNative := AValue;
end;

procedure TTokenAccount.SetMint(const AValue: IPublicKey);
begin
  FMint := AValue;
end;

procedure TTokenAccount.SetOwner(const AValue: IPublicKey);
begin
  FOwner := AValue;
end;

procedure TTokenAccount.SetState(const AValue: TTokenAccountState);
begin
  FState := AValue;
end;

class function TTokenAccount.Deserialize(const AData: TBytes): ITokenAccount;
begin
  if Length(AData) <> TLayout.Length then
    raise EArgumentException.CreateFmt('%s has wrong size. Expected %d bytes, actual %d bytes.',
      ['AData', TLayout.Length, Length(AData)]);

  Result := TTokenAccount.Create;

  Result.Mint   := TDeserialization.GetPubKey(AData, TLayout.MintOffset);
  Result.Owner  := TDeserialization.GetPubKey(AData, TLayout.OwnerOffset);
  Result.Amount := TDeserialization.GetU64(AData, TLayout.AmountOffset);

  Result.State           := TTokenAccountState(TDeserialization.GetU8(AData, TLayout.StateOffset));
  Result.DelegatedAmount := TDeserialization.GetU64(AData, TLayout.DelegatedAmountOffset);

  if TDeserialization.GetU32(AData, TLayout.DelegateOptionOffset) = 1 then
    Result.Delegate := TDeserialization.GetPubKey(AData, TLayout.DelegateOffset);

  if TDeserialization.GetU32(AData, TLayout.IsNativeOptionOffset) = 1 then
    Result.IsNative := TDeserialization.GetU64(AData, TLayout.IsNativeOffset);

  if TDeserialization.GetU32(AData, TLayout.CloseAuthorityOptionOffset) = 1 then
    Result.CloseAuthority := TDeserialization.GetPubKey(AData, TLayout.CloseAuthorityOffset);
end;

{ TTokenMint }

function TTokenMint.GetDecimals: Byte;
begin
  Result := FDecimals;
end;

function TTokenMint.GetFreezeAuthority: IPublicKey;
begin
  Result := FFreezeAuthority;
end;

function TTokenMint.GetIsInitialized: Boolean;
begin
  Result := FIsInitialized;
end;

function TTokenMint.GetMintAuthority: IPublicKey;
begin
  Result := FMintAuthority;
end;

function TTokenMint.GetSupply: UInt64;
begin
  Result := FSupply;
end;

procedure TTokenMint.SetDecimals(const AValue: Byte);
begin
  FDecimals := AValue;
end;

procedure TTokenMint.SetFreezeAuthority(const AValue: IPublicKey);
begin
  FFreezeAuthority := AValue;
end;

procedure TTokenMint.SetIsInitialized(const AValue: Boolean);
begin
  FIsInitialized := AValue;
end;

procedure TTokenMint.SetMintAuthority(const AValue: IPublicKey);
begin
  FMintAuthority := AValue;
end;

procedure TTokenMint.SetSupply(const AValue: UInt64);
begin
  FSupply := AValue;
end;

class function TTokenMint.Deserialize(const AData: TBytes): ITokenMint;
begin
  if Length(AData) <> TLayout.Length then
    raise EArgumentException.CreateFmt('%s has wrong size. Expected %d bytes, actual %d bytes.',
      ['AData', TLayout.Length, Length(AData)]);

  Result := TTokenMint.Create;

  if TDeserialization.GetU32(AData, TLayout.MintAuthorityOptionOffset) = 1 then
    Result.MintAuthority := TDeserialization.GetPubKey(AData, TLayout.MintAuthorityOffset);

  Result.Supply        := TDeserialization.GetU64(AData, TLayout.SupplyOffset);
  Result.Decimals      := TDeserialization.GetU8(AData, TLayout.DecimalsOffset);
  Result.IsInitialized := TDeserialization.GetBool(AData, TLayout.IsInitializedOffset);

  if TDeserialization.GetU32(AData, TLayout.FreezeAuthorityOptionOffset) = 1 then
    Result.FreezeAuthority := TDeserialization.GetPubKey(AData, TLayout.FreezeAuthorityOffset);
end;

end.

