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
  SysUtils,
  TypInfo,
  Rtti,
  System.JSON,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpJsonHelpers,
  SlpValueHelpers,
  SlpNullable,
  SlpBaseJsonConverter;

type
  /// <summary>
  /// Converts a JsonRpcErrorResponse from json into its model representation.
  /// </summary>
  TRpcErrorResponseConverter = class(TBaseJsonConverter)
  public
    /// <summary>
    /// Returns True when ATypeInfo matches TJsonRpcErrorResponse.
    /// </summary>
    function CanConvert(ATypeInfo: PTypeInfo): Boolean; override;
    /// <summary>
    /// Deserializes a TJsonRpcErrorResponse from a JSON reader.
    /// </summary>
    function ReadJson(const AReader: TJsonReader; ATypeInfo: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
    /// <summary>
    /// Serializes a TJsonRpcErrorResponse to a JSON writer.
    /// </summary>
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
  end;

const
  SPropJsonRpc = 'jsonrpc';
  SPropId      = 'id';
  SPropError   = 'error';

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
  LErr: TJsonRpcErrorResponse;
  LProp: string;
  LJO: TJSONObject;
  LErrorContent: TErrorContent;
begin
  if AReader.TokenType <> TJsonToken.StartObject then
    Exit(nil);

  AReader.Read;

  LErr := TJsonRpcErrorResponse.Create;
  try
    while AReader.TokenType <> TJsonToken.EndObject do
    begin
      LProp := AReader.Value.AsString;

      AReader.Read;

      if LProp = SPropJsonRpc then
        LErr.Jsonrpc := AReader.Value.AsString
      else if LProp = SPropId then
      begin
        if AReader.Value.IsEmpty then
          LErr.Id := TNullable<Integer>.None
        else
          LErr.Id := AReader.Value.AsInteger;
      end
      else if LProp = SPropError then
      begin
        case AReader.TokenType of
          TJsonToken.&String:
            LErr.ErrorMessage := AReader.Value.AsString;

          TJsonToken.StartObject:
            begin
              LJO := TJSONObject(AReader.ReadJsonValue);
              try
                LErrorContent := ASerializer.Deserialize<TErrorContent>(LJO.ToJSON);
                LErr.Error := LErrorContent;
              finally
                LJO.Free;
              end;
            end;
        else
          AReader.Skip();
        end;
      end
      else
        AReader.Skip();

      AReader.Read;
    end;

    Result := LErr;
  except
    LErr.Free;
    raise;
  end;
end;

procedure TRpcErrorResponseConverter.WriteJson(
  const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer);
var
  LResp: TJsonRpcErrorResponse;
  LValue: TValue;
begin
  LValue := AValue.Unwrap();

  if LValue.IsEmpty or (LValue.AsObject = nil) then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  LResp := TJsonRpcErrorResponse(LValue.AsObject);

  AWriter.WriteStartObject;
  try
    AWriter.WritePropertyName(SPropJsonRpc);
    AWriter.WriteValue(LResp.Jsonrpc);

    AWriter.WritePropertyName(SPropError);
    if Assigned(LResp.Error) then
      ASerializer.Serialize(AWriter, LResp.Error)
    else if LResp.ErrorMessage <> '' then
      AWriter.WriteValue(LResp.ErrorMessage)
    else
      AWriter.WriteNull;

    AWriter.WritePropertyName(SPropId);
    if LResp.Id.HasValue then
      AWriter.WriteValue(LResp.Id.Value)
    else
      AWriter.WriteNull;
  finally
    AWriter.WriteEndObject;
  end;
end;


end.
