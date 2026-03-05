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

unit SlpNullableConverter;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.JSON,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpNullable,
  SlpJsonHelpers;

type
  /// JSON converter for TNullable<T> (value-types-only).
  /// Register one instance per closed generic (e.g., Int64, Double, etc).
  TNullableConverter<T> = class(TJsonConverter)
  public
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;

    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;

    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
  end;

  TNullableIntegerConverter = class(TNullableConverter<Integer>);
  TNullableInt64Converter = class(TNullableConverter<Int64>);
  TNullableUInt32Converter = class(TNullableConverter<UInt32>);
  TNullableUInt64Converter = class(TNullableConverter<UInt64>);
  TNullableDoubleConverter = class(TNullableConverter<Double>);

implementation

function TNullableConverter<T>.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := (ATypeInf = TypeInfo(TNullable<T>));
end;

function TNullableConverter<T>.ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  JV: TJSONValue;
  Underlying: T;
begin
  if AReader.TokenType = TJsonToken.PropertyName then
    AReader.Read;

  JV := AReader.ReadJsonValue;
  try
    if (JV = nil) or JV.IsKindOfClass(TJSONNull) then
      Exit(TValue.From<TNullable<T>>(TNullable<T>.None));

    Underlying := ASerializer.Deserialize<T>(JV.ToJSON);
    Result := TValue.From<TNullable<T>>(TNullable<T>.Some(Underlying));
  finally
    JV.Free;
  end;
end;

procedure TNullableConverter<T>.WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
  const ASerializer: TJsonSerializer);
var
  N: TNullable<T>;
begin
  if AValue.IsEmpty then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  N := AValue.AsType<TNullable<T>>;
  if N.HasValue then
    ASerializer.Serialize<T>(AWriter, N.Value)
  else
    AWriter.WriteNull;
end;

end.

