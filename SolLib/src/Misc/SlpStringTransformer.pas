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

unit SlpStringTransformer;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils;

type
  TStringTransform = reference to function(const AInput: string): string;

  TStringTransformer = class sealed
  private
    class function IsAsciiUpper(ACh: Char): Boolean; static; inline;
    class function IsAsciiLower(ACh: Char): Boolean; static; inline;
    class function ToAsciiUpper(ACh: Char): Char; static; inline;
    class function ToAsciiLower(ACh: Char): Char; static; inline;
    class function SeparatedName(const AInput: string; ASeparator: Char): string; static;
  public
    class function Identity: TStringTransform; static;
    class function Compose(const AFirst, ASecond: TStringTransform): TStringTransform; static;
    class function ComposeMany(const ASteps: array of TStringTransform): TStringTransform; static;

    class function ToCamel(const AInput: string): string; static;
    class function ToPascal(const AInput: string): string; static;
    class function ToSnake(const AInput: string): string; static;
    class function ToKebab(const AInput: string): string; static;
    class function NormalizeAcronyms(const AInput: string): string; static;

    class function MakeSeparatedNamer(ASeparator: Char): TStringTransform; static;
    class function MakeAcronymNormalizer: TStringTransform; static;
  end;

  /// <summary>
  /// Base provider. Subclass and override GetTransform to supply any TStringTransform.
  /// </summary>
  TStringTransformProvider = class abstract
  public
    class function GetTransform: TStringTransform; virtual; abstract;
  end;

  /// <summary>Class reference for use in attributes or factory patterns.</summary>
  TStringTransformProviderClass = class of TStringTransformProvider;

  TIdentityTransformProvider = class(TStringTransformProvider)
  public
    class function GetTransform: TStringTransform; override;
  end;

  TCamelCaseTransformProvider = class(TStringTransformProvider)
  public
    class function GetTransform: TStringTransform; override;
  end;

  TPascalCaseTransformProvider = class(TStringTransformProvider)
  public
    class function GetTransform: TStringTransform; override;
  end;

  TSnakeCaseTransformProvider = class(TStringTransformProvider)
  public
    class function GetTransform: TStringTransform; override;
  end;

  TKebabCaseTransformProvider = class(TStringTransformProvider)
  public
    class function GetTransform: TStringTransform; override;
  end;

  TAcronymNormalizerTransformProvider = class(TStringTransformProvider)
  public
    class function GetTransform: TStringTransform; override;
  end;

implementation

{ TStringTransformer - ASCII helpers }

class function TStringTransformer.IsAsciiUpper(ACh: Char): Boolean;
begin
  Result := (ACh >= 'A') and (ACh <= 'Z');
end;

class function TStringTransformer.IsAsciiLower(ACh: Char): Boolean;
begin
  Result := (ACh >= 'a') and (ACh <= 'z');
end;

class function TStringTransformer.ToAsciiUpper(ACh: Char): Char;
begin
  if (ACh >= 'a') and (ACh <= 'z') then
    Result := Char(Ord(ACh) - 32)
  else
    Result := ACh;
end;

class function TStringTransformer.ToAsciiLower(ACh: Char): Char;
begin
  if (ACh >= 'A') and (ACh <= 'Z') then
    Result := Char(Ord(ACh) + 32)
  else
    Result := ACh;
end;

{ TStringTransformer - Core transforms }

class function TStringTransformer.Identity: TStringTransform;
begin
  Result :=
    function(const AStr: string): string
    begin
      Result := AStr;
    end;
end;

class function TStringTransformer.Compose(const AFirst, ASecond: TStringTransform): TStringTransform;
begin
  Result :=
    function(const AStr: string): string
    begin
      Result := ASecond(AFirst(AStr));
    end;
end;

class function TStringTransformer.ComposeMany(const ASteps: array of TStringTransform): TStringTransform;
var
  LCaptured: TArray<TStringTransform>;
  LI, LCount: Integer;
begin
  // Capture only assigned steps into a owned array to avoid
  // N intermediate closure allocations from repeated Compose calls.
  LCount := 0;
  SetLength(LCaptured, Length(ASteps));
  for LI := Low(ASteps) to High(ASteps) do
    if Assigned(ASteps[LI]) then
    begin
      LCaptured[LCount] := ASteps[LI];
      Inc(LCount);
    end;
  SetLength(LCaptured, LCount);

  if LCount = 0 then
    Exit(Identity());
  if LCount = 1 then
    Exit(LCaptured[0]);

  Result :=
    function(const AInput: string): string
    var
      LJ: Integer;
    begin
      Result := AInput;
      for LJ := 0 to High(LCaptured) do
        Result := LCaptured[LJ](Result);
    end;
end;

class function TStringTransformer.ToCamel(const AInput: string): string;
begin
  Result := AInput;
  if Result <> '' then
    Result[1] := ToAsciiLower(Result[1]);
end;

class function TStringTransformer.ToPascal(const AInput: string): string;
begin
  Result := AInput;
  if Result <> '' then
    Result[1] := ToAsciiUpper(Result[1]);
end;

class function TStringTransformer.SeparatedName(const AInput: string; ASeparator: Char): string;
var
  LI, LLen: Integer;
  LC: Char;
  LPrevUpper, LNextLower: Boolean;
  LBuilder: TStringBuilder;
begin
  LLen := Length(AInput);
  if LLen = 0 then
    Exit('');

  LBuilder := TStringBuilder.Create(LLen + (LLen div 4));
  try
    for LI := 1 to LLen do
    begin
      LC := AInput[LI];
      if (LI > 1) and IsAsciiUpper(LC) then
      begin
        LPrevUpper := IsAsciiUpper(AInput[LI - 1]);
        LNextLower := (LI < LLen) and IsAsciiLower(AInput[LI + 1]);
        // Insert separator at camelCase boundary (lower->Upper)
        // or at acronym-to-word boundary (Upper before UpperLower, e.g. HTTPServer -> HTTP_Server)
        if (not LPrevUpper) or LNextLower then
          LBuilder.Append(ASeparator);
      end;
      LBuilder.Append(ToAsciiLower(LC));
    end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

class function TStringTransformer.ToSnake(const AInput: string): string;
begin
  Result := SeparatedName(AInput, '_');
end;

class function TStringTransformer.ToKebab(const AInput: string): string;
begin
  Result := SeparatedName(AInput, '-');
end;

class function TStringTransformer.NormalizeAcronyms(const AInput: string): string;
var
  LI, LLen, LRunStart, LRunLen: Integer;
  LBuilder: TStringBuilder;
begin
  LLen := Length(AInput);
  if LLen = 0 then
    Exit('');
  LBuilder := TStringBuilder.Create(LLen);
  try
    LI := 1;
    while LI <= LLen do
    begin
      if IsAsciiUpper(AInput[LI]) then
      begin
        // Measure the uppercase run
        LRunStart := LI;
        LRunLen := 1;
        while (LRunStart + LRunLen <= LLen) and IsAsciiUpper(AInput[LRunStart + LRunLen]) do
          Inc(LRunLen);

        if LRunLen >= 2 then
        begin
          // If the char after the run is lowercase, back off one so it starts
          // the next word: HTTPServer -> Http + Server, not Httpserver
          if (LRunStart + LRunLen <= LLen) and IsAsciiLower(AInput[LRunStart + LRunLen]) then
            Dec(LRunLen);

          // Emit normalized acronym: first upper + rest lower
          LBuilder.Append(AInput[LRunStart]);
          while LRunLen > 1 do
          begin
            Inc(LRunStart);
            Dec(LRunLen);
            LBuilder.Append(ToAsciiLower(AInput[LRunStart]));
          end;
          LI := LRunStart + 1;
          Continue;
        end;
        // RunLen = 1: single uppercase char, fall through
      end;
      LBuilder.Append(AInput[LI]);
      Inc(LI);
    end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

class function TStringTransformer.MakeSeparatedNamer(ASeparator: Char): TStringTransform;
begin
  Result :=
    function(const AStr: string): string
    begin
      Result := SeparatedName(AStr, ASeparator);
    end;
end;

class function TStringTransformer.MakeAcronymNormalizer: TStringTransform;
begin
  Result :=
    function(const AStr: string): string
    begin
      Result := NormalizeAcronyms(AStr);
    end;
end;

{ TIdentityTransformProvider }

class function TIdentityTransformProvider.GetTransform: TStringTransform;
begin
  Result := TStringTransformer.Identity();
end;

{ TCamelCaseTransformProvider }

class function TCamelCaseTransformProvider.GetTransform: TStringTransform;
begin
  Result := TStringTransformer.ToCamel;
end;

{ TPascalCaseTransformProvider }

class function TPascalCaseTransformProvider.GetTransform: TStringTransform;
begin
  Result := TStringTransformer.ToPascal;
end;

{ TSnakeCaseTransformProvider }

class function TSnakeCaseTransformProvider.GetTransform: TStringTransform;
begin
  Result := TStringTransformer.MakeSeparatedNamer('_');
end;

{ TKebabCaseTransformProvider }

class function TKebabCaseTransformProvider.GetTransform: TStringTransform;
begin
  Result := TStringTransformer.MakeSeparatedNamer('-');
end;

{ TAcronymNormalizerTransformProvider }

class function TAcronymNormalizerTransformProvider.GetTransform: TStringTransform;
begin
  Result := TStringTransformer.MakeAcronymNormalizer();
end;

end.
