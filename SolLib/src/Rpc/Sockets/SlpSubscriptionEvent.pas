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

unit SlpSubscriptionEvent;

{$I ..\..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  SlpRpcEnum;

type
  /// <summary>
  /// Marker interface for event payloads.
  /// </summary>
  IEventArgs = interface
    ['{5C7B5B8B-8B1E-4C7B-9B67-5E8C8B2DB0B9}']
  end;

  /// <summary>
  /// Represents an event related to a given subscription.
  /// </summary>
  ISubscriptionEvent = interface(IEventArgs)
    ['{D7C2E1E8-0A4E-4B06-97D3-1B0E2C02C2E7}']
    /// <summary>
    /// The new status of the subscription.
    /// </summary>
    function GetStatus: TSubscriptionStatus;
    /// <summary>
    /// A possible error message for this event.
    /// </summary>
    function GetError: string;
    /// <summary>
    /// A possible error code for this event.
    /// </summary>
    function GetCode: string;

    /// <summary>The new status of the subscription.</summary>
    property Status: TSubscriptionStatus read GetStatus;
    /// <summary>A possible error message for this event.</summary>
    property Error: string read GetError;
    /// <summary>A possible error code for this event.</summary>
    property Code: string read GetCode;
  end;

  /// <summary>
  /// Represents an event related to a given subscription.
  /// </summary>
  /// <remarks>
  /// </remarks>
  TSubscriptionEvent = class sealed(TInterfacedObject, ISubscriptionEvent)
  private
    FStatus: TSubscriptionStatus;
    FError: string;
    FCode: string;
  protected
    function GetStatus: TSubscriptionStatus;
    function GetError: string;
    function GetCode: string;
  public
    /// <summary>
    /// Constructor.
    /// </summary>
    /// <param name="AStatus">The new status.</param>
    /// <param name="AError">The possible error message.</param>
    /// <param name="ACode">The possible error code.</param>
    constructor Create(AStatus: TSubscriptionStatus; const AError: string = ''; const ACode: string = '');

    /// <summary>The new status of the subscription.</summary>
    property Status: TSubscriptionStatus read GetStatus;
    /// <summary>A possible error message for this event.</summary>
    property Error: string read GetError;
    /// <summary>A possible error code for this event.</summary>
    property Code: string read GetCode;
  end;

implementation

{ TSubscriptionEvent }

constructor TSubscriptionEvent.Create(AStatus: TSubscriptionStatus; const AError, ACode: string);
begin
  inherited Create;
  FStatus := AStatus;
  FError  := AError;
  FCode   := ACode;
end;

function TSubscriptionEvent.GetCode: string;
begin
  Result := FCode;
end;

function TSubscriptionEvent.GetError: string;
begin
  Result := FError;
end;

function TSubscriptionEvent.GetStatus: TSubscriptionStatus;
begin
  Result := FStatus;
end;

end.

