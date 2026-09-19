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

unit SlpTokenPrograms;

{$I ../Include/SolLib.inc}

interface

uses
  SlpTokenProgram,
  SlpToken2022Program;

type
  /// <summary>Metaclass reference to the classic SPL Token program.</summary>
  TTokenProgramClass = class of TTokenProgram;
  /// <summary>Metaclass reference to the Token-2022 program.</summary>
  TToken2022ProgramClass = class of TToken2022Program;

  /// <summary>
  /// Namespacing entry point for the SPL token programs. <c>Legacy</c> is the classic
  /// Token program and <c>Token2022</c> is the Token-2022 program; each yields the
  /// program class, so instructions read as, for example,
  /// <c>TTokenPrograms.Token2022.Transfer(...)</c>.
  /// </summary>
  TTokenPrograms = class sealed
  strict private
    class function GetLegacy: TTokenProgramClass; static;
    class function GetToken2022: TToken2022ProgramClass; static;
  public
    /// <summary>The classic SPL Token program.</summary>
    class property Legacy: TTokenProgramClass read GetLegacy;
    /// <summary>The Token-2022 program.</summary>
    class property Token2022: TToken2022ProgramClass read GetToken2022;
  end;

implementation

{ TTokenPrograms }

class function TTokenPrograms.GetLegacy: TTokenProgramClass;
begin
  Result := TTokenProgram;
end;

class function TTokenPrograms.GetToken2022: TToken2022ProgramClass;
begin
  Result := TToken2022Program;
end;

end.
