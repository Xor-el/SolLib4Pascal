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

unit SlpWebSocketApiClient;

{$I ..\..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  SlpWebSocketClientBase;

type
  /// <summary>
  /// Minimal WebSocket client abstraction.
  /// Defines the contract for connecting, disconnecting, sending data,
  /// and receiving notifications about connection and message events.
  /// </summary>
  IWebSocketApiClient = interface
    ['{BCCC1E0C-2B53-4144-A7B2-079EE0668D5A}']

    /// <summary>
    /// Returns whether the WebSocket connection is currently active.
    /// </summary>
    function Connected: Boolean;

    /// <summary>
    /// Establishes a connection to the specified WebSocket URL.
    /// </summary>
    /// <param name="AUrl">The target WebSocket URL.</param>
    procedure Connect(const AUrl: string);

    /// <summary>
    /// Closes the WebSocket connection.
    /// </summary>
    procedure Disconnect;

    /// <summary>
    /// Sends a UTF-8 encoded text message to the WebSocket server.
    /// </summary>
    /// <param name="AText">The text message to send.</param>
    procedure Send(const AText: string); overload;

    /// <summary>
    /// Sends a binary message to the WebSocket server.
    /// </summary>
    /// <param name="AData">The binary data to send.</param>
    procedure Send(const AData: TBytes); overload;

    // Property accessors
    function GetOnConnect: TProc;
    procedure SetOnConnect(const Value: TProc);

    function GetOnDisconnect: TProc;
    procedure SetOnDisconnect(const Value: TProc);

    function GetOnReceiveTextMessage: TProc<string>;
    procedure SetOnReceiveTextMessage(const Value: TProc<string>);

    function GetOnReceiveBinaryMessage: TProc<TBytes>;
    procedure SetOnReceiveBinaryMessage(const Value: TProc<TBytes>);

    function GetOnError: TProc<string>;
    procedure SetOnError(const Value: TProc<string>);

    function GetOnException: TProc<Exception>;
    procedure SetOnException(const Value: TProc<Exception>);

    /// <summary>
    /// Invoked when the connection is successfully established.
    /// </summary>
    property OnConnect: TProc read GetOnConnect write SetOnConnect;

    /// <summary>
    /// Invoked when the connection is terminated.
    /// </summary>
    property OnDisconnect: TProc read GetOnDisconnect write SetOnDisconnect;

    /// <summary>
    /// Invoked when a text message is received from the server.
    /// </summary>
    property OnReceiveTextMessage: TProc<string> read GetOnReceiveTextMessage write SetOnReceiveTextMessage;

    /// <summary>
    /// Invoked when a binary message is received from the server.
    /// </summary>
    property OnReceiveBinaryMessage: TProc<TBytes> read GetOnReceiveBinaryMessage write SetOnReceiveBinaryMessage;

    /// <summary>
    /// Invoked when a WebSocket error occurs.
    /// </summary>
    property OnError: TProc<string> read GetOnError write SetOnError;

    /// <summary>
    /// Invoked when an exception is raised inside the WebSocket client.
    /// </summary>
    property OnException: TProc<Exception> read GetOnException write SetOnException;
  end;

  /// <summary>
  /// Default WebSocket API client implementation that wraps a low-level WebSocket client.
  /// </summary>
  TWebSocketApiClient = class(TInterfacedObject, IWebSocketApiClient)
  private
    FWebSocketClientImpl: TWebSocketClientBaseImpl;

    FOnConnect: TProc;
    FOnDisconnect: TProc;
    FOnReceiveTextMessage: TProc<string>;
    FOnReceiveBinaryMessage: TProc<TBytes>;
    FOnError: TProc<string>;
    FOnException: TProc<Exception>;

    procedure SetupCallbacks;

    procedure OnConnectImpl;
    procedure OnDisconnectImpl;
    procedure OnReceiveTextMessageImpl(const AData: string);
    procedure OnReceiveBinaryMessageImpl(const AData: TBytes);
    procedure OnErrorImpl(const AError: string);
    procedure OnExceptionImpl(const AException: Exception);

    // Interface property accessors
    function GetOnConnect: TProc;
    procedure SetOnConnect(const Value: TProc);

    function GetOnDisconnect: TProc;
    procedure SetOnDisconnect(const Value: TProc);

    function GetOnReceiveTextMessage: TProc<string>;
    procedure SetOnReceiveTextMessage(const Value: TProc<string>);

    function GetOnReceiveBinaryMessage: TProc<TBytes>;
    procedure SetOnReceiveBinaryMessage(const Value: TProc<TBytes>);

    function GetOnError: TProc<string>;
    procedure SetOnError(const Value: TProc<string>);

    function GetOnException: TProc<Exception>;
    procedure SetOnException(const Value: TProc<Exception>);

    function Connected: Boolean;

    procedure Connect(const AUrl: string);
    procedure Disconnect;

    procedure Send(const AData: string); overload;
    procedure Send(const AData: TBytes); overload;
  public
    constructor Create(const AExisting: TWebSocketClientBaseImpl);
    destructor Destroy; override;
  end;

implementation

{ TWebSocketApiClient }

procedure TWebSocketApiClient.SetupCallbacks;
var
  LCallbacks: TWebSocketClientCallbacks;
begin
  LCallbacks.OnConnect :=
    procedure
    begin
      OnConnectImpl;
    end;

  LCallbacks.OnDisconnect :=
    procedure
    begin
      OnDisconnectImpl;
    end;

  LCallbacks.OnReceiveTextMessage :=
    procedure(AData: string)
    begin
      OnReceiveTextMessageImpl(AData);
    end;

  LCallbacks.OnReceiveBinaryMessage :=
    procedure(AData: TBytes)
    begin
      OnReceiveBinaryMessageImpl(AData);
    end;

  LCallbacks.OnError :=
    procedure(AError: string)
    begin
      OnErrorImpl(AError);
    end;

  LCallbacks.OnException :=
    procedure(AException: Exception)
    begin
      OnExceptionImpl(AException);
    end;

  FWebSocketClientImpl.Callbacks := LCallbacks;
end;

constructor TWebSocketApiClient.Create(const AExisting: TWebSocketClientBaseImpl);
begin
  inherited Create;

  if not Assigned(AExisting) then
    raise EArgumentNilException.Create('AExisting cannot be nil');

  FWebSocketClientImpl := AExisting;
  SetupCallbacks;
end;

destructor TWebSocketApiClient.Destroy;
begin
  if Assigned(FWebSocketClientImpl) then
  begin
    FWebSocketClientImpl.ClearCallbacks;
    FWebSocketClientImpl.Free;
  end;

  inherited;
end;

function TWebSocketApiClient.Connected: Boolean;
begin
  Result := FWebSocketClientImpl.Connected;
end;

procedure TWebSocketApiClient.Connect(const AUrl: string);
begin
  FWebSocketClientImpl.Connect(AUrl);
end;

procedure TWebSocketApiClient.Disconnect;
begin
  FWebSocketClientImpl.Disconnect;
end;

procedure TWebSocketApiClient.Send(const AData: string);
begin
  FWebSocketClientImpl.Send(AData);
end;

procedure TWebSocketApiClient.Send(const AData: TBytes);
begin
  FWebSocketClientImpl.Send(AData);
end;

procedure TWebSocketApiClient.OnConnectImpl;
begin
  if Assigned(FOnConnect) then FOnConnect();
end;

procedure TWebSocketApiClient.OnDisconnectImpl;
begin
  if Assigned(FOnDisconnect) then FOnDisconnect();
end;

procedure TWebSocketApiClient.OnReceiveTextMessageImpl(const AData: string);
begin
  if Assigned(FOnReceiveTextMessage) then FOnReceiveTextMessage(AData);
end;

procedure TWebSocketApiClient.OnReceiveBinaryMessageImpl(const AData: TBytes);
begin
  if Assigned(FOnReceiveBinaryMessage) then FOnReceiveBinaryMessage(AData);
end;

procedure TWebSocketApiClient.OnErrorImpl(const AError: string);
begin
  if Assigned(FOnError) then FOnError(AError);
end;

procedure TWebSocketApiClient.OnExceptionImpl(const AException: Exception);
begin
  if Assigned(FOnException) then FOnException(AException);
end;

// === Interface Property Accessors ===

function TWebSocketApiClient.GetOnConnect: TProc;
begin
  Result := FOnConnect;
end;

procedure TWebSocketApiClient.SetOnConnect(const Value: TProc);
begin
  FOnConnect := Value;
end;

function TWebSocketApiClient.GetOnDisconnect: TProc;
begin
  Result := FOnDisconnect;
end;

procedure TWebSocketApiClient.SetOnDisconnect(const Value: TProc);
begin
  FOnDisconnect := Value;
end;

function TWebSocketApiClient.GetOnReceiveTextMessage: TProc<string>;
begin
  Result := FOnReceiveTextMessage;
end;

procedure TWebSocketApiClient.SetOnReceiveTextMessage(const Value: TProc<string>);
begin
  FOnReceiveTextMessage := Value;
end;

function TWebSocketApiClient.GetOnReceiveBinaryMessage: TProc<TBytes>;
begin
  Result := FOnReceiveBinaryMessage;
end;

procedure TWebSocketApiClient.SetOnReceiveBinaryMessage(const Value: TProc<TBytes>);
begin
  FOnReceiveBinaryMessage := Value;
end;

function TWebSocketApiClient.GetOnError: TProc<string>;
begin
  Result := FOnError;
end;

procedure TWebSocketApiClient.SetOnError(const Value: TProc<string>);
begin
  FOnError := Value;
end;

function TWebSocketApiClient.GetOnException: TProc<Exception>;
begin
  Result := FOnException;
end;

procedure TWebSocketApiClient.SetOnException(const Value: TProc<Exception>);
begin
  FOnException := Value;
end;

end.

