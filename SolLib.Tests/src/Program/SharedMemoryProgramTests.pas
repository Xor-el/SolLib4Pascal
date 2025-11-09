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
  Wallet: IWallet;
  Payload: TBytes;
  FromAccount: IAccount;
  ToAccount: IAccount;
  Tx: ITransactionInstruction;
  ExpectedData: TBytes;
  TotalLen: Integer;
begin
  // Arrange
  Wallet := TWallet.Create(MnemonicWords);
  Payload := TEncoding.UTF8.GetBytes('Hello World!');
  FromAccount := Wallet.GetAccountByIndex(0);
  ToAccount   := Wallet.GetAccountByIndex(1);

  // Act
  Tx := TSharedMemoryProgram.Write(ToAccount.PublicKey, Payload, 0);

  // Build expected buffer: 8 zero bytes (u64 offset=0) + payload
  TotalLen := 8 + Length(Payload);
  SetLength(ExpectedData, TotalLen);

  Move(Payload[0], ExpectedData[8], Length(Payload));

  AssertEquals<Byte>(ExpectedData, Tx.Data, 'Data');
  AssertEquals(1, Tx.Keys.Count, 'Keys.Count');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSharedMemoryProgramTests);
{$ELSE}
  RegisterTest(TSharedMemoryProgramTests.Suite);
{$ENDIF}

end.

