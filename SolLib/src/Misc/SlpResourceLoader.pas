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

unit SlpResourceLoader;

{$I ../Include/SolLib.inc}

interface

uses
{$IFDEF USE_EMBEDDED_RESOURCES}
  System.Classes,
  System.Types,
{$ENDIF}
{$IFDEF USE_FILE_RESOURCES}
  System.IOUtils,
{$ENDIF}
  System.SysUtils;


type
  /// <summary>
  /// Cross-platform resource loader that supports embedded resources (desktop)
  /// and file-based assets (mobile iOS/Android).
  /// </summary>
  TSlpResourceLoader = class
  private
    /// <summary>
    /// Loads raw bytes from a resource.
    /// </summary>
    class function LoadBytes(const AResourceName: string): TBytes; static;

    /// <summary>
    /// Loads a resource as a string with the specified encoding, handling BOM.
    /// </summary>
    class function LoadString(const AResourceName: string; const AEncoding: TEncoding): string; static;

  {$IFDEF USE_FILE_RESOURCES}
    /// <summary>
    /// Gets the base path for asset files on mobile platforms.
    /// </summary>
    class function GetAssetBasePath: string; static;

    /// <summary>
    /// Gets the full file path for a resource on mobile platforms.
    /// </summary>
    class function GetAssetFilePath(const AResourceName: string): string; static;
  {$ENDIF}

  public
    /// <summary>
    /// Load a resource as a UTF-8 encoded string.
    /// </summary>
    class function LoadAsString(const AResourceName: string): string; overload; static;

    /// <summary>
    /// Load a resource as a string with a specific encoding.
    /// </summary>
    class function LoadAsString(const AResourceName: string; const AEncoding: TEncoding): string; overload; static;

    /// <summary>
    /// Load a resource as raw bytes.
    /// </summary>
    class function LoadAsBytes(const AResourceName: string): TBytes; static;

    /// <summary>
    /// Check if a resource exists.
    /// </summary>
    class function ResourceExists(const AResourceName: string): Boolean; static;
  end;

implementation

{ TSlpResourceLoader }

{$IFDEF USE_EMBEDDED_RESOURCES}
class function TSlpResourceLoader.LoadBytes(const AResourceName: string): TBytes;
var
  RS: TResourceStream;
begin
  RS := TResourceStream.Create(HInstance, AResourceName, RT_RCDATA);
  try
    SetLength(Result, RS.Size);
    if RS.Size > 0 then
      RS.ReadBuffer(Result[0], RS.Size);
  finally
    RS.Free;
  end;
end;

class function TSlpResourceLoader.ResourceExists(const AResourceName: string): Boolean;
var
  RS: TResourceStream;
begin
  try
    RS := TResourceStream.Create(HInstance, AResourceName, RT_RCDATA);
    try
      Result := True;
    finally
      RS.Free;
    end;
  except
    Result := False;
  end;
end;
{$ENDIF}

{$IFDEF USE_FILE_RESOURCES}
class function TSlpResourceLoader.GetAssetBasePath: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'SolLib');
end;

class function TSlpResourceLoader.GetAssetFilePath(const AResourceName: string): string;
begin
  Result := TPath.Combine(GetAssetBasePath, AResourceName);
end;

class function TSlpResourceLoader.LoadBytes(const AResourceName: string): TBytes;
var
  FilePath: string;
begin
  FilePath := GetAssetFilePath(AResourceName);
  Result := TFile.ReadAllBytes(FilePath);
end;

class function TSlpResourceLoader.ResourceExists(const AResourceName: string): Boolean;
var
  FilePath: string;
begin
  FilePath := GetAssetFilePath(AResourceName);
  Result := TFile.Exists(FilePath);
end;
{$ENDIF}

class function TSlpResourceLoader.LoadString(const AResourceName: string;
  const AEncoding: TEncoding): string;
var
  Bytes: TBytes;
  BOMLength: Integer;
  Enc: TEncoding;
begin
  Result := '';
  Bytes := LoadBytes(AResourceName);

  if Length(Bytes) > 0 then
  begin
    // Detect and skip BOM at byte level
    Enc := AEncoding;
    BOMLength := TEncoding.GetBufferEncoding(Bytes, Enc);

    // Convert bytes to string, skipping BOM
    Result := Enc.GetString(Bytes, BOMLength, Length(Bytes) - BOMLength);
  end;
end;

class function TSlpResourceLoader.LoadAsString(const AResourceName: string): string;
begin
  Result := LoadAsString(AResourceName, TEncoding.UTF8);
end;

class function TSlpResourceLoader.LoadAsString(const AResourceName: string;
  const AEncoding: TEncoding): string;
begin
  Result := LoadString(AResourceName, AEncoding);
end;

class function TSlpResourceLoader.LoadAsBytes(const AResourceName: string): TBytes;
begin
  Result := LoadBytes(AResourceName);
end;

end.

