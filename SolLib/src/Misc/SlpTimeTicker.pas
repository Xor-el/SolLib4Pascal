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

unit SlpTimeTicker;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  System.Classes;

type
  TTickerErrorEvent = procedure(ASender: TObject; const AException: Exception) of object;

  /// <summary>
  /// Cross-platform ticker. Calls OnTick every IntervalMs.
  /// </summary>
  TTimeTicker = class(TThread)
  private
    FGate: TEvent;
    FLock: TCriticalSection;
    FOnTick: TNotifyEvent;
    FOnError: TTickerErrorEvent;
    FIntervalMs: Cardinal;
    FEnabled: Boolean;
    FStarted: Boolean;
    function GetOnTick: TNotifyEvent;
    procedure SetOnTick(const AValue: TNotifyEvent);
    function GetOnError: TTickerErrorEvent;
    procedure SetOnError(const AValue: TTickerErrorEvent);
    function GetIntervalMs: Cardinal;
    procedure SetIntervalMs(const AValue: Cardinal);
  protected
    procedure Execute; override;
  public
    constructor Create(const AIntervalMs: Cardinal);
    destructor Destroy; override;
    procedure Enable;
    procedure Disable;
    function IsEnabled: Boolean;
    property IntervalMs: Cardinal read GetIntervalMs write SetIntervalMs;
    property OnTick: TNotifyEvent read GetOnTick write SetOnTick;
    property OnError: TTickerErrorEvent read GetOnError write SetOnError;
  end;

implementation

{ TTimeTicker }

constructor TTimeTicker.Create(const AIntervalMs: Cardinal);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FGate := TEvent.Create(nil, False, False, '');
  FLock := TCriticalSection.Create;
  FIntervalMs := AIntervalMs;
  FOnTick := nil;
  FOnError := nil;
  FEnabled := False;
  FStarted := False;
end;

destructor TTimeTicker.Destroy;
begin
  if FStarted then
  begin
    Terminate;       // tell the thread loop to exit
    FGate.SetEvent;  // wake it up if it's waiting
    WaitFor;         // block until Execute has exited
  end;
  FGate.Free;
  FLock.Free;
  FOnTick := nil;
  FOnError := nil;
  inherited;
end;

function TTimeTicker.GetOnTick: TNotifyEvent;
begin
  FLock.Enter;
  try
    Result := FOnTick;
  finally
    FLock.Leave;
  end;
end;

procedure TTimeTicker.SetOnTick(const AValue: TNotifyEvent);
begin
  FLock.Enter;
  try
    FOnTick := AValue;
  finally
    FLock.Leave;
  end;
end;

function TTimeTicker.GetOnError: TTickerErrorEvent;
begin
  FLock.Enter;
  try
    Result := FOnError;
  finally
    FLock.Leave;
  end;
end;

procedure TTimeTicker.SetOnError(const AValue: TTickerErrorEvent);
begin
  FLock.Enter;
  try
    FOnError := AValue;
  finally
    FLock.Leave;
  end;
end;

function TTimeTicker.GetIntervalMs: Cardinal;
begin
  FLock.Enter;
  try
    Result := FIntervalMs;
  finally
    FLock.Leave;
  end;
end;

procedure TTimeTicker.SetIntervalMs(const AValue: Cardinal);
begin
  FLock.Enter;
  try
    FIntervalMs := AValue;
  finally
    FLock.Leave;
  end;
end;

procedure TTimeTicker.Enable;
begin
  if not FStarted then
  begin
    FStarted := True;
    inherited Start;
  end;
  FEnabled := True;
  FGate.SetEvent;
end;

procedure TTimeTicker.Disable;
begin
  FEnabled := False;
  FGate.SetEvent;
end;

function TTimeTicker.IsEnabled: Boolean;
begin
  Result := FEnabled;
end;

procedure TTimeTicker.Execute;
var
  LNextWake, LNowTick, LInterval, LElapsed: Cardinal;
  LTickHandler: TNotifyEvent;
  LErrorHandler: TTickerErrorEvent;
begin
  LNextWake := TThread.GetTickCount;
  while not Terminated do
  begin
    if not FEnabled then
    begin
      // Sleep until signalled — no polling
      FGate.WaitFor(INFINITE);
      LNextWake := TThread.GetTickCount + GetIntervalMs;
      Continue;
    end;

    // Snapshot the handler under lock to avoid torn reads
    LTickHandler := GetOnTick();

    // Tick
    try
      if Assigned(LTickHandler) then
        LTickHandler(Self);
    except
      on E: Exception do
      begin
        LErrorHandler := GetOnError();
        if Assigned(LErrorHandler) then
        begin
          try
            LErrorHandler(Self, E);
          except
            // prevent error handler from killing the ticker
          end;
        end;
      end;
    end;

    // Compute next wait using Cardinal arithmetic (wrap-safe)
    LInterval := GetIntervalMs;
    LNextWake := LNextWake + LInterval;
    LNowTick := TThread.GetTickCount;

    // Cardinal subtraction wraps correctly for a single 32-bit overflow
    LElapsed := LNowTick - LNextWake;
    // If LNextWake is in the future, LElapsed wraps to a huge value (> LInterval)
    if LElapsed >= LInterval then
      // We're behind or exactly on time — fire immediately
      FGate.WaitFor(0)
    else
      FGate.WaitFor(Cardinal(LNextWake - LNowTick));
  end;
end;

end.
