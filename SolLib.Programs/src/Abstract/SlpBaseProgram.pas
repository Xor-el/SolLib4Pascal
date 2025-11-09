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

unit SlpBaseProgram;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  SlpPublicKey;

type
  /// <summary>
  /// Base Program interface.
  /// </summary>
  IProgram = interface
    ['{2E5E3D9B-6A0C-4B2E-9A52-9C0E3C8C7B11}']
    /// <summary>
    /// The program's key
    /// </summary>
    function GetProgramIdKey: IPublicKey;
    /// <summary>
    /// The name of the program
    /// </summary>
    function GetProgramName: string;

    /// <summary>
    /// The program's key
    /// </summary>
    property ProgramIdKey: IPublicKey read GetProgramIdKey;
    /// <summary>
    /// The name of the program
    /// </summary>
    property ProgramName: string read GetProgramName;
  end;

  /// <summary>
  /// A class to abstract some of the core program commonality
  /// </summary>
  TBaseProgram = class abstract(TInterfacedObject, IProgram)
  private
    FProgramIdKey: IPublicKey;
    FProgramName : string;
  protected
    /// <summary>
    /// The public key of the program.
    /// </summary>
    function GetProgramIdKey: IPublicKey; virtual;
    /// <summary>
    /// The program's name.
    /// </summary>
    function GetProgramName: string; virtual;
  public
    /// <summary>
    /// Creates an instance of the base program class with specified id and name.
    /// </summary>
    /// <param name="AProgramIdKey">The program key</param>
    /// <param name="AProgramName">The program name</param>
    constructor Create(const AProgramIdKey: IPublicKey; const AProgramName: string); reintroduce;

    /// <summary>
    /// The public key of the program.
    /// </summary>
    property ProgramIdKey: IPublicKey read GetProgramIdKey;
    /// <summary>
    /// The program's name.
    /// </summary>
    property ProgramName: string read GetProgramName;
  end;

implementation

{ TBaseProgram }

constructor TBaseProgram.Create(const AProgramIdKey: IPublicKey; const AProgramName: string);
begin
  inherited Create;
  FProgramIdKey := AProgramIdKey;
  FProgramName  := AProgramName;
end;

function TBaseProgram.GetProgramIdKey: IPublicKey;
begin
  Result := FProgramIdKey;
end;

function TBaseProgram.GetProgramName: string;
begin
  Result := FProgramName;
end;

end.

