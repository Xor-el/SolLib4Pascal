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

unit KeyStoreKdfCheckerTests;

interface

uses
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpSecretKeyStoreService,
  SlpSolLibExceptions,
  SolLibKeyStoreTestCase;

type
  TKeyStoreKdfCheckerTests = class(TSolLibKeyStoreTestCase)
  published
    procedure TestInvalidKdf;
  end;

implementation

{ TKeyStoreKdfCheckerTests }

procedure TKeyStoreKdfCheckerTests.TestInvalidKdf;
var
  LSut: TSecretKeyStoreService;
  LJson: string;
begin
  LJson := LoadTestData('InvalidKdfType.json');

  LSut := TSecretKeyStoreService.Create;
  try
    AssertException(
      procedure
      begin
        LSut.DecryptKeyStoreFromJson('randomPassword', LJson);
      end,
      EInvalidKdfException
    );
  finally
    LSut.Free;
  end;
end;

initialization
{$IFDEF FPC}
  RegisterTest(TKeyStoreKdfCheckerTests);
{$ELSE}
  RegisterTest(TKeyStoreKdfCheckerTests.Suite);
{$ENDIF}

end.


