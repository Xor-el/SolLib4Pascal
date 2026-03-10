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

unit SlpArrayUtils;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Math,
  SlpSolLibTypes;

type
  TArrayUtils = class sealed
  private
    class procedure RequireRange(ACond: Boolean; const AMsg: string); static;
  public

    class function AreArraysEqual(const AFirst, BSecond: TBytes): Boolean; overload; static;
    class function AreArraysEqual(const AFirst, BSecond: TArray<Integer>): Boolean; overload; static;

    /// <summary>Concatenate two arrays of any type T.</summary>
    class function Concat<T>(const AFirst, BSecond: TArray<T>): TArray<T>; static;
    class function Slice<T>(const A: TArray<T>; AOffset: Integer): TArray<T>; overload;
    /// <summary>
    /// Generic slice: returns A[Offset .. Offset+Count-1], clamped to bounds.
    /// </summary>
    class function Slice<T>(const A: TArray<T>; AOffset, ACount: Integer): TArray<T>; overload;

        {==================== COPY (PROCEDURES) ====================}

    /// <summary>
    /// Copy the entire Source to Dest starting at index 0.
    /// Raises if Dest is nil or Dest.Length &lt; Source.Length.
    /// </summary>
    class procedure Copy<T>(const ASource: TArray<T>; var ADest: TArray<T>); overload; static;

    /// <summary>
    /// Copy Count items from Source[SrcIndex] into Dest[DestIndex].
    /// No resizing: raises if the copy will not fit. Overlap-safe.
    /// </summary>
    class procedure Copy<T>(
      const ASource: TArray<T>; ASrcIndex: Integer;
      var ADest: TArray<T>; ADestIndex: Integer;
      ACount: Integer); overload; static;

    /// <summary>
    /// Copy entire Source into Dest starting at DestIndex.
    /// No resizing: raises if the copy will not fit.
    /// </summary>
    class procedure Copy<T>(
      const ASource: TArray<T>;
      var ADest: TArray<T>;
      ADestIndex: Integer); overload; static;

    /// <summary>
    /// Copy Source[SrcIndex..end] into Dest starting at DestIndex.
    /// No resizing: raises if the copy will not fit.
    /// </summary>
    class procedure Copy<T>(
      const ASource: TArray<T>; ASrcIndex: Integer;
      var ADest: TArray<T>; ADestIndex: Integer); overload; static;

    {==================== COPY (FUNCTIONS) ====================}

    /// <summary>
    /// Returns a NEW array that is a copy of Source (entire array).
    /// </summary>
    class function Copy<T>(const ASource: TArray<T>): TArray<T>; overload; static;

    /// <summary>
    /// Returns a NEW array with the first Count items of Source.
    /// Raises if Count &lt; 0 or Count &gt; Source.Length.
    /// </summary>
    class function Copy<T>(
      const ASource: TArray<T>; ACount: Integer): TArray<T>; overload; static;

    /// <summary>
    /// Returns a NEW array with Source[Index..Index+Count-1].
    /// Range-checked.
    /// </summary>
    class function Copy<T>(
      const ASource: TArray<T>; AIndex, ACount: Integer): TArray<T>; overload; static;

    class function Copy<T>(
      const ASource: TArray<T>; const ACloner: TFunc<T, T>): TArray<T>; overload; static;

    class function IndexOf<T>(
      const AValues: TArray<T>; const APredicate: TFunc<T, Boolean>;
      out AIndex: Integer): Boolean; overload; static;

    class function IndexOf<T>(
      const AValues: TArray<T>; const APredicate: TFunc<T, Boolean>;
      const AStartIndex, ACount: Integer; out AIndex: Integer): Boolean; overload; static;

    /// <summary>
    /// Overwrite the entire array with zeros (0).
    /// </summary>
    class procedure Fill<T>(var AArr: TArray<T>); overload; static;

    /// <summary>
    /// Overwrite the entire array with the specified value.
    /// </summary>
    class procedure Fill<T>(var AArr: TArray<T>; const AValue: T); overload; static;

    /// <summary>
    /// Overwrite a subrange of the array starting at Offset for Count elements with zero.
    /// </summary>
    class procedure Fill<T>(var AArr: TArray<T>; const AOffset, ACount: Integer); overload; static;

    /// <summary>
    /// Overwrite a subrange of the array starting at Offset for Count elements with a specific value.
    /// </summary>
    class procedure Fill<T>(var AArr: TArray<T>; const AOffset, ACount: Integer; const AValue: T); overload; static;

    class function Reverse<T>(const ASource: TArray<T>): TArray<T>; static;

    class function Any<T>(const AList: TArray<T>; const APred: TPredicate<T>): Boolean; static;

    /// <summary>
    /// Constant-time comparison of two byte arrays (timing-attack resistant).
    /// </summary>
    class function ConstantTimeEquals(const AFirst, BSecond: TBytes): Boolean; static;

    /// <summary>
    /// Securely zero-out a byte array.
    /// </summary>
    class procedure Zeroize(var AArr: TBytes); static;
  end;

implementation

{ TArrayUtils }

class procedure TArrayUtils.RequireRange(ACond: Boolean; const AMsg: string);
begin
  if not ACond then
    raise ERangeError.Create(AMsg);
end;

class function TArrayUtils.AreArraysEqual(const AFirst, BSecond: TBytes): Boolean;
var
  LLen: Integer;
begin
  if Pointer(AFirst) = Pointer(BSecond) then
    Exit(True);
  LLen := Length(AFirst);
  if LLen <> Length(BSecond) then
    Exit(False);
  if LLen = 0 then
    Exit(True);
  Result := CompareMem(@AFirst[0], @BSecond[0], LLen);
end;

class function TArrayUtils.AreArraysEqual(const AFirst, BSecond: TArray<Integer>): Boolean;
var
  LLen: Integer;
begin
  if Pointer(AFirst) = Pointer(BSecond) then
    Exit(True);
  LLen := Length(AFirst);
  if LLen <> Length(BSecond) then
    Exit(False);
  if LLen = 0 then
    Exit(True);
  Result := CompareMem(@AFirst[0], @BSecond[0], LLen * SizeOf(Integer));
end;

class function TArrayUtils.Concat<T>(const AFirst, BSecond: TArray<T>): TArray<T>;
var
  LLenA, LLenB: Integer;
begin
  LLenA := Length(AFirst);
  LLenB := Length(BSecond);
  SetLength(Result, LLenA + LLenB);
  if LLenA > 0 then
    Copy<T>(AFirst, 0, Result, 0, LLenA);
  if LLenB > 0 then
    Copy<T>(BSecond, 0, Result, LLenA, LLenB);
end;

class function TArrayUtils.Slice<T>(const A: TArray<T>; AOffset: Integer): TArray<T>;
begin
  Result := Slice<T>(A, AOffset, Length(A) - AOffset);
end;

class function TArrayUtils.Slice<T>(const A: TArray<T>; AOffset, ACount: Integer): TArray<T>;
var
  LLen, LOffset, LCount: Integer;
begin
  LLen := Length(A);
  LOffset := AOffset;
  LCount := ACount;

  // Clamp offset
  if LOffset < 0 then
    LOffset := 0
  else if LOffset > LLen then
    LOffset := LLen;

  // Clamp count
  if LCount < 0 then
    LCount := 0
  else if LOffset + LCount > LLen then
    LCount := LLen - LOffset;

  Result := Copy<T>(A, LOffset, LCount);
end;

{==================== COPY (PROCEDURES) ====================}

class procedure TArrayUtils.Copy<T>(
  const ASource: TArray<T>;
  var ADest: TArray<T>);
var
  LSrcLen: Integer;
begin
  LSrcLen := Length(ASource);
  RequireRange(Length(ADest) >= LSrcLen, 'Destination too small for copy.');
  if LSrcLen = 0 then
    Exit;
  Copy<T>(ASource, 0, ADest, 0, LSrcLen);
end;

class procedure TArrayUtils.Copy<T>(
  const ASource: TArray<T>; ASrcIndex: Integer;
  var ADest: TArray<T>; ADestIndex: Integer;
  ACount: Integer);
var
  LSrcLen, LDestLen, LI: Integer;
begin
  RequireRange(ASrcIndex >= 0, 'SrcIndex must be >= 0.');
  RequireRange(ADestIndex >= 0, 'DestIndex must be >= 0.');
  RequireRange(ACount >= 0, 'Count must be >= 0.');

  LSrcLen := Length(ASource);
  LDestLen := Length(ADest);

  RequireRange(ASrcIndex <= LSrcLen, 'SrcIndex out of range.');
  RequireRange(ACount <= (LSrcLen - ASrcIndex), 'Count exceeds Source length.');
  RequireRange(ADestIndex <= LDestLen, 'DestIndex out of range.');
  RequireRange(ACount <= (LDestLen - ADestIndex), 'Destination too small for copy.');

  if ACount = 0 then Exit;

  if (Pointer(ASource) = Pointer(ADest)) and (ADestIndex > ASrcIndex)
     and (ADestIndex < ASrcIndex + ACount) then
  begin
    for LI := ACount - 1 downto 0 do
      ADest[ADestIndex + LI] := ASource[ASrcIndex + LI];
  end
  else
  begin
    for LI := 0 to ACount - 1 do
      ADest[ADestIndex + LI] := ASource[ASrcIndex + LI];
  end;
end;

class procedure TArrayUtils.Copy<T>(
  const ASource: TArray<T>;
  var ADest: TArray<T>;
  ADestIndex: Integer);
begin
  Copy<T>(ASource, 0, ADest, ADestIndex, Length(ASource));
end;

class procedure TArrayUtils.Copy<T>(
  const ASource: TArray<T>; ASrcIndex: Integer;
  var ADest: TArray<T>; ADestIndex: Integer);
begin
  RequireRange(ASrcIndex >= 0, 'SrcIndex must be >= 0.');
  Copy<T>(ASource, ASrcIndex, ADest, ADestIndex, Length(ASource) - ASrcIndex);
end;

{==================== COPY (FUNCTIONS) ====================}

class function TArrayUtils.Copy<T>(
  const ASource: TArray<T>): TArray<T>;
begin
  Result := Copy<T>(ASource, 0, Length(ASource));
end;

class function TArrayUtils.Copy<T>(
  const ASource: TArray<T>; ACount: Integer): TArray<T>;
begin
  RequireRange(ACount >= 0, 'Count must be >= 0.');
  RequireRange(ACount <= Length(ASource), 'Count exceeds Source length.');
  Result := Copy<T>(ASource, 0, ACount);
end;

class function TArrayUtils.Copy<T>(
  const ASource: TArray<T>; AIndex, ACount: Integer): TArray<T>;
begin
  RequireRange(AIndex >= 0, 'Index must be >= 0.');
  RequireRange(ACount >= 0, 'Count must be >= 0.');
  RequireRange(AIndex <= Length(ASource), 'Index out of range.');
  RequireRange(ACount <= (Length(ASource) - AIndex), 'Index+Count exceeds Source length.');

  SetLength(Result, ACount);
  if ACount > 0 then
    Copy<T>(ASource, AIndex, Result, 0, ACount);
end;

class function TArrayUtils.Copy<T>(
  const ASource: TArray<T>;
  const ACloner: TFunc<T, T>): TArray<T>;
var
  LI, LLen: Integer;
begin
  if not Assigned(ACloner) then
    raise EArgumentNilException.Create('Cloner must be assigned');

  LLen := Length(ASource);
  SetLength(Result, LLen);
  for LI := 0 to LLen - 1 do
    Result[LI] := ACloner(ASource[LI]);
end;

class function TArrayUtils.IndexOf<T>(
  const AValues: TArray<T>;
  const APredicate: TFunc<T, Boolean>;
  out AIndex: Integer): Boolean;
begin
  Result := IndexOf<T>(AValues, APredicate, 0, Length(AValues), AIndex);
end;


class function TArrayUtils.IndexOf<T>(
  const AValues: TArray<T>;
  const APredicate: TFunc<T, Boolean>;
  const AStartIndex, ACount: Integer;
  out AIndex: Integer): Boolean;
var
  LI, LLastIndex, LLimit: Integer;
begin
  if not Assigned(APredicate) then
    raise Exception.Create('Predicate function cannot be nil.');

  if (AStartIndex < 0) or (AStartIndex > Length(AValues)) then
    raise Exception.CreateFmt('StartIndex (%d) is out of bounds.', [AStartIndex]);

  if (ACount < 0) then
    raise Exception.CreateFmt('Count (%d) cannot be negative.', [ACount]);

  LLimit := Min(Length(AValues), AStartIndex + ACount);
  LLastIndex := LLimit - 1;

  for LI := AStartIndex to LLastIndex do
    if APredicate(AValues[LI]) then
    begin
      AIndex := LI;
      Exit(True);
    end;

  AIndex := -1;
  Result := False;
end;

class procedure TArrayUtils.Fill<T>(var AArr: TArray<T>);
begin
  if Length(AArr) = 0 then
    Exit;
  Fill<T>(AArr, 0, Length(AArr), Default(T));
end;

class procedure TArrayUtils.Fill<T>(var AArr: TArray<T>; const AValue: T);
begin
  if Length(AArr) = 0 then
    Exit;
  Fill<T>(AArr, 0, Length(AArr), AValue);
end;

class procedure TArrayUtils.Fill<T>(var AArr: TArray<T>; const AOffset, ACount: Integer);
begin
  Fill<T>(AArr, AOffset, ACount, Default(T));
end;

class procedure TArrayUtils.Fill<T>(
  var AArr: TArray<T>;
  const AOffset, ACount: Integer;
  const AValue: T);
var
  LI: Integer;
begin
  if (AOffset < 0) or (ACount < 0) or (AOffset + ACount > Length(AArr)) then
    raise EArgumentOutOfRangeException.Create('Invalid offset/count range.');

  for LI := AOffset to AOffset + ACount - 1 do
    AArr[LI] := AValue;
end;

class function TArrayUtils.Reverse<T>(const ASource: TArray<T>): TArray<T>;
var
  LI, LLen: Integer;
begin
  LLen := Length(ASource);
  SetLength(Result, LLen);

  for LI := 0 to LLen - 1 do
    Result[LI] := ASource[LLen - 1 - LI];
end;

class function TArrayUtils.Any<T>(const AList: TArray<T>; const APred: TPredicate<T>): Boolean;
var
  LItem: T;
begin
  for LItem in AList do
    if APred(LItem) then
      Exit(True);
  Result := False;
end;

class function TArrayUtils.ConstantTimeEquals(const AFirst, BSecond: TBytes): Boolean;
var
  LI: Integer;
  LDiff: Byte;
begin
  if Length(AFirst) <> Length(BSecond) then
    Exit(False);
  LDiff := 0;
  for LI := 0 to High(AFirst) do
    LDiff := LDiff or (AFirst[LI] xor BSecond[LI]);
  Result := (LDiff = 0);
end;

class procedure TArrayUtils.Zeroize(var AArr: TBytes);
begin
  if Length(AArr) = 0 then
    Exit;
  Fill<Byte>(AArr, 0, Length(AArr), 0);
end;

end.

