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

unit SlpSolanaRpcClient;

{$I ..\..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.Generics.Collections,
  System.Json.Serializers,
{$IFDEF FPC}
  URIParser,
{$ELSE}
  System.Net.URLClient,
{$ENDIF}
  SlpDataEncoders,
  SlpRpcModel,
  SlpRpcEnum,
  SlpRpcMessage,
  SlpRequestResult,
  SlpConfigObject,
  SlpJsonRpcClient,
  SlpIdGenerator,
  SlpHttpApiClient,
  SlpRateLimiter,
  SlpNullable,
  SlpValueUtils,
  SlpLogger,
  SlpJsonKit,
  SlpEncodingConverter,
  SlpJsonStringEnumConverter,
  SlpJsonConverterFactory;

type
  /// <summary>
  /// Specifies the methods to interact with the JSON RPC API.
  /// </summary>
  IRpcClient = interface
    ['{0C9C3B04-1CC6-4E6D-8B63-3A06B6C3C34A}']
    /// <summary>
    /// The address this client connects to.
    /// </summary>
    function GetNodeAddress: TURI;
    property NodeAddress: TURI read GetNodeAddress;

    /// <summary>
    /// Generates the next unique id for the request.
    /// </summary>
    /// <returns>The id.</returns>
    function GetNextIdForReq(): Integer;

    /// <summary>
    /// Low-level method to send a batch of JSON RPC requests
    /// </summary>
    /// <param name="AReqs"></param>
    /// <returns></returns>
    function SendBatchRequest(const AReqs: TJsonRpcBatchRequest): TRequestResult<TJsonRpcBatchResponse>;

    /// <summary>
    /// Gets the token mint info. This method only works if the target account is a SPL token mint.
    /// <remarks>
    /// The <c>ACommitment</c> parameter is optional, the default value Commitment.Finalized is not sent.
    /// </remarks>
    /// </summary>
    /// <param name="APubKey">The token mint public key.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetTokenMintInfo(const APubKey: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TTokenMintInfo>>;

    /// <summary>
    /// Gets the token account info.
    /// <remarks>
    /// The <c>ACommitment</c> parameter is optional, the default value Commitment.Finalized is not sent.
    /// </remarks>
    /// </summary>
    /// <param name="APubKey">The token account public key.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetTokenAccountInfo(const APubKey: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TTokenAccountInfo>>;

    /// <summary>
    /// Gets the account info.
    /// <remarks>
    /// The <c>ACommitment</c> parameter is optional, the default value Commitment.Finalized is not sent.
    /// </remarks>
    /// </summary>
    /// <param name="APubKey">The account public key.</param>
    /// <param name="AEncoding">The encoding of the account data.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetAccountInfo(const APubKey: string; AEncoding: TBinaryEncoding = TBinaryEncoding.Base64; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TAccountInfo>>;

    /// <summary>
    /// Gets the balance for a certain public key.
    /// <remarks>
    /// The <c>ACommitment</c> parameter is optional, the default value Commitment.Finalized is not sent.
    /// </remarks>
    /// </summary>
    /// <param name="APubKey">The public key.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetBalance(const APubKey: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<UInt64>>;

    /// <summary>
    /// Returns identity and transaction information about a block in the ledger.
    /// <remarks>
    /// <para>
    /// The <c>ACommitment</c> parameter is optional, Commitment.Processed is not supported,
    /// the default value Commitment.Finalized is not sent.
    /// </para>
    /// <para>
    /// The <c>ATransactionDetails</c> parameter is optional, the default value TransactionDetailsFilterType.Full is not sent.
    /// </para>
    /// <para>
    /// The <c>ABlockRewards</c> parameter is optional, the default value, <c>false</c>, is not sent.
    /// </para>
    /// </remarks>
    /// </summary>
    /// <param name="ASlot">The slot.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <param name="ATransactionDetails">The level of transaction detail to return.</param>
    /// <param name="ABlockRewards">Whether to populate the rewards array.</param>
    /// <param name="AMaxSupportedTransactionVersion">Transaction Version.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetBlock(ASlot: UInt64; ATransactionDetails: TTransactionDetailsFilterType = TTransactionDetailsFilterType.Full;
      ABlockRewards: Boolean = False; AMaxSupportedTransactionVersion: Integer = 0; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TBlockInfo>;

    /// <summary>
    /// Gets the block commitment of a certain block, identified by slot.
    /// </summary>
    /// <param name="ASlot">The slot.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetBlockCommitment(ASlot: UInt64): TRequestResult<TBlockCommitment>;

    /// <summary>
    /// Gets the current block height of the node.
    /// </summary>
    /// <param name="ACommitment">The commitment state to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetBlockHeight(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<UInt64>;

    /// <summary>
    /// Returns recent block production information from the current or previous epoch.
    /// </summary>
    /// <remarks>
    /// All the arguments are optional, but the lastSlot must be paired with a firstSlot argument.
    /// </remarks>
    /// <param name="AIdentity">Filter production details only for this given validator.</param>
    /// <param name="AFirstSlot">The first slot to return production information (inclusive).</param>
    /// <param name="ALastSlot">The last slot to return production information (inclusive and optional).</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetBlockProduction(const AIdentity: string; const AFirstSlot, ALastSlot: TNullable<UInt64>;
      ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TBlockProductionInfo>>;

    /// <summary>
    /// Returns a list of blocks between two slots.
    /// </summary>
    /// <param name="AStartSlot">The start slot (inclusive).</param>
    /// <param name="AEndSlot">The start slot (inclusive and optional).</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetBlocks(AStartSlot: UInt64; AEndSlot: UInt64 = 0; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TList<UInt64>>;

    /// <summary>
    /// Returns a list of confirmed blocks starting at the given slot.
    /// </summary>
    /// <param name="AStartSlot">The start slot (inclusive).</param>
    /// <param name="ALimit">The max number of blocks to return.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetBlocksWithLimit(AStartSlot, ALimit: UInt64; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TList<UInt64>>;

    /// <summary>
    /// Gets the estimated production time for a certain block, identified by slot.
    /// </summary>
    /// <param name="ASlot">The slot.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetBlockTime(ASlot: UInt64): TRequestResult<UInt64>;

    /// <summary>
    /// Gets the cluster nodes.
    /// </summary>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetClusterNodes: TRequestResult<TObjectList<TClusterNode>>;

    /// <summary>
    /// Gets information about the current epoch.
    /// </summary>
    /// <param name="ACommitment">The commitment state to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetEpochInfo(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TEpochInfo>;

    /// <summary>
    /// Gets epoch schedule information from this cluster's genesis config.
    /// </summary>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetEpochSchedule: TRequestResult<TEpochScheduleInfo>;

    /// <summary>
    /// Get the fee the network will charge for a particular Message.
    /// </summary>
    /// <param name="AMessage">The base-64 encoded message.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetFeeForMessage(const AMessage: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<UInt64>>;

    /// <summary>
    /// Returns the slot of the lowest confirmed block that has not been purged from the ledger.
    /// </summary>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetFirstAvailableBlock: TRequestResult<UInt64>;

    /// <summary>
    /// Gets the genesis hash of the ledger.
    /// </summary>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetGenesisHash: TRequestResult<string>;

    /// <summary>
    /// Returns the current health of the node.
    /// This method should return the string 'ok' if the node is healthy, or the error code along with any information provided otherwise.
    /// </summary>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetHealth: TRequestResult<string>;

    /// <summary>
    /// Gets the identity pubkey for the current node.
    /// </summary>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetIdentity: TRequestResult<TNodeIdentity>;

    /// <summary>
    /// Gets the current inflation governor.
    /// </summary>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetInflationGovernor(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TInflationGovernor>;

    /// <summary>
    /// Gets the specific inflation values for the current epoch.
    /// </summary>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetInflationRate: TRequestResult<TInflationRate>;

    /// <summary>
    /// Gets the inflation reward for a list of addresses for an epoch.
    /// </summary>
    /// <param name="AAddresses">The list of addresses to query, as base-58 encoded strings.</param>
    /// <param name="AEpoch">The epoch.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetInflationReward(const AAddresses: TArray<string>; AEpoch: UInt64 = 0; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TObjectList<TInflationReward>>;

    /// <summary>
    /// Gets the 20 largest accounts, by lamport balance.
    /// </summary>
    /// <remarks>Results may be cached up to two hours.</remarks>
    /// <param name="AFilter">Filter results by account type.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetLargestAccounts(const AFilter: TNullable<TAccountFilterType>; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TObjectList<TLargeAccount>>>;

    /// <summary>
    /// Returns the leader schedule for an epoch.
    /// </summary>
    /// <param name="ASlot">Fetch the leader schedule for the epoch that corresponds to the provided slot.
    /// If unspecified, the leader schedule for the current epoch is fetched.</param>
    /// <param name="AIdentity">Filter results for this validator only (base 58 encoded string and optional).</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetLeaderSchedule(ASlot: UInt64 = 0; const AIdentity: string = ''; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TDictionary<string, TList<UInt64>>>;

    /// <summary>
    /// Gets the maximum slot seen from retransmit stage.
    /// </summary>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetMaxRetransmitSlot: TRequestResult<UInt64>;

    /// <summary>
    /// Gets the maximum slot seen from after shred insert.
    /// </summary>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetMaxShredInsertSlot: TRequestResult<UInt64>;

    /// <summary>
    /// Gets the minimum balance required to make account rent exempt.
    /// </summary>
    /// <param name="AAccountDataSize">The account data size.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetMinimumBalanceForRentExemption(AAccountDataSize: Int64; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<UInt64>;

    /// <summary>
    /// Gets the lowest slot that the node has information about in its ledger.
    /// <remarks>
    /// This value may decrease over time if a node is configured to purging data.
    /// </remarks>
    /// </summary>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetMinimumLedgerSlot: TRequestResult<UInt64>;

    /// <summary>
    /// Gets the account info for multiple accounts.
    /// </summary>
    /// <param name="AAccounts">The list of the accounts public keys.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetMultipleAccounts(const AAccounts: TArray<string>; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TObjectList<TAccountInfo>>>;

    /// <summary>
    /// Returns all accounts owned by the provided program Pubkey.
    /// <remarks>Accounts must meet all filter criteria to be included in the results.</remarks>
    /// </summary>
    /// <param name="APubKey">The program public key.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <param name="ADataSize">The data size of the account to compare against the program account data.</param>
    /// <param name="ADataSlice">The config param used to request a slice of the account's data.</param>
    /// <param name="AMemCmpList">The list of comparisons to match against the program account data.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetProgramAccounts(const APubKey: string; const ADataSize: TNullable<Integer>; const ADataSlice: TDataSlice = nil; const AMemCmpList: TArray<TMemCmp> = nil; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TObjectList<TAccountKeyPair>>;

    /// <summary>
    /// Gets the latest block hash.
    /// </summary>
    /// <param name="commitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetLatestBlockHash(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TLatestBlockHash>>;

    /// <summary>
    /// Returns whether a blockhash is still valid or not.
    /// </summary>
    /// <param name="ABlockHash">The Blockhash to validate, as a base58 encoded string.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function IsBlockHashValid(const ABlockHash: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<Boolean>>;

    /// <summary>
    /// Gets a list of recent performance samples.
    /// <remarks>
    /// Unless <c>searchTransactionHistory</c> is included, this method only searches the recent status cache of signatures.
    /// </remarks>
    /// </summary>
    /// <param name="ALimit">Maximum transaction signatures to return, between 1-720. Default is 720.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetRecentPerformanceSamples(ALimit: UInt64 = 720): TRequestResult<TObjectList<TPerformanceSample>>;

    /// <summary>
    /// Gets a list of prioritization fees from recent blocks.
    /// </summary>
    /// <param name="AAccounts">Accounts used in your transaction; otherwise, you'll find the lowest fee to land a transaction overall (optional).</param>
    /// <returns>Returns a task that holds the asynchronous operation result and state.</returns>
    function GetRecentPrioritizationFees(const AAccounts: TArray<string> = nil): TRequestResult<TObjectList<TPrioritizationFeeItem>>;

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
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetSignaturesForAddress(const AAccountPubKey: string; ALimit: UInt64 = 1000; const ABefore: string = ''; const AUntil: string = ''; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TObjectList<TSignatureStatusInfo>>;

    /// <summary>
    /// Gets the status of a list of signatures.
    /// <remarks>
    /// Unless <c>searchTransactionHistory</c> is included, this method only searches the recent status cache of signatures.
    /// </remarks>
    /// </summary>
    /// <param name="ATransactionHashes">The list of transactions to search status info for.</param>
    /// <param name="ASearchTransactionHistory">If the node should search for signatures in it's ledger cache.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetSignatureStatuses(const ATransactionHashes: TArray<string>; ASearchTransactionHistory: Boolean = False): TRequestResult<TResponseValue<TObjectList<TSignatureStatusInfo>>>;

    /// <summary>
    /// Gets the current slot the node is processing
    /// </summary>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetSlot(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<UInt64>;

    /// <summary>
    /// Gets the current slot leader.
    /// </summary>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetSlotLeader(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<string>;

    /// <summary>
    /// Gets the slot leaders for a given slot range.
    /// </summary>
    /// <param name="AStart">The start slot.</param>
    /// <param name="ALimit">The result limit.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetSlotLeaders(AStart, ALimit: UInt64; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TList<string>>;

    /// <summary>
    /// Gets the highest slot that the node has a snapshot for.
    /// </summary>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetHighestSnapshotSlot: TRequestResult<TSnapshotSlotInfo>;

    /// <summary>
    /// Gets information about the current supply.
    /// </summary>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetSupply(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TSupply>>;

    /// <summary>
    /// Gets the token balance of an SPL Token account.
    /// </summary>
    /// <param name="ASplTokenAccountPublicKey">Public key of Token account to query, as base-58 encoded string.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetTokenAccountBalance(const ASplTokenAccountPublicKey: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TTokenBalance>>;

    /// <summary>
    /// Gets all SPL Token accounts by approved delegate.
    /// </summary>
    /// <param name="AOwnerPubKey">Public key of account owner query, as base-58 encoded string.</param>
    /// <param name="ATokenMintPubKey">Public key of the specific token Mint to limit accounts to, as base-58 encoded string.</param>
    /// <param name="ATokenProgramId">Public key of the Token program ID that owns the accounts, as base-58 encoded string.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetTokenAccountsByDelegate(const AOwnerPubKey: string; const ATokenMintPubKey: string = ''; const ATokenProgramId: string = ''; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;

    /// <summary>
    /// Gets all SPL Token accounts by token owner.
    /// </summary>
    /// <param name="AOwnerPubKey">Public key of account owner query, as base-58 encoded string.</param>
    /// <param name="ATokenMintPubKey">Public key of the specific token Mint to limit accounts to, as base-58 encoded string.</param>
    /// <param name="ATokenProgramId">Public key of the Token program ID that owns the accounts, as base-58 encoded string.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetTokenAccountsByOwner(const AOwnerPubKey: string; const ATokenMintPubKey: string = ''; const ATokenProgramId: string = ''; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;

    /// <summary>
    /// Gets the 20 largest token accounts of a particular SPL Token.
    /// </summary>
    /// <param name="ATokenMintPubKey">Public key of Token Mint to query, as base-58 encoded string.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetTokenLargestAccounts(const ATokenMintPubKey: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TObjectList<TLargeTokenAccount>>>;

    /// <summary>
    /// Get the token supply of an SPL Token type.
    /// </summary>
    /// <param name="ATokenMintPubKey">Public key of Token Mint to query, as base-58 encoded string.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetTokenSupply(const ATokenMintPubKey: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TTokenBalance>>;

    /// <summary>
    /// Returns transaction details for a confirmed transaction.
    /// <remarks>
    /// <para>
    /// The <c>commitment</c> parameter is optional, <see cref="TCommitment.Processed"/> is not supported,
    /// the default value <see cref="TCommitment.Finalized"/> is not sent.
    /// </para>
    /// </remarks>
    /// </summary>
    /// <param name="ASignature"></param>
    /// <param name="AMaxSupportedTransactionVersion"></param>
    /// <param name="AEncoding"></param>
    /// <param name="ACommitment"></param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetTransaction(const ASignature: string; AMaxSupportedTransactionVersion: Integer = 0; const AEncoding: string = 'json'; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TTransactionMetaSlotInfo>;

    /// <summary>
    /// Gets the total transaction count of the ledger.
    /// </summary>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetTransactionCount(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<UInt64>;

    /// <summary>
    /// Requests an airdrop to the passed <c>APubKey</c> of the passed <c>ALamports</c> amount.
    /// <remarks>
    /// The <c>ACommitment</c> parameter is optional, the default <see cref="TCommitment.Finalized"/> is used.
    /// </remarks>
    /// </summary>
    /// <param name="APubKey">The public key of to receive the airdrop.</param>
    /// <param name="ALamports">The amount of lamports to request.</param>
    /// <param name="ACommitment">The block commitment used to retrieve block hashes and verify success.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function RequestAirdrop(const APubKey: string; ALamports: UInt64; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<string>;

    /// <summary>
    /// Sends a transaction.
    /// </summary>
    /// <param name="ATransaction">The signed transaction as base-64 encoded string.</param>
    /// <param name="AMaxRetries">The maximum number of times for the RPC node to retry sending the transaction to the leader. If this parameter not provided, the RPC node will retry the transaction until it is finalized or until the blockhash expires.</param>
    /// <param name="AMinContextSlot">The minimum slot at which to perform preflight transaction checks.</param>
    /// <param name="ASkipPreflight">If true skip the preflight transaction checks (default false).</param>
    /// <param name="APreFlightCommitment">The block commitment used for preflight.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function SendTransaction(const ATransaction: string; const AMaxRetries: TNullable<UInt32>; const AMinContextSlot: TNullable<UInt64>; ASkipPreflight: Boolean = False; APreflightCommitment: TCommitment = TCommitment.Finalized): TRequestResult<string>; overload;

    /// <summary>
    /// Sends a transaction.
    /// </summary>
    /// <param name="ATransaction">The signed transaction as byte array.</param>
    /// <param name="AMaxRetries">The maximum number of times for the RPC node to retry sending the transaction to the leader. If this parameter not provided, the RPC node will retry the transaction until it is finalized or until the blockhash expires.</param>
    /// <param name="AMinContextSlot">The minimum slot at which to perform preflight transaction checks.</param>
    /// <param name="ASkipPreflight">If true skip the preflight transaction checks (default false).</param>
    /// <param name="APreFlightCommitment">The block commitment used for preflight.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function SendTransaction(const ATransaction: TBytes; const AMaxRetries: TNullable<UInt32>; const AMinContextSlot: TNullable<UInt64>; ASkipPreflight: Boolean = False; APreflightCommitment: TCommitment = TCommitment.Finalized): TRequestResult<string>; overload;

    /// <summary>
    /// Simulate sending a transaction.
    /// </summary>
    /// <param name="ATransaction">The signed transaction base-64 encoded string.</param>
    /// <param name="ASigVerify">If the transaction signatures should be verified
    /// (default false, conflicts with <c>AReplaceRecentBlockHash</c>.</param>
    /// <param name="AReplaceRecentBlockhash">If the transaction recent blockhash should be replaced with the most recent blockhash
    /// (default false, conflicts with <c>ASigVerify</c></param>
    /// <param name="AAccountsToReturn">List of accounts to return, as base-58 encoded strings.</param>
    /// <param name="ACommitment">The block commitment used to retrieve block hashes and verify success.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function SimulateTransaction(const ATransaction: string;
                                 ASigVerify: Boolean = False;
                                 AReplaceRecentBlockhash: Boolean = False;
                                 const AAccountsToReturn: TArray<string> = nil;
                                 ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TSimulationLogs>>; overload;

    /// <summary>
    /// Simulate sending a transaction.
    /// </summary>
    /// <param name="ATransaction">The signed transaction as a byte array.</param>
    /// <param name="ASigVerify">If the transaction signatures should be verified
    /// (default false, conflicts with <c>AReplaceRecentBlockHash</c>.</param>
    /// <param name="AReplaceRecentBlockhash">If the transaction recent blockhash should be replaced with the most recent blockhash
    /// (default false, conflicts with <c>ASigVerify</c></param>
    /// <param name="AAccountsToReturn">List of accounts to return, as base-58 encoded strings.</param>
    /// <param name="ACommitment">The block commitment used to retrieve block hashes and verify success.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function SimulateTransaction(const ATransaction: TBytes;
                                 ASigVerify: Boolean = False;
                                 AReplaceRecentBlockhash: Boolean = False;
                                 const AAccountsToReturn: TArray<string> = nil;
                                 ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TSimulationLogs>>; overload;

    /// <summary>
    /// Gets the current node's software version info.
    /// </summary>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetVersion: TRequestResult<TNodeVersion>;

    /// <summary>
    /// Gets the account info and associated stake for all voting accounts in the current bank.
    /// </summary>
    /// <param name="AVotePubKey">Filter by validator vote address, base-58 encoded string.</param>
    /// <param name="ACommitment">The state commitment to consider when querying the ledger state.</param>
    /// <returns>Returns an object that wraps the result along with possible errors with the request.</returns>
    function GetVoteAccounts(const AVotePubKey: string = ''; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TVoteAccounts>;
  end;

  /// <summary>
  /// Implements functionality to interact with the Solana JSON RPC API.
  /// </summary>
  TSolanaRpcClient = class(TJsonRpcClient, IRpcClient)
  private
    FIdGenerator: TIdGenerator;

    /// <summary>
    /// Generates the next unique id for the request.
    /// </summary>
    /// <returns>The id.</returns>
    function GetNextIdForReq(): Integer;

    /// <summary>
    /// Conditionally includes the <c>commitment</c> option.
    /// </summary>
    /// <param name="AParameter">The requested commitment.</param>
    /// <param name="ADefaultValue">
    /// The default commitment; when <c>AParameter = ADefaultValue</c>, the key is omitted.
    /// </param>
    /// <returns>
    /// A <c>TKeyValue</c> pair when included; otherwise <c>Default(TKeyValue)</c>.
    /// </returns>
    function HandleCommitment(AParameter: TCommitment; ADefault: TCommitment = TCommitment.Finalized): TKeyValue;
    /// <summary>
    /// Conditionally includes the <c>transactionDetails</c> option.
    /// </summary>
    /// <param name="AParameter">The requested details level.</param>
    /// <param name="ADefaultValue">
    /// The default details level; when <c>AParameter = ADefaultValue</c>, the key is omitted.
    /// </param>
    /// <returns>
    /// A <c>TKeyValue</c> pair when included; otherwise <c>Default(TKeyValue)</c>.
    /// </returns>
    function HandleTransactionDetails(AParameter: TTransactionDetailsFilterType; ADefault: TTransactionDetailsFilterType = TTransactionDetailsFilterType.Full): TKeyValue;

  protected
    function BuildSerializer: TJsonSerializer; override;

    /// <summary>
    /// Build the request for the passed RPC method and parameters.
    /// </summary>
    /// <param name="AMethod">The request's RPC method.</param>
    /// <param name="AParameters">A list of parameters to include in the request.</param>
    /// <returns>A JSON-RPC request object.</returns>
    function BuildRequest(const AMethod: string; const AParameters: TList<TValue>): TJsonRpcRequest;

    /// <summary>
    /// Send a request synchronously.
    /// </summary>
    /// <param name="AMethod">The request's RPC method.</param>
    /// <typeparam name="T">The type of the request result.</typeparam>
    /// <returns>A request result.</returns>
    function SendRequest<T>(const AMethod: string): TRequestResult<T>; overload;


    /// <summary>
    /// Send a request synchronously.
    /// </summary>
    /// <param name="AMethod">The request's RPC method.</param>
    /// <param name="AParameters">A list of parameters to include in the request.</param>
    /// <typeparam name="T">The type of the request result.</typeparam>
    /// <returns>A request result.</returns>
    function SendRequest<T>(const AMethod: string; const AParameters: TList<TValue>): TRequestResult<T>; overload;

  public
    /// <summary>
    /// Initialize the Rpc Client with the passed url.
    /// </summary>
    /// <param name="AUrl">The URL of the node exposing the JSON RPC API.</param>
    /// <param name="AClient">The HttpClient Used for the RPC Connection.</param>
    /// <param name="ALogger">The abstracted Logger instance or nil for no logger</param>
    /// <param name="ARateLimiter">A rate limiting strategy or null.</param>
    constructor Create(const AUrl: string; const AClient: IHttpApiClient; const ALogger: ILogger = nil; const ARateLimiter: IRateLimiter = nil);
    destructor Destroy; override;

    property NodeAddress: TURI read GetNodeAddress;

    // --- IRpcClient ---
    function GetTokenMintInfo(const APubKey: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TTokenMintInfo>>;

    function GetTokenAccountInfo(const APubKey: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TTokenAccountInfo>>;

    function GetAccountInfo(const APubKey: string; AEncoding: TBinaryEncoding = TBinaryEncoding.Base64; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TAccountInfo>>;

    function GetBalance(const APubKey: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<UInt64>>;

    function GetBlock(ASlot: UInt64;
                      ATransactionDetails: TTransactionDetailsFilterType = TTransactionDetailsFilterType.Full;
                      ABlockRewards: Boolean = False;
                      AMaxSupportedTransactionVersion: Integer = 0;
                      ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TBlockInfo>;

    function GetBlockCommitment(ASlot: UInt64): TRequestResult<TBlockCommitment>;

    function GetBlockHeight(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<UInt64>;

    function GetBlockProduction(const AIdentity: string; const AFirstSlot, ALastSlot: TNullable<UInt64>; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TBlockProductionInfo>>;

    function GetBlocks(AStartSlot: UInt64; AEndSlot: UInt64 = 0; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TList<UInt64>>;

    function GetBlocksWithLimit(AStartSlot, ALimit: UInt64; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TList<UInt64>>;

    function GetBlockTime(ASlot: UInt64): TRequestResult<UInt64>;

    function GetClusterNodes: TRequestResult<TObjectList<TClusterNode>>;

    function GetEpochInfo(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TEpochInfo>;

    function GetEpochSchedule: TRequestResult<TEpochScheduleInfo>;

    function GetFeeForMessage(const AMessage: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<UInt64>>;

    function GetFirstAvailableBlock: TRequestResult<UInt64>;

    function GetGenesisHash: TRequestResult<string>;

    function GetHealth: TRequestResult<string>;

    function GetIdentity: TRequestResult<TNodeIdentity>;

    function GetInflationGovernor(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TInflationGovernor>;

    function GetInflationRate: TRequestResult<TInflationRate>;

    function GetInflationReward(const AAddresses: TArray<string>; AEpoch: UInt64 = 0; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TObjectList<TInflationReward>>;

    function GetLargestAccounts(const AFilter: TNullable<TAccountFilterType>; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TObjectList<TLargeAccount>>>;

    function GetLeaderSchedule(ASlot: UInt64 = 0; const AIdentity: string = ''; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TDictionary<string, TList<UInt64>>>;

    function GetMaxRetransmitSlot: TRequestResult<UInt64>;

    function GetMaxShredInsertSlot: TRequestResult<UInt64>;

    function GetMinimumBalanceForRentExemption(AAccountDataSize: Int64; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<UInt64>;

    function GetMinimumLedgerSlot: TRequestResult<UInt64>;

    function GetMultipleAccounts(const AAccounts: TArray<string>; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TObjectList<TAccountInfo>>>;

    function GetProgramAccounts(const APubKey: string; const ADataSize: TNullable<Integer>; const ADataSlice: TDataSlice = nil; const AMemCmpList: TArray<TMemCmp> = nil; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TObjectList<TAccountKeyPair>>;

    function GetLatestBlockHash(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TLatestBlockHash>>;

    function IsBlockHashValid(const ABlockHash: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<Boolean>>;

    function GetRecentPerformanceSamples(ALimit: UInt64 = 720): TRequestResult<TObjectList<TPerformanceSample>>;

    function GetRecentPrioritizationFees(const AAccounts: TArray<string> = nil): TRequestResult<TObjectList<TPrioritizationFeeItem>>;

    function GetSignaturesForAddress(const AAccountPubKey: string; ALimit: UInt64 = 1000; const ABefore: string = ''; const AUntil: string = ''; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TObjectList<TSignatureStatusInfo>>;

    function GetSignatureStatuses(const ATransactionHashes: TArray<string>; ASearchTransactionHistory: Boolean = False): TRequestResult<TResponseValue<TObjectList<TSignatureStatusInfo>>>;

    function GetSlot(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<UInt64>;

    function GetSlotLeader(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<string>;

    function GetSlotLeaders(AStart, ALimit: UInt64; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TList<string>>;

    function GetHighestSnapshotSlot: TRequestResult<TSnapshotSlotInfo>;

    function GetSupply(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TSupply>>;

    function GetTokenAccountBalance(const ASplTokenAccountPublicKey: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TTokenBalance>>;

    function GetTokenAccountsByDelegate(const AOwnerPubKey: string; const ATokenMintPubKey: string = ''; const ATokenProgramId: string = ''; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;

    function GetTokenAccountsByOwner(const AOwnerPubKey: string; const ATokenMintPubKey: string = ''; const ATokenProgramId: string = ''; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;

    function GetTokenLargestAccounts(const ATokenMintPubKey: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TObjectList<TLargeTokenAccount>>>;

    function GetTokenSupply(const ATokenMintPubKey: string; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TTokenBalance>>;

    function GetTransaction(const ASignature: string; AMaxSupportedTransactionVersion: Integer = 0; const AEncoding: string = 'json'; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TTransactionMetaSlotInfo>;

    function GetTransactionCount(ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<UInt64>;

    function RequestAirdrop(const APubKey: string; ALamports: UInt64; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<string>;

    function SendTransaction(const ATransaction: string; const AMaxRetries: TNullable<UInt32>; const AMinContextSlot: TNullable<UInt64>; ASkipPreflight: Boolean = False; APreflightCommitment: TCommitment = TCommitment.Finalized): TRequestResult<string>; overload;

    function SendTransaction(const ATransaction: TBytes; const AMaxRetries: TNullable<UInt32>; const AMinContextSlot: TNullable<UInt64>; ASkipPreflight: Boolean = False; APreflightCommitment: TCommitment = TCommitment.Finalized): TRequestResult<string>; overload;

    function SimulateTransaction(const ATransaction: string;
                                 ASigVerify: Boolean = False;
                                 AReplaceRecentBlockhash: Boolean = False;
                                 const AAccountsToReturn: TArray<string> = nil;
                                 ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TSimulationLogs>>; overload;

    function SimulateTransaction(const ATransaction: TBytes;
                                 ASigVerify: Boolean = False;
                                 AReplaceRecentBlockhash: Boolean = False;
                                 const AAccountsToReturn: TArray<string> = nil;
                                 ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TResponseValue<TSimulationLogs>>; overload;

    function GetVersion: TRequestResult<TNodeVersion>;

    function GetVoteAccounts(const AVotePubKey: string = ''; ACommitment: TCommitment = TCommitment.Finalized): TRequestResult<TVoteAccounts>;
  end;

implementation

{ TSolanaRpcClient }

constructor TSolanaRpcClient.Create(const AUrl: string; const AClient: IHttpApiClient; const ALogger: ILogger; const ARateLimiter: IRateLimiter);
begin
  inherited Create(AUrl, AClient, ALogger, ARateLimiter);
  FIdGenerator := TIdGenerator.Create();
end;

destructor TSolanaRpcClient.Destroy;
begin
   if Assigned(FIdGenerator) then
     FIdGenerator.Free;
  inherited;
end;

function TSolanaRpcClient.BuildSerializer: TJsonSerializer;
var
  Converters: TList<TJsonConverter>;
begin
  Converters := TJsonConverterFactory.GetRpcConverters();
  try
    Converters.Add(TEncodingConverter.Create);
    Converters.Add(TJsonStringEnumConverter.Create(TJsonNamingPolicy.CamelCase));

    Result := TJsonSerializerFactory.CreateSerializer(
      TEnhancedContractResolver.Create(
        TJsonMemberSerialization.Public,
        TJsonNamingPolicy.CamelCase
      ),
      Converters
    );
  finally
    Converters.Free;
  end;
end;

function TSolanaRpcClient.GetNextIdForReq: Integer;
begin
  Result := FIdGenerator.GetNextId();
end;

function TSolanaRpcClient.BuildRequest(const AMethod: string; const AParameters: TList<TValue>): TJsonRpcRequest;
begin
  Result := TJsonRpcRequest.Create(FIdGenerator.GetNextId(), AMethod, AParameters);
end;

function TSolanaRpcClient.SendRequest<T>(const AMethod: string): TRequestResult<T>;
var
  Req: TJsonRpcRequest;
begin
  Req := BuildRequest(AMethod, nil);
  try
    Result := SendRequest<T>(Req);
  finally
    if Assigned(Req) then Req.Free;
  end;
end;

function TSolanaRpcClient.SendRequest<T>(const AMethod: string; const AParameters: TList<TValue>): TRequestResult<T>;
var
  Req: TJsonRpcRequest;
begin
  Req := BuildRequest(AMethod, AParameters);
  try
    Result := SendRequest<T>(Req);
  finally
    if Assigned(Req) then Req.Free;
  end;
end;


function TSolanaRpcClient.HandleCommitment(AParameter, ADefault: TCommitment): TKeyValue;
begin
  if AParameter <> ADefault then
    Result := TKeyValue.From('commitment', TValue.From<TCommitment>(AParameter))
  else
    Result := Default(TKeyValue);
end;

function TSolanaRpcClient.HandleTransactionDetails(AParameter, ADefault: TTransactionDetailsFilterType): TKeyValue;
begin
  if AParameter <> ADefault then
    Result := TKeyValue.From('transactionDetails', TValue.From<TTransactionDetailsFilterType>(AParameter))
  else
    Result := Default(TKeyValue);
end;

function TSolanaRpcClient.GetTokenMintInfo(const APubKey: string; ACommitment: TCommitment): TRequestResult<TResponseValue<TTokenMintInfo>>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<string>(APubKey),
      TConfigObject.Make(
        TKeyValue.From('encoding', 'jsonParsed'),
        HandleCommitment(ACommitment)
      )
    );

  Result := SendRequest<TResponseValue<TTokenMintInfo>>('getAccountInfo', LParams);
end;

function TSolanaRpcClient.GetTokenAccountInfo(const APubKey: string; ACommitment: TCommitment): TRequestResult<TResponseValue<TTokenAccountInfo>>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<string>(APubKey),
      TConfigObject.Make(
        TKeyValue.From('encoding', 'jsonParsed'),
        HandleCommitment(ACommitment)
      )
    );

  Result := SendRequest<TResponseValue<TTokenAccountInfo>>('getAccountInfo', LParams);
end;

function TSolanaRpcClient.GetAccountInfo(const APubKey: string; AEncoding: TBinaryEncoding; ACommitment: TCommitment): TRequestResult<TResponseValue<TAccountInfo>>;
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

  Result := SendRequest<TResponseValue<TAccountInfo>>('getAccountInfo', LParams);
end;

function TSolanaRpcClient.GetBalance(const APubKey: string; ACommitment: TCommitment): TRequestResult<TResponseValue<UInt64>>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<string>(APubKey),
      TConfigObject.Make(
        HandleCommitment(ACommitment)
      )
    );

  Result := SendRequest<TResponseValue<UInt64>>('getBalance', LParams);
end;

function TSolanaRpcClient.GetBlock(
  ASlot: UInt64;
  ATransactionDetails: TTransactionDetailsFilterType;
  ABlockRewards: Boolean;
  AMaxSupportedTransactionVersion: Integer;
  ACommitment: TCommitment
): TRequestResult<TBlockInfo>;
var
  LParams: TList<TValue>;
  LRewards: TValue;
begin
  if ACommitment = TCommitment.Processed then
    raise EArgumentException.Create('Commitment.Processed is not supported for this method.');

  if ABlockRewards then
    LRewards := TValue.From<Boolean>(True)
  else
    LRewards := TValue.Empty;

    LParams := TParameters.Make(
      TValue.From<UInt64>(ASlot),
      TConfigObject.Make(
        TKeyValue.Make('encoding', 'json'),
        TKeyValue.Make('maxSupportedTransactionVersion', AMaxSupportedTransactionVersion),
        HandleTransactionDetails(ATransactionDetails),
        TKeyValue.Make('rewards', LRewards),
        HandleCommitment(ACommitment)
      )
    );

  Result := SendRequest<TBlockInfo>('getBlock', LParams);
end;

function TSolanaRpcClient.GetBlockCommitment(ASlot: UInt64): TRequestResult<TBlockCommitment>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<UInt64>(ASlot)
    );

  Result := SendRequest<TBlockCommitment>('getBlockCommitment', LParams);
end;

function TSolanaRpcClient.GetBlockHeight(ACommitment: TCommitment): TRequestResult<UInt64>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<TDictionary<string, TValue>>(
        TConfigObject.Make(
          HandleCommitment(ACommitment)
        )
      )
    );

  Result := SendRequest<UInt64>('getBlockHeight', LParams);
end;

function TSolanaRpcClient.GetBlockProduction(const AIdentity: string; const AFirstSlot, ALastSlot: TNullable<UInt64>; ACommitment: TCommitment): TRequestResult<TResponseValue<TBlockProductionInfo>>;
var
  LArgs   : TList<TValue>;
  LConfig : TDictionary<string, TValue>;
  LRange  : TDictionary<string, TValue>;
  LRangeKV: TKeyValue;
  LIdentity: TKeyValue;
begin
  LIdentity := Default(TKeyValue);
  if not string.IsNullOrEmpty(AIdentity) then
    LIdentity := TKeyValue.Make('identity', TValue.From<string>(AIdentity));

  // Build optional range object: requires firstSlot; lastSlot is optional
  LRangeKV := Default(TKeyValue);
  if AFirstSlot.HasValue then
  begin
    LRange := TDictionary<string, TValue>.Create;
    LRange.Add('firstSlot', TValue.From<UInt64>(AFirstSlot.Value));
    if ALastSlot.HasValue then
      LRange.Add('lastSlot',  TValue.From<UInt64>(ALastSlot.Value));
    LRangeKV := TKeyValue.Make('range', TValue.From<TDictionary<string, TValue>>(LRange));
  end
  else if ALastSlot.HasValue then
    raise EArgumentException.Create(
      'Range parameters are optional, but the lastSlot argument must be paired with a firstSlot.');

  LConfig := TConfigObject.Make(
    HandleCommitment(ACommitment),
    LIdentity,
    LRangeKV
  );

  LArgs := nil;

  if Assigned(LConfig) then
   LArgs := TParameters.Make(TValue.From<TDictionary<string, TValue>>(LConfig));

  Result := SendRequest<TResponseValue<TBlockProductionInfo>>('getBlockProduction', LArgs);
end;

function TSolanaRpcClient.GetBlocks(AStartSlot, AEndSlot: UInt64; ACommitment: TCommitment): TRequestResult<TList<UInt64>>;
var
  LParams: TList<TValue>;
  LEndSlot: TValue;
begin
  if ACommitment = TCommitment.Processed then
    raise EArgumentException.Create('Commitment.Processed is not supported for this method.');

  if AEndSlot > 0 then
    LEndSlot := TValue.From<UInt64>(AEndSlot)
  else
    LEndSlot := TValue.Empty;

    LParams := TParameters.Make(
      TValue.From<UInt64>(AStartSlot),
      LEndSlot,
      TConfigObject.Make(
        HandleCommitment(ACommitment)
      )
    );

  Result := SendRequest<TList<UInt64>>('getBlocks', LParams);
end;

function TSolanaRpcClient.GetBlocksWithLimit(AStartSlot, ALimit: UInt64; ACommitment: TCommitment): TRequestResult<TList<UInt64>>;
var
  LParams: TList<TValue>;
begin
  if ACommitment = TCommitment.Processed then
    raise EArgumentException.Create('Commitment.Processed is not supported for this method.');

    LParams := TParameters.Make(
      TValue.From<UInt64>(AStartSlot),
      TValue.From<UInt64>(ALimit),
      TConfigObject.Make(
        HandleCommitment(ACommitment)
      )
    );

  Result := SendRequest<TList<UInt64>>('getBlocksWithLimit', LParams);
end;

function TSolanaRpcClient.GetBlockTime(ASlot: UInt64): TRequestResult<UInt64>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<UInt64>(ASlot)
    );

  Result := SendRequest<UInt64>('getBlockTime', LParams);
end;

function TSolanaRpcClient.GetClusterNodes: TRequestResult<TObjectList<TClusterNode>>;
begin
  Result := SendRequest<TObjectList<TClusterNode>>('getClusterNodes');
end;

function TSolanaRpcClient.GetEpochInfo(ACommitment: TCommitment): TRequestResult<TEpochInfo>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<TDictionary<string, TValue>>(
        TConfigObject.Make(
          HandleCommitment(ACommitment)
        )
      )
    );

  Result := SendRequest<TEpochInfo>('getEpochInfo', LParams);
end;

function TSolanaRpcClient.GetEpochSchedule: TRequestResult<TEpochScheduleInfo>;
begin
  Result := SendRequest<TEpochScheduleInfo>('getEpochSchedule');
end;

function TSolanaRpcClient.GetFeeForMessage(const AMessage: string; ACommitment: TCommitment): TRequestResult<TResponseValue<UInt64>>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<string>(AMessage),
      TConfigObject.Make(
        HandleCommitment(ACommitment)
      )
    );

  Result := SendRequest<TResponseValue<UInt64>>('getFeeForMessage', LParams);
end;

function TSolanaRpcClient.GetFirstAvailableBlock: TRequestResult<UInt64>;
begin
  Result := SendRequest<UInt64>('getFirstAvailableBlock');
end;

function TSolanaRpcClient.GetGenesisHash: TRequestResult<string>;
begin
  Result := SendRequest<string>('getGenesisHash');
end;

function TSolanaRpcClient.GetHealth: TRequestResult<string>;
begin
  Result := SendRequest<string>('getHealth');
end;

function TSolanaRpcClient.GetIdentity: TRequestResult<TNodeIdentity>;
begin
  Result := SendRequest<TNodeIdentity>('getIdentity');
end;

function TSolanaRpcClient.GetInflationGovernor(ACommitment: TCommitment): TRequestResult<TInflationGovernor>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<TDictionary<string, TValue>>(
        TConfigObject.Make(
          HandleCommitment(ACommitment)
        )
      )
    );

  Result := SendRequest<TInflationGovernor>('getInflationGovernor', LParams);
end;

function TSolanaRpcClient.GetInflationRate: TRequestResult<TInflationRate>;
begin
  Result := SendRequest<TInflationRate>('getInflationRate');
end;

function TSolanaRpcClient.GetInflationReward(const AAddresses: TArray<string>; AEpoch: UInt64; ACommitment: TCommitment): TRequestResult<TObjectList<TInflationReward>>;
var
  LParams: TList<TValue>;
  LEpoch : TValue;
begin
  if AEpoch > 0 then
    LEpoch := TValue.From<UInt64>(AEpoch)
  else
    LEpoch := TValue.Empty;

    LParams := TParameters.Make(
      TValue.From<TArray<string>>(AAddresses),
      TConfigObject.Make(
        HandleCommitment(ACommitment),
        TKeyValue.Make('epoch', LEpoch)
      )
    );

  Result := SendRequest<TObjectList<TInflationReward>>('getInflationReward', LParams);
end;

function TSolanaRpcClient.GetLargestAccounts(
  const AFilter: TNullable<TAccountFilterType>;
  ACommitment: TCommitment
): TRequestResult<TResponseValue<TObjectList<TLargeAccount>>>;
var
  LParams: TList<TValue>;
begin
    if AFilter.HasValue then
    begin
      LParams := TParameters.Make(
        TConfigObject.Make(
          HandleCommitment(ACommitment),
          TKeyValue.Make('filter', TValue.From<TAccountFilterType>(AFilter.Value))
        )
      );
    end
    else
    begin
      LParams := TParameters.Make(
        TConfigObject.Make(
          HandleCommitment(ACommitment)
        )
      );
    end;

    Result := SendRequest<TResponseValue<TObjectList<TLargeAccount>>>(
      'getLargestAccounts',
      LParams
    );
end;

function TSolanaRpcClient.GetLeaderSchedule(ASlot: UInt64; const AIdentity: string; ACommitment: TCommitment): TRequestResult<TDictionary<string, TList<UInt64>>>;
var
  LParams: TList<TValue>;
  LSlotParam, LIdentity: TValue;
begin
  if ASlot > 0 then
    LSlotParam := TValue.From<UInt64>(ASlot)
  else
    LSlotParam := TValue.Empty;

  LIdentity := TValue.Empty;
  if AIdentity <> '' then
    LIdentity := TValue.From<string>(AIdentity);

    LParams := TParameters.Make(
      LSlotParam,
      TConfigObject.Make(
        HandleCommitment(ACommitment),
        TKeyValue.Make('identity', LIdentity)
      )
    );

    Result := SendRequest<TDictionary<string, TList<UInt64>>>(
      'getLeaderSchedule',
      LParams
    );
end;

function TSolanaRpcClient.GetMaxRetransmitSlot: TRequestResult<UInt64>;
begin
  Result := SendRequest<UInt64>('getMaxRetransmitSlot', nil);
end;

function TSolanaRpcClient.GetMaxShredInsertSlot: TRequestResult<UInt64>;
begin
  Result := SendRequest<UInt64>('getMaxShredInsertSlot', nil);
end;

function TSolanaRpcClient.GetMinimumBalanceForRentExemption(AAccountDataSize: Int64; ACommitment: TCommitment): TRequestResult<UInt64>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<Int64>(AAccountDataSize),
      TConfigObject.Make(
        HandleCommitment(ACommitment)
      )
    );

  Result := SendRequest<UInt64>('getMinimumBalanceForRentExemption', LParams);
end;

function TSolanaRpcClient.GetMinimumLedgerSlot: TRequestResult<UInt64>;
begin
  Result := SendRequest<UInt64>('minimumLedgerSlot');
end;

function TSolanaRpcClient.GetMultipleAccounts(const AAccounts: TArray<string>; ACommitment: TCommitment): TRequestResult<TResponseValue<TObjectList<TAccountInfo>>>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<TArray<string>>(AAccounts),
      TConfigObject.Make(
        TKeyValue.Make('encoding', 'base64'),
        HandleCommitment(ACommitment)
      )
    );

    Result := SendRequest<TResponseValue<TObjectList<TAccountInfo>>>(
      'getMultipleAccounts',
      LParams
    );
end;

function TSolanaRpcClient.GetProgramAccounts(
  const APubKey: string;
  const ADataSize: TNullable<Integer>;
  const ADataSlice: TDataSlice;
  const AMemCmpList: TArray<TMemCmp>;
  ACommitment: TCommitment
): TRequestResult<TObjectList<TAccountKeyPair>>;
var
  LFilters, LParams: TList<TValue>;

  function MemCmpValue(const AFilter: TMemCmp): TValue;
  begin
    Result := TConfigObject.Make(
      TKeyValue.Make(
        'memcmp',
        TConfigObject.Make(
          TKeyValue.Make('offset', AFilter.Offset),
          TKeyValue.Make('bytes',  AFilter.Bytes)
        )
      )
    );
  end;

  function FiltersValue(const Items: TList<TValue>): TValue;
  begin
    Result := TValue.From<TArray<TValue>>(Items.ToArray);
  end;

  function DataSliceValue(const ADataSlice: TDataSlice): TValue;
  begin
   if not Assigned(ADataSlice) then
    Exit(TValue.Empty);

    Result :=
        TConfigObject.Make(
          TKeyValue.Make('length', ADataSlice.Length),
          TKeyValue.Make('offset',  ADataSlice.Offset)
    );
  end;

var
  I: Integer;
begin
  LFilters := TList<TValue>.Create;
  try
    // Optional dataSize
    if ADataSize.HasValue then
      LFilters.Add(
        TConfigObject.Make(
          TKeyValue.Make('dataSize', ADataSize.Value)
        )
      );

    // Optional memcmp array
    for I := Low(AMemCmpList) to High(AMemCmpList) do
      LFilters.Add(MemCmpValue(AMemCmpList[I]));

    LParams := TParameters.Make(
      APubKey,
      TConfigObject.Make(
        TKeyValue.Make('encoding', 'base64'),
        TKeyValue.Make('filters', FiltersValue(LFilters)),
        TKeyValue.Make('dataSlice', DataSliceValue(ADataSlice)),
        HandleCommitment(ACommitment)
      )
    );

    Result := SendRequest<TObjectList<TAccountKeyPair>>('getProgramAccounts', LParams);
  finally
    LFilters.Free;
  end;
end;

function TSolanaRpcClient.GetLatestBlockHash(ACommitment: TCommitment): TRequestResult<TResponseValue<TLatestBlockHash>>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<TDictionary<string, TValue>>(
        TConfigObject.Make(
          HandleCommitment(ACommitment)
        )
      )
    );

  Result := SendRequest<TResponseValue<TLatestBlockHash>>('getLatestBlockhash', LParams);
end;

function TSolanaRpcClient.IsBlockHashValid(const ABlockHash: string; ACommitment: TCommitment): TRequestResult<TResponseValue<Boolean>>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<string>(ABlockHash),
      TConfigObject.Make(
        HandleCommitment(ACommitment)
      )
    );

  Result := SendRequest<TResponseValue<Boolean>>('isBlockhashValid', LParams);
end;

function TSolanaRpcClient.GetRecentPerformanceSamples(ALimit: UInt64): TRequestResult<TObjectList<TPerformanceSample>>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<UInt64>(ALimit)
    );

    Result := SendRequest<TObjectList<TPerformanceSample>>(
      'getRecentPerformanceSamples',
      LParams
    );
end;

function TSolanaRpcClient.GetRecentPrioritizationFees(const AAccounts: TArray<string>): TRequestResult<TObjectList<TPrioritizationFeeItem>>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<TArray<string>>(AAccounts)
    );

    Result := SendRequest<TObjectList<TPrioritizationFeeItem>>(
      'getRecentPrioritizationFees',
      LParams
    );
end;

function TSolanaRpcClient.GetSignaturesForAddress(const AAccountPubKey: string; ALimit: UInt64; const ABefore, AUntil: string; ACommitment: TCommitment): TRequestResult<TObjectList<TSignatureStatusInfo>>;
var
  LParams: TList<TValue>;
  LLimit, LBefore, LUntil: TValue;
begin
  if ACommitment = TCommitment.Processed then
    raise EArgumentException.Create('Commitment.Processed is not supported for this method.');

  if ALimit <> 1000 then
    LLimit := TValue.From<UInt64>(ALimit)
  else
    LLimit := TValue.Empty;

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

  Result := SendRequest<TObjectList<TSignatureStatusInfo>>('getSignaturesForAddress', LParams);
end;

function TSolanaRpcClient.GetSignatureStatuses(const ATransactionHashes: TArray<string>; ASearchTransactionHistory: Boolean): TRequestResult<TResponseValue<TObjectList<TSignatureStatusInfo>>>;
var
  LParams: TList<TValue>;
  LSearch: TValue;
begin
  if ASearchTransactionHistory then
    LSearch := TValue.From<Boolean>(True)
  else
    LSearch := TValue.Empty;

    LParams := TParameters.Make(
      TValue.From<TArray<string>>(ATransactionHashes),
      TConfigObject.Make(
        TKeyValue.Make('searchTransactionHistory', LSearch)
      )
    );

    Result := SendRequest<TResponseValue<TObjectList<TSignatureStatusInfo>>>(
      'getSignatureStatuses',
      LParams
    );
end;

function TSolanaRpcClient.GetSlot(ACommitment: TCommitment): TRequestResult<UInt64>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<TDictionary<string, TValue>>(
        TConfigObject.Make(
          HandleCommitment(ACommitment)
        )
      )
    );

  Result := SendRequest<UInt64>('getSlot', LParams);
end;

function TSolanaRpcClient.GetSlotLeader(ACommitment: TCommitment): TRequestResult<string>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<TDictionary<string, TValue>>(
        TConfigObject.Make(
          HandleCommitment(ACommitment)
        )
      )
    );

  Result := SendRequest<string>('getSlotLeader', LParams);
end;

function TSolanaRpcClient.GetSlotLeaders(AStart, ALimit: UInt64; ACommitment: TCommitment): TRequestResult<TList<string>>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<UInt64>(AStart),
      TValue.From<UInt64>(ALimit),
      TConfigObject.Make(
        HandleCommitment(ACommitment)
      )
    );

  Result := SendRequest<TList<string>>('getSlotLeaders', LParams);
end;

function TSolanaRpcClient.GetHighestSnapshotSlot: TRequestResult<TSnapshotSlotInfo>;
begin
  Result := SendRequest<TSnapshotSlotInfo>('getHighestSnapshotSlot', nil);
end;

function TSolanaRpcClient.GetSupply(ACommitment: TCommitment): TRequestResult<TResponseValue<TSupply>>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<TDictionary<string, TValue>>(
        TConfigObject.Make(
          HandleCommitment(ACommitment)
        )
      )
    );

  Result := SendRequest<TResponseValue<TSupply>>('getSupply', LParams);
end;

function TSolanaRpcClient.GetTokenAccountBalance(const ASplTokenAccountPublicKey: string; ACommitment: TCommitment): TRequestResult<TResponseValue<TTokenBalance>>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<string>(ASplTokenAccountPublicKey),
      TConfigObject.Make(
        HandleCommitment(ACommitment)
      )
    );

    Result := SendRequest<TResponseValue<TTokenBalance>>(
      'getTokenAccountBalance',
      LParams
    );
end;

function TSolanaRpcClient.GetTokenAccountsByDelegate(const AOwnerPubKey, ATokenMintPubKey, ATokenProgramId: string; ACommitment: TCommitment): TRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
var
  LParams: TList<TValue>;
  LTokenMintPubKey, LTokenProgramId: TValue;
begin
  if (string.IsNullOrWhiteSpace(ATokenMintPubKey) and string.IsNullOrWhiteSpace(ATokenProgramId)) then
    raise EArgumentException.Create('either ATokenProgramId or ATokenMintPubKey must be set');

    LTokenMintPubKey := TValue.Empty;
    if ATokenMintPubKey <> '' then
     LTokenMintPubKey := TValue.From<string>(ATokenMintPubKey);

    LTokenProgramId := TValue.Empty;
    if ATokenProgramId <> '' then
     LTokenProgramId := TValue.From<string>(ATokenProgramId);

    LParams := TParameters.Make(
      TValue.From<string>(AOwnerPubKey),
      TConfigObject.Make(
        TKeyValue.Make('mint', LTokenMintPubKey),
        TKeyValue.Make('programId', LTokenProgramId)
      ),
      TConfigObject.Make(
        HandleCommitment(ACommitment),
        TKeyValue.Make('encoding', 'jsonParsed')
      )
    );

    Result := SendRequest<TResponseValue<TObjectList<TTokenAccount>>>(
      'getTokenAccountsByDelegate',
      LParams
    );
end;

function TSolanaRpcClient.GetTokenAccountsByOwner(const AOwnerPubKey, ATokenMintPubKey, ATokenProgramId: string; ACommitment: TCommitment): TRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
var
  LParams: TList<TValue>;
  LTokenMintPubKey, LTokenProgramId: TValue;
begin
  if (string.IsNullOrWhiteSpace(ATokenMintPubKey) and string.IsNullOrWhiteSpace(ATokenProgramId)) then
    raise EArgumentException.Create('either ATokenProgramId or ATokenMintPubKey must be set');

    LTokenMintPubKey := TValue.Empty;
    if ATokenMintPubKey <> '' then
     LTokenMintPubKey := TValue.From<string>(ATokenMintPubKey);

    LTokenProgramId := TValue.Empty;
    if ATokenProgramId <> '' then
     LTokenProgramId := TValue.From<string>(ATokenProgramId);

    LParams := TParameters.Make(
      TValue.From<string>(AOwnerPubKey),
      TConfigObject.Make(
        TKeyValue.Make('mint', LTokenMintPubKey),
        TKeyValue.Make('programId', LTokenProgramId)
      ),
      TConfigObject.Make(
        HandleCommitment(ACommitment),
        TKeyValue.Make('encoding', 'jsonParsed')
      )
    );

    Result := SendRequest<TResponseValue<TObjectList<TTokenAccount>>>(
      'getTokenAccountsByOwner',
      LParams
    );
end;

function TSolanaRpcClient.GetTokenLargestAccounts(const ATokenMintPubKey: string; ACommitment: TCommitment): TRequestResult<TResponseValue<TObjectList<TLargeTokenAccount>>>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<string>(ATokenMintPubKey),
      TConfigObject.Make(
        HandleCommitment(ACommitment)
      )
    );

    Result := SendRequest<TResponseValue<TObjectList<TLargeTokenAccount>>>(
      'getTokenLargestAccounts',
      LParams
    );
end;

function TSolanaRpcClient.GetTokenSupply(const ATokenMintPubKey: string; ACommitment: TCommitment): TRequestResult<TResponseValue<TTokenBalance>>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<string>(ATokenMintPubKey),
      TConfigObject.Make(
        HandleCommitment(ACommitment)
      )
    );

  Result := SendRequest<TResponseValue<TTokenBalance>>('getTokenSupply', LParams);
end;

function TSolanaRpcClient.GetTransaction(const ASignature: string; AMaxSupportedTransactionVersion: Integer; const AEncoding: string; ACommitment: TCommitment): TRequestResult<TTransactionMetaSlotInfo>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<string>(ASignature),
      TConfigObject.Make(
        TKeyValue.Make('encoding', TValue.From<string>(AEncoding)),
        HandleCommitment(ACommitment),
        TKeyValue.Make('maxSupportedTransactionVersion',
          TValue.From<Integer>(AMaxSupportedTransactionVersion))
      )
    );

  Result := SendRequest<TTransactionMetaSlotInfo>('getTransaction', LParams);
end;

function TSolanaRpcClient.GetTransactionCount(ACommitment: TCommitment): TRequestResult<UInt64>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<TDictionary<string, TValue>>(
        TConfigObject.Make(
          HandleCommitment(ACommitment)
        )
      )
    );

  Result := SendRequest<UInt64>('getTransactionCount', LParams);
end;

function TSolanaRpcClient.RequestAirdrop(const APubKey: string; ALamports: UInt64; ACommitment: TCommitment): TRequestResult<string>;
var
  LParams: TList<TValue>;
begin
    LParams := TParameters.Make(
      TValue.From<string>(APubKey),
      TValue.From<UInt64>(ALamports),
      TConfigObject.Make(
        HandleCommitment(ACommitment)
      )
    );

  Result := SendRequest<string>('requestAirdrop', LParams);
end;

function TSolanaRpcClient.SendTransaction(const ATransaction: string; const AMaxRetries: TNullable<UInt32>; const AMinContextSlot: TNullable<UInt64>; ASkipPreflight: Boolean; APreflightCommitment: TCommitment): TRequestResult<string>;
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
        TKeyValue.Make('encoding',              TValue.From<TBinaryEncoding>(TBinaryEncoding.Base64))
      )
    );

  Result := SendRequest<string>('sendTransaction', LParams);
end;

function TSolanaRpcClient.SendTransaction(const ATransaction: TBytes; const AMaxRetries: TNullable<UInt32>; const AMinContextSlot: TNullable<UInt64>; ASkipPreflight: Boolean; APreflightCommitment: TCommitment): TRequestResult<string>;
begin
  Result := SendTransaction(TEncoders.Base64.EncodeData(ATransaction), AMaxRetries, AMinContextSlot, ASkipPreflight, APreflightCommitment);
end;

function TSolanaRpcClient.SimulateTransaction(const ATransaction: string; ASigVerify: Boolean;
  AReplaceRecentBlockhash: Boolean; const AAccountsToReturn: TArray<string>;
  ACommitment: TCommitment): TRequestResult<TResponseValue<TSimulationLogs>>;
var
  LParams: TList<TValue>;
  LSigVerify, LReplaceRB: TValue;
  LAccounts: TKeyValue;
begin
  if ASigVerify and AReplaceRecentBlockhash then
    raise EArgumentException.Create(
      'Parameters sigVerify and replaceRecentBlockhash are incompatible, only one can be set to true.');

  if ASigVerify then
    LSigVerify := TValue.From<Boolean>(True)
  else
    LSigVerify := TValue.Empty;

  if AReplaceRecentBlockhash then
    LReplaceRB := TValue.From<Boolean>(True)
  else
    LReplaceRB := TValue.Empty;

  if Assigned(AAccountsToReturn) then
    LAccounts := TKeyValue.Make('accounts',
      TValue.From<TDictionary<string, TValue>>(
        TConfigObject.Make(
          TKeyValue.Make('encoding', TValue.From<TBinaryEncoding>(TBinaryEncoding.Base64)),
          TKeyValue.Make('addresses', TValue.From<TArray<string>>(AAccountsToReturn))
        )
      ))
  else
    LAccounts := TKeyValue.Make('accounts', TValue.Empty);

    LParams := TParameters.Make(
      TValue.From<string>(ATransaction),
      TConfigObject.Make(
        TKeyValue.Make('sigVerify', LSigVerify),
        HandleCommitment(ACommitment),
        TKeyValue.Make('encoding', TValue.From<TBinaryEncoding>(TBinaryEncoding.Base64)),
        TKeyValue.Make('replaceRecentBlockhash', LReplaceRB),
        LAccounts
      )
    );

  Result := SendRequest<TResponseValue<TSimulationLogs>>('simulateTransaction', LParams);
end;

function TSolanaRpcClient.SimulateTransaction(const ATransaction: TBytes; ASigVerify: Boolean;
  AReplaceRecentBlockhash: Boolean; const AAccountsToReturn: TArray<string>;
  ACommitment: TCommitment): TRequestResult<TResponseValue<TSimulationLogs>>;
begin
  Result := SimulateTransaction(TEncoders.Base64.EncodeData(ATransaction), ASigVerify, AReplaceRecentBlockhash, AAccountsToReturn, ACommitment);
end;

function TSolanaRpcClient.GetVersion: TRequestResult<TNodeVersion>;
begin
  Result := SendRequest<TNodeVersion>('getVersion');
end;

function TSolanaRpcClient.GetVoteAccounts(const AVotePubKey: string; ACommitment: TCommitment): TRequestResult<TVoteAccounts>;
var
  LParams: TList<TValue>;
  LVotePubKey: TValue;
begin
    LVotePubKey := TValue.Empty;
    if AVotePubKey <> '' then
     LVotePubKey := TValue.From<string>(AVotePubKey);

    LParams := TParameters.Make(
      TConfigObject.Make(
        HandleCommitment(ACommitment),
        TKeyValue.Make('votePubkey', LVotePubKey)
      )
    );

  Result := SendRequest<TVoteAccounts>('getVoteAccounts', LParams);
end;

end.
