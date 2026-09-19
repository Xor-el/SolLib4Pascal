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

unit SlpTransactionConfig;

{$I ../Include/SolLib.inc}

interface

uses
  SlpNullable;

type
  /// <summary>
  /// Represents the in-message configuration options for a version 1 transaction
  /// (priority fee, compute unit limit, loaded accounts data size limit and heap size).
  /// </summary>
  TTransactionConfig = class
  private
    FPriorityFee: TNullable<UInt64>;
    FComputeUnitLimit: TNullable<UInt32>;
    FLoadedAccountsDataSizeLimit: TNullable<UInt32>;
    FHeapSize: TNullable<UInt32>;
  public
    /// <summary>The priority fee for the transaction.</summary>
    property PriorityFee: TNullable<UInt64> read FPriorityFee write FPriorityFee;
    /// <summary>The compute unit limit for the transaction.</summary>
    property ComputeUnitLimit: TNullable<UInt32> read FComputeUnitLimit write FComputeUnitLimit;
    /// <summary>The loaded accounts data size limit for the transaction.</summary>
    property LoadedAccountsDataSizeLimit: TNullable<UInt32> read FLoadedAccountsDataSizeLimit write FLoadedAccountsDataSizeLimit;
    /// <summary>The heap size for the transaction.</summary>
    property HeapSize: TNullable<UInt32> read FHeapSize write FHeapSize;

    /// <summary>The size, in bytes, of the config values that are set.</summary>
    function Size: Integer;

    /// <summary>Returns a copy of this configuration.</summary>
    function Clone: TTransactionConfig;
  end;

  /// <summary>
  /// A bit mask describing which <see cref="TTransactionConfig"/> options are present in a v1 message.
  /// </summary>
  TTransactionConfigMask = record
  public
  const
    /// <summary>Mask bits for the priority fee option.</summary>
    PriorityFee = $3;
    /// <summary>Mask bit for the compute unit limit option.</summary>
    ComputeUnitLimit = $4;
    /// <summary>Mask bit for the loaded accounts data size option.</summary>
    LoadedAccountsDataSize = $8;
    /// <summary>Mask bit for the heap size option.</summary>
    HeapSize = $10;
    /// <summary>Mask covering all known options.</summary>
    KnownBits = PriorityFee or ComputeUnitLimit or LoadedAccountsDataSize or HeapSize;
  private
    FValue: UInt32;
  public
    /// <summary>Initializes the mask with the given raw value.</summary>
    constructor Create(AValue: UInt32);

    /// <summary>Builds a mask describing the options set on <paramref name="AConfig"/>.</summary>
    class function FromConfig(const AConfig: TTransactionConfig): TTransactionConfigMask; static;

    /// <summary>True when the mask contains bits outside <see cref="KnownBits"/>.</summary>
    function HasUnknownBits: Boolean;
    /// <summary>True when the priority-fee bits are set to an invalid partial value.</summary>
    function HasInvalidPriorityFeeBits: Boolean;
    function HasPriorityFee: Boolean;
    function HasComputeUnitLimit: Boolean;
    function HasLoadedAccountsDataSize: Boolean;
    function HasHeapSize: Boolean;
    /// <summary>The size, in bytes, of the config values implied by the mask.</summary>
    function SizeOfConfig: Integer;

    /// <summary>The raw mask value.</summary>
    property Value: UInt32 read FValue;
  end;

implementation

{ TTransactionConfig }

function TTransactionConfig.Size: Integer;
begin
  Result := 0;
  if FPriorityFee.HasValue then
    Inc(Result, SizeOf(UInt64));
  if FComputeUnitLimit.HasValue then
    Inc(Result, SizeOf(UInt32));
  if FLoadedAccountsDataSizeLimit.HasValue then
    Inc(Result, SizeOf(UInt32));
  if FHeapSize.HasValue then
    Inc(Result, SizeOf(UInt32));
end;

function TTransactionConfig.Clone: TTransactionConfig;
begin
  Result := TTransactionConfig.Create;
  Result.FPriorityFee := FPriorityFee;
  Result.FComputeUnitLimit := FComputeUnitLimit;
  Result.FLoadedAccountsDataSizeLimit := FLoadedAccountsDataSizeLimit;
  Result.FHeapSize := FHeapSize;
end;

{ TTransactionConfigMask }

constructor TTransactionConfigMask.Create(AValue: UInt32);
begin
  FValue := AValue;
end;

class function TTransactionConfigMask.FromConfig(const AConfig: TTransactionConfig): TTransactionConfigMask;
var
  LMask: UInt32;
begin
  LMask := 0;
  if AConfig <> nil then
  begin
    if AConfig.PriorityFee.HasValue then
      LMask := LMask or PriorityFee;
    if AConfig.ComputeUnitLimit.HasValue then
      LMask := LMask or ComputeUnitLimit;
    if AConfig.LoadedAccountsDataSizeLimit.HasValue then
      LMask := LMask or LoadedAccountsDataSize;
    if AConfig.HeapSize.HasValue then
      LMask := LMask or HeapSize;
  end;
  Result := TTransactionConfigMask.Create(LMask);
end;

function TTransactionConfigMask.HasUnknownBits: Boolean;
begin
  Result := (FValue or UInt32(KnownBits)) <> UInt32(KnownBits);
end;

function TTransactionConfigMask.HasInvalidPriorityFeeBits: Boolean;
var
  LBits: UInt32;
begin
  LBits := FValue and PriorityFee;
  Result := (LBits <> 0) and (LBits <> PriorityFee);
end;

function TTransactionConfigMask.HasPriorityFee: Boolean;
begin
  Result := (FValue and PriorityFee) = PriorityFee;
end;

function TTransactionConfigMask.HasComputeUnitLimit: Boolean;
begin
  Result := (FValue and ComputeUnitLimit) <> 0;
end;

function TTransactionConfigMask.HasLoadedAccountsDataSize: Boolean;
begin
  Result := (FValue and LoadedAccountsDataSize) <> 0;
end;

function TTransactionConfigMask.HasHeapSize: Boolean;
begin
  Result := (FValue and HeapSize) <> 0;
end;

function TTransactionConfigMask.SizeOfConfig: Integer;
begin
  Result := 0;
  if HasPriorityFee then
    Inc(Result, SizeOf(UInt64));
  if HasComputeUnitLimit then
    Inc(Result, SizeOf(UInt32));
  if HasLoadedAccountsDataSize then
    Inc(Result, SizeOf(UInt32));
  if HasHeapSize then
    Inc(Result, SizeOf(UInt32));
end;

end.
