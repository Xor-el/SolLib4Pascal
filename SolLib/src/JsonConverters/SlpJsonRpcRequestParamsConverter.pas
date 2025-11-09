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

unit SlpJsonRpcRequestParamsConverter;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  System.Generics.Collections,
  System.JSON,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  System.JSON.Utils,
  SlpBaseJsonConverter,
  SlpValueHelpers,
  SlpJsonHelpers;

type
  TJsonRpcRequestParamsConverter = class(TBaseJsonConverter)
  private
    class function ReadParamsListFromJsonValue(const JV: TJSONValue): TList<TValue>; static;
  public
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
  end;

implementation

{ TJsonRpcRequestParamsConverter }

class function TJsonRpcRequestParamsConverter.ReadParamsListFromJsonValue(
  const JV: TJSONValue): TList<TValue>;
var
  Arr: TJSONArray;
  I: Integer;
begin
  if (JV = nil) or (JV is TJSONNull) then
    Exit(nil);

  Result := TList<TValue>.Create;

  if JV is TJSONArray then
  begin
    Arr := TJSONArray(JV);
    for I := 0 to Arr.Count - 1 do
      Result.Add(Arr.Items[I].ToTValue());
  end
  else
  begin
    // non-array JSON value => single param list
    Result.Add(JV.ToTValue());
  end;
end;

function TJsonRpcRequestParamsConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  // We only want to attach to TList<TValue> (or subclasses)
  Result := TJsonTypeUtils.InheritsFrom(ATypeInf, TList<TValue>);
end;

procedure TJsonRpcRequestParamsConverter.WriteJson(
  const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer);
var
  L: TList<TValue>;
  V: TValue;
begin
  if AValue.IsEmpty then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  L := TList<TValue>(AValue.AsObject);
  if L = nil then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  // Emit [] even if empty (JSON-RPC allows empty array params)
  AWriter.WriteStartArray;
  for V in L do
    WriteTValue(AWriter, ASerializer, V.Unwrap());
  AWriter.WriteEndArray;
end;

function TJsonRpcRequestParamsConverter.ReadJson(
  const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue;
  const ASerializer: TJsonSerializer): TValue;
var
  JV: TJSONValue;
  Existing: TList<TValue>;
  Parsed: TList<TValue>;
  Item: TValue;
begin
  JV := AReader.ReadJsonValue;
  try
    // If a list already exists, mutate it in-place
    if (not AExistingValue.IsEmpty) and (AExistingValue.Kind = tkClass) and
       (AExistingValue.AsObject is TList<TValue>) then
    begin
      Existing := TList<TValue>(AExistingValue.AsObject);
      Existing.Clear;

      Parsed := ReadParamsListFromJsonValue(JV);
      try
        if Parsed <> nil then
          for Item in Parsed do
            Existing.Add(Item);
      finally
        Parsed.Free; // we copied items; free the temp list
      end;

      Result := AExistingValue; // keep same instance
      Exit;
    end;

    // Otherwise create a new list and return it (caller will assign)
    Result := TValue.From<TList<TValue>>(ReadParamsListFromJsonValue(JV));
  finally
    JV.Free;
  end;
end;

end.

