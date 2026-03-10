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
  System.Character,
  System.SysUtils;

type
  TStringTransform = reference to function(const AStr: string): string;

  TStringTransformer = class sealed
    private
    class function SeparatedName(const AStr: string; const ASep: Char): string; static;
  public
    class function Identity: TStringTransform; static;
    class function Compose(const AFirst, ASecond: TStringTransform): TStringTransform; static;
    class function ComposeMany(const ASteps: array of TStringTransform): TStringTransform; static;

    class function ToCamel(const AStr: string): string; static;
    class function ToPascal(const AStr: string): string; static;
    class function ToSnake(const AStr: string): string; static;
    class function ToKebab(const AStr: string): string; static;
    class function MakeSeparatedNamer(const ASep: Char): TStringTransform; static;
    class function MakeAcronymNormalizer: TStringTransform; static;
  end;

  type
  /// Base provider. Subclass and override GetTransform to supply any TStringTransform.
  TStringTransformProvider = class abstract
  public
    class function GetTransform: TStringTransform; virtual; abstract;
  end;

  /// Class reference you can pass in attributes
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

{ TStringTransformer }

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
  // (AFirst ° ASecond)(AStr) = ASecond(AFirst(AStr)) — apply AFirst first, then ASecond
  Result :=
    function(const AStr: string): string
    begin
      Result := ASecond(AFirst(AStr));
    end;
end;

class function TStringTransformer.ComposeMany(const ASteps: array of TStringTransform): TStringTransform;
var
  LI: Integer;
begin
  // Left-to-right: (((Step0 ° Step1) ° Step2) ...)
  Result := Identity();
  for LI := Low(ASteps) to High(ASteps) do
    if Assigned(ASteps[LI]) then
      Result := Compose(Result, ASteps[LI]);
end;

class function TStringTransformer.ToCamel(const AStr: string): string;
begin
  Result := AStr;
  if Result <> '' then
    Result[1] := Result[1].ToLower;
end;

class function TStringTransformer.ToPascal(const AStr: string): string;
begin
  Result := AStr;
  if Result <> '' then
    Result[1] := Result[1].ToUpper;
end;

class function TStringTransformer.SeparatedName(const AStr: string; const ASep: Char): string;
var
  LI: Integer;
  LC: Char;
begin
  Result := '';
  for LI := 1 to Length(AStr) do
  begin
    LC := AStr[LI];
    if (LI > 1) and (LC.IsUpper) then
      Result := Result + ASep + LC.ToLower
    else
      Result := Result + LC.ToLower;
  end;
end;

class function TStringTransformer.ToSnake(const AStr: string): string;
begin
  Result := SeparatedName(AStr, '_');
end;

class function TStringTransformer.ToKebab(const AStr: string): string;
begin
  Result := SeparatedName(AStr, '-');
end;

class function TStringTransformer.MakeSeparatedNamer(const ASep: Char): TStringTransform;
begin
  Result :=
    function(const AStr: string): string
    begin
      Result := SeparatedName(AStr, ASep);
    end;
end;

class function TStringTransformer.MakeAcronymNormalizer: TStringTransform;
begin
  // Turns HTTPServerError -> HttpServerError; URLPath -> UrlPath; ID -> Id
  Result :=
    function(const AStr: string): string
    var
      LI, LLen, LRunStart, LRunLen: Integer;
      LNextIsLower: Boolean;
    begin
      Result := '';
      LLen := Length(AStr);
      LI := 1;
      while LI <= LLen do
      begin
        // detect an uppercase run
        if AStr[LI].IsUpper then
        begin
          LRunStart := LI;
          LRunLen := 1;
          while (LRunStart + LRunLen <= LLen) and AStr[LRunStart + LRunLen].IsUpper do
            Inc(LRunLen);

          if LRunLen >= 2 then
          begin
            // If the char *after* the run is lowercase, back off the last cap:
            // HTTPServer -> run=HTTP, leave 'S' to start next word
            LNextIsLower := (LRunStart + LRunLen <= LLen) and AStr[LRunStart + LRunLen].IsLower;
            if LNextIsLower then
              Dec(LRunLen);

            // emit normalized acronym: first upper + rest lower
            Result := Result + AStr[LRunStart] + LowerCase(Copy(AStr, LRunStart + 1, LRunLen - 1));
            Inc(LI, LRunLen);
            Continue;
          end;
          // runLen = 1 -> just fall through and copy as-is
        end;

        Result := Result + AStr[LI];
        Inc(LI);
      end;
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
  Result :=
    function(const AStr: string): string
    begin
      Result := TStringTransformer.ToCamel(AStr);
    end;
end;

{ TPascalCaseTransformProvider }

class function TPascalCaseTransformProvider.GetTransform: TStringTransform;
begin
  Result :=
    function(const AStr: string): string
    begin
      Result := TStringTransformer.ToPascal(AStr);
    end;
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

