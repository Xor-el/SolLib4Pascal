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

unit SlpHttpClientBase;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.NetEncoding,
  SlpHttpApiResponse;

type
  THttpApiQueryParams  = TDictionary<string,string>;
  THttpApiHeaderParams = TDictionary<string,string>;
  // Abstract base for compiler-specific HTTP implementations
  THttpClientBase = class abstract

  public

    function GetJson(const AUrl: string;
                     const AQuery: THttpApiQueryParams;
                     const AHeaders: THttpApiHeaderParams): IHttpApiResponse; virtual; abstract;

    function PostJson(const AUrl, AJson: string;
                      const AHeaders: THttpApiHeaderParams): IHttpApiResponse; virtual; abstract;

    class function UrlEncode(const AStr: string): string; static;
    class function BuildUrlWithQuery(const ABaseUrl: string; const AQuery: THttpApiQueryParams): string; static;
  end;

implementation

{ THttpClientBase }

class function THttpClientBase.UrlEncode(const AStr: string): string;
begin
  Result := TNetEncoding.URL.Encode(AStr);
end;

class function THttpClientBase.BuildUrlWithQuery(const ABaseUrl: string; const AQuery: THttpApiQueryParams): string;
var
  LKey, LSep, LVal: string;
begin
  Result := ABaseUrl;
  if (AQuery = nil) or (AQuery.Count = 0) then Exit;
  if Pos('?', Result) > 0 then LSep := '&' else LSep := '?';
  for LKey in AQuery.Keys do
  begin
    if not AQuery.TryGetValue(LKey, LVal) then
      LVal := '';
    Result := Result + LSep +
      UrlEncode(LKey) + '=' +
      UrlEncode(LVal);
    LSep := '&';
  end;
end;

end.

