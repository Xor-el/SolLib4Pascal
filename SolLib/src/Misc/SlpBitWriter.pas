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
    FValues: TList<Boolean>;  // bit buffer
    FPosition: Integer;         // insertion cursor (0..Count)

    function GetCount: Integer; inline;
    class function SwapEndianBytes(const ABytes: TBytes): TBytes; static;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Current insertion cursor (0..Count).</summary>
    property Position: Integer read FPosition write FPosition;

    /// <summary>Number of bits currently stored.</summary>
    property Count: Integer read GetCount;

    /// <summary>Write a single bit at Position; Position advances by 1.</summary>
    procedure WriteBit(AValue: Boolean);

    /// <summary>Write all bits from a byte array (after per-byte bit swap).</summary>
    procedure Write(const ABytes: TBytes); overload;

    /// <summary>Write first BitCount bits from a byte array (after per-byte bit swap).</summary>
    procedure Write(const ABytes: TBytes; ABitCount: Integer); overload;

    /// <summary>Write first BitCount bits from a TBits instance.</summary>
    procedure Write(const ABits: TBits; ABitCount: Integer); overload;

    /// <summary>Export as bytes (packs little-endian bits per byte, then swaps per-byte bit order back).</summary>
    function ToBytes: TBytes;

    /// <summary>Export as TBits. Caller owns the result and must Free it.</summary>
    function ToBitArray: TBits;

    /// <summary>Export as array of 11-bit integers (BIP-39 style grouping).</summary>
    function ToIntegers: TArray<Integer>;

    /// <summary>Convert any TBits to 11-bit integers.</summary>
    class function ToIntegersFromBits(const ABits: TBits): TArray<Integer>; static;

    /// <summary>Human-readable bit dump with spaces every 8 bits.</summary>
    function ToString: string; override;
  end;

implementation

{ TBitWriter }

constructor TBitWriter.Create;
begin
  inherited Create;
  FValues := TList<Boolean>.Create;
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

procedure TBitWriter.WriteBit(AValue: Boolean);
begin
  if (FPosition < 0) or (FPosition > FValues.Count) then
    raise ERangeError.Create('Position out of range');
  FValues.Insert(FPosition, AValue);
  Inc(FPosition);
end;

procedure TBitWriter.Write(const ABytes: TBytes);
begin
  Write(ABytes, Length(ABytes) * 8);
end;

procedure TBitWriter.Write(const ABits: TBits; ABitCount: Integer);
var
  LI: Integer;
begin
  if ABitCount < 0 then
    raise EArgumentException.Create('BitCount must be >= 0');
  if ABitCount > ABits.Size then
    raise EArgumentException.Create('BitCount exceeds source bits');

  for LI := 0 to ABitCount - 1 do
  begin
    if (FPosition < 0) or (FPosition > FValues.Count) then
      raise ERangeError.Create('Position out of range');
    FValues.Insert(FPosition, ABits[LI]);
    Inc(FPosition);
  end;
end;

procedure TBitWriter.Write(const ABytes: TBytes; ABitCount: Integer);
var
  LSwapped: TBytes;
  LI, LBitIdx, LWritten: Integer;
  LBitVal: Boolean;
begin
  if ABitCount < 0 then
    raise EArgumentException.Create('BitCount must be >= 0');
  if ABitCount > Length(ABytes) * 8 then
    raise EArgumentException.Create('BitCount exceeds byte array length * 8');

  LSwapped := SwapEndianBytes(ABytes);

  LWritten := 0;
  for LI := 0 to High(LSwapped) do
  begin
    for LBitIdx := 0 to 7 do
    begin
      if LWritten = ABitCount then
        Exit;
      LBitVal := ((LSwapped[LI] shr LBitIdx) and 1) = 1; // little-endian bit packing
      if (FPosition < 0) or (FPosition > FValues.Count) then
        raise ERangeError.Create('Position out of range');
      FValues.Insert(FPosition, LBitVal);
      Inc(FPosition);
      Inc(LWritten);
    end;
  end;
end;

function TBitWriter.ToBytes: TBytes;
var
  LByteLen, LI, LB, LOffs: Integer;
  LRaw: TBytes;
begin
  // pack to little-endian in-byte order
  LByteLen := FValues.Count div 8;
  if (FValues.Count mod 8) <> 0 then
    Inc(LByteLen);
  SetLength(LRaw, LByteLen);

  for LI := 0 to FValues.Count - 1 do
  begin
    LB := LI div 8;
    LOffs := LI mod 8; // bit 0 = LSB
    if FValues[LI] then
      LRaw[LB] := LRaw[LB] or (1 shl LOffs);
  end;

  Result := SwapEndianBytes(LRaw);
end;

function TBitWriter.ToBitArray: TBits;
var
  LI: Integer;
begin
  Result := TBits.Create;
  Result.Size := FValues.Count;
  for LI := 0 to FValues.Count - 1 do
    Result[LI] := FValues[LI];
end;

function TBitWriter.ToIntegers: TArray<Integer>;
var
  LBits: TBits;
begin
  LBits := ToBitArray;
  try
    Result := ToIntegersFromBits(LBits);
  finally
    LBits.Free;
  end;
end;

class function TBitWriter.ToIntegersFromBits(const ABits: TBits): TArray<Integer>;
var
  LI, LGroupVal, LTotalBits: Integer;
  LOutList: TList<Integer>;
begin
  LTotalBits := ABits.Size;
  if LTotalBits = 0 then
    Exit(nil);

  LOutList := TList<Integer>.Create;
  try
    LGroupVal := 0;
    for LI := 0 to LTotalBits - 1 do
    begin
      if ABits[LI] then
        LGroupVal := LGroupVal or (1 shl (10 - (LI mod 11)));

      if (LI mod 11) = 10 then
      begin
        LOutList.Add(LGroupVal);
        LGroupVal := 0;
      end;
    end;

    // trailing partial group (normally not present in BIP-39, but safe)
    if (LTotalBits mod 11) <> 0 then
      LOutList.Add(LGroupVal);

    Result := LOutList.ToArray;
  finally
    LOutList.Free;
  end;
end;

function TBitWriter.ToString: string;
var
  LSB: TStringBuilder;
  LI: Integer;
begin
  LSB := TStringBuilder.Create(FValues.Count + FValues.Count div 8);
  try
    for LI := 0 to FValues.Count - 1 do
    begin
      if (LI <> 0) and ((LI mod 8) = 0) then
        LSB.Append(' ');
      if FValues[LI] then LSB.Append('1') else LSB.Append('0');
    end;
    Result := LSB.ToString;
  finally
    LSB.Free;
  end;
end;

class function TBitWriter.SwapEndianBytes(const ABytes: TBytes): TBytes;
var
  LI, LBit: Integer;
  LB, LNewB: Byte;
begin
  SetLength(Result, Length(ABytes));
  for LI := 0 to High(ABytes) do
  begin
    LB := ABytes[LI];
    LNewB := 0;
    for LBit := 0 to 7 do
      LNewB := LNewB or (((LB shr LBit) and 1) shl (7 - LBit)); // reverse bit order within the byte
    Result[LI] := LNewB;
  end;
end;

end.

