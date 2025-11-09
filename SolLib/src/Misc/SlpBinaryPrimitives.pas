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

unit SlpBinaryPrimitives;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  ClpConverters;

type
  TBinaryPrimitives = class
  private
    class procedure CheckBounds(const AData: TBytes; AOffset, ANeeded: Integer); static; inline;

    class procedure ReadUInt16AsBytesLEInternal(AValue: UInt16; const AData: TBytes; AOffset: Integer); static; inline;
    class procedure ReadUInt16AsBytesBEInternal(AValue: UInt16; const AData: TBytes; AOffset: Integer); static; inline;
    class function ReadBytesAsUInt16LEInternal(const AData: TBytes; AOffset: Integer): UInt16; static; inline;
    class function ReadBytesAsUInt16BEInternal(const AData: TBytes; AOffset: Integer): UInt16; static; inline;

  public
    class procedure WriteUInt16LittleEndian(const AData: TBytes; AOffset: Integer; AValue: UInt16); static;
    class procedure WriteUInt32LittleEndian(const AData: TBytes; AOffset: Integer; AValue: UInt32); static;
    class procedure WriteUInt64LittleEndian(const AData: TBytes; AOffset: Integer; AValue: UInt64); static;

    class procedure WriteInt16LittleEndian(const AData: TBytes; AOffset: Integer; AValue: Int16); static;
    class procedure WriteInt32LittleEndian(const AData: TBytes; AOffset: Integer; AValue: Int32); static;
    class procedure WriteInt64LittleEndian(const AData: TBytes; AOffset: Integer; AValue: Int64); static;

    class procedure WriteSingleLittleEndian(const AData: TBytes; AOffset: Integer; AValue: Single); static;
    class procedure WriteDoubleLittleEndian(const AData: TBytes; AOffset: Integer; AValue: Double); static;

    class procedure WriteUInt16BigEndian(const AData: TBytes; AOffset: Integer; AValue: UInt16); static;
    class procedure WriteUInt32BigEndian(const AData: TBytes; AOffset: Integer; AValue: UInt32); static;
    class procedure WriteUInt64BigEndian(const AData: TBytes; AOffset: Integer; AValue: UInt64); static;

    class procedure WriteInt16BigEndian(const AData: TBytes; AOffset: Integer; AValue: Int16); static;
    class procedure WriteInt32BigEndian(const AData: TBytes; AOffset: Integer; AValue: Int32); static;
    class procedure WriteInt64BigEndian(const AData: TBytes; AOffset: Integer; AValue: Int64); static;

    class procedure WriteSingleBigEndian(const AData: TBytes; AOffset: Integer; AValue: Single); static;
    class procedure WriteDoubleBigEndian(const AData: TBytes; AOffset: Integer; AValue: Double); static;

    class function ReadUInt16LittleEndian(const AData: TBytes; AOffset: Integer): UInt16; static;
    class function ReadUInt32LittleEndian(const AData: TBytes; AOffset: Integer): UInt32; static;
    class function ReadUInt64LittleEndian(const AData: TBytes; AOffset: Integer): UInt64; static;

    class function ReadInt16LittleEndian(const AData: TBytes; AOffset: Integer): Int16; static;
    class function ReadInt32LittleEndian(const AData: TBytes; AOffset: Integer): Int32; static;
    class function ReadInt64LittleEndian(const AData: TBytes; AOffset: Integer): Int64; static;

    class function ReadSingleLittleEndian(const AData: TBytes; AOffset: Integer): Single; static;
    class function ReadDoubleLittleEndian(const AData: TBytes; AOffset: Integer): Double; static;

    class function ReadUInt16BigEndian(const AData: TBytes; AOffset: Integer): UInt16; static;
    class function ReadUInt32BigEndian(const AData: TBytes; AOffset: Integer): UInt32; static;
    class function ReadUInt64BigEndian(const AData: TBytes; AOffset: Integer): UInt64; static;

    class function ReadInt16BigEndian(const AData: TBytes; AOffset: Integer): Int16; static;
    class function ReadInt32BigEndian(const AData: TBytes; AOffset: Integer): Int32; static;
    class function ReadInt64BigEndian(const AData: TBytes; AOffset: Integer): Int64; static;

    class function ReadSingleBigEndian(const AData: TBytes; AOffset: Integer): Single; static;
    class function ReadDoubleBigEndian(const AData: TBytes; AOffset: Integer): Double; static;
  end;

implementation

{ TBinaryPrimitives }

class procedure TBinaryPrimitives.CheckBounds(const AData: TBytes; AOffset, ANeeded: Integer);
begin
  if (AOffset < 0) or (AOffset + ANeeded > Length(AData)) then
    raise EArgumentOutOfRangeException.Create('AOffset');
end;

class procedure TBinaryPrimitives.ReadUInt16AsBytesLEInternal(AValue: UInt16; const AData: TBytes; AOffset: Integer);
begin
  // Little endian: least significant byte first
  AData[AOffset]     := Byte(AValue and $FF);
  AData[AOffset + 1] := Byte((AValue shr 8) and $FF);
end;

class procedure TBinaryPrimitives.ReadUInt16AsBytesBEInternal(AValue: UInt16; const AData: TBytes; AOffset: Integer);
begin
  // Big endian: most significant byte first
  AData[AOffset]     := Byte((AValue shr 8) and $FF);
  AData[AOffset + 1] := Byte(AValue and $FF);
end;

class function TBinaryPrimitives.ReadBytesAsUInt16LEInternal(const AData: TBytes; AOffset: Integer): UInt16;
begin
  // Little endian: LSB first
  Result := UInt16(AData[AOffset]) or (UInt16(AData[AOffset + 1]) shl 8);
end;

class function TBinaryPrimitives.ReadBytesAsUInt16BEInternal(const AData: TBytes; AOffset: Integer): UInt16;
begin
  // Big endian: MSB first
  Result := (UInt16(AData[AOffset]) shl 8) or UInt16(AData[AOffset + 1]);
end;

class procedure TBinaryPrimitives.WriteUInt16LittleEndian(const AData: TBytes; AOffset: Integer; AValue: UInt16);
begin
  CheckBounds(AData, AOffset, SizeOf(UInt16));
  ReadUInt16AsBytesLEInternal(AValue, AData, AOffset);
end;

class procedure TBinaryPrimitives.WriteUInt32LittleEndian(const AData: TBytes; AOffset: Integer; AValue: UInt32);
begin
  CheckBounds(AData, AOffset, SizeOf(UInt32));
  TConverters.ReadUInt32AsBytesLE(AValue, AData, AOffset);
end;

class procedure TBinaryPrimitives.WriteUInt64LittleEndian(const AData: TBytes; AOffset: Integer; AValue: UInt64);
begin
  CheckBounds(AData, AOffset, SizeOf(UInt64));
  TConverters.ReadUInt64AsBytesLE(AValue, AData, AOffset);
end;

class procedure TBinaryPrimitives.WriteInt16LittleEndian(const AData: TBytes; AOffset: Integer; AValue: Int16);
begin
  CheckBounds(AData, AOffset, SizeOf(Int16));
  ReadUInt16AsBytesLEInternal(UInt16(AValue), AData, AOffset);
end;

class procedure TBinaryPrimitives.WriteInt32LittleEndian(const AData: TBytes; AOffset: Integer; AValue: Int32);
begin
  CheckBounds(AData, AOffset, SizeOf(Int32));
  TConverters.ReadUInt32AsBytesLE(UInt32(AValue), AData, AOffset);
end;

class procedure TBinaryPrimitives.WriteInt64LittleEndian(const AData: TBytes; AOffset: Integer; AValue: Int64);
begin
  CheckBounds(AData, AOffset, SizeOf(Int64));
  TConverters.ReadUInt64AsBytesLE(UInt64(AValue), AData, AOffset);
end;

class procedure TBinaryPrimitives.WriteSingleLittleEndian(const AData: TBytes; AOffset: Integer; AValue: Single);
var
  bits: UInt32;
begin
  CheckBounds(AData, AOffset, SizeOf(Single));
  Move(AValue, bits, SizeOf(Single));
  TConverters.ReadUInt32AsBytesLE(bits, AData, AOffset);
end;

class procedure TBinaryPrimitives.WriteDoubleLittleEndian(const AData: TBytes; AOffset: Integer; AValue: Double);
var
  bits: UInt64;
begin
  CheckBounds(AData, AOffset, SizeOf(Double));
  Move(AValue, bits, SizeOf(Double));
  TConverters.ReadUInt64AsBytesLE(bits, AData, AOffset);
end;

class procedure TBinaryPrimitives.WriteUInt16BigEndian(const AData: TBytes; AOffset: Integer; AValue: UInt16);
begin
  CheckBounds(AData, AOffset, SizeOf(UInt16));
  ReadUInt16AsBytesBEInternal(AValue, AData, AOffset);
end;

class procedure TBinaryPrimitives.WriteUInt32BigEndian(const AData: TBytes; AOffset: Integer; AValue: UInt32);
begin
  CheckBounds(AData, AOffset, SizeOf(UInt32));
  TConverters.ReadUInt32AsBytesBE(AValue, AData, AOffset);
end;

class procedure TBinaryPrimitives.WriteUInt64BigEndian(const AData: TBytes; AOffset: Integer; AValue: UInt64);
begin
  CheckBounds(AData, AOffset, SizeOf(UInt64));
  TConverters.ReadUInt64AsBytesBE(AValue, AData, AOffset);
end;

class procedure TBinaryPrimitives.WriteInt16BigEndian(const AData: TBytes; AOffset: Integer; AValue: Int16);
begin
  CheckBounds(AData, AOffset, SizeOf(Int16));
  ReadUInt16AsBytesBEInternal(UInt16(AValue), AData, AOffset);
end;

class procedure TBinaryPrimitives.WriteInt32BigEndian(const AData: TBytes; AOffset: Integer; AValue: Int32);
begin
  CheckBounds(AData, AOffset, SizeOf(Int32));
  TConverters.ReadUInt32AsBytesBE(UInt32(AValue), AData, AOffset);
end;

class procedure TBinaryPrimitives.WriteInt64BigEndian(const AData: TBytes; AOffset: Integer; AValue: Int64);
begin
  CheckBounds(AData, AOffset, SizeOf(Int64));
  TConverters.ReadUInt64AsBytesBE(UInt64(AValue), AData, AOffset);
end;

class procedure TBinaryPrimitives.WriteSingleBigEndian(const AData: TBytes; AOffset: Integer; AValue: Single);
var
  bits: UInt32;
begin
  CheckBounds(AData, AOffset, SizeOf(Single));
  Move(AValue, bits, SizeOf(Single));
  TConverters.ReadUInt32AsBytesBE(bits, AData, AOffset);
end;

class procedure TBinaryPrimitives.WriteDoubleBigEndian(const AData: TBytes; AOffset: Integer; AValue: Double);
var
  bits: UInt64;
begin
  CheckBounds(AData, AOffset, SizeOf(Double));
  Move(AValue, bits, SizeOf(Double));
  TConverters.ReadUInt64AsBytesBE(bits, AData, AOffset);
end;

class function TBinaryPrimitives.ReadUInt16LittleEndian(const AData: TBytes; AOffset: Integer): UInt16;
begin
  CheckBounds(AData, AOffset, SizeOf(UInt16));
  Result := ReadBytesAsUInt16LEInternal(AData, AOffset);
end;

class function TBinaryPrimitives.ReadUInt32LittleEndian(const AData: TBytes; AOffset: Integer): UInt32;
begin
  CheckBounds(AData, AOffset, SizeOf(UInt32));
  Result := TConverters.ReadBytesAsUInt32LE(PByte(AData), AOffset);
end;

class function TBinaryPrimitives.ReadUInt64LittleEndian(const AData: TBytes; AOffset: Integer): UInt64;
begin
  CheckBounds(AData, AOffset, SizeOf(UInt64));
  Result := TConverters.ReadBytesAsUInt64LE(PByte(AData), AOffset);
end;

class function TBinaryPrimitives.ReadInt16LittleEndian(const AData: TBytes; AOffset: Integer): Int16;
begin
  CheckBounds(AData, AOffset, SizeOf(Int16));
  Result := Int16(ReadBytesAsUInt16LEInternal(AData, AOffset));
end;

class function TBinaryPrimitives.ReadInt32LittleEndian(const AData: TBytes; AOffset: Integer): Int32;
begin
  CheckBounds(AData, AOffset, SizeOf(Int32));
  Result := Int32(TConverters.ReadBytesAsUInt32LE(PByte(AData), AOffset));
end;

class function TBinaryPrimitives.ReadInt64LittleEndian(const AData: TBytes; AOffset: Integer): Int64;
begin
  CheckBounds(AData, AOffset, SizeOf(Int64));
  Result := Int64(TConverters.ReadBytesAsUInt64LE(PByte(AData), AOffset));
end;

class function TBinaryPrimitives.ReadSingleLittleEndian(const AData: TBytes; AOffset: Integer): Single;
var
  bits: UInt32;
begin
  CheckBounds(AData, AOffset, SizeOf(Single));
  bits := TConverters.ReadBytesAsUInt32LE(PByte(AData), AOffset);
  Move(bits, Result, SizeOf(Single));
end;

class function TBinaryPrimitives.ReadDoubleLittleEndian(const AData: TBytes; AOffset: Integer): Double;
var
  bits: UInt64;
begin
  CheckBounds(AData, AOffset, SizeOf(Double));
  bits := TConverters.ReadBytesAsUInt64LE(PByte(AData), AOffset);
  Move(bits, Result, SizeOf(Double));
end;

class function TBinaryPrimitives.ReadUInt16BigEndian(const AData: TBytes; AOffset: Integer): UInt16;
begin
  CheckBounds(AData, AOffset, SizeOf(UInt16));
  Result := ReadBytesAsUInt16BEInternal(AData, AOffset);
end;

class function TBinaryPrimitives.ReadUInt32BigEndian(const AData: TBytes; AOffset: Integer): UInt32;
begin
  CheckBounds(AData, AOffset, SizeOf(UInt32));
  Result := TConverters.ReadBytesAsUInt32BE(PByte(AData), AOffset);
end;

class function TBinaryPrimitives.ReadUInt64BigEndian(const AData: TBytes; AOffset: Integer): UInt64;
begin
  CheckBounds(AData, AOffset, SizeOf(UInt64));
  Result := TConverters.ReadBytesAsUInt64BE(PByte(AData), AOffset);
end;

class function TBinaryPrimitives.ReadInt16BigEndian(const AData: TBytes; AOffset: Integer): Int16;
begin
  CheckBounds(AData, AOffset, SizeOf(Int16));
  Result := Int16(ReadBytesAsUInt16BEInternal(AData, AOffset));
end;

class function TBinaryPrimitives.ReadInt32BigEndian(const AData: TBytes; AOffset: Integer): Int32;
begin
  CheckBounds(AData, AOffset, SizeOf(Int32));
  Result := Int32(TConverters.ReadBytesAsUInt32BE(PByte(AData), AOffset));
end;

class function TBinaryPrimitives.ReadInt64BigEndian(const AData: TBytes; AOffset: Integer): Int64;
begin
  CheckBounds(AData, AOffset, SizeOf(Int64));
  Result := Int64(TConverters.ReadBytesAsUInt64BE(PByte(AData), AOffset));
end;

class function TBinaryPrimitives.ReadSingleBigEndian(const AData: TBytes; AOffset: Integer): Single;
var
  bits: UInt32;
begin
  CheckBounds(AData, AOffset, SizeOf(Single));
  bits := TConverters.ReadBytesAsUInt32BE(PByte(AData), AOffset);
  Move(bits, Result, SizeOf(Single));
end;

class function TBinaryPrimitives.ReadDoubleBigEndian(const AData: TBytes; AOffset: Integer): Double;
var
  bits: UInt64;
begin
  CheckBounds(AData, AOffset, SizeOf(Double));
  bits := TConverters.ReadBytesAsUInt64BE(PByte(AData), AOffset);
  Move(bits, Result, SizeOf(Double));
end;

end.
