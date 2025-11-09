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

unit SlpJsonConverterFactory;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.JSON.Serializers,
  System.JSON.Converters,
  SlpJsonListConverter,
  SlpRpcModel;

type
  TJsonConverterFactory = class
  public
    class function GetRpcConverters: TList<TJsonConverter>; static;
  end;

implementation

{ TJsonConverterFactory }

class function TJsonConverterFactory.GetRpcConverters: TList<TJsonConverter>;
begin
  Result := TList<TJsonConverter>.Create;

  // === Basic list converters ===
  Result.Add(TJsonListConverter<string>.Create);
  Result.Add(TJsonListConverter<UInt64>.Create);

  // === PreserveNullOnRead list converters ===
  Result.Add(TPreserveNullOnReadJsonObjectListConverter<TClusterNode>.Create);
  Result.Add(TPreserveNullOnReadJsonObjectListConverter<TInflationReward>.Create);
  Result.Add(TPreserveNullOnReadJsonObjectListConverter<TLargeAccount>.Create);
  Result.Add(TPreserveNullOnReadJsonObjectListConverter<TAccountInfo>.Create);
  Result.Add(TPreserveNullOnReadJsonObjectListConverter<TAccountKeyPair>.Create);
  Result.Add(TPreserveNullOnReadJsonObjectListConverter<TPerformanceSample>.Create);
  Result.Add(TPreserveNullOnReadJsonObjectListConverter<TSignatureStatusInfo>.Create);
  Result.Add(TPreserveNullOnReadJsonObjectListConverter<TTokenAccount>.Create);
  Result.Add(TPreserveNullOnReadJsonObjectListConverter<TLargeTokenAccount>.Create);
  Result.Add(TPreserveNullOnReadJsonObjectListConverter<TPrioritizationFeeItem>.Create);

  // === Dictionary converter ===
  Result.Add(TJsonStringDictionaryConverter<TList<UInt64>>.Create);
end;

end.

