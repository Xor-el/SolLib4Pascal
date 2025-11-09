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

unit SolanaRpcRateLimitingTests;

interface

uses
  System.SysUtils,
  System.Diagnostics,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpRateLimiter,
  SolLibTestCase;

type
  TSolanaRpcRateLimitingTests = class(TSolLibTestCase)
  published
    procedure TestMaxSpeed_NoLimits;
    procedure TestMaxSpeed_WithinLimits;
    procedure TestTwoHitsPerSecond;
  end;

implementation

{ TSolanaRpcRateLimitingTests }

procedure TSolanaRpcRateLimitingTests.TestMaxSpeed_NoLimits;
var
  L: IRateLimiter;
  I: Integer;
begin
  // Default: no limits -> all fires should pass immediately
  L := TRateLimiter.CreateDefault;
  AssertTrue(L.CanFire, 'CanFire should be True initially');
  for I := 1 to 7 do
    L.WaitFire;
end;

procedure TSolanaRpcRateLimitingTests.TestMaxSpeed_WithinLimits;
var
  L: IRateLimiter;
  I: Integer;
begin
  // High ceiling: effectively unthrottled for a handful of calls
  L := TRateLimiter.CreateDefault.AllowHits(100).PerSeconds(10);
  AssertTrue(L.CanFire, 'CanFire should be True initially');
  for I := 1 to 9 do
    L.WaitFire;
end;

procedure TSolanaRpcRateLimitingTests.TestTwoHitsPerSecond;
var
  L: IRateLimiter;
  SW: TStopwatch;
  I: Integer;
  ElapsedMs: Int64;
begin
  // Strict rate: 2 hits per second
  L := TRateLimiter.CreateDefault.AllowHits(2).PerSeconds(1);
  AssertTrue(L.CanFire, 'CanFire should be True initially');

  SW := TStopwatch.StartNew;
  for I := 1 to 7 do
    L.WaitFire;
  SW.Stop;

  ElapsedMs := SW.ElapsedMilliseconds;
  // Expect total time > 2000 ms for ~7 fires at 2/sec
  AssertTrue(ElapsedMs > 2000, Format('ExecTime %dms (expected > 2000ms)', [ElapsedMs]));
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcRateLimitingTests);
{$ELSE}
  RegisterTest(TSolanaRpcRateLimitingTests.Suite);
{$ENDIF}

end.

