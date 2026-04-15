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

unit SlpMulticast;

{$I ../Include/SolLib.inc}

interface

uses
  SysUtils,
  Generics.Collections,
  Generics.Defaults,
  SyncObjs,
  SlpSolLibTypes;

type
  /// <summary>
  /// Generic multicast container for function/procedure/anonymous-method handlers.
  /// Allows duplicates; Remove deletes one occurrence from the end.
  /// Thread-safe: Add/Remove/Notify are guarded; Notify snapshots before invoking.
  /// </summary>
  IMulticast<THandler> = interface
    ['{A0D3F8E0-8A9B-4E2B-BB54-7A0A0B6E8C7F}']
    procedure Add(const AHandler: THandler);
    procedure Remove(const AHandler: THandler);
    procedure Clear;
    function Count: Integer;
    function IsEmpty: Boolean;

    /// <summary>
    /// Invoke all subscribers using a user-supplied invoker that knows how to call THandler.
    /// If a handler raises an exception, it propagates immediately and remaining
    /// handlers are not invoked.
    /// Example:
    ///   Multicast.Notify(
    ///     procedure(const AHandler: TProc&lt;Integer, string&gt;)
    ///     begin
    ///       AHandler(42, 'hello');
    ///     end);
    /// </summary>
    procedure Notify(const AInvoker: TProc<THandler>);
  end;

  /// <summary>
  /// Default implementation of IMulticast&lt;THandler&gt;.
  /// </summary>
  TMulticast<THandler> = class(TInterfacedObject, IMulticast<THandler>)
  private
    FList: TList<THandler>;
    FComparer: IEqualityComparer<THandler>;
    FLock: TCriticalSection;

    /// <summary>
    /// Takes a snapshot of the current handler list under lock.
    /// Returns nil if the list is empty.
    /// </summary>
    function Snapshot: TArray<THandler>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(const AHandler: THandler);
    procedure Remove(const AHandler: THandler);
    procedure Clear;
    function Count: Integer;
    function IsEmpty: Boolean;
    procedure Notify(const AInvoker: TProc<THandler>);
  end;

implementation

{ TMulticast<THandler> }

constructor TMulticast<THandler>.Create;
begin
  inherited Create;
  FList := TList<THandler>.Create;
  FComparer := TEqualityComparer<THandler>.Default;
  FLock := TCriticalSection.Create;
end;

destructor TMulticast<THandler>.Destroy;
begin
  FList.Free;
  FLock.Free;
  inherited;
end;

function TMulticast<THandler>.Snapshot: TArray<THandler>;
begin
  FLock.Acquire;
  try
    if FList.Count = 0 then
      Result := nil
    else
      Result := FList.ToArray;
  finally
    FLock.Release;
  end;
end;

procedure TMulticast<THandler>.Add(const AHandler: THandler);
begin
  FLock.Acquire;
  try
    FList.Add(AHandler);
  finally
    FLock.Release;
  end;
end;

procedure TMulticast<THandler>.Remove(const AHandler: THandler);
var
  LI: Integer;
begin
  FLock.Acquire;
  try
    for LI := FList.Count - 1 downto 0 do
      if FComparer.Equals(FList[LI], AHandler) then
      begin
        FList.Delete(LI);
        Break;
      end;
  finally
    FLock.Release;
  end;
end;

procedure TMulticast<THandler>.Clear;
begin
  FLock.Acquire;
  try
    FList.Clear;
  finally
    FLock.Release;
  end;
end;

function TMulticast<THandler>.Count: Integer;
begin
  FLock.Acquire;
  try
    Result := FList.Count;
  finally
    FLock.Release;
  end;
end;

function TMulticast<THandler>.IsEmpty: Boolean;
begin
  FLock.Acquire;
  try
    Result := FList.Count = 0;
  finally
    FLock.Release;
  end;
end;

procedure TMulticast<THandler>.Notify(const AInvoker: TProc<THandler>);
var
  LHandlers: TArray<THandler>;
  LHandler: THandler;
begin
  if not Assigned(AInvoker) then
    Exit;

  LHandlers := Snapshot;
  if LHandlers = nil then
    Exit;

  for LHandler in LHandlers do
    AInvoker(LHandler);
end;

end.
