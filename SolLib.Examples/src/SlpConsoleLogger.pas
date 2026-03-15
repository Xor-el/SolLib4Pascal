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

unit SlpConsoleLogger;

interface

uses
  System.SysUtils,
  SlpLogger;

type
  TConsoleLogger = class(TInterfacedObject, ILogger)
  private
    FCategory: string;
    FMinLevel: TLogLevel;
    FAnsiEnabled: Boolean;

    function LevelToString(ALevel: TLogLevel): string;
    function LevelAnsiColor(ALevel: TLogLevel): string;
    function ResetAnsiColor: string;
    function IsPositionalTemplate(const ATemplate: string): Boolean;
    function FormatMessage(const ATemplate: string; const AArgs: array of const): string;
    function VarRecToString(const AVarRec: TVarRec): string;
    class function BackingObjectFromInterface(const AIntf: IInterface): TObject; static;
    function IsAnsiSupported: Boolean;
  public
    constructor Create(const ACategory: string; AMinLevel: TLogLevel = TLogLevel.Trace);
    class constructor Create;

    procedure Log(ALevel: TLogLevel; const AEventId: TEventId; const AMessageTemplate: string; const AArgs: array of const); overload;
    procedure Log(ALevel: TLogLevel; const AMessageTemplate: string; const AArgs: array of const); overload;

    procedure LogException(ALevel: TLogLevel; const AEventId: TEventId; const AException: Exception; const AMessageTemplate: string; const AArgs: array of const); overload;
    procedure LogException(ALevel: TLogLevel; const AException: Exception; const AMessageTemplate: string; const AArgs: array of const); overload;

    procedure LogTrace(const AMessageTemplate: string; const AArgs: array of const); overload;
    procedure LogTrace(const AEventId: TEventId; const AMessageTemplate: string; const AArgs: array of const); overload;

    procedure LogDebug(const AMessageTemplate: string; const AArgs: array of const); overload;
    procedure LogDebug(const AEventId: TEventId; const AMessageTemplate: string; const AArgs: array of const); overload;

    procedure LogInformation(const AMessageTemplate: string; const AArgs: array of const); overload;
    procedure LogInformation(const AEventId: TEventId; const AMessageTemplate: string; const AArgs: array of const); overload;

    procedure LogWarning(const AMessageTemplate: string; const AArgs: array of const); overload;
    procedure LogWarning(const AEventId: TEventId; const AMessageTemplate: string; const AArgs: array of const); overload;

    procedure LogError(const AMessageTemplate: string; const AArgs: array of const); overload;
    procedure LogError(const AEventId: TEventId; const AMessageTemplate: string; const AArgs: array of const); overload;

    procedure LogCritical(const AMessageTemplate: string; const AArgs: array of const); overload;
    procedure LogCritical(const AEventId: TEventId; const AMessageTemplate: string; const AArgs: array of const); overload;

    function IsEnabled(ALevel: TLogLevel): Boolean;
    function Category: string;
  end;

  TConsoleLoggerFactory = class(TInterfacedObject, ILoggerFactory)
  private
    FMinLevel: TLogLevel;
  public
    constructor Create(AMinLevel: TLogLevel = TLogLevel.Trace);
    function CreateLogger(const ACategoryName: string): ILogger;
    procedure SetMinimumLevel(ALevel: TLogLevel);
    function GetMinimumLevel: TLogLevel;
  end;

implementation

{$IFDEF MSWINDOWS}
uses
  Winapi.Windows;

procedure EnableVirtualTerminalProcessing;
var
  LHandle: THandle;
  LMode: DWORD;
begin
  LHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  if (LHandle = INVALID_HANDLE_VALUE) or not GetConsoleMode(LHandle, LMode) then
    Exit;

  LMode := LMode or ENABLE_VIRTUAL_TERMINAL_PROCESSING;
  SetConsoleMode(LHandle, LMode);
end;
{$ENDIF}

{ TConsoleLogger }

class constructor TConsoleLogger.Create;
begin
  {$IFDEF MSWINDOWS}
  EnableVirtualTerminalProcessing;
  {$ENDIF}
end;

constructor TConsoleLogger.Create(const ACategory: string; AMinLevel: TLogLevel);
begin
  inherited Create;
  FCategory := ACategory;
  FMinLevel := AMinLevel;
  FAnsiEnabled := IsAnsiSupported;
end;

function TConsoleLogger.IsAnsiSupported: Boolean;
{$IFDEF MSWINDOWS}
var
  LHandle: THandle;
  LMode: DWORD;
begin
  LHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  if (LHandle = INVALID_HANDLE_VALUE) or not GetConsoleMode(LHandle, LMode) then
    Exit(False);
  Result := (LMode and ENABLE_VIRTUAL_TERMINAL_PROCESSING) <> 0;
end;
{$ELSE}
begin
  Result := True;
end;
{$ENDIF}

function TConsoleLogger.Category: string;
begin
  Result := FCategory;
end;

function TConsoleLogger.IsEnabled(ALevel: TLogLevel): Boolean;
begin
  Result := Ord(ALevel) >= Ord(FMinLevel);
end;

function TConsoleLogger.LevelToString(ALevel: TLogLevel): string;
const
  Names: array[TLogLevel] of string = ('TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL');
begin
  Result := Names[ALevel];
end;

function TConsoleLogger.LevelAnsiColor(ALevel: TLogLevel): string;
begin
  if not FAnsiEnabled then Exit('');
  case ALevel of
    TLogLevel.Trace: Result := #27'[37m';
    TLogLevel.Debug: Result := #27'[36m';
    TLogLevel.Info:  Result := #27'[32m';
    TLogLevel.Warn:  Result := #27'[33m';
    TLogLevel.Error: Result := #27'[31m';
    TLogLevel.Fatal: Result := #27'[35m';
  else
    Result := #27'[0m';
  end;
end;

function TConsoleLogger.ResetAnsiColor: string;
begin
  if not FAnsiEnabled then Exit('');
  Result := #27'[0m';
end;

function TConsoleLogger.IsPositionalTemplate(const ATemplate: string): Boolean;
var
  LI, LLen: Integer;
begin
  Result := False;
  LLen := Length(ATemplate);
  if LLen < 2 then Exit;
  for LI := 1 to LLen - 1 do
    if ATemplate[LI] = '{' then
      if CharInSet(ATemplate[LI + 1], ['0'..'9']) then
      begin
        Result := True;
        Exit;
      end;
end;

function TConsoleLogger.VarRecToString(const AVarRec: TVarRec): string;
var
  LObj: TObject;
  LIntfObj: TObject;
begin
  case AVarRec.VType of
    vtInteger:       Result := IntToStr(AVarRec.VInteger);
    vtInt64:         Result := IntToStr(AVarRec.VInt64^);
    vtBoolean:       Result := BoolToStr(AVarRec.VBoolean, True);
    vtChar:          Result := string(AVarRec.VChar);
    vtWideChar:      Result := AVarRec.VWideChar;
    vtExtended:      Result := FloatToStr(AVarRec.VExtended^);
    vtString:        Result := string(AVarRec.VString^);
    vtPChar:         Result := string(AVarRec.VPChar);
    vtPWideChar:     Result := string(AVarRec.VPWideChar);
    vtAnsiString:    Result := string(AnsiString(AVarRec.VAnsiString));
    vtUnicodeString: Result := string(AVarRec.VUnicodeString);
    vtObject:
      begin
        LObj := AVarRec.VObject;
        if Assigned(LObj) then
          Result := Format('%s(%p)', [LObj.ClassName, Pointer(LObj)])
        else
          Result := 'nil';
      end;
    vtInterface:
      begin
        LIntfObj := BackingObjectFromInterface(IInterface(AVarRec.VInterface));
        if Assigned(LIntfObj) then
          Result := Format('%s(%p)', [LIntfObj.ClassName, Pointer(LIntfObj)])
        else
          Result := Format('<interface %p>', [Pointer(AVarRec.VInterface)]);
      end;
  else
    Result := '<unknown>';
  end;
end;

class function TConsoleLogger.BackingObjectFromInterface(const AIntf: IInterface): TObject;
var
  LUnknown: IInterface;
begin
  Result := nil;
  if AIntf = nil then Exit;
  if AIntf.QueryInterface(IInterface, LUnknown) = S_OK then
    if TObject(LUnknown) is TObject then
      Result := TObject(LUnknown);
end;

function TConsoleLogger.FormatMessage(const ATemplate: string; const AArgs: array of const): string;
var
  LI: Integer;
  LStr: string;
begin
  LStr := ATemplate;
  if IsPositionalTemplate(LStr) then
  begin
    for LI := High(AArgs) downto 0 do
      LStr := StringReplace(LStr, '{' + LI.ToString + '}', VarRecToString(AArgs[LI]), [rfReplaceAll]);
    Result := LStr;
    Exit;
  end;

  if Length(AArgs) > 0 then
    Result := Format(LStr, AArgs)
  else
    Result := LStr;
end;

procedure TConsoleLogger.Log(ALevel: TLogLevel; const AMessageTemplate: string; const AArgs: array of const);
begin
  Log(ALevel, TEventId.Empty, AMessageTemplate, AArgs);
end;

procedure TConsoleLogger.Log(ALevel: TLogLevel; const AEventId: TEventId;
  const AMessageTemplate: string; const AArgs: array of const);
const
  DIM_ANSI = #27'[90m';
var
  LMsg, LLevelStr, LDateStr: string;
  LDim, LColor, LReset: string;
  LPrefix, LEventPart, LCategoryPart, LCategoryWithColon: string;
begin
  if not IsEnabled(ALevel) then Exit;

  LMsg := FormatMessage(AMessageTemplate, AArgs);
  LLevelStr := LevelToString(ALevel);
  LDateStr := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now);

  // Style tokens collapse to empty when ANSI is disabled
  if FAnsiEnabled then
  begin
    LDim := DIM_ANSI;
    LColor := LevelAnsiColor(ALevel);
    LReset := ResetAnsiColor;
  end
  else
  begin
    LDim := '';
    LColor := '';
    LReset := '';
  end;

  // Category (optional)
  if FCategory <> '' then
    LCategoryPart := Format('%s[%s]%s', [LDim, FCategory, LReset])
  else
    LCategoryPart := '';

  // Prefix: date/time and [LEVEL] (brackets dimmed, level colored)
  LPrefix := Format('%s%s %s[%s%s%s%s] ', [LDim, LDateStr, LDim, LColor, LLevelStr, LReset, LDim]);

  // Event id (optional)
  if not AEventId.IsEmpty then
    LEventPart := Format('(%s%d:%s%s) ', [LDim, AEventId.Id, AEventId.Name, LDim])
  else
    LEventPart := '';

  // Category + colon (optional; colon is dimmed if ANSI)
  if LCategoryPart <> '' then
    LCategoryWithColon := Format('%s%s: ', [LCategoryPart, LDim])
  else
    LCategoryWithColon := '';

  // Final line (ensure we reset styles before the message)
  Writeln(Format('%s%s%s%s%s', [LPrefix, LEventPart, LCategoryWithColon, LReset, LMsg]));
end;

procedure TConsoleLogger.LogException(ALevel: TLogLevel; const AException: Exception; const AMessageTemplate: string; const AArgs: array of const);
begin
  LogException(ALevel, TEventId.Empty, AException, AMessageTemplate, AArgs);
end;

procedure TConsoleLogger.LogException(ALevel: TLogLevel; const AEventId: TEventId; const AException: Exception; const AMessageTemplate: string; const AArgs: array of const);
var
  LFullMsg: string;
begin
  LFullMsg := FormatMessage(AMessageTemplate, AArgs) + sLineBreak + '  Exception: ' + AException.ClassName + ' - ' + AException.Message;
  Log(ALevel, AEventId, LFullMsg, []);
end;

procedure TConsoleLogger.LogTrace(const AMessageTemplate: string; const AArgs: array of const);
begin
  Log(TLogLevel.Trace, AMessageTemplate, AArgs);
end;

procedure TConsoleLogger.LogTrace(const AEventId: TEventId; const AMessageTemplate: string; const AArgs: array of const);
begin
  Log(TLogLevel.Trace, AEventId, AMessageTemplate, AArgs);
end;

procedure TConsoleLogger.LogDebug(const AMessageTemplate: string; const AArgs: array of const);
begin
  Log(TLogLevel.Debug, AMessageTemplate, AArgs);
end;

procedure TConsoleLogger.LogDebug(const AEventId: TEventId; const AMessageTemplate: string; const AArgs: array of const);
begin
  Log(TLogLevel.Debug, AEventId, AMessageTemplate, AArgs);
end;

procedure TConsoleLogger.LogInformation(const AMessageTemplate: string; const AArgs: array of const);
begin
  Log(TLogLevel.Info, AMessageTemplate, AArgs);
end;

procedure TConsoleLogger.LogInformation(const AEventId: TEventId; const AMessageTemplate: string; const AArgs: array of const);
begin
  Log(TLogLevel.Info, AEventId, AMessageTemplate, AArgs);
end;

procedure TConsoleLogger.LogWarning(const AMessageTemplate: string; const AArgs: array of const);
begin
  Log(TLogLevel.Warn, AMessageTemplate, AArgs);
end;

procedure TConsoleLogger.LogWarning(const AEventId: TEventId; const AMessageTemplate: string; const AArgs: array of const);
begin
  Log(TLogLevel.Warn, AEventId, AMessageTemplate, AArgs);
end;

procedure TConsoleLogger.LogError(const AMessageTemplate: string; const AArgs: array of const);
begin
  Log(TLogLevel.Error, AMessageTemplate, AArgs);
end;

procedure TConsoleLogger.LogError(const AEventId: TEventId; const AMessageTemplate: string; const AArgs: array of const);
begin
  Log(TLogLevel.Error, AEventId, AMessageTemplate, AArgs);
end;

procedure TConsoleLogger.LogCritical(const AMessageTemplate: string; const AArgs: array of const);
begin
  Log(TLogLevel.Fatal, AMessageTemplate, AArgs);
end;

procedure TConsoleLogger.LogCritical(const AEventId: TEventId; const AMessageTemplate: string; const AArgs: array of const);
begin
  Log(TLogLevel.Fatal, AEventId, AMessageTemplate, AArgs);
end;

{ TConsoleLoggerFactory }

constructor TConsoleLoggerFactory.Create(AMinLevel: TLogLevel);
begin
  inherited Create;
  FMinLevel := AMinLevel;
end;

function TConsoleLoggerFactory.CreateLogger(const ACategoryName: string): ILogger;
begin
  Result := TConsoleLogger.Create(ACategoryName, FMinLevel);
end;

procedure TConsoleLoggerFactory.SetMinimumLevel(ALevel: TLogLevel);
begin
  FMinLevel := ALevel;
end;

function TConsoleLoggerFactory.GetMinimumLevel: TLogLevel;
begin
  Result := FMinLevel;
end;

end.

