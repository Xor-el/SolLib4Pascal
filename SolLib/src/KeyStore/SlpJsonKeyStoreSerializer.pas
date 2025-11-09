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

unit SlpJsonKeyStoreSerializer;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.JSON.Serializers,
  SlpKeyStoreModel,
  SlpJsonKit;

type
  /// <summary>
  /// JSON serializer wrappers for keystore models.
  /// </summary>
  TJsonKeyStoreSerializer = class
  public
    type
      /// <summary>Pbkdf2-specific (de)serialization helpers.</summary>
      TPbkdf2 = class
      public
        class function Serialize(const AKeyStore: TKeyStore<TPbkdf2Params>): string; static;
        class function Deserialize(const AJson: string): TKeyStore<TPbkdf2Params>; static;
      end;

      /// <summary>Scrypt-specific (de)serialization helpers.</summary>
      TScrypt = class
      public
        class function Serialize(const AKeyStore: TKeyStore<TScryptParams>): string; static;
        class function Deserialize(const AJson: string): TKeyStore<TScryptParams>; static;
      end;
  end;

implementation

{ TJsonKeyStoreSerializer.TPbkdf2 }

class function TJsonKeyStoreSerializer.TPbkdf2.Serialize(
  const AKeyStore: TKeyStore<TPbkdf2Params>): string;
begin
  Result := TJsonSerializerFactory.Shared.Serialize<TKeyStore<TPbkdf2Params>>(AKeyStore);
end;

class function TJsonKeyStoreSerializer.TPbkdf2.Deserialize(
  const AJson: string): TKeyStore<TPbkdf2Params>;
begin
  Result := TJsonSerializerFactory.Shared.Deserialize<TKeyStore<TPbkdf2Params>>(AJson);
end;

{ TJsonKeyStoreSerializer.TScrypt }

class function TJsonKeyStoreSerializer.TScrypt.Serialize(
  const AKeyStore: TKeyStore<TScryptParams>): string;
begin
  Result := TJsonSerializerFactory.Shared.Serialize<TKeyStore<TScryptParams>>(AKeyStore);
end;

class function TJsonKeyStoreSerializer.TScrypt.Deserialize(
  const AJson: string): TKeyStore<TScryptParams>;
begin
  Result := TJsonSerializerFactory.Shared.Deserialize<TKeyStore<TScryptParams>>(AJson);
end;

end.

