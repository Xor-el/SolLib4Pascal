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

unit SlpTokenMintHelper;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpAccount,
  SlpPublicKey,
  SlpTokenProgram,
  SlpSystemProgram,
  SlpRpcModel,
  SlpRequestResult,
  SlpRpcMessage,
  SlpTransactionBuilder,
  SlpSolanaRpcClient,
  SlpExample;

type
  /// <summary>
  /// Enumeration describing the result of mint initialization.
  /// </summary>
  TMintStatus = (Unknown, AlreadyExists, Created);

  /// <summary>
  /// Result of EnsureMintInitialized operation.
  /// </summary>
  TMintEnsureResult = record
    Status    : TMintStatus;
    Signature : string;
  end;

  /// <summary>
  /// Static helper to ensure that a mint exists and is initialized.
  /// </summary>
  TTokenMintHelper = class sealed
  public
    /// <summary>
    /// Ensures that a mint exists at the given public key.
    /// If the mint account is missing or uninitialized, it creates and initializes it.
    /// Returns a record describing the outcome.
    /// </summary>
    class function EnsureMintInitialized(
      const ARpc      : IRpcClient;
      const AAuthority: IAccount;
      const AMint     : IAccount;
      const ADecimals : Byte = 2
    ): TMintEnsureResult; static;
  end;

implementation

class function TTokenMintHelper.EnsureMintInitialized(
  const ARpc      : IRpcClient;
  const AAuthority: IAccount;
  const AMint     : IAccount;
  const ADecimals : Byte
): TMintEnsureResult;
var
  LInfo      : IRequestResult<TResponseValue<TAccountInfo>>;
  LBlock     : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LMinRent   : IRequestResult<UInt64>;
  LTxBuilder : ITransactionBuilder;
  LSigners   : TList<IAccount>;
  LTx        : TBytes;
begin
  Result.Status    := TMintStatus.Unknown;
  Result.Signature := '';

  try
    // 1. Check if mint already exists
    LInfo := ARpc.GetAccountInfo(AMint.PublicKey.Key);

    if (LInfo <> nil) and LInfo.WasSuccessful and
       (LInfo.Result <> nil) and (LInfo.Result.Value <> nil) and (LInfo.Result.Value.Owner = TTokenProgram.ProgramIdKey.Key) then
    begin
      Writeln('Mint already exists and is owned by Token Program: ' + AMint.PublicKey.Key);
      Result.Status := TMintStatus.AlreadyExists;
      Exit(Result);
    end;

    // 2. Create & initialize mint
    LMinRent := ARpc.GetMinimumBalanceForRentExemption(TTokenProgram.MintAccountDataSize);
    LBlock   := ARpc.GetLatestBlockHash;

    Writeln('Creating mint at: ' + AMint.PublicKey.Key);

    LTxBuilder := TTransactionBuilder.Create;
    LTxBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(AAuthority.PublicKey)
      .AddInstruction(
        TSystemProgram.CreateAccount(
          AAuthority.PublicKey,
          AMint.PublicKey,
          LMinRent.Result,
          TTokenProgram.MintAccountDataSize,
          TTokenProgram.ProgramIdKey
        )
      )
      .AddInstruction(
        TTokenProgram.InitializeMint(
          AMint.PublicKey,
          ADecimals,
          AAuthority.PublicKey,
          AAuthority.PublicKey
        )
      );

    LSigners := TList<IAccount>.Create;
    try
      LSigners.Add(AAuthority);
      LSigners.Add(AMint);
      LTx := LTxBuilder.Build(LSigners);
    finally
      LSigners.Free;
    end;

    Result.Signature := TBaseExample.SubmitTxSendAndLog(LTx);
    TBaseExample.PollConfirmedTx(Result.Signature);

    Result.Status := TMintStatus.Created;
    Writeln('Mint created and initialized successfully.');
  except
    on E: Exception do
    begin
      Writeln('Error ensuring mint: ' + E.Message);
      Result.Status := TMintStatus.Unknown;
    end;
  end;
end;

end.

