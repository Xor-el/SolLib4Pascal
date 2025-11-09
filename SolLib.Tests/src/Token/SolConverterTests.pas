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

unit SolConverterTests;

interface

uses
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpSolConverter,
  SolLibTokenTestCase;

type
  TSolConverterTests = class(TSolLibTokenTestCase)
  published
    procedure TestSolConverter_RoundTrip;
  end;

implementation

{ TSolConverterTests }
procedure TSolConverterTests.TestSolConverter_RoundTrip;
begin
  AssertEquals(168855000000, TSolConverter.ConvertToLamports(168.855), 'ConvertToLamports');
  AssertEquals(168.855, TSolConverter.ConvertToSol(168855000000), DoubleCompareDelta, 'ConvertToSol (round-trip)');
  AssertEquals(168.855000000, TSolConverter.ConvertToSol(168855000000), DoubleCompareDelta, 'ConvertToSol');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolConverterTests);
{$ELSE}
  RegisterTest(TSolConverterTests.Suite);
{$ENDIF}

end.

