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

unit SlpTimeTicker;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  System.Classes;

type
  /// <summary>
  /// Cross-platform ticker. Calls OnTick every IntervalMs.
  /// </summary>
  TTimeTicker = class(TThread)
  private
    FGate: TEvent;
    FOnTick: TNotifyEvent;
    FIntervalMs: Cardinal;
    FEnabled: Boolean;
    FStarted: Boolean; // <-- track if we have started the thread
  protected
    procedure Execute; override;
  public
    constructor Create(const AIntervalMs: Cardinal);
    destructor Destroy; override;

    procedure Enable;
    procedure Disable;
    function IsEnabled: Boolean;

    property IntervalMs: Cardinal read FIntervalMs write FIntervalMs;
    property OnTick: TNotifyEvent read FOnTick write FOnTick;
  end;

implementation

{ TTimeTicker }

constructor TTimeTicker.Create(const AIntervalMs: Cardinal);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FGate := TEvent.Create(nil, False, False, '');
  FIntervalMs := AIntervalMs;
  FOnTick := nil;
  FEnabled := False;
  FStarted := False; // will call Start on first Enable
end;

destructor TTimeTicker.Destroy;
begin
  if FStarted then
  begin
    Terminate;       // tell the thread loop to exit
    FGate.SetEvent;  // wake it up if it's waiting
    WaitFor;         // block until Execute has exited
  end;
  FGate.Free;        // now safe to free
  FOnTick := nil;
  inherited;         // base cleanup
end;

procedure TTimeTicker.Enable;
begin
  // Start the thread exactly once, lazily
  if not FStarted then
  begin
    FStarted := True;
    inherited Start;     // start the worker thread now
  end;

  FEnabled := True;
  FGate.SetEvent;        // wake immediately
end;

procedure TTimeTicker.Disable;
begin
  FEnabled := False;
  FGate.SetEvent;        // wake to observe new state
end;

function TTimeTicker.IsEnabled: Boolean;
begin
  Result := FEnabled;
end;

procedure TTimeTicker.Execute;
var
  NextWake, NowTick: UInt64;
  WaitMs: Cardinal;
begin
  // Use monotonic tick to avoid wall-clock jumps
  NextWake := TThread.GetTickCount;
  while not Terminated do
  begin
    if not FEnabled then
    begin
      FGate.WaitFor(100);
      NextWake := TThread.GetTickCount + FIntervalMs;
      Continue;
    end;

    // Tick
    try
      if Assigned(FOnTick) then
        FOnTick(Self);
    except
      // keep ticker alive
    end;

    // Compute next wait
    NextWake := NextWake + FIntervalMs;
    NowTick := TThread.GetTickCount;
    if NextWake <= NowTick then
      WaitMs := 0
    else
      WaitMs := Cardinal(NextWake - NowTick);

    // Wait or wake early if enabled/disabled toggles
    FGate.WaitFor(WaitMs);
  end;
end;

end.

