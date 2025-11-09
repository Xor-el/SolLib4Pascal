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

unit Ed25519Bip32Tests;

interface

uses
  System.SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpEd25519Bip32,
  SolLibTestCase;

type
  TEd25519Bip32Tests = class(TSolLibTestCase)
  private
    function SeedWithoutPassphrase: TBytes;
  published
    procedure TestDerivePath_Invalid;
  end;

implementation

const
  DerivationPath        = 'm/44''/501''/0''/0''';
  InvalidDerivationPath = 'm44/''501''''//0''/0''';

{ TEd25519Bip32Tests }

function TEd25519Bip32Tests.SeedWithoutPassphrase: TBytes;
begin
  Result := TBytes.Create(
    124,36,217,106,151,19,165,102,96,101,74,81,
    237,254,232,133,28,167,31,35,119,188,66,40,
    101,104,25,103,139,83,57,7,19,215,6,113,22,
    145,107,209,208,107,159,40,223,19,82,53,136,
    255,40,171,137,93,9,205,28,7,207,88,194,91,
    219,232
  );
end;

procedure TEd25519Bip32Tests.TestDerivePath_Invalid;
begin
  AssertException(
    procedure
    var Ed: TEd25519Bip32;
    begin
      Ed := TEd25519Bip32.Create(SeedWithoutPassphrase);
      try
        Ed.DerivePath(InvalidDerivationPath);
      finally
        Ed.Free;
      end;
    end,
    Exception
  );
end;

initialization
{$IFDEF FPC}
  RegisterTest(TEd25519Bip32Tests);
{$ELSE}
  RegisterTest(TEd25519Bip32Tests.Suite);
{$ENDIF}

end.

