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

    class function MergeHeaders(const ADefaults, AExtra: THttpApiHeaderParams): THttpApiHeaderParams; static;
    class procedure ApplyHeaders(const AClient: TFPHTTPClient; const AHeaders: THttpApiHeaderParams); static;
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
  const ADefaults, AExtra: THttpApiHeaderParams): THttpApiHeaderParams;
var
  LKey: string;
begin
  Result := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  if ADefaults <> nil then
    for LKey in ADefaults.Keys do
      Result.AddOrSetValue(LKey, ADefaults.Items[LKey]);
  if AExtra <> nil then
    for LKey in AExtra.Keys do
      Result.AddOrSetValue(LKey, AExtra.Items[LKey]);
end;

class procedure TFPCHttpClientImpl.ApplyHeaders(
  const AClient: TFPHTTPClient; const AHeaders: THttpApiHeaderParams);
var
  LKey: string;
begin
  AClient.RequestHeaders.Clear;
  if AHeaders <> nil then
    for LKey in AHeaders.Keys do
      AClient.AddHeader(LKey, AHeaders.Items[LKey]);
end;

function TFPCHttpClientImpl.GetJson(const AUrl: string;
  const AQuery: THttpApiQueryParams; const AHeaders: THttpApiHeaderParams): IHttpApiResponse;
var
  LUrl, LBody, LStatusText: string;
  LStatusCode: Integer;
  LDefaultHdrs, LFinalHdrs: THttpApiHeaderParams;
  LResponseStream: TStringStream;
begin
  LUrl := BuildUrlWithQuery(AUrl, AQuery);

  LFinalHdrs := nil;
  LResponseStream := nil;
  LDefaultHdrs := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  try
    try
      LDefaultHdrs.Add('Accept', 'application/json');

      LFinalHdrs := MergeHeaders(LDefaultHdrs, AHeaders);
      ApplyHeaders(FClient, LFinalHdrs);

      LResponseStream := TStringStream.Create('', TEncoding.UTF8);
      FClient.Get(LUrl, LResponseStream);

      LStatusCode := FClient.ResponseStatusCode;
      LStatusText := FClient.ResponseStatusText;
      LBody := LResponseStream.DataString;

      Result := THttpApiResponse.Create(LStatusCode, LStatusText, LBody);
    except
      on E: Exception do
        raise;
    end;
  finally
    FClient.RequestHeaders.Clear;
    if Assigned(LResponseStream) then
      LResponseStream.Free;
    if Assigned(LFinalHdrs) then
      LFinalHdrs.Free;
    LDefaultHdrs.Free;
  end;
end;

function TFPCHttpClientImpl.PostJson(const AUrl, AJson: string;
  const AHeaders: THttpApiHeaderParams): IHttpApiResponse;
var
  LBody, LStatusText: string;
  LStatusCode: Integer;
  LDefaultHdrs, LFinalHdrs: THttpApiHeaderParams;
  LResponseStream: TStringStream;
  LRequestBodyStream: TStringStream;
begin
  LFinalHdrs := nil;
  LRequestBodyStream := nil;
  LResponseStream := nil;
  LDefaultHdrs := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  try
    try
      LDefaultHdrs.Add('Content-Type', 'application/json');

      LFinalHdrs := MergeHeaders(LDefaultHdrs, AHeaders);
      ApplyHeaders(FClient, LFinalHdrs);

      LRequestBodyStream := TStringStream.Create(AJson, TEncoding.UTF8);
      FClient.RequestBody := LRequestBodyStream;

      LResponseStream := TStringStream.Create('', TEncoding.UTF8);
      FClient.Post(AUrl, LResponseStream);

      LStatusCode := FClient.ResponseStatusCode;
      LStatusText := FClient.ResponseStatusText;
      LBody := LResponseStream.DataString;

      Result := THttpApiResponse.Create(LStatusCode, LStatusText, LBody);
    except
      on E: Exception do
        raise;
    end;
  finally
    FClient.RequestHeaders.Clear;
    if Assigned(LResponseStream) then
      LResponseStream.Free;
    if Assigned(LRequestBodyStream) then
      LRequestBodyStream.Free;
    if Assigned(LFinalHdrs) then
      LFinalHdrs.Free;
    LDefaultHdrs.Free;
  end;
end;

end.
