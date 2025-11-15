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

unit SlpTransactionExtendedExample;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpWallet,
  SlpAccount,
  SlpPublicKey,
  SlpSystemProgram,
  SlpTokenProgram,
  SlpMemoProgram,
  SlpRpcModel,
  SlpSolanaRpcClient,
  SlpNonceAccount,
  SlpRpcMessage,
  SlpTransactionBuilder,
  SlpRequestResult,
  SlpExample,
  SlpTokenMintHelper;

const
  /// <summary>
  /// Mnemonic.
  /// </summary>
  MnemonicWords = TBaseExample.MNEMONIC_WORDS;

type
  /// <summary>
  /// Create Mint + Initialize Mint + Create Token Account + Initialize + MintTo + Memo.
  /// </summary>
  TCreateInitializeAndMintToExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// Simple MintTo into an existing token account + Memo.
  /// </summary>
  TSimpleMintToExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// Create a new token account, Initialize, Transfer tokens + Memo.
  /// </summary>
  TTransferTokenExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// Same as transfer but using TransferChecked (with decimals).
  /// </summary>
  TTransferTokenCheckedExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// Create and initialize a Nonce account.
  /// </summary>
  TCreateNonceAccountExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

implementation

{ TCreateInitializeAndMintToExample }

procedure TCreateInitializeAndMintToExample.Run;
var
  LRpc       : IRpcClient;
  LWallet    : IWallet;
  LOwner     : IAccount;
  LMint      : IAccount;
  LInitialAcc: IAccount;
  LBlock     : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LMinAcc    : IRequestResult<UInt64>;
  LMinMint   : IRequestResult<UInt64>;
  LTx        : TBytes;
  LSignature : string;
  LSigners   : TList<IAccount>;
  LTxBuilder : ITransactionBuilder;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LMinAcc := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.TokenAccountDataSize);
  Writeln('MinBalanceForRentExemption Account >> ' + LMinAcc.Result.ToString);

  LMinMint := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.MintAccountDataSize);
  Writeln('MinBalanceForRentExemption Mint Account >> ' + LMinMint.Result.ToString);

  LOwner := LWallet.GetAccountByIndex(0);
  Writeln('OwnerAccount: ' + LOwner.ToString);

  LMint := LWallet.GetAccountByIndex(5006);

  Writeln('MintAccount: ' + LMint.ToString);

  LInitialAcc := LWallet.GetAccountByIndex(5007);

  Writeln('InitialAccount: ' + LInitialAcc.ToString);

  LBlock  := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LMint.PublicKey,
        LMinMint.Result,
        TTokenProgram.MintAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TTokenProgram.InitializeMint(
        LMint.PublicKey,
        2,
        LOwner.PublicKey,
        LOwner.PublicKey
      )
    )
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LInitialAcc.PublicKey,
        LMinAcc.Result,
        TTokenProgram.TokenAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TTokenProgram.InitializeAccount(
        LInitialAcc.PublicKey,
        LMint.PublicKey,
        LOwner.PublicKey
      )
    )
    .AddInstruction(
      TTokenProgram.MintTo(
        LMint.PublicKey,
        LInitialAcc.PublicKey,
        25000,
        LOwner.PublicKey
      )
    )
    .AddInstruction(
      TMemoProgram.NewMemo(
        LInitialAcc.PublicKey,
        'Hello from SolLib'
      )
    );

  // Build transaction with required signers
  LSigners := TList<IAccount>.Create;
  try
    LSigners.Add(LOwner);
    LSigners.Add(LMint);
    LSigners.Add(LInitialAcc);
    LTx := LTxBuilder.Build(LSigners);
  finally
    LSigners.Free;
  end;

  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);
end;

{ TSimpleMintToExample }

procedure TSimpleMintToExample.Run;
var
  LRpc: IRpcClient;
  LWallet: IWallet;
  LOwner, LMint, LInitialAcc: IAccount;
  LBlock: IRequestResult<TResponseValue<TLatestBlockHash>>;
  LTx: TBytes;
  LSignature: string;
  LSigners: TList<IAccount>;
  LTxBuilder: ITransactionBuilder;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LBlock := LRpc.GetLatestBlockHash;

  LOwner := LWallet.GetAccountByIndex(0);
  Writeln('OwnerAccount: ' + LOwner.ToString);

  LMint := LWallet.GetAccountByIndex(31);
  Writeln('MintAccount: ' + LMint.ToString);

  LInitialAcc := LWallet.GetAccountByIndex(60);
  Writeln('InitialAccount: ' + LInitialAcc.ToString);

  LTxBuilder := TTransactionBuilder.Create;

  LTxBuilder
    .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)
    .AddInstruction(
      TTokenProgram.MintTo(
        LMint.PublicKey,
        LInitialAcc.PublicKey,
        25000000,
        LOwner.PublicKey
      )
    )
    .AddInstruction(
      TMemoProgram.NewMemo(
        LInitialAcc.PublicKey,
        'Hello from SolLib'
      )
    );

  // Build transaction with required signers
  LSigners := TList<IAccount>.Create;
  try
    LSigners.Add(LOwner);
    LSigners.Add(LInitialAcc);
    LTx := LTxBuilder.Build(LSigners);
  finally
    LSigners.Free;
  end;

  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);
end;

{ TTransferTokenExample }

procedure TTransferTokenExample.Run;
var
  LRpc       : IRpcClient;
  LWallet    : IWallet;
  LOwner     : IAccount;
  LMint      : IAccount;
  LInitialAcc: IAccount;
  LNewAcc    : IAccount;
  LBlock     : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LMinAcc    : IRequestResult<UInt64>;
  LTx        : TBytes;
  LSignature : string;
  LSigners   : TList<IAccount>;
  LTxBuilder : ITransactionBuilder;
  LResult: TMintEnsureResult;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LMinAcc := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.TokenAccountDataSize);
  Writeln('MinBalanceForRentExemption Account >> ' + LMinAcc.Result.ToString);

  LOwner := LWallet.GetAccountByIndex(0);
  Writeln('OwnerAccount: ' + LOwner.ToString);

  LMint := LWallet.GetAccountByIndex(31);
  Writeln('MintAccount: ' + LMint.ToString);

  LInitialAcc := LWallet.GetAccountByIndex(60);
  Writeln('InitialAccount: ' + LInitialAcc.ToString);

  LNewAcc := LWallet.GetAccountByIndex(61);
  Writeln('NewAccount: ' + LNewAcc.ToString);

  LResult := TTokenMintHelper.EnsureMintInitialized(
    LRpc,
    LOwner,   // mint authority
    LMint,  // mint account
    2       // decimals
    );

  if LResult.Status = TMintStatus.Unknown then
    Exit;

  LBlock  := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)
    // 1. Create Initial Account
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LInitialAcc.PublicKey,
        LMinAcc.Result,
        TTokenProgram.TokenAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )
    // 2. Initialize Initial Account
    .AddInstruction(
      TTokenProgram.InitializeAccount(
        LInitialAcc.PublicKey,
        LMint.PublicKey,
        LOwner.PublicKey
      )
    )
    // 3. Seed source with balance (mint authority = LOwner here)
    .AddInstruction(
      TTokenProgram.MintTo(
        LMint.PublicKey,
        LInitialAcc.PublicKey,
        25000,              // or more, but >= transfer amount
        LOwner.PublicKey
      )
    )
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LNewAcc.PublicKey,
        LMinAcc.Result,
        TTokenProgram.TokenAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TTokenProgram.InitializeAccount(
        LNewAcc.PublicKey,
        LMint.PublicKey,
        LOwner.PublicKey
      )
    )
    .AddInstruction(
      TTokenProgram.Transfer(
        LInitialAcc.PublicKey,
        LNewAcc.PublicKey,
        25000,
        LOwner.PublicKey
      )
    )
    .AddInstruction(
      TMemoProgram.NewMemo(
        LInitialAcc.PublicKey,
        'Hello from SolLib'
      )
    );

  // Build transaction with required signers
  LSigners := TList<IAccount>.Create;
  try
    LSigners.Add(LOwner);
    LSigners.Add(LNewAcc);
    LSigners.Add(LInitialAcc);

    LTx := LTxBuilder.Build(LSigners);
  finally
    LSigners.Free;
  end;

  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);
end;

{ TTransferTokenCheckedExample }

procedure TTransferTokenCheckedExample.Run;
var
  LRpc       : IRpcClient;
  LWallet    : IWallet;
  LOwner     : IAccount;
  LMint      : IAccount;
  LInitialAcc: IAccount;
  LNewAcc    : IAccount;
  LBlock     : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LMinAcc    : IRequestResult<UInt64>;
  LTx        : TBytes;
  LSignature : string;
  LSigners   : TList<IAccount>;
  LTxBuilder : ITransactionBuilder;
  LResult: TMintEnsureResult;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LMinAcc := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.TokenAccountDataSize);
  Writeln('MinBalanceForRentExemption Account >> ' + LMinAcc.Result.ToString);

  LOwner := LWallet.GetAccountByIndex(0);
  Writeln('OwnerAccount: ' + LOwner.ToString);

  LMint := LWallet.GetAccountByIndex(31);
  Writeln('MintAccount: ' + LMint.ToString);

  LInitialAcc := LWallet.GetAccountByIndex(100);
  Writeln('InitialAccount: ' + LInitialAcc.ToString);

  LNewAcc := LWallet.GetAccountByIndex(101);
  Writeln('NewAccount: ' + LNewAcc.ToString);

  LResult := TTokenMintHelper.EnsureMintInitialized(
    LRpc,
    LOwner,   // mint authority
    LMint,  // mint account
    2       // decimals
    );

  if LResult.Status = TMintStatus.Unknown then
    Exit;

  LBlock  := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)
    // 1. Create Initial Account
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LInitialAcc.PublicKey,
        LMinAcc.Result,
        TTokenProgram.TokenAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )
    // 2. Initialize Initial Account
    .AddInstruction(
      TTokenProgram.InitializeAccount(
        LInitialAcc.PublicKey,
        LMint.PublicKey,
        LOwner.PublicKey
      )
    )
    // 3. Seed source with balance (mint authority = LOwner here)
    .AddInstruction(
      TTokenProgram.MintTo(
        LMint.PublicKey,
        LInitialAcc.PublicKey,
        25000,              // or more, but >= transfer amount
        LOwner.PublicKey
      )
    )
     ////
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LNewAcc.PublicKey,
        LMinAcc.Result,
        TTokenProgram.TokenAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TTokenProgram.InitializeAccount(
        LNewAcc.PublicKey,
        LMint.PublicKey,
        LOwner.PublicKey
      )
    )
    .AddInstruction(
      TTokenProgram.TransferChecked(
        LInitialAcc.PublicKey,
        LNewAcc.PublicKey,
        25000,
        2,
        LOwner.PublicKey,
        LMint.PublicKey
      )
    )
    .AddInstruction(
      TMemoProgram.NewMemo(
        LInitialAcc.PublicKey,
        'Hello from SolLib'
      )
    );

  // Build transaction with required signers
  LSigners := TList<IAccount>.Create;
  try
    LSigners.Add(LOwner);
    LSigners.Add(LNewAcc);
    LSigners.Add(LInitialAcc);

    LTx := LTxBuilder.Build(LSigners);
  finally
    LSigners.Free;
  end;

  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);
end;

{ TCreateNonceAccountExample }

procedure TCreateNonceAccountExample.Run;
var
  LRpc      : IRpcClient;
  LWallet   : IWallet;
  LOwner    : IAccount;
  LNonceAcc : IAccount;
  LBlock    : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LMinAcc   : IRequestResult<UInt64>;
  LTx       : TBytes;
  LSignature: string;
  LSigners  : TList<IAccount>;
  LTxBuilder: ITransactionBuilder;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LBlock  := LRpc.GetLatestBlockHash;
  LMinAcc := LRpc.GetMinimumBalanceForRentExemption(TNonceAccount.AccountDataSize);

  LOwner := LWallet.GetAccountByIndex(0);
  Writeln('OwnerAccount: ' + LOwner.ToString);

  LNonceAcc := LWallet.GetAccountByIndex(1120);
  Writeln('NonceAccount: ' + LNonceAcc.ToString);

  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LNonceAcc.PublicKey,
        LMinAcc.Result,
        TNonceAccount.AccountDataSize,
        TSystemProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TSystemProgram.InitializeNonceAccount(
        LNonceAcc.PublicKey,
        LOwner.PublicKey
      )
    );

  // Build transaction with required signers
  LSigners := TList<IAccount>.Create;
  try
    LSigners.Add(LOwner);
    LSigners.Add(LNonceAcc);
    LTx := LTxBuilder.Build(LSigners);
  finally
    LSigners.Free;
  end;

  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);
end;

end.

