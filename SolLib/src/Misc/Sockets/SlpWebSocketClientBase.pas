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

unit SlpWebSocketClientBase;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils;

type
  TWebSocketClientCallbacks = record
    OnConnect: TProc;
    OnDisconnect: TProc;
    OnReceiveTextMessage: TProc<string>;
    OnReceiveBinaryMessage: TProc<TBytes>;
    OnError: TProc<string>;
    OnException: TProc<Exception>;
  end;

  // Abstract base for different WebSocket implementations
  TWebSocketClientBase = class abstract
  private
    FCallbacks: TWebSocketClientCallbacks;

  public

    procedure ClearCallbacks;

    function Connected: Boolean; virtual; abstract;

    procedure Connect(const AUrl: string); virtual; abstract;
    procedure Disconnect(); virtual; abstract;

    procedure Send(const AData: string); overload; virtual; abstract;
    procedure Send(const AData: TBytes); overload; virtual; abstract;

    property Callbacks: TWebSocketClientCallbacks read FCallbacks write FCallbacks;
  end;

implementation

{ TWebSocketClientBase }

procedure TWebSocketClientBase.ClearCallbacks;
begin
  FCallbacks.OnConnect := nil;
  FCallbacks.OnDisconnect := nil;
  FCallbacks.OnReceiveTextMessage := nil;
  FCallbacks.OnReceiveBinaryMessage := nil;
  FCallbacks.OnError := nil;
  FCallbacks.OnException := nil;
  FCallbacks := Default(TWebSocketClientCallbacks);
end;

end.

