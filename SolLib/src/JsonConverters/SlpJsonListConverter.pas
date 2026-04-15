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

unit SlpJsonListConverter;

{$I ../Include/SolLib.inc}

interface

uses
  SysUtils,
  Generics.Collections,
  TypInfo,
  Rtti,
  System.JSON,
  System.JSON.Utils,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers,
  System.JSON.Converters,
  SlpJsonHelpers;

type
  /// <summary>
  /// Shared helper that deserializes JSON array elements into a TList&lt;V&gt;,
  /// preserving null elements as Default(V).
  /// </summary>
  TListDeserializer<V> = record
    /// <summary>Reads array elements from AReader and adds them to AList.</summary>
    class procedure PopulateFromReader(const AReader: TJsonReader;
      const ASerializer: TJsonSerializer; AList: TList<V>); static;
  end;

  /// <summary>
  /// List converter that preserves JSON null array elements as default values of V.
  /// </summary>
  TPreserveNullOnReadJsonListConverter<V> = class(TJsonListConverter<V>)
  public
    /// <summary>
    /// Deserializes a JSON array into a TList&lt;V&gt;, keeping null elements as Default(V).
    /// </summary>
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
  end;

  /// <summary>
  /// JSON converter for TObjectList&lt;V&gt; that serializes and deserializes arrays of owned objects.
  /// </summary>
  TJsonObjectListConverter<V: class> = class(TJsonConverter)
  public
    /// <summary>
    /// Serializes a TObjectList&lt;V&gt; to a JSON array.
    /// </summary>
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
      const ASerializer: TJsonSerializer); override;
    /// <summary>
    /// Deserializes a JSON array into a TObjectList&lt;V&gt;.
    /// </summary>
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
    /// <summary>
    /// Returns True when ATypeInf matches TObjectList&lt;V&gt;.
    /// </summary>
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
  end;

  /// <summary>
  /// Object-list converter that preserves JSON null array elements as nil entries.
  /// </summary>
  TPreserveNullOnReadJsonObjectListConverter<V: class> = class(TJsonObjectListConverter<V>)
  public
    /// <summary>
    /// Deserializes a JSON array into a TObjectList&lt;V&gt;, keeping null elements as nil.
    /// </summary>
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
      const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
  end;

implementation

class procedure TListDeserializer<V>.PopulateFromReader(
  const AReader: TJsonReader; const ASerializer: TJsonSerializer;
  AList: TList<V>);
var
  LJV: TJSONValue;
  LItem: V;
begin
  while AReader.ReadNextArrayElement(LJV) do
  begin
    try
      if LJV.Null then
        LItem := Default(V)
      else
        LItem := ASerializer.Deserialize<V>(LJV.ToJSON);

      AList.Add(LItem);
    finally
      LJV.Free;
    end;
  end;
end;

{ TPreserveNullOnReadJsonListConverter<V> }

function TPreserveNullOnReadJsonListConverter<V>.ReadJson
  (const AReader: TJsonReader; ATypeInf: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  LList: TList<V>;
  LOwns: Boolean;
begin
  if AReader.TokenType = TJsonToken.Null then
    Result := nil
  else
  begin
    LOwns := AExistingValue.IsEmpty;
    if LOwns then
      LList := TList<V>.Create
    else
      LList := AExistingValue.AsType<TList<V>>;

    try
      TListDeserializer<V>.PopulateFromReader(AReader, ASerializer, LList);
      Result := TValue.From(LList);
    except
      if LOwns then
        LList.Free;
      raise;
    end;
  end;
end;

{ TJsonObjectListConverter<V> }

function TJsonObjectListConverter<V>.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := TJsonTypeUtils.InheritsFrom(ATypeInf, TObjectList<V>);
end;

function TJsonObjectListConverter<V>.ReadJson(const AReader: TJsonReader;
  ATypeInf: PTypeInfo; const AExistingValue: TValue;
  const ASerializer: TJsonSerializer): TValue;
var
  LList: TObjectList<V>;
  LOwns: Boolean;
  LArr: TArray<V>;
begin
  if AReader.TokenType = TJsonToken.Null then
    Result := nil
  else
  begin
    ASerializer.Populate(AReader, LArr);
    LOwns := AExistingValue.IsEmpty;
    if LOwns then
      LList := TObjectList<V>.Create(True)
    else
      LList := AExistingValue.AsType<TObjectList<V>>;
    try
      LList.AddRange(LArr);
      Result := TValue.From(LList);
    except
      if LOwns then
        LList.Free;
      raise;
    end;
  end;
end;

procedure TJsonObjectListConverter<V>.WriteJson(const AWriter: TJsonWriter;
  const AValue: TValue; const ASerializer: TJsonSerializer);
var
  LList: TObjectList<V>;
begin
  if AValue.TryAsType(LList) then
    ASerializer.Serialize(AWriter, LList.ToArray)
  else
    raise EJsonException.CreateFmt
      ('Type of Value "%s" does not match with the expected type: "%s"',
      [AValue.TypeInfo^.Name, TObjectList<V>.ClassName]);
end;

{ TPreserveNullOnReadJsonObjectListConverter<V> }

function TPreserveNullOnReadJsonObjectListConverter<V>.ReadJson
  (const AReader: TJsonReader; ATypeInf: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  LList: TObjectList<V>;
  LOwns: Boolean;
begin
  if AReader.TokenType = TJsonToken.Null then
    Result := nil
  else
  begin
    LOwns := AExistingValue.IsEmpty;
    if LOwns then
      LList := TObjectList<V>.Create(True)
    else
      LList := AExistingValue.AsType<TObjectList<V>>;

    try
      TListDeserializer<V>.PopulateFromReader(AReader, ASerializer, LList);
      Result := TValue.From(LList);
    except
      if LOwns then
        LList.Free;
      raise;
    end;
  end;
end;

end.
