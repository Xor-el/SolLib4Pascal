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

unit AssociatedTokenAccountProgramTests;

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
  SlpAccount,
  SlpPublicKey,
  SlpTransactionInstruction,
  SlpAssociatedTokenAccountProgram,
  SolLibProgramTestCase;

type
  TAssociatedTokenAccountProgramTests = class(TSolLibProgramTestCase)
  private

    class function ProgramIdBytes: TBytes; static;
    class function EmptyBytes: TBytes; static;
  published
    procedure TestCreateAssociatedTokenAccount;
  end;

implementation

{ TAssociatedTokenAccountProgramTests }

class function TAssociatedTokenAccountProgramTests.ProgramIdBytes: TBytes;
begin
  Result := TBytes.Create(
    140, 151, 37, 143, 78, 36, 137, 241, 187, 61, 16, 41, 20,
    142, 13, 131, 11, 90, 19, 153, 218, 255, 16, 132, 4, 142, 123,
    216, 219, 233, 248, 89
  );
end;

class function TAssociatedTokenAccountProgramTests.EmptyBytes: TBytes;
begin
  Result := TBytes.Create();
end;

procedure TAssociatedTokenAccountProgramTests.TestCreateAssociatedTokenAccount;
const
  MnemonicWords =
    'route clerk disease box emerge airport loud waste attitude film army tray ' +
    'forward deal onion eight catalog surface unit card window walnut wealth medal';
var
  LWallet       : IWallet;
  LOwnerAccount : IAccount;
  LMintAccount  : IAccount;
  LInstr        : ITransactionInstruction;
begin
  LWallet := TWallet.Create(MnemonicWords);

  LOwnerAccount := LWallet.GetAccountByIndex(10);
  LMintAccount  := LWallet.GetAccountByIndex(21);

  LInstr := TAssociatedTokenAccountProgram.CreateAssociatedTokenAccount(
              LOwnerAccount.PublicKey,
              LOwnerAccount.PublicKey,
              LMintAccount.PublicKey
            );

  AssertEquals(7, LInstr.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(ProgramIdBytes, LInstr.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(EmptyBytes, LInstr.Data, 'Data should be empty array');
end;


initialization
{$IFDEF FPC}
  RegisterTest(TAssociatedTokenAccountProgramTests);
{$ELSE}
  RegisterTest(TAssociatedTokenAccountProgramTests.Suite);
{$ENDIF}

end.

