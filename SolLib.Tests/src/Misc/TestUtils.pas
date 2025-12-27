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

unit TestUtils;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.JSON.Serializers,
  SlpJsonKit,
  SlpJsonStringEnumConverter,
  SlpEncodingConverter,
  SlpIOUtils;

type
  /// Minimal, test helpers.
  TTestUtils = class
  private
    class var FSerializer: TJsonSerializer;

    class function BuildSerializer: TJsonSerializer; static;

  public

    /// Read whole file as UTF-8 (default).
    class function ReadAllText(const AFileName: string): string; overload; static;
    class function ReadAllText(const AFileName: string; const AEncoding: TEncoding): string; overload; static;

    class function Serialize<T>(const AData: T): string; static;
    class function Deserialize<T>(const AData: string): T; static;

    class constructor Create();
    class destructor Destroy();
  end;

implementation

{ TTestUtils }

class constructor TTestUtils.Create;
begin
  FSerializer := BuildSerializer();
end;

class destructor TTestUtils.Destroy;
var
 I: Integer;
begin
  if Assigned(FSerializer) then
  begin
    if Assigned(FSerializer.Converters) then
    begin
      for I := 0 to FSerializer.Converters.Count - 1 do
        if Assigned(FSerializer.Converters[I]) then
          FSerializer.Converters[I].Free;
      FSerializer.Converters.Clear;
    end;
    FSerializer.Free;
  end;

  inherited;
end;

class function TTestUtils.BuildSerializer: TJsonSerializer;
var
  Converters     : TList<TJsonConverter>;
begin
  Converters := TList<TJsonConverter>.Create;
  try
    Converters.Add(TJsonStringEnumConverter.Create(TJsonNamingPolicy.CamelCase));
    Converters.Add(TEncodingConverter.Create);

    Result := TJsonSerializerFactory.CreateSerializer(
      TEnhancedContractResolver.Create(
        TJsonMemberSerialization.Public,
        TJsonNamingPolicy.CamelCase
      ),
      Converters
    );
  finally
    Converters.Free;
  end;
end;

class function TTestUtils.Serialize<T>(const AData: T): string;
begin
  Result := FSerializer.Serialize<T>(AData);
end;

class function TTestUtils.Deserialize<T>(const AData: string): T;
begin
  Result := FSerializer.Deserialize<T>(AData);
end;

class function TTestUtils.ReadAllText(const AFileName: string): string;
begin
  Result := ReadAllText(AFileName, TEncoding.UTF8);
end;

class function TTestUtils.ReadAllText(const AFileName: string; const AEncoding: TEncoding): string;
begin
  Result := TIOUtils.ReadAllText(AFileName, AEncoding);
end;

end.

