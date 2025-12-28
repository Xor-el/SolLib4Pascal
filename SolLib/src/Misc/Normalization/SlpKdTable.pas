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

unit SlpKdTable;

{$I ../../Include/SolLib.inc}

{$IFDEF USE_EMBEDDED_RESOURCES}
{$R '../../Resources/Normalization.res'}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  SlpResourceLoader,
  SlpSolLibExceptions;

type
  TRange = record
    Lo, Hi: Integer;
  end;

  TKdTable = class
  private
    class var FSubstitutionTable: string;

    class function Supported(const Ch: Char): Boolean; static;
    class procedure Substitute(Ch: Char; SB: TStringBuilder); overload; static;
    class procedure Substitute(Pos: Integer; SB: TStringBuilder); overload; static;

    class constructor Create();
  public
    class function NormalizeKd(const S: string): string; static;
  end;

const
  SupportedChars: array[0..12] of TRange = (
  (Lo: 0; Hi: 1000),
  (Lo: 12352; Hi: 12447),
  (Lo: 12448; Hi: 12543),
  (Lo: 19968; Hi: 40959),
  (Lo: 13312; Hi: 19967),
  (Lo: 131072; Hi: 173791),
  (Lo: 63744; Hi: 64255),
  (Lo: 194560; Hi: 195103),
  (Lo: 13056; Hi: 13311),
  (Lo: 12288; Hi: 12351),
  (Lo: 65280; Hi: 65535),
  (Lo: 8192; Hi: 8303),
  (Lo: 8352; Hi: 8399)
  );

implementation

{ TKdTable }

class constructor TKdTable.Create;
begin
  FSubstitutionTable := TSlpResourceLoader.Instance.LoadAsString('KD_SUBSTITUTION_TABLE', TEncoding.UTF8);
end;

class function TKdTable.NormalizeKd(const S: string): string;
var
  SB: TStringBuilder;
  i, n: Integer;
  ch: Char;
begin
  SB := TStringBuilder.Create(Length(S));
  try
    n := Length(S);
    for i := 1 to n do
    begin
      ch := S[i];
      if not Supported(ch) then
        raise EKdNormalizationNotSupported.Create('the input string can''t be normalized on this platform');
      Substitute(ch, SB);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

class function TKdTable.Supported(const Ch: Char): Boolean;
var
  i: Integer;
  code: Integer;
begin
  code := Ord(Ch);
  for i := Low(SupportedChars) to High(SupportedChars) do
    if (code >= SupportedChars[i].Lo) and (code <= SupportedChars[i].Hi) then
      Exit(True);
  Result := False;
end;

class procedure TKdTable.Substitute(Ch: Char; SB: TStringBuilder);
var
  i, L: Integer;
  substitutedChar: Char;
begin
  L := Length(FSubstitutionTable);
  i := 1;
  while i <= L do
  begin
    substitutedChar := FSubstitutionTable[i];
    if substitutedChar = Ch then
    begin
      Substitute(i, SB);
      Exit;
    end;
    if substitutedChar > Ch then
      Break;

    while (i <= L) and (FSubstitutionTable[i] <> #10) do
      Inc(i);
    Inc(i);
  end;
  SB.Append(Ch);
end;

class procedure TKdTable.Substitute(Pos: Integer; SB: TStringBuilder);
var
  i, L: Integer;
begin
  L := Length(FSubstitutionTable);
  i := Pos + 1;
  while (i <= L) and (FSubstitutionTable[i] <> #10) do
  begin
    SB.Append(FSubstitutionTable[i]);
    Inc(i);
  end;
end;

end.

