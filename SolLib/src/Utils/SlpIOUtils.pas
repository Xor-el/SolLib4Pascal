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

unit SlpIOUtils;

{$I ../Include/SolLib.inc}

interface

uses
  System.IOUtils,
  System.SysUtils;

type
  TIOUtils = class
  public
    class function ReadAllText(const AFilePath: string): string; overload; static;
    class function ReadAllText(const AFilePath: string; const AEncoding: TEncoding): string; overload; static;

    class procedure WriteAllBytes(const AFilePath: string; const AContent: TBytes); static;

    class procedure WriteAllText(const AFilePath: string; const AContent: string); overload; static;
    class procedure WriteAllText(const AFilePath: string; const AContent: string; const AEncoding: TEncoding); overload; static;

    class function CombinePath(const A, B: string): string; static;
    class function GetFullPath(const APath: string): string; static;
  end;

implementation

{ TIOUtils }

class function TIOUtils.ReadAllText(const AFilePath: string): string;
begin
  Result := TFile.ReadAllText(AFilePath);
end;

class function TIOUtils.ReadAllText(const AFilePath: string;
  const AEncoding: TEncoding): string;
begin
  Result := TFile.ReadAllText(AFilePath, AEncoding);
end;

class procedure TIOUtils.WriteAllBytes(const AFilePath: string;
  const AContent: TBytes);
begin
  TFile.WriteAllBytes(AFilePath, AContent);
end;

class procedure TIOUtils.WriteAllText(const AFilePath: string;
  const AContent: string);
begin
  TFile.WriteAllText(AFilePath, AContent);
end;

class procedure TIOUtils.WriteAllText(const AFilePath, AContent: string;
  const AEncoding: TEncoding);
begin
  TFile.WriteAllText(AFilePath, AContent, AEncoding);
end;

class function TIOUtils.CombinePath(const A, B: string): string;
begin
  Result := TPath.Combine(A, B);
end;

class function TIOUtils.GetFullPath(const APath: string): string;
begin
  Result := TPath.GetFullPath(APath);
end;

end.
