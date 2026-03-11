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

unit SlpJsonRpcBatchResponseConverter;

{$I ../Include/SolLib.inc}

interface

uses
  System.Rtti,
  System.TypInfo,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Serializers,
  SlpBaseJsonBatchConverter;

type
  /// <summary>
  /// JSON converter that deserializes a JSON array into a TJsonRpcBatchResponse.
  /// </summary>
  TJsonRpcBatchResponseConverter = class(TBaseJsonBatchConverter)
  public
    /// <summary>
    /// Returns True when ATypeInf matches TJsonRpcBatchResponse.
    /// </summary>
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
    /// <summary>
    /// Deserializes a JSON array of RPC response objects into a TJsonRpcBatchResponse.
    /// </summary>
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
  end;

implementation

uses
  SlpRpcMessage;

function TJsonRpcBatchResponseConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := ATypeInf = TypeInfo(TJsonRpcBatchResponse);
end;

function TJsonRpcBatchResponseConverter.ReadJson(
  const AReader: TJsonReader; ATypeInf: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
begin
  Result := ReadBatchArray<TJsonRpcBatchResponse, TJsonRpcBatchResponseItem>(
    AReader, AExistingValue, ASerializer);
end;

end.
