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

unit SlpBaseClient;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
  System.TypInfo,
  SlpDataEncoders,
  SlpSolanaRpcClient,
  SlpSolanaStreamingRpcClient,
  SlpRequestResult,
  SlpRpcMessage,
  SlpRpcModel,
  SlpRpcEnum,
  SlpTransactionInstruction,
  SlpTransactionBuilder,
  SlpMessageDomain,
  SlpPublicKey,
  SlpNullable,
  SlpResultWrapper,
  SlpSolLibTypes;

type
  /// <summary>
  /// Implements the base client (interface, ref-counted).
  /// </summary>
  IBaseClient = interface
    ['{F1A8E1B8-7F21-4C7C-A4F5-4BAA3B0F7C39}']
    /// <summary>
    /// The program address.
    /// </summary>
    function GetProgramIdKey: IPublicKey;
    /// <summary>
    /// The RPC client.
    /// </summary>
    function GetRpcClient: IRpcClient;
    /// <summary>
    /// The Streaming RPC client.
    /// </summary>
    function GetStreamingRpcClient: IStreamingRpcClient;
    /// <summary>
    /// The program address.
    /// </summary>
    property ProgramIdKey: IPublicKey read GetProgramIdKey;
    /// <summary>
    /// The RPC client.
    /// </summary>
    property RpcClient: IRpcClient read GetRpcClient;
    /// <summary>
    /// The Streaming RPC client.
    /// </summary>
    property StreamingRpcClient: IStreamingRpcClient read GetStreamingRpcClient;
  end;

  /// <summary>
  /// Implements the base client
  /// </summary>
  TBaseClient = class abstract(TInterfacedObject, IBaseClient)
  private
    FProgramIdKey: IPublicKey;
    FRpcClient: IRpcClient;
    FStreamingRpcClient: IStreamingRpcClient;

    function GetProgramIdKey: IPublicKey;
    function GetRpcClient: IRpcClient;
    function GetStreamingRpcClient: IStreamingRpcClient;

    /// <summary>
    /// Deserializes the given byte array into the specified type.
    /// </summary>
    /// <param name="AData">The data to deserialize into the specified type.</param>
    /// <typeparam name="T">The type.</typeparam>
    /// <returns>An instance of the specified type or nil in case it was unable to deserialize.</returns>
    class function DeserializeAccount<T: class>(const AData: TBytes): T; static;

  protected
    /// <summary>
    /// Gets the account info for the given account address and attempts to deserialize the account data into the specified type.
    /// </summary>
    /// <param name="AProgramAddress">The program account address.</param>
    /// <param name="AFilters">The filters to apply.</param>
    /// <param name="ADataSize">The expected account data size.</param>
    /// <param name="ACommitment">The commitment parameter for the RPC request.</param>
    /// <typeparam name="T">The specified type.</typeparam>
    /// <returns>A <see cref="IProgramAccountsResultWrapper{T}"/> containing the RPC response and the deserialized accounts if successful.</returns>
    function GetProgramAccounts<T: class>(
      const AProgramAddress: string;
      const AFilters: TArray<TMemCmp>;
      const ADataSlice: TDataSlice;
      const ADataSize: TNullable<Integer>;
      ACommitment: TCommitment = TCommitment.Finalized
    ): IProgramAccountsResultWrapper<TObjectList<T>>;

    /// <summary>
    /// Gets the account info for the given account address and attempts to deserialize the account data into the specified type.
    /// </summary>
    /// <param name="AAccountAddresses">The list of account addresses to fetch.</param>
    /// <param name="ACommitment">The commitment parameter for the RPC request.</param>
    /// <typeparam name="T">The specified type.</typeparam>
    /// <returns>A <see cref="IMultipleAccountsResultWrapper{T}"/> containing the RPC response and the deserialized accounts if successful.</returns>
    function GetMultipleAccounts<T: class>(
      const AAccountAddresses: TArray<string>;
      ACommitment: TCommitment = TCommitment.Finalized
    ): IMultipleAccountsResultWrapper<TObjectList<T>>;

    /// <summary>
    /// Gets the account info for the given account address and attempts to deserialize the account data into the specified type.
    /// </summary>
    /// <param name="AAccountAddress">The account address.</param>
    /// <param name="ACommitment">The commitment parameter for the RPC request.</param>
    /// <typeparam name="T">The specified type.</typeparam>
    /// <returns>A <see cref="IAccountResultWrapper{T}"/> containing the RPC response and the deserialized account if successful.</returns>
    function GetAccount<T: class>(
      const AAccountAddress: string;
      ACommitment: TCommitment = TCommitment.Finalized
    ): IAccountResultWrapper<T>;

    /// <summary>
    /// Subscribes to notifications on changes to the given account and deserializes the account data into the specified type.
    /// </summary>
    /// <param name="AAccountAddress">The account address.</param>
    /// <param name="ACommitment">The commitment parameter for the RPC request.</param>
    /// <param name="ACallback">An action that is called when a notification is received</param>
    /// <typeparam name="T">The specified type.</typeparam>
    /// <returns>The subscription state.</returns>
    function SubscribeAccount<T: class>(
      const APubKey: string;
      const ACallback: TProc<ISubscriptionState, TResponseValue<TAccountInfo>, T>;
      const ACommitment: TCommitment = TCommitment.Finalized
    ): ISubscriptionState;
    /// <summary>
    /// Initialize the base client with the given RPC clients.
    /// </summary>
    /// <param name="ARpcClient">The RPC client instance.</param>
    /// <param name="AStreamingRpcClient">The Streaming RPC client instance.</param>
    /// <param name="AProgramId">The program ID.</param>
    constructor Create(const ARpcClient: IRpcClient;
                       const AStreamingRpcClient: IStreamingRpcClient;
                       const AProgramId: IPublicKey);


    property ProgramIdKey: IPublicKey read GetProgramIdKey;

    property RpcClient: IRpcClient read GetRpcClient;

    property StreamingRpcClient: IStreamingRpcClient read GetStreamingRpcClient;

  end;


  /// <summary>
  /// Represents a program error and the respective message.
  /// </summary>
  /// <typeparam name="T">The underlying enum type. Enum values need to match program error codes.</typeparam>
  IProgramError<T> = interface
    ['{7A3A8C66-5C8D-4D1B-9E9F-3C3C7B1D1341}']
    /// <summary>
    /// The error kind according to the enum.
    /// </summary>
    function GetErrorKind: T;
    /// <summary>
    /// The error message.
    /// </summary>
    function GetMessage: string;
    /// <summary>
    /// The error code, according to the enum and program definition.
    /// </summary>
    function GetErrorCode: Cardinal;

    /// <summary>
    /// The error kind according to the enum.
    /// </summary>
    property ErrorKind: T read GetErrorKind;
    /// <summary>
    /// The error message.
    /// </summary>
    property Message: string read GetMessage;
    /// <summary>
    /// The error code, according to the enum and program definition.
    /// </summary>
    property ErrorCode: Cardinal read GetErrorCode;
  end;

  /// <summary>
  /// Represents a program error and the respective message.
  /// </summary>
  /// <typeparam name="T">The underlying enum type. Enum values need to match program error codes.</typeparam>
  TProgramError<T> = class(TInterfacedObject, IProgramError<T>)
  private
    FErrorKind: T;
    FMessage: string;
    FErrorCode: Cardinal;
  protected
    function GetErrorKind: T;
    function GetMessage: string;
    function GetErrorCode: Cardinal;
  public
    /// <summary>
    /// Default constructor that populates all values.
    /// </summary>
    /// <param name="AValue">The corresponding error value.</param>
    /// <param name="AMessage">The error message that matches the error value.</param>
    constructor Create(const AValue: T; const AMessage: string);
  end;

  /// <summary>
  /// Transactional base client. Extends Base client and adds functionality related to transactions and error retrieval.
  /// </summary>
  /// <typeparam name="TEnum">The error enum type.
  /// The enum values need to match the program error codes and be correctly mapped in BuildErrorsDictionary abstract method. </typeparam>
  ITransactionalBaseClient<TEnum> = interface(IBaseClient)
    ['{C3E2E1A8-5C4A-4C1C-8D5B-6A73B0B1A9E7}']

    function GetProgramErrors: TDictionary<Cardinal, IProgramError<TEnum>>;
    /// <summary>
    /// Signs and sends a given <c>TransactionInstruction</c> using signing delegate.
    /// </summary>
    /// <param name="AInstruction">The transaction to be sent.</param>
    /// <param name="AFeePayer">The fee payer.</param>
    /// <param name="ASigningCallback">The callback used to sign the transaction.
    /// This delegate is called once for each <c>IPublicKey</c> account that needs write permissions according to the transaction data.</param>
    /// <param name="ACommitment">The commitment parameter for the RPC request.</param>
    function SignAndSendTransaction(
      const AInstruction: ITransactionInstruction;
      const AFeePayer: IPublicKey;
      const ASigningCallback: TFunc<TBytes, IPublicKey, TBytes>;
      ACommitment: TCommitment = TCommitment.Finalized
    ): IRequestResult<string>;

    /// <summary>
    /// Try to retrieve a custom program error from a transaction or simulation result.
    /// </summary>
    /// <param name="ALogs">The transaction error or simulation result.</param>
    /// <returns>The possible program error, if it was caused by this program.</returns>
    function GetProgramError(const ALogs: TSimulationLogs): IProgramError<TEnum>; overload;

    /// <summary>
    /// Try to retrieve a custom program error from a transaction or simulation result.
    /// </summary>
    /// <param name="AError">The transaction error or simulation result.</param>
    /// <returns>The possible program error, if it was caused by this program.</returns>
    function GetProgramError(const AError: TTransactionError): IProgramError<TEnum>; overload;

    /// <summary>
    /// Mapping from error codes to error values (code, message and enum).
    /// </summary>
    property ProgramErrors: TDictionary<Cardinal, IProgramError<TEnum>> read GetProgramErrors;
  end;

  /// <summary>
  /// Transactional base client. Extends Base client and adds functionality related to transactions and error retrieval.
  /// </summary>
  /// <typeparam name="TEnum">The error enum type.
  /// The enum values need to match the program error codes and be correctly mapped in BuildErrorsDictionary abstract method. </typeparam>
  TTransactionalBaseClient<TEnum> = class abstract(TBaseClient, ITransactionalBaseClient<TEnum>)
  private
    FProgramErrors: TDictionary<Cardinal, IProgramError<TEnum>>;

    function GetProgramErrors: TDictionary<Cardinal, IProgramError<TEnum>>;
  protected
    /// <summary>
    /// Function that builds a mapping between error codes and error values.
    /// This is used to populate the ProgramErrors dictionary that powers the GetProgramError methods.
    /// </summary>
    /// <returns>The dictionary with the possible errors.</returns>
    function BuildErrorsDictionary: TDictionary<Cardinal, IProgramError<TEnum>>; virtual; abstract;
  public
    /// <summary>
    /// Initialize the transactional base client.
    /// </summary>
    /// <param name="ARpcClient">The RPC client instance.</param>
    /// <param name="AStreamingRpcClient">The Streaming RPC client instance.</param>
    /// <param name="AProgramId">The program ID.</param>
    constructor Create(const ARpcClient: IRpcClient;
                       const AStreamingRpcClient: IStreamingRpcClient;
                       const AProgramId: IPublicKey); reintroduce;

    destructor Destroy; override;

    /// <summary>
    /// Signs and sends a given <c>TransactionInstruction</c> using signing delegate.
    /// </summary>
    /// <param name="AInstruction">The transaction to be sent.</param>
    /// <param name="AFeePayer">The fee payer.</param>
    /// <param name="ASigningCallback">The callback used to sign the transaction.
    /// This delegate is called once for each <c>IPublicKey</c> account that needs write permissions according to the transaction data.</param>
    /// <param name="ACommitment">The commitment parameter for the RPC request.</param>
    function SignAndSendTransaction(
      const AInstruction: ITransactionInstruction;
      const AFeePayer: IPublicKey;
      const ASigningCallback: TFunc<TBytes, IPublicKey, TBytes>;
      ACommitment: TCommitment = TCommitment.Finalized
    ): IRequestResult<string>;

    /// <summary>
    /// Try to retrieve a custom program error from a transaction or simulation result.
    /// </summary>
    /// <param name="ALogs">The transaction error or simulation result.</param>
    /// <returns>The possible program error, if it was caused by this program.</returns>
    function GetProgramError(const ALogs: TSimulationLogs): IProgramError<TEnum>; overload;

    /// <summary>
    /// Try to retrieve a custom program error from a transaction or simulation result.
    /// </summary>
    /// <param name="AError">The transaction error or simulation result.</param>
    /// <returns>The possible program error, if it was caused by this program.</returns>
    function GetProgramError(const AError: TTransactionError): IProgramError<TEnum>; overload;
  end;

implementation

{ TBaseClient }

constructor TBaseClient.Create(
  const ARpcClient: IRpcClient;
  const AStreamingRpcClient: IStreamingRpcClient;
  const AProgramId: IPublicKey);
begin
  inherited Create;
  FRpcClient := ARpcClient;
  FStreamingRpcClient := AStreamingRpcClient;
  FProgramIdKey := AProgramId;
end;

function TBaseClient.GetProgramIdKey: IPublicKey;
begin
  Result := FProgramIdKey;
end;

function TBaseClient.GetRpcClient: IRpcClient;
begin
  Result := FRpcClient;
end;

function TBaseClient.GetStreamingRpcClient: IStreamingRpcClient;
begin
  Result := FStreamingRpcClient;
end;

class function TBaseClient.DeserializeAccount<T>(const AData: TBytes): T;
var
  Ctx      : TRttiContext;
  TypeT    : TRttiType;
  InstType : TRttiInstanceType;
  Meta     : TClass;
  MetaType : TRttiType;
  M        : TRttiMethod;
  Params   : TArray<TRttiParameter>;
  Ret      : TValue;
  Arg      : TValue;
begin
  Result := Default(T);

  Ctx := TRttiContext.Create;
  try
    TypeT := Ctx.GetType(TypeInfo(T));
    if not (TypeT is TRttiInstanceType) then
      raise EInvalidOp.Create('T must be a class type.');

    InstType := TRttiInstanceType(TypeT);
    Meta     := InstType.MetaclassType;
    MetaType := Ctx.GetType(Meta);

    // Find a class function Deserialize(const Bytes: TBytes): <T or descendant>
    for M in MetaType.GetMethods('Deserialize') do
    begin
      if (M.MethodKind = mkClassFunction) then
      begin
        Params := M.GetParameters;
        if (Length(Params) = 1) and (Params[0].ParamType.Handle = TypeInfo(TBytes)) then
        begin
          Arg := TValue.From<TBytes>(AData);
          Ret := M.Invoke(Meta, [Arg]);

          // Accept exact T or any descendant; TryAsType avoids hard type-info comparisons
          if Ret.TryAsType<T>(Result) then
            Exit;
        end;
      end;
    end;
  finally
    Ctx.Free;
  end;
end;

function TBaseClient.GetProgramAccounts<T>(
  const AProgramAddress: string;
  const AFilters: TArray<TMemCmp>;
  const ADataSlice: TDataSlice;
  const ADataSize: TNullable<Integer>;
  ACommitment: TCommitment
): IProgramAccountsResultWrapper<TObjectList<T>>;
var
  LRes   : IRequestResult<TObjectList<TAccountKeyPair>>;
  LParsed: TObjectList<T>;
  Pair   : TAccountKeyPair;
  Bytes  : TBytes;
  Item   : T;
begin
  LRes := FRpcClient.GetProgramAccounts(AProgramAddress, ADataSize, ADataSlice, AFilters, TBinaryEncoding.Base64, ACommitment);

  if (not LRes.WasSuccessful) or (LRes.Result = nil) or (LRes.Result.Count = 0) then
    Exit(TProgramAccountsResultWrapper<TObjectList<T>>.Create(LRes));

  LParsed := TObjectList<T>.Create(True);
  try
    for Pair in LRes.Result do
    begin
      if (Assigned(Pair.Account.Data)) and (Length(Pair.Account.Data) > 0) then
      begin
        Bytes := TEncoders.Base64.DecodeData(Pair.Account.Data[0]);
        Item := DeserializeAccount<T>(Bytes);
        LParsed.Add(Item);
      end;
    end;
    Result := TProgramAccountsResultWrapper<TObjectList<T>>.Create(LRes, LParsed);
  except
    LParsed.Free;
    Result := TProgramAccountsResultWrapper<TObjectList<T>>.Create(LRes);
  end;
end;

function TBaseClient.GetMultipleAccounts<T>(
  const AAccountAddresses: TArray<string>;
  ACommitment: TCommitment
): IMultipleAccountsResultWrapper<TObjectList<T>>;
var
  LRes   : IRequestResult<TResponseValue<TObjectList<TAccountInfo>>>;
  LParsed: TObjectList<T>;
  Info   : TAccountInfo;
  Bytes  : TBytes;
  Item   : T;
begin
  LRes := FRpcClient.GetMultipleAccounts(AAccountAddresses, TBinaryEncoding.Base64, ACommitment);

  if (not LRes.WasSuccessful) or (LRes.Result = nil) or
     (LRes.Result.Value = nil) or (LRes.Result.Value.Count = 0) then
    Exit(TMultipleAccountsResultWrapper<TObjectList<T>>.Create(LRes));

  LParsed := TObjectList<T>.Create(True);
  try
    for Info in LRes.Result.Value do
    begin
      if (Assigned(Info.Data)) and (Length(Info.Data) > 0) then
      begin
        Bytes := TEncoders.Base64.DecodeData(Info.Data[0]);
        Item := DeserializeAccount<T>(Bytes);
        LParsed.Add(Item);
      end;
    end;
    Result := TMultipleAccountsResultWrapper<TObjectList<T>>.Create(LRes, LParsed);
  except
    LParsed.Free;
    Result := TMultipleAccountsResultWrapper<TObjectList<T>>.Create(LRes);
  end;
end;

function TBaseClient.GetAccount<T>(
  const AAccountAddress: string;
  ACommitment: TCommitment
): IAccountResultWrapper<T>;
var
  LRes  : IRequestResult<TResponseValue<TAccountInfo>>;
  Bytes : TBytes;
  Item  : T;
begin
  LRes := FRpcClient.GetAccountInfo(AAccountAddress, TBinaryEncoding.Base64, ACommitment);

  if LRes.WasSuccessful and (LRes.Result <> nil) and (LRes.Result.Value <> nil) and
     (Assigned(LRes.Result.Value.Data)) and (Length(LRes.Result.Value.Data) > 0) then
  begin
    Bytes := TEncoders.Base64.DecodeData(LRes.Result.Value.Data[0]);
    Item := DeserializeAccount<T>(Bytes);
    Exit(TAccountResultWrapper<T>.Create(LRes, Item));
  end;

  Result := TAccountResultWrapper<T>.Create(LRes);
end;

function TBaseClient.SubscribeAccount<T>(
  const APubKey    : string;
  const ACallback  : TProc<ISubscriptionState, TResponseValue<TAccountInfo>, T>;
  const ACommitment: TCommitment
): ISubscriptionState;
begin
  Result :=
    FStreamingRpcClient.SubscribeAccountInfo(
      APubKey,
      procedure(ASub: ISubscriptionState; AEnv: TResponseValue<TAccountInfo>)
      var
        LParsed: T;
        LBytes : TBytes;
      begin
        LParsed := nil;

        // Safely decode base64 payload if present, then parse into T
        if (AEnv <> nil) and (AEnv.Value <> nil) and
           (Length(AEnv.Value.Data) > 0) and (AEnv.Value.Data[0] <> '') then
        begin
          LBytes  := TEncoders.Base64.DecodeData(AEnv.Value.Data[0]);
          LParsed := DeserializeAccount<T>(LBytes);
        end;

        if Assigned(ACallback) then
          ACallback(ASub, AEnv, LParsed);
      end,
      ACommitment
    );
end;

{ TProgramError<T> }

constructor TProgramError<T>.Create(const AValue: T; const AMessage: string);
var
  LCtx : TRttiContext;
  LTyp : TRttiType;
  LVal : TValue;
begin
  inherited Create;

  LCtx := TRttiContext.Create;
  try
    // Runtime validation: T must be an enum
    LTyp := LCtx.GetType(TypeInfo(T));
    if (LTyp = nil) or (LTyp.TypeKind <> tkEnumeration) then
      raise EArgumentException.Create('TProgramError<T>: T must be an enum type.');

    FErrorKind := AValue;
    FMessage   := AMessage;

    LVal := TValue.From<T>(AValue);
    FErrorCode := Cardinal(LVal.AsOrdinal);
  finally
    LCtx.Free;
  end;
end;


function TProgramError<T>.GetErrorCode: Cardinal;
begin
  Result := FErrorCode;
end;

function TProgramError<T>.GetErrorKind: T;
begin
  Result := FErrorKind;
end;

function TProgramError<T>.GetMessage: string;
begin
  Result := FMessage;
end;

{ TTransactionalBaseClient<TEnum> }

constructor TTransactionalBaseClient<TEnum>.Create(
  const ARpcClient: IRpcClient;
  const AStreamingRpcClient: IStreamingRpcClient;
  const AProgramId: IPublicKey);
begin
  inherited Create(ARpcClient, AStreamingRpcClient, AProgramId);
  FProgramErrors := BuildErrorsDictionary;
end;

destructor TTransactionalBaseClient<TEnum>.Destroy;
begin
  if Assigned(FProgramErrors) then FProgramErrors.Free;

  inherited;
end;

function TTransactionalBaseClient<TEnum>.GetProgramErrors: TDictionary<Cardinal, IProgramError<TEnum>>;
begin
  Result := FProgramErrors;
end;

function TTransactionalBaseClient<TEnum>.SignAndSendTransaction(
  const AInstruction: ITransactionInstruction;
  const AFeePayer: IPublicKey;
  const ASigningCallback: TFunc<TBytes, IPublicKey, TBytes>;
  ACommitment: TCommitment
): IRequestResult<string>;
var
  LTB     : ITransactionBuilder;
  LRecent : IRequestResult<TResponseValue<TLatestBlockHash>>;
  LWire   : TBytes;
  LMsg    : IMessage;
  I       : Integer;
  LSig    : TBytes;
begin
  // 1) Build transaction
  LTB := TTransactionBuilder.Create;
  LTB.AddInstruction(AInstruction);

  // 2) Fetch recent blockhash
  LRecent := RpcClient.GetLatestBlockHash(ACommitment);
  if (not LRecent.WasSuccessful) or (not Assigned(LRecent.Result)) or (LRecent.Result.Value.Blockhash = '') then
    raise Exception.Create('Failed to get recent blockhash');

  LTB.SetRecentBlockHash(LRecent.Result.Value.Blockhash);
  LTB.SetFeePayer(AFeePayer);

  // 3) Compile and sign
  LWire := LTB.CompileMessage;          // message bytes for signing
  LMsg  := TMessage.Deserialize(LWire); // to inspect header/account keys

  for I := 0 to LMsg.Header.RequiredSignatures - 1 do
  begin
    LSig := ASigningCallback(LWire, LMsg.AccountKeys[I]);
    LTB.AddSignature(LSig);
  end;

  // 4) Send transaction
  Result := RpcClient.SendTransaction(LTB.Serialize, TNullable<UInt32>.None, TNullable<UInt64>.None, False, TBinaryEncoding.Base64, ACommitment);
end;

function TTransactionalBaseClient<TEnum>.GetProgramError(
  const ALogs: TSimulationLogs): IProgramError<TEnum>;
var
  LId : Cardinal;
  LErr: IProgramError<TEnum>;
  LLast: string;
begin
  Result := nil;

  // Check: custom instruction error present?
  if (ALogs.Error <> nil) and
     (ALogs.Error.InstructionError <> nil) and
     (ALogs.Error.InstructionError.&Type = TInstructionErrorType.Custom) and
     (ALogs.Error.InstructionError.CustomError.HasValue) then
  begin
    LId := Cardinal(ALogs.Error.InstructionError.CustomError.Value);

    // If logs exist and program id is known, verify last log references this program
    if (Assigned(ProgramIdKey)) and (Assigned(ALogs.Logs)) and (Length(ALogs.Logs) > 0) then
    begin
      LLast := ALogs.Logs[High(ALogs.Logs)];
      //check if error came from this program, in case its a multiple prog tx
      if not LLast.StartsWith('Program ' + ProgramIdKey.Key) then
        Exit(nil);
    end;

    if FProgramErrors.TryGetValue(LId, LErr) then
      Exit(LErr);
  end;
end;

function TTransactionalBaseClient<TEnum>.GetProgramError(
  const AError: TTransactionError): IProgramError<TEnum>;
var
  LId : Cardinal;
begin
  Result := nil;
  if (AError.InstructionError <> nil) and
     (AError.InstructionError.&Type = TInstructionErrorType.Custom) and
     (AError.InstructionError.CustomError.HasValue) then
  begin
    LId := Cardinal(AError.InstructionError.CustomError.Value);
    FProgramErrors.TryGetValue(LId, Result);
  end;
end;

end.

