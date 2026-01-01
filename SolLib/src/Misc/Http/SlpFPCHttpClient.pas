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

unit SlpFPCHttpClient;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  opensslsockets,
  fphttpclient,
  SlpHttpClientBase,
  SlpHttpApiResponse,
  SlpComparerFactory;

type
  TFPCHttpClientImpl = class(THttpClientBase)
  private
    FClient: TFPHTTPClient;

    class function MergeHeaders(const Defaults, Extra: THttpApiHeaderParams): THttpApiHeaderParams; static;
    class procedure ApplyHeaders(const Client: TFPHTTPClient; const Headers: THttpApiHeaderParams); static;
  public
    constructor Create(const AExisting: TFPHTTPClient = nil);
    destructor Destroy; override;

    function GetJson(const AUrl: string;
                     const AQuery: THttpApiQueryParams;
                     const AHeaders: THttpApiHeaderParams): IHttpApiResponse; override;

    function PostJson(const AUrl, AJson: string;
                      const AHeaders: THttpApiHeaderParams): IHttpApiResponse; override;
  end;

implementation

{ TFPCHttpClientImpl }

constructor TFPCHttpClientImpl.Create(const AExisting: TFPHTTPClient);
begin
  inherited Create;
  if Assigned(AExisting) then
    FClient := AExisting
  else
    FClient := TFPHTTPClient.Create(nil);
end;

destructor TFPCHttpClientImpl.Destroy;
begin
  FClient.Free;
  inherited;
end;

class function TFPCHttpClientImpl.MergeHeaders(
  const Defaults, Extra: THttpApiHeaderParams): THttpApiHeaderParams;
var
  K: string;
begin
  Result := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  if Defaults <> nil then
    for K in Defaults.Keys do
      Result.AddOrSetValue(K, Defaults.Items[K]);
  if Extra <> nil then
    for K in Extra.Keys do
      Result.AddOrSetValue(K, Extra.Items[K]);
end;

class procedure TFPCHttpClientImpl.ApplyHeaders(
  const Client: TFPHTTPClient; const Headers: THttpApiHeaderParams);
var
  K: string;
begin
  Client.RequestHeaders.Clear;
  if Headers <> nil then
    for K in Headers.Keys do
      Client.AddHeader(K, Headers.Items[K]);
end;

function TFPCHttpClientImpl.GetJson(const AUrl: string;
  const AQuery: THttpApiQueryParams; const AHeaders: THttpApiHeaderParams): IHttpApiResponse;
var
  Url, Body, StatusText: string;
  StatusCode: Integer;
  DefaultHdrs, FinalHdrs: THttpApiHeaderParams;
  ResponseStream: TStringStream;
begin
  Url := BuildUrlWithQuery(AUrl, AQuery);

  FinalHdrs := nil;
  ResponseStream := nil;
  DefaultHdrs := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  try
    try
      DefaultHdrs.Add('Accept', 'application/json');

      FinalHdrs := MergeHeaders(DefaultHdrs, AHeaders);
      ApplyHeaders(FClient, FinalHdrs);

      ResponseStream := TStringStream.Create('', TEncoding.UTF8);
      FClient.Get(Url, ResponseStream);

      StatusCode := FClient.ResponseStatusCode;
      StatusText := FClient.ResponseStatusText;
      Body := ResponseStream.DataString;

      Result := THttpApiResponse.Create(StatusCode, StatusText, Body);
    except
      on E: Exception do
        raise;
    end;
  finally
    FClient.RequestHeaders.Clear;
    if Assigned(ResponseStream) then
      ResponseStream.Free;
    if Assigned(FinalHdrs) then
      FinalHdrs.Free;
    DefaultHdrs.Free;
  end;
end;

function TFPCHttpClientImpl.PostJson(const AUrl, AJson: string;
  const AHeaders: THttpApiHeaderParams): IHttpApiResponse;
var
  Body, StatusText: string;
  StatusCode: Integer;
  DefaultHdrs, FinalHdrs: THttpApiHeaderParams;
  ResponseStream: TStringStream;
  RequestBodyStream: TStringStream;
begin
  FinalHdrs := nil;
  RequestBodyStream := nil;
  ResponseStream := nil;
  DefaultHdrs := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  try
    try
      DefaultHdrs.Add('Content-Type', 'application/json');

      FinalHdrs := MergeHeaders(DefaultHdrs, AHeaders);
      ApplyHeaders(FClient, FinalHdrs);

      RequestBodyStream := TStringStream.Create(AJson, TEncoding.UTF8);
      FClient.RequestBody := RequestBodyStream;

      ResponseStream := TStringStream.Create('', TEncoding.UTF8);
      FClient.Post(AUrl, ResponseStream);

      StatusCode := FClient.ResponseStatusCode;
      StatusText := FClient.ResponseStatusText;
      Body := ResponseStream.DataString;

      Result := THttpApiResponse.Create(StatusCode, StatusText, Body);
    except
      on E: Exception do
        raise;
    end;
  finally
    FClient.RequestHeaders.Clear;
    if Assigned(ResponseStream) then
      ResponseStream.Free;
    if Assigned(RequestBodyStream) then
      RequestBodyStream.Free;
    if Assigned(FinalHdrs) then
      FinalHdrs.Free;
    DefaultHdrs.Free;
  end;
end;

end.
