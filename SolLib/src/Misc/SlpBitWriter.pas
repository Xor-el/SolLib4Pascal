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

unit SlpBitWriter;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  /// <summary>
  /// Bit writer that supports insertion at an arbitrary Position.
  /// Internally uses TList<Boolean>.
  /// </summary>
  TBitWriter = class
  private
    FValues  : TList<Boolean>;  // bit buffer
    FPosition: Integer;         // insertion cursor (0..Count)

    function  GetCount: Integer; inline;
    class function SwapEndianBytes(const Bytes: TBytes): TBytes; static;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Current insertion cursor (0..Count).</summary>
    property Position: Integer read FPosition write FPosition;

    /// <summary>Number of bits currently stored.</summary>
    property Count: Integer read GetCount;

    /// <summary>Write a single bit at Position; Position advances by 1.</summary>
    procedure WriteBit(Value: Boolean);

    /// <summary>Write all bits from a byte array (after per-byte bit swap).</summary>
    procedure Write(const Bytes: TBytes); overload;

    /// <summary>Write first BitCount bits from a byte array (after per-byte bit swap).</summary>
    procedure Write(const Bytes: TBytes; BitCount: Integer); overload;

    /// <summary>Write first BitCount bits from a TBits instance.</summary>
    procedure Write(const Bits: TBits; BitCount: Integer); overload;

    /// <summary>Export as bytes (packs little-endian bits per byte, then swaps per-byte bit order back).</summary>
    function ToBytes: TBytes;

    /// <summary>Export as TBits. Caller owns the result and must Free it.</summary>
    function ToBitArray: TBits;

    /// <summary>Export as array of 11-bit integers (BIP-39 style grouping).</summary>
    function ToIntegers: TArray<Integer>;

    /// <summary>Convert any TBits to 11-bit integers.</summary>
    class function ToIntegersFromBits(const Bits: TBits): TArray<Integer>; static;

    /// <summary>Human-readable bit dump with spaces every 8 bits.</summary>
    function ToString: string; override;
  end;

implementation

{ TBitWriter }

constructor TBitWriter.Create;
begin
  inherited Create;
  FValues   := TList<Boolean>.Create;
  FPosition := 0;
end;

destructor TBitWriter.Destroy;
begin
  if Assigned(FValues) then
    FValues.Free;
  inherited;
end;

function TBitWriter.GetCount: Integer;
begin
  Result := FValues.Count;
end;

procedure TBitWriter.WriteBit(Value: Boolean);
begin
  if (FPosition < 0) or (FPosition > FValues.Count) then
    raise ERangeError.Create('Position out of range');
  FValues.Insert(FPosition, Value);
  Inc(FPosition);
end;

procedure TBitWriter.Write(const Bytes: TBytes);
begin
  Write(Bytes, Length(Bytes) * 8);
end;

procedure TBitWriter.Write(const Bits: TBits; BitCount: Integer);
var
  I: Integer;
begin
  if BitCount < 0 then
    raise EArgumentException.Create('BitCount must be >= 0');
  if BitCount > Bits.Size then
    raise EArgumentException.Create('BitCount exceeds source bits');

  for I := 0 to BitCount - 1 do
  begin
    if (FPosition < 0) or (FPosition > FValues.Count) then
      raise ERangeError.Create('Position out of range');
    FValues.Insert(FPosition, Bits[I]);
    Inc(FPosition);
  end;
end;

procedure TBitWriter.Write(const Bytes: TBytes; BitCount: Integer);
var
  Swapped: TBytes;
  I, BitIdx, Written: Integer;
  BitVal: Boolean;
begin
  if BitCount < 0 then
    raise EArgumentException.Create('BitCount must be >= 0');
  if BitCount > Length(Bytes) * 8 then
    raise EArgumentException.Create('BitCount exceeds byte array length * 8');

  Swapped := SwapEndianBytes(Bytes);

  Written := 0;
  for I := 0 to High(Swapped) do
  begin
    for BitIdx := 0 to 7 do
    begin
      if Written = BitCount then
        Exit;
      BitVal := ((Swapped[I] shr BitIdx) and 1) = 1; // little-endian bit packing
      if (FPosition < 0) or (FPosition > FValues.Count) then
        raise ERangeError.Create('Position out of range');
      FValues.Insert(FPosition, BitVal);
      Inc(FPosition);
      Inc(Written);
    end;
  end;
end;

function TBitWriter.ToBytes: TBytes;
var
  ByteLen, I, B, Offs: Integer;
  Raw: TBytes;
begin
  // pack to little-endian in-byte order
  ByteLen := FValues.Count div 8;
  if (FValues.Count mod 8) <> 0 then
    Inc(ByteLen);
  SetLength(Raw, ByteLen);

  for I := 0 to FValues.Count - 1 do
  begin
    B    := I div 8;
    Offs := I mod 8; // bit 0 = LSB
    if FValues[I] then
      Raw[B] := Raw[B] or (1 shl Offs);
  end;

  Result := SwapEndianBytes(Raw);
end;

function TBitWriter.ToBitArray: TBits;
var
  I: Integer;
begin
  Result := TBits.Create;
  Result.Size := FValues.Count;
  for I := 0 to FValues.Count - 1 do
    Result[I] := FValues[I];
end;

function TBitWriter.ToIntegers: TArray<Integer>;
var
  Bits: TBits;
begin
  Bits := ToBitArray;
  try
    Result := ToIntegersFromBits(Bits);
  finally
    Bits.Free;
  end;
end;

class function TBitWriter.ToIntegersFromBits(const Bits: TBits): TArray<Integer>;
var
  I, GroupVal, TotalBits: Integer;
  OutList: TList<Integer>;
begin
  TotalBits := Bits.Size;
  if TotalBits = 0 then
    Exit(nil);

  OutList := TList<Integer>.Create;
  try
    GroupVal := 0;
    for I := 0 to TotalBits - 1 do
    begin
      if Bits[I] then
        GroupVal := GroupVal or (1 shl (10 - (I mod 11)));

      if (I mod 11) = 10 then
      begin
        OutList.Add(GroupVal);
        GroupVal := 0;
      end;
    end;

    // trailing partial group (normally not present in BIP-39, but safe)
    if (TotalBits mod 11) <> 0 then
      OutList.Add(GroupVal);

    Result := OutList.ToArray;
  finally
    OutList.Free;
  end;
end;

function TBitWriter.ToString: string;
var
  SB: TStringBuilder;
  I: Integer;
begin
  SB := TStringBuilder.Create(FValues.Count + FValues.Count div 8);
  try
    for I := 0 to FValues.Count - 1 do
    begin
      if (I <> 0) and ((I mod 8) = 0) then
        SB.Append(' ');
      if FValues[I] then SB.Append('1') else SB.Append('0');
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

class function TBitWriter.SwapEndianBytes(const Bytes: TBytes): TBytes;
var
  I, Bit: Integer;
  B, NewB: Byte;
begin
  SetLength(Result, Length(Bytes));
  for I := 0 to High(Bytes) do
  begin
    B := Bytes[I];
    NewB := 0;
    for Bit := 0 to 7 do
      NewB := NewB or (((B shr Bit) and 1) shl (7 - Bit)); // reverse bit order within the byte
    Result[I] := NewB;
  end;
end;

end.

