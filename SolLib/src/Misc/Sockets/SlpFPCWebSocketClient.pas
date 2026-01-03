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

unit SlpFPCWebSocketClient;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  URIParser,
  opensslsockets,
  fpwebsocketclient,
  fpwebsocket,
  SlpLogger,
  SlpWebSocketClientBase;

type
  /// <summary>
  /// Record containing parsed WebSocket URL components.
  /// </summary>
  TWebSocketUrlInfo = record
    Host: string;
    Port: Integer;
    Resource: string;
    UseSSL: Boolean;
  end;

  /// <summary>
  /// FPC fcl-web TWebsocketClient-based implementation of TWebSocketClientBase.
  /// </summary>
  TFPCWebSocketClientImpl = class(TWebSocketClientBase)
  private
    FClient: TWebsocketClient;
    FLogger: ILogger;

  strict protected
    /// <summary>
    /// Parses a WebSocket URL (ws:// or wss://) into its components.
    /// </summary>
    function ParseWebSocketUrl(const AUrl: string): TWebSocketUrlInfo; virtual;

    /// <summary>
    /// Triggered when the WebSocket connection is successfully established.
    /// </summary>
    procedure HandleConnect(Sender: TObject);

    /// <summary>
    /// Triggered when the WebSocket connection is closed or disconnected.
    /// </summary>
    procedure HandleDisconnect(Sender: TObject);

    /// <summary>
    /// Triggered when a message (text or binary) is received from the WebSocket connection.
    /// </summary>
    procedure HandleMessageReceived(Sender: TObject; const AMessage: TWSMessage);

    /// <summary>
    /// Triggered when a control frame (ping/pong/close) is received.
    /// </summary>
    procedure HandleControl(Sender: TObject; AType: TFrameType; const AData: TBytes);

  public
    constructor Create(const AExisting: TWebsocketClient = nil; const ALogger: ILogger = nil);
    destructor Destroy; override;

    function Connected: Boolean; override;

    procedure Connect(const AUrl: string); override;
    procedure Disconnect(); override;

    procedure Send(const AData: string); overload; override;
    procedure Send(const AData: TBytes); overload; override;
  end;

implementation

{ TFPCWebSocketClientImpl }

constructor TFPCWebSocketClientImpl.Create(const AExisting: TWebsocketClient; const ALogger: ILogger);
var
  LMessagePump: TWSThreadMessagePump;
begin
  inherited Create;

  FLogger := ALogger;

  if Assigned(AExisting) then
  begin
    // Use caller-provided client instance.
    FClient := AExisting;
  end
  else
  begin
    // Create message pump for async message handling
    LMessagePump := TWSThreadMessagePump.Create(nil);
    LMessagePump.Interval := 50; // Check every 50ms

    // Create and fully configure our own client
    FClient := TWebsocketClient.Create(nil);
    FClient.MessagePump := LMessagePump;
    FClient.ConnectTimeout := 10000; // 10 second connect timeout
    FClient.CheckTimeOut := 100;     // 100ms check timeout
  end;

  // Wire events:
  //  - If caller already set a callback, keep theirs.
  //  - If it's nil, assign ours so we can surface events via Callbacks.
  if not Assigned(FClient.OnConnect) then
    FClient.OnConnect := HandleConnect;
  if not Assigned(FClient.OnDisconnect) then
    FClient.OnDisconnect := HandleDisconnect;
  if not Assigned(FClient.OnMessageReceived) then
    FClient.OnMessageReceived := HandleMessageReceived;
  if not Assigned(FClient.OnControl) then
    FClient.OnControl := HandleControl;
end;

destructor TFPCWebSocketClientImpl.Destroy;
begin
  try
    Disconnect;
  finally
    if Assigned(FClient.MessagePump) then
      FClient.MessagePump.Free;
    FClient.Free;
  end;
  inherited;
end;

function TFPCWebSocketClientImpl.ParseWebSocketUrl(const AUrl: string): TWebSocketUrlInfo;
var
  URI: TURI;
begin
  URI := ParseURI(AUrl);

  Result.Host := URI.Host;
  Result.Resource := URI.Path + URI.Document;
  if Result.Resource = '' then
    Result.Resource := '/';
  if URI.Params <> '' then
    Result.Resource := Result.Resource + '?' + URI.Params;

  // Determine SSL based on scheme
  Result.UseSSL := SameText(URI.Protocol, 'wss');

  // Determine port
  if URI.Port <> 0 then
    Result.Port := URI.Port
  else if Result.UseSSL then
    Result.Port := 443
  else
    Result.Port := 80;
end;

function TFPCWebSocketClientImpl.Connected: Boolean;
begin
  Result := FClient.Active;
end;

procedure TFPCWebSocketClientImpl.Connect(const AUrl: string);
var
  LUrlInfo: TWebSocketUrlInfo;
begin
  if Connected then
    Exit;

  if Assigned(FLogger) then
    FLogger.LogInformation('WebSocket connecting: {0}', [AUrl]);

  LUrlInfo := ParseWebSocketUrl(AUrl);

  FClient.HostName := LUrlInfo.Host;
  FClient.Port := LUrlInfo.Port;
  FClient.Resource := LUrlInfo.Resource;
  FClient.UseSSL := LUrlInfo.UseSSL;

  // Start message pump for async receiving (only if assigned)
  if Assigned(FClient.MessagePump) then
    FClient.MessagePump.Execute;

  // Connect
  FClient.Connect;
end;

procedure TFPCWebSocketClientImpl.Disconnect;
begin
  if not Connected then
    Exit;

  if Assigned(FLogger) then
    FLogger.LogInformation('WebSocket disconnecting', []);

  // Stop message pump first to avoid callback issues (only if assigned)
  if Assigned(FClient.MessagePump) then
  begin
    try
      FClient.MessagePump.Terminate;
    except
      // Ignore termination errors
    end;
  end;

  FClient.Disconnect;
end;

procedure TFPCWebSocketClientImpl.Send(const AData: string);
begin
  if Assigned(FLogger) then
    FLogger.LogInformation('Sending text frame ({0} chars)', [IntToStr(Length(AData))]);

  FClient.SendMessage(AData);
end;

procedure TFPCWebSocketClientImpl.Send(const AData: TBytes);
begin
  if Assigned(FLogger) then
    FLogger.LogInformation('Sending binary frame ({0} bytes)', [IntToStr(Length(AData))]);

  FClient.SendData(AData);
end;

procedure TFPCWebSocketClientImpl.HandleConnect(Sender: TObject);
begin
  if Assigned(FLogger) then
    FLogger.LogInformation('Connected', []);

  if not Assigned(Callbacks.OnConnect) then
    Exit;

  Callbacks.OnConnect();
end;

procedure TFPCWebSocketClientImpl.HandleDisconnect(Sender: TObject);
begin
  if Assigned(FLogger) then
    FLogger.LogInformation('Disconnected', []);

  if not Assigned(Callbacks.OnDisconnect) then
    Exit;

  Callbacks.OnDisconnect();
end;

procedure TFPCWebSocketClientImpl.HandleMessageReceived(Sender: TObject;
  const AMessage: TWSMessage);
begin
  if AMessage.IsText then
  begin
    if Assigned(FLogger) then
      FLogger.LogInformation('Text Data Received', []);

    if Assigned(Callbacks.OnReceiveTextMessage) then
      Callbacks.OnReceiveTextMessage(AMessage.AsString);
  end
  else
  begin
    if Assigned(FLogger) then
      FLogger.LogInformation('Binary Data Received', []);

    if Assigned(Callbacks.OnReceiveBinaryMessage) then
      Callbacks.OnReceiveBinaryMessage(AMessage.PayLoad);
  end;
end;

procedure TFPCWebSocketClientImpl.HandleControl(Sender: TObject;
  AType: TFrameType; const AData: TBytes);
begin
  case AType of
    ftPing:
      begin
        if Assigned(FLogger) then
          FLogger.LogInformation('Ping received', []);
      end;

    ftPong:
      begin
        if Assigned(FLogger) then
          FLogger.LogInformation('Pong received', []);
      end;

    ftClose:
      begin
        if Assigned(FLogger) then
          FLogger.LogInformation('Close frame received', []);
      end;
  end;
end;

end.
