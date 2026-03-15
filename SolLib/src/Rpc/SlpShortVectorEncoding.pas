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

unit SlpShortVectorEncoding;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils;

type
  /// <summary>
  /// Result for compact length decoding (Value + bytes consumed).
  /// </summary>
  TShortVecDecode = record
    Value: Integer;
    Length: Integer;
    class function Make(AValue, ALength: Integer): TShortVecDecode; static;
  end;

  /// <summary>
  /// Implements Solana's short vector (compact-u16/varint) length encoding.
  /// </summary>
  TShortVectorEncoding = class sealed
  public
    /// <summary>
    /// The length of the compact-u16 multi-byte encoding.
    /// </summary>
    const SpanLength = 3;

    /// <summary>
    /// Encodes the number of account keys present in the transaction as a short vector, see remarks.
    /// <remarks>
    /// See the documentation for more information on this encoding:
    /// https://docs.solana.com/developing/programming-model/transactions#compact-array-format
    /// </remarks>
    /// </summary>
    /// <param name="len">The number of account keys present in the transaction.</param>
    /// <returns>The short vector encoded data.</returns>
    class function EncodeLength(ALen: Integer): TBytes; static;

    /// <summary>
    /// Decodes the number of account keys present in the transaction following a specific format.
    /// <remarks>
    /// See the documentation for more information on this encoding:
    /// https://docs.solana.com/developing/programming-model/transactions#compact-array-format
    /// </remarks>
    /// </summary>
    /// <param name="data">The short vector encoded data.</param>
    /// <returns>The number of account keys present in the transaction.</returns>
    class function DecodeLength(const AData: TBytes): TShortVecDecode; overload; static;

    /// <summary>
    /// Decode from a TBytes starting at StartIndex.
    /// Returns (Value, LengthConsumed).
    /// </summary>
    class function DecodeLength(const AData: TBytes; AStartIndex: Integer): TShortVecDecode; overload; static;

    /// <summary>
    /// Decode from a raw buffer.
    /// Returns (Value, LengthConsumed).
    /// </summary>
    class function DecodeLength(const AData: Pointer; ADataSize: NativeInt): TShortVecDecode; overload; static;
  end;

implementation

{ TShortVecDecode }

class function TShortVecDecode.Make(AValue, ALength: Integer): TShortVecDecode;
begin
  Result.Value := AValue;
  Result.Length := ALength;
end;

{ TShortVectorEncoding }

class function TShortVectorEncoding.EncodeLength(ALen: Integer): TBytes;
var
  LOutput: array[0..9] of Byte;
  LRemLen: Integer;
  LCursor: Integer;
  LElem: Integer;
begin
  if ALen < 0 then
    raise EArgumentOutOfRangeException.Create('Length must be non-negative.');

  LRemLen := ALen;
  LCursor := 0;

  while True do
  begin
    LElem := LRemLen and $7F;
    LRemLen := Cardinal(LRemLen) shr 7; // logical shift

    if LRemLen = 0 then
    begin
      LOutput[LCursor] := Byte(LElem);
      Break;
    end;

    LElem := LElem or $80;
    LOutput[LCursor] := Byte(LElem);
    Inc(LCursor);
  end;

  SetLength(Result, LCursor + 1);
  Move(LOutput[0], Result[0], LCursor + 1);
end;


class function TShortVectorEncoding.DecodeLength(const AData: TBytes): TShortVecDecode;
begin
  Result := DecodeLength(AData, 0);
end;

class function TShortVectorEncoding.DecodeLength(
  const AData: TBytes; AStartIndex: Integer): TShortVecDecode;
var
  LP: Pointer;
  LSize: NativeInt;
begin
  if (AStartIndex < 0) or (AStartIndex >= Length(AData)) then
    Exit(TShortVecDecode.Make(0, 0));

  // Pointer to the start index inside the byte array
  LP := @AData[AStartIndex];

  // Remaining bytes from StartIndex to end
  LSize := Length(AData) - AStartIndex;

  // Delegate to the pointer-based implementation
  Result := DecodeLength(LP, LSize);
end;

class function TShortVectorEncoding.DecodeLength(const AData: Pointer; ADataSize: NativeInt): TShortVecDecode;
var
  LP: PByte;
  LElem: Byte;
  LDecodedValue, LDecodedSize: Integer;
begin
  LDecodedValue := 0;
  LDecodedSize := 0;

  if (AData = nil) or (ADataSize <= 0) then
    Exit(TShortVecDecode.Make(0, 0));

  LP := PByte(AData);

  while LDecodedSize < ADataSize do
  begin
    LElem := LP^;
    LDecodedValue := LDecodedValue or ((LElem and $7F) shl (LDecodedSize * 7));
    Inc(LDecodedSize);
    Inc(LP);

    if (LElem and $80) = 0 then
      Break;
  end;

  Result := TShortVecDecode.Make(LDecodedValue, LDecodedSize);
end;

end.

