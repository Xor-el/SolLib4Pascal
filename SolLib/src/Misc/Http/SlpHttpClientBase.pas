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

    class function UrlEncode(const S: string): string; static;
    class function BuildUrlWithQuery(const BaseUrl: string; const Q: THttpApiQueryParams): string; static;
  end;

implementation

{ THttpClientBase }

class function THttpClientBase.UrlEncode(const S: string): string;
begin
  Result := TNetEncoding.URL.Encode(S);
end;

class function THttpClientBase.BuildUrlWithQuery(const BaseUrl: string; const Q: THttpApiQueryParams): string;
var
  Key, Sep, Val: string;
begin
  Result := BaseUrl;
  if (Q = nil) or (Q.Count = 0) then Exit;
  if Pos('?', Result) > 0 then Sep := '&' else Sep := '?';
  for Key in Q.Keys do
  begin
    if not Q.TryGetValue(Key, Val) then
      Val := '';
    Result := Result + Sep +
      UrlEncode(Key) + '=' +
      UrlEncode(Val);
    Sep := '&';
  end;
end;

end.

