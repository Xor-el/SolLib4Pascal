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
  System.Generics.Defaults,
  SlpSolLibTypes;

type
  TArrayUtils = class sealed
  private
    class procedure RequireRange(Cond: Boolean; const Msg: string); static;
  public

    /// <summary>
    /// Element-wise equality for arrays of any type T using a comparer.
    /// If <c>Comparer</c> is nil, uses <c>TEqualityComparer&lt;T&gt;.Default</c>.
    /// </summary>
    class function AreArraysEqual<T>(
      const A, B: TArray<T>;
      const Comparer: IEqualityComparer<T> = nil
    ): Boolean; overload; static;

    /// <summary>Concatenate two arrays of any type T.</summary>
    class function Concat<T>(const A, B: TArray<T>): TArray<T>; static;
    class function Slice<T>(const A: TArray<T>; Offset: Integer): TArray<T>; overload;
    /// <summary>
    /// Generic slice: returns A[Offset .. Offset+Count-1], clamped to bounds.
    /// - Managed T: element-wise copy (refcount-safe)
    /// - Unmanaged T: bulk Move
    /// </summary>
    class function Slice<T>(const A: TArray<T>; Offset, Count: Integer): TArray<T>; overload;

        {==================== COPY (PROCEDURES) ====================}

    /// <summary>
    /// Copy the entire Source to Dest starting at index 0.
    /// Raises if Dest is nil or Dest.Length &lt; Source.Length.
    /// </summary>
    class procedure Copy<T>(const Source: TArray<T>; var Dest: TArray<T>); overload; static;

    /// <summary>
    /// Copy Count items from Source[SrcIndex] into Dest[DestIndex].
    /// No resizing: raises if the copy will not fit.
    /// Overlap-safe. Managed types copied with assignments.
    /// </summary>
    class procedure Copy<T>(
      const Source: TArray<T>; SrcIndex: Integer;
      var Dest: TArray<T>; DestIndex: Integer;
      Count: Integer); overload; static;

    /// <summary>
    /// Copy entire Source into Dest starting at DestIndex.
    /// No resizing: raises if the copy will not fit.
    /// </summary>
    class procedure Copy<T>(
      const Source: TArray<T>;
      var Dest: TArray<T>;
      DestIndex: Integer); overload; static;

    /// <summary>
    /// Copy Source[SrcIndex..end] into Dest starting at DestIndex.
    /// No resizing: raises if the copy will not fit.
    /// </summary>
    class procedure Copy<T>(
      const Source: TArray<T>; SrcIndex: Integer;
      var Dest: TArray<T>; DestIndex: Integer); overload; static;

    {==================== COPY (FUNCTIONS) ====================}

    /// <summary>
    /// Returns a NEW array that is a copy of Source (entire array).
    /// </summary>
    class function Copy<T>(const Source: TArray<T>): TArray<T>; overload; static;

    /// <summary>
    /// Returns a NEW array with the first Count items of Source.
    /// Raises if Count &lt; 0 or Count &gt; Source.Length.
    /// </summary>
    class function Copy<T>(
      const Source: TArray<T>; Count: Integer): TArray<T>; overload; static;

    /// <summary>
    /// Returns a NEW array with Source[Index..Index+Count-1].
    /// Range-checked.
    /// </summary>
    class function Copy<T>(
      const Source: TArray<T>; Index, Count: Integer): TArray<T>; overload; static;

    class function Copy<T>(
      const Source: TArray<T>; const Cloner: TFunc<T, T>): TArray<T>; overload; static;

    class function IndexOf<T>(
      const Values: TArray<T>; const Predicate: TFunc<T, Boolean>;
      out Index: Integer): Boolean; overload; static;

    class function IndexOf<T>(
      const Values: TArray<T>; const Predicate: TFunc<T, Boolean>;
      const StartIndex, Count: Integer; out Index: Integer): Boolean; overload; static;

    /// <summary>
    /// Overwrite the entire array with zeros (0).
    /// </summary>
    class procedure Fill<T>(var Arr: TArray<T>); overload; static;

    /// <summary>
    /// Overwrite the entire array with the specified value.
    /// </summary>
    class procedure Fill<T>(var Arr: TArray<T>; const Value: T); overload; static;

    /// <summary>
    /// Overwrite a subrange of the array starting at Offset for Count elements with zero.
    /// </summary>
    class procedure Fill<T>(var Arr: TArray<T>; const Offset, Count: Integer); overload; static;

    /// <summary>
    /// Overwrite a subrange of the array starting at Offset for Count elements with a specific value.
    /// </summary>
    class procedure Fill<T>(var Arr: TArray<T>; const Offset, Count: Integer; const Value: T); overload; static;

    class function Reverse<T>(const Source: TArray<T>): TArray<T>; static;

    class function Any<T>(const L: TArray<T>; const Pred: TPredicate<T>): Boolean; static;
  end;

implementation

{ TArrayUtils }

class procedure TArrayUtils.RequireRange(Cond: Boolean; const Msg: string);
begin
  if not Cond then
    raise ERangeError.Create(Msg);
end;

class function TArrayUtils.AreArraysEqual<T>(
  const A, B: TArray<T>;
  const Comparer: IEqualityComparer<T>
): Boolean;
var
  LA: Integer;
  Cmp: IEqualityComparer<T>;
begin
  // Same backing pointer? Equal (covers same dynamic array instance).
  if Pointer(A) = Pointer(B) then
    Exit(True);

  LA := Length(A);
  if LA <> Length(B) then
    Exit(False);
  if LA = 0 then
    Exit(True);

  // If caller gave a comparer, we must honor it.
  if Assigned(Comparer) then
    Cmp := Comparer
  else
    Cmp := TEqualityComparer<T>.Default;

  // Fast path: unmanaged element type AND no custom comparer
  // (Default comparer for unmanaged types would use = anyway; this avoids per-item loop.)
  if (not Assigned(Comparer)) and (not IsManagedType(TypeInfo(T))) then
  begin
    // Bitwise compare (NOTE: for floats, this is *bitwise* equality:
    // NaN vs NaN may compare False unless payloads match exactly.)
    Exit(CompareMem(@A[0], @B[0], LA * SizeOf(T)));
  end;

  // Fallback: per-element equality
  for var i := 0 to LA - 1 do
    if not Cmp.Equals(A[i], B[i]) then
      Exit(False);

  Result := True;
end;

class function TArrayUtils.Concat<T>(const A, B: TArray<T>): TArray<T>;
var
  LA, LB, i: Integer;
  Managed: Boolean;
begin
  LA := Length(A);
  LB := Length(B);
  SetLength(Result, LA + LB);

  Managed := IsManagedType(TypeInfo(T));

  if Managed then
  begin
    // Managed types (string, interface, dynamic array, variant, or records containing them):
    // copy via assignment to keep ref-counts correct
    for i := 0 to LA - 1 do
      Result[i] := A[i];
    for i := 0 to LB - 1 do
      Result[LA + i] := B[i];
  end
  else
  begin
    // Unmanaged (Integer, Double, pointers, class refs, records without managed fields): raw copy is fine
    if LA > 0 then
      Move(A[0], Result[0], LA * SizeOf(T));
    if LB > 0 then
      Move(B[0], Result[LA], LB * SizeOf(T));
  end;
end;

class function TArrayUtils.Slice<T>(const A: TArray<T>; Offset: Integer): TArray<T>;
begin
  Result := Slice<T>(A, Offset, Length(A) - Offset);
end;

class function TArrayUtils.Slice<T>(const A: TArray<T>; Offset, Count: Integer): TArray<T>;
var
  L: Integer;
begin
  L := Length(A);

  // Clamp offset
  if Offset < 0 then
    Offset := 0
  else if Offset > L then
    Offset := L;

  // Clamp count
  if Count < 0 then
    Count := 0
  else if Offset + Count > L then
    Count := L - Offset;

  Result := Copy<T>(A, Offset, Count);
end;

{==================== COPY (PROCEDURES) ====================}

class procedure TArrayUtils.Copy<T>(
  const Source: TArray<T>;
  var Dest: TArray<T>);
var
  SrcLen: Integer;
begin
  SrcLen := Length(Source);
  RequireRange(Length(Dest) >= SrcLen, 'Destination too small for copy.');
  if SrcLen = 0 then
    Exit;
  Copy<T>(Source, 0, Dest, 0, SrcLen);
end;

class procedure TArrayUtils.Copy<T>(
  const Source: TArray<T>; SrcIndex: Integer;
  var Dest: TArray<T>; DestIndex: Integer;
  Count: Integer);
var
  SrcLen, DestLen: Integer;
  Managed, SameArray, OverlapBackward: Boolean;
  i: Integer;
begin
  RequireRange(SrcIndex >= 0, 'SrcIndex must be >= 0.');
  RequireRange(DestIndex >= 0, 'DestIndex must be >= 0.');
  RequireRange(Count >= 0, 'Count must be >= 0.');

  SrcLen := Length(Source);
  DestLen := Length(Dest);

  RequireRange(SrcIndex <= SrcLen, 'SrcIndex out of range.');
  RequireRange(Count <= (SrcLen - SrcIndex), 'Count exceeds Source length.');
  RequireRange(DestIndex <= DestLen, 'DestIndex out of range.');
  RequireRange(Count <= (DestLen - DestIndex), 'Destination too small for copy.');

  if Count = 0 then Exit;

  Managed := IsManagedType(TypeInfo(T));
  SameArray := Pointer(Source) = Pointer(Dest);

  if Managed then
  begin
    // If both slices overlap in the same array and destination region starts
    // inside the source region but AFTER it, we need backward copy.
    OverlapBackward := SameArray
      and (DestIndex > SrcIndex)
      and (DestIndex < SrcIndex + Count);

    if OverlapBackward then
    begin
      for i := Count - 1 downto 0 do
        Dest[DestIndex + i] := Source[SrcIndex + i];
    end
    else
    begin
      for i := 0 to Count - 1 do
        Dest[DestIndex + i] := Source[SrcIndex + i];
    end;
  end
  else
  begin
    // Unmanaged: Move is memmove-like (overlap safe)
    Move(Source[SrcIndex], Dest[DestIndex], Count * SizeOf(T));
  end;
end;

class procedure TArrayUtils.Copy<T>(
  const Source: TArray<T>;
  var Dest: TArray<T>;
  DestIndex: Integer);
begin
  Copy<T>(Source, 0, Dest, DestIndex, Length(Source));
end;

class procedure TArrayUtils.Copy<T>(
  const Source: TArray<T>; SrcIndex: Integer;
  var Dest: TArray<T>; DestIndex: Integer);
begin
  RequireRange(SrcIndex >= 0, 'SrcIndex must be >= 0.');
  Copy<T>(Source, SrcIndex, Dest, DestIndex, Length(Source) - SrcIndex);
end;

{==================== COPY (FUNCTIONS) ====================}

class function TArrayUtils.Copy<T>(
  const Source: TArray<T>): TArray<T>;
begin
  Result := Copy<T>(Source, 0, Length(Source));
end;

class function TArrayUtils.Copy<T>(
  const Source: TArray<T>; Count: Integer): TArray<T>;
begin
  RequireRange(Count >= 0, 'Count must be >= 0.');
  RequireRange(Count <= Length(Source), 'Count exceeds Source length.');
  Result := Copy<T>(Source, 0, Count);
end;

class function TArrayUtils.Copy<T>(
  const Source: TArray<T>; Index, Count: Integer): TArray<T>;
var
  L, i: Integer;
  Managed: Boolean;
begin
  L := Length(Source);
  RequireRange(Index >= 0, 'Index must be >= 0.');
  RequireRange(Count >= 0, 'Count must be >= 0.');
  RequireRange(Index <= L, 'Index out of range.');
  RequireRange(Count <= (L - Index), 'Index+Count exceeds Source length.');

  SetLength(Result, Count);
  if Count = 0 then Exit;

  Managed := IsManagedType(TypeInfo(T));
  if Managed then
  begin
    for i := 0 to Count - 1 do
      Result[i] := Source[Index + i];
  end
  else
  begin
    Move(Source[Index], Result[0], Count * SizeOf(T));
  end;
end;

class function TArrayUtils.Copy<T>(
  const Source: TArray<T>;
  const Cloner: TFunc<T, T>): TArray<T>;
var
  I, L, Done: Integer;
  IsClassT: Boolean;
  Obj: TObject;
begin
  if not Assigned(Cloner) then
    raise EArgumentNilException.Create('Cloner must be assigned');

  L := Length(Source);
  SetLength(Result, L);

  // Detect at runtime whether T is a class type
  IsClassT := GetTypeKind(TypeInfo(T)) = tkClass;

  Done := 0;
  try
    for I := 0 to L - 1 do
    begin
      Result[I] := Cloner(Source[I]); // may raise
      Inc(Done);
    end;
  except
    if IsClassT then
    begin
      // Free only successfully cloned objects
      for I := 0 to Done - 1 do
      begin
        Obj := TObject(PPointer(@Result[I])^);
        if Assigned(Obj) then
          Obj.Free;
      end;

    // Reset only freed entries (the rest are still default)
     if Done > 0 then
      Fill<T>(Result, 0, Done, Default(T));
    end;

    raise;
  end;
end;

class function TArrayUtils.IndexOf<T>(
  const Values: TArray<T>;
  const Predicate: TFunc<T, Boolean>;
  out Index: Integer): Boolean;
begin
  Result := IndexOf<T>(Values, Predicate, 0, Length(Values), Index);
end;

class function TArrayUtils.IndexOf<T>(
  const Values: TArray<T>;
  const Predicate: TFunc<T, Boolean>;
  const StartIndex, Count: Integer;
  out Index: Integer): Boolean;
var
  I, LastIndex, Limit: Integer;
begin
  if not Assigned(Predicate) then
    raise Exception.Create('Predicate function cannot be nil.');

  if (StartIndex < 0) or (StartIndex > Length(Values)) then
    raise Exception.CreateFmt('StartIndex (%d) is out of bounds.', [StartIndex]);

  if (Count < 0) then
    raise Exception.CreateFmt('Count (%d) cannot be negative.', [Count]);

  Limit := Min(Length(Values), StartIndex + Count);
  LastIndex := Limit - 1;

  for I := StartIndex to LastIndex do
    if Predicate(Values[I]) then
    begin
      Index := I;
      Exit(True);
    end;

  Index := -1;
  Result := False;
end;

class procedure TArrayUtils.Fill<T>(var Arr: TArray<T>);
begin
  if Length(Arr) = 0 then
    Exit;
  Fill<T>(Arr, 0, Length(Arr), Default(T));
end;

class procedure TArrayUtils.Fill<T>(var Arr: TArray<T>; const Value: T);
begin
  if Length(Arr) = 0 then
    Exit;
  Fill<T>(Arr, 0, Length(Arr), Value);
end;

class procedure TArrayUtils.Fill<T>(var Arr: TArray<T>; const Offset, Count: Integer);
begin
  Fill<T>(Arr, Offset, Count, Default(T));
end;

class procedure TArrayUtils.Fill<T>(
  var Arr: TArray<T>;
  const Offset, Count: Integer;
  const Value: T);
var
  I, ElemSize: Integer;
  Managed: Boolean;
  P: Pointer;
  NeedsLoop: Boolean;
begin
  if (Offset < 0) or (Count < 0) or (Offset + Count > Length(Arr)) then
    raise EArgumentOutOfRangeException.Create('Invalid offset/count range.');

  if Count = 0 then
    Exit;

  Managed := IsManagedType(TypeInfo(T));
  ElemSize := SizeOf(T);
  P := @Arr[Offset];

  // quick exit
  if (ElemSize = 0) or (P = nil) then
    Exit;

  // Determine if we must use loop
  NeedsLoop :=
    Managed or              // managed types (strings, interfaces, etc.)
    ((ElemSize > 1) and     // multi-byte types
     (PByte(@Value)^ <> 0)); // non-zero fill value

  if NeedsLoop then
  begin
    // Safe per-element assignment
    for I := Offset to Offset + Count - 1 do
      Arr[I] := Value;
  end
  else
  begin
    // Fast FillChar path:
    //   - All unmanaged, 1-byte types (Byte, ShortInt, AnsiChar)
    //   - Any type filled with zero
    FillChar(P^, ElemSize * Count, PByte(@Value)^);
  end;
end;

class function TArrayUtils.Reverse<T>(const Source: TArray<T>): TArray<T>;
var
  I, L: Integer;
begin
  L := Length(Source);
  SetLength(Result, L);

  for I := 0 to L - 1 do
    Result[I] := Source[L - 1 - I];
end;

class function TArrayUtils.Any<T>(const L: TArray<T>; const Pred: TPredicate<T>): Boolean;
var
  Item: T;
begin
  for Item in L do
    if Pred(Item) then
      Exit(True);
  Result := False;
end;


end.

