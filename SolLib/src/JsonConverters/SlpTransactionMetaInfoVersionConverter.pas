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

unit SlpTransactionMetaInfoVersionConverter;

{$I ../Include/SolLib.inc}

interface

uses
  SysUtils,
  TypInfo,
  Rtti,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpBaseJsonConverter,
  SlpValueHelpers;

type
  /// <summary>
  /// JSON converter for a "dynamic" value that is either a string or a 32-bit integer.
  /// </summary>
  TTransactionMetaInfoVersionConverter = class(TBaseJsonConverter)
  public
    /// <summary>
    /// Returns True when ATypeInfo matches TValue.
    /// </summary>
    function CanConvert(ATypeInfo: PTypeInfo): Boolean; override;

    /// <summary>
    /// Deserializes a string-or-integer dynamic value from a JSON reader.
    /// </summary>
    function ReadJson(const AReader: TJsonReader; ATypeInfo: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;

    /// <summary>
    /// Serializes a string-or-integer dynamic value to a JSON writer.
    /// </summary>
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
  LI64: Int64;
  LStr: string;
begin
  SkipPropertyName(AReader);

  case AReader.TokenType of
    TJsonToken.&String:
      begin
        LStr := AReader.Value.AsString;
        Exit(TValue.From<string>(LStr));
      end;

    TJsonToken.&Integer:
      begin
        LI64 := AReader.Value.AsInt64;
        // Must fit in 32-bit Integer
        if (LI64 < Low(Integer)) or (LI64 > High(Integer)) then
          raise EJsonSerializationException.CreateFmt(
            'DynamicTypeConverter: integer value %d out of 32-bit range', [LI64]
          );
        Exit(TValue.From<Integer>(Integer(LI64)));
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
  LValue: TValue;
begin
  LValue := AValue.Unwrap();

  if LValue.IsEmpty then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  // Only accept Delphi string or 32-bit Integer
  if LValue.IsType<Integer> or LValue.IsType<string> then
  begin
    WriteTValue(AWriter, ASerializer, LValue);
    Exit;
  end;

  raise EJsonSerializationException.Create(
    'TTransactionMetaInfoVersionConverter: only Integer and string are supported for writing'
  );
end;

end.

