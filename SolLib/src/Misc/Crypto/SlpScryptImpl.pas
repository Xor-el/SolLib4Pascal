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

unit SlpScryptImpl;

{$I ..\..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  ClpBits;

type
  TScryptImpl = class sealed
  private
    class function SingleIterationPbkdf2(const P, S: TBytes; DKLen: Integer): TBytes; static;
    /// <summary>
    /// Copies a specified number of bytes from a source pointer to a destination pointer.
    /// </summary>
    class procedure BulkCopy(Dst, Src: Pointer; Len: NativeInt); static;
    /// <summary>
    /// Copies a specified number of bytes from a source pointer to a destination pointer.
    /// </summary>
    class procedure BulkXor(Dst, Src: Pointer; Len: NativeInt); static;
    /// <summary>
    /// Encode an integer to byte array on any alignment in little endian format.
    /// </summary>
    class procedure Encode32(P: PByte; X: Cardinal); static;
    /// <summary>
    /// Decode an integer from byte array on any alignment in little endian format.
    /// </summary>
    class function  Decode32(P: PByte): Cardinal; static;
    class function  RotateLeft32(A: Cardinal; B: Integer): Cardinal; static; inline;
    /// <summary>
    /// Apply the salsa20/8 core to the provided block.
    /// </summary>
    class procedure Salsa208(B: PCardinal); static;
    /// <summary>
    /// Compute Bout = BlockMix_{salsa20/8, r}(Bin).  The input Bin must be 128r
    /// bytes in length; the output Bout must also be the same size.
    /// The temporary space X must be 64 bytes.
    /// </summary>
    class procedure BlockMix(Bin, Bout, X: PCardinal; RoundsR: Integer); static;
    /// <summary>
    /// Return the result of parsing B_{2r-1} as a little-endian integer.
    /// </summary>
    class function  Integerify(B: PCardinal; RoundsR: Integer): UInt64; static;
    /// <summary>
    /// Compute B = SMix_r(B, N).  The input B must be 128r bytes in length;
    /// the temporary storage V must be 128rN bytes in length; the temporary
    /// storage XY must be 256r + 64 bytes in length.  The value N must be a
    /// power of 2 greater than 1.  The arrays B, V, and XY must be aligned to a
    /// multiple of 64 bytes.
    /// </summary>
    class procedure SMix(B: PByte; RoundsR, N: Integer; V, XY: PCardinal); static;
  public
    class function DeriveKey(const Password, Salt: TBytes;
      N, RoundsR, PCount, DKLen: Integer): TBytes; static;
  end;

implementation

 uses
  SlpCryptoUtils;

{ TScryptImpl }

class procedure TScryptImpl.BulkCopy(Dst, Src: Pointer; Len: NativeInt);
begin
  Move(Src^, Dst^, Len);
end;

class procedure TScryptImpl.BulkXor(Dst, Src: Pointer; Len: NativeInt);
var
  d, s: PByte;
  L: NativeInt;
begin
  d := Dst; s := Src; L := Len;
  while L >= 8 do
  begin
    PUInt64(d)^ := PUInt64(d)^ xor PUInt64(s)^;
    Inc(d, 8); Inc(s, 8); Dec(L, 8);
  end;
  if L >= 4 then
  begin
    PCardinal(d)^ := PCardinal(d)^ xor PCardinal(s)^;
    Inc(d, 4); Inc(s, 4); Dec(L, 4);
  end;
  if L >= 2 then
  begin
    PWord(d)^ := PWord(d)^ xor PWord(s)^;
    Inc(d, 2); Inc(s, 2); Dec(L, 2);
  end;
  if L >= 1 then
    d^ := d^ xor s^;
end;

class procedure TScryptImpl.Encode32(P: PByte; X: Cardinal);
begin
  P[0] := Byte(X and $FF);
  P[1] := Byte((X shr 8) and $FF);
  P[2] := Byte((X shr 16) and $FF);
  P[3] := Byte((X shr 24) and $FF);
end;

class function TScryptImpl.Decode32(P: PByte): Cardinal;
begin
  Result :=
    Cardinal(P[0]) or
    (Cardinal(P[1]) shl 8) or
    (Cardinal(P[2]) shl 16) or
    (Cardinal(P[3]) shl 24);
end;

class function TScryptImpl.RotateLeft32(A: Cardinal; B: Integer): Cardinal;
begin
  Result := TBits.RotateLeft32(A, B);
end;

class procedure TScryptImpl.Salsa208(B: PCardinal);
var
  x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15: Cardinal;
  i: Integer;
begin
  x0 := B[0];  x1 := B[1];  x2 := B[2];  x3 := B[3];
  x4 := B[4];  x5 := B[5];  x6 := B[6];  x7 := B[7];
  x8 := B[8];  x9 := B[9];  x10 := B[10]; x11 := B[11];
  x12 := B[12]; x13 := B[13]; x14 := B[14]; x15 := B[15];

  for i := 0 to 3 do
  begin
    //((x0 + x12) << 7) | ((x0 + x12) >> (32 - 7));
    // Operate on columns. //
    x4  := x4  xor RotateLeft32(x0 + x12, 7);   x8  := x8  xor RotateLeft32(x4 + x0, 9);
    x12 := x12 xor RotateLeft32(x8 + x4, 13);   x0  := x0  xor RotateLeft32(x12 + x8, 18);

    x9  := x9  xor RotateLeft32(x5 + x1, 7);    x13 := x13 xor RotateLeft32(x9 + x5, 9);
    x1  := x1  xor RotateLeft32(x13 + x9, 13);  x5  := x5  xor RotateLeft32(x1 + x13, 18);

    x14 := x14 xor RotateLeft32(x10 + x6, 7);   x2  := x2  xor RotateLeft32(x14 + x10, 9);
    x6  := x6  xor RotateLeft32(x2 + x14, 13);  x10 := x10 xor RotateLeft32(x6 + x2, 18);

    x3  := x3  xor RotateLeft32(x15 + x11, 7);  x7  := x7  xor RotateLeft32(x3 + x15, 9);
    x11 := x11 xor RotateLeft32(x7 + x3, 13);   x15 := x15 xor RotateLeft32(x11 + x7, 18);

    // Operate on rows. //
    x1  := x1  xor RotateLeft32(x0 + x3, 7);    x2  := x2  xor RotateLeft32(x1 + x0, 9);
    x3  := x3  xor RotateLeft32(x2 + x1, 13);   x0  := x0  xor RotateLeft32(x3 + x2, 18);

    x6  := x6  xor RotateLeft32(x5 + x4, 7);    x7  := x7  xor RotateLeft32(x6 + x5, 9);
    x4  := x4  xor RotateLeft32(x7 + x6, 13);   x5  := x5  xor RotateLeft32(x4 + x7, 18);

    x11 := x11 xor RotateLeft32(x10 + x9, 7);   x8  := x8  xor RotateLeft32(x11 + x10, 9);
    x9  := x9  xor RotateLeft32(x8 + x11, 13);  x10 := x10 xor RotateLeft32(x9 + x8, 18);

    x12 := x12 xor RotateLeft32(x15 + x14, 7);  x13 := x13 xor RotateLeft32(x12 + x15, 9);
    x14 := x14 xor RotateLeft32(x13 + x12, 13); x15 := x15 xor RotateLeft32(x14 + x13, 18);
  end;

  B[0]  := B[0]  + x0;   B[1]  := B[1]  + x1;   B[2]  := B[2]  + x2;   B[3]  := B[3]  + x3;
  B[4]  := B[4]  + x4;   B[5]  := B[5]  + x5;   B[6]  := B[6]  + x6;   B[7]  := B[7]  + x7;
  B[8]  := B[8]  + x8;   B[9]  := B[9]  + x9;   B[10] := B[10] + x10;  B[11] := B[11] + x11;
  B[12] := B[12] + x12;  B[13] := B[13] + x13;  B[14] := B[14] + x14;  B[15] := B[15] + x15;
end;

class procedure TScryptImpl.BlockMix(Bin, Bout, X: PCardinal; RoundsR: Integer);
var
  i: Integer;
begin
  // X <-- B_{2r-1}
  BulkCopy(X, @Bin[(2 * RoundsR - 1) * 16], 64);

  i := 0;
  while i <= (2 * RoundsR - 1) do
  begin
    // even half  (i even)
    BulkXor(X, @Bin[i * 16], 64);
    Salsa208(X);
    // Y_even -> Bout[(i div 2) * 16]
    BulkCopy(@Bout[(i div 2) * 16], X, 64);

    Inc(i);
    if i >= 2 * RoundsR then Break;

    // odd half   (i odd, i is the next block)
    BulkXor(X, @Bin[i * 16], 64);
    Salsa208(X);
    // Y_odd -> Bout[r*16 + (i div 2) * 16]
    BulkCopy(@Bout[RoundsR * 16 + (i div 2) * 16], X, 64);

    Inc(i);
  end;
end;

class function TScryptImpl.Integerify(B: PCardinal; RoundsR: Integer): UInt64;
var
  X: PCardinal;
begin
  // X points to the last 64-byte chunk (B_{2r-1})
  X := PCardinal(PByte(B) + (2 * RoundsR - 1) * 64);
  Result := (UInt64(X[1]) shl 32) or UInt64(X[0]);
end;

class procedure TScryptImpl.SMix(B: PByte; RoundsR, N: Integer; V, XY: PCardinal);
var
  X, Y, Z: PCardinal;
  i, k: Integer;
  j, idx: Integer; // j bounded to 0..N-1; idx for pointer math
begin
  X := XY;               // size >= 32 * r
  Y := @XY[32 * RoundsR];// size >= 32 * r
  Z := @XY[64 * RoundsR];// temp 16 words (64 bytes)

  // 1: X <-- B
  for k := 0 to (32 * RoundsR - 1) do
    X[k] := Decode32(@B[4 * k]);

  // 2: for i = 0..N-1 (two steps per loop)
  i := 0;
  while i < N do
  begin
    BulkCopy(@V[i * (32 * RoundsR)], X, 128 * RoundsR);
    BlockMix(X, Y, Z, RoundsR);

    Inc(i);
    BulkCopy(@V[i * (32 * RoundsR)], Y, 128 * RoundsR);
    BlockMix(Y, X, Z, RoundsR);

    Inc(i);
  end;

  // 6: for i = 0..N-1
  i := 0;
  while i < N do
  begin
    // j <- Integerify(X) mod N, bounded to 0..N-1 then cast to Integer
    j := Integer(Integerify(X, RoundsR) and UInt64(N - 1));
    idx := j * (32 * RoundsR);
    BulkXor(X, @V[idx], 128 * RoundsR);
    BlockMix(X, Y, Z, RoundsR);

    j := Integer(Integerify(Y, RoundsR) and UInt64(N - 1));
    idx := j * (32 * RoundsR);
    BulkXor(Y, @V[idx], 128 * RoundsR);
    BlockMix(Y, X, Z, RoundsR);

    Inc(i, 2);
  end;

  // 10: B' <- X
  for k := 0 to (32 * RoundsR - 1) do
    Encode32(@B[4 * k], X[k]);
end;

class function TScryptImpl.SingleIterationPbkdf2(const P, S: TBytes; DKLen: Integer): TBytes;
begin
  Result := TPbkdf2SHA256.DeriveKey(P, S, 1, DKLen);
end;

class function TScryptImpl.DeriveKey(const Password, Salt: TBytes;
  N, RoundsR, PCount, DKLen: Integer): TBytes;
var
  BA: TBytes;            // B: p * 128 * r bytes
  XY: TArray<Cardinal>;  // 64*r + 16 words (for X,Y,Z)
  V : TArray<Cardinal>;  // 32*r*N words (128*r*N bytes)
  i, BlockLen: Integer;
  Bi: PByte;
begin
  if (N <= 1) or ((N and (N - 1)) <> 0) then
    raise EArgumentException.Create('N must be > 1 and a power of 2');

  if (RoundsR <= 0) or (PCount <= 0) then
    raise EArgumentException.Create('r and p must be > 0');

  // 1: B <- PBKDF2(P, S, 1, p*128*r)
  BlockLen := 128 * RoundsR;
  BA := SingleIterationPbkdf2(Password, Salt, PCount * BlockLen);

  // temp buffers
  SetLength(XY, 32 * RoundsR * 2 + 16);   // X(32r) + Y(32r) + Z(16)
  SetLength(V,  32 * RoundsR * N);        // 32*r*N words

  // 2: for i = 0..p-1: SMix(B_i, r, N)
  for i := 0 to PCount - 1 do
  begin
    Bi := @BA[i * BlockLen];
    SMix(Bi, RoundsR, N, @V[0], @XY[0]);
  end;

  // 5: DK <- PBKDF2(P, B, 1, dkLen)
  Result := SingleIterationPbkdf2(Password, BA, DKLen);
end;

end.

