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
  LErr: TJsonRpcErrorResponse;
  LProp: string;
  LJO: TJSONObject;
  LErrorContent: TErrorContent;

begin
  if AReader.TokenType <> TJsonToken.StartObject then
    Exit(nil);

  AReader.Read;

  LErr := TJsonRpcErrorResponse.Create;

  while AReader.TokenType <> TJsonToken.EndObject do
  begin
    LProp := AReader.Value.AsString;

    AReader.Read;

    if LProp = 'jsonrpc' then
    begin
      LErr.Jsonrpc := AReader.Value.AsString;
    end
    else if LProp = 'id' then
    begin
     if AReader.Value.IsEmpty then
      LErr.Id := TNullable<Integer>.None
      else
      LErr.Id := AReader.Value.AsInteger
    end
    else if LProp = 'error' then
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
    begin
      AReader.Skip();
    end;

    AReader.Read;
  end;

  Result := LErr;
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
    AWriter.WritePropertyName('jsonrpc');
    AWriter.WriteValue(LResp.Jsonrpc);

    AWriter.WritePropertyName('error');
    if Assigned(LResp.Error) then
      ASerializer.Serialize(AWriter, LResp.Error)
    else if LResp.ErrorMessage <> '' then
      AWriter.WriteValue(LResp.ErrorMessage)
    else
      AWriter.WriteNull;

    AWriter.WritePropertyName('id');
    if LResp.Id.HasValue then
      AWriter.WriteValue(LResp.Id.Value)
    else
      AWriter.WriteNull;
  finally
    AWriter.WriteEndObject;
  end;
end;


end.
