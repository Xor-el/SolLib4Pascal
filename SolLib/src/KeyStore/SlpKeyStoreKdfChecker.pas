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

unit SlpKeyStoreKdfChecker;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.StrUtils,
  System.JSON,
  System.JSON.Serializers,
  SlpSolLibExceptions,
  SlpKeyStoreEnum,
  SlpKeyStoreService;

type
  /// <summary>
  /// Implements a checker for the <see cref="TKeyStore{TKdfParams}"/>'s <see cref="TKdfType"/>.
  /// </summary>
  TKeyStoreKdfChecker = class
  private
    /// <summary>
    /// Get the kdf type string from the json document.
    /// </summary>
    /// <param name="ARoot">The parsed JSON root object.</param>
    /// <returns>The kdf type string.</returns>
    /// <exception cref="EJsonException">Throws exception when json property <c>crypto</c> or <c>kdf</c> couldn't be found</exception>
    class function GetKdfTypeFromJson(const ARoot: TJSONObject): string; static;
  public
    /// <summary>
    /// Gets the kdf type from the json keystore.
    /// </summary>
    /// <param name="AJson">The json keystore.</param>
    /// <returns>The kdf type.</returns>
    /// <exception cref="EArgumentNilException">Throws exception when <c>json</c> param is null/empty.</exception>
    /// <exception cref="EJsonParseException">Throws exception when text could not be processed to JSON.</exception>
    /// <exception cref="EJsonException">Throws exception when <c>kdf</c> json property is <c>null</c>.</exception>
    /// <exception cref="EInvalidKdfException">Throws exception when the <c>kdf</c> json property has an invalid <see cref="TKdfType"/> value.</exception>
    class function GetKeyStoreKdfType(const AJson: string): TKdfType; static;
  end;

implementation

{ TKeyStoreKdfChecker }

class function TKeyStoreKdfChecker.GetKdfTypeFromJson
  (const ARoot: TJSONObject): string;
var
  LCrypto: TJSONObject;
  LKdfVal: TJSONValue;
begin
  if (ARoot = nil) then
    raise EJsonException.Create('could not get crypto params object from json');

  if not ARoot.TryGetValue<TJSONObject>('crypto', LCrypto) then
    raise EJsonException.Create('could not get crypto params object from json');

  LKdfVal := nil;
  if not LCrypto.TryGetValue<TJSONValue>('kdf', LKdfVal) then
    raise EJsonException.Create('could not get kdf object from json');

  if (LKdfVal = nil) or (LKdfVal.Value = '') then
    raise EJsonException.Create('could not get kdf type from json');

  Result := LKdfVal.Value;
end;

class function TKeyStoreKdfChecker.GetKeyStoreKdfType(const AJson: string)
  : TKdfType;
var
  LRootVal: TJSONValue;
  LRootObj: TJSONObject;
  LKdfStr: string;
  LIdx: Integer;
begin
  if (AJson = '') then
    raise EArgumentNilException.Create('json');

  LRootVal := TJSONObject.ParseJSONValue(AJson);
  if LRootVal = nil then
    raise EJsonParseException.Create('could not process json');

  try
    if not(LRootVal is TJSONObject) then
      raise EJsonSerializationException.Create('could not process json');

    LRootObj := TJSONObject(LRootVal);

    LKdfStr := GetKdfTypeFromJson(LRootObj);

    LIdx := IndexStr(LKdfStr, [TKeyStorePbkdf2Service.KdfType, TKeyStoreScryptService.KdfType]);

    case LIdx of
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
