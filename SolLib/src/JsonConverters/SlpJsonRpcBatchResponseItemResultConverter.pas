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

unit SlpJsonRpcBatchResponseItemResultConverter;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  System.JSON,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  SlpBaseJsonConverter,
  SlpValueHelpers,
  SlpJsonHelpers;

type
  TJsonRpcBatchResponseItemResultConverter = class(TBaseJsonConverter)
  public
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
  end;

implementation

{ TJsonRpcBatchResponseItemResultConverter }

function TJsonRpcBatchResponseItemResultConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := (ATypeInf = TypeInfo(TValue));
end;

procedure TJsonRpcBatchResponseItemResultConverter.WriteJson(
  const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer);
begin
  if AValue.IsEmpty then
  begin
    AWriter.WriteNull;
    Exit;
  end;

  WriteTValue(AWriter, ASerializer, AValue.Unwrap());
end;

function TJsonRpcBatchResponseItemResultConverter.ReadJson(
  const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue;
  const ASerializer: TJsonSerializer): TValue;
var
  JV: TJSONValue;
begin
  // Read one JSON value (null/scalar/array/object) and convert into a TValue.
  JV := AReader.ReadJsonValue;
  try
    if JV = nil then
      Exit(TValue.Empty);

    // Convert DOM to TValue (primitives/arrays/objects/DOM passthrough)
    Result := JV.ToTValue();
  finally
    JV.Free;
  end;
end;

end.

