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

unit SlpAccountDataConverter;

{$I ..\Include\SolLib.inc}

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
  SlpJsonHelpers;

type
  /// <summary>
  /// - If JSON is an array -> deserialize to TArray<string>.
  /// - If JSON is an object -> serialize that object back to compact JSON string,
  ///   return TArray<string> with [ json, 'jsonParsed' ].
  /// - Otherwise -> raise "Unable to parse account data".
  /// </summary>
  TAccountDataConverter = class(TJsonConverter)

  public
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
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
  Arr: TArray<string>;
begin
  // If JSON is an array -> TArray<string>
  if AReader.TokenType = TJsonToken.StartArray then
  begin
    ASerializer.Populate(AReader, Arr);
    Exit(TValue.From<TArray<string>>(Arr));
  end;

  // If JSON is an object -> ["<object-as-json>", "jsonParsed"]
  if AReader.TokenType = TJsonToken.StartObject then
  begin
    SetLength(Arr, 2);
    Arr[0] := AReader.ToJson();
    Arr[1] := 'jsonParsed';
    Exit(TValue.From<TArray<string>>(Arr));
  end;

  raise EJsonException.Create('Unable to parse account data');
end;

procedure TAccountDataConverter.WriteJson(
  const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer);
var
  SArr: TArray<string>;
  JV: TJSONValue;
begin
  // Expecting a TArray<string> in all cases
  if AValue.IsEmpty then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  if not AValue.IsType<TArray<string>> then
    raise EJsonSerializationException.Create('TAccountDataConverter: expected TArray<string>');

  SArr := AValue.AsType<TArray<string>>;

  // Special shape: [ json, 'jsonParsed' ] -> write the json as the actual object
  if (Length(SArr) = 2) and SameText(SArr[1], 'jsonParsed') then
  begin
    // Try to parse the first entry as JSON and emit it as a DOM (preserving numerics)
    JV := TJSONObject.ParseJSONValue(SArr[0]);
    try
      if Assigned(JV) then
      begin
        AWriter.WriteJsonValue(JV);
        Exit;
      end
      else
      begin
        // If it didn't parse, fall back to writing the raw array of strings
        AWriter.WriteStartArray;
        AWriter.WriteValue(SArr[0]);
        AWriter.WriteValue(SArr[1]);
        AWriter.WriteEndArray;
        Exit;
      end;
    finally
      JV.Free;
    end;
  end;

  // Default: write as a plain array of strings (e.g., ["", "base64"])
  AWriter.WriteStartArray;
  for var S in SArr do
    AWriter.WriteValue(S);
  AWriter.WriteEndArray;
end;

end.


