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

unit SlpSgcWebSocketClient;

{$I ../../Include/SolLib.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  SlpLogger,
  SlpWebSocketClientBase,
  sgcWebSocket,
  sgcWebSocket_Classes,
  sgcWebSocket_Types;

type
  /// <summary>
  /// Sgc (eSeGeCe) TsgcWebSocketClient-based implementation of TWebSocketClientBaseImpl.
  /// </summary>
  TSgcWebSocketClientImpl = class(TWebSocketClientBaseImpl)
  private
    FClient: TsgcWebSocketClient;
    FLogger: ILogger;
  strict protected

    /// <summary>
    /// Triggered when the WebSocket connection is successfully established.
    /// </summary>
    /// <param name="AConnection">The WebSocket connection object.</param>
    procedure DoConnect(AConnection: TsgcWsConnection);

    /// <summary>
    /// Triggered when the WebSocket connection is closed or disconnected.
    /// </summary>
    /// <param name="AConnection">The WebSocket connection object.</param>
    /// <param name="ACode">The WebSocket close status code.</param>
    procedure DoDisconnect(AConnection: TsgcWsConnection; ACode: Integer);

    /// <summary>
    /// Triggered when a text message is received from the WebSocket connection.
    /// </summary>
    /// <param name="AConnection">The WebSocket connection object.</param>
    /// <param name="AData">The received text message.</param>
    procedure DoMessage(AConnection: TsgcWsConnection; const AData: string);

    /// <summary>
    /// Triggered when binary data is received from the WebSocket connection.
    /// Converts the received stream into bytes and invokes the corresponding callback.
    /// </summary>
    /// <param name="AConnection">The WebSocket connection object.</param>
    /// <param name="AData">The received binary data as a memory stream.</param>
    procedure DoBinary(AConnection: TsgcWsConnection; const AData: TMemoryStream);

    /// <summary>
    /// Triggered when an error message is reported from the WebSocket client.
    /// </summary>
    /// <param name="AConnection">The WebSocket connection object.</param>
    /// <param name="AError">The error message text.</param>
    procedure DoError(AConnection: TsgcWsConnection; const AError: string);

    /// <summary>
    /// Triggered when an exception occurs within the WebSocket client context.
    /// </summary>
    /// <param name="AConnection">The WebSocket connection object.</param>
    /// <param name="AException">The exception object representing the error.</param>
    procedure DoException(AConnection: TsgcWsConnection; AException: Exception);

  public
    constructor Create(const AExisting: TsgcWebSocketClient = nil; const ALogger: ILogger = nil);
    destructor Destroy; override;

    function Connected: Boolean; override;

    procedure Connect(const AUrl: string); override;
    procedure Disconnect(); override;

    procedure Send(const AData: string); overload; override;
    procedure Send(const AData: TBytes); overload; override;
  end;

implementation

{ TSgcWebSocketClientImpl }

constructor TSgcWebSocketClientImpl.Create(const AExisting: TsgcWebSocketClient; const ALogger: ILogger);
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
    // Create and fully configure our own client.
    FClient := TsgcWebSocketClient.Create(nil);

    FClient.NotifyEvents := neNoSync;
    FClient.Options.FragmentedMessages := frgOnlyBuffer;
    FClient.Options.CleanDisconnect := True;

    // HeartBeat: keepalive pings
    FClient.HeartBeat.Enabled  := True;   // keepalive on
    FClient.HeartBeat.Interval := 15;     // seconds between pings
    FClient.HeartBeat.Timeout  := 90;     // seconds to wait for pong before error/close

    // WatchDog: auto-reconnect on unexpected disconnects
    FClient.WatchDog.Enabled  := True;    // auto reconnect
    FClient.WatchDog.Interval := 5;       // seconds between attempts
    FClient.WatchDog.Attempts := 0;       // unlimited attempts
  end;

  // Wire events:
  //  - If caller already set a callback, keep theirs.
  //  - If it's nil, assign ours so we can surface events via Callbacks.
  if not Assigned(FClient.OnConnect) then
    FClient.OnConnect := DoConnect;
  if not Assigned(FClient.OnDisconnect) then
    FClient.OnDisconnect := DoDisconnect;
  if not Assigned(FClient.OnMessage) then
    FClient.OnMessage := DoMessage;
  if not Assigned(FClient.OnBinary) then
    FClient.OnBinary := DoBinary;
  if not Assigned(FClient.OnError) then
    FClient.OnError := DoError;
  if not Assigned(FClient.OnException) then
    FClient.OnException := DoException;
end;

destructor TSgcWebSocketClientImpl.Destroy;
begin
  try
    Disconnect;
  finally
    FClient.Free;
  end;
  inherited;
end;

function TSgcWebSocketClientImpl.Connected: Boolean;
begin
  Result := FClient.Active;
end;

procedure TSgcWebSocketClientImpl.Connect(const AUrl: string);
begin
  if Connected then
    Exit;

  if Assigned(FLogger) then
    FLogger.LogInformation('WebSocket connecting: {0}', [AUrl]);

  FClient.URL := AUrl;
  FClient.Connect();
end;

procedure TSgcWebSocketClientImpl.Disconnect;
begin
  if not Connected then
    Exit;

  if Assigned(FLogger) then
    FLogger.LogInformation('WebSocket disconnecting', []);

  FClient.Disconnect();
end;

procedure TSgcWebSocketClientImpl.Send(const AData: string);
begin
  if Assigned(FLogger) then
    FLogger.LogInformation('Sending text frame ({0} chars)', [IntToStr(Length(AData))]);

  FClient.WriteData(AData);
end;

procedure TSgcWebSocketClientImpl.Send(const AData: TBytes);
var
  LStream: TMemoryStream;
begin
  if Assigned(FLogger) then
    FLogger.LogInformation('Sending binary frame ({0} bytes)', [IntToStr(Length(AData))]);

  LStream := TMemoryStream.Create;
  try
    if Length(AData) > 0 then
      LStream.WriteBuffer(AData[0], Length(AData));

    LStream.Position := 0;
    FClient.WriteData(LStream);
  finally
    LStream.Free;
  end;
end;

procedure TSgcWebSocketClientImpl.DoConnect(AConnection: TsgcWsConnection);
begin
  if Assigned(FLogger) then
   FLogger.LogInformation('Connected', []);

  if not Assigned(Callbacks.OnConnect) then
    Exit;

  Callbacks.OnConnect();
end;

procedure TSgcWebSocketClientImpl.DoDisconnect(AConnection: TsgcWsConnection;
  ACode: Integer);
begin
  if Assigned(FLogger) then
   FLogger.LogInformation('Disconnected - Code: {0}', [IntToStr(ACode)]);

  if not Assigned(Callbacks.OnDisconnect) then
    Exit;

  Callbacks.OnDisconnect();
end;

procedure TSgcWebSocketClientImpl.DoMessage(AConnection: TsgcWsConnection;
  const AData: string);
begin
  if Assigned(FLogger) then
   FLogger.LogInformation('Text Data Received', []);

  if not Assigned(Callbacks.OnReceiveTextMessage) then
    Exit;

  Callbacks.OnReceiveTextMessage(AData);
end;

procedure TSgcWebSocketClientImpl.DoBinary(AConnection: TsgcWsConnection;
  const AData: TMemoryStream);

  function StreamToBytes(const S: TStream): TBytes;
  var
    L: Integer;
  begin
    L := S.Size;
    if L <= 0 then
      Exit(nil);
    SetLength(Result, L);
    S.Position := 0;
    S.ReadBuffer(Result[0], L);
  end;

var
  Bytes: TBytes;
begin
  if Assigned(FLogger) then
   FLogger.LogInformation('Binary Data Received', []);

  if not Assigned(Callbacks.OnReceiveBinaryMessage) then
    Exit;

  Bytes := StreamToBytes(AData);
  Callbacks.OnReceiveBinaryMessage(Bytes);
end;

procedure TSgcWebSocketClientImpl.DoError(AConnection: TsgcWsConnection;
  const AError: string);
begin
  if Assigned(FLogger) then
   FLogger.LogError('An Error Occurred: {0}', [AError]);

  if not Assigned(Callbacks.OnError) then
    Exit;

  Callbacks.OnError(AError);
end;

procedure TSgcWebSocketClientImpl.DoException(AConnection: TsgcWsConnection;
  AException: Exception);
begin
  if Assigned(FLogger) then
   FLogger.LogException(TLogLevel.Fatal, AException, 'An Exception Occurred: {0}', [AException.Message]);

  if not Assigned(Callbacks.OnException) then
    Exit;

  Callbacks.OnException(AException);
end;

end.
