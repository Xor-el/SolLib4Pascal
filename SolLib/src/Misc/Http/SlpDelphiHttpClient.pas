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

unit SlpDelphiHttpClient;

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

    class function MergeHeaders(const ADefaults, AExtra: THttpApiHeaderParams): TNetHeaders; static;
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
  const ADefaults, AExtra: THttpApiHeaderParams): TNetHeaders;
var
  LTmp: THttpApiHeaderParams;
  LKeys: TArray<string>;
  LI: Integer;
  LKey: string;
begin
  LTmp := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  try
    if ADefaults <> nil then
      for LKey in ADefaults.Keys do
        LTmp.AddOrSetValue(LKey, ADefaults.Items[LKey]);

    if AExtra <> nil then
      for LKey in AExtra.Keys do
        LTmp.AddOrSetValue(LKey, AExtra.Items[LKey]);

    LKeys := LTmp.Keys.ToArray;
    SetLength(Result, Length(LKeys));
    for LI := 0 to High(LKeys) do
    begin
      Result[LI].Name  := LKeys[LI];
      Result[LI].Value := LTmp.Items[LKeys[LI]];
    end;
  finally
    LTmp.Free;
  end;
end;

function TDelphiHttpClientImpl.GetJson(const AUrl: string;
  const AQuery: THttpApiQueryParams; const AHeaders: THttpApiHeaderParams): IHttpApiResponse;
var
  LUrl, LBody, LStatusText: string;
  LResp: IHTTPResponse;
  LStatusCode: Integer;
  LDefaultHdrs: THttpApiHeaderParams;
  LNetHeaders: TNetHeaders;
begin
  LUrl := BuildUrlWithQuery(AUrl, AQuery);

  LDefaultHdrs := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  try
    LDefaultHdrs.Add('Accept', 'application/json');
    LNetHeaders := MergeHeaders(LDefaultHdrs, AHeaders);
  finally
    LDefaultHdrs.Free;
  end;

  try
    LResp := FClient.Get(LUrl, nil, LNetHeaders);
    LBody := LResp.ContentAsString(TEncoding.UTF8);
    LStatusCode := LResp.StatusCode;
    LStatusText := LResp.StatusText;
  except
    on E: Exception do
      raise;
  end;

  Result := THttpApiResponse.Create(LStatusCode, LStatusText, LBody);
end;

function TDelphiHttpClientImpl.PostJson(const AUrl, AJson: string;
  const AHeaders: THttpApiHeaderParams): IHttpApiResponse;
var
  LMS: TMemoryStream;
  LBuffer: TBytes;
  LBody, LStatusText: string;
  LResp: IHTTPResponse;
  LStatusCode: Integer;
  LDefaultHdrs: THttpApiHeaderParams;
  LNetHeaders: TNetHeaders;
begin
  LDefaultHdrs := THttpApiHeaderParams.Create(TStringComparerFactory.OrdinalIgnoreCase);
  try
    LDefaultHdrs.Add('Content-Type', 'application/json');
    LNetHeaders := MergeHeaders(LDefaultHdrs, AHeaders);
  finally
    LDefaultHdrs.Free;
  end;

  LMS := TMemoryStream.Create;
  try
    if AJson <> '' then
    begin
      LBuffer := TEncoding.UTF8.GetBytes(AJson);
      if Length(LBuffer) > 0 then LMS.WriteBuffer(LBuffer, Length(LBuffer));
    end;
    LMS.Position := 0;

    try
      LResp := FClient.Post(AUrl, LMS, nil, LNetHeaders);
      LBody := LResp.ContentAsString(TEncoding.UTF8);
      LStatusCode := LResp.StatusCode;
      LStatusText := LResp.StatusText;
    except
      on E: Exception do
        raise;
    end;

    Result := THttpApiResponse.Create(LStatusCode, LStatusText, LBody);
  finally
    LMS.Free;
  end;
end;

end.
