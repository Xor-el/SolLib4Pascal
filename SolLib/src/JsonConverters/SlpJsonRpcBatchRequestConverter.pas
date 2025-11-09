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

unit SlpJsonRpcBatchRequestConverter;

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
  TJsonRpcBatchRequestConverter = class(TJsonConverter)
  public
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
  end;

implementation

{ TJsonRpcBatchRequestConverter }

uses
  SlpRpcMessage;

function TJsonRpcBatchRequestConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := ATypeInf = TypeInfo(TJsonRpcBatchRequest);
end;

function TJsonRpcBatchRequestConverter.ReadJson(
  const AReader: TJsonReader; ATypeInf: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  Batch: TJsonRpcBatchRequest;
  JV: TJSONValue;
  Item: TJsonRpcRequest;
begin
  // Normalize entry
  if (AReader.TokenType = TJsonToken.None) and (not AReader.Read) then Exit(nil);
  while AReader.TokenType = TJsonToken.Comment do if not AReader.Read then Exit(nil);

  if AReader.TokenType = TJsonToken.Null then Exit(nil);
  if AReader.TokenType <> TJsonToken.StartArray then
    raise EJsonSerializationException.Create('Expected JSON array for TJsonRpcBatchRequest');

  // Create/reuse
  if AExistingValue.IsEmpty or (AExistingValue.AsObject = nil) then
    Batch := TJsonRpcBatchRequest.Create
  else begin
    Batch := TJsonRpcBatchRequest(AExistingValue.AsObject);
    Batch.Clear;
  end;

  // Pull each element via the helper (handles comment skipping + positioning)
  while AReader.ReadNextArrayElement(JV) do
  begin
    try
      Item := ASerializer.Deserialize<TJsonRpcRequest>(JV.ToJSON);
      if Item <> nil then Batch.Add(Item);
    finally
      JV.Free;
    end;
  end;

  Result := TValue.From<TJsonRpcBatchRequest>(Batch);
end;

procedure TJsonRpcBatchRequestConverter.WriteJson(
  const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer);
var
  Batch: TJsonRpcBatchRequest;
  I: Integer;
begin
  if AValue.IsEmpty or (AValue.AsObject = nil) then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  Batch := TJsonRpcBatchRequest(AValue.AsObject);

  AWriter.WriteStartArray;
  for I := 0 to Batch.Count - 1 do
    ASerializer.Serialize(AWriter, Batch[I]);
  AWriter.WriteEndArray;
end;

end.

