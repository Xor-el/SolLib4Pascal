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

unit SolanaStreamingRpcClientTests;

interface

uses
  System.SysUtils,
  System.SyncObjs,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpRpcEnum,
  SlpWebSocketApiClient,
  SlpRpcMessage,
  SlpRpcModel,
  SlpSubscriptionEvent,
  SlpSolanaStreamingRpcClient,
  SlpNullable,
  RpcClientMocks,
  SolLibStreamingRpcClientTestCase;

type
  TSolanaStreamingRpcClientTests = class(TSolLibStreamingRpcClientTestCase)
  published
    procedure TestCallbacksAreSetup;
    procedure TestSubscribeAccountInfo;
    procedure TestSubscribeTokenAccount;
    procedure TestSubscribeAccountInfoProcessed;
    procedure TestUnsubscribe;
    procedure TestSubscribeLogsMention;
    procedure TestSubscribeLogsMentionConfirmed;
    procedure TestSubscribeLogsAll;
    procedure TestSubscribeLogsAllProcessed;
    procedure TestSubscribeLogsWithErrors;
    procedure TestSubscribeProgram;
    procedure TestSubscribeProgramFilters;
    procedure TestSubscribeProgramMemcmpFilters;
    procedure TestSubscribeProgramDataFilter;
    procedure TestSubscribeProgramConfirmed;
    procedure TestSubscribeSlotInfo;
    procedure TestSubscribeRoot;
    procedure TestSubscribeSignature;
    procedure TestSubscribeSignature_ErrorNotification;
    procedure TestSubscribeSignature_Processed;
    procedure TestSubscribeBadAccount;
    procedure TestSubscribeAccountBigPayload;
  end;

implementation

{ TSolanaRpcStreamingClientTests }

procedure TSolanaStreamingRpcClientTests.TestCallbacksAreSetup;
var
  LWs           : TMockWebSocketApiClient;
  LWsIntf       : IWebSocketApiClient;
  LSut          : IStreamingRpcClient;
begin
  // Arrange: mock WS + real LSut
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  AssertTrue(Assigned(LWsIntf.OnConnect),    'OnConnect not wired');
  AssertTrue(Assigned(LWsIntf.OnDisconnect),    'OnDisconnect not wired');
  AssertTrue(Assigned(LWsIntf.OnReceiveTextMessage),   'OnReceiveTextMessage not wired');
  AssertTrue(Assigned(LWsIntf.OnReceiveBinaryMessage),     'OnReceiveBinaryMessage not wired');
  AssertTrue(Assigned(LWsIntf.OnError),     'OnError not wired');
  AssertTrue(Assigned(LWsIntf.OnException),     'OnException not wired');
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeAccountInfo;
var
  LWs: TMockWebSocketApiClient;
  LWsIntf: IWebSocketApiClient;
  LSut: IStreamingRpcClient;
  LPubKey: string;
  LExpectedSend: string;
  LSubConfirm: string;
  LNotification: string;
  LSubscriptionState: ISubscriptionState;
  // captured values from the callback
  LCallbackNotified: Boolean;
  LCallbackSlot: UInt64;
  LCallbackOwner: string;
  LCallbackLamports: UInt64;
  LCallbackRentEpoch: UInt64;
  LCallbackExecutable: Boolean;
begin
  // Arrange: mock WS + real LSut
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  // Prepare frames
  LExpectedSend := LoadTestData('Account/AccountSubscribe.json');
  LSubConfirm := LoadTestData('SubscribeConfirm.json');
  LNotification := LoadTestData('Account/AccountSubscribeNotification.json');

  LWs.EnqueueText(LSubConfirm);
  LWs.EnqueueText(LNotification);

  LPubKey := 'CM78CPUeXjn8o3yroDHxUtKsZZgoy4GPkPPXfouKNH12';

  LCallbackExecutable := True;  // will flip to False from payload
  // Act
  LSut.Connect;

  LSubscriptionState := LSut.SubscribeAccountInfo(
    LPubKey,
    procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TAccountInfo>)
    begin
      // Capture callback values for assertions
      if (AResponse <> nil) and (AResponse.Context <> nil) then
        LCallbackSlot := AResponse.Context.Slot;

      if (AResponse <> nil) and (AResponse.Value <> nil) then
      begin
        LCallbackOwner      := AResponse.Value.Owner;
        LCallbackLamports   := AResponse.Value.Lamports;
        LCallbackRentEpoch  := AResponse.Value.RentEpoch;
        LCallbackExecutable := AResponse.Value.Executable;
      end;

      LCallbackNotified := True;

      if ASubscriptionState <> nil then
        ASubscriptionState.Unsubscribe;
    end
  );

  AssertNotNull(LSubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirm + notification
  LWs.TriggerAll;

  AssertTrue(LCallbackNotified, 'Notification callback did not fire');
  AssertEquals(5199307, LCallbackSlot, 'Context.Slot mismatch');
  AssertEquals('11111111111111111111111111111111', LCallbackOwner, 'Owner mismatch');
  AssertEquals(33594, LCallbackLamports, 'Lamports mismatch');
  AssertEquals(635, LCallbackRentEpoch, 'RentEpoch mismatch');
  AssertFalse(LCallbackExecutable, 'Executable mismatch');

  // Teardown
  LSut.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeTokenAccount;
var
  LWs                 : TMockWebSocketApiClient;
  LWsIntf             : IWebSocketApiClient;
  LSut                : IStreamingRpcClient;
  LPubKey             : string;
  LExpectedSend       : string;
  LSubConfirm         : string;
  LNotification       : string;
  LSubscriptionState  : ISubscriptionState;
  // captured values from the callback
  LCallbackNotified   : Boolean;
  LCallbackSlot       : UInt64;
  LCallbackOwner      : string;
  LCallbackLamports   : UInt64;
  LCallbackTokenOwner : string;
  LCallbackAmount     : string;
  LCallbackUiAmount   : string;
  LCallbackDecimals   : Integer;
  LTokenAccountData: TTokenAccountData;
begin
  // Arrange: mock WS + real LSut
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  // Prepare frames
  LExpectedSend := LoadTestData('Account/TokenAccountSubscribe.json');
  LSubConfirm := LoadTestData('SubscribeConfirm.json');
  LNotification := LoadTestData('Account/TokenAccountSubscribeNotification.json');

  LWs.EnqueueText(LSubConfirm);
  LWs.EnqueueText(LNotification);

  LPubKey := 'CM78CPUeXjn8o3yroDHxUtKsZZgoy4GPkPPXfouKNH12';

  // Act
  LSut.Connect;

  LSubscriptionState := LSut.SubscribeTokenAccount(
    LPubKey,
    procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TTokenAccountInfo>)
    begin
      if (AResponse <> nil) and (AResponse.Context <> nil) then
        LCallbackSlot := AResponse.Context.Slot;

      if (AResponse <> nil) and (AResponse.Value <> nil) then
      begin
        LCallbackOwner    := AResponse.Value.Owner;
        LCallbackLamports := AResponse.Value.Lamports;

        LTokenAccountData := AResponse.Value.Data.AsType<TTokenAccountData>;

        if (LTokenAccountData <> nil) and
           (LTokenAccountData.Parsed <> nil) and
           (LTokenAccountData.Parsed.Info <> nil) and
           (LTokenAccountData.Parsed.Info.TokenAmount <> nil) then
        begin
          LCallbackTokenOwner := LTokenAccountData.Parsed.Info.Owner;
          LCallbackAmount     := LTokenAccountData.Parsed.Info.TokenAmount.Amount;
          LCallbackUiAmount   := LTokenAccountData.Parsed.Info.TokenAmount.UiAmountString;
          LCallbackDecimals   := LTokenAccountData.Parsed.Info.TokenAmount.Decimals;
        end;
      end;

      LCallbackNotified := True;

      if ASubscriptionState <> nil then
        ASubscriptionState.Unsubscribe;
    end
  );

  // Assert subscribe request
  AssertNotNull(LSubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirm + notification
  LWs.TriggerAll;

  AssertTrue(LCallbackNotified, 'Notification callback did not fire');
  AssertEquals(99118135, LCallbackSlot, 'Context.Slot mismatch');
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LCallbackOwner, 'Owner mismatch');
  AssertEquals('F8Vyqk3unwxkXukZFQeYyGmFfTG3CAX4v24iyrjEYBJV', LCallbackTokenOwner, 'Parsed.Info.Owner mismatch');
  AssertEquals('9830001302037', LCallbackAmount, 'TokenAmount.Amount mismatch');
  AssertEquals('9830001.302037', LCallbackUiAmount, 'TokenAmount.UiAmountString mismatch');
  AssertEquals(6, LCallbackDecimals, 'TokenAmount.Decimals mismatch');
  AssertEquals(2039280, LCallbackLamports, 'Lamports mismatch');

  // Teardown
  LSut.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeAccountInfoProcessed;
var
  LWs                 : TMockWebSocketApiClient;
  LWsIntf             : IWebSocketApiClient;
  LSut                : IStreamingRpcClient;
  LPubKey             : string;
  LExpectedSend       : string;
  LSubConfirm         : string;
  LNotification       : string;
  LSubscriptionState  : ISubscriptionState;
  // captured values from the callback
  LCallbackNotified   : Boolean;
  LCallbackSlot       : UInt64;
  LCallbackOwner      : string;
  LCallbackLamports   : UInt64;
  LCallbackRentEpoch  : UInt64;
  LCallbackExecutable : Boolean;
begin
  // Arrange: mock WS + real LSut
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  // Prepare frames: subscription confirm, then notification
  LExpectedSend := LoadTestData('Account/AccountSubscribeProcessed.json');
  LSubConfirm := LoadTestData('SubscribeConfirm.json');
  LNotification := LoadTestData('Account/AccountSubscribeNotification.json');

  LWs.EnqueueText(LSubConfirm);
  LWs.EnqueueText(LNotification);

  LPubKey := 'CM78CPUeXjn8o3yroDHxUtKsZZgoy4GPkPPXfouKNH12';

  // Act
  LSut.Connect;

  LSubscriptionState := LSut.SubscribeAccountInfo(
    LPubKey,
    procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TAccountInfo>)
    begin
      if (AResponse <> nil) and (AResponse.Context <> nil) then
        LCallbackSlot := AResponse.Context.Slot;

      if (AResponse <> nil) and (AResponse.Value <> nil) then
      begin
        LCallbackOwner      := AResponse.Value.Owner;
        LCallbackLamports   := AResponse.Value.Lamports;
        LCallbackRentEpoch  := AResponse.Value.RentEpoch;
        LCallbackExecutable := AResponse.Value.Executable;
      end;

      LCallbackNotified := True;

      if ASubscriptionState <> nil then
        ASubscriptionState.Unsubscribe;
    end,
    TCommitment.Processed
  );

  // Assert subscribe request
  AssertNotNull(LSubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirm + notification
  LWs.TriggerAll;

  AssertTrue(LCallbackNotified, 'Notification callback did not fire');
  AssertEquals(5199307, LCallbackSlot, 'Context.Slot mismatch');
  AssertEquals('11111111111111111111111111111111', LCallbackOwner, 'Owner mismatch');
  AssertEquals(33594, LCallbackLamports, 'Lamports mismatch');
  AssertEquals(635, LCallbackRentEpoch, 'RentEpoch mismatch');
  AssertFalse(LCallbackExecutable, 'Executable mismatch');

  // Teardown
  LSut.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestUnsubscribe;
var
  LWs                : TMockWebSocketApiClient;
  LWsIntf            : IWebSocketApiClient;
  LSut               : IStreamingRpcClient;
  LPubKey            : string;
  LSubConfirm        : string;
  LUnsubResponse     : string;
  LSub               : ISubscriptionState;
  LUnsubscribed      : Boolean;
  LWaitUnsubscribed  : TEvent;
begin
  // Arrange: mock WS + real LSut
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  // Frames (deliver in two phases)
  LSubConfirm    := LoadTestData('SubscribeConfirm.json');
  LUnsubResponse := LoadTestData('Account/AccountSubUnsubscription.json');

  // Phase 1: only the subscription confirmation
  LWs.EnqueueText(LSubConfirm);

  LPubKey := 'CM78CPUeXjn8o3yroDHxUtKsZZgoy4GPkPPXfouKNH12';

  LUnsubscribed := False;
  LWaitUnsubscribed := TEvent.Create(nil, True, False, '');
  try
    // Act
    LSut.Connect;

    // Subscribe
    LSub := LSut.SubscribeAccountInfo(
      LPubKey,
      procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TAccountInfo>)
      begin
        // no-op for this test
      end
    );

    // Deliver the subscribe-confirm frame so SubscriptionId is set and state is Subscribed
    LWs.TriggerAll;

    // Observe state changes; notify when Unsubscribed
    LSub.AddSubscriptionChanged(
      procedure(ASubscriptionState: ISubscriptionState; AEvent: ISubscriptionEvent)
      begin
        if (AEvent <> nil) and (AEvent.Status = TSubscriptionStatus.Unsubscribed) then
        begin
          LUnsubscribed := True;
          LWaitUnsubscribed.SetEvent;
        end;
      end
    );

    // Request unsubscription (client will send *Unsubscribe with current SubscriptionId)
    LSub.Unsubscribe;

    // Phase 2: deliver the server's boolean result for unsubscribe
    LWs.EnqueueText(LUnsubResponse);
    LWs.TriggerAll;

    // Assert we observed the Unsubscribed state transition
    AssertEquals(Ord(TWaitResult.wrSignaled), Ord(LWaitUnsubscribed.WaitFor(3000)), 'Unsubscribe signal not observed');
    AssertTrue(LUnsubscribed, 'Subscription did not reach Unsubscribed state');
  finally
    LWaitUnsubscribed.Free;
    LSut.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeLogsMention;
var
  LWs                : TMockWebSocketApiClient;
  LWsIntf            : IWebSocketApiClient;
  LSut               : IStreamingRpcClient;
  LPubKey            : string;
  LExpectedSend      : string;
  LSubConfirm        : string;
  LSubscriptionState : ISubscriptionState;
begin
  // Arrange: mock WS + real LSut
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  // Expected subscribe payload and confirm frame
  LExpectedSend := LoadTestData('Logs/LogsSubscribeMention.json');
  LSubConfirm := LoadTestData('SubscribeConfirm.json');

  // Only confirmation (no notification needed for this test)
  LWs.EnqueueText(LSubConfirm);

  LPubKey := '11111111111111111111111111111111';

  // Act
  LSut.Connect;

  LSubscriptionState := LSut.SubscribeLogInfo(
    LPubKey,
    procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TLogInfo>)
    begin

    end
  );

  // Assert the subscribe request sent to the socket
  AssertNotNull(LSubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver the confirmation frame
  LWs.TriggerAll;

  // Teardown
  LSut.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeLogsMentionConfirmed;
var
  LWs                : TMockWebSocketApiClient;
  LWsIntf            : IWebSocketApiClient;
  LSut               : IStreamingRpcClient;
  LPubKey            : string;
  LExpectedSend      : string;
  LSubConfirm        : string;
  LSubscriptionState : ISubscriptionState;
begin
  // Arrange: mock WS + real LSut
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  // Expected subscribe payload (with commitment=confirmed) and confirm frame
  LExpectedSend := LoadTestData('Logs/LogsSubscribeMentionConfirmed.json');
  LSubConfirm := LoadTestData('SubscribeConfirm.json');

  // Only confirmation
  LWs.EnqueueText(LSubConfirm);

  LPubKey := '11111111111111111111111111111111';

  // Act
  LSut.Connect;

  LSubscriptionState := LSut.SubscribeLogInfo(
    LPubKey,
    procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TLogInfo>)
    begin

    end,
    TCommitment.Confirmed
  );

  // Assert the subscribe request sent to the socket
  AssertNotNull(LSubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirmation frame
  LWs.TriggerAll;

  // Teardown
  LSut.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeLogsAll;
var
  LWs                 : TMockWebSocketApiClient;
  LWsIntf             : IWebSocketApiClient;
  LSut                : IStreamingRpcClient;
  LExpectedSend       : string;
  LSubConfirm         : string;
  LNotification       : string;
  LSubscriptionState  : ISubscriptionState;

  // captured from callback
  LCallbackNotified   : Boolean;
  LCallbackSlot       : UInt64;
  LCallbackSignature  : string;
  LCallbackHasError   : Boolean;
  LCallbackFirstLog   : string;
begin
  // Arrange: mock WS + real LSut
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  // Expected outgoing subscribe payload and incoming frames
  LExpectedSend := LoadTestData('Logs/LogsSubscribeAll.json');
  LSubConfirm := LoadTestData('SubscribeConfirm.json');
  LNotification := LoadTestData('Logs/LogsSubscribeNotification.json');

  // Queue: confirmation then notification
  LWs.EnqueueText(LSubConfirm);
  LWs.EnqueueText(LNotification);

  LCallbackHasError  := True; // default true, will flip to false if nil

  // Act
  LSut.Connect;

  LSubscriptionState := LSut.SubscribeLogInfo(
    TLogsSubscriptionType.All,
    procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TLogInfo>)
    begin
      if (AResponse <> nil) and (AResponse.Context <> nil) then
        LCallbackSlot := AResponse.Context.Slot;

      if (AResponse <> nil) and (AResponse.Value <> nil) then
      begin
        LCallbackSignature := AResponse.Value.Signature;
        LCallbackHasError  := (AResponse.Value.Error <> nil);
        if (Length(AResponse.Value.Logs) > 0) then
          LCallbackFirstLog := AResponse.Value.Logs[0];
      end;

      LCallbackNotified := True;

      if ASubscriptionState <> nil then
        ASubscriptionState.Unsubscribe;
    end
  );

  // Assert request sent
  AssertNotNull(LSubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirm + notification
  LWs.TriggerAll;

  AssertTrue(LCallbackNotified, 'Notification callback did not fire');
  AssertEquals(5208469, LCallbackSlot, 'Context.Slot mismatch');
  AssertEquals(
    '5h6xBEauJ3PK6SWCZ1PGjBvj8vDdWG3KpwATGy1ARAXFSDwt8GFXM7W5Ncn16wmqokgpiKRLuS83KUxyZyv2sUYv',
    LCallbackSignature,
    'Signature mismatch'
  );
  AssertFalse(LCallbackHasError, 'Expected no error in log notification');
  AssertEquals(
    'BPF program 83astBRguLMdt2h5U1Tpdq5tjFoJ6noeGwaY3mDLVcri success',
    LCallbackFirstLog,
    'First log line mismatch'
  );

  // Teardown
  LSut.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeLogsAllProcessed;
var
  LWs                 : TMockWebSocketApiClient;
  LWsIntf             : IWebSocketApiClient;
  LSut                : IStreamingRpcClient;
  LExpectedSend       : string;
  LSubConfirm         : string;
  LNotification       : string;
  LSubscriptionState  : ISubscriptionState;

  // captured from callback
  LCallbackNotified   : Boolean;
  LCallbackSlot       : UInt64;
  LCallbackSignature  : string;
  LCallbackHasError   : Boolean;
  LCallbackFirstLog   : string;
begin
  // Arrange: mock WS + real LSut
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  // Expected outgoing subscribe payload (commitment=processed) and incoming frames
  LExpectedSend := LoadTestData('Logs/LogsSubscribeAllProcessed.json');
  LSubConfirm := LoadTestData('SubscribeConfirm.json');
  LNotification := LoadTestData('Logs/LogsSubscribeNotification.json');

  // Queue: confirmation then notification
  LWs.EnqueueText(LSubConfirm);
  LWs.EnqueueText(LNotification);

  LCallbackHasError  := True; // will flip to False when Error = nil

  // Act
  LSut.Connect;

  LSubscriptionState := LSut.SubscribeLogInfo(
    TLogsSubscriptionType.All,
    procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TLogInfo>)
    begin
      if (AResponse <> nil) and (AResponse.Context <> nil) then
        LCallbackSlot := AResponse.Context.Slot;

      if (AResponse <> nil) and (AResponse.Value <> nil) then
      begin
        LCallbackSignature := AResponse.Value.Signature;
        LCallbackHasError  := (AResponse.Value.Error <> nil);
        if Length(AResponse.Value.Logs) > 0 then
          LCallbackFirstLog := AResponse.Value.Logs[0];
      end;

      LCallbackNotified := True;

      // optional: clean up subscription after first notification
      if ASubscriptionState <> nil then
        ASubscriptionState.Unsubscribe;
    end,
    TCommitment.Processed
  );

  // Assert the subscribe request sent to the socket
  AssertNotNull(LSubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirm + notification
  LWs.TriggerAll;

  // Assert callback & payload fields
  AssertTrue(LCallbackNotified, 'Notification callback did not fire');
  AssertEquals(5208469, LCallbackSlot, 'Context.Slot mismatch');
  AssertEquals(
    '5h6xBEauJ3PK6SWCZ1PGjBvj8vDdWG3KpwATGy1ARAXFSDwt8GFXM7W5Ncn16wmqokgpiKRLuS83KUxyZyv2sUYv',
    LCallbackSignature,
    'Signature mismatch'
  );
  AssertFalse(LCallbackHasError, 'Expected no error in log notification');
  AssertEquals(
    'BPF program 83astBRguLMdt2h5U1Tpdq5tjFoJ6noeGwaY3mDLVcri success',
    LCallbackFirstLog,
    'First log line mismatch'
  );

  // Teardown
  LSut.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeLogsWithErrors;
var
  LWs                 : TMockWebSocketApiClient;
  LWsIntf             : IWebSocketApiClient;
  LSut                : IStreamingRpcClient;
  LExpectedSend       : string;
  LSubConfirm         : string;
  LNotification       : string;
  LSubscriptionState  : ISubscriptionState;

  // captured from callback
  LCallbackNotified   : Boolean;
  LCallbackErrorType  : TTransactionErrorType;
  LCallbackInstrType  : TInstructionErrorType;
  LCallbackCustomErr  : TNullable<UInt32>;
  LCallbackSignature  : string;
begin
  // Arrange: mock WS + real LSut
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  // Expected outgoing subscribe payload (commitment=processed) and incoming frames (with error)
  LExpectedSend := LoadTestData('Logs/LogsSubscribeAllProcessed.json');
  LSubConfirm := LoadTestData('SubscribeConfirm.json');
  LNotification := LoadTestData('Logs/LogsSubscribeNotificationWithError.json');

  // Queue: confirmation then error notification
  LWs.EnqueueText(LSubConfirm);
  LWs.EnqueueText(LNotification);

  // Act
  LSut.Connect;

  LSubscriptionState := LSut.SubscribeLogInfo(
    TLogsSubscriptionType.All,
    procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TLogInfo>)
    begin
      if (AResponse <> nil) and (AResponse.Value <> nil) then
      begin
        if Assigned(AResponse.Value.Error) then
        begin
          LCallbackErrorType := AResponse.Value.Error.&Type;
          if Assigned(AResponse.Value.Error.InstructionError) then
          begin
            LCallbackInstrType := AResponse.Value.Error.InstructionError.&Type;
            LCallbackCustomErr := AResponse.Value.Error.InstructionError.CustomError;
          end;
        end;
        LCallbackSignature := AResponse.Value.Signature;
      end;

      LCallbackNotified := True;

      // optional: end after first notification
      if ASubscriptionState <> nil then
        ASubscriptionState.Unsubscribe;
    end,
    TCommitment.Processed
  );

  AssertNotNull(LSubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirm + notification (with error)
  LWs.TriggerAll;

  AssertTrue(LCallbackNotified, 'Notification callback did not fire');

  AssertEquals(
    Ord(TTransactionErrorType.InstructionError),
    Ord(LCallbackErrorType),
    'TransactionErrorType mismatch'
  );
  AssertEquals(
    Ord(TInstructionErrorType.Custom),
    Ord(LCallbackInstrType),
    'InstructionErrorType mismatch'
  );
  AssertEquals(41, LCallbackCustomErr.Value, 'CustomError code mismatch');

  AssertEquals(
    'bGNVGCa1WFchzJStauKFVk7anzuFvA7hkMcx8Zi2o4euJaivzpwz8346yJ4Xn8H7XzMp44coTxdcDRd9d4yzj4m',
    LCallbackSignature,
    'Signature mismatch'
  );

  // Teardown
  LSut.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeProgram;
var
  LWs                : TMockWebSocketApiClient;
  LWsIntf            : IWebSocketApiClient;
  LSut               : IStreamingRpcClient;
  LExpectedSend      : string;
  LSubConfirm        : string;
  LNotification      : string;
  LSubscriptionState : ISubscriptionState;

  // captured from callback
  LCallbackNotified  : Boolean;
  LCallbackSlot      : UInt64;
  LCallbackPubKey    : string;
  LCallbackOwner     : string;
  LCallbackExecutable: Boolean;
  LCallbackRentEpoch : UInt64;
  LCallbackLamports  : UInt64;
begin
  // Arrange: mock WS + real LSut
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  // Expected outgoing subscribe payload and incoming frames
  LExpectedSend := LoadTestData('Program/ProgramSubscribe.json');
  LSubConfirm := LoadTestData('SubscribeConfirm.json');
  LNotification := LoadTestData('Program/ProgramSubscribeNotification.json');

  // Queue: confirmation then notification
  LWs.EnqueueText(LSubConfirm);
  LWs.EnqueueText(LNotification);

  LCallbackExecutable := True;  // will flip to False from payload

  // Act
  LSut.Connect;

  LSubscriptionState := LSut.SubscribeProgram(
    '11111111111111111111111111111111',
    procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TAccountKeyPair>)
    begin
      if (AResponse <> nil) and (AResponse.Context <> nil) then
        LCallbackSlot := AResponse.Context.Slot;

      if (AResponse <> nil) and (AResponse.Value <> nil) then
      begin
        LCallbackPubKey     := AResponse.Value.PublicKey;
        if AResponse.Value.Account <> nil then
        begin
          LCallbackOwner      := AResponse.Value.Account.Owner;
          LCallbackExecutable := AResponse.Value.Account.Executable;
          LCallbackRentEpoch  := AResponse.Value.Account.RentEpoch;
          LCallbackLamports   := AResponse.Value.Account.Lamports;
        end;
      end;

      LCallbackNotified := True;

      // optional: unsubscribe after first notification
      if ASubscriptionState <> nil then
        ASubscriptionState.Unsubscribe;
    end,
    TNullable<Int32>.None
  );

  // Assert subscribe request payload
  AssertNotNull(LSubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirm + notification
  LWs.TriggerAll;

  AssertTrue(LCallbackNotified, 'Notification callback did not fire');
  AssertEquals(80854485, LCallbackSlot, 'Context.Slot mismatch');
  AssertEquals('9FXD1NXrK6xFU8i4gLAgjj2iMEWTqJhSuQN8tQuDfm2e', LCallbackPubKey, 'PublicKey mismatch');
  AssertEquals('11111111111111111111111111111111', LCallbackOwner, 'Owner mismatch');
  AssertFalse(LCallbackExecutable, 'Executable mismatch');
  AssertEquals(187, LCallbackRentEpoch, 'RentEpoch mismatch');
  AssertEquals(458553192193, LCallbackLamports, 'Lamports mismatch');

  // Teardown
  LSut.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeProgramFilters;
var
  LWs        : TMockWebSocketApiClient;
  LWsIntf    : IWebSocketApiClient;
  LSut       : IStreamingRpcClient;
  LExpected  : string;
  LProgramId : string;
  LDataSize  : TNullable<Integer>;
  LMemCmpArr : TArray<TMemCmp>;
  LI        : Integer;
begin
  // Arrange
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  LExpected  := LoadTestData('Program/ProgramSubscribeFilters.json');
  LProgramId := '9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin';

  LDataSize := TNullable<Integer>.Some(3228);

  SetLength(LMemCmpArr, 1);
  LMemCmpArr[0] := TMemCmp.Create;
  LMemCmpArr[0].Offset := 45;
  LMemCmpArr[0].Bytes  := 'CuieVDEDtLo7FypA9SbLM9saXFdb1dsshEkyErMqkRQq';

  // Act
  LSut.Connect;
  try
    LSut.SubscribeProgram(
      LProgramId,
      procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TAccountKeyPair>)
      begin
        // no-op for this test (we only assert the outgoing payload)
      end,
      LDataSize,
      LMemCmpArr
    );

    AssertJsonMatch(LExpected, LWs.LastSentText, 'Program subscribe with filters JSON mismatch');
  finally
    for LI := Low(LMemCmpArr) to High(LMemCmpArr) do
      LMemCmpArr[LI].Free;
    LMemCmpArr := nil;

    // Teardown
    LSut.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeProgramMemcmpFilters;
var
  LWs        : TMockWebSocketApiClient;
  LWsIntf    : IWebSocketApiClient;
  LSut       : IStreamingRpcClient;
  LExpected  : string;
  LProgramId : string;
  LNoSize    : TNullable<Integer>;
  LMemCmpArr : TArray<TMemCmp>;
  LI        : Integer;
begin
  // Arrange
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  LExpected  := LoadTestData('Program/ProgramSubscribeMemcmpFilter.json');
  LProgramId := '9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin';

  // No dataSize; only memcmp filter
  LNoSize := TNullable<Integer>.None;

  SetLength(LMemCmpArr, 1);
  LMemCmpArr[0] := TMemCmp.Create;
  LMemCmpArr[0].Offset := 45;
  LMemCmpArr[0].Bytes  := 'CuieVDEDtLo7FypA9SbLM9saXFdb1dsshEkyErMqkRQq';

  // Act
  LSut.Connect;
  try
    LSut.SubscribeProgram(
      LProgramId,
      procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TAccountKeyPair>)
      begin
        // no-op: we only verify the outgoing payload
      end,
      LNoSize,
      LMemCmpArr
    );

    // Assert: JSON sent equals expected
    AssertJsonMatch(LExpected, LWs.LastSentText, 'Program subscribe with memcmp filter JSON mismatch');
  finally
    // Free owned TMemCmp objects
    for LI := Low(LMemCmpArr) to High(LMemCmpArr) do
      LMemCmpArr[LI].Free;
    LMemCmpArr := nil;

    // Teardown
    LSut.Disconnect;
  end;
end;

 procedure TSolanaStreamingRpcClientTests.TestSubscribeProgramDataFilter;
var
  LWs        : TMockWebSocketApiClient;
  LWsIntf    : IWebSocketApiClient;
  LSut       : IStreamingRpcClient;
  LExpected  : string;
  LProgramId : string;
  LDataSize  : TNullable<Integer>;
begin
  // Arrange
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  LExpected  := LoadTestData('Program/ProgramSubscribeDataSizeFilter.json');
  LProgramId := '9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin';

  LDataSize := TNullable<Integer>.Some(3228);

  // Act
  LSut.Connect;
  try
    LSut.SubscribeProgram(
      LProgramId,
      procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TAccountKeyPair>)
      begin
        // no-op: request-shape test only
      end,
      LDataSize
    );

    // Assert
    AssertJsonMatch(LExpected, LWs.LastSentText, 'Program subscribe with dataSize filter JSON mismatch');
  finally
    LSut.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeProgramConfirmed;
var
  LWs               : TMockWebSocketApiClient;
  LWsIntf           : IWebSocketApiClient;
  LSut              : IStreamingRpcClient;
  LExpectedSend     : string;
  LSubConfirm       : string;
  LNotification     : string;
  LSubscriptionState: ISubscriptionState;

  // captured values from the callback
  LCallbackNotified : Boolean;
  LCallbackSlot     : UInt64;
  LCallbackPubKey   : string;
  LCallbackOwner    : string;
  LCallbackExec     : Boolean;
  LCallbackRentEp   : UInt64;
  LCallbackLamports : UInt64;
begin
  // Arrange: mock WS + real LSut
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  LExpectedSend := LoadTestData('Program/ProgramSubscribeConfirmed.json');
  LSubConfirm   := LoadTestData('SubscribeConfirm.json');
  LNotification := LoadTestData('Program/ProgramSubscribeNotification.json');

  // Queue server frames
  LWs.EnqueueText(LSubConfirm);
  LWs.EnqueueText(LNotification);

  LCallbackNotified := False;

  // Act
  LSut.Connect;
  try
    LSubscriptionState :=
      LSut.SubscribeProgram(
        '11111111111111111111111111111111',
        procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TAccountKeyPair>)
        begin
          if (AResponse <> nil) and (AResponse.Context <> nil) then
            LCallbackSlot := AResponse.Context.Slot;

          if (AResponse <> nil) and (AResponse.Value <> nil) then
          begin
            LCallbackPubKey  := AResponse.Value.PublicKey;
            if AResponse.Value.Account <> nil then
            begin
              LCallbackOwner    := AResponse.Value.Account.Owner;
              LCallbackExec     := AResponse.Value.Account.Executable;
              LCallbackRentEp   := AResponse.Value.Account.RentEpoch;
              LCallbackLamports := AResponse.Value.Account.Lamports;
            end;
          end;

          LCallbackNotified := True;
          if ASubscriptionState <> nil then
            ASubscriptionState.Unsubscribe;
        end,
        TNullable<Integer>.None,
        nil,
        TCommitment.Confirmed
      );

    AssertNotNull(LSubscriptionState, 'Subscription state should not be nil');

    AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Program subscribe (Confirmed) JSON mismatch');

    // Deliver frames (confirm + notification) to LSut
    LWs.TriggerAll;

    AssertTrue(LCallbackNotified, 'Notification callback did not fire');
    AssertEquals(80854485, LCallbackSlot, 'Context.Slot mismatch');
    AssertEquals('9FXD1NXrK6xFU8i4gLAgjj2iMEWTqJhSuQN8tQuDfm2e', LCallbackPubKey, 'PublicKey mismatch');
    AssertEquals('11111111111111111111111111111111', LCallbackOwner, 'Owner mismatch');
    AssertFalse(LCallbackExec, 'Executable mismatch');
    AssertEquals(187, LCallbackRentEp, 'RentEpoch mismatch');
    AssertEquals(458553192193, LCallbackLamports, 'Lamports mismatch');
  finally
    LSut.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeSlotInfo;
var
  LWs               : TMockWebSocketApiClient;
  LWsIntf           : IWebSocketApiClient;
  LSut              : IStreamingRpcClient;
  LExpectedSend     : string;
  LSubConfirm       : string;
  LNotification     : string;
  LSubscriptionState: ISubscriptionState;

  // captured values from the callback
  LCallbackNotified : Boolean;
  LCallbackParent   : Integer;
  LCallbackRoot     : Integer;
  LCallbackSlot     : Integer;
begin
  // Arrange: mock WS + real LSut
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  LExpectedSend := LoadTestData('SlotSubscribe.json');
  LSubConfirm   := LoadTestData('SubscribeConfirm.json');
  LNotification := LoadTestData('SlotSubscribeNotification.json');

  // Queue server frames
  LWs.EnqueueText(LSubConfirm);
  LWs.EnqueueText(LNotification);

  LCallbackNotified := False;

  // Act
  LSut.Connect;
  try
    LSubscriptionState :=
      LSut.SubscribeSlotInfo(
        procedure(ASubscriptionState: ISubscriptionState; AInfo: TSlotInfo)
        begin
          LCallbackParent := AInfo.Parent;
          LCallbackRoot   := AInfo.Root;
          LCallbackSlot   := AInfo.Slot;

          LCallbackNotified := True;
          if ASubscriptionState <> nil then
            ASubscriptionState.Unsubscribe;
        end
      );

    AssertNotNull(LSubscriptionState, 'Subscription state should not be nil');

    AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Slot subscribe JSON mismatch');

    // Deliver frames (confirm + notification) to LSut
    LWs.TriggerAll;

    // Assert callback + values
    AssertTrue(LCallbackNotified, 'Notification callback did not fire');
    AssertEquals(75, LCallbackParent, 'Parent mismatch');
    AssertEquals(44, LCallbackRoot,   'Root mismatch');
    AssertEquals(76, LCallbackSlot,   'Slot mismatch');
  finally
    LSut.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeRoot;
var
  LWs               : TMockWebSocketApiClient;
  LWsIntf           : IWebSocketApiClient;
  LSut              : IStreamingRpcClient;
  LExpectedSend     : string;
  LSubConfirm       : string;
  LNotification     : string;
  LSubscriptionState: ISubscriptionState;

  // captured value from the callback
  LCallbackNotified : Boolean;
  LCallbackRoot     : Integer;
begin
  // Arrange: mock WS + real LSut
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  LExpectedSend := LoadTestData('RootSubscribe.json');
  LSubConfirm   := LoadTestData('SubscribeConfirm.json');
  LNotification := LoadTestData('RootSubscribeNotification.json');

  // Queue server frames
  LWs.EnqueueText(LSubConfirm);
  LWs.EnqueueText(LNotification);

  LCallbackNotified := False;

  // Act
  LSut.Connect;
  try
    LSubscriptionState :=
      LSut.SubscribeRoot(
        procedure(ASubscriptionState: ISubscriptionState; AValue: Integer)
        begin
          LCallbackRoot     := AValue;
          LCallbackNotified := True;
          if ASubscriptionState <> nil then
            ASubscriptionState.Unsubscribe;
        end
      );

    AssertNotNull(LSubscriptionState, 'Subscription state should not be nil');

    AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Root subscribe JSON mismatch');

    // Deliver frames (confirm + notification) to LSut
    LWs.TriggerAll;

    // Assert callback + value
    AssertTrue(LCallbackNotified, 'Notification callback did not fire');
    AssertEquals(42, LCallbackRoot, 'Root value mismatch');
  finally
    LSut.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeSignature;
var
  LWs                : TMockWebSocketApiClient;
  LWsIntf            : IWebSocketApiClient;
  LSut               : IStreamingRpcClient;
  LExpectedSend      : string;
  LSubConfirm        : string;
  LNotification      : string;
  LSub               : ISubscriptionState;

  // callback flags
  LCallbackFired     : Boolean;
  LHasValue          : Boolean;
  LHasError          : Boolean;

  // subscription-changed capture
  LChangedSignal     : TEvent;
  LLastChange        : ISubscriptionEvent;
begin
  // Arrange
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  LExpectedSend := LoadTestData('Signature/SignatureSubscribe.json');
  LSubConfirm   := LoadTestData('SubscribeConfirm.json');
  LNotification := LoadTestData('Signature/SignatureSubscribeNotification.json');

  // server frames: confirm -> notification
  LWs.EnqueueText(LSubConfirm);
  LWs.EnqueueText(LNotification);

  LCallbackFired := False;
  LHasValue      := False;
  LHasError      := False;

  LChangedSignal := TEvent.Create(nil, True, False, '');
  try
    // Act
    LSut.Connect;
    LSub :=
      LSut.SubscribeSignature(
        '4orRpuqStpJDvcpBy3vDSV4TDTGNbefmqYUnG2yVnKwjnLFqCwY4h5cBTAKakKek4inuxHF71LuscBS1vwSLtWcx',
          procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TErrorResult>)
          begin
            LCallbackFired := True;
            LHasValue := (AResponse <> nil) and (AResponse.Value <> nil);
            LHasError := LHasValue and (AResponse.Value.Error <> nil);
            // signature notifications auto-unsubscribe (handled by client)
          end,
        TCommitment.Finalized
      );

    // listen for auto-unsubscribe
    LSub.AddSubscriptionChanged(
      procedure(ASubscriptionState: ISubscriptionState; AEvent: ISubscriptionEvent)
      begin
        LLastChange := AEvent;
        if (AEvent <> nil) and (AEvent.Status = TSubscriptionStatus.Unsubscribed) then
          LChangedSignal.SetEvent;
      end
    );

    AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Signature subscribe JSON mismatch');

    // Drive confirm + notification
    LWs.TriggerAll;

    // Assert via boolean flags
    AssertTrue(LCallbackFired, 'Signature callback did not fire');
    AssertTrue(LHasValue, 'Expected Env.Value to be assigned');
    AssertFalse(LHasError, 'Expected Env.Value.Error to be nil');

    // Expect auto-unsubscribe after signature notification
    case LChangedSignal.WaitFor(3000) of
      wrSignaled: ; // ok
    else
      Fail('Did not receive Unsubscribed change event');
    end;

    AssertNotNull(LLastChange, 'No subscription change captured');
    AssertEquals(Ord(TSubscriptionStatus.Unsubscribed), Ord(LLastChange.Status), 'Subscription status mismatch');
    AssertEquals(Ord(TSubscriptionStatus.Unsubscribed), Ord(LSub.State), 'Sub.State mismatch');
  finally
    LChangedSignal.Free;
    LSut.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeSignature_ErrorNotification;
var
  LWs                : TMockWebSocketApiClient;
  LWsIntf            : IWebSocketApiClient;
  LSut               : IStreamingRpcClient;

  LExpectedSend      : string;
  LSubConfirm        : string;
  LNotification      : string;

  LSub               : ISubscriptionState;

  // callback flags
  LCallbackFired     : Boolean;
  LHasValue          : Boolean;
  LHasError          : Boolean;

  // captured error details
  LCapErrType        : TTransactionErrorType;
  LCapInstrErrType   : TInstructionErrorType;
  LCapCustomErr      : TNullable<UInt32>;

  // subscription change signaling
  LChangedSignal     : TEvent;
  LLastChange        : ISubscriptionEvent;
begin
  // Arrange
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  LExpectedSend := LoadTestData('Signature/SignatureSubscribe.json');
  LSubConfirm   := LoadTestData('SubscribeConfirm.json');
  LNotification := LoadTestData('Signature/SignatureSubscribeErrorNotification.json');

  // server frames: confirm -> error notification
  LWs.EnqueueText(LSubConfirm);
  LWs.EnqueueText(LNotification);

  LChangedSignal := TEvent.Create(nil, True, False, '');
  try
    // Act
    LSut.Connect;

    LSub :=
      LSut.SubscribeSignature(
        '4orRpuqStpJDvcpBy3vDSV4TDTGNbefmqYUnG2yVnKwjnLFqCwY4h5cBTAKakKek4inuxHF71LuscBS1vwSLtWcx',
          procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TErrorResult>)
          begin
            LCallbackFired := True;
            LHasValue := (AResponse <> nil) and (AResponse.Value <> nil);
            LHasError := LHasValue and (AResponse.Value.Error <> nil);

            if LHasError then
            begin
              LCapErrType      := AResponse.Value.Error.&Type;
              if AResponse.Value.Error.InstructionError <> nil then
              begin
                LCapInstrErrType := AResponse.Value.Error.InstructionError.&Type;
                LCapCustomErr    := AResponse.Value.Error.InstructionError.CustomError;
              end;
            end;
            // client auto-unsubscribes on signature notifications
          end,
        TCommitment.Finalized
      );

    // subscribe to state changes (expect Unsubscribed after notification)
    LSub.AddSubscriptionChanged(
      procedure(ASubscriptionState: ISubscriptionState; AEvent: ISubscriptionEvent)
      begin
        LLastChange := AEvent;
        if (AEvent <> nil) and (AEvent.Status = TSubscriptionStatus.Unsubscribed) then
          LChangedSignal.SetEvent;
      end
    );

    AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Signature subscribe JSON mismatch');

    // Drive confirm + error notification
    LWs.TriggerAll;

    AssertTrue(LCallbackFired, 'Signature callback did not fire');
    AssertTrue(LHasValue, 'Expected Env.Value to be assigned');
    AssertTrue(LHasError, 'Expected Env.Value.Error to be assigned (error notification)');

    AssertEquals(Ord(TTransactionErrorType.InstructionError), Ord(LCapErrType), 'Error.Type mismatch');
    AssertEquals(Ord(TInstructionErrorType.Custom), Ord(LCapInstrErrType), 'InstructionError.Type mismatch');
    AssertEquals(0, LCapCustomErr.Value, 'InstructionError.CustomError mismatch');

    // Expect Unsubscribed after signature notification
    case LChangedSignal.WaitFor(3000) of
      wrSignaled: ; // ok
    else
      Fail('Did not receive Unsubscribed change event');
    end;

    AssertNotNull(LLastChange, 'No subscription change captured');
    AssertEquals(Ord(TSubscriptionStatus.Unsubscribed), Ord(LLastChange.Status), 'Subscription status mismatch');
    AssertEquals(Ord(TSubscriptionStatus.Unsubscribed), Ord(LSub.State), 'Sub.State mismatch');
  finally
    LChangedSignal.Free;
    LSut.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeSignature_Processed;
var
  LWs                : TMockWebSocketApiClient;
  LWsIntf            : IWebSocketApiClient;
  LSut               : IStreamingRpcClient;

  LExpectedSend      : string;
  LSubConfirm        : string;
  LNotification      : string;

  LSub               : ISubscriptionState;

  // callback flags
  LCallbackFired     : Boolean;
  LHasValue          : Boolean;
  LHasError          : Boolean;

  // subscription change signaling
  LChangedSignal     : TEvent;
  LLastChange        : ISubscriptionEvent;
begin
  // Arrange
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  LExpectedSend := LoadTestData('Signature/SignatureSubscribeProcessed.json');
  LSubConfirm   := LoadTestData('SubscribeConfirm.json');
  LNotification := LoadTestData('Signature/SignatureSubscribeNotification.json');

  // server frames: confirm -> success notification (no error)
  LWs.EnqueueText(LSubConfirm);
  LWs.EnqueueText(LNotification);

  LCallbackFired := False;
  LHasValue      := False;
  LHasError      := False;

  LChangedSignal := TEvent.Create(nil, True, False, '');
  try
    // Act
    LSut.Connect;

    LSub :=
      LSut.SubscribeSignature(
        '4orRpuqStpJDvcpBy3vDSV4TDTGNbefmqYUnG2yVnKwjnLFqCwY4h5cBTAKakKek4inuxHF71LuscBS1vwSLtWcx',
          procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TErrorResult>)
          begin
            LCallbackFired := True;
            LHasValue := (AResponse <> nil) and (AResponse.Value <> nil);
            LHasError := LHasValue and (AResponse.Value.Error <> nil);
          end,
        TCommitment.Processed
      );

    // listen for Unsubscribed transition
    LSub.AddSubscriptionChanged(
      procedure(ASubscriptionState: ISubscriptionState; AEvent: ISubscriptionEvent)
      begin
        LLastChange := AEvent;
        if (AEvent <> nil) and (AEvent.Status = TSubscriptionStatus.Unsubscribed) then
          LChangedSignal.SetEvent;
      end
    );

    AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Signature subscribe (Processed) JSON mismatch');

    // Drive confirm + notification
    LWs.TriggerAll;

    // Assertions
    AssertTrue(LCallbackFired, 'Signature callback did not fire');
    AssertTrue(LHasValue, 'Expected Env.Value to be assigned');
    AssertFalse(LHasError, 'Did not expect Env.Value.Error for non-error notification');

    // Expect Unsubscribed after notification
    case LChangedSignal.WaitFor(3000) of
      wrSignaled: ; // ok
    else
      Fail('Did not receive Unsubscribed change event');
    end;

    AssertNotNull(LLastChange, 'No subscription change captured');
    AssertEquals(Ord(TSubscriptionStatus.Unsubscribed), Ord(LLastChange.Status), 'Subscription status mismatch');
    AssertEquals(Ord(TSubscriptionStatus.Unsubscribed), Ord(LSub.State), 'Sub.State mismatch');
  finally
    LChangedSignal.Free;
    LSut.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeBadAccount;
var
  LWs            : TMockWebSocketApiClient;
  LWsIntf        : IWebSocketApiClient;
  LSut           : IStreamingRpcClient;

  LExpectedSend  : string;
  LSubConfirm    : string;

  LPubKey        : string;
  LSub           : ISubscriptionState;

  // subscription change capture
  LGotChange     : TEvent;
  LLastEvent     : ISubscriptionEvent;
begin
  // Arrange
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  LExpectedSend := LoadTestData('Account/BadAccountSubscribe.json');
  LSubConfirm   := LoadTestData('Account/BadAccountSubscribeResult.json');

  LWs.EnqueueText(LSubConfirm);

  LPubKey    := 'invalidkey1';
  LGotChange := TEvent.Create(nil, True, False, '');
  try
    // Act
    LSut.Connect;

    LSub :=
      LSut.SubscribeAccountInfo(
        LPubKey,
        procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TAccountInfo>)
        begin
          // No-op: for a bad account, the server fails the subscription request;
          // the callback for account notifications won't be invoked.
        end
      );

    // Capture subscription change (expect ErrorSubscribing)
    LSub.AddSubscriptionChanged(
      procedure(ASubscriptionState: ISubscriptionState; AEvent: ISubscriptionEvent)
      begin
        LLastEvent := AEvent;
        LGotChange.SetEvent;
      end
    );

    AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Bad-account subscribe JSON mismatch');

    // Drive the queued error response
    LWs.TriggerAll;

    // Wait for the ErrorSubscribing event
    case LGotChange.WaitFor(3000) of
      wrSignaled: ; // ok
    else
      Fail('Did not receive subscription change event for bad account');
    end;

    AssertNotNull(LLastEvent, 'Missing subscription event payload');
    AssertEquals('-32602', LLastEvent.Code, 'Error code mismatch');
    AssertEquals(Ord(TSubscriptionStatus.ErrorSubscribing), Ord(LLastEvent.Status), 'Event status mismatch');
    AssertEquals('Invalid Request: Invalid pubkey provided', LLastEvent.Error, 'Error message mismatch');

    AssertEquals(Ord(TSubscriptionStatus.ErrorSubscribing), Ord(LSub.State), 'Subscription state mismatch');
  finally
    LGotChange.Free;
    LSut.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeAccountBigPayload;
var
  LWs                 : TMockWebSocketApiClient;
  LWsIntf             : IWebSocketApiClient;
  LSut                : IStreamingRpcClient;

  LExpectedSend       : string;
  LSubConfirm         : string;
  LNotification       : string;
  LExpectedDataBody   : string;

  LPubKey             : string;
  LSub                : ISubscriptionState;

  // subscription change capture
  LGotSubscribedEvt   : Boolean;
  LLastEvent         : ISubscriptionEvent;

  // notification capture
  LCallbackNotified   : Boolean;
  LEnvWasSet        : Boolean;
  LValueWasSet      : Boolean;
  LEnvBase64     : string;
  LEnvEncodingTag: string;
begin
  // Arrange: mock WS + real LSut
  LWs     := TMockWebSocketApiClient.Create;
  LWsIntf := LWs;
  LSut    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, LWsIntf);

  // Files
  LExpectedSend     := LoadTestData('Account/BigAccountSubscribe.json');
  LSubConfirm       := LoadTestData('SubscribeConfirm.json');
  LNotification     := LoadTestData('Account/BigAccountNotificationPayload.json');
  LExpectedDataBody := LoadTestData('Account/BigAccountNotificationPayloadData.txt');

  // Queue frames: subscription confirmation then BIG notification payload
  LWs.EnqueueText(LSubConfirm);
  LWs.EnqueueText(LNotification);

  LPubKey := 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';

  try
    // Act
    LSut.Connect;

    LSub :=
      LSut.SubscribeAccountInfo(
        LPubKey,
        procedure(ASubscriptionState: ISubscriptionState; AResponse: TResponseValue<TAccountInfo>)
        begin
          // Capture notification
          LEnvWasSet   := (AResponse <> nil);
          LValueWasSet := (AResponse <> nil) and (AResponse.Value <> nil);
          LEnvBase64 := AResponse.Value.Data[0];
          LEnvEncodingTag := AResponse.Value.Data[1];
          LCallbackNotified := True;
        end
      );

    // Track "Subscribed" event after confirm
    LSub.AddSubscriptionChanged(
      procedure(ASubscriptionState: ISubscriptionState; AEvent: ISubscriptionEvent)
      begin
        LLastEvent := AEvent;
        if (AEvent.Status = TSubscriptionStatus.Subscribed) then
          LGotSubscribedEvt := True;
      end
    );

    AssertJsonMatch(LExpectedSend, LWs.LastSentText, 'Subscribe request JSON mismatch');

    // Drive both queued frames (confirm -> subscribed; then big payload notification)
    LWs.TriggerAll;

    AssertTrue(LGotSubscribedEvt, 'Did not receive Subscribed event');
    AssertNotNull(LLastEvent, 'Missing subscription event');
    AssertEquals(Ord(TSubscriptionStatus.Subscribed), Ord(LLastEvent.Status), 'Subscription status mismatch');
    AssertTrue((LLastEvent.Error = '') and (LLastEvent.Code = ''), 'Unexpected error/code on subscribe confirm');
    AssertEquals(Ord(TSubscriptionStatus.Subscribed), Ord(LSub.State), 'Subscription state mismatch');

    AssertTrue(LCallbackNotified, 'Notification callback did not fire');
    AssertTrue(LEnvWasSet,   'Callback environment was nil');
    AssertTrue(LValueWasSet, 'Callback environment value was nil');

    AssertEquals(LExpectedDataBody, LEnvBase64, 'AccountInfo.Data[0] mismatch');
    AssertEquals('base64', LEnvEncodingTag, 'AccountInfo.Data[1] encoding tag mismatch');
  finally
    LSut.Disconnect;
  end;
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaStreamingRpcClientTests);
{$ELSE}
  RegisterTest(TSolanaStreamingRpcClientTests.Suite);
{$ENDIF}

end.

