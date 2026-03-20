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

unit SlpIOUtilities;

{$I ../Include/SolLib.inc}

interface

uses
  System.IOUtils,
  System.SysUtils;

type
  TIOUtilities = class
  public
    class function ReadAllText(const AFilePath: string): string; overload; static;
    class function ReadAllText(const AFilePath: string; const AEncoding: TEncoding): string; overload; static;

    class procedure WriteAllBytes(const AFilePath: string; const AContent: TBytes); static;

    class procedure WriteAllText(const AFilePath: string; const AContent: string); overload; static;
    class procedure WriteAllText(const AFilePath: string; const AContent: string; const AEncoding: TEncoding); overload; static;

    class function CombinePath(const AFirstPath, ASecondPath: string): string; static;
    class function GetFullPath(const APath: string): string; static;
  end;

implementation

{ TIOUtilities }

class function TIOUtilities.ReadAllText(const AFilePath: string): string;
begin
  Result := TFile.ReadAllText(AFilePath);
end;

class function TIOUtilities.ReadAllText(const AFilePath: string;
  const AEncoding: TEncoding): string;
begin
  Result := TFile.ReadAllText(AFilePath, AEncoding);
end;

class procedure TIOUtilities.WriteAllBytes(const AFilePath: string;
  const AContent: TBytes);
begin
  TFile.WriteAllBytes(AFilePath, AContent);
end;

class procedure TIOUtilities.WriteAllText(const AFilePath: string;
  const AContent: string);
begin
  TFile.WriteAllText(AFilePath, AContent);
end;

class procedure TIOUtilities.WriteAllText(const AFilePath, AContent: string;
  const AEncoding: TEncoding);
begin
  TFile.WriteAllText(AFilePath, AContent, AEncoding);
end;

class function TIOUtilities.CombinePath(const AFirstPath, ASecondPath: string): string;
begin
  Result := TPath.Combine(AFirstPath, ASecondPath);
end;

class function TIOUtilities.GetFullPath(const APath: string): string;
begin
  Result := TPath.GetFullPath(APath);
end;

end.
