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

unit SlpTokenWallet;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections,
  System.Generics.Defaults,
  SlpPublicKey,
  SlpRpcModel,
  SlpRpcEnum,
  SlpRequestResult,
  SlpRpcMessage,
  SlpSolanaRpcClient,
  SlpSolanaRpcBatchWithCallbacks,
  SlpSolLibExceptions,
  SlpTokenDomain,
  SlpTokenWalletRpcProxy,
  SlpTokenMintResolver,
  SlpSolConverter,
  SlpTransactionBuilder,
  SlpListUtils,
  SlpNullable,
  SlpTokenProgram,
  SlpAssociatedTokenAccountProgram;

type
  ITokenWalletLoadCtx = interface
  ['{C08C7B9A-A5C3-4E64-9F2E-0D3B2C05F5F7}']

    function  Lock: TCriticalSection;
    function  Gate: TEvent;

    procedure IncSuccess;
    procedure IncFail;
    function  Success: Integer;
    function  Fail: Integer;

    procedure SetLamports(const V: UInt64);
    function  Lamports: UInt64;

    procedure AdoptAccounts(const L: TObjectList<TTokenAccount>);
    function  Accounts: TObjectList<TTokenAccount>;

    function  PublicKey: string;
    function  MintResolver: ITokenMintResolver;

    procedure WrapUp;          // call after each callback finishes
    procedure MarkInvoked;     // mark when thunk starts
  end;


type
  TTokenWalletLoadCtx = class sealed(TInterfacedObject, ITokenWalletLoadCtx)
  private
    FLock        : TCriticalSection;
    FGate        : TEvent;
    FSuccess     : Integer;
    FFail        : Integer;
    FLamports    : UInt64;
    FAccounts    : TObjectList<TTokenAccount>;
    FMintResolver: ITokenMintResolver;
    FPublicKey   : string;
    FCompleted   : Boolean;
    FInvoked     : Boolean;
  private

    function  Lock: TCriticalSection;
    function  Gate: TEvent;

    procedure IncSuccess;
    procedure IncFail;
    function  Success: Integer;
    function  Fail: Integer;

    procedure SetLamports(const V: UInt64);
    function  Lamports: UInt64;

    procedure AdoptAccounts(const L: TObjectList<TTokenAccount>);
    function  Accounts: TObjectList<TTokenAccount>;

    function  PublicKey: string;
    function  MintResolver: ITokenMintResolver;

    procedure WrapUp;
    procedure MarkInvoked;

  public
    constructor Create(const APublicKey: string; const AMintResolver: ITokenMintResolver);
    destructor Destroy; override;
  end;

  ITokenWallet = interface
    ['{28A6BEA7-C05F-48C8-80EF-DC270A38E954}']

    function GetSol: Double;
    function GetLamports: UInt64;
    function GetPublicKey: IPublicKey;

        /// <summary>
    /// Refresh balances and token accounts.
    /// </summary>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    procedure Refresh(ACommitment: TCommitment = TCommitment.Finalized);

    /// <summary>
    /// Get consolidated token balances across all sub-accounts for each token mint in this wallet.
    /// </summary>
    /// <returns>A list of TokenWalletBalance objects, one per token mint in this wallet.</returns>
    function Balances: TList<ITokenWalletBalance>;

    /// <summary>
    /// Returns a TokenWalletFilterList of sub-accounts in this wallet address.
    /// <para>Use the filter methods ForToken, WithSymbol, WithAtLeast, WithMint, AssociatedTokenAccount
    /// to select the sub-account you want to use.</para>
    /// </summary>
    function TokenAccounts: ITokenWalletFilterList;

    /// <summary>
    /// Send tokens from source to target wallet Associated Token Account for the token mint.
    /// </summary>
    /// <para>
    /// The <c>ASource</c> parameter is a TokenWalletAccount instance that tokens will be sent from.
    /// They will be deposited into an Associated Token Account in the destination wallet.
    /// If an Associated Token Account does not exist, it will be created at the cost of feePayer.
    /// </para>
    /// <param name="ASource">Source account of tokens to be sent.</param>
    /// <param name="AAmount">Human readable amount of tokens to send.</param>
    /// <param name="ADestination">Destination wallet address.</param>
    /// <param name="AFeePayer">PublicKey of the fee payer address.</param>
    /// <param name="ASignTxCallback">Callback used to sign the TransactionBuilder.</param>
    /// <returns>The RPC request result containing the submitted transaction signature.</returns>
    function Send(const ASource: ITokenWalletAccount; const AAmount: Double;
                  const ADestination: string; const AFeePayer: IPublicKey;
                  const ASignTxCallback: TFunc<ITransactionBuilder, TBytes>): TRequestResult<string>; overload;

    /// <summary>
    /// Send tokens from source to target wallet Associated Token Account for the token mint.
    /// If an ATA does not exist for the destination, it will be created at the cost of feePayer.
    /// </summary>
    /// <param name="ASource">Source account of tokens to be sent.</param>
    /// <param name="AAmount">Human-readable amount of tokens to send.</param>
    /// <param name="ADestination">Destination wallet address.</param>
    /// <param name="AFeePayer">PublicKey of the fee payer address.</param>
    /// <param name="ASignTxCallback">Callback used to sign the TransactionBuilder.</param>
    /// <returns>The RPC request result containing the submitted transaction signature.</returns>
    function Send(const ASource: ITokenWalletAccount; const AAmount: Double;
                  const ADestination: IPublicKey; const AFeePayer: IPublicKey;
                  const ASignTxCallback: TFunc<ITransactionBuilder, TBytes>): TRequestResult<string>; overload;

    /// <summary>
    /// Checks for a target Associated Token Account for the given mint and prepares one if not found.
    /// </summary>
    /// <para>
    /// Use this method to conditionally create a target Associated Token Account in this wallet as part of your own builder.
    /// </para>
    /// <param name="ABuilder">The TransactionBuilder create account logic will be added to if required.</param>
    /// <param name="AMint">The public key of the mint for the Associated Token Account.</param>
    /// <param name="AFeePayer">The account that will fund the account creation if required.</param>
    /// <returns>The public key of the Associated Token Account that will be created.</returns>
    function JitCreateAssociatedTokenAccount(const ABuilder: ITransactionBuilder;
                                             const AMint: string;
                                             const AFeePayer: IPublicKey): IPublicKey;

    /// <summary>Does a public key belong to a subaccount of this wallet?</summary>
    function IsSubAccount(const APubKey: string): Boolean; overload;
    /// <summary>Does a public key belong to a subaccount of this wallet?</summary>
    function IsSubAccount(const APubKey: IPublicKey): Boolean; overload;

    property PublicKey: IPublicKey read GetPublicKey;
    /// <summary>Native SOL balance in lamports.</summary>
    property Lamports: UInt64 read GetLamports;
    /// <summary>Native SOL balance as decimal.</summary>
    property Sol: Double read GetSol;

  end;

  /// <summary>
  /// An object that represents the token wallet accounts that belong to a wallet address and methods to send tokens
  /// to other wallets whilst transparently handling the complexities of Associated Token Accounts.
  /// <para>Use Load method to get started and Send method to send tokens.</para>
  /// </summary>
  TTokenWallet = class(TInterfacedObject, ITokenWallet)
  private
    FRpcClient: ITokenWalletRpcProxy;
    FMintResolver: ITokenMintResolver;
    FPublicKey: IPublicKey;
    FAtaCache: TDictionary<string, IPublicKey>;
    FLamports: UInt64;
    FTokenAccounts: TObjectList<TTokenAccount>;

    function GetSol: Double;
    function GetLamports: UInt64;
    function GetPublicKey: IPublicKey;

    function GetAssociatedTokenAddressForMint(const AMint: string): IPublicKey;

    procedure Refresh(ACommitment: TCommitment = TCommitment.Finalized);

    function Balances: TList<ITokenWalletBalance>;

    function TokenAccounts: ITokenWalletFilterList;

    function Send(const ASource: ITokenWalletAccount; const AAmount: Double;
                  const ADestination: string; const AFeePayer: IPublicKey;
                  const ASignTxCallback: TFunc<ITransactionBuilder, TBytes>): TRequestResult<string>; overload;

    function Send(const ASource: ITokenWalletAccount; const AAmount: Double;
                  const ADestination: IPublicKey; const AFeePayer: IPublicKey;
                  const ASignTxCallback: TFunc<ITransactionBuilder, TBytes>): TRequestResult<string>; overload;


    function JitCreateAssociatedTokenAccount(const ABuilder: ITransactionBuilder;
                                             const AMint: string;
                                             const AFeePayer: IPublicKey): IPublicKey;

    function IsSubAccount(const APubKey: string): Boolean; overload;

    function IsSubAccount(const APubKey: IPublicKey): Boolean; overload;

    constructor Create(const AClient: ITokenWalletRpcProxy;
                       const AMintResolver: ITokenMintResolver;
                       const APublicKey: IPublicKey); overload;

    constructor Create(const AMintResolver: ITokenMintResolver;
                       const APublicKey: IPublicKey); overload;
  public

   destructor Destroy; override;

        /// <summary>
    /// Load a TokenWallet instance for a given public key.
    /// </summary>
    /// <param name="AClient">An instance of the RPC client.</param>
    /// <param name="AMintResolver">An instance of a mint resolver.</param>
    /// <param name="APublicKey">The account public key (base58 string).</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>An instance of TokenWallet loaded with the token accounts of the publicKey provided.</returns>
    class function Load(const AClient: IRpcClient;
                        const AMintResolver: ITokenMintResolver;
                        const APublicKey: string;
                        ACommitment: TCommitment = TCommitment.Finalized): ITokenWallet; overload;

    /// <summary>
    /// Load a TokenWallet instance for a given public key.
    /// </summary>
    /// <param name="AClient">An instance of the RPC client.</param>
    /// <param name="AMintResolver">An instance of a mint resolver.</param>
    /// <param name="APublicKey">The account public key.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>An instance of TokenWallet loaded with the token accounts of the publicKey provided.</returns>
    class function Load(const AClient: IRpcClient;
                        const AMintResolver: ITokenMintResolver;
                        const APublicKey: IPublicKey;
                        ACommitment: TCommitment = TCommitment.Finalized): ITokenWallet; overload;

    /// <summary>
    /// Load a TokenWallet instance for a given public key.
    /// </summary>
    /// <param name="Alient">An instance of the RPC client proxy.</param>
    /// <param name="AMintResolver">An instance of a mint resolver.</param>
    /// <param name="APublicKey">The account public key (base58 string).</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>An instance of TokenWallet loaded with the token accounts of the publicKey provided.</returns>
    class function Load(const AClient: ITokenWalletRpcProxy;
                        const AMintResolver: ITokenMintResolver;
                        const APublicKey: string;
                        ACommitment: TCommitment = TCommitment.Finalized): ITokenWallet; overload;

    /// <summary>
    /// Load a TokenWallet instance for a given public key.
    /// </summary>
    /// <param name="AClient">An instance of the RPC client proxy.</param>
    /// <param name="AMintResolver">An instance of a mint resolver.</param>
    /// <param name="APublicKey">The account public key.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>An instance of TokenWallet loaded with the token accounts of the publicKey provided.</returns>
    class function Load(const AClient: ITokenWalletRpcProxy;
                        const AMintResolver: ITokenMintResolver;
                        const APublicKey: IPublicKey;
                        ACommitment: TCommitment = TCommitment.Finalized): ITokenWallet; overload;

     /// <summary>
    /// Creates and loads a TokenWallet instance using an existing RPC batch call.
    /// Synchronous version: executes the batch and waits for both callbacks.
    /// </summary>
    /// <param name="ABatch">An instance of SolanaRpcBatchWithCallbacks</param>
    /// <param name="AMintResolver">An instance of a mint resolver.</param>
    /// <param name="APublicKey">The account public key.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>A func that materializes an instance of TokenWallet populated once the batch has executed.</returns>
    class function Load(const ABatch: TSolanaRpcBatchWithCallbacks;
                        const AMintResolver: ITokenMintResolver;
                        const APublicKey: IPublicKey;
                        ACommitment: TCommitment = TCommitment.Finalized): TFunc<ITokenWallet>; overload;

    /// <summary>
    /// Creates and loads a TokenWallet instance using an existing RPC batch call.
    /// Synchronous version: executes the batch and waits for both callbacks.
    /// </summary>
    /// <param name="ABatch">An instance of SolanaRpcBatchWithCallbacks</param>
    /// <param name="AMintResolver">An instance of a mint resolver.</param>
    /// <param name="APublicKey">The account public key (base58 string).</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>A func that materializes an instance of TokenWallet populated once the batch has executed.</returns>
    class function Load(const ABatch: TSolanaRpcBatchWithCallbacks;
                         const AMintResolver: ITokenMintResolver;
                        const APublicKey: string;
                        ACommitment: TCommitment = TCommitment.Finalized): TFunc<ITokenWallet>; overload;

  end;

implementation

{ TTokenWalletLoadCtx }

constructor TTokenWalletLoadCtx.Create(const APublicKey: string; const AMintResolver: ITokenMintResolver);
begin
  inherited Create;
  FLock  := TCriticalSection.Create;
  FGate  := TEvent.Create(nil, True, False, '');
  FAccounts := nil;
  FMintResolver := AMintResolver;
  FPublicKey := APublicKey;
end;

destructor TTokenWalletLoadCtx.Destroy;
begin
  if Assigned(FAccounts) then FAccounts.Free;
  if Assigned(FGate) then FGate.Free;
  if Assigned(FLock) then FLock.Free;
  FMintResolver := nil;
  FPublicKey := '';
  inherited;
end;

function TTokenWalletLoadCtx.Lock: TCriticalSection;
begin
 Result := FLock;
end;

function TTokenWalletLoadCtx.Gate: TEvent;
begin
 Result := FGate;
end;

procedure TTokenWalletLoadCtx.IncSuccess;
begin
 Inc(FSuccess);
end;

procedure TTokenWalletLoadCtx.IncFail;
begin
 Inc(FFail);
end;

function  TTokenWalletLoadCtx.Success: Integer;
begin
 Result := FSuccess;
end;

function  TTokenWalletLoadCtx.Fail: Integer;
begin
 Result := FFail;
end;

procedure TTokenWalletLoadCtx.SetLamports(const V: UInt64);
begin
 FLamports := V;
end;

function  TTokenWalletLoadCtx.Lamports: UInt64;
begin
 Result := FLamports;
end;

procedure TTokenWalletLoadCtx.AdoptAccounts(const L: TObjectList<TTokenAccount>);
begin
  FAccounts := L; // may be nil
end;

function  TTokenWalletLoadCtx.Accounts: TObjectList<TTokenAccount>;
begin
  Result := FAccounts;
end;

function  TTokenWalletLoadCtx.PublicKey: string;
begin
 Result := FPublicKey;
end;

function  TTokenWalletLoadCtx.MintResolver: ITokenMintResolver;
begin
 Result := FMintResolver;
end;

procedure TTokenWalletLoadCtx.WrapUp;
begin
  if (FSuccess = 2) or (FSuccess + FFail = 2) then
  begin
    FCompleted := True;
    if Assigned(FGate) then FGate.SetEvent;
  end;
end;

procedure TTokenWalletLoadCtx.MarkInvoked;
begin
  FInvoked := True;
end;

{ TTokenWallet }

constructor TTokenWallet.Create(const AClient: ITokenWalletRpcProxy;
                                const AMintResolver: ITokenMintResolver;
                                const APublicKey: IPublicKey);
begin
  if AClient = nil then raise EArgumentNilException.Create('AClient');
  if AMintResolver = nil then raise EArgumentNilException.Create('AMintResolver');
  if APublicKey = nil then raise EArgumentNilException.Create('APublicKey');

  inherited Create;
  FRpcClient := AClient;
  FMintResolver := AMintResolver;
  FPublicKey := APublicKey;
  FAtaCache := TDictionary<string, IPublicKey>.Create();
  FTokenAccounts := TObjectList<TTokenAccount>.Create(True);
end;

constructor TTokenWallet.Create(const AMintResolver: ITokenMintResolver;
                                const APublicKey: IPublicKey);
begin
  if AMintResolver = nil then raise EArgumentNilException.Create('AMintResolver');
  if APublicKey = nil then raise EArgumentNilException.Create('APublicKey');

  inherited Create;
  FMintResolver := AMintResolver;
  FPublicKey := APublicKey;
  FAtaCache := TDictionary<string, IPublicKey>.Create();
  FTokenAccounts := TObjectList<TTokenAccount>.Create(True);
end;

destructor TTokenWallet.Destroy;
begin
 if Assigned(FTokenAccounts) then
   FTokenAccounts.Free;
 if Assigned(FAtaCache) then
   FAtaCache.Free;
  inherited;
end;

function TTokenWallet.GetSol: Double;
begin
  Result := TSolConverter.ConvertToSol(FLamports);
end;

function TTokenWallet.GetLamports: UInt64;
begin
  Result := FLamports;
end;

function TTokenWallet.GetPublicKey: IPublicKey;
begin
  Result := FPublicKey;
end;

class function TTokenWallet.Load(const AClient: IRpcClient;
                                 const AMintResolver: ITokenMintResolver;
                                 const APublicKey: string;
                                 ACommitment: TCommitment): ITokenWallet;
var
 LTokenWalletRpcProxy: ITokenWalletRpcProxy;
 LPublicKey: IPublicKey;
begin
  if APublicKey = '' then
    raise EArgumentNilException.Create('APublicKey');
  LTokenWalletRpcProxy := TTokenWalletRpcProxy.Create(AClient);
  LPublicKey := TPublicKey.Create(APublicKey);
  Result := Load(LTokenWalletRpcProxy, AMintResolver, LPublicKey, ACommitment);
end;

class function TTokenWallet.Load(const AClient: IRpcClient;
                                 const AMintResolver: ITokenMintResolver;
                                 const APublicKey: IPublicKey;
                                 ACommitment: TCommitment): ITokenWallet;
var
 LTokenWalletRpcProxy: ITokenWalletRpcProxy;
begin
  LTokenWalletRpcProxy := TTokenWalletRpcProxy.Create(AClient);
  Result := Load(LTokenWalletRpcProxy, AMintResolver, APublicKey, ACommitment);
end;

class function TTokenWallet.Load(const AClient: ITokenWalletRpcProxy;
                                 const AMintResolver: ITokenMintResolver;
                                 const APublicKey: string;
                                 ACommitment: TCommitment): ITokenWallet;
var
 LPublicKey: IPublicKey;
begin
  if APublicKey = '' then
    raise EArgumentNilException.Create('APublicKey');
  LPublicKey := TPublicKey.Create(APublicKey);
  Result := Load(AClient, AMintResolver, LPublicKey, ACommitment);
end;

class function TTokenWallet.Load(const AClient: ITokenWalletRpcProxy;
                                 const AMintResolver: ITokenMintResolver;
                                 const APublicKey: IPublicKey;
                                 ACommitment: TCommitment): ITokenWallet;
begin
  if AClient = nil then raise EArgumentNilException.Create('AClient');
  if AMintResolver = nil then raise EArgumentNilException.Create('AMintResolver');
  if APublicKey = nil then raise EArgumentNilException.Create('APublicKey');

  if not APublicKey.IsOnCurve then
    raise EArgumentException.Create('PublicKey not valid - check this is native wallet address (not an ATA, PDA or aux account)');

  Result := TTokenWallet.Create(AClient, AMintResolver, APublicKey);
  Result.Refresh(ACommitment);
end;

class function TTokenWallet.Load(const ABatch: TSolanaRpcBatchWithCallbacks;
                                 const AMintResolver: ITokenMintResolver;
                                 const APublicKey: IPublicKey;
                                 ACommitment: TCommitment): TFunc<ITokenWallet>;
begin
  if APublicKey = nil then raise EArgumentNilException.Create('publicKey');
  if not APublicKey.IsOnCurve then
    raise EArgumentException.Create('APublicKey not valid - check this is native wallet address (not an ATA, PDA or aux account)');
  Result := Load(ABatch, AMintResolver, APublicKey.Key, ACommitment);
end;

class function TTokenWallet.Load(
  const ABatch: TSolanaRpcBatchWithCallbacks;
  const AMintResolver: ITokenMintResolver;
  const APublicKey: string;
  ACommitment: TCommitment
): TFunc<ITokenWallet>;
var
  Ctx: ITokenWalletLoadCtx;
begin
  if ABatch = nil then
    raise EArgumentNilException.Create('ABatch');
  if AMintResolver = nil then
    raise EArgumentNilException.Create('AMintResolver');
  if APublicKey = '' then
    raise EArgumentNilException.Create('APublicKey');

  Ctx := TTokenWalletLoadCtx.Create(APublicKey, AMintResolver);

  // === Enqueue: SOL balance ===
  ABatch.GetBalance(Ctx.PublicKey, ACommitment,
    procedure (AResp: TResponseValue<UInt64>; AErr: Exception)
    begin
      if Assigned(Ctx.Lock) then Ctx.Lock.Acquire;
      try
        if (AErr = nil) and (AResp <> nil) then
        begin
          Ctx.SetLamports(AResp.Value);
          Ctx.IncSuccess;
        end
        else
          Ctx.IncFail;
      finally
        if Assigned(Ctx.Lock) then Ctx.Lock.Release;
        Ctx.WrapUp;
      end;
    end);

  // === Enqueue: token accounts ===
  ABatch.GetTokenAccountsByOwner(Ctx.PublicKey, '', TTokenProgram.ProgramIdKey.Key, ACommitment,
    procedure (AResp: TResponseValue<TObjectList<TTokenAccount>>; AErr: Exception)
    begin
      if Assigned(Ctx.Lock) then Ctx.Lock.Acquire;
      try
        if (AErr = nil) and (AResp <> nil) then
        begin
          Ctx.AdoptAccounts(AResp.Value);
          AResp.Value := nil; // prevent double free
          Ctx.IncSuccess;
        end
        else
          Ctx.IncFail;
      finally
        if Assigned(Ctx.Lock) then Ctx.Lock.Release;
        Ctx.WrapUp;
      end;
    end);

  // === Return thunk ===
  Result :=
    function: ITokenWallet
    var
      Wallet: TTokenWallet;
      PkObj : IPublicKey;
      Done  : Boolean;
    begin
      Ctx.MarkInvoked;

      // Optional wait:
      // if Assigned(Ctx.Gate) then Ctx.Gate.WaitFor(INFINITE);

      if Assigned(Ctx.Lock) then Ctx.Lock.Acquire;
      try
        Done := ((Ctx.Success + Ctx.Fail) = 2);
        if not Done then
          raise EInvalidOpException.Create('Batch not completed. Call after processing responses.');
        if Ctx.Success <> 2 then
          raise Exception.Create('Failed to load TokenWallet via batch.');
      finally
        if Assigned(Ctx.Lock) then Ctx.Lock.Release;
      end;

      PkObj  := TPublicKey.Create(Ctx.PublicKey);
      Wallet := TTokenWallet.Create(Ctx.MintResolver, PkObj);
      Wallet.FLamports      := Ctx.Lamports;
      Wallet.FTokenAccounts.Free;
      Wallet.FTokenAccounts := Ctx.Accounts;
      Ctx.AdoptAccounts(nil);

      Result := Wallet;
    end;
end;

procedure TTokenWallet.Refresh(ACommitment: TCommitment);
var
  LBalance: IRequestResult<TResponseValue<UInt64>>;
  LAccounts: IRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
begin
  LBalance := FRpcClient.GetBalance(FPublicKey.Key, ACommitment);
  LAccounts := FRpcClient.GetTokenAccountsByOwner(FPublicKey.Key, '', TTokenProgram.ProgramIdKey.Key, TBinaryEncoding.JsonParsed, ACommitment);

  if LBalance.WasSuccessful then
    FLamports := LBalance.Result.Value
  else
    raise ETokenWalletException<TResponseValue<UInt64>>.CreateFmt(
      'Could not load balance for %s: %s',
      [FPublicKey.ToString, LBalance.Reason]
    );

  if LAccounts.WasSuccessful then
  begin
    FTokenAccounts.Free;
    FTokenAccounts := LAccounts.Result.Value;
    LAccounts.Result.Value := nil;
  end
  else
    raise ETokenWalletException<TResponseValue<TObjectList<TTokenAccount>>>.CreateFmt(
      'Could not load tokenAccounts for %s: %s',
      [FPublicKey.ToString, LAccounts.Reason]
    );
end;

function TTokenWallet.Balances: TList<ITokenWalletBalance>;
var
  LMintBalances: TDictionary<string, ITokenWalletBalance>;
  LToken: TTokenAccount;
  LMint: string;
  LBal: ITokenWalletBalance;
  LTokenDef: ITokenDef;
  LDecimals: Integer;
  LTokenAccountData: TTokenAccountData;
begin
  LMintBalances := TDictionary<string, ITokenWalletBalance>.Create;
  try
    for LToken in FTokenAccounts do
    begin
      LTokenAccountData := LToken.Account.Data.AsType<TTokenAccountData>;
      LMint := LTokenAccountData.Parsed.Info.Mint;

      if not LMintBalances.TryGetValue(LMint, LBal) then
      begin
        LTokenDef := FMintResolver.Resolve(LMint);
        LDecimals := LTokenAccountData.Parsed.Info.TokenAmount.Decimals;
        if (LTokenDef.DecimalPlaces = -1) and (LDecimals >= 0) then
          LTokenDef := LTokenDef.CloneWithKnownDecimals(LDecimals);

        LBal := TTokenWalletBalance.Create(
          LTokenDef,
          LTokenAccountData.Parsed.Info.TokenAmount.AmountDouble,
          LTokenAccountData.Parsed.Info.TokenAmount.AmountUInt64,
          LToken.Account.Lamports,
          1
        );
        LMintBalances.Add(LMint, LBal);
      end
      else
      begin
        LBal := LBal.AddAccount(
          LTokenAccountData.Parsed.Info.TokenAmount.AmountDouble,
          LTokenAccountData.Parsed.Info.TokenAmount.AmountUInt64,
          LToken.Account.Lamports,
          1
        );
        LMintBalances[LMint] := LBal;
      end;
    end;

    Result := TList<ITokenWalletBalance>.Create();
    try
      for var Pair in LMintBalances do
        Result.Add(Pair.Value);

      Result.Sort(
        TComparer<ITokenWalletBalance>.Construct(
          function(const A, B: ITokenWalletBalance): Integer
          begin
            Result := CompareText(A.TokenName, B.TokenName);
          end));
    except
      Result.Free;
      raise;
    end;
  finally
    LMintBalances.Free;
  end;
end;

function TTokenWallet.TokenAccounts: ITokenWalletFilterList;
var
  LList: TList<ITokenWalletAccount>;
  LAcc: TTokenAccount;
  LMint: string;
  LAta: IPublicKey;
  LIsAta: Boolean;
  LLamportsRaw: UInt64;
  LOwner: string;
  LDecimals: Integer;
  LBalRaw: UInt64;
  LBalDouble: Double;
  LTokenDef: ITokenDef;
  LTokenWalletAccount: ITokenWalletAccount;
  LTokenAccountData: TTokenAccountData;
begin
  LList := TList<ITokenWalletAccount>.Create();
  try
    for LAcc in FTokenAccounts do
    begin
      LTokenAccountData := LAcc.Account.Data.AsType<TTokenAccountData>;
      LMint := LTokenAccountData.Parsed.Info.Mint;
      LAta := GetAssociatedTokenAddressForMint(LMint);
      LIsAta := SameStr(LAta.Key, LAcc.PublicKey);
      LLamportsRaw := LAcc.Account.Lamports;

      if LTokenAccountData.Parsed.Info.Owner <> '' then
        LOwner := LTokenAccountData.Parsed.Info.Owner
      else
        LOwner := FPublicKey.Key;

      LDecimals := LTokenAccountData.Parsed.Info.TokenAmount.Decimals;
      LBalRaw := LTokenAccountData.Parsed.Info.TokenAmount.AmountUInt64;
      LBalDouble := LTokenAccountData.Parsed.Info.TokenAmount.AmountDouble;

      LTokenDef := FMintResolver.Resolve(LMint);
      if (LTokenDef.DecimalPlaces = -1) and (LDecimals >= 0) then
        LTokenDef := LTokenDef.CloneWithKnownDecimals(LDecimals);

      LTokenWalletAccount := TTokenWalletAccount.Create(LTokenDef, LBalDouble, LBalRaw, LLamportsRaw,
                                   LAcc.PublicKey, LOwner, LIsAta);

      LList.Add(LTokenWalletAccount);
    end;

    LList.Sort(
      TComparer<ITokenWalletAccount>.Construct(
        function (const A, B: ITokenWalletAccount): Integer
        begin
          Result := CompareText(A.TokenName, B.TokenName);
        end));

    Result := TTokenWalletFilterList.Create(LList.ToArray);
  finally
    LList.Free;
  end;
end;

function TTokenWallet.Send(const ASource: ITokenWalletAccount; const AAmount: Double;
                           const ADestination: string; const AFeePayer: IPublicKey;
                           const ASignTxCallback: TFunc<ITransactionBuilder, TBytes>): TRequestResult<string>;
var
 LPublicKey: IPublicKey;
begin
  LPublicKey := TPublicKey.Create(ADestination);
  Result := Send(ASource, AAmount, LPublicKey, AFeePayer, ASignTxCallback);
end;

function TTokenWallet.Send(const ASource: ITokenWalletAccount; const AAmount: Double;
                           const ADestination: IPublicKey; const AFeePayer: IPublicKey;
                           const ASignTxCallback: TFunc<ITransactionBuilder, TBytes>): TRequestResult<string>;
var
  LTxB: ITransactionBuilder;
  LBlockHash: IRequestResult<TResponseValue<TLatestBlockHash>>;
  LDestWallet: ITokenWallet;
  LTargetAta: IPublicKey;
  LTokenDef: ITokenDef;
  LQtyRaw: UInt64;
  LTx: TBytes;
  LPublicKey: IPublicKey;
begin
  if ASource = nil then
    raise EArgumentNilException.Create('ASource');
  if ADestination = nil then
    raise EArgumentNilException.Create('ADestination');
  if AFeePayer = nil then
    raise EArgumentNilException.Create('AFeePayer');
  if not Assigned(ASignTxCallback) then
    raise EArgumentNilException.Create('ASignTxCallback');

  if not ADestination.IsOnCurve then
    raise EArgumentException.CreateFmt('Destination PublicKey %s is invalid wallet address.', [ADestination.Key]);
  if not AFeePayer.IsOnCurve then
    raise EArgumentException.CreateFmt('AFeePayer PublicKey %s is invalid wallet address.', [AFeePayer.Key]);

  if not SameStr(ASource.Owner, FPublicKey.Key) then
    raise EArgumentException.Create('Source account does not belong to this wallet.');

  LDestWallet := Load(FRpcClient, FMintResolver, ADestination, TCommitment.Finalized);
  LBlockHash := FRpcClient.GetLatestBlockHash;

  LTxB := TTransactionBuilder.Create;
  LTxB.SetRecentBlockHash(LBlockHash.Result.Value.Blockhash)
       .SetFeePayer(AFeePayer);

  // Ensure target ATA
  LTargetAta := LDestWallet.JitCreateAssociatedTokenAccount(LTxB, ASource.TokenMint, AFeePayer);

  // Amount -> raw
  LTokenDef := FMintResolver.Resolve(ASource.TokenMint);
  LQtyRaw := LTokenDef.ConvertDoubleToUInt64(AAmount);

  // Transfer instruction
  LPublicKey := TPublicKey.Create(ASource.PublicKey);
  LTxB.AddInstruction(
    TTokenProgram.Transfer(LPublicKey, LTargetAta, LQtyRaw, FPublicKey));

  // Sign
  LTx := ASignTxCallback(LTxB);
  if Length(LTx) = 0 then
    raise EArgumentException.Create('Result from signTxCallback was empty');

  Result := FRpcClient.SendTransaction(LTx, TNullable<UInt32>.None, TNullable<UInt64>.None);
end;

function TTokenWallet.JitCreateAssociatedTokenAccount(const ABuilder: ITransactionBuilder;
                                                      const AMint: string;
                                                      const AFeePayer: IPublicKey): IPublicKey;
var
  LTargets: ITokenWalletFilterList;
  LPublicKey: IPublicKey;
begin
  if ABuilder = nil then
    raise EArgumentNilException.Create('builder');
  if AMint = '' then
    raise EArgumentNilException.Create('mint');
  if AFeePayer = nil then
    raise EArgumentNilException.Create('feePayer');
  if not AFeePayer.IsOnCurve then
    raise EArgumentException.CreateFmt('feePayer PublicKey %s is invalid wallet address.', [AFeePayer.ToString]);

  // Find ATA for this mint
  LTargets := TokenAccounts.WithMint(AMint).WhichAreAssociatedTokenAccounts;

  if LTargets.Count = 0 then
  begin
    // Derive ATA
    Result := GetAssociatedTokenAddressForMint(AMint);

    // Create if missing
    LPublicKey := TPublicKey.Create(AMint);
    ABuilder.AddInstruction(
      TAssociatedTokenAccountProgram.CreateAssociatedTokenAccount(
        AFeePayer, FPublicKey, LPublicKey));
  end
  else
  begin
    // Reuse existing ATA
    Result := TPublicKey.Create(LTargets.First.PublicKey);
  end;
end;

function TTokenWallet.GetAssociatedTokenAddressForMint(const AMint: string): IPublicKey;
var
 LPublicKey: IPublicKey;
begin
  if AMint = '' then
    raise EArgumentNilException.Create('AMint');

  if not FAtaCache.TryGetValue(AMint, Result) then
  begin
    // derive deterministic ATA (https://spl.solana.com/associated-token-account)
    LPublicKey := TPublicKey.Create(AMint);
    Result := TAssociatedTokenAccountProgram.DeriveAssociatedTokenAccount(FPublicKey, LPublicKey);
    FAtaCache.Add(AMint, Result);
  end;
end;

function TTokenWallet.IsSubAccount(const APubKey: string): Boolean;
begin
  if APubKey = '' then
    raise EArgumentNilException.Create('APubkey');

  Result := TListUtils.Any<TTokenAccount>(
    FTokenAccounts,
    function(TokenAcc: TTokenAccount): Boolean
    begin
      Result := SameStr(TokenAcc.PublicKey, APubKey);
    end
  );
end;

function TTokenWallet.IsSubAccount(const APubKey: IPublicKey): Boolean;
begin
  if APubKey = nil then raise EArgumentNilException.Create('pubkey');
  Result := IsSubAccount(APubKey.Key);
end;

end.

