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

unit SlpTokenMintResolver;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  System.JSON.Serializers,
  SlpTokenDomain,
  SlpTokenModel,
  SlpJsonKit,
  SlpHttpApiClient,
  SlpHttpApiResponse,
  SlpSolLibExceptions;

type
  /// <summary>
  /// Contains the method used to resolve mint public key addresses into TokenDef objects
  /// </summary>
  ITokenMintResolver = interface
    ['{FEFB4841-A1DB-4467-82CA-4F477E30FFA2}']
    /// <summary>
    /// Resolve a mint public key address into a TokenDef object
    /// </summary>
    /// <param name="TokenMint">The token mint address</param>
    /// <returns>An instance of the TokenDef containing known info about this token or a constructed unknown entry</returns>
    function Resolve(const TokenMint: string): ITokenDef;
    procedure Add(AToken: ITokenDef); overload;
    procedure Add(ATokenItem: TTokenListItem); overload;

    function GetKnownTokens(): TDictionary<string, ITokenDef>;

    property KnownTokens: TDictionary<string, ITokenDef> read GetKnownTokens;
  end;

  TTokenMintResolver = class(TInterfacedObject, ITokenMintResolver)
  private const
    TOKENLIST_GITHUB_URL =
      'https://cdn.jsdelivr.net/gh/solflare-wallet/token-list@latest/solana-tokenlist.json';
  private
    FTokens: TDictionary<string, ITokenDef>;

    constructor CreateFromTokenList(ATokenList: TTokenListDoc);

    function Resolve(const ATokenMint: string): ITokenDef;
    procedure Add(AToken: ITokenDef); overload;
    procedure Add(ATokenItem: TTokenListItem); overload;

    function GetKnownTokens(): TDictionary<string, ITokenDef>;

    class function ParseJsonToTokenListDoc(const AJson: string): TTokenListDoc;
  public
    constructor Create; overload;
    destructor Destroy; override;

    class function Load: ITokenMintResolver; overload;
    class function Load(const AUrl: string): ITokenMintResolver; overload;
    class function Load(const AUrl: string; const AHttpClient: IHttpApiClient): ITokenMintResolver; overload;
    class function ParseTokenList(const AJson: string): ITokenMintResolver;
  end;

implementation

{ TTokenMintResolver }

constructor TTokenMintResolver.Create;
begin
  inherited Create;
  FTokens := TDictionary<string, ITokenDef>.Create();
end;

constructor TTokenMintResolver.CreateFromTokenList(ATokenList: TTokenListDoc);
var
  Token: TTokenListItem;
begin
  Create;
  for Token in ATokenList.Tokens do
    Add(Token);
end;

destructor TTokenMintResolver.Destroy;
begin
  if Assigned(FTokens) then
   FTokens.Free;

  inherited;
end;

function TTokenMintResolver.GetKnownTokens: TDictionary<string, ITokenDef>;
var
  Token: TPair<string, ITokenDef>;
begin
  Result := TDictionary<string, ITokenDef>.Create();
  for Token in FTokens do
    Result.Add(Token.Key, Token.Value);
end;

class function TTokenMintResolver.Load: ITokenMintResolver;
begin
  Result := Load(TOKENLIST_GITHUB_URL);
end;

class function TTokenMintResolver.Load(const AUrl: string): ITokenMintResolver;
var
  LHttpClient: IHttpApiClient;
begin
  LHttpClient := THttpApiClient.Create;
  Result := Load(AUrl, LHttpClient);
end;

class function TTokenMintResolver.Load(const AUrl: string; const AHttpClient: IHttpApiClient): ITokenMintResolver;
var
  Resp: IHttpApiResponse;
begin
  if AHttpClient = nil then
    raise EArgumentNilException.Create('Http');

  Resp := AHttpClient.GetJson(AUrl);

  if Resp.StatusCode <> 200 then
    raise ETokenMintResolveException.CreateFmt(
      'Failed to fetch token list. HTTP %d %s',
      [Resp.StatusCode, Resp.StatusText]
    );

  Result := ParseTokenList(Resp.ResponseBody);
end;

class function TTokenMintResolver.ParseTokenList(const AJson: string)
  : ITokenMintResolver;
var
  TokenList: TTokenListDoc;
begin
  if AJson = '' then
    raise EArgumentNilException.Create('json');

  TokenList := ParseJsonToTokenListDoc(AJson);
  try
    Result := CreateFromTokenList(TokenList);
  finally
    TokenList.Free;
  end;
end;

function TTokenMintResolver.Resolve(const ATokenMint: string): ITokenDef;
var
  Token: ITokenDef;
begin
  if FTokens.TryGetValue(ATokenMint, Token) then
    Exit(Token)
  else
  begin
    // Create a placeholder "unknown" token
    Token := TTokenDef.Create(ATokenMint, Format('Unknown %s', [ATokenMint]
      ), '', -1);
    FTokens.AddOrSetValue(ATokenMint, Token);
    Result := Token;
  end;
end;


procedure TTokenMintResolver.Add(AToken: ITokenDef);
begin
  if AToken = nil then
    raise EArgumentNilException.Create('token');
  FTokens.AddOrSetValue(AToken.TokenMint, AToken);
end;

procedure TTokenMintResolver.Add(ATokenItem: TTokenListItem);
var
  Token: ITokenDef;
  LogoUrl, CoinGeckoId, ProjectUrl: string;
  V: TValue;
begin
  if ATokenItem = nil then
    raise EArgumentNilException.Create('tokenItem');

  LogoUrl := ATokenItem.LogoUri;
  CoinGeckoId := '';
  ProjectUrl := '';

  if (ATokenItem.Extensions <> nil) then
  begin
    if (ATokenItem.Extensions <> nil) then
    begin
      if ATokenItem.Extensions.TryGetValue('coingeckoId', V) then
        if V.IsType<string> then
          CoinGeckoId := V.AsType<string>;

      if ATokenItem.Extensions.TryGetValue('website', V) then
        if V.IsType<string> then
          ProjectUrl := V.AsType<string>;
    end;

    Token := TTokenDef.Create(ATokenItem.Address, ATokenItem.Name,
      ATokenItem.Symbol, ATokenItem.Decimals);
    Token.CoinGeckoId := CoinGeckoId;
    Token.TokenLogoUrl := LogoUrl;
    Token.TokenProjectUrl := ProjectUrl;

    FTokens.AddOrSetValue(Token.TokenMint, Token);
  end;

end;

class function TTokenMintResolver.ParseJsonToTokenListDoc(const AJson: string)
  : TTokenListDoc;
begin
  if AJson = '' then
    raise EArgumentNilException.Create('json');

  Result := TJsonSerializerFactory.Shared.Deserialize<TTokenListDoc>(AJson);
end;

end.
