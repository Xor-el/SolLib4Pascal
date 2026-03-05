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

unit SlpJsonRpcBatchRequestConverter;

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
  TJsonRpcBatchRequestConverter = class(TBaseJsonBatchConverter)
  public
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
  end;

implementation

uses
  SlpRpcMessage;

function TJsonRpcBatchRequestConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := ATypeInf = TypeInfo(TJsonRpcBatchRequest);
end;

function TJsonRpcBatchRequestConverter.ReadJson(
  const AReader: TJsonReader; ATypeInf: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
begin
  Result := ReadBatchArray<TJsonRpcBatchRequest, TJsonRpcRequest>(
    AReader, AExistingValue, ASerializer);
end;

end.
