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

unit SlpJsonHelpers;

{$I ..\Include\SolLib.inc}

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
    /// Primitives → native TValue; objects/arrays → cloned DOM as TObject.
    function ToTValue(): TValue;
  end;

type
  /// Adds value-capture helpers to TJsonReader
  TJsonReaderHelper = class helper for TJsonReader
  private
    procedure NextSkippingComments(var R: TJsonReader);
  public
    /// Materialize the current JSON value (recursively) into a TJSONValue.
    /// Consumes the value; leaves the reader positioned at EndObject/EndArray
    /// or at the primitive token just read.
    function ReadJsonValue: TJSONValue;

    /// returns False (and V=nil) instead of raising on malformed/unsupported input.
    function TryReadJsonValue(out V: TJSONValue): Boolean;

    /// Reads the next element of the current array (assumes reader is at StartArray on first call,
    /// or positioned after a previous element). Returns False at EndArray. On True, Elem is assigned.
    function ReadNextArrayElement(out Elem: TJSONValue): Boolean;

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
    procedure WriteJsonValue(const JV: TJSONValue);

    /// Convenience: write "Name": <value> where <value> is a TJSONValue.
    procedure WriteJsonProperty(const Name: string; const JV: TJSONValue);

    //function TryWriteTValue(const V: TValue): Boolean;
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
  JNum: TJSONNumber;
  JBoo: TJSONBool;
  S: string;
  I64: Int64;
  D: Double;
  V, VClone: TJSONValue;
begin
  V := Self;
  if V = nil then
    Exit(TValue.Empty);

  if V.IsExactClass(TJSONNull) then
    Exit(TValue.Empty);

  if V.IsExactClass(TJSONNumber) then
  begin
    JNum := TJSONNumber(V);
    if TryStrToInt64(JNum.Value, I64) then
      Exit(TValue.From<Int64>(I64))
    else
    begin
      D := JNum.AsDouble;
      Exit(TValue.From<Double>(D));
    end;
  end;

  if V.IsExactClass(TJSONString) then
  begin
    S := TJSONString(V).Value;
    Exit(TValue.From<string>(S));
  end;

  if V.IsKindOfClass(TJSONBool) then
  begin
    JBoo := TJSONBool(V);
    Exit(TValue.From<Boolean>(JBoo.AsBoolean));
  end;

  // Objects/arrays -> keep a clone of the DOM node boxed in TValue
  VClone := V.Clone as TJSONValue;
  Result := TValue.From<TJSONValue>(VClone);
end;

{ TJsonReaderHelper }

procedure TJsonReaderHelper.NextSkippingComments(var R: TJsonReader);
begin
  repeat
    // Read only if we are not on the very first token of a value
    if (R.TokenType = TJsonToken.Comment) then
      R.Read
    else
      Break;
  until False;
end;

function TJsonReaderHelper.ReadJsonValue: TJSONValue;

  function ReadValue(var R: TJsonReader): TJSONValue;
  var
    Obj: TJSONObject;
    Arr: TJSONArray;
    Name: string;
    V: TJSONValue;
  begin
    (* // tolerate being called on a PropertyName by jumping to its value
      if R.TokenType = TJsonToken.PropertyName then
      begin
      R.Read;                 // move to the property's value
      Exit(ReadValue(R));     // read that value
      end; *)

    // If we hit a comment at value position, advance past it
    if R.TokenType = TJsonToken.Comment then
    begin
      R.Read;
      Exit(ReadValue(R));
    end;

    case R.TokenType of
      TJsonToken.StartObject:
        begin
          Obj := TJSONObject.Create;
          try
            R.Read; // first property / EndObject / Comment
            NextSkippingComments(R); // skip comments before first property
            while R.TokenType <> TJsonToken.EndObject do
            begin
              // comments between properties
              if R.TokenType = TJsonToken.Comment then
              begin
                R.Read;
                Continue;
              end;

              if R.TokenType <> TJsonToken.PropertyName then
                raise EJsonException.Create('Expected property name');

              Name := R.Value.AsString;
              R.Read; // move to value
              V := ReadValue(R); // recurse value
              Obj.AddPair(Name, V);

              R.Read; // next property / EndObject / Comment
              NextSkippingComments(R); // tolerate comments between properties
            end;
            Exit(Obj);
          except
            Obj.Free;
            raise;
          end;
        end;

      TJsonToken.StartArray:
        begin
          Arr := TJSONArray.Create;
          try
            R.Read; // first element / EndArray / Comment
            NextSkippingComments(R); // skip comments before first element
            while R.TokenType <> TJsonToken.EndArray do
            begin
              // comments between elements
              if R.TokenType = TJsonToken.Comment then
              begin
                R.Read;
                Continue;
              end;

              Arr.AddElement(ReadValue(R)); // recurse element

              R.Read; // next element / EndArray / Comment
              NextSkippingComments(R); // tolerate comments between elements
            end;
            Exit(Arr);
          except
            Arr.Free;
            raise;
          end;
        end;

      TJsonToken.String:
        Exit(TJSONString.Create(R.Value.AsString));

      // Use typed accessors for numerics (avoid invalid casts)
      TJsonToken.Integer:
        Exit(TJSONNumber.Create(R.Value.AsInt64));

      TJsonToken.Float:
        Exit(TJSONNumber.Create(Double(R.Value.AsExtended)));

      TJsonToken.Boolean:
        if R.Value.AsBoolean then
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
        [Ord(R.TokenType)]);
    end;
  end;

begin
  // If the current position is on a standalone comment before a value, skip it.
  if Self.TokenType = TJsonToken.Comment then
    Self.Read;
  Result := ReadValue(Self);
end;

function TJsonReaderHelper.TryReadJsonValue(out V: TJSONValue): Boolean;
begin
  try
    V := ReadJsonValue;
    Result := True;
  except
    V := nil;
    Result := False;
  end;
end;

function TJsonReaderHelper.ReadNextArrayElement(out Elem: TJSONValue): Boolean;
begin
  Elem := nil;

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
  Elem := Self.ReadJsonValue; // your existing function
  if Elem = nil then
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
  V: TJSONValue;
begin
  V := ReadJsonValue;
  try
    if Assigned(V) then
      Result := V.ToJson
    else
      Result := '';
  finally
    V.Free;
  end;
end;

procedure TJsonReaderHelper.SkipValue;

  procedure SkipCurrent(var R: TJsonReader);
  var
    Depth: Integer;
  begin
    // Skip any leading comments
    NextSkippingComments(R);

    case R.TokenType of
      TJsonToken.StartObject, TJsonToken.StartArray:
        begin
          // Walk matching start/end tokens, tolerating comments anywhere.
          Depth := 0;
          repeat
            if (R.TokenType = TJsonToken.StartObject) or
              (R.TokenType = TJsonToken.StartArray) then
              Inc(Depth)
            else if (R.TokenType = TJsonToken.EndObject) or
              (R.TokenType = TJsonToken.EndArray) then
              Dec(Depth);

            if Depth = 0 then
              Break;

            R.Read;
            if R.TokenType = TJsonToken.Comment then
              NextSkippingComments(R);
          until False;
        end;
      // primitives (string/number/bool/null) – nothing to do; they are a single token
    else
      // If we're on a comment or unexpected token, advance once
      if R.TokenType = TJsonToken.Comment then
        NextSkippingComments(R);
    end;
  end;

begin
  SkipCurrent(Self);
end;

{ TJsonWriterHelper }

procedure TJsonWriterHelper.WriteJsonValue(const JV: TJSONValue);

  procedure WriteNumberLexeme(const S: string);
  var
    I64: Int64;
    F: Double;
    FS: TFormatSettings;
  begin
    FS := TFormatSettings.Create;
    FS.DecimalSeparator := '.';
    if TryStrToInt64(S, I64) then
      Self.WriteValue(I64)
    else if TryStrToFloat(S, F, FS) then
      Self.WriteValue(F)
    else
      // Extremely large integers that don't fit → safest fallback as string
      Self.WriteValue(S);
  end;

var
  Pair: TJSONPair;
  Arr: TJSONArray;
  I: Integer;
begin
  if JV = nil then
  begin
    Self.WriteNull;
    Exit;
  end;

  if JV.IsExactClass(TJSONObject) then
  begin
    Self.WriteStartObject;
    for Pair in TJSONObject(JV) do
    begin
      Self.WritePropertyName(Pair.JsonString.Value);
      WriteJsonValue(Pair.JsonValue);
    end;
    Self.WriteEndObject;
    Exit;
  end;

  if JV.IsExactClass(TJSONArray) then
  begin
    Arr := TJSONArray(JV);
    Self.WriteStartArray;
    for I := 0 to Arr.Count - 1 do
      WriteJsonValue(Arr.Items[I]);
    Self.WriteEndArray;
    Exit;
  end;

  if JV.IsExactClass(TJSONNumber) then
  begin
    WriteNumberLexeme(TJSONNumber(JV).Value);
    Exit;
  end;

  if JV.IsExactClass(TJSONString) then
  begin
    Self.WriteValue(TJSONString(JV).Value);
    Exit;
  end;

  if JV.IsExactClass(TJSONNull) then
  begin
    Self.WriteNull;
    Exit;
  end;

  if JV.IsKindOfClass(TJSONBool) then
  begin
    Self.WriteValue(TJSONBool(JV).AsBoolean);
    Exit;
  end;

  // Fallback: write as a string (shouldn't happen for standard RTL nodes)
  Self.WriteValue(JV.ToJson);
end;

procedure TJsonWriterHelper.WriteJsonProperty(const Name: string;
  const JV: TJSONValue);
begin
  Self.WritePropertyName(Name);
  Self.WriteJsonValue(JV);
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
