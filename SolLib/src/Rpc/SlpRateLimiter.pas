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

unit SlpRateLimiter;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Generics.Collections,
  System.Classes;

type
  /// <summary>
  /// Provides rate limiting behaviour for RPC interactions using a sliding time window.
  /// </summary>
  /// <remarks>
  /// - Intended for single-threaded use (not thread-safe).
  /// </remarks>
  IRateLimiter = interface
    ['{2D6E49A1-AD9E-4B93-B1D0-9E2BF9D79E0E}']
    /// <summary>
    /// Blocks (sleeping) until the next "fire" is permitted, then records the hit.
    /// </summary>
    procedure WaitFire;

    /// <summary>
    /// Indicates whether a "fire" would be permitted right now without blocking.
    /// </summary>
    function CanFire: Boolean;

    /// <summary>
    /// Sets the sliding-window length in seconds for the rate limit.
    /// </summary>
    /// <param name="seconds">Window length in seconds.</param>
    /// <returns>The same limiter instance for fluent chaining.</returns>
    function PerSeconds(seconds: Integer): IRateLimiter;

    /// <summary>
    /// Sets the sliding-window length in milliseconds for the rate limit.
    /// </summary>
    /// <param name="ms">Window length in milliseconds.</param>
    /// <returns>The same limiter instance for fluent chaining.</returns>
    function PerMs(ms: Integer): IRateLimiter;

    /// <summary>
    /// Sets how many hits are allowed within the sliding window.
    /// </summary>
    /// <param name="hits">Number of permitted hits within the configured window.</param>
    /// <returns>The same limiter instance for fluent chaining.</returns>
    function AllowHits(hits: Integer): IRateLimiter;
  end;

  /// <summary>
  /// A primitive blocking sliding time-window rate limiter (not thread-safe).
  /// </summary>
  /// <remarks>
  /// Use the factory methods <see cref="TRateLimiter.New"/> or
  /// <see cref="TRateLimiter.CreateDefault"/> to obtain an <see cref="IRateLimiter"/>.
  /// </remarks>
  TRateLimiter = class(TInterfacedObject, IRateLimiter)
  private
    FHits: Integer;
    FDurationMs: Integer;
    FHitList: TQueue<TDateTime>;

    /// <summary>
    /// Computes the earliest UTC time when a new fire is allowed, given a check time.
    /// </summary>
    function NextFireAllowed(const CheckTimeUtc: TDateTime): TDateTime;

    /// <summary>
    /// Returns the current UTC time.
    /// </summary>
    class function UtcNow: TDateTime; static;
  public
    /// <summary>
    /// Low-level constructor (prefer <see cref="New"/>/<see cref="CreateDefault"/>).
    /// </summary>
    /// <param name="hits">Number of hits allowed within the window.</param>
    /// <param name="durationMs">Window length in milliseconds (0 means "no window").</param>
    constructor Create(hits, durationMs: Integer);
    destructor Destroy; override;

    /// <summary>
    /// Creates a limiter with the specified <paramref name="hits"/> and <paramref name="durationMs"/>.
    /// </summary>
    /// <returns>An <see cref="IRateLimiter"/> whose lifetime is interface-managed.</returns>
    class function New(hits, durationMs: Integer): IRateLimiter; static;

    /// <summary>
    /// Creates a limiter with <c>hits=1</c> and <c>durationMs=0</c> (effectively "no limit").
    /// </summary>
    /// <returns>An <see cref="IRateLimiter"/> whose lifetime is interface-managed.</returns>
    class function CreateDefault: IRateLimiter; static;

    { IRateLimiter }
    /// <inheritdoc/>
    procedure WaitFire;
    /// <inheritdoc/>
    function CanFire: Boolean;
    /// <inheritdoc/>
    function PerSeconds(seconds: Integer): IRateLimiter;
    /// <inheritdoc/>
    function PerMs(ms: Integer): IRateLimiter;
    /// <inheritdoc/>
    function AllowHits(hits: Integer): IRateLimiter;

    /// <summary>
    /// Debug helper: shows queue size and oldest-hit timestamp (local time).
    /// </summary>
    function ToString: string; override;
  end;

implementation

{ TRateLimiter }

constructor TRateLimiter.Create(hits, durationMs: Integer);
begin
  inherited Create;
  FHits       := hits;
  FDurationMs := durationMs;
  FHitList    := TQueue<TDateTime>.Create;
end;

destructor TRateLimiter.Destroy;
begin
  FHitList.Free;
  inherited;
end;

class function TRateLimiter.New(hits, durationMs: Integer): IRateLimiter;
begin
  Result := TRateLimiter.Create(hits, durationMs);
end;

class function TRateLimiter.CreateDefault: IRateLimiter;
begin
  Result := TRateLimiter.Create(1, 0);
end;

class function TRateLimiter.UtcNow: TDateTime;
begin
  Result := TTimeZone.Local.ToUniversalTime(Now);
end;

function TRateLimiter.CanFire: Boolean;
var
  NowUtc, ResumeUtc: TDateTime;
begin
  NowUtc   := UtcNow;
  ResumeUtc := NextFireAllowed(NowUtc);
  Result   := NowUtc >= ResumeUtc;
end;

function TRateLimiter.NextFireAllowed(const CheckTimeUtc: TDateTime): TDateTime;
var
  CutOff: TDateTime;
  DeltaMs: Double;
begin
  // No window => allow immediately
  if FDurationMs = 0 then
    Exit(CheckTimeUtc);

  // Empty queue => allow immediately
  if FHitList.Count = 0 then
    Exit(CheckTimeUtc);

  CutOff := IncMilliSecond(CheckTimeUtc, Int64(-FDurationMs));
  while (FHitList.Count > 0) do
  begin
    DeltaMs := (FHitList.Peek - CutOff) * MSecsPerDay;
    if DeltaMs < 0 then
      FHitList.Dequeue
    else
      Break;
  end;

  if FHitList.Count >= FHits then
    Result := IncMilliSecond(FHitList.Peek, FDurationMs)
  else
    Result := CheckTimeUtc;
end;

procedure TRateLimiter.WaitFire;
var
  CheckUtc, ResumeUtc: TDateTime;
begin
  CheckUtc  := UtcNow;
  ResumeUtc := NextFireAllowed(CheckUtc);

  while UtcNow <= ResumeUtc do
    TThread.Sleep(50);

  if FDurationMs > 0 then
    FHitList.Enqueue(UtcNow);
end;

function TRateLimiter.PerSeconds(seconds: Integer): IRateLimiter;
begin
  if seconds < 0 then
    raise EArgumentOutOfRangeException.Create('seconds must be >= 0');
  FDurationMs := seconds * 1000;
  Result := Self;
end;

function TRateLimiter.PerMs(ms: Integer): IRateLimiter;
begin
  if ms < 0 then
    raise EArgumentOutOfRangeException.Create('ms must be >= 0');
  FDurationMs := ms;
  Result := Self;
end;

function TRateLimiter.AllowHits(hits: Integer): IRateLimiter;
begin
  if hits < 1 then
    raise EArgumentOutOfRangeException.Create('hits must be >= 1');
  FHits := hits;
  Result := Self;
end;

function TRateLimiter.ToString: string;
var
  Head: TDateTime;
begin
  if FHitList.Count > 0 then
  begin
    Head := FHitList.Peek;
    Result := Format('%d-%s', [FHitList.Count, FormatDateTime('hh:nn:ss.zzz', TTimeZone.Local.ToLocalTime(Head))]);
  end
  else
    Result := '(empty)';
end;

end.

