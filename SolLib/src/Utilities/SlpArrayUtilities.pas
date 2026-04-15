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

unit SlpArrayUtilities;

{$I ../Include/SolLib.inc}

interface

uses
  SysUtils,
  Math,
  Generics.Defaults;

type
  TArrayUtilities = class sealed
  private
    class procedure CheckRange(ACond: Boolean; const AMsg: string); static; inline;
  public

    /// <summary>
    /// Element-wise equality for arrays of any type T using a comparer.
    /// If AComparer is nil, uses TEqualityComparer&lt;T&gt;.Default.
    /// <summary>
    /// Element-wise equality for arrays of any type T using a comparer.
    /// If AComparer is nil, uses TEqualityComparer&lt;T&gt;.Default.
    /// </summary>
    class function AreArraysEqual<T>(
      const A, B: TArray<T>;
      const AComparer: IEqualityComparer<T> = nil
    ): Boolean; overload; static;

    /// <summary>Bitwise equality for byte arrays via CompareMem.</summary>
    class function AreArraysEqual(const AFirst, ASecond: TBytes): Boolean; overload; static;

    /// <summary>Bitwise equality for integer arrays via CompareMem.</summary>
    class function AreArraysEqual(const AFirst, ASecond: TArray<Integer>): Boolean; overload; static;

    /// <summary>Concatenate two arrays of any type T.</summary>
    class function Concat<T>(const AFirst, ASecond: TArray<T>): TArray<T>; static;

    /// <summary>Returns A[AOffset..end].</summary>
    class function Slice<T>(const ASource: TArray<T>; AOffset: Integer): TArray<T>; overload; static;

    /// <summary>
    /// Returns A[AOffset .. AOffset+ACount-1], clamped to bounds.
    /// </summary>
    class function Slice<T>(const ASource: TArray<T>; AOffset, ACount: Integer): TArray<T>; overload; static;

    {==================== COPY (PROCEDURES) ====================}

    /// <summary>
    /// Copy the entire ASource to ADest starting at index 0.
    /// Raises if ADest is too small.
    /// </summary>
    class procedure Copy<T>(const ASource: TArray<T>; var ADest: TArray<T>); overload; static;

    /// <summary>
    /// Copy ACount items from ASource[ASrcIndex] into ADest[ADestIndex].
    /// No resizing. Overlap-safe.
    /// </summary>
    class procedure Copy<T>(
      const ASource: TArray<T>; ASrcIndex: Integer;
      var ADest: TArray<T>; ADestIndex: Integer;
      ACount: Integer); overload; static;

    /// <summary>
    /// Copy entire ASource into ADest starting at ADestIndex.
    /// </summary>
    class procedure Copy<T>(
      const ASource: TArray<T>;
      var ADest: TArray<T>;
      ADestIndex: Integer); overload; static;

    /// <summary>
    /// Copy ASource[ASrcIndex..end] into ADest starting at ADestIndex.
    /// </summary>
    class procedure Copy<T>(
      const ASource: TArray<T>; ASrcIndex: Integer;
      var ADest: TArray<T>; ADestIndex: Integer); overload; static;

    {==================== COPY (FUNCTIONS) ====================}

    /// <summary>Returns a new array that is a full copy of ASource.</summary>
    class function Copy<T>(const ASource: TArray<T>): TArray<T>; overload; static;

    /// <summary>Returns a new array with the first ACount items of ASource.</summary>
    class function Copy<T>(
      const ASource: TArray<T>; ACount: Integer): TArray<T>; overload; static;

    /// <summary>Returns a new array with ASource[AIndex..AIndex+ACount-1].</summary>
    class function Copy<T>(
      const ASource: TArray<T>; AIndex, ACount: Integer): TArray<T>; overload; static;

    /// <summary>Returns a new array with each element deep-cloned via ACloner.</summary>
    class function Copy<T>(
      const ASource: TArray<T>; const ACloner: TFunc<T, T>): TArray<T>; overload; static;

    class function IndexOf<T>(
      const AValues: TArray<T>; const APredicate: TFunc<T, Boolean>;
      out AIndex: Integer): Boolean; overload; static;

    class function IndexOf<T>(
      const AValues: TArray<T>; const APredicate: TFunc<T, Boolean>;
      AStartIndex, ACount: Integer; out AIndex: Integer): Boolean; overload; static;

    /// <summary>Overwrite the entire array with Default(T).</summary>
    class procedure Fill<T>(var AArr: TArray<T>); overload; static;

    /// <summary>Overwrite the entire array with AValue.</summary>
    class procedure Fill<T>(var AArr: TArray<T>; const AValue: T); overload; static;

    /// <summary>Overwrite AArr[AOffset..AOffset+ACount-1] with Default(T).</summary>
    class procedure Fill<T>(var AArr: TArray<T>; AOffset, ACount: Integer); overload; static;

    /// <summary>Overwrite AArr[AOffset..AOffset+ACount-1] with AValue.</summary>
    class procedure Fill<T>(var AArr: TArray<T>; AOffset, ACount: Integer; const AValue: T); overload; static;

    /// <summary>Returns a new array with elements in reverse order.</summary>
    class function Reverse<T>(const ASource: TArray<T>): TArray<T>; static;

    /// <summary>Returns True if any element satisfies APred.</summary>
    class function Any<T>(const AArr: TArray<T>; const APred: TPredicate<T>): Boolean; static;

    /// <summary>
    /// Constant-time comparison of two byte arrays.
    /// Both length and content comparisons are constant-time to avoid
    /// leaking information through timing side channels.
    /// </summary>
    class function ConstantTimeEquals(const AFirst, ASecond: TBytes): Boolean; static;
  end;

implementation

{ TArrayUtilities }

class procedure TArrayUtilities.CheckRange(ACond: Boolean; const AMsg: string);
begin
  if not ACond then
    raise ERangeError.Create(AMsg);
end;

class function TArrayUtilities.AreArraysEqual<T>(
  const A, B: TArray<T>;
  const AComparer: IEqualityComparer<T>
): Boolean;
var
  LLen, LI: Integer;
  LCmp: IEqualityComparer<T>;
begin
  if Pointer(A) = Pointer(B) then
    Exit(True);

  LLen := Length(A);
  if LLen <> Length(B) then
    Exit(False);
  if LLen = 0 then
    Exit(True);

  if Assigned(AComparer) then
    LCmp := AComparer
  else
    LCmp := TEqualityComparer<T>.Default;

  for LI := 0 to LLen - 1 do
    if not LCmp.Equals(A[LI], B[LI]) then
      Exit(False);

  Result := True;
end;

class function TArrayUtilities.AreArraysEqual(const AFirst, ASecond: TBytes): Boolean;
var
  LLen: Integer;
begin
  if Pointer(AFirst) = Pointer(ASecond) then
    Exit(True);
  LLen := Length(AFirst);
  if LLen <> Length(ASecond) then
    Exit(False);
  if LLen = 0 then
    Exit(True);
  Result := CompareMem(@AFirst[0], @ASecond[0], LLen);
end;

class function TArrayUtilities.AreArraysEqual(const AFirst, ASecond: TArray<Integer>): Boolean;
var
  LLen: Integer;
begin
  if Pointer(AFirst) = Pointer(ASecond) then
    Exit(True);
  LLen := Length(AFirst);
  if LLen <> Length(ASecond) then
    Exit(False);
  if LLen = 0 then
    Exit(True);
  Result := CompareMem(@AFirst[0], @ASecond[0], LLen * SizeOf(Integer));
end;

class function TArrayUtilities.Concat<T>(const AFirst, ASecond: TArray<T>): TArray<T>;
var
  LA, LB, LI: Integer;
begin
  LA := Length(AFirst);
  LB := Length(ASecond);
  SetLength(Result, LA + LB);
  for LI := 0 to LA - 1 do
    Result[LI] := AFirst[LI];
  for LI := 0 to LB - 1 do
    Result[LA + LI] := ASecond[LI];
end;

class function TArrayUtilities.Slice<T>(const ASource: TArray<T>; AOffset: Integer): TArray<T>;
begin
  Result := Slice<T>(ASource, AOffset, Length(ASource) - AOffset);
end;

class function TArrayUtilities.Slice<T>(const ASource: TArray<T>; AOffset, ACount: Integer): TArray<T>;
var
  LLen: Integer;
begin
  LLen := Length(ASource);
  // Clamp offset and count to bounds
  if AOffset < 0 then
    AOffset := 0
  else if AOffset > LLen then
    AOffset := LLen;
  if ACount < 0 then
    ACount := 0
  else if AOffset + ACount > LLen then
    ACount := LLen - AOffset;
  Result := Copy<T>(ASource, AOffset, ACount);
end;

{==================== COPY (PROCEDURES) ====================}

class procedure TArrayUtilities.Copy<T>(
  const ASource: TArray<T>;
  var ADest: TArray<T>);
begin
  CheckRange(Length(ADest) >= Length(ASource), 'Destination too small');
  if Length(ASource) > 0 then
    Copy<T>(ASource, 0, ADest, 0, Length(ASource));
end;

class procedure TArrayUtilities.Copy<T>(
  const ASource: TArray<T>; ASrcIndex: Integer;
  var ADest: TArray<T>; ADestIndex: Integer;
  ACount: Integer);
var
  LSrcLen, LDestLen, LI: Integer;
  LSameArray, LOverlapBackward: Boolean;
begin
  CheckRange(ASrcIndex >= 0, 'ASrcIndex must be >= 0');
  CheckRange(ADestIndex >= 0, 'ADestIndex must be >= 0');
  CheckRange(ACount >= 0, 'ACount must be >= 0');

  LSrcLen := Length(ASource);
  LDestLen := Length(ADest);

  CheckRange(ASrcIndex + ACount <= LSrcLen, 'Source range out of bounds');
  CheckRange(ADestIndex + ACount <= LDestLen, 'Destination range out of bounds');

  if ACount = 0 then
    Exit;

  LSameArray := Pointer(ASource) = Pointer(ADest);

  // For overlapping regions in the same array where dest is after source,
  // copy backwards to avoid overwriting unread elements.
  LOverlapBackward := LSameArray
    and (ADestIndex > ASrcIndex)
    and (ADestIndex < ASrcIndex + ACount);

  if LOverlapBackward then
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

class procedure TArrayUtilities.Copy<T>(
  const ASource: TArray<T>;
  var ADest: TArray<T>;
  ADestIndex: Integer);
begin
  Copy<T>(ASource, 0, ADest, ADestIndex, Length(ASource));
end;

class procedure TArrayUtilities.Copy<T>(
  const ASource: TArray<T>; ASrcIndex: Integer;
  var ADest: TArray<T>; ADestIndex: Integer);
begin
  CheckRange(ASrcIndex >= 0, 'ASrcIndex must be >= 0');
  Copy<T>(ASource, ASrcIndex, ADest, ADestIndex, Length(ASource) - ASrcIndex);
end;

{==================== COPY (FUNCTIONS) ====================}

class function TArrayUtilities.Copy<T>(
  const ASource: TArray<T>): TArray<T>;
begin
  Result := Copy<T>(ASource, 0, Length(ASource));
end;

class function TArrayUtilities.Copy<T>(
  const ASource: TArray<T>; ACount: Integer): TArray<T>;
begin
  CheckRange(ACount >= 0, 'ACount must be >= 0');
  CheckRange(ACount <= Length(ASource), 'ACount exceeds source length');
  Result := Copy<T>(ASource, 0, ACount);
end;

class function TArrayUtilities.Copy<T>(
  const ASource: TArray<T>; AIndex, ACount: Integer): TArray<T>;
var
  LLen, LI: Integer;
begin
  LLen := Length(ASource);
  CheckRange(AIndex >= 0, 'AIndex must be >= 0');
  CheckRange(ACount >= 0, 'ACount must be >= 0');
  CheckRange(AIndex + ACount <= LLen, 'Source range out of bounds');

  SetLength(Result, ACount);
  for LI := 0 to ACount - 1 do
    Result[LI] := ASource[AIndex + LI];
end;

class function TArrayUtilities.Copy<T>(
  const ASource: TArray<T>;
  const ACloner: TFunc<T, T>): TArray<T>;
var
  LI, LLen, LDone: Integer;
  LIsClass: Boolean;
  LObj: TObject;
begin
  if not Assigned(ACloner) then
    raise EArgumentNilException.Create('ACloner must be assigned');

  LLen := Length(ASource);
  SetLength(Result, LLen);

  LIsClass := GetTypeKind(TypeInfo(T)) = tkClass;
  LDone := 0;
  try
    for LI := 0 to LLen - 1 do
    begin
      Result[LI] := ACloner(ASource[LI]);
      Inc(LDone);
    end;
  except
    // On failure, free any successfully cloned objects to prevent leaks
    if LIsClass then
      for LI := 0 to LDone - 1 do
      begin
        LObj := TObject(PPointer(@Result[LI])^);
        if Assigned(LObj) then
          LObj.Free;
      end;
    if LDone > 0 then
      Fill<T>(Result, 0, LDone, Default(T));
    raise;
  end;
end;

class function TArrayUtilities.IndexOf<T>(
  const AValues: TArray<T>;
  const APredicate: TFunc<T, Boolean>;
  out AIndex: Integer): Boolean;
begin
  Result := IndexOf<T>(AValues, APredicate, 0, Length(AValues), AIndex);
end;

class function TArrayUtilities.IndexOf<T>(
  const AValues: TArray<T>;
  const APredicate: TFunc<T, Boolean>;
  AStartIndex, ACount: Integer;
  out AIndex: Integer): Boolean;
var
  LI, LLimit: Integer;
begin
  if not Assigned(APredicate) then
    raise EArgumentNilException.Create('APredicate must be assigned');
  CheckRange((AStartIndex >= 0) and (AStartIndex <= Length(AValues)),
    'AStartIndex out of bounds');
  CheckRange(ACount >= 0, 'ACount must be >= 0');

  LLimit := Min(Length(AValues), AStartIndex + ACount);
  for LI := AStartIndex to LLimit - 1 do
    if APredicate(AValues[LI]) then
    begin
      AIndex := LI;
      Exit(True);
    end;
  AIndex := -1;
  Result := False;
end;

class procedure TArrayUtilities.Fill<T>(var AArr: TArray<T>);
begin
  if Length(AArr) > 0 then
    Fill<T>(AArr, 0, Length(AArr), Default(T));
end;

class procedure TArrayUtilities.Fill<T>(var AArr: TArray<T>; const AValue: T);
begin
  if Length(AArr) > 0 then
    Fill<T>(AArr, 0, Length(AArr), AValue);
end;

class procedure TArrayUtilities.Fill<T>(var AArr: TArray<T>; AOffset, ACount: Integer);
begin
  Fill<T>(AArr, AOffset, ACount, Default(T));
end;

class procedure TArrayUtilities.Fill<T>(
  var AArr: TArray<T>;
  AOffset, ACount: Integer;
  const AValue: T);
var
  LI: Integer;
begin
  CheckRange((AOffset >= 0) and (ACount >= 0) and (AOffset + ACount <= Length(AArr)),
    'Invalid offset/count range');
  for LI := AOffset to AOffset + ACount - 1 do
    AArr[LI] := AValue;
end;

class function TArrayUtilities.Reverse<T>(const ASource: TArray<T>): TArray<T>;
var
  LI, LLen: Integer;
begin
  LLen := Length(ASource);
  SetLength(Result, LLen);
  for LI := 0 to LLen - 1 do
    Result[LI] := ASource[LLen - 1 - LI];
end;

class function TArrayUtilities.Any<T>(const AArr: TArray<T>; const APred: TPredicate<T>): Boolean;
var
  LItem: T;
begin
  for LItem in AArr do
    if APred(LItem) then
      Exit(True);
  Result := False;
end;

class function TArrayUtilities.ConstantTimeEquals(const AFirst, ASecond: TBytes): Boolean;
var
  LLenA, LLenB, LLen, LI: Integer;
  LDiff: Cardinal;
begin
  LLenA := Length(AFirst);
  LLenB := Length(ASecond);
  // Accumulate length mismatch into LDiff without branching
  LDiff := Cardinal(LLenA xor LLenB);
  // Compare up to the shorter length to avoid out-of-bounds,
  // but always iterate the full shorter length regardless of mismatches
  LLen := LLenA;
  if LLenB < LLen then
    LLen := LLenB;
  for LI := 0 to LLen - 1 do
    LDiff := LDiff or Cardinal(AFirst[LI] xor ASecond[LI]);
  Result := (LDiff = 0);
end;

end.
