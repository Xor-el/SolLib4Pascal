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

unit SystemProgramTests;

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
  SlpAccount,
  SlpPublicKey,
  SlpNonceAccount,
  SlpTransactionInstruction,
  SlpTokenProgram,
  SlpSystemProgram,
  SolLibProgramTestCase;

type
  TSystemProgramTests = class(TSolLibProgramTestCase)
  private
   const
     BalanceForRentExemption = 2039280;
     MnemonicWords =
      'route clerk disease box emerge airport loud waste attitude film army tray ' +
      'forward deal onion eight catalog surface unit card window walnut wealth medal';

     NonceAccountBase64Data =
      'AAAAAAEAAABHaauXIEuoP7DK7hf3ho8eB05SFYGg2J2UN52qZbc' +
      'XsnM+zs3rCNyHGAjze1Gvfq4gRzzrz7ggv4rYXkMo8P2DiBMAAAAAAAA=';

     NonceAccountInvalidBase64Data =
      '77+977+977+977+9Ae+/ve+/ve+/vUdpwqvClyBLwqg/wrDDisOuF8O3wob' +
      'Cjx4HTlJSFcKBIMOYwp3ClDfCncKqZcK3F8Kycz7DjsONw6sIw5zChxgIw7N' +
      '7UcKvfsKuIEc8w6vDj8K4IMK/worDmF5DKMOww73Cg8KIE++/ve+/ve+/ve+/ve+/ve+/vQ==';

    class function SystemProgramIdBytes: TBytes; static;

    class function CreateAccountInstructionBytes: TBytes; static;
    class function TransferInstructionBytes: TBytes; static;
    class function AssignInstructionBytes: TBytes; static;
    class function CreateAccountWithSeedInstructionBytes: TBytes; static;
    class function AdvanceNonceAccountInstructionBytes: TBytes; static;
    class function WithdrawNonceAccountInstructionBytes: TBytes; static;
    class function InitializeNonceAccountInstructionBytes: TBytes; static;
    class function AuthorizeNonceAccountInstructionBytes: TBytes; static;
    class function AllocateInstructionBytes: TBytes; static;
    class function AllocateWithSeedInstructionBytes: TBytes; static;
    class function AssignWithSeedInstructionBytes: TBytes; static;
    class function TransferWithSeedInstructionBytes: TBytes; static;

  published
    procedure TestSystemProgramTransfer;
    procedure TestSystemProgramCreateAccount;
    procedure TestSystemProgramAssign;
    procedure TestSystemProgramCreateAccountWithSeed;
    procedure TestSystemProgramAdvanceNonceAccount;
    procedure TestSystemProgramWithdrawNonceAccount;
    procedure TestSystemProgramInitializeNonceAccount;
    procedure TestSystemProgramAuthorizeNonceAccount;
    procedure TestSystemProgramAllocate;
    procedure TestSystemProgramAllocateWithSeed;
    procedure TestSystemProgramAssignWithSeed;
    procedure TestSystemProgramTransferWithSeed;

    procedure TestNonceAccountDeserializationException;
    procedure TestNonceAccountDeserialization;
  end;

implementation

{ TSystemProgramTests }

class function TSystemProgramTests.SystemProgramIdBytes: TBytes;
begin
  Result := TBytes.Create(
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  );
end;

class function TSystemProgramTests.CreateAccountInstructionBytes: TBytes;
begin
  Result := TBytes.Create(
    0,0,0,0, 240,29,31,0,0,0,0,0, 165,0,0,0,0,0,0,0,
    6,221,246,225,215,101,161,147,217,203,225,70,206,235,121,172,
    28,180,133,237,95,91,55,145,58,140,245,133,126,255,0,169
  );
end;

class function TSystemProgramTests.TransferInstructionBytes: TBytes;
begin
  Result := TBytes.Create(
    2,0,0,0, 128,150,152,0,0,0,0,0
  );
end;

class function TSystemProgramTests.AssignInstructionBytes: TBytes;
begin
  Result := TBytes.Create(
    1,0,0,0,
    189,31,212,204,51,65,12,40,137,113,214,99,175,9,119,28,
    19,10,56,240,87,136,148,225,227,13,181,127,113,230,10,186
  );
end;

class function TSystemProgramTests.CreateAccountWithSeedInstructionBytes: TBytes;
begin
  Result := TBytes.Create(
    3,0,0,0,
    244,171,249,196,62,132,245,193,114,19,34,7,37,207,38,98,
    69,136,106,149,175,110,143,211,108,198,5,239,231,182,7,20,
    8,0,0,0, 0,0,0,0,
    116,101,115,116,83,101,101,100,
    64,66,15,0,0,0,0,0,
    232,3,0,0,0,0,0,0,
    4,23,154,206,58,166,9,125,107,80,224,57,235,71,51,46,
    27,153,48,39,162,54,144,176,6,128,214,189,53,152,48,38
  );
end;

class function TSystemProgramTests.AdvanceNonceAccountInstructionBytes: TBytes;
begin
  Result := TBytes.Create(4,0,0,0);
end;

class function TSystemProgramTests.WithdrawNonceAccountInstructionBytes: TBytes;
begin
  Result := TBytes.Create(
    5,0,0,0, 64,66,15,0,0,0,0,0
  );
end;

class function TSystemProgramTests.InitializeNonceAccountInstructionBytes: TBytes;
begin
  Result := TBytes.Create(
    6,0,0,0,
    4,23,154,206,58,166,9,125,107,80,224,57,235,71,51,46,
    27,153,48,39,162,54,144,176,6,128,214,189,53,152,48,38
  );
end;

class function TSystemProgramTests.AuthorizeNonceAccountInstructionBytes: TBytes;
begin
  Result := TBytes.Create(
    7,0,0,0,
    4,23,154,206,58,166,9,125,107,80,224,57,235,71,51,46,
    27,153,48,39,162,54,144,176,6,128,214,189,53,152,48,38
  );
end;

class function TSystemProgramTests.AllocateInstructionBytes: TBytes;
begin
  Result := TBytes.Create(
    8,0,0,0, 64,66,15,0,0,0,0,0
  );
end;

class function TSystemProgramTests.AllocateWithSeedInstructionBytes: TBytes;
begin
  Result := TBytes.Create(
    9,0,0,0,
    244,171,249,196,62,132,245,193,114,19,34,7,37,207,38,98,
    69,136,106,149,175,110,143,211,108,198,5,239,231,182,7,20,
    8,0,0,0, 0,0,0,0,
    116,101,115,116,83,101,101,100,
    232,3,0,0,0,0,0,0,
    4,23,154,206,58,166,9,125,107,80,224,57,235,71,51,46,
    27,153,48,39,162,54,144,176,6,128,214,189,53,152,48,38
  );
end;

class function TSystemProgramTests.AssignWithSeedInstructionBytes: TBytes;
begin
  Result := TBytes.Create(
    10,0,0,0,
    244,171,249,196,62,132,245,193,114,19,34,7,37,207,38,98,
    69,136,106,149,175,110,143,211,108,198,5,239,231,182,7,20,
    8,0,0,0,0,0,0,0,
    116,101,115,116,83,101,101,100,
    4,23,154,206,58,166,9,125,107,80,224,57,235,71,51,46,
    27,153,48,39,162,54,144,176,6,128,214,189,53,152,48,38
  );
end;

class function TSystemProgramTests.TransferWithSeedInstructionBytes: TBytes;
begin
  Result := TBytes.Create(
    11,0,0,0,
    64,66,15,0,0,0,0,0,
    8,0,0,0,0,0,0,0,
    116,101,115,116,83,101,101,100,
    4,23,154,206,58,166,9,125,107,80,224,57,235,71,51,46,
    27,153,48,39,162,54,144,176,6,128,214,189,53,152,48,38
  );
end;

procedure TSystemProgramTests.TestSystemProgramTransfer;
var
  LWallet: IWallet;
  LFromAccount, LToAccount: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet      := TWallet.Create(MnemonicWords);
  LFromAccount := LWallet.GetAccountByIndex(0);
  LToAccount   := LWallet.GetAccountByIndex(1);

  LTx := TSystemProgram.Transfer(LFromAccount.PublicKey, LToAccount.PublicKey, 10000000);

  AssertEquals(2, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(TransferInstructionBytes, LTx.Data, 'Data');
  AssertEquals(SystemProgramIdBytes,    LTx.ProgramId, 'ProgramId');
end;

procedure TSystemProgramTests.TestSystemProgramCreateAccount;
var
  LWallet: IWallet;
  LMintAccount, LOwnerAccount: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet       := TWallet.Create(MnemonicWords);
  LMintAccount  := LWallet.GetAccountByIndex(3);
  LOwnerAccount := LWallet.GetAccountByIndex(4);

  LTx := TSystemProgram.CreateAccount(
          LOwnerAccount.PublicKey,
          LMintAccount.PublicKey,
          BalanceForRentExemption,
          TTokenProgram.TokenAccountDataSize,
          TTokenProgram.ProgramIdKey
       );

  AssertEquals(2, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(CreateAccountInstructionBytes, LTx.Data, 'Data');
  AssertEquals(SystemProgramIdBytes,         LTx.ProgramId, 'ProgramId');
end;

procedure TSystemProgramTests.TestSystemProgramAssign;
var
  LWallet: IWallet;
  LAccount, LNewOwner: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet   := TWallet.Create(MnemonicWords);
  LAccount  := LWallet.GetAccountByIndex(4);
  LNewOwner := LWallet.GetAccountByIndex(5);

  LTx := TSystemProgram.Assign(LAccount.PublicKey, LNewOwner.PublicKey);

  AssertEquals(1, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(AssignInstructionBytes, LTx.Data, 'Data');
  AssertEquals(SystemProgramIdBytes,   LTx.ProgramId, 'ProgramId');
end;

procedure TSystemProgramTests.TestSystemProgramCreateAccountWithSeed;
var
  LWallet: IWallet;
  LBaseAccount, LFrom, LToAcc, LOwner: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet      := TWallet.Create(MnemonicWords);
  LBaseAccount := LWallet.GetAccountByIndex(6);
  LFrom        := LWallet.GetAccountByIndex(5);
  LToAcc       := LWallet.GetAccountByIndex(4);
  LOwner       := LWallet.GetAccountByIndex(3);

  LTx := TSystemProgram.CreateAccountWithSeed(
          LFrom.PublicKey,
          LToAcc.PublicKey,
          LBaseAccount.PublicKey,
          'testSeed',
          1000000,
          1000,
          LOwner.PublicKey
       );

  AssertEquals(3, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(CreateAccountWithSeedInstructionBytes, LTx.Data, 'Data');
  AssertEquals(SystemProgramIdBytes,                  LTx.ProgramId, 'ProgramId');
end;

procedure TSystemProgramTests.TestSystemProgramAdvanceNonceAccount;
var
  LWallet: IWallet;
  LNonceAcc, LOwner: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet   := TWallet.Create(MnemonicWords);
  LNonceAcc := LWallet.GetAccountByIndex(69);
  LOwner    := LWallet.GetAccountByIndex(3);

  LTx := TSystemProgram.AdvanceNonceAccount(LNonceAcc.PublicKey, LOwner.PublicKey);

  AssertEquals(3, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(AdvanceNonceAccountInstructionBytes, LTx.Data, 'Data');
  AssertEquals(SystemProgramIdBytes,                LTx.ProgramId, 'ProgramId');
end;

procedure TSystemProgramTests.TestSystemProgramWithdrawNonceAccount;
var
  LWallet: IWallet;
  LNonceAcc, LToAcc, LOwner: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet   := TWallet.Create(MnemonicWords);
  LNonceAcc := LWallet.GetAccountByIndex(69);
  LToAcc    := LWallet.GetAccountByIndex(5);
  LOwner    := LWallet.GetAccountByIndex(3);

  LTx := TSystemProgram.WithdrawNonceAccount(
          LNonceAcc.PublicKey,
          LToAcc.PublicKey,
          LOwner.PublicKey,
          1000000
       );

  AssertEquals(5, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(WithdrawNonceAccountInstructionBytes, LTx.Data, 'Data');
  AssertEquals(SystemProgramIdBytes,                 LTx.ProgramId, 'ProgramId');
end;

procedure TSystemProgramTests.TestSystemProgramInitializeNonceAccount;
var
  LWallet: IWallet;
  LNonceAcc, LOwner: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet   := TWallet.Create(MnemonicWords);
  LNonceAcc := LWallet.GetAccountByIndex(69);
  LOwner    := LWallet.GetAccountByIndex(3);

  LTx := TSystemProgram.InitializeNonceAccount(LNonceAcc.PublicKey, LOwner.PublicKey);

  AssertEquals(3, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(InitializeNonceAccountInstructionBytes, LTx.Data, 'Data');
  AssertEquals(SystemProgramIdBytes,                   LTx.ProgramId, 'ProgramId');
end;

procedure TSystemProgramTests.TestSystemProgramAuthorizeNonceAccount;
var
  LWallet: IWallet;
  LNonceAcc, LOwner, LNewAuthority: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet       := TWallet.Create(MnemonicWords);
  LNonceAcc     := LWallet.GetAccountByIndex(69);
  LOwner        := LWallet.GetAccountByIndex(4);
  LNewAuthority := LWallet.GetAccountByIndex(3);

  LTx := TSystemProgram.AuthorizeNonceAccount(
          LNonceAcc.PublicKey,
          LOwner.PublicKey,
          LNewAuthority.PublicKey
       );

  AssertEquals(2, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(AuthorizeNonceAccountInstructionBytes, LTx.Data, 'Data');
  AssertEquals(SystemProgramIdBytes,                  LTx.ProgramId, 'ProgramId');
end;

procedure TSystemProgramTests.TestSystemProgramAllocate;
var
  LWallet: IWallet;
  LNonceAcc: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet   := TWallet.Create(MnemonicWords);
  LNonceAcc := LWallet.GetAccountByIndex(69);

  LTx := TSystemProgram.Allocate(LNonceAcc.PublicKey, 1000000);

  AssertEquals(1, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(AllocateInstructionBytes, LTx.Data, 'Data');
  AssertEquals(SystemProgramIdBytes,     LTx.ProgramId, 'ProgramId');
end;

procedure TSystemProgramTests.TestSystemProgramAllocateWithSeed;
var
  LWallet: IWallet;
  LBaseAccount, LAccount, LOwner: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet      := TWallet.Create(MnemonicWords);
  LBaseAccount := LWallet.GetAccountByIndex(6);
  LAccount     := LWallet.GetAccountByIndex(5);
  LOwner       := LWallet.GetAccountByIndex(3);

  LTx := TSystemProgram.AllocateWithSeed(
          LAccount.PublicKey,
          LBaseAccount.PublicKey,
          'testSeed',
          1000,
          LOwner.PublicKey
       );

  AssertEquals(2, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(AllocateWithSeedInstructionBytes, LTx.Data, 'Data');
  AssertEquals(SystemProgramIdBytes,             LTx.ProgramId, 'ProgramId');
end;

procedure TSystemProgramTests.TestSystemProgramAssignWithSeed;
var
  LWallet: IWallet;
  LBaseAccount, LAccount, LOwner: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet      := TWallet.Create(MnemonicWords);
  LBaseAccount := LWallet.GetAccountByIndex(6);
  LAccount     := LWallet.GetAccountByIndex(5);
  LOwner       := LWallet.GetAccountByIndex(3);

  LTx := TSystemProgram.AssignWithSeed(
          LAccount.PublicKey,
          LBaseAccount.PublicKey,
          'testSeed',
          LOwner.PublicKey
       );

  AssertEquals(2, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(AssignWithSeedInstructionBytes, LTx.Data, 'Data');
  AssertEquals(SystemProgramIdBytes,           LTx.ProgramId, 'ProgramId');
end;

procedure TSystemProgramTests.TestSystemProgramTransferWithSeed;
var
  LWallet: IWallet;
  LBaseAccount, LFromAcc, LToAcc, LOwner : IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet      := TWallet.Create(MnemonicWords);
  LBaseAccount := LWallet.GetAccountByIndex(6);
  LFromAcc     := LWallet.GetAccountByIndex(5);
  LToAcc       := LWallet.GetAccountByIndex(4);
  LOwner       := LWallet.GetAccountByIndex(3);

  LTx := TSystemProgram.TransferWithSeed(
          LFromAcc.PublicKey,
          LBaseAccount.PublicKey,
          'testSeed',
          LOwner.PublicKey,
          LToAcc.PublicKey,
          1000000
       );

  AssertEquals(3, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(TransferWithSeedInstructionBytes, LTx.Data, 'Data');
  AssertEquals(SystemProgramIdBytes,             LTx.ProgramId, 'ProgramId');
end;

procedure TSystemProgramTests.TestNonceAccountDeserializationException;
begin
  AssertException(
    procedure
    begin
      TNonceAccount.Deserialize(TEncoders.Base64.DecodeData(NonceAccountInvalidBase64Data));
    end,
    EArgumentException
  );
end;

procedure TSystemProgramTests.TestNonceAccountDeserialization;
var
  LAcc: INonceAccount;
begin
  LAcc := TNonceAccount.Deserialize(TEncoders.Base64.DecodeData(NonceAccountBase64Data));

  AssertEquals(0, LAcc.Version, 'Version');
  AssertEquals(1, LAcc.State,   'State');

  AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LAcc.Authorized.Key, 'Authorized');
  AssertEquals('8ksS6xXd7vzNrpZfBTf9gJ87Bma5AjnQ9baEcT7xH5QE', LAcc.Nonce.Key,       'Nonce');
  AssertEquals(5000, LAcc.FeeCalculator.LamportsPerSignature, 'LamportsPerSignature');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSystemProgramTests);
{$ELSE}
  RegisterTest(TSystemProgramTests.Suite);
{$ENDIF}

end.

