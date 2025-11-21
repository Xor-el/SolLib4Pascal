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

unit SlpStreamingRpcClient;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections,
  System.JSON.Serializers,
{$IFDEF FPC}
  URIParser,
{$ELSE}
  System.Net.URLClient,
{$ENDIF}
  SlpJsonKit,
  SlpEncodingConverter,
  SlpJsonStringEnumConverter,
  SlpLogger,
  SlpWebSocketApiClient,
  SlpConnectionStatistics;

type
  /// <summary>
  /// Base streaming RPC client class that abstracts the WebSocket handling.
  /// </summary>
  /// <remarks>
  /// Subclasses must implement <see cref="HandleNewMessage" /> and <see cref="CleanupSubscriptions" />.
  /// </remarks>
  TStreamingRpcClient = class abstract(TInterfacedObject)
  private
    FLock: TCriticalSection;
    FNodeAddress: TURI;
    FConnectionStats: IConnectionStatistics;

    procedure WireClientCallbacks;

  protected

    FLogger: ILogger;
    FClient: IWebSocketApiClient;

    /// <summary>
    /// The internal constructor that setups the client.
    /// </summary>
    /// <param name="AUrl">The url of the streaming RPC server.</param>
    /// <param name="AClient">The possible websocket instance.</param>
    /// <param name="ALogger">The possible logger instance.</param>
    constructor Create(const AUrl: string; const AClient: IWebSocketApiClient; const ALogger: ILogger);

    function GetNodeAddress: TURI;

    /// <summary>
    /// Override to customize the converter list.
    /// </summary>
    function GetConverters: TList<TJsonConverter>; virtual;

    /// <summary>
    /// Override to customize the serializer
    /// </summary>
    function BuildSerializer: TJsonSerializer; virtual;

    function GetStatistics: IConnectionStatistics;
    /// <summary>
    /// Handles a new message payload.
    /// </summary>
    /// <param name="AMessagePayload">The message payload.</param>
    procedure HandleNewMessage(const AMessagePayload: TBytes); virtual; abstract;

    /// <summary>
    /// Clean up subscription objects after disconnection.
    /// </summary>
    procedure CleanupSubscriptions; virtual; abstract;
  public

    destructor Destroy; override;

    property NodeAddress: TURI read GetNodeAddress;

    /// <summary>
    /// Statistics of the current connection.
    /// </summary>
    property Statistics: IConnectionStatistics read GetStatistics;

    /// <summary>
    /// Initializes the websocket connection.
    /// </summary>
    procedure Connect;

    /// <summary>
    /// Disconnects/Closes the websocket connection.
    /// </summary>
    procedure Disconnect;

  end;

implementation

{ TStreamingRpcClient }

procedure TStreamingRpcClient.WireClientCallbacks;
begin

  FClient.OnReceiveTextMessage :=
    procedure(AData: string)
    var
      LPayload: TBytes;
    begin
      if Assigned(FLogger) then
        FLogger.LogInformation('Text Received: {0}', [AData]);

      LPayload := TEncoding.UTF8.GetBytes(AData);
      try
        FConnectionStats.AddReceived(Length(LPayload));
        HandleNewMessage(LPayload);
      except
        on E: Exception do
          if Assigned(FLogger) then
            FLogger.LogError('HandleNewMessage(text) failed: {0}', [E.Message]);
      end;
    end;

  FClient.OnReceiveBinaryMessage :=
    procedure(AData: TBytes)
    var
      LCopyB: TBytes;
    begin
      LCopyB := System.Copy(AData, 0, Length(AData));
      try
        FConnectionStats.AddReceived(Length(LCopyB));
        HandleNewMessage(LCopyB);
      except
        on E: Exception do
          if Assigned(FLogger) then
            FLogger.LogError('HandleNewMessage(binary) failed: {0}', [E.Message]);
      end;
    end;

  FClient.OnConnect :=
    procedure
    begin
      if Assigned(FLogger) then
        FLogger.LogInformation('WebSocket connected: {0}', [FNodeAddress.ToString]);
    end;

  FClient.OnDisconnect :=
    procedure
    begin
      if Assigned(FLogger) then
        FLogger.LogInformation('WebSocket disconnected: {0}', [FNodeAddress.ToString]);
    end;

  FClient.OnError :=
    procedure(AError: string)
    begin
      if Assigned(FLogger) then
        FLogger.LogError('WebSocket error: {0}', [AError]);
    end;

  FClient.OnException :=
    procedure(AException: Exception)
    begin
      if Assigned(FLogger) then
        FLogger.LogError('WebSocket exception: {0}', [AException.Message]);
    end;
end;

constructor TStreamingRpcClient.Create(const AUrl: string; const AClient: IWebSocketApiClient; const ALogger: ILogger);
begin
  inherited Create;
  FNodeAddress := TURI.Create(AUrl);
  FClient := AClient;
  FLogger := ALogger;
  FLock := TCriticalSection.Create;
  FConnectionStats := TConnectionStatistics.Create;

  WireClientCallbacks;
end;

destructor TStreamingRpcClient.Destroy;
begin
  Disconnect;
  FClient := nil;

  if Assigned(FLock) then
    FLock.Free;
  inherited;
end;

function TStreamingRpcClient.GetNodeAddress: TURI;
begin
  Result := FNodeAddress;
end;

function TStreamingRpcClient.GetConverters: TList<TJsonConverter>;
begin
  Result := TList<TJsonConverter>.Create;
  Result.Add(TEncodingConverter.Create);
  Result.Add(TJsonStringEnumConverter.Create(TJsonNamingPolicy.CamelCase));
end;

function TStreamingRpcClient.BuildSerializer: TJsonSerializer;
var
  Converters: TList<TJsonConverter>;
begin
  Converters := GetConverters();
  try
    Result := TJsonSerializerFactory.CreateSerializer(
      TEnhancedContractResolver.Create(
        TJsonMemberSerialization.Public,
        TJsonNamingPolicy.CamelCase
      ),
      Converters
    );
  finally
    Converters.Free;
  end;
end;

function TStreamingRpcClient.GetStatistics: IConnectionStatistics;
begin
  Result := FConnectionStats;
end;

procedure TStreamingRpcClient.Connect;
begin
  FLock.Acquire;
  try
    if not FClient.Connected then
    begin
      FClient.Connect(FNodeAddress.ToString);
    end;
  finally
    FLock.Release;
  end;
end;

procedure TStreamingRpcClient.Disconnect;
begin
  FLock.Acquire;
  try
    if FClient.Connected then
    begin
      FClient.Disconnect;
      CleanupSubscriptions;
    end;
  finally
    FLock.Release;
  end;
end;

end.

