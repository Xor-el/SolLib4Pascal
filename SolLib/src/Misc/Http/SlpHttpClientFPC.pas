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

unit SlpHttpClientFPC;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  fphttpclient,
  opensslsockets,
  httpprotocol,
  URIParser,
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
  DefaultHdrs, ExtraHdrs, FinalHdrs: THttpApiHeaderParams;
  ResponseStream: TStringStream;
begin
  Url := BuildUrlWithQuery(AUrl, AQuery);

  DefaultHdrs := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  ExtraHdrs   := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  try
    DefaultHdrs.Add('Accept', 'application/json');

    if AHeaders <> nil then
      for var K in AHeaders.Keys do
        ExtraHdrs.AddOrSetValue(K, AHeaders.Items[K]);

    FinalHdrs := MergeHeaders(DefaultHdrs, ExtraHdrs);
    try
      ApplyHeaders(FClient, FinalHdrs);

      ResponseStream := TStringStream.Create('', TEncoding.UTF8);
      try
        FClient.Get(Url, ResponseStream);

        StatusCode := FClient.ResponseStatusCode;
        StatusText := FClient.ResponseStatusText;

        Body := ResponseStream.DataString;
        Result := THttpApiResponse.Create(StatusCode, StatusText, Body);
      finally
        ResponseStream.Free;
        FClient.RequestHeaders.Clear;
      end;
    finally
      FinalHdrs.Free;
    end;
  except
    on E: Exception do
      raise;
  finally
    ExtraHdrs.Free;
    DefaultHdrs.Free;
  end;
end;

function TFPCHttpClientImpl.PostJson(const AUrl, AJson: string;
  const AHeaders: THttpApiHeaderParams): IHttpApiResponse;
var
  MS: TMemoryStream;
  Buffer: TBytes;
  Body, StatusText: string;
  StatusCode: Integer;
  DefaultHdrs, ExtraHdrs, FinalHdrs: THttpApiHeaderParams;
  ResponseStream: TStringStream;
  K: string;
begin
  DefaultHdrs := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  ExtraHdrs   := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  try
    DefaultHdrs.Add('Content-Type', 'application/json');

    if AHeaders <> nil then
      for K in AHeaders.Keys do
        ExtraHdrs.AddOrSetValue(K, AHeaders.Items[K]);

    FinalHdrs := MergeHeaders(DefaultHdrs, ExtraHdrs);
    try
      ApplyHeaders(FClient, FinalHdrs);

      MS := TMemoryStream.Create;
      try
        if AJson <> '' then
        begin
          Buffer := TEncoding.UTF8.GetBytes(AJson);
          if Length(Buffer) > 0 then
          begin
            MS.WriteBuffer(Buffer, Length(Buffer));
          end;
        end;
        MS.Position := 0;

        ResponseStream := TStringStream.Create('', TEncoding.UTF8);
        try
          FClient.Post(AUrl, MS, ResponseStream);

          StatusCode := FClient.ResponseStatusCode;
          StatusText := FClient.ResponseStatusText;

          Body := ResponseStream.DataString;
          Result := THttpApiResponse.Create(StatusCode, StatusText, Body);
        finally
          ResponseStream.Free;
          FClient.RequestHeaders.Clear;
        end;
      finally
        MS.Free;
      end;
    finally
      FinalHdrs.Free;
    end;
  except
    on E: Exception do
      raise;
  finally
    ExtraHdrs.Free;
    DefaultHdrs.Free;
  end;
end;


end.

