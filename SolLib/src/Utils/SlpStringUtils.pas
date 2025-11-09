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

unit SlpStringUtils;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Character,
  System.Generics.Collections;

type
  TStringUtils = class sealed
  public
    /// <summary>Split on any Unicode whitespace (like C# Split(null, RemoveEmptyEntries)).</summary>
    class function SplitOnWhitespace(const S: string): TArray<string>; static;

    /// <summary>Unescape simple C-style sequences: \n, \r, \t, \\, \", \0.</summary>
    class function UnEscapeCStyle(const S: string): string; static;
  end;

implementation

{ TStringUtils }

class function TStringUtils.SplitOnWhitespace(const S: string): TArray<string>;
var
  n, i, startIdx: Integer;
  parts: TList<string>;
begin
  parts := TList<string>.Create;
  try
    n := Length(S);
    if n = 0 then
    begin
      SetLength(Result, 0);
      Exit; // empty input => empty result
    end;

    // 1-based scan; Copy for substrings.
    startIdx := 1; // current token start (1-based)
    i := 1;
    while i <= n do
    begin
      if S[i].IsWhiteSpace() then
      begin
        // add token if there is a non-empty span [startIdx .. i-1]
        if i > startIdx then
          parts.Add(Copy(S, startIdx, i - startIdx));

        // skip the whole whitespace run
        Inc(i);
        while (i <= n) and S[i].IsWhiteSpace() do
          Inc(i);

        startIdx := i;
        Continue;
      end;
      Inc(i);
    end;

    // tail token (if any): [startIdx .. n]
    if startIdx <= n then
      parts.Add(Copy(S, startIdx, n - startIdx + 1));

    Result := parts.ToArray;
  finally
    parts.Free;
  end;
end;

class function TStringUtils.UnEscapeCStyle(const S: string): string;
var
  I, L: Integer;
  C: Char;
begin
  Result := '';
  L := Length(S);
  I := 1;
  while I <= L do
  begin
    C := S[I];
    if (C = '\') and (I < L) then
    begin
      Inc(I);
      case S[I] of
        'n':  Result := Result + #10;  // newline
        'r':  Result := Result + #13;  // carriage return
        't':  Result := Result + #9;   // tab
        '\':  Result := Result + '\';  // backslash
        '"':  Result := Result + '"';  // quote
        '0':  Result := Result + #0;   // null
      else
        // Unknown escape: keep as-is (backslash + char)
        Result := Result + '\' + S[I];
      end;
    end
    else
      Result := Result + C;
    Inc(I);
  end;
end;

end.

