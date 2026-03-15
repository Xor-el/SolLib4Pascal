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

unit SlpConnectionStatistics;

{$I ../Include/SolLib.inc}

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
    procedure SetAverageThroughput10Seconds(const AValue: UInt64);
    property AverageThroughput10Seconds: UInt64 read GetAverageThroughput10Seconds write SetAverageThroughput10Seconds;

    /// <summary>
    /// Average throughput in the last minute. Measured in bytes/s.
    /// </summary>
    function GetAverageThroughput60Seconds: UInt64;
    procedure SetAverageThroughput60Seconds(const AValue: UInt64);
    property AverageThroughput60Seconds: UInt64 read GetAverageThroughput60Seconds write SetAverageThroughput60Seconds;

    /// <summary>
    /// Total bytes downloaded.
    /// </summary>
    function GetTotalReceivedBytes: UInt64;
    procedure SetTotalReceivedBytes(const AValue: UInt64);
    property TotalReceivedBytes: UInt64 read GetTotalReceivedBytes write SetTotalReceivedBytes;

    procedure AddReceived(const ACount: UInt32);
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
    procedure SetAverageThroughput10Seconds(const AValue: UInt64);
    function GetAverageThroughput60Seconds: UInt64;
    procedure SetAverageThroughput60Seconds(const AValue: UInt64);
    function GetTotalReceivedBytes: UInt64;
    procedure SetTotalReceivedBytes(const AValue: UInt64);

    procedure RemoveOutdatedData(ASender: TObject);

    procedure AddReceived(const ACount: UInt32);

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

procedure TConnectionStatistics.AddReceived(const ACount: UInt32);
var
  LSecs: Int64;
  LCurrentVal: UInt64;
begin
  FLock.Acquire;
  try
    LSecs := CurrentUnixSeconds;
    Inc(FTotalReceived, ACount);
    if not FTicker.IsEnabled then
      FTicker.Enable;

    if FHistoricData.TryGetValue(LSecs, LCurrentVal) then
      FHistoricData[LSecs] := LCurrentVal + ACount
    else
      FHistoricData.Add(LSecs, ACount);

    Inc(FAverageReceived60s, ACount div 60);
    Inc(FAverageReceived10s, ACount div 10);
  finally
    FLock.Release;
  end;
end;

procedure TConnectionStatistics.RemoveOutdatedData(ASender: TObject);
var
  LCurrentSec, LOldSec: Int64;
  LPair: TPair<Int64, UInt64>;
  LTotal, LTenSecTotal: UInt64;
begin
  FLock.Acquire;
  try
    LCurrentSec := CurrentUnixSeconds;
    LOldSec := LCurrentSec - 60;

    if FHistoricData.ContainsKey(LOldSec) then
      FHistoricData.Remove(LOldSec);

    if FHistoricData.Count = 0 then
    begin
      FTicker.Disable;
      FAverageReceived60s := 0;
      FAverageReceived10s := 0;
      Exit;
    end
    else
    begin
      LTotal := 0;
      LTenSecTotal := 0;

    for LPair in FHistoricData do
    begin
      Inc(LTotal, LPair.Value);
      if LPair.Key > (LCurrentSec - 10) then
        Inc(LTenSecTotal, LPair.Value);
    end;

      FAverageReceived60s := LTotal div 60;
      FAverageReceived10s := LTenSecTotal div 10;
    end;
  finally
    FLock.Release;
  end;
end;

function TConnectionStatistics.GetAverageThroughput10Seconds: UInt64;
begin
  Result := FAverageReceived10s;
end;

procedure TConnectionStatistics.SetAverageThroughput10Seconds(const AValue: UInt64);
begin
  FAverageReceived10s := AValue;
end;

function TConnectionStatistics.GetAverageThroughput60Seconds: UInt64;
begin
  Result := FAverageReceived60s;
end;

procedure TConnectionStatistics.SetAverageThroughput60Seconds(const AValue: UInt64);
begin
  FAverageReceived60s := AValue;
end;

function TConnectionStatistics.GetTotalReceivedBytes: UInt64;
begin
  Result := FTotalReceived;
end;

procedure TConnectionStatistics.SetTotalReceivedBytes(const AValue: UInt64);
begin
  FTotalReceived := AValue;
end;

end.

