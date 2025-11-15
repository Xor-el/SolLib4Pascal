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

unit SlpTransactionDecodingExample;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpExample,
  SlpSolanaRpcClient,
  SlpWallet,
  SlpRequestResult,
  SlpRpcModel,
  SlpRpcMessage,
  SlpAccount,
  SlpPublicKey,
  SlpDataEncoders,
  SlpTransactionDomain,
  SlpTransactionInstruction,
  SlpTransactionBuilder,
  SlpAccountDomain,
  SlpTokenProgram,
  SlpSystemProgram,
  SlpMemoProgram;

type
  /// <summary>
  /// Builds a multi-instruction message, simulates, decodes from wire format,
  /// prints fields (fee payer, blockhash, signatures, instruction metas), and
  /// simulates again to verify equivalence.
  /// </summary>
  /// <remarks>
  ///   This example covers the full transaction lifecycle:
  ///   <list type="number">
  ///     <item>Creating and initializing accounts (mint, token, and derived system accounts).</item>
  ///     <item>Building the transaction message using <c>TTransactionBuilder</c>.</item>
  ///     <item>Signing and serializing the transaction.</item>
  ///     <item>Decoding and inspecting the transaction structure.</item>
  ///     <item>Re-simulating the decoded transaction for validation.</item>
  ///   </list>
  /// </remarks>
  TTransactionDecodingExample = class(TBaseExample)
  private
   const
     MnemonicWords = TBaseExample.MNEMONIC_WORDS;
  public
    /// <summary>Runs the example.</summary>
    procedure Run; override;
  end;

implementation

{ TTransactionDecodingExample }

procedure TTransactionDecodingExample.Run;
var
  LRpc: IRpcClient;
  LWallet: IWallet;
  LOwnerAccount, LMintAccount, LInitialAccount: IAccount;
  LBlockhashResult: IRequestResult<TResponseValue<TLatestBlockHash>>;
  LMinRentAcc, LMinRentMint: IRequestResult<UInt64>;
  LBuilder: ITransactionBuilder;
  LMsgData, LTxBytes, LTxDecBytes: TBytes;
  LBase64Msg: string;
  LTxPopulated: ITransaction;
  LSigPair: ISignaturePubKeyPair;
  LTxDecoded: ITransaction;
  DerivedAccountPublicKey: IPublicKey;
  TxIx: ITransactionInstruction;
begin
  // 1. Initialize RPC client and wallet
  LRpc := TestNetRpcClient;
  LWallet := TWallet.Create(MnemonicWords);

  // Retrieve accounts for this example
  LOwnerAccount   := LWallet.GetAccountByIndex(0);     // Fee payer / authority
  LMintAccount    := LWallet.GetAccountByIndex(7000);   // Mint account
  LInitialAccount := LWallet.GetAccountByIndex(7001);   // Token account

  // 2. Fetch recent blockhash and rent-exemption balances
  LBlockhashResult := LRpc.GetLatestBlockHash;
  LMinRentAcc      := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.TokenAccountDataSize);
  LMinRentMint     := LRpc.GetMinimumBalanceForRentExemption(TTokenProgram.MintAccountDataSize);

  // Log account info
  Writeln(Format('MinBalanceForRentExemption Account >> %d', [LMinRentAcc.Result]));
  Writeln(Format('MinBalanceForRentExemption Mint    >> %d', [LMinRentMint.Result]));
  Writeln(Format('OwnerAccount: %s', [LOwnerAccount.PublicKey.Key]));
  Writeln(Format('MintAccount:  %s', [LMintAccount.PublicKey.Key]));
  Writeln(Format('InitialAccount: %s', [LInitialAccount.PublicKey.Key]));

  // 3. Create a seed-derived system account
  TPublicKey.TryCreateWithSeed(
    LOwnerAccount.PublicKey,
    'Some Seed',
    TSystemProgram.ProgramIdKey,
    DerivedAccountPublicKey
  );

  // 4. Build transaction
  LBuilder := TTransactionBuilder.Create;
  LMsgData :=
    LBuilder
      .SetRecentBlockHash(LBlockhashResult.Result.Value.Blockhash)
      .SetFeePayer(LOwnerAccount.PublicKey)

      // 1. Create mint account
      .AddInstruction(TSystemProgram.CreateAccount(
        LOwnerAccount.PublicKey,
        LMintAccount.PublicKey,
        LMinRentMint.Result,
        TTokenProgram.MintAccountDataSize,
        TTokenProgram.ProgramIdKey
      ))

      // 2. Initialize mint (2 decimals, authority = owner)
      .AddInstruction(TTokenProgram.InitializeMint(
        LMintAccount.PublicKey,
        2,
        LOwnerAccount.PublicKey,
        LOwnerAccount.PublicKey
      ))

      // 3. Create seed-derived account (fund with rent-exempt lamports)
      .AddInstruction(TSystemProgram.CreateAccountWithSeed(
        LOwnerAccount.PublicKey,
        DerivedAccountPublicKey,
        LOwnerAccount.PublicKey,
        'Some Seed',
        LMinRentAcc.Result,
        0,
        TSystemProgram.ProgramIdKey
      ))

      // 4. Transfer lamports from derived to owner
      .AddInstruction(TSystemProgram.TransferWithSeed(
        DerivedAccountPublicKey,
        LOwnerAccount.PublicKey,
        'Some Seed',
        TSystemProgram.ProgramIdKey,
        LOwnerAccount.PublicKey,
        25000
      ))

      // 5. Create token account
      .AddInstruction(TSystemProgram.CreateAccount(
        LOwnerAccount.PublicKey,
        LInitialAccount.PublicKey,
        LMinRentAcc.Result,
        TTokenProgram.TokenAccountDataSize,
        TTokenProgram.ProgramIdKey
      ))

      // 6. Initialize token account
      .AddInstruction(TTokenProgram.InitializeAccount(
        LInitialAccount.PublicKey,
        LMintAccount.PublicKey,
        LOwnerAccount.PublicKey
      ))

      // 7. Mint tokens
      .AddInstruction(TTokenProgram.MintTo(
        LMintAccount.PublicKey,
        LInitialAccount.PublicKey,
        1000000,
        LOwnerAccount.PublicKey
      ))

      // 8. Add memo
      .AddInstruction(TMemoProgram.NewMemo(LInitialAccount.PublicKey, 'Hello from SolLib'))
      .CompileMessage;

  // 5. Encode message to Base64
  LBase64Msg := TEncoders.Base64.EncodeData(LMsgData);
  Writeln(Format('Message: %s', [LBase64Msg]));

  // 6. Sign and populate transaction
  LTxPopulated := TTransaction.Populate(
    LBase64Msg,
    TArray<TBytes>.Create(
      LOwnerAccount.Sign(LMsgData),
      LMintAccount.Sign(LMsgData),
      LInitialAccount.Sign(LMsgData)
    )
  );
  LTxBytes := LTxPopulated.Serialize;

  // 7. Simulate original transaction
  SimulateTxAndLog(LTxBytes);

  // 8. Decode and inspect the transaction
  Writeln(Format('%sDECODING TRANSACTION FROM WIRE FORMAT%s%s',
                 [TAB, TAB, NEWLINE]));
  LTxDecoded := TTransaction.Deserialize(LTxBytes);

  Writeln(Format('FeePayer: %s', [LTxDecoded.FeePayer.Key]));
  Writeln(Format('BlockHash/Nonce: %s', [LTxDecoded.RecentBlockHash]));

  // Display signatures
  for LSigPair in LTxDecoded.Signatures do
    Writeln(Format('Signer: %s%sSignature: %s',
      [LSigPair.PublicKey.Key,
       TAB,
       TEncoders.Base58.EncodeData(LSigPair.Signature)]));

  // Display instructions and account metadata
  for TxIx in LTxDecoded.Instructions do
  begin
    Writeln(Format('ProgramKey: %s%s%sInstructionData: %s',
      [TEncoders.Base58.EncodeData(TxIx.ProgramId),
       NEWLINE,
       TAB,
       TEncoders.Base64.EncodeData(TxIx.Data)]));

    var M: IAccountMeta;
    for M in TxIx.Keys do
      Writeln(Format('%sAccountMeta: %s%sWritable: %s%sSigner: %s',
        [TAB,
         M.PublicKey.Key,
         TAB,
         BoolToStr(M.IsWritable, True),
         TAB,
         BoolToStr(M.IsSigner, True)]));
  end;

  // 9. Serialize decoded transaction and simulate again
  LTxDecBytes := LTxDecoded.Serialize;
  SimulateTxAndLog(LTxDecBytes);
end;


end.

