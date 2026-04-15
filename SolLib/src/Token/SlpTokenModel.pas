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

unit SlpTokenModel;

{$I ../Include/SolLib.inc}

interface

uses
  SysUtils,
  Rtti,
  Generics.Collections,
  System.JSON.Serializers,
  SlpValueHelpers,
  SlpJsonListConverter,
  SlpTokenListItemExtensionsConverter;

type
  /// <summary>
  /// Token Definition object used by the TokenMintResolver.
  /// TokenMint uniquely identifies a token on the Solana blockchain.
  /// Symbol is purely cosmetic and is not sufficient to uniquely identify a token by itself.
  /// </summary>
  TTokenListItem = class;

  TTokenListItemCollectionConverter = class(TPreserveNullOnReadJsonObjectListConverter<TTokenListItem>);

  /// <summary>
  /// Internal class used to deserialize tokenlist.json items.
  /// </summary>
  TTokenListItem = class
  private
    FAddress: string;
    FSymbol: string;
    FName: string;
    FDecimals: Integer;
    FLogoUri: string;
    FExtensions: TDictionary<string, TValue>;

  public
   destructor Destroy; override;

   function Clone: TTokenListItem;

    property Address: string read FAddress write FAddress;
    property Symbol: string read FSymbol write FSymbol;
    property Name: string read FName write FName;
    property Decimals: Integer read FDecimals write FDecimals;
    property LogoUri: string read FLogoUri write FLogoUri;
    [JsonConverter(TTokenListItemExtensionsConverter)]
    property Extensions: TDictionary<string, TValue> read FExtensions write FExtensions;
  end;

  /// <summary>
  /// Internal class used to deserialize tokenlist.json document.
  /// </summary>
  TTokenListDoc = class
  private
    FTokens: TObjectList<TTokenListItem>;
  public
    destructor Destroy; override;

    function Clone: TTokenListDoc;

    [JsonConverter(TTokenListItemCollectionConverter)]
    property Tokens: TObjectList<TTokenListItem> read FTokens write FTokens;

  end;

implementation

{ TTokenListItem }

function TTokenListItem.Clone: TTokenListItem;
var
  LExtension: TPair<string, TValue>;
  LExtensions: TDictionary<string, TValue>;
begin
  Result := TTokenListItem.Create;
  Result.FAddress := FAddress;
  Result.FSymbol := FSymbol;
  Result.FName := FName;
  Result.FDecimals := FDecimals;
  Result.FLogoUri := FLogoUri;

  LExtensions := TDictionary<string, TValue>.Create();

  for LExtension in FExtensions do
    LExtensions.Add(LExtension.Key, LExtension.Value.Clone);

  Result.FExtensions := LExtensions;
end;

destructor TTokenListItem.Destroy;
var
  LPair: TPair<string, TValue>;
  LObj: TObject;
begin
  if Assigned(FExtensions) then
  begin
    for LPair in FExtensions do
    begin
     if LPair.Value.IsObject then
      begin
        LObj := LPair.Value.AsObject;
        if Assigned(LObj) then
          LObj.Free;
      end;
    end;
    FExtensions.Free;
  end;

  inherited;
end;

{ TTokenListDoc }

function TTokenListDoc.Clone: TTokenListDoc;
var
 LToken: TTokenListItem;
 LTokenList: TObjectList<TTokenListItem>;
begin
  Result := TTokenListDoc.Create;
  LTokenList := TObjectList<TTokenListItem>.Create(True);

  for LToken in FTokens do
    LTokenList.Add(LToken.Clone);

  Result.FTokens := LTokenList;
end;

destructor TTokenListDoc.Destroy;
begin
  if Assigned(FTokens) then
  begin
    FTokens.Free;
  end;
  inherited;
end;

end.

