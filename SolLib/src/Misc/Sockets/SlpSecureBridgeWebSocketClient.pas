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

unit SlpSecureBridgeWebSocketClient;

{$I ../../Include/SolLib.inc}

interface

uses
  SysUtils,
  SlpLogger,
  SlpWebSocketClientBase,
  ScUtils,
  ScWebSocketClient;

type
  /// <summary>
  /// SecureBridge (Devart) TScWebSocketClient-based implementation of TWebSocketClientBase.
  /// </summary>
  TSecureBridgeWebSocketClientImpl = class(TWebSocketClientBase)
  private
    FClient: TScWebSocketClient;
    FLogger: ILogger;

    // Fragment reassembly for messages split across frames
    FFragBuf: TBytes;
    FFragType: TScWebSocketMessageType;
    FFragActive: Boolean;

    procedure HandleAfterConnect(ASender: TObject);
    procedure HandleAfterDisconnect(ASender: TObject);
    procedure HandleConnectFail(ASender: TObject);
    procedure HandleAsyncError(ASender: TObject; AException: Exception);
    procedure HandleMessage(ASender: TObject; const AData: TBytes;
                            AMessageType: TScWebSocketMessageType; AEndOfMessage: Boolean);
    procedure HandleControlMessage(ASender: TObject; AControlMessageType: TScWebSocketControlMessageType);

    procedure DeliverCompletedText(const AData: TBytes);
    procedure DeliverCompletedBinary(const AData: TBytes);
    procedure AppendFragment(const AData: TBytes; AMessageType: TScWebSocketMessageType; AEndOfMessage: Boolean);
    procedure ResetFragment;
  public
    constructor Create(const AExisting: TScWebSocketClient = nil; const ALogger: ILogger = nil);
    destructor Destroy; override;

    function Connected: Boolean; override;

    procedure Connect(const AUrl: string); override;
    procedure Disconnect; override;

    procedure Send(const AData: string); overload; override;
    procedure Send(const AData: TBytes); overload; override;

    /// <summary>Optional: Send a WebSocket ping if supported by your version.</summary>
    procedure Ping;
  end;

implementation

{ TSecureBridgeWebSocketClientImpl }

constructor TSecureBridgeWebSocketClientImpl.Create(const AExisting: TScWebSocketClient; const ALogger: ILogger);
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
    // Create and configure our own client.
    FClient := TScWebSocketClient.Create(nil);

    FClient.EventsCallMode := ecDirectly;

    // HeartBeat: keepalive pings
    FClient.HeartBeatOptions.Enabled := True;   // keepalive on
    FClient.HeartBeatOptions.Interval := 15;     // seconds between pings
    FClient.HeartBeatOptions.Timeout := 90;     // seconds to wait for pong before error/close

    // WatchDog: auto-reconnect on unexpected disconnects
    FClient.WatchDogOptions.Enabled := True;    // auto reconnect
    FClient.WatchDogOptions.Interval := 5;       // seconds between attempts
    FClient.WatchDogOptions.Attempts := -1;      // unlimited attempts
  end;

  // Wire events:
  //  - If caller already set a callback, keep theirs.
  //  - If it's nil, assign ours so we can surface events via Callbacks.
  if not Assigned(FClient.AfterConnect) then
    FClient.AfterConnect := HandleAfterConnect;
  if not Assigned(FClient.AfterDisconnect) then
    FClient.AfterDisconnect := HandleAfterDisconnect;
  if not Assigned(FClient.OnConnectFail) then
    FClient.OnConnectFail := HandleConnectFail;
  if not Assigned(FClient.OnAsyncError) then
    FClient.OnAsyncError := HandleAsyncError;
  if not Assigned(FClient.OnMessage) then
    FClient.OnMessage := HandleMessage;
  if not Assigned(FClient.OnControlMessage) then
    FClient.OnControlMessage := HandleControlMessage;

  ResetFragment;
end;

destructor TSecureBridgeWebSocketClientImpl.Destroy;
begin
  try
    Disconnect;
  finally
    FClient.Free;
  end;
  inherited;
end;

function TSecureBridgeWebSocketClientImpl.Connected: Boolean;
begin
  Result := (FClient.State = sOpen);
end;

procedure TSecureBridgeWebSocketClientImpl.Connect(const AUrl: string);
begin
  if Connected then
    Exit;

  if Assigned(FLogger) then
    FLogger.LogInformation('WebSocket connecting: {0}', [AUrl]);

  FClient.Connect(AUrl);
end;

procedure TSecureBridgeWebSocketClientImpl.Disconnect;
begin
  if not Connected then
    Exit;

  if Assigned(FLogger) then
    FLogger.LogInformation('WebSocket disconnecting', []);

  // Use Close() to gracefully close
  FClient.Close;
end;

procedure TSecureBridgeWebSocketClientImpl.Send(const AData: string);
begin
  if Assigned(FLogger) then
    FLogger.LogInformation('Sending text frame ({0} chars)', [IntToStr(Length(AData))]);

  FClient.Send(AData);
end;

procedure TSecureBridgeWebSocketClientImpl.Send(const AData: TBytes);
begin
  if Assigned(FLogger) then
    FLogger.LogInformation('Sending binary frame ({0} bytes)', [IntToStr(Length(AData))]);

  FClient.Send(AData, 0, Length(AData), mtBinary, True);
end;

procedure TSecureBridgeWebSocketClientImpl.Ping;
begin
  FClient.Ping;
end;

procedure TSecureBridgeWebSocketClientImpl.HandleAfterConnect(ASender: TObject);
begin
  if Assigned(FLogger) then
    FLogger.LogInformation('Connected', []);

  if Assigned(Callbacks.OnConnect) then
    Callbacks.OnConnect();
end;

procedure TSecureBridgeWebSocketClientImpl.HandleAfterDisconnect(ASender: TObject);
begin
  if Assigned(FLogger) then
    FLogger.LogInformation('Disconnected', []);

  if Assigned(Callbacks.OnDisconnect) then
    Callbacks.OnDisconnect();

  ResetFragment;
end;

procedure TSecureBridgeWebSocketClientImpl.HandleConnectFail(ASender: TObject);
begin
  if Assigned(FLogger) then
    FLogger.LogError('Connection failed', []);

  if Assigned(Callbacks.OnError) then
    Callbacks.OnError('Connection failed');
end;

procedure TSecureBridgeWebSocketClientImpl.HandleAsyncError(ASender: TObject; AException: Exception);
begin
  if Assigned(FLogger) then
    FLogger.LogException(TLogLevel.Error, AException, 'Async error: {0}', [AException.Message]);

  if Assigned(Callbacks.OnException) then
    Callbacks.OnException(AException);
end;

procedure TSecureBridgeWebSocketClientImpl.HandleControlMessage(
  ASender: TObject; AControlMessageType: TScWebSocketControlMessageType);
begin
  // Optional: log ping/pong
  if Assigned(FLogger) then
    case AControlMessageType of
      cmtPing: FLogger.LogInformation('Ping received', []);
      cmtPong: FLogger.LogInformation('Pong received', []);
    end;
end;

procedure TSecureBridgeWebSocketClientImpl.HandleMessage(
  ASender: TObject; const AData: TBytes; AMessageType: TScWebSocketMessageType; AEndOfMessage: Boolean);
begin
  // Library may deliver fragmented messages; buffer until AEndOfMessage=True
  AppendFragment(AData, AMessageType, AEndOfMessage);

  if AEndOfMessage then
  begin
    try
      case AMessageType of
        mtText:   DeliverCompletedText(FFragBuf);
        mtBinary: DeliverCompletedBinary(FFragBuf);
        mtClose:  ; // Close notifications are handled via AfterDisconnect/Close logic
      end;
    finally
      ResetFragment;
    end;
  end;
end;

procedure TSecureBridgeWebSocketClientImpl.AppendFragment(
  const AData: TBytes; AMessageType: TScWebSocketMessageType; AEndOfMessage: Boolean);
var
  LBaseLen, LAddLen: Integer;
begin
  if not FFragActive then
  begin
    // Start a new message
    FFragActive := True;
    FFragType := AMessageType;
    FFragBuf := nil;
  end;

  // If message type changes mid-stream, flush previous (defensive)
  if (FFragType <> AMessageType) and FFragActive then
    ResetFragment;

  LAddLen := Length(AData);
  if LAddLen > 0 then
  begin
    LBaseLen := Length(FFragBuf);
    SetLength(FFragBuf, LBaseLen + LAddLen);
    Move(AData[0], FFragBuf[LBaseLen], LAddLen);
  end;

  if AEndOfMessage then
  begin
    // nothing else here; caller will deliver and reset
  end;
end;

procedure TSecureBridgeWebSocketClientImpl.DeliverCompletedText(const AData: TBytes);
var
  LS: string;
begin
  if Assigned(FLogger) then
    FLogger.LogInformation('Text Data Received', []);

  if not Assigned(Callbacks.OnReceiveTextMessage) then
    Exit;

  // WebSocket text is UTF-8 by spec
  if Length(AData) > 0 then
    LS := TEncoding.UTF8.GetString(AData)
  else
    LS := '';

  Callbacks.OnReceiveTextMessage(LS);
end;

procedure TSecureBridgeWebSocketClientImpl.DeliverCompletedBinary(const AData: TBytes);
begin
  if Assigned(FLogger) then
    FLogger.LogInformation('Binary Data Received', []);

  if not Assigned(Callbacks.OnReceiveBinaryMessage) then
    Exit;

  Callbacks.OnReceiveBinaryMessage(AData);
end;


procedure TSecureBridgeWebSocketClientImpl.ResetFragment;
begin
  FFragBuf := nil;
  FFragActive := False;
  FFragType := mtBinary;
end;

end.

