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

unit SlpJsonRpcBatchResponseItemResultConverter;

{$I ../Include/SolLib.inc}

interface

uses
  SysUtils,
  TypInfo,
  Rtti,
  System.JSON,
  System.JSON.Readers,
  System.JSON.Serializers,
  SlpBaseJsonConverter,
  SlpValueHelpers,
  SlpJsonHelpers;

type
  /// <summary>
  /// Converts a raw JSON value into a TValue for batch RPC response items.
  /// </summary>
  TJsonRpcBatchResponseItemResultConverter = class(TBaseJsonConverter)
  public
    /// <summary>
    /// Returns True when ATypeInf matches TValue.
    /// </summary>
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
    /// <summary>
    /// Deserializes a batch RPC response item result from a JSON reader.
    /// </summary>
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
  end;

implementation

{ TJsonRpcBatchResponseItemResultConverter }

function TJsonRpcBatchResponseItemResultConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := (ATypeInf = TypeInfo(TValue));
end;

function TJsonRpcBatchResponseItemResultConverter.ReadJson(
  const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue;
  const ASerializer: TJsonSerializer): TValue;
var
  LJV: TJSONValue;
begin
  // Read one JSON value (null/scalar/array/object) and convert into a TValue.
  LJV := AReader.ReadJsonValue;
  try
    if LJV = nil then
      Exit(TValue.Empty);

    // Convert DOM to TValue (primitives/arrays/objects/DOM passthrough)
    Result := LJV.ToTValue();
  finally
    LJV.Free;
  end;
end;

end.

