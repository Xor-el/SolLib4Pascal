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

unit SlpTokenWalletRpcProxy;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
  SlpNullable,
  SlpRpcEnum,
  SlpRpcModel,
  SlpRpcMessage,
  SlpRequestResult,
  SlpSolanaRpcClient;

type
  /// <summary>
  /// This interface contains the subset of methods from RPC client used by TokenWallet.
  /// </summary>
  ITokenWalletRpcProxy = interface
    ['{A14C1C2C-0D3B-4C8C-AC24-3E7A1C1F1F1A}']

    /// <summary>
    /// Gets the balance for a certain public key.
    /// <remarks>
    /// The <c>ACommitment</c> parameter is optional, the default value <see cref="TCommitment.Finalized"/> is not sent.
    /// </remarks>
    /// </summary>
    /// <param name="APubKey">The public key.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that holds the context and address balance.</returns>
    function GetBalance(const APubKey: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<UInt64>>;

    /// <summary>
    /// Gets all SPL Token accounts by token owner.
    /// </summary>
    /// <param name="AOwnerPubKey">Public key of account owner query, as base-58 encoded string.</param>
    /// <param name="ATokenMintPubKey">Public key of the specific token Mint to limit accounts to, as base-58 encoded string.</param>
    /// <param name="ATokenProgramId">Public key of the Token program ID that owns the accounts, as base-58 encoded string.</param>
    /// <param name="AEncoding">The binary encoding.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that holds the result and state.</returns>
    function GetTokenAccountsByOwner(const AOwnerPubKey: string; const ATokenMintPubKey: string = ''; const ATokenProgramId: string = ''; AEncoding: TBinaryEncoding = TBinaryEncoding.JsonParsed; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;

    /// <summary>
    /// Gets a recent block hash.
    /// </summary>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that holds the result and state.</returns>
    function GetLatestBlockHash(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TLatestBlockHash>>;

    /// <summary>
    /// Sends a transaction.
    /// </summary>
    /// <param name="ATransaction">The signed transaction as byte array.</param>
    /// <param name="AMaxRetries">The maximum number of times for the RPC node to retry sending the transaction to the leader. If this parameter not provided, the RPC node will retry the transaction until it is finalized or until the blockhash expires.</param>
    /// <param name="AMinContextSlot">The minimum slot at which to perform preflight transaction checks.</param>
    /// <param name="ASkipPreflight">If true skip the preflight transaction checks (default false).</param>
    /// <param name="APreFlightCommitment">The block commitment used for preflight.</param>
    /// <param name="AEncoding">The binary encoding.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function SendTransaction(const ATransaction: TBytes; const AMaxRetries: TNullable<UInt32>; const AMinContextSlot: TNullable<UInt64>; ASkipPreflight: Boolean = False; AEncoding: TBinaryEncoding = TBinaryEncoding.Base64; APreflightCommitment: TCommitment = TCommitment.Finalized): TRequestResult<string>;
  end;

  /// <summary>
  /// An internal RPC proxy that has everything required by TokenWallet.
  /// </summary>
  TTokenWalletRpcProxy = class(TInterfacedObject, ITokenWalletRpcProxy)
  private
    /// <summary>
    /// The RPC client to use.
    /// </summary>
    FClient: IRpcClient;
  public
    /// <summary>
    /// Constructs an instance of the TokenWalletRpcProxy.
    /// </summary>
    /// <param name="AClient"></param>
    constructor Create(const AClient: IRpcClient);

    /// <inheritdoc />
    function GetBalance(const APubKey: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<UInt64>>;

    /// <inheritdoc />
    function GetTokenAccountsByOwner(const AOwnerPubKey: string; const ATokenMintPubKey: string = ''; const ATokenProgramId: string = ''; AEncoding: TBinaryEncoding = TBinaryEncoding.JsonParsed; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;

    /// <inheritdoc />
    function GetLatestBlockHash(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TLatestBlockHash>>;

    /// <inheritdoc />
    function SendTransaction(const ATransaction: TBytes; const AMaxRetries: TNullable<UInt32>; const AMinContextSlot: TNullable<UInt64>; ASkipPreflight: Boolean = False; AEncoding: TBinaryEncoding = TBinaryEncoding.Base64; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<string>;
  end;

implementation

{ TTokenWalletRpcProxy }

constructor TTokenWalletRpcProxy.Create(const AClient: IRpcClient);
begin
  if not Assigned(AClient) then
    raise EArgumentNilException.Create('AClient');
  FClient := AClient;
end;

function TTokenWalletRpcProxy.GetBalance(const APubKey: string; ACommitment: TCommitment): TRequestResult<TResponseValue<UInt64>>;
begin
  Result := FClient.GetBalance(APubKey, ACommitment);
end;

function TTokenWalletRpcProxy.GetLatestBlockHash(ACommitment: TCommitment): TRequestResult<TResponseValue<TLatestBlockHash>>;
begin
  Result := FClient.GetLatestBlockHash(ACommitment);
end;

function TTokenWalletRpcProxy.GetTokenAccountsByOwner(const AOwnerPubKey, ATokenMintPubKey, ATokenProgramId: string; AEncoding: TBinaryEncoding; ACommitment: TCommitment): TRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
begin
  Result := FClient.GetTokenAccountsByOwner(AOwnerPubKey, ATokenMintPubKey, ATokenProgramId, AEncoding, ACommitment);
end;

function TTokenWalletRpcProxy.SendTransaction(const ATransaction: TBytes; const AMaxRetries: TNullable<UInt32>; const AMinContextSlot: TNullable<UInt64>; ASkipPreflight: Boolean; AEncoding: TBinaryEncoding; ACommitment: TCommitment): TRequestResult<string>;
begin
  Result := FClient.SendTransaction(ATransaction, AMaxRetries, AMinContextSlot, ASkipPreflight, AEncoding, ACommitment);
end;

end.

