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
  SysUtils,
  Rtti,
  TypInfo,
  System.JSON,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpNullable,
  SlpJsonHelpers,
  SlpBaseJsonConverter;

type
  /// JSON converter for TNullable<T> (value-types-only).
  /// Register one instance per closed generic (e.g., Int64, Double, etc).
  TNullableConverter<T> = class(TBaseJsonConverter)
  public
    /// <summary>
    /// Returns True when ATypeInf matches TNullable of T.
    /// </summary>
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;

    /// <summary>
    /// Deserializes a TNullable of T from a JSON reader, returning None on null.
    /// </summary>
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;

    /// <summary>
    /// Serializes a TNullable of T to a JSON writer, emitting null when empty.
    /// </summary>
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
  LJV: TJSONValue;
  LUnderlying: T;
begin
  SkipPropertyName(AReader);

  LJV := AReader.ReadJsonValue;
  try
    if (LJV = nil) or LJV.IsKindOfClass(TJSONNull) then
      Exit(TValue.From<TNullable<T>>(TNullable<T>.None));

    LUnderlying := ASerializer.Deserialize<T>(LJV.ToJSON);
    Result := TValue.From<TNullable<T>>(TNullable<T>.Some(LUnderlying));
  finally
    LJV.Free;
  end;
end;

procedure TNullableConverter<T>.WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
  const ASerializer: TJsonSerializer);
var
  LN: TNullable<T>;
begin
  if AValue.IsEmpty then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  LN := AValue.AsType<TNullable<T>>;
  if LN.HasValue then
    ASerializer.Serialize<T>(AWriter, LN.Value)
  else
    AWriter.WriteNull;
end;

end.

