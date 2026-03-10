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

unit SlpJsonRpcRequestParamsConverter;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  System.Generics.Collections,
  System.JSON,
  System.JSON.Readers,
  System.JSON.Serializers,
  System.JSON.Utils,
  SlpBaseJsonConverter,
  SlpValueHelpers,
  SlpJsonHelpers;

type
  TJsonRpcRequestParamsConverter = class(TBaseJsonConverter)
  private
    class function ReadParamsListFromJsonValue(const AJV: TJSONValue): TList<TValue>; static;
  public
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
  end;

implementation

{ TJsonRpcRequestParamsConverter }

class function TJsonRpcRequestParamsConverter.ReadParamsListFromJsonValue(
  const AJV: TJSONValue): TList<TValue>;
var
  LArr: TJSONArray;
  LI: Integer;
begin
  if (AJV = nil) or (AJV is TJSONNull) then
    Exit(nil);

  Result := TList<TValue>.Create;

  if AJV is TJSONArray then
  begin
    LArr := TJSONArray(AJV);
    for LI := 0 to LArr.Count - 1 do
      Result.Add(LArr.Items[LI].ToTValue());
  end
  else
  begin
    // non-array JSON value => single param list
    Result.Add(AJV.ToTValue());
  end;
end;

function TJsonRpcRequestParamsConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  // We only want to attach to TList<TValue> (or subclasses)
  Result := TJsonTypeUtils.InheritsFrom(ATypeInf, TList<TValue>);
end;

function TJsonRpcRequestParamsConverter.ReadJson(
  const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue;
  const ASerializer: TJsonSerializer): TValue;
var
  LJV: TJSONValue;
  LExisting: TList<TValue>;
  LParsed: TList<TValue>;
  LItem: TValue;
begin
  LJV := AReader.ReadJsonValue;
  try
    // If a list already exists, mutate it in-place
    if (not AExistingValue.IsEmpty) and (AExistingValue.Kind = tkClass) and
       (AExistingValue.AsObject is TList<TValue>) then
    begin
      LExisting := TList<TValue>(AExistingValue.AsObject);
      LExisting.Clear;

      LParsed := ReadParamsListFromJsonValue(LJV);
      try
        if LParsed <> nil then
          for LItem in LParsed do
            LExisting.Add(LItem);
      finally
        LParsed.Free; // we copied items; free the temp list
      end;

      Result := AExistingValue; // keep same instance
      Exit;
    end;

    // Otherwise create a new list and return it (caller will assign)
    Result := TValue.From<TList<TValue>>(ReadParamsListFromJsonValue(LJV));
  finally
    LJV.Free;
  end;
end;

end.

