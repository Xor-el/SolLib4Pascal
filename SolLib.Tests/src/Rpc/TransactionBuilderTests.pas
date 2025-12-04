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

unit TransactionBuilderTests;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpDataEncoders,
  SlpWallet,
  SlpPublicKey,
  SlpAccount,
  SlpTransactionDomain,
  SlpAccountDomain,
  SlpTransactionInstruction,
  SlpTransactionInstructionFactory,
  SlpTransactionBuilder,
  SlpTokenProgram,
  SlpMemoProgram,
  SlpSystemProgram,
  SlpComputeBudgetProgram,
  SolLibTestCase;

type
  TTransactionBuilderTests = class(TSolLibTestCase)
  private
    const MnemonicWords =
      'route clerk disease box emerge airport loud waste attitude film army tray'+
      ' forward deal onion eight catalog surface unit card window walnut wealth medal';

    const Blockhash = '5cZja93sopRB9Bkhckj5WzCxCaVyriv2Uh5fFDPDFFfj';

    const AddSignatureBlockHash = 'F2EzHpSp2WYRDA1roBN2Q4Wzw7ePxU2z1zWfh8ejUEyh';

    const AddSignatureTransaction =
      'AblTj+KPqqFaUoAB33XKA6zNlGS0pLqpeSQ6MFJsU6jwEKpCRgESlDTEVek24EnTkL7kgQ8iOul3GrpxiGDOWw8' +
      'BAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7J7rHLZwOnCKOnqrRmjOO1w2JcV0XhPLlWiw5thiF' +
      'gQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUpTUPhdyILWFKVWcniKKW3fHqur0KYGeIhJMvTu9' +
      'qDQVQOHggZl4ubetKawWVznB6EGcsLPkeO3Skl7nXGaZAICAgABDAIAAACAlpgAAAAAAAMBABRIZWxsbyBmcm9t' +
      'IFNvbExpYiA6KQ==';

    const AddSignatureSignature =
      '4huXNSqdfRbjrisfXRnSUtjewZUbhJzCRZCFGbW6S3tATvzD6Ror91iYPogBhsoyZecuXaWx9E1DZDAVV8EFneJz';

    const ExpectedTransactionHashWithTransferAndMemo =
      'AUvMogol1CIrs5z3iOPEDMimN10opYACOPdxPGvXP/IXMugia/G8GG9RJf93qZMDxOm8zvKL/' +
      '2zsOE3N/MOjhAMBAAIEUy4zulRg8z2yKITZaNwcnq6G6aH8D0ITae862qbJ+3eE3M6r5DRwldq' +
      'uwlqOuXDDOWZagXmbHnAU3w5Dg44kogAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
      'BUpTUPhdyILWFKVWcniKKW3fHqur0KYGeIhJMvTu9qBEixald4nI54jqHpYLSWViej50bnmzhe' +
      'n0yUOsH2zbbgICAgABDAIAAACAlpgAAAAAAAMBABRIZWxsbyBmcm9tIFNvbExpYiA6KQ==';

    const ExpectedTransactionHashCreateInitializeAndMintTo =
      'A2KFRswz3UCwTstAlTCXS6+vmjJSuVMGqmqWcmvl91mWgq/cvXH6leXV2pYLZJlZw5bqD1o41F' +
      'yeEzM6X0lHtg6tdu2LNYlr3qY8spnj8ExkdsMJknooWzPio1kuGh1V0863EyF44tLk6I9erKdL' +
      'pvgJq9hppRmrwec1IvhODkoBGE3+toaUClFfKsbunbYPOexA0OEOPp8KTzloUG8Io7bZ//lPrU' +
      '3W9ecTdmSWyNZf7ii/Y7ul+SgSUNjECMb9DQMABAdHaauXIEuoP7DK7hf3ho8eB05SFYGg2J2U' +
      'N52qZbcXsk0+Jb2M++6vIpkqr8zv+aohVvbSqnzuJeRSoRYepWULT6cip03g/pgXJNLrhxqTpZ' +
      '3aHH1CxvB/iB89zlU8m8UAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAVKU1D4XciC' +
      '1hSlVnJ4iilt3x6rq9CmBniISTL07vagBqfVFxksXFEhjMlMPUrxf1ja7gibof1E49vZigAAAA' +
      'AG3fbh12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqeD/Y3arpTMrvjv2uP0ZD3LVkDTmRAfO' +
      'pQ603IYXOGjCBgMCAAI0AAAAAGBNFgAAAAAAUgAAAAAAAAAG3fbh12Whk9nL4UbO63msHLSF7V' +
      '9bN5E6jPWFfv8AqQYCAgVDAAJHaauXIEuoP7DK7hf3ho8eB05SFYGg2J2UN52qZbcXsgFHaauX' +
      'IEuoP7DK7hf3ho8eB05SFYGg2J2UN52qZbcXsgMCAAE0AAAAAPAdHwAAAAAApQAAAAAAAAAG3f' +
      'bh12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqQYEAQIABQEBBgMCAQAJB6hhAAAAAAAABAEB' +
      'EUhlbGxvIGZyb20gU29sTGli';

     const ExpectedTransactionWithPriorityFees =
       'ARqI0iR2oVNDASDRffW1q2Tg37+HscfElZragqnj7z/1mNxjNs14DK1atOlCTzEnw3KsQtKCgn' +
       'mBOA3qh+sDnAkBAAIER2mrlyBLqD+wyu4X94aPHgdOUhWBoNidlDedqmW3F7KE3M6r5DRwldqu' +
       'wlqOuXDDOWZagXmbHnAU3w5Dg44kogAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAw' +
       'ZGb+UhFzL/7K26csOb57yM5bvF9xJrLEObOkAAAABEixald4nI54jqHpYLSWViej50bnmzhen0' +
       'yUOsH2zbbgMDAAUCgBoGAAMACQOghgEAAAAAAAICAAEMAgAAAEBCDwAAAAAA';

    const NonceStr = '2S1kjspXLPs6jpNVXQfNMqZzzSrKLbGdr9Fxap5h1DLN';

  published
    procedure TestTransactionBuilderBuildNullInstructionsException;
    procedure TestTransactionBuilderBuild;
    procedure TestTransactionBuilderBuildNullBlockhashException;
    procedure TestTransactionBuilderBuildNullFeePayerException;
    procedure TestTransactionBuilderBuildEmptySignersException;
    procedure CreateInitializeAndMintToTest;
    procedure CompileMessageTest;
    procedure TestTransactionInstructionTest;
    procedure TransactionBuilderAddSignatureTest;
    procedure TestTransactionWithPriorityFeesInformation;
  end;

implementation

{ TTransactionBuilderTests }

procedure TTransactionBuilderTests.TestTransactionBuilderBuildNullInstructionsException;
var
  Wallet: IWallet;
  FromAccount: IAccount;
  Builder: ITransactionBuilder;
begin
  Wallet := TWallet.Create(MnemonicWords);
  FromAccount := Wallet.GetAccountByIndex(0);

  Builder := TTransactionBuilder.Create;
  Builder.SetRecentBlockHash(Blockhash);

  AssertException(
    procedure
    begin
      Builder.Build(FromAccount)
    end,
    Exception
  );
end;

procedure TTransactionBuilderTests.TestTransactionBuilderBuild;
var
  Wallet: IWallet;
  FromAccount, ToAccount: IAccount;
  Builder: ITransactionBuilder;
  TxBytes: TBytes;
  B64: string;
begin
  Wallet := TWallet.Create(MnemonicWords);
  FromAccount := Wallet.GetAccountByIndex(0);
  ToAccount   := Wallet.GetAccountByIndex(1);

  Builder := TTransactionBuilder.Create;
  TxBytes := Builder
    .SetRecentBlockHash(Blockhash)
    .SetFeePayer(FromAccount.PublicKey)
    .AddInstruction(TSystemProgram.Transfer(FromAccount.PublicKey, ToAccount.PublicKey, 10000000))
    .AddInstruction(TMemoProgram.NewMemo(FromAccount.PublicKey, 'Hello from SolLib :)'))
    .Build(FromAccount);

  B64 := TEncoders.Base64.EncodeData(TxBytes);
  AssertEquals(ExpectedTransactionHashWithTransferAndMemo, B64);
end;

procedure TTransactionBuilderTests.TestTransactionBuilderBuildNullBlockhashException;
var
  Wallet: IWallet;
  FromAccount, ToAccount: IAccount;
  Builder: ITransactionBuilder;
begin
  Wallet := TWallet.Create(MnemonicWords);
  FromAccount := Wallet.GetAccountByIndex(0);
  ToAccount   := Wallet.GetAccountByIndex(1);

  Builder := TTransactionBuilder.Create;
  Builder
    .SetFeePayer(FromAccount.PublicKey)
    .AddInstruction(TSystemProgram.Transfer(FromAccount.PublicKey, ToAccount.PublicKey, 10000000))
    .AddInstruction(TMemoProgram.NewMemo(FromAccount.PublicKey, 'Hello from SolLib :)'));

  AssertException(
    procedure
    begin
      Builder.Build(FromAccount)
    end,
    Exception
  );
end;

procedure TTransactionBuilderTests.TestTransactionBuilderBuildNullFeePayerException;
var
  Wallet: IWallet;
  FromAccount, ToAccount: IAccount;
  Builder: ITransactionBuilder;
begin
  Wallet := TWallet.Create(MnemonicWords);
  FromAccount := Wallet.GetAccountByIndex(0);
  ToAccount   := Wallet.GetAccountByIndex(1);

  Builder := TTransactionBuilder.Create;
  Builder
    .SetRecentBlockHash(Blockhash)
    .AddInstruction(TSystemProgram.Transfer(FromAccount.PublicKey, ToAccount.PublicKey, 10000000))
    .AddInstruction(TMemoProgram.NewMemo(FromAccount.PublicKey, 'Hello from SolLib :)'));

  AssertException(
    procedure
    begin
      Builder.Build(FromAccount)
    end,
    Exception
  );
end;

procedure TTransactionBuilderTests.TestTransactionBuilderBuildEmptySignersException;
var
  Wallet: IWallet;
  FromAccount, ToAccount: IAccount;
  Builder: ITransactionBuilder;
  EmptySigners: TList<IAccount>;
begin
  Wallet := TWallet.Create(MnemonicWords);
  FromAccount := Wallet.GetAccountByIndex(0);
  ToAccount   := Wallet.GetAccountByIndex(1);

  EmptySigners := TList<IAccount>.Create;
  try
    Builder := TTransactionBuilder.Create;
    Builder
      .SetRecentBlockHash(Blockhash)
      .AddInstruction(TSystemProgram.Transfer(FromAccount.PublicKey, ToAccount.PublicKey, 10000000))
      .AddInstruction(TMemoProgram.NewMemo(FromAccount.PublicKey, 'Hello from SolLib :)'));

    AssertException(
      procedure
      begin
        Builder.Build(EmptySigners)
      end,
      Exception
    );
  finally
    EmptySigners.Free;
  end;
end;

procedure TTransactionBuilderTests.CreateInitializeAndMintToTest;
var
  Wallet: IWallet;
  BlockHash, B64: string;
  MinBalanceForAccount, MinBalanceForMint: UInt64;
  MintAccount, OwnerAccount, InitialAccount: IAccount;
  Builder: ITransactionBuilder;
  Signers: TList<IAccount>;
  Tx: TBytes;
  Tx2: ITransaction;
  Msg: TBytes;
  Ok: Boolean;
begin
  Wallet := TWallet.Create(MnemonicWords);
  BlockHash := 'G9JC6E7LfG6ayxARq5zDV5RdDr6P8NJEdzTUJ8ttrSKs';
  MinBalanceForAccount := 2039280;
  MinBalanceForMint    := 1461600;

  MintAccount    := Wallet.GetAccountByIndex(17);
  OwnerAccount   := Wallet.GetAccountByIndex(10);
  InitialAccount := Wallet.GetAccountByIndex(18);

  Builder := TTransactionBuilder.Create;
  Builder
    .SetRecentBlockHash(BlockHash)
    .SetFeePayer(OwnerAccount.PublicKey)
    .AddInstruction(
      TSystemProgram.CreateAccount(
        OwnerAccount.PublicKey, MintAccount.PublicKey, MinBalanceForMint,
        TTokenProgram.MintAccountDataSize, TTokenProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TTokenProgram.InitializeMint(
        MintAccount.PublicKey, 2, OwnerAccount.PublicKey, OwnerAccount.PublicKey
      )
    )
    .AddInstruction(
      TSystemProgram.CreateAccount(
        OwnerAccount.PublicKey, InitialAccount.PublicKey, MinBalanceForAccount,
        TTokenProgram.TokenAccountDataSize, TTokenProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TTokenProgram.InitializeAccount(
        InitialAccount.PublicKey, MintAccount.PublicKey, OwnerAccount.PublicKey
      )
    )
    .AddInstruction(
      TTokenProgram.MintTo(
        MintAccount.PublicKey, InitialAccount.PublicKey, 25000, OwnerAccount.PublicKey
      )
    )
    .AddInstruction(TMemoProgram.NewMemo(InitialAccount.PublicKey, 'Hello from SolLib'));

  Signers := TList<IAccount>.Create;
  try
    Signers.AddRange([OwnerAccount, MintAccount, InitialAccount]);
    Tx := Builder.Build(Signers);
  finally
    Signers.Free;
  end;

  Tx2 := TTransaction.Deserialize(Tx);
  Msg := Tx2.CompileMessage;
  Ok := Tx2.Signatures[0].PublicKey.Verify(Msg, Tx2.Signatures[0].Signature);
  AssertTrue(Ok, 'Signature[0] should verify');

  B64 := TEncoders.Base64.EncodeData(Tx);
  AssertEquals(ExpectedTransactionHashCreateInitializeAndMintTo, B64);
end;

procedure TTransactionBuilderTests.CompileMessageTest;
var
  Wallet: IWallet;
  OwnerAccount, NonceAccount, ToAccount: IAccount;
  NonceInfo: INonceInformation;
  Builder: ITransactionBuilder;
  CompiledMessageBytes, TxBytes: TBytes;
begin
  CompiledMessageBytes := TBytes.Create(
    1, 0, 2, 5, 71, 105, 171, 151, 32, 75, 168, 63, 176, 202, 238, 23, 247, 134, 143, 30, 7, 78, 82, 21,
    129, 160, 216, 157, 148, 55, 157, 170, 101, 183, 23, 178, 132, 220, 206, 171, 228, 52, 112, 149, 218,
    174, 194, 90, 142, 185, 112, 195, 57, 102, 90, 129, 121, 155, 30, 112, 20, 223, 14, 67, 131, 142, 36,
    162, 223, 244, 229, 56, 86, 243, 0, 74, 86, 58, 56, 142, 17, 130, 113, 147, 61, 1, 136, 126, 243, 22,
    226, 173, 108, 74, 212, 104, 81, 199, 120, 180, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 167, 213, 23, 25, 44, 86, 142, 224, 138, 132, 95, 115, 210,
    151, 136, 207, 3, 92, 49, 69, 178, 26, 179, 68, 216, 6, 46, 169, 64, 0, 0, 21, 68, 15, 82, 0, 49, 0,
    146, 241, 176, 13, 84, 249, 55, 39, 9, 212, 80, 57, 8, 193, 89, 211, 49, 162, 144, 45, 140, 117, 21, 46,
    83, 2, 3, 3, 2, 4, 0, 4, 4, 0, 0, 0, 3, 2, 0, 1, 12, 2, 0, 0, 0, 0, 202, 154, 59, 0, 0, 0, 0
  );

  Wallet := TWallet.Create(MnemonicWords);
  OwnerAccount := Wallet.GetAccountByIndex(10);
  NonceAccount := Wallet.GetAccountByIndex(1119);
  ToAccount    := Wallet.GetAccountByIndex(1);

  NonceInfo := TNonceInformation.Create(
    NonceStr,
    TSystemProgram.AdvanceNonceAccount(NonceAccount.PublicKey, OwnerAccount.PublicKey)
  );

  Builder := TTransactionBuilder.Create;
  TxBytes := Builder
    .SetFeePayer(OwnerAccount.PublicKey)
    .SetNonceInformation(NonceInfo)
    .AddInstruction(
      TSystemProgram.Transfer(OwnerAccount.PublicKey, ToAccount.PublicKey, 1000000000)
    )
    .CompileMessage;

  AssertEquals<Byte>(CompiledMessageBytes, TxBytes, 'compiled message mismatch');
end;

procedure TTransactionBuilderTests.TestTransactionInstructionTest;
var
  Wallet: IWallet;
  OwnerAccount: IAccount;
  MemoIx, Created: ITransactionInstruction;
  LPubKey: IPublicKey;
  LKeys: TList<IAccountMeta>;
  I: Integer;
begin
  Wallet := TWallet.Create(MnemonicWords);
  OwnerAccount := Wallet.GetAccountByIndex(10);
  MemoIx := TMemoProgram.NewMemo(OwnerAccount.PublicKey, 'Hello');
  LPubKey := TPublicKey.Create(MemoIx.ProgramId);

  LKeys := TList<IAccountMeta>.Create;
  LKeys.AddRange(MemoIx.Keys);

  Created := TTransactionInstructionFactory.Create(
    LPubKey,
    LKeys,
    MemoIx.Data
  );

  AssertEquals(
    TEncoders.Base64.EncodeData(MemoIx.ProgramId),
    TEncoders.Base64.EncodeData(Created.ProgramId),
    'ProgramId b64'
  );

  AssertEquals(MemoIx.Keys.Count, Created.Keys.Count, 'Keys count mismatch');
  for I := 0 to MemoIx.Keys.Count - 1 do
    AssertTrue(MemoIx.Keys[I] = Created.Keys[I], Format('Keys[%d] instance', [I]));

  AssertEquals(
    TEncoders.Base64.EncodeData(MemoIx.Data),
    TEncoders.Base64.EncodeData(Created.Data),
    'Data b64'
  );
end;

procedure TTransactionBuilderTests.TransactionBuilderAddSignatureTest;
var
  Wallet: IWallet;
  FromAccount, ToAccount: IAccount;
  Builder: ITransactionBuilder;
  MsgBytes, Sig, Tx: TBytes;
  Sig58, TxB64: string;
begin
  Wallet := TWallet.Create(MnemonicWords);
  FromAccount := Wallet.GetAccountByIndex(10);
  ToAccount   := Wallet.GetAccountByIndex(8);

  Builder := TTransactionBuilder.Create;
  Builder
    .SetRecentBlockHash(AddSignatureBlockHash)
    .SetFeePayer(FromAccount.PublicKey)
    .AddInstruction(TSystemProgram.Transfer(FromAccount.PublicKey, ToAccount.PublicKey, 10000000))
    .AddInstruction(TMemoProgram.NewMemo(FromAccount.PublicKey, 'Hello from SolLib :)'));

  MsgBytes := Builder.CompileMessage;
  Sig      := FromAccount.Sign(MsgBytes);

  Sig58 := TEncoders.Base58.EncodeData(Sig);
  AssertEquals(AddSignatureSignature, Sig58, 'base58 signature');

  Tx := Builder.AddSignature(Sig).Serialize;
  TxB64 := TEncoders.Base64.EncodeData(Tx);
  AssertEquals(AddSignatureTransaction, TxB64, 'serialized tx b64');
end;

procedure TTransactionBuilderTests.TestTransactionWithPriorityFeesInformation;
var
  Wallet: IWallet;
  FromAccount, ToAccount: IAccount;
  Builder: ITransactionBuilder;
  PriorityFeesInfo: IPriorityFeesInformation;
  TxBytes: TBytes;
  TxB64: string;
begin
  Wallet      := TWallet.Create(MnemonicWords);
  FromAccount := Wallet.GetAccountByIndex(10);
  ToAccount   := Wallet.GetAccountByIndex(1);

  // Prepare priority-fee instructions
  PriorityFeesInfo := TPriorityFeesInformation.Create(
    TComputeBudgetProgram.SetComputeUnitLimit(400000),   // SetComputeUnitLimit
    TComputeBudgetProgram.SetComputeUnitPrice(100000)    // SetComputeUnitPrice
  );

  Builder := TTransactionBuilder.Create;
  TxBytes := Builder
    .SetRecentBlockHash(Blockhash)
    .SetFeePayer(FromAccount.PublicKey)
    .AddInstruction(TSystemProgram.Transfer(FromAccount.PublicKey, ToAccount.PublicKey, 1000000))
    .SetPriorityFeesInformation(PriorityFeesInfo)
    .Build(FromAccount);

  TxB64 := TEncoders.Base64.EncodeData(TxBytes);
  AssertEquals(ExpectedTransactionWithPriorityFees, TxB64);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TTransactionBuilderTests);
{$ELSE}
  RegisterTest(TTransactionBuilderTests.Suite);
{$ENDIF}

end.

