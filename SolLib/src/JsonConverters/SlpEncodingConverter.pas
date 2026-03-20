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

unit SlpEncodingConverter;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpEnumUtilities,
  SlpValueHelpers,
  SlpRpcEnum,
  SlpSolLibTypes,
  SlpBaseJsonConverter;

type
  /// <summary>
  /// Converts TBinaryEncoding values to and from their Solana JSON string representations.
  /// </summary>
  TEncodingConverter = class(TBaseJsonConverter)
  public
    /// <summary>
    /// Returns True when ATypeInfo matches TBinaryEncoding.
    /// </summary>
    function CanConvert(ATypeInfo: PTypeInfo): Boolean; override;
    /// <summary>
    /// Deserializes a TBinaryEncoding value from a JSON reader.
    /// </summary>
    function ReadJson(const AReader: TJsonReader; ATypeInfo: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
    /// <summary>
    /// Serializes a TBinaryEncoding value to a JSON writer.
    /// </summary>
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
  end;

implementation

function TEncodingConverter.CanConvert(ATypeInfo: PTypeInfo): Boolean;
begin
  Result := ATypeInfo = TypeInfo(TBinaryEncoding);
end;

function TEncodingConverter.ReadJson(const AReader: TJsonReader; ATypeInfo: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  LS: string;
  LEnc: TBinaryEncoding;
begin
  if AReader.TokenType = TJsonToken.Null then
    Exit(TValue.Empty);

  if (ATypeInfo = nil) or (ATypeInfo.Kind <> tkEnumeration) then
    raise EJsonException.Create('EncodingConverter called for non-enum type.');

  LS := AReader.Value.AsString;
  if not TEnumUtilities.TryGetEnumValue<TBinaryEncoding>(LS, LEnc,
    function(AInput: string): string
    begin
      Result := StringReplace(AInput, '+', '', [rfReplaceAll]);
    end) then
    raise EJsonException.CreateFmt('Unknown binary encoding "%s".', [LS]);

  Result := TValue.From<TBinaryEncoding>(LEnc);
end;

procedure TEncodingConverter.WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
  const ASerializer: TJsonSerializer);
var
  LEnc: TBinaryEncoding;
  LV: TValue;
begin
  LV := AValue.Unwrap();

  if not LV.TryAsType<TBinaryEncoding>(LEnc) then
    raise EJsonException.Create('EncodingConverter received unexpected value type.');

  case LEnc of
    TBinaryEncoding.Json:
      AWriter.WriteValue('json');

    TBinaryEncoding.JsonParsed:
      AWriter.WriteValue('jsonParsed');

    TBinaryEncoding.Base58:
      AWriter.WriteValue('base58');

    TBinaryEncoding.Base64:
      AWriter.WriteValue('base64');

    TBinaryEncoding.Base64Zstd:
      AWriter.WriteValue('base64+zstd');
  else
    raise EJsonException.CreateFmt(
      'EncodingConverter received unsupported encoding value (%d).',
      [Ord(LEnc)]
    );
  end;
end;


end.

