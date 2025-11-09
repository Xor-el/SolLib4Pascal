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

unit SlpRequestResult;

{$I ..\..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Math,
  SlpRpcModel,
  SlpHttpApiResponse,
  SlpValueUtils;

type
  IRequestResult<T> = interface
    ['{1E6BB2E9-7C0E-4C0A-9B7F-8E2B2B1D71C1}']

    function GetWasSuccessful: Boolean;
    function GetWasHttpRequestSuccessful: Boolean;
    procedure SetWasHttpRequestSuccessful(const Value: Boolean);
    function GetWasRequestSuccessfullyHandled: Boolean;
    procedure SetWasRequestSuccessfullyHandled(const Value: Boolean);
    function GetReason: string;
    procedure SetReason(const Value: string);
    function GetResult: T;
    procedure SetResult(const Value: T);
    function GetHttpStatusCode: Integer;
    procedure SetHttpStatusCode(const Value: Integer);
    function GetServerErrorCode: Integer;
    procedure SetServerErrorCode(const Value: Integer);
    function GetErrorData: TErrorData;
    procedure SetErrorData(const Value: TErrorData);
    function GetRawRpcRequest: string;
    procedure SetRawRpcRequest(const Value: string);
    function GetRawRpcResponse: string;
    procedure SetRawRpcResponse(const Value: string);

    property WasSuccessful: Boolean read GetWasSuccessful;
    property WasHttpRequestSuccessful: Boolean read GetWasHttpRequestSuccessful write SetWasHttpRequestSuccessful;
    property WasRequestSuccessfullyHandled: Boolean read GetWasRequestSuccessfullyHandled write SetWasRequestSuccessfullyHandled;
    property Reason: string read GetReason write SetReason;
    property Result: T read GetResult write SetResult;
    property HttpStatusCode: Integer read GetHttpStatusCode write SetHttpStatusCode;
    property ServerErrorCode: Integer read GetServerErrorCode write SetServerErrorCode;
    property ErrorData: TErrorData read GetErrorData write SetErrorData;
    property RawRpcRequest: string read GetRawRpcRequest write SetRawRpcRequest;
    property RawRpcResponse: string read GetRawRpcResponse write SetRawRpcResponse;
  end;

  /// <summary>
  /// Represents the result of a given request.
  /// </summary>
  TRequestResult<T> = class(TInterfacedObject, IRequestResult<T>)
  private
    FWasHttpRequestSuccessful: Boolean;
    FWasRequestSuccessfullyHandled: Boolean;
    FReason: string;
    FResult: T;
    FHttpStatusCode: Integer;
    FServerErrorCode: Integer;
    FErrorData: TErrorData;
    FRawRpcRequest: string;
    FRawRpcResponse: string;

    // IRequestResult<T> getters/setters
    function GetWasSuccessful: Boolean;
    function GetWasHttpRequestSuccessful: Boolean;
    procedure SetWasHttpRequestSuccessful(const Value: Boolean);
    function GetWasRequestSuccessfullyHandled: Boolean;
    procedure SetWasRequestSuccessfullyHandled(const Value: Boolean);
    function GetReason: string;
    procedure SetReason(const Value: string);
    function GetResult: T;
    procedure SetResult(const Value: T);
    function GetHttpStatusCode: Integer;
    procedure SetHttpStatusCode(const Value: Integer);
    function GetServerErrorCode: Integer;
    procedure SetServerErrorCode(const Value: Integer);
    function GetErrorData: TErrorData;
    procedure SetErrorData(const Value: TErrorData);
    function GetRawRpcRequest: string;
    procedure SetRawRpcRequest(const Value: string);
    function GetRawRpcResponse: string;
    procedure SetRawRpcResponse(const Value: string);
  public
    constructor Create; overload; virtual;
    constructor CreateFromResponse(const AResponse: IHttpApiResponse); overload; virtual;
    constructor CreateFromResponse(const AResponse: IHttpApiResponse; const AResult: T); overload; virtual;
    constructor CreateWithError(AStatusCode: Integer; const AReason: string); virtual;
    destructor Destroy; override;

    // IRequestResult<T>
    property WasSuccessful: Boolean read GetWasSuccessful;
    property WasHttpRequestSuccessful: Boolean read GetWasHttpRequestSuccessful write SetWasHttpRequestSuccessful;
    property WasRequestSuccessfullyHandled: Boolean read GetWasRequestSuccessfullyHandled write SetWasRequestSuccessfullyHandled;
    property Reason: string read GetReason write SetReason;
    property Result: T read GetResult write SetResult;
    property HttpStatusCode: Integer read GetHttpStatusCode write SetHttpStatusCode;
    property ServerErrorCode: Integer read GetServerErrorCode write SetServerErrorCode;
    property ErrorData: TErrorData read GetErrorData write SetErrorData;
    property RawRpcRequest: string read GetRawRpcRequest write SetRawRpcRequest;
    property RawRpcResponse: string read GetRawRpcResponse write SetRawRpcResponse;
  end;

implementation

{ TRequestResult<T> }

constructor TRequestResult<T>.Create;
begin
  inherited Create;
  FWasHttpRequestSuccessful := False;
  FWasRequestSuccessfullyHandled := False;
  FReason := '';
  FHttpStatusCode := 0;
  FServerErrorCode := 0;
end;

constructor TRequestResult<T>.CreateFromResponse(const AResponse: IHttpApiResponse);
begin
  CreateFromResponse(AResponse, Default(T));
end;

constructor TRequestResult<T>.CreateFromResponse(const AResponse: IHttpApiResponse; const AResult: T);
begin
  Create;
  if AResponse <> nil then
  begin
    FHttpStatusCode := AResponse.StatusCode;
    FWasHttpRequestSuccessful := InRange(AResponse.StatusCode, 200, 299);
    FReason := AResponse.StatusText;
  end;
  FResult := AResult;
end;

constructor TRequestResult<T>.CreateWithError(AStatusCode: Integer; const AReason: string);
begin
  Create;
  FHttpStatusCode := AStatusCode;
  FReason := AReason;
  FWasHttpRequestSuccessful := False;
end;

destructor TRequestResult<T>.Destroy;
var
  V: TValue;
begin
 if Assigned(FErrorData) then
   FErrorData.Free;

 V := TValue.From<T>(FResult);

 if not V.IsEmpty then
   TValueUtils.FreeParameter(V);

  inherited;
end;

function TRequestResult<T>.GetWasSuccessful: Boolean;
begin
  Result := FWasHttpRequestSuccessful and FWasRequestSuccessfullyHandled;
end;

function TRequestResult<T>.GetWasHttpRequestSuccessful: Boolean;
begin
  Result := FWasHttpRequestSuccessful;
end;

procedure TRequestResult<T>.SetWasHttpRequestSuccessful(const Value: Boolean);
begin
  FWasHttpRequestSuccessful := Value;
end;

function TRequestResult<T>.GetWasRequestSuccessfullyHandled: Boolean;
begin
  Result := FWasRequestSuccessfullyHandled;
end;

procedure TRequestResult<T>.SetWasRequestSuccessfullyHandled(const Value: Boolean);
begin
  FWasRequestSuccessfullyHandled := Value;
end;

function TRequestResult<T>.GetReason: string;
begin
  Result := FReason;
end;

procedure TRequestResult<T>.SetReason(const Value: string);
begin
  FReason := Value;
end;

function TRequestResult<T>.GetResult: T;
begin
  Result := FResult;
end;

procedure TRequestResult<T>.SetResult(const Value: T);
begin
  FResult := Value;
end;

function TRequestResult<T>.GetHttpStatusCode: Integer;
begin
  Result := FHttpStatusCode;
end;

procedure TRequestResult<T>.SetHttpStatusCode(const Value: Integer);
begin
  FHttpStatusCode := Value;
end;

function TRequestResult<T>.GetServerErrorCode: Integer;
begin
  Result := FServerErrorCode;
end;

procedure TRequestResult<T>.SetServerErrorCode(const Value: Integer);
begin
  FServerErrorCode := Value;
end;

function TRequestResult<T>.GetErrorData: TErrorData;
begin
  Result := FErrorData;
end;

procedure TRequestResult<T>.SetErrorData(const Value: TErrorData);
begin
  FErrorData := Value;
end;

function TRequestResult<T>.GetRawRpcRequest: string;
begin
  Result := FRawRpcRequest;
end;

procedure TRequestResult<T>.SetRawRpcRequest(const Value: string);
begin
  FRawRpcRequest := Value;
end;

function TRequestResult<T>.GetRawRpcResponse: string;
begin
  Result := FRawRpcResponse;
end;

procedure TRequestResult<T>.SetRawRpcResponse(const Value: string);
begin
  FRawRpcResponse := Value;
end;

end.

