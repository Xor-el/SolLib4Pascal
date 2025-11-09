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

unit SlpWellKnownTokens;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpTokenDomain,
  SlpTokenMintResolver;

type
  /// <summary>
  /// Defines well known tokens and their SPL Token Address, name, symbol and number of decimal places
  /// </summary>
  TWellKnownTokens = class
  private
    class var FTokens: TList<ITokenDef>;

    class var FWrappedSOL: ITokenDef;
    class var FUSDC: ITokenDef;
    class var FUSDT: ITokenDef;
    class var FSerum: ITokenDef;
    class var FRaydium: ITokenDef;
    class var FBonfida: ITokenDef;
    class var FCope: ITokenDef;
    class var FKin: ITokenDef;
    class var FTulip: ITokenDef;
    class var FOrca: ITokenDef;
    class var FMango: ITokenDef;
    class var FSamoyed: ITokenDef;
    class var FSaber: ITokenDef;
    class var FFabric: ITokenDef;
    class var FBoring: ITokenDef;
    class var FLiquid: ITokenDef;
    class var FStep: ITokenDef;
    class var FSolrise: ITokenDef;
    class var FOnly1: ITokenDef;
    class var FStarAtlas: ITokenDef;
    class var FStarAtlasDao: ITokenDef;
    class var FWoof: ITokenDef;
    class var FShadowToken: ITokenDef;


    class constructor Create;
    class destructor Destroy;

   public
    /// <summary>
    /// Get all TokenDefs in one list
    /// </summary>
    /// <returns>A list of well known TokenDef</returns>
    class function All: TList<ITokenDef>;

    /// <summary>
    /// Create a TokenMintResolver pre-loaded with well known tokens
    /// </summary>
    /// <returns>An instance of the TokenMintResolver bootstrapped with the well known tokens</returns>
    class function CreateTokenMintResolver: ITokenMintResolver;

        /// <summary>
    /// Wrapped SOL
    /// </summary>
    class property WrappedSOL: ITokenDef read FWrappedSOL;

    /// <summary>
    /// USDC
    /// </summary>
    class property USDC: ITokenDef read FUSDC;

    /// <summary>
    /// USDT
    /// </summary>
    class property USDT: ITokenDef read FUSDT;

    /// <summary>
    /// SRM (Serum)
    /// </summary>
    class property Serum: ITokenDef read FSerum;

    /// <summary>
    /// RAY (Raydium)
    /// </summary>
    class property Raydium: ITokenDef read FRaydium;

    /// <summary>
    /// FIDA (Bonfida)
    /// </summary>
    class property Bonfida: ITokenDef read FBonfida;

    /// <summary>
    /// COPE
    /// </summary>
    class property Cope: ITokenDef read FCope;

    /// <summary>
    /// KIN
    /// </summary>
    class property Kin: ITokenDef read FKin;

    /// <summary>
    /// TULIP (Tulip/Solfarm)
    /// </summary>
    class property Tulip: ITokenDef read FTulip;

    /// <summary>
    /// Orca
    /// </summary>
    class property Orca: ITokenDef read FOrca;

    /// <summary>
    /// MNGO (Mango Markets)
    /// </summary>
    class property Mango: ITokenDef read FMango;

    /// <summary>
    /// SAMO (Samoyed Coin)
    /// </summary>
    class property Samoyed: ITokenDef read FSamoyed;

    /// <summary>
    /// SBR (Saber)
    /// </summary>
    class property Saber: ITokenDef read FSaber;

    /// <summary>
    /// FAB (Fabric Protocol)
    /// </summary>
    class property Fabric: ITokenDef read FFabric;

    /// <summary>
    /// BOP (Boring Protocol)
    /// </summary>
    class property Boring: ITokenDef read FBoring;

    /// <summary>
    /// LIQ (Liquid)
    /// </summary>
    class property Liquid: ITokenDef read FLiquid;

    /// <summary>
    /// Step
    /// </summary>
    class property Step: ITokenDef read FStep;

    /// <summary>
    /// SLRS (Solrise Finance)
    /// </summary>
    class property Solrise: ITokenDef read FSolrise;

    /// <summary>
    /// LIKE (Only1)
    /// </summary>
    class property Only1: ITokenDef read FOnly1;

    /// <summary>
    /// ATLAS (Star Atlas)
    /// </summary>
    class property StarAtlas: ITokenDef read FStarAtlas;

    /// <summary>
    /// POLIS (Star Atlas DAO)
    /// </summary>
    class property StarAtlasDao: ITokenDef read FStarAtlasDao;

    /// <summary>
    /// WOOF (WOOFENCOMICS)
    /// </summary>
    class property Woof: ITokenDef read FWoof;

    /// <summary>
    /// Shadow Token (SHDW)
    /// </summary>
    class property ShadowToken: ITokenDef read FShadowToken;

  end;

implementation

class constructor TWellKnownTokens.Create;
begin
  FTokens := TList<ITokenDef>.Create();
  
  // Initialize well known tokens
  FWrappedSOL := TTokenDef.Create('So11111111111111111111111111111111111111112', 'Wrapped SOL', 'SOL', 9);
  FUSDC := TTokenDef.Create('EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v', 'USD Coin', 'USDC', 6);
  FUSDT := TTokenDef.Create('Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB', 'USDT', 'USDT', 6);
  FSerum := TTokenDef.Create('SRMuApVNdxXokk5GT7XD5cUUgXMBCoAz2LHeuAoKWRt', 'Serum', 'SRM', 6);
  FRaydium := TTokenDef.Create('4k3Dyjzvzp8eMZWUXbBCjEvwSkkk59S5iCNLY3QrkX6R', 'Raydium', 'RAY', 6);
  FBonfida := TTokenDef.Create('EchesyfXePKdLtoiZSL8pBe8Myagyy8ZRqsACNCFGnvp', 'Bonfida', 'FIDA', 6);
  FCope := TTokenDef.Create('8HGyAAB1yoM1ttS7pXjHMa3dukTFGQggnFFH3hJZgzQh', 'Cope', 'COPE', 6);
  FKin := TTokenDef.Create('kinXdEcpDQeHPEuQnqmUgtYykqKGVFq6CeVX5iAHJq6', 'KIN', 'KIN', 9);
  FTulip := TTokenDef.Create('TuLipcqtGVXP9XR62wM8WWCm6a9vhLs7T1uoWBk6FDs', 'Tulip', 'TULIP', 6);
  FOrca := TTokenDef.Create('orcaEKTdK7LKz57vaAYr9QeNsVEPfiu6QeMU1kektZE', 'Orca', 'ORCA', 6);
  FMango := TTokenDef.Create('MangoCzJ36AjZyKwVj3VnYU4GTonjfVEnJmvvWaxLac', 'Mango', 'MNGO', 6);
  FSamoyed := TTokenDef.Create('7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU', 'Samoyed Coin', 'SAMO', 9);
  FSaber := TTokenDef.Create('Saber2gLauYim4Mvftnrasomsv6NvAuncvMEZwcLpD1', 'Saber', 'SBR', 6);
  FFabric := TTokenDef.Create('EdAhkbj5nF9sRM7XN7ewuW8C9XEUMs8P7cnoQ57SYE96', 'Fabric', 'FAB', 9);
  FBoring := TTokenDef.Create('BLwTnYKqf7u4qjgZrrsKeNs2EzWkMLqVCu6j8iHyrNA3', 'Boring Protocol', 'BOP', 9);
  FLiquid := TTokenDef.Create('4wjPQJ6PrkC4dHhYghwJzGBVP78DkBzA2U3kHoFNBuhj', 'LIQ Protocol', 'LIQ', 6);
  FStep := TTokenDef.Create('StepAscQoEioFxxWGnh2sLBDFp9d8rvKz2Yp39iDpyT', 'Step', 'STEP', 9);
  FSolrise := TTokenDef.Create('SLRSSpSLUTP7okbCUBYStWCo1vUgyt775faPqz8HUMr', 'Solrise Finance', 'SLRS', 6);
  FOnly1 := TTokenDef.Create('3bRTivrVsitbmCTGtqwp7hxXPsybkjn4XLNtPsHqa3zR', 'Only1', 'LIKE', 9);
  FStarAtlas := TTokenDef.Create('ATLASXmbPQxBUYbxPsV97usA3fPQYEqzQBUHgiFCUsXx', 'Star Atlas', 'ATLAS', 8);
  FStarAtlasDao := TTokenDef.Create('poLisWXnNRwC6oBu1vHiuKQzFjGL4XDSu4g9qjz9qVk', 'Star Atlas DAO', 'POLIS', 8);
  FWoof := TTokenDef.Create('9nEqaUcb16sQ3Tn1psbkWqyhPdLmfHWjKGymREjsAgTE', 'WOOFENOMICS', 'WOOF', 6);
  FShadowToken := TTokenDef.Create('SHDWyBxihqiCj6YekG2GUr7wqKLeLAMK1gHZck9pL6y', 'Shadow Token', 'SHDW', 9);
  
  // Add all tokens to the list
  FTokens.Add(FWrappedSOL);
  FTokens.Add(FUSDC);
  FTokens.Add(FUSDT);
  FTokens.Add(FSerum);
  FTokens.Add(FRaydium);
  FTokens.Add(FBonfida);
  FTokens.Add(FCope);
  FTokens.Add(FKin);
  FTokens.Add(FTulip);
  FTokens.Add(FOrca);
  FTokens.Add(FMango);
  FTokens.Add(FSamoyed);
  FTokens.Add(FSaber);
  FTokens.Add(FFabric);
  FTokens.Add(FBoring);
  FTokens.Add(FLiquid);
  FTokens.Add(FStep);
  FTokens.Add(FSolrise);
  FTokens.Add(FOnly1);
  FTokens.Add(FStarAtlas);
  FTokens.Add(FStarAtlasDao);
  FTokens.Add(FWoof);
  FTokens.Add(FShadowToken);
end;

class destructor TWellKnownTokens.Destroy;
begin
  FTokens.Free;
end;


class function TWellKnownTokens.All: TList<ITokenDef>;
var
  token: ITokenDef;
begin
  // Return new instance of list for immutability
  Result := TList<ITokenDef>.Create();
  for token in FTokens do
    Result.Add(token);
end;

class function TWellKnownTokens.CreateTokenMintResolver: ITokenMintResolver;
var
  Token: ITokenDef;
begin
  Result := TTokenMintResolver.Create;
  for Token in FTokens do
    Result.Add(Token);
end;

end.
