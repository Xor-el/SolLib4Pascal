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
  SlpRpcEnum;

type
  TEncodingConverter = class(TJsonConverter)
  public
    function CanConvert(ATypeInfo: PTypeInfo): Boolean; override;
    function ReadJson(const AReader: TJsonReader; ATypeInfo: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
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
  S: string;
  Enc: TBinaryEncoding;
begin
  if AReader.TokenType = TJsonToken.Null then
    Exit(TValue.Empty);

  if (ATypeInfo = nil) or (ATypeInfo.Kind <> tkEnumeration) then
    raise EJsonException.Create('EncodingConverter called for non-enum type.');

  S := AReader.Value.AsString;

  if SameText(S, 'json') then
    Enc := TBinaryEncoding.Json
  else if SameText(S, 'jsonParsed') then
    Enc := TBinaryEncoding.JsonParsed
  else if SameText(S, 'base58') then
    Enc := TBinaryEncoding.Base58
  else if SameText(S, 'base64') then
    Enc := TBinaryEncoding.Base64
  else if SameText(S, 'base64+zstd') then
    Enc := TBinaryEncoding.Base64Zstd
  else
    raise EJsonException.CreateFmt('Unknown binary encoding "%s".', [S]);

  Result := TValue.From<TBinaryEncoding>(Enc);
end;

procedure TEncodingConverter.WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
  const ASerializer: TJsonSerializer);
var
  Enc: TBinaryEncoding;
begin
  if not AValue.TryAsType<TBinaryEncoding>(Enc) then
    raise EJsonException.Create('EncodingConverter received unexpected value type.');

  case Enc of
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
      [Ord(Enc)]
    );
  end;
end;


end.

