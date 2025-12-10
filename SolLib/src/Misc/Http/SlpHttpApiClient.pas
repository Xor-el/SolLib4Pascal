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

unit SlpHttpApiClient;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils,
{$IFDEF FPC}
  SlpHttpClientFPC,
{$ELSE}
  SlpHttpClientDelphi,
{$ENDIF}
  SlpHttpApiResponse,
  SlpHttpClientBase;

type
  /// <summary>Minimal HTTP client abstraction.</summary>
  IHttpApiClient = interface
    ['{D68A5B9B-5B5F-4C6A-93F5-9D32F0E0903A}']
    function GetJson(const AUrl: string): IHttpApiResponse; overload;
    function GetJson(const AUrl: string; const AQuery: THttpApiQueryParams): IHttpApiResponse; overload;
    function GetJson(const AUrl: string; const AQuery: THttpApiQueryParams;
                     const AHeaders: THttpApiHeaderParams): IHttpApiResponse; overload;

    function PostJson(const AUrl, AJson: string): IHttpApiResponse; overload;
    function PostJson(const AUrl, AJson: string;
                      const AHeaders: THttpApiHeaderParams): IHttpApiResponse; overload;
  end;

  /// <summary>
  /// Facade for selecting the right implementation.
  /// </summary>
  THttpApiClient = class(TInterfacedObject, IHttpApiClient)
  private
    FHttpClientImpl: THttpClientBase;
  public
    constructor Create(const AExisting: THttpClientBase = nil);
    destructor Destroy; override;

    function GetJson(const AUrl: string): IHttpApiResponse; overload;
    function GetJson(const AUrl: string; const AQuery: THttpApiQueryParams): IHttpApiResponse; overload;
    function GetJson(const AUrl: string; const AQuery: THttpApiQueryParams;
                     const AHeaders: THttpApiHeaderParams): IHttpApiResponse; overload;

    function PostJson(const AUrl, AJson: string): IHttpApiResponse; overload;
    function PostJson(const AUrl, AJson: string;
                      const AHeaders: THttpApiHeaderParams): IHttpApiResponse; overload;
  end;

implementation

{ THttpApiClient }

constructor THttpApiClient.Create(const AExisting: THttpClientBase);
begin
  inherited Create;
  if Assigned(AExisting) then
    FHttpClientImpl := AExisting
  else
  begin
{$IFDEF FPC}
  FHttpClientImpl := TFPCHttpClientImpl.Create;
{$ELSE}
  FHttpClientImpl := TDelphiHttpClientImpl.Create;
{$ENDIF}
  end;
end;

destructor THttpApiClient.Destroy;
begin
  FHttpClientImpl.Free;
  inherited;
end;

function THttpApiClient.GetJson(const AUrl: string): IHttpApiResponse;
begin
  Result := GetJson(AUrl, nil);
end;

function THttpApiClient.GetJson(const AUrl: string; const AQuery: THttpApiQueryParams): IHttpApiResponse;
begin
  Result := GetJson(AUrl, AQuery, nil);
end;

function THttpApiClient.GetJson(const AUrl: string; const AQuery: THttpApiQueryParams;
  const AHeaders: THttpApiHeaderParams): IHttpApiResponse;
begin
  Result := FHttpClientImpl.GetJson(AUrl, AQuery, AHeaders);
end;

function THttpApiClient.PostJson(const AUrl, AJson: string): IHttpApiResponse;
begin
  Result := PostJson(AUrl, AJson, nil);
end;

function THttpApiClient.PostJson(const AUrl, AJson: string;
  const AHeaders: THttpApiHeaderParams): IHttpApiResponse;
begin
  Result := FHttpClientImpl.PostJson(AUrl, AJson, AHeaders);
end;

end.
