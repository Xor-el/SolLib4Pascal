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

unit InstructionDecoderExample;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  ExampleBase,
  SlpWallet,
  SlpAccount,
  SlpPublicKey,
  SlpSystemProgram,
  SlpMemoProgram,
  SlpRpcModel,
  SlpRpcMessage,
  SlpMessageDomain,
  SlpTransactionBuilder,
  SlpRequestResult,
  SlpIOUtilities;

type
  /// <summary>
  ///   Demonstrates building a transaction message and decoding its instructions.
  /// </summary>
  /// <remarks>
  ///   This example:
  ///   <list type="number">
  ///     <item>Creates a simple SOL transfer and memo transaction.</item>
  ///     <item>Compiles it into message bytes.</item>
  ///     <item>Decodes and prints the instructions from the compiled message.</item>
  ///   </list>
  /// </remarks>
  TInstructionDecoderFromMessageExample = class(TExampleBase)
  private
    const
      MnemonicWords = TExampleBase.MNEMONIC_WORDS;
  public
    procedure Run; override;
  end;

  TInstructionDecoderFromBlockExample = class(TExampleBase)
  public
    procedure Run; override;
  end;

implementation

{ TInstructionDecoderFromMessageExample }

procedure TInstructionDecoderFromMessageExample.Run;
var
  LWallet: IWallet;
  LFrom, LTo: IAccount;
  LBlockHash: IRequestResult<TResponseValue<TLatestBlockHash>>;
  LBuilder: ITransactionBuilder;
  LMsgBytes: TBytes;
begin
  // Initialize wallet and accounts
  LWallet := TWallet.Create(MnemonicWords);
  LFrom := LWallet.GetAccountByIndex(0);
  LTo := LWallet.GetAccountByIndex(8);

  // Fetch recent blockhash
  LBlockHash := TestNetRpcClient.GetLatestBlockHash;
  Writeln(Format('BlockHash >> %s', [LBlockHash.Result.Value.Blockhash]));

  // Build and compile transaction message
  LBuilder := TTransactionBuilder.Create;
  LMsgBytes :=
    LBuilder
      .SetRecentBlockHash(LBlockHash.Result.Value.Blockhash)
      .SetFeePayer(LFrom.PublicKey)
      .AddInstruction(
        TSystemProgram.Transfer(LFrom.PublicKey, LTo.PublicKey, 10000000)
      )
      .AddInstruction(
        TMemoProgram.NewMemo(LFrom.PublicKey, 'Hello from SolLib :)')
      )
      .CompileMessage;

  // Decode instructions from the compiled message
  DecodeMessageFromWire(LMsgBytes);
end;

{ TInstructionDecoderFromBlockExample }

procedure TInstructionDecoderFromBlockExample.Run;
const
  SLOTS: array[0..1] of UInt64 = (366321180, 366321183);
  VOTE_PROGRAM = 'Vote111111111111111111111111111111111111111';
var
  LSlot: UInt64;
  LBlock: IRequestResult<TBlockInfo>;
  LTxMeta: TTransactionMetaInfo;
  LTxInfo: TTransactionInfo;
  LMsg: TTransactionContentInfo;
  LInsCount, LProgIdx: Integer;
  LProgKey: string;
begin
  for LSlot in SLOTS do
  begin
    LBlock := TestNetRpcClient.GetBlock(LSlot);

    if (LBlock = nil) or (not LBlock.WasSuccessful) or (LBlock.Result = nil) then
    begin
      Writeln(Format('Failed to fetch block %d', [LSlot]));
      Continue;
    end;

    // write raw JSON to ./response<slot>.json (if available)
    if LBlock.RawRpcResponse <> '' then
      TIOUtilities.WriteAllText(Format('./response%d.json', [LSlot]), LBlock.RawRpcResponse);

    Writeln(Format('BlockHash >> %s', [LBlock.Result.Blockhash]));
    Writeln(Format('%s%sDECODING INSTRUCTIONS FROM TRANSACTIONS IN BLOCK %s%s',
      [NEWLINE, DOUBLETAB, LBlock.Result.Blockhash, NEWLINE]));

    for LTxMeta in LBlock.Result.Transactions do
    begin
      // inspect raw message
      LTxInfo := LTxMeta.Transaction.AsType<TTransactionInfo>;
      if LTxInfo = nil then
        Continue;

      LMsg := LTxInfo.Message;
      if LMsg = nil then
        Continue;

      LInsCount := LMsg.Instructions.Count;

      // skip pure vote tx: single instruction and its program is vote program
      if (LInsCount = 1) then
      begin
        LProgIdx := LMsg.Instructions[0].ProgramIdIndex;
        if (LProgIdx >= 0) and (LProgIdx < Length(LMsg.AccountKeys)) then
        begin
          LProgKey := LMsg.AccountKeys[LProgIdx];
          if SameStr(LProgKey, VOTE_PROGRAM) then
            Continue;
        end;
      end;

      // skip if fewer than 2 instructions
      if LInsCount < 2 then
        Continue;

      // log signature and instruction counts
      if Length(LTxInfo.Signatures) > 0 then
        Writeln(Format('%s%sDECODING INSTRUCTIONS FROM TRANSACTION %s',
          [NEWLINE, DOUBLETAB, LTxInfo.Signatures[0]]));

      Writeln(Format('Instructions: %d', [LInsCount]));
      if (LTxMeta.Meta <> nil) and (LTxMeta.Meta.InnerInstructions <> nil) then
        Writeln(Format('InnerInstructions: %d', [LTxMeta.Meta.InnerInstructions.Count])
        )
      else
        Writeln('InnerInstructions: 0');

      DecodeInstructionsFromTransactionMetaInfoAndLog(LTxMeta);
    end;
  end;
end;

end.

