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

unit SlpTransactionMetaInfoTransactionConverter;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.TypInfo,
  System.Rtti,
  System.Generics.Collections,
  System.JSON,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpBaseJsonConverter,
  SlpValueHelpers,
  SlpJsonHelpers;

type
  /// <summary>
  /// Handles different transaction meta encodings when deserialized.
  /// Target Delphi type is TValue (attach on a TValue property).
  /// - JSON object   -> TValue(TTransactionInfo)
  /// - JSON [string] -> TValue(TArray&lt;string&gt;)
  /// Anything else     -> raises EJsonSerializationException.
  /// </summary>
  TTransactionMetaInfoTransactionConverter = class(TBaseJsonConverter)

  public
    function CanConvert(ATypeInfo: PTypeInfo): Boolean; override;

    function ReadJson(const AReader: TJsonReader; ATypeInfo: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer)
      : TValue; override;

    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
  end;

implementation

uses
  SlpRpcModel;

function TTransactionMetaInfoTransactionConverter.CanConvert
  (ATypeInfo: PTypeInfo): Boolean;
begin
  Result := (ATypeInfo = TypeInfo(TValue));
end;

function TTransactionMetaInfoTransactionConverter.ReadJson
  (const AReader: TJsonReader; ATypeInfo: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  ObjJson: string;
  SR: TStringReader;
  JR: TJsonTextReader;
  Tx: TTransactionInfo;

  Elem: TJSONValue;
  Bag: TList<string>;
  Arr: TArray<string>;
  S: string;
begin
  // If positioned at a property name, step to its value
  if AReader.TokenType = TJsonToken.PropertyName then
    AReader.Read;

  case AReader.TokenType of
    // OBJECT -> TTransactionInfo via serializer
    TJsonToken.StartObject:
      begin
        ObjJson := AReader.ToJson; // consumes the whole object value
        SR := TStringReader.Create(ObjJson);
        try
          JR := TJsonTextReader.Create(SR);
          try
            Tx := ASerializer.Deserialize<TTransactionInfo>(JR);
            Result := TValue.From<TTransactionInfo>(Tx);
            Exit;
          finally
            JR.Free;
          end;
        finally
          SR.Free;
        end;
      end;

    // ARRAY -> accept only array of strings, iterate using ReadNextArrayElement
    TJsonToken.StartArray:
      begin
        Bag := TList<string>.Create;
        try
          // ReadNextArrayElement returns each element as a TJSONValue we must free.
          while AReader.ReadNextArrayElement(Elem) do
          begin
            try
              if not(Elem.IsExactClass(TJSONString)) then
                raise EJsonSerializationException.Create
                  ('TTransactionMetaInfoTransactionConverter: array must contain only strings');

              S := TJSONString(Elem).Value;
              Bag.Add(S);
            finally
              Elem.Free;
            end;
          end;

          Arr := Bag.ToArray;
          Result := TValue.From<TArray<string>>(Arr);
          Exit;
        finally
          Bag.Free;
        end;
      end;
  end;

  // Anything else is unsupported (null/bool/number/...)
  raise EJsonSerializationException.Create
    ('Unsupported JSON value type in TTransactionMetaInfoTransactionConverter');
end;

procedure TTransactionMetaInfoTransactionConverter.WriteJson
  (const AWriter: TJsonWriter; const AValue: TValue;
  const ASerializer: TJsonSerializer);
begin
  WriteTValue(AWriter, ASerializer, AValue);
end;

end.
