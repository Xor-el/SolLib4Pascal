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

unit SlpRpcModel;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.Generics.Collections,
  System.JSON.Serializers,
  System.JSON.Converters,
  SlpRpcEnum,
  SlpNullable,
  SlpJsonClampNumberConverter,
  SlpAccountDataConverter,
  SlpJsonListConverter,
  SlpTransactionErrorJsonConverter,
  SlpNullableConverter,
  SlpTokenAccountDataConverter,
  SlpTransactionMetaInfoVersionConverter,
  SlpTransactionMetaInfoTransactionConverter;

  type
    TTokenBalance = class;
    TTokenAccountInfoDetails = class;
    TParsedTokenAccountData = class;
    TTokenAccountData = class;
    TTokenMintInfoDetails = class;
    TParsedTokenMintData = class;
    TTokenMintData = class;
    TRewardInfo = class;
    TTransactionMetaInfo = class;
    TInstructionInfo = class;
    TTokenBalanceInfo = class;
    TInnerInstruction = class;
    TAccountInfo = class;
    TInstructionError = class;
    TTransactionError = class;
    TLoadedAddresses = class;
    TVoteAccount = class;

    TRewardInfoCollectionConverter = class(TPreserveNullOnReadJsonObjectListConverter<TRewardInfo>);
    TTransactionMetaInfoCollectionConverter = class(TPreserveNullOnReadJsonObjectListConverter<TTransactionMetaInfo>);
    TInstructionInfoCollectionConverter = class(TPreserveNullOnReadJsonObjectListConverter<TInstructionInfo>);
    TInnerInstructionCollectionConverter = class(TPreserveNullOnReadJsonObjectListConverter<TInnerInstruction>);
    TTokenBalanceInfoCollectionConverter = class(TPreserveNullOnReadJsonObjectListConverter<TTokenBalanceInfo>);
    TAccountInfoCollectionConverter = class(TPreserveNullOnReadJsonObjectListConverter<TAccountInfo>);
    TVoteAccountCollectionConverter = class(TPreserveNullOnReadJsonObjectListConverter<TVoteAccount>);

    TBlockProductionInfoMapConverter = class(TJsonStringDictionaryConverter<TArray<Integer>>);

  /// <summary>
  /// The base class of the account info, to be subclassed for token account info classes
  /// </summary>
  TAccountInfoBase = class
  private
    FLamports: UInt64;
    FOwner: string;
    FExecutable: Boolean;
    FRentEpoch: UInt64;
    FSpace: UInt64;
  public
    /// <summary>
    /// The lamports balance of the account
    /// </summary>
    property Lamports: UInt64 read FLamports write FLamports;

    /// <summary>
    /// The account owner
    /// </summary>
    property Owner: string read FOwner write FOwner;

    /// <summary>
    /// Indicates whether the account contains a program (and is strictly read-only)
    /// </summary>
    property Executable: Boolean read FExecutable write FExecutable;

    /// <summary>
    /// The epoch at which the account will next owe rent
    /// </summary>
    /// <remarks>
    /// see the links below to understand the reason for the clamp converter
    /// References:
    /// <see href="https://github.com/gagliardetto/solana-go/issues/172">solana-go #172</see>,
    /// <see href="https://github.com/anza-xyz/agave/issues/2950">agave #2950</see>,
    /// <see href="https://github.com/magicblock-labs/Solana.Unity-Core/issues/49">Solana.Unity-Core #49</see>.
    /// </remarks>
    [JsonConverter(TJsonUInt64ClampNumberConverter)]
    property RentEpoch: UInt64 read FRentEpoch write FRentEpoch;

    /// <summary>
    /// The data size of the account
    /// </summary>
    property Space: UInt64 read FSpace write FSpace;
  end;

  /// <summary>
  /// Represents the account info
  /// </summary>
  TAccountInfo = class(TAccountInfoBase)
  private
    FData: TArray<string>;
  public
    /// <summary>
    /// The actual account data.
    /// <remarks>
    /// This field should contain two values: first value is the data, the second one is the encoding.
    /// </remarks>
    /// </summary>
    [JsonConverter(TAccountDataConverter)]
    property Data: TArray<string> read FData write FData;
  end;

  /// <summary>
  /// Represents the tuple account key and account data
  /// </summary>
  TAccountKeyPair = class
  private
    FAccount: TAccountInfo;
    FPublicKey: string;
  public
    /// <summary>
    /// The account info
    /// </summary>
    property Account: TAccountInfo read FAccount write FAccount;

    /// <summary>
    /// A base-58 encoded public key representing the account's public key
    /// </summary>
    [JsonName('pubkey')]
    property PublicKey: string read FPublicKey write FPublicKey;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents the account info for a given token account.
  /// </summary>
  TTokenAccountInfo = class(TAccountInfoBase)
  private
    FData: TValue;
  public
    destructor Destroy; override;

    [JsonConverter(TTokenAccountDataConverter)]
    property Data: TValue read FData write FData;
  end;

  /// <summary>
  /// Represents the account info for a given token account.
  /// </summary>
  TTokenMintInfo = class(TAccountInfoBase)
  private
    FData: TTokenMintData;
  public
    destructor Destroy; override;

    property Data: TTokenMintData read FData write FData;
  end;

  /// <summary>
  /// Represents a Token Mint account data.
  /// </summary>
  TTokenMintData = class
  private
    FProgram: string;
    FSpace: UInt64;
    FParsed: TParsedTokenMintData;
  public
    destructor Destroy; override;

    property &Program: string read FProgram write FProgram;
    property Space: UInt64 read FSpace write FSpace;
    property Parsed: TParsedTokenMintData read FParsed write FParsed;
  end;

  /// <summary>
  /// Represents the Token Mint parsed data, as formatted per SPL token program.
  /// </summary>
  TParsedTokenMintData = class
  private
    FInfo: TTokenMintInfoDetails;
    FType: string;
  public
    destructor Destroy; override;

    property Info: TTokenMintInfoDetails read FInfo write FInfo;
    property &Type: string read FType write FType;
  end;

  /// <summary>
  /// Represents a Token Mint account info as formatted per the SPL token program.
  /// </summary>
  TTokenMintInfoDetails = class
  private
    FFreezeAuthority: string;
    FMintAuthority: string;
    FDecimals: Byte;
    FIsInitialized: Boolean;
    FSupply: string;

    function GetSupplyUlong: UInt64;
  public
    property FreezeAuthority: string read FFreezeAuthority write FFreezeAuthority;
    property MintAuthority: string read FMintAuthority write FMintAuthority;
    property Decimals: Byte read FDecimals write FDecimals;
    property IsInitialized: Boolean read FIsInitialized write FIsInitialized;
    property Supply: string read FSupply write FSupply;

    property SupplyUlong: UInt64 read GetSupplyUlong;
  end;

  /// <summary>
  /// Represents the details of the info field of a token account.
  /// </summary>
  TTokenAccountInfoDetails = class
  private
    FTokenAmount: TTokenBalance;
    FDelegate: string;
    FDelegatedAmount: TTokenBalance;
    FState: string;
    FIsNative: Boolean;
    FMint: string;
    FOwner: string;
  public
    destructor Destroy; override;

    property TokenAmount: TTokenBalance read FTokenAmount write FTokenAmount;
    property Delegate: string read FDelegate write FDelegate;
    property DelegatedAmount: TTokenBalance read FDelegatedAmount write FDelegatedAmount;
    property State: string read FState write FState;
    property IsNative: Boolean read FIsNative write FIsNative;
    property Mint: string read FMint write FMint;
    property Owner: string read FOwner write FOwner;
  end;

  /// <summary>
  /// Represents the parsed account data, as available by the program-specific state parser.
  /// </summary>
  TParsedTokenAccountData = class
  private
    FType: string;
    FInfo: TTokenAccountInfoDetails;
  public
    destructor Destroy; override;

    property &Type: string read FType write FType;
    property Info: TTokenAccountInfoDetails read FInfo write FInfo;
  end;

  /// <summary>
  /// Represents the token balance of an account.
  /// </summary>
  TTokenBalance = class
  private
    FAmount: string;
    FDecimals: Integer;
    FUiAmount: TNullable<Double>;
    FUiAmountString: string;

    function GetAmountUInt64: UInt64;
    function GetAmountDouble: Double;
  public
    /// <summary>
    /// The raw token account balance without decimals.
    /// </summary>
    property Amount: string read FAmount write FAmount;
    /// <summary>
    /// The number of base 10 digits to the right of the decimal place.
    /// </summary>
    property Decimals: Integer read FDecimals write FDecimals;
    /// <summary>
    /// The token account balance, using mint-prescribed decimals. DEPRECATED.
    ///  `UiAmount` is deprecated, please use `UiAmountString` instead.
    /// </summary>
    [JsonConverter(TNullableDoubleConverter)]
    property UiAmount: TNullable<Double> read FUiAmount write FUiAmount;
    /// <summary>
    /// The token account balance as a string, using mint-prescribed decimals.
    /// </summary>
    property UiAmountString: string read FUiAmountString write FUiAmountString;

    /// <summary>
    /// The token account balance as a UInt64
    /// </summary>
    [JsonIgnore]
    property AmountUInt64: UInt64 read GetAmountUInt64;
    [JsonIgnore]
    property AmountDouble: Double read GetAmountDouble;
  end;

  /// <summary>
  /// Represents a token account's data.
  /// </summary>
  TTokenAccountData = class
  private
    FProgram: string;
    FSpace: UInt64;
    FParsed: TParsedTokenAccountData;
  public
    destructor Destroy; override;

    property &Program: string read FProgram write FProgram;
    property Space: UInt64 read FSpace write FSpace;
    property Parsed: TParsedTokenAccountData read FParsed write FParsed;
  end;

  /// <summary>
  /// Represents a large token account.
  /// </summary>
  TLargeTokenAccount = class(TTokenBalance)
  private
    FAddress: string;
  public
    property Address: string read FAddress write FAddress;
  end;

  /// <summary>
  /// Represents a large account.
  /// </summary>
  TLargeAccount = class
  private
    FLamports: UInt64;
    FAddress: string;
  public
    property Lamports: UInt64 read FLamports write FLamports;
    property Address: string read FAddress write FAddress;
  end;

  /// <summary>
  /// Represents the fee calculator info.
  /// </summary>
  TFeeCalculator = class
  private
    FLamportsPerSignature: UInt64;
  public
    /// <summary>
    /// The amount, in lamports, to be paid per signature.
    /// </summary>
    property LamportsPerSignature: UInt64 read FLamportsPerSignature write FLamportsPerSignature;
  end;

  /// <summary>
  /// Represents the fee calculator info.
  /// </summary>
  TFeeCalculatorInfo = class
  private
    FFeeCalculator: TFeeCalculator;
  public
    destructor Destroy; override;

    /// <summary>
    /// The fee calculator info.
    /// </summary>
    property FeeCalculator: TFeeCalculator read FFeeCalculator write FFeeCalculator;
  end;

  /// <summary>
  /// Represents block hash info.
  /// </summary>
  TBlockHash = class
  private
    FBlockhash: string;
    FFeeCalculator: TFeeCalculator;
  public
    destructor Destroy; override;

    /// <summary>
    /// A base-58 encoded string representing the block hash.
    /// </summary>
    property Blockhash: string read FBlockhash write FBlockhash;

    /// <summary>
    /// The fee calculator data.
    /// </summary>
    property FeeCalculator: TFeeCalculator read FFeeCalculator write FFeeCalculator;
  end;

  /// <summary>
  /// Represents the latest block hash info.
  /// </summary>
  TLatestBlockHash = class
  private
    FBlockhash: string;
    FLastValidBlockHeight: UInt64;
  public
    /// <summary>
    /// A base-58 encoded string representing the block hash.
    /// </summary>
    property Blockhash: string read FBlockhash write FBlockhash;

    /// <summary>
    /// The last block height at which the blockhash will be valid.
    /// </summary>
    property LastValidBlockHeight: UInt64 read FLastValidBlockHeight write FLastValidBlockHeight;
  end;

  /// <summary>
  /// Represents the block commitment info.
  /// </summary>
  TBlockCommitment = class
  private
    FCommitment: TArray<UInt64>;
    FTotalStake: UInt64;
  public
    /// <summary>
    /// A list of values representing the amount of cluster stake in lamports that has
    /// voted onn the block at each depth from 0 to (max lockout history + 1).
    /// </summary>
    property Commitment: TArray<UInt64> read FCommitment write FCommitment;

    /// <summary>
    /// Total active stake, in lamports, of the current epoch.
    /// </summary>
    property TotalStake: UInt64 read FTotalStake write FTotalStake;
  end;

  /// <summary>
  /// Represents the block info.
  /// </summary>
  TBlockInfo = class
  private
    FBlockTime: Int64;
    FBlockhash: string;
    FPreviousBlockhash: string;
    FParentSlot: UInt64;
    FBlockHeight: TNullable<UInt64>;
    FMaxSupportedTransactionVersion: Integer;

    FRewards: TObjectList<TRewardInfo>;
    FTransactions: TObjectList<TTransactionMetaInfo>;
  public
    destructor Destroy; override;

    /// <summary>
    /// Estimated block production time.
    /// </summary>
    property BlockTime: Int64 read FBlockTime write FBlockTime;

    /// <summary>
    /// A base-58 encoded public key representing the block hash.
    /// </summary>
    property Blockhash: string read FBlockhash write FBlockhash;

    /// <summary>
    /// A base-58 encoded public key representing the block hash of this block's parent.
    /// <remarks>
    /// If the parent block is no longer available due to ledger cleanup, this field will return
    /// '11111111111111111111111111111111'
    /// </remarks>
    /// </summary>
    property PreviousBlockhash: string read FPreviousBlockhash write FPreviousBlockhash;

    /// <summary>
    /// The slot index of this block's parent.
    /// </summary>
    property ParentSlot: UInt64 read FParentSlot write FParentSlot;

    /// <summary>
    /// The number of blocks beneath this block.
    /// </summary>
    [JsonConverter(TNullableUInt64Converter)]
    property BlockHeight: TNullable<UInt64> read FBlockHeight write FBlockHeight;

    /// <summary>
    /// Max transaction version allowed
    /// </summary>
    property MaxSupportedTransactionVersion: Integer read FMaxSupportedTransactionVersion write FMaxSupportedTransactionVersion;

    /// <summary>
    /// The rewards for this given block.
    /// </summary>
    [JsonConverter(TRewardInfoCollectionConverter)]
    property Rewards: TObjectList<TRewardInfo> read FRewards write FRewards;

    /// <summary>
    /// Collection of transactions and their metadata within this block.
    /// </summary>
    [JsonConverter(TTransactionMetaInfoCollectionConverter)]
    property Transactions: TObjectList<TTransactionMetaInfo> read FTransactions write FTransactions;
  end;

  /// <summary>
  /// Represents the reward information related to a given account.
  /// </summary>
  TRewardInfo = class
  private
    FPubkey: string;
    FLamports: Int64;
    FPostBalance: UInt64;
    FRewardType: TRewardType;
  public
    /// <summary>
    /// The account pubkey as base58 encoded string.
    /// </summary>
    property Pubkey: string read FPubkey write FPubkey;

    /// <summary>
    /// Number of reward lamports credited or debited by the account.
    /// </summary>
    property Lamports: Int64 read FLamports write FLamports;

    /// <summary>
    /// Account balance in lamports after the reward was applied.
    /// </summary>
    property PostBalance: UInt64 read FPostBalance write FPostBalance;

    /// <summary>
    /// The epoch in which the reward was credited or debited.
    /// </summary>
    property RewardType: TRewardType read FRewardType write FRewardType;
  end;

  /// <summary>
  /// Represents the data of given instruction.
  /// </summary>
  TInstructionInfo = class
  private
    FProgramIdIndex: Integer;
    FAccounts: TArray<Integer>;
    FData: string;
  public
    /// <summary>
    /// Index into the <i>Message.AccountKeys</i> array indicating the program account that executes this instruction.
    /// </summary>
    property ProgramIdIndex: Integer read FProgramIdIndex write FProgramIdIndex;

    /// <summary>
    /// List of ordered indices into the <i>Message.AccountKeys</i> array indicating which accounts to pass to the program.
    /// </summary>
    property Accounts: TArray<Integer> read FAccounts write FAccounts;

    /// <summary>
    /// The program input data encoded in a base-58 string.
    /// </summary>
    property Data: string read FData write FData;
  end;

  /// <summary>
  /// Represents an inner instruction. Inner instruction are cross-program instructions that are invoked during transaction processing.
  /// </summary>
  TInnerInstruction = class
  private
    FIndex: Integer;
    FInstructions: TObjectList<TInstructionInfo>;
  public
    /// <summary>
    /// Index of the transaction instruction from which the inner instruction(s) originated
    /// </summary>
    property Index: Integer read FIndex write FIndex;

    /// <summary>
    /// List of program instructions that will be executed in sequence and committed in one atomic transaction if all succeed.
    /// </summary>
    [JsonConverter(TInstructionInfoCollectionConverter)]
    property Instructions: TObjectList<TInstructionInfo> read FInstructions write FInstructions;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents the structure of a token balance metadata for a transaction.
  /// </summary>
  TTokenBalanceInfo = class
  private
    FAccountIndex: Integer;
    FMint: string;
    FOwner: string;
    FUiTokenAmount: TTokenBalance;
  public
    /// <summary>
    /// Index of the account in which the token balance is provided for.
    /// </summary>
    property AccountIndex: Integer read FAccountIndex write FAccountIndex;

    /// <summary>
    /// Pubkey of the token's mint.
    /// </summary>
    property Mint: string read FMint write FMint;

    /// <summary>
    /// Pubkey of the token owner
    /// </summary>
    property Owner: string read FOwner write FOwner;

    /// <summary>
    /// Token balance details.
    /// </summary>
    property UiTokenAmount: TTokenBalance read FUiTokenAmount write FUiTokenAmount;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents the transaction metadata.
  /// </summary>
  TTransactionMeta = class
  private
    FError: TTransactionError;
    FFee: UInt64;
    FPreBalances: TArray<UInt64>;
    FPostBalances: TArray<UInt64>;
    FInnerInstructions: TObjectList<TInnerInstruction>;
    FPreTokenBalances: TObjectList<TTokenBalanceInfo>;
    FPostTokenBalances: TObjectList<TTokenBalanceInfo>;
    FLogMessages: TArray<string>;
    FRewards: TObjectList<TRewardInfo>;
    FLoadedAddresses: TLoadedAddresses;
  public
    /// <summary>
    /// Possible transaction error.
    /// </summary>
    [JsonName('err')]
    property Error: TTransactionError read FError write FError;

    /// <summary>
    /// Fee this transaction was charged.
    /// </summary>
    property Fee: UInt64 read FFee write FFee;

    /// <summary>
    /// Collection of account balances from before the transaction was processed.
    /// </summary>
    property PreBalances: TArray<UInt64> read FPreBalances write FPreBalances;

    /// <summary>
    /// Collection of account balances after the transaction was processed.
    /// </summary>
    property PostBalances: TArray<UInt64> read FPostBalances write FPostBalances;

    /// <summary>
    /// List of inner instructions or omitted if inner instruction recording was not yet enabled during this transaction.
    /// </summary>
    [JsonConverter(TInnerInstructionCollectionConverter)]
    property InnerInstructions: TObjectList<TInnerInstruction> read FInnerInstructions write FInnerInstructions;

    /// <summary>
    /// List of token balances from before the transaction was processed or omitted if token balance recording was not yet enabled during this transaction.
    /// </summary>
    [JsonConverter(TTokenBalanceInfoCollectionConverter)]
    property PreTokenBalances: TObjectList<TTokenBalanceInfo> read FPreTokenBalances write FPreTokenBalances;

    /// <summary>
    /// List of token balances from after the transaction was processed or omitted if token balance recording was not yet enabled during this transaction.
    /// </summary>
    [JsonConverter(TTokenBalanceInfoCollectionConverter)]
    property PostTokenBalances: TObjectList<TTokenBalanceInfo> read FPostTokenBalances write FPostTokenBalances;

    /// <summary>
    /// Array of string log messages or omitted if log message recording was not yet enabled during this transaction.
    /// </summary>
    property LogMessages: TArray<string> read FLogMessages write FLogMessages;

    /// <summary>
    /// Transaction-level rewards, populated if rewards are requested
    /// </summary>
    [JsonConverter(TRewardInfoCollectionConverter)]
    property Rewards: TObjectList<TRewardInfo> read FRewards write FRewards;

    /// <summary>
    /// Transaction addresses loaded from address lookup tables.
    /// </summary>
    property LoadedAddresses: TLoadedAddresses read FLoadedAddresses write FLoadedAddresses;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Transaction addresses loaded from address lookup tables.
  /// </summary>
  TLoadedAddresses = class
  private
    FWritable: TArray<string>;
    FReadonly: TArray<string>;
  public
    /// <summary>
    /// Writable address list
    /// </summary>
    property Writable: TArray<string> read FWritable write FWritable;

    /// <summary>
    /// Readonly address list
    /// </summary>
    property Readonly: TArray<string> read FReadonly write FReadonly;
  end;

  /// <summary>
  /// Details the number and type of accounts and signatures in a given transaction.
  /// </summary>
  TTransactionHeaderInfo = class
  private
    FNumRequiredSignatures: Integer;
    FNumReadonlySignedAccounts: Integer;
    FNumReadonlyUnsignedAccounts: Integer;
  public
    /// <summary>
    /// The total number of signatures required to make the transaction valid.
    /// </summary>
    property NumRequiredSignatures: Integer read FNumRequiredSignatures write FNumRequiredSignatures;

    /// <summary>
    /// The last NumReadonlySignedAccounts of the signed keys are read-only accounts.
    /// </summary>
    property NumReadonlySignedAccounts: Integer read FNumReadonlySignedAccounts write FNumReadonlySignedAccounts;

    /// <summary>
    /// The last NumReadonlyUnsignedAccounts of the unsigned keys are read-only accounts.
    /// </summary>
    property NumReadonlyUnsignedAccounts: Integer read FNumReadonlyUnsignedAccounts write FNumReadonlyUnsignedAccounts;
  end;

  /// <summary>
  /// Represents the contents of the trasaction.
  /// </summary>
  TTransactionContentInfo = class
  private
    FAccountKeys: TArray<string>;
    FHeader: TTransactionHeaderInfo;
    FRecentBlockhash: string;
    FInstructions: TObjectList<TInstructionInfo>;
  public
    /// <summary>
    /// List of base-58 encoded public keys used by the transaction, including by the instructions and for signatures.
    /// </summary>
    property AccountKeys: TArray<string> read FAccountKeys write FAccountKeys;

    /// <summary>
    /// Details the account types and signatures required by the transaction.
    /// </summary>
    property Header: TTransactionHeaderInfo read FHeader write FHeader;

    /// <summary>
    ///  A base-58 encoded hash of a recent block in the ledger used to prevent transaction duplication and to give transactions lifetimes.
    /// </summary>
    property RecentBlockhash: string read FRecentBlockhash write FRecentBlockhash;

    /// <summary>
    /// List of program instructions that will be executed in sequence and committed in one atomic transaction if all succeed.
    /// </summary>
    [JsonConverter(TInstructionInfoCollectionConverter)]
    property Instructions: TObjectList<TInstructionInfo> read FInstructions write FInstructions;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents a transaction.
  /// </summary>
  TTransactionInfo = class
  private
    FSignatures: TArray<string>;
    FMessage: TTransactionContentInfo;
  public
    /// <summary>
    /// The signatures of this transaction.
    /// </summary>
    property Signatures: TArray<string> read FSignatures write FSignatures;

    /// <summary>
    /// The message contents of the transaction.
    /// </summary>
    property Message: TTransactionContentInfo read FMessage write FMessage;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents the tuple transaction and metadata.
  /// </summary>
  TTransactionMetaInfo = class
  private
    FTransaction, FVersion: TValue;
    FMeta: TTransactionMeta;
  public
    /// <summary>
    /// The transaction information.
    /// </summary>
    [JsonConverter(TTransactionMetaInfoTransactionConverter)]
    property Transaction: TValue read FTransaction write FTransaction;

    /// <summary>
    /// The metadata information.
    /// </summary>
    property Meta: TTransactionMeta read FMeta write FMeta;

    /// <summary>
    /// Transaction Version
    /// </summary>
    [JsonConverter(TTransactionMetaInfoVersionConverter)]
    property Version: TValue read FVersion write FVersion;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents the transaction, metadata and its containing slot.
  /// </summary>
  TTransactionMetaSlotInfo = class(TTransactionMetaInfo)
  private
    FSlot: UInt64;
    FBlockTime: TNullable<Int64>;
  public
    /// <summary>
    /// The slot this transaction was processed in.
    /// </summary>
    property Slot: UInt64 read FSlot write FSlot;

    /// <summary>
    /// Estimated block production time.
    /// </summary>
    [JsonConverter(TNullableInt64Converter)]
    property BlockTime: TNullable<Int64> read FBlockTime write FBlockTime;
  end;

  /// <summary>
  /// Represents a log during transaction simulation
  /// </summary>
  TLog = class
  private
    FError: TTransactionError;
    FLogs: TArray<string>;
  public
    /// <summary>
    /// The error associated with the transaction simulation
    /// </summary>
    [JsonName('err')]
    property Error: TTransactionError read FError write FError;

    /// <summary>
    /// The log messages the transaction instructions output during execution
    /// </summary>
    property Logs: TArray<string> read FLogs write FLogs;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents a log message when subscribing to the log output of the Streaming RPC
  /// </summary>
  TLogInfo = class(TLog)
  private
    FSignature: string;
  public
    /// <summary>
    /// The signature of the transaction
    /// </summary>
    property Signature: string read FSignature write FSignature;
  end;

  /// <summary>
  /// Represents the result of a transaction simulation
  /// </summary>
  TSimulationLogs = class
  private
    FAccounts: TObjectList<TAccountInfo>;
    FError: TTransactionError;
    FLogs: TArray<string>;
    FUnitsConsumed: TNullable<UInt64>;
  public
    /// <summary>
    /// Account infos as requested in the simulateTransaction method
    /// </summary>
    [JsonConverter(TAccountInfoCollectionConverter)]
    property Accounts: TObjectList<TAccountInfo> read FAccounts write FAccounts;

    /// <summary>
    /// The error associated with the transaction simulation
    /// </summary>
    [JsonName('err')]
    property Error: TTransactionError read FError write FError;

    /// <summary>
    /// The log messages the transaction instructions output during execution
    /// </summary>
    property Logs: TArray<string> read FLogs write FLogs;

    /// <summary>
    /// The units consumed during the transaction simulation
    /// </summary>
    [JsonConverter(TNullableUInt64Converter)]
    property UnitsConsumed: TNullable<UInt64> read FUnitsConsumed write FUnitsConsumed;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents a complete error message.
  /// </summary>
  /// <remarks>See RpcError::RpcResponseError in solana\client\src\rpc_request.rs</remarks>
  TErrorData = class(TSimulationLogs)

  end;

  // Represents an instruction error
  TInstructionError = class
  private
    FInstructionIndex: Integer;
    FType: TInstructionErrorType;
    FCustomError: TNullable<UInt32>;
    FBorshIoError: string;
  public
    property InstructionIndex: Integer read FInstructionIndex write FInstructionIndex;
    property &Type: TInstructionErrorType read FType write FType;
    property CustomError: TNullable<UInt32> read FCustomError write FCustomError;
    property BorshIoError: string read FBorshIoError write FBorshIoError;
  end;

  /// <summary>
  /// Represents a Transaction Error.
  /// </summary>
  [JsonConverter(TTransactionErrorJsonConverter)]
  TTransactionError = class
  private
    FType: TTransactionErrorType;
    FInstructionError: TInstructionError;
  public
    property &Type: TTransactionErrorType read FType write FType;
    property InstructionError: TInstructionError read FInstructionError write FInstructionError;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents a slot range.
  /// </summary>
  TSlotRange = class
  private
    FFirstSlot: UInt64;
    FLastSlot: UInt64;
  public
    /// <summary>
    /// The first slot of the range (inclusive).
    /// </summary>
    property FirstSlot: UInt64 read FFirstSlot write FFirstSlot;

    /// <summary>
    /// The last slot of the range (inclusive).
    /// </summary>
    property LastSlot: UInt64 read FLastSlot write FLastSlot;
  end;

  /// <summary>
  /// Holds the block production information.
  /// </summary>
  TBlockProductionInfo = class
  private
    FByIdentity: TDictionary<string, TArray<Integer>>;
    FRange: TSlotRange;
  public
    /// <summary>
    /// The block production as a map from the validator to a list
    /// of the number of leader slots and number of blocks produced
    /// </summary>
    [JsonConverter(TBlockProductionInfoMapConverter)]
    property ByIdentity: TDictionary<string, TArray<Integer>> read FByIdentity write FByIdentity;

    /// <summary>
    /// The block production range by slots.
    /// </summary>
    property Range: TSlotRange read FRange write FRange;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents a node in the cluster.
  /// </summary>
  TClusterNode = class
  private
    FGossip: string;
    FPublicKey: string;
    FRpc: string;
    FTpu: string;
    FVersion: string;
    FFeatureSet: TNullable<UInt64>;
    FShredVersion: UInt64;
  public
    /// <summary>
    /// Gossip network address for the node.
    /// </summary>
    property Gossip: string read FGossip write FGossip;

    /// <summary>
    /// A base-58 encoded public key associated with the node.
    /// </summary>
    [JsonName('pubkey')]
    property PublicKey: string read FPublicKey write FPublicKey;

    /// <summary>
    /// JSON RPC network address for the node. The service may not be enabled.
    /// </summary>
    property Rpc: string read FRpc write FRpc;

    /// <summary>
    /// TPU network address for the node.
    /// </summary>
    property Tpu: string read FTpu write FTpu;

    /// <summary>
    /// The software version of the node. The information may not be available.
    /// </summary>
    property Version: string read FVersion write FVersion;

    /// <summary>
    /// Unique identifier of the current software's feature set.
    /// </summary>
    [JsonConverter(TNullableUInt64Converter)]
    property FeatureSet: TNullable<UInt64> read FFeatureSet write FFeatureSet;

    /// <summary>
    /// The shred version the node has been configured to use.
    /// </summary>
    property ShredVersion: UInt64 read FShredVersion write FShredVersion;
  end;

    /// <summary>
  /// Represents information about the current epoch.
  /// </summary>
  TEpochInfo = class
  private
    FAbsoluteSlot: UInt64;
    FBlockHeight: UInt64;
    FEpoch: UInt64;
    FSlotIndex: UInt64;
    FSlotsInEpoch: UInt64;
  public
    /// <summary>
    /// The current slot.
    /// </summary>
    property AbsoluteSlot: UInt64 read FAbsoluteSlot write FAbsoluteSlot;

    /// <summary>
    /// The current block height.
    /// </summary>
    property BlockHeight: UInt64 read FBlockHeight write FBlockHeight;

    /// <summary>
    /// The current epoch.
    /// </summary>
    property Epoch: UInt64 read FEpoch write FEpoch;

    /// <summary>
    /// The current slot relative to the start of the current epoch.
    /// </summary>
    property SlotIndex: UInt64 read FSlotIndex write FSlotIndex;

    /// <summary>
    /// The number of slots in this epoch
    /// </summary>
    property SlotsInEpoch: UInt64 read FSlotsInEpoch write FSlotsInEpoch;
  end;

  /// <summary>
  /// Represents information about the epoch schedule.
  /// </summary>
  TEpochScheduleInfo = class
  private
    FSlotsPerEpoch: UInt64;
    FLeaderScheduleSlotOffset: UInt64;
    FFirstNormalEpoch: UInt64;
    FFirstNormalSlot: UInt64;
    FWarmup: Boolean;
  public
    /// <summary>
    /// The maximum number of slots in each epoch.
    /// </summary>
    property SlotsPerEpoch: UInt64 read FSlotsPerEpoch write FSlotsPerEpoch;

    /// <summary>
    /// The number of slots before beginning of an epoch to calculate a leader schedule for that epoch.
    /// </summary>
    property LeaderScheduleSlotOffset: UInt64 read FLeaderScheduleSlotOffset write FLeaderScheduleSlotOffset;

    /// <summary>
    /// The first normal-length epoch.
    /// </summary>
    property FirstNormalEpoch: UInt64 read FFirstNormalEpoch write FFirstNormalEpoch;

    /// <summary>
    /// The first normal-length slot.
    /// </summary>
    property FirstNormalSlot: UInt64 read FFirstNormalSlot write FFirstNormalSlot;

    /// <summary>
    /// Whether epochs start short and grow.
    /// </summary>
    property Warmup: Boolean read FWarmup write FWarmup;

  end;

  /// <summary>
  /// Holds an error result.
  /// </summary>
  TErrorResult = class
  private
    FError: TTransactionError;
  public
    /// <summary>
    /// The error string.
    /// </summary>
    [JsonName('err')]
    property Error: TTransactionError read FError write FError;

    /// <summary>
    /// Destructor. Frees owned reference types (if any).
    /// </summary>
    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents the fee rate governor.
  /// </summary>
  TFeeRateGovernor = class
  private
    FBurnPercent: Double;
    FMaxLamportsPerSignature: UInt64;
    FMinLamportsPerSignature: UInt64;
    FTargetLamportsPerSignature: UInt64;
    FTargetSignaturesPerSlot: UInt64;
  public
    /// <summary>
    /// Percentage of fees collected to be destroyed.
    /// </summary>
    property BurnPercent: Double read FBurnPercent write FBurnPercent;

    /// <summary>
    /// Highest value LamportsPerSignature can attain for the next slot.
    /// </summary>
    property MaxLamportsPerSignature: UInt64 read FMaxLamportsPerSignature write FMaxLamportsPerSignature;

    /// <summary>
    /// Smallest value LamportsPerSignature can attain for the next slot.
    /// </summary>
    property MinLamportsPerSignature: UInt64 read FMinLamportsPerSignature write FMinLamportsPerSignature;

    /// <summary>
    /// Desired fee rate for the cluster.
    /// </summary>
    property TargetLamportsPerSignature: UInt64 read FTargetLamportsPerSignature write FTargetLamportsPerSignature;

    /// <summary>
    /// Desired signature rate for the cluster.
    /// </summary>
    property TargetSignaturesPerSlot: UInt64 read FTargetSignaturesPerSlot write FTargetSignaturesPerSlot;
  end;

  /// <summary>
  /// Represents the fee rate governor info.
  /// </summary>
  TFeeRateGovernorInfo = class
  private
    FFeeRateGovernor: TFeeRateGovernor;
  public
    /// <summary>
    /// The fee rate governor.
    /// </summary>
    property FeeRateGovernor: TFeeRateGovernor read FFeeRateGovernor write FFeeRateGovernor;

    /// <summary>
    /// Destructor. Frees the owned FeeRateGovernor instance if assigned.
    /// </summary>
    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents information about the fees.
  /// </summary>
  TFeesInfo = class
  private
    FBlockhash: string;
    FFeeCalculator: TFeeCalculator;
    FLastValidSlot, FLastValidBlockHeight: UInt64;
  public
    /// <summary>
    /// A block hash as base-58 encoded string.
    /// </summary>
    property Blockhash: string read FBlockhash write FBlockhash;

    /// <summary>
    /// The fee calculator for this block hash.
    /// </summary>
    property FeeCalculator: TFeeCalculator read FFeeCalculator write FFeeCalculator;

    /// <summary>
    /// DEPRECATED - this value is inaccurate and should not be relied upon
    /// </summary>
    property LastValidSlot: UInt64 read FLastValidSlot write FLastValidSlot;

    /// <summary>
    /// Last block height at which a blockhash will be valid.
    /// </summary>
    property LastValidBlockHeight: UInt64 read FLastValidBlockHeight write FLastValidBlockHeight;

    /// <summary>
    /// Destructor. Frees the owned FeeCalculator instance if assigned.
    /// </summary>
    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents information about the prioritization fees.
  /// </summary>
  TPrioritizationFeeItem = class
  private
    FSlot: UInt64;
    FPrioritizationFee: UInt64;
  public
    /// <summary>
    /// Slot in which the fee was observed.
    /// </summary>
    property Slot: UInt64 read FSlot write FSlot;

    /// <summary>
    /// The per-compute-unit fee paid by at least one successfully landed transaction,
    /// specified in increments of micro-lamports.
    /// </summary>
    property PrioritizationFee: UInt64 read FPrioritizationFee write FPrioritizationFee;
  end;

  /// <summary>
  /// Represents the <c>memcmp</c> filter for the <see cref="IRpcClient.GetProgramAccounts"/> method.
  /// </summary>
  TMemCmp = class
  private
    FOffset: Integer;
    FBytes: string;
  public
    /// <summary>
    /// The offset into program account data at which to start the comparison.
    /// </summary>
    property Offset: Integer read FOffset write FOffset;

    /// <summary>
    /// The data to match against the program data, as base-58 encoded string and limited to 129 bytes.
    /// </summary>
    property Bytes: string read FBytes write FBytes;
  end;

  /// <summary>
  /// Represents the <c>dataSlice</c> for the <see cref="IRpcClient.GetProgramAccounts"/> method.
  /// </summary>
  TDataSlice = class
  private
    FLength, FOffset: Integer;
  public
    /// <summary>
    /// The number of bytes to return.
    /// </summary>
    property Length: Integer read FLength write FLength;

    /// <summary>
    /// The byte offset from which to start reading.
    /// </summary>
    property Offset: Integer read FOffset write FOffset;
  end;

  /// <summary>
  /// Represents the identity public key for the current node.
  /// </summary>
  TNodeIdentity = class
  private
    FIdentity: string;
  public
    /// <summary>
    /// The identity public key of the current node, as base-58 encoded string.
    /// </summary>
    property Identity: string read FIdentity write FIdentity;
  end;

  /// <summary>
  /// Represents inflation governor information.
  /// </summary>
  TInflationGovernor = class
  private
    FInitial: Double;
    FTerminal: Double;
    FTaper: Double;
    FFoundation: Double;
    FFoundationTerm: Double;
  public
    /// <summary>
    /// The initial inflation percentage from time zero.
    /// </summary>
    property Initial: Double read FInitial write FInitial;

    /// <summary>
    /// The terminal inflation percentage.
    /// </summary>
    property Terminal: Double read FTerminal write FTerminal;

    /// <summary>
    /// The rate per year at which inflation is lowered.
    /// <remarks>Rate reduction is derived using the target slot time as per genesis config.</remarks>
    /// </summary>
    property Taper: Double read FTaper write FTaper;

    /// <summary>
    /// Percentage of total inflation allocated to the foundation.
    /// </summary>
    property Foundation: Double read FFoundation write FFoundation;

    /// <summary>
    /// Duration of foundation pool inflation in years.
    /// </summary>
    property FoundationTerm: Double read FFoundationTerm write FFoundationTerm;
  end;

  /// <summary>
  /// Represents the inflation rate information.
  /// </summary>
  TInflationRate = class
  private
    FEpoch: Double;
    FFoundation: Double;
    FTotal: Double;
    FValidator: Double;
  public
    /// <summary>
    /// Epoch for which these values are valid.
    /// </summary>
    property Epoch: Double read FEpoch write FEpoch;

    /// <summary>
    /// Percentage of total inflation allocated to the foundation.
    /// </summary>
    property Foundation: Double read FFoundation write FFoundation;

    /// <summary>
    /// Percentage of total inflation.
    /// </summary>
    property Total: Double read FTotal write FTotal;

    /// <summary>
    /// Percentage of total inflation allocated to validators.
    /// </summary>
    property Validator: Double read FValidator write FValidator;
  end;

  /// <summary>
  /// Represents the inflation reward for a certain address.
  /// </summary>
  TInflationReward = class
  private
    FEpoch: UInt64;
    FEffectiveSlot: UInt64;
    FAmount: UInt64;
    FPostBalance: UInt64;
  public
    /// <summary>
    /// Epoch for which a reward occurred.
    /// </summary>
    property Epoch: UInt64 read FEpoch write FEpoch;

    /// <summary>
    /// The slot in which the rewards are effective.
    /// </summary>
    property EffectiveSlot: UInt64 read FEffectiveSlot write FEffectiveSlot;

    /// <summary>
    /// The reward amount in lamports.
    /// </summary>
    property Amount: UInt64 read FAmount write FAmount;

    /// <summary>
    /// Post balance of the account in lamports.
    /// </summary>
    property PostBalance: UInt64 read FPostBalance write FPostBalance;
  end;

  /// <summary>
  /// Represents a performance sample.
  /// </summary>
  TPerformanceSample = class
  private
    FSlot: UInt64;
    FNumTransactions: UInt64;
    FNumSlots: UInt64;
    FSamplePeriodSecs: Integer;
  public
    /// <summary>
    /// Slot in which sample was taken at.
    /// </summary>
    property Slot: UInt64 read FSlot write FSlot;

    /// <summary>
    /// Number of transactions in sample.
    /// </summary>
    property NumTransactions: UInt64 read FNumTransactions write FNumTransactions;

    /// <summary>
    /// Number of slots in sample
    /// </summary>
    property NumSlots: UInt64 read FNumSlots write FNumSlots;

    /// <summary>
    /// Number of seconds in a sample window.
    /// </summary>
    property SamplePeriodSecs: Integer read FSamplePeriodSecs write FSamplePeriodSecs;
  end;

    /// <summary>
  /// Represents the signature status information.
  /// </summary>
  TSignatureStatusInfo = class
  private
    FSlot: UInt64;
    FConfirmations: TNullable<UInt64>;
    FError: TTransactionError;
    FConfirmationStatus: string;
    FMemo: string;
    FSignature: string;
    FBlockTime: TNullable<UInt64>;
  public
    /// <summary>
    /// The slot the transaction was processed in.
    /// </summary>
    property Slot: UInt64 read FSlot write FSlot;

    /// <summary>
    /// The number of blocks since signature confirmation.
    /// </summary>
    [JsonConverter(TNullableUInt64Converter)]
    property Confirmations: TNullable<UInt64> read FConfirmations write FConfirmations;

    /// <summary>
    /// The error if the transaction failed, null if it succeeded.
    /// </summary>
    [JsonName('err')]
    property Error: TTransactionError read FError write FError;

    /// <summary>
    /// The transaction's cluster confirmation status, either "processed", "confirmed" or "finalized".
    /// </summary>
    property ConfirmationStatus: string read FConfirmationStatus write FConfirmationStatus;

    /// <summary>
    /// Memo associated with the transaction, null if no memo is present.
    /// </summary>
    property Memo: string read FMemo write FMemo;

    /// <summary>
    /// The transaction signature as base-58 encoded string.
    /// </summary>
    property Signature: string read FSignature write FSignature;

    /// <summary>
    /// Estimated production time as Unix timestamp, null if not available.
    /// </summary>
    [JsonConverter(TNullableUInt64Converter)]
    property BlockTime: TNullable<UInt64> read FBlockTime write FBlockTime;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents the slot info.
  /// </summary>
  TSlotInfo = class
  private
    FParent: Integer;
    FRoot: Integer;
    FSlot: Integer;
  public
    /// <summary>
    /// The parent slot.
    /// </summary>
    property Parent: Integer read FParent write FParent;

    /// <summary>
    /// The root as set by the validator.
    /// </summary>
    property Root: Integer read FRoot write FRoot;

    /// <summary>
    /// The current slot.
    /// </summary>
    property Slot: Integer read FSlot write FSlot;
  end;

  /// <summary>
  /// The highest snapshot slot info.
  /// </summary>
  TSnapshotSlotInfo = class
  private
    FFull: UInt64;
    FIncremental: TNullable<UInt64>;
  public
    /// <summary>
    /// The highest full snapshot slot.
    /// </summary>
    property Full: UInt64 read FFull write FFull;

    /// <summary>
    /// The highest incremental snapshot slot based on <see cref="Full"/>.
    /// </summary>
    [JsonConverter(TNullableUInt64Converter)]
    property Incremental: TNullable<UInt64> read FIncremental write FIncremental;
  end;

  /// <summary>
  /// Represents the stake activation info.
  /// </summary>
  TStakeActivationInfo = class
  private
    FActive: UInt64;
    FInactive: UInt64;
    FState: string;
  public
    /// <summary>
    /// Stake active during the epoch.
    /// </summary>
    property Active: UInt64 read FActive write FActive;

    /// <summary>
    /// Stake inactive during the epoch.
    /// </summary>
    property Inactive: UInt64 read FInactive write FInactive;

    /// <summary>
    /// The stake account's activation state, one of "active", "inactive", "activating", "deactivating".
    /// </summary>
    property State: string read FState write FState;
  end;

  /// <summary>
  /// Represents supply info.
  /// </summary>
  TSupply = class
  private
    FCirculating: UInt64;
    FNonCirculating: UInt64;
    FNonCirculatingAccounts: TArray<string>;
    FTotal: UInt64;
  public
    /// <summary>
    /// Circulating supply in lamports.
    /// </summary>
    property Circulating: UInt64 read FCirculating write FCirculating;

    /// <summary>
    /// Non-circulating supply in lamports.
    /// </summary>
    property NonCirculating: UInt64 read FNonCirculating write FNonCirculating;

    /// <summary>
    /// A list of account addresses of non-circulating accounts, as strings.
    /// </summary>
    property NonCirculatingAccounts: TArray<string> read FNonCirculatingAccounts write FNonCirculatingAccounts;

    /// <summary>
    /// Total supply in lamports.
    /// </summary>
    property Total: UInt64 read FTotal write FTotal;
  end;

  /// <summary>
  /// Represents a token account.
  /// </summary>
  TTokenAccount = class
  private
    FAccount: TTokenAccountInfo;
    FPublicKey: string;
  public
    /// <summary>
    /// The token account info.
    /// </summary>
    property Account: TTokenAccountInfo read FAccount write FAccount;

    /// <summary>
    /// A base-58 encoded public key representing the account's public key.
    /// </summary>
    [JsonName('pubkey')]
    property PublicKey: string read FPublicKey write FPublicKey;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents the current solana versions running on the node.
  /// </summary>
  TNodeVersion = class
  private
    FSolanaCore: string;
    FFeatureSet: TNullable<UInt64>;
  public
    /// <summary>
    /// Software version of solana-core.
    /// </summary>
    [JsonName('solana-core')]
    property SolanaCore: string read FSolanaCore write FSolanaCore;

    /// <summary>
    /// unique identifier of the current software's feature set.
    /// </summary>
    [JsonName('feature-set')]
    [JsonConverter(TNullableUInt64Converter)]
    property FeatureSet: TNullable<UInt64> read FFeatureSet write FFeatureSet;
  end;

  /// <summary>
  /// Represents the account info and associated stake for all the voting accounts in the current bank.
  /// </summary>
  TVoteAccount = class
  private
    FRootSlot: UInt64;
    FVotePublicKey: string;
    FNodePublicKey: string;
    FActivatedStake: UInt64;
    FEpochVoteAccount: Boolean;
    FCommission: Double;
    FLastVote: UInt64;
    FEpochCredits: TArray<TArray<UInt64>>;
  public
    /// <summary>
    /// The root slot for this vote account.
    /// </summary>
    property RootSlot: UInt64 read FRootSlot write FRootSlot;

    /// <summary>
    /// The vote account address, as a base-58 encoded string.
    /// </summary>
    [JsonName('votePubkey')]
    property VotePublicKey: string read FVotePublicKey write FVotePublicKey;

    /// <summary>
    /// The validator identity, as a base-58 encoded string.
    /// </summary>
    [JsonName('nodePubkey')]
    property NodePublicKey: string read FNodePublicKey write FNodePublicKey;

    /// <summary>
    /// The stake, in lamports, delegated to this vote account and active in this epoch.
    /// </summary>
    property ActivatedStake: UInt64 read FActivatedStake write FActivatedStake;

    /// <summary>
    /// Whether the vote account is staked for this epoch.
    /// </summary>
    property EpochVoteAccount: Boolean read FEpochVoteAccount write FEpochVoteAccount;

    /// <summary>
    /// Percentage of rewards payout owed to the vote account.
    /// </summary>
    property Commission: Double read FCommission write FCommission;

    /// <summary>
    /// Most recent slot voted on by this vote account.
    /// </summary>
    property LastVote: UInt64 read FLastVote write FLastVote;

    /// <summary>
    /// History of how many credits earned by the end of the each epoch.
    /// <remarks>
    /// Each array contains [epoch, credits, previousCredits];
    /// </remarks>
    /// </summary>
    property EpochCredits: TArray<TArray<UInt64>> read FEpochCredits write FEpochCredits;
  end;

  /// <summary>
  /// Represents the vote accounts.
  /// </summary>
  TVoteAccounts = class
  private
    FCurrent, FDelinquent: TObjectList<TVoteAccount>;
  public
    /// <summary>
    /// Current vote accounts.
    /// </summary>
    [JsonConverter(TVoteAccountCollectionConverter)]
    property Current: TObjectList<TVoteAccount> read FCurrent write FCurrent;

    /// <summary>
    /// Delinquent vote accounts.
    /// </summary>
    [JsonConverter(TVoteAccountCollectionConverter)]
    property Delinquent: TObjectList<TVoteAccount> read FDelinquent write FDelinquent;

    destructor Destroy; override;
  end;


implementation

{ TAccountKeyPair }

destructor TAccountKeyPair.Destroy;
begin
 if Assigned(FAccount) then
  FAccount.Free;

  inherited;
end;

destructor TTokenAccountInfo.Destroy;
var
  Obj: TObject;
begin
  if FData.IsObject then
  begin
    Obj := FData.AsObject;
    if Assigned(Obj) then
      Obj.Free;
    FData := TValue.Empty;
  end;

  inherited Destroy;
end;

{ TTokenMintInfo }

destructor TTokenMintInfo.Destroy;
begin
 if Assigned(FData) then
  FData.Free;

  inherited Destroy;
end;

{ TTokenMintData }

destructor TTokenMintData.Destroy;
begin
 if Assigned(FParsed) then
  FParsed.Free;

  inherited Destroy;
end;

{ TParsedTokenMintData }

destructor TParsedTokenMintData.Destroy;
begin
 if Assigned(FInfo) then
  FInfo.Free;

  inherited Destroy;
end;

{ TTokenMintInfoDetails }

function TTokenMintInfoDetails.GetSupplyUlong: UInt64;
begin
  Result := UInt64.Parse(FSupply);
end;

{ TTokenAccountInfoDetails }

destructor TTokenAccountInfoDetails.Destroy;
begin
 if Assigned(FTokenAmount) then
  FTokenAmount.Free;

 if Assigned(FDelegatedAmount) then
  FDelegatedAmount.Free;

  inherited Destroy;
end;

{ TParsedTokenAccountData }

destructor TParsedTokenAccountData.Destroy;
begin
 if Assigned(FInfo) then
  FInfo.Free;

  inherited Destroy;
end;

{ TTokenBalance }

function TTokenBalance.GetAmountUInt64: UInt64;
begin
  Result := UInt64.Parse(FAmount);
end;

function TTokenBalance.GetAmountDouble: Double;
begin
  Result := Double.Parse(FUiAmountString, TFormatSettings.Invariant);
end;

{ TTokenAccountData }

destructor TTokenAccountData.Destroy;
begin
 if Assigned(FParsed) then
  FParsed.Free;

  inherited Destroy;
end;

{ TFeeCalculatorInfo }

destructor TFeeCalculatorInfo.Destroy;
begin
 if Assigned(FFeeCalculator) then
  FFeeCalculator.Free;

  inherited Destroy;
end;

{ TBlockHash }

destructor TBlockHash.Destroy;
begin
 if Assigned(FFeeCalculator) then
  FFeeCalculator.Free;

  inherited Destroy;
end;

{ TBlockInfo }

destructor TBlockInfo.Destroy;
begin
  if Assigned(FRewards) then
   FRewards.Free;

  if Assigned(FTransactions) then
   FTransactions.Free;

  inherited Destroy;
end;

{ TInnerInstruction }

destructor TInnerInstruction.Destroy;
begin
  if Assigned(FInstructions) then
    FInstructions.Free;

  inherited;
end;

{ TTokenBalanceInfo }

destructor TTokenBalanceInfo.Destroy;
begin
  if Assigned(FUiTokenAmount) then
    FUiTokenAmount.Free;

  inherited;
end;

{ TTransactionMeta }

destructor TTransactionMeta.Destroy;
begin
  if Assigned(FError) then
    FError.Free;

  if Assigned(FInnerInstructions) then
    FInnerInstructions.Free;

  if Assigned(FPreTokenBalances) then
    FPreTokenBalances.Free;

  if Assigned(FPostTokenBalances) then
    FPostTokenBalances.Free;

  if Assigned(FRewards) then
    FRewards.Free;

  if Assigned(FLoadedAddresses) then
    FLoadedAddresses.Free;

  inherited;
end;

{ TTransactionContentInfo }

destructor TTransactionContentInfo.Destroy;
begin
  if Assigned(FHeader) then
    FHeader.Free;

  if Assigned(FInstructions) then
    FInstructions.Free;

  inherited;
end;

{ TTransactionInfo }

destructor TTransactionInfo.Destroy;
begin
  if Assigned(FMessage) then
    FMessage.Free;

  inherited;
end;

{ TTransactionMetaInfo }

destructor TTransactionMetaInfo.Destroy;
var
  Obj: TObject;
begin
  if FTransaction.IsObject then
  begin
    Obj := FTransaction.AsObject;
    if Assigned(Obj) then
      Obj.Free;
    FTransaction := TValue.Empty;
  end;

  if FVersion.IsObject then
  begin
    Obj := FVersion.AsObject;
    if Assigned(Obj) then
      Obj.Free;
    FVersion := TValue.Empty;
  end;

  if Assigned(FMeta) then
    FMeta.Free;

  inherited;
end;

{ TLog }

destructor TLog.Destroy;
begin
  if Assigned(FError) then
    FError.Free;

  inherited;
end;

{ TSimulationLogs }

destructor TSimulationLogs.Destroy;
begin
  if Assigned(FAccounts) then
    FAccounts.Free;

  if Assigned(FError) then
    FError.Free;

  inherited;
end;

{ TTransactionError }

destructor TTransactionError.Destroy;
begin
if Assigned(FInstructionError) then
  FInstructionError.Free;

  inherited;
end;

{ TBlockProductionInfo }

destructor TBlockProductionInfo.Destroy;
begin
  if Assigned(FByIdentity) then
    FByIdentity.Free;

  if Assigned(FRange) then
    FRange.Free;

  inherited;
end;


{ TErrorResult }

destructor TErrorResult.Destroy;
begin
  if Assigned(FError) then
    FError.Free;

  inherited;
end;

{ TFeeRateGovernorInfo }

destructor TFeeRateGovernorInfo.Destroy;
begin
  if Assigned(FFeeRateGovernor) then
    FFeeRateGovernor.Free;

  inherited;
end;

{ TFeesInfo }

destructor TFeesInfo.Destroy;
begin
  if Assigned(FFeeCalculator) then
    FFeeCalculator.Free;

  inherited;
end;

{ TSignatureStatusInfo }

destructor TSignatureStatusInfo.Destroy;
begin
  if Assigned(FError) then
    FError.Free;

  inherited;
end;

{ TTokenAccount }

destructor TTokenAccount.Destroy;
begin
  if Assigned(FAccount) then
    FAccount.Free;

  inherited;
end;

{ TVoteAccounts }

destructor TVoteAccounts.Destroy;
begin
  if Assigned(FCurrent) then
    FCurrent.Free;

  if Assigned(FDelinquent) then
    FDelinquent.Free;

  inherited;
end;

end.

