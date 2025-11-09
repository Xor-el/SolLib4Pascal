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

unit SlpResultWrapper;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  SlpRequestResult,
  SlpRpcMessage,
  SlpRpcModel,
  SlpValueUtils;

type
  /// <summary>
  /// Wraps a result to an RPC request.
  /// </summary>
  /// <typeparam name="T">The underlying type of the request.</typeparam>
  /// <typeparam name="T2">The underlying type of the request.</typeparam>
  IResultWrapper<T; T2> = interface
    ['{B4C1E0C0-2E87-4E4E-91B0-5E55E4B3E4A0}']
    /// <summary>
    /// The original response to the request.
    /// </summary>
    function GetOriginalRequest: IRequestResult<T>;
    /// <summary>
    /// The desired type of the account data.
    /// </summary>
    function GetParsedResult: T2;
    procedure SetParsedResult(const AValue: T2);
    /// <summary>
    /// Whether the deserialization of the account data into the desired structure was successful.
    /// </summary>
    function GetWasDeserializationSuccessful: Boolean;
    /// <summary>
    /// Whether the original request and the deserialization of the account data into the desired structure was successful.
    /// </summary>
    function GetWasSuccessful: Boolean;

    /// <summary>
    /// The original response to the request.
    /// </summary>
    property OriginalRequest: IRequestResult<T> read GetOriginalRequest;
    /// <summary>
    /// The desired type of the account data.
    /// </summary>
    property ParsedResult: T2 read GetParsedResult write SetParsedResult;
    /// <summary>
    /// Whether the deserialization of the account data into the desired structure was successful.
    /// </summary>
    property WasDeserializationSuccessful: Boolean read GetWasDeserializationSuccessful;
    /// <summary>
    /// Whether the original request and the deserialization of the account data into the desired structure was successful.
    /// </summary>
    property WasSuccessful: Boolean read GetWasSuccessful;
  end;

  /// <summary>
  /// Wraps a result to an RPC request.
  /// </summary>
  /// <typeparam name="T">The underlying type of the request.</typeparam>
  /// <typeparam name="T2">The underlying type of the request.</typeparam>
  TResultWrapper<T; T2> = class(TInterfacedObject, IResultWrapper<T, T2>)
  private
    FOriginalRequest: IRequestResult<T>;
    FParsedResult: T2;
  //protected
    function GetOriginalRequest: IRequestResult<T>;
    function GetParsedResult: T2;
    procedure SetParsedResult(const AValue: T2);
    function GetWasDeserializationSuccessful: Boolean;
    function GetWasSuccessful: Boolean;
  public
    /// <summary>
    /// Initialize the result wrapper with the given result.
    /// </summary>
    /// <param name="AResult">The result of the request.</param>
    constructor Create(const AResult: IRequestResult<T>); overload;
    /// <summary>
    /// Initialize the result wrapper with the given result and it's parsed result type.
    /// </summary>
    /// <param name="AResult">The result of the request.</param>
    /// <param name="AParsedResult">The parsed result type.</param>
    constructor Create(const AResult: IRequestResult<T>; const AParsedResult: T2); overload;

    destructor Destroy; override;
  end;

  /// <summary>
  ///
  /// </summary>
  /// <typeparam name="T"></typeparam>
  IMultipleAccountsResultWrapper<T> = interface(IResultWrapper<TResponseValue<TObjectList<TAccountInfo>>, T>)
    ['{C9D8B10D-6A5A-4C3F-8F20-8C3B6C3C7F9E}']
  end;

  /// <summary>
  ///
  /// </summary>
  /// <typeparam name="T"></typeparam>
  TMultipleAccountsResultWrapper<T> = class(TResultWrapper<TResponseValue<TObjectList<TAccountInfo>>, T>, IMultipleAccountsResultWrapper<T>)
  public
    /// <summary>
    /// Initialize the result wrapper with the given result.
    /// </summary>
    /// <param name="AResult">The result of the request.</param>
    constructor Create(const AResult: IRequestResult<TResponseValue<TObjectList<TAccountInfo>>>); overload;
    /// <summary>
    /// Initialize the result wrapper with the given result.
    /// </summary>
    /// <param name="AResult">The result of the request.</param>
    /// <param name="AParsedResult">The parsed result type.</param>
    constructor Create(const AResult: IRequestResult<TResponseValue<TObjectList<TAccountInfo>>>; const AParsedResult: T); overload;
  end;

  /// <summary>
  ///
  /// </summary>
  /// <typeparam name="T"></typeparam>
  IAccountResultWrapper<T> = interface(IResultWrapper<TResponseValue<TAccountInfo>, T>)
    ['{7E8A2D65-3B19-4F73-8A4B-2C6A0F4E7E53}']
  end;

  /// <summary>
  ///
  /// </summary>
  /// <typeparam name="T"></typeparam>
  TAccountResultWrapper<T> = class(TResultWrapper<TResponseValue<TAccountInfo>, T>, IAccountResultWrapper<T>)
  public
    /// <summary>
    /// Initialize the result wrapper with the given result.
    /// </summary>
    /// <param name="AResult">The result of the request.</param>
    constructor Create(const AResult: IRequestResult<TResponseValue<TAccountInfo>>); overload;
    /// <summary>
    /// Initialize the result wrapper with the given result.
    /// </summary>
    /// <param name="AResult">The result of the request.</param>
    /// <param name="AParsedResult">The parsed result type.</param>
    constructor Create(const AResult: IRequestResult<TResponseValue<TAccountInfo>>; const AParsedResult: T); overload;
  end;

  /// <summary>
  ///
  /// </summary>
  /// <typeparam name="T"></typeparam>
  IProgramAccountsResultWrapper<T> = interface(IResultWrapper<TObjectList<TAccountKeyPair>, T>)
    ['{9F6B6C2A-8D9B-4F4B-BF4A-7A7CDA7B9F77}']
  end;

  /// <summary>
  ///
  /// </summary>
  /// <typeparam name="T"></typeparam>
  TProgramAccountsResultWrapper<T> = class(TResultWrapper<TObjectList<TAccountKeyPair>, T>, IProgramAccountsResultWrapper<T>)
  public
    /// <summary>
    /// Initialize the result wrapper with the given result.
    /// </summary>
    /// <param name="AResult">The result of the request.</param>
    constructor Create(const AResult: IRequestResult<TObjectList<TAccountKeyPair>>); overload;
    /// <summary>
    /// Initialize the result wrapper with the given result.
    /// </summary>
    /// <param name="AResult">The result of the request.</param>
    /// <param name="AParsedResult">The parsed result type.</param>
    constructor Create(const AResult: IRequestResult<TObjectList<TAccountKeyPair>>; const AParsedResult: T); overload;
  end;

implementation

{ TResultWrapper<T,T2> }

constructor TResultWrapper<T, T2>.Create(const AResult: IRequestResult<T>);
begin
  inherited Create;
  FOriginalRequest := AResult;
end;

constructor TResultWrapper<T, T2>.Create(const AResult: IRequestResult<T>; const AParsedResult: T2);
begin
  inherited Create;
  FOriginalRequest := AResult;
  FParsedResult := AParsedResult;
end;

destructor TResultWrapper<T, T2>.Destroy;
var
 V: TValue;
begin
 V := TValue.From<T2>(FParsedResult);

 if not V.IsEmpty then
   TValueUtils.FreeParameter(V);

  inherited;
end;

function TResultWrapper<T, T2>.GetOriginalRequest: IRequestResult<T>;
begin
  Result := FOriginalRequest;
end;

function TResultWrapper<T, T2>.GetParsedResult: T2;
begin
  Result := FParsedResult;
end;

procedure TResultWrapper<T, T2>.SetParsedResult(const AValue: T2);
begin
  FParsedResult := AValue;
end;

function TResultWrapper<T, T2>.GetWasDeserializationSuccessful: Boolean;
var
  LKind: TTypeKind;
begin
  LKind := PTypeInfo(TypeInfo(T2))^.Kind;
  case LKind of
    tkClass,
    tkInterface,
    tkPointer,
    tkClassRef,
    tkDynArray,
    tkUString, tkWString, tkLString, tkString:
      Result := PPointer(@FParsedResult)^ <> nil;
  else
    Result := True;
  end;
end;

function TResultWrapper<T, T2>.GetWasSuccessful: Boolean;
begin
  Result := Assigned(FOriginalRequest) and FOriginalRequest.WasSuccessful and GetWasDeserializationSuccessful;
end;

{ TMultipleAccountsResultWrapper<T> }

constructor TMultipleAccountsResultWrapper<T>.Create(
  const AResult: IRequestResult<TResponseValue<TObjectList<TAccountInfo>>>);
begin
  inherited Create(AResult);
end;

constructor TMultipleAccountsResultWrapper<T>.Create(
  const AResult: IRequestResult<TResponseValue<TObjectList<TAccountInfo>>>;
  const AParsedResult: T);
begin
  inherited Create(AResult, AParsedResult);
end;

{ TAccountResultWrapper<T> }

constructor TAccountResultWrapper<T>.Create(
  const AResult: IRequestResult<TResponseValue<TAccountInfo>>);
begin
  inherited Create(AResult);
end;

constructor TAccountResultWrapper<T>.Create(
  const AResult: IRequestResult<TResponseValue<TAccountInfo>>;
  const AParsedResult: T);
begin
  inherited Create(AResult, AParsedResult);
end;

{ TProgramAccountsResultWrapper<T> }

constructor TProgramAccountsResultWrapper<T>.Create(
  const AResult: IRequestResult<TObjectList<TAccountKeyPair>>);
begin
  inherited Create(AResult);
end;

constructor TProgramAccountsResultWrapper<T>.Create(
  const AResult: IRequestResult<TObjectList<TAccountKeyPair>>;
  const AParsedResult: T);
begin
  inherited Create(AResult, AParsedResult);
end;

end.

