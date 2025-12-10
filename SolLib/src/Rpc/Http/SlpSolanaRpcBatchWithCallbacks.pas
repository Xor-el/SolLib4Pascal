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

unit SlpSolanaRpcBatchWithCallbacks;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  SlpDataEncoders,
  SlpRpcModel,
  SlpRpcEnum,
  SlpSolanaRpcClient,
  SlpSolanaRpcBatchComposer,
  SlpRpcMessage,
  SlpConfigObject,
  SlpValueUtils,
  SlpNullable;

type
  /// <summary>
  /// This class is used to create a batch of RPC requests that can be executed as a single call to the RPC endpoint.
  /// Use of batches can have give a significant performance improvement instead of making multiple requests.
  /// The execution of batches can be controlled manually via the Flush method, or can be invoked automatically using auto-execute mode.
  /// Auto-execute mode is useful when iterating through large worksets.
  /// </summary>
  TSolanaRpcBatchWithCallbacks = class
  private
    FComposer: TSolanaRpcBatchComposer;
    function HandleCommitment(AValue: TCommitment; ADefault: TCommitment = TCommitment.Finalized): TKeyValue;
  public
    /// <summary>
    /// Constructs a new TSolanaRpcBatchWithCallbacks instance
    /// </summary>
    /// <param name="ARpcClient">A RPC client</param>
    constructor Create(const ARpcClient: IRpcClient);
    destructor Destroy; override;

    property Composer: TSolanaRpcBatchComposer read FComposer;

    /// <summary>
    /// Sets the auto execute mode and trigger threshold
    /// </summary>
    /// <param name="AMode">The auto execute mode to use.</param>
    /// <param name="ABatchSizeTrigger">The number of requests that will trigger a batch execution.</param>
    procedure AutoExecute(const AMode: TBatchAutoExecuteMode; const ABatchSizeTrigger: Integer);
    /// <summary>
    /// Used to execute any requests remaining in the batch.
    /// </summary>
    procedure Flush;

    /// <summary>
    /// Gets the balance for a certain public key.
    /// <remarks>
    /// The <c>ACommitment</c> parameter is optional, the default value <see cref="TCommitment.Finalized"/> is not sent.
    /// </remarks>
    /// </summary>
    /// <param name="APubKey">The public key.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <param name="ACallback">The callback to handle the result.</param>
    procedure GetBalance(const APubKey: string;
      ACommitment: TCommitment = TCommitment.Finalized;
      const ACallback: TProc<TResponseValue<UInt64>, Exception> = nil);

    /// <summary>
    /// Gets all SPL Token accounts by token owner.
    /// </summary>
    /// <param name="AOwnerPubKey">Public key of account owner query, as base-58 encoded string.</param>
    /// <param name="ATokenMintPubKey">Public key of the specific token Mint to limit accounts to, as base-58 encoded string.</param>
    /// <param name="ATokenProgramId">Public key of the Token program ID that owns the accounts, as base-58 encoded string.</param>
    /// <param name="AEncoding">The binary encoding.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <param name="ACallback">The callback to handle the result.</param>
    procedure GetTokenAccountsByOwner(const AOwnerPubKey: string;
      const ATokenMintPubKey: string = '';
      const ATokenProgramId: string = '';
      AEncoding: TBinaryEncoding = TBinaryEncoding.JsonParsed;
      ACommitment: TCommitment = TCommitment.Finalized;
      const ACallback: TProc<TResponseValue<TObjectList<TTokenAccount>>, Exception> = nil);

    /// <summary>
    /// Gets signatures with the given commitment for transactions involving the address.
    /// <remarks>
    /// Unless <c>searchTransactionHistory</c> is included, this method only searches the recent status cache of signatures.
    /// </remarks>
    /// </summary>
    /// <param name="AAccountPubKey">The account address as base-58 encoded string.</param>
    /// <param name="ALimit">Maximum transaction signatures to return, between 1-1000. Default is 1000.</param>
    /// <param name="ABefore">Start searching backwards from this transaction signature.</param>
    /// <param name="AUntil">Search until this transaction signature, if found before limit is reached.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <param name="ACallback">The callback to handle the result.</param>
    procedure GetSignaturesForAddress(const AAccountPubKey: string;
      const ALimit: UInt64 = 1000;
      const ABefore: string = '';
      const AUntil: string = '';
      ACommitment: TCommitment = TCommitment.Finalized;
      const ACallback: TProc<TObjectList<TSignatureStatusInfo>, Exception> = nil);

    /// <summary>
    /// Returns all accounts owned by the provided program Pubkey.
    /// <remarks>Accounts must meet all filter criteria to be included in the results.</remarks>
    /// </summary>
    /// <param name="APubKey">The program public key.</param>
    /// <param name="ADataSize">The data size of the account to compare against the program account data.</param>
    /// <param name="AMemCmpList">The list of comparisons to match against the program account data.</param>
    /// <param name="AEncoding">The binary encoding.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <param name="ACallback">The callback to handle the result.</param>
    procedure GetProgramAccounts(const AProgramPubKey: string;
      const ADataSize: TNullable<Integer>;
      const AMemCmpList: TArray<TMemCmp> = nil;
      AEncoding: TBinaryEncoding = TBinaryEncoding.Base64;
      ACommitment: TCommitment = TCommitment.Finalized;
      const ACallback: TProc<TObjectList<TAccountKeyPair>, Exception> = nil);

    /// <summary>
    /// Returns transaction details for a confirmed transaction.
    /// <remarks>
    /// <para>
    /// The <c>ACommitment</c> parameter is optional, <see cref="TCommitment.Processed"/> is not supported,
    /// the default value <see cref="TCommitment.Finalized"/> is not sent.
    /// </para>
    /// </remarks>
    /// </summary>
    /// <param name="ASignature">Transaction signature as base-58 encoded string.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <param name="ACallback">The callback to handle the result.</param>
    procedure GetTransaction(const ASignature: string;
      ACommitment: TCommitment = TCommitment.Finalized;
      const ACallback: TProc<TTransactionMetaSlotInfo, Exception> = nil);

    /// <summary>
    /// Gets the account info.
    /// <remarks>
    /// The <c>ACommitment</c> parameter is optional, the default value <see cref="TCommitment.Finalized"/> is not sent.
    /// </remarks>
    /// </summary>
    /// <param name="APubKey">The account public key.</param>
    /// <param name="AEncoding">The encoding of the account data.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <param name="ACallback">The callback to handle the result.</param>
    procedure GetAccountInfo(const APubKey: string;
      AEncoding: TBinaryEncoding = TBinaryEncoding.Base64;
      ACommitment: TCommitment = TCommitment.Finalized;
      const ACallback: TProc<TResponseValue<TAccountInfo>, Exception> = nil);

    /// <summary>
    /// Gets the token mint info. This method only works if the target account is a SPL token mint.
    /// <remarks>
    /// The <c>ACommitment</c> parameter is optional, the default value <see cref="TCommitment.Finalized"/> is not sent.
    /// </remarks>
    /// </summary>
    /// <param name="APubKey">The token mint public key.</param>
    /// <param name="AEncoding">The encoding of the account data.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <param name="ACallback">The callback to handle the result.</param>
    procedure GetTokenMintInfo(const APubKey: string;
      AEncoding: TBinaryEncoding = TBinaryEncoding.JsonParsed;
      ACommitment: TCommitment = TCommitment.Finalized;
      const ACallback: TProc<TResponseValue<TTokenMintInfo>, Exception> = nil);

    /// <summary>
    /// Gets the 20 largest token accounts of a particular SPL Token.
    /// </summary>
    /// <param name="ATokenMintPubKey">Public key of Token Mint to query, as base-58 encoded string.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <param name="ACallback">The callback to handle the result.</param>
    procedure GetTokenLargestAccounts(const ATokenMintPubKey: string;
      ACommitment: TCommitment = TCommitment.Finalized;
      const ACallback: TProc<TResponseValue<TObjectList<TLargeTokenAccount>>, Exception> = nil);

    /// <summary>
    /// Sends a transaction.
    /// </summary>
    /// <param name="ATransaction">The signed transaction as byte array.</param>
    /// <param name="AMaxRetries">The maximum number of times for the RPC node to retry sending the transaction to the leader. If this parameter not provided, the RPC node will retry the transaction until it is finalized or until the blockhash expires.</param>
    /// <param name="AMinContextSlot">The minimum slot at which to perform preflight transaction checks.</param>
    /// <param name="ASkipPreflight">If true skip the preflight transaction checks (default false).</param>
    /// <param name="AEncoding">The binary encoding.</param>
    /// <param name="APreflightCommitment">The block commitment used to retrieve block hashes and verify success.</param>
    /// <param name="ACallback">The callback to handle the result.</param>
    procedure SendTransaction(const ATransaction: TBytes;
      const AMaxRetries: TNullable<UInt32>;
      const AMinContextSlot: TNullable<UInt64>;
      ASkipPreflight: Boolean = False;
      AEncoding: TBinaryEncoding = TBinaryEncoding.Base64;
      APreflightCommitment: TCommitment = TCommitment.Finalized;
      const ACallback: TProc<string, Exception> = nil); overload;

    /// <summary>
    /// Sends a transaction.
    /// </summary>
    /// <param name="ATransaction">The signed transaction as base-64 encoded string.</param>
    /// <param name="AMaxRetries">The maximum number of times for the RPC node to retry sending the transaction to the leader. If this parameter not provided, the RPC node will retry the transaction until it is finalized or until the blockhash expires.</param>
    /// <param name="AMinContextSlot">The minimum slot at which to perform preflight transaction checks.</param>
    /// <param name="ASkipPreflight">If true skip the prflight transaction checks (default false).</param>
    /// <param name="AEncoding">The binary encoding.</param>
    /// <param name="APreflightCommitment">The block commitment used for preflight.</param>
    /// <param name="ACallback">The callback to handle the result.</param>
    procedure SendTransaction(const ATransaction: string;
      const AMaxRetries: TNullable<UInt32>;
      const AMinContextSlot: TNullable<UInt64>;
      ASkipPreflight: Boolean = False;
      AEncoding: TBinaryEncoding = TBinaryEncoding.Base64;
      APreflightCommitment: TCommitment = TCommitment.Finalized;
      const ACallback: TProc<string, Exception> = nil); overload;

    /// <summary>
    /// Gets the account info for multiple accounts.
    /// </summary>
    /// <param name="AAccounts">The list of the accounts public keys.</param>
    /// <param name="AEncoding">The binary encoding.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <param name="ACallback">The callback to handle the result.</param>
    procedure GetMultipleAccounts(const AAccounts: TArray<string>;
      AEncoding: TBinaryEncoding = TBinaryEncoding.Base64;
      ACommitment: TCommitment = TCommitment.Finalized;
      const ACallback: TProc<TResponseValue<TObjectList<TAccountInfo>>, Exception> = nil);

    /// <summary>
    /// Gets the token account info.
    /// <remarks>
    /// The <c>ACommitment</c> parameter is optional, the default value <see cref="TCommitment.Finalized"/> is not sent.
    /// </remarks>
    /// </summary>
    /// <param name="APubKey">The token account public key.</param>
    /// <param name="AEncoding">The binary encoding.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <param name="ACallback">The callback to handle the result.</param>
    procedure GetTokenAccountInfo(const APubKey: string;
      AEncoding: TBinaryEncoding = TBinaryEncoding.JsonParsed;
      ACommitment: TCommitment = TCommitment.Finalized;
      const ACallback: TProc<TResponseValue<TTokenAccountInfo>, Exception> = nil);
  end;

implementation

{ TSolanaRpcBatchWithCallbacks }

constructor TSolanaRpcBatchWithCallbacks.Create(const ARpcClient: IRpcClient);
begin
  inherited Create;
  if ARpcClient = nil then
    raise EArgumentNilException.Create('ARpcClient');
  FComposer := TSolanaRpcBatchComposer.Create(ARpcClient);
end;

destructor TSolanaRpcBatchWithCallbacks.Destroy;
begin
  if Assigned(FComposer) then
    FComposer.Free;
  inherited;
end;

function TSolanaRpcBatchWithCallbacks.HandleCommitment(
  AValue: TCommitment;
  ADefault: TCommitment): TKeyValue;
begin
  if AValue <> ADefault then
    Result := TKeyValue.Make('commitment', TValue.From<TCommitment>(AValue))
  else
    Result := Default(TKeyValue);
end;

procedure TSolanaRpcBatchWithCallbacks.AutoExecute(const AMode: TBatchAutoExecuteMode; const ABatchSizeTrigger: Integer);
begin
  FComposer.AutoExecute(AMode, ABatchSizeTrigger);
end;

procedure TSolanaRpcBatchWithCallbacks.Flush;
begin
  if FComposer.Count > 0 then
    FComposer.Flush;
end;

procedure TSolanaRpcBatchWithCallbacks.GetBalance(const APubKey: string;
  ACommitment: TCommitment;
  const ACallback: TProc<TResponseValue<UInt64>, Exception>);
var
  LParams: TList<TValue>;
begin
  LParams := TParameters.Make(
    TValue.From<string>(APubKey),
    TConfigObject.Make(
      HandleCommitment(ACommitment)
    )
  );

  FComposer.AddRequest<TResponseValue<UInt64>>('getBalance', LParams, ACallback);
end;

procedure TSolanaRpcBatchWithCallbacks.GetTokenAccountsByOwner(
  const AOwnerPubKey, ATokenMintPubKey, ATokenProgramId: string;
  AEncoding: TBinaryEncoding;
  ACommitment: TCommitment;
  const ACallback: TProc<TResponseValue<TObjectList<TTokenAccount>>, Exception>);
var
  LParams: TList<TValue>;
begin
  if (ATokenMintPubKey.Trim = '') and (ATokenProgramId.Trim = '') then
    raise EArgumentException.Create('either tokenProgramId or tokenMintPubKey must be set');

  LParams := TParameters.Make(
    TValue.From<string>(AOwnerPubKey),
    TConfigObject.Make(
      TKeyValue.Make('mint', TValue.From<string>(ATokenMintPubKey)),
      TKeyValue.Make('programId', TValue.From<string>(ATokenProgramId))
    ),
    TConfigObject.Make(
      HandleCommitment(ACommitment),
      TKeyValue.Make('encoding', TValue.From<TBinaryEncoding>(AEncoding))
    )
  );

  FComposer.AddRequest<TResponseValue<TObjectList<TTokenAccount>>>('getTokenAccountsByOwner', LParams, ACallback);
end;

procedure TSolanaRpcBatchWithCallbacks.GetSignaturesForAddress(
  const AAccountPubKey: string; const ALimit: UInt64; const ABefore, AUntil: string;
  ACommitment: TCommitment;
  const ACallback: TProc<TObjectList<TSignatureStatusInfo>, Exception>);
var
  LParams: TList<TValue>;
  LLimit, LBefore, LUntil: TValue;
begin
  if ACommitment = TCommitment.Processed then
    raise EArgumentException.Create('Commitment.Processed is not supported for this method.');

  LLimit := TValue.Empty;
  if ALimit <> 1000 then
    LLimit := TValue.From<UInt64>(ALimit);

  LBefore := TValue.Empty;
  if ABefore <> '' then
    LBefore := TValue.From<string>(ABefore);

  LUntil := TValue.Empty;
  if AUntil <> '' then
    LUntil := TValue.From<string>(AUntil);

  LParams := TParameters.Make(
    TValue.From<string>(AAccountPubKey),
    TConfigObject.Make(
      TKeyValue.Make('limit',  LLimit),
      TKeyValue.Make('before', LBefore),
      TKeyValue.Make('until',  LUntil),
      HandleCommitment(ACommitment)
    )
  );

  FComposer.AddRequest<TObjectList<TSignatureStatusInfo>>('getSignaturesForAddress', LParams, ACallback);
end;

procedure TSolanaRpcBatchWithCallbacks.GetProgramAccounts(const AProgramPubKey: string;
  const ADataSize: TNullable<Integer>; const AMemCmpList: TArray<TMemCmp>;
  AEncoding: TBinaryEncoding;
  ACommitment: TCommitment;
  const ACallback: TProc<TObjectList<TAccountKeyPair>, Exception>);
var
  LParams: TList<TValue>;
  LFilters: TArray<TValue>;
  I: Integer;
begin
  SetLength(LFilters, 0);

  LFilters := LFilters + [TConfigObject.Make(
    TKeyValue.Make('dataSize', TValue.From<TNullable<Integer>>(ADataSize))
  )];

  if (AMemCmpList <> nil) and (Length(AMemCmpList) > 0) then
  begin
    for I := 0 to Length(AMemCmpList) - 1 do
    begin
      LFilters := LFilters + [ TConfigObject.Make(
        TKeyValue.Make('memcmp',
          TConfigObject.Make(
            TKeyValue.Make('offset', TValue.From<Integer>(AMemCmpList[I].Offset)),
            TKeyValue.Make('bytes',  TValue.From<string>(AMemCmpList[I].Bytes))
          )
        )
      ) ];
    end;
  end;

  if Length(LFilters) > 0 then
  begin
    LParams := TParameters.Make(
      TValue.From<string>(AProgramPubKey),
      TConfigObject.Make(
        TKeyValue.Make('encoding', TValue.From<TBinaryEncoding>(AEncoding)),
        TKeyValue.Make('filters',  TValue.From<TArray<TValue>>(LFilters)),
        HandleCommitment(ACommitment)
      )
    );
  end
  else
  begin
    LParams := TParameters.Make(
      TValue.From<string>(AProgramPubKey),
      TConfigObject.Make(
        TKeyValue.Make('encoding', TValue.From<TBinaryEncoding>(AEncoding)),
        HandleCommitment(ACommitment)
      )
    );
  end;

  FComposer.AddRequest<TObjectList<TAccountKeyPair>>('getProgramAccounts', LParams, ACallback);
end;

procedure TSolanaRpcBatchWithCallbacks.GetTransaction(const ASignature: string;
  ACommitment: TCommitment;
  const ACallback: TProc<TTransactionMetaSlotInfo, Exception>);
var
  LParams: TList<TValue>;
begin
  LParams := TParameters.Make(
    TValue.From<string>(ASignature),
    TConfigObject.Make(
      TKeyValue.Make('encoding', TValue.From<TBinaryEncoding>(TBinaryEncoding.Json)),
      HandleCommitment(ACommitment)
    )
  );

  FComposer.AddRequest<TTransactionMetaSlotInfo>('getTransaction', LParams, ACallback);
end;

procedure TSolanaRpcBatchWithCallbacks.GetAccountInfo(const APubKey: string;
  AEncoding: TBinaryEncoding;
  ACommitment: TCommitment;
  const ACallback: TProc<TResponseValue<TAccountInfo>, Exception>);
var
  LParams: TList<TValue>;
begin
  LParams := TParameters.Make(
    TValue.From<string>(APubKey),
    TConfigObject.Make(
      TKeyValue.Make('encoding', TValue.From<TBinaryEncoding>(AEncoding)),
      HandleCommitment(ACommitment)
    )
  );

  FComposer.AddRequest<TResponseValue<TAccountInfo>>('getAccountInfo', LParams, ACallback);
end;

procedure TSolanaRpcBatchWithCallbacks.GetTokenMintInfo(const APubKey: string;
  AEncoding: TBinaryEncoding;
  ACommitment: TCommitment;
  const ACallback: TProc<TResponseValue<TTokenMintInfo>, Exception>);
var
  LParams: TList<TValue>;
begin
  LParams := TParameters.Make(
    TValue.From<string>(APubKey),
    TConfigObject.Make(
      TKeyValue.Make('encoding', TValue.From<TBinaryEncoding>(AEncoding)),
      HandleCommitment(ACommitment)
    )
  );
  FComposer.AddRequest<TResponseValue<TTokenMintInfo>>('getAccountInfo', LParams, ACallback);
end;

procedure TSolanaRpcBatchWithCallbacks.GetTokenLargestAccounts(
  const ATokenMintPubKey: string;
  ACommitment: TCommitment;
  const ACallback: TProc<TResponseValue<TObjectList<TLargeTokenAccount>>, Exception>);
var
  LParams: TList<TValue>;
begin
  LParams := TParameters.Make(
    TValue.From<string>(ATokenMintPubKey),
    TConfigObject.Make(
      HandleCommitment(ACommitment)
    )
  );
  FComposer.AddRequest<TResponseValue<TObjectList<TLargeTokenAccount>>>('getTokenLargestAccounts', LParams, ACallback);
end;

procedure TSolanaRpcBatchWithCallbacks.SendTransaction(const ATransaction: TBytes;
  const AMaxRetries: TNullable<UInt32>;
  const AMinContextSlot: TNullable<UInt64>;
  ASkipPreflight: Boolean;
  AEncoding: TBinaryEncoding;
  APreflightCommitment: TCommitment;
  const ACallback: TProc<string, Exception>);
var
  LEncoded: string;
begin
  case AEncoding of
    TBinaryEncoding.Base58:
      LEncoded := TEncoders.Base58.EncodeData(ATransaction);

    TBinaryEncoding.Base64:
      LEncoded := TEncoders.Base64.EncodeData(ATransaction);
  else
    raise EArgumentException.CreateFmt(
      'SendTransaction only supports Base58 or Base64 encoding. Unsupported encoding: %s',
      [GetEnumName(TypeInfo(TBinaryEncoding), Ord(AEncoding))]
    );
  end;

  SendTransaction(LEncoded, AMaxRetries, AMinContextSlot, ASkipPreflight, AEncoding, APreflightCommitment, ACallback);
end;

procedure TSolanaRpcBatchWithCallbacks.SendTransaction(
  const ATransaction: string;
  const AMaxRetries: TNullable<UInt32>;
  const AMinContextSlot: TNullable<UInt64>;
  ASkipPreflight: Boolean;
  AEncoding: TBinaryEncoding;
  APreflightCommitment: TCommitment;
  const ACallback: TProc<string, Exception>);
var
  LParams: TList<TValue>;
  LSkip, LPreflight, LMaxRetries, LMinContextSlot: TValue;
begin
  if ASkipPreflight then
    LSkip := TValue.From<Boolean>(True)
  else
    LSkip := TValue.Empty;

  if APreflightCommitment = TCommitment.Finalized then
    LPreflight := TValue.Empty
  else
    LPreflight := TValue.From<TCommitment>(APreflightCommitment);

  if AMaxRetries.HasValue then
    LMaxRetries := TValue.From<UInt32>(AMaxRetries.Value)
  else
    LMaxRetries := TValue.Empty;

  if AMinContextSlot.HasValue then
    LMinContextSlot := TValue.From<UInt64>(AMinContextSlot.Value)
  else
    LMinContextSlot := TValue.Empty;

    LParams := TParameters.Make(
      TValue.From<string>(ATransaction),
      TConfigObject.Make(
        TKeyValue.Make('skipPreflight',         LSkip),
        TKeyValue.Make('maxRetries',         LMaxRetries),
        TKeyValue.Make('minContextSlot',         LMinContextSlot),
        TKeyValue.Make('preflightCommitment',   LPreflight),
        TKeyValue.Make('encoding',              TValue.From<TBinaryEncoding>(AEncoding))
      )
    );

  FComposer.AddRequest<string>('sendTransaction', LParams, ACallback);
end;

procedure TSolanaRpcBatchWithCallbacks.GetMultipleAccounts(const AAccounts: TArray<string>;
  AEncoding: TBinaryEncoding;
  ACommitment: TCommitment;
  const ACallback: TProc<TResponseValue<TObjectList<TAccountInfo>>, Exception>);
var
  LParams: TList<TValue>;
begin
  LParams := TParameters.Make(
    TValue.From<TArray<string>>(AAccounts),
    TConfigObject.Make(
      TKeyValue.Make('encoding', TValue.From<TBinaryEncoding>(AEncoding)),
      HandleCommitment(ACommitment)
    )
  );

  FComposer.AddRequest<TResponseValue<TObjectList<TAccountInfo>>>('getMultipleAccounts', LParams, ACallback);
end;

procedure TSolanaRpcBatchWithCallbacks.GetTokenAccountInfo(const APubKey: string;
  AEncoding: TBinaryEncoding;
  ACommitment: TCommitment;
  const ACallback: TProc<TResponseValue<TTokenAccountInfo>, Exception>);
var
  LParams: TList<TValue>;
begin
  LParams := TParameters.Make(
    TValue.From<string>(APubKey),
    TConfigObject.Make(
      TKeyValue.Make('encoding', TValue.From<TBinaryEncoding>(AEncoding)),
      HandleCommitment(ACommitment)
    )
  );

  FComposer.AddRequest<TResponseValue<TTokenAccountInfo>>('getAccountInfo', LParams, ACallback);
end;

end.

