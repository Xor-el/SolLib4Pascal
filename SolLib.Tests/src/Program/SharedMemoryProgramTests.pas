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

unit SharedMemoryProgramTests;

interface

uses
  System.SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpAccount,
  SlpWallet,
  SlpTransactionInstruction,
  SlpSharedMemoryProgram,
  SolLibProgramTestCase;

type
  TSharedMemoryProgramTests = class(TSolLibProgramTestCase)
  published
    procedure TestWriteEncoding;
  end;

implementation

procedure TSharedMemoryProgramTests.TestWriteEncoding;
const
  MnemonicWords =
    'route clerk disease box emerge airport loud waste attitude film army tray ' +
    'forward deal onion eight catalog surface unit card window walnut wealth medal';
var
  LWallet: IWallet;
  LPayload: TBytes;
  LFromAccount: IAccount;
  LToAccount: IAccount;
  LTx: ITransactionInstruction;
  LExpectedData: TBytes;
  LTotalLen: Integer;
begin
  // Arrange
  LWallet := TWallet.Create(MnemonicWords);
  LPayload := TEncoding.UTF8.GetBytes('Hello World!');
  LFromAccount := LWallet.GetAccountByIndex(0);
  LToAccount   := LWallet.GetAccountByIndex(1);

  // Act
  LTx := TSharedMemoryProgram.Write(LToAccount.PublicKey, LPayload, 0);

  // Build expected buffer: 8 zero bytes (u64 offset=0) + payload
  LTotalLen := 8 + Length(LPayload);
  SetLength(LExpectedData, LTotalLen);

  Move(LPayload[0], LExpectedData[8], Length(LPayload));

  AssertEquals(LExpectedData, LTx.Data, 'Data');
  AssertEquals(1, LTx.Keys.Count, 'Keys.Count');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSharedMemoryProgramTests);
{$ELSE}
  RegisterTest(TSharedMemoryProgramTests.Suite);
{$ENDIF}

end.

