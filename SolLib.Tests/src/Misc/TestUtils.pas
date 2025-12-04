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

unit TestUtils;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.JSON.Serializers,
  SlpJsonKit,
  SlpJsonStringEnumConverter,
  SlpEncodingConverter,
  SlpJsonConverterFactory,
  SlpIOUtils;

type
  /// Minimal, test helpers.
  TTestUtils = class
  private
    class var FTestSourceRoot: string; // optional explicit override
    class var FSerializer: TJsonSerializer;

    /// Resolve a base dir using either FTestSourceRoot or a climb for Marker(s).
    class function GetSourceDir(
      const Marker: string
    ): string; static;

    /// Executable directory (trailing slash).
    class function ExecutableDir: string; static;

    /// Climb up from StartDir to find any of the Targets (file or directory).
    class function LocateUpwards(
      const StartDir: string;
      const Targets: array of string;
      out FoundAncestorDir, FoundFullPath: string
    ): Boolean; overload; static;
    class function BuildSerializer: TJsonSerializer; static;

  public
    /// Set once (e.g., in test init) to pin the repo/test root explicitly.
    class procedure SetTestSourceRoot(const Dir: string); static;

    /// Same as GetSourceDir, then appends Suffix (if provided).
    class function GetSourceDirWithSuffix(
      const Marker: string;
      const Suffix: string
    ): string; static;

    class function CombineAll(const Parts: array of string;
      const IncludeTrailingDelimiter: Boolean = False): string; static;

    /// Read whole file as UTF-8 (default).
    class function ReadAllText(const AFileName: string): string; overload; static;
    class function ReadAllText(const AFileName: string; const AEncoding: TEncoding): string; overload; static;

    class function Serialize<T>(const AData: T): string; static;
    class function Deserialize<T>(const AData: string): T; static;

    class constructor Create();
    class destructor Destroy();
  end;

implementation

{ TTestUtils }

class constructor TTestUtils.Create;
begin
  FSerializer := BuildSerializer();
end;

class destructor TTestUtils.Destroy;
var
 I: Integer;
begin
  if Assigned(FSerializer) then
  begin
    if Assigned(FSerializer.Converters) then
    begin
      for I := 0 to FSerializer.Converters.Count - 1 do
        if Assigned(FSerializer.Converters[I]) then
          FSerializer.Converters[I].Free;
      FSerializer.Converters.Clear;
    end;
    FSerializer.Free;
  end;

  inherited;
end;

class function TTestUtils.BuildSerializer: TJsonSerializer;
var
  Converters     : TList<TJsonConverter>;
  LRpcConverters : TList<TJsonConverter>;
begin
  Converters := TList<TJsonConverter>.Create;
  try
    Converters.Add(TJsonStringEnumConverter.Create(TJsonNamingPolicy.CamelCase));
    Converters.Add(TEncodingConverter.Create);

    LRpcConverters := TJsonConverterFactory.GetRpcConverters;
    try
      Converters.AddRange(LRpcConverters);
    finally
      LRpcConverters.Free;
    end;

    Result := TJsonSerializerFactory.CreateSerializer(
      TEnhancedContractResolver.Create(
        TJsonMemberSerialization.Public,
        TJsonNamingPolicy.CamelCase
      ),
      Converters
    );
  finally
    Converters.Free;
  end;
end;

class function TTestUtils.Serialize<T>(const AData: T): string;
begin
  Result := FSerializer.Serialize<T>(AData);
end;

class function TTestUtils.Deserialize<T>(const AData: string): T;
begin
  Result := FSerializer.Deserialize<T>(AData);
end;

class procedure TTestUtils.SetTestSourceRoot(const Dir: string);
begin
  FTestSourceRoot := IncludeTrailingPathDelimiter(Dir);
end;

class function TTestUtils.LocateUpwards(
  const StartDir: string;
  const Targets: array of string;
  out FoundAncestorDir, FoundFullPath: string): Boolean;
var
  Cur, Parent, CandidatePath: string;
  Steps, i: Integer;
begin
  Result := False;
  FoundAncestorDir := '';
  FoundFullPath    := '';

  Cur := IncludeTrailingPathDelimiter(ExpandFileName(StartDir));

  for Steps := 0 to 32 do
  begin
    for i := 0 to High(Targets) do
    begin
      CandidatePath := TIOUtils.GetFullPath(TIOUtils.CombinePath(Cur, Targets[i]));
      if DirectoryExists(CandidatePath) or FileExists(CandidatePath) then
      begin
        FoundAncestorDir := Cur;
        FoundFullPath    := CandidatePath;
        Exit(True);
      end;
    end;

    Parent := IncludeTrailingPathDelimiter(
      ExtractFileDir(ExcludeTrailingPathDelimiter(Cur))
    );
    if (Parent = '') or SameFileName(Parent, Cur) then Break;
    Cur := Parent;
  end;
end;

class function TTestUtils.GetSourceDir(const Marker: string): string;
var
  Base, Full: string;
begin
  // 0) explicit override
  if FTestSourceRoot <> '' then
    Exit(IncludeTrailingPathDelimiter(FTestSourceRoot));

  // 1) Heuristic climb via LocateUpwards
  if (Marker <> '') and TTestUtils.LocateUpwards(ExecutableDir, [Marker], Base, Full) then
    Exit(IncludeTrailingPathDelimiter(Full));  // return the matched path

  // 2) Fail loudly
  raise Exception.Create(
    'Unable to resolve source path. call SetTestSourceRoot, ' +
    'or ensure the marker exists somewhere above the Executable.'
  );
end;

class function TTestUtils.GetSourceDirWithSuffix(
  const Marker, Suffix: string): string;
var
  Root: string;
begin
  Root := GetSourceDir(Marker); // returns the matched folder (Full)
  if Suffix <> '' then
    Result := CombineAll([Root, Suffix], True) // ensure trailing delimiter
  else
    Result := IncludeTrailingPathDelimiter(ExcludeTrailingPathDelimiter(Root));
end;

class function TTestUtils.CombineAll(const Parts: array of string;
  const IncludeTrailingDelimiter: Boolean): string;
var
  i: Integer;
  P: string;
begin
  Result := '';
  for i := 0 to High(Parts) do
  begin
    P := Trim(Parts[i]);
    if P = '' then
      Continue;

    if Result = '' then
      Result := P
    else
      Result := IncludeTrailingPathDelimiter(ExcludeTrailingPathDelimiter(Result)) + P;
  end;

  if IncludeTrailingDelimiter then
    Result := IncludeTrailingPathDelimiter(ExcludeTrailingPathDelimiter(Result))
  else
    Result := ExcludeTrailingPathDelimiter(Result);
end;

class function TTestUtils.ExecutableDir: string;
begin
  Result := IncludeTrailingPathDelimiter(GetCurrentDir);
end;

class function TTestUtils.ReadAllText(const AFileName: string): string;
begin
  Result := ReadAllText(AFileName, TEncoding.UTF8);
end;

class function TTestUtils.ReadAllText(const AFileName: string; const AEncoding: TEncoding): string;
begin
  Result := TIOUtils.ReadAllText(AFileName, AEncoding);
end;

end.

