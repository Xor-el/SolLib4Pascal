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
  sut: TSecretKeyStoreService;
  json: string;
begin
  json := LoadTestData('InvalidKdfType.json');

  sut := TSecretKeyStoreService.Create;
  try
    AssertException(
      procedure
      begin
        sut.DecryptKeyStoreFromJson('randomPassword', json);
      end,
      EInvalidKdfException
    );
  finally
    sut.Free;
  end;
end;

initialization
{$IFDEF FPC}
  RegisterTest(TKeyStoreKdfCheckerTests);
{$ELSE}
  RegisterTest(TKeyStoreKdfCheckerTests.Suite);
{$ENDIF}

end.


