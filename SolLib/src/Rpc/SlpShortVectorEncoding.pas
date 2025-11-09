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

unit SlpShortVectorEncoding;

{$I ..\Include\SolLib.inc}

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
    class function DecodeLength(const Data: TBytes): TShortVecDecode; overload; static;

    /// <summary>
    /// Decode from a TBytes starting at StartIndex.
    /// Returns (Value, LengthConsumed).
    /// </summary>
    class function DecodeLength(const Data: TBytes; StartIndex: Integer): TShortVecDecode; overload; static;

    /// <summary>
    /// Decode from a raw buffer.
    /// Returns (Value, LengthConsumed).
    /// </summary>
    class function DecodeLength(const Data: Pointer; DataSize: NativeInt): TShortVecDecode; overload; static;
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
  Output: array[0..9] of Byte;
  RemLen: Integer;
  Cursor: Integer;
  Elem: Integer;
begin
  if ALen < 0 then
    raise EArgumentOutOfRangeException.Create('Length must be non-negative.');

  RemLen := ALen;
  Cursor := 0;

  while True do
  begin
    Elem := RemLen and $7F;
    RemLen := Cardinal(RemLen) shr 7; // logical shift

    if RemLen = 0 then
    begin
      Output[Cursor] := Byte(Elem);
      Break;
    end;

    Elem := Elem or $80;
    Output[Cursor] := Byte(Elem);
    Inc(Cursor);
  end;

  SetLength(Result, Cursor + 1);
  Move(Output[0], Result[0], Cursor + 1);
end;


class function TShortVectorEncoding.DecodeLength(const Data: TBytes): TShortVecDecode;
begin
  Result := DecodeLength(Data, 0);
end;

class function TShortVectorEncoding.DecodeLength(
  const Data: TBytes; StartIndex: Integer): TShortVecDecode;
var
  P: Pointer;
  Size: NativeInt;
begin
  if (StartIndex < 0) or (StartIndex >= Length(Data)) then
    Exit(TShortVecDecode.Make(0, 0));

  // Pointer to the start index inside the byte array
  P := @Data[StartIndex];

  // Remaining bytes from StartIndex to end
  Size := Length(Data) - StartIndex;

  // Delegate to the pointer-based implementation
  Result := DecodeLength(P, Size);
end;

class function TShortVectorEncoding.DecodeLength(const Data: Pointer; DataSize: NativeInt): TShortVecDecode;
var
  P: PByte;
  Elem: Byte;
  Value, Size: Integer;
begin
  Value := 0;
  Size := 0;

  if (Data = nil) or (DataSize <= 0) then
    Exit(TShortVecDecode.Make(0, 0));

  P := PByte(Data);

  while Size < DataSize do
  begin
    Elem := P^;
    Value := Value or ((Elem and $7F) shl (Size * 7));
    Inc(Size);
    Inc(P);

    if (Elem and $80) = 0 then
      Break;
  end;

  Result := TShortVecDecode.Make(Value, Size);
end;

end.

