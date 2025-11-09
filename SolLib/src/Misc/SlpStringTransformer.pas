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

unit SlpStringTransformer;

{$I ..\Include\SolLib.inc}

interface

uses
  System.Character,
  System.SysUtils;

type
  TStringTransform = reference to function(const S: string): string;

  TStringTransformer = class sealed
    private
    class function SeparatedName(const S: string; const Sep: Char): string; static;
  public
    class function Identity: TStringTransform; static;
    class function Compose(const A, B: TStringTransform): TStringTransform; static;
    class function ComposeMany(const Steps: array of TStringTransform): TStringTransform; static;

    class function ToCamel(const S: string): string; static;
    class function ToPascal(const S: string): string; static;
    class function ToSnake(const S: string): string; static;
    class function ToKebab(const S: string): string; static;
    class function MakeSeparatedNamer(const Sep: Char): TStringTransform; static;
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
    function(const S: string): string
    begin
      Result := S;
    end;
end;

class function TStringTransformer.Compose(const A, B: TStringTransform): TStringTransform;
begin
  // (A ∘ B)(S) = B(A(S)) — apply A first, then B
  Result :=
    function(const S: string): string
    begin
      Result := B(A(S));
    end;
end;

class function TStringTransformer.ComposeMany(const Steps: array of TStringTransform): TStringTransform;
var
  I: Integer;
begin
  // Left-to-right: (((Step0 ∘ Step1) ∘ Step2) ...)
  Result := Identity();
  for I := Low(Steps) to High(Steps) do
    if Assigned(Steps[I]) then
      Result := Compose(Result, Steps[I]);
end;

class function TStringTransformer.ToCamel(const S: string): string;
begin
  Result := S;
  if Result <> '' then
    Result[1] := Result[1].ToLower;
end;

class function TStringTransformer.ToPascal(const S: string): string;
begin
  Result := S;
  if Result <> '' then
    Result[1] := Result[1].ToUpper;
end;

class function TStringTransformer.SeparatedName(const S: string; const Sep: Char): string;
var
  I: Integer;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    if (I > 1) and (C.IsUpper) then
      Result := Result + Sep + C.ToLower
    else
      Result := Result + C.ToLower;
  end;
end;

class function TStringTransformer.ToSnake(const S: string): string;
begin
  Result := SeparatedName(S, '_');
end;

class function TStringTransformer.ToKebab(const S: string): string;
begin
  Result := SeparatedName(S, '-');
end;

class function TStringTransformer.MakeSeparatedNamer(const Sep: Char): TStringTransform;
begin
  Result :=
    function(const S: string): string
    begin
      Result := SeparatedName(S, Sep);
    end;
end;

class function TStringTransformer.MakeAcronymNormalizer: TStringTransform;
begin
  // Turns HTTPServerError -> HttpServerError; URLPath -> UrlPath; ID -> Id
  Result :=
    function(const S: string): string
    var
      i, L, runStart, runLen: Integer;
      nextIsLower: Boolean;
    begin
      Result := '';
      L := Length(S);
      i := 1;
      while i <= L do
      begin
        // detect an uppercase run
        if S[i].IsUpper then
        begin
          runStart := i;
          runLen := 1;
          while (runStart + runLen <= L) and S[runStart + runLen].IsUpper do
            Inc(runLen);

          if runLen >= 2 then
          begin
            // If the char *after* the run is lowercase, back off the last cap:
            // HTTPServer -> run=HTTP, leave 'S' to start next word
            nextIsLower := (runStart + runLen <= L) and S[runStart + runLen].IsLower;
            if nextIsLower then
              Dec(runLen);

            // emit normalized acronym: first upper + rest lower
            Result := Result + S[runStart] + LowerCase(Copy(S, runStart + 1, runLen - 1));
            Inc(i, runLen);
            Continue;
          end;
          // runLen = 1 → just fall through and copy as-is
        end;

        Result := Result + S[i];
        Inc(i);
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
    function(const S: string): string
    begin
      Result := TStringTransformer.ToCamel(S);
    end;
end;

{ TPascalCaseTransformProvider }

class function TPascalCaseTransformProvider.GetTransform: TStringTransform;
begin
  Result :=
    function(const S: string): string
    begin
      Result := TStringTransformer.ToPascal(S);
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

