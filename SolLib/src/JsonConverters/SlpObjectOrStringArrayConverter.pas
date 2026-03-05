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

unit SlpObjectOrStringArrayConverter;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  System.Generics.Collections,
  System.JSON,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Serializers,
  SlpBaseJsonConverter,
  SlpJsonHelpers;

type
  /// Generic converter for JSON values that are either a JSON object (deserialized
  /// to T) or a JSON array of strings (deserialized to TArray<string>).
  /// Target Delphi type is TValue.
  TObjectOrStringArrayConverter<T: class> = class(TBaseJsonConverter)
  public
    function CanConvert(ATypeInfo: PTypeInfo): Boolean; override;
    function ReadJson(const AReader: TJsonReader; ATypeInfo: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
  end;

implementation

{ TObjectOrStringArrayConverter<T> }

function TObjectOrStringArrayConverter<T>.CanConvert(ATypeInfo: PTypeInfo): Boolean;
begin
  Result := (ATypeInfo = TypeInfo(TValue));
end;

function TObjectOrStringArrayConverter<T>.ReadJson(
  const AReader: TJsonReader; ATypeInfo: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  Elem: TJSONValue;
  Bag: TList<string>;
  Obj: T;
begin
  SkipPropertyName(AReader);

  case AReader.TokenType of
    TJsonToken.StartObject:
      begin
        Obj := ASerializer.Deserialize<T>(AReader.ToJson);
        Result := TValue.From<T>(Obj);
      end;

    TJsonToken.StartArray:
      begin
        Bag := TList<string>.Create;
        try
          while AReader.ReadNextArrayElement(Elem) do
          begin
            try
              if not Elem.IsExactClass(TJSONString) then
                raise EJsonSerializationException.CreateFmt(
                  '%s: array must contain only strings', [Self.ClassName]);
              Bag.Add(TJSONString(Elem).Value);
            finally
              Elem.Free;
            end;
          end;
          Result := TValue.From<TArray<string>>(Bag.ToArray);
        finally
          Bag.Free;
        end;
      end;
  else
    raise EJsonSerializationException.CreateFmt(
      'Unsupported JSON value type in %s', [Self.ClassName]);
  end;
end;

end.
