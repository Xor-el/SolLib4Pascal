{ * ************************************************************************ * }
{ *                              SolLib Library                              * }
{ *                  Copyright (c) 2025 Ugochukwu Mmaduekwe                  * }
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

unit SlpMultisigExample;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  SlpWallet,
  SlpAccount,
  SlpPublicKey,
  SlpTransactionDomain,
  SlpSystemProgram,
  SlpTokenProgram,
  SlpMemoProgram,
  SlpTokenProgramModel,
  SlpRpcModel,
  SlpSolanaRpcClient,
  SlpRpcMessage,
  SlpMessageDomain,
  SlpTransactionBuilder,
  SlpRequestResult,
  SlpDataEncoders,
  SlpExample;

const
  /// <summary>
  /// Mnemonic.
  /// </summary>
  MnemonicWords = TBaseExample.MNEMONIC_WORDS;

type
  /// <summary>
  /// Create multisig, create mint, initialize mint with multisig as authority, then MintTo via multisig signers.
  /// </summary>
  TCreateInitializeAndMintToMultiSigExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// MintToChecked via multisig signers.
  /// </summary>
  TMintToCheckedMultisigExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// Create a token-account-owned-by-multisig; transfer in; then transfer out using multisig signers.
  /// </summary>
  TTransferCheckedMultiSigExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// Separate multisigs for mint authority and freeze authority; mint, freeze, thaw, set freeze authority to none.
  /// </summary>
  TFreezeAuthorityExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// ApproveChecked with a token-account multisig, transfer by delegate, then revoke.
  /// </summary>
  TApproveCheckedMultisigExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// MintToChecked via mint multisig, then BurnChecked via token-account multisig.
  /// </summary>
  TSimpleMintToAndBurnCheckedMultisigExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// BurnChecked full balance and CloseAccount using token-account multisig.
  /// </summary>
  TBurnCheckedAndCloseAccountMultisigExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

  /// <summary>
  /// Fetch a multisig account and deserialize it.
  /// </summary>
  TGetMultiSignatureAccountExample = class(TBaseExample)
  public
    procedure Run; override;
  end;

implementation

{ TCreateInitializeAndMintToMultiSigExample }

procedure TCreateInitializeAndMintToMultiSigExample.Run;
var
  LRpc         : IRpcClient;
  LWallet      : IWallet;
  LOwner       : IAccount;
  LMint        : IAccount;
  LInitial     : IAccount;
  LMultiSig    : IAccount;
  LSigner1     : IAccount;
  LSigner2     : IAccount;
  LSigner3     : IAccount;
  LSigner4     : IAccount;
  LSigner5     : IAccount;
  LBlock       : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LMinMsRent   : IRequestResult<UInt64>;
  LMinAccRent  : IRequestResult<UInt64>;
  LMinMintRent : IRequestResult<UInt64>;
  LTxBuilder   : ITransactionBuilder;

  LMsgBytes   : TBytes;
  LMsg        : IMessage;
  LTx         : ITransaction;
  LTxBytes    : TBytes;

  LSignature   : string;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  // rents
  LMinMsRent   := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.MultisigAccountDataSize);
  Writeln('MinBalanceForRentExemption MultiSig >> ' + LMinMsRent.Result.ToString);
  LMinAccRent  := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.TokenAccountDataSize);
  Writeln('MinBalanceForRentExemption Account >> ' + LMinAccRent.Result.ToString);
  LMinMintRent := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.MintAccountDataSize);
  Writeln('MinBalanceForRentExemption Mint Account >> ' + LMinMintRent.Result.ToString);

  LOwner    := LWallet.GetAccountByIndex(10);
  LMint     := LWallet.GetAccountByIndex(94224);
  LInitial  := LWallet.GetAccountByIndex(84224);
  LMultiSig := LWallet.GetAccountByIndex(2011);

  LSigner1 := LWallet.GetAccountByIndex(25100);
  LSigner2 := LWallet.GetAccountByIndex(25101);
  LSigner3 := LWallet.GetAccountByIndex(25102);
  LSigner4 := LWallet.GetAccountByIndex(25103);
  LSigner5 := LWallet.GetAccountByIndex(25104);

  // -------- Tx #1: create multisig + create mint + init mint (multisig as mint authority) + memo
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      // create multisig account (multisig account must sign)
      .AddInstruction(
        TSystemProgram.CreateAccount(
          LOwner.PublicKey,
          LMultiSig.PublicKey,
          LMinMsRent.Result,
          TTokenProgram.MultisigAccountDataSize,
          TTokenProgram.ProgramIdKey
        )
      )
      .AddInstruction(
        TTokenProgram.InitializeMultiSignature(
          LMultiSig.PublicKey,
          TArray<IPublicKey>.Create(
            LSigner1.PublicKey, LSigner2.PublicKey, LSigner3.PublicKey, LSigner4.PublicKey, LSigner5.PublicKey
          ),
          3
        )
      )
      // create mint (mint account must sign)
      .AddInstruction(
        TSystemProgram.CreateAccount(
          LOwner.PublicKey,
          LMint.PublicKey,
          LMinMintRent.Result,
          TTokenProgram.MintAccountDataSize,
          TTokenProgram.ProgramIdKey
        )
      )
      // initialize mint: decimals=10, mint authority = multisig
      .AddInstruction(
        TTokenProgram.InitializeMint(
          LMint.PublicKey,
          10,
          LMultiSig.PublicKey
        )
      )
      .AddInstruction(TMemoProgram.NewMemo(LOwner.PublicKey, 'Hello from SolLib'))
      .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB + 'POPULATING TRANSACTION WITH SIGNATURES' + TAB);
  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),
      LMultiSig.Sign(LMsgBytes),
      LMint.Sign(LMsgBytes)
    )
  );

  LTxBytes := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);

  // -------- Tx #2: create token account for owner, init, then mint-to using multisig signers (3-of-5)
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      .AddInstruction(
        TSystemProgram.CreateAccount(
          LOwner.PublicKey,
          LInitial.PublicKey,
          LMinAccRent.Result,
          TTokenProgram.TokenAccountDataSize,
          TTokenProgram.ProgramIdKey
        )
      )
      .AddInstruction(
        TTokenProgram.InitializeAccount(
          LInitial.PublicKey,
          LMint.PublicKey,
          LOwner.PublicKey
        )
      )
      .AddInstruction(
        TTokenProgram.MintTo(
          LMint.PublicKey,
          LInitial.PublicKey,
          25000,
          LMultiSig.PublicKey,
          TArray<IPublicKey>.Create(
            LSigner1.PublicKey, LSigner2.PublicKey, LSigner4.PublicKey
          )
        )
      )
      .AddInstruction(TMemoProgram.NewMemo(LOwner.PublicKey, 'Hello from SolLib'))
      .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB + 'POPULATING TRANSACTION WITH SIGNATURES' + TAB);
  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),     // fee payer
      LInitial.Sign(LMsgBytes),   // newly created token account
      LSigner1.Sign(LMsgBytes),   // 3-of-5 multisig signers
      LSigner2.Sign(LMsgBytes),
      LSigner4.Sign(LMsgBytes)
    )
  );

  LTxBytes := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);
end;


{ TMintToCheckedMultisigExample }

procedure TMintToCheckedMultisigExample.Run;
var
  LRpc       : IRpcClient;
  LWallet    : IWallet;
  LOwner     : IAccount;
  LMint      : IAccount;
  LDest      : IAccount;
  LMultiSig  : IAccount;
  LSigner1   : IAccount;
  LSigner2   : IAccount;
  LSigner4   : IAccount;
  LBlock     : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LTxBuilder : ITransactionBuilder;

  LMsgBytes  : TBytes;
  LMsg       : IMessage;
  LTx        : ITransaction;
  LTxBytes   : TBytes;

  LSignature : string;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LOwner    := LWallet.GetAccountByIndex(10);
  LMint     := LWallet.GetAccountByIndex(94224);
  LDest     := LWallet.GetAccountByIndex(84224);
  LMultiSig := LWallet.GetAccountByIndex(2011);
  LSigner1  := LWallet.GetAccountByIndex(25100);
  LSigner2  := LWallet.GetAccountByIndex(25101);
  LSigner4  := LWallet.GetAccountByIndex(25103);

  // Build + COMPILE message
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      .AddInstruction(
        TTokenProgram.MintToChecked(
          LMint.PublicKey,
          LDest.PublicKey,
          LMultiSig.PublicKey,
          25000,
          10,
          TArray<IPublicKey>.Create(
            LSigner1.PublicKey,
            LSigner2.PublicKey,
            LSigner4.PublicKey
          )
        )
      )
      .AddInstruction(
        TMemoProgram.NewMemo(LOwner.PublicKey, 'Hello from SolLib')
      )
      .CompileMessage;

  // Decode → Populate with signatures → Serialize
  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB +
          'POPULATING TRANSACTION WITH SIGNATURES' + TAB);

  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),
      LSigner1.Sign(LMsgBytes),
      LSigner2.Sign(LMsgBytes),
      LSigner4.Sign(LMsgBytes)
    )
  );

  LTxBytes   := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);
end;

{ TTransferCheckedMultiSigExample }

procedure TTransferCheckedMultiSigExample.Run;
var
  LRpc         : IRpcClient;
  LWallet      : IWallet;
  LOwner       : IAccount;
  LMint        : IAccount;
  LSource      : IAccount;
  LTokenDest   : IAccount;
  LTokenMs     : IAccount;
  LTokS1, LTokS2, LTokS3, LTokS4, LTokS5: IAccount;
  LBlock       : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LMinMsRent   : IRequestResult<UInt64>;
  LMinAccRent  : IRequestResult<UInt64>;
  LTxBuilder   : ITransactionBuilder;

  LMsgBytes    : TBytes;
  LMsg         : IMessage;
  LTx          : ITransaction;
  LTxBytes     : TBytes;

  LSignature   : string;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LMinMsRent  := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.MultisigAccountDataSize);
  Writeln('MinBalanceForRentExemption MultiSig >> ' + LMinMsRent.Result.ToString);
  LMinAccRent := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.TokenAccountDataSize);
  Writeln('MinBalanceForRentExemption Account >> ' + LMinAccRent.Result.ToString);

  LOwner     := LWallet.GetAccountByIndex(10);
  LMint      := LWallet.GetAccountByIndex(94224);
  LSource    := LWallet.GetAccountByIndex(84224);

  LTokenDest := LWallet.GetAccountByIndex(3042); // token account owned by multisig (to be created)
  LTokenMs   := LWallet.GetAccountByIndex(3043);

  LTokS1 := LWallet.GetAccountByIndex(25280);
  LTokS2 := LWallet.GetAccountByIndex(25281);
  LTokS3 := LWallet.GetAccountByIndex(25282);
  LTokS4 := LWallet.GetAccountByIndex(25283);
  LTokS5 := LWallet.GetAccountByIndex(25284);

  // -------- Tx #1: create token-owner multisig + token account (owned by it) + TransferChecked source -> tokenDest
  LBlock := LRpc.GetLatestBlockHash;

  // Then we create an account which will be the token's mint authority
  // In this same transaction we initialize the token mint with said authorities
  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      // create token-owner multisig
      .AddInstruction(
        TSystemProgram.CreateAccount(
          LOwner.PublicKey,
          LTokenMs.PublicKey,
          LMinMsRent.Result,
          TTokenProgram.MultisigAccountDataSize,
          TTokenProgram.ProgramIdKey
        )
      )
      .AddInstruction(
        TTokenProgram.InitializeMultiSignature(
          LTokenMs.PublicKey,
          TArray<IPublicKey>.Create(
            LTokS1.PublicKey, LTokS2.PublicKey, LTokS3.PublicKey, LTokS4.PublicKey, LTokS5.PublicKey
          ),
          3
        )
      )
      // create token account owned by that multisig
      .AddInstruction(
        TSystemProgram.CreateAccount(
          LOwner.PublicKey,
          LTokenDest.PublicKey,
          LMinAccRent.Result,
          TTokenProgram.TokenAccountDataSize,
          TTokenProgram.ProgramIdKey
        )
      )
      .AddInstruction(
        TTokenProgram.InitializeAccount(
          LTokenDest.PublicKey,
          LMint.PublicKey,
          LTokenMs.PublicKey
        )
      )
      // transfer in (owner signs as authority of source)
      .AddInstruction(
        TTokenProgram.TransferChecked(
          LSource.PublicKey,
          LTokenDest.PublicKey,
          10000,
          10,
          LOwner.PublicKey,
          LMint.PublicKey
        )
      )
      .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB +
          'POPULATING TRANSACTION WITH SIGNATURES' + TAB);

  // Sign: fee payer/owner, plus the newly created accounts (multisig & token account)
  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),
      LTokenMs.Sign(LMsgBytes),
      LTokenDest.Sign(LMsgBytes)
    )
  );

  LTxBytes   := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);

  // -------- Tx #2: transfer back tokenDest -> source using token-account multisig (3-of-5 signers)
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      .AddInstruction(
        TTokenProgram.Transfer(
          LTokenDest.PublicKey,
          LSource.PublicKey,
          10000,
          LTokenMs.PublicKey,
          TArray<IPublicKey>.Create(
            LTokS3.PublicKey, LTokS4.PublicKey, LTokS5.PublicKey
          )
        )
      )
      .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB +
          'POPULATING TRANSACTION WITH SIGNATURES' + TAB);

  // Sign: fee payer/owner + the 3 multisig signers authorizing the transfer
  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),
      LTokS3.Sign(LMsgBytes),
      LTokS4.Sign(LMsgBytes),
      LTokS5.Sign(LMsgBytes)
    )
  );

  LTxBytes   := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);
end;

{ TFreezeAuthorityExample }

procedure TFreezeAuthorityExample.Run;
var
  LRpc        : IRpcClient;
  LWallet     : IWallet;
  LOwner      : IAccount;
  LMint       : IAccount;
  LInitial    : IAccount;

  // Freeze authority multisig + signers
  LFreezeMs   : IAccount;
  LFreezeS1, LFreezeS2, LFreezeS3, LFreezeS4, LFreezeS5: IAccount;

  // Mint authority multisig + signers
  LMintMs     : IAccount;
  LMintS1, LMintS2, LMintS3, LMintS4, LMintS5: IAccount;

  LBlock      : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LMinMsRent  : IRequestResult<UInt64>;
  LMinAccRent : IRequestResult<UInt64>;
  LMinMintRent: IRequestResult<UInt64>;
  LTxBuilder  : ITransactionBuilder;

  LMsgBytes   : TBytes;
  LMsg        : IMessage;
  LTx         : ITransaction;
  LTxBytes    : TBytes;

  LSignature  : string;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  // Rents
  LMinMsRent   := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.MultisigAccountDataSize);
  Writeln('MinBalanceForRentExemption MultiSig >> ' + LMinMsRent.Result.ToString);
  LMinAccRent  := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.TokenAccountDataSize);
  Writeln('MinBalanceForRentExemption Account >> ' + LMinAccRent.Result.ToString);
  LMinMintRent := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.MintAccountDataSize);
  Writeln('MinBalanceForRentExemption Mint Account >> ' + LMinMintRent.Result.ToString);

  LOwner   := LWallet.GetAccountByIndex(10);
  LMint    := LWallet.GetAccountByIndex(94330);
  LInitial := LWallet.GetAccountByIndex(84330);

  // Mint multisig + signers
  LMintMs  := LWallet.GetAccountByIndex(10116);
  LMintS1  := LWallet.GetAccountByIndex(251280);
  LMintS2  := LWallet.GetAccountByIndex(251281);
  LMintS3  := LWallet.GetAccountByIndex(251282);
  LMintS4  := LWallet.GetAccountByIndex(251283);
  LMintS5  := LWallet.GetAccountByIndex(251284);

  // Freeze multisig + signers
  LFreezeMs := LWallet.GetAccountByIndex(3057);
  LFreezeS1 := LWallet.GetAccountByIndex(25410);
  LFreezeS2 := LWallet.GetAccountByIndex(25411);
  LFreezeS3 := LWallet.GetAccountByIndex(25412);
  LFreezeS4 := LWallet.GetAccountByIndex(25413);
  LFreezeS5 := LWallet.GetAccountByIndex(25414);

  // ---------------- Tx #1: create freeze multisig ----------------
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      .AddInstruction(
        TSystemProgram.CreateAccount(
          LOwner.PublicKey,
          LFreezeMs.PublicKey,
          LMinMsRent.Result,
          TTokenProgram.MultisigAccountDataSize,
          TTokenProgram.ProgramIdKey
        )
      )
      .AddInstruction(
        TTokenProgram.InitializeMultiSignature(
          LFreezeMs.PublicKey,
          TArray<IPublicKey>.Create(
            LFreezeS1.PublicKey, LFreezeS2.PublicKey, LFreezeS3.PublicKey,
            LFreezeS4.PublicKey, LFreezeS5.PublicKey
          ),
          3
        )
      )
      .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB +
          'POPULATING TRANSACTION WITH SIGNATURES' + TAB);

  // Sign: fee payer + new multisig account
  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),
      LFreezeMs.Sign(LMsgBytes)
    )
  );

  LTxBytes   := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);

  // ---------------- Tx #2: create mint multisig, create mint, init with authorities ----------------
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      .AddInstruction(
        TSystemProgram.CreateAccount(
          LOwner.PublicKey,
          LMintMs.PublicKey,
          LMinMsRent.Result,
          TTokenProgram.MultisigAccountDataSize,
          TTokenProgram.ProgramIdKey
        )
      )
      .AddInstruction(
        TTokenProgram.InitializeMultiSignature(
          LMintMs.PublicKey,
          TArray<IPublicKey>.Create(
            LMintS1.PublicKey, LMintS2.PublicKey, LMintS3.PublicKey,
            LMintS4.PublicKey, LMintS5.PublicKey
          ),
          3
        )
      )
      .AddInstruction(
        TSystemProgram.CreateAccount(
          LOwner.PublicKey,
          LMint.PublicKey,
          LMinMintRent.Result,
          TTokenProgram.MintAccountDataSize,
          TTokenProgram.ProgramIdKey
        )
      )
      .AddInstruction(
        TTokenProgram.InitializeMint(
          LMint.PublicKey,
          10,
          LMintMs.PublicKey,
          LFreezeMs.PublicKey
        )
      )
      .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB +
          'POPULATING TRANSACTION WITH SIGNATURES' + TAB);

  // Sign: fee payer + mint multisig + mint account
  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),
      LMintMs.Sign(LMsgBytes),
      LMint.Sign(LMsgBytes)
    )
  );

  LTxBytes   := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);

  // ---------------- Tx #3: create holder token account, init, mint-to using mint multisig ----------------
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      .AddInstruction(
        TSystemProgram.CreateAccount(
          LOwner.PublicKey,
          LInitial.PublicKey,
          LMinAccRent.Result,
          TTokenProgram.TokenAccountDataSize,
          TTokenProgram.ProgramIdKey
        )
      )
      .AddInstruction(
        TTokenProgram.InitializeAccount(
          LInitial.PublicKey,
          LMint.PublicKey,
          LOwner.PublicKey
        )
      )
      .AddInstruction(
        TTokenProgram.MintTo(
          LMint.PublicKey,
          LInitial.PublicKey,
          25000,
          LMintMs.PublicKey,
          TArray<IPublicKey>.Create(LMintS1.PublicKey, LMintS2.PublicKey, LMintS4.PublicKey)
      ))
      .AddInstruction(TMemoProgram.NewMemo(LOwner.PublicKey, 'Hello from SolLib'))
      .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB +
          'POPULATING TRANSACTION WITH SIGNATURES' + TAB);

  // Sign: fee payer + new token account + 3 mint multisig signers
  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),
      LInitial.Sign(LMsgBytes),
      LMintS1.Sign(LMsgBytes),
      LMintS2.Sign(LMsgBytes),
      LMintS4.Sign(LMsgBytes)
    )
  );

  LTxBytes   := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);

  // ---------------- Tx #4: Freeze the holder account (freeze multisig 3-of-5) ----------------
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      .AddInstruction(
        TTokenProgram.FreezeAccount(
          LInitial.PublicKey,
          LMint.PublicKey,
          LFreezeMs.PublicKey,
          TTokenProgram.ProgramIdKey,
          TArray<IPublicKey>.Create(LFreezeS2.PublicKey, LFreezeS3.PublicKey, LFreezeS4.PublicKey)
        )
      )
      .AddInstruction(TMemoProgram.NewMemo(LOwner.PublicKey, 'Hello from SolLib'))
      .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB +
          'POPULATING TRANSACTION WITH SIGNATURES' + TAB);

  // Sign: fee payer + the 3 freeze multisig signers
  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),
      LFreezeS2.Sign(LMsgBytes),
      LFreezeS3.Sign(LMsgBytes),
      LFreezeS4.Sign(LMsgBytes)
    )
  );

  LTxBytes   := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);

  // ---------------- Tx #5: Thaw, then SetAuthority(freeze) to none (freeze multisig 3-of-5) ----------------
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      .AddInstruction(
        TTokenProgram.ThawAccount(
          LInitial.PublicKey,
          LMint.PublicKey,
          LFreezeMs.PublicKey,
          TTokenProgram.ProgramIdKey,
          TArray<IPublicKey>.Create(LFreezeS2.PublicKey, LFreezeS3.PublicKey, LFreezeS4.PublicKey)
        )
      )
      .AddInstruction(
        TTokenProgram.SetAuthority(
          LMint.PublicKey,
          TAuthorityType.FreezeAccount,
          LFreezeMs.PublicKey,
          nil, // none
          TArray<IPublicKey>.Create(LFreezeS2.PublicKey, LFreezeS3.PublicKey, LFreezeS4.PublicKey)
        )
      )
      .AddInstruction(TMemoProgram.NewMemo(LOwner.PublicKey, 'Hello from SolLib'))
      .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB +
          'POPULATING TRANSACTION WITH SIGNATURES' + TAB);

  // Sign: fee payer + the 3 freeze multisig signers
  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),
      LFreezeS2.Sign(LMsgBytes),
      LFreezeS3.Sign(LMsgBytes),
      LFreezeS4.Sign(LMsgBytes)
    )
  );

  LTxBytes   := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);
end;


{ TApproveCheckedMultisigExample }

procedure TApproveCheckedMultisigExample.Run;
var
  LRpc        : IRpcClient;
  LWallet     : IWallet;
  LOwner      : IAccount;
  LDelegate   : IAccount;
  LMint       : IAccount;
  LInitial    : IAccount;

  // Token account & its multisig + signers
  LTokAcc     : IAccount;
  LTokMs      : IAccount;
  LTokS1, LTokS2, LTokS3, LTokS4, LTokS5: IAccount;

  // Mint multisig + signers (only 3 used for this flow)
  LMintMs     : IAccount;
  LMintS1, LMintS2, LMintS4: IAccount;

  LBlock      : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LMinMsRent  : IRequestResult<UInt64>;
  LMinAccRent : IRequestResult<UInt64>;
  LMinMintRent: IRequestResult<UInt64>;
  LTxBuilder  : ITransactionBuilder;

  LMsgBytes   : TBytes;
  LMsg        : IMessage;
  LTx         : ITransaction;
  LTxBytes    : TBytes;

  LSignature  : string;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  // Rents
  LMinMsRent   := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.MultisigAccountDataSize);
  Writeln('MinBalanceForRentExemption MultiSig >> ' + LMinMsRent.Result.ToString);
  LMinAccRent  := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.TokenAccountDataSize);
  Writeln('MinBalanceForRentExemption Account >> ' + LMinAccRent.Result.ToString);
  LMinMintRent := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.MintAccountDataSize);
  Writeln('MinBalanceForRentExemption Mint Account >> ' + LMinMintRent.Result.ToString);

  LOwner    := LWallet.GetAccountByIndex(10);
  LDelegate := LWallet.GetAccountByIndex(194330);
  LMint     := LWallet.GetAccountByIndex(94330);
  LInitial  := LWallet.GetAccountByIndex(84330);

  LMintMs := LWallet.GetAccountByIndex(10116);
  LMintS1 := LWallet.GetAccountByIndex(251280);
  LMintS2 := LWallet.GetAccountByIndex(251281);
  LMintS4 := LWallet.GetAccountByIndex(251283); // three signers used here

  LTokAcc := LWallet.GetAccountByIndex(4044);
  LTokMs  := LWallet.GetAccountByIndex(4045);

  LTokS1 := LWallet.GetAccountByIndex(25490);
  LTokS2 := LWallet.GetAccountByIndex(25491);
  LTokS3 := LWallet.GetAccountByIndex(25492);
  LTokS4 := LWallet.GetAccountByIndex(25493);
  LTokS5 := LWallet.GetAccountByIndex(25494);

  // ---------------- Tx #1: create token-account multisig + memo ----------------
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      .AddInstruction(
        TSystemProgram.CreateAccount(
          LOwner.PublicKey,
          LTokMs.PublicKey,
          LMinMsRent.Result,
          TTokenProgram.MultisigAccountDataSize,
          TTokenProgram.ProgramIdKey
        )
      )
      .AddInstruction(
        TTokenProgram.InitializeMultiSignature(
          LTokMs.PublicKey,
          TArray<IPublicKey>.Create(
            LTokS1.PublicKey, LTokS2.PublicKey, LTokS3.PublicKey, LTokS4.PublicKey, LTokS5.PublicKey
          ),
          3
        )
      )
      .AddInstruction(TMemoProgram.NewMemo(LOwner.PublicKey, 'Hello from SolLib'))
      .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB +
          'POPULATING TRANSACTION WITH SIGNATURES' + TAB);

  // Sign: fee payer + new multisig account
  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),
      LTokMs.Sign(LMsgBytes)
    )
  );

  LTxBytes   := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);

  // ---------------- Tx #2: create token account (owned by multisig) & mint to it via mint multisig ----------------
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      .AddInstruction(
        TSystemProgram.CreateAccount(
          LOwner.PublicKey,
          LTokAcc.PublicKey,
          LMinAccRent.Result,
          TTokenProgram.TokenAccountDataSize,
          TTokenProgram.ProgramIdKey
        )
      )
      .AddInstruction(
        TTokenProgram.InitializeAccount(
          LTokAcc.PublicKey,
          LMint.PublicKey,
          LTokMs.PublicKey
        )
      )
      .AddInstruction(
        TTokenProgram.MintTo(
          LMint.PublicKey,
          LTokAcc.PublicKey,
          25000,
          LMintMs.PublicKey,
          TArray<IPublicKey>.Create(
            LMintS1.PublicKey, LMintS2.PublicKey, LMintS4.PublicKey
          )
        )
      )
      .AddInstruction(TMemoProgram.NewMemo(LOwner.PublicKey, 'Hello from SolLib'))
      .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB +
          'POPULATING TRANSACTION WITH SIGNATURES' + TAB);

  // Sign: fee payer + new token account + 3 mint multisig signers
  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),
      LTokAcc.Sign(LMsgBytes),
      LMintS1.Sign(LMsgBytes),
      LMintS2.Sign(LMsgBytes),
      LMintS4.Sign(LMsgBytes)
    )
  );

  LTxBytes   := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);

  // ---------------- Tx #3: ApproveChecked by token-account multisig + memo ----------------
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      .AddInstruction(
        TTokenProgram.ApproveChecked(
          LTokAcc.PublicKey,
          LDelegate.PublicKey,
          5000,
          10,
          LTokMs.PublicKey,
          LMint.PublicKey,
          TArray<IPublicKey>.Create(
            LTokS1.PublicKey, LTokS2.PublicKey, LTokS3.PublicKey
          )
        )
      )
      .AddInstruction(TMemoProgram.NewMemo(LOwner.PublicKey, 'Hello from SolLib'))
      .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB +
          'POPULATING TRANSACTION WITH SIGNATURES' + TAB);

  // Sign: fee payer + 3 token multisig signers
  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),
      LTokS1.Sign(LMsgBytes),
      LTokS2.Sign(LMsgBytes),
      LTokS3.Sign(LMsgBytes)
    )
  );

  LTxBytes   := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);

  // ---------------- Tx #4: Delegate TransferChecked, then Revoke by multisig ----------------
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      .AddInstruction(
        TTokenProgram.TransferChecked(
          LTokAcc.PublicKey,
          LInitial.PublicKey,
          5000,
          10,
          LDelegate.PublicKey,
          LMint.PublicKey
        )
      )
      .AddInstruction(
        TTokenProgram.Revoke(
          LTokAcc.PublicKey,
          LTokMs.PublicKey,
          TArray<IPublicKey>.Create(
            LTokS1.PublicKey, LTokS2.PublicKey, LTokS3.PublicKey
          )
        )
      )
      .AddInstruction(TMemoProgram.NewMemo(LOwner.PublicKey, 'Hello from SolLib'))
      .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB +
          'POPULATING TRANSACTION WITH SIGNATURES' + TAB);

  // Sign: fee payer + delegate (for TransferChecked) + 3 token multisig signers (for Revoke)
  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),
      LDelegate.Sign(LMsgBytes),
      LTokS1.Sign(LMsgBytes),
      LTokS2.Sign(LMsgBytes),
      LTokS3.Sign(LMsgBytes)
    )
  );

  LTxBytes   := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);
end;

{ TSimpleMintToAndBurnCheckedMultisigExample }

procedure TSimpleMintToAndBurnCheckedMultisigExample.Run;
var
  LRpc       : IRpcClient;
  LWallet    : IWallet;
  LOwner     : IAccount;
  LMint      : IAccount;
  LTokAcc    : IAccount;

  // Mint multisig + signers
  LMintMs    : IAccount;
  LMintS1, LMintS2, LMintS3: IAccount;

  // Token-account multisig + signers
  LTokMs     : IAccount;
  LTokS1, LTokS2, LTokS3: IAccount;

  LBlock     : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LTxBuilder : ITransactionBuilder;

  // Reused artifacts
  LMsgBytes  : TBytes;
  LMsg       : IMessage;
  LTx        : ITransaction;
  LTxBytes   : TBytes;

  LSignature : string;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LOwner  := LWallet.GetAccountByIndex(10);
  LMint   := LWallet.GetAccountByIndex(94330);
  LTokAcc := LWallet.GetAccountByIndex(4044);

  LMintMs := LWallet.GetAccountByIndex(10116);
  LMintS1 := LWallet.GetAccountByIndex(251280);
  LMintS2 := LWallet.GetAccountByIndex(251281);
  LMintS3 := LWallet.GetAccountByIndex(251282);

  LTokMs  := LWallet.GetAccountByIndex(4045);
  LTokS1  := LWallet.GetAccountByIndex(25490);
  LTokS2  := LWallet.GetAccountByIndex(25491);
  LTokS3  := LWallet.GetAccountByIndex(25492);

  // -------- Single Tx: MintToChecked (mint multisig) + BurnChecked (token multisig) + Memo --------
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      .AddInstruction(
        TTokenProgram.MintToChecked(
          LMint.PublicKey,
          LTokAcc.PublicKey,
          LMintMs.PublicKey,
          1000000000,
          10,
          TArray<IPublicKey>.Create(
            LMintS1.PublicKey, LMintS2.PublicKey, LMintS3.PublicKey
          )
        )
      )
      .AddInstruction(
        TTokenProgram.BurnChecked(
          LMint.PublicKey,
          LTokAcc.PublicKey,
          LTokMs.PublicKey,
          500000,
          10,
          TArray<IPublicKey>.Create(
            LTokS1.PublicKey, LTokS2.PublicKey, LTokS3.PublicKey
          )
        )
      )
      .AddInstruction(TMemoProgram.NewMemo(LOwner.PublicKey, 'Hello from SolLib'))
      .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB +
          'POPULATING TRANSACTION WITH SIGNATURES' + TAB);

  // Sign: fee payer + 3 mint multisig signers (MintToChecked) + 3 token multisig signers (BurnChecked)
  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),
      LMintS1.Sign(LMsgBytes),
      LMintS2.Sign(LMsgBytes),
      LMintS3.Sign(LMsgBytes),
      LTokS1.Sign(LMsgBytes),
      LTokS2.Sign(LMsgBytes),
      LTokS3.Sign(LMsgBytes)
    )
  );

  LTxBytes   := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);
end;

{ TBurnCheckedAndCloseAccountMultisigExample }

procedure TBurnCheckedAndCloseAccountMultisigExample.Run;
var
  LRpc        : IRpcClient;
  LWallet     : IWallet;
  LOwner      : IAccount;
  LMint       : IAccount;
  LTokAcc     : IAccount;

  // token-account multisig + signers
  LTokMs      : IAccount;
  LTokS1, LTokS2, LTokS3: IAccount;

  LBlock      : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LBalanceRes : IRequestResult<TResponseValue<TTokenBalance>>;
  LTxBuilder  : ITransactionBuilder;

  LMsgBytes   : TBytes;
  LMsg        : IMessage;
  LTx         : ITransaction;
  LTxBytes    : TBytes;

  LSignature  : string;
  LAmountU64  : UInt64;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  LOwner  := LWallet.GetAccountByIndex(10);
  LMint   := LWallet.GetAccountByIndex(94330);
  LTokAcc := LWallet.GetAccountByIndex(4044);
  LTokMs  := LWallet.GetAccountByIndex(4045);
  LTokS1  := LWallet.GetAccountByIndex(25490);
  LTokS2  := LWallet.GetAccountByIndex(25491);
  LTokS3  := LWallet.GetAccountByIndex(25492);

  LBalanceRes := LRpc.GetTokenAccountBalance(LTokAcc.PublicKey.Key);
  Writeln('Account Balance >> ' + LBalanceRes.Result.Value.UiAmountString);
  LAmountU64 := LBalanceRes.Result.Value.AmountUInt64;

  // -------- Single Tx: BurnChecked (token multisig) + CloseAccount (token multisig) + Memo --------
  LBlock := LRpc.GetLatestBlockHash;

  LTxBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LOwner.PublicKey)
      .AddInstruction(
        TTokenProgram.BurnChecked(
          LMint.PublicKey,
          LTokAcc.PublicKey,
          LTokMs.PublicKey,
          LAmountU64,
          10,
          TArray<IPublicKey>.Create(
            LTokS1.PublicKey, LTokS2.PublicKey, LTokS3.PublicKey
          )
        )
      )
      .AddInstruction(
        TTokenProgram.CloseAccount(
          LTokAcc.PublicKey,
          LOwner.PublicKey,
          LTokMs.PublicKey,
          TTokenProgram.ProgramIdKey,
          TArray<IPublicKey>.Create(
            LTokS1.PublicKey, LTokS2.PublicKey, LTokS3.PublicKey
          )
        )
      )
      .AddInstruction(TMemoProgram.NewMemo(LOwner.PublicKey, 'Hello from SolLib'))
      .CompileMessage;

  LMsg := DecodeMessageFromWire(LMsgBytes);

  Writeln(NEWLINE + TAB +
          'POPULATING TRANSACTION WITH SIGNATURES' + TAB);

  // Sign: fee payer + token multisig signers (for BurnChecked & CloseAccount)
  LTx := TTransaction.Populate(
    LMsg,
    TArray<TBytes>.Create(
      LOwner.Sign(LMsgBytes),
      LTokS1.Sign(LMsgBytes),
      LTokS2.Sign(LMsgBytes),
      LTokS3.Sign(LMsgBytes)
    )
  );

  LTxBytes   := LogTransactionAndSerialize(LTx);
  LSignature := SubmitTxSendAndLog(LTxBytes);
  PollConfirmedTx(LSignature);
end;


{ TGetMultiSignatureAccountExample }

procedure TGetMultiSignatureAccountExample.Run;
var
  LRpc       : IRpcClient;
  LWallet    : IWallet;
  LMs        : IAccount;
  LAccInfo   : IRequestResult<TResponseValue<TAccountInfo>>;
  LBytes     : TBytes;
  LMultiSig  : IMultiSignatureAccount;
begin
  LRpc    := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  // The multisig which is the token account authority
  LMs := LWallet.GetAccountByIndex(4045);
  LAccInfo := LRpc.GetAccountInfo(LMs.PublicKey.Key);

  LBytes := TEncoders.Base64.DecodeData(LAccInfo.Result.Value.Data[0]);
  LMultiSig := TMultiSignatureAccount.Deserialize(LBytes);

  Writeln(Format('Multisig threshold: MinimumSigners = %d of NumberOfSigners = %d',
    [LMultiSig.MinimumSigners, LMultiSig.NumberSigners]));
end;

end.

