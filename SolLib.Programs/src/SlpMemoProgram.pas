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

unit SlpMemoProgram;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
  SlpArrayUtils,
  SlpPublicKey,
  SlpAccountDomain,
  SlpTransactionInstruction,
  SlpDecodedInstruction;

type
  /// <summary>
  /// Implements the Memo Program methods.
  /// <remarks>
  /// For more information see: https://spl.solana.com/memo
  /// </remarks>
  /// </summary>
  TMemoProgram = class
  private
    const ProgramName     = 'Memo Program';
    const InstructionName = 'New Memo';

    class var FProgramIdKey: IPublicKey;
    class var FProgramIdKeyV2: IPublicKey;

    class constructor Create;
    class destructor Destroy;

    class function GetProgramIdKey: IPublicKey; static;
    class function GetProgramIdKeyV2: IPublicKey; static;

  public
    /// <summary>
    /// The public key of the Memo Program.
    /// </summary>
    class property ProgramIdKey: IPublicKey read GetProgramIdKey;

    /// <summary>
    /// The public key of the Memo Program V2.
    /// </summary>
    class property ProgramIdKeyV2: IPublicKey read GetProgramIdKeyV2;

    /// <summary>
    /// Initialize a new transaction instruction which interacts with the Memo Program.
    /// </summary>
    /// <param name="AAccount">The public key of the account associated with the memo.</param>
    /// <param name="AMemo">The memo to be included in the transaction.</param>
    /// <returns>The <see cref="ITransactionInstruction"/> which includes the memo data.</returns>
    class function NewMemo(const AAccount: IPublicKey; const AMemo: string): ITransactionInstruction; static;

    /// <summary>
    /// Initialize a new transaction instruction which interacts with the Memo Program.
    /// </summary>
    /// <param name="AMemo">The memo to be included in the transaction.</param>
    /// <param name="AAccount">The public key of the account associated with the memo.</param>
    /// <returns>The <see cref="ITransactionInstruction"/> which includes the memo data.</returns>
    class function NewMemoV2(const AMemo: string; const AAccount: IPublicKey = nil): ITransactionInstruction; static;

    /// <summary>
    /// Decodes an instruction created by the Memo Program.
    /// </summary>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    /// <returns>A decoded instruction.</returns>
    class function Decode(const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes): IDecodedInstruction; static;
  end;

implementation

{ TMemoProgram }

class constructor TMemoProgram.Create;
begin
  FProgramIdKey   := TPublicKey.Create('Memo1UhkJRfHyvLMcVucJwxXeuD728EqVDDwQDxFMNo');
  FProgramIdKeyV2 := TPublicKey.Create('MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr');
end;

class destructor TMemoProgram.Destroy;
begin
  FProgramIdKey := nil;
  FProgramIdKeyV2 := nil;
end;

class function TMemoProgram.GetProgramIdKey: IPublicKey;
begin
  Result := FProgramIdKey;
end;

class function TMemoProgram.GetProgramIdKeyV2: IPublicKey;
begin
  Result := FProgramIdKeyV2;
end;

class function TMemoProgram.NewMemo(
  const AAccount: IPublicKey; const AMemo: string
): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
  LMemoBytes: TBytes;
begin
  if AMemo = '' then
    raise EArgumentNilException.Create('AMemo');

  if not Assigned(AAccount) then
    raise EArgumentNilException.Create('AAccount');

  LKeys := TList<IAccountMeta>.Create;
  LKeys.Add(TAccountMeta.ReadOnly(AAccount, True));

  LMemoBytes := TEncoding.UTF8.GetBytes(AMemo);

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, LMemoBytes);
end;

class function TMemoProgram.NewMemoV2(
  const AMemo: string; const AAccount: IPublicKey
): ITransactionInstruction;
var
  LKeys: TList<IAccountMeta>;
  LMemoBytes: TBytes;
begin
  if AMemo = '' then
    raise EArgumentNilException.Create('AMemo');

  LKeys := TList<IAccountMeta>.Create;
  if AAccount <> nil then
    LKeys.Add(TAccountMeta.ReadOnly(AAccount, True));

  LMemoBytes := TEncoding.UTF8.GetBytes(AMemo);

  Result := TTransactionInstruction.Create(ProgramIdKeyV2.KeyBytes, LKeys, LMemoBytes);
end;

class function TMemoProgram.Decode(
  const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes
): IDecodedInstruction;
var
  LMemoStr : string;
  LUseV1   : Boolean;
begin

  LUseV1 := TArrayUtils.Any<IPublicKey>(AKeys,
    function(AKey: IPublicKey): Boolean
    begin
      Result := SameStr(AKey.Key, ProgramIdKey.Key);
    end
  );

  Result := TDecodedInstruction.Create;

  if LUseV1
    then Result.PublicKey := ProgramIdKey
    else Result.PublicKey := ProgramIdKeyV2;

  Result.InstructionName   := InstructionName;
  Result.ProgramName       := ProgramName;
  Result.InnerInstructions := TList<IDecodedInstruction>.Create();
  Result.Values  := TDictionary<string, TValue>.Create;

  LMemoStr := TEncoding.UTF8.GetString(AData);

  if Length(AKeyIndices) > 0 then
  begin
    Result.Values.Add('Signer', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
    Result.Values.Add('Memo', LMemoStr);
  end
  else
    Result.Values.Add('Memo', LMemoStr);
end;


end.

