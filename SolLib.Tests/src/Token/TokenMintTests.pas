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
  System.SysUtils,
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
  json: string;
  tokens: ITokenMintResolver;
  wsol: ITokenDef;
begin
  json := LoadTestData('TokenMint/SimpleTokenList.json');

  tokens := TTokenMintResolver.ParseTokenList(json);

  wsol := tokens.Resolve(TWellKnownTokens.WrappedSOL.TokenMint);
  AssertTrue(wsol <> nil, 'WSOL not resolved');

  AssertEquals(TWellKnownTokens.WrappedSOL.Symbol,        wsol.Symbol,      'symbol mismatch');
  AssertEquals(TWellKnownTokens.WrappedSOL.TokenName,     wsol.TokenName,   'name mismatch');
  AssertEquals(TWellKnownTokens.WrappedSOL.TokenMint,     wsol.TokenMint,   'mint mismatch');
  AssertEquals(TWellKnownTokens.WrappedSOL.DecimalPlaces, wsol.DecimalPlaces, 'decimals mismatch');
end;

procedure TTokenMintTests.TestTokenInfoResolverUnknowns;
var
  json: string;
  tokens: ITokenMintResolver;
  unknown, unknown2, known, known2: ITokenDef;
  mint: string;
begin
  json := LoadTestData('TokenMint/SimpleTokenList.json');

  tokens := TTokenMintResolver.ParseTokenList(json);

  // lookup unknown mint - non-fatal - returns unknown def
  mint := 'deadbeef11111111111111111111111111111111112';
  unknown := tokens.Resolve(mint);
  AssertTrue(unknown <> nil, 'unknown token not provided');
  AssertEquals(-1, unknown.DecimalPlaces, 'unknown decimals should be -1');
  AssertTrue(Pos('deadbeef', LowerCase(unknown.TokenName)) > 0, 'unknown name should contain deadbeef');
  AssertEquals(mint, unknown.TokenMint, 'unknown mint mismatch');

  // repeat lookup and ensure same instance reused
  unknown2 := tokens.Resolve(unknown.TokenMint);
  AssertTrue(unknown = unknown2, 'resolver should return the same instance for unknown');

  known2 := TTokenDef.Create(unknown2.TokenMint, 'Test Mint', 'MINT', 4);
  tokens.Add(known2);
  known := tokens.Resolve(unknown.TokenMint);
  AssertTrue(known <> nil, 'known token not resolved');
  AssertTrue(known <> unknown, 'known must be a different instance than previous unknown');
  AssertEquals(4, known.DecimalPlaces, 'known decimals');
  AssertEquals('Test Mint', known.TokenName, 'known name');
  AssertEquals(unknown.TokenMint, known.TokenMint, 'mint must match');
end;

procedure TTokenMintTests.TestTokenDefCreateQuantity;
var
  qty: ITokenQuantity;
  dec: Double;
  raw: UInt64;
begin
  qty := TWellKnownTokens.USDC.CreateQuantityWithRaw(4741784);
  AssertEquals(4741784, qty.QuantityRaw, 'raw mismatch');
  AssertEquals(4.741784, qty.QuantityDouble, DoubleCompareDelta);
  AssertEquals('USDC', qty.Symbol, 'symbol mismatch');
  AssertEquals(6, qty.DecimalPlaces, 'decimal places mismatch');
  AssertEquals('4.741784 USDC (USD Coin)', qty.ToString, 'ToString mismatch');

  // Raydium conversions
  dec := TWellKnownTokens.Raydium.ConvertUInt64ToDouble(123456);
  AssertEquals(0.123456, dec, DoubleCompareDelta);

  raw := TWellKnownTokens.Raydium.ConvertDoubleToUInt64(1.23);
  AssertEquals(1230000, raw);
end;

procedure TTokenMintTests.TestDynamicTokenDefCreateQuantity;
var
  pubkey: IPublicKey;
  resolver: ITokenMintResolver;
  qty: ITokenQuantity;
  LTokenDef: ITokenDef;
begin
  pubkey := TPublicKey.Create('FakekjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');

  LTokenDef := TTokenDef.Create(pubkey.Key, 'Fake Coin', 'FK', 3);
  resolver := TTokenMintResolver.Create;
  resolver.Add(LTokenDef);

  // via uint64/raw
  qty := resolver.Resolve(pubkey.Key).CreateQuantityWithRaw(4741784);
  AssertEquals(pubkey.Key, qty.TokenMint, 'mint mismatch');
  AssertEquals(4741784, qty.QuantityRaw, 'raw mismatch');
  AssertEquals(4741.784, qty.QuantityDouble, DoubleCompareDelta);
  AssertEquals('FK', qty.Symbol, 'symbol mismatch');
  AssertEquals(3, qty.DecimalPlaces, 'decimal places mismatch');
  AssertEquals('4741.784 FK (Fake Coin)', qty.ToString, 'ToString mismatch');

  // via double
  qty := resolver.Resolve(pubkey.Key).CreateQuantityWithDecimal(14741.784);
  AssertEquals(pubkey.Key, qty.TokenMint, 'mint mismatch');
  AssertEquals(14741784, qty.QuantityRaw, 'raw mismatch');
  AssertEquals(14741.784, qty.QuantityDouble);
  AssertEquals('FK', qty.Symbol, 'symbol mismatch');
  AssertEquals(3, qty.DecimalPlaces, 'decimal places mismatch');
  AssertEquals('14741.784 FK (Fake Coin)', qty.ToString, 'ToString mismatch');
end;

procedure TTokenMintTests.TestPreloadedMintResolver;
var
  tokens: ITokenMintResolver;
  cope: ITokenDef;
begin
  tokens := TWellKnownTokens.CreateTokenMintResolver;
  cope := tokens.Resolve('8HGyAAB1yoM1ttS7pXjHMa3dukTFGQggnFFH3hJZgzQh'); // COPE
  AssertEquals(6, cope.DecimalPlaces, 'COPE decimals');
end;

procedure TTokenMintTests.TestExtendedTokenMeta;
var
  json: string;
  tokens: ITokenMintResolver;
  usdc: ITokenDef;
begin
  json := LoadTestData('TokenMint/SimpleTokenList.json');
  tokens := TTokenMintResolver.ParseTokenList(json);

  usdc := tokens.Resolve('EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v');
  AssertTrue(usdc <> nil, 'USDC not resolved');
  AssertEquals(6, usdc.DecimalPlaces, 'USDC decimals');
  AssertEquals('EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v', usdc.TokenMint, 'USDC mint');

  AssertEquals('usd-coin', usdc.CoinGeckoId, 'CoinGeckoId');
  AssertEquals('https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v/logo.png',
               usdc.TokenLogoUrl, 'TokenLogoUrl');
  AssertEquals('https://www.centre.io/', usdc.TokenProjectUrl, 'TokenProjectUrl');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TTokenMintTests);
{$ELSE}
  RegisterTest(TTokenMintTests.Suite);
{$ENDIF}

end.

