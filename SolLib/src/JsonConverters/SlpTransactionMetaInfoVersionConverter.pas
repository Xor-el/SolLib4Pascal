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

unit SlpTransactionMetaInfoVersionConverter;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpValueHelpers;

type
  /// <summary>
  /// JSON converter for a "dynamic" value that is either a string or a 32-bit integer.
  /// </summary>
  TTransactionMetaInfoVersionConverter = class(TJsonConverter)
  public
    function CanConvert(ATypeInfo: PTypeInfo): Boolean; override;

    function ReadJson(const AReader: TJsonReader; ATypeInfo: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;

    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
  end;

implementation

{ TTransactionMetaInfoVersionConverter }

function TTransactionMetaInfoVersionConverter.CanConvert(ATypeInfo: PTypeInfo): Boolean;
begin
  Result := ATypeInfo = TypeInfo(TValue);
end;

function TTransactionMetaInfoVersionConverter.ReadJson(const AReader: TJsonReader; ATypeInfo: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  I64: Int64;
  S  : string;
begin
  // If we're currently at a PropertyName, advance to its value
  if AReader.TokenType = TJsonToken.PropertyName then
    AReader.Read;

  case AReader.TokenType of
    TJsonToken.String:
      begin
        S := AReader.Value.AsString;
        Exit(TValue.From<string>(S));
      end;

    TJsonToken.Integer:
      begin
        I64 := AReader.Value.AsInt64;
        // Must fit in 32-bit Integer
        if (I64 < Low(Integer)) or (I64 > High(Integer)) then
          raise EJsonSerializationException.CreateFmt(
            'DynamicTypeConverter: integer value %d out of 32-bit range', [I64]
          );
        Exit(TValue.From<Integer>(Integer(I64)));
      end;
  end;

  // Anything else (null, float, bool, object, array) is unsupported
  raise EJsonSerializationException.CreateFmt(
    'TTransactionMetaInfoVersionConverter: unsupported token %d (expected string or integer)', [Ord(AReader.TokenType)]
  );
end;

procedure TTransactionMetaInfoVersionConverter.WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
  const ASerializer: TJsonSerializer);
var
  V: TValue;
begin
  V := AValue.Unwrap();

  if V.IsEmpty then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  // Only accept Delphi string or 32-bit Integer
  if V.IsType<Integer> or V.IsType<string> then
  begin
    ASerializer.Serialize(AWriter, V);
    Exit;
  end;

  raise EJsonSerializationException.Create(
    'TTransactionMetaInfoVersionConverter: only Integer and string are supported for writing'
  );
end;

end.

