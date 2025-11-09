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

unit SlpDecodedInstruction;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  SlpPublicKey,
  SlpValueHelpers,
  SlpValueUtils;

type
  IDecodedInstruction = interface
    ['{2A8C4084-8B5E-4A75-8C42-2E6D7B34D7C5}']
    function  GetPublicKey: IPublicKey;
    procedure SetPublicKey(const Value: IPublicKey);
    function  GetProgramName: string;
    procedure SetProgramName(const Value: string);
    function  GetInstructionName: string;
    procedure SetInstructionName(const Value: string);
    function  GetValues: TDictionary<string, TValue>;
    procedure SetValues(const Value: TDictionary<string, TValue>);
    function  GetInnerInstructions: TList<IDecodedInstruction>;
    procedure SetInnerInstructions(const Value: TList<IDecodedInstruction>);

    /// <summary>
    /// The public key of the program.
    /// </summary>
    property PublicKey: IPublicKey read GetPublicKey write SetPublicKey;
    /// <summary>
    /// The program name.
    /// </summary>
    property ProgramName: string read GetProgramName write SetProgramName;
    /// <summary>
    /// The instruction name.
    /// </summary>
    property InstructionName: string read GetInstructionName write SetInstructionName;
    /// <summary>
    /// Values decoded from the instruction.
    /// </summary>
    property Values: TDictionary<string, TValue> read GetValues write SetValues;
    /// <summary>
    /// The inner instructions related to this decoded instruction.
    /// </summary>
    property InnerInstructions: TList<IDecodedInstruction> read GetInnerInstructions write SetInnerInstructions;

    /// <summary>
    /// Converts the decoded instructions to a string
    /// </summary>
    /// <returns>A string representation of the decoded instructions</returns>
    function  ToString: string;
    /// <summary>
    /// Converts the decoded instructions to a string, indented a certain amount
    /// </summary>
    /// <returns>A string representation of the decoded instructions, indented a certain amount</returns>
    function  ToStringIdented(AIndent: Integer): string;
  end;

  /// <summary>
  /// Represents a decoded instruction.
  /// </summary>
  TDecodedInstruction = class(TInterfacedObject, IDecodedInstruction)
  private
    FPublicKey        : IPublicKey;
    FProgramName      : string;
    FInstructionName  : string;
    FValues           : TDictionary<string, TValue>;
    FInnerInstructions: TList<IDecodedInstruction>;

    function  GetPublicKey: IPublicKey;
    procedure SetPublicKey(const Value: IPublicKey);
    function  GetProgramName: string;
    procedure SetProgramName(const Value: string);
    function  GetInstructionName: string;
    procedure SetInstructionName(const Value: string);
    function  GetValues: TDictionary<string, TValue>;
    procedure SetValues(const Value: TDictionary<string, TValue>);
    function  GetInnerInstructions: TList<IDecodedInstruction>;
    procedure SetInnerInstructions(const Value: TList<IDecodedInstruction>);
  public
    destructor Destroy; override;

    function  ToString: string; override;
    function  ToStringIdented(AIndent: Integer): string; reintroduce;

  end;

implementation

{ TDecodedInstruction }

destructor TDecodedInstruction.Destroy;
begin
  if Assigned(FInnerInstructions) then FInnerInstructions.Free;
  if Assigned(FValues) then TValueUtils.FreeParameters(FValues);
  inherited;
end;

function TDecodedInstruction.GetPublicKey: IPublicKey;
begin
  Result := FPublicKey;
end;

procedure TDecodedInstruction.SetPublicKey(const Value: IPublicKey);
begin
  FPublicKey := Value;
end;

function TDecodedInstruction.GetProgramName: string;
begin
  Result := FProgramName;
end;

procedure TDecodedInstruction.SetProgramName(const Value: string);
begin
  FProgramName := Value;
end;

function TDecodedInstruction.GetInstructionName: string;
begin
  Result := FInstructionName;
end;

procedure TDecodedInstruction.SetInstructionName(const Value: string);
begin
  FInstructionName := Value;
end;

function TDecodedInstruction.GetValues: TDictionary<string, TValue>;
begin
  Result := FValues;
end;

procedure TDecodedInstruction.SetValues(
  const Value: TDictionary<string, TValue>);
begin
  FValues := Value;
end;

function TDecodedInstruction.GetInnerInstructions: TList<IDecodedInstruction>;
begin
  Result := FInnerInstructions;
end;

procedure TDecodedInstruction.SetInnerInstructions(
  const Value: TList<IDecodedInstruction>);
begin
  FInnerInstructions := Value;
end;

function TDecodedInstruction.ToString: string;
begin
  Result := ToStringIdented(0);
end;

function TDecodedInstruction.ToStringIdented(AIndent: Integer): string;

  function PairToString(const AKey: string; const AVal: TValue): string;
  var
    SVal: string;
  begin
    if AVal.IsEmpty then
      SVal := ''
    else
      SVal := AVal.ToStringExtended;
    Result := Format('[%s, %s]', [AKey, SVal]);
  end;

var
  Indent: string;
  KV: TPair<string, TValue>;
  ValuesJoined: string;
  First: Boolean;
  Child: IDecodedInstruction;
  PubKeyText: string;
begin
  Indent := StringOfChar(' ', AIndent * 4);
  if FPublicKey <> nil then
    PubKeyText := FPublicKey.Key
  else
    PubKeyText := '<nil>';

  // Build joined key/value string
  ValuesJoined := '';
  First := True;
  for KV in FValues do
  begin
    if not First then
      ValuesJoined := ValuesJoined + ',';
    ValuesJoined := ValuesJoined + PairToString(KV.Key, KV.Value);
    First := False;
  end;

  // Use LF (#10)
  Result := '';
  Result := Result + Format('%s[%d] %s:%s:%s'#10,
                            [Indent, AIndent, PubKeyText, FProgramName, FInstructionName]);
  Result := Result + Format('%s[%d] [%s]'#10, [Indent, AIndent, ValuesJoined]);
  Result := Result + Format('%s[%d] InnerInstructions (%d)'#10,
                            [Indent, AIndent, FInnerInstructions.Count]);

  // Append nested inner instructions
  for Child in FInnerInstructions do
    Result := Result + Child.ToStringIdented(AIndent + 1);
end;

end.

