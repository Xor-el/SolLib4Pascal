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

unit SlpSerialization;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  ClpBigInteger,
  SlpArrayUtils,
  SlpPublicKey,
  SlpBinaryPrimitives;

type
  /// <summary>
  /// Methods for serialization of program data using <see cref="TBytes"/>.
  /// </summary>
  TSerialization = class
  private
    class procedure CheckBounds(const AData: TBytes; AOffset, ASize: Integer); static; inline;
  public
    /// <summary>
    /// Write a 8-bit unsigned integer to the byte array at the given offset.
    /// </summary>
    /// <param name="AData">The byte array to write data to.</param>
    /// <param name="AValue">The 8-bit unsigned integer value to write.</param>
    /// <param name="AOffset">The offset at which to write the 8-bit unsigned integer.</param>
    /// <exception cref="EArgumentOutOfRangeException">Thrown when the offset is too big for the data array.</exception>
    class procedure WriteU8(var AData: TBytes; AValue: Byte; AOffset: Integer); static;
    /// <summary>
    /// Write a boolean to the byte array at the given offset.
    /// </summary>
    /// <param name="AData">The byte array to write data to.</param>
    /// <param name="AValue">The boolean value to write.</param>
    /// <param name="AOffset">The offset at which to write the 8-bit unsigned integer.</param>
    /// <exception cref="EArgumentOutOfRangeException">Thrown when the offset is too big for the data array.</exception>
    class procedure WriteBool(var AData: TBytes; AValue: Boolean; AOffset: Integer); static;
    /// <summary>
    /// Write a 16-bit unsigned integer to the byte array at the given offset.
    /// </summary>
    /// <param name="AData">The byte array to write data to.</param>
    /// <param name="AValue">The 16-bit unsigned integer value to write.</param>
    /// <param name="AOffset">The offset at which to write the 16-bit unsigned integer.</param>
    /// <exception cref="EArgumentOutOfRangeException">Thrown when the offset is too big for the data array.</exception>
    class procedure WriteU16(var AData: TBytes; AValue: Word; AOffset: Integer); static;
    /// <summary>
    /// Write a 32-bit unsigned integer to the byte array at the given offset.
    /// </summary>
    /// <param name="AData">The byte array to write data to.</param>
    /// <param name="AValue">The 32-bit unsigned integer value to write.</param>
    /// <param name="AOffset">The offset at which to write the 32-bit unsigned integer.</param>
    /// <exception cref="EArgumentOutOfRangeException">Thrown when the offset is too big for the data array.</exception>
    class procedure WriteU32(var AData: TBytes; AValue: UInt32; AOffset: Integer); static;
    /// <summary>
    /// Write a 64-bit unsigned integer to the byte array at the given offset.
    /// </summary>
    /// <param name="AData">The byte array to write data to.</param>
    /// <param name="AValue">The 64-bit unsigned integer value to write.</param>
    /// <param name="AOffset">The offset at which to write the 64-bit unsigned integer.</param>
    /// <exception cref="EArgumentOutOfRangeException">Thrown when the offset is too big for the data array.</exception>
    class procedure WriteU64(var AData: TBytes; AValue: UInt64; AOffset: Integer); static;
    /// <summary>
    /// Write a 8-bit signed integer to the byte array at the given offset.
    /// </summary>
    /// <param name="AData">The byte array to write data to.</param>
    /// <param name="AValue">The 8-bit signed integer value to write.</param>
    /// <param name="AOffset">The offset at which to write the 8-bit signed integer.</param>
    /// <exception cref="EArgumentOutOfRangeException">Thrown when the offset is too big for the data array.</exception>
    class procedure WriteS8(var AData: TBytes; AValue: ShortInt; AOffset: Integer); static;
    /// <summary>
    /// Write a 16-bit signed integer to the byte array at the given offset.
    /// </summary>
    /// <param name="AData">The byte array to write data to.</param>
    /// <param name="AValue">The 16-bit signed integer value to write.</param>
    /// <param name="AOffset">The offset at which to write the 16-bit signed integer.</param>
    /// <exception cref="EArgumentOutOfRangeException">Thrown when the offset is too big for the data array.</exception>
    class procedure WriteS16(var AData: TBytes; AValue: SmallInt; AOffset: Integer); static;
    /// <summary>
    /// Write a 32-bit signed integer to the byte array at the given offset.
    /// </summary>
    /// <param name="AData">The byte array to write data to.</param>
    /// <param name="AValue">The 32-bit signed integer value to write.</param>
    /// <param name="AOffset">The offset at which to write the 32-bit signed integer.</param>
    /// <exception cref="EArgumentOutOfRangeException">Thrown when the offset is too big for the data array.</exception>
    class procedure WriteS32(var AData: TBytes; AValue: Int32; AOffset: Integer); static;
    /// <summary>
    /// Write a 64-bit signed integer to the byte array at the given offset.
    /// </summary>
    /// <param name="AData">The byte array to write data to.</param>
    /// <param name="AValue">The 64-bit signed integer value to write.</param>
    /// <param name="AOffset">The offset at which to write the 64-bit signed integer.</param>
    /// <exception cref="EArgumentOutOfRangeException">Thrown when the offset is too big for the data array.</exception>
    class procedure WriteS64(var AData: TBytes; AValue: Int64; AOffset: Integer); static;
    /// <summary>
    /// Write a single-precision floating-point value to the byte array at the given offset.
    /// </summary>
    /// <param name="AData">The byte array to write data to.</param>
    /// <param name="AValue">The <see cref="single"/> to write.</param>
    /// <param name="AOffset">The offset at which to write the <see cref="float"/>.</param>
    /// <exception cref="EArgumentOutOfRangeException">Thrown when the offset is too big for the data array.</exception>
    class procedure WriteSingle(var AData: TBytes; AValue: Single; AOffset: Integer); static;
    /// <summary>
    /// Write a double-precision floating-point value to the byte array at the given offset.
    /// </summary>
    /// <param name="AData">The byte array to write data to.</param>
    /// <param name="AValue">The <see cref="double"/> to write.</param>
    /// <param name="AOffset">The offset at which to write the <see cref="double"/>.</param>
    /// <exception cref="EArgumentOutOfRangeException">Thrown when the offset is too big for the data array.</exception>
    class procedure WriteDouble(var AData: TBytes; AValue: Double; AOffset: Integer); static;

    /// <summary>
    /// Write a span of bytes to the byte array at the given offset.
    /// </summary>
    /// <param name="AData">The byte array to write data to.</param>
    /// <param name="ASrcSpan">The <see cref="TBytes"/> to write.</param>
    /// <param name="AOffset">The offset at which to write the <see cref="TBytes"/>.</param>
    /// <exception cref="EArgumentOutOfRangeException">Thrown when the offset is too big for the data array.</exception>
    class procedure WriteSpan(var AData: TBytes; const ASrcSpan: TBytes; AOffset: Integer); static;
    /// <summary>
    /// Write a <see cref="PublicKey"/> encoded as a 32 byte array to the byte array at the given offset.
    /// </summary>
    /// <param name="AData">The byte array to write data to.</param>
    /// <param name="APublicKey">The <see cref="PublicKey"/> to write.</param>
    /// <param name="AOffset">The offset at which to write the <see cref="PublicKey"/>.</param>
    /// <exception cref="EArgumentOutOfRangeException">Thrown when the offset is too big for the data array.</exception>
    class procedure WritePubKey(var AData: TBytes; const APubKey: IPublicKey; AOffset: Integer); static;
    /// <summary>
    /// Write an arbitrarily long number to the byte array at the given offset, specifying it's length in bytes.
    /// Optionally specify if it's signed and the endianness.
    /// </summary>
    /// <param name="AData">The byte array to write data to.</param>
    /// <param name="AValue">The <see cref="BigInteger"/> to write.</param>
    /// <param name="AOffset">The offset at which to write the <see cref="BigInteger"/>.</param>
    /// <param name="ALength">The length in bytes.</param>
    /// <param name="AIsUnsigned">Whether the value does not use signed encoding.</param>
    /// <param name="AIsBigEndian">Whether the value is in big-endian byte order.</param>
    /// <returns>An integer representing the number of bytes written to the byte array.</returns>
    /// <exception cref="EArgumentOutOfRangeException">Thrown when the offset is too big for the data array.</exception>
    class function WriteBigInt(var AData: TBytes; const AValue: TBigInteger;
      AOffset, ALength: Integer; AIsUnsigned: Boolean = False;
      AIsBigEndian: Boolean = False): Integer; static;

    /// <summary>
    /// Write a UTF8 string value to the byte array at the given offset.
    /// </summary>
    /// <param name="AData">The byte array to write data to.</param>
    /// <param name="AValue">The <see cref="string"/> to write.</param>
    /// <param name="AOffset">The offset at which to write the <see cref="string"/>.</param>
    /// <returns>Returns the number of bytes written.</returns>
    class function WriteBorshString(var AData: TBytes; const AValue: String; AOffset: Integer): Integer; static;
    /// <summary>
    /// Write a UTF8 byte vector to the byte array at the given offset.
    /// </summary>
    /// <param name="AData"></param>
    /// <param name="ABuffer"></param>
    /// <param name="AOffset"></param>
    /// <returns></returns>
    class function WriteBorshByteVector(var AData: TBytes; const ABuffer: TBytes; AOffset: Integer): Integer; static;
    /// <summary>
    /// Encodes a string for a transaction
    /// </summary>
    /// <param name="AData"> the string to be encoded</param>
    /// <returns></returns>
    class function EncodeBincodeString(const AData: String): TBytes; static;
  end;

implementation

{ TSerialization }

class procedure TSerialization.CheckBounds(const AData: TBytes; AOffset, ASize: Integer);
begin
  if (AOffset < 0) or (AOffset + ASize > Length(AData)) then
    raise EArgumentOutOfRangeException.Create('AOffset');
end;

class procedure TSerialization.WriteU8(var AData: TBytes; AValue: Byte; AOffset: Integer);
begin
  CheckBounds(AData, AOffset, SizeOf(Byte));
  AData[AOffset] := AValue;
end;

class procedure TSerialization.WriteBool(var AData: TBytes; AValue: Boolean; AOffset: Integer);
begin
  CheckBounds(AData, AOffset, SizeOf(Byte));
  AData[AOffset] := Ord(AValue);
end;

class procedure TSerialization.WriteU16(var AData: TBytes; AValue: Word; AOffset: Integer);
begin
  CheckBounds(AData, AOffset, SizeOf(Word));
  TBinaryPrimitives.WriteUInt16LittleEndian(AData, AOffset, AValue);
end;

class procedure TSerialization.WriteU32(var AData: TBytes; AValue: UInt32; AOffset: Integer);
begin
  CheckBounds(AData, AOffset, SizeOf(UInt32));
  TBinaryPrimitives.WriteUInt32LittleEndian(AData, AOffset, AValue);
end;

class procedure TSerialization.WriteU64(var AData: TBytes; AValue: UInt64; AOffset: Integer);
begin
  CheckBounds(AData, AOffset, SizeOf(UInt64));
  TBinaryPrimitives.WriteUInt64LittleEndian(AData, AOffset, AValue);
end;

class procedure TSerialization.WriteS8(var AData: TBytes; AValue: ShortInt; AOffset: Integer);
begin
  CheckBounds(AData, AOffset, SizeOf(ShortInt));
  AData[AOffset] := Byte(AValue);
end;

class procedure TSerialization.WriteS16(var AData: TBytes; AValue: SmallInt; AOffset: Integer);
begin
  CheckBounds(AData, AOffset, SizeOf(SmallInt));
  TBinaryPrimitives.WriteInt16LittleEndian(AData, AOffset, AValue);
end;

class procedure TSerialization.WriteS32(var AData: TBytes; AValue: Int32; AOffset: Integer);
begin
  CheckBounds(AData, AOffset, SizeOf(Int32));
  TBinaryPrimitives.WriteInt32LittleEndian(AData, AOffset, AValue);
end;

class procedure TSerialization.WriteS64(var AData: TBytes; AValue: Int64; AOffset: Integer);
begin
  CheckBounds(AData, AOffset, SizeOf(Int64));
  TBinaryPrimitives.WriteInt64LittleEndian(AData, AOffset, AValue);
end;

class procedure TSerialization.WriteSingle(var AData: TBytes; AValue: Single; AOffset: Integer);
begin
  CheckBounds(AData, AOffset, SizeOf(Single));
  TBinaryPrimitives.WriteSingleLittleEndian(AData, AOffset, AValue);
end;

class procedure TSerialization.WriteDouble(var AData: TBytes; AValue: Double; AOffset: Integer);
begin
  CheckBounds(AData, AOffset, SizeOf(Double));
  TBinaryPrimitives.WriteDoubleLittleEndian(AData, AOffset, AValue);
end;

class procedure TSerialization.WriteSpan(var AData: TBytes; const ASrcSpan: TBytes; AOffset: Integer);
begin
  CheckBounds(AData, AOffset, Length(ASrcSpan));
  TArrayUtils.Copy<Byte>(ASrcSpan, 0, AData, AOffset, Length(ASrcSpan));
end;

class procedure TSerialization.WritePubKey(var AData: TBytes; const APubKey: IPublicKey; AOffset: Integer);
var
 LPubKeyBytes: TBytes;
begin
  LPubKeyBytes := APubKey.KeyBytes;
  CheckBounds(AData, AOffset, Length(LPubKeyBytes));
  TArrayUtils.Copy<Byte>(LPubKeyBytes, 0, AData, AOffset, Length(LPubKeyBytes));
end;

class function TSerialization.WriteBigInt(var AData: TBytes; const AValue: TBigInteger;
  AOffset, ALength: Integer; AIsUnsigned: Boolean; AIsBigEndian: Boolean): Integer;
var
  Src     : TBytes;
  I, ByteCnt, Written : Integer;
begin
  if AIsUnsigned then
    Src := AValue.ToByteArrayUnsigned
  else
    Src := AValue.ToByteArray;

  ByteCnt := Length(Src);

  if ByteCnt > ALength then
    raise EArgumentOutOfRangeException.Create('BigInt too big.');
  if (AOffset + ALength) > Length(AData) then
    raise EArgumentOutOfRangeException.Create('offset');

  // Copy minimal bytes starting at AOffset in the requested endianness
  if ByteCnt > 0 then
  begin
    if AIsBigEndian then
    begin
      // keep big-endian order
      TArrayUtils.Copy<Byte>(Src, 0, AData, AOffset, ByteCnt);
    end
    else
    begin
      // little-endian: reverse while copying
      for I := 0 to ByteCnt - 1 do
        AData[AOffset + I] := Src[ByteCnt - 1 - I];
    end;
  end;

  Written := ByteCnt;

  // If signed and negative, pad remaining up to ALength with 0xFF (two's-complement sign extension)
  if (not AIsUnsigned) and (AValue.SignValue < 0) then
  begin
    I := Written;
    while I < ALength do
    begin
      AData[AOffset + I] := $FF;
      Inc(I);
    end;
  end;

  Result := Written;
end;

class function TSerialization.WriteBorshString(var AData: TBytes; const AValue: String; AOffset: Integer): Integer;
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.UTF8.GetBytes(AValue);

  if (AOffset + SizeOf(UInt32) + Length(Bytes)) > Length(AData) then
    raise EArgumentOutOfRangeException.Create('AOffset');

  WriteU32(AData, UInt32(Length(Bytes)), AOffset);
  WriteSpan(AData, Bytes, AOffset + SizeOf(UInt32));
  Result := Length(Bytes) + SizeOf(UInt32);
end;

class function TSerialization.WriteBorshByteVector(var AData: TBytes; const ABuffer: TBytes; AOffset: Integer): Integer;
begin
  WriteU64(AData, UInt64(Length(ABuffer)), AOffset);
  WriteSpan(AData, ABuffer, AOffset + SizeOf(UInt64));
  Result := SizeOf(UInt64) + Length(ABuffer);
end;

class function TSerialization.EncodeBincodeString(const AData: String): TBytes;
var
  StrBytes: TBytes;
begin
  StrBytes := TEncoding.UTF8.GetBytes(AData);
  SetLength(Result, Length(StrBytes) + SizeOf(UInt64));
  WriteU64(Result, UInt64(Length(StrBytes)), 0);
  WriteSpan(Result, StrBytes, 8);
end;

end.

