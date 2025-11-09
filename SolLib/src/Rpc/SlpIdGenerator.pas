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

unit SlpIdGenerator;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.SyncObjs;

type
  /// <summary>
  /// Id generator
  /// </summary>
  TIdGenerator = class
  private
    FId: Integer;
    FLock: TCriticalSection;
  public

    constructor Create;
    destructor Destroy; override;
    
    /// <summary>
    /// Gets the id of the next request
    /// </summary>
    /// <returns>The id</returns>
    function GetNextId: Integer;
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
