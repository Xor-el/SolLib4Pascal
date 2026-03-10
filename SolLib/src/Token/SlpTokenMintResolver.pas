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

unit SlpTokenMintResolver;

{$I ../Include/SolLib.inc}

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
    /// <param name="ATokenMint">The token mint address</param>
    /// <returns>An instance of the TokenDef containing known info about this token or a constructed unknown entry</returns>
    function Resolve(const ATokenMint: string): ITokenDef;
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
  LToken: TTokenListItem;
begin
  Create;
  for LToken in ATokenList.Tokens do
    Add(LToken);
end;

destructor TTokenMintResolver.Destroy;
begin
  if Assigned(FTokens) then
   FTokens.Free;

  inherited;
end;

function TTokenMintResolver.GetKnownTokens: TDictionary<string, ITokenDef>;
var
  LToken: TPair<string, ITokenDef>;
begin
  Result := TDictionary<string, ITokenDef>.Create();
  for LToken in FTokens do
    Result.Add(LToken.Key, LToken.Value);
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
  LResp: IHttpApiResponse;
begin
  if AHttpClient = nil then
    raise EArgumentNilException.Create('Http');

  LResp := AHttpClient.GetJson(AUrl);

  if not LResp.IsSuccessStatusCode then
    raise ETokenMintResolveException.CreateFmt(
      'Failed to fetch token list. HTTP %d %s',
      [LResp.StatusCode, LResp.StatusText]
    );

  Result := ParseTokenList(LResp.ResponseBody);
end;

class function TTokenMintResolver.ParseTokenList(const AJson: string)
  : ITokenMintResolver;
var
  LTokenList: TTokenListDoc;
begin
  if AJson = '' then
    raise EArgumentNilException.Create('json');

  LTokenList := ParseJsonToTokenListDoc(AJson);
  try
    Result := CreateFromTokenList(LTokenList);
  finally
    LTokenList.Free;
  end;
end;

function TTokenMintResolver.Resolve(const ATokenMint: string): ITokenDef;
var
  LToken: ITokenDef;
begin
  if FTokens.TryGetValue(ATokenMint, LToken) then
    Exit(LToken)
  else
  begin
    // Create a placeholder "unknown" token
    LToken := TTokenDef.Create(ATokenMint, Format('Unknown %s', [ATokenMint]
      ), '', -1);
    FTokens.AddOrSetValue(ATokenMint, LToken);
    Result := LToken;
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
  LToken: ITokenDef;
  LLogoUrl, LCoinGeckoId, LProjectUrl: string;
  LV: TValue;
begin
  if ATokenItem = nil then
    raise EArgumentNilException.Create('tokenItem');

  LLogoUrl := ATokenItem.LogoUri;
  LCoinGeckoId := '';
  LProjectUrl := '';

  if ATokenItem.Extensions = nil then
    Exit;

  if ATokenItem.Extensions.TryGetValue('coingeckoId', LV) and LV.IsType<string> then
    LCoinGeckoId := LV.AsType<string>;

  if ATokenItem.Extensions.TryGetValue('website', LV) and LV.IsType<string> then
    LProjectUrl := LV.AsType<string>;

  LToken := TTokenDef.Create(
    ATokenItem.Address,
    ATokenItem.Name,
    ATokenItem.Symbol,
    ATokenItem.Decimals
  );
  LToken.CoinGeckoId := LCoinGeckoId;
  LToken.TokenLogoUrl := LLogoUrl;
  LToken.TokenProjectUrl := LProjectUrl;

  FTokens.AddOrSetValue(LToken.TokenMint, LToken);
end;


class function TTokenMintResolver.ParseJsonToTokenListDoc(const AJson: string)
  : TTokenListDoc;
begin
  if AJson = '' then
    raise EArgumentNilException.Create('json');

  Result := TJsonSerializerFactory.Shared.Deserialize<TTokenListDoc>(AJson);
end;

end.
