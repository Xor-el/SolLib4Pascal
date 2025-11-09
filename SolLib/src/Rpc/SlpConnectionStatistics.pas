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

unit SlpConnectionStatistics;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.SyncObjs,
  System.DateUtils,
  SlpTimeTicker;

type
  /// <summary>
  /// Contains several statistics regarding connection speed and data usage.
  /// </summary>
  IConnectionStatistics = interface
    ['{67871DBD-BCD7-437A-A1EE-8E4D878984AD}']

    /// <summary>
    /// Average throughput in the last 10s. Measured in bytes/s.
    /// </summary>
    function GetAverageThroughput10Seconds: UInt64;
    procedure SetAverageThroughput10Seconds(const Value: UInt64);
    property AverageThroughput10Seconds: UInt64 read GetAverageThroughput10Seconds write SetAverageThroughput10Seconds;

    /// <summary>
    /// Average throughput in the last minute. Measured in bytes/s.
    /// </summary>
    function GetAverageThroughput60Seconds: UInt64;
    procedure SetAverageThroughput60Seconds(const Value: UInt64);
    property AverageThroughput60Seconds: UInt64 read GetAverageThroughput60Seconds write SetAverageThroughput60Seconds;

    /// <summary>
    /// Total bytes downloaded.
    /// </summary>
    function GetTotalReceivedBytes: UInt64;
    procedure SetTotalReceivedBytes(const Value: UInt64);
    property TotalReceivedBytes: UInt64 read GetTotalReceivedBytes write SetTotalReceivedBytes;

    procedure AddReceived(const Count: UInt32);
  end;

  /// <summary>
  /// Connection Stats using TTimeTicker for periodic cleanup.
  /// </summary>
type
  TConnectionStatistics = class(TInterfacedObject, IConnectionStatistics)
  private
    FTicker: TTimeTicker;
    FLock: TCriticalSection;
    FHistoricData: TDictionary<Int64, UInt64>;

    FTotalReceived: UInt64;
    FAverageReceived10s: UInt64;
    FAverageReceived60s: UInt64;

    function GetAverageThroughput10Seconds: UInt64;
    procedure SetAverageThroughput10Seconds(const Value: UInt64);
    function GetAverageThroughput60Seconds: UInt64;
    procedure SetAverageThroughput60Seconds(const Value: UInt64);
    function GetTotalReceivedBytes: UInt64;
    procedure SetTotalReceivedBytes(const Value: UInt64);

    procedure RemoveOutdatedData(Sender: TObject);

    procedure AddReceived(const Count: UInt32);

    class function CurrentUnixSeconds: Int64; static;
  public
    constructor Create(const ATimerIntervalMs: Cardinal = 1000);
    destructor Destroy; override;
  end;


implementation

{ TConnectionStatistics }

constructor TConnectionStatistics.Create(const ATimerIntervalMs: Cardinal);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FHistoricData := TDictionary<Int64, UInt64>.Create;

  FTicker := TTimeTicker.Create(ATimerIntervalMs);
  FTicker.OnTick := RemoveOutdatedData;
  FTicker.Disable; // start disabled; enable on first AddReceived

  FTotalReceived := 0;
  FAverageReceived10s := 0;
  FAverageReceived60s := 0;
end;

destructor TConnectionStatistics.Destroy;
begin
  if Assigned(FTicker) then
  begin
    FTicker.Disable;
    FTicker.Free;
  end;

  if Assigned(FHistoricData) then
    FHistoricData.Free;

  if Assigned(FLock) then
    FLock.Free;

  inherited;
end;


class function TConnectionStatistics.CurrentUnixSeconds: Int64;
begin
  Result := DateTimeToUnix(Now, False);
end;

procedure TConnectionStatistics.AddReceived(const Count: UInt32);
var
  Secs: Int64;
  CurrentVal: UInt64;
begin
  FLock.Acquire;
  try
    Secs := CurrentUnixSeconds;
    Inc(FTotalReceived, Count);
    if not FTicker.IsEnabled then
      FTicker.Enable;

    if FHistoricData.TryGetValue(Secs, CurrentVal) then
      FHistoricData[Secs] := CurrentVal + Count
    else
      FHistoricData.Add(Secs, Count);

    Inc(FAverageReceived60s, Count div 60);
    Inc(FAverageReceived10s, Count div 10);
  finally
    FLock.Release;
  end;
end;

procedure TConnectionStatistics.RemoveOutdatedData(Sender: TObject);
var
  CurrentSec, OldSec: Int64;
  Pair: TPair<Int64, UInt64>;
  Total, TenSecTotal: UInt64;
begin
  FLock.Acquire;
  try
    CurrentSec := CurrentUnixSeconds;
    OldSec := CurrentSec - 60;

    if FHistoricData.ContainsKey(OldSec) then
      FHistoricData.Remove(OldSec);

    if FHistoricData.Count = 0 then
    begin
      FTicker.Disable;
      FAverageReceived60s := 0;
      FAverageReceived10s := 0;
      Exit;
    end
    else
    begin
      Total := 0;
      TenSecTotal := 0;

    for Pair in FHistoricData do
    begin
      Inc(Total, Pair.Value);
      if Pair.Key > (CurrentSec - 10) then
        Inc(TenSecTotal, Pair.Value);
    end;

      FAverageReceived60s := Total div 60;
      FAverageReceived10s := TenSecTotal div 10;
    end;
  finally
    FLock.Release;
  end;
end;

function TConnectionStatistics.GetAverageThroughput10Seconds: UInt64;
begin
  Result := FAverageReceived10s;
end;

procedure TConnectionStatistics.SetAverageThroughput10Seconds(const Value: UInt64);
begin
  FAverageReceived10s := Value;
end;

function TConnectionStatistics.GetAverageThroughput60Seconds: UInt64;
begin
  Result := FAverageReceived60s;
end;

procedure TConnectionStatistics.SetAverageThroughput60Seconds(const Value: UInt64);
begin
  FAverageReceived60s := Value;
end;

function TConnectionStatistics.GetTotalReceivedBytes: UInt64;
begin
  Result := FTotalReceived;
end;

procedure TConnectionStatistics.SetTotalReceivedBytes(const Value: UInt64);
begin
  FTotalReceived := Value;
end;

end.

