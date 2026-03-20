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

unit SlpSecretKeyStoreService;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.JSON,
  System.DateUtils,
  SlpIOUtilities,
  SlpKeyStoreKdfChecker,
  SlpKeyStoreEnum,
  SlpKeyStoreService,
  SlpSolLibExceptions;

type
  /// <summary>
  /// Unified keystore service that auto-detects the KDF type (scrypt or PBKDF2)
  /// from JSON and dispatches to the appropriate service.
  /// </summary>
  TSecretKeyStoreService = class
  private
    FKeyStoreScryptService: TKeyStoreScryptService;
    FKeyStorePbkdf2Service: TKeyStorePbkdf2Service;
  public
    constructor Create; overload;
    constructor Create(AKeyStoreScryptService: TKeyStoreScryptService;
      AKeyStorePbkdf2Service: TKeyStorePbkdf2Service); overload;
    destructor Destroy; override;

    /// <summary>Extracts the address from a JSON keystore string.</summary>
    class function GetAddressFromKeyStore(const AJson: string): string; static;

    /// <summary>Generates a UTC-timestamped filename for keystore export.</summary>
    class function GenerateUtcFileName(const AAddress: string): string; static;

    function DecryptKeyStoreFromFile(const APassword, AFilePath: string): TBytes;
    function DecryptKeyStoreFromJson(const APassword, AJson: string): TBytes;
    function EncryptAndGenerateDefaultKeyStoreAsJson(const APassword: string;
      const AKey: TBytes; const AAddress: string): string;
  end;

implementation

{ TSecretKeyStoreService }

constructor TSecretKeyStoreService.Create;
begin
  Create(TKeyStoreScryptService.Create, TKeyStorePbkdf2Service.Create);
end;

constructor TSecretKeyStoreService.Create(AKeyStoreScryptService: TKeyStoreScryptService;
  AKeyStorePbkdf2Service: TKeyStorePbkdf2Service);
begin
  inherited Create;
  FKeyStoreScryptService := AKeyStoreScryptService;
  FKeyStorePbkdf2Service := AKeyStorePbkdf2Service;
end;

destructor TSecretKeyStoreService.Destroy;
begin
  FKeyStoreScryptService.Free;
  FKeyStorePbkdf2Service.Free;
  inherited;
end;

class function TSecretKeyStoreService.GetAddressFromKeyStore(const AJson: string): string;
var
  LRootVal: TJSONValue;
  LRootObj: TJSONObject;
  LAddrVal: TJSONValue;
begin
  if AJson = '' then
    raise EArgumentNilException.Create('json');

  LRootVal := TJSONObject.ParseJSONValue(AJson);
  if LRootVal = nil then
    raise EJsonParseException.Create('Could not process JSON');
  try
    if not (LRootVal is TJSONObject) then
      raise EJsonParseException.Create('Could not process JSON');

    LRootObj := TJSONObject(LRootVal);
    if not LRootObj.TryGetValue<TJSONValue>('address', LAddrVal) then
      raise EJsonException.Create('Could not get address from JSON');

    Result := LAddrVal.Value;
  finally
    LRootVal.Free;
  end;
end;

class function TSecretKeyStoreService.GenerateUtcFileName(const AAddress: string): string;
var
  LIso: string;
begin
  if AAddress = '' then
    raise EArgumentNilException.Create('address');

  LIso := DateToISO8601(TTimeZone.Local.ToUniversalTime(Now), True).Replace(':', '-');
  Result := 'utc--' + LIso + '--' + AAddress;
end;

function TSecretKeyStoreService.DecryptKeyStoreFromFile(const APassword, AFilePath: string): TBytes;
begin
  if APassword = '' then
    raise EArgumentNilException.Create('password');
  if AFilePath = '' then
    raise EArgumentNilException.Create('filePath');

  Result := DecryptKeyStoreFromJson(APassword, TIOUtilities.ReadAllText(AFilePath, TEncoding.UTF8));
end;

function TSecretKeyStoreService.DecryptKeyStoreFromJson(const APassword, AJson: string): TBytes;
begin
  if APassword = '' then
    raise EArgumentNilException.Create('password');
  if AJson = '' then
    raise EArgumentNilException.Create('json');

  case TKeyStoreKdfChecker.GetKeyStoreKdfType(AJson) of
    TKdfType.Pbkdf2:
      Result := FKeyStorePbkdf2Service.DecryptKeyStoreFromJson(APassword, AJson);
    TKdfType.Scrypt:
      Result := FKeyStoreScryptService.DecryptKeyStoreFromJson(APassword, AJson);
  else
    raise EInvalidKdfException.Create('Invalid kdf type');
  end;
end;

function TSecretKeyStoreService.EncryptAndGenerateDefaultKeyStoreAsJson(
  const APassword: string; const AKey: TBytes; const AAddress: string): string;
begin
  if APassword = '' then
    raise EArgumentNilException.Create('password');
  if AAddress = '' then
    raise EArgumentNilException.Create('address');

  Result := FKeyStoreScryptService.EncryptAndGenerateKeyStoreAsJson(APassword, AKey, AAddress);
end;

end.

