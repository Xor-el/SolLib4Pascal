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

unit SolanaRpcRateLimitingTests;

interface

uses
  SysUtils,
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
  LLimiter: IRateLimiter;
  LI: Integer;
begin
  // Default: no limits -> all fires should pass immediately
  LLimiter := TRateLimiter.CreateDefault;
  AssertTrue(LLimiter.CanFire, 'CanFire should be True initially');
  for LI := 1 to 7 do
    LLimiter.WaitFire;
end;

procedure TSolanaRpcRateLimitingTests.TestMaxSpeed_WithinLimits;
var
  LLimiter: IRateLimiter;
  LI: Integer;
begin
  // High ceiling: effectively unthrottled for a handful of calls
  LLimiter := TRateLimiter.CreateDefault.AllowHits(100).PerSeconds(10);
  AssertTrue(LLimiter.CanFire, 'CanFire should be True initially');
  for LI := 1 to 9 do
    LLimiter.WaitFire;
end;

procedure TSolanaRpcRateLimitingTests.TestTwoHitsPerSecond;
var
  LLimiter: IRateLimiter;
  LStopwatch: TStopwatch;
  LI: Integer;
  LElapsedMs: Int64;
begin
  // Strict rate: 2 hits per second
  LLimiter := TRateLimiter.CreateDefault.AllowHits(2).PerSeconds(1);
  AssertTrue(LLimiter.CanFire, 'CanFire should be True initially');

  LStopwatch := TStopwatch.StartNew;
  for LI := 1 to 7 do
    LLimiter.WaitFire;
  LStopwatch.Stop;

  LElapsedMs := LStopwatch.ElapsedMilliseconds;
  // Expect total time > 2000 ms for ~7 fires at 2/sec
  AssertTrue(LElapsedMs > 2000, Format('ExecTime %dms (expected > 2000ms)', [LElapsedMs]));
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcRateLimitingTests);
{$ELSE}
  RegisterTest(TSolanaRpcRateLimitingTests.Suite);
{$ENDIF}

end.

