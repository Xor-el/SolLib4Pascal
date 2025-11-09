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

unit SlpRpcEnum;

{$I ..\Include\SolLib.inc}

interface

type
  /// <summary>
  /// Represents the filter account type.
  /// </summary>
  TAccountFilterType = (
    /// <summary>
    /// Circulating accounts.
    /// </summary>
    Circulating,
    /// <summary>
    /// Non circulating accounts.
    /// </summary>
    NonCirculating
  );

  /// <summary>
  /// Represents the different auto execute modes for a SolanaRpcBatchComposer
  /// </summary>
  TBatchAutoExecuteMode = (
    /// <summary>
    /// No auto execution.
    /// </summary>
    Manual = 0,

    /// <summary>
    /// Execute with RPC batch failure throwing an Exception.
    /// </summary>
    ExecuteWithFatalFailure = 1,

    /// <summary>
    /// Execute with RPC batch failures exceptions routed into callbacks.
    /// </summary>
    ExecuteWithCallbackFailures = 2
  );

  /// <summary>
  /// The encodings used for binary data to interact with the Solana nodes.
  /// </summary>
  TBinaryEncoding = (

     /// <summary>
    /// JSON with parsed data
    /// </summary>
    JsonParsed,

    /// <summary>
    /// Base64 encoding
    /// </summary>
    Base64,

    /// <summary>
    /// Base64 with zstd compression
    /// </summary>
    Base64Zstd
  );

  /// <summary>
  /// The commitment describes how finalized a block is at that point in time.
  /// </summary>
  TCommitment = (

    /// <summary>
    /// The node will query the most recent block confirmed by supermajority of the cluster as having reached maximum lockout, meaning the cluster has recognized this block as finalized.
    /// </summary>
    Finalized,

    /// <summary>
    /// The node will query the most recent block that has been voted on by supermajority of the cluster.
    /// </summary>
    Confirmed,

    /// <summary>
    /// The node will query its most recent block. Note that the block may not be complete.
    /// </summary>
    Processed

  );

  /// <summary>
  /// Enum with the possible vote selection parameter for the log subscription method.
  /// </summary>
  TLogsSubscriptionType = (
    /// <summary>
    /// Subscribes to All logs.
    /// </summary>
    All,

    /// <summary>
    /// Subscribes to All logs including votes.
    /// </summary>
    AllWithVotes
  );

  /// <summary>
  /// Used to specify which block data to retrieve.
  /// </summary>
  TTransactionDetails = (
    /// <summary>
    /// Retrieve the full block data.
    /// </summary>
    Full,
    /// <summary>
    /// Retrieve only signatures, leaving out detailed transaction data.
    /// </summary>
    Signatures,
    /// <summary>
    /// Retrieve only basic block data.
    /// </summary>
    None
  );

  /// <summary>
  /// Represents the filter type for block data.
  /// </summary>
  TTransactionDetailsFilterType = (
    /// <summary>
    /// Returns no transaction details.
    /// </summary>
    None,

    /// <summary>
    /// Returns only transaction signatures.
    /// </summary>
    Signatures,

    /// <summary>
    /// Returns full transaction details.
    /// </summary>
    Full
  );

    /// <summary>
  /// The possible types of Transaction errors.
  /// </summary>
  TTransactionErrorType = (
    /// <summary>
    /// An account is already being processed in another transaction in a way
    /// that does not support parallelism
    /// </summary>
    AccountInUse,
    /// <summary>
    /// A `Pubkey` appears twice in the transaction's `account_keys`. Instructions can reference
    /// `Pubkey`s more than once but the message must contain a list with no duplicate keys
    /// </summary>
    AccountLoadedTwice,
    /// <summary>
    /// Attempt to debit an account but found no record of a prior credit.
    /// </summary>
    AccountNotFound,
    /// <summary>
    /// Attempt to load a program that does not exist
    /// </summary>
    ProgramAccountNotFound,
    /// <summary>
    /// The from `Pubkey` does not have sufficient balance to pay the fee to schedule the transaction
    /// </summary>
    InsufficientFundsForFee,
    /// <summary>
    /// This account may not be used to pay transaction fees
    /// </summary>
    InvalidAccountForFee,
    /// <summary>
    /// The bank has seen this transaction before. This can occur under normal operation
    /// when a UDP packet is duplicated, as a user error from a client not updating
    /// its `recent_blockhash`, or as a double-spend attack.
    /// </summary>
    AlreadyProcessed,
    /// <summary>
    /// The bank has not seen the given `recent_blockhash` or the transaction is too old and
    /// the `recent_blockhash` has been discarded.
    /// </summary>
    BlockhashNotFound,
    /// <summary>
    /// An error occurred while processing an instruction.
    /// </summary>
    InstructionError,
    /// <summary>
    /// Loader call chain is too deep
    /// </summary>
    CallChainTooDeep,
    /// <summary>
    /// Transaction requires a fee but has no signature present
    /// </summary>
    MissingSignatureForFee,
    /// <summary>
    /// Transaction contains an invalid account reference
    /// </summary>
    InvalidAccountIndex,
    /// <summary>
    /// Transaction did not pass signature verification
    /// </summary>
    SignatureFailure,
    /// <summary>
    /// This program may not be used for executing instructions
    /// </summary>
    InvalidProgramForExecution,
    /// <summary>
    /// Transaction failed to sanitize accounts offsets correctly
    /// implies that account locks are not taken for this TX, and should
    /// not be unlocked.
    /// </summary>
    SanitizeFailure,
    /// <summary>
    /// Transactions are currently disabled due to cluster maintenance
    /// </summary>
    ClusterMaintenance,
    /// <summary>
    /// Transaction processing left an account with an outstanding borrowed reference
    /// </summary>
    AccountBorrowOutstanding,
    /// <summary>
    /// Transaction would exceed max Block Cost Limit.
    /// </summary>
    WouldExceedMaxBlockCostLimit,
    /// <summary>
    /// Transaction version is unsupported.
    /// </summary>
    UnsupportedVersion,
    /// <summary>
    /// Transaction loads a writable account that cannot be written.
    /// </summary>
    InvalidWritableAccount,
    /// <summary>
    /// Transaction would exceed max account limit within the block.
    /// </summary>
    WouldExceedMaxAccountCostLimit,
    /// <summary>
    /// Transaction would exceed max account data limit within the block.
    /// </summary>
    WouldExceedMaxAccountDataCostLimit,
    /// <summary>
    /// Transaction locked too many accounts.
    /// </summary>
    TooManyAccountLocks,
    /// <summary>
    /// Address lookup table not found.
    /// </summary>
    AddressLookupTableNotFound,
    /// <summary>
    /// Attempted to lookup addresses from an account owned by the wrong program.
    /// </summary>
    InvalidAddressLookupTableOwner,
    /// <summary>
    /// Attempted to lookup addresses from an invalid account.
    /// </summary>
    InvalidAddressLookupTableData,
    /// <summary>
    /// Address table lookup uses an invalid index.
    /// </summary>
    InvalidAddressLookupTableIndex,
    /// <summary>
    /// Transaction leaves an account with a lower balance than rent-exempt minimum.
    /// </summary>
    InvalidRentPayingAccount,
    /// <summary>
    /// Transaction would exceed max Vote Cost Limit.
    /// </summary>
    WouldExceedMaxVoteCostLimit,
    /// <summary>
    /// Transaction results in an account without insufficient funds for rent
    /// </summary>
    InsufficientFundsForRent
  );

type
  TInstructionErrorType = (
    /// <summary>
    /// The program instruction returned an error. (Deprecated)
    /// </summary>
    GenericError,

    /// <summary>
    /// The arguments provided to a program were invalid
    /// </summary>
    InvalidArgument,

    /// <summary>
    /// An instruction''s data contents were invalid
    /// </summary>
    InvalidInstructionData,

    /// <summary>
    /// An account''s data contents was invalid
    /// </summary>
    InvalidAccountData,

    /// <summary>
    /// An account''s data was too small
    /// </summary>
    AccountDataTooSmall,

    /// <summary>
    /// An account''s balance was too small to complete the instruction
    /// </summary>
    InsufficientFunds,

    /// <summary>
    /// The account did not have the expected program id
    /// </summary>
    IncorrectProgramId,

    /// <summary>
    /// A signature was required but not found
    /// </summary>
    MissingRequiredSignature,

    /// <summary>
    /// An initialize instruction was sent to an account that has already been initialized.
    /// </summary>
    AccountAlreadyInitialized,

    /// <summary>
    /// An attempt to operate on an account that hasn''t been initialized.
    /// </summary>
    UninitializedAccount,

    /// <summary>
    /// Program''s instruction lamport balance does not equal the balance after the instruction
    /// </summary>
    UnbalancedInstruction,

    /// <summary>
    /// Program modified an account''s program id
    /// </summary>
    ModifiedProgramId,

    /// <summary>
    /// Program spent the lamports of an account that doesn''t belong to it
    /// </summary>
    ExternalAccountLamportSpend,

    /// <summary>
    /// Program modified the data of an account that doesn''t belong to it
    /// </summary>
    ExternalAccountDataModified,

    /// <summary>
    /// Read-only account''s lamports modified
    /// </summary>
    ReadonlyLamportChange,

    /// <summary>
    /// Read-only account''s data was modified
    /// </summary>
    ReadonlyDataModified,

    /// <summary>
    /// An account was referenced more than once in a single instruction
    /// (Deprecated, instructions can now contain duplicate accounts)
    /// </summary>
    DuplicateAccountIndex,

    /// <summary>
    /// Executable bit on account changed, but shouldn''t have
    /// </summary>
    ExecutableModified,

    /// <summary>
    /// Rent_epoch account changed, but shouldn''t have
    /// </summary>
    RentEpochModified,

    /// <summary>
    /// The instruction expected additional account keys
    /// </summary>
    NotEnoughAccountKeys,

    /// <summary>
    /// A non-system program changed the size of the account data
    /// </summary>
    AccountDataSizeChanged,

    /// <summary>
    /// The instruction expected an executable account
    /// </summary>
    AccountNotExecutable,

    /// <summary>
    /// Failed to borrow a reference to account data, already borrowed
    /// </summary>
    AccountBorrowFailed,

    /// <summary>
    /// Account data has an outstanding reference after a program''s execution
    /// </summary>
    AccountBorrowOutstanding,

    /// <summary>
    /// The same account was multiply passed to an on-chain program''s entrypoint, but the program
    /// modified them differently. A program can only modify one instance of the account because
    /// the runtime cannot determine which changes to pick or how to merge them if both are modified
    /// </summary>
    DuplicateAccountOutOfSync,

    /// <summary>
    /// Allows on-chain programs to implement program-specific error types and see them returned
    /// by the Solana runtime. A program-specific error may be any type that is represented as
    /// or serialized to a u32 integer.
    /// </summary>
    Custom, // (u32)

    /// <summary>
    /// The return value from the program was invalid. Valid errors are either a defined builtin
    /// error value or a user-defined error in the lower 32 bits.
    /// </summary>
    InvalidError,

    /// <summary>
    /// Executable account''s data was modified
    /// </summary>
    ExecutableDataModified,

    /// <summary>
    /// Executable account''s lamports modified
    /// </summary>
    ExecutableLamportChange,

    /// <summary>
    /// Executable accounts must be rent exempt
    /// </summary>
    ExecutableAccountNotRentExempt,

    /// <summary>
    /// Unsupported program id
    /// </summary>
    UnsupportedProgramId,

    /// <summary>
    /// Cross-program invocation call depth too deep
    /// </summary>
    CallDepth,

    /// <summary>
    /// An account required by the instruction is missing
    /// </summary>
    MissingAccount,

    /// <summary>
    /// Cross-program invocation reentrancy not allowed for this instruction
    /// </summary>
    ReentrancyNotAllowed,

    /// <summary>
    /// Length of the seed is too long for address generation
    /// </summary>
    MaxSeedLengthExceeded,

    /// <summary>
    /// Provided seeds do not result in a valid address
    /// </summary>
    InvalidSeeds,

    /// <summary>
    /// Failed to reallocate account data of this length
    /// </summary>
    InvalidRealloc,

    /// <summary>
    /// Computational budget exceeded
    /// </summary>
    ComputationalBudgetExceeded,

    /// <summary>
    /// Cross-program invocation with unauthorized signer or writable account
    /// </summary>
    PrivilegeEscalation,

    /// <summary>
    /// Failed to create program execution environment
    /// </summary>
    ProgramEnvironmentSetupFailure,

    /// <summary>
    /// Program failed to complete
    /// </summary>
    ProgramFailedToComplete,

    /// <summary>
    /// Program failed to compile
    /// </summary>
    ProgramFailedToCompile,

    /// <summary>
    /// Account is immutable
    /// </summary>
    Immutable,

    /// <summary>
    /// Incorrect authority provided
    /// </summary>
    IncorrectAuthority,

    /// <summary>
    /// Failed to serialize or deserialize account data
    /// </summary>
    BorshIoError, // (String)

    /// <summary>
    /// An account does not have enough lamports to be rent-exempt
    /// </summary>
    AccountNotRentExempt,

    /// <summary>
    /// Invalid account owner
    /// </summary>
    InvalidAccountOwner,

    /// <summary>
    /// Program arithmetic overflowed
    /// </summary>
    ArithmeticOverflow,

    /// <summary>
    /// Unsupported sysvar
    /// </summary>
    UnsupportedSysvar,

    /// <summary>
    /// Illegal account owner.
    /// </summary>
    IllegalOwner,

    /// <summary>
    /// Account data allocation exceeded the maximum accounts data size limit.
    /// </summary>
    MaxAccountsDataSizeExceeded,

    /// <summary>
    /// Active vote account close.
    /// </summary>
    ActiveVoteAccountClose
  );

  /// <summary>
  /// The type of the reward.
  /// </summary>
  TRewardType = (
    /// <summary>
    /// Default value in case the returned value is undefined.
    /// </summary>
    Unknown,

    /// <summary>
    /// Fee reward.
    /// </summary>
    Fee,

    /// <summary>
    /// Rent reward.
    /// </summary>
    Rent,

    /// <summary>
    /// Voting reward.
    /// </summary>
    Voting,

    /// <summary>
    /// Staking reward.
    /// </summary>
    Staking
  );

  /// <summary>
  /// Represents the public Solana clusters.
  /// </summary>
  TCluster = (
    /// <summary>
    /// Devnet serves as a playground for anyone who wants to take Solana for a test drive, as a user, token holder, app developer, or validator.
    /// </summary>
    /// <remarks>
    /// Application developers should target Devnet.
    /// Potential validators should first target Devnet.
    /// Key points:
    /// <list type="bullet">
    ///   <item>Devnet tokens are not real</item>
    ///   <item>Devnet includes a token faucet for airdrops for application testing</item>
    ///   <item>Devnet may be subject to ledger resets</item>
    ///   <item>Devnet typically runs a newer software version than Mainnet Beta</item>
    /// </list>
    /// </remarks>
    DevNet,

    /// <summary>
    /// Testnet is where Solana stress tests recent release features on a live cluster, particularly focused on network performance, stability and validator behavior.
    /// </summary>
    /// <remarks>
    /// Tour de SOL initiative runs on Testnet, where malicious behavior and attacks are encouraged on the network to help find and squash bugs or network vulnerabilities.
    /// Key points:
    /// <list type="bullet">
    ///   <item>Devnet tokens are not real</item>
    ///   <item>Devnet includes a token faucet for airdrops for application testing</item>
    ///   <item>Devnet may be subject to ledger resets</item>
    ///   <item>Testnet typically runs a newer software release than both Devnet and Mainnet Beta</item>
    /// </list>
    /// </remarks>
    TestNet,

    /// <summary>
    /// A permissionless, persistent cluster for early token holders and launch partners. Currently, rewards and inflation are disabled.
    /// </summary>
    /// <remarks>
    /// Tokens that are issued on Mainnet Beta are real SOL.
    /// </remarks>
    MainNet
  );

  /// <summary>
  /// Represents the status of a subscription.
  /// </summary>
  TSubscriptionStatus = (
    /// <summary>
    /// Waiting for the subscription message to be handled.
    /// </summary>
    WaitingResult,

    /// <summary>
    /// The subscription was terminated.
    /// </summary>
    Unsubscribed,

    /// <summary>
    /// The subscription is still alive.
    /// </summary>
    Subscribed,

    /// <summary>
    /// There was an error during subscription.
    /// </summary>
    ErrorSubscribing
  );

implementation

end.
