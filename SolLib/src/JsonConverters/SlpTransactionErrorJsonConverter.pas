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

unit SlpTransactionErrorJsonConverter;

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
  SlpRpcEnum,
  SlpNullable;

type
  /// <summary>
  /// Converts a TransactionError from json into its model representation.
  /// </summary>
  TTransactionErrorJsonConverter = class(TJsonConverter)
  public
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer)
      : TValue; override;
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
  end;

implementation

uses
  SlpRpcModel;

{ TTransactionErrorJsonConverter }

function TTransactionErrorJsonConverter.CanConvert(ATypeInf: PTypeInfo)
  : Boolean;
begin
  Result := ATypeInf = TypeInfo(TTransactionError);
end;

function TTransactionErrorJsonConverter.ReadJson(const AReader: TJsonReader;
  ATypeInf: PTypeInfo; const AExistingValue: TValue;
  const ASerializer: TJsonSerializer): TValue;

  function TryParseEnum(const AType: PTypeInfo; const S: string;
    out OrdVal: Integer): Boolean;
  begin
    OrdVal := GetEnumValue(AType, S);
    Result := OrdVal >= 0;
  end;

var
  Err: TTransactionError;
  EnumOrd: Integer;
  EnumStr: string;
begin
  if AReader.TokenType = TJsonToken.Null then
    Exit(nil);

  Err := TTransactionError.Create;

  if AReader.TokenType = TJsonToken.String then
  begin
    EnumStr := AReader.Value.AsString;
    if TryParseEnum(TypeInfo(TTransactionErrorType), EnumStr, EnumOrd) then
      Err.&Type := TTransactionErrorType(EnumOrd);
    Exit(Err);
  end;

  if AReader.TokenType <> TJsonToken.StartObject then
    raise EJsonException.Create('Unexpected error value.');

  AReader.Read;

  if AReader.TokenType <> TJsonToken.PropertyName then
    raise EJsonException.Create('Unexpected error value.');

  begin
    EnumStr := AReader.Value.AsString;
    if TryParseEnum(TypeInfo(TTransactionErrorType), EnumStr, EnumOrd) then
      Err.&Type := TTransactionErrorType(EnumOrd);
  end;

  if Err.&Type = TTransactionErrorType.InstructionError then
  begin
    AReader.Read;
    Err.InstructionError := TInstructionError.Create;

    if AReader.TokenType <> TJsonToken.StartArray then
      raise EJsonException.Create('Unexpected error value.');

    AReader.Read;

    if AReader.TokenType <> TJsonToken.Integer then
      raise EJsonException.Create('Unexpected error value.');

    Err.InstructionError.InstructionIndex := AReader.Value.AsInteger;

    AReader.Read;

    if AReader.TokenType = TJsonToken.String then
    begin
      EnumStr := AReader.Value.AsString;
      if TryParseEnum(TypeInfo(TInstructionErrorType), EnumStr, EnumOrd) then
        Err.InstructionError.&Type := TInstructionErrorType(EnumOrd);
      AReader.Read; // string
      AReader.Read; // endarray
      Exit(Err);
    end;

    if AReader.TokenType <> TJsonToken.StartObject then
      raise EJsonException.Create('Unexpected error value.');

    AReader.Read;

    if AReader.TokenType <> TJsonToken.PropertyName then
      raise EJsonException.Create('Unexpected error value.');

    EnumStr := AReader.Value.AsString;
    if TryParseEnum(TypeInfo(TInstructionErrorType), EnumStr, EnumOrd) then
      Err.InstructionError.&Type := TInstructionErrorType(EnumOrd);

    AReader.Read;

    if (AReader.TokenType = TJsonToken.Integer) or
      (AReader.TokenType = TJsonToken.Null) then
    begin
      case AReader.TokenType of
        TJsonToken.Integer:
          Err.InstructionError.CustomError := UInt32(AReader.Value.AsUInt64);

        TJsonToken.Null:
          Err.InstructionError.CustomError := TNullable<UInt32>.None;
      end;
      AReader.Read; // number
      AReader.Read; // endobj
      AReader.Read; // endarray
      Exit(Err);
    end;

    if AReader.TokenType <> TJsonToken.String then
      raise EJsonException.Create('Unexpected error value.');

    Err.InstructionError.BorshIoError := AReader.Value.AsString;

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
    Exit(Err);
  end;

  Result := Err;
end;

procedure TTransactionErrorJsonConverter.WriteJson(
  const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer);
var
  Err: TTransactionError;
  Instr: TInstructionError;
  ErrTypeName: string;
  InstrTypeName: string;
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

  Err := AValue.AsType<TTransactionError>;
  if Err = nil then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  // If not InstructionError, serialize as a simple string (enum name).
  if Err.&Type <> TTransactionErrorType.InstructionError then
  begin
    ErrTypeName := GetEnumName(TypeInfo(TTransactionErrorType), Ord(Err.&Type));
    AWriter.WriteValue(ErrTypeName);
    Exit;
  end;

  // InstructionError -> {"InstructionError": [ index, <payload> ]}
  Instr := Err.InstructionError;
  if Instr = nil then
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

  InstrTypeName := GetEnumName(TypeInfo(TInstructionErrorType), Ord(Instr.&Type));

  AWriter.WriteStartObject;
  AWriter.WritePropertyName('InstructionError');
  AWriter.WriteStartArray;

  // First array element: instruction index
  // Use the property name you set in ReadJson (InstructionIndex)
  AWriter.WriteValue(Instr.InstructionIndex);

  // Second array element:
  // Choose between { "<Enum>": <int/null|string> } or "<Enum>" (string)
  if (Instr.&Type = TInstructionErrorType.Custom) then
  begin
    AWriter.WriteStartObject;
    AWriter.WritePropertyName(InstrTypeName);
    if Instr.CustomError.HasValue then
      AWriter.WriteValue(Instr.CustomError.Value)
    else
      AWriter.WriteNull;
    AWriter.WriteEndObject;
  end
  else if (Instr.&Type = TInstructionErrorType.BorshIoError) or
          (Instr.BorshIoError <> '') then
  begin
    AWriter.WriteStartObject;
    AWriter.WritePropertyName(InstrTypeName);
    AWriter.WriteValue(Instr.BorshIoError);
    AWriter.WriteEndObject;
  end
  else
  begin
    // Simple case: just the enum name as string
    AWriter.WriteValue(InstrTypeName);
  end;

  AWriter.WriteEndArray;   // ]
  AWriter.WriteEndObject;  // }
end;

end.
