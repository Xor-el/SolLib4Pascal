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

unit SlpTokenDomain;

{$I ..\Include\SolLib.inc}

interface

uses
 System.SysUtils,
 System.Generics.Collections;

type

  ITokenQuantity = interface;

  ITokenDef = interface
    ['{F3B7F03B-3C2E-4F4D-A9C2-A88C2D5B7E5B}']
    function GetTokenMint: string;
    function GetTokenName: string;
    function GetSymbol: string;
    function GetDecimalPlaces: Integer;
    function GetCoinGeckoId: string;
    function GetTokenProjectUrl: string;
    function GetTokenLogoUrl: string;

    procedure SetCoinGeckoId(const AValue: string);
    procedure SetTokenProjectUrl(const AValue: string);
    procedure SetTokenLogoUrl(const AValue: string);

    function CreateQuantity(AValueDecimal: Double; AValueRaw: UInt64): ITokenQuantity;
    function CreateQuantityWithRaw(AValue: UInt64): ITokenQuantity;
    function CreateQuantityWithDecimal(AValue: Double): ITokenQuantity;

    function ConvertUInt64ToDouble(AValue: UInt64): Double;
    function ConvertDoubleToUInt64(AValue: Double): UInt64;

    function CloneWithKnownDecimals(ADecimalPlaces: Integer): ITokenDef;

    function Clone: ITokenDef;

    property TokenMint: string read GetTokenMint;
    property TokenName: string read GetTokenName;
    property Symbol: string read GetSymbol;
    property DecimalPlaces: Integer read GetDecimalPlaces;
    property CoinGeckoId: string read GetCoinGeckoId write SetCoinGeckoId;
    property TokenProjectUrl: string read GetTokenProjectUrl write SetTokenProjectUrl;
    property TokenLogoUrl: string read GetTokenLogoUrl write SetTokenLogoUrl;
  end;

  /// <summary>
  /// Token definition object, describes a token and provides helper functions.
  /// </summary>
  TTokenDef = class(TInterfacedObject, ITokenDef)
  private
    FTokenMint: string;
    FTokenName: string;
    FSymbol: string;
    FDecimalPlaces: Integer;
    FCoinGeckoId: string;
    FTokenProjectUrl: string;
    FTokenLogoUrl: string;

    function GetTokenMint: string;
    function GetTokenName: string;
    function GetSymbol: string;
    function GetDecimalPlaces: Integer;
    function GetCoinGeckoId: string;
    function GetTokenProjectUrl: string;
    function GetTokenLogoUrl: string;

    procedure SetCoinGeckoId(const AValue: string);
    procedure SetTokenProjectUrl(const AValue: string);
    procedure SetTokenLogoUrl(const AValue: string);

    function CreateQuantity(AValueDecimal: Double; AValueRaw: UInt64): ITokenQuantity;
    function CreateQuantityWithRaw(AValue: UInt64): ITokenQuantity;
    function CreateQuantityWithDecimal(AValue: Double): ITokenQuantity;

    function ConvertDoubleToUInt64(AValue: Double): UInt64;
    function ConvertUInt64ToDouble(AValue: UInt64): Double;

    function CloneWithKnownDecimals(ADecimalPlaces: Integer): ITokenDef;

    function Clone: ITokenDef;

  public
    constructor Create(const AMint, AName, ASymbol: string; ADecimalPlaces: Integer);
  end;

   ITokenQuantity = interface
      ['{C5E6F0D8-39E6-4BE2-9E7C-9C1E0F5C2C31}']
      function GetTokenDef: ITokenDef;
      function GetTokenMint: string;
      function GetTokenName: string;
      function GetSymbol: string;
      function GetDecimalPlaces: Integer;
      function GetQuantityDouble: Double;
      function GetQuantityRaw: UInt64;

      function AddQuantity(AValueDecimal: Double; AValueRaw: UInt64): ITokenQuantity;

      function ToString: string;

      property TokenDef: ITokenDef read GetTokenDef;
      property TokenMint: string read GetTokenMint;
      property TokenName: string read GetTokenName;
      property Symbol: string read GetSymbol;
      property DecimalPlaces: Integer read GetDecimalPlaces;
      property QuantityDouble: Double read GetQuantityDouble;
      property QuantityRaw: UInt64 read GetQuantityRaw;
  end;

  /// <summary>
  /// Represents a token quantity of a known mint with a known number of decimal places.
  /// </summary>
  TTokenQuantity = class(TInterfacedObject, ITokenQuantity)
  private
    FTokenDef: ITokenDef;
    FTokenMint: string;
    FSymbol: string;
    FTokenName: string;
    FDecimalPlaces: Integer;
    FQuantityDouble: Double;
    FQuantityRaw: UInt64;

    function GetTokenDef: ITokenDef;
    function GetTokenMint: string;
    function GetTokenName: string;
    function GetSymbol: string;
    function GetDecimalPlaces: Integer;
    function GetQuantityDouble: Double;
    function GetQuantityRaw: UInt64;

    function AddQuantity(AValueDecimal: Double; AValueRaw: UInt64): ITokenQuantity;

  public
    constructor Create(const ATokenDef: ITokenDef; ABalanceDecimal: Double; ABalanceRaw: UInt64);

    function ToString: string; override;

  end;

  ITokenWalletBalance = interface(ITokenQuantity)
    ['{CC0F6E12-4EFB-4B41-9B1C-2A6FBB0D5F6E}']
    function GetLamports: UInt64;
    function GetAccountCount: Integer;

    function GetText: string;

    /// <summary>
    /// Add the value of an account to this consolidated balance.
    /// Returns a new instance.
    /// </summary>
    function AddAccount(AValueDecimal: Double;
                        AValueRaw: UInt64;
                        ALamportsRaw: UInt64;
                        AAccountCount: Integer): ITokenWalletBalance;

    /// <summary>
    /// How many lamports this balance represents.
    /// </summary>
    property Lamports: UInt64 read GetLamports;
    /// <summary>
    /// Number of accounts this balance represents.
    /// </summary>
    property AccountCount: Integer read GetAccountCount;
    /// <summary>
    /// Friendly string representation.
    /// </summary>
    property Text: string read GetText;
  end;

  /// <summary>
  /// A consolidated token balance for a number of accounts of a given mint.
  /// </summary>
  TTokenWalletBalance = class(TTokenQuantity, ITokenWalletBalance)
  private
    FLamports: UInt64;
    FAccountCount: Integer;

    function GetLamports: UInt64;
    function GetAccountCount: Integer;

    /// <summary>
    /// Add the value of an account to this consolidated balance.
    /// Returns a new instance.
    /// </summary>
    function AddAccount(AValueDecimal: Double;
                        AValueRaw: UInt64;
                        ALamportsRaw: UInt64;
                        AAccountCount: Integer): ITokenWalletBalance;

    function GetText: string;
  public
    /// <summary>
    /// Constructs a TokenWalletBalance instance.
    /// </summary>
    constructor Create(const ATokenDef: ITokenDef;
                       ABalanceDecimal: Double;
                       ABalanceRaw: UInt64;
                       ALamportsRaw: UInt64;
                       AAccountCount: Integer);
  end;

  ITokenWalletAccount = interface(ITokenWalletBalance)
    ['{B8B58DB7-BA8A-47A2-8CDA-4F1C7A2D1E3A}']
    function GetOwner: string;
    function GetPublicKey: string;
    function GetIsAssociatedTokenAccount: Boolean;

    function GetText: string;

    property Owner: string read GetOwner;
    property PublicKey: string read GetPublicKey;
    property IsAssociatedTokenAccount: Boolean read GetIsAssociatedTokenAccount;
    /// <summary>
    /// Friendly string representation with ATA indicator.
    /// </summary>
    property Text: string read GetText;
  end;

  /// <summary>
  /// A token balance for an individual token account.
  /// </summary>
  TTokenWalletAccount = class(TTokenWalletBalance, ITokenWalletAccount)
  private
    FPublicKey: string;
    FOwner: string;
    FIsAssociatedTokenAccount: Boolean;

    function GetOwner: string;
    function GetPublicKey: string;
    function GetIsAssociatedTokenAccount: Boolean;

    function GetText: string;
  public
    /// <summary>
    /// Constructs a TokenWalletAccount instance.
    /// </summary>
    constructor Create(const ATokenDef: ITokenDef;
                       ABalanceDecimal: Double;
                       ABalanceRaw: UInt64;
                       ALamportsRaw: UInt64;
                       const APublicKey, AOwner: string;
                       AIsATA: Boolean);
  end;


  ITokenWalletFilterList = interface
    ['{7D5E9F6C-12E4-4F37-9433-AE2DF53967AF}']

    /// <summary>
    /// Keeps all accounts that match the TokenDef provided.
    /// </summary>
    /// <param name="AToken">An instance of TokenDef to use for filtering.</param>
    /// <returns>A filtered list of accounts that match the supplied TokenDef.</returns>
    function ForToken(const AToken: ITokenDef): ITokenWalletFilterList;
    /// <summary>
    /// Keeps all accounts with the token symbol supplied.
    /// <para>Be aware that token symbol does not guarantee you are interacting with the TokenMint you think.
    /// It is much safer to identify tokens using their token mint public key address.</para>
    /// </summary>
    /// <param name="ASymbol">A token symbol, e.g. USDC.</param>
    /// <returns>A filtered list of accounts for the given token symbol.</returns>
    function WithSymbol(const ASymbol: string): ITokenWalletFilterList;
    /// <summary>
    /// Get the TokenWalletAccount for the public key provided.
    /// </summary>
    /// <param name="APublicKey">Public key for the account.</param>
    /// <returns>The account with the matching public key or nil if not found.</returns>
    function WithPublicKey(const APublicKey: string): ITokenWalletAccount;
    /// <summary>
    /// Keeps all accounts for the given token mint address.
    /// </summary>
    /// <param name="AMint">Token mint public key address.</param>
    /// <returns>A filtered list of accounts for the given mint.</returns>
    function WithMint(const AMint: string): ITokenWalletFilterList; overload;
    /// <summary>
    /// Uses the TokenDef TokenMint to keep all matching accounts.
    /// </summary>
    /// <param name="ATokenDef">A TokenDef instance.</param>
    /// <returns>A filtered list of accounts for the given mint.</returns>
    function WithMint(const ATokenDef: ITokenDef): ITokenWalletFilterList; overload;
    /// <summary>
    /// Keeps all accounts with at least the supplied minimum balance.
    /// </summary>
    /// <param name="AMinimumBalance">A minimum balance value as Double.</param>
    /// <returns>A filtered list of accounts with at least the supplied balance.</returns>
    function WithAtLeast(AMinimumBalance: Double): ITokenWalletFilterList; overload;
    /// <summary>
    /// Keeps all accounts with at least the supplied minimum balance.
    /// </summary>
    /// <param name="AMinimumBalance">A minimum balance value as UInt64.</param>
    /// <returns>A filtered list of accounts with at least the supplied balance.</returns>
    function WithAtLeast(AMinimumBalance: UInt64): ITokenWalletFilterList; overload;
    /// <summary>
    /// Keeps all accounts with a non-zero balance.
    /// </summary>
    /// <returns>A filtered list of accounts with non-zero balance.</returns>
    function WithNonZero: ITokenWalletFilterList;
    /// <summary>
    /// Keeps all Associated Token Account instances in the list.
    /// </summary>
    /// <returns>A filtered list that only contains Associated Token Accounts.</returns>
    function WhichAreAssociatedTokenAccounts: ITokenWalletFilterList;
    /// <summary>
    /// Return the first associated account found in the list or nil.
    /// <para>Typically used immediately after a WithMint or ForToken filter
    /// to identify the Associated Token Account for that token.</para>
    /// </summary>
    /// <returns>The first matching Associated Token Account in the list or nil if none were found.</returns>
    function AssociatedTokenAccount: ITokenWalletAccount;
    /// <summary>
    /// Keeps all instances that satisfy the filter provided.
    /// </summary>
    /// <param name="AFilter">The filter to use.</param>
    /// <returns>A filtered list that only contains matching entries.</returns>
    function WithCustomFilter(const AFilter: TPredicate<ITokenWalletAccount>): ITokenWalletFilterList;

    function GetEnumerator: TList<ITokenWalletAccount>.TEnumerator;

    function ToList: TList<ITokenWalletAccount>;

    function Count: Integer;

    function First: ITokenWalletAccount;
  end;


  TTokenWalletFilterList = class(TInterfacedObject, ITokenWalletFilterList)
  private
    FList: TList<ITokenWalletAccount>;

    function ForToken(const AToken: ITokenDef): ITokenWalletFilterList;

    function WithSymbol(const ASymbol: string): ITokenWalletFilterList;

    function WithPublicKey(const APublicKey: string): ITokenWalletAccount;

    function WithMint(const AMint: string): ITokenWalletFilterList; overload;

    function WithMint(const ATokenDef: ITokenDef): ITokenWalletFilterList; overload;

    function WithAtLeast(AMinimumBalance: Double): ITokenWalletFilterList; overload;

    function WithAtLeast(AMinimumBalance: UInt64): ITokenWalletFilterList; overload;

    function WithNonZero: ITokenWalletFilterList;

    function WhichAreAssociatedTokenAccounts: ITokenWalletFilterList;

    function AssociatedTokenAccount: ITokenWalletAccount;

    function WithCustomFilter(const AFilter: TPredicate<ITokenWalletAccount>): ITokenWalletFilterList;

    function GetEnumerator: TList<ITokenWalletAccount>.TEnumerator;

    function ToList: TList<ITokenWalletAccount>;

    function Count: Integer;

    function First: ITokenWalletAccount;
  public
    /// <summary>
    /// Constructs an instance of TokenWalletFilterList with a list of accounts.
    /// </summary>
    /// <param name="AAccounts">Some accounts to add to the list.</param>
    constructor Create(const AAccounts: array of ITokenWalletAccount); overload;
    constructor Create(const AAccounts: TEnumerable<ITokenWalletAccount>); overload;
    destructor Destroy; override;

  end;


implementation

{ TTokenDef }

constructor TTokenDef.Create(const AMint, AName, ASymbol: string; ADecimalPlaces: Integer);
begin
  FTokenMint := AMint;
  FTokenName := AName;
  FSymbol := ASymbol;
  FDecimalPlaces := ADecimalPlaces;
end;

function TTokenDef.GetTokenMint: string;
begin
 Result := FTokenMint;
end;

function TTokenDef.GetTokenName: string;
begin
 Result := FTokenName;
end;

function TTokenDef.GetSymbol: string;
begin
 Result := FSymbol;
end;
function TTokenDef.GetDecimalPlaces: Integer;
begin
 Result := FDecimalPlaces;
end;

function TTokenDef.GetCoinGeckoId: string;
begin
 Result := FCoinGeckoId;
end;

function TTokenDef.GetTokenProjectUrl: string;
begin
 Result := FTokenProjectUrl;
end;

function TTokenDef.GetTokenLogoUrl: string;
begin
 Result := FTokenLogoUrl;
end;

procedure TTokenDef.SetCoinGeckoId(const AValue: string);
begin
  FCoinGeckoId := AValue;
end;

procedure TTokenDef.SetTokenProjectUrl(const AValue: string);
begin
  FTokenProjectUrl := AValue;
end;

procedure TTokenDef.SetTokenLogoUrl(const AValue: string);
begin
  FTokenLogoUrl := AValue;
end;

function TTokenDef.Clone: ITokenDef;
begin
 Result := TTokenDef.Create(FTokenMint, FTokenName, FSymbol, FDecimalPlaces);
 Result.CoinGeckoId := FCoinGeckoId;
 Result.TokenProjectUrl := FTokenProjectUrl;
 Result.TokenLogoUrl := FTokenLogoUrl;
end;

function TTokenDef.CreateQuantity(AValueDecimal: Double; AValueRaw: UInt64): ITokenQuantity;
begin
  Result := TTokenQuantity.Create(Self, AValueDecimal, AValueRaw);
end;

function TTokenDef.CreateQuantityWithRaw(AValue: UInt64): ITokenQuantity;
begin
  Result := CreateQuantity(ConvertUInt64ToDouble(AValue), AValue);
end;

function TTokenDef.CreateQuantityWithDecimal(AValue: Double): ITokenQuantity;
begin
  Result := CreateQuantity(AValue, ConvertDoubleToUInt64(AValue));
end;

function TTokenDef.ConvertDoubleToUInt64(AValue: Double): UInt64;
var
  I: Integer;
  ImpliedAmount: Double;
begin
  if FDecimalPlaces < 0 then
    raise Exception.CreateFmt('DecimalPlaces is unknown for mint %s', [FTokenMint]);

  ImpliedAmount := AValue;
  for I := 1 to FDecimalPlaces do
    ImpliedAmount := ImpliedAmount * 10;
  Result := Trunc(ImpliedAmount);
end;

function TTokenDef.ConvertUInt64ToDouble(AValue: UInt64): Double;
var
  I: Integer;
  ImpliedAmount: Double;
begin
  if FDecimalPlaces < 0 then
    raise Exception.CreateFmt('DecimalPlaces is unknown for mint %s', [FTokenMint]);

  ImpliedAmount := AValue;
  for I := 1 to FDecimalPlaces do
    ImpliedAmount := ImpliedAmount / 10;
  Result := ImpliedAmount;
end;

function TTokenDef.CloneWithKnownDecimals(ADecimalPlaces: Integer): ITokenDef;
begin
  if ADecimalPlaces < 0 then
    raise EArgumentOutOfRangeException.Create('Decimal places must be 0+');

  Result := TTokenDef.Create(FTokenMint, FTokenName, FSymbol, ADecimalPlaces);
  Result.CoinGeckoId := FCoinGeckoId;
  Result.TokenLogoUrl := FTokenLogoUrl;
  Result.TokenProjectUrl := FTokenProjectUrl;
end;

{ TTokenQuantity }

constructor TTokenQuantity.Create(const ATokenDef: ITokenDef; ABalanceDecimal: Double; ABalanceRaw: UInt64);
begin
  if ATokenDef = nil then
    raise EArgumentNilException.Create('tokenDef');

  FTokenDef := ATokenDef;
  FSymbol := ATokenDef.Symbol;
  FTokenName := ATokenDef.TokenName;
  FTokenMint := ATokenDef.TokenMint;
  FDecimalPlaces := ATokenDef.DecimalPlaces;
  FQuantityDouble := ABalanceDecimal;
  FQuantityRaw := ABalanceRaw;
end;

function TTokenQuantity.AddQuantity(AValueDecimal: Double; AValueRaw: UInt64): ITokenQuantity;
begin
  Result := TTokenQuantity.Create(FTokenDef,
    FQuantityDouble + AValueDecimal,
    FQuantityRaw + AValueRaw);
end;

function TTokenQuantity.GetTokenDef: ITokenDef;
begin
 Result := FTokenDef;
end;

function TTokenQuantity.GetTokenMint: string;
begin
 Result := FTokenMint;
end;

function TTokenQuantity.GetTokenName: string;
begin
 Result := FTokenName;
end;

function TTokenQuantity.GetSymbol: string;
begin
 Result := FSymbol;
end;

function TTokenQuantity.GetDecimalPlaces: Integer;
begin
 Result := FDecimalPlaces;
end;

function TTokenQuantity.GetQuantityDouble: Double;
begin
 Result := FQuantityDouble;
end;

function TTokenQuantity.GetQuantityRaw: UInt64;
begin
 Result := FQuantityRaw;
end;

function TTokenQuantity.ToString: string;
begin
  if FSymbol = FTokenName then
    Result := Format('%g %s', [FQuantityDouble, FSymbol])
  else
    Result := Format('%g %s (%s)', [FQuantityDouble, FSymbol, FTokenName]);
end;

{ TTokenWalletBalance }

constructor TTokenWalletBalance.Create(const ATokenDef: ITokenDef;
                                       ABalanceDecimal: Double;
                                       ABalanceRaw: UInt64;
                                       ALamportsRaw: UInt64;
                                       AAccountCount: Integer);
begin
  inherited Create(ATokenDef, ABalanceDecimal, ABalanceRaw);
  FLamports := ALamportsRaw;
  FAccountCount := AAccountCount;
end;

function TTokenWalletBalance.AddAccount(AValueDecimal: Double;
                                        AValueRaw: UInt64;
                                        ALamportsRaw: UInt64;
                                        AAccountCount: Integer): ITokenWalletBalance;
begin
  Result := TTokenWalletBalance.Create(
    Self.FTokenDef,
    Self.FQuantityDouble + AValueDecimal,
    Self.FQuantityRaw + AValueRaw,
    Self.FLamports + ALamportsRaw,
    Self.FAccountCount + AAccountCount
  );
end;

function TTokenWalletBalance.GetAccountCount: Integer;
begin
 Result := FAccountCount;
end;

function TTokenWalletBalance.GetLamports: UInt64;
begin
 Result := FLamports;
end;

function TTokenWalletBalance.GetText: string;
begin
  if FSymbol = FTokenName then
    Result := Format('%g %s', [FQuantityDouble, FSymbol])
  else
    Result := Format('%g %s (%s)', [FQuantityDouble, FSymbol, FTokenName]);
end;


{ TTokenWalletAccount }

constructor TTokenWalletAccount.Create(const ATokenDef: ITokenDef;
                                       ABalanceDecimal: Double;
                                       ABalanceRaw: UInt64;
                                       ALamportsRaw: UInt64;
                                       const APublicKey, AOwner: string;
                                       AIsATA: Boolean);
begin
  if APublicKey = '' then
    raise EArgumentNilException.Create('APublicKey');
  if AOwner = '' then
    raise EArgumentNilException.Create('AOwner');

  inherited Create(ATokenDef, ABalanceDecimal, ABalanceRaw, ALamportsRaw, 1);
  FPublicKey := APublicKey;
  FOwner := AOwner;
  FIsAssociatedTokenAccount := AIsATA;
end;

function TTokenWalletAccount.GetIsAssociatedTokenAccount: Boolean;
begin
 Result := FIsAssociatedTokenAccount;
end;

function TTokenWalletAccount.GetOwner: string;
begin
 Result := FOwner;
end;

function TTokenWalletAccount.GetPublicKey: string;
begin
 Result := FPublicKey;
end;

function TTokenWalletAccount.GetText: string;
begin
  if FIsAssociatedTokenAccount then
    Result := inherited GetText + ' [ATA]'
  else
    Result := inherited GetText;
end;


{ TTokenWalletFilterList }


constructor TTokenWalletFilterList.Create(const AAccounts: array of ITokenWalletAccount);

var
  Account: ITokenWalletAccount;
begin
  inherited Create;
  FList := TList<ITokenWalletAccount>.Create;
  for Account in AAccounts do
    FList.Add(Account);
end;

constructor TTokenWalletFilterList.Create(const AAccounts: TEnumerable<ITokenWalletAccount>);
var
  Account: ITokenWalletAccount;
begin
  inherited Create;
  FList := TList<ITokenWalletAccount>.Create;

  if AAccounts = nil then
    raise EArgumentNilException.Create('AAccounts');

  for Account in AAccounts do
    FList.Add(Account);
end;

destructor TTokenWalletFilterList.Destroy;
begin
  FList.Free;
  inherited;
end;

function TTokenWalletFilterList.ForToken(const AToken: ITokenDef): ITokenWalletFilterList;
var
  Account: ITokenWalletAccount;
  Filtered: TTokenWalletFilterList;
begin
  if AToken = nil then
    raise EArgumentNilException.Create('AToken');

  Filtered := TTokenWalletFilterList.Create([]);
  for Account in FList do
    if SameText(Account.TokenMint, AToken.TokenMint) then
      Filtered.FList.Add(Account);

  Result := Filtered;
end;

function TTokenWalletFilterList.WithSymbol(const ASymbol: string): ITokenWalletFilterList;
var
  Account: ITokenWalletAccount;
  Filtered: TTokenWalletFilterList;
begin
  if ASymbol.Trim = '' then
    raise EArgumentException.Create('ASymbol cannot be empty.');

  Filtered := TTokenWalletFilterList.Create([]);
  for Account in FList do
    if SameText(Account.Symbol, ASymbol) then
      Filtered.FList.Add(Account);

  Result := Filtered;
end;

function TTokenWalletFilterList.WithPublicKey(const APublicKey: string): ITokenWalletAccount;
var
  Account: ITokenWalletAccount;
begin
  if APublicKey.Trim = '' then
    raise EArgumentException.Create('APublicKey cannot be empty.');

  for Account in FList do
    if SameStr(Account.PublicKey, APublicKey) then
      Exit(Account);

  Result := nil;
end;

function TTokenWalletFilterList.WithMint(const AMint: string): ITokenWalletFilterList;
var
  Account: ITokenWalletAccount;
  Filtered: TTokenWalletFilterList;
begin
  Filtered := TTokenWalletFilterList.Create([]);
  for Account in FList do
    if SameText(Account.TokenMint, AMint) then
      Filtered.FList.Add(Account);
  Result := Filtered;
end;

function TTokenWalletFilterList.WithMint(const ATokenDef: ITokenDef): ITokenWalletFilterList;
begin
  if ATokenDef = nil then
    raise EArgumentNilException.Create('ATokenDef');
  Result := WithMint(ATokenDef.TokenMint);
end;

function TTokenWalletFilterList.WithAtLeast(AMinimumBalance: Double): ITokenWalletFilterList;
var
  Account: ITokenWalletAccount;
  Filtered: TTokenWalletFilterList;
begin
  Filtered := TTokenWalletFilterList.Create([]);
  for Account in FList do
    if Account.QuantityDouble >= AMinimumBalance then
      Filtered.FList.Add(Account);
  Result := Filtered;
end;

function TTokenWalletFilterList.WithAtLeast(AMinimumBalance: UInt64): ITokenWalletFilterList;
var
  Account: ITokenWalletAccount;
  Filtered: TTokenWalletFilterList;
begin
  Filtered := TTokenWalletFilterList.Create([]);
  for Account in FList do
    if Account.QuantityRaw >= AMinimumBalance then
      Filtered.FList.Add(Account);
  Result := Filtered;
end;

function TTokenWalletFilterList.WithNonZero: ITokenWalletFilterList;
var
  Account: ITokenWalletAccount;
  Filtered: TTokenWalletFilterList;
begin
  Filtered := TTokenWalletFilterList.Create([]);
  for Account in FList do
    if Account.QuantityRaw > 0 then
      Filtered.FList.Add(Account);
  Result := Filtered;
end;

function TTokenWalletFilterList.WhichAreAssociatedTokenAccounts: ITokenWalletFilterList;
var
  Account: ITokenWalletAccount;
  Filtered: TTokenWalletFilterList;
begin
  Filtered := TTokenWalletFilterList.Create([]);
  for Account in FList do
    if Account.IsAssociatedTokenAccount then
      Filtered.FList.Add(Account);
  Result := Filtered;
end;

function TTokenWalletFilterList.AssociatedTokenAccount: ITokenWalletAccount;
var
  List: ITokenWalletFilterList;
begin
  List := WhichAreAssociatedTokenAccounts;
  if List.Count > 0 then
    Result := List.First
  else
    Result := nil;
end;

function TTokenWalletFilterList.WithCustomFilter(const AFilter: TPredicate<ITokenWalletAccount>): ITokenWalletFilterList;
var
  Account: ITokenWalletAccount;
  Filtered: TTokenWalletFilterList;
begin
  if not Assigned(AFilter) then
    raise EArgumentNilException.Create('AFilter');

  Filtered := TTokenWalletFilterList.Create([]);
  for Account in FList do
    if AFilter(Account) then
      Filtered.FList.Add(Account);

  Result := Filtered;
end;

function TTokenWalletFilterList.GetEnumerator: TList<ITokenWalletAccount>.TEnumerator;
begin
  Result := FList.GetEnumerator;
end;

function TTokenWalletFilterList.ToList: TList<ITokenWalletAccount>;
begin
  Result := FList;
end;

function TTokenWalletFilterList.Count: Integer;
begin
  Result := FList.Count;
end;

function TTokenWalletFilterList.First: ITokenWalletAccount;
begin
  if FList.Count > 0 then
    Result := FList.First
  else
    Result := nil;
end;

end.
