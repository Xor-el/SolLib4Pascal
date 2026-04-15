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

unit SlpKeyStoreKdfChecker;

{$I ../Include/SolLib.inc}

interface

uses
  SysUtils,
  StrUtils,
  System.JSON,
  System.JSON.Serializers,
  SlpSolLibExceptions,
  SlpKeyStoreEnum,
  SlpKeyStoreService;

type
  /// <summary>
  /// Detects the KDF type from a JSON keystore string.
  /// </summary>
  TKeyStoreKdfChecker = class sealed
  private
    class function GetKdfTypeFromJson(const ARoot: TJSONObject): string; static;
  public
    /// <summary>
    /// Parses the JSON keystore and returns the detected KDF type.
    /// </summary>
    class function GetKeyStoreKdfType(const AJson: string): TKdfType; static;
  end;

implementation

{ TKeyStoreKdfChecker }

class function TKeyStoreKdfChecker.GetKdfTypeFromJson(const ARoot: TJSONObject): string;
var
  LCrypto: TJSONObject;
  LKdfVal: TJSONValue;
begin
  if ARoot = nil then
    raise EJsonException.Create('Could not get crypto params from JSON');

  if not ARoot.TryGetValue<TJSONObject>('crypto', LCrypto) then
    raise EJsonException.Create('Could not get crypto params from JSON');

  if not LCrypto.TryGetValue<TJSONValue>('kdf', LKdfVal) then
    raise EJsonException.Create('Could not get kdf from JSON');

  if (LKdfVal = nil) or (LKdfVal.Value = '') then
    raise EJsonException.Create('Could not get kdf type from JSON');

  Result := LKdfVal.Value;
end;

class function TKeyStoreKdfChecker.GetKeyStoreKdfType(const AJson: string): TKdfType;
var
  LRootVal: TJSONValue;
  LKdfStr: string;
begin
  if AJson = '' then
    raise EArgumentNilException.Create('json');

  LRootVal := TJSONObject.ParseJSONValue(AJson);
  if LRootVal = nil then
    raise EJsonParseException.Create('Could not process JSON');
  try
    if not (LRootVal is TJSONObject) then
      raise EJsonSerializationException.Create('Could not process JSON');

    LKdfStr := GetKdfTypeFromJson(TJSONObject(LRootVal));

    case IndexStr(LKdfStr, [TKeyStorePbkdf2Service.KdfType, TKeyStoreScryptService.KdfType]) of
      0: Result := TKdfType.Pbkdf2;
      1: Result := TKdfType.Scrypt;
    else
      raise EInvalidKdfException.Create(LKdfStr);
    end;
  finally
    LRootVal.Free;
  end;
end;

end.
