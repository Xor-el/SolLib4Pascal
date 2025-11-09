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

unit SlpIOUtils;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes;

type
  TIOUtils = class
  private
    class function NormalizePathDelimiters(const APath: string): string; static;
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

class function TIOUtils.NormalizePathDelimiters(const APath: string): string;
var
  I: Integer;
begin
  Result := APath;
  for I := 1 to Length(Result) do
    if (Result[I] = '\') or (Result[I] = '/') then
      Result[I] := PathDelim;

  // collapse duplicate delimiters
  while Pos(PathDelim + PathDelim, Result) > 0 do
    Result := StringReplace(Result, PathDelim + PathDelim, PathDelim, [rfReplaceAll]);
end;

class function TIOUtils.ReadAllText(const AFilePath: string): string;
begin
  Result := ReadAllText(AFilePath, TEncoding.UTF8);
end;

class function TIOUtils.ReadAllText(const AFilePath: string;
  const AEncoding: TEncoding): string;
var
  Reader: TStreamReader;
begin
  if not FileExists(AFilePath) then
    raise EFileNotFoundException.CreateFmt('File not found: %s', [AFilePath]);

  Reader := TStreamReader.Create(AFilePath, AEncoding, True);
  try
    Result := Reader.ReadToEnd;
  finally
    Reader.Free;
  end;
end;

class procedure TIOUtils.WriteAllBytes(const AFilePath: string;
  const AContent: TBytes);
var
  Stream: TFileStream;
begin
  ForceDirectories(ExtractFileDir(AFilePath)); // ensure target folder exists
  Stream := TFileStream.Create(AFilePath, fmCreate);
  try
    if Length(AContent) > 0 then
      Stream.WriteBuffer(AContent[0], Length(AContent));
  finally
    Stream.Free;
  end;
end;

class procedure TIOUtils.WriteAllText(const AFilePath: string;
  const AContent: string);
begin
  WriteAllText(AFilePath, AContent, TEncoding.UTF8);
end;

class procedure TIOUtils.WriteAllText(const AFilePath, AContent: string;
  const AEncoding: TEncoding);
var
  Stream: TFileStream;
  Writer: TStreamWriter;
begin
  Stream := TFileStream.Create(AFilePath, fmCreate or fmShareDenyWrite);
  try
    Writer := TStreamWriter.Create(Stream, AEncoding);
    try
      Writer.Write(AContent);
      Writer.Flush;
    finally
      Writer.Free;
    end;
  finally
    Stream.Free;
  end;
end;

class function TIOUtils.CombinePath(const A, B: string): string;
var
  LeftPart, RightPart: string;
begin
  LeftPart := NormalizePathDelimiters(A);
  RightPart := NormalizePathDelimiters(B);

  // If right side is absolute (like /usr/bin or C:\Tools), return it directly
  if ExtractFileDrive(RightPart) <> '' then
    Exit(RightPart)
  else if (Length(RightPart) > 0) and (RightPart[1] = PathDelim) then
    Exit(RightPart);

  if LeftPart = '' then
    Exit(RightPart)
  else if RightPart = '' then
    Exit(LeftPart);

  Result := IncludeTrailingPathDelimiter(LeftPart) + RightPart;
end;

class function TIOUtils.GetFullPath(const APath: string): string;
var
  CurrentDir: string;
begin
  if APath = '' then
    Exit('');

  // Use ExpandFileName for relative→absolute conversion
  if ExtractFileDrive(APath) <> '' then
    Result := ExpandFileName(APath)
  else
  begin
    CurrentDir := GetCurrentDir;
    Result := ExpandFileName(IncludeTrailingPathDelimiter(CurrentDir) + APath);
  end;

  Result := NormalizePathDelimiters(Result);
end;

end.
