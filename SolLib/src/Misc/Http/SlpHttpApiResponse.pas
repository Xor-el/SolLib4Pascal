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

unit SlpHttpApiResponse;

{$I ../../Include/SolLib.inc}

interface

uses
  System.Math;

type
  /// <summary>
  /// Minimal HTTP response abstraction usable by RPC layer without tying to a specific HTTP stack.
  /// </summary>
  IHttpApiResponse = interface
    ['{E9A4E7E1-8F5F-4C07-B28A-0A4B0EAB5C6A}']
    function GetStatusCode: Integer;
    function GetStatusText: string;
    function GetResponseBody: string;
    function GetIsSuccessStatusCode: Boolean;

    property StatusCode: Integer read GetStatusCode;
    property StatusText: string read GetStatusText;
    property ResponseBody: string read GetResponseBody;
    property IsSuccessStatusCode: Boolean read GetIsSuccessStatusCode;
  end;

type
  THttpApiResponse = class(TInterfacedObject, IHttpApiResponse)
  private
    FStatusCode: Integer;
    FStatusText, FResponseBody: string;

    function GetStatusCode: Integer;
    function GetStatusText: string;
    function GetResponseBody: string;
    function GetIsSuccessStatusCode: Boolean;
  public
    constructor Create(AStatusCode: Integer; const AStatusText: string;
      const ABody: String);
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

function THttpApiResponse.GetStatusCode: Integer;
begin
  Result := FStatusCode;
end;

function THttpApiResponse.GetStatusText: string;
begin
  Result := FStatusText;
end;

function THttpApiResponse.GetResponseBody: string;
begin
  Result := FResponseBody;
end;

function THttpApiResponse.GetIsSuccessStatusCode: Boolean;
begin
  Result := InRange(FStatusCode, 200, 299);
end;

end.
