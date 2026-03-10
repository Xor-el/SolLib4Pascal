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

unit SlpExampleExplorer;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  SlpExample;

type
  TExampleExplorer = class sealed
  public
    class procedure Execute; static;
  end;

implementation

class procedure TExampleExplorer.Execute;
var
  LCtx: TRttiContext;
  LTypes: TArray<TRttiType>;
  LCandidates: TList<TRttiInstanceType>;
  LT: TRttiType;
  LCls: TRttiInstanceType;
  LCtor: TRttiMethod;
  LOption: string;
  LIndex, LI: Integer;
  LInstValue: TValue;
  LObj: TObject;
  LExample: IExample;

function GetParameterlessConstructor(const AType: TRttiInstanceType): TRttiMethod;
var
  LMethod: TRttiMethod;
  LC: TClass;
begin
  Result := nil;

  if (AType = nil) or (AType.MetaclassType = nil) then
    Exit;

  LC := AType.MetaclassType;

  // Skip the abstract root itself (exact match only)
  if LC = TBaseExample then
    Exit;

  // Find a public parameterless constructor
  for LMethod in AType.GetMethods do
    if LMethod.IsConstructor
       and (Length(LMethod.GetParameters) = 0)
       and (LMethod.Visibility in [mvPublic]) then
      Exit(LMethod);
end;

function ImplementsIExample(const AType: TRttiInstanceType): Boolean;
var
  LIID: TGUID;
  LC: TClass;
begin
  Result := False;
  if (AType = nil) or (AType.MetaclassType = nil) then Exit;
  LIID := GetTypeData(TypeInfo(IExample))^.Guid;

  LC := AType.MetaclassType;
  while LC <> nil do
  begin
    if LC.GetInterfaceEntry(LIID) <> nil then
      Exit(True);
    LC := LC.ClassParent;
  end;
end;

begin
  LCtx := TRttiContext.Create;
  LCandidates := TList<TRttiInstanceType>.Create;
  try
    LTypes := LCtx.GetTypes;

    for LT in LTypes do
      if (LT is TRttiInstanceType) then
      begin
        LCls := TRttiInstanceType(LT);

        if (LCls.MetaclassType.ClassInfo <> nil) and
           not LCls.MetaclassType.ClassName.StartsWith('@') then
        begin
          if ((GetParameterlessConstructor(LCls) <> nil) and ImplementsIExample(LCls)) then
            LCandidates.Add(LCls);
        end;
      end;

   if LCandidates.Count = 0 then
    begin
      Writeln('No examples found. Make sure the example units are in the DPR uses list.');
      Exit;
    end;

    // main loop with “exit” or “quit” command for graceful stop
    while True do
    begin
      Writeln;
      Writeln('Choose an example to run (type "exit" or "quit" to leave):');
      for LI := 0 to LCandidates.Count - 1 do
        Writeln(LI.ToString + ') ' + LCandidates[LI].MetaclassType.ClassName);

      Write('> ');
      Readln(LOption);

      if SameText(LOption, 'exit') or SameText(LOption, 'quit') then
        Break;

      if TryStrToInt(LOption, LIndex) and (LIndex >= 0) and (LIndex < LCandidates.Count) then
      begin
        LCls := LCandidates[LIndex];
        try
          LCtor := GetParameterlessConstructor(LCls);
          if LCtor = nil then
            raise Exception.CreateFmt('No parameterless constructor found for %s',
              [LCls.MetaclassType.ClassName]);

          LInstValue := LCtor.Invoke(LCls.MetaclassType, []);
          LObj := LInstValue.AsObject;

          if Supports(LObj, IExample, LExample) then
            LExample.Run
          else
            Writeln('Selected type does not support IExample at runtime.');
        except
          on E: Exception do
            Writeln('Error running example: ' + E.ClassName + ': ' + E.Message);
        end;
      end
      else
        Writeln('Invalid option.');
    end;

    Writeln('Explorer stopped gracefully.');
  finally
    LCandidates.Free;
    LCtx.Free;
  end;
end;

end.

