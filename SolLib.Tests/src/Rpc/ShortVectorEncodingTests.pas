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

unit ShortVectorEncodingTests;

interface

uses
  System.SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpShortVectorEncoding,
  SolLibTestCase;

type
  TShortVectorEncodingTests = class(TSolLibTestCase)
  published
    procedure EncodeLength;
  end;

implementation

{ TShortVectorEncodingTests }

procedure TShortVectorEncodingTests.EncodeLength;
begin
  // 0      -> [0x00]
  AssertEquals<Byte>(
    TBytes.Create($00),
    TShortVectorEncoding.EncodeLength(0),
    'encode(0)'
  );

  // 1      -> [0x01]
  AssertEquals<Byte>(
    TBytes.Create($01),
    TShortVectorEncoding.EncodeLength(1),
    'encode(1)'
  );

  // 5      -> [0x05]
  AssertEquals<Byte>(
    TBytes.Create($05),
    TShortVectorEncoding.EncodeLength(5),
    'encode(5)'
  );

  // 127    -> [0x7F]
  AssertEquals<Byte>(
    TBytes.Create($7F),
    TShortVectorEncoding.EncodeLength(127),
    'encode(127)'
  );

  // 128    -> [0x80, 0x01]
  AssertEquals<Byte>(
    TBytes.Create($80, $01),
    TShortVectorEncoding.EncodeLength(128),
    'encode(128)'
  );

  // 255    -> [0xFF, 0x01]
  AssertEquals<Byte>(
    TBytes.Create($FF, $01),
    TShortVectorEncoding.EncodeLength(255),
    'encode(255)'
  );

  // 256    -> [0x80, 0x02]
  AssertEquals<Byte>(
    TBytes.Create($80, $02),
    TShortVectorEncoding.EncodeLength(256),
    'encode(256)'
  );

  // 32767  -> [0xFF, 0xFF, 0x01]
  AssertEquals<Byte>(
    TBytes.Create($FF, $FF, $01),
    TShortVectorEncoding.EncodeLength(32767),
    'encode(32767)'
  );

  // 2,097,152 (0x200000) -> [0x80, 0x80, 0x80, 0x01]
  AssertEquals<Byte>(
    TBytes.Create($80, $80, $80, $01),
    TShortVectorEncoding.EncodeLength(2097152),
    'encode(2097152)'
  );
end;

initialization
{$IFDEF FPC}
  RegisterTest(TShortVectorEncodingTests);
{$ELSE}
  RegisterTest(TShortVectorEncodingTests.Suite);
{$ENDIF}

end.

