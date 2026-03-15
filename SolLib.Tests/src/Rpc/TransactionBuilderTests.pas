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
  LWallet: IWallet;
  LFromAccount: IAccount;
  LBuilder: ITransactionBuilder;
begin
  LWallet := TWallet.Create(MnemonicWords);
  LFromAccount := LWallet.GetAccountByIndex(0);

  LBuilder := TTransactionBuilder.Create;
  LBuilder.SetRecentBlockHash(Blockhash);

  AssertException(
    procedure
    begin
      LBuilder.Build(LFromAccount)
    end,
    Exception
  );
end;

procedure TTransactionBuilderTests.TestTransactionBuilderBuild;
var
  LWallet: IWallet;
  LFromAccount, LToAccount: IAccount;
  LBuilder: ITransactionBuilder;
  LTxBytes: TBytes;
  LB64: string;
begin
  LWallet := TWallet.Create(MnemonicWords);
  LFromAccount := LWallet.GetAccountByIndex(0);
  LToAccount := LWallet.GetAccountByIndex(1);

  LBuilder := TTransactionBuilder.Create;
  LTxBytes := LBuilder
    .SetRecentBlockHash(Blockhash)
    .SetFeePayer(LFromAccount.PublicKey)
    .AddInstruction(TSystemProgram.Transfer(LFromAccount.PublicKey, LToAccount.PublicKey, 10000000))
    .AddInstruction(TMemoProgram.NewMemo(LFromAccount.PublicKey, 'Hello from SolLib :)'))
    .Build(LFromAccount);

  LB64 := EncodeBase64(LTxBytes);
  AssertEquals(ExpectedTransactionHashWithTransferAndMemo, LB64);
end;

procedure TTransactionBuilderTests.TestTransactionBuilderBuildNullBlockhashException;
var
  LWallet: IWallet;
  LFromAccount, LToAccount: IAccount;
  LBuilder: ITransactionBuilder;
begin
  LWallet := TWallet.Create(MnemonicWords);
  LFromAccount := LWallet.GetAccountByIndex(0);
  LToAccount := LWallet.GetAccountByIndex(1);

  LBuilder := TTransactionBuilder.Create;
  LBuilder
    .SetFeePayer(LFromAccount.PublicKey)
    .AddInstruction(TSystemProgram.Transfer(LFromAccount.PublicKey, LToAccount.PublicKey, 10000000))
    .AddInstruction(TMemoProgram.NewMemo(LFromAccount.PublicKey, 'Hello from SolLib :)'));

  AssertException(
    procedure
    begin
      LBuilder.Build(LFromAccount)
    end,
    Exception
  );
end;

procedure TTransactionBuilderTests.TestTransactionBuilderBuildNullFeePayerException;
var
  LWallet: IWallet;
  LFromAccount, LToAccount: IAccount;
  LBuilder: ITransactionBuilder;
begin
  LWallet := TWallet.Create(MnemonicWords);
  LFromAccount := LWallet.GetAccountByIndex(0);
  LToAccount := LWallet.GetAccountByIndex(1);

  LBuilder := TTransactionBuilder.Create;
  LBuilder
    .SetRecentBlockHash(Blockhash)
    .AddInstruction(TSystemProgram.Transfer(LFromAccount.PublicKey, LToAccount.PublicKey, 10000000))
    .AddInstruction(TMemoProgram.NewMemo(LFromAccount.PublicKey, 'Hello from SolLib :)'));

  AssertException(
    procedure
    begin
      LBuilder.Build(LFromAccount)
    end,
    Exception
  );
end;

procedure TTransactionBuilderTests.TestTransactionBuilderBuildEmptySignersException;
var
  LWallet: IWallet;
  LFromAccount, LToAccount: IAccount;
  LBuilder: ITransactionBuilder;
  LEmptySigners: TList<IAccount>;
begin
  LWallet := TWallet.Create(MnemonicWords);
  LFromAccount := LWallet.GetAccountByIndex(0);
  LToAccount := LWallet.GetAccountByIndex(1);

  LEmptySigners := TList<IAccount>.Create;
  try
    LBuilder := TTransactionBuilder.Create;
    LBuilder
      .SetRecentBlockHash(Blockhash)
      .AddInstruction(TSystemProgram.Transfer(LFromAccount.PublicKey, LToAccount.PublicKey, 10000000))
      .AddInstruction(TMemoProgram.NewMemo(LFromAccount.PublicKey, 'Hello from SolLib :)'));

    AssertException(
      procedure
      begin
        LBuilder.Build(LEmptySigners)
      end,
      Exception
    );
  finally
    LEmptySigners.Free;
  end;
end;

procedure TTransactionBuilderTests.CreateInitializeAndMintToTest;
var
  LWallet: IWallet;
  LBlockHash, LB64: string;
  LMinBalanceForAccount, LMinBalanceForMint: UInt64;
  LMintAccount, LOwnerAccount, LInitialAccount: IAccount;
  LBuilder: ITransactionBuilder;
  LSigners: TList<IAccount>;
  LTx: TBytes;
  LTx2: ITransaction;
  LMsg: TBytes;
  LOk: Boolean;
begin
  LWallet := TWallet.Create(MnemonicWords);
  LBlockHash := 'G9JC6E7LfG6ayxARq5zDV5RdDr6P8NJEdzTUJ8ttrSKs';
  LMinBalanceForAccount := 2039280;
  LMinBalanceForMint := 1461600;

  LMintAccount := LWallet.GetAccountByIndex(17);
  LOwnerAccount := LWallet.GetAccountByIndex(10);
  LInitialAccount := LWallet.GetAccountByIndex(18);

  LBuilder := TTransactionBuilder.Create;
  LBuilder
    .SetRecentBlockHash(LBlockHash)
    .SetFeePayer(LOwnerAccount.PublicKey)
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwnerAccount.PublicKey, LMintAccount.PublicKey, LMinBalanceForMint,
        TTokenProgram.MintAccountDataSize, TTokenProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TTokenProgram.InitializeMint(
        LMintAccount.PublicKey, 2, LOwnerAccount.PublicKey, LOwnerAccount.PublicKey
      )
    )
    .AddInstruction(
      TSystemProgram.CreateAccount(
        LOwnerAccount.PublicKey, LInitialAccount.PublicKey, LMinBalanceForAccount,
        TTokenProgram.TokenAccountDataSize, TTokenProgram.ProgramIdKey
      )
    )
    .AddInstruction(
      TTokenProgram.InitializeAccount(
        LInitialAccount.PublicKey, LMintAccount.PublicKey, LOwnerAccount.PublicKey
      )
    )
    .AddInstruction(
      TTokenProgram.MintTo(
        LMintAccount.PublicKey, LInitialAccount.PublicKey, 25000, LOwnerAccount.PublicKey
      )
    )
    .AddInstruction(TMemoProgram.NewMemo(LInitialAccount.PublicKey, 'Hello from SolLib'));

  LSigners := TList<IAccount>.Create;
  try
    LSigners.AddRange([LOwnerAccount, LMintAccount, LInitialAccount]);
    LTx := LBuilder.Build(LSigners);
  finally
    LSigners.Free;
  end;

  LTx2 := TTransaction.Deserialize(LTx);
  LMsg := LTx2.CompileMessage;
  LOk := LTx2.Signatures[0].PublicKey.Verify(LMsg, LTx2.Signatures[0].Signature);
  AssertTrue(LOk, 'Signature[0] should verify');

  LB64 := EncodeBase64(LTx);
  AssertEquals(ExpectedTransactionHashCreateInitializeAndMintTo, LB64);
end;

procedure TTransactionBuilderTests.CompileMessageTest;
var
  LWallet: IWallet;
  LOwnerAccount, LNonceAccount, LToAccount: IAccount;
  LNonceInfo: INonceInformation;
  LBuilder: ITransactionBuilder;
  LCompiledMessageBytes, LTxBytes: TBytes;
begin
  LCompiledMessageBytes := TBytes.Create(
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

  LWallet := TWallet.Create(MnemonicWords);
  LOwnerAccount := LWallet.GetAccountByIndex(10);
  LNonceAccount := LWallet.GetAccountByIndex(1119);
  LToAccount := LWallet.GetAccountByIndex(1);

  LNonceInfo := TNonceInformation.Create(
    NonceStr,
    TSystemProgram.AdvanceNonceAccount(LNonceAccount.PublicKey, LOwnerAccount.PublicKey)
  );

  LBuilder := TTransactionBuilder.Create;
  LTxBytes := LBuilder
    .SetFeePayer(LOwnerAccount.PublicKey)
    .SetNonceInformation(LNonceInfo)
    .AddInstruction(
      TSystemProgram.Transfer(LOwnerAccount.PublicKey, LToAccount.PublicKey, 1000000000)
    )
    .CompileMessage;

  AssertEquals(LCompiledMessageBytes, LTxBytes, 'compiled message mismatch');
end;

procedure TTransactionBuilderTests.TestTransactionInstructionTest;
var
  LWallet: IWallet;
  LOwnerAccount: IAccount;
  LMemoIx, LCreated: ITransactionInstruction;
  LPubKey: IPublicKey;
  LKeys: TList<IAccountMeta>;
  LI: Integer;
begin
  LWallet := TWallet.Create(MnemonicWords);
  LOwnerAccount := LWallet.GetAccountByIndex(10);
  LMemoIx := TMemoProgram.NewMemo(LOwnerAccount.PublicKey, 'Hello');
  LPubKey := TPublicKey.Create(LMemoIx.ProgramId);

  LKeys := TList<IAccountMeta>.Create;
  LKeys.AddRange(LMemoIx.Keys);

  LCreated := TTransactionInstructionFactory.Create(
    LPubKey,
    LKeys,
    LMemoIx.Data
  );

  AssertEquals(
    EncodeBase64(LMemoIx.ProgramId),
    EncodeBase64(LCreated.ProgramId),
    'ProgramId b64'
  );

  AssertEquals(LMemoIx.Keys.Count, LCreated.Keys.Count, 'Keys count mismatch');
  for LI := 0 to LMemoIx.Keys.Count - 1 do
    AssertTrue(LMemoIx.Keys[LI] = LCreated.Keys[LI], Format('Keys[%d] instance', [LI]));

  AssertEquals(
    EncodeBase64(LMemoIx.Data),
    EncodeBase64(LCreated.Data),
    'Data b64'
  );
end;

procedure TTransactionBuilderTests.TransactionBuilderAddSignatureTest;
var
  LWallet: IWallet;
  LFromAccount, LToAccount: IAccount;
  LBuilder: ITransactionBuilder;
  LMsgBytes, LSig, LTx: TBytes;
  LSig58, LTxB64: string;
begin
  LWallet := TWallet.Create(MnemonicWords);
  LFromAccount := LWallet.GetAccountByIndex(10);
  LToAccount := LWallet.GetAccountByIndex(8);

  LBuilder := TTransactionBuilder.Create;
  LBuilder
    .SetRecentBlockHash(AddSignatureBlockHash)
    .SetFeePayer(LFromAccount.PublicKey)
    .AddInstruction(TSystemProgram.Transfer(LFromAccount.PublicKey, LToAccount.PublicKey, 10000000))
    .AddInstruction(TMemoProgram.NewMemo(LFromAccount.PublicKey, 'Hello from SolLib :)'));

  LMsgBytes := LBuilder.CompileMessage;
  LSig := LFromAccount.Sign(LMsgBytes);

  LSig58 := EncodeBase58(LSig);
  AssertEquals(AddSignatureSignature, LSig58, 'base58 signature');

  LTx := LBuilder.AddSignature(LSig).Serialize;
  LTxB64 := EncodeBase64(LTx);
  AssertEquals(AddSignatureTransaction, LTxB64, 'serialized tx b64');
end;

procedure TTransactionBuilderTests.TestTransactionWithPriorityFeesInformation;
var
  LWallet: IWallet;
  LFromAccount, LToAccount: IAccount;
  LBuilder: ITransactionBuilder;
  LPriorityFeesInfo: IPriorityFeesInformation;
  LTxBytes: TBytes;
  LTxB64: string;
begin
  LWallet := TWallet.Create(MnemonicWords);
  LFromAccount := LWallet.GetAccountByIndex(10);
  LToAccount := LWallet.GetAccountByIndex(1);

  // Prepare priority-fee instructions
  LPriorityFeesInfo := TPriorityFeesInformation.Create(
    TComputeBudgetProgram.SetComputeUnitLimit(400000),   // SetComputeUnitLimit
    TComputeBudgetProgram.SetComputeUnitPrice(100000)    // SetComputeUnitPrice
  );

  LBuilder := TTransactionBuilder.Create;
  LTxBytes := LBuilder
    .SetRecentBlockHash(Blockhash)
    .SetFeePayer(LFromAccount.PublicKey)
    .AddInstruction(TSystemProgram.Transfer(LFromAccount.PublicKey, LToAccount.PublicKey, 1000000))
    .SetPriorityFeesInformation(LPriorityFeesInfo)
    .Build(LFromAccount);

  LTxB64 := EncodeBase64(LTxBytes);
  AssertEquals(ExpectedTransactionWithPriorityFees, LTxB64);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TTransactionBuilderTests);
{$ELSE}
  RegisterTest(TTransactionBuilderTests.Suite);
{$ENDIF}

end.

