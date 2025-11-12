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

unit SlpTokenSwapModel;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  SlpPublicKey,
  SlpBinaryPrimitives,
  SlpSerialization,

  SlpArrayUtils;

type
  /// <summary>
  /// Curve type enum for an instruction
  /// </summary>
  TCurveType = (
    /// <summary>Uniswap-style constant product curve, invariant = token_a_amount * token_b_amount</summary>
    ConstantProduct = 0,
    /// <summary>Flat line, always providing 1:1 from one token to another</summary>
    ConstantPrice   = 1,
    /// <summary>Stable, like uniswap, but with wide zone of 1:1 instead of one point</summary>
    Stable          = 2,
    /// <summary>Offset curve, like Uniswap, but the token B side has a faked offset</summary>
    Offset          = 3
  );

  /// <summary>Versions of this state account</summary>
   TSwapVersion = (SwapV1 = 1);

  /// <summary>
  /// A curve calculator must serialize itself to bytes (Solana: up to 32)
  /// </summary>
  ICurveCalculator = interface
    ['{4B3B6E97-2E19-4F43-9E5F-0C4D2B0E1C2A}']
    /// <summary>
    /// Serialize this calculator type
    /// </summary>
    /// <returns></returns>
    function Serialize: TBytes;
  end;

  /// <summary>
  /// Uniswap-style constant product curve, invariant = token_a_amount * token_b_amount
  /// </summary>
  IConstantProductCurve = interface(ICurveCalculator)
    ['{6E3C3A2E-7C9F-4D09-990F-0E9A3B7B4F12}']
  end;

  /// <summary>
  /// Encapsulates all fee information and calculations for swap operations
  /// </summary>
  IFees = interface
    ['{C6F3C3C3-1D1A-4F4B-A1B8-5C5B7F8E9A0B}']
    /// <summary>Trade fee numerator.</summary>
    function GetTradeFeeNumerator: UInt64;
    /// <summary>Trade fee denominator.</summary>
    function GetTradeFeeDenominator: UInt64;
    /// <summary>Owner trade fee numerator.</summary>
    function GetOwnerTradeFeeNumerator: UInt64;
    /// <summary>Owner trade fee denominator.</summary>
    function GetOwnerTradeFeeDenominator: UInt64;
    /// <summary>Owner withdraw fee numerator.</summary>
    function GetOwnerWithdrawFeeNumerator: UInt64;
    /// <summary>Owner withdraw fee denominator.</summary>
    function GetOwnerWithdrawFeeDenominator: UInt64;
    /// <summary>Host trading fee numerator.</summary>
    function GetHostFeeNumerator: UInt64;
    /// <summary>Host trading fee denominator.</summary>
    function GetHostFeeDenominator: UInt64;

    procedure SetTradeFeeNumerator(const AValue: UInt64);
    procedure SetTradeFeeDenominator(const AValue: UInt64);
    procedure SetOwnerTradeFeeNumerator(const AValue: UInt64);
    procedure SetOwnerTradeFeeDenominator(const AValue: UInt64);
    procedure SetOwnerWithdrawFeeNumerator(const AValue: UInt64);
    procedure SetOwnerWithdrawFeeDenominator(const AValue: UInt64);
    procedure SetHostFeeNumerator(const AValue: UInt64);
    procedure SetHostFeeDenominator(const AValue: UInt64);

    /// <summary>Serialize the Fees (64 bytes)</summary>
    function Serialize: TBytes;

    property TradeFeeNumerator: UInt64 read GetTradeFeeNumerator write SetTradeFeeNumerator;
    property TradeFeeDenominator: UInt64 read GetTradeFeeDenominator write SetTradeFeeDenominator;
    property OwnerTradeFeeNumerator: UInt64 read GetOwnerTradeFeeNumerator write SetOwnerTradeFeeNumerator;
    property OwnerTradeFeeDenominator: UInt64 read GetOwnerTradeFeeDenominator write SetOwnerTradeFeeDenominator;
    property OwnerWithdrawFeeNumerator: UInt64 read GetOwnerWithdrawFeeNumerator write SetOwnerWithdrawFeeNumerator;
    property OwnerWithdrawFeeDenominator: UInt64 read GetOwnerWithdrawFeeDenominator write SetOwnerWithdrawFeeDenominator;
    property HostFeeNumerator: UInt64 read GetHostFeeNumerator write SetHostFeeNumerator;
    property HostFeeDenominator: UInt64 read GetHostFeeDenominator write SetHostFeeDenominator;
  end;

  /// <summary>
  /// A swap curve type of a token swap. The static construction methods should be used to construct
  /// </summary>
  ISwapCurve = interface
    ['{D3F4D66A-0B56-4F0E-9A5D-5D3A2C1A9EAA}']
    /// <summary>The curve type.</summary>
    function GetCurveType: TCurveType;
    /// <summary>The calculator used.</summary>
    function GetCalculator: ICurveCalculator;
    /// <summary>Serialize this swap curve for an instruction.</summary>
    function Serialize: TBytes;

    property CurveType: TCurveType read GetCurveType;
    property Calculator: ICurveCalculator read GetCalculator;
  end;

  /// <summary>
  /// TokenSwap program state
  /// </summary>
  ITokenSwapAccount = interface
    ['{7CF8F412-9049-4E7F-8B2C-2A9E0F8A9F3B}']

    /// <summary>Version of this state account</summary>
    function GetVersion: TSwapVersion;
    /// <summary>Initialized state</summary>
    function GetIsInitialized: Boolean;
    /// <summary>Nonce used in program address.</summary>
    function GetNonce: Byte;
    /// <summary>Program ID of the tokens being exchanged.</summary>
    function GetTokenProgramId: IPublicKey;
    /// <summary>Token A</summary>
    function GetTokenAAccount: IPublicKey;
    /// <summary>Token B</summary>
    function GetTokenBAccount: IPublicKey;
    /// <summary>Pool tokens are issued when A or B tokens are deposited.</summary>
    function GetPoolMint: IPublicKey;
    /// <summary>Mint information for token A</summary>
    function GetTokenAMint: IPublicKey;
    /// <summary>Mint information for token B</summary>
    function GetTokenBMint: IPublicKey;
    /// <summary>Pool token account to receive trading and / or withdrawal fees</summary>
    function GetPoolFeeAccount: IPublicKey;
    /// <summary>All fee information</summary>
    function GetFees: IFees;
    /// <summary>Swap curve parameters</summary>
    function GetSwapCurve: ISwapCurve;

    property Version: TSwapVersion read GetVersion;
    property IsInitialized: Boolean read GetIsInitialized;
    property Nonce: Byte read GetNonce;
    property TokenProgramId: IPublicKey read GetTokenProgramId;
    property TokenAAccount: IPublicKey read GetTokenAAccount;
    property TokenBAccount: IPublicKey read GetTokenBAccount;
    property PoolMint: IPublicKey read GetPoolMint;
    property TokenAMint: IPublicKey read GetTokenAMint;
    property TokenBMint: IPublicKey read GetTokenBMint;
    property PoolFeeAccount: IPublicKey read GetPoolFeeAccount;
    property Fees: IFees read GetFees;
    property SwapCurve: ISwapCurve read GetSwapCurve;
  end;

  /// <summary>Constant product calculator concrete type</summary>
  TConstantProductCurve = class(TInterfacedObject, IConstantProductCurve)
  public
    /// <summary>Serialize this calculator type</summary>
    function Serialize: TBytes;
  end;

  /// <summary>Fees concrete type</summary>
  TFees = class(TInterfacedObject, IFees)
  private
    FTradeFeeNumerator: UInt64;
    FTradeFeeDenominator: UInt64;
    FOwnerTradeFeeNumerator: UInt64;
    FOwnerTradeFeeDenominator: UInt64;
    FOwnerWithdrawFeeNumerator: UInt64;
    FOwnerWithdrawFeeDenominator: UInt64;
    FHostFeeNumerator: UInt64;
    FHostFeeDenominator: UInt64;
    function GetTradeFeeNumerator: UInt64;
    function GetTradeFeeDenominator: UInt64;
    function GetOwnerTradeFeeNumerator: UInt64;
    function GetOwnerTradeFeeDenominator: UInt64;
    function GetOwnerWithdrawFeeNumerator: UInt64;
    function GetOwnerWithdrawFeeDenominator: UInt64;
    function GetHostFeeNumerator: UInt64;
    function GetHostFeeDenominator: UInt64;
    procedure SetTradeFeeNumerator(const AValue: UInt64);
    procedure SetTradeFeeDenominator(const AValue: UInt64);
    procedure SetOwnerTradeFeeNumerator(const AValue: UInt64);
    procedure SetOwnerTradeFeeDenominator(const AValue: UInt64);
    procedure SetOwnerWithdrawFeeNumerator(const AValue: UInt64);
    procedure SetOwnerWithdrawFeeDenominator(const AValue: UInt64);
    procedure SetHostFeeNumerator(const AValue: UInt64);
    procedure SetHostFeeDenominator(const AValue: UInt64);
  public
    function Serialize: TBytes;
    class function Deserialize(const ABytes: TBytes): IFees; static;

    property TradeFeeNumerator: UInt64 read GetTradeFeeNumerator write SetTradeFeeNumerator;
    property TradeFeeDenominator: UInt64 read GetTradeFeeDenominator write SetTradeFeeDenominator;
    property OwnerTradeFeeNumerator: UInt64 read GetOwnerTradeFeeNumerator write SetOwnerTradeFeeNumerator;
    property OwnerTradeFeeDenominator: UInt64 read GetOwnerTradeFeeDenominator write SetOwnerTradeFeeDenominator;
    property OwnerWithdrawFeeNumerator: UInt64 read GetOwnerWithdrawFeeNumerator write SetOwnerWithdrawFeeNumerator;
    property OwnerWithdrawFeeDenominator: UInt64 read GetOwnerWithdrawFeeDenominator write SetOwnerWithdrawFeeDenominator;
    property HostFeeNumerator: UInt64 read GetHostFeeNumerator write SetHostFeeNumerator;
    property HostFeeDenominator: UInt64 read GetHostFeeDenominator write SetHostFeeDenominator;
  end;

  /// <summary>
  /// A swap curve type of a token swap. The static construction methods should be used to construct
  /// </summary>
  TSwapCurve = class(TInterfacedObject, ISwapCurve)
  private
    FCurveType: TCurveType;
    FCalculator: ICurveCalculator;
    class var FConstantProduct: ISwapCurve;
    class constructor Create;
    function GetCurveType: TCurveType;
    function GetCalculator: ICurveCalculator;

    constructor Create(const ACurveType: TCurveType; const ACalculator: ICurveCalculator);

  public
    function Serialize: TBytes;
    /// <summary>
    /// Deserializes the SwapCurve object from binary.
    /// </summary>
    /// <param name="ABytes">The payload to decode.</param>
    /// <returns>The decoded SwapCurve object.</returns>
    class function Deserialize(const ABytes: TBytes): ISwapCurve; static;

    /// <summary>
    /// Static: Constant Product curve singleton
    /// </summary>
    class property ConstantProduct: ISwapCurve read FConstantProduct;

    property CurveType: TCurveType read GetCurveType;
    property Calculator: ICurveCalculator read GetCalculator;
  end;

  /// <summary>TokenSwap program state concrete type</summary>
  TTokenSwapAccount = class(TInterfacedObject, ITokenSwapAccount)
  private
    FVersion: TSwapVersion;
    FIsInitialized: Boolean;
    FNonce: Byte;
    FTokenProgramId: IPublicKey;
    FTokenAAccount: IPublicKey;
    FTokenBAccount: IPublicKey;
    FPoolMint: IPublicKey;
    FTokenAMint: IPublicKey;
    FTokenBMint: IPublicKey;
    FPoolFeeAccount: IPublicKey;
    FFees: IFees;
    FSwapCurve: ISwapCurve;

    const
    /// <summary>
    /// Token Swap account layout size.
    /// </summary>
    TokenSwapAccountDataSize = 323;

    function GetVersion: TSwapVersion;
    function GetIsInitialized: Boolean;
    function GetNonce: Byte;
    function GetTokenProgramId: IPublicKey;
    function GetTokenAAccount: IPublicKey;
    function GetTokenBAccount: IPublicKey;
    function GetPoolMint: IPublicKey;
    function GetTokenAMint: IPublicKey;
    function GetTokenBMint: IPublicKey;
    function GetPoolFeeAccount: IPublicKey;
    function GetFees: IFees;
    function GetSwapCurve: ISwapCurve;
  public
    /// <summary>
    /// Token Swap data length. // 1 (for the SwapVersion enum) + 323 (TokenSwapAccountDataSize)
    /// </summary>
    const TokenSwapDataLength = 1 + TokenSwapAccountDataSize; // add one for the version enum

    /// <summary>
    /// Deserilize a token swap from the bytes of an account
    /// </summary>
    class function Deserialize(const AData: TBytes): ITokenSwapAccount; static;
  end;

implementation

{ TConstantProductCurve }

function TConstantProductCurve.Serialize: TBytes;
begin
  Result := nil;
end;

{ TFees }

function TFees.GetHostFeeDenominator: UInt64;
begin
  Result := FHostFeeDenominator;
end;

procedure TFees.SetHostFeeDenominator(const AValue: UInt64);
begin
  FHostFeeDenominator := AValue;
end;

function TFees.GetHostFeeNumerator: UInt64;
begin
  Result := FHostFeeNumerator;
end;

procedure TFees.SetHostFeeNumerator(const AValue: UInt64);
begin
  FHostFeeNumerator := AValue;
end;

function TFees.GetOwnerTradeFeeDenominator: UInt64;
begin
  Result := FOwnerTradeFeeDenominator;
end;

procedure TFees.SetOwnerTradeFeeDenominator(const AValue: UInt64);
begin
  FOwnerTradeFeeDenominator := AValue;
end;

function TFees.GetOwnerTradeFeeNumerator: UInt64;
begin
  Result := FOwnerTradeFeeNumerator;
end;

procedure TFees.SetOwnerTradeFeeNumerator(const AValue: UInt64);
begin
  FOwnerTradeFeeNumerator := AValue;
end;

function TFees.GetOwnerWithdrawFeeDenominator: UInt64;
begin
  Result := FOwnerWithdrawFeeDenominator;
end;

procedure TFees.SetOwnerWithdrawFeeDenominator(const AValue: UInt64);
begin
  FOwnerWithdrawFeeDenominator := AValue;
end;

function TFees.GetOwnerWithdrawFeeNumerator: UInt64;
begin
  Result := FOwnerWithdrawFeeNumerator;
end;

procedure TFees.SetOwnerWithdrawFeeNumerator(const AValue: UInt64);
begin
  FOwnerWithdrawFeeNumerator := AValue;
end;

function TFees.GetTradeFeeDenominator: UInt64;
begin
  Result := FTradeFeeDenominator;
end;

procedure TFees.SetTradeFeeDenominator(const AValue: UInt64);
begin
  FTradeFeeDenominator := AValue;
end;

function TFees.GetTradeFeeNumerator: UInt64;
begin
  Result := FTradeFeeNumerator;
end;

procedure TFees.SetTradeFeeNumerator(const AValue: UInt64);
begin
  FTradeFeeNumerator := AValue;
end;

function TFees.Serialize: TBytes;
begin
  SetLength(Result, 64);
  TSerialization.WriteU64(Result, FTradeFeeNumerator, 0);
  TSerialization.WriteU64(Result, FTradeFeeDenominator, 8);
  TSerialization.WriteU64(Result, FOwnerTradeFeeNumerator, 16);
  TSerialization.WriteU64(Result, FOwnerTradeFeeDenominator, 24);
  TSerialization.WriteU64(Result, FOwnerWithdrawFeeNumerator, 32);
  TSerialization.WriteU64(Result, FOwnerWithdrawFeeDenominator, 40);
  TSerialization.WriteU64(Result, FHostFeeNumerator, 48);
  TSerialization.WriteU64(Result, FHostFeeDenominator, 56);
end;

class function TFees.Deserialize(const ABytes: TBytes): IFees;
var
  LFees: TFees;
begin
  if Length(ABytes) <> 64 then
    raise EArgumentException.Create('Fees payload must be 64 bytes');

  LFees := TFees.Create;
  LFees.FTradeFeeNumerator           := TBinaryPrimitives.ReadUInt64LittleEndian(ABytes, 0);
  LFees.FTradeFeeDenominator         := TBinaryPrimitives.ReadUInt64LittleEndian(ABytes, 8);
  LFees.FOwnerTradeFeeNumerator      := TBinaryPrimitives.ReadUInt64LittleEndian(ABytes, 16);
  LFees.FOwnerTradeFeeDenominator    := TBinaryPrimitives.ReadUInt64LittleEndian(ABytes, 24);
  LFees.FOwnerWithdrawFeeNumerator   := TBinaryPrimitives.ReadUInt64LittleEndian(ABytes, 32);
  LFees.FOwnerWithdrawFeeDenominator := TBinaryPrimitives.ReadUInt64LittleEndian(ABytes, 40);
  LFees.FHostFeeNumerator            := TBinaryPrimitives.ReadUInt64LittleEndian(ABytes, 48);
  LFees.FHostFeeDenominator          := TBinaryPrimitives.ReadUInt64LittleEndian(ABytes, 56);
  Result := LFees;
end;

{ TSwapCurve }

class constructor TSwapCurve.Create;
var
 LCpc: IConstantProductCurve;
begin
  LCpc := TConstantProductCurve.Create;
  FConstantProduct := TSwapCurve.Create(TCurveType.ConstantProduct, LCpc);
end;

constructor TSwapCurve.Create(const ACurveType: TCurveType; const ACalculator: ICurveCalculator);
begin
  inherited Create;
  FCurveType := ACurveType;
  FCalculator := ACalculator;
end;

function TSwapCurve.GetCalculator: ICurveCalculator;
begin
  Result := FCalculator;
end;

function TSwapCurve.GetCurveType: TCurveType;
begin
  Result := FCurveType;
end;

function TSwapCurve.Serialize: TBytes;
begin
  SetLength(Result, 33);
  TSerialization.WriteU8(Result, Byte(FCurveType), 0);
  TSerialization.WriteSpan(Result, FCalculator.Serialize, 1);
end;

class function TSwapCurve.Deserialize(const ABytes: TBytes): ISwapCurve;
var
  LKind: Byte;
begin
  if Length(ABytes) < 1 then
    raise EArgumentException.Create('SwapCurve payload is too short');

  LKind := ABytes[0];
  case TCurveType(LKind) of
    TCurveType.ConstantProduct:
      Result := FConstantProduct;
  else
    raise ENotSupportedException.Create('Only constant product curves are supported currently');
  end;
end;

{ TTokenSwapAccount }

function TTokenSwapAccount.GetFees: IFees;
begin
  Result := FFees;
end;

function TTokenSwapAccount.GetIsInitialized: Boolean;
begin
  Result := FIsInitialized;
end;

function TTokenSwapAccount.GetNonce: Byte;
begin
  Result := FNonce;
end;

function TTokenSwapAccount.GetPoolFeeAccount: IPublicKey;
begin
  Result := FPoolFeeAccount;
end;

function TTokenSwapAccount.GetPoolMint: IPublicKey;
begin
  Result := FPoolMint;
end;

function TTokenSwapAccount.GetSwapCurve: ISwapCurve;
begin
  Result := FSwapCurve;
end;

function TTokenSwapAccount.GetTokenAAccount: IPublicKey;
begin
  Result := FTokenAAccount;
end;

function TTokenSwapAccount.GetTokenAMint: IPublicKey;
begin
  Result := FTokenAMint;
end;

function TTokenSwapAccount.GetTokenBAccount: IPublicKey;
begin
  Result := FTokenBAccount;
end;

function TTokenSwapAccount.GetTokenBMint: IPublicKey;
begin
  Result := FTokenBMint;
end;

function TTokenSwapAccount.GetTokenProgramId: IPublicKey;
begin
  Result := FTokenProgramId;
end;

function TTokenSwapAccount.GetVersion: TSwapVersion;
begin
  Result := FVersion;
end;

class function TTokenSwapAccount.Deserialize(const AData: TBytes): ITokenSwapAccount;
var
  LAcc: TTokenSwapAccount;
begin
  if Length(AData) <> TokenSwapDataLength then
    Exit(nil);

  LAcc := TTokenSwapAccount.Create;

  LAcc.FVersion := TSwapVersion.SwapV1;

  LAcc.FIsInitialized := AData[1] = 1;
  LAcc.FNonce := AData[2];

  LAcc.FTokenProgramId := TPublicKey.Create(TArrayUtils.Slice<Byte>(AData, 3, 32));
  LAcc.FTokenAAccount  := TPublicKey.Create(TArrayUtils.Slice<Byte>(AData, 35, 32));
  LAcc.FTokenBAccount  := TPublicKey.Create(TArrayUtils.Slice<Byte>(AData, 67, 32));
  LAcc.FPoolMint       := TPublicKey.Create(TArrayUtils.Slice<Byte>(AData, 99, 32));
  LAcc.FTokenAMint     := TPublicKey.Create(TArrayUtils.Slice<Byte>(AData, 131, 32));
  LAcc.FTokenBMint     := TPublicKey.Create(TArrayUtils.Slice<Byte>(AData, 163, 32));
  LAcc.FPoolFeeAccount := TPublicKey.Create(TArrayUtils.Slice<Byte>(AData, 195, 32));
  LAcc.FFees := TFees.Deserialize(TArrayUtils.Slice<Byte>(AData, 227, 64));
  LAcc.FSwapCurve := TSwapCurve.Deserialize(TArrayUtils.Slice<Byte>(AData, 291, Length(AData) - 291));

  Result := LAcc;
end;

end.

