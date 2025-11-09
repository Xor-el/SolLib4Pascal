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

unit SlpNullableConverter;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes,
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
  S: string;
  SR: TStringReader;
  JR: TJsonTextReader;
  Underlying: T;
begin
  // ReadJsonValue raises on PropertyName, so advance to the value first.
  if AReader.TokenType = TJsonToken.PropertyName then
    AReader.Read;

  // Materialize the current value into a DOM node
  JV := AReader.ReadJsonValue; // consumes exactly one JSON value
  try
    // Map null/undefined -> None
    if (JV = nil) or JV.IsKindOfClass(TJSONNull) then
    begin
      Exit(TValue.From<TNullable<T>>(TNullable<T>.None));
    end;

    // Refeed that DOM as text into a fresh reader, and let the serializer build T
    S  := JV.ToJSON;
    SR := TStringReader.Create(S);
    try
      JR := TJsonTextReader.Create(SR);
      try
        Underlying := ASerializer.Deserialize<T>(JR);
      finally
        JR.Free;
      end;
    finally
      SR.Free;
    end;

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

