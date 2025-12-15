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

unit SlpSolanaStreamingRpcClient;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  System.JSON,
  System.Json.Serializers,
{$IFDEF FPC}
  URIParser,
{$ELSE}
  System.Net.URLClient,
{$ENDIF}
  SlpRpcModel,
  SlpRpcMessage,
  SlpConfigObject,
  SlpRpcEnum,
  SlpStreamingRpcClient,
  SlpIdGenerator,
  SlpConnectionStatistics,
  SlpSubscriptionEvent,
  SlpWebSocketApiClient,
  SlpMulticast,
  SlpValueUtils,
  SlpNullable,
  SlpLogger;

type
  /// <summary>
  /// Represents the channel of a given subscription.
  /// </summary>
  TSubscriptionChannel = class sealed
  public
    /// <summary>
    /// Account subscription (<c>accountSubscribe</c>).
    /// </summary>
    const TokenAccount = 'TokenAccount';

    /// <summary>
    /// Account subscription (<c>accountSubscribe</c>).
    /// </summary>
    const Account = 'Account';

    /// <summary>
    /// Logs subscription (<c>logsSubscribe</c>).
    /// </summary>
    const Logs = 'Logs';

    /// <summary>
    /// Program subscription (<c>programSubscribe</c>).
    /// </summary>
    const &Program = 'Program';

    /// <summary>
    /// Signature subscription (<c>signatureSubscribe</c>).
    /// </summary>
    const Signature = 'Signature';

    /// <summary>
    /// Slot subscription (<c>slotSubscribe</c>).
    /// </summary>
    const Slot = 'Slot';

    /// <summary>
    /// Root subscription (<c>rootSubscribe</c>).
    /// </summary>
    const Root = 'Root';
  end;

  ISubscriptionState = interface;

  /// <summary>
  /// Represents the streaming RPC client for the solana API.
  /// </summary>
  IStreamingRpcClient = interface
    ['{7C2C0E3C-35C6-4F7E-85E9-5A8E0B2B9C5F}']

    /// <summary>
    /// The address this client connects to.
    /// </summary>
    function GetNodeAddress: TURI;

    /// <summary>
    /// Statistics of the current connection.
    /// </summary>
    function GetStatistics: IConnectionStatistics;

    /// <summary>
    /// The address this client connects to.
    /// </summary>
    property NodeAddress: TURI read GetNodeAddress;

    /// <summary>
    /// Statistics of the current connection.
    /// </summary>
    property Statistics: IConnectionStatistics read GetStatistics;

    /// <summary>
    /// Subscribes to AccountInfo notifications.
    /// </summary>
    /// <remarks>
    /// The <c>commitment</c> parameter is optional, the default value <see cref="Commitment.Finalized"/> is not sent.
    /// </remarks>
    /// <param name="APubkey">The public key of the account.</param>
    /// <param name="ACallback">The callback to handle data notifications.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object representing the state of the subscription.</returns>
    function SubscribeAccountInfo(
      const APubkey: string;
      const ACallback: TProc<ISubscriptionState, TResponseValue<TAccountInfo>>;
      const ACommitment: TCommitment = TCommitment.Finalized
    ): ISubscriptionState;

    /// <summary>
    /// Subscribes to Token Account notifications. Note: Only works if the account is a Token Account.
    /// </summary>
    /// <remarks>
    /// The <c>commitment</c> parameter is optional, the default value <see cref="Commitment.Finalized"/> is not sent.
    /// </remarks>
    /// <param name="APubkey">The public key of the account.</param>
    /// <param name="ACallback">The callback to handle data notifications.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object representing the state of the subscription.</returns>
    function SubscribeTokenAccount(
      const APubkey: string;
      const ACallback: TProc<ISubscriptionState, TResponseValue<TTokenAccountInfo>>;
      const ACommitment: TCommitment = TCommitment.Finalized
    ): ISubscriptionState;

    /// <summary>
    /// Subscribes to the logs notifications that mention a given public key.
    /// </summary>
    /// <remarks>
    /// The <c>commitment</c> parameter is optional, the default value <see cref="Commitment.Finalized"/> is not sent.
    /// </remarks>
    /// <param name="APubkey">The public key to filter by mention.</param>
    /// <param name="ACallback">The callback to handle data notifications.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object representing the state of the subscription.</returns>
    function SubscribeLogInfo(
      const APubkey: string;
      const ACallback: TProc<ISubscriptionState, TResponseValue<TLogInfo>>;
      const ACommitment: TCommitment = TCommitment.Finalized
    ): ISubscriptionState; overload;

    /// <summary>
    /// Subscribes to the logs notifications.
    /// </summary>
    /// <remarks>
    /// The <c>commitment</c> parameter is optional, the default value <see cref="Commitment.Finalized"/> is not sent.
    /// </remarks>
    /// <param name="ASubscriptionType">The filter mechanism.</param>
    /// <param name="ACallback">The callback to handle data notifications.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object representing the state of the subscription.</returns>
    function SubscribeLogInfo(
      const ASubscriptionType: TLogsSubscriptionType;
      const ACallback: TProc<ISubscriptionState, TResponseValue<TLogInfo>>;
      const ACommitment: TCommitment = TCommitment.Finalized
    ): ISubscriptionState; overload;

    /// <summary>
    /// Subscribes to a transaction signature to receive notification when the transaction is confirmed.
    /// </summary>
    /// <remarks>
    /// The <c>commitment</c> parameter is optional, the default value <see cref="Commitment.Finalized"/> is not sent.
    /// </remarks>
    /// <param name="ATransactionSignature">The transaction signature.</param>
    /// <param name="ACallback">The callback to handle data notifications.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object representing the state of the subscription.</returns>
    function SubscribeSignature(
      const ATransactionSignature: string;
      const ACallback: TProc<ISubscriptionState, TResponseValue<TErrorResult>>;
      const ACommitment: TCommitment = TCommitment.Finalized
    ): ISubscriptionState;

    /// <summary>
    /// Subscribes to changes to a given program account data.
    /// </summary>
    /// <param name="AProgramPubkey">The program pubkey.</param>
    /// <param name="ACallback">The callback to handle data notifications.</param>
    /// <param name="ADataSize"></param>
    /// <param name="AMemCmpList"></param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object representing the state of the subscription.</returns>
    function SubscribeProgram(
      const AProgramPubkey: string;
      const ACallback: TProc<ISubscriptionState, TResponseValue<TAccountKeyPair>>;
      const ADataSize: TNullable<Integer>;
      const AMemCmpList: TArray<TMemCmp> = nil;
      const ACommitment: TCommitment = TCommitment.Finalized
    ): ISubscriptionState;

    /// <summary>
    /// Subscribes to receive notifications anytime a slot is processed by the validator.
    /// </summary>
    /// <param name="ACallback">The callback to handle data notifications.</param>
    /// <returns>Returns an object representing the state of the subscription.</returns>
    function SubscribeSlotInfo(
      const ACallback: TProc<ISubscriptionState, TSlotInfo>
    ): ISubscriptionState;

    /// <summary>
    /// Subscribes to receive notifications anytime a new root is set by the validator.
    /// </summary>
    /// <param name="ACallback">The callback to handle data notifications.</param>
    /// <returns>Returns an object representing the state of the subscription.</returns>
    function SubscribeRoot(
      const ACallback: TProc<ISubscriptionState, Integer>
    ): ISubscriptionState;

    /// <summary>
    /// Unsubscribes from a given subscription using the state object. This is a synchronous and blocking function.
    /// </summary>
    /// <param name="ASubscription">The subscription state object.</param>
    procedure Unsubscribe(const ASubscription: ISubscriptionState);

    /// <summary>
    /// Initializes the client connection and starts listening for socket messages.
    /// </summary>
    procedure Connect;

    /// <summary>
    /// Disconnects and removes all running subscriptions.
    /// </summary>
    procedure Disconnect;
  end;

  /// <summary>
  /// Represents the state of a given subscription.
  /// </summary>
  ISubscriptionState = interface
    ['{4E1F4F5E-7D2E-4A63-9E3E-5C2F4C6B7C88}']
    /// <summary>The subscription ID as confirmed by the node.</summary>
    function  GetSubscriptionId: Integer;
    procedure SetSubscriptionId(const AValue: Integer);

    /// <summary>The channel subscribed.</summary>
    function  GetChannel: string;

    /// <summary>The current state of the subscription.</summary>
    function  GetState: TSubscriptionStatus;

    /// <summary>The last error message.</summary>
    function  GetLastError: string;

    /// <summary>The last error code.</summary>
    function  GetLastCode: string;

    /// <summary>The collection of parameters submitted for this subscription.</summary>
    function  GetAdditionalParameters: TList<TValue>;

    /// <summary>Changes the state of the subscription and notifies subscribers.</summary>
    procedure ChangeState(const ANewState: TSubscriptionStatus; const AError: string = ''; const ACode: string = '');

    /// <summary>Invokes the data handler.</summary>
    /// <param name="AData">The data.</param>
    procedure HandleData(const AData: TValue);

    /// <summary>Unsubscribes the current subscription.</summary>
    procedure Unsubscribe;

    /// <summary>Add a listener for subscription changes.</summary>
    procedure AddSubscriptionChanged(const AHandler: TProc<ISubscriptionState, ISubscriptionEvent>);

    /// <summary>Remove a listener.</summary>
    procedure RemoveSubscriptionChanged(const AHandler: TProc<ISubscriptionState, ISubscriptionEvent>);

    property SubscriptionId: Integer read GetSubscriptionId write SetSubscriptionId;
    property Channel: string read GetChannel;
    property State: TSubscriptionStatus read GetState;
    property LastError: string read GetLastError;
    property LastCode: string read GetLastCode;
    property AdditionalParameters: TList<TValue> read GetAdditionalParameters;
  end;

  /// <summary>
  /// Represents the state of a given subscription with specified type handler.
  /// </summary>
  /// <typeparam name="T">The type of the data received by this subscription.</typeparam>
  ISubscriptionStateWithHandler<T> = interface(ISubscriptionState)
    ['{B2F6F4A2-9A2D-4D56-B3B7-2B3E0A1B6F11}']
    /// <summary>The data handler reference.</summary>
    procedure SetDataHandler(const AHandler: TProc<ISubscriptionStateWithHandler<T>, T>);
  end;

  /// <summary>
  /// Represents the state of a given subscription.
  /// </summary>
  TSubscriptionState = class(TInterfacedObject, ISubscriptionState)
  private
    FRpcClient: IStreamingRpcClient;
    FSubscriptionId: Integer;
    FChannel: string;
    FState: TSubscriptionStatus;
    FLastError: string;
    FLastCode: string;
    FAdditionalParameters: TList<TValue>;

    // Multicast list of handlers
    FSubs: IMulticast<TProc<ISubscriptionState, ISubscriptionEvent>>;

    // ISubscriptionState core
    procedure ChangeState(const ANewState: TSubscriptionStatus; const AError: string = ''; const ACode: string = '');
    procedure HandleData(const AData: TValue); virtual; abstract;
    procedure Unsubscribe;

  protected
    // ISubscriptionState getters/setters
    function  GetSubscriptionId: Integer;
    procedure SetSubscriptionId(const AValue: Integer);
    function  GetChannel: string;
    function  GetState: TSubscriptionStatus;
    function  GetLastError: string;
    function  GetLastCode: string;
    function  GetAdditionalParameters: TList<TValue>;

    procedure AddSubscriptionChanged(const AHandler: TProc<ISubscriptionState, ISubscriptionEvent>);
    procedure RemoveSubscriptionChanged(const AHandler: TProc<ISubscriptionState, ISubscriptionEvent>);

    /// <summary>
    /// Base constructor.
    /// </summary>
    /// <param name="ARpcClient">The streaming rpc client reference.</param>
    /// <param name="AChannel">The channel of this subscription.</param>
    /// <param name="AAdditionalParameters">Additional parameters for this given subscription.</param>
    constructor Create(const ARpcClient: IStreamingRpcClient; const AChannel: string;
                       const AAdditionalParameters: TList<TValue> = nil); overload;
  public
    /// <summary>Destructor.</summary>
    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents the state of a given subscription with specified type handler.
  /// </summary>
  /// <typeparam name="T">The type of the data received by this subscription.</typeparam>
  TSubscriptionStateWithHandler<T> = class(TSubscriptionState, ISubscriptionStateWithHandler<T>)
  private
    FDataHandler: TProc<ISubscriptionStateWithHandler<T>, T>;

    /// <inheritdoc cref="ISubscriptionState.HandleData(TValue)"/>
    procedure HandleData(const AData: TValue); override;

    // ISubscriptionStateWithHandler<T>
    procedure SetDataHandler(const AHandler: TProc<ISubscriptionStateWithHandler<T>, T>);
  public
    /// <summary>
    /// Constructor with all parameters related to a given subscription.
    /// </summary>
    /// <param name="ARpcClient">The streaming rpc client reference.</param>
    /// <param name="AChannel">The channel of this subscription.</param>
    /// <param name="AHandler">The handler for the data received.</param>
    /// <param name="AAdditionalParameters">Additional parameters for this given subscription.</param>
    constructor Create(const ARpcClient: IStreamingRpcClient; const AChannel: string;
                       const AHandler: TProc<ISubscriptionState, T>;
                       const AAdditionalParameters: TList<TValue> = nil);

    destructor Destroy; override;
  end;

  /// <summary>Implementation of the Solana streaming RPC API abstraction client.</summary>
  TSolanaStreamingRpcClient = class(TStreamingRpcClient, IStreamingRpcClient)
  private
     /// <summary>
     /// Message Id generator.
    /// </summary>
    FIdGenerator: IIdGenerator;
     /// <summary>
     /// Json Serializer.
    /// </summary>
    FSerializer: TJsonSerializer;
    /// <summary>
    /// Maps the internal ids to the unconfirmed subscription state objects.
    /// </summary>
    FUnconfirmed: TDictionary<Integer, ISubscriptionState>;
    /// <summary>
    /// Maps the server ids to the confirmed subscription state objects.
    /// </summary>
    FConfirmed: TDictionary<Integer, ISubscriptionState>;

    FLock: TCriticalSection;

    FUnsubscribeMap: TArray<TPair<string, string>>;

    /// <summary>
    /// Removes an unconfirmed subscription.
    /// </summary>
    /// <param name="AId">The subscription id.</param>
    /// <returns>Returns the subscription object if it was found.</returns>
    function RemoveUnconfirmedSubscription(const AId: Integer): ISubscriptionState;
    /// <summary>
    /// Removes a given subscription object from the map and notifies the object of the unsubscription.
    /// </summary>
    /// <param name="AId">The subscription id.</param>
    /// <param name="AShouldNotify">Whether or not to notify that the subscription was removed.</param>
    procedure RemoveSubscription(const AId: Integer; const AShouldNotify: Boolean);
    /// <summary>
    /// Confirms a given subcription based on the internal subscription id and the newly received external id.
    /// Moves the subcription state object from the unconfirmed map to the confirmed map.
    /// </summary>
    /// <param name="AInternalId"></param>
    /// <param name="AResultId"></param>
    procedure ConfirmSubscription(const AInternalId, AResultId: Integer);
    /// <summary>
    /// Adds a new subscription state object into the unconfirmed subscriptions map.
    /// </summary>
    /// <param name="ASubscription">The subcription to add.</param>
    /// <param name="AInternalId">The internally generated id of the subscription.</param>
    procedure AddSubscription(const ASubscription: ISubscriptionState; const AInternalId: Integer);
    /// <summary>
    /// Safely retrieves a subscription state object from a given subscription id.
    /// </summary>
    /// <param name="ASubscriptionId">The subscription id.</param>
    /// <returns>The subscription state object.</returns>
    function RetrieveSubscription(const ASubscriptionId: Integer): ISubscriptionState;

    /// <summary>
    /// Handles and finishes parsing the contents of an error message.
    /// </summary>
    /// <param name="ARoot"></param>
    procedure HandleErrorFromRoot(const ARoot: TJSONObject);

    /// <summary>
    /// Conditionally includes the <c>commitment</c> option.
    /// </summary>
    /// <param name="AParameter">The requested commitment.</param>
    /// <param name="ADefaultValue">
    /// The default commitment; when <c>AParameter = ADefaultValue</c>, the key is omitted.
    /// </param>
    /// <returns>
    /// A <c>TKeyValue</c> pair when included; otherwise <c>Default(TKeyValue)</c>.
    /// </returns>
    function HandleCommitment(AParameter: TCommitment; ADefault: TCommitment = TCommitment.Finalized): TKeyValue;

    /// <summary>
    /// Build the request for the passed RPC method and parameters.
    /// </summary>
    /// <param name="AMethod">The request's RPC method.</param>
    /// <param name="AParameters">A list of parameters to include in the request.</param>
    /// <returns>A JSON-RPC request object.</returns>
    function BuildRequest(const AMethod: string; const AParameters: TList<TValue>): TJsonRpcRequest;

    function SubscribeAccountInfo(const APubKey: string;
      const ACallback: TProc<ISubscriptionState, TResponseValue<TAccountInfo>>;
      const ACommitment: TCommitment = TCommitment.Finalized): ISubscriptionState;

    function SubscribeTokenAccount(const APubKey: string;
      const ACallback: TProc<ISubscriptionState, TResponseValue<TTokenAccountInfo>>;
      const ACommitment: TCommitment = TCommitment.Finalized): ISubscriptionState;

    function SubscribeLogInfo(const APubKey: string;
      const ACallback: TProc<ISubscriptionState, TResponseValue<TLogInfo>>;
      const ACommitment: TCommitment = TCommitment.Finalized): ISubscriptionState; overload;

    function SubscribeLogInfo(const ASubscriptionType: TLogsSubscriptionType;
      const ACallback: TProc<ISubscriptionState, TResponseValue<TLogInfo>>;
      const ACommitment: TCommitment = TCommitment.Finalized): ISubscriptionState; overload;

    function SubscribeSignature(const ATxSignature: string;
      const ACallback: TProc<ISubscriptionState, TResponseValue<TErrorResult>>;
      const ACommitment: TCommitment = TCommitment.Finalized): ISubscriptionState;

    /// <summary>
    /// Subscribe Program
    /// </summary>
    /// <param name="AProgramPubkey"></param>
    /// <param name="ACallback"></param>
    /// <param name="ADataSize"></param>
    /// <param name="AMemCmpList"></param>
    /// <param name="ACommitment"></param>
    /// <returns></returns>
    function SubscribeProgram(const AProgramPubkey: string;
      const ACallback: TProc<ISubscriptionState, TResponseValue<TAccountKeyPair>>;
      const ADataSize: TNullable<Integer>; const AMemCmpList: TArray<TMemCmp> = nil;
      const ACommitment: TCommitment = TCommitment.Finalized): ISubscriptionState;

    function SubscribeSlotInfo(const ACallback: TProc<ISubscriptionState, TSlotInfo>): ISubscriptionState;
    function SubscribeRoot(const ACallback: TProc<ISubscriptionState, Integer>): ISubscriptionState;

    /// <summary>
    /// Internal subscribe function, finishes the serialization and sends the message payload.
    /// </summary>
    /// <param name="ASub">The subscription state object.</param>
    /// <param name="AMsg">The message to be serialized and sent.</param>
    /// <returns>The subscription state</returns>
    function Subscribe(
      const ASub: ISubscriptionState;
      const AMsg: TJsonRpcRequest): ISubscriptionState; overload;

    procedure Unsubscribe(const ASubscription: ISubscriptionState);

    /// <summary>
    /// Gets (and caches) the unsubscribe map.
    /// </summary>
    function GetUnsubscribeMap: TArray<TPair<string, string>>;

    function GetUnsubscribeMethodName(const AChannel: string): string;

  protected
    procedure CleanupSubscriptions; override;

    procedure HandleNewMessage(const APayload: TBytes); override;

    procedure SendAs<T>(const AJson: string; const ASub: ISubscriptionState);

    /// <summary>
    /// Handles a notification message and finishes parsing the contents.
    /// </summary>
    /// <param name="AJsonObject">The JsonObject holding the message.</param>
    /// <param name="AMethod">The method parameter already parsed within the message.</param>
    /// <param name="ASubscriptionId">The subscriptionId for this message.</param>
    procedure HandleDataMessage(const AJsonObject: TJSONObject; const AMethod: string; const ASubscriptionId: Integer); virtual;

    /// <summary>
    /// Builds the mapping between subscription channels and their unsubscribe method names.
    /// Override in subclasses to extend or modify mappings.
    /// </summary>
    function BuildUnsubscribeMap: TArray<TPair<string, string>>; virtual;

    /// <summary>
    /// Send a request synchronously.
    /// </summary>
    /// <param name="AChannel">The subscription channel.</param>
    /// <param name="AMethod">The request's RPC method.</param>
    /// <param name="ACallback">The subscription callback.</param>
    /// <typeparam name="T">The type of the subscription callback result.</typeparam>
    /// <returns>A subscription state.</returns>
    function Subscribe<T>(
      const AChannel : string;
      const AMethod  : string;
      const ACallback: TProc<ISubscriptionState, T>
    ): ISubscriptionState; overload;

    /// <summary>
    /// Send a request synchronously.
    /// </summary>
    /// <param name="AChannel">The subscription channel.</param>
    /// <param name="AMethod">The request's RPC method.</param>
    /// <param name="ACallback">The subscription callback.</param>
    /// <param name="AParameters">A list of parameters to include in the request.</param>
    /// <typeparam name="T">The type of the subscription callback result.</typeparam>
    /// <returns>A subscription state.</returns>
    function Subscribe<T>(
      const AChannel : string;
      const AMethod  : string;
      const ACallback: TProc<ISubscriptionState, T>;
      const AParams  : TList<TValue>
    ): ISubscriptionState; overload;

  public
    /// <summary>
    /// Initializes a new instance of the class.
    /// </summary>
    /// <param name="AUrl">The URL of the server to connect to.</param>
    /// <param name="AClient">An optional WebSocket client instance to use.</param>
    /// <param name="ALogger">An optional ILogger instance for logging.</param>
    constructor Create(const AUrl: string; const AClient: IWebSocketApiClient; const ALogger: ILogger = nil);
    destructor Destroy; override;
  end;

implementation

{ TSubscriptionState }

constructor TSubscriptionState.Create(const ARpcClient: IStreamingRpcClient; const AChannel: string;
  const AAdditionalParameters: TList<TValue>);
begin
  inherited Create;
  FRpcClient := ARpcClient;
  FChannel := AChannel;
  FLastError := '';
  FLastCode := '';
  FAdditionalParameters := AAdditionalParameters;

  FSubs := TMulticast<TProc<ISubscriptionState, ISubscriptionEvent>>.Create;
end;

destructor TSubscriptionState.Destroy;
begin
  if Assigned(FAdditionalParameters) then
   TValueUtils.FreeParameters(FAdditionalParameters);
  inherited;
end;

function TSubscriptionState.GetSubscriptionId: Integer;
begin
  Result := FSubscriptionId;
end;

procedure TSubscriptionState.SetSubscriptionId(const AValue: Integer);
begin
  FSubscriptionId := AValue;
end;

function TSubscriptionState.GetChannel: string;
begin
  Result := FChannel;
end;

function TSubscriptionState.GetState: TSubscriptionStatus;
begin
  Result := FState;
end;

function TSubscriptionState.GetLastError: string;
begin
  Result := FLastError;
end;

function TSubscriptionState.GetLastCode: string;
begin
  Result := FLastCode;
end;

function TSubscriptionState.GetAdditionalParameters: TList<TValue>;
begin
  Result := FAdditionalParameters;
end;

procedure TSubscriptionState.AddSubscriptionChanged(
  const AHandler: TProc<ISubscriptionState, ISubscriptionEvent>);
begin
  if not Assigned(AHandler) then Exit;

  FSubs.Add(AHandler);
end;

procedure TSubscriptionState.RemoveSubscriptionChanged(
  const AHandler: TProc<ISubscriptionState, ISubscriptionEvent>);
begin
  if not Assigned(AHandler) or (FSubs = nil) then Exit;

  FSubs.Remove(AHandler);
end;

procedure TSubscriptionState.ChangeState(const ANewState: TSubscriptionStatus; const AError, ACode: string);
var
  Ev: ISubscriptionEvent;
begin
  FState := ANewState;
  FLastError := AError;
  FLastCode := ACode;

  if Assigned(FSubs) and not FSubs.IsEmpty then
  begin
    Ev := TSubscriptionEvent.Create(ANewState, AError, ACode);

    FSubs.Notify(
        procedure(H: TProc<ISubscriptionState, ISubscriptionEvent>)
        begin
          H(Self as ISubscriptionState, Ev);
        end
    );
  end;
end;

procedure TSubscriptionState.Unsubscribe;
begin
  if Assigned(FRpcClient) then
    FRpcClient.Unsubscribe(Self as ISubscriptionState);
end;

{ TSubscriptionStateWithHandler<T> }

constructor TSubscriptionStateWithHandler<T>.Create(const ARpcClient: IStreamingRpcClient;
  const AChannel: string; const AHandler: TProc<ISubscriptionState, T>;
  const AAdditionalParameters: TList<TValue>);
begin
  inherited Create(ARpcClient, AChannel, AAdditionalParameters);
  FDataHandler := TProc<ISubscriptionStateWithHandler<T>, T>(AHandler);
end;

destructor TSubscriptionStateWithHandler<T>.Destroy;
begin
  FDataHandler := nil;
  inherited;
end;

procedure TSubscriptionStateWithHandler<T>.HandleData(const AData: TValue);
var
  H: TProc<ISubscriptionStateWithHandler<T>, T>;
begin
  H := FDataHandler;
  if Assigned(H) then
    H(Self as ISubscriptionStateWithHandler<T>, AData.AsType<T>);
end;

procedure TSubscriptionStateWithHandler<T>.SetDataHandler(
  const AHandler: TProc<ISubscriptionStateWithHandler<T>, T>);
begin
  FDataHandler := AHandler;
end;

{ TSolanaStreamingRpcClient }

constructor TSolanaStreamingRpcClient.Create(const AUrl: string; const AClient: IWebSocketApiClient; const ALogger: ILogger);
begin
  inherited Create(AUrl, AClient, ALogger);
  FIdGenerator := TIdGenerator.Create();
  FSerializer := BuildSerializer();
  FUnconfirmed := TDictionary<Integer, ISubscriptionState>.Create;
  FConfirmed   := TDictionary<Integer, ISubscriptionState>.Create;
  FLock := TCriticalSection.Create;
end;

destructor TSolanaStreamingRpcClient.Destroy;
var
  I: Integer;
begin
  inherited;

  if Assigned(FUnconfirmed) then
    FUnconfirmed.Free;

  if Assigned(FConfirmed) then
    FConfirmed.Free;

  if Assigned(FSerializer) then
  begin
    if Assigned(FSerializer.Converters) then
    begin
      for I := 0 to FSerializer.Converters.Count - 1 do
        if Assigned(FSerializer.Converters[I]) then
          FSerializer.Converters[I].Free;
      FSerializer.Converters.Clear;
    end;
    FSerializer.Free;
  end;

  if Assigned(FLock) then
    FLock.Free;
end;

procedure TSolanaStreamingRpcClient.SendAs<T>(
  const AJson: string; const ASub: ISubscriptionState);
var
  V: TValue;
begin
  V := TValue.From<T>(FSerializer.Deserialize<T>(AJson));
  try
    ASub.HandleData(V);
  finally
    TValueUtils.FreeParameter(V);
  end;
end;

procedure TSolanaStreamingRpcClient.CleanupSubscriptions;
var
  Pair: TPair<Integer, ISubscriptionState>;
begin
  for Pair in FConfirmed do
    if Assigned(Pair.Value) then
    begin
      Pair.Value.ChangeState(TSubscriptionStatus.Unsubscribed, 'Connection terminated');
      FConfirmed[Pair.Key] := nil;
    end;

  for Pair in FUnconfirmed do
    if Assigned(Pair.Value) then
    begin
      Pair.Value.ChangeState(TSubscriptionStatus.Unsubscribed, 'Connection terminated');
      FUnconfirmed[Pair.Key] := nil;
    end;

  FUnconfirmed.Clear;
  FConfirmed.Clear;
end;

function TSolanaStreamingRpcClient.RemoveUnconfirmedSubscription(const AId: Integer): ISubscriptionState;
begin
  FLock.Acquire;
  try
    if not FUnconfirmed.TryGetValue(AId, Result) then
    begin
      Result := nil;
      if Assigned(FLogger) then
        FLogger.LogDebug('No unconfirmed subscription found with ID:{0}', [IntToStr(AId)]);
      Exit;
    end;
    FUnconfirmed.Remove(AId);
  finally
    FLock.Release;
  end;
end;

procedure TSolanaStreamingRpcClient.RemoveSubscription(const AId: Integer; const AShouldNotify: Boolean);
var
  Sub: ISubscriptionState;
begin
  FLock.Acquire;
  try
    if not FConfirmed.TryGetValue(AId, Sub) then
    begin
      if Assigned(FLogger) then
        FLogger.LogDebug('No subscription found with ID:{0}', [IntToStr(AId)]);
      Exit;
    end;
    FConfirmed.Remove(AId);
  finally
    FLock.Release;
  end;

  if AShouldNotify and Assigned(Sub) then
    Sub.ChangeState(TSubscriptionStatus.Unsubscribed);
end;

procedure TSolanaStreamingRpcClient.ConfirmSubscription(const AInternalId, AResultId: Integer);
var
  Sub: ISubscriptionState;
begin
  Sub := nil;

  FLock.Acquire;
  try
    if FUnconfirmed.TryGetValue(AInternalId, Sub) then
    begin
      FUnconfirmed.Remove(AInternalId);
      Sub.SubscriptionId := AResultId;
      FConfirmed.AddOrSetValue(AResultId, Sub);
    end;
  finally
    FLock.Release;
  end;

  if Assigned(Sub) then
    Sub.ChangeState(TSubscriptionStatus.Subscribed);
end;

procedure TSolanaStreamingRpcClient.AddSubscription(const ASubscription: ISubscriptionState; const AInternalId: Integer);
begin
  FLock.Acquire;
  try
    FUnconfirmed.Add(AInternalId, ASubscription);
  finally
    FLock.Release;
  end;
end;

function TSolanaStreamingRpcClient.RetrieveSubscription(const ASubscriptionId: Integer): ISubscriptionState;
begin
  FLock.Acquire;
  try
    if not FConfirmed.TryGetValue(ASubscriptionId, Result) then
      Result := nil;
  finally
    FLock.Release;
  end;
end;

procedure TSolanaStreamingRpcClient.HandleErrorFromRoot(const ARoot: TJSONObject);
var
  LErrObj: TJSONObject;
  LIdVal: TJSONValue;
  LId: Integer;
  LSub: ISubscriptionState;
  LErrJson: string;
  LErrObjInst: TErrorContent;
begin
  if ARoot = nil then Exit;

  LErrObj := ARoot.GetValue('error') as TJSONObject;
  LIdVal  := ARoot.GetValue('id');

  LErrObjInst := nil;
  if LErrObj <> nil then
  begin
    LErrJson := LErrObj.ToJSON;
    LErrObjInst := FSerializer.Deserialize<TErrorContent>(LErrJson);

    if LErrObjInst = nil then
    Exit;
  end;

  try
    if (LIdVal <> nil) and TryStrToInt(LIdVal.Value, LId) then
    begin
      LSub := RemoveUnconfirmedSubscription(LId);
      if Assigned(LSub) and Assigned(LErrObjInst) then
        LSub.ChangeState(
          TSubscriptionStatus.ErrorSubscribing,
          LErrObjInst.Message,
          IntToStr(LErrObjInst.Code)
        );
    end;
  finally
    LErrObjInst.Free;
  end;
end;

procedure TSolanaStreamingRpcClient.HandleNewMessage(const APayload: TBytes);
var
  LRoot, LParamsObj: TJSONObject;
  LMethodVal, LErrorVal, LIdVal, LResultVal, LSubVal: TJSONValue;
  LMethod: string;
  LId, LIntResult, LSubId: Integer;
  LHaveId, LHaveIntResult, LHandled, LHasBoolResult, LBoolResult: Boolean;
begin
  // Log raw payload (info)
  if Assigned(FLogger) and FLogger.IsEnabled(TLogLevel.Info) then
    FLogger.LogInformation('[Received]{0}', [TEncoding.UTF8.GetString(APayload)]);

  // Parse top-level JSON
  LRoot := TJSONObject.ParseJSONValue(APayload, 0) as TJSONObject;
  if LRoot = nil then
    Exit;

  LMethod        := '';
  LId            := 0;
  LIntResult     := 0;
  LSubId         := 0;
  LHandled       := False;
  LHasBoolResult  := False;
  LBoolResult    := False;

  try
    // Common fields
    LMethodVal := LRoot.GetValue('method');
    LErrorVal  := LRoot.GetValue('error');
    LIdVal     := LRoot.GetValue('id');
    LResultVal := LRoot.GetValue('result');

    if (LMethodVal is TJSONString) then
      LMethod := TJSONString(LMethodVal).Value
    else
      LMethod := '';

    // Error path -> delegate and return
    if Assigned(LErrorVal) then
    begin
      HandleErrorFromRoot(LRoot);
      Exit;
    end;

    // Notification path via params.subscription
    LParamsObj := LRoot.GetValue('params') as TJSONObject;
    if Assigned(LParamsObj) then
    begin
      LSubVal := LParamsObj.GetValue('subscription');
      if Assigned(LSubVal) and TryStrToInt(LSubVal.Value, LSubId) then
      begin
        HandleDataMessage(LParamsObj, LMethod, LSubId);
        LHandled := True;
      end;
    end;

    // Confirmation path: id + result (int)
    if Assigned(LIdVal) then
      LHaveId := TryStrToInt(LIdVal.Value, LId)
    else
      LHaveId := False;

    if Assigned(LResultVal) then
      LHaveIntResult := TryStrToInt(LResultVal.Value, LIntResult)
    else
      LHaveIntResult := False;

    if (not LHandled) and LHaveId and LHaveIntResult then
    begin
      ConfirmSubscription(LId, LIntResult);
      LHandled := True;
    end;

    // Unsubscribe result path: id + result (bool)
    if (not LHandled) and LHaveId and Assigned(LResultVal) then
    begin
      if LResultVal is TJSONTrue then
      begin
        LBoolResult  := True;
        LHasBoolResult := True;
      end
      else if LResultVal is TJSONFalse then
      begin
        LBoolResult  := False;
        LHasBoolResult := True;
      end;
    end;

    if LHasBoolResult then
      RemoveSubscription(LId, LBoolResult);

  finally
    LRoot.Free;
  end;
end;

procedure TSolanaStreamingRpcClient.HandleDataMessage(
  const AJsonObject: TJSONObject;
  const AMethod: string;
  const ASubscriptionId: Integer);
var
  LSub     : ISubscriptionState;
  LResVal  : TJSONValue;
  LSubVal  : TJSONValue;
  LJson    : string;
  LSubId   : Integer;
  LHaveSub : Boolean;
begin
  if AJsonObject = nil then Exit;

  LSub := RetrieveSubscription(ASubscriptionId);
  if not Assigned(LSub) then Exit;

  LSubVal  := AJsonObject.GetValue('subscription');
  LHaveSub := Assigned(LSubVal) and TryStrToInt(LSubVal.Value, LSubId);

  LResVal := AJsonObject.GetValue('result');
  if LResVal = nil then Exit;

  LJson := LResVal.ToJSON;

  if AMethod = 'accountNotification' then
  begin
    if LSub.Channel = TSubscriptionChannel.TokenAccount then
      SendAs<TResponseValue<TTokenAccountInfo>>(LJson, LSub)
    else
      SendAs<TResponseValue<TAccountInfo>>(LJson, LSub);
  end
  else if AMethod = 'logsNotification' then
    SendAs<TResponseValue<TLogInfo>>(LJson, LSub)
  else if AMethod = 'programNotification' then
    SendAs<TResponseValue<TAccountKeyPair>>(LJson, LSub)
  else if AMethod = 'signatureNotification' then
  begin
    SendAs<TResponseValue<TErrorResult>>(LJson, LSub);
    if not LHaveSub then Exit;
    RemoveSubscription(LSubId, True);
  end
  else if AMethod = 'slotNotification' then
    SendAs<TSlotInfo>(LJson, LSub)
  else if AMethod = 'rootNotification' then
    SendAs<Integer>(LJson, LSub);
end;

function TSolanaStreamingRpcClient.HandleCommitment(AParameter, ADefault: TCommitment): TKeyValue;
begin
  if AParameter <> ADefault then
    Result := TKeyValue.From('commitment', TValue.From<TCommitment>(AParameter))
  else
    Result := Default(TKeyValue);
end;

function TSolanaStreamingRpcClient.BuildRequest(const AMethod: string; const AParameters: TList<TValue>): TJsonRpcRequest;
begin
  Result := TJsonRpcRequest.Create(FIdGenerator.GetNextId(), AMethod, AParameters);
end;

function TSolanaStreamingRpcClient.Subscribe<T>(
  const AChannel : string;
  const AMethod  : string;
  const ACallback: TProc<ISubscriptionState, T>
): ISubscriptionState;
begin
  Result := Subscribe<T>(AChannel, AMethod, ACallback, nil);
end;

function TSolanaStreamingRpcClient.Subscribe<T>(
  const AChannel : string;
  const AMethod  : string;
  const ACallback: TProc<ISubscriptionState, T>;
  const AParams  : TList<TValue>
): ISubscriptionState;
var
  LSub: ISubscriptionState;
  LReq: TJsonRpcRequest;
begin
  // Create the typed subscription state with the provided callback
  LSub := TSubscriptionStateWithHandler<T>.Create(
            Self as IStreamingRpcClient,
            AChannel,
            ACallback,
            TValueUtils.CloneValueList(AParams)
          );

  // Build the JSON-RPC subscribe request and send it
  LReq := BuildRequest(AMethod, AParams);
  try
    Result := Subscribe(LSub, LReq);
  finally
    LReq.Free;
  end;
end;

function TSolanaStreamingRpcClient.SubscribeAccountInfo(
  const APubKey: string;
  const ACallback: TProc<ISubscriptionState, TResponseValue<TAccountInfo>>;
  const ACommitment: TCommitment = TCommitment.Finalized
): ISubscriptionState;
var
  LParams: TList<TValue>;
begin
  // parameters = [ pubkey, { "encoding": "base64", ("commitment": X)? } ]
  LParams := TParameters.Make(
    TValue.From<string>(APubKey),
    TValue.From<TDictionary<string, TValue>>(
      TConfigObject.Make(
        TKeyValue.Make('encoding', TValue.From<TBinaryEncoding>(TBinaryEncoding.Base64)),
        HandleCommitment(ACommitment)
      )
    )
  );

  Result := Subscribe<TResponseValue<TAccountInfo>>(
              TSubscriptionChannel.Account,
              'accountSubscribe',
              ACallback,
              LParams
            );
end;

function TSolanaStreamingRpcClient.SubscribeTokenAccount(
  const APubKey: string;
  const ACallback: TProc<ISubscriptionState, TResponseValue<TTokenAccountInfo>>;
  const ACommitment: TCommitment = TCommitment.Finalized
): ISubscriptionState;
var
  LParams: TList<TValue>;
begin
  // parameters = [ pubkey, { "encoding": "jsonParsed", ("commitment": X)? } ]
  LParams := TParameters.Make(
    TValue.From<string>(APubKey),
    TValue.From<TDictionary<string, TValue>>(
      TConfigObject.Make(
        TKeyValue.Make('encoding', TValue.From<TBinaryEncoding>(TBinaryEncoding.JsonParsed)),
        HandleCommitment(ACommitment)
      )
    )
  );

  Result := Subscribe<TResponseValue<TTokenAccountInfo>>(
              TSubscriptionChannel.TokenAccount,
              'accountSubscribe',
              ACallback,
              LParams
            );
end;

function TSolanaStreamingRpcClient.SubscribeLogInfo(
  const APubKey: string;
  const ACallback: TProc<ISubscriptionState, TResponseValue<TLogInfo>>;
  const ACommitment: TCommitment = TCommitment.Finalized
): ISubscriptionState;
var
  LParams : TList<TValue>;
begin
  // parameters =
  // [
  //   { "mentions": [ pubkey ] },
  //   { "commitment": X }   // only when not Finalized
  // ]
  LParams := TParameters.Make(
    TValue.From<TDictionary<string, TValue>>(
      TConfigObject.Make(
        TKeyValue.Make('mentions', TValue.From<TArray<string>>(TArray<string>.Create(APubKey)))
      )
    ),
    TConfigObject.Make(
      HandleCommitment(ACommitment)
    )
  );

  Result := Subscribe<TResponseValue<TLogInfo>>(
              TSubscriptionChannel.Logs,
              'logsSubscribe',
              ACallback,
              LParams
            );
end;

function TSolanaStreamingRpcClient.SubscribeLogInfo(
  const ASubscriptionType: TLogsSubscriptionType;
  const ACallback: TProc<ISubscriptionState, TResponseValue<TLogInfo>>;
  const ACommitment: TCommitment = TCommitment.Finalized
): ISubscriptionState;
var
  LParams: TList<TValue>;
begin
  // parameters = [ subscriptionType, { ("commitment": X)? } ]
  LParams := TParameters.Make(
    TValue.From<TLogsSubscriptionType>(ASubscriptionType),
    TConfigObject.Make(
      HandleCommitment(ACommitment)
    )
  );

  Result := Subscribe<TResponseValue<TLogInfo>>(
              TSubscriptionChannel.Logs,
              'logsSubscribe',
              ACallback,
              LParams
            );
end;

function TSolanaStreamingRpcClient.SubscribeSignature(
  const ATxSignature: string;
  const ACallback: TProc<ISubscriptionState, TResponseValue<TErrorResult>>;
  const ACommitment: TCommitment = TCommitment.Finalized
): ISubscriptionState;
var
  LParams: TList<TValue>;
begin
  // parameters = [ transactionSignature, { ("commitment": X)? } ]
  LParams := TParameters.Make(
    TValue.From<string>(ATxSignature),
    TConfigObject.Make(
      HandleCommitment(ACommitment)
    )
  );

  Result := Subscribe<TResponseValue<TErrorResult>>(
              TSubscriptionChannel.Signature,
              'signatureSubscribe',
              ACallback,
              LParams
            );
end;

function TSolanaStreamingRpcClient.SubscribeProgram(
  const AProgramPubkey: string;
  const ACallback: TProc<ISubscriptionState, TResponseValue<TAccountKeyPair>>;
  const ADataSize: TNullable<Integer>;
  const AMemCmpList: TArray<TMemCmp> = nil;
  const ACommitment: TCommitment = TCommitment.Finalized
): ISubscriptionState;
var
  LFilters, LParams: TList<TValue>;

  function MemCmpValue(const AFilter: TMemCmp): TValue;
  begin
    // { "memcmp": { "offset": <int>, "bytes": "<base58/base64>" } }
    Result := TConfigObject.Make(
      TKeyValue.Make(
        'memcmp',
        TConfigObject.Make(
          TKeyValue.Make('offset', AFilter.Offset),
          TKeyValue.Make('bytes',  AFilter.Bytes)
        )
      )
    );
  end;

  function FiltersValue(const Items: TList<TValue>): TValue;
  begin
    // JSON array for "filters": [...]
    Result := TValue.From<TArray<TValue>>(Items.ToArray);
  end;

var
  I: Integer;
begin
  // Build filters list (optional dataSize + optional memcmp[])
  LFilters := TList<TValue>.Create;
  try
    if ADataSize.HasValue then
      LFilters.Add(
        TConfigObject.Make(
          TKeyValue.Make('dataSize', ADataSize.Value)
        )
      );

    for I := Low(AMemCmpList) to High(AMemCmpList) do
      LFilters.Add(MemCmpValue(AMemCmpList[I]));

    // parameters = [
    //   programPubkey,
    //   { "encoding":"base64", "filters":[...], ("commitment":X)? }
    // ]
    LParams := TParameters.Make(
      TValue.From<string>(AProgramPubkey),
      TValue.From<TDictionary<string, TValue>>(
        TConfigObject.Make(
          TKeyValue.Make('encoding', TValue.From<TBinaryEncoding>(TBinaryEncoding.Base64)),
          TKeyValue.Make('filters',  FiltersValue(LFilters)),
          HandleCommitment(ACommitment)
        )
      )
    );

    Result := Subscribe<TResponseValue<TAccountKeyPair>>(
                TSubscriptionChannel.Program,
                'programSubscribe',
                ACallback,
                LParams
              );
  finally
    LFilters.Free;
  end;
end;

function TSolanaStreamingRpcClient.SubscribeSlotInfo(
  const ACallback: TProc<ISubscriptionState, TSlotInfo>
): ISubscriptionState;
begin
  Result := Subscribe<TSlotInfo>(
              TSubscriptionChannel.Slot,
              'slotSubscribe',
              ACallback
            );
end;

function TSolanaStreamingRpcClient.SubscribeRoot(
  const ACallback: TProc<ISubscriptionState, Integer>
): ISubscriptionState;
begin
  // rootSubscribe takes no params
  Result := Subscribe<Integer>(
              TSubscriptionChannel.Root,
              'rootSubscribe',
              ACallback
            );
end;

procedure TSolanaStreamingRpcClient.Unsubscribe(const ASubscription: ISubscriptionState);
var
  LMethod: string;
  LParams: TList<TValue>;
  LReq   : TJsonRpcRequest;
begin
  if ASubscription = nil then
    Exit;

  LMethod := GetUnsubscribeMethodName(ASubscription.Channel);

  // params = [ subscription.SubscriptionId ]
  LParams := TParameters.Make(
    TValue.From<Integer>(ASubscription.SubscriptionId)
  );

  LReq := BuildRequest(LMethod, LParams);
  try
    Subscribe(ASubscription, LReq);
  finally
    LReq.Free;
  end;
end;

function TSolanaStreamingRpcClient.Subscribe(
  const ASub: ISubscriptionState;
  const AMsg: TJsonRpcRequest
): ISubscriptionState;
var
  Payload : string;
begin
  Payload := FSerializer.Serialize(AMsg);

  if Assigned(FLogger) and FLogger.IsEnabled(TLogLevel.Info) then
    FLogger.LogInformation(TEventId.Create(AMsg.Id.Value, AMsg.Method), '[Sending]{0}', [Payload]);

  try
    FClient.Send(Payload);
    AddSubscription(ASub, AMsg.Id.Value);
  except
    on E: Exception do
    begin
      ASub.ChangeState(TSubscriptionStatus.ErrorSubscribing, E.Message);
      if Assigned(FLogger) then
        FLogger.LogDebug(TEventId.Create(AMsg.Id.Value, AMsg.Method), 'Unable to send message (id={0}, method={1}): {2}',
          [AMsg.Id.Value.ToString, AMsg.Method, E.Message]);
    end;
  end;

  Result := ASub;
end;

function TSolanaStreamingRpcClient.BuildUnsubscribeMap: TArray<TPair<string, string>>;
begin
  // base mapping
  Result := [
    TPair<string, string>.Create(TSubscriptionChannel.Account,   'accountUnsubscribe'),
    TPair<string, string>.Create(TSubscriptionChannel.Logs,      'logsUnsubscribe'),
    TPair<string, string>.Create(TSubscriptionChannel.Program,  'programUnsubscribe'),
    TPair<string, string>.Create(TSubscriptionChannel.Root,      'rootUnsubscribe'),
    TPair<string, string>.Create(TSubscriptionChannel.Signature, 'signatureUnsubscribe'),
    TPair<string, string>.Create(TSubscriptionChannel.Slot,      'slotUnsubscribe')
  ];
end;

function TSolanaStreamingRpcClient.GetUnsubscribeMap: TArray<TPair<string, string>>;
begin
  // lazy initialization
  if Length(FUnsubscribeMap) = 0 then
    FUnsubscribeMap := BuildUnsubscribeMap;
  Result := FUnsubscribeMap;
end;

function TSolanaStreamingRpcClient.GetUnsubscribeMethodName(
  const AChannel: string): string;
var
  Pair: TPair<string, string>;
begin
  for Pair in GetUnsubscribeMap do
    if SameStr(Pair.Key, AChannel) then
      Exit(Pair.Value);

  raise EArgumentOutOfRangeException.CreateFmt(
    'invalid message type (channel=%s)', [AChannel]);
end;

end.

