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

unit SlpTransactionInstruction;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpShortVectorEncoding,
  SlpAccountDomain,
  SlpArrayUtils;

type
  ITransactionInstruction = interface
    ['{7A0A5B6D-7E0B-4D6E-9E3C-8F65B5F6AF3F}']
    function GetProgramId: TBytes;
    function GetKeys: TList<IAccountMeta>;
    function GetData: TBytes;

    function Clone: ITransactionInstruction;

    property ProgramId: TBytes read GetProgramId;
    property Keys: TList<IAccountMeta> read GetKeys;
    property Data: TBytes read GetData;
  end;

  IVersionedTransactionInstruction = interface(ITransactionInstruction)
    ['{E3B2E5C2-2D53-4E9A-A9F6-6E67C5A56F11}']
    function GetKeyIndices: TBytes;
    property KeyIndices: TBytes read GetKeyIndices;
  end;

  ICompiledInstruction = interface
    ['{B65A7C1E-2B9E-48C0-8C7F-5F8D9E63C2FA}']
    function GetProgramIdIndex: Byte;
    function GetKeyIndicesCount: TBytes;
    function GetKeyIndices: TBytes;
    function GetDataLength: TBytes;
    function GetData: TBytes;

    /// Total item length in the serialized buffer
    function ItemCount: Integer;

    property ProgramIdIndex: Byte read GetProgramIdIndex;
    property KeyIndicesCount: TBytes read GetKeyIndicesCount;
    property KeyIndices: TBytes read GetKeyIndices;
    property DataLength: TBytes read GetDataLength;
    property Data: TBytes read GetData;
  end;

  TCompiledInstructionDecode = record
    Instruction: ICompiledInstruction;
    Length: Integer;
  end;

  TTransactionInstruction = class(TInterfacedObject, ITransactionInstruction)
  private
    FProgramId, FData: TBytes;
    FKeys: TList<IAccountMeta>;

    function GetProgramId: TBytes;
    function GetKeys: TList<IAccountMeta>;
    function GetData: TBytes;

    function Clone: ITransactionInstruction;

    class function Make(const AProgramId: TBytes;
  const AKeys: TList<IAccountMeta>; const AData: TBytes): ITransactionInstruction; static;
  public
    constructor Create(const AProgramId: TBytes;
      const AKeys: TList<IAccountMeta>; const AData: TBytes);
    destructor Destroy; override;
  end;

  TVersionedTransactionInstruction = class(TTransactionInstruction, IVersionedTransactionInstruction)
  private
    FKeyIndices: TBytes;

    function GetKeyIndices: TBytes;

  public
    constructor Create(const AProgramId: TBytes;
      const AKeys: TList<IAccountMeta>; const AData, AKeyIndices: TBytes);

    function Make(const AProgramId: TBytes;
      const AKeys: TList<IAccountMeta>; const AData, AKeyIndices: TBytes)
      : IVersionedTransactionInstruction;
  end;

  TCompiledInstruction = class(TInterfacedObject, ICompiledInstruction)
  public type
    Layout = record
    public const
      ProgramIdIndexOffset = 0;
    end;
  private
    FProgramIdIndex: Byte;
    FKeyIndicesCount: TBytes;
    FKeyIndices: TBytes;
    FDataLength: TBytes;
    FData: TBytes;

    function GetProgramIdIndex: Byte;
    function GetKeyIndicesCount: TBytes;
    function GetKeyIndices: TBytes;
    function GetDataLength: TBytes;
    function GetData: TBytes;

    function ItemCount: Integer;

    class function Make(const AProgramIdIndex: Byte;
      const AKeyIndicesCount, AKeyIndices, ADataLength, AData: TBytes)
      : ICompiledInstruction; static;
  public
    constructor Create(const AProgramIdIndex: Byte;
      const AKeyIndicesCount, AKeyIndices, ADataLength, AData: TBytes);

    class function Deserialize(const Data: TBytes) : TCompiledInstructionDecode; static;

  end;

implementation

{ TTransactionInstruction }

constructor TTransactionInstruction.Create(const AProgramId: TBytes;
  const AKeys: TList<IAccountMeta>; const AData: TBytes);
begin
  inherited Create;
  FProgramId := AProgramId;
  FData      := AData;
  FKeys := AKeys;
end;

destructor TTransactionInstruction.Destroy;
begin
  if Assigned(FKeys) then
    FKeys.Free;
  inherited;
end;

function TTransactionInstruction.Clone: ITransactionInstruction;
var
  NewKeys: TList<IAccountMeta>;
  SrcMeta, DstMeta: IAccountMeta;
begin
  NewKeys := nil;

  if Assigned(FKeys) then
  begin
    NewKeys := TList<IAccountMeta>.Create;
    try
      for SrcMeta in FKeys do
      begin
        if Assigned(SrcMeta) then
          DstMeta := SrcMeta.Clone
        else
          DstMeta := nil;
        NewKeys.Add(DstMeta);
      end;
    except
      NewKeys.Free;
      raise;
    end;
  end;

  Result := Make(
              TArrayUtils.Copy<Byte>(FProgramId),
              NewKeys,
              TArrayUtils.Copy<Byte>(FData)
            );
end;

function TTransactionInstruction.GetData: TBytes;
begin
  Result := FData;
end;

function TTransactionInstruction.GetKeys: TList<IAccountMeta>;
begin
  Result := FKeys;
end;

function TTransactionInstruction.GetProgramId: TBytes;
begin
  Result := FProgramId;
end;

class function TTransactionInstruction.Make(const AProgramId: TBytes;
  const AKeys: TList<IAccountMeta>; const AData: TBytes): ITransactionInstruction;
begin
  Result := TTransactionInstruction.Create(AProgramId, AKeys, AData);
end;

{ TVersionedTransactionInstruction }

constructor TVersionedTransactionInstruction.Create(const AProgramId: TBytes;
  const AKeys: TList<IAccountMeta>; const AData, AKeyIndices: TBytes);
begin
  inherited Create(AProgramId, AKeys, AData);
  FKeyIndices := AKeyIndices;
end;

function TVersionedTransactionInstruction.GetKeyIndices: TBytes;
begin
  Result := FKeyIndices;
end;

function TVersionedTransactionInstruction.Make(const AProgramId: TBytes;
  const AKeys: TList<IAccountMeta>; const AData, AKeyIndices: TBytes)
  : IVersionedTransactionInstruction;
begin
  Result := TVersionedTransactionInstruction.Create(AProgramId, AKeys, AData, AKeyIndices);
end;

{ TCompiledInstruction }

constructor TCompiledInstruction.Create(const AProgramIdIndex: Byte;
  const AKeyIndicesCount, AKeyIndices, ADataLength, AData: TBytes);
begin
  inherited Create;
  FProgramIdIndex := AProgramIdIndex;
  FKeyIndicesCount := AKeyIndicesCount;
  FKeyIndices := AKeyIndices;
  FDataLength := ADataLength;
  FData := AData;
end;

function TCompiledInstruction.GetData: TBytes;
begin
  Result := FData;
end;

function TCompiledInstruction.GetDataLength: TBytes;
begin
  Result := FDataLength;
end;

function TCompiledInstruction.GetKeyIndices: TBytes;
begin
  Result := FKeyIndices;
end;

function TCompiledInstruction.GetKeyIndicesCount: TBytes;
begin
  Result := FKeyIndicesCount;
end;

function TCompiledInstruction.GetProgramIdIndex: Byte;
begin
  Result := FProgramIdIndex;
end;

function TCompiledInstruction.ItemCount: Integer;
begin
  Result := 1 + Length(FKeyIndicesCount) + Length(FKeyIndices) +
            Length(FDataLength) + Length(FData);
end;

class function TCompiledInstruction.Deserialize(const Data: TBytes): TCompiledInstructionDecode;
var
  InstructionLength: Integer;
  LProgramIdIndex: Byte;
  EncodedKeyIndicesLength: TBytes;
  KeyIndicesLength, KeyIndicesLengthEncodedLength: Integer;
  LKeyIndices: TBytes;
  EncodedDataLength: TBytes;
  LDataLength, DataLengthEncodedLength: Integer;
  InstructionEncodedData: TBytes;
begin
  InstructionLength := 0;

  LProgramIdIndex := Data[TCompiledInstruction.Layout.ProgramIdIndexOffset];
  Inc(InstructionLength, 1);

  EncodedKeyIndicesLength := TArrayUtils.Slice<Byte>(Data, InstructionLength,
    TShortVectorEncoding.SpanLength);
  with TShortVectorEncoding.DecodeLength(EncodedKeyIndicesLength) do
  begin
    KeyIndicesLength := Value;
    KeyIndicesLengthEncodedLength := Length;
  end;
  Inc(InstructionLength, KeyIndicesLengthEncodedLength);

  LKeyIndices := TArrayUtils.Slice<Byte>(Data, InstructionLength, KeyIndicesLength);
  Inc(InstructionLength, KeyIndicesLength);

  if Length(Data) > InstructionLength + TShortVectorEncoding.SpanLength then
    EncodedDataLength := TArrayUtils.Slice<Byte>(Data, InstructionLength, TShortVectorEncoding.SpanLength)
  else
    EncodedDataLength := TArrayUtils.Slice<Byte>(Data, InstructionLength, Length(Data) - InstructionLength);

  with TShortVectorEncoding.DecodeLength(EncodedDataLength) do
  begin
    LDataLength := Value;
    DataLengthEncodedLength := Length;
  end;
  Inc(InstructionLength, DataLengthEncodedLength);

  InstructionEncodedData := TArrayUtils.Slice<Byte>(Data, InstructionLength, LDataLength);
  Inc(InstructionLength, LDataLength);

  Result.Instruction := Make(
    LProgramIdIndex,
    TArrayUtils.Slice<Byte>(EncodedKeyIndicesLength, 0, KeyIndicesLengthEncodedLength),
    LKeyIndices,
    TArrayUtils.Slice<Byte>(EncodedDataLength, 0, DataLengthEncodedLength),
    InstructionEncodedData
  );
  Result.Length := InstructionLength;
end;

class function TCompiledInstruction.Make(const AProgramIdIndex: Byte;
  const AKeyIndicesCount, AKeyIndices, ADataLength,
  AData: TBytes): ICompiledInstruction;
begin
 Result := TCompiledInstruction.Create(AProgramIdIndex, AKeyIndicesCount, AKeyIndices, ADataLength, AData);
end;

end.

