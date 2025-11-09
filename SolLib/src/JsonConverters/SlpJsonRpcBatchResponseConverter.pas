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

unit SlpJsonRpcBatchResponseConverter;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  System.JSON,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpJsonHelpers;

type
  TJsonRpcBatchResponseConverter = class(TJsonConverter)
  public
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
  end;

implementation

uses
  SlpRpcMessage;

{ TJsonRpcBatchResponseConverter }

function TJsonRpcBatchResponseConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := ATypeInf = TypeInfo(TJsonRpcBatchResponse);
end;

function TJsonRpcBatchResponseConverter.ReadJson(
  const AReader: TJsonReader; ATypeInf: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  Batch: TJsonRpcBatchResponse;
  JV: TJSONValue;
  Item: TJsonRpcBatchResponseItem;
  OwnBatch: Boolean;
begin
  // Normalize entry
  if (AReader.TokenType = TJsonToken.None) and (not AReader.Read) then Exit(nil);
  while AReader.TokenType = TJsonToken.Comment do
    if not AReader.Read then Exit(nil);

  if AReader.TokenType = TJsonToken.Null then Exit(nil);
  if AReader.TokenType <> TJsonToken.StartArray then
    raise EJsonSerializationException.Create('Expected JSON array for TJsonRpcBatchResponse');

  if AExistingValue.IsEmpty or (AExistingValue.AsObject = nil) then
  begin
    Batch := TJsonRpcBatchResponse.Create;
    OwnBatch := True;   // we created it → free on exceptions
  end
  else
  begin
    Batch := TJsonRpcBatchResponse(AExistingValue.AsObject);
    Batch.Clear;
    OwnBatch := False;  // caller owns existing instance
  end;

  try
    while AReader.ReadNextArrayElement(JV) do
    begin
      try
        Item := ASerializer.Deserialize<TJsonRpcBatchResponseItem>(JV.ToJSON);
        if Item <> nil then
        begin
          try
            Batch.Add(Item); // list owns items
          except
            Item.Free;       // avoid leak if Add ever raises
            raise;
          end;
        end;
      finally
        JV.Free; // always free the temporary DOM node
      end;
    end;

    Result := TValue.From<TJsonRpcBatchResponse>(Batch);
  except
    // Only free if we created the batch here
    if OwnBatch then
      Batch.Free;
    raise;
  end;
end;


procedure TJsonRpcBatchResponseConverter.WriteJson(
  const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer);
var
  Batch: TJsonRpcBatchResponse;
  I: Integer;
begin
  if AValue.IsEmpty or (AValue.AsObject = nil) then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  Batch := TJsonRpcBatchResponse(AValue.AsObject);

  AWriter.WriteStartArray;
  for I := 0 to Batch.Count - 1 do
    ASerializer.Serialize(AWriter, Batch[I]); // delegates to item converter
  AWriter.WriteEndArray;
end;

end.

