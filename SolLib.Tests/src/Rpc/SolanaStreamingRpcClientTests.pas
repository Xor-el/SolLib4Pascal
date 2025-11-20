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
  TestUtils,
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
  WS           : TMockWebSocketApiClient;
  WSIntf       : IWebSocketApiClient;
  SUT          : IStreamingRpcClient;
begin
  // Arrange: mock WS + real SUT
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  AssertTrue(Assigned(WSIntf.OnConnect),    'OnConnect not wired');
  AssertTrue(Assigned(WSIntf.OnDisconnect),    'OnDisconnect not wired');
  AssertTrue(Assigned(WSIntf.OnReceiveTextMessage),   'OnReceiveTextMessage not wired');
  AssertTrue(Assigned(WSIntf.OnReceiveBinaryMessage),     'OnReceiveBinaryMessage not wired');
  AssertTrue(Assigned(WSIntf.OnError),     'OnError not wired');
  AssertTrue(Assigned(WSIntf.OnException),     'OnException not wired');
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeAccountInfo;
var
  WS: TMockWebSocketApiClient;
  WSIntf: IWebSocketApiClient;
  SUT: IStreamingRpcClient;
  PubKey: string;
  ExpectedSend: string;
  SubConfirm: string;
  Notification: string;
  SubscriptionState: ISubscriptionState;
  // captured values from the callback
  CallbackNotified: Boolean;
  CallbackSlot: UInt64;
  CallbackOwner: string;
  CallbackLamports: UInt64;
  CallbackRentEpoch: UInt64;
  CallbackExecutable: Boolean;
begin
  // Arrange: mock WS + real SUT
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  // Prepare frames
  ExpectedSend := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Account', 'AccountSubscribe.json'])
  );
  SubConfirm := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json'])
  );
  Notification := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Account', 'AccountSubscribeNotification.json'])
  );

  WS.EnqueueText(SubConfirm);
  WS.EnqueueText(Notification);

  PubKey := 'CM78CPUeXjn8o3yroDHxUtKsZZgoy4GPkPPXfouKNH12';

  CallbackExecutable := True;  // will flip to False from payload
  // Act
  SUT.Connect;

  SubscriptionState := SUT.SubscribeAccountInfo(
    PubKey,
    procedure(Sub: ISubscriptionState; Env: TResponseValue<TAccountInfo>)
    begin
      // Capture callback values for assertions
      if (Env <> nil) and (Env.Context <> nil) then
        CallbackSlot := Env.Context.Slot;

      if (Env <> nil) and (Env.Value <> nil) then
      begin
        CallbackOwner      := Env.Value.Owner;
        CallbackLamports   := Env.Value.Lamports;
        CallbackRentEpoch  := Env.Value.RentEpoch;
        CallbackExecutable := Env.Value.Executable;
      end;

      CallbackNotified := True;

      if Sub <> nil then
        Sub.Unsubscribe;
    end
  );

  AssertNotNull(SubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirm + notification
  WS.TriggerAll;

  AssertTrue(CallbackNotified, 'Notification callback did not fire');
  AssertEquals(5199307, CallbackSlot, 'Context.Slot mismatch');
  AssertEquals('11111111111111111111111111111111', CallbackOwner, 'Owner mismatch');
  AssertEquals(33594, CallbackLamports, 'Lamports mismatch');
  AssertEquals(635, CallbackRentEpoch, 'RentEpoch mismatch');
  AssertFalse(CallbackExecutable, 'Executable mismatch');

  // Teardown
  SUT.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeTokenAccount;
var
  WS                 : TMockWebSocketApiClient;
  WSIntf             : IWebSocketApiClient;
  SUT                : IStreamingRpcClient;
  PubKey             : string;
  ExpectedSend       : string;
  SubConfirm         : string;
  Notification       : string;
  SubscriptionState  : ISubscriptionState;
  // captured values from the callback
  CallbackNotified   : Boolean;
  CallbackSlot       : UInt64;
  CallbackOwner      : string;
  CallbackLamports   : UInt64;
  CallbackTokenOwner : string;
  CallbackAmount     : string;
  CallbackUiAmount   : string;
  CallbackDecimals   : Integer;
  TokenAccountData: TTokenAccountData;
begin
  // Arrange: mock WS + real SUT
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  // Prepare frames
  ExpectedSend := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Account', 'TokenAccountSubscribe.json'])
  );
  SubConfirm := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json'])
  );
  Notification := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Account', 'TokenAccountSubscribeNotification.json'])
  );

  WS.EnqueueText(SubConfirm);
  WS.EnqueueText(Notification);

  PubKey := 'CM78CPUeXjn8o3yroDHxUtKsZZgoy4GPkPPXfouKNH12';

  // Act
  SUT.Connect;

  SubscriptionState := SUT.SubscribeTokenAccount(
    PubKey,
    procedure(Sub: ISubscriptionState; Env: TResponseValue<TTokenAccountInfo>)
    begin
      if (Env <> nil) and (Env.Context <> nil) then
        CallbackSlot := Env.Context.Slot;

      if (Env <> nil) and (Env.Value <> nil) then
      begin
        CallbackOwner    := Env.Value.Owner;
        CallbackLamports := Env.Value.Lamports;

        TokenAccountData := Env.Value.Data.AsType<TTokenAccountData>;

        if (TokenAccountData <> nil) and
           (TokenAccountData.Parsed <> nil) and
           (TokenAccountData.Parsed.Info <> nil) and
           (TokenAccountData.Parsed.Info.TokenAmount <> nil) then
        begin
          CallbackTokenOwner := TokenAccountData.Parsed.Info.Owner;
          CallbackAmount     := TokenAccountData.Parsed.Info.TokenAmount.Amount;
          CallbackUiAmount   := TokenAccountData.Parsed.Info.TokenAmount.UiAmountString;
          CallbackDecimals   := TokenAccountData.Parsed.Info.TokenAmount.Decimals;
        end;
      end;

      CallbackNotified := True;

      if Sub <> nil then
        Sub.Unsubscribe;
    end
  );

  // Assert subscribe request
  AssertNotNull(SubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirm + notification
  WS.TriggerAll;

  AssertTrue(CallbackNotified, 'Notification callback did not fire');
  AssertEquals(99118135, CallbackSlot, 'Context.Slot mismatch');
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', CallbackOwner, 'Owner mismatch');
  AssertEquals('F8Vyqk3unwxkXukZFQeYyGmFfTG3CAX4v24iyrjEYBJV', CallbackTokenOwner, 'Parsed.Info.Owner mismatch');
  AssertEquals('9830001302037', CallbackAmount, 'TokenAmount.Amount mismatch');
  AssertEquals('9830001.302037', CallbackUiAmount, 'TokenAmount.UiAmountString mismatch');
  AssertEquals(6, CallbackDecimals, 'TokenAmount.Decimals mismatch');
  AssertEquals(2039280, CallbackLamports, 'Lamports mismatch');

  // Teardown
  SUT.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeAccountInfoProcessed;
var
  WS                 : TMockWebSocketApiClient;
  WSIntf             : IWebSocketApiClient;
  SUT                : IStreamingRpcClient;
  PubKey             : string;
  ExpectedSend       : string;
  SubConfirm         : string;
  Notification       : string;
  SubscriptionState  : ISubscriptionState;
  // captured values from the callback
  CallbackNotified   : Boolean;
  CallbackSlot       : UInt64;
  CallbackOwner      : string;
  CallbackLamports   : UInt64;
  CallbackRentEpoch  : UInt64;
  CallbackExecutable : Boolean;
begin
  // Arrange: mock WS + real SUT
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  // Prepare frames: subscription confirm, then notification
  ExpectedSend := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Account', 'AccountSubscribeProcessed.json'])
  );
  SubConfirm := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json'])
  );
  Notification := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Account', 'AccountSubscribeNotification.json'])
  );

  WS.EnqueueText(SubConfirm);
  WS.EnqueueText(Notification);

  PubKey := 'CM78CPUeXjn8o3yroDHxUtKsZZgoy4GPkPPXfouKNH12';

  // Act
  SUT.Connect;

  SubscriptionState := SUT.SubscribeAccountInfo(
    PubKey,
    procedure(Sub: ISubscriptionState; Env: TResponseValue<TAccountInfo>)
    begin
      if (Env <> nil) and (Env.Context <> nil) then
        CallbackSlot := Env.Context.Slot;

      if (Env <> nil) and (Env.Value <> nil) then
      begin
        CallbackOwner      := Env.Value.Owner;
        CallbackLamports   := Env.Value.Lamports;
        CallbackRentEpoch  := Env.Value.RentEpoch;
        CallbackExecutable := Env.Value.Executable;
      end;

      CallbackNotified := True;

      if Sub <> nil then
        Sub.Unsubscribe;
    end,
    TCommitment.Processed
  );

  // Assert subscribe request
  AssertNotNull(SubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirm + notification
  WS.TriggerAll;

  AssertTrue(CallbackNotified, 'Notification callback did not fire');
  AssertEquals(5199307, CallbackSlot, 'Context.Slot mismatch');
  AssertEquals('11111111111111111111111111111111', CallbackOwner, 'Owner mismatch');
  AssertEquals(33594, CallbackLamports, 'Lamports mismatch');
  AssertEquals(635, CallbackRentEpoch, 'RentEpoch mismatch');
  AssertFalse(CallbackExecutable, 'Executable mismatch');

  // Teardown
  SUT.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestUnsubscribe;
var
  WS                : TMockWebSocketApiClient;
  WSIntf            : IWebSocketApiClient;
  SUT               : IStreamingRpcClient;
  PubKey            : string;
  SubConfirm        : string;
  UnsubResponse     : string;
  Sub               : ISubscriptionState;
  Unsubscribed      : Boolean;
  WaitUnsubscribed  : TEvent;
begin
  // Arrange: mock WS + real SUT
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  // Frames (deliver in two phases)
  SubConfirm    := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json']));
  UnsubResponse := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Account', 'AccountSubUnsubscription.json']));

  // Phase 1: only the subscription confirmation
  WS.EnqueueText(SubConfirm);

  PubKey := 'CM78CPUeXjn8o3yroDHxUtKsZZgoy4GPkPPXfouKNH12';

  Unsubscribed := False;
  WaitUnsubscribed := TEvent.Create(nil, True, False, '');
  try
    // Act
    SUT.Connect;

    // Subscribe
    Sub := SUT.SubscribeAccountInfo(
      PubKey,
      procedure(S: ISubscriptionState; Env: TResponseValue<TAccountInfo>)
      begin
        // no-op for this test
      end
    );

    // Deliver the subscribe-confirm frame so SubscriptionId is set and state is Subscribed
    WS.TriggerAll;

    // Observe state changes; notify when Unsubscribed
    Sub.AddSubscriptionChanged(
      procedure(S: ISubscriptionState; E: ISubscriptionEvent)
      begin
        if (E <> nil) and (E.Status = TSubscriptionStatus.Unsubscribed) then
        begin
          Unsubscribed := True;
          WaitUnsubscribed.SetEvent;
        end;
      end
    );

    // Request unsubscription (client will send *Unsubscribe with current SubscriptionId)
    Sub.Unsubscribe;

    // Phase 2: deliver the server's boolean result for unsubscribe
    WS.EnqueueText(UnsubResponse);
    WS.TriggerAll;

    // Assert we observed the Unsubscribed state transition
    AssertEquals(Ord(TWaitResult.wrSignaled), Ord(WaitUnsubscribed.WaitFor(3000)), 'Unsubscribe signal not observed');
    AssertTrue(Unsubscribed, 'Subscription did not reach Unsubscribed state');
  finally
    WaitUnsubscribed.Free;
    SUT.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeLogsMention;
var
  WS                : TMockWebSocketApiClient;
  WSIntf            : IWebSocketApiClient;
  SUT               : IStreamingRpcClient;
  PubKey            : string;
  ExpectedSend      : string;
  SubConfirm        : string;
  SubscriptionState : ISubscriptionState;
begin
  // Arrange: mock WS + real SUT
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  // Expected subscribe payload and confirm frame
  ExpectedSend := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Logs', 'LogsSubscribeMention.json'])
  );
  SubConfirm := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json'])
  );

  // Only confirmation (no notification needed for this test)
  WS.EnqueueText(SubConfirm);

  PubKey := '11111111111111111111111111111111';

  // Act
  SUT.Connect;

  SubscriptionState := SUT.SubscribeLogInfo(
    PubKey,
    procedure(Sub: ISubscriptionState; Env: TResponseValue<TLogInfo>)
    begin

    end
  );

  // Assert the subscribe request sent to the socket
  AssertNotNull(SubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver the confirmation frame
  WS.TriggerAll;

  // Teardown
  SUT.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeLogsMentionConfirmed;
var
  WS                : TMockWebSocketApiClient;
  WSIntf            : IWebSocketApiClient;
  SUT               : IStreamingRpcClient;
  PubKey            : string;
  ExpectedSend      : string;
  SubConfirm        : string;
  SubscriptionState : ISubscriptionState;
begin
  // Arrange: mock WS + real SUT
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  // Expected subscribe payload (with commitment=confirmed) and confirm frame
  ExpectedSend := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Logs', 'LogsSubscribeMentionConfirmed.json'])
  );
  SubConfirm := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json'])
  );

  // Only confirmation
  WS.EnqueueText(SubConfirm);

  PubKey := '11111111111111111111111111111111';

  // Act
  SUT.Connect;

  SubscriptionState := SUT.SubscribeLogInfo(
    PubKey,
    procedure(Sub: ISubscriptionState; Env: TResponseValue<TLogInfo>)
    begin

    end,
    TCommitment.Confirmed
  );

  // Assert the subscribe request sent to the socket
  AssertNotNull(SubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirmation frame
  WS.TriggerAll;

  // Teardown
  SUT.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeLogsAll;
var
  WS                 : TMockWebSocketApiClient;
  WSIntf             : IWebSocketApiClient;
  SUT                : IStreamingRpcClient;
  ExpectedSend       : string;
  SubConfirm         : string;
  Notification       : string;
  SubscriptionState  : ISubscriptionState;

  // captured from callback
  CallbackNotified   : Boolean;
  CallbackSlot       : UInt64;
  CallbackSignature  : string;
  CallbackHasError   : Boolean;
  CallbackFirstLog   : string;
begin
  // Arrange: mock WS + real SUT
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  // Expected outgoing subscribe payload and incoming frames
  ExpectedSend := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Logs', 'LogsSubscribeAll.json'])
  );
  SubConfirm := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json'])
  );
  Notification := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Logs', 'LogsSubscribeNotification.json'])
  );

  // Queue: confirmation then notification
  WS.EnqueueText(SubConfirm);
  WS.EnqueueText(Notification);

  CallbackHasError  := True; // default true, will flip to false if nil

  // Act
  SUT.Connect;

  SubscriptionState := SUT.SubscribeLogInfo(
    TLogsSubscriptionType.All,
    procedure(Sub: ISubscriptionState; Env: TResponseValue<TLogInfo>)
    begin
      if (Env <> nil) and (Env.Context <> nil) then
        CallbackSlot := Env.Context.Slot;

      if (Env <> nil) and (Env.Value <> nil) then
      begin
        CallbackSignature := Env.Value.Signature;
        CallbackHasError  := (Env.Value.Error <> nil);
        if (Length(Env.Value.Logs) > 0) then
          CallbackFirstLog := Env.Value.Logs[0];
      end;

      CallbackNotified := True;

      if Sub <> nil then
        Sub.Unsubscribe;
    end
  );

  // Assert request sent
  AssertNotNull(SubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirm + notification
  WS.TriggerAll;

  AssertTrue(CallbackNotified, 'Notification callback did not fire');
  AssertEquals(5208469, CallbackSlot, 'Context.Slot mismatch');
  AssertEquals(
    '5h6xBEauJ3PK6SWCZ1PGjBvj8vDdWG3KpwATGy1ARAXFSDwt8GFXM7W5Ncn16wmqokgpiKRLuS83KUxyZyv2sUYv',
    CallbackSignature,
    'Signature mismatch'
  );
  AssertFalse(CallbackHasError, 'Expected no error in log notification');
  AssertEquals(
    'BPF program 83astBRguLMdt2h5U1Tpdq5tjFoJ6noeGwaY3mDLVcri success',
    CallbackFirstLog,
    'First log line mismatch'
  );

  // Teardown
  SUT.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeLogsAllProcessed;
var
  WS                 : TMockWebSocketApiClient;
  WSIntf             : IWebSocketApiClient;
  SUT                : IStreamingRpcClient;
  ExpectedSend       : string;
  SubConfirm         : string;
  Notification       : string;
  SubscriptionState  : ISubscriptionState;

  // captured from callback
  CallbackNotified   : Boolean;
  CallbackSlot       : UInt64;
  CallbackSignature  : string;
  CallbackHasError   : Boolean;
  CallbackFirstLog   : string;
begin
  // Arrange: mock WS + real SUT
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  // Expected outgoing subscribe payload (commitment=processed) and incoming frames
  ExpectedSend := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Logs', 'LogsSubscribeAllProcessed.json'])
  );
  SubConfirm := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json'])
  );
  Notification := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Logs', 'LogsSubscribeNotification.json'])
  );

  // Queue: confirmation then notification
  WS.EnqueueText(SubConfirm);
  WS.EnqueueText(Notification);

  CallbackHasError  := True; // will flip to False when Error = nil

  // Act
  SUT.Connect;

  SubscriptionState := SUT.SubscribeLogInfo(
    TLogsSubscriptionType.All,
    procedure(Sub: ISubscriptionState; Env: TResponseValue<TLogInfo>)
    begin
      if (Env <> nil) and (Env.Context <> nil) then
        CallbackSlot := Env.Context.Slot;

      if (Env <> nil) and (Env.Value <> nil) then
      begin
        CallbackSignature := Env.Value.Signature;
        CallbackHasError  := (Env.Value.Error <> nil);
        if Length(Env.Value.Logs) > 0 then
          CallbackFirstLog := Env.Value.Logs[0];
      end;

      CallbackNotified := True;

      // optional: clean up subscription after first notification
      if Sub <> nil then
        Sub.Unsubscribe;
    end,
    TCommitment.Processed
  );

  // Assert the subscribe request sent to the socket
  AssertNotNull(SubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirm + notification
  WS.TriggerAll;

  // Assert callback & payload fields
  AssertTrue(CallbackNotified, 'Notification callback did not fire');
  AssertEquals(5208469, CallbackSlot, 'Context.Slot mismatch');
  AssertEquals(
    '5h6xBEauJ3PK6SWCZ1PGjBvj8vDdWG3KpwATGy1ARAXFSDwt8GFXM7W5Ncn16wmqokgpiKRLuS83KUxyZyv2sUYv',
    CallbackSignature,
    'Signature mismatch'
  );
  AssertFalse(CallbackHasError, 'Expected no error in log notification');
  AssertEquals(
    'BPF program 83astBRguLMdt2h5U1Tpdq5tjFoJ6noeGwaY3mDLVcri success',
    CallbackFirstLog,
    'First log line mismatch'
  );

  // Teardown
  SUT.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeLogsWithErrors;
var
  WS                 : TMockWebSocketApiClient;
  WSIntf             : IWebSocketApiClient;
  SUT                : IStreamingRpcClient;
  ExpectedSend       : string;
  SubConfirm         : string;
  Notification       : string;
  SubscriptionState  : ISubscriptionState;

  // captured from callback
  CallbackNotified   : Boolean;
  CallbackErrorType  : TTransactionErrorType;
  CallbackInstrType  : TInstructionErrorType;
  CallbackCustomErr  : TNullable<UInt32>;
  CallbackSignature  : string;
begin
  // Arrange: mock WS + real SUT
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  // Expected outgoing subscribe payload (commitment=processed) and incoming frames (with error)
  ExpectedSend := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Logs', 'LogsSubscribeAllProcessed.json'])
  );
  SubConfirm := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json'])
  );
  Notification := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Logs', 'LogsSubscribeNotificationWithError.json'])
  );

  // Queue: confirmation then error notification
  WS.EnqueueText(SubConfirm);
  WS.EnqueueText(Notification);

  // Act
  SUT.Connect;

  SubscriptionState := SUT.SubscribeLogInfo(
    TLogsSubscriptionType.All,
    procedure(Sub: ISubscriptionState; Env: TResponseValue<TLogInfo>)
    begin
      if (Env <> nil) and (Env.Value <> nil) then
      begin
        if Assigned(Env.Value.Error) then
        begin
          CallbackErrorType := Env.Value.Error.&Type;
          if Assigned(Env.Value.Error.InstructionError) then
          begin
            CallbackInstrType := Env.Value.Error.InstructionError.&Type;
            CallbackCustomErr := Env.Value.Error.InstructionError.CustomError;
          end;
        end;
        CallbackSignature := Env.Value.Signature;
      end;

      CallbackNotified := True;

      // optional: end after first notification
      if Sub <> nil then
        Sub.Unsubscribe;
    end,
    TCommitment.Processed
  );

  AssertNotNull(SubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirm + notification (with error)
  WS.TriggerAll;

  AssertTrue(CallbackNotified, 'Notification callback did not fire');

  AssertEquals(
    Ord(TTransactionErrorType.InstructionError),
    Ord(CallbackErrorType),
    'TransactionErrorType mismatch'
  );
  AssertEquals(
    Ord(TInstructionErrorType.Custom),
    Ord(CallbackInstrType),
    'InstructionErrorType mismatch'
  );
  AssertEquals(41, CallbackCustomErr.Value, 'CustomError code mismatch');

  AssertEquals(
    'bGNVGCa1WFchzJStauKFVk7anzuFvA7hkMcx8Zi2o4euJaivzpwz8346yJ4Xn8H7XzMp44coTxdcDRd9d4yzj4m',
    CallbackSignature,
    'Signature mismatch'
  );

  // Teardown
  SUT.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeProgram;
var
  WS                : TMockWebSocketApiClient;
  WSIntf            : IWebSocketApiClient;
  SUT               : IStreamingRpcClient;
  ExpectedSend      : string;
  SubConfirm        : string;
  Notification      : string;
  SubscriptionState : ISubscriptionState;

  // captured from callback
  CallbackNotified  : Boolean;
  CallbackSlot      : UInt64;
  CallbackPubKey    : string;
  CallbackOwner     : string;
  CallbackExecutable: Boolean;
  CallbackRentEpoch : UInt64;
  CallbackLamports  : UInt64;
begin
  // Arrange: mock WS + real SUT
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  // Expected outgoing subscribe payload and incoming frames
  ExpectedSend := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Program', 'ProgramSubscribe.json'])
  );
  SubConfirm := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json'])
  );
  Notification := TTestUtils.ReadAllText(
    TTestUtils.CombineAll([FResDir, 'Program', 'ProgramSubscribeNotification.json'])
  );

  // Queue: confirmation then notification
  WS.EnqueueText(SubConfirm);
  WS.EnqueueText(Notification);

  CallbackExecutable := True;  // will flip to False from payload

  // Act
  SUT.Connect;

  SubscriptionState := SUT.SubscribeProgram(
    '11111111111111111111111111111111',
    procedure(Sub: ISubscriptionState; Env: TResponseValue<TAccountKeyPair>)
    begin
      if (Env <> nil) and (Env.Context <> nil) then
        CallbackSlot := Env.Context.Slot;

      if (Env <> nil) and (Env.Value <> nil) then
      begin
        CallbackPubKey     := Env.Value.PublicKey;
        if Env.Value.Account <> nil then
        begin
          CallbackOwner      := Env.Value.Account.Owner;
          CallbackExecutable := Env.Value.Account.Executable;
          CallbackRentEpoch  := Env.Value.Account.RentEpoch;
          CallbackLamports   := Env.Value.Account.Lamports;
        end;
      end;

      CallbackNotified := True;

      // optional: unsubscribe after first notification
      if Sub <> nil then
        Sub.Unsubscribe;
    end,
    TNullable<Int32>.None
  );

  // Assert subscribe request payload
  AssertNotNull(SubscriptionState, 'Subscription state should not be nil');
  AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Subscribe request JSON mismatch');

  // Deliver confirm + notification
  WS.TriggerAll;

  AssertTrue(CallbackNotified, 'Notification callback did not fire');
  AssertEquals(80854485, CallbackSlot, 'Context.Slot mismatch');
  AssertEquals('9FXD1NXrK6xFU8i4gLAgjj2iMEWTqJhSuQN8tQuDfm2e', CallbackPubKey, 'PublicKey mismatch');
  AssertEquals('11111111111111111111111111111111', CallbackOwner, 'Owner mismatch');
  AssertFalse(CallbackExecutable, 'Executable mismatch');
  AssertEquals(187, CallbackRentEpoch, 'RentEpoch mismatch');
  AssertEquals(458553192193, CallbackLamports, 'Lamports mismatch');

  // Teardown
  SUT.Disconnect;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeProgramFilters;
var
  WS        : TMockWebSocketApiClient;
  WSIntf    : IWebSocketApiClient;
  SUT       : IStreamingRpcClient;
  Expected  : string;
  ProgramId : string;
  DataSize  : TNullable<Integer>;
  MemCmpArr : TArray<TMemCmp>;
  I         : Integer;
begin
  // Arrange
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  Expected  := TTestUtils.ReadAllText(
                 TTestUtils.CombineAll([FResDir, 'Program', 'ProgramSubscribeFilters.json'])
               );
  ProgramId := '9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin';

  DataSize := TNullable<Integer>.Some(3228);

  SetLength(MemCmpArr, 1);
  MemCmpArr[0] := TMemCmp.Create;
  MemCmpArr[0].Offset := 45;
  MemCmpArr[0].Bytes  := 'CuieVDEDtLo7FypA9SbLM9saXFdb1dsshEkyErMqkRQq';

  // Act
  SUT.Connect;
  try
    SUT.SubscribeProgram(
      ProgramId,
      procedure(Sub: ISubscriptionState; Env: TResponseValue<TAccountKeyPair>)
      begin
        // no-op for this test (we only assert the outgoing payload)
      end,
      DataSize,
      MemCmpArr
    );

    AssertJsonMatch(Expected, WS.LastSentText, 'Program subscribe with filters JSON mismatch');
  finally
    for I := Low(MemCmpArr) to High(MemCmpArr) do
      MemCmpArr[I].Free;
    MemCmpArr := nil;

    // Teardown
    SUT.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeProgramMemcmpFilters;
var
  WS        : TMockWebSocketApiClient;
  WSIntf    : IWebSocketApiClient;
  SUT       : IStreamingRpcClient;
  Expected  : string;
  ProgramId : string;
  NoSize    : TNullable<Integer>;
  MemCmpArr : TArray<TMemCmp>;
  I         : Integer;
begin
  // Arrange
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  Expected  := TTestUtils.ReadAllText(
                 TTestUtils.CombineAll([FResDir, 'Program', 'ProgramSubscribeMemcmpFilter.json'])
               );
  ProgramId := '9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin';

  // No dataSize; only memcmp filter
  NoSize := TNullable<Integer>.None;

  SetLength(MemCmpArr, 1);
  MemCmpArr[0] := TMemCmp.Create;
  MemCmpArr[0].Offset := 45;
  MemCmpArr[0].Bytes  := 'CuieVDEDtLo7FypA9SbLM9saXFdb1dsshEkyErMqkRQq';

  // Act
  SUT.Connect;
  try
    SUT.SubscribeProgram(
      ProgramId,
      procedure(Sub: ISubscriptionState; Env: TResponseValue<TAccountKeyPair>)
      begin
        // no-op: we only verify the outgoing payload
      end,
      NoSize,
      MemCmpArr
    );

    // Assert: JSON sent equals expected
    AssertJsonMatch(Expected, WS.LastSentText, 'Program subscribe with memcmp filter JSON mismatch');
  finally
    // Free owned TMemCmp objects
    for I := Low(MemCmpArr) to High(MemCmpArr) do
      MemCmpArr[I].Free;
    MemCmpArr := nil;

    // Teardown
    SUT.Disconnect;
  end;
end;

 procedure TSolanaStreamingRpcClientTests.TestSubscribeProgramDataFilter;
var
  WS        : TMockWebSocketApiClient;
  WSIntf    : IWebSocketApiClient;
  SUT       : IStreamingRpcClient;
  Expected  : string;
  ProgramId : string;
  DataSize  : TNullable<Integer>;
begin
  // Arrange
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  Expected  := TTestUtils.ReadAllText(
                 TTestUtils.CombineAll([FResDir, 'Program', 'ProgramSubscribeDataSizeFilter.json'])
               );
  ProgramId := '9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin';

  DataSize := TNullable<Integer>.Some(3228);

  // Act
  SUT.Connect;
  try
    SUT.SubscribeProgram(
      ProgramId,
      procedure(Sub: ISubscriptionState; Env: TResponseValue<TAccountKeyPair>)
      begin
        // no-op: request-shape test only
      end,
      DataSize
    );

    // Assert
    AssertJsonMatch(Expected, WS.LastSentText, 'Program subscribe with dataSize filter JSON mismatch');
  finally
    SUT.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeProgramConfirmed;
var
  WS               : TMockWebSocketApiClient;
  WSIntf           : IWebSocketApiClient;
  SUT              : IStreamingRpcClient;
  ExpectedSend     : string;
  SubConfirm       : string;
  Notification     : string;
  SubscriptionState: ISubscriptionState;

  // captured values from the callback
  CallbackNotified : Boolean;
  CallbackSlot     : UInt64;
  CallbackPubKey   : string;
  CallbackOwner    : string;
  CallbackExec     : Boolean;
  CallbackRentEp   : UInt64;
  CallbackLamports : UInt64;
begin
  // Arrange: mock WS + real SUT
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  ExpectedSend := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'Program', 'ProgramSubscribeConfirmed.json'])
                  );
  SubConfirm   := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json'])
                  );
  Notification := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'Program', 'ProgramSubscribeNotification.json'])
                  );

  // Queue server frames
  WS.EnqueueText(SubConfirm);
  WS.EnqueueText(Notification);

  CallbackNotified := False;

  // Act
  SUT.Connect;
  try
    SubscriptionState :=
      SUT.SubscribeProgram(
        '11111111111111111111111111111111',
        procedure(Sub: ISubscriptionState; Env: TResponseValue<TAccountKeyPair>)
        begin
          if (Env <> nil) and (Env.Context <> nil) then
            CallbackSlot := Env.Context.Slot;

          if (Env <> nil) and (Env.Value <> nil) then
          begin
            CallbackPubKey  := Env.Value.PublicKey;
            if Env.Value.Account <> nil then
            begin
              CallbackOwner    := Env.Value.Account.Owner;
              CallbackExec     := Env.Value.Account.Executable;
              CallbackRentEp   := Env.Value.Account.RentEpoch;
              CallbackLamports := Env.Value.Account.Lamports;
            end;
          end;

          CallbackNotified := True;
          if Sub <> nil then
            Sub.Unsubscribe;
        end,
        TNullable<Integer>.None,
        nil,
        TCommitment.Confirmed
      );

    AssertNotNull(SubscriptionState, 'Subscription state should not be nil');

    AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Program subscribe (Confirmed) JSON mismatch');

    // Deliver frames (confirm + notification) to SUT
    WS.TriggerAll;

    AssertTrue(CallbackNotified, 'Notification callback did not fire');
    AssertEquals(80854485, CallbackSlot, 'Context.Slot mismatch');
    AssertEquals('9FXD1NXrK6xFU8i4gLAgjj2iMEWTqJhSuQN8tQuDfm2e', CallbackPubKey, 'PublicKey mismatch');
    AssertEquals('11111111111111111111111111111111', CallbackOwner, 'Owner mismatch');
    AssertFalse(CallbackExec, 'Executable mismatch');
    AssertEquals(187, CallbackRentEp, 'RentEpoch mismatch');
    AssertEquals(458553192193, CallbackLamports, 'Lamports mismatch');
  finally
    SUT.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeSlotInfo;
var
  WS               : TMockWebSocketApiClient;
  WSIntf           : IWebSocketApiClient;
  SUT              : IStreamingRpcClient;
  ExpectedSend     : string;
  SubConfirm       : string;
  Notification     : string;
  SubscriptionState: ISubscriptionState;

  // captured values from the callback
  CallbackNotified : Boolean;
  CallbackParent   : Integer;
  CallbackRoot     : Integer;
  CallbackSlot     : Integer;
begin
  // Arrange: mock WS + real SUT
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  ExpectedSend := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'SlotSubscribe.json'])
                  );
  SubConfirm   := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json'])
                  );
  Notification := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'SlotSubscribeNotification.json'])
                  );

  // Queue server frames
  WS.EnqueueText(SubConfirm);
  WS.EnqueueText(Notification);

  CallbackNotified := False;

  // Act
  SUT.Connect;
  try
    SubscriptionState :=
      SUT.SubscribeSlotInfo(
        procedure(Sub: ISubscriptionState; Info: TSlotInfo)
        begin
          CallbackParent := Info.Parent;
          CallbackRoot   := Info.Root;
          CallbackSlot   := Info.Slot;

          CallbackNotified := True;
          if Sub <> nil then
            Sub.Unsubscribe;
        end
      );

    AssertNotNull(SubscriptionState, 'Subscription state should not be nil');

    AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Slot subscribe JSON mismatch');

    // Deliver frames (confirm + notification) to SUT
    WS.TriggerAll;

    // Assert callback + values
    AssertTrue(CallbackNotified, 'Notification callback did not fire');
    AssertEquals(75, CallbackParent, 'Parent mismatch');
    AssertEquals(44, CallbackRoot,   'Root mismatch');
    AssertEquals(76, CallbackSlot,   'Slot mismatch');
  finally
    SUT.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeRoot;
var
  WS               : TMockWebSocketApiClient;
  WSIntf           : IWebSocketApiClient;
  SUT              : IStreamingRpcClient;
  ExpectedSend     : string;
  SubConfirm       : string;
  Notification     : string;
  SubscriptionState: ISubscriptionState;

  // captured value from the callback
  CallbackNotified : Boolean;
  CallbackRoot     : Integer;
begin
  // Arrange: mock WS + real SUT
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  ExpectedSend := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'RootSubscribe.json'])
                  );
  SubConfirm   := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json'])
                  );
  Notification := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'RootSubscribeNotification.json'])
                  );

  // Queue server frames
  WS.EnqueueText(SubConfirm);
  WS.EnqueueText(Notification);

  CallbackNotified := False;

  // Act
  SUT.Connect;
  try
    SubscriptionState :=
      SUT.SubscribeRoot(
        procedure(Sub: ISubscriptionState; Value: Integer)
        begin
          CallbackRoot     := Value;
          CallbackNotified := True;
          if Sub <> nil then
            Sub.Unsubscribe;
        end
      );

    AssertNotNull(SubscriptionState, 'Subscription state should not be nil');

    AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Root subscribe JSON mismatch');

    // Deliver frames (confirm + notification) to SUT
    WS.TriggerAll;

    // Assert callback + value
    AssertTrue(CallbackNotified, 'Notification callback did not fire');
    AssertEquals(42, CallbackRoot, 'Root value mismatch');
  finally
    SUT.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeSignature;
var
  WS                : TMockWebSocketApiClient;
  WSIntf            : IWebSocketApiClient;
  SUT               : IStreamingRpcClient;
  ExpectedSend      : string;
  SubConfirm        : string;
  Notification      : string;
  Sub               : ISubscriptionState;

  // callback flags
  CallbackFired     : Boolean;
  HasValue          : Boolean;
  HasError          : Boolean;

  // subscription-changed capture
  ChangedSignal     : TEvent;
  LastChange        : ISubscriptionEvent;
begin
  // Arrange
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  ExpectedSend := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'Signature', 'SignatureSubscribe.json']));
  SubConfirm   := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json']));
  Notification := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'Signature', 'SignatureSubscribeNotification.json']));

  // server frames: confirm -> notification
  WS.EnqueueText(SubConfirm);
  WS.EnqueueText(Notification);

  CallbackFired := False;
  HasValue      := False;
  HasError      := False;

  ChangedSignal := TEvent.Create(nil, True, False, '');
  try
    // Act
    SUT.Connect;
    Sub :=
      SUT.SubscribeSignature(
        '4orRpuqStpJDvcpBy3vDSV4TDTGNbefmqYUnG2yVnKwjnLFqCwY4h5cBTAKakKek4inuxHF71LuscBS1vwSLtWcx',
          procedure(ASub: ISubscriptionState; Env: TResponseValue<TErrorResult>)
          begin
            CallbackFired := True;
            HasValue := (Env <> nil) and (Env.Value <> nil);
            HasError := HasValue and (Env.Value.Error <> nil);
            // signature notifications auto-unsubscribe (handled by client)
          end,
        TCommitment.Finalized
      );

    // listen for auto-unsubscribe
    Sub.AddSubscriptionChanged(
      procedure(S: ISubscriptionState; E: ISubscriptionEvent)
      begin
        LastChange := E;
        if (E <> nil) and (E.Status = TSubscriptionStatus.Unsubscribed) then
          ChangedSignal.SetEvent;
      end
    );

    AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Signature subscribe JSON mismatch');

    // Drive confirm + notification
    WS.TriggerAll;

    // Assert via boolean flags
    AssertTrue(CallbackFired, 'Signature callback did not fire');
    AssertTrue(HasValue, 'Expected Env.Value to be assigned');
    AssertFalse(HasError, 'Expected Env.Value.Error to be nil');

    // Expect auto-unsubscribe after signature notification
    case ChangedSignal.WaitFor(3000) of
      wrSignaled: ; // ok
    else
      Fail('Did not receive Unsubscribed change event');
    end;

    AssertNotNull(LastChange, 'No subscription change captured');
    AssertEquals(Ord(TSubscriptionStatus.Unsubscribed), Ord(LastChange.Status), 'Subscription status mismatch');
    AssertEquals(Ord(TSubscriptionStatus.Unsubscribed), Ord(Sub.State), 'Sub.State mismatch');
  finally
    ChangedSignal.Free;
    SUT.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeSignature_ErrorNotification;
var
  WS                : TMockWebSocketApiClient;
  WSIntf            : IWebSocketApiClient;
  SUT               : IStreamingRpcClient;

  ExpectedSend      : string;
  SubConfirm        : string;
  Notification      : string;

  Sub               : ISubscriptionState;

  // callback flags
  CallbackFired     : Boolean;
  HasValue          : Boolean;
  HasError          : Boolean;

  // captured error details
  CapErrType        : TTransactionErrorType;
  CapInstrErrType   : TInstructionErrorType;
  CapCustomErr      : TNullable<UInt32>;

  // subscription change signaling
  ChangedSignal     : TEvent;
  LastChange        : ISubscriptionEvent;
begin
  // Arrange
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  ExpectedSend := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'Signature', 'SignatureSubscribe.json']));
  SubConfirm   := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json']));
  Notification := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'Signature', 'SignatureSubscribeErrorNotification.json']));

  // server frames: confirm -> error notification
  WS.EnqueueText(SubConfirm);
  WS.EnqueueText(Notification);

  ChangedSignal := TEvent.Create(nil, True, False, '');
  try
    // Act
    SUT.Connect;

    Sub :=
      SUT.SubscribeSignature(
        '4orRpuqStpJDvcpBy3vDSV4TDTGNbefmqYUnG2yVnKwjnLFqCwY4h5cBTAKakKek4inuxHF71LuscBS1vwSLtWcx',
          procedure(ASub: ISubscriptionState; Env: TResponseValue<TErrorResult>)
          begin
            CallbackFired := True;
            HasValue := (Env <> nil) and (Env.Value <> nil);
            HasError := HasValue and (Env.Value.Error <> nil);

            if HasError then
            begin
              CapErrType      := Env.Value.Error.&Type;
              if Env.Value.Error.InstructionError <> nil then
              begin
                CapInstrErrType := Env.Value.Error.InstructionError.&Type;
                CapCustomErr    := Env.Value.Error.InstructionError.CustomError;
              end;
            end;
            // client auto-unsubscribes on signature notifications
          end,
        TCommitment.Finalized
      );

    // subscribe to state changes (expect Unsubscribed after notification)
    Sub.AddSubscriptionChanged(
      procedure(S: ISubscriptionState; E: ISubscriptionEvent)
      begin
        LastChange := E;
        if (E <> nil) and (E.Status = TSubscriptionStatus.Unsubscribed) then
          ChangedSignal.SetEvent;
      end
    );

    AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Signature subscribe JSON mismatch');

    // Drive confirm + error notification
    WS.TriggerAll;

    AssertTrue(CallbackFired, 'Signature callback did not fire');
    AssertTrue(HasValue, 'Expected Env.Value to be assigned');
    AssertTrue(HasError, 'Expected Env.Value.Error to be assigned (error notification)');

    AssertEquals(Ord(TTransactionErrorType.InstructionError), Ord(CapErrType), 'Error.Type mismatch');
    AssertEquals(Ord(TInstructionErrorType.Custom), Ord(CapInstrErrType), 'InstructionError.Type mismatch');
    AssertEquals(0, CapCustomErr.Value, 'InstructionError.CustomError mismatch');

    // Expect Unsubscribed after signature notification
    case ChangedSignal.WaitFor(3000) of
      wrSignaled: ; // ok
    else
      Fail('Did not receive Unsubscribed change event');
    end;

    AssertNotNull(LastChange, 'No subscription change captured');
    AssertEquals(Ord(TSubscriptionStatus.Unsubscribed), Ord(LastChange.Status), 'Subscription status mismatch');
    AssertEquals(Ord(TSubscriptionStatus.Unsubscribed), Ord(Sub.State), 'Sub.State mismatch');
  finally
    ChangedSignal.Free;
    SUT.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeSignature_Processed;
var
  WS                : TMockWebSocketApiClient;
  WSIntf            : IWebSocketApiClient;
  SUT               : IStreamingRpcClient;

  ExpectedSend      : string;
  SubConfirm        : string;
  Notification      : string;

  Sub               : ISubscriptionState;

  // callback flags
  CallbackFired     : Boolean;
  HasValue          : Boolean;
  HasError          : Boolean;

  // subscription change signaling
  ChangedSignal     : TEvent;
  LastChange        : ISubscriptionEvent;
begin
  // Arrange
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  ExpectedSend := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'Signature', 'SignatureSubscribeProcessed.json']));
  SubConfirm   := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json']));
  Notification := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'Signature', 'SignatureSubscribeNotification.json']));

  // server frames: confirm -> success notification (no error)
  WS.EnqueueText(SubConfirm);
  WS.EnqueueText(Notification);

  CallbackFired := False;
  HasValue      := False;
  HasError      := False;

  ChangedSignal := TEvent.Create(nil, True, False, '');
  try
    // Act
    SUT.Connect;

    Sub :=
      SUT.SubscribeSignature(
        '4orRpuqStpJDvcpBy3vDSV4TDTGNbefmqYUnG2yVnKwjnLFqCwY4h5cBTAKakKek4inuxHF71LuscBS1vwSLtWcx',
          procedure(ASub: ISubscriptionState; Env: TResponseValue<TErrorResult>)
          begin
            CallbackFired := True;
            HasValue := (Env <> nil) and (Env.Value <> nil);
            HasError := HasValue and (Env.Value.Error <> nil);
          end,
        TCommitment.Processed
      );

    // listen for Unsubscribed transition
    Sub.AddSubscriptionChanged(
      procedure(S: ISubscriptionState; E: ISubscriptionEvent)
      begin
        LastChange := E;
        if (E <> nil) and (E.Status = TSubscriptionStatus.Unsubscribed) then
          ChangedSignal.SetEvent;
      end
    );

    AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Signature subscribe (Processed) JSON mismatch');

    // Drive confirm + notification
    WS.TriggerAll;

    // Assertions
    AssertTrue(CallbackFired, 'Signature callback did not fire');
    AssertTrue(HasValue, 'Expected Env.Value to be assigned');
    AssertFalse(HasError, 'Did not expect Env.Value.Error for non-error notification');

    // Expect Unsubscribed after notification
    case ChangedSignal.WaitFor(3000) of
      wrSignaled: ; // ok
    else
      Fail('Did not receive Unsubscribed change event');
    end;

    AssertNotNull(LastChange, 'No subscription change captured');
    AssertEquals(Ord(TSubscriptionStatus.Unsubscribed), Ord(LastChange.Status), 'Subscription status mismatch');
    AssertEquals(Ord(TSubscriptionStatus.Unsubscribed), Ord(Sub.State), 'Sub.State mismatch');
  finally
    ChangedSignal.Free;
    SUT.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeBadAccount;
var
  WS            : TMockWebSocketApiClient;
  WSIntf        : IWebSocketApiClient;
  SUT           : IStreamingRpcClient;

  ExpectedSend  : string;
  SubConfirm    : string;

  PubKey        : string;
  Sub           : ISubscriptionState;

  // subscription change capture
  GotChange     : TEvent;
  LastEvent     : ISubscriptionEvent;
begin
  // Arrange
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  ExpectedSend := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'Account', 'BadAccountSubscribe.json']));
  SubConfirm   := TTestUtils.ReadAllText(
                    TTestUtils.CombineAll([FResDir, 'Account', 'BadAccountSubscribeResult.json']));

  WS.EnqueueText(SubConfirm);

  PubKey    := 'invalidkey1';
  GotChange := TEvent.Create(nil, True, False, '');
  try
    // Act
    SUT.Connect;

    Sub :=
      SUT.SubscribeAccountInfo(
        PubKey,
        procedure(ASub: ISubscriptionState; Env: TResponseValue<TAccountInfo>)
        begin
          // No-op: for a bad account, the server fails the subscription request;
          // the callback for account notifications won't be invoked.
        end
      );

    // Capture subscription change (expect ErrorSubscribing)
    Sub.AddSubscriptionChanged(
      procedure(S: ISubscriptionState; E: ISubscriptionEvent)
      begin
        LastEvent := E;
        GotChange.SetEvent;
      end
    );

    AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Bad-account subscribe JSON mismatch');

    // Drive the queued error response
    WS.TriggerAll;

    // Wait for the ErrorSubscribing event
    case GotChange.WaitFor(3000) of
      wrSignaled: ; // ok
    else
      Fail('Did not receive subscription change event for bad account');
    end;

    AssertNotNull(LastEvent, 'Missing subscription event payload');
    AssertEquals('-32602', LastEvent.Code, 'Error code mismatch');
    AssertEquals(Ord(TSubscriptionStatus.ErrorSubscribing), Ord(LastEvent.Status), 'Event status mismatch');
    AssertEquals('Invalid Request: Invalid pubkey provided', LastEvent.Error, 'Error message mismatch');

    AssertEquals(Ord(TSubscriptionStatus.ErrorSubscribing), Ord(Sub.State), 'Subscription state mismatch');
  finally
    GotChange.Free;
    SUT.Disconnect;
  end;
end;

procedure TSolanaStreamingRpcClientTests.TestSubscribeAccountBigPayload;
var
  WS                 : TMockWebSocketApiClient;
  WSIntf             : IWebSocketApiClient;
  SUT                : IStreamingRpcClient;

  ExpectedSend       : string;
  SubConfirm         : string;
  Notification       : string;
  ExpectedDataBody   : string;

  PubKey             : string;
  Sub                : ISubscriptionState;

  // subscription change capture
  GotSubscribedEvt   : Boolean;
  LastEvt            : ISubscriptionEvent;

  // notification capture
  CallbackNotified   : Boolean;
  EnvWasSet        : Boolean;
  ValueWasSet      : Boolean;
  EnvBase64     : string;
  EnvEncodingTag: string;
begin
  // Arrange: mock WS + real SUT
  WS     := TMockWebSocketApiClient.Create;
  WSIntf := WS;
  SUT    := TSolanaStreamingRpcClient.Create(TestnetStreamingUrl, WSIntf);

  // Files
  ExpectedSend     := TTestUtils.ReadAllText(
                        TTestUtils.CombineAll([FResDir, 'Account', 'BigAccountSubscribe.json']));
  SubConfirm       := TTestUtils.ReadAllText(
                        TTestUtils.CombineAll([FResDir, 'SubscribeConfirm.json']));
  Notification     := TTestUtils.ReadAllText(
                        TTestUtils.CombineAll([FResDir, 'Account', 'BigAccountNotificationPayload.json']));
  ExpectedDataBody := TTestUtils.ReadAllText(
                        TTestUtils.CombineAll([FResDir, 'Account', 'BigAccountNotificationPayloadData.txt']));

  // Queue frames: subscription confirmation then BIG notification payload
  WS.EnqueueText(SubConfirm);
  WS.EnqueueText(Notification);

  PubKey := 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';

  try
    // Act
    SUT.Connect;

    Sub :=
      SUT.SubscribeAccountInfo(
        PubKey,
        procedure(ASub: ISubscriptionState; Env: TResponseValue<TAccountInfo>)
        begin
          // Capture notification
          EnvWasSet   := (Env <> nil);
          ValueWasSet := (Env <> nil) and (Env.Value <> nil);
          EnvBase64 := Env.Value.Data[0];
          EnvEncodingTag := Env.Value.Data[1];
          CallbackNotified := True;
        end
      );

    // Track "Subscribed" event after confirm
    Sub.AddSubscriptionChanged(
      procedure(S: ISubscriptionState; E: ISubscriptionEvent)
      begin
        LastEvt := E;
        if (E.Status = TSubscriptionStatus.Subscribed) then
          GotSubscribedEvt := True;
      end
    );

    AssertJsonMatch(ExpectedSend, WS.LastSentText, 'Subscribe request JSON mismatch');

    // Drive both queued frames (confirm -> subscribed; then big payload notification)
    WS.TriggerAll;

    AssertTrue(GotSubscribedEvt, 'Did not receive Subscribed event');
    AssertNotNull(LastEvt, 'Missing subscription event');
    AssertEquals(Ord(TSubscriptionStatus.Subscribed), Ord(LastEvt.Status), 'Subscription status mismatch');
    AssertTrue((LastEvt.Error = '') and (LastEvt.Code = ''), 'Unexpected error/code on subscribe confirm');
    AssertEquals(Ord(TSubscriptionStatus.Subscribed), Ord(Sub.State), 'Subscription state mismatch');

    AssertTrue(CallbackNotified, 'Notification callback did not fire');
    AssertTrue(EnvWasSet,   'Callback environment was nil');
    AssertTrue(ValueWasSet, 'Callback environment value was nil');

    AssertEquals(ExpectedDataBody, EnvBase64, 'AccountInfo.Data[0] mismatch');
    AssertEquals('base64', EnvEncodingTag, 'AccountInfo.Data[1] encoding tag mismatch');
  finally
    SUT.Disconnect;
  end;
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcStreamingClientTests);
{$ELSE}
  RegisterTest(TSolanaStreamingRpcClientTests.Suite);
{$ENDIF}

end.

