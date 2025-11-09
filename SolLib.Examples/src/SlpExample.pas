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

unit SlpExample;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  SlpHttpApiClient,
  SlpDataEncoders,
  SlpValueHelpers,
  SlpInstructionDecoder,
  SlpMessageDomain,
  SlpAccountDomain,
  SlpTransactionDomain,
  SlpTransactionInstruction,
  SlpSolanaRpcClient,
  SlpPublicKey,
  SlpClientFactory,
  SlpRpcEnum,
  SlpRpcModel,
  SlpNullable,
  SlpRequestResult,
  SlpLogger,
  SlpConsoleLogger,
  SlpDecodedInstruction,
  SlpRpcMessage;

 type
  IExample = interface
    ['{8B6C7B7B-2C8A-4D5D-9B1E-9E3B8D6A1C21}']
    procedure Run;
  end;

  type
    TExpectedKeyPair = record
      Pub: string;
      Priv: string;
    end;

type
  TBaseExample = class abstract(TInterfacedObject, IExample)
  private

    class var FTestNetRpcClient, FMainNetRpcClient: IRpcClient;
    class var FLogger: ILogger;

    class constructor Create;
    class destructor Destroy;

    class function GetStringRepresentation(const AValue: TValue): string;

  protected
      // shared constants for indentation and formatting
    const
      TAB = #9;
      DOUBLETAB = TAB + TAB;
      TRIPLETAB = DOUBLETAB + TAB;
      QUADTAB = TRIPLETAB + TAB;
      NEWLINE = sLineBreak;

    class property Logger: ILogger read FLogger;

    class property TestNetRpcClient: IRpcClient read FTestNetRpcClient;
    class property MainNetRpcClient: IRpcClient read FMainNetRpcClient;

  public

    const
      MNEMONIC_WORDS =
        'route clerk disease box emerge airport loud waste attitude film army tray ' +
        'forward deal onion eight catalog surface unit card window walnut wealth medal';

    procedure Run; virtual; abstract;
    /// <summary>
    /// Pretty prints simulation logs (each line indented with two tabs + newline).
    /// </summary>
    class function PrettyPrintTransactionSimulationLogs(
      const ALogMessages: TArray<string>): string; static;

    /// <summary>
    /// Submits a transaction and logs output from SimulateTransaction.
    /// </summary>
    class function SimulateTxAndLog(const ATx: TBytes): Boolean; static;

    /// <summary>
    /// Submits a transaction and logs output from SimulateTransaction, then returns the signature.
    /// </summary>
    class function SubmitTxSendAndLog(const ATx: TBytes): string; static;

    /// <summary>
    /// Polls the rpc client until a transaction signature has been confirmed (simple success loop).
    /// </summary>
    class procedure PollConfirmedTx(const ASignature: string); static;

    /// <summary>
    /// Decodes a message from wire (binary) format and logs its contents. Returns the parsed message.
    /// </summary>
    class function DecodeMessageFromWire(const AMsgData: TBytes): IMessage; static;

    /// <summary>
    /// Decodes and logs the instructions in a message (using TInstructionDecoder).
    /// </summary>
    class procedure DecodeInstructionsFromMessageAndLog(const AMessage: IMessage); static;

    /// <summary>
    /// Decodes and logs all instructions (and CPIs) from a TransactionMetaInfo.
    /// </summary>
    class procedure DecodeInstructionsFromTransactionMetaInfoAndLog(const ATxMeta: TTransactionMetaInfo); static;


    /// <summary>
    /// Logs a transaction (signers, instructions) and returns its serialized bytes.
    /// </summary>
    class function LogTransactionAndSerialize(const ATx: ITransaction): TBytes; static;
  end;

implementation

{ TExampleHelpers }

class constructor TBaseExample.Create;
var
 LHttpClient: IHttpApiClient;
 LLoggerFactory: ILoggerFactory;
begin
  LHttpClient := THttpApiClient.Create();
  LLoggerFactory := TConsoleLoggerFactory.Create;
  FLogger := LLoggerFactory.CreateLogger('Examples');

  FTestNetRpcClient := TClientFactory.GetClient(TCluster.TestNet, LHttpClient, FLogger);
  FMainNetRpcClient := TClientFactory.GetClient(TCluster.MainNet, LHttpClient, FLogger);
end;

class destructor TBaseExample.Destroy;
begin
  FLogger := nil;
  FTestNetRpcClient := nil;
  FMainNetRpcClient := nil;
end;

class function TBaseExample.GetStringRepresentation(const AValue: TValue): string;
begin
  case AValue.Kind of
    tkDynArray:
      if AValue.IsType<TBytes> then
        Result := TEncoders.Base64.EncodeData(AValue.AsType<TBytes>)
      else
        Result := '<array>';
  else
    Result := AValue.ToStringExtended;
  end;
end;

class function TBaseExample.PrettyPrintTransactionSimulationLogs(
  const ALogMessages: TArray<string>): string;
var
  LBuilder: TStringBuilder;
  LLog: string;
begin
  LBuilder := TStringBuilder.Create;
  try
    for LLog in ALogMessages do
      LBuilder.AppendFormat('%s%s%s', [DOUBLETAB, LLog, NEWLINE]);
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

class function TBaseExample.SimulateTxAndLog(const ATx: TBytes): Boolean;
var
  LTxBase64, LLogs: string;
  LSim: IRequestResult<TResponseValue<TSimulationLogs>>;
begin
  Result := False;
  // log tx bytes in base64 for easy inspection
  LTxBase64 := TEncoders.Base64.EncodeData(ATx);
  Writeln(Format('Tx Data: %s', [LTxBase64]));

  // simulate
  LSim := FTestNetRpcClient.SimulateTransaction(ATx);
  if (LSim <> nil) and (LSim.Result <> nil) and (LSim.Result.Value <> nil) then
  begin
    LLogs := PrettyPrintTransactionSimulationLogs(LSim.Result.Value.Logs);

    Writeln(Format('Transaction Simulation:%s%sLogs:%s%s%s',
      [NEWLINE, TAB, NEWLINE, LLogs, NEWLINE]));

    if LSim.Result.Value.&Error <> nil then
    begin
      Writeln(Format('Transaction Simulation:%s%sError: %s',
        [NEWLINE, TAB, LSim.Result.Value.&Error.QualifiedClassName]));

      Result := True;
    end;
  end
  else
  begin
    Writeln('SimulateTransaction: (no result)');
  end;
end;

class function TBaseExample.SubmitTxSendAndLog(const ATx: TBytes): string;
var
  LSend: IRequestResult<string>;
  LHasError: Boolean;
begin

  LHasError := SimulateTxAndLog(ATx);
  if LHasError then
  begin
    Exit('');
  end;


  // send
  LSend := FTestNetRpcClient.SendTransaction(ATx, TNullable<UInt32>.None, TNullable<UInt64>.None);
  if (LSend <> nil) then
  begin
    Writeln(Format('Tx Signature: %s', [LSend.Result]));
    Result := LSend.Result;
  end
  else
  begin
    Writeln('Tx Signature: (no result)');
    Result := '';
  end;
end;

class procedure TBaseExample.PollConfirmedTx(const ASignature: string);
const
  TIMEOUT_MS = 60000; // 60 seconds
  POLL_INTERVAL_MS = 5000;
var
  LMeta: IRequestResult<TTransactionMetaSlotInfo>;
  LElapsed: Integer;
begin
  if ASignature = '' then
  begin
    Exit;
  end;

  LElapsed := 0;
  LMeta := FTestNetRpcClient.GetTransaction(ASignature);

  while ((LMeta = nil) or (not LMeta.WasSuccessful)) and (LElapsed < TIMEOUT_MS) do
  begin
    Sleep(POLL_INTERVAL_MS);
    Inc(LElapsed, POLL_INTERVAL_MS);
    LMeta := FTestNetRpcClient.GetTransaction(ASignature);
  end;

  if (LMeta = nil) or (not LMeta.WasSuccessful) then
    Writeln(Format('Unable to confirm transaction with signature %s after %d seconds.',
      [ASignature, TIMEOUT_MS div 1000]));
end;

class function TBaseExample.DecodeMessageFromWire(const AMsgData: TBytes): IMessage;
var
  LBase64: string;
  LMsg: IMessage;
  LKey: IPublicKey;
begin
  LBase64 := TEncoders.Base64.EncodeData(AMsgData);
  Writeln(Format('Message: %s', [LBase64]));

  LMsg := TMessage.Deserialize(LBase64);

  Writeln(Format('%s%sDECODING TRANSACTION FROM WIRE FORMAT%s%s',
    [NEWLINE, TAB, TAB, NEWLINE]));
  Writeln(Format('Message Header: %d %d %d',
    [LMsg.Header.RequiredSignatures,
     LMsg.Header.ReadOnlySignedAccounts,
     LMsg.Header.ReadOnlyUnsignedAccounts]));
  Writeln(Format('Message BlockHash/Nonce: %s', [LMsg.RecentBlockhash]));

  for LKey in LMsg.AccountKeys do
    Writeln(Format('Message Account: %s', [LKey.Key]));

  DecodeInstructionsFromMessageAndLog(LMsg);
  Result := LMsg;
end;

class procedure TBaseExample.DecodeInstructionsFromMessageAndLog(
  const AMessage: IMessage);
var
  LDecoded : TList<IDecodedInstruction>;
  LInst    : IDecodedInstruction;
  LPair    : TPair<string, TValue>;
  S        : string;

begin
  LDecoded := TInstructionDecoder.DecodeInstructions(AMessage);
  try
    S := 'Message Decoded Instructions:';
    for LInst in LDecoded do
    begin
      S := S + Format('%s%sProgram: %s%s%sInstruction: %s%s', [
        NEWLINE,
        TAB, LInst.ProgramName,
        NEWLINE,
        TRIPLETAB, LInst.InstructionName,
        NEWLINE
      ]);

      for LPair in LInst.Values do
        S := S + Format('%s%s - %s%s', [
          QUADTAB, LPair.Key, GetStringRepresentation(LPair.Value), NEWLINE
        ]);
    end;

    Writeln(S);
  finally
    LDecoded.Free;
  end;
end;

class procedure TBaseExample.DecodeInstructionsFromTransactionMetaInfoAndLog(
  const ATxMeta: TTransactionMetaInfo);
var
  LDecoded : TList<IDecodedInstruction>;
  LInst    : IDecodedInstruction;
  LInner   : IDecodedInstruction;
  LPair    : TPair<string, TValue>;
  S        : string;
begin
  LDecoded := TInstructionDecoder.DecodeInstructions(ATxMeta);
  try
    S := Format('%s%s', [TAB, 'Instructions']);

    for LInst in LDecoded do
    begin
      S := S + Format('%s%sProgram: %s%sKey: %s%s', [
        NEWLINE,
        TAB, LInst.ProgramName,
        TAB, LInst.PublicKey.Key,
        NEWLINE
      ]);
      S := S + Format('%s%sInstruction: %s%s', [
        NEWLINE, DOUBLETAB, LInst.InstructionName, NEWLINE
      ]);

      for LPair in LInst.Values do
        S := S + Format('%s%s - %s%s', [
          TRIPLETAB, LPair.Key, GetStringRepresentation(LPair.Value), NEWLINE
        ]);

      // Inner instructions block
      if LInst.InnerInstructions.Count > 0 then
      begin
        S := S + Format('%s%s', [DOUBLETAB, 'InnerInstructions']);

        for LInner in LInst.InnerInstructions do
        begin
          S := S + Format('%s%sCPI: %s%sKey: %s%s', [
            NEWLINE,
            DOUBLETAB, LInner.ProgramName,
            TAB, LInner.PublicKey.Key,
            NEWLINE
          ]);
          S := S + Format('%s%sInstruction: %s%s', [
            TRIPLETAB, LInner.InstructionName, NEWLINE
          ]);

          for LPair in LInner.Values do
            S := S + Format('%s%s - %s%s', [
              QUADTAB, LPair.Key, GetStringRepresentation(LPair.Value), NEWLINE
            ]);
        end;
      end;
    end;

    Writeln(S);
  finally
    LDecoded.Free;
  end;
end;

class function TBaseExample.LogTransactionAndSerialize(
  const ATx: ITransaction): TBytes;
var
  LPair: ISignaturePubKeyPair;
  LIns: ITransactionInstruction;
  LMeta: IAccountMeta;
  LProg, LSigB58: string;
begin
  Writeln(Format('Tx FeePayer:  %s', [ATx.FeePayer.Key]));
  Writeln(Format('Tx BlockHash/Nonce: %s', [ATx.RecentBlockHash]));

  // signatures
  for LPair in ATx.Signatures do
  begin
    if Length(LPair.Signature) > 0 then
      LSigB58 := TEncoders.Base58.EncodeData(LPair.Signature)
    else
      LSigB58 := '';
    Writeln(Format('Tx Signer: %s %sSignature: %s',
      [LPair.PublicKey.Key, TAB, LSigB58]));
  end;

  // instructions
  for LIns in ATx.Instructions do
  begin
    LProg := TEncoders.Base58.EncodeData(LIns.ProgramId);
    Writeln(Format('Tx ProgramKey: %s%s%sInstructionData: %s',
      [LProg, NEWLINE, TAB, TEncoders.Base64.EncodeData(LIns.Data)]));

    for LMeta in LIns.Keys do
    begin
      Writeln(Format('Tx %sAccountMeta: %s%sWritable: %s%sSigner: %s',
        [TAB, LMeta.PublicKey.Key,
         TAB, BoolToStr(LMeta.IsWritable, True),
         TAB, BoolToStr(LMeta.IsSigner, True)]));
    end;
  end;

  Result := ATx.Serialize;
end;

end.

