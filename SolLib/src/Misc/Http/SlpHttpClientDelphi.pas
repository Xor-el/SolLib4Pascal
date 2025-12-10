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

unit SlpHttpClientDelphi;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Net.URLClient,
  System.Net.HttpClient,
  SlpHttpApiResponse,
  SlpComparerFactory,
  SlpHttpClientBase;

type
  TDelphiHttpClientImpl = class(THttpClientBase)
  private
    FClient: THTTPClient;

    class function MergeHeaders(const Defaults, Extra: THttpApiHeaderParams): TNetHeaders; static;
  public
    constructor Create(const AExisting: THTTPClient = nil);
    destructor Destroy; override;

    function GetJson(const AUrl: string;
                     const AQuery: THttpApiQueryParams;
                     const AHeaders: THttpApiHeaderParams): IHttpApiResponse; override;

    function PostJson(const AUrl, AJson: string;
                      const AHeaders: THttpApiHeaderParams): IHttpApiResponse; override;
  end;

implementation

{ TDelphiHttpClientImpl }

constructor TDelphiHttpClientImpl.Create(const AExisting: THTTPClient);
begin
  inherited Create;
  if Assigned(AExisting) then
   FClient := AExisting
  else
   FClient := THTTPClient.Create;
end;

destructor TDelphiHttpClientImpl.Destroy;
begin
  FClient.Free;
  inherited;
end;

class function TDelphiHttpClientImpl.MergeHeaders(
  const Defaults, Extra: THttpApiHeaderParams): TNetHeaders;
var
  Tmp: THttpApiHeaderParams;
  Keys: TArray<string>;
  I: Integer;
  K: string;
begin
  Tmp := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  try
    if Defaults <> nil then
      for K in Defaults.Keys do
        Tmp.AddOrSetValue(K, Defaults.Items[K]);

    if Extra <> nil then
      for K in Extra.Keys do
        Tmp.AddOrSetValue(K, Extra.Items[K]);

    Keys := Tmp.Keys.ToArray;
    SetLength(Result, Length(Keys));
    for I := 0 to High(Keys) do
    begin
      Result[I].Name  := Keys[I];
      Result[I].Value := Tmp.Items[Keys[I]];
    end;
  finally
    Tmp.Free;
  end;
end;

function TDelphiHttpClientImpl.GetJson(const AUrl: string;
  const AQuery: THttpApiQueryParams; const AHeaders: THttpApiHeaderParams): IHttpApiResponse;
var
  Url, Body, StatusText: string;
  Resp: IHTTPResponse;
  StatusCode: Integer;
  DefaultHdrs, ExtraHdrs: THttpApiHeaderParams;
  NetHeaders: TNetHeaders;
begin
  Url := BuildUrlWithQuery(AUrl, AQuery);

  DefaultHdrs := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  ExtraHdrs := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  try
    DefaultHdrs.Add('Accept', 'application/json');

    if AHeaders <> nil then
      for var K in AHeaders.Keys do ExtraHdrs.AddOrSetValue(K, AHeaders.Items[K]);

    NetHeaders := MergeHeaders(DefaultHdrs, ExtraHdrs);
  finally
    DefaultHdrs.Free;
    ExtraHdrs.Free;
  end;

  try
    Resp := FClient.Get(Url, nil, NetHeaders);
    Body := Resp.ContentAsString(TEncoding.UTF8);
    StatusCode := Resp.StatusCode;
    StatusText := Resp.StatusText;
  except
    on E: Exception do
      raise;
  end;

  Result := THttpApiResponse.Create(StatusCode, StatusText, Body);
end;

function TDelphiHttpClientImpl.PostJson(const AUrl, AJson: string;
  const AHeaders: THttpApiHeaderParams): IHttpApiResponse;
var
  MS: TMemoryStream;
  Buffer: TBytes;
  Body, StatusText: string;
  Resp: IHTTPResponse;
  StatusCode: Integer;
  DefaultHdrs, ExtraHdrs: THttpApiHeaderParams;
  NetHeaders: TNetHeaders;
begin
  DefaultHdrs := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  ExtraHdrs := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  try
    DefaultHdrs.Add('Content-Type', 'application/json');

    if AHeaders <> nil then
      for var K in AHeaders.Keys do ExtraHdrs.AddOrSetValue(K, AHeaders.Items[K]);

    NetHeaders := MergeHeaders(DefaultHdrs, ExtraHdrs);
  finally
    DefaultHdrs.Free;
    ExtraHdrs.Free;
  end;

  MS := TMemoryStream.Create;
  try
    if AJson <> '' then
    begin
      Buffer := TEncoding.UTF8.GetBytes(AJson);
      if Length(Buffer) > 0 then MS.WriteBuffer(Buffer, Length(Buffer));
    end;
    MS.Position := 0;

    try
      Resp := FClient.Post(AUrl, MS, nil, NetHeaders);
      Body := Resp.ContentAsString(TEncoding.UTF8);
      StatusCode := Resp.StatusCode;
      StatusText := Resp.StatusText;
    except
      on E: Exception do
        raise;
    end;

    Result := THttpApiResponse.Create(StatusCode, StatusText, Body);
  finally
    MS.Free;
  end;
end;

end.

