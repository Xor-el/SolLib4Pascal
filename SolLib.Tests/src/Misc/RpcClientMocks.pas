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

unit RpcClientMocks;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.Json.Serializers,
  SlpRequestResult,
  SlpTokenWalletRpcProxy,
  SlpNullable,
  SlpRpcEnum,
  SlpRpcMessage,
  SlpRpcModel,
  SlpJsonKit,
  SlpEncodingConverter,
  SlpJsonStringEnumConverter,
  SlpJsonConverterFactory,
  SlpHttpClientBase,
  SlpHttpApiClient,
  SlpWebSocketApiClient,
  SlpHttpApiResponse,
  TestUtils;

type
  /// <summary>
  /// Simple mock that captures the last URL/JSON and returns a preset response.
  /// Supports GET/POST, optional query dict and header dict. Headers are ignored by default.
  /// </summary>
  TMockRpcHttpClient = class(TInterfacedObject, IHttpApiClient)
  private
    FExpectedUrl: string;
    FStatusCode: Integer;
    FStatusText: string;
    FResponseBody: string;
    FCallCount: Integer;
    FRaiseOnRequest: Boolean;

    FLastUrl: string;
    FLastJson: string;

  public
    constructor Create(const AExpectedUrl: string;
                       AStatusCode: Integer;
                       const AStatusText, ABody: string);

    constructor CreateForThrow(const AExpectedUrl: string; const AMessage: string);

    procedure ConfigureThrow(const AMessage: string);

    function GetJson(const AUrl: string): IHttpApiResponse; overload;
    function GetJson(const AUrl: string; const AQuery: THttpApiQueryParams): IHttpApiResponse; overload;
    function GetJson(const AUrl: string; const AQuery: THttpApiQueryParams;
                     const AHeaders: THttpApiHeaderParams): IHttpApiResponse; overload;

    function PostJson(const AUrl: string; const AJson: string): IHttpApiResponse; overload;
    function PostJson(const AUrl, AJson: string;
                      const AHeaders: THttpApiHeaderParams): IHttpApiResponse; overload;

    property CallCount: Integer read FCallCount;
    property LastUrl: string read FLastUrl;
    property LastJson: string read FLastJson;
  end;

type
  TMyMockHttpMessageHandler = class
  private
    type TReqResp = record
      ExpectedRequest: string;
      Response: string;
      Status: Integer;
    end;
  private
    FQueue: TQueue<TReqResp>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(const ExpectedRequests, ExpectedResponses: string; const Status: Integer = 200);
    function Dequeue(out ExpectedRequests, ExpectedResponses: string; out Status: Integer): Boolean;
  end;

type
  /// <summary>
  /// Queue-driven mock client. Each call dequeues a prepared response.
  /// </summary>
  TQueuedMockRpcHttpClient = class(TInterfacedObject, IHttpApiClient)
  private
    FHandler: TMyMockHttpMessageHandler;
    FBaseUrl: string;
    FLastJson: string;

    function DequeueOrDefault: IHttpApiResponse;
  public
    constructor Create(AHandler: TMyMockHttpMessageHandler; const ABaseUrl: string);

    function GetJson(const AUrl: string): IHttpApiResponse; overload;
    function GetJson(const AUrl: string; const AQuery: THttpApiQueryParams): IHttpApiResponse; overload;
    function GetJson(const AUrl: string; const AQuery: THttpApiQueryParams;
                     const AHeaders: THttpApiHeaderParams): IHttpApiResponse; overload;

    function PostJson(const AUrl: string; const AJson: string): IHttpApiResponse; overload;
    function PostJson(const AUrl, AJson: string;
                      const AHeaders: THttpApiHeaderParams): IHttpApiResponse; overload;

    property LastJson: string read FLastJson;
  end;

 type
  /// <summary>
  /// Queue-driven mock of ITokenWalletRpcProxy.
  /// Enqueue one JSON-RPC response (as text) per expected call.
  /// </summary>
  TMockTokenWalletRpcProxy = class(TInterfacedObject, ITokenWalletRpcProxy)
  strict private
    FResponses : TQueue<string>;
    FLock      : TCriticalSection;
    FReqSeqId  : Integer;
    FSerializer: TJsonSerializer;

  private
    function  BuildSerializer: TJsonSerializer;
    function  GetNextJsonResponse<T>: TJsonRpcResponse<T>;
    function  MockResponseValue<T>: TRequestResult<TResponseValue<T>>;
    function  MockValue<T>: TRequestResult<T>;

  public
    constructor Create;
    destructor Destroy; override;

    procedure AddTextFile(const AFilePath: string);

    function GetBalance(const APubKey: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<UInt64>>;
    function GetLatestBlockHash(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TLatestBlockHash>>;
    function GetTokenAccountsByOwner(const AOwnerPubKey: string; const ATokenMintPubKey: string = ''; const ATokenProgramId: string = ''; AEncoding: TBinaryEncoding = TBinaryEncoding.JsonParsed; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
    function SendTransaction(const ATransaction: TBytes; const AMaxRetries: TNullable<UInt32>; const AMinContextSlot: TNullable<UInt64>; ASkipPreflight: Boolean = False; AEncoding: TBinaryEncoding = TBinaryEncoding.Base64; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<string>;
  end;

  type
  /// <summary>
  /// Queue-driven mock of IWebSocketApiClient.
  /// - Captures sent payloads (text & binary).
  /// - Lets us tests enqueue incoming frames and trigger delivery deterministically.
  /// Invoke TriggerNext/TriggerAll in test when ready.
  /// </summary>
  TMockWebSocketApiClient = class(TInterfacedObject, IWebSocketApiClient)
  private type
    TInboundKind = (Text, Binary);
    TInboundFrame = record
      Kind : TInboundKind;
      Text : string;
      Data : TBytes;
    end;
  private
    // state
    FConnected: Boolean;
    FUrl      : string;

    // callbacks
    FOnConnect             : TProc;
    FOnDisconnect          : TProc;
    FOnReceiveTextMessage  : TProc<string>;
    FOnReceiveBinaryMessage: TProc<TBytes>;
    FOnError               : TProc<string>;
    FOnException           : TProc<Exception>;

    // captures
    FSentText   : TList<string>;
    FSentBinary : TList<TBytes>;

    // inbound queue
    FInboundQ   : TQueue<TInboundFrame>;

    procedure DoConnectCallback;
    procedure DoDisconnectCallback;
    procedure Deliver(const AFrame: TInboundFrame);

    { IWebSocketApiClient }
    function  Connected: Boolean;
    procedure Connect(const AUrl: string);
    procedure Disconnect;

    procedure Send(const AText: string); overload;
    procedure Send(const AData: TBytes); overload;

    function  GetOnConnect: TProc;
    procedure SetOnConnect(const Value: TProc);

    function  GetOnDisconnect: TProc;
    procedure SetOnDisconnect(const Value: TProc);

    function  GetOnReceiveTextMessage: TProc<string>;
    procedure SetOnReceiveTextMessage(const Value: TProc<string>);

    function  GetOnReceiveBinaryMessage: TProc<TBytes>;
    procedure SetOnReceiveBinaryMessage(const Value: TProc<TBytes>);

    function  GetOnError: TProc<string>;
    procedure SetOnError(const Value: TProc<string>);

    function  GetOnException: TProc<Exception>;
    procedure SetOnException(const Value: TProc<Exception>);

  public
    constructor Create;
    destructor Destroy; override;

    { Test helpers }

    /// <summary>Add a text frame that will be delivered to OnReceiveTextMessage.</summary>
    procedure EnqueueText(const AText: string);

    /// <summary>Add a binary frame that will be delivered to OnReceiveBinaryMessage.</summary>
    procedure EnqueueBinary(const AData: TBytes);

    /// <summary>Deliver the next queued inbound frame (if any).</summary>
    function  TriggerNext: Boolean;

    /// <summary>Deliver all queued inbound frames.</summary>
    procedure TriggerAll;

    /// <summary>Number of text payloads sent via Send(string).</summary>
    function  SentTextCount: Integer;

    /// <summary>Number of binary payloads sent via Send(TBytes).</summary>
    function  SentBinaryCount: Integer;

    /// <summary>Return last sent text ('' if none).</summary>
    function  LastSentText: string;

    /// <summary>Return a copy of the last sent binary payload (empty if none).</summary>
    function  LastSentBinary: TBytes;

    /// <summary>Return the i-th sent text (0-based).</summary>
    function  SentTextAt(Index: Integer): string;

    /// <summary>Return a copy of the i-th sent binary payload (0-based).</summary>
    function  SentBinaryAt(Index: Integer): TBytes;
  end;

implementation

{ TMockRpcHttpClient }

procedure TMockRpcHttpClient.ConfigureThrow(const AMessage: string);
begin
  FRaiseOnRequest := True;
  FStatusText   := AMessage;
end;

constructor TMockRpcHttpClient.Create(const AExpectedUrl: string;
  AStatusCode: Integer; const AStatusText, ABody: string);
begin
  inherited Create;
  FExpectedUrl    := AExpectedUrl;
  FStatusCode := AStatusCode;
  FStatusText   := AStatusText;
  FResponseBody   := ABody;
  FCallCount      := 0;
  FLastUrl        := '';
  FLastJson       := '';
  FRaiseOnRequest := False;
end;

constructor TMockRpcHttpClient.CreateForThrow(const AExpectedUrl: string; const AMessage: string);
begin
  inherited Create;
  FExpectedUrl    := AExpectedUrl;
  FStatusCode := 0;
  FStatusText   := AMessage;
  FResponseBody   := '';
  FCallCount      := 0;
  FLastUrl        := '';
  FLastJson       := '';
  FRaiseOnRequest := True;
end;

function TMockRpcHttpClient.GetJson(const AUrl: string): IHttpApiResponse;
begin
  Result := GetJson(AUrl, nil);
end;

function TMockRpcHttpClient.GetJson(const AUrl: string; const AQuery: THttpApiQueryParams): IHttpApiResponse;
begin
  Result := GetJson(AUrl, AQuery, nil);
end;

function TMockRpcHttpClient.GetJson(const AUrl: string; const AQuery: THttpApiQueryParams;
  const AHeaders: THttpApiHeaderParams): IHttpApiResponse;
var
  _ : string;
begin
   // computed but not used; kept to mirror real flow
  _ := THttpClientBase.BuildUrlWithQuery(AUrl, AQuery);
  // Headers are ignored in this simple mock;
  Inc(FCallCount);
  FLastUrl := AUrl;
  FLastJson := '';

  if FRaiseOnRequest then
    raise Exception.Create(FStatusText);

  Result := THttpApiResponse.Create(FStatusCode, FStatusText, FResponseBody);
end;

function TMockRpcHttpClient.PostJson(const AUrl, AJson: string): IHttpApiResponse;
begin
    // Headers are ignored by this mock
  Result := PostJson(AUrl, AJson, nil);
end;

function TMockRpcHttpClient.PostJson(const AUrl, AJson: string;
  const AHeaders: THttpApiHeaderParams): IHttpApiResponse;
begin
  Inc(FCallCount);
  FLastUrl  := AUrl;
  FLastJson := AJson;
  if FRaiseOnRequest then
    raise Exception.Create(FStatusText);

  Result := THttpApiResponse.Create(FStatusCode, FStatusText, FResponseBody);
end;

{ TMyMockHttpMessageHandler }

constructor TMyMockHttpMessageHandler.Create;
begin
  inherited Create;
  FQueue := TQueue<TReqResp>.Create;
end;

destructor TMyMockHttpMessageHandler.Destroy;
begin
  FQueue.Free;
  inherited;
end;

procedure TMyMockHttpMessageHandler.Add(const ExpectedRequests, ExpectedResponses: string; const Status: Integer);
var
  R: TReqResp;
begin
  R.ExpectedRequest := ExpectedRequests;
  R.Response        := ExpectedResponses;
  R.Status          := Status;
  FQueue.Enqueue(R);
end;

function TMyMockHttpMessageHandler.Dequeue(out ExpectedRequests, ExpectedResponses: string; out Status: Integer): Boolean;
var
  R: TReqResp;
begin
  Result := False;
  if FQueue.Count = 0 then Exit;
  R := FQueue.Dequeue;
  ExpectedRequests  := R.ExpectedRequest;
  ExpectedResponses := R.Response;
  Status            := R.Status;
  Result := True;
end;

{ TQueuedMockRpcHttpClient }

constructor TQueuedMockRpcHttpClient.Create(AHandler: TMyMockHttpMessageHandler; const ABaseUrl: string);
begin
  inherited Create;
  FHandler := AHandler;
  FBaseUrl := ABaseUrl;
  FLastJson := '';
end;

function TQueuedMockRpcHttpClient.DequeueOrDefault: IHttpApiResponse;
var
  ExpectedReq, ExpectedResp: string;
  Status: Integer;
begin
  if not FHandler.Dequeue(ExpectedReq, ExpectedResp, Status) then
    Exit(THttpApiResponse.Create(500, 'Failure', '{"error":"No queued mock response"}'));
  Result := THttpApiResponse.Create(Status, 'Success', ExpectedResp);
end;

function TQueuedMockRpcHttpClient.GetJson(const AUrl: string): IHttpApiResponse;
begin
  Result := GetJson(AUrl, nil);
end;

function TQueuedMockRpcHttpClient.GetJson(const AUrl: string; const AQuery: THttpApiQueryParams): IHttpApiResponse;
begin
  Result := GetJson(AUrl, AQuery, nil);
end;

function TQueuedMockRpcHttpClient.GetJson(const AUrl: string; const AQuery: THttpApiQueryParams;
  const AHeaders: THttpApiHeaderParams): IHttpApiResponse;
var
  _ : string;
begin
  // computed but not used; kept to mirror real flow
  _ := THttpClientBase.BuildUrlWithQuery(AUrl, AQuery);
   // headers ignored in this mock
  Result := DequeueOrDefault;
end;

function TQueuedMockRpcHttpClient.PostJson(const AUrl, AJson: string): IHttpApiResponse;
begin
  Result := PostJson(AUrl, AJson, nil);
end;

function TQueuedMockRpcHttpClient.PostJson(const AUrl, AJson: string;
  const AHeaders: THttpApiHeaderParams): IHttpApiResponse;
begin
  // headers ignored in this mock
  FLastJson := AJson;
  Result := DequeueOrDefault;
end;

{ TMockTokenWalletRpc }

constructor TMockTokenWalletRpcProxy.Create;
begin
  inherited Create;
  FReqSeqId   := 0;
  FResponses  := TQueue<string>.Create;
  FLock       := TCriticalSection.Create;
  FSerializer := BuildSerializer;
end;

destructor TMockTokenWalletRpcProxy.Destroy;
var
  I: Integer;
  _: string;
begin
  // drain queue
  if Assigned(FResponses) then
  begin
    while FResponses.Count > 0 do
      _ := FResponses.Dequeue;
    FResponses.Free;
  end;

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

  FLock.Free;

  inherited;
end;

function TMockTokenWalletRpcProxy.BuildSerializer: TJsonSerializer;
var
  Converters: TList<TJsonConverter>;
begin
  Converters := TJsonConverterFactory.GetRpcConverters();
  try
    Converters.Add(TEncodingConverter.Create);
    Converters.Add(TJsonStringEnumConverter.Create(TJsonNamingPolicy.CamelCase));

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

procedure TMockTokenWalletRpcProxy.AddTextFile(const AFilePath: string);
begin
  FResponses.Enqueue(TestUtils.TTestUtils.ReadAllText(AFilePath, TEncoding.UTF8));
end;

function TMockTokenWalletRpcProxy.GetNextJsonResponse<T>: TJsonRpcResponse<T>;
var
  LJson: string;
  LId: Integer;
  LResp: TJsonRpcResponse<T>;
begin
  if FResponses.Count = 0 then
    raise Exception.Create('Mock responses exhausted');

  FLock.Acquire;
  try
    Inc(FReqSeqId);
    LId := FReqSeqId;
    LJson := FResponses.Dequeue;
  finally
    FLock.Release;
  end;

  // deserialize JSON RPC response
  LResp := FSerializer.Deserialize<TJsonRpcResponse<T>>(LJson);
  if LResp = nil then
    raise Exception.Create('Mock response did not deserialize');

  // overwrite RPC Id to a deterministic sequence
  LResp.Id := LId;
  Result := LResp;
end;

function TMockTokenWalletRpcProxy.MockResponseValue<T>: TRequestResult<TResponseValue<T>>;
var
  LEnv: TJsonRpcResponse<TResponseValue<T>>;
begin
  LEnv := nil;
  try
    LEnv := GetNextJsonResponse<TResponseValue<T>>();

    // Package success and transfer ownership of the inner Result
    Result := TRequestResult<TResponseValue<T>>.Create();
    Result.WasHttpRequestSuccessful := True;
    Result.WasRequestSuccessfullyHandled := True;
    Result.HttpStatusCode := 200;

    // take ownership of payload, then null out wrapper to avoid double free/release
    Result.Result := LEnv.Result;
    LEnv.Result := nil;
  finally
    if Assigned(LEnv) then
      LEnv.Free;
  end;
end;

function TMockTokenWalletRpcProxy.MockValue<T>: TRequestResult<T>;
var
  LEnv: TJsonRpcResponse<T>;
begin
  LEnv := nil;
  try
    LEnv := GetNextJsonResponse<T>();

    // Package success and transfer ownership of the inner Result
    Result := TRequestResult<T>.Create();
    Result.WasHttpRequestSuccessful := True;
    Result.WasRequestSuccessfullyHandled := True;
    Result.HttpStatusCode := 200;

    // take ownership of payload, then null out wrapper to avoid double free/release
    Result.Result := LEnv.Result;
    LEnv.Result := Default(T);
  finally
    if Assigned(LEnv) then
      LEnv.Free;
  end;
end;

function TMockTokenWalletRpcProxy.GetBalance(
  const APubKey: string; ACommitment: TCommitment): TRequestResult<TResponseValue<UInt64>>;
begin
  Result := MockResponseValue<UInt64>;
end;

function TMockTokenWalletRpcProxy.GetLatestBlockHash(
  ACommitment: TCommitment): TRequestResult<TResponseValue<TLatestBlockHash>>;
begin
  Result := MockResponseValue<TLatestBlockHash>;
end;

function TMockTokenWalletRpcProxy.GetTokenAccountsByOwner(
  const AOwnerPubKey, ATokenMintPubKey, ATokenProgramId: string;
  AEncoding: TBinaryEncoding; ACommitment: TCommitment): TRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
begin
  Result := MockResponseValue<TObjectList<TTokenAccount>>;
end;

function TMockTokenWalletRpcProxy.SendTransaction(
  const ATransaction: TBytes;  const AMaxRetries: TNullable<UInt32>; const AMinContextSlot: TNullable<UInt64>;
  ASkipPreflight: Boolean; AEncoding: TBinaryEncoding; ACommitment: TCommitment): TRequestResult<string>;
begin
  Result := MockValue<string>;
end;


{ TMockWebSocketApiClient }

constructor TMockWebSocketApiClient.Create;
begin
  inherited Create;
  FConnected  := False;
  FUrl        := '';
  FSentText   := TList<string>.Create;
  FSentBinary := TList<TBytes>.Create;
  FInboundQ   := TQueue<TInboundFrame>.Create;
end;

destructor TMockWebSocketApiClient.Destroy;
begin
  FInboundQ.Free;
  FSentBinary.Free;
  FSentText.Free;
  inherited;
end;

function TMockWebSocketApiClient.Connected: Boolean;
begin
  Result := FConnected;
end;

procedure TMockWebSocketApiClient.Connect(const AUrl: string);
begin
  FUrl       := AUrl;
  FConnected := True;
  DoConnectCallback;
end;

procedure TMockWebSocketApiClient.Disconnect;
begin
  if not FConnected then Exit;
  FConnected := False;
  DoDisconnectCallback;
end;

procedure TMockWebSocketApiClient.Send(const AText: string);
begin
  // capture outbound text exactly as sent (for later assertions)
  FSentText.Add(AText);
  // no immediate echo/delivery here�tests control inbound via Enqueue* + Trigger*
end;

procedure TMockWebSocketApiClient.Send(const AData: TBytes);
var
  CopyB: TBytes;
begin
  // capture outbound binary (store a copy for safety)
  CopyB := System.Copy(AData, 0, Length(AData));
  FSentBinary.Add(CopyB);
end;

procedure TMockWebSocketApiClient.EnqueueText(const AText: string);
var
  F: TInboundFrame;
begin
  F.Kind := Text;
  F.Text := AText;
  F.Data := nil;
  FInboundQ.Enqueue(F);
end;

procedure TMockWebSocketApiClient.EnqueueBinary(const AData: TBytes);
var
  F: TInboundFrame;
begin
  F.Kind := Binary;
  F.Text := '';
  F.Data := System.Copy(AData, 0, Length(AData));
  FInboundQ.Enqueue(F);
end;

function TMockWebSocketApiClient.TriggerNext: Boolean;
var
  F: TInboundFrame;
begin
  Result := False;
  if FInboundQ.Count = 0 then Exit;
  F := FInboundQ.Dequeue;
  Deliver(F);
  Result := True;
end;

procedure TMockWebSocketApiClient.TriggerAll;
begin
  while TriggerNext do ;
end;

function TMockWebSocketApiClient.SentTextCount: Integer;
begin
  Result := FSentText.Count;
end;

function TMockWebSocketApiClient.SentBinaryCount: Integer;
begin
  Result := FSentBinary.Count;
end;

function TMockWebSocketApiClient.LastSentText: string;
begin
  if FSentText.Count = 0 then
    Exit('');
  Result := FSentText[FSentText.Count - 1];
end;

function TMockWebSocketApiClient.LastSentBinary: TBytes;
begin
  if FSentBinary.Count = 0 then
    Exit(nil);
  Result := System.Copy(FSentBinary[FSentBinary.Count - 1], 0,
                        Length(FSentBinary[FSentBinary.Count - 1]));
end;

function TMockWebSocketApiClient.SentTextAt(Index: Integer): string;
begin
  Result := FSentText[Index];
end;

function TMockWebSocketApiClient.SentBinaryAt(Index: Integer): TBytes;
begin
  Result := System.Copy(FSentBinary[Index], 0, Length(FSentBinary[Index]));
end;

procedure TMockWebSocketApiClient.DoConnectCallback;
begin
  if Assigned(FOnConnect) then
    FOnConnect();
end;

procedure TMockWebSocketApiClient.DoDisconnectCallback;
begin
  if Assigned(FOnDisconnect) then
    FOnDisconnect();
end;

procedure TMockWebSocketApiClient.Deliver(const AFrame: TInboundFrame);
begin
  case AFrame.Kind of
    Text:
      if Assigned(FOnReceiveTextMessage) then
        FOnReceiveTextMessage(AFrame.Text);
    Binary:
      if Assigned(FOnReceiveBinaryMessage) then
        FOnReceiveBinaryMessage(AFrame.Data);
  end;
end;

{ Getters/Setters }

function TMockWebSocketApiClient.GetOnConnect: TProc;
begin
  Result := FOnConnect;
end;

procedure TMockWebSocketApiClient.SetOnConnect(const Value: TProc);
begin
  FOnConnect := Value;
end;

function TMockWebSocketApiClient.GetOnDisconnect: TProc;
begin
  Result := FOnDisconnect;
end;

procedure TMockWebSocketApiClient.SetOnDisconnect(const Value: TProc);
begin
  FOnDisconnect := Value;
end;

function TMockWebSocketApiClient.GetOnReceiveTextMessage: TProc<string>;
begin
  Result := FOnReceiveTextMessage;
end;

procedure TMockWebSocketApiClient.SetOnReceiveTextMessage(const Value: TProc<string>);
begin
  FOnReceiveTextMessage := Value;
end;

function TMockWebSocketApiClient.GetOnReceiveBinaryMessage: TProc<TBytes>;
begin
  Result := FOnReceiveBinaryMessage;
end;

procedure TMockWebSocketApiClient.SetOnReceiveBinaryMessage(const Value: TProc<TBytes>);
begin
  FOnReceiveBinaryMessage := Value;
end;

function TMockWebSocketApiClient.GetOnError: TProc<string>;
begin
  Result := FOnError;
end;

procedure TMockWebSocketApiClient.SetOnError(const Value: TProc<string>);
begin
  FOnError := Value;
end;

function TMockWebSocketApiClient.GetOnException: TProc<Exception>;
begin
  Result := FOnException;
end;

procedure TMockWebSocketApiClient.SetOnException(const Value: TProc<Exception>);
begin
  FOnException := Value;
end;

end.

