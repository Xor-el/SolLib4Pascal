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

unit SlpRpcMessage;

{$I ..\Include\SolLib.inc}

interface

uses
  System.Rtti,
  System.SysUtils,
  System.TypInfo,
  System.Generics.Collections,
  System.JSON.Serializers,
  SlpValueUtils,
  SlpRpcModel,
  SlpNullable,
  SlpJsonKit,
  SlpNullableConverter,
  SlpJsonRpcBatchRequestConverter,
  SlpJsonRpcBatchResponseConverter,
  SlpRpcErrorResponseConverter,
  SlpJsonRpcRequestParamsConverter,
  SlpJsonRpcBatchResponseItemResultConverter;

type
  /// <summary>
  /// Context objects, holds the slot.
  /// </summary>
  TContextObj = class
  private
    FSlot: UInt64;
    FApiVersion: string;
  public
    /// <summary>The slot.</summary>
    property Slot: UInt64 read FSlot write FSlot;
    /// <summary>The api version.</summary>
    property ApiVersion: string read FApiVersion write FApiVersion;
  end;

  /// <summary>
  /// Holds the contents of an error message.
  /// </summary>
  TErrorContent = class
  private
    FCode: Integer;
    FMessage: string;
    FData: TErrorData;
  public
    /// <summary>The error code.</summary>
    property Code: Integer read FCode write FCode;
    /// <summary>The string error message.</summary>
    property Message: string read FMessage write FMessage;
    /// <summary>Possible extension data as a dictionary.</summary>
    property Data: TErrorData read FData write FData;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Contains the pair Context + Value from a given request.
  /// </summary>
  /// <typeparam name="T"></typeparam>
  TResponseValue<T> = class
  private
    FContext: TContextObj;
    FValue: T;
  public
    /// <summary>The context object from a given request.</summary>
    property Context: TContextObj read FContext write FContext;
    /// <summary>The value object from a given request.</summary>
    property Value: T read FValue write FValue;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Base JsonRpc message.
  /// </summary>
  TJsonRpcBase = class abstract
  private
    FJsonrpc: string;
    FId: TNullable<Integer>;
  public
    /// <summary>
    /// The rpc version.
    /// </summary>
    property Jsonrpc: string read FJsonrpc write FJsonrpc;

    /// <summary>
    /// The id of the message.
    /// </summary>
    [JsonConverter(TNullableIntegerConverter)]
    property Id: TNullable<Integer> read FId write FId;

    constructor Create;
  end;

  /// <summary>
  /// Rpc request message.
  /// </summary>
  TJsonRpcRequest = class(TJsonRpcBase)
  private
    FMethod: string;
    FParams: TList<TValue>;
  public
    /// <summary>
    /// The request method.
    /// </summary>
    property Method: string read FMethod;

    /// <summary>
    /// The method parameters list (only written if not empty).
    /// </summary>
    [JsonIgnoreWithCondition(TJsonIgnoreCondition.WhenWritingNull)]
    [JsonConverter(TJsonRpcRequestParamsConverter)]
    property Params: TList<TValue> read FParams write FParams;

    constructor Create(); overload;
    constructor Create(const AId: TNullable<Integer>; const AMethod: string;
      AParameters: TList<TValue>); overload;
    destructor Destroy; override;

    function Clone: TJsonRpcRequest;
  end;

  /// <summary>
  /// This class represents multiple JsonRpcRequest objects and is used for making
  /// a of batch requests in a single HTTP request.
  /// https://docs.solana.com/developing/clients/jsonrpc-api
  /// Requests can be sent in batches by sending an array of JSON-RPC request objects as the data for a single POST.
  /// </summary>
  [JsonConverter(TJsonRpcBatchRequestConverter)]
  TJsonRpcBatchRequest = class(TObjectList<TJsonRpcRequest>)
  public
    constructor Create;
    destructor Destroy; override;
  end;


  /// <summary>
  /// Holds a rpc request response.
  /// </summary>
  /// <typeparam name="T">The type of the result.</typeparam>
  TJsonRpcResponse<T> = class(TJsonRpcBase)
  private
    FResult: T;
  public
    /// <summary>The result of a given request.</summary>
    property Result: T read FResult write FResult;

    destructor Destroy; override;
  end;

  /// <summary>
  /// An object that represents a response item from an API batch request.
  /// The response type hint is supplied.
  /// </summary>
  TJsonRpcBatchResponseItem = class(TJsonRpcBase)
  private
    FResultType: PTypeInfo;   // lightweight type hint
    FResult: TValue;
    function GetResultTypeRtti: TRttiType;
  public

    destructor Destroy; override;
    /// <summary>
    /// The anticipated runtime type of this result (ignored in JSON).
    /// </summary>
    [JsonIgnore]
    property ResultType: PTypeInfo read FResultType write FResultType;

    /// <summary>
    /// Convenience RTTI view of ResultType (ignored in JSON).
    /// </summary>
    [JsonIgnore]
    property ResultTypeRtti: TRttiType read GetResultTypeRtti;

    /// <summary>
    /// The RPC result of a given request as a value.
    /// </summary>
    [JsonConverter(TJsonRpcBatchResponseItemResultConverter)]
    property Result: TValue read FResult write FResult;

    /// <summary>
    /// Cast the result to T.
    /// </summary>
    function ResultAs<T>: T; inline;
  end;

  /// <summary>
  /// This class represents the response from a request containing a batch of JSON RPC requests
  /// </summary>
  [JsonConverter(TJsonRpcBatchResponseConverter)]
  TJsonRpcBatchResponse = class(TObjectList<TJsonRpcBatchResponseItem>)
  public
    constructor Create;
    destructor Destroy; override;
  end;

  [JsonConverter(TRpcErrorResponseConverter)]
  TJsonRpcErrorResponse = class(TJsonRpcBase)
  private
    FError: TErrorContent;
    FErrorMessage: string;
  public
    /// <summary>The detailed error deserialized.</summary>
    property Error: TErrorContent read FError write FError;
    /// <summary>An error message.</summary>
    property ErrorMessage: string read FErrorMessage write FErrorMessage;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Holds a json rpc message from a streaming socket.
  /// </summary>
  /// <typeparam name="T">The type of the result.</typeparam>
  TJsonRpcStreamResponse<T> = class
  private
    FResult: T;
    FSubscription: Integer;
  public
    /// <summary>
    /// The message received.
    /// </summary>
    property Result: T read FResult write FResult;

    /// <summary>
    /// The subscription id that the message belongs to.
    /// </summary>
    property Subscription: Integer read FSubscription write FSubscription;
  end;

implementation

{ TErrorContent }

destructor TErrorContent.Destroy;
begin
  if Assigned(FData) then
     FData.Free;
  inherited;
end;

{ TResponseValue<T> }

destructor TResponseValue<T>.Destroy;
var
  V: TValue;
begin
 if Assigned(FContext) then
   FContext.Free;

  V := TValue.From<T>(FValue);

 if not V.IsEmpty then
   TValueUtils.FreeParameter(V);

  inherited;
end;

{ TJsonRpcBase }

constructor TJsonRpcBase.Create;
begin
  inherited Create;
end;

{ TJsonRpcRequest }

constructor TJsonRpcRequest.Create(const AId: TNullable<Integer>; const AMethod: string;
  AParameters: TList<TValue>);
begin
  inherited Create;
  FMethod := AMethod;
  FParams := AParameters;
  Id := AId;
  Jsonrpc := '2.0';
end;

constructor TJsonRpcRequest.Create;
begin
  inherited Create();
end;

destructor TJsonRpcRequest.Destroy;
begin
  if Assigned(FParams) then
    TValueUtils.FreeParameters(FParams);

  inherited;
end;

function TJsonRpcRequest.Clone: TJsonRpcRequest;

function CloneParams(const AParams: TList<TValue>): TList<TValue>;
begin
  Result := TValueUtils.CloneValueList(AParams);
end;

begin
  Result := TJsonRpcRequest.Create(Self.Id, Self.Method, CloneParams(Self.Params));
end;

{ TJsonRpcBatchRequest }

constructor TJsonRpcBatchRequest.Create;
begin
  inherited Create(True);
end;

destructor TJsonRpcBatchRequest.Destroy;
begin
  inherited Destroy;
end;

{ TJsonRpcBatchResponseItem }

destructor TJsonRpcBatchResponseItem.Destroy;
begin
 if not FResult.IsEmpty then
   TValueUtils.FreeParameter(FResult);

  inherited;
end;

function TJsonRpcBatchResponseItem.GetResultTypeRtti: TRttiType;
var
  Ctx: TRttiContext;
begin
  if FResultType = nil then
    Exit(nil);
  Ctx := TRttiContext.Create;
  try
    Result := Ctx.GetType(FResultType);
  finally
    Ctx.Free;
  end;
end;

function TJsonRpcBatchResponseItem.ResultAs<T>: T;
begin
  if FResult.IsEmpty then
    Exit(Default(T));

  Result := FResult.AsType<T>;
end;

{ TJsonRpcResponse<T> }

destructor TJsonRpcResponse<T>.Destroy;
var
  V: TValue;
  Obj: TObject;
begin
  V := TValue.From<T>(FResult);

  if V.IsObject then
  begin
    Obj := V.AsObject;
    if Assigned(Obj) then
      Obj.Free;
    V := TValue.Empty;
  end;
  inherited;
end;

{ TJsonRpcBatchResponse }

constructor TJsonRpcBatchResponse.Create;
begin
  inherited Create(True);
end;

destructor TJsonRpcBatchResponse.Destroy;
begin
  inherited Destroy;
end;

{ TJsonRpcErrorResponse }

destructor TJsonRpcErrorResponse.Destroy;
begin
  if Assigned(FError) then
     FError.Free;

  inherited;
end;

end.
