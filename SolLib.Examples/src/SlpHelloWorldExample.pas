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

unit SlpHelloWorldExample;

interface

uses
  System.SysUtils,
  System.TypInfo,
  SlpWallet,
  SlpAccount,
  SlpPublicKey,
  SlpExample,
  SlpRequestResult,
  SlpRpcModel,
  SlpRpcMessage,
  SlpRpcEnum,
  SlpSolanaRpcClient,
  SlpSolanaStreamingRpcClient,
  SlpWebSocketApiClient,
  SlpTransactionBuilder,
  SlpMemoProgram,
  SlpSystemProgram,
  SlpClientFactory,
  //SlpSecureBridgeWebSocketClient,
  SlpSgcWebSocketClient;

type
  /// <summary>
  /// Hello World with WebSocket streaming: transfer -> subscribe to signature;
  /// on confirmation, print balance.
  /// </summary>
  THelloWorldExample = class(TBaseExample)
  private
    const
    /// <summary>
    /// Mnemonic.
    /// </summary>
    MnemonicWords = TBaseExample.MNEMONIC_WORDS;
  public
    procedure Run; override;
  end;

implementation

{ THelloWorldExample }

procedure THelloWorldExample.Run;
var
  LRpc      : IRpcClient;
  LStreamingRpc   : IStreamingRpcClient;
  LWebSocketClient: IWebSocketApiClient;
  LWallet   : IWallet;
  LFrom       : IAccount;
  LTo         : IAccount;
  LBlock      : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LBalance  : IRequestResult<TResponseValue<UInt64>>;
  LTxBuilder  : ITransactionBuilder;
  LMsgBytes   : TBytes;
  LMsgSignature: TBytes;
  LTxBytes    : TBytes;
  LSignature  : string;
  LSubscription: ISubscriptionState;
begin
  //LWebSocketClient := TWebSocketApiClient.Create(TSecureBridgeWebSocketClientImpl.Create(nil, Logger));
  LWebSocketClient := TWebSocketApiClient.Create(TSgcWebSocketClientImpl.Create(nil, Logger));
  // RPC + Streaming + Wallet
  LRpc    := TestNetRpcClient;
  LStreamingRpc := TClientFactory.GetStreamingClient(TCluster.TestNet, LWebSocketClient, Logger);
  LWallet := TWallet.Create(MnemonicWords);
  LFrom   := LWallet.GetAccountByIndex(0);
  LTo   := LWallet.GetAccountByIndex(1);

  Writeln('Hello World!');
  Writeln('Mnemonic: ' + LWallet.Mnemonic.ToString);
  Writeln('From PubKey  : ' + LFrom.PublicKey.Key);
  Writeln('From PrivKey : ' + LFrom.PrivateKey.Key);
  Writeln('To PubKey  : ' + LTo.PublicKey.Key);

  // Receiver Initial balance
  LBalance := LRpc.GetBalance(LTo.PublicKey.Key);
  if (LBalance <> nil) and LBalance.WasSuccessful and (LBalance.Result <> nil) then
    Writeln(Format('Receiver Balance (Pre-Transfer): %d', [LBalance.Result.Value]))
  else
    Writeln('Balance(Pre-Transfer): <unavailable>');

  // Connect streaming
  LStreamingRpc.Connect;

  LBlock := LRpc.GetLatestBlockHash;

  Writeln('BlockHash >> ' + LBlock.Result.Value.Blockhash);

  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
    .SetFeePayer(LFrom.PublicKey)
    .AddInstruction(
      TSystemProgram.Transfer(
        LFrom.PublicKey,
        LTo.PublicKey,
        1000
      )
    )
    .AddInstruction(
      TMemoProgram.NewMemo(
        LFrom.PublicKey,
        'Hello from SolLib :)'
      )
    );

  LMsgBytes := LTxBuilder.CompileMessage;
  LMsgSignature := LFrom.Sign(LMsgBytes);

  LTxBytes := LTxBuilder
               .AddSignature(LMsgSignature)
               .Serialize;

  LSignature := SubmitTxSendAndLog(LTxBytes);

  Writeln('Transfer TxHash: ' + LSignature);

  // Subscribe to the transfer signature; do follow-up work when it's confirmed.
 LSubscription := LStreamingRpc.SubscribeSignature(
    LSignature,
    procedure(ASub: ISubscriptionState; AData: TResponseValue<TErrorResult>)
    var
      LBal   : IRequestResult<TResponseValue<UInt64>>;
    begin
      // Success path: Value present AND no error
      if (AData <> nil) and (AData.Value <> nil) and (AData.Value.Error = nil) then
      begin
        // Re-check balance after transfer
        LBal := LRpc.GetBalance(LTo.PublicKey.Key);
        if (LBal <> nil) and LBal.WasSuccessful and (LBal.Result <> nil) then
          Writeln(Format('Receiver Balance (Post-Transfer): %d', [LBal.Result.Value]))
        else
          Writeln('Balance (Post-Transfer): <unavailable>');

      end
      else
      begin
        // Error case (surface type if available)
        if (AData <> nil) and (AData.Value <> nil) and (AData.Value.Error <> nil) then
          Writeln('Transaction error: ' + GetEnumName(TypeInfo(TTransactionErrorType), Ord(AData.Value.Error.&Type)))
        else
          Writeln('Transaction error: <unknown>');

      end;
    end,
    TCommitment.Finalized
  );
end;

end.

