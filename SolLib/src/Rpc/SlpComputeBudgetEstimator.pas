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

unit SlpComputeBudgetEstimator;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.StrUtils,
  System.Math,
  System.Generics.Collections,
  SlpRpcModel,
  SlpRequestResult,
  SlpRpcMessage,
  SlpSolanaRpcClient,
  SlpTransactionDomain,
  SlpComputeBudgetProgram,
  SlpNullable,
  SlpSolLibExceptions;

type
  /// <summary>
  /// Static helper for estimating <c>ComputeBudgetProgram.SetComputeUnitLimit</c> and
  /// <c>ComputeBudgetProgram.SetComputeUnitPrice</c> from a BUILT transaction (bytes)
  /// that represents your workload and does NOT yet include compute-budget
  /// instructions.
  /// https://solana.com/docs/core/fees
  /// https://solana.com/developers/cookbook/transactions/optimize-compute
  /// https://solana.com/developers/guides/advanced/how-to-optimize-compute
  /// https://solana.com/developers/cookbook/transactions/add-priority-fees
  /// </summary>
  TComputeBudgetEstimator = class sealed
  private
    class function ComputePriceFromAccountMinimums(
      const AFees: TArray<UInt64>;
      const AMaxRequiredFeeRatio: Double;
      const ADefaultMicroLamportsPerCu: UInt64
    ): UInt64; static;

    class function SimulateUnitsConsumed(
      const ARpc: IRpcClient;
      const ATxBytes: TBytes
    ): UInt64; static;

    class function FetchRecentPrioritizationFees(
      const ARpc: IRpcClient;
      const AHintAccounts: TArray<string>
    ): TArray<UInt64>; static;

        /// <summary>Round up <paramref name="AValue"/> to the nearest multiple of <paramref name="AStep"/>.</summary>
    class function RoundUpToStep(const AValue, AStep: UInt64): UInt64; static;

    /// <summary>
    /// Returns the element at percentile <paramref name="APercentile"/> (0..1) from <paramref name="AFees"/>.
    /// </summary>
    /// <remarks>
    /// Uses a simple order statistic: sort ascending, then take index <c>Round(P * High)</c>.
    /// Returns 0 if the input is empty.
    /// </remarks>
    class function PickPercentile(const AFees: TArray<UInt64>; const APercentile: Double): UInt64; static;

  public
    /// <summary>
    /// Builds priority-fee guidance for a draft transaction by:
    /// 1) simulating the transaction bytes to obtain <c>UnitsConsumed</c>,
    /// 2) computing the requested compute unit limit as <c>UnitsConsumed + ceil(UnitsConsumed * ASafetyMargin)</c>,
    /// 3) querying recent prioritization fees for the accounts you plan to lock and
    ///    pricing as <c>ceil(max(per-account minimums) * AMaxRequiredFeeRatio)</c>
    ///    (falling back to <paramref name="ADefaultMicroLamportsPerCu"/> if no usable samples are returned).
    /// Returns a class with the corresponding <c>SetComputeUnitLimit</c> and <c>SetComputeUnitPrice</c> instructions.
    /// </summary>
    /// <param name="ARpc">
    /// RPC client used to simulate the transaction and fetch recent prioritization fees.
    /// </param>
    /// <param name="ADraftTransactionBytes">
    /// The fully built transaction (as bytes) which <b>includes</b> the compute-budget instructions.
    /// This is simulated to determine <c>UnitsConsumed</c>.
    /// </param>
    /// <param name="AFeeHintAccounts">
    /// Base58 account addresses your transaction will lock. The fee endpoint returns a per-account minimum
    /// priority fee; the strict requirement to land is the <b>AMaxRequiredFeeRatio</b> of those minimums.
    /// </param>
    /// <param name="ASafetyMargin">
    /// Multiplier applied directly to the simulated <c>UnitsConsumed</c> to produce the requested limit:
    /// <c>ComputeUnitLimit = UnitsConsumed + ceil(UnitsConsumed * ASafetyMargin)</c>. Must be in the range <c>[0..1]</c>.
    /// For example, <c>0.10</c> = +10% of used units.
    /// </param>
    /// <param name="AMaxRequiredFeeRatio">
    /// Fraction in the range <c>[0..1]</c> applied to the strict requirement derived from the endpoint:
    /// <c>ComputeUnitPrice(µ-lamports/CU) = ceil( max(per-account minimums) * AMaxRequiredFeeRatio )</c>.
    /// Examples:
    /// <list type="bullet">
    /// <item><description><c>1.0</c> -> pay the strict maximum (safest "must-land").</description></item>
    /// <item><description><c>0.75</c> -> pay 75% of that maximum (e.g., max=6 -> price=ceil(6 * 0.75) = 5).</description></item>
    /// <item><description><c>0.5</c> -> pay 50% of that maximum (default if you choose so elsewhere).</description></item>
    /// </list>
    /// If the endpoint returns an empty set or only zeros, the function uses <paramref name="ADefaultMicroLamportsPerCu"/>.
    /// </param>
    /// <param name="ADefaultMicroLamportsPerCu">
    /// Fallback µ-lamports per compute unit used only when the fee RPC call succeeds but produces
    /// no usable (non-zero) samples.
    /// </param>
    /// <returns>
    /// An <c>IPriorityFeesInformation</c> containing:
    /// <list type="bullet">
    /// <item><description><c>TComputeBudgetProgram.SetComputeUnitLimit(ComputeUnitLimit)</c></description></item>
    /// <item><description><c>TComputeBudgetProgram.SetComputeUnitPrice(ComputeUnitPrice)</c></description></item>
    /// </list>
    /// ready to be inserted at the start of your transaction.
    /// </returns>
    /// <exception cref="EComputeBudgetEstimationError">
    /// Thrown when:
    /// <list type="bullet">
    /// <item><description><paramref name="ARpc"/> is <c>nil</c>.</description></item>
    /// <item><description><paramref name="ADraftTransactionBytes"/> is empty.</description></item>
    /// <item><description><paramref name="ASafetyMargin"/> &lt; 0.</description></item>
    /// <item><description>The simulation fails or does not return <c>UnitsConsumed</c>.</description></item>
    /// <item><description>The recent-fees RPC fails (network/server error).</description></item>
    /// </list>
    /// (Errors are propagated as <c>EComputeBudgetEstimationError</c>. )
    /// </exception>
    class function EstimatePriorityFeesInformation(
      const ARpc: IRpcClient;
      const ADraftTransactionBytes: TBytes;
      const AFeeHintAccounts: TArray<string> = nil;
      const ASafetyMargin: Double = 0.10;
      const AMaxRequiredFeeRatio: Double = 0.5;
      const ADefaultMicroLamportsPerCu: UInt64 = 800
    ): IPriorityFeesInformation; static;

    /// <summary>
    /// Builds priority-fee guidance for a draft transaction using a **percentile-based** recent-fee strategy.
    /// </summary>
    /// <remarks>
    /// Flow:
    /// <list type="number">
    ///   <item><description>Simulate <paramref name="ADraftTransactionBytes"/> (which should NOT contain compute-budget instructions) to obtain <c>UnitsConsumed</c>.</description></item>
    ///   <item><description>Compute requested compute-unit limit as <c>UnitsConsumed + ceil(UnitsConsumed * ASafetyMargin)</c>, then round up to <paramref name="AComputeUnitStep"/> and clamp to <paramref name="AMinComputeUnitLimit"/>..\<paramref name="AMaxComputeUnitLimit"/>.</description></item>
    ///   <item><description>Fetch recent prioritization fees and pick the <paramref name="APrioritizationPercentile"/> (e.g., 0.75 = P75). Multiply by <paramref name="AMaxRequiredFeeRatio"/>, ceil, and clamp to <paramref name="AMinPriceMicroLamportsPerCu"/>..\<paramref name="AMaxPriceMicroLamportsPerCu"/>. If no usable samples, fall back to <paramref name="ADefaultMicroLamportsPerCu"/>.</description></item>
    /// </list>
    /// Returns <see cref="IPriorityFeesInformation"/> with <c>SetComputeUnitLimit</c> and <c>SetComputeUnitPrice</c> ready to prepend to the transaction.
    /// </remarks>
    /// <param name="ARpc">RPC client used for simulation and recent-fee queries.</param>
    /// <param name="ADraftTransactionBytes">
    /// Fully built transaction bytes **without** compute-budget instructions. These bytes are simulated to measure <c>UnitsConsumed</c>.
    /// </param>
    /// <param name="AFeeHintAccounts">
    /// Base58 addresses your transaction will likely **write-lock** (fee endpoint uses them for per-account minimums). May be <c>nil</c>.
    /// </param>
    /// <param name="ASafetyMargin">Extra fraction in <c>[0..1]</c> added on top of used CUs (e.g., 0.10 = +10%).</param>
    /// <param name="APrioritizationPercentile">Percentile in <c>[0..1]</c> from recent fees (e.g., 0.75 for P75).</param>
    /// <param name="AMaxRequiredFeeRatio">
    /// Ratio in <c>[0..1]</c> applied to the chosen percentile to soften bidding (e.g., 0.5 = pay 50% of that percentile).
    /// </param>
    /// <param name="ADefaultMicroLamportsPerCu">Fallback µLamports/CU when fee samples are empty or all zero.</param>
    /// <param name="AMinComputeUnitLimit">Lower clamp for requested CU limit (e.g., 200000).</param>
    /// <param name="AMaxComputeUnitLimit">Upper clamp for requested CU limit (e.g., 1400000).</param>
    /// <param name="AComputeUnitStep">Round-up step for CU limit (e.g., 1000).</param>
    /// <param name="AMinPriceMicroLamportsPerCu">Lower clamp for µLamports/CU (e.g., 200).</param>
    /// <param name="AMaxPriceMicroLamportsPerCu">Upper clamp for µLamports/CU (e.g., 50000).</param>
    /// <exception cref="EComputeBudgetEstimationError">
    /// Thrown if RPC calls fail, arguments are invalid, or simulation does not produce <c>UnitsConsumed</c>.
    /// </exception>
    class function EstimatePriorityFeesInformationV2(
      const ARpc: IRpcClient;
      const ADraftTransactionBytes: TBytes;
      const AFeeHintAccounts: TArray<string> = nil;
      const ASafetyMargin: Double = 0.10;
      const APrioritizationPercentile: Double = 0.75;
      const AMaxRequiredFeeRatio: Double = 0.50;
      const ADefaultMicroLamportsPerCu: UInt64 = 800;
      const AMinComputeUnitLimit: UInt64 = 200000;
      const AMaxComputeUnitLimit: UInt64 = 1400000;
      const AComputeUnitStep: UInt64 = 1000;
      const AMinPriceMicroLamportsPerCu: UInt64 = 200;
      const AMaxPriceMicroLamportsPerCu: UInt64 = 50000
    ): IPriorityFeesInformation; static;
  end;

implementation

{ TComputeBudgetEstimator }

class function TComputeBudgetEstimator.ComputePriceFromAccountMinimums(
  const AFees: TArray<UInt64>;
  const AMaxRequiredFeeRatio: Double;
  const ADefaultMicroLamportsPerCu: UInt64
): UInt64;
var
  LMaxFee: UInt64;
  I: Integer;
begin
  // Assume caller validated AMaxRequiredFeeRatio between [0,1].
  LMaxFee := 0;

  if (AFees <> nil) and (Length(AFees) > 0) then
    for I := 0 to High(AFees) do
      if AFees[I] > LMaxFee then
        LMaxFee := AFees[I];

  if LMaxFee = 0 then
    // Empty or all zeros ? fallback
    Result := ADefaultMicroLamportsPerCu
  else
    // Pay ratio of the strict requirement (max of minimums). Ceil to avoid underbidding.
    Result := Ceil(LMaxFee * AMaxRequiredFeeRatio);
end;

class function TComputeBudgetEstimator.SimulateUnitsConsumed(
  const ARpc: IRpcClient; const ATxBytes: TBytes
): UInt64;
var
  LSim: IRequestResult<TResponseValue<TSimulationLogs>>;
begin
  LSim := ARpc.SimulateTransaction(ATxBytes);

  if (LSim = nil) or (not LSim.WasSuccessful) or
   (LSim.Result = nil) or (LSim.Result.Value = nil) then
    raise EComputeBudgetEstimationError.CreateFmt(
      'Simulation failed. Error: %s',
      [IfThen(LSim <> nil, LSim.Reason, 'unknown')]
    );

  if not LSim.Result.Value.UnitsConsumed.HasValue then
    raise EComputeBudgetEstimationError.Create('Simulation did not return UnitsConsumed.');

  Result := LSim.Result.Value.UnitsConsumed.Value;
end;

class function TComputeBudgetEstimator.FetchRecentPrioritizationFees(
  const ARpc: IRpcClient; const AHintAccounts: TArray<string>
): TArray<UInt64>;
var
  LFees: IRequestResult<TObjectList<TPrioritizationFeeItem>>;
  I: Integer;
begin
  LFees := ARpc.GetRecentPrioritizationFees(AHintAccounts);

  if (LFees = nil) or (not LFees.WasSuccessful) or (LFees.Result = nil) then
    raise EComputeBudgetEstimationError.CreateFmt(
      'getRecentPrioritizationFees failed. Error: %s',
      [IfThen(LFees <> nil, LFees.Reason, 'unknown')]
    );

  if (LFees.Result = nil) or (LFees.Result.Count = 0) then
    Exit(nil);

  SetLength(Result, LFees.Result.Count);
  for I := 0 to LFees.Result.Count - 1 do
    // guard against negative values (shouldn’t happen)
    Result[I] := Max(0, LFees.Result[I].PrioritizationFee);
end;

class function TComputeBudgetEstimator.RoundUpToStep(
  const AValue, AStep: UInt64): UInt64;
begin
  if AStep = 0 then
    Exit(AValue);
  Result := ((AValue + AStep - 1) div AStep) * AStep;
end;

class function TComputeBudgetEstimator.PickPercentile(
  const AFees: TArray<UInt64>; const APercentile: Double): UInt64;
var
  LSorted: TArray<UInt64>;
  LIdx: Integer;
begin
  Result := 0;
  if (Length(AFees) = 0) then
    Exit;

  LSorted := Copy(AFees);
  TArray.Sort<UInt64>(LSorted);

  // Map [0..1] to an index in [0..High]
  LIdx := EnsureRange(Round(APercentile * High(LSorted)), 0, High(LSorted));
  Result := LSorted[LIdx];
end;

class function TComputeBudgetEstimator.EstimatePriorityFeesInformation(
  const ARpc: IRpcClient;
  const ADraftTransactionBytes: TBytes;
  const AFeeHintAccounts: TArray<string>;
  const ASafetyMargin: Double;
  const AMaxRequiredFeeRatio: Double;
  const ADefaultMicroLamportsPerCu: UInt64
): IPriorityFeesInformation;
var
  LUnitsConsumed: UInt64;
  LComputeUnitLimit: UInt64;
  LComputeUnitPrice: UInt64;
  LFees: TArray<UInt64>;
begin
  if ARpc = nil then
    raise EComputeBudgetEstimationError.Create('RpcClient is nil.');
  if Length(ADraftTransactionBytes) = 0 then
    raise EComputeBudgetEstimationError.Create('Draft transaction bytes must be non-empty.');
  if (ASafetyMargin < 0) or (ASafetyMargin > 1) then
    raise EComputeBudgetEstimationError.Create('Safety margin must be in [0, 1].');
  if (AMaxRequiredFeeRatio < 0) or (AMaxRequiredFeeRatio > 1) then
    raise EComputeBudgetEstimationError.Create('AMaxRequiredFeeRatio must be in [0, 1].');

  // 1) Simulate — must succeed and expose UnitsConsumed
  LUnitsConsumed := SimulateUnitsConsumed(ARpc, ADraftTransactionBytes);

  // 2) Requested (billable) limit = used + ceil(used * safetyMargin)
  LComputeUnitLimit := LUnitsConsumed + UInt64(Ceil(LUnitsConsumed * ASafetyMargin));

  // 3) Fetch recent fees (throws if RPC failed)
  LFees := FetchRecentPrioritizationFees(ARpc, AFeeHintAccounts);

  // 4) Derive µ-lamports/CU from max(mins) * ratio (with fallback)
  LComputeUnitPrice := ComputePriceFromAccountMinimums(
    LFees,
    AMaxRequiredFeeRatio,
    ADefaultMicroLamportsPerCu
  );

  Result := TPriorityFeesInformation.Create(
    TComputeBudgetProgram.SetComputeUnitLimit(LComputeUnitLimit), // limit
    TComputeBudgetProgram.SetComputeUnitPrice(LComputeUnitPrice)  // price (micro-lamports)
  );
end;

class function TComputeBudgetEstimator.EstimatePriorityFeesInformationV2(
  const ARpc: IRpcClient;
  const ADraftTransactionBytes: TBytes;
  const AFeeHintAccounts: TArray<string>;
  const ASafetyMargin: Double;
  const APrioritizationPercentile: Double;
  const AMaxRequiredFeeRatio: Double;
  const ADefaultMicroLamportsPerCu: UInt64;
  const AMinComputeUnitLimit: UInt64;
  const AMaxComputeUnitLimit: UInt64;
  const AComputeUnitStep: UInt64;
  const AMinPriceMicroLamportsPerCu: UInt64;
  const AMaxPriceMicroLamportsPerCu: UInt64
): IPriorityFeesInformation;
var
  LUnitsConsumed     : UInt64;
  LComputeUnitLimit  : UInt64;
  LFees              : TArray<UInt64>;
  LPercentileValue   : UInt64;
  LComputeUnitPrice  : UInt64;
begin
  if ARpc = nil then
    raise EComputeBudgetEstimationError.Create('RpcClient is nil.');
  if Length(ADraftTransactionBytes) = 0 then
    raise EComputeBudgetEstimationError.Create('Draft transaction bytes must be non-empty.');
  if (ASafetyMargin < 0) or (ASafetyMargin > 1) then
    raise EComputeBudgetEstimationError.Create('ASafetyMargin must be in [0, 1].');
  if (APrioritizationPercentile < 0) or (APrioritizationPercentile > 1) then
    raise EComputeBudgetEstimationError.Create('APrioritizationPercentile must be in [0, 1].');
  if (AMaxRequiredFeeRatio < 0) or (AMaxRequiredFeeRatio > 1) then
    raise EComputeBudgetEstimationError.Create('AMaxRequiredFeeRatio must be in [0, 1].');
  if (AMinComputeUnitLimit > AMaxComputeUnitLimit) then
    raise EComputeBudgetEstimationError.Create('AMinComputeUnitLimit must be <= AMaxComputeUnitLimit.');
  if (AMinPriceMicroLamportsPerCu > AMaxPriceMicroLamportsPerCu) then
    raise EComputeBudgetEstimationError.Create('AMinPriceMicroLamportsPerCu must be <= AMaxPriceMicroLamportsPerCu.');

  // 1) Simulate to get used CUs (must succeed)
  LUnitsConsumed := SimulateUnitsConsumed(ARpc, ADraftTransactionBytes);

  // 2) Compute requested/billable CU limit with headroom
  LComputeUnitLimit := LUnitsConsumed + UInt64(Ceil(LUnitsConsumed * ASafetyMargin));
  LComputeUnitLimit := RoundUpToStep(LComputeUnitLimit, AComputeUnitStep);
  LComputeUnitLimit := EnsureRange(LComputeUnitLimit, AMinComputeUnitLimit, AMaxComputeUnitLimit);

  // 3) Fetch recent fees
  LFees := FetchRecentPrioritizationFees(ARpc, AFeeHintAccounts);

  // 4) Choose percentile, apply ratio, and clamp (fallback to default if no usable sample)
  if (Length(LFees) = 0) then
  begin
    LComputeUnitPrice := ADefaultMicroLamportsPerCu;
  end
  else
  begin
    LPercentileValue := PickPercentile(LFees, APrioritizationPercentile);
    if LPercentileValue = 0 then
      LComputeUnitPrice := ADefaultMicroLamportsPerCu
    else
      LComputeUnitPrice := Ceil(LPercentileValue * AMaxRequiredFeeRatio);
  end;

  LComputeUnitPrice := EnsureRange(LComputeUnitPrice, AMinPriceMicroLamportsPerCu, AMaxPriceMicroLamportsPerCu);

  // 5) Build the priority fee information
  Result := TPriorityFeesInformation.Create(
    TComputeBudgetProgram.SetComputeUnitLimit(LComputeUnitLimit),
    TComputeBudgetProgram.SetComputeUnitPrice(LComputeUnitPrice)
  );
end;

end.

