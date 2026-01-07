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

unit SlpDeserialization;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  SlpBinaryPrimitives,
  SlpArrayUtils,
  SlpPublicKey;

type
  /// <summary>
  /// Return type for bincode string decoding: the decoded string and the total length consumed.
  /// </summary>
  TDecodedBincodeString = record
    EncodedString: string;
    Length: Integer;
  end;

  /// <summary>
  /// Methods for deserializing from <c>TBytes</c> with offset checks.
  /// </summary>
  TDeserialization = class
  private
    /// <summary>
    /// Ensures that <paramref name="AOffset"/>..<paramref name="AOffset"/>+<paramref name="ANeedLen"/>-1
    /// lies within <paramref name="AData"/>; otherwise raises <see cref="EArgumentOutOfRangeException"/>
    /// with parameter name "AOffset".
    /// </summary>
    class procedure CheckBounds(const AData: TBytes; AOffset, ANeedLen: Integer); static;

  public
    /// <summary>
    /// Get an 8-bit unsigned integer from the buffer at the given offset.
    /// </summary>
    /// <param name="AData">The buffer to read from.</param>
    /// <param name="AOffset">The offset at which the 8-bit unsigned integer begins.</param>
    class function GetU8(const AData: TBytes; AOffset: Integer): Byte; static;

    /// <summary>
    /// Get a 16-bit unsigned integer from the buffer at the given offset (little-endian).
    /// </summary>
    /// <param name="AData">The buffer to read from.</param>
    /// <param name="AOffset">The offset at which the 16-bit unsigned integer begins.</param>
    class function GetU16(const AData: TBytes; AOffset: Integer): Word; static;

    /// <summary>
    /// Get a 32-bit unsigned integer from the buffer at the given offset (little-endian).
    /// </summary>
    /// <param name="AData">The buffer to read from.</param>
    /// <param name="AOffset">The offset at which the 32-bit unsigned integer begins.</param>
    class function GetU32(const AData: TBytes; AOffset: Integer): Cardinal; static;

    /// <summary>
    /// Get a 64-bit unsigned integer from the buffer at the given offset (little-endian).
    /// </summary>
    /// <param name="AData">The buffer to read from.</param>
    /// <param name="AOffset">The offset at which the 64-bit unsigned integer begins.</param>
    class function GetU64(const AData: TBytes; AOffset: Integer): UInt64; static;

    /// <summary>
    /// Get an 8-bit signed integer from the buffer at the given offset.
    /// </summary>
    /// <param name="AData">The buffer to read from.</param>
    /// <param name="AOffset">The offset at which the 8-bit signed integer begins.</param>
    class function GetS8(const AData: TBytes; AOffset: Integer): ShortInt; static;

    /// <summary>
    /// Get a 16-bit signed integer from the buffer at the given offset (little-endian).
    /// </summary>
    /// <param name="AData">The buffer to read from.</param>
    /// <param name="AOffset">The offset at which the 16-bit signed integer begins.</param>
    class function GetS16(const AData: TBytes; AOffset: Integer): SmallInt; static;

    /// <summary>
    /// Get a 32-bit signed integer from the buffer at the given offset (little-endian).
    /// </summary>
    /// <param name="AData">The buffer to read from.</param>
    /// <param name="AOffset">The offset at which the 32-bit signed integer begins.</param>
    class function GetS32(const AData: TBytes; AOffset: Integer): Integer; static;

    /// <summary>
    /// Get a 64-bit signed integer from the buffer at the given offset (little-endian).
    /// </summary>
    /// <param name="AData">The buffer to read from.</param>
    /// <param name="AOffset">The offset at which the 64-bit signed integer begins.</param>
    class function GetS64(const AData: TBytes; AOffset: Integer): Int64; static;

    /// <summary>
    /// Get a subarray from the buffer at the given offset with the given length.
    /// </summary>
    /// <param name="AData">The buffer to read from.</param>
    /// <param name="AOffset">The offset at which the desired span begins.</param>
    /// <param name="ALen">The desired length for the new span.</param>
    class function GetSpan(const AData: TBytes; AOffset, ALen: Integer): TBytes; static;

    /// <summary>
    /// Get a <see cref="TPublicKey"/> encoded as a 32-byte array from the buffer at the given offset.
    /// </summary>
    /// <param name="AData">The buffer to read from.</param>
    /// <param name="AOffset">The offset at which the public key begins.</param>
    class function GetPubKey(const AData: TBytes; AOffset: Integer): IPublicKey; static;

    /// <summary>
    /// Get a double-precision floating-point number from the buffer (little-endian).
    /// </summary>
    /// <param name="AData">The buffer to read from.</param>
    /// <param name="AOffset">The offset at which the value begins.</param>
    class function GetDouble(const AData: TBytes; AOffset: Integer): Double; static;

    /// <summary>
    /// Get a single-precision floating-point number from the buffer (little-endian).
    /// </summary>
    /// <param name="AData">The buffer to read from.</param>
    /// <param name="AOffset">The offset at which the value begins.</param>
    class function GetSingle(const AData: TBytes; AOffset: Integer): Single; static;

    /// <summary>
    /// Get a boolean value from the buffer at the given offset.
    /// </summary>
    /// <param name="AData">The buffer to read from.</param>
    /// <param name="AOffset">The offset at which the boolean value is located.</param>
    class function GetBool(const AData: TBytes; AOffset: Integer): Boolean; static;

    /// <summary>
    /// Decode a bincode-encoded string (u64 length + UTF-8 bytes).
    /// </summary>
    /// <param name="AData">The buffer to decode from.</param>
    /// <param name="AOffset">The offset at which the string begins.</param>
    class function DecodeBincodeString(const AData: TBytes; AOffset: Integer): TDecodedBincodeString; static;

    /// <summary>
    /// Decode a BORSH-encoded string (u32 length + UTF-8 bytes).
    /// </summary>
    /// <param name="AData">The buffer to decode from.</param>
    /// <param name="AOffset">The offset at which the string begins.</param>
    /// <param name="AResultStr">The decoded string.</param>
    class function GetBorshString(const AData: TBytes; AOffset: Integer; out AResultStr: string): Integer; static;

    /// <summary>
    /// Get a subarray from the buffer at the given offset and length.
    /// </summary>
    /// <param name="AData">The buffer to read from.</param>
    /// <param name="AOffset">The offset where the data begins.</param>
    /// <param name="ALen">The number of bytes to copy.</param>
    class function GetBytes(const AData: TBytes; AOffset, ALen: Integer): TBytes; static;
  end;

implementation

{ TDeserialization }

class procedure TDeserialization.CheckBounds(const AData: TBytes; AOffset, ANeedLen: Integer);
begin
  if (AOffset < 0) or (ANeedLen < 0) or (AOffset + ANeedLen > Length(AData)) then
    raise EArgumentOutOfRangeException.Create('AOffset');
end;

class function TDeserialization.GetU8(const AData: TBytes; AOffset: Integer): Byte;
begin
  CheckBounds(AData, AOffset, SizeOf(Byte));
  Result := AData[AOffset];
end;

class function TDeserialization.GetU16(const AData: TBytes; AOffset: Integer): Word;
begin
  CheckBounds(AData, AOffset, SizeOf(Word));
  Result := TBinaryPrimitives.ReadUInt16LittleEndian(AData, AOffset);
end;

class function TDeserialization.GetU32(const AData: TBytes; AOffset: Integer): Cardinal;
begin
  CheckBounds(AData, AOffset, SizeOf(Cardinal));
  Result := TBinaryPrimitives.ReadUInt32LittleEndian(AData, AOffset);
end;

class function TDeserialization.GetU64(const AData: TBytes; AOffset: Integer): UInt64;
begin
  CheckBounds(AData, AOffset, SizeOf(UInt64));
  Result := TBinaryPrimitives.ReadUInt64LittleEndian(AData, AOffset);
end;

class function TDeserialization.GetS8(const AData: TBytes; AOffset: Integer): ShortInt;
begin
  CheckBounds(AData, AOffset, SizeOf(ShortInt));
  Result := ShortInt(AData[AOffset]);
end;

class function TDeserialization.GetS16(const AData: TBytes; AOffset: Integer): SmallInt;
begin
  CheckBounds(AData, AOffset, SizeOf(SmallInt));
  Result := TBinaryPrimitives.ReadInt16LittleEndian(AData, AOffset);
end;

class function TDeserialization.GetS32(const AData: TBytes; AOffset: Integer): Integer;
begin
  CheckBounds(AData, AOffset, SizeOf(Integer));
  Result := TBinaryPrimitives.ReadInt32LittleEndian(AData, AOffset);
end;

class function TDeserialization.GetS64(const AData: TBytes; AOffset: Integer): Int64;
begin
  CheckBounds(AData, AOffset, SizeOf(Int64));
  Result := TBinaryPrimitives.ReadInt64LittleEndian(AData, AOffset);
end;

class function TDeserialization.GetSpan(const AData: TBytes; AOffset, ALen: Integer): TBytes;
begin
  CheckBounds(AData, AOffset, ALen);
  Result := TArrayUtils.Slice<Byte>(AData, AOffset, ALen);
end;

class function TDeserialization.GetBytes(const AData: TBytes; AOffset, ALen: Integer): TBytes;
begin
  CheckBounds(AData, AOffset, ALen);
  Result := TArrayUtils.Slice<Byte>(AData, AOffset, ALen);
end;

class function TDeserialization.GetPubKey(const AData: TBytes; AOffset: Integer): IPublicKey;
var
  LKeyBytes: TBytes;
begin
  CheckBounds(AData, AOffset, TPublicKey.PublicKeyLength);
  LKeyBytes := TArrayUtils.Slice<Byte>(AData, AOffset, TPublicKey.PublicKeyLength);
  Result := TPublicKey.Create(LKeyBytes);
end;

class function TDeserialization.GetDouble(const AData: TBytes; AOffset: Integer): Double;
begin
  CheckBounds(AData, AOffset, SizeOf(Double));
  Result := TBinaryPrimitives.ReadDoubleLittleEndian(AData, AOffset);
end;

class function TDeserialization.GetSingle(const AData: TBytes; AOffset: Integer): Single;
begin
  CheckBounds(AData, AOffset, SizeOf(Single));
  Result := TBinaryPrimitives.ReadSingleLittleEndian(AData, AOffset);
end;

class function TDeserialization.GetBool(const AData: TBytes; AOffset: Integer): Boolean;
var
  LByte: Byte;
begin
  LByte := GetU8(AData, AOffset);
  Result := LByte = 1;
end;

class function TDeserialization.DecodeBincodeString(
  const AData: TBytes; AOffset: Integer): TDecodedBincodeString;
var
  LStringLength: Integer;
  LStringBytes: TBytes;
begin
  CheckBounds(AData, AOffset, SizeOf(UInt64));

  LStringLength := Integer(GetU64(AData, AOffset));
  LStringBytes := TArrayUtils.Slice<Byte>(AData, AOffset + SizeOf(UInt64), LStringLength);

  Result.EncodedString := TEncoding.UTF8.GetString(LStringBytes);
  Result.Length := LStringLength + SizeOf(UInt64);
end;

class function TDeserialization.GetBorshString(
  const AData: TBytes; AOffset: Integer; out AResultStr: string): Integer;
var
  LStringLength: Integer;
  LStringBytes: TBytes;
begin
  CheckBounds(AData, AOffset, SizeOf(Cardinal));

  LStringLength := Integer(GetU32(AData, AOffset));
  LStringBytes := TArrayUtils.Slice<Byte>(AData, AOffset + SizeOf(UInt32), LStringLength);
  AResultStr := TEncoding.UTF8.GetString(LStringBytes);

  Result := LStringLength + SizeOf(Cardinal);
end;

end.

