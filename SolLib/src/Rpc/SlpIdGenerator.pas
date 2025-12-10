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

unit SlpIdGenerator;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.SyncObjs;

type
  /// <summary>
  /// Id generator
  /// </summary>
  IIdGenerator = interface
    ['{9A99F7C1-5C42-41C2-9F3D-1A9A2C91F7E3}']
    /// <summary>
    /// Gets the id of the next request
    /// </summary>
    /// <returns>The id</returns>
    function GetNextId: Integer;
  end;

  /// <summary>
  /// Id generator
  /// </summary>
  TIdGenerator = class(TInterfacedObject, IIdGenerator)
  private
    FId: Integer;
    FLock: TCriticalSection;

    /// <summary>
    /// Gets the id of the next request
    /// </summary>
    /// <returns>The id</returns>
    function GetNextId: Integer;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

constructor TIdGenerator.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FId := 0;
end;

destructor TIdGenerator.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TIdGenerator.GetNextId: Integer;
begin
  FLock.Acquire;
  try
    Result := FId;
    Inc(FId);
  finally
    FLock.Release;
  end;
end;

end.
