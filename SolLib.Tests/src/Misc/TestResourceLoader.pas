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

unit TestResourceLoader;

{$R '../Resources/TestResources.res'}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types;

type
  /// <summary>
  /// Utility class for loading test data from embedded resources.
  /// </summary>
  TTestResourceLoader = class
  private
    /// <summary>
    /// Converts a relative file path to a resource name.
    /// Example: 'JsonConverter/AccountInfo_Data_Base64.json' -> 'JSONCONVERTER_ACCOUNTINFO_DATA_BASE64_JSON'
    /// </summary>
    class function PathToResourceName(const APath: string): string; static;

    /// <summary>
    /// Loads raw bytes from a resource.
    /// </summary>
    class function LoadResourceBytes(const AResourceName: string): TBytes; static;

    /// <summary>
    /// Loads a resource as a string with the specified encoding.
    /// </summary>
    class function LoadResourceString(const AResourceName: string; const AEncoding: TEncoding): string; static;
  public
    /// <summary>
    /// Load a test resource by its relative path (e.g., 'JsonConverter/AccountInfo_Data_Base64.json').
    /// Automatically converts the path to the corresponding resource name.
    /// Uses UTF-8 encoding.
    /// </summary>
    class function LoadTestData(const ARelativePath: string): string; overload; static;

    /// <summary>
    /// Load a test resource by its relative path with a specific encoding.
    /// </summary>
    class function LoadTestData(const ARelativePath: string; const AEncoding: TEncoding): string; overload; static;

    /// <summary>
    /// Load a test resource by explicit resource name (e.g., 'JSONCONVERTER_ACCOUNTINFO_DATA_BASE64_JSON').
    /// Uses UTF-8 encoding.
    /// </summary>
    class function LoadByName(const AResourceName: string): string; overload; static;

    /// <summary>
    /// Load a test resource by explicit resource name with a specific encoding.
    /// </summary>
    class function LoadByName(const AResourceName: string; const AEncoding: TEncoding): string; overload; static;

    /// <summary>
    /// Load a test resource as raw bytes by its relative path.
    /// </summary>
    class function LoadTestDataBytes(const ARelativePath: string): TBytes; static;

    /// <summary>
    /// Check if a resource exists by its relative path.
    /// </summary>
    class function ResourceExists(const ARelativePath: string): Boolean; static;
  end;

implementation

{ TTestResourceLoader }

class function TTestResourceLoader.PathToResourceName(const APath: string): string;
begin
  // Convert: 'JsonConverter/AccountInfo_Data_Base64.json'
  // To:      'JSONCONVERTER_ACCOUNTINFO_DATA_BASE64_JSON'
  //
  // Convert: 'KeyStore/InvalidEmptyFile.txt'
  // To:      'KEYSTORE_INVALIDEMPTYFILE_TXT'
  Result := APath;
  Result := Result.Replace('/', '_', [rfReplaceAll]);
  Result := Result.Replace('\', '_', [rfReplaceAll]);
  Result := Result.Replace('.json', '_JSON', [rfIgnoreCase]);
  Result := Result.Replace('.txt', '_TXT', [rfIgnoreCase]);
  Result := Result.Replace('.', '_', [rfReplaceAll]);
  Result := Result.Replace('-', '_', [rfReplaceAll]);
  Result := Result.ToUpper;
end;

class function TTestResourceLoader.LoadResourceBytes(const AResourceName: string): TBytes;
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

class function TTestResourceLoader.LoadResourceString(const AResourceName: string;
  const AEncoding: TEncoding): string;
var
  Bytes: TBytes;
  BOMLength: Integer;
  Enc: TEncoding;
begin
  Result := '';
  Bytes := LoadResourceBytes(AResourceName);

  if Length(Bytes) > 0 then
  begin
    // Detect and skip BOM at byte level
    Enc := AEncoding;
    BOMLength := TEncoding.GetBufferEncoding(Bytes, Enc);

    // Convert bytes to string, skipping BOM
    Result := Enc.GetString(Bytes, BOMLength, Length(Bytes) - BOMLength);
  end;
end;

class function TTestResourceLoader.LoadTestData(const ARelativePath: string): string;
begin
  Result := LoadTestData(ARelativePath, TEncoding.UTF8);
end;

class function TTestResourceLoader.LoadTestData(const ARelativePath: string;
  const AEncoding: TEncoding): string;
begin
  Result := LoadResourceString(PathToResourceName(ARelativePath), AEncoding);
end;

class function TTestResourceLoader.LoadByName(const AResourceName: string): string;
begin
  Result := LoadByName(AResourceName, TEncoding.UTF8);
end;

class function TTestResourceLoader.LoadByName(const AResourceName: string;
  const AEncoding: TEncoding): string;
begin
  Result := LoadResourceString(AResourceName, AEncoding);
end;

class function TTestResourceLoader.LoadTestDataBytes(const ARelativePath: string): TBytes;
begin
  Result := LoadResourceBytes(PathToResourceName(ARelativePath));
end;

class function TTestResourceLoader.ResourceExists(const ARelativePath: string): Boolean;
var
  ResourceName: string;
begin
  ResourceName := PathToResourceName(ARelativePath);
  Result := FindResource(HInstance, PChar(ResourceName), RT_RCDATA) <> 0;
end;

end.
