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
  System.Classes,
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
  SR: TStringReader;
  JR: TJsonTextReader;
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
        TJsonToken.String:
          Err.ErrorMessage := AReader.Value.AsString;

        TJsonToken.StartObject:
          begin
            // Capture ONLY the error object here to avoid re-entrancy issues
            JO := TJSONObject(AReader.ReadJsonValue);
            // reader now at EndObject of "error"
            try
              ErrorContent := TErrorContent.Create;
              Err.Error := ErrorContent;
              // Populate Err.Error using a fresh reader over the captured JSON
              SR := TStringReader.Create(JO.ToJSON);
              try
                JR := TJsonTextReader.Create(SR);
                try
                  ASerializer.Populate(JR, ErrorContent);
                finally
                  JR.Free;
                end;
              finally
                SR.Free;
              end;
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
  Ctx: TRttiContext;
  T: TRttiType;
  PId: TRttiProperty;
  VId: TValue;
  NId: TNullable<Integer>;
  V: TValue;
begin
  V := AValue.Unwrap();

  // null / empty input -> write null
  if V.IsEmpty or (V.AsObject = nil) then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  Resp := TJsonRpcErrorResponse(V.AsObject);

  AWriter.WriteStartObject;
  try
    // "jsonrpc"
    AWriter.WritePropertyName('jsonrpc');
    AWriter.WriteValue(Resp.Jsonrpc);

    // "error": either a plain string (ErrorMessage) or an object (Error)
    AWriter.WritePropertyName('error');
    if Assigned(Resp.Error) then
    begin
      // object form
      ASerializer.Serialize(AWriter, Resp.Error);
    end
    else if Resp.ErrorMessage <> '' then
    begin
      // string form
      AWriter.WriteValue(Resp.ErrorMessage);
    end
    else
    begin
      // if neither provided, emit null (defensive)
      AWriter.WriteNull;
    end;

    // "id": prefer nullable integer semantics if present
    AWriter.WritePropertyName('id');

    // Try to obtain the "Id" property via RTTI (to tolerate future type changes)
    Ctx := TRttiContext.Create;
    try
      T := Ctx.GetType(Resp.ClassType);
      PId := nil;
      if T <> nil then
        PId := T.GetProperty('Id');

      if (PId <> nil) and PId.IsReadable then
      begin
        VId := PId.GetValue(Resp);

        // If it's exactly TNullable<Integer>, honor HasValue/Value
        if (VId.Kind = tkRecord) and (VId.TypeInfo = TypeInfo(TNullable<Integer>)) then
        begin
          NId := VId.AsType<TNullable<Integer>>;
          if NId.HasValue then
            AWriter.WriteValue(NId.Value)
          else
            AWriter.WriteNull;
        end
        else
        begin
          // Fallbacks: if a plain integer (or int64) was used, write it; allow null when empty
          case VId.Kind of
            tkInteger: AWriter.WriteValue(VId.AsInteger);
            tkInt64:   AWriter.WriteValue(VId.AsInt64);
          else
            // If something else (string/null/empty), be conservative:
            if VId.IsEmpty then
              AWriter.WriteNull
            else
              ASerializer.Serialize(AWriter, VId); // last-resort delegate
          end;
        end;
      end
      else
      begin
        // No Id property readable -> write null to match typical JSON-RPC when absent
        AWriter.WriteNull;
      end;
    finally
      Ctx.Free;
    end;

  finally
    AWriter.WriteEndObject;
  end;
end;


end.
