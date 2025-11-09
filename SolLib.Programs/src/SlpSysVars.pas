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

unit SlpSysVars;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  SlpPublicKey;

type
  /// <summary>
  /// Represents the System Variables
  /// </summary>
  TSysVars = class sealed
  strict private
    class var FRecentBlockHashesKey: IPublicKey;
    class var FRentKey            : IPublicKey;
    class var FClockKey           : IPublicKey;
    class var FStakeHistoryKey    : IPublicKey;
    class var FSlotHashesKey      : IPublicKey;
    class var FInstructionsKey    : IPublicKey;
  public
    /// <summary>
    /// The public key of the Recent Block Hashes System Variable.
    /// </summary>
    class property RecentBlockHashesKey: IPublicKey read FRecentBlockHashesKey;

    /// <summary>
    /// The public key of the Rent System Variable.
    /// </summary>
    class property RentKey: IPublicKey read FRentKey;

    /// <summary>
    /// The public key of the Clock System Variable.
    /// </summary>
    class property ClockKey: IPublicKey read FClockKey;

    /// <summary>
    /// The public key of the Stake History System Variable.
    /// </summary>
    class property StakeHistoryKey: IPublicKey read FStakeHistoryKey;

    /// <summary>
    /// The public key of the Slot Hashes Systen Variable
    /// </summary>
    class property SlotHashesKey: IPublicKey read FSlotHashesKey;

    /// <summary>
    /// The public key of the Instructions System Variable
    /// </summary>
    class property InstructionsKey: IPublicKey read FInstructionsKey;

    class constructor Create;
    class destructor Destroy;
  end;

implementation

{ TSysVars }

class constructor TSysVars.Create;
begin
  FRecentBlockHashesKey := TPublicKey.Create('SysvarRecentB1ockHashes11111111111111111111');
  FRentKey              := TPublicKey.Create('SysvarRent111111111111111111111111111111111');
  FClockKey             := TPublicKey.Create('SysvarC1ock11111111111111111111111111111111');
  FStakeHistoryKey      := TPublicKey.Create('SysvarStakeHistory1111111111111111111111111');
  FSlotHashesKey        := TPublicKey.Create('SysvarS1otHashes111111111111111111111111111');
  FInstructionsKey      := TPublicKey.Create('Sysvar1nstructions1111111111111111111111111');
end;

class destructor TSysVars.Destroy;
begin
  FRecentBlockHashesKey := nil;
  FRentKey              := nil;
  FClockKey             := nil;
  FStakeHistoryKey      := nil;
  FSlotHashesKey        := nil;
  FInstructionsKey      := nil;
end;

end.

