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

unit TokenMintTests;

interface

uses
  SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpTokenMintResolver,
  SlpTokenDomain,
  SlpPublicKey,
  SlpWellKnownTokens,
  SolLibTokenTestCase;

type
  TTokenMintTests = class(TSolLibTokenTestCase)
  published
    procedure TestTokenInfoResolverParseAndFind;
    procedure TestTokenInfoResolverUnknowns;
    procedure TestTokenDefCreateQuantity;
    procedure TestDynamicTokenDefCreateQuantity;
    procedure TestPreloadedMintResolver;
    procedure TestExtendedTokenMeta;
  end;

implementation

{ TTokenMintTests }

procedure TTokenMintTests.TestTokenInfoResolverParseAndFind;
var
  LJson: string;
  LTokens: ITokenMintResolver;
  LWsol: ITokenDef;
begin
  LJson := LoadTestData('TokenMint/SimpleTokenList.json');

  LTokens := TTokenMintResolver.ParseTokenList(LJson);

  LWsol := LTokens.Resolve(TWellKnownTokens.WrappedSOL.TokenMint);
  AssertTrue(LWsol <> nil, 'WSOL not resolved');

  AssertEquals(TWellKnownTokens.WrappedSOL.Symbol,        LWsol.Symbol,      'symbol mismatch');
  AssertEquals(TWellKnownTokens.WrappedSOL.TokenName,     LWsol.TokenName,   'name mismatch');
  AssertEquals(TWellKnownTokens.WrappedSOL.TokenMint,     LWsol.TokenMint,   'mint mismatch');
  AssertEquals(TWellKnownTokens.WrappedSOL.DecimalPlaces, LWsol.DecimalPlaces, 'decimals mismatch');
end;

procedure TTokenMintTests.TestTokenInfoResolverUnknowns;
var
  LJson: string;
  LTokens: ITokenMintResolver;
  LUnknown, LUnknown2, LKnown, LKnown2: ITokenDef;
  LMint: string;
begin
  LJson := LoadTestData('TokenMint/SimpleTokenList.json');

  LTokens := TTokenMintResolver.ParseTokenList(LJson);

  // lookup unknown mint - non-fatal - returns unknown def
  LMint := 'deadbeef11111111111111111111111111111111112';
  LUnknown := LTokens.Resolve(LMint);
  AssertTrue(LUnknown <> nil, 'unknown token not provided');
  AssertEquals(-1, LUnknown.DecimalPlaces, 'unknown decimals should be -1');
  AssertTrue(Pos('deadbeef', LowerCase(LUnknown.TokenName)) > 0, 'unknown name should contain deadbeef');
  AssertEquals(LMint, LUnknown.TokenMint, 'unknown mint mismatch');

  // repeat lookup and ensure same instance reused
  LUnknown2 := LTokens.Resolve(LUnknown.TokenMint);
  AssertTrue(LUnknown = LUnknown2, 'resolver should return the same instance for unknown');

  LKnown2 := TTokenDef.Create(LUnknown2.TokenMint, 'Test Mint', 'MINT', 4);
  LTokens.Add(LKnown2);
  LKnown := LTokens.Resolve(LUnknown.TokenMint);
  AssertTrue(LKnown <> nil, 'known token not resolved');
  AssertTrue(LKnown <> LUnknown, 'known must be a different instance than previous unknown');
  AssertEquals(4, LKnown.DecimalPlaces, 'known decimals');
  AssertEquals('Test Mint', LKnown.TokenName, 'known name');
  AssertEquals(LUnknown.TokenMint, LKnown.TokenMint, 'mint must match');
end;

procedure TTokenMintTests.TestTokenDefCreateQuantity;
var
  LQty: ITokenQuantity;
  LDec: Double;
  LRaw: UInt64;
begin
  LQty := TWellKnownTokens.USDC.CreateQuantityWithRaw(4741784);
  AssertEquals(4741784, LQty.QuantityRaw, 'raw mismatch');
  AssertEquals(4.741784, LQty.QuantityDouble, DoubleCompareDelta);
  AssertEquals('USDC', LQty.Symbol, 'symbol mismatch');
  AssertEquals(6, LQty.DecimalPlaces, 'decimal places mismatch');
  AssertEquals('4.741784 USDC (USD Coin)', LQty.ToString, 'ToString mismatch');

  // Raydium conversions
  LDec := TWellKnownTokens.Raydium.ConvertUInt64ToDouble(123456);
  AssertEquals(0.123456, LDec, DoubleCompareDelta);

  LRaw := TWellKnownTokens.Raydium.ConvertDoubleToUInt64(1.23);
  AssertEquals(1230000, LRaw);
end;

procedure TTokenMintTests.TestDynamicTokenDefCreateQuantity;
var
  LPubkey: IPublicKey;
  LResolver: ITokenMintResolver;
  LQty: ITokenQuantity;
  LTokenDef: ITokenDef;
begin
  LPubkey := TPublicKey.Create('FakekjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');

  LTokenDef := TTokenDef.Create(LPubkey.Key, 'Fake Coin', 'FK', 3);
  LResolver := TTokenMintResolver.Create;
  LResolver.Add(LTokenDef);

  // via uint64/raw
  LQty := LResolver.Resolve(LPubkey.Key).CreateQuantityWithRaw(4741784);
  AssertEquals(LPubkey.Key, LQty.TokenMint, 'mint mismatch');
  AssertEquals(4741784, LQty.QuantityRaw, 'raw mismatch');
  AssertEquals(4741.784, LQty.QuantityDouble, DoubleCompareDelta);
  AssertEquals('FK', LQty.Symbol, 'symbol mismatch');
  AssertEquals(3, LQty.DecimalPlaces, 'decimal places mismatch');
  AssertEquals('4741.784 FK (Fake Coin)', LQty.ToString, 'ToString mismatch');

  // via double
  LQty := LResolver.Resolve(LPubkey.Key).CreateQuantityWithDecimal(14741.784);
  AssertEquals(LPubkey.Key, LQty.TokenMint, 'mint mismatch');
  AssertEquals(14741784, LQty.QuantityRaw, 'raw mismatch');
  AssertEquals(14741.784, LQty.QuantityDouble);
  AssertEquals('FK', LQty.Symbol, 'symbol mismatch');
  AssertEquals(3, LQty.DecimalPlaces, 'decimal places mismatch');
  AssertEquals('14741.784 FK (Fake Coin)', LQty.ToString, 'ToString mismatch');
end;

procedure TTokenMintTests.TestPreloadedMintResolver;
var
  LTokens: ITokenMintResolver;
  LCope: ITokenDef;
begin
  LTokens := TWellKnownTokens.CreateTokenMintResolver;
  LCope := LTokens.Resolve('8HGyAAB1yoM1ttS7pXjHMa3dukTFGQggnFFH3hJZgzQh'); // COPE
  AssertEquals(6, LCope.DecimalPlaces, 'COPE decimals');
end;

procedure TTokenMintTests.TestExtendedTokenMeta;
var
  LJson: string;
  LTokens: ITokenMintResolver;
  LUsdc: ITokenDef;
begin
  LJson := LoadTestData('TokenMint/SimpleTokenList.json');
  LTokens := TTokenMintResolver.ParseTokenList(LJson);

  LUsdc := LTokens.Resolve('EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v');
  AssertTrue(LUsdc <> nil, 'USDC not resolved');
  AssertEquals(6, LUsdc.DecimalPlaces, 'USDC decimals');
  AssertEquals('EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v', LUsdc.TokenMint, 'USDC mint');

  AssertEquals('usd-coin', LUsdc.CoinGeckoId, 'CoinGeckoId');
  AssertEquals('https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v/logo.png',
               LUsdc.TokenLogoUrl, 'TokenLogoUrl');
  AssertEquals('https://www.centre.io/', LUsdc.TokenProjectUrl, 'TokenProjectUrl');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TTokenMintTests);
{$ELSE}
  RegisterTest(TTokenMintTests.Suite);
{$ENDIF}

end.

