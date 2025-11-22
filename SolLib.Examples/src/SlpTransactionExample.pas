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

unit SlpTransactionExample;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpWallet,
  SlpAccount,
  SlpPublicKey,
  SlpTransactionDomain,
  SlpTransactionInstruction,
  SlpSystemProgram,
  SlpTokenProgram,
  SlpMemoProgram,
  SlpComputeBudgetProgram,
  SlpRpcModel,
  SlpSolanaRpcClient,
  SlpNonceAccount,
  SlpRpcMessage,
  SlpMessageDomain,
  SlpTransactionBuilder,
  SlpRequestResult,
  SlpDataEncoders,
  SlpExample,
  SlpComputeBudgetEstimator,
  SlpTokenMintHelper;

const
  /// <summary>
  /// Mnemonic.
  /// </summary>
  MnemonicWords = TBaseExample.MNEMONIC_WORDS;

type
  /// <summary>
  /// Simple transfer + memo using TTransactionBuilder.
  /// </summary>
  TTransactionBuilderExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// Simple transfer + memo (via account private key) using TTransactionBuilder.
  /// </summary>
  TTransactionBuilderUsingPrivateKeyExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// Transfer using a durable nonce (AdvanceNonce + NonceInformation).
  /// </summary>
  TTransferWithDurableNonceExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// Transfer with priority fees (Compute Budget).
  /// </summary>
  TTransferWithPriorityFeesExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// Transfer with estimated priority fees (Compute Budget).
  /// https://solana.com/docs/core/fees
  /// https://solana.com/developers/cookbook/transactions/optimize-compute
  /// https://solana.com/developers/guides/advanced/how-to-optimize-compute
  /// https://solana.com/developers/cookbook/transactions/add-priority-fees
  /// </summary>
  TTransferWithEstimatedPriorityFeesExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// Transfer with estimated priority fees (Compute Budget).
  /// https://solana.com/docs/core/fees
  /// https://solana.com/developers/cookbook/transactions/optimize-compute
  /// https://solana.com/developers/guides/advanced/how-to-optimize-compute
  /// https://solana.com/developers/cookbook/transactions/add-priority-fees
  /// </summary>
  TTransferWithEstimatedPriorityFeesExampleV2 = class(TBaseExample)
  public
    procedure Run; override;
  end;

    /// <summary>
   /// Build+send a tx with ComputeBudget, check balances, fetch the tx via RPC,
  /// and decode its instructions using the built-in instruction decoder.
  /// </summary>
  TTxBuilderComputeBudgetBalanceAndDecodeExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// Burn example that compiles message, populates signatures, serializes & submits.
  /// </summary>
  TBurnExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// Build, compile message, sign manually, add signature, serialize, simulate, send.
  /// </summary>
  TAddSignatureExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

implementation

{ TTransactionBuilderExample }

procedure TTransactionBuilderExample.Run;
var
  LRpc      : IRpcClient;
  LWallet   : IWallet;
  LFrom     : IAccount;
  LTo       : IAccount;
  LTx       : TBytes;
  LBlock    : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LSignature: string;
  LTxBuilder: ITransactionBuilder;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LFrom := LWallet.GetAccountByIndex(0);
  LTo   := LWallet.GetAccountByIndex(8);

  LBlock := LRpc.GetLatestBlockHash;
  if (LBlock <> nil) and LBlock.WasSuccessful and (LBlock.Result <> nil) then
    Writeln(Format('BlockHash >> %s', [LBlock.Result.Value.Blockhash]));

  LTxBuilder := TTransactionBuilder.Create;
  LTx := LTxBuilder
           .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
           .SetFeePayer(LFrom.PublicKey)
           .AddInstruction(TSystemProgram.Transfer(LFrom.PublicKey, LTo.PublicKey, 10000000))
           .AddInstruction(TMemoProgram.NewMemo(LFrom.PublicKey, 'Hello from SolLib :)'))
           .Build(LFrom);

  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);
end;

{ TTransactionBuilderUsingPrivateKeyExample }

procedure TTransactionBuilderUsingPrivateKeyExample.Run;
const
  SenderPrivateKey = TBaseExample.ACCOUNT_PRIVATE_KEY;
  ReceiverPublicKey = '9KmfMX4Ne5ocb8C7PwjmJTWTpQTQcPhkeD2zY35mawhq';
var
  LRpc      : IRpcClient;
  LFrom     : IAccount;
  LTo       : IPublicKey;
  LTx       : TBytes;
  LBlock    : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LSignature: string;
  LTxBuilder: ITransactionBuilder;
begin
  LRpc    := TestNetRpcClient;

  LFrom := TAccount.FromSecretKey(SenderPrivateKey);
  LTo   := TPublicKey.FromString(ReceiverPublicKey);

  LBlock := LRpc.GetLatestBlockHash;
  if (LBlock <> nil) and LBlock.WasSuccessful and (LBlock.Result <> nil) then
    Writeln(Format('BlockHash >> %s', [LBlock.Result.Value.Blockhash]));

  LTxBuilder := TTransactionBuilder.Create;
  LTx := LTxBuilder
           .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
           .SetFeePayer(LFrom.PublicKey)
           .AddInstruction(TSystemProgram.Transfer(LFrom.PublicKey, LTo, 10000000))
           .AddInstruction(TMemoProgram.NewMemo(LFrom.PublicKey, 'Hello from SolLib :)'))
           .Build(LFrom);

  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);
end;

{ TTransferWithDurableNonceExample }

procedure TTransferWithDurableNonceExample.Run;
var
  LRpc         : IRpcClient;
  LWallet      : IWallet;
  LOwner       : IAccount;
  LNonceAcc    : IAccount;
  LTo          : IAccount;
  LNonceAccInfo: IRequestResult<TResponseValue<TAccountInfo>>;
  LAcctDataBytes: TBytes;
  LNonceData   : INonceAccount;
  LNonceInfo   : INonceInformation;
  LSignature   : string;
  LTxBuilder   : ITransactionBuilder;
  LTx          : TBytes;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LOwner := LWallet.GetAccountByIndex(0);
  Writeln('OwnerAccount: ' + LOwner.ToString);

  LNonceAcc := LWallet.GetAccountByIndex(1119);
  Writeln('NonceAccount: ' + LNonceAcc.ToString);

  LTo := LWallet.GetAccountByIndex(1);
  Writeln('ToAccount: ' + LTo.ToString);

  // Get the Nonce Account to get the Nonce to use for the transaction
  LNonceAccInfo := LRpc.GetAccountInfo(LNonceAcc.PublicKey.Key);
  LAcctDataBytes := TEncoders.Base64.DecodeData(LNonceAccInfo.Result.Value.Data[0]);
  LNonceData := TNonceAccount.Deserialize(LAcctDataBytes);

  Writeln('NonceAccount Authority: ' + LNonceData.Authorized.Key);
  Writeln('NonceAccount Nonce: ' + LNonceData.Nonce.Key);

  // Initialize the nonce information to be used with the transaction
  LNonceInfo := TNonceInformation.Create(
    LNonceData.Nonce.Key,
    TSystemProgram.AdvanceNonceAccount(LNonceAcc.PublicKey, LOwner.PublicKey)
  );

  LTxBuilder := TTransactionBuilder.Create;
  LTx := LTxBuilder
           .SetFeePayer(LOwner.PublicKey)
           .SetNonceInformation(LNonceInfo)
           .AddInstruction(
             TSystemProgram.Transfer(
               LOwner.PublicKey,
               LTo.PublicKey,
               1000000000
             )
           )
           .Build(LOwner);

  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);
end;

{ TTransferWithPriorityFeesExample }

procedure TTransferWithPriorityFeesExample.Run;
var
  LRpc        : IRpcClient;
  LWallet     : IWallet;
  LOwner      : IAccount;
  LTo         : IAccount;
  LBlock      : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LPrioFees   : IPriorityFeesInformation;
  LTx         : TBytes;
  LSignature   : string;
  LTxBuilder   : ITransactionBuilder;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LOwner := LWallet.GetAccountByIndex(0);
  Writeln('OwnerAccount: ' + LOwner.ToString);

  LTo := LWallet.GetAccountByIndex(1);
  Writeln('ToAccount: ' + LTo.ToString);

  // Fetch recent blockhash
  LBlock := LRpc.GetLatestBlockHash;

  // Prepare priority fees information
  LPrioFees := TPriorityFeesInformation.Create(
    TComputeBudgetProgram.SetComputeUnitLimit(400000), // limit
    TComputeBudgetProgram.SetComputeUnitPrice(100000)  // price (micro-lamports)
  );

  LTxBuilder := TTransactionBuilder.Create;
  LTx := LTxBuilder
           .SetFeePayer(LOwner.PublicKey)
           .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
           .AddInstruction(
             TSystemProgram.Transfer(
               LOwner.PublicKey,
               LTo.PublicKey,
               1000000
             )
           )
           .SetPriorityFeesInformation(LPrioFees)
           .Build(LOwner);

  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);
end;

{ TTransferWithEstimatedPriorityFeesExample }

procedure TTransferWithEstimatedPriorityFeesExample.Run;
var
  LRpc        : IRpcClient;
  LWallet     : IWallet;
  LOwner      : IAccount;
  LTo         : IAccount;
  LBlock      : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LSimPrioFees, LActualPrioFees   : IPriorityFeesInformation;
  LSimTx, LActualTx         : TBytes;
  LSignature   : string;
  LSimTxBuilder, LActualTxBuilder   : ITransactionBuilder;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LOwner := LWallet.GetAccountByIndex(0);
  Writeln('OwnerAccount: ' + LOwner.ToString);

  LTo := LWallet.GetAccountByIndex(1);
  Writeln('ToAccount: ' + LTo.ToString);

  // Fetch recent blockhash
  LBlock := LRpc.GetLatestBlockHash;

  // Prepare simulation priority fees information
  LSimPrioFees := TPriorityFeesInformation.Create(
    TComputeBudgetProgram.SetComputeUnitLimit(400000), // limit
    TComputeBudgetProgram.SetComputeUnitPrice(100000)  // price (micro-lamports)
  );

  LSimTxBuilder := TTransactionBuilder.Create;
  LSimTx := LSimTxBuilder
           .SetFeePayer(LOwner.PublicKey)
           .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
           .AddInstruction(
             TSystemProgram.Transfer(
               LOwner.PublicKey,
               LTo.PublicKey,
               1000000
             )
           )
           .SetPriorityFeesInformation(LSimPrioFees)
           .Build(LOwner);

  // Estimate priority fees information
  LActualPrioFees := TComputeBudgetEstimator.EstimatePriorityFeesInformation(
    LRpc,
    LSimTx,
    [ LOwner.PublicKey.Key ]
  );

  LActualTxBuilder := TTransactionBuilder.Create;
  LActualTx := LActualTxBuilder
           .SetFeePayer(LOwner.PublicKey)
           .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
           .AddInstruction(
             TSystemProgram.Transfer(
               LOwner.PublicKey,
               LTo.PublicKey,
               1000000
             )
           )
           .SetPriorityFeesInformation(LActualPrioFees)
           .Build(LOwner);

  LSignature := SubmitTxSendAndLog(LActualTx);
  PollConfirmedTx(LSignature);
end;

{ TTransferWithEstimatedPriorityFeesExampleV2 }

procedure TTransferWithEstimatedPriorityFeesExampleV2.Run;
var
  LRpc        : IRpcClient;
  LWallet     : IWallet;
  LOwner      : IAccount;
  LTo         : IAccount;
  LBlock      : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LSimPrioFees, LActualPrioFees   : IPriorityFeesInformation;
  LSimTx, LActualTx         : TBytes;
  LSignature   : string;
  LSimTxBuilder, LActualTxBuilder   : ITransactionBuilder;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LOwner := LWallet.GetAccountByIndex(0);
  Writeln('OwnerAccount: ' + LOwner.ToString);

  LTo := LWallet.GetAccountByIndex(1);
  Writeln('ToAccount: ' + LTo.ToString);

  // Fetch recent blockhash
  LBlock := LRpc.GetLatestBlockHash;

  // Prepare simulation priority fees information
  LSimPrioFees := TPriorityFeesInformation.Create(
    TComputeBudgetProgram.SetComputeUnitLimit(400000), // limit
    TComputeBudgetProgram.SetComputeUnitPrice(100000)  // price (micro-lamports)
  );

  LSimTxBuilder := TTransactionBuilder.Create;
  LSimTx := LSimTxBuilder
           .SetFeePayer(LOwner.PublicKey)
           .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
           .AddInstruction(
             TSystemProgram.Transfer(
               LOwner.PublicKey,
               LTo.PublicKey,
               1000000
             )
           )
           .SetPriorityFeesInformation(LSimPrioFees)
           .Build(LOwner);

  // Estimate priority fees information
  LActualPrioFees := TComputeBudgetEstimator.EstimatePriorityFeesInformationV2(
    LRpc,
    LSimTx,
    [ LOwner.PublicKey.Key ]
  );

  LActualTxBuilder := TTransactionBuilder.Create;
  LActualTx := LActualTxBuilder
           .SetFeePayer(LOwner.PublicKey)
           .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
           .AddInstruction(
             TSystemProgram.Transfer(
               LOwner.PublicKey,
               LTo.PublicKey,
               1000000
             )
           )
           .SetPriorityFeesInformation(LActualPrioFees)
           .Build(LOwner);

  LSignature := SubmitTxSendAndLog(LActualTx);
  PollConfirmedTx(LSignature);
end;

{ TTxBuilderComputeBudgetBalanceAndDecodeExample }

procedure TTxBuilderComputeBudgetBalanceAndDecodeExample.Run;
const
  Memo = 'SolLib TxBuilder+ComputeBudget+Decode';
var
  LRpc                      : IRpcClient;
  LWallet                   : IWallet;
  LFrom, LTo                : IAccount;
  LBlock                    : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LBeforeBal, LAfterBal     : IRequestResult<TResponseValue<UInt64>>;
  LSimTx, LActualTx         : TBytes;
  LSignature                : string;
  LSimTxBuilder             : ITransactionBuilder;
  LActualTxBuilder          : ITransactionBuilder;
  LSimPrioFees              : IPriorityFeesInformation;
  LActualPrioFees           : IPriorityFeesInformation;
  LTxResp                   : IRequestResult<TTransactionMetaSlotInfo>;
begin
  // 1) Setup
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(TBaseExample.MNEMONIC_WORDS);

  LFrom := LWallet.GetAccountByIndex(0);
  LTo   := LWallet.GetAccountByIndex(1);

  // 2) Fetch recent blockhash
  LBlock := LRpc.GetLatestBlockHash;
  if (LBlock = nil) or (not LBlock.WasSuccessful) or (LBlock.Result = nil) then
    raise Exception.Create('Failed to get recent blockhash');

  // 3) Balance BEFORE
  LBeforeBal := LRpc.GetBalance(LFrom.PublicKey.Key);
  if LBeforeBal.WasSuccessful then
    Writeln(Format('Balance BEFORE (lamports): %d', [LBeforeBal.Result.Value]))
  else
    Writeln('Balance BEFORE: <unavailable>');

  // 4) Prepare simulation priority fees information
  LSimPrioFees := TPriorityFeesInformation.Create(
    TComputeBudgetProgram.SetComputeUnitLimit(400000), // limit
    TComputeBudgetProgram.SetComputeUnitPrice(100000)  // price (micro-lamports)
  );

  // 5) Build simulation transaction (transfer + memo + priority fees)
  LSimTxBuilder := TTransactionBuilder.Create;
  LSimTx :=
    LSimTxBuilder
      .SetFeePayer(LFrom.PublicKey)
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetPriorityFeesInformation(LSimPrioFees)
      .AddInstruction(
        TSystemProgram.Transfer(
          LFrom.PublicKey,
          LTo.PublicKey,
          1000000
        )
      )
      .AddInstruction(
        TMemoProgram.NewMemo(
          LFrom.PublicKey,
          Memo
        )
      )
      .Build(LFrom);

  // 6) Estimate priority fees information
  LActualPrioFees := TComputeBudgetEstimator.EstimatePriorityFeesInformation(
    LRpc,
    LSimTx,
    [ LFrom.PublicKey.Key ]
  );

  // 7) Build actual transaction (transfer + memo + estimated priority fees)
  LActualTxBuilder := TTransactionBuilder.Create;
  LActualTx :=
    LActualTxBuilder
      .SetFeePayer(LFrom.PublicKey)
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetPriorityFeesInformation(LActualPrioFees)
      .AddInstruction(
        TSystemProgram.Transfer(
          LFrom.PublicKey,
          LTo.PublicKey,
          1000000
        )
      )
      .AddInstruction(
        TMemoProgram.NewMemo(
          LFrom.PublicKey,
          Memo
        )
      )
      .Build(LFrom);

  // 8) Send
  LSignature := SubmitTxSendAndLog(LActualTx);

  // 9) Confirm
  PollConfirmedTx(LSignature);

  // 10) Balance AFTER
  LAfterBal := LRpc.GetBalance(LFrom.PublicKey.Key);
  if LAfterBal.WasSuccessful then
    Writeln(Format('Balance AFTER (lamports): %d', [LAfterBal.Result.Value]))
  else
    Writeln('Balance AFTER: <unavailable>');

  // 11) Fetch the transaction via RPC and decode instructions using the decoder
  LTxResp := LRpc.GetTransaction(LSignature);
  if (LTxResp = nil) or (not LTxResp.WasSuccessful) or (LTxResp.Result = nil) then
  begin
    Writeln('getTransaction failed or empty');
    Exit;
  end;

  Writeln(NEWLINE + TAB + 'DECODING INSTRUCTIONS FROM CONFIRMED TRANSACTION' + NEWLINE);

  DecodeInstructionsFromTransactionMetaInfoAndLog(LTxResp.Result);
end;

{ TBurnExample }

procedure TBurnExample.Run;
var
  LRpc        : IRpcClient;
  LWallet     : IWallet;
  LOwner      : IAccount;
  LMint       : IAccount;
  LInitialAcc : IAccount;
  LBlock      : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LMsgBytes   : TBytes;
  LMsgSignature: TBytes;
  LTxBytes    : TBytes;
  LMsg        : IMessage;
  LTx         : ITransaction;
  LSignature  : string;
  LTxBuilder  : ITransactionBuilder;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LBlock := LRpc.GetLatestBlockHash;

  LOwner      := LWallet.GetAccountByIndex(0);
  LMint       := LWallet.GetAccountByIndex(31);
  LInitialAcc := LWallet.GetAccountByIndex(59);

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes := LTxBuilder
                 .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
                 .SetFeePayer(LOwner.PublicKey)
                 .AddInstruction(
                   TTokenProgram.Burn(
                     LInitialAcc.PublicKey,
                     LMint.PublicKey,
                     200,
                     LOwner.PublicKey
                   )
                 )
                 .AddInstruction(
                   TMemoProgram.NewMemo(
                     LOwner.PublicKey,
                     'Hello from SolLib'
                   )
                 )
                 .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB +
          'POPULATING TRANSACTION WITH SIGNATURES' +
          TAB);

  LMsgSignature := LOwner.Sign(LMsgBytes);
  LTx := TTransaction.Populate(LMsg, TArray<TBytes>.Create(LMsgSignature));
  LTxBytes := LogTransactionAndSerialize(LTx);

  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);
end;

{ TAddSignatureExample }

procedure TAddSignatureExample.Run;
var
  LRpc        : IRpcClient;
  LWallet     : IWallet;
  LFrom       : IAccount;
  LTo         : IAccount;
  LBlock      : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LTxBuilder  : ITransactionBuilder;
  LMsgBytes   : TBytes;
  LMsgSignature: TBytes;
  LTxBytes    : TBytes;
  LSignature  : string;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LFrom := LWallet.GetAccountByIndex(0);
  LTo   := LWallet.GetAccountByIndex(8);

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
        10000000
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
  PollConfirmedTx(LSignature);
end;

end.

