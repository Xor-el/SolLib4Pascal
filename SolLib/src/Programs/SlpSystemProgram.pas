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

unit SlpSystemProgram;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  SlpPublicKey,
  SlpAccountDomain,
  SlpSerialization,
  SlpDeserialization,
  SlpDecodedInstruction,
  SlpSysVars,
  SlpTransactionInstruction;

type
  /// <summary>
  /// Represents the instruction types for the <see cref="SystemProgram"/>.
  /// <remarks>
  /// For more information see:
  /// https://docs.solana.com/developing/runtime-facilities/programs#system-program
  /// https://docs.rs/solana-sdk/1.7.0/solana_sdk/system_instruction/enum.SystemInstruction.html
  /// </remarks>
  /// </summary>
  TSystemProgramInstructions = class sealed
  public
    type
      /// <summary>
      /// Represents the instruction types for the <see cref="SystemProgram"/>.
      /// </summary>
      TValues = (
        /// <summary>
        /// Create a new account.
        /// </summary>
        CreateAccount = 0,
        /// <summary>
        /// Assign account to a program.
        /// </summary>
        Assign = 1,
        /// <summary>
        /// Transfer lamports.
        /// </summary>
        Transfer = 2,
        /// <summary>
        /// Create a new account at an address derived from a base public key and a seed.
        /// </summary>
        CreateAccountWithSeed = 3,
        /// <summary>
        /// Consumes a stored nonce, replacing it with a successor.
        /// </summary>
        AdvanceNonceAccount = 4,
        /// <summary>
        /// Withdraw funds from a nonce account.
        /// </summary>
        WithdrawNonceAccount = 5,
        /// <summary>
        /// Drive state of uninitialized nonce account to Initialized, setting the nonce value.
        /// </summary>
        InitializeNonceAccount = 6,
        /// <summary>
        /// Change the entity authorized to execute nonce instructions on the account.
        /// </summary>
        AuthorizeNonceAccount = 7,
        /// <summary>
        /// Allocate space in a (possibly new) account without funding.
        /// </summary>
        Allocate = 8,
        /// <summary>
        /// Allocate space for and assign an account at an address derived from a base public key and a seed.
        /// </summary>
        AllocateWithSeed = 9,
        /// <summary>
        /// Assign account to a program based on a seed
        /// </summary>
        AssignWithSeed = 10,
        /// <summary>
        /// Transfer lamports from a derived address.
        /// </summary>
        TransferWithSeed = 11
      );
  private
    /// <summary>
    /// Represents the user-friendly names for the instruction types for the <see cref="SystemProgram"/>.
    /// </summary>
    class var FNames: TDictionary<TValues, string>;
  public
      /// <summary>Represents the user-friendly names for the instruction types.</summary>
    class property Names: TDictionary<TValues, string> read FNames;

    class constructor Create;
    class destructor Destroy;
  end;

  /// <summary>
  /// Implements the system program data encodings.
  /// </summary>
  TSystemProgramData = class sealed
  private
  /// <summary>
  /// The offset at which the value which defines the program method begins.
  /// </summary>
    const MethodOffset = 0;

  public

    /// <summary>
    /// Encode transaction instruction data for the <see cref="SystemProgramInstructions.Values.CreateAccount"/> method.
    /// </summary>
    /// <param name="AOwner">The public key of the owner program account.</param>
    /// <param name="ALamports">The number of lamports to fund the account.</param>
    /// <param name="ASpace">The space to be allocated to the account.</param>
    /// <returns>The transaction instruction data.</returns>
    class function EncodeCreateAccountData(const AOwner: IPublicKey; const ALamports, ASpace: UInt64): TBytes; static;

    /// <summary>
    /// Encode transaction instruction data for the <see cref="SystemProgramInstructions.Values.Assign"/> method.
    /// </summary>
    /// <param name="AProgramId">The program id to set as the account owner.</param>
    /// <returns>The transaction instruction data.</returns>
    class function EncodeAssignData(const AProgramId: IPublicKey): TBytes; static;

    /// <summary>
    /// Encode transaction instruction data for the <see cref="SystemProgramInstructions.Values.Transfer"/> method.
    /// </summary>
    /// <param name="ALamports">The number of lamports to fund the account.</param>
    /// <returns>The transaction instruction data.</returns>
    class function EncodeTransferData(const ALamports: UInt64): TBytes; static;

    /// <summary>
    /// Encode transaction instruction data for the <see cref="SystemProgramInstructions.Values.CreateAccountWithSeed"/> method.
    /// </summary>
    /// <param name="ABaseAccount">The public key of the base account used to derive the account address.</param>
    /// <param name="AOwner">The public key of the owner program account address.</param>
    /// <param name="ALamports">Number of lamports to transfer to the new account.</param>
    /// <param name="ASpace">Number of bytes of memory to allocate.</param>
    /// <param name="ASeed">Seed to use to derive the account address.</param>
    /// <returns>The transaction instruction data.</returns>
    class function EncodeCreateAccountWithSeedData(
      const ABaseAccount, AOwner: IPublicKey; const ALamports, ASpace: UInt64; const ASeed: string): TBytes; static;

    /// <summary>
    /// Encode transaction instruction data for the <see cref="SystemProgramInstructions.Values.AdvanceNonceAccount"/> method.
    /// </summary>
    /// <returns>The transaction instruction data.</returns>
    class function EncodeAdvanceNonceAccountData: TBytes; static;

    /// <summary>
    /// Encode transaction instruction data for the <see cref="SystemProgramInstructions.Values.WithdrawNonceAccount"/> method.
    /// </summary>
    /// <param name="ALamports"></param>
    /// <returns>The transaction instruction data.</returns>
    class function EncodeWithdrawNonceAccountData(const ALamports: UInt64): TBytes; static;

    /// <summary>
    /// Encode transaction instruction data for the <see cref="SystemProgramInstructions.Values.InitializeNonceAccount"/> method.
    /// </summary>
    /// <param name="AAuthorized">The public key of the entity authorized to execute nonce instructions on the account.</param>
    /// <returns>The transaction instruction data.</returns>
    class function EncodeInitializeNonceAccountData(const AAuthorized: IPublicKey): TBytes; static;

    /// <summary>
    /// Encode transaction instruction data for the <see cref="SystemProgramInstructions.Values.AuthorizeNonceAccount"/> method.
    /// </summary>
    /// <param name="AAuthorized">The public key of the entity authorized to execute nonce instructions on the account.</param>
    /// <returns>The transaction instruction data.</returns>
    class function EncodeAuthorizeNonceAccountData(const AAuthorized: IPublicKey): TBytes; static;

    /// <summary>
    /// Encode transaction instruction data for the <see cref="SystemProgramInstructions.Values.Allocate"/> method.
    /// </summary>
    /// <param name="ASpace">Number of bytes of memory to allocate.</param>
    /// <returns>The transaction instruction data.</returns>
    class function EncodeAllocateData(const ASpace: UInt64): TBytes; static;

    /// <summary>
    /// Encode transaction instruction data for the <see cref="SystemProgramInstructions.Values.AllocateWithSeed"/> method.
    /// </summary>
    /// <param name="ABaseAccount">The public key of the base account.</param>
    /// <param name="ASpace">Number of bytes of memory to allocate.</param>
    /// <param name="AOwner">Owner to use to derive the funding account address.</param>
    /// <param name="ASeed">Seed to use to derive the funding account address.</param>
    /// <returns>The transaction instruction data.</returns>
    class function EncodeAllocateWithSeedData(
      const ABaseAccount, AOwner: IPublicKey; const ASpace: UInt64; const ASeed: string): TBytes; static;

      /// <summary>
      /// Encode transaction instruction data for the <see cref="SystemProgramInstructions.Values.AssignWithSeed"/> method.
      /// </summary>
      /// <param name="ABaseAccount">The public key of the base account.</param>
      /// <param name="ASeed">Seed to use to derive the account address.</param>
      /// <param name="AOwner">The public key of the owner program account.</param>
      /// <returns>The transaction instruction data.</returns>
    class function EncodeAssignWithSeedData(
      const ABaseAccount: IPublicKey; const ASeed: string; const AOwner: IPublicKey): TBytes; static;

      /// <summary>
      /// Encode transaction instruction data for the <see cref="SystemProgramInstructions.Values.TransferWithSeed"/> method.
      /// </summary>
      /// <param name="AOwner">Owner to use to derive the funding account address.</param>
      /// <param name="ASeed">Seed to use to derive the funding account address.</param>
      /// <param name="ALamports">Amount of lamports to transfer.</param>
      /// <returns>The transaction instruction data.</returns>
    class function EncodeTransferWithSeedData(
      const AOwner: IPublicKey; const ASeed: string; const ALamports: UInt64): TBytes; static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="SystemProgramInstructions.Values.CreateAccount"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeCreateAccountData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="SystemProgramInstructions.Values.Assign"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeAssignData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="SystemProgramInstructions.Values.Transfer"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeTransferData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="SystemProgramInstructions.Values.CreateAccountWithSeed"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeCreateAccountWithSeedData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="SystemProgramInstructions.Values.AdvanceNonceAccount"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeAdvanceNonceAccountData(const ADecodedInstruction: IDecodedInstruction;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="SystemProgramInstructions.Values.WithdrawNonceAccount"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeWithdrawNonceAccountData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="SystemProgramInstructions.Values.InitializeNonceAccount"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeInitializeNonceAccountData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="SystemProgramInstructions.Values.AuthorizeNonceAccount"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeAuthorizeNonceAccountData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="SystemProgramInstructions.Values.Allocate"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeAllocateData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="SystemProgramInstructions.Values.AllocateWithSeed"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeAllocateWithSeedData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="SystemProgramInstructions.Values.AssignWithSeed"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeAssignWithSeedData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;

    /// <summary>
    /// Decodes the instruction instruction data  for the <see cref="SystemProgramInstructions.Values.TransferWithSeed"/> method
    /// </summary>
    /// <param name="ADecodedInstruction">The decoded instruction to add data to.</param>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    class procedure DecodeTransferWithSeedData(const ADecodedInstruction: IDecodedInstruction; const AData: TBytes;
      const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes); static;
  end;

  /// <summary>
  /// Implements the System Program methods.
  /// <remarks>
  /// For more information see:
  /// https://docs.solana.com/developing/runtime-facilities/programs#system-program
  /// https://docs.rs/solana-sdk/1.7.0/solana_sdk/system_instruction/enum.SystemInstruction.html
  /// </remarks>
  /// </summary>
  TSystemProgram = class sealed
  private
    const ProgramName = 'System Program';
    class var FProgramIdKey: IPublicKey;

    class function GetProgramIdKey: IPublicKey; static;
  public
      /// <summary>The public key of the System Program.</summary>
    class property ProgramIdKey: IPublicKey read GetProgramIdKey;

    class constructor Create;
    class destructor Destroy;

    /// <summary>
    /// Initialize a new transaction instruction which interacts with the System Program to create a new account.
    /// </summary>
    /// <param name="AFromAccount">The public key of the account from which the lamports will be transferred.</param>
    /// <param name="ANewAccountPublicKey">The public key of the account to which the lamports will be transferred.</param>
    /// <param name="ALamports">The amount of lamports to transfer.</param>
    /// <param name="ASpace">Number of bytes of memory to allocate for the account.</param>
    /// <param name="AProgramId">The program id of the account.</param>
    /// <returns>The transaction instruction.</returns>
    class function CreateAccount(
      const AFromAccount, ANewAccountPublicKey: IPublicKey;
      const ALamports, ASpace: UInt64; const AProgramId: IPublicKey
    ): TTransactionInstruction; static;

    /// <summary>
    /// Initialize a new transaction instruction which interacts with the System Program to assign a new account owner.
    /// </summary>
    /// <param name="AAccount">The public key of the account to assign a new owner.</param>
    /// <param name="AProgramId">The program id of the account to assign as owner.</param>
    /// <returns>The transaction instruction.</returns>
    class function Assign(
      const AAccount, AProgramId: IPublicKey
    ): TTransactionInstruction; static;

    /// <summary>
    /// Initialize a new transaction instruction which interacts with the System Program to transfer lamports.
    /// </summary>
    /// <param name="AFromPublicKey">The public key of the account to transfer from.</param>
    /// <param name="AToPublicKey">The public key of the account to transfer to.</param>
    /// <param name="ALamports">The amount of lamports.</param>
    /// <returns>The transaction instruction.</returns>
    class function Transfer(
      const AFromPublicKey, AToPublicKey: IPublicKey; const ALamports: UInt64
    ): TTransactionInstruction; static;

    /// <summary>
    /// Initialize a new transaction instruction which interacts with the System Program
    /// to create a new account at an address derived from a base public key and a seed.
    /// </summary>
    /// <param name="AFromPublicKey">The public key of the account to transfer from.</param>
    /// <param name="AToPublicKey">The public key of the account to transfer to.</param>
    /// <param name="ABaseAccount">The public key of the base account.</param>
    /// <param name="ASeed">The seed to use to derive the account address.</param>
    /// <param name="ALamports">The amount of lamports.</param>
    /// <param name="ASpace">The number of bytes of space to allocate for the account.</param>
    /// <param name="AOwner">The public key of the owner to use to derive the account address.</param>
    /// <returns>The transaction instruction.</returns>
    class function CreateAccountWithSeed(
      const AFromPublicKey, AToPublicKey, ABaseAccount: IPublicKey;
      const ASeed: string; const ALamports, ASpace: UInt64; const AOwner: IPublicKey
    ): TTransactionInstruction; static;

    /// <summary>
    /// Initialize a new transaction instruction which interacts with the System Program
    /// to consume a stored nonce, replacing it with a successor.
    /// </summary>
    /// <param name="ANonceAccountPublicKey">The public key of the nonce account.</param>
    /// <param name="AAuthorized">The public key of the account authorized to perform nonce operations on the nonce account.</param>
    /// <returns>The transaction instruction.</returns>
    class function AdvanceNonceAccount(
      const ANonceAccountPublicKey, AAuthorized: IPublicKey
    ): TTransactionInstruction; static;

    /// <summary>
    /// Initialize a new transaction instruction which interacts with the System Program to withdraw funds from a nonce account.
    /// </summary>
    /// <param name="ANonceAccountPublicKey">The public key of the nonce account.</param>
    /// <param name="AToPublicKey">The public key of the account to transfer to.</param>
    /// <param name="AAuthorized">The public key of the account authorized to perform nonce operations on the nonce account.</param>
    /// <param name="ALamports">The amount of lamports to transfer.</param>
    /// <returns>The transaction instruction.</returns>
    class function WithdrawNonceAccount(
      const ANonceAccountPublicKey, AToPublicKey, AAuthorized: IPublicKey; const ALamports: UInt64
    ): TTransactionInstruction; static;

    /// <summary>
    /// Initialize a new transaction instruction which interacts with the System Program to drive the
    /// state of an Uninitialized nonce account to Initialized, setting the nonce value.
    /// </summary>
    /// <param name="ANonceAccountPublicKey">The public key of the nonce account.</param>
    /// <param name="AAuthorized">The public key of the account authorized to perform nonce operations on the nonce account.</param>
    /// <returns>The transaction instruction.</returns>
    class function InitializeNonceAccount(
      const ANonceAccountPublicKey, AAuthorized: IPublicKey
    ): TTransactionInstruction; static;

    /// <summary>
    /// Initialize a new transaction instruction which interacts with the System Program to change
    /// the entity authorized to execute nonce instructions on the account.
    /// </summary>
    /// <param name="AonceAccountPublicKey">The public key of the nonce account.</param>
    /// <param name="Authorized">The public key of the account authorized to perform nonce operations on the nonce account.</param>
    /// <param name="ANewAuthority">The public key of the new authority for the nonce operations.</param>
    /// <returns>The transaction instruction.</returns>
    class function AuthorizeNonceAccount(
      const ANonceAccountPublicKey, AAuthorized, ANewAuthority: IPublicKey
    ): TTransactionInstruction; static;

    /// <summary>
    /// Initialize a new transaction instruction which interacts with the System Program to
    /// allocate space in a (possibly new) account without funding.
    /// </summary>
    /// <param name="AAccount">The public key of the account to allocate space to.</param>
    /// <param name="ASpace">The number of bytes of space to allocate.</param>
    /// <returns>The transaction instruction.</returns>
    class function Allocate(
      const AAccount: IPublicKey; const ASpace: UInt64
    ): TTransactionInstruction; static;

    /// <summary>
    /// Initialize a new transaction instruction which interacts with the System Program to
    /// allocate space for and assign an account at an address derived from a base public key and a seed.
    /// </summary>
    /// <param name="AAccount">The public key of the account to allocate space to.</param>
    /// <param name="ABaseAccount">The public key of the base account.</param>
    /// <param name="ASeed">The seed to use to derive the account address.</param>
    /// <param name="ASpace">The number of bytes of space to allocate.</param>
    /// <param name="AOwner">The public key of the owner to use to derive the account address.</param>
    /// <returns>The transaction instruction.</returns>
    class function AllocateWithSeed(
      const AAccount, ABaseAccount: IPublicKey; const ASeed: string; const ASpace: UInt64; const AOwner: IPublicKey
    ): TTransactionInstruction; static;

    /// <summary>
    /// Initialize a new transaction instruction which interacts with the System Program to
    /// assign an account to a program based on a seed.
    /// </summary>
    /// <param name="AAccount">The public key of the account to assign to.</param>
    /// <param name="ABaseAccount">The public key of the base account.</param>
    /// <param name="ASeed">The seed to use to derive the account address.</param>
    /// <param name="AOwner">The public key of the owner to use to derive the account address.</param>
    /// <returns>The transaction instruction.</returns>
    class function AssignWithSeed(
      const AAccount, ABaseAccount: IPublicKey; const ASeed: string; const AOwner: IPublicKey
    ): TTransactionInstruction; static;

    /// <summary>
    /// Initialize a new transaction instruction which interacts with the System Program to
    /// transfer lamports from a derived address.
    /// </summary>
    /// <param name="AFromPublicKey">The public key of the account to transfer from.</param>
    /// <param name="AFromBaseAccount">The public key of the base account.</param>
    /// <param name="ASeed">The seed to use to derive the funding account address.</param>
    /// <param name="AFromOwner">The public key of the owner to use to derive the funding account address.</param>
    /// <param name="AToPublicKey">The account to transfer to.</param>
    /// <param name="ALamports">The amount of lamports to transfer.</param>
    /// <returns>The transaction instruction.</returns>
    class function TransferWithSeed(
      const AFromPublicKey, AFromBaseAccount: IPublicKey; const ASeed: string; const AFromOwner, AToPublicKey: IPublicKey; const ALamports: UInt64
    ): TTransactionInstruction; static;

    /// <summary>
    /// Decodes an instruction created by the System Program.
    /// </summary>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    /// <returns>A decoded instruction.</returns>
    class function Decode(
      const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes
    ): IDecodedInstruction; static;
  end;

implementation

{ TSystemProgramInstructions }

class constructor TSystemProgramInstructions.Create;
begin
  FNames := TDictionary<TValues, string>.Create;
  FNames.Add(TValues.CreateAccount, 'Create Account');
  FNames.Add(TValues.Assign, 'Assign');
  FNames.Add(TValues.Transfer, 'Transfer');
  FNames.Add(TValues.CreateAccountWithSeed, 'Create Account With Seed');
  FNames.Add(TValues.AdvanceNonceAccount, 'Advance Nonce Account');
  FNames.Add(TValues.WithdrawNonceAccount, 'Withdraw Nonce Account');
  FNames.Add(TValues.InitializeNonceAccount, 'Initialize Nonce Account');
  FNames.Add(TValues.AuthorizeNonceAccount, 'Authorize Nonce Account');
  FNames.Add(TValues.Allocate, 'Allocate');
  FNames.Add(TValues.AllocateWithSeed, 'Allocate With Seed');
  FNames.Add(TValues.AssignWithSeed, 'Assign With Seed');
  FNames.Add(TValues.TransferWithSeed, 'Transfer With Seed');
end;

class destructor TSystemProgramInstructions.Destroy;
begin
  FNames.Free;
end;

class function TSystemProgramData.EncodeCreateAccountData(const AOwner: IPublicKey; const ALamports, ASpace: UInt64): TBytes;
begin
  SetLength(Result, 52);
  TSerialization.WriteU32(Result, UInt32(TSystemProgramInstructions.TValues.CreateAccount), MethodOffset);
  TSerialization.WriteU64(Result, ALamports, 4);
  TSerialization.WriteU64(Result, ASpace, 12);
  TSerialization.WritePubKey(Result, AOwner, 20);
end;

class function TSystemProgramData.EncodeAssignData(const AProgramId: IPublicKey): TBytes;
begin
  SetLength(Result, 36);
  TSerialization.WriteU32(Result, UInt32(TSystemProgramInstructions.TValues.Assign), MethodOffset);
  TSerialization.WritePubKey(Result, AProgramId, 4);
end;

class function TSystemProgramData.EncodeTransferData(const ALamports: UInt64): TBytes;
begin
  SetLength(Result, 12);
  TSerialization.WriteU32(Result, UInt32(TSystemProgramInstructions.TValues.Transfer), MethodOffset);
  TSerialization.WriteU64(Result, ALamports, 4);
end;

class function TSystemProgramData.EncodeCreateAccountWithSeedData(
  const ABaseAccount, AOwner: IPublicKey; const ALamports, ASpace: UInt64; const ASeed: string): TBytes;
var
 EncodedSeed: TBytes;
begin
  EncodedSeed := TSerialization.EncodeBincodeString(ASeed);
  SetLength(Result, 84 + Length(EncodedSeed));
  TSerialization.WriteU32(Result, UInt32(TSystemProgramInstructions.TValues.CreateAccountWithSeed), MethodOffset);
  TSerialization.WritePubKey(Result, ABaseAccount, 4);
  TSerialization.WriteSpan(Result, EncodedSeed, 36);
  TSerialization.WriteU64(Result, ALamports, 36 + Length(EncodedSeed));
  TSerialization.WriteU64(Result, ASpace, 44 + Length(EncodedSeed));
  TSerialization.WritePubKey(Result, AOwner, 52 + Length(EncodedSeed));
end;

class function TSystemProgramData.EncodeAdvanceNonceAccountData: TBytes;
begin
  SetLength(Result, 4);
  TSerialization.WriteU32(Result, UInt32(TSystemProgramInstructions.TValues.AdvanceNonceAccount), MethodOffset);
end;

class function TSystemProgramData.EncodeWithdrawNonceAccountData(const ALamports: UInt64): TBytes;
begin
  SetLength(Result, 12);
  TSerialization.WriteU32(Result, UInt32(TSystemProgramInstructions.TValues.WithdrawNonceAccount), MethodOffset);
  TSerialization.WriteU64(Result, ALamports, 4);
end;

class function TSystemProgramData.EncodeInitializeNonceAccountData(const AAuthorized: IPublicKey): TBytes;
begin
  SetLength(Result, 36);
  TSerialization.WriteU32(Result, UInt32(TSystemProgramInstructions.TValues.InitializeNonceAccount), MethodOffset);
  TSerialization.WritePubKey(Result, AAuthorized, 4);
end;

class function TSystemProgramData.EncodeAuthorizeNonceAccountData(const AAuthorized: IPublicKey): TBytes;
begin
  SetLength(Result, 36);
  TSerialization.WriteU32(Result, UInt32(TSystemProgramInstructions.TValues.AuthorizeNonceAccount), MethodOffset);
  TSerialization.WritePubKey(Result, AAuthorized, 4);
end;

class function TSystemProgramData.EncodeAllocateData(const ASpace: UInt64): TBytes;
begin
  SetLength(Result, 12);
  TSerialization.WriteU32(Result, UInt32(TSystemProgramInstructions.TValues.Allocate), MethodOffset);
  TSerialization.WriteU64(Result, ASpace, 4);
end;

class function TSystemProgramData.EncodeAllocateWithSeedData(
  const ABaseAccount, AOwner: IPublicKey; const ASpace: UInt64; const ASeed: string): TBytes;
var
 EncodedSeed: TBytes;
begin
  EncodedSeed := TSerialization.EncodeBincodeString(ASeed);
  SetLength(Result, 76 + Length(EncodedSeed));
  TSerialization.WriteU32(Result, UInt32(TSystemProgramInstructions.TValues.AllocateWithSeed), MethodOffset);
  TSerialization.WritePubKey(Result, ABaseAccount, 4);
  TSerialization.WriteSpan(Result, EncodedSeed, 36);
  TSerialization.WriteU64(Result, ASpace, 36 + Length(EncodedSeed));
  TSerialization.WritePubKey(Result, AOwner, 44 + Length(EncodedSeed));
end;

class function TSystemProgramData.EncodeAssignWithSeedData(
  const ABaseAccount: IPublicKey; const ASeed: string; const AOwner: IPublicKey): TBytes;
var
 EncodedSeed: TBytes;
begin
  EncodedSeed := TSerialization.EncodeBincodeString(ASeed);
  SetLength(Result, 68 + Length(EncodedSeed));
  TSerialization.WriteU32(Result, UInt32(TSystemProgramInstructions.TValues.AssignWithSeed), MethodOffset);
  TSerialization.WritePubKey(Result, ABaseAccount, 4);
  TSerialization.WriteSpan(Result, EncodedSeed, 36);
  TSerialization.WritePubKey(Result, AOwner, 36 + Length(EncodedSeed));
end;

class function TSystemProgramData.EncodeTransferWithSeedData(
  const AOwner: IPublicKey; const ASeed: string; const ALamports: UInt64): TBytes;
var
 EncodedSeed: TBytes;
begin
  EncodedSeed := TSerialization.EncodeBincodeString(ASeed);
  SetLength(Result, 44 + Length(EncodedSeed));
  TSerialization.WriteU32(Result, UInt32(TSystemProgramInstructions.TValues.TransferWithSeed), MethodOffset);
  TSerialization.WriteU64(Result, ALamports, 4);
  TSerialization.WriteSpan(Result, EncodedSeed, 12);
  TSerialization.WritePubKey(Result, AOwner, 12 + Length(EncodedSeed));
end;

class procedure TSystemProgramData.DecodeCreateAccountData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecodedInstruction.Values.Add('Owner Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecodedInstruction.Values.Add('New Account',   TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecodedInstruction.Values.Add('Amount',        TValue.From<UInt64>(TDeserialization.GetU64(AData, 4)));
  ADecodedInstruction.Values.Add('Space',         TValue.From<UInt64>(TDeserialization.GetU64(AData, 12)));
end;

class procedure TSystemProgramData.DecodeAssignData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecodedInstruction.Values.Add('Account',  TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecodedInstruction.Values.Add('Assign To',TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 4)));
end;

class procedure TSystemProgramData.DecodeTransferData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecodedInstruction.Values.Add('From Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecodedInstruction.Values.Add('To Account',   TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecodedInstruction.Values.Add('Amount',       TValue.From<UInt64>(TDeserialization.GetU64(AData, 4)));
end;

class procedure TSystemProgramData.DecodeCreateAccountWithSeedData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
var
 DecBinCodeData: TDecodedBincodeString;
begin
  ADecodedInstruction.Values.Add('From Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecodedInstruction.Values.Add('To Account',   TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecodedInstruction.Values.Add('Base Account', TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 4)));
  DecBinCodeData := TDeserialization.DecodeBincodeString(AData, 36);
  ADecodedInstruction.Values.Add('Seed',         TValue.From<string>(DecBinCodeData.EncodedString));
  ADecodedInstruction.Values.Add('Amount',       TValue.From<UInt64>(TDeserialization.GetU64(AData, 36 + DecBinCodeData.Length)));
  ADecodedInstruction.Values.Add('Space',        TValue.From<UInt64>(TDeserialization.GetU64(AData, 44 + DecBinCodeData.Length)));
  ADecodedInstruction.Values.Add('Owner',        TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 52 + DecBinCodeData.Length)));
end;

class procedure TSystemProgramData.DecodeAdvanceNonceAccountData(
  const ADecodedInstruction: IDecodedInstruction; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecodedInstruction.Values.Add('Nonce Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecodedInstruction.Values.Add('Authority',     TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
end;

class procedure TSystemProgramData.DecodeWithdrawNonceAccountData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecodedInstruction.Values.Add('Nonce Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecodedInstruction.Values.Add('To Account',    TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecodedInstruction.Values.Add('Authority',     TValue.From<IPublicKey>(AKeys[AKeyIndices[4]]));
  ADecodedInstruction.Values.Add('Amount',        TValue.From<UInt64>(TDeserialization.GetU64(AData, 4)));
end;

class procedure TSystemProgramData.DecodeInitializeNonceAccountData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecodedInstruction.Values.Add('Nonce Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecodedInstruction.Values.Add('Authority',     TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 4)));
end;

class procedure TSystemProgramData.DecodeAuthorizeNonceAccountData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecodedInstruction.Values.Add('Nonce Account',    TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecodedInstruction.Values.Add('Current Authority',TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecodedInstruction.Values.Add('New Authority',    TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 4)));
end;

class procedure TSystemProgramData.DecodeAllocateData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
begin
  ADecodedInstruction.Values.Add('Account', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecodedInstruction.Values.Add('Space',   TValue.From<UInt64>(TDeserialization.GetU64(AData, 4)));
end;

class procedure TSystemProgramData.DecodeAllocateWithSeedData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
var
 DecBinCodeData: TDecodedBincodeString;
begin
  ADecodedInstruction.Values.Add('Account',      TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecodedInstruction.Values.Add('Base Account', TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 4)));
  DecBinCodeData := TDeserialization.DecodeBincodeString(AData, 36);
  ADecodedInstruction.Values.Add('Seed',         TValue.From<string>(DecBinCodeData.EncodedString));
  ADecodedInstruction.Values.Add('Space',        TValue.From<UInt64>(TDeserialization.GetU64(AData, 36 + DecBinCodeData.Length)));
  ADecodedInstruction.Values.Add('Owner',        TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 44 + DecBinCodeData.Length)));
end;

class procedure TSystemProgramData.DecodeAssignWithSeedData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
var
 DecBinCodeData: TDecodedBincodeString;
begin
  ADecodedInstruction.Values.Add('Account',      TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecodedInstruction.Values.Add('Base Account', TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 4)));
  DecBinCodeData := TDeserialization.DecodeBincodeString(AData, 36);
  ADecodedInstruction.Values.Add('Seed',         TValue.From<string>(DecBinCodeData.EncodedString));
  ADecodedInstruction.Values.Add('Owner',        TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 36 + DecBinCodeData.Length)));
end;

class procedure TSystemProgramData.DecodeTransferWithSeedData(
  const ADecodedInstruction: IDecodedInstruction; const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes);
var
 DecBinCodeData: TDecodedBincodeString;
begin
  ADecodedInstruction.Values.Add('From Account',     TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  ADecodedInstruction.Values.Add('From Base Account',TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  ADecodedInstruction.Values.Add('To Account',       TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  ADecodedInstruction.Values.Add('Amount',           TValue.From<UInt64>(TDeserialization.GetU64(AData, 4)));
  DecBinCodeData := TDeserialization.DecodeBincodeString(AData, 12);
  ADecodedInstruction.Values.Add('Seed',             TValue.From<string>(DecBinCodeData.EncodedString));
  ADecodedInstruction.Values.Add('From Owner',       TValue.From<IPublicKey>(TDeserialization.GetPubKey(AData, 12 + DecBinCodeData.Length)));
end;

{ TSystemProgram }

class constructor TSystemProgram.Create;
begin
  FProgramIdKey := TPublicKey.Create('11111111111111111111111111111111');
end;

class destructor TSystemProgram.Destroy;
begin
  FProgramIdKey := nil;
end;

class function TSystemProgram.GetProgramIdKey: IPublicKey;
begin
  Result := FProgramIdKey;
end;

class function TSystemProgram.CreateAccount(
  const AFromAccount, ANewAccountPublicKey: IPublicKey;
  const ALamports, ASpace: UInt64; const AProgramId: IPublicKey
): TTransactionInstruction;
var
 Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;

  Keys.Add(TAccountMeta.Writable(AFromAccount, True));
  Keys.Add(TAccountMeta.Writable(ANewAccountPublicKey, True));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TSystemProgramData.EncodeCreateAccountData(AProgramId, ALamports, ASpace));
end;

class function TSystemProgram.Assign(
  const AAccount, AProgramId: IPublicKey
): TTransactionInstruction;
var Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, True));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TSystemProgramData.EncodeAssignData(AProgramId));
end;

class function TSystemProgram.Transfer(
  const AFromPublicKey, AToPublicKey: IPublicKey; const ALamports: UInt64
): TTransactionInstruction;
var Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AFromPublicKey, True));
  Keys.Add(TAccountMeta.Writable(AToPublicKey, False));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TSystemProgramData.EncodeTransferData(ALamports));
end;

class function TSystemProgram.CreateAccountWithSeed(
  const AFromPublicKey, AToPublicKey, ABaseAccount: IPublicKey;
  const ASeed: string; const ALamports, ASpace: UInt64; const AOwner: IPublicKey
): TTransactionInstruction;
var Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AFromPublicKey, True));
  Keys.Add(TAccountMeta.Writable(AToPublicKey, False));

  if not ABaseAccount.Equals(AFromPublicKey) then
    Keys.Add(TAccountMeta.ReadOnly(ABaseAccount, True));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TSystemProgramData.EncodeCreateAccountWithSeedData(ABaseAccount, AOwner, ALamports, ASpace, ASeed));
end;

class function TSystemProgram.AdvanceNonceAccount(
  const ANonceAccountPublicKey, AAuthorized: IPublicKey
): TTransactionInstruction;
var Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ANonceAccountPublicKey, False));
  Keys.Add(TAccountMeta.ReadOnly(TSysVars.RecentBlockHashesKey, False));
  Keys.Add(TAccountMeta.ReadOnly(AAuthorized, True));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TSystemProgramData.EncodeAdvanceNonceAccountData);
end;

class function TSystemProgram.WithdrawNonceAccount(
  const ANonceAccountPublicKey, AToPublicKey, AAuthorized: IPublicKey; const ALamports: UInt64
): TTransactionInstruction;
var Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ANonceAccountPublicKey, False));
  Keys.Add(TAccountMeta.Writable(AToPublicKey, False));
  Keys.Add(TAccountMeta.ReadOnly(TSysVars.RecentBlockHashesKey, False));
  Keys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));
  Keys.Add(TAccountMeta.ReadOnly(AAuthorized, True));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TSystemProgramData.EncodeWithdrawNonceAccountData(ALamports));
end;

class function TSystemProgram.InitializeNonceAccount(
  const ANonceAccountPublicKey, AAuthorized: IPublicKey
): TTransactionInstruction;
var Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ANonceAccountPublicKey, False));
  Keys.Add(TAccountMeta.ReadOnly(TSysVars.RecentBlockHashesKey, False));
  Keys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TSystemProgramData.EncodeInitializeNonceAccountData(AAuthorized));
end;

class function TSystemProgram.AuthorizeNonceAccount(
  const ANonceAccountPublicKey, AAuthorized, ANewAuthority: IPublicKey
): TTransactionInstruction;
var Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(ANonceAccountPublicKey, False));
  Keys.Add(TAccountMeta.ReadOnly(AAuthorized, True));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TSystemProgramData.EncodeAuthorizeNonceAccountData(ANewAuthority));
end;

class function TSystemProgram.Allocate(
  const AAccount: IPublicKey; const ASpace: UInt64
): TTransactionInstruction;
var Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, True));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TSystemProgramData.EncodeAllocateData(ASpace));
end;

class function TSystemProgram.AllocateWithSeed(
  const AAccount, ABaseAccount: IPublicKey; const ASeed: string; const ASpace: UInt64; const AOwner: IPublicKey
): TTransactionInstruction;
var Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, False));
  Keys.Add(TAccountMeta.ReadOnly(ABaseAccount, True));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TSystemProgramData.EncodeAllocateWithSeedData(ABaseAccount, AOwner, ASpace, ASeed));
end;

class function TSystemProgram.AssignWithSeed(
  const AAccount, ABaseAccount: IPublicKey; const ASeed: string; const AOwner: IPublicKey
): TTransactionInstruction;
var Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AAccount, False));
  Keys.Add(TAccountMeta.ReadOnly(ABaseAccount, True));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TSystemProgramData.EncodeAssignWithSeedData(ABaseAccount, ASeed, AOwner));
end;

class function TSystemProgram.TransferWithSeed(
  const AFromPublicKey, AFromBaseAccount: IPublicKey; const ASeed: string; const AFromOwner, AToPublicKey: IPublicKey; const ALamports: UInt64
): TTransactionInstruction;
var Keys: TList<IAccountMeta>;
begin
  Keys := TList<IAccountMeta>.Create;
  Keys.Add(TAccountMeta.Writable(AFromPublicKey, False));
  Keys.Add(TAccountMeta.ReadOnly(AFromBaseAccount, True));
  Keys.Add(TAccountMeta.ReadOnly(AToPublicKey, False));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, Keys, TSystemProgramData.EncodeTransferWithSeedData(AFromOwner, ASeed, ALamports));
end;

class function TSystemProgram.Decode(
  const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes
): IDecodedInstruction;
var
  Instruction: UInt32;
  InstructionValue: TSystemProgramInstructions.TValues;
begin
  Instruction := TDeserialization.GetU32(AData, TSystemProgramData.MethodOffset);

  if GetEnumName(TypeInfo(TSystemProgramInstructions.TValues), Instruction) = '' then
  begin
    Result := TDecodedInstruction.Create;
    Result.PublicKey        := ProgramIdKey;
    Result.InstructionName  := 'Unknown Instruction';
    Result.ProgramName      := ProgramName;
    Result.Values             := TDictionary<string, TValue>.Create;
    Result.InnerInstructions  := TList<IDecodedInstruction>.Create();
    Exit;
  end;

  InstructionValue := TSystemProgramInstructions.TValues(Instruction);

  Result := TDecodedInstruction.Create;
  Result.PublicKey := ProgramIdKey;
  Result.ProgramName := ProgramName;
  Result.InstructionName := TSystemProgramInstructions.Names[InstructionValue];
  Result.Values := TDictionary<string, TValue>.Create;
  Result.InnerInstructions := TList<IDecodedInstruction>.Create;

  case InstructionValue of
    TSystemProgramInstructions.TValues.CreateAccount:
      TSystemProgramData.DecodeCreateAccountData(Result, AData, AKeys, AKeyIndices);
    TSystemProgramInstructions.TValues.Assign:
      TSystemProgramData.DecodeAssignData(Result, AData, AKeys, AKeyIndices);
    TSystemProgramInstructions.TValues.Transfer:
      TSystemProgramData.DecodeTransferData(Result, AData, AKeys, AKeyIndices);
    TSystemProgramInstructions.TValues.CreateAccountWithSeed:
      TSystemProgramData.DecodeCreateAccountWithSeedData(Result, AData, AKeys, AKeyIndices);
    TSystemProgramInstructions.TValues.AdvanceNonceAccount:
      TSystemProgramData.DecodeAdvanceNonceAccountData(Result, AKeys, AKeyIndices);
    TSystemProgramInstructions.TValues.WithdrawNonceAccount:
      TSystemProgramData.DecodeWithdrawNonceAccountData(Result, AData, AKeys, AKeyIndices);
    TSystemProgramInstructions.TValues.InitializeNonceAccount:
      TSystemProgramData.DecodeInitializeNonceAccountData(Result, AData, AKeys, AKeyIndices);
    TSystemProgramInstructions.TValues.AuthorizeNonceAccount:
      TSystemProgramData.DecodeAuthorizeNonceAccountData(Result, AData, AKeys, AKeyIndices);
    TSystemProgramInstructions.TValues.Allocate:
      TSystemProgramData.DecodeAllocateData(Result, AData, AKeys, AKeyIndices);
    TSystemProgramInstructions.TValues.AllocateWithSeed:
      TSystemProgramData.DecodeAllocateWithSeedData(Result, AData, AKeys, AKeyIndices);
    TSystemProgramInstructions.TValues.AssignWithSeed:
      TSystemProgramData.DecodeAssignWithSeedData(Result, AData, AKeys, AKeyIndices);
    TSystemProgramInstructions.TValues.TransferWithSeed:
      TSystemProgramData.DecodeTransferWithSeedData(Result, AData, AKeys, AKeyIndices);
  end;
end;

end.

