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

unit SlpJsonHelpers;

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
  SlpStringTransformer,
  SlpJsonKit;

type
  { Class helper for TJSONValue }
  TJSONValueHelper = class helper for TJSONValue
  public
    { True iff Self is assigned and Self.ClassType = AClass (no inheritance). }
    function IsExactClass(AClass: TClass): Boolean; inline;

    { Convenience: mirrors TObject.InheritsFrom for readability at call sites. }
    function IsKindOfClass(AClass: TClass): Boolean; inline;

    /// Convert a RTL JSON DOM node into a TValue we store in Result.
    /// Primitives -> native TValue; objects/arrays -> cloned DOM as TObject.
    function ToTValue(): TValue;
  end;

type
  /// Adds value-capture helpers to TJsonReader
  TJsonReaderHelper = class helper for TJsonReader
  private
    procedure NextSkippingComments(var AR: TJsonReader);
  public
    /// Materialize the current JSON value (recursively) into a TJSONValue.
    /// Consumes the value; leaves the reader positioned at EndObject/EndArray
    /// or at the primitive token just read.
    function ReadJsonValue: TJSONValue;

    /// returns False (and V=nil) instead of raising on malformed/unsupported input.
    function TryReadJsonValue(out AValue: TJSONValue): Boolean;

    /// Reads the next element of the current array (assumes reader is at StartArray on first call,
    /// or positioned after a previous element). Returns False at EndArray. On True, Elem is assigned.
    function ReadNextArrayElement(out AElem: TJSONValue): Boolean;

    /// Convenience: materialize the current value as compact JSON text.
    function ToJson: string;

    /// Skip the current JSON value (recursively), without materializing a DOM.
    procedure SkipValue;
  end;

type
  /// Helper that writes RTL TJSONValue trees into a TJsonWriter
  /// while preserving numeric tokens (no unwanted quotes).
  TJsonWriterHelper = class helper for TJsonWriter
  public
    /// Write a JSON DOM node (TJSONValue) token-by-token.
    procedure WriteJsonValue(const AJV: TJSONValue);

    /// Convenience: write "Name": <value> where <value> is a TJSONValue.
    procedure WriteJsonProperty(const AName: string; const AJV: TJSONValue);
  end;

  TJsonNamingPolicyHelper = record helper for TJsonNamingPolicy
  public
    function GetFunc: TStringTransform;
  end;

implementation

{ TJSONValueHelper }

function TJSONValueHelper.IsExactClass(AClass: TClass): Boolean;
begin
  Result := Assigned(Self) and (Self.ClassType = AClass);
end;

function TJSONValueHelper.IsKindOfClass(AClass: TClass): Boolean;
begin
  Result := Assigned(Self) and Self.ClassType.InheritsFrom(AClass);
end;

function TJSONValueHelper.ToTValue(): TValue;
var
  LJNum: TJSONNumber;
  LJBoo: TJSONBool;
  LS: string;
  LI64: Int64;
  LD: Double;
  LV, LVClone: TJSONValue;
begin
  LV := Self;
  if LV = nil then
    Exit(TValue.Empty);

  if LV.IsExactClass(TJSONNull) then
    Exit(TValue.Empty);

  if LV.IsExactClass(TJSONNumber) then
  begin
    LJNum := TJSONNumber(LV);
    if TryStrToInt64(LJNum.Value, LI64) then
      Exit(TValue.From<Int64>(LI64))
    else
    begin
      LD := LJNum.AsDouble;
      Exit(TValue.From<Double>(LD));
    end;
  end;

  if LV.IsExactClass(TJSONString) then
  begin
    LS := TJSONString(LV).Value;
    Exit(TValue.From<string>(LS));
  end;

  if LV.IsKindOfClass(TJSONBool) then
  begin
    LJBoo := TJSONBool(LV);
    Exit(TValue.From<Boolean>(LJBoo.AsBoolean));
  end;

  // Objects/arrays -> keep a clone of the DOM node boxed in TValue
  LVClone := LV.Clone as TJSONValue;
  Result := TValue.From<TJSONValue>(LVClone);
end;

{ TJsonReaderHelper }

procedure TJsonReaderHelper.NextSkippingComments(var AR: TJsonReader);
begin
  repeat
    // Read only if we are not on the very first token of a value
    if (AR.TokenType = TJsonToken.Comment) then
      AR.Read
    else
      Break;
  until False;
end;

function TJsonReaderHelper.ReadJsonValue: TJSONValue;

  function ReadValue(var AR: TJsonReader): TJSONValue;
  var
    LObj: TJSONObject;
    LArr: TJSONArray;
    LName: string;
    LV: TJSONValue;
  begin

    // If we hit a comment at value position, advance past it
    if AR.TokenType = TJsonToken.Comment then
    begin
      AR.Read;
      Exit(ReadValue(AR));
    end;

    case AR.TokenType of
      TJsonToken.StartObject:
        begin
          LObj := TJSONObject.Create;
          try
            AR.Read; // first property / EndObject / Comment
            NextSkippingComments(AR); // skip comments before first property
            while AR.TokenType <> TJsonToken.EndObject do
            begin
              // comments between properties
              if AR.TokenType = TJsonToken.Comment then
              begin
                AR.Read;
                Continue;
              end;

              if AR.TokenType <> TJsonToken.PropertyName then
                raise EJsonException.Create('Expected property name');

              LName := AR.Value.AsString;
              AR.Read; // move to value
              LV := ReadValue(AR); // recurse value
              LObj.AddPair(LName, LV);

              AR.Read; // next property / EndObject / Comment
              NextSkippingComments(AR); // tolerate comments between properties
            end;
            Exit(LObj);
          except
            LObj.Free;
            raise;
          end;
        end;

      TJsonToken.StartArray:
        begin
          LArr := TJSONArray.Create;
          try
            AR.Read; // first element / EndArray / Comment
            NextSkippingComments(AR); // skip comments before first element
            while AR.TokenType <> TJsonToken.EndArray do
            begin
              // comments between elements
              if AR.TokenType = TJsonToken.Comment then
              begin
                AR.Read;
                Continue;
              end;

              LArr.AddElement(ReadValue(AR)); // recurse element

              AR.Read; // next element / EndArray / Comment
              NextSkippingComments(AR); // tolerate comments between elements
            end;
            Exit(LArr);
          except
            LArr.Free;
            raise;
          end;
        end;

      TJsonToken.&String:
        Exit(TJSONString.Create(AR.Value.AsString));

      // Use typed accessors for numerics (avoid invalid casts)
      TJsonToken.&Integer:
        Exit(TJSONNumber.Create(AR.Value.AsInt64));

      TJsonToken.Float:
        Exit(TJSONNumber.Create(Double(AR.Value.AsExtended)));

      TJsonToken.Boolean:
        if AR.Value.AsBoolean then
          Exit(TJSONTrue.Create)
        else
          Exit(TJSONFalse.Create);

      TJsonToken.Null, TJsonToken.Undefined:
        Exit(TJSONNull.Create);

      TJsonToken.PropertyName:
        // PropertyName is only valid inside an object; if we see it here,
        // the caller didn't structure the read loop correctly.
        raise EJsonException.Create
          ('Unexpected PropertyName at value position');

    else
      raise EJsonException.CreateFmt('Unsupported token %d',
        [Ord(AR.TokenType)]);
    end;
  end;

begin
  // If the current position is on a standalone comment before a value, skip it.
  if Self.TokenType = TJsonToken.Comment then
    Self.Read;
  Result := ReadValue(Self);
end;

function TJsonReaderHelper.TryReadJsonValue(out AValue: TJSONValue): Boolean;
begin
  try
    AValue := ReadJsonValue;
    Result := True;
  except
    AValue := nil;
    Result := False;
  end;
end;

function TJsonReaderHelper.ReadNextArrayElement(out AElem: TJSONValue): Boolean;
begin
  AElem := nil;

  // On first call, we may still be on StartArray: step in
  if Self.TokenType = TJsonToken.StartArray then
    Self.Read;

  // Skip comments between elements
  while Self.TokenType = TJsonToken.Comment do
    if not Self.Read then
      Exit(False);

  // End of array?
  if Self.TokenType = TJsonToken.EndArray then
  begin
    Result := False;
    Exit;
  end;

  // We should now be at the start of an element; materialize it
  AElem := Self.ReadJsonValue;
  if AElem = nil then
  begin
    // Defensive: treat nil as "no element" (e.g., if we were mis-positioned)
    Result := False;
    Exit;
  end;

  // Move past the element to the next token (comma/EndArray/comment)
  Self.Read;
  // Skip possible comments after the element
  while Self.TokenType = TJsonToken.Comment do
    if not Self.Read then
      Break;

  Result := True;
end;

function TJsonReaderHelper.ToJson: string;
var
  LV: TJSONValue;
begin
  LV := ReadJsonValue;
  try
    if Assigned(LV) then
      Result := LV.ToJson
    else
      Result := '';
  finally
    LV.Free;
  end;
end;

procedure TJsonReaderHelper.SkipValue;

  procedure SkipCurrent(var AR: TJsonReader);
  var
    LDepth: Integer;
  begin
    // Skip any leading comments
    NextSkippingComments(AR);

    case AR.TokenType of
      TJsonToken.StartObject, TJsonToken.StartArray:
        begin
          // Walk matching start/end tokens, tolerating comments anywhere.
          LDepth := 0;
          repeat
            if (AR.TokenType = TJsonToken.StartObject) or
              (AR.TokenType = TJsonToken.StartArray) then
              Inc(LDepth)
            else if (AR.TokenType = TJsonToken.EndObject) or
              (AR.TokenType = TJsonToken.EndArray) then
              Dec(LDepth);

            if LDepth = 0 then
              Break;

            AR.Read;
            if AR.TokenType = TJsonToken.Comment then
              NextSkippingComments(AR);
          until False;
        end;
      // primitives (string/number/bool/null) – nothing to do; they are a single token
    else
      // If we're on a comment or unexpected token, advance once
      if AR.TokenType = TJsonToken.Comment then
        NextSkippingComments(AR);
    end;
  end;

begin
  SkipCurrent(Self);
end;

{ TJsonWriterHelper }

procedure TJsonWriterHelper.WriteJsonValue(const AJV: TJSONValue);

  procedure WriteNumberLexeme(const AStr: string);
  var
    LI64: Int64;
    LF: Double;
    LFS: TFormatSettings;
  begin
    LFS := TFormatSettings.Create;
    LFS.DecimalSeparator := '.';
    if TryStrToInt64(AStr, LI64) then
      Self.WriteValue(LI64)
    else if TryStrToFloat(AStr, LF, LFS) then
      Self.WriteValue(LF)
    else
      // Extremely large integers that don't fit -> safest fallback as string
      Self.WriteValue(AStr);
  end;

var
  LPair: TJSONPair;
  LArr: TJSONArray;
  LI: Integer;
begin
  if AJV = nil then
  begin
    Self.WriteNull;
    Exit;
  end;

  if AJV.IsExactClass(TJSONObject) then
  begin
    Self.WriteStartObject;
    for LPair in TJSONObject(AJV) do
    begin
      Self.WritePropertyName(LPair.JsonString.Value);
      WriteJsonValue(LPair.JsonValue);
    end;
    Self.WriteEndObject;
    Exit;
  end;

  if AJV.IsExactClass(TJSONArray) then
  begin
    LArr := TJSONArray(AJV);
    Self.WriteStartArray;
    for LI := 0 to LArr.Count - 1 do
      WriteJsonValue(LArr.Items[LI]);
    Self.WriteEndArray;
    Exit;
  end;

  if AJV.IsExactClass(TJSONNumber) then
  begin
    WriteNumberLexeme(TJSONNumber(AJV).Value);
    Exit;
  end;

  if AJV.IsExactClass(TJSONString) then
  begin
    Self.WriteValue(TJSONString(AJV).Value);
    Exit;
  end;

  if AJV.IsExactClass(TJSONNull) then
  begin
    Self.WriteNull;
    Exit;
  end;

  if AJV.IsKindOfClass(TJSONBool) then
  begin
    Self.WriteValue(TJSONBool(AJV).AsBoolean);
    Exit;
  end;

  // Fallback: write as a string (shouldn't happen for standard RTL nodes)
  Self.WriteValue(AJV.ToJson);
end;

procedure TJsonWriterHelper.WriteJsonProperty(const AName: string;
  const AJV: TJSONValue);
begin
  Self.WritePropertyName(AName);
  Self.WriteJsonValue(AJV);
end;

{ TJsonNamingPolicyHelper }

function TJsonNamingPolicyHelper.GetFunc: TStringTransform;
begin
  case Self of
    TJsonNamingPolicy.CamelCase:  Result := TCamelCaseTransformProvider.GetTransform();
    TJsonNamingPolicy.PascalCase: Result := TPascalCaseTransformProvider.GetTransform();
    TJsonNamingPolicy.SnakeCase:  Result := TSnakeCaseTransformProvider.GetTransform();
    TJsonNamingPolicy.KebabCase:  Result := TKebabCaseTransformProvider.GetTransform();
  else
    Result := TIdentityTransformProvider.GetTransform();
  end;
end;

end.
