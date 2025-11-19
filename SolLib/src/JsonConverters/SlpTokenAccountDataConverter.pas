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

unit SlpTokenAccountDataConverter;

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
  SlpValueHelpers,
  SlpJsonHelpers;

type
  /// <summary>
  /// Handles different transaction meta encodings when deserialized.
  /// Target Delphi type is TValue (attach on a TValue property).
  /// - JSON object   -> TValue(TTokenAccountData)
  /// - JSON [string] -> TValue(TArray&lt;string&gt;)
  /// Anything else     -> raises EJsonSerializationException.
  /// </summary>
  TTokenAccountDataConverter = class(TJsonConverter)

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

function TTokenAccountDataConverter.CanConvert
  (ATypeInfo: PTypeInfo): Boolean;
begin
  Result := (ATypeInfo = TypeInfo(TValue));
end;

function TTokenAccountDataConverter.ReadJson
  (const AReader: TJsonReader; ATypeInfo: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  ObjJson: string;
  SR: TStringReader;
  JR: TJsonTextReader;
  Tx: TTokenAccountData;

  Elem: TJSONValue;
  Bag: TList<string>;
  Arr: TArray<string>;
  S: string;
begin
  // If positioned at a property name, step to its value
  if AReader.TokenType = TJsonToken.PropertyName then
    AReader.Read;

  case AReader.TokenType of
    // OBJECT -> TTokenAccountData via serializer
    TJsonToken.StartObject:
      begin
        ObjJson := AReader.ToJson; // consumes the whole object value
        SR := TStringReader.Create(ObjJson);
        try
          JR := TJsonTextReader.Create(SR);
          try
            Tx := ASerializer.Deserialize<TTokenAccountData>(JR);
            Result := TValue.From<TTokenAccountData>(Tx);
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
                  ('TTokenAccountDataConverter: array must contain only strings');

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
    ('Unsupported JSON value type in TTokenAccountDataConverter');
end;

procedure TTokenAccountDataConverter.WriteJson
  (const AWriter: TJsonWriter; const AValue: TValue;
  const ASerializer: TJsonSerializer);

var
  V: TValue;
  I, N: Integer;
begin
  V := AValue.Unwrap();

  if V.IsEmpty then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  // If the TValue holds an array of strings, emit it directly
  if V.IsType<TArray<string>> then
  begin
    N := V.GetArrayLength;
    AWriter.WriteStartArray;
    for I := 0 to N - 1 do
    begin
      ASerializer.Serialize(AWriter, V.GetArrayElement(I));
    end;
    AWriter.WriteEndArray;
    Exit();
  end;

  // Otherwise, delegate to the serializer (e.g., TTokenAccountData)
  ASerializer.Serialize(AWriter, V);
end;

end.
