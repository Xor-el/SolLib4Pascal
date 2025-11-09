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

unit SlpAssociatedTokenAccountsExample;

{$I ..\..\SolLib\src\Include\SolLib.inc}

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
  SlpAssociatedTokenAccountProgram,
  SlpRpcModel,
  SlpRpcMessage,
  SlpTransactionBuilder,
  SlpRequestResult,
  SlpExample;

type
  /// <summary>
  ///   Demonstrates creating mint and token accounts, minting tokens,
  ///   and transferring tokens to an associated token account (ATA).
  /// </summary>
  /// <remarks>
  ///   This example shows a full flow of:
  ///   <list type="number">
  ///     <item>Creating and initializing a mint account</item>
  ///     <item>Creating and initializing a token account</item>
  ///     <item>Minting tokens to the initial token account</item>
  ///     <item>Creating an ATA for another owner</item>
  ///     <item>Transferring tokens to the ATA</item>
  ///   </list>
  /// </remarks>
  TAssociatedTokenAccountsExample = class(TBaseExample)
  private
    const
      MnemonicWords = TBaseExample.MNEMONIC_WORDS;
  public
    procedure Run; override;
  end;

implementation

procedure TAssociatedTokenAccountsExample.Run;
var
  LWallet: IWallet;
  LOwner, LMint, LInitial: IAccount;
  LBlockhash: IRequestResult<TResponseValue<TLatestBlockHash>>;
  LMinAccRent, LMinMintRent: IRequestResult<UInt64>;
  LTxBuilder: ITransactionBuilder;
  LTx: TBytes;
  LSignature: string;
  LAssociatedOwner, LAssociatedAta: IPublicKey;
  LSigners: TList<IAccount>;
begin
  //
  // Setup: create wallet and accounts
  //
  LWallet  := TWallet.Create(MnemonicWords);
  LOwner   := LWallet.GetAccountByIndex(0);   // fee payer / owner
  LMint    := LWallet.GetAccountByIndex(1030);  // mint account
  LInitial := LWallet.GetAccountByIndex(1031);  // token account to hold minted tokens

  //
  // Get network info and minimum balance requirements
  //
  LBlockhash   := TestNetRpcClient.GetLatestBlockHash;
  LMinAccRent  := TestNetRpcClient.GetMinimumBalanceForRentExemption(TTokenProgram.TokenAccountDataSize);
  LMinMintRent := TestNetRpcClient.GetMinimumBalanceForRentExemption(TTokenProgram.MintAccountDataSize);

  Writeln(Format('MinBalanceForRentExemption Account >> %d', [LMinAccRent.Result]));
  Writeln(Format('MinBalanceForRentExemption Mint    >> %d', [LMinMintRent.Result]));
  Writeln(Format('OwnerAccount:  %s', [LOwner.PublicKey.Key]));
  Writeln(Format('MintAccount:   %s', [LMint.PublicKey.Key]));
  Writeln(Format('InitialAccount:%s', [LInitial.PublicKey.Key]));

  //
  // Step 1: Create & initialize mint and token account, then mint tokens
  //
  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlockhash.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)

    // create mint account
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LMint.PublicKey,
        LMinMintRent.Result,
        TTokenProgram.MintAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )

    // initialize mint (decimals = 2, mint & freeze authority = owner)
    .AddInstruction(
      TTokenProgram.InitializeMint(
        LMint.PublicKey,
        2,
        LOwner.PublicKey,
        LOwner.PublicKey
      )
    )

    // create token account to hold minted tokens
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwner.PublicKey,
        LInitial.PublicKey,
        LMinAccRent.Result,
        TTokenProgram.TokenAccountDataSize,
        TTokenProgram.ProgramIdKey
      )
    )

    // initialize token account with owner
    .AddInstruction(
      TTokenProgram.InitializeAccount(
        LInitial.PublicKey,
        LMint.PublicKey,
        LOwner.PublicKey
      )
    )

    // mint tokens to initial account
    .AddInstruction(
      TTokenProgram.MintTo(
        LMint.PublicKey,
        LInitial.PublicKey,
        1000000,
        LOwner.PublicKey
      )
    )

    // add optional memo
    .AddInstruction(
      TMemoProgram.NewMemo(LInitial.PublicKey, 'Hello from SolLib')
    );

  // Build transaction with required signers
  LSigners := TList<IAccount>.Create;
  try
    LSigners.Add(LOwner);
    LSigners.Add(LMint);
    LSigners.Add(LInitial);
    LTx := LTxBuilder.Build(LSigners);
  finally
    LSigners.Free;
  end;

  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);

  //
  // Step 2: Create an associated token account (ATA) for another owner and transfer tokens
  //
  LAssociatedOwner := TPublicKey.Create('65EoWs57dkMEWbK4TJkPDM76rnbumq7r3fiZJnxggj2G');
  LAssociatedAta   := TAssociatedTokenAccountProgram.DeriveAssociatedTokenAccount(
                        LAssociatedOwner,
                        LMint.PublicKey
                      );

  Writeln(Format('AssociatedTokenAccountOwner: %s', [LAssociatedOwner.Key]));
  Writeln(Format('AssociatedTokenAccount:      %s', [LAssociatedAta.Key]));

  LTxBuilder := TTransactionBuilder.Create;
  LTxBuilder
    .SetRecentBlockHash(LBlockhash.Result.Value.Blockhash)
    .SetFeePayer(LOwner.PublicKey)

    // create ATA
    .AddInstruction(
      TAssociatedTokenAccountProgram.CreateAssociatedTokenAccount(
        LOwner.PublicKey,       // payer
        LAssociatedOwner,       // owner of the ATA
        LMint.PublicKey         // mint
      )
    )

    // transfer SPL tokens from initial account to ATA
    .AddInstruction(
      TTokenProgram.Transfer(
        LInitial.PublicKey,
        LAssociatedAta,
        25000,
        LOwner.PublicKey        // owner authority of initial account
      )
    )

    // add memo
    .AddInstruction(
      TMemoProgram.NewMemo(LOwner.PublicKey, 'Hello from SolLib')
    );

  // Build transaction with signers
  LSigners := TList<IAccount>.Create;
  try
    LSigners.Add(LOwner);
    LTx := LTxBuilder.Build(LSigners);
  finally
    LSigners.Free;
  end;

  LSignature := SubmitTxSendAndLog(LTx);
  PollConfirmedTx(LSignature);
end;

end.

