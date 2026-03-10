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

unit SlpDecodedInstruction;

{$I ../../Include/SolLib.inc}

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
    procedure SetPublicKey(const AValue: IPublicKey);
    function  GetProgramName: string;
    procedure SetProgramName(const AValue: string);
    function  GetInstructionName: string;
    procedure SetInstructionName(const AValue: string);
    function  GetValues: TDictionary<string, TValue>;
    procedure SetValues(const AValue: TDictionary<string, TValue>);
    function  GetInnerInstructions: TList<IDecodedInstruction>;
    procedure SetInnerInstructions(const AValue: TList<IDecodedInstruction>);

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
    procedure SetPublicKey(const AValue: IPublicKey);
    function  GetProgramName: string;
    procedure SetProgramName(const AValue: string);
    function  GetInstructionName: string;
    procedure SetInstructionName(const AValue: string);
    function  GetValues: TDictionary<string, TValue>;
    procedure SetValues(const AValue: TDictionary<string, TValue>);
    function  GetInnerInstructions: TList<IDecodedInstruction>;
    procedure SetInnerInstructions(const AValue: TList<IDecodedInstruction>);
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

procedure TDecodedInstruction.SetPublicKey(const AValue: IPublicKey);
begin
  FPublicKey := AValue;
end;

function TDecodedInstruction.GetProgramName: string;
begin
  Result := FProgramName;
end;

procedure TDecodedInstruction.SetProgramName(const AValue: string);
begin
  FProgramName := AValue;
end;

function TDecodedInstruction.GetInstructionName: string;
begin
  Result := FInstructionName;
end;

procedure TDecodedInstruction.SetInstructionName(const AValue: string);
begin
  FInstructionName := AValue;
end;

function TDecodedInstruction.GetValues: TDictionary<string, TValue>;
begin
  Result := FValues;
end;

procedure TDecodedInstruction.SetValues(
  const AValue: TDictionary<string, TValue>);
begin
  FValues := AValue;
end;

function TDecodedInstruction.GetInnerInstructions: TList<IDecodedInstruction>;
begin
  Result := FInnerInstructions;
end;

procedure TDecodedInstruction.SetInnerInstructions(
  const AValue: TList<IDecodedInstruction>);
begin
  FInnerInstructions := AValue;
end;

function TDecodedInstruction.ToString: string;
begin
  Result := ToStringIdented(0);
end;

function TDecodedInstruction.ToStringIdented(AIndent: Integer): string;

  function PairToString(const AKey: string; const AVal: TValue): string;
  var
    LSVal: string;
  begin
    if AVal.IsEmpty then
      LSVal := ''
    else
      LSVal := AVal.ToStringExtended;
    Result := Format('[%s, %s]', [AKey, LSVal]);
  end;

var
  LIndent: string;
  LKV: TPair<string, TValue>;
  LValuesJoined: string;
  LFirst: Boolean;
  LChild: IDecodedInstruction;
  LPubKeyText: string;
begin
  LIndent := StringOfChar(' ', AIndent * 4);
  if FPublicKey <> nil then
    LPubKeyText := FPublicKey.Key
  else
    LPubKeyText := '<nil>';

  // Build joined key/value string
  LValuesJoined := '';
  LFirst := True;
  for LKV in FValues do
  begin
    if not LFirst then
      LValuesJoined := LValuesJoined + ',';
    LValuesJoined := LValuesJoined + PairToString(LKV.Key, LKV.Value);
    LFirst := False;
  end;

  // Use LF (#10)
  Result := '';
  Result := Result + Format('%s[%d] %s:%s:%s'#10,
                            [LIndent, AIndent, LPubKeyText, FProgramName, FInstructionName]);
  Result := Result + Format('%s[%d] [%s]'#10, [LIndent, AIndent, LValuesJoined]);
  Result := Result + Format('%s[%d] InnerInstructions (%d)'#10,
                            [LIndent, AIndent, FInnerInstructions.Count]);

  // Append nested inner instructions
  for LChild in FInnerInstructions do
    Result := Result + LChild.ToStringIdented(AIndent + 1);
end;

end.

