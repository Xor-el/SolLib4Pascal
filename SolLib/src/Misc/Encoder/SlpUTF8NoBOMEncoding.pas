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

unit SlpUTF8NoBOMEncoding;

{$I ..\..\Include\SolLib.inc}

interface

uses
  System.SysUtils;

type
  /// UTF-8 encoding that never emits a BOM (singleton via UTF8NoBOM)
  TUTF8NoBOMEncoding = class(TUTF8Encoding)
  strict private
    class var FInstance: TEncoding;
    class function GetInstance: TEncoding; static;
  public
    // Ensure no BOM ever written
    function GetPreamble: TBytes; override;
    function Clone: TEncoding; override;

    class property Instance: TEncoding read GetInstance;

    // Lifecycle
    class constructor Create;
    class destructor Destroy;
  end;

implementation

{ TUTF8NoBOMEncoding }

function TUTF8NoBOMEncoding.GetPreamble: TBytes;
begin
  SetLength(Result, 0); // no BOM
end;

function TUTF8NoBOMEncoding.Clone: TEncoding;
begin
  // Return a new no-BOM encoder if someone clones it
  Result := TUTF8NoBOMEncoding.Create;
end;

class function TUTF8NoBOMEncoding.GetInstance: TEncoding;
begin
  if FInstance = nil then
    FInstance := TUTF8NoBOMEncoding.Create;
  Result := FInstance;
end;

class constructor TUTF8NoBOMEncoding.Create;
begin
  FInstance := TUTF8NoBOMEncoding.Create;
end;

class destructor TUTF8NoBOMEncoding.Destroy;
begin
  FInstance.Free;
  FInstance := nil;
end;

end.

