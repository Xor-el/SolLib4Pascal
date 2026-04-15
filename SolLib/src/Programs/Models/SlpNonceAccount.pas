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

unit SlpNonceAccount;

{$I ../../Include/SolLib.inc}

interface

uses
  SysUtils,
  SlpRpcModel,
  SlpPublicKey,
  SlpDeserialization;

type
  INonceAccount = interface
    ['{6E7A4A9B-AE4F-4A2B-BF7F-0C2A36E1F1F2}']
    function GetVersion: Cardinal;
    procedure SetVersion(const AValue: Cardinal);

    function GetState: Cardinal;
    procedure SetState(const AValue: Cardinal);

    function GetAuthorized: IPublicKey;
    procedure SetAuthorized(const AValue: IPublicKey);

    function GetNonce: IPublicKey;
    procedure SetNonce(const AValue: IPublicKey);

    function GetFeeCalculator: TFeeCalculator;
    procedure SetFeeCalculator(const AValue: TFeeCalculator);

    /// <summary>
    /// The value used to specify version.
    /// </summary>
    property Version: Cardinal read GetVersion write SetVersion;
    /// <summary>
    /// The state of the nonce account.
    /// </summary>
    property State: Cardinal read GetState write SetState;
    /// <summary>
    /// The public key of the account authorized to interact with the nonce account.
    /// </summary>
    property Authorized: IPublicKey read GetAuthorized write SetAuthorized;
    /// <summary>
    /// The nonce.
    /// </summary>
    property Nonce: IPublicKey read GetNonce write SetNonce;
    /// <summary>
    /// The fee calculator
    /// </summary>
    property FeeCalculator: TFeeCalculator read GetFeeCalculator write SetFeeCalculator;
  end;

  /// <summary>
  /// Represents a <see cref="SystemProgram"/> Nonce Account in Solana.
  /// </summary>
  TNonceAccount = class(TInterfacedObject, INonceAccount)
  public
    /// <summary>
    /// The size of the data for a nonce account.
    /// </summary>
    const AccountDataSize = 80;
  private
    type
      /// <summary>
      /// Represents the layout of the <see cref="NonceAccount"/> data structure.
      /// </summary>
      TLayout = record
        /// <summary>
        /// The offset at which the version value begins.
        /// </summary>
        const VersionOffset       = 0;
        /// <summary>
        /// The offset at which the state value begins.
        /// </summary>
        const StateOffset         = 4;
        /// <summary>
        /// The offset at which the authorized public key value begins.
        /// </summary>
        const AuthorizedKeyOffset = 8;
        /// <summary>
        /// The offset at which the current nonce public key value begins.
        /// </summary>
        const NonceKeyOffset      = 40;
        /// <summary>
        /// The offset at which the fee calculator value begins.
        /// </summary>
        const FeeCalculatorOffset = 72;
      end;
  private
    FVersion, FState: Cardinal;
    FAuthorized, FNonce: IPublicKey;
    FFeeCalculator: TFeeCalculator;

    function GetVersion: Cardinal;
    procedure SetVersion(const AValue: Cardinal);
    function GetState: Cardinal;
    procedure SetState(const AValue: Cardinal);
    function GetAuthorized: IPublicKey;
    procedure SetAuthorized(const AValue: IPublicKey);
    function GetNonce: IPublicKey;
    procedure SetNonce(const AValue: IPublicKey);
    function GetFeeCalculator: TFeeCalculator;
    procedure SetFeeCalculator(const AValue: TFeeCalculator);
  public
    destructor Destroy; override;
    /// <summary>
    /// Deserialize a TBytes into a <see cref="NonceAccount"/> instance.
    /// </summary>
    /// <param name="AData">The data to deserialize into the structure.</param>
    /// <returns>The Nonce Account structure.</returns>
    class function Deserialize(const AData: TBytes): INonceAccount; static;
  end;

implementation

{ TNonceAccount }

destructor TNonceAccount.Destroy;
begin
  if Assigned(FFeeCalculator) then
    FFeeCalculator.Free;

  inherited;
end;

function TNonceAccount.GetAuthorized: IPublicKey;
begin
  Result := FAuthorized;
end;

function TNonceAccount.GetFeeCalculator: TFeeCalculator;
begin
  Result := FFeeCalculator;
end;

function TNonceAccount.GetNonce: IPublicKey;
begin
  Result := FNonce;
end;

function TNonceAccount.GetState: Cardinal;
begin
  Result := FState;
end;

function TNonceAccount.GetVersion: Cardinal;
begin
  Result := FVersion;
end;

procedure TNonceAccount.SetAuthorized(const AValue: IPublicKey);
begin
  FAuthorized := AValue;
end;

procedure TNonceAccount.SetFeeCalculator(const AValue: TFeeCalculator);
begin
  FFeeCalculator := AValue;
end;

procedure TNonceAccount.SetNonce(const AValue: IPublicKey);
begin
  FNonce := AValue;
end;

procedure TNonceAccount.SetState(const AValue: Cardinal);
begin
  FState := AValue;
end;

procedure TNonceAccount.SetVersion(const AValue: Cardinal);
begin
  FVersion := AValue;
end;

class function TNonceAccount.Deserialize(const AData: TBytes): INonceAccount;
var
  FC: TFeeCalculator;
begin
  if Length(AData) <> AccountDataSize then
    raise EArgumentException.CreateFmt('data has wrong size. Expected %d bytes, actual %d bytes.',
      [AccountDataSize, Length(AData)]);

  Result := TNonceAccount.Create;
  // version/state
  Result.Version := TDeserialization.GetU32(AData, TLayout.VersionOffset);
  Result.State := TDeserialization.GetU32(AData, TLayout.StateOffset);
  // keys
  Result.Authorized := TDeserialization.GetPubKey(AData, TLayout.AuthorizedKeyOffset);
  Result.Nonce := TDeserialization.GetPubKey(AData, TLayout.NonceKeyOffset);
  // fee calculator
  FC := TFeeCalculator.Create();
  FC.LamportsPerSignature := TDeserialization.GetU64(AData, TLayout.FeeCalculatorOffset);
  Result.FeeCalculator := FC;
end;

end.

