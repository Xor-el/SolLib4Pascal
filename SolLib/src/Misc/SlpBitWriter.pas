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
  System.Classes;

type
  /// <summary>
  /// Append-only bit writer for BIP-39 mnemonic operations.
  /// Bits are stored MSB-first (big-endian bit order), matching BIP-39's
  /// convention where the most significant bit of each byte is written first.
  /// </summary>
  TBitWriter = class
  private
    FBits: TBytes;    // packed bit storage, MSB-first within each byte
    FCount: Integer;  // total number of bits written

    procedure EnsureCapacity(AAdditionalBits: Integer);
    procedure AppendBit(AValue: Boolean); inline;
  public
    constructor Create;

    /// <summary>Number of bits currently stored.</summary>
    property Count: Integer read FCount;

    /// <summary>Write all bits from a byte array (MSB-first per byte).</summary>
    procedure Write(const ABytes: TBytes); overload;

    /// <summary>Write first ABitCount bits from a byte array (MSB-first per byte).</summary>
    procedure Write(const ABytes: TBytes; ABitCount: Integer); overload;

    /// <summary>Write first ABitCount bits from a TBits instance.</summary>
    procedure Write(const ABits: TBits; ABitCount: Integer); overload;

    /// <summary>Export as bytes (MSB-first bit packing, matching input convention).</summary>
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
  FCount := 0;
  SetLength(FBits, 32); // initial capacity: 256 bits
end;

procedure TBitWriter.EnsureCapacity(AAdditionalBits: Integer);
var
  LNeededBytes, LCapacity: Integer;
begin
  LNeededBytes := (FCount + AAdditionalBits + 7) div 8;
  LCapacity := Length(FBits);
  if LNeededBytes > LCapacity then
  begin
    // Double capacity until sufficient
    while LCapacity < LNeededBytes do
    begin
      if LCapacity = 0 then
        LCapacity := 32
      else
        LCapacity := LCapacity * 2;
    end;
    SetLength(FBits, LCapacity);
  end;
end;

procedure TBitWriter.AppendBit(AValue: Boolean);
var
  LByteIdx, LBitIdx: Integer;
begin
  LByteIdx := FCount div 8;
  LBitIdx := 7 - (FCount mod 8); // MSB-first: bit 7 is first in each byte
  if AValue then
    FBits[LByteIdx] := FBits[LByteIdx] or (1 shl LBitIdx);
  Inc(FCount);
end;

procedure TBitWriter.Write(const ABytes: TBytes);
begin
  Write(ABytes, Length(ABytes) * 8);
end;

procedure TBitWriter.Write(const ABytes: TBytes; ABitCount: Integer);
var
  LI, LByteIdx, LBitIdx: Integer;
begin
  if ABitCount < 0 then
    raise EArgumentException.Create('ABitCount must be >= 0');
  if ABitCount > Length(ABytes) * 8 then
    raise EArgumentException.Create('ABitCount exceeds byte array capacity');

  EnsureCapacity(ABitCount);

  // Read bits MSB-first from source bytes
  for LI := 0 to ABitCount - 1 do
  begin
    LByteIdx := LI div 8;
    LBitIdx := 7 - (LI mod 8); // MSB first
    AppendBit(((ABytes[LByteIdx] shr LBitIdx) and 1) = 1);
  end;
end;

procedure TBitWriter.Write(const ABits: TBits; ABitCount: Integer);
var
  LI: Integer;
begin
  if ABitCount < 0 then
    raise EArgumentException.Create('ABitCount must be >= 0');
  if ABitCount > ABits.Size then
    raise EArgumentException.Create('ABitCount exceeds source bits');

  EnsureCapacity(ABitCount);

  for LI := 0 to ABitCount - 1 do
    AppendBit(ABits[LI]);
end;

function TBitWriter.ToBytes: TBytes;
var
  LByteLen: Integer;
begin
  LByteLen := (FCount + 7) div 8;
  SetLength(Result, LByteLen);
  if LByteLen > 0 then
    Move(FBits[0], Result[0], LByteLen);
end;

function TBitWriter.ToBitArray: TBits;
var
  LI, LByteIdx, LBitIdx: Integer;
begin
  Result := TBits.Create;
  Result.Size := FCount;
  for LI := 0 to FCount - 1 do
  begin
    LByteIdx := LI div 8;
    LBitIdx := 7 - (LI mod 8);
    Result[LI] := ((FBits[LByteIdx] shr LBitIdx) and 1) = 1;
  end;
end;

function TBitWriter.ToIntegers: TArray<Integer>;
var
  LGroupCount, LI, LByteIdx, LBitIdx, LGroupIdx, LBitInGroup: Integer;
  LBitVal: Boolean;
begin
  if FCount = 0 then
    Exit(nil);

  LGroupCount := FCount div 11;
  if (FCount mod 11) <> 0 then
    Inc(LGroupCount);
  SetLength(Result, LGroupCount);

  LGroupIdx := 0;
  LBitInGroup := 0;
  for LI := 0 to FCount - 1 do
  begin
    LByteIdx := LI div 8;
    LBitIdx := 7 - (LI mod 8);
    LBitVal := ((FBits[LByteIdx] shr LBitIdx) and 1) = 1;

    if LBitVal then
      Result[LGroupIdx] := Result[LGroupIdx] or (1 shl (10 - LBitInGroup));

    Inc(LBitInGroup);
    if LBitInGroup = 11 then
    begin
      Inc(LGroupIdx);
      LBitInGroup := 0;
    end;
  end;
end;

class function TBitWriter.ToIntegersFromBits(const ABits: TBits): TArray<Integer>;
var
  LTotalBits, LGroupCount, LI, LGroupIdx, LBitInGroup: Integer;
begin
  LTotalBits := ABits.Size;
  if LTotalBits = 0 then
    Exit(nil);

  LGroupCount := LTotalBits div 11;
  if (LTotalBits mod 11) <> 0 then
    Inc(LGroupCount);
  SetLength(Result, LGroupCount);

  LGroupIdx := 0;
  LBitInGroup := 0;
  for LI := 0 to LTotalBits - 1 do
  begin
    if ABits[LI] then
      Result[LGroupIdx] := Result[LGroupIdx] or (1 shl (10 - LBitInGroup));

    Inc(LBitInGroup);
    if LBitInGroup = 11 then
    begin
      Inc(LGroupIdx);
      LBitInGroup := 0;
    end;
  end;
end;

function TBitWriter.ToString: string;
var
  LSB: TStringBuilder;
  LI, LByteIdx, LBitIdx: Integer;
begin
  LSB := TStringBuilder.Create(FCount + FCount div 8);
  try
    for LI := 0 to FCount - 1 do
    begin
      if (LI > 0) and ((LI mod 8) = 0) then
        LSB.Append(' ');
      LByteIdx := LI div 8;
      LBitIdx := 7 - (LI mod 8);
      if ((FBits[LByteIdx] shr LBitIdx) and 1) = 1 then
        LSB.Append('1')
      else
        LSB.Append('0');
    end;
    Result := LSB.ToString;
  finally
    LSB.Free;
  end;
end;

end.
