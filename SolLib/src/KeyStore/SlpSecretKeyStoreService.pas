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

unit SlpSecretKeyStoreService;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.JSON,
  System.DateUtils,
  SlpIOUtils,
  SlpKeyStoreKdfChecker,
  SlpKeyStoreEnum,
  SlpKeyStoreService,
  SlpSolLibExceptions;

type
  /// <summary>
  /// Implements a keystore compatible with the web3 secret storage standard.
  /// https://ethereum.org/developers/docs/data-structures-and-encoding/web3-secret-storage/
  /// </summary>
  TSecretKeyStoreService = class
  private
    FKeyStoreScryptService: TKeyStoreScryptService;
    FKeyStorePbkdf2Service: TKeyStorePbkdf2Service;
  public
    /// <summary>
    /// Initializes a new instance of <c>TSecretKeyStoreService</c>.
    /// </summary>
    constructor Create; overload;
    /// <summary>
    /// Initializes a new instance of <c>TSecretKeyStoreService</c> with injected services.
    /// </summary>
    /// <param name="AKeyStoreScryptService">The scrypt-based keystore service.</param>
    /// <param name="AKeyStorePbkdf2Service">The PBKDF2-based keystore service.</param>
    constructor Create(AKeyStoreScryptService: TKeyStoreScryptService;
                       AKeyStorePbkdf2Service: TKeyStorePbkdf2Service); overload;
    /// <summary>
    /// Frees owned services.
    /// </summary>
    destructor Destroy; override;

    /// <summary>
    /// Get the address from the json keystore.
    /// </summary>
    /// <param name="AJson">The json keystore.</param>
    /// <returns>The address string.</returns>
    /// <exception cref="EArgumentNilException">Thrown when <c>AJson</c> is empty.</exception>
    /// <exception cref="EJsonParseException">Thrown when text could not be processed to JSON.</exception>
    /// <exception cref="EJsonException">Thrown when <c>address</c> JSON property is not present.</exception>
    class function GetAddressFromKeyStore(const AJson: string): string; static;

    /// <summary>
    /// Generates a UTC filename for the keystore.
    /// </summary>
    /// <param name="AAddress">The address to include in the filename.</param>
    /// <returns>The generated filename.</returns>
    /// <exception cref="EArgumentNilException">Thrown when <c>AAddress</c> is empty.</exception>
    class function GenerateUtcFileName(const AAddress: string): string; static;

    /// <summary>
    /// Decrypt the keystore from a file path.
    /// </summary>
    /// <param name="APassword">The password.</param>
    /// <param name="AFilePath">The keystore file path.</param>
    /// <returns>The decrypted private key bytes.</returns>
    /// <exception cref="EArgumentNilException">Thrown when <c>APassword</c> or <c>AFilePath</c> is empty.</exception>
    function DecryptKeyStoreFromFile(const APassword, AFilePath: string): TBytes;

    /// <summary>
    /// Decrypt the keystore from a json string.
    /// </summary>
    /// <param name="APassword">The password.</param>
    /// <param name="AJson">The json keystore.</param>
    /// <returns>The decrypted private key bytes.</returns>
    /// <exception cref="EArgumentNilException">Thrown when <c>APassword</c> or <c>AJson</c> is empty.</exception>
    /// <exception cref="EJsonParseException">Thrown when text could not be processed to JSON.</exception>
    /// <exception cref="EJsonException">Thrown when the JSON content is missing required properties.</exception>
    /// <exception cref="EInvalidKdfException">Throws exception when the <c>kdf</c> json property has an invalid <see cref="TKdfType"/> value.</exception>
    function DecryptKeyStoreFromJson(const APassword, AJson: string): TBytes;

    /// <summary>
    /// Encrypt and generate the default (scrypt) keystore as json.
    /// </summary>
    /// <param name="APassword">The password.</param>
    /// <param name="AKey">The private key bytes.</param>
    /// <param name="AAddress">The address.</param>
    /// <returns>The json keystore.</returns>
    /// <exception cref="EArgumentNilException">Thrown when <c>APassword</c> or <c>AAddress</c> is empty.</exception>
    function EncryptAndGenerateDefaultKeyStoreAsJson(const APassword: string; const AKey: TBytes;
      const AAddress: string): string;
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
 if Assigned(FKeyStoreScryptService) then
   FKeyStoreScryptService.Free;
 if Assigned(FKeyStorePbkdf2Service) then
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
    raise EJSONParseException.Create('could not process json');
  try
    if not (LRootVal is TJSONObject) then
      raise EJSONParseException.Create('could not process json');

    LRootObj := TJSONObject(LRootVal);
    LAddrVal := nil;
    if not LRootObj.TryGetValue<TJSONValue>('address', LAddrVal) then
      raise EJsonException.Create('could not get address from json');

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
var
  LJson: string;
begin
  if APassword = '' then
    raise EArgumentNilException.Create('password');
  if AFilePath = '' then
    raise EArgumentNilException.Create('filePath');

  LJson := TIOUtils.ReadAllText(AFilePath, TEncoding.UTF8);
  Result := DecryptKeyStoreFromJson(APassword, LJson);
end;

function TSecretKeyStoreService.DecryptKeyStoreFromJson(const APassword, AJson: string): TBytes;
var
  LType: TKdfType;
begin
  if APassword = '' then
    raise EArgumentNilException.Create('password');
  if AJson = '' then
    raise EArgumentNilException.Create('json');

  LType := TKeyStoreKdfChecker.GetKeyStoreKdfType(AJson);
  case LType of
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

