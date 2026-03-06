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

unit SlpRpcErrorResponseConverter;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  System.JSON,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpJsonHelpers,
  SlpValueHelpers,
  SlpNullable;

type
  /// <summary>
  /// Converts a JsonRpcErrorResponse from json into its model representation.
  /// </summary>
  TRpcErrorResponseConverter = class(TJsonConverter)
  public
    function CanConvert(ATypeInfo: PTypeInfo): Boolean; override;
    function ReadJson(const AReader: TJsonReader; ATypeInfo: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer)
      : TValue; override;
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
  end;

implementation

uses
  SlpRpcMessage;

{ TRpcErrorResponseConverter }

function TRpcErrorResponseConverter.CanConvert(ATypeInfo: PTypeInfo): Boolean;
begin
  Result := ATypeInfo = TypeInfo(TJsonRpcErrorResponse);
end;

function TRpcErrorResponseConverter.ReadJson(const AReader: TJsonReader;
  ATypeInfo: PTypeInfo; const AExistingValue: TValue;
  const ASerializer: TJsonSerializer): TValue;
var
  Err: TJsonRpcErrorResponse;
  Prop: string;
  JO: TJSONObject;
  ErrorContent: TErrorContent;

begin
  if AReader.TokenType <> TJsonToken.StartObject then
    Exit(nil);

  AReader.Read;

  Err := TJsonRpcErrorResponse.Create;

  while AReader.TokenType <> TJsonToken.EndObject do
  begin
    Prop := AReader.Value.AsString;

    AReader.Read;

    if Prop = 'jsonrpc' then
    begin
      Err.Jsonrpc := AReader.Value.AsString;
    end
    else if Prop = 'id' then
    begin
     if AReader.Value.IsEmpty then
      Err.Id := TNullable<Integer>.None
      else
      Err.Id := AReader.Value.AsInteger
    end
    else if Prop = 'error' then
    begin
      case AReader.TokenType of
        TJsonToken.&String:
          Err.ErrorMessage := AReader.Value.AsString;

        TJsonToken.StartObject:
          begin
            JO := TJSONObject(AReader.ReadJsonValue);
            try
              ErrorContent := ASerializer.Deserialize<TErrorContent>(JO.ToJSON);
              Err.Error := ErrorContent;
            finally
              JO.Free;
            end;
          end;
      else
        AReader.Skip();
      end;
    end
    else
    begin
      AReader.Skip();
    end;

    AReader.Read;
  end;

  Result := Err;
end;


procedure TRpcErrorResponseConverter.WriteJson(
  const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer);
var
  Resp: TJsonRpcErrorResponse;
  V: TValue;
begin
  V := AValue.Unwrap();

  if V.IsEmpty or (V.AsObject = nil) then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  Resp := TJsonRpcErrorResponse(V.AsObject);

  AWriter.WriteStartObject;
  try
    AWriter.WritePropertyName('jsonrpc');
    AWriter.WriteValue(Resp.Jsonrpc);

    AWriter.WritePropertyName('error');
    if Assigned(Resp.Error) then
      ASerializer.Serialize(AWriter, Resp.Error)
    else if Resp.ErrorMessage <> '' then
      AWriter.WriteValue(Resp.ErrorMessage)
    else
      AWriter.WriteNull;

    AWriter.WritePropertyName('id');
    if Resp.Id.HasValue then
      AWriter.WriteValue(Resp.Id.Value)
    else
      AWriter.WriteNull;
  finally
    AWriter.WriteEndObject;
  end;
end;


end.
