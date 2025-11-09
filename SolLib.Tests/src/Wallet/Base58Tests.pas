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

unit Base58Tests;

interface

uses
  System.SysUtils,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpDataEncoders,
  SolLibTestCase;

type
  TBase58Tests = class(TSolLibTestCase)
  private
    function FromHexString(const Hex: string): TBytes;
  published
    procedure ShouldEncodeProperly;
    procedure ShouldDecodeProperly;
    procedure ShouldThrowExceptionOnInvalidBase58;
    procedure ShouldThrowExceptionOnEncodingNilOrEmptyArray;
    procedure ShouldThrowExceptionOnDecodingEmptyString;
  end;

implementation

type
  TPair = record
    Hex: string;
    B58: string;
  end;

const
  DataSet: array[0..10] of TPair = (
    (Hex: '61'; B58: '2g'),
    (Hex: '626262'; B58: 'a3gV'),
    (Hex: '636363'; B58: 'aPEr'),
    (Hex: '73696d706c792061206c6f6e6720737472696e67'; B58: '2cFupjhnEsSn59qHXstmK2ffpLv2'),
    (Hex: '00eb15231dfceb60925886b67d065299925915aeb172c06647'; B58: '1NS17iag9jJgTHD1VXjvLCEnZuQ3rJDE9L'),
    (Hex: '516b6fcd0f'; B58: 'ABnLTmg'),
    (Hex: 'bf4f89001e670274dd'; B58: '3SEo3LWLoPntC'),
    (Hex: '572e4794'; B58: '3EFU7m'),
    (Hex: 'ecac89cad93923c02321'; B58: 'EJDM8drfXA6uyA'),
    (Hex: '10c8511e'; B58: 'Rt5zm'),
    (Hex: '00000000000000000000'; B58: '1111111111')
  );

{ TBase58Tests }

function TBase58Tests.FromHexString(const Hex: string): TBytes;
begin
  Result := TEncoders.Hex.DecodeData(Hex);
end;

procedure TBase58Tests.ShouldEncodeProperly;
var
  I: Integer;
  DataBytes: TBytes;
  Encoded: string;
begin
  for I := Low(DataSet) to High(DataSet) do
  begin
    DataBytes := FromHexString(DataSet[I].Hex);
    Encoded := TEncoders.Base58.EncodeData(DataBytes);
    AssertEquals(DataSet[I].B58, Encoded);
  end;
end;

procedure TBase58Tests.ShouldDecodeProperly;
var
  I: Integer;
  Decoded: TBytes;
  Expected: TBytes;
begin
  for I := Low(DataSet) to High(DataSet) do
  begin
    Decoded := TEncoders.Base58.DecodeData(DataSet[I].B58);
    Expected := FromHexString(DataSet[I].Hex);
    AssertEquals<Byte>(Decoded, Expected);
  end;
end;

procedure TBase58Tests.ShouldThrowExceptionOnInvalidBase58;
var
  ResultBytes, Expected2: TBytes;
begin
  // invalid -> must throw
  AssertException(
    procedure
    begin
      TEncoders.Base58.DecodeData('invalid');
    end,
    Exception
  );

  // contains non-base58 content mixed with whitespace -> must throw
  AssertException(
    procedure
    begin
      TEncoders.Base58.DecodeData(' '#9#10#11#12#13' skip '#13#12#11#10#9' a');
    end,
    Exception
  );

  // only ignorable whitespace around the word "skip"
  ResultBytes := TEncoders.Base58.DecodeData(' '#9#10#11#12#13' skip '#13#12#11#10#9' ');
  Expected2 := FromHexString('971a55');
  AssertEquals<Byte>(ResultBytes, Expected2);
end;

procedure TBase58Tests.ShouldThrowExceptionOnEncodingNilOrEmptyArray;
var
  Tmp: TBytes;
begin
  // nil -> must throw
  AssertException(
    procedure
    begin
      Tmp := nil;
      TEncoders.Base58.EncodeData(Tmp);
    end,
    EArgumentNilException
  );

  // empty -> must throw
  AssertException(
    procedure
    begin
      SetLength(Tmp, 0);
      TEncoders.Base58.EncodeData(Tmp);
    end,
    EArgumentNilException
  );
end;

procedure TBase58Tests.ShouldThrowExceptionOnDecodingEmptyString;
begin
  // empty -> must throw
  AssertException(
    procedure
    begin
      TEncoders.Base58.DecodeData('');
    end,
    EArgumentException
  );
end;

initialization
{$IFDEF FPC}
  RegisterTest(TBase58Tests);
{$ELSE}
  RegisterTest(TBase58Tests.Suite);
{$ENDIF}

end.

