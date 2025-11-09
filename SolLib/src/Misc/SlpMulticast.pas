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

unit SlpMulticast;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SyncObjs;

type
  /// <summary>
  /// Generic multicast container for function/procedure/anonymous-method handlers.
  /// Allows duplicates, and Remove deletes one occurrence from the end.
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
    /// Example:
    ///   Multicast.Notify(
    ///     procedure(const H: TProc<Integer, string>)
    ///     begin
    ///       H(42, 'hello');
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
    FLock: TCriticalSection;
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
  FLock := TCriticalSection.Create;
end;

destructor TMulticast<THandler>.Destroy;
begin
  FLock.Enter;
  try
    FList.Free;
  finally
    FLock.Leave;
    FLock.Free;
  end;
  inherited;
end;

procedure TMulticast<THandler>.Add(const AHandler: THandler);
begin
  // Allows duplicates
  FLock.Enter;
  try
    FList.Add(AHandler);
  finally
    FLock.Leave;
  end;
end;

procedure TMulticast<THandler>.Remove(const AHandler: THandler);
var
  I: Integer;
  Cmp: IEqualityComparer<THandler>;
begin
  // Remove ONE occurrence from the end
  FLock.Enter;
  try
    Cmp := TEqualityComparer<THandler>.Default;
    for I := FList.Count - 1 downto 0 do
      if Cmp.Equals(FList[I], AHandler) then
      begin
        FList.Delete(I);
        Break;
      end;
  finally
    FLock.Leave;
  end;
end;

procedure TMulticast<THandler>.Clear;
begin
  FLock.Enter;
  try
    FList.Clear;
  finally
    FLock.Leave;
  end;
end;

function TMulticast<THandler>.Count: Integer;
begin
  FLock.Enter;
  try
    Result := FList.Count;
  finally
    FLock.Leave;
  end;
end;

function TMulticast<THandler>.IsEmpty: Boolean;
begin
  Result := Count = 0;
end;

procedure TMulticast<THandler>.Notify(const AInvoker: TProc<THandler>);
var
  Snapshot: TArray<THandler>;
  H: THandler;
begin
  if not Assigned(AInvoker) then Exit;

  // Snapshot to avoid re-entrancy/mutation during callbacks
  FLock.Enter;
  try
    if FList.Count = 0 then Exit;
    Snapshot := FList.ToArray;
  finally
    FLock.Leave;
  end;

  for H in Snapshot do
  begin
    try
      AInvoker(H);
    except
      // Swallow to keep multicast robust.
    end;
  end;
end;

end.

