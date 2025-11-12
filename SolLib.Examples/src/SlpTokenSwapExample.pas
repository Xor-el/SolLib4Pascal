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

unit SlpTokenSwapExample;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpWallet,
  SlpAccount,
  SlpPublicKey,
  SlpRpcModel,
  SlpSolanaRpcClient,
  SlpRpcMessage,
  SlpRequestResult,
  SlpTransactionBuilder,
  SlpSystemProgram,
  SlpTokenProgram,
  SlpTokenSwapProgram,
  SlpTokenSwapModel,
  SlpDataEncoders,
  SlpExample;

type
  /// <summary>
  /// End-to-end example that sets up two mints, user token accounts,
  /// initializes a Token Swap pool, and exercises swap/deposit/withdraw flows.
  /// </summary>
  TTokenSwapExample = class(TBaseExample)
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

{ TTokenSwapExample }

procedure TTokenSwapExample.Run;
var
  LMainRpc   : IRpcClient;
  LRpc       : IRpcClient;
  LWallet    : IWallet;

  // Blockhash & fees
  LBlock     : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LMinMint   : IRequestResult<UInt64>;
  LMinAcc    : IRequestResult<UInt64>;
  LMinSwap   : IRequestResult<UInt64>;

  // Accounts
  LOwner         : IAccount;
  LTokenAMint    : IAccount;
  LTokenAUserAcc : IAccount;
  LTokenBMint    : IAccount;
  LTokenBUserAcc : IAccount;

  LSwap              : IAccount;
  LSwapAuthority     : IPublicKey;

  LSwapTokenAAccount : IAccount;
  LSwapTokenBAccount : IAccount;

  LPoolMint       : IAccount;
  LPoolUserAcc    : IAccount;
  LPoolFeeAcc     : IAccount;

  // Tx
  LTxBuilder  : ITransactionBuilder;
  LTx         : TBytes;
  LSigners    : TList<IAccount>;
  LSignature  : string;

  // Fees structure
  LFees       : IFees;

  // Deserialize state demo
  LAccInfo    : IRequestResult<TResponseValue<TAccountInfo>>;
  LSwapState  : ITokenSwapAccount;
  //LAccountInfoData: string;
  LAccountInfoDataBytes: TBytes;
begin
  // RPCs
  LRpc     := TestNetRpcClient;
  LMainRpc := MainNetRpcClient;

  // --- Load on-chain TokenSwap account state
  // Sanity check the expected size against a live mainnet swap
  LAccInfo := LMainRpc.GetAccountInfo('GAM8dQkm4LwYJgPZbML61mKPUCQX7uAquxu67p9oifSK');
  if LAccInfo.WasSuccessful and (Length(LAccInfo.Result.Value.Data) > 0) then
  begin
    LAccountInfoDataBytes := TEncoders.Base64.DecodeData(LAccInfo.Result.Value.Data[0]);
    Writeln('Live TokenSwap account length:  ' + IntToStr(Length(LAccountInfoDataBytes)) + 'bytes');
    LSwapState := TTokenSwapAccount.Deserialize(LAccountInfoDataBytes);
    Writeln('Pool Mint (from mainnet state read): ' + LSwapState.PoolMint.Key);
  end;

  // Wallet + base owner
  LWallet := TWallet.Create(MnemonicWords);
  LOwner  := LWallet.GetAccountByIndex(0);
  Writeln('OwnerAccount: ' + LOwner.ToString);

  // Create local working accounts
  LTokenAMint    := TAccount.Create;
  LTokenAUserAcc := TAccount.Create;
  LTokenBMint    := TAccount.Create;
  LTokenBUserAcc := TAccount.Create;

  // === Setup two mints + user token accounts, mint initial supply ===
  LMinMint := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.MintAccountDataSize);
  LMinAcc  := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.TokenAccountDataSize);
  Writeln('MinBalance RentEx Mint: ' + LMinMint.Result.ToString);
  Writeln('MinBalance RentEx Token Acc: ' + LMinAcc.Result.ToString);

  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)
    // create mints
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LTokenAMint.PublicKey,
        LMinMint.Result,
        TTokenProgram.MintAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LTokenBMint.PublicKey,
        LMinMint.Result,
        TTokenProgram.MintAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )
    // create user token accounts
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LTokenAUserAcc.PublicKey,
        LMinAcc.Result,
        TTokenProgram.TokenAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LTokenBUserAcc.PublicKey,
        LMinAcc.Result,
        TTokenProgram.TokenAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )
    // init mints (mint authority = owner, freeze authority omitted)
    .AddInstruction(
      TTokenProgram.InitializeMint(
        LTokenAMint.PublicKey,
        9,
        LOwner.PublicKey
      )
    )
    .AddInstruction(
      TTokenProgram.InitializeMint(
        LTokenBMint.PublicKey,
        9,
        LOwner.PublicKey
      )
    )
    // init user token accounts
    .AddInstruction(
      TTokenProgram.InitializeAccount(
        LTokenAUserAcc.PublicKey,
        LTokenAMint.PublicKey,
        LOwner.PublicKey
      )
    )
    .AddInstruction(
      TTokenProgram.InitializeAccount(
        LTokenBUserAcc.PublicKey,
        LTokenBMint.PublicKey,
        LOwner.PublicKey
      )
    )
    // mint some balances
    .AddInstruction(
      TTokenProgram.MintTo(
        LTokenAMint.PublicKey,
        LTokenAUserAcc.PublicKey,
        1000000000000,
        LOwner.PublicKey
      )
    )
    .AddInstruction(
      TTokenProgram.MintTo(
        LTokenBMint.PublicKey,
        LTokenBUserAcc.PublicKey,
        1000000000000,
        LOwner.PublicKey
      )
    );

  LSigners := TList<IAccount>.Create;
  try
    LSigners.Add(LOwner);
    LSigners.Add(LTokenAMint);
    LSigners.Add(LTokenBMint);
    LSigners.Add(LTokenAUserAcc);
    LSigners.Add(LTokenBUserAcc);
    LTx := LTxBuilder.Build(LSigners);
  finally
    LSigners.Free;
  end;

  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);

  // === Prepare swap authority and its token accounts ===
  LSwap          := TAccount.Create;
  LSwapAuthority := TTokenSwapProgram.CreateAuthority(LSwap.PublicKey).PublicKey;

  LSwapTokenAAccount := TAccount.Create;
  LSwapTokenBAccount := TAccount.Create;

  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)
    // Create + init swap's Token A account (owned by swap authority) + fund it
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LSwapTokenAAccount.PublicKey,
        LMinAcc.Result,
        TTokenProgram.TokenAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TTokenProgram.InitializeAccount(
        LSwapTokenAAccount.PublicKey,
        LTokenAMint.PublicKey,
        LSwapAuthority
      )
    )
    .AddInstruction(
      TTokenProgram.Transfer(
        LTokenAUserAcc.PublicKey,
        LSwapTokenAAccount.PublicKey,
        5000000000,
        LOwner.PublicKey
      )
    )
    // Create + init swap's Token B account + fund it
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LSwapTokenBAccount.PublicKey,
        LMinAcc.Result,
        TTokenProgram.TokenAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TTokenProgram.InitializeAccount(
        LSwapTokenBAccount.PublicKey,
        LTokenBMint.PublicKey,
        LSwapAuthority
      )
    )
    .AddInstruction(
      TTokenProgram.Transfer(
        LTokenBUserAcc.PublicKey,
        LSwapTokenBAccount.PublicKey,
        5000000000,
        LOwner.PublicKey
      )
    );

  LSigners := TList<IAccount>.Create;
  try
    LSigners.Add(LOwner);
    LSigners.Add(LSwapTokenAAccount);
    LSigners.Add(LSwapTokenBAccount);
    LTx := LTxBuilder.Build(LSigners);
  finally
    LSigners.Free;
  end;

  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);

  // === Create pool mint + user pool account + fee pool account ===
  LPoolMint    := TAccount.Create;
  LPoolUserAcc := TAccount.Create;
  LPoolFeeAcc  := TAccount.Create;

  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)
    // pool mint
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LPoolMint.PublicKey,
        LMinMint.Result,
        TTokenProgram.MintAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TTokenProgram.InitializeMint(
        LPoolMint.PublicKey,
        9,
        LSwapAuthority
      )
    )
    // pool user account
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LPoolUserAcc.PublicKey,
        LMinAcc.Result,
        TTokenProgram.TokenAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TTokenProgram.InitializeAccount(
        LPoolUserAcc.PublicKey,
        LPoolMint.PublicKey,
        LOwner.PublicKey
      )
    )
    // pool fee account (owner set to program owner key)
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LPoolFeeAcc.PublicKey,
        LMinAcc.Result,
        TTokenProgram.TokenAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TTokenProgram.InitializeAccount(
        LPoolFeeAcc.PublicKey,
        LPoolMint.PublicKey,
        TTokenSwapProgram.OwnerKey
      )
    );

  LSigners := TList<IAccount>.Create;
  try
    LSigners.Add(LOwner);
    LSigners.Add(LPoolMint);
    LSigners.Add(LPoolUserAcc);
    LSigners.Add(LPoolFeeAcc);
    LTx := LTxBuilder.Build(LSigners);
  finally
    LSigners.Free;
  end;

  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);

  // === Create swap account + initialize the swap ===
  LMinSwap := LRpc.GetMinimumBalanceForRentExemption(TTokenSwapProgram.TokenSwapDataLength);
  LBlock   := LRpc.GetLatestBlockHash;

  LFees := TFees.Create;

  // Fill fees
  LFees.TradeFeeNumerator            := 25;
  LFees.TradeFeeDenominator          := 10000;
  LFees.OwnerTradeFeeNumerator       := 5;
  LFees.OwnerTradeFeeDenominator     := 10000;
  LFees.OwnerWithdrawFeeNumerator     := 0;
  LFees.OwnerWithdrawFeeDenominator   := 0;
  LFees.HostFeeNumerator             := 20;
  LFees.HostFeeDenominator           := 100;

  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)
    // create the swap account owned by token-swap program
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LSwap.PublicKey,
        LMinSwap.Result,
        TTokenSwapProgram.TokenSwapDataLength,
        TTokenSwapProgram.ProgramIdKey
      )
    )
    // initialize swap
    .AddInstruction(
      TTokenSwapProgram.Initialize(
        LSwap.PublicKey,
        LSwapTokenAAccount.PublicKey,
        LSwapTokenBAccount.PublicKey,
        LPoolMint.PublicKey,
        LPoolFeeAcc.PublicKey,
        LPoolUserAcc.PublicKey,
        LFees,
        TSwapCurve.ConstantProduct
      )
    );

  Writeln('Swap Account: ' + LSwap.ToString);
  Writeln('Swap Auth Account: ' + LSwapAuthority.ToString);
  Writeln('Pool Mint Account: ' + LPoolMint.ToString);
  Writeln('Pool User Account: ' + LPoolUserAcc.ToString);
  Writeln('Pool Fee Account: ' + LPoolFeeAcc.ToString);

  LSigners := TList<IAccount>.Create;
  try
    LSigners.Add(LOwner);
    LSigners.Add(LSwap);
    LTx := LTxBuilder.Build(LSigners);
  finally
    LSigners.Free;
  end;

  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);

  // === Now: user performs a swap in the pool ===
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)
    .AddInstruction(
      TTokenSwapProgram.Swap(
        LSwap.PublicKey,
        LOwner.PublicKey,
        LTokenAUserAcc.PublicKey,
        LSwapTokenAAccount.PublicKey,
        LSwapTokenBAccount.PublicKey,
        LTokenBUserAcc.PublicKey,
        LPoolMint.PublicKey,
        LPoolFeeAcc.PublicKey,
        nil,               // host fee account (optional)
        1000000000,        // 1000000000 in
        500000             // 500000 out
      )
    );

  LTx := LTxBuilder.Build(LOwner);
  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);

  // === User deposits both tokens (add liquidity) ===
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)
    .AddInstruction(
      TTokenSwapProgram.DepositAllTokenTypes(
        LSwap.PublicKey,
        LOwner.PublicKey,
        LTokenAUserAcc.PublicKey,
        LTokenBUserAcc.PublicKey,
        LSwapTokenAAccount.PublicKey,
        LSwapTokenBAccount.PublicKey,
        LPoolMint.PublicKey,
        LPoolUserAcc.PublicKey,
        1000000,          // pool tokens desired
        100000000000,     // max token A
        100000000000      // max token B
      )
    );

  LTx := LTxBuilder.Build(LOwner);
  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);

  // === User withdraws both tokens (remove liquidity) ===
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)
    .AddInstruction(
      TTokenSwapProgram.WithdrawAllTokenTypes(
        LSwap.PublicKey,
        LOwner.PublicKey,
        LPoolMint.PublicKey,
        LPoolUserAcc.PublicKey,
        LSwapTokenAAccount.PublicKey,
        LSwapTokenBAccount.PublicKey,
        LTokenAUserAcc.PublicKey,
        LTokenBUserAcc.PublicKey,
        LPoolFeeAcc.PublicKey,
        1000000,          // pool tokens to burn
        1000,             // min token A out
        1000              // min token B out
      )
    );

  LTx := LTxBuilder.Build(LOwner);
  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);

  // === User deposits single token (exact amount in) ===
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)
    .AddInstruction(
      TTokenSwapProgram.DepositSingleTokenTypeExactAmountIn(
        LSwap.PublicKey,
        LOwner.PublicKey,
        LTokenAUserAcc.PublicKey,
        LSwapTokenAAccount.PublicKey,
        LSwapTokenBAccount.PublicKey,
        LPoolMint.PublicKey,
        LPoolUserAcc.PublicKey,
        1000000000,   // source token amount
        1000          // min pool token amount
      )
    );

  LTx := LTxBuilder.Build(LOwner);
  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);

  // === User withdraws single token (exact amount out) ===
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)
    .AddInstruction(
      TTokenSwapProgram.WithdrawSingleTokenTypeExactAmountOut(
        LSwap.PublicKey,
        LOwner.PublicKey,
        LPoolMint.PublicKey,
        LPoolUserAcc.PublicKey,
        LSwapTokenAAccount.PublicKey,
        LSwapTokenBAccount.PublicKey,
        LTokenAUserAcc.PublicKey,
        LPoolFeeAcc.PublicKey,
        1000000,  // destination token amount (exact out)
        100000    // max pool token amount
      )
    );

  LTx := LTxBuilder.Build(LOwner);
  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);
end;

end.

