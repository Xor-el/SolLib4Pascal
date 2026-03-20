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

unit SlpTransactionErrorJsonConverter;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpRpcEnum,
  SlpNullable,
  SlpBaseJsonConverter;

type
  /// <summary>
  /// Converts a TransactionError from json into its model representation.
  /// </summary>
  TTransactionErrorJsonConverter = class(TBaseJsonConverter)
  public
    /// <summary>
    /// Returns True when ATypeInf matches TTransactionError.
    /// </summary>
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
    /// <summary>
    /// Deserializes a TTransactionError from a JSON reader.
    /// </summary>
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
    /// <summary>
    /// Serializes a TTransactionError to a JSON writer.
    /// </summary>
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
  end;

const
  SUnexpectedErrorValue = 'Unexpected error value.';

implementation

uses
  SlpEnumUtilities,
  SlpRpcModel;

{ TTransactionErrorJsonConverter }

function TTransactionErrorJsonConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := ATypeInf = TypeInfo(TTransactionError);
end;

function TTransactionErrorJsonConverter.ReadJson(const AReader: TJsonReader;
  ATypeInf: PTypeInfo; const AExistingValue: TValue;
  const ASerializer: TJsonSerializer): TValue;
var
  LErr: TTransactionError;
  LEnumStr: string;
  LErrType: TTransactionErrorType;
  LInstrType: TInstructionErrorType;
begin
  if AReader.TokenType = TJsonToken.Null then
    Exit(nil);

  LErr := TTransactionError.Create;
  try
    if AReader.TokenType = TJsonToken.&String then
    begin
      LEnumStr := AReader.Value.AsString;
      if TEnumUtilities.TryGetEnumValue<TTransactionErrorType>(LEnumStr, LErrType) then
        LErr.&Type := LErrType;
      Exit(LErr);
    end;

    if AReader.TokenType <> TJsonToken.StartObject then
      raise EJsonException.Create(SUnexpectedErrorValue);

    AReader.Read;

    if AReader.TokenType <> TJsonToken.PropertyName then
      raise EJsonException.Create(SUnexpectedErrorValue);

    LEnumStr := AReader.Value.AsString;
    if TEnumUtilities.TryGetEnumValue<TTransactionErrorType>(LEnumStr, LErrType) then
      LErr.&Type := LErrType;

    if LErr.&Type = TTransactionErrorType.InstructionError then
    begin
      AReader.Read;
      LErr.InstructionError := TInstructionError.Create;

      if AReader.TokenType <> TJsonToken.StartArray then
        raise EJsonException.Create(SUnexpectedErrorValue);

      AReader.Read;

      if AReader.TokenType <> TJsonToken.&Integer then
        raise EJsonException.Create(SUnexpectedErrorValue);

      LErr.InstructionError.InstructionIndex := AReader.Value.AsInteger;

      AReader.Read;

      if AReader.TokenType = TJsonToken.&String then
      begin
        LEnumStr := AReader.Value.AsString;
        if TEnumUtilities.TryGetEnumValue<TInstructionErrorType>(LEnumStr, LInstrType) then
          LErr.InstructionError.&Type := LInstrType;
        AReader.Read; // string
        AReader.Read; // endarray
        Exit(LErr);
      end;

      if AReader.TokenType <> TJsonToken.StartObject then
        raise EJsonException.Create(SUnexpectedErrorValue);

      AReader.Read;

      if AReader.TokenType <> TJsonToken.PropertyName then
        raise EJsonException.Create(SUnexpectedErrorValue);

      LEnumStr := AReader.Value.AsString;
      if TEnumUtilities.TryGetEnumValue<TInstructionErrorType>(LEnumStr, LInstrType) then
        LErr.InstructionError.&Type := LInstrType;

      AReader.Read;

      if (AReader.TokenType = TJsonToken.&Integer) or
        (AReader.TokenType = TJsonToken.Null) then
      begin
        case AReader.TokenType of
          TJsonToken.&Integer:
            LErr.InstructionError.CustomError := UInt32(AReader.Value.AsUInt64);

          TJsonToken.Null:
            LErr.InstructionError.CustomError := TNullable<UInt32>.None;
        end;
        AReader.Read; // number
        AReader.Read; // endobj
        AReader.Read; // endarray
        Exit(LErr);
      end;

      if AReader.TokenType <> TJsonToken.&String then
        raise EJsonException.Create(SUnexpectedErrorValue);

      LErr.InstructionError.BorshIoError := AReader.Value.AsString;

      AReader.Read; // number
      AReader.Read; // endobj
      AReader.Read; // endarray
    end
    else
    begin
      AReader.Read; // startobj details
      AReader.Read; // details property name
      AReader.Read; // details property value
      AReader.Read; // endobj details
      AReader.Read; // endobj
      Exit(LErr);
    end;

    Result := LErr;
  except
    LErr.Free;
    raise;
  end;
end;

procedure TTransactionErrorJsonConverter.WriteJson(
  const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer);
var
  LErr: TTransactionError;
  LInstr: TInstructionError;
  LErrTypeName: string;
  LInstrTypeName: string;
begin
  // Null writer
  if AValue.IsEmpty then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  // Expect a TTransactionError instance
  if not AValue.IsType<TTransactionError> then
    raise EJsonSerializationException.Create('TTransactionErrorJsonConverter: expected TTransactionError');

  LErr := AValue.AsType<TTransactionError>;
  if LErr = nil then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  // If not InstructionError, serialize as a simple string (enum name).
  if LErr.&Type <> TTransactionErrorType.InstructionError then
  begin
    LErrTypeName := TEnumUtilities.ToString<TTransactionErrorType>(LErr.&Type);
    AWriter.WriteValue(LErrTypeName);
    Exit;
  end;

  // InstructionError -> {"InstructionError": [ index, <payload> ]}
  LInstr := LErr.InstructionError;
  if LInstr = nil then
  begin
    // Defensive: still emit a valid shape with nulls if model is incomplete
    AWriter.WriteStartObject;
    AWriter.WritePropertyName('InstructionError');
    AWriter.WriteStartArray;
    AWriter.WriteValue(0);
    AWriter.WriteNull;
    AWriter.WriteEndArray;
    AWriter.WriteEndObject;
    Exit;
  end;

  LInstrTypeName := TEnumUtilities.ToString<TInstructionErrorType>(LInstr.&Type);

  AWriter.WriteStartObject;
  AWriter.WritePropertyName('InstructionError');
  AWriter.WriteStartArray;

  // First array element: instruction index
  // Use the property name you set in ReadJson (InstructionIndex)
  AWriter.WriteValue(LInstr.InstructionIndex);

  // Second array element:
  // Choose between { "<Enum>": <int/null|string> } or "<Enum>" (string)
  if (LInstr.&Type = TInstructionErrorType.Custom) then
  begin
    AWriter.WriteStartObject;
    AWriter.WritePropertyName(LInstrTypeName);
    if LInstr.CustomError.HasValue then
      AWriter.WriteValue(LInstr.CustomError.Value)
    else
      AWriter.WriteNull;
    AWriter.WriteEndObject;
  end
  else if (LInstr.&Type = TInstructionErrorType.BorshIoError) or (LInstr.BorshIoError <> '') then
  begin
    AWriter.WriteStartObject;
    AWriter.WritePropertyName(LInstrTypeName);
    AWriter.WriteValue(LInstr.BorshIoError);
    AWriter.WriteEndObject;
  end
  else
  begin
    // Simple case: just the enum name as string
    AWriter.WriteValue(LInstrTypeName);
  end;

  AWriter.WriteEndArray;   // ]
  AWriter.WriteEndObject;  // }
end;

end.
