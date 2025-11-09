{ * ************************************************************************ * }
{ *                              SolLib Library                              * }
{ *                  Copyright (c) 2025 Ugochukwu Mmaduekwe                  * }
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

unit SlpHttpApiResponse;

{$I ..\..\Include\SolLib.inc}

interface

type
  /// <summary>
  /// Minimal HTTP response abstraction usable by RPC layer without tying to a specific HTTP stack.
  /// </summary>
  IHttpApiResponse = interface
    ['{E9A4E7E1-8F5F-4C07-B28A-0A4B0EAB5C6A}']
    function StatusCode: Integer;
    function StatusText: string;
    function ResponseBody: string;
  end;

type
  THttpApiResponse = class(TInterfacedObject, IHttpApiResponse)
  private
    FStatusCode: Integer;
    FStatusText, FResponseBody: string;
  public
    constructor Create(AStatusCode: Integer; const AStatusText: string;
      const ABody: String);
    function StatusCode: Integer;
    function StatusText: string;
    function ResponseBody: string;
  end;

implementation

{ THttpApiResponse }

constructor THttpApiResponse.Create(AStatusCode: Integer; const AStatusText: string; const ABody: String);
begin
  inherited Create;
  FStatusCode := AStatusCode;
  FStatusText := AStatusText;
  FResponseBody := ABody;
end;

function THttpApiResponse.StatusCode: Integer;
begin
  Result := FStatusCode;
end;

function THttpApiResponse.StatusText: string;
begin
  Result := FStatusText;
end;

function THttpApiResponse.ResponseBody: string;
begin
  Result := FResponseBody;
end;


end.
