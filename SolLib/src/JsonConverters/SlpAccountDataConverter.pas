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

unit SlpAccountDataConverter;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  System.JSON,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpValueHelpers,
  SlpJsonHelpers,
  SlpBaseJsonConverter;

type
  /// <summary>
  /// - If JSON is an array -> deserialize to TArray<string>.
  /// - If JSON is an object -> serialize that object back to compact JSON string,
  ///   return TArray<string> with [ json, 'jsonParsed' ].
  /// - Otherwise -> raise "Unable to parse account data".
  /// </summary>
  TAccountDataConverter = class(TBaseJsonConverter)

  public
    /// <summary>
    /// Returns True when ATypeInf matches TArray of string.
    /// </summary>
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
    /// <summary>
    /// Deserializes account data from a JSON reader (array or object form).
    /// </summary>
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
    /// <summary>
    /// Serializes account data to a JSON writer.
    /// </summary>
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
  end;

implementation

function TAccountDataConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := ATypeInf = TypeInfo(TArray<string>);
end;

function TAccountDataConverter.ReadJson(
  const AReader: TJsonReader; ATypeInf: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  LArr: TArray<string>;
begin
  // If JSON is an array -> TArray<string>
  if AReader.TokenType = TJsonToken.StartArray then
  begin
    ASerializer.Populate(AReader, LArr);
    Exit(TValue.From<TArray<string>>(LArr));
  end;

  // If JSON is an object -> ["<object-as-json>", "jsonParsed"]
  if AReader.TokenType = TJsonToken.StartObject then
  begin
    SetLength(LArr, 2);
    LArr[0] := AReader.ToJson();
    LArr[1] := 'jsonParsed';
    Exit(TValue.From<TArray<string>>(LArr));
  end;

  raise EJsonException.Create('Unable to parse account data');
end;

procedure TAccountDataConverter.WriteJson(
  const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer);
var
  LSArr: TArray<string>;
  LJV: TJSONValue;
  LV: TValue;
  LS: string;
begin
  LV := AValue.Unwrap();
  // Expecting a TArray<string> in all cases
  if LV.IsEmpty then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  if not LV.IsType<TArray<string>> then
    raise EJsonSerializationException.Create('TAccountDataConverter: expected TArray<string>');

  LSArr := LV.AsType<TArray<string>>;

  // Special shape: [ json, 'jsonParsed' ] -> write the json as the actual object
  if (Length(LSArr) = 2) and SameText(LSArr[1], 'jsonParsed') then
  begin
    // Try to parse the first entry as JSON and emit it as a DOM (preserving numerics)
    LJV := TJSONObject.ParseJSONValue(LSArr[0]);
    try
      if Assigned(LJV) then
      begin
        AWriter.WriteJsonValue(LJV);
        Exit;
      end
      else
      begin
        // If it didn't parse, fall back to writing the raw array of strings
        AWriter.WriteStartArray;
        AWriter.WriteValue(LSArr[0]);
        AWriter.WriteValue(LSArr[1]);
        AWriter.WriteEndArray;
        Exit;
      end;
    finally
      LJV.Free;
    end;
  end;

  // Default: write as a plain array of strings (e.g., ["", "base64"])
  AWriter.WriteStartArray;
  for LS in LSArr do
    AWriter.WriteValue(LS);
  AWriter.WriteEndArray;
end;

end.


