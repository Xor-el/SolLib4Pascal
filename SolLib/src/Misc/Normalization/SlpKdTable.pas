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
  SysUtils,
  SlpResourceLoader,
  SlpSolLibExceptions;

type
  TRange = record
    Lo, Hi: Integer;
  end;

  TKdTable = class
  private
    class var FSubstitutionTable: string;

    class function Supported(const ACh: Char): Boolean; static;
    class procedure Substitute(ACh: Char; ASB: TStringBuilder); overload; static;
    class procedure Substitute(APos: Integer; ASB: TStringBuilder); overload; static;

    class constructor Create();
  public
    class function NormalizeKd(const AStr: string): string; static;
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

class function TKdTable.NormalizeKd(const AStr: string): string;
var
  LSB: TStringBuilder;
  LI, LN: Integer;
  LCh: Char;
begin
  LSB := TStringBuilder.Create(Length(AStr));
  try
    LN := Length(AStr);
    for LI := 1 to LN do
    begin
      LCh := AStr[LI];
      if not Supported(LCh) then
        raise EKdfNormalizationNotSupported.Create('the input string can''t be normalized on this platform');
      Substitute(LCh, LSB);
    end;
    Result := LSB.ToString;
  finally
    LSB.Free;
  end;
end;

class function TKdTable.Supported(const ACh: Char): Boolean;
var
  LI: Integer;
  LCode: Integer;
begin
  LCode := Ord(ACh);
  for LI := Low(SupportedChars) to High(SupportedChars) do
    if (LCode >= SupportedChars[LI].Lo) and (LCode <= SupportedChars[LI].Hi) then
      Exit(True);
  Result := False;
end;

class procedure TKdTable.Substitute(ACh: Char; ASB: TStringBuilder);
var
  LI, LLen: Integer;
  LSubstitutedChar: Char;
begin
  LLen := Length(FSubstitutionTable);
  LI := 1;
  while LI <= LLen do
  begin
    LSubstitutedChar := FSubstitutionTable[LI];
    if LSubstitutedChar = ACh then
    begin
      Substitute(LI, ASB);
      Exit;
    end;
    if LSubstitutedChar > ACh then
      Break;

    while (LI <= LLen) and (FSubstitutionTable[LI] <> #10) do
      Inc(LI);
    Inc(LI);
  end;
  ASB.Append(ACh);
end;

class procedure TKdTable.Substitute(APos: Integer; ASB: TStringBuilder);
var
  LI, LLen: Integer;
begin
  LLen := Length(FSubstitutionTable);
  LI := APos + 1;
  while (LI <= LLen) and (FSubstitutionTable[LI] <> #10) do
  begin
    ASB.Append(FSubstitutionTable[LI]);
    Inc(LI);
  end;
end;

end.

