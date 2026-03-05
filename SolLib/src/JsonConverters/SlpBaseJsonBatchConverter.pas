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

unit SlpBaseJsonBatchConverter;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  System.Generics.Collections,
  System.JSON,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Serializers,
  SlpBaseJsonConverter,
  SlpJsonHelpers;

type
  /// Base class for batch JSON-RPC converters. Provides a generic
  /// ReadBatchArray method that handles deserialization of a JSON array
  /// into a TObjectList-based batch type.
  TBaseJsonBatchConverter = class(TBaseJsonConverter)
  protected
    class function ReadBatchArray<TBatch: class, constructor; TItem: class>(
      const AReader: TJsonReader; const AExistingValue: TValue;
      const ASerializer: TJsonSerializer): TValue; static;
  end;

implementation

{ TBaseJsonBatchConverter }

class function TBaseJsonBatchConverter.ReadBatchArray<TBatch, TItem>(
  const AReader: TJsonReader; const AExistingValue: TValue;
  const ASerializer: TJsonSerializer): TValue;
var
  Batch: TObjectList<TItem>;
  JV: TJSONValue;
  Item: TItem;
  OwnBatch: Boolean;
begin
  if (AReader.TokenType = TJsonToken.None) and (not AReader.Read) then Exit(nil);
  while AReader.TokenType = TJsonToken.Comment do
    if not AReader.Read then Exit(nil);

  if AReader.TokenType = TJsonToken.Null then Exit(nil);
  if AReader.TokenType <> TJsonToken.StartArray then
    raise EJsonSerializationException.Create('Expected JSON array for batch');

  if AExistingValue.IsEmpty or (AExistingValue.AsObject = nil) then
  begin
    Batch := TObjectList<TItem>(TBatch.Create);
    OwnBatch := True;
  end
  else
  begin
    Batch := TObjectList<TItem>(AExistingValue.AsObject);
    Batch.Clear;
    OwnBatch := False;
  end;

  try
    while AReader.ReadNextArrayElement(JV) do
    begin
      try
        Item := ASerializer.Deserialize<TItem>(JV.ToJSON);
        if Item <> nil then
        begin
          try
            Batch.Add(Item);
          except
            Item.Free;
            raise;
          end;
        end;
      finally
        JV.Free;
      end;
    end;
    TValue.Make(@Batch, TypeInfo(TBatch), Result);
  except
    if OwnBatch then
      Batch.Free;
    raise;
  end;
end;

end.
