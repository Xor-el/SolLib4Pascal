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

unit SlpExampleExplorer;

{$I ..\..\SolLib\src\Include\SolLib.inc}

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
  Ctx        : TRttiContext;
  Types      : TArray<TRttiType>;
  Candidates : TList<TRttiInstanceType>;
  T          : TRttiType;
  Cls        : TRttiInstanceType;
  LCtor      : TRttiMethod;
  Option     : string;
  Index, I   : Integer;
  InstValue  : TValue;
  Obj        : TObject;
  Example    : IExample;

function GetParameterlessConstructor(const AType: TRttiInstanceType): TRttiMethod;
var
  M: TRttiMethod;
  C: TClass;
begin
  Result := nil;

  if (AType = nil) or (AType.MetaclassType = nil) then
    Exit;

  C := AType.MetaclassType;

  // Skip the abstract root itself (exact match only)
  if C = TBaseExample then
    Exit;

  // Find a public parameterless constructor
  for M in AType.GetMethods do
    if M.IsConstructor
       and (Length(M.GetParameters) = 0)
       and (M.Visibility in [mvPublic]) then
      Exit(M);
end;

function ImplementsIExample(const AType: TRttiInstanceType): Boolean;
var
  IID: TGUID;
  C  : TClass;
begin
  Result := False;
  if (AType = nil) or (AType.MetaclassType = nil) then Exit;
  IID := GetTypeData(TypeInfo(IExample))^.Guid;

  C := AType.MetaclassType;
  while C <> nil do
  begin
    if C.GetInterfaceEntry(IID) <> nil then
      Exit(True);
    C := C.ClassParent;
  end;
end;

begin
  Ctx := TRttiContext.Create;
  Candidates := TList<TRttiInstanceType>.Create;
  try
    Types := Ctx.GetTypes;

    for T in Types do
      if (T is TRttiInstanceType) then
      begin
        Cls := TRttiInstanceType(T);

        if (Cls.MetaclassType.ClassInfo <> nil) and
           not Cls.MetaclassType.ClassName.StartsWith('@') then
        begin
          if ((GetParameterlessConstructor(Cls) <> nil) and ImplementsIExample(Cls)) then
            Candidates.Add(Cls);
        end;
      end;

   if Candidates.Count = 0 then
    begin
      Writeln('No examples found. Make sure the example units are in the DPR uses list.');
      Exit;
    end;

    // main loop with “exit” or “quit” command for graceful stop
    while True do
    begin
      Writeln;
      Writeln('Choose an example to run (type "exit" or "quit" to leave):');
      for I := 0 to Candidates.Count - 1 do
        Writeln(I.ToString + ') ' + Candidates[I].MetaclassType.ClassName);

      Write('> ');
      Readln(Option);

      if SameText(Option, 'exit') or SameText(Option, 'quit') then
        Break;

      if TryStrToInt(Option, Index) and (Index >= 0) and (Index < Candidates.Count) then
      begin
        Cls := Candidates[Index];
        try
          LCtor := GetParameterlessConstructor(Cls);
          if LCtor = nil then
            raise Exception.CreateFmt('No parameterless constructor found for %s',
              [Cls.MetaclassType.ClassName]);

          InstValue := LCtor.Invoke(Cls.MetaclassType, []);
          Obj := InstValue.AsObject;

          if Supports(Obj, IExample, Example) then
            Example.Run
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
    Candidates.Free;
    Ctx.Free;
  end;
end;

end.

