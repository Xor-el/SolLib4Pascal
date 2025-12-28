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
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.Types;

type
  /// <summary>
  /// Interface for resource loading operations.
  /// </summary>
  ISlpResourceLoader = interface
    ['{B1C2D3E4-F5A6-7890-BCDE-F12345678901}']
    /// <summary>
    /// Load a resource as a UTF-8 encoded string.
    /// </summary>
    function LoadAsString(const AResourceName: string): string; overload;

    /// <summary>
    /// Load a resource as a string with a specific encoding.
    /// </summary>
    function LoadAsString(const AResourceName: string; const AEncoding: TEncoding): string; overload;

    /// <summary>
    /// Load a resource as raw bytes.
    /// </summary>
    function LoadAsBytes(const AResourceName: string): TBytes;

    /// <summary>
    /// Check if a resource exists.
    /// </summary>
    function ResourceExists(const AResourceName: string): Boolean;
  end;

  /// <summary>
  /// Interface for providing the base path for file-based resources.
  /// Implement this interface to customize where resources are loaded from.
  /// </summary>
  ISlpFileResourcePathProvider = interface
    ['{C2D3E4F5-A6B7-8901-CDEF-234567890ABC}']
    function GetAssetBasePath: string;
  end;

  /// <summary>
  /// Base class for resource loaders with common BOM handling logic.
  /// </summary>
  TBaseResourceLoader = class abstract(TInterfacedObject, ISlpResourceLoader)
  protected
    /// <summary>
    /// Load raw bytes from the resource. Must be implemented by subclasses.
    /// </summary>
    function DoLoadBytes(const AResourceName: string): TBytes; virtual; abstract;

    /// <summary>
    /// Check if the resource exists. Must be implemented by subclasses.
    /// </summary>
    function DoesResourceExists(const AResourceName: string): Boolean; virtual; abstract;

    /// <summary>
    /// Load string with BOM handling. Common implementation.
    /// </summary>
    function LoadString(const AResourceName: string; const AEncoding: TEncoding): string;
  public
    function LoadAsString(const AResourceName: string): string; overload;
    function LoadAsString(const AResourceName: string; const AEncoding: TEncoding): string; overload;
    function LoadAsBytes(const AResourceName: string): TBytes;
    function ResourceExists(const AResourceName: string): Boolean;
  end;

  /// <summary>
  /// Loads resources from embedded .res files (desktop platforms).
  /// </summary>
  TEmbeddedResourceLoader = class(TBaseResourceLoader)
  protected
    function DoLoadBytes(const AResourceName: string): TBytes; override;
    function DoesResourceExists(const AResourceName: string): Boolean; override;
  end;

  /// <summary>
  /// Default path provider that returns TPath.GetDocumentsPath/SolLib.
  /// </summary>
  TDefaultFileResourcePathProvider = class(TInterfacedObject, ISlpFileResourcePathProvider)
  public
    function GetAssetBasePath: string;
  end;

  /// <summary>
  /// Loads resources from file system (mobile platforms).
  /// </summary>
  TFileResourceLoader = class(TBaseResourceLoader)
  private
    FPathProvider: ISlpFileResourcePathProvider;
    function GetAssetBasePath: string;
    function GetAssetFilePath(const AResourceName: string): string;
  protected
    function DoLoadBytes(const AResourceName: string): TBytes; override;
    function DoesResourceExists(const AResourceName: string): Boolean; override;
  public
    constructor Create; overload;
    constructor Create(const APathProvider: ISlpFileResourcePathProvider); overload;
  end;

  /// <summary>
  /// Static accessor for the default resource loader instance.
  /// </summary>
  TSlpResourceLoader = class
  private
    class var FInstance: ISlpResourceLoader;
    class constructor Create;
  public
    /// <summary>
    /// The resource loader instance. Can be replaced with a custom implementation.
    /// </summary>
    class property Instance: ISlpResourceLoader read FInstance write FInstance;
  end;

// =============================================================================
// Example: Customizing the file asset base path
// =============================================================================
//
// To use a custom asset path on mobile platforms, create your own path provider
// and assign a new TFileResourceLoader instance:
//
//   type
//     TMyPathProvider = class(TInterfacedObject, ISlpResourcePathProvider)
//     public
//       function GetAssetBasePath: string;
//     end;
//
//   function TMyPathProvider.GetAssetBasePath: string;
//   begin
//     Result := TPath.Combine(TPath.GetDocumentsPath, TPath.Combine('MyApp', 'Assets'));
//   end;
//
//   // At application startup:
//   TSlpResourceLoader.Instance := TFileResourceLoader.Create(TMyPathProvider.Create as ISlpResourcePathProvider);
//
// =============================================================================

implementation

{ TBaseResourceLoader }

function TBaseResourceLoader.LoadString(const AResourceName: string;
  const AEncoding: TEncoding): string;
var
  Bytes: TBytes;
  BOMLength: Integer;
  Enc: TEncoding;
begin
  Result := '';
  Bytes := DoLoadBytes(AResourceName);

  if Length(Bytes) > 0 then
  begin
    Enc := AEncoding;
    BOMLength := TEncoding.GetBufferEncoding(Bytes, Enc);
    Result := Enc.GetString(Bytes, BOMLength, Length(Bytes) - BOMLength);
  end;
end;

function TBaseResourceLoader.LoadAsString(const AResourceName: string): string;
begin
  Result := LoadAsString(AResourceName, TEncoding.UTF8);
end;

function TBaseResourceLoader.LoadAsString(const AResourceName: string;
  const AEncoding: TEncoding): string;
begin
  Result := LoadString(AResourceName, AEncoding);
end;

function TBaseResourceLoader.LoadAsBytes(const AResourceName: string): TBytes;
begin
  Result := DoLoadBytes(AResourceName);
end;

function TBaseResourceLoader.ResourceExists(const AResourceName: string): Boolean;
begin
  Result := DoesResourceExists(AResourceName);
end;

{ TEmbeddedResourceLoader }

function TEmbeddedResourceLoader.DoLoadBytes(const AResourceName: string): TBytes;
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

function TEmbeddedResourceLoader.DoesResourceExists(const AResourceName: string): Boolean;
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

{ TDefaultFileResourcePathProvider }

function TDefaultFileResourcePathProvider.GetAssetBasePath: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'SolLib');
end;

{ TFileResourceLoader }

constructor TFileResourceLoader.Create;
begin
  inherited Create;
  FPathProvider := TDefaultFileResourcePathProvider.Create;
end;

constructor TFileResourceLoader.Create(const APathProvider: ISlpFileResourcePathProvider);
begin
  inherited Create;
  FPathProvider := APathProvider;
end;

function TFileResourceLoader.GetAssetBasePath: string;
begin
  Result := FPathProvider.GetAssetBasePath;
end;

function TFileResourceLoader.GetAssetFilePath(const AResourceName: string): string;
begin
  Result := TPath.Combine(GetAssetBasePath, AResourceName);
end;

function TFileResourceLoader.DoLoadBytes(const AResourceName: string): TBytes;
var
  FilePath: string;
begin
  FilePath := GetAssetFilePath(AResourceName);
  Result := TFile.ReadAllBytes(FilePath);
end;

function TFileResourceLoader.DoesResourceExists(const AResourceName: string): Boolean;
var
  FilePath: string;
begin
  FilePath := GetAssetFilePath(AResourceName);
  Result := TFile.Exists(FilePath);
end;

{ TSlpResourceLoader }

class constructor TSlpResourceLoader.Create;
begin
  {$IFDEF USE_EMBEDDED_RESOURCES}
  FInstance := TEmbeddedResourceLoader.Create;
  {$ENDIF}
  {$IFDEF USE_FILE_RESOURCES}
  FInstance := TFileResourceLoader.Create;
  {$ENDIF}
end;

end.

