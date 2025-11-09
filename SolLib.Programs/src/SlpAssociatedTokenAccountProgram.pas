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

unit SlpAssociatedTokenAccountProgram;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
  SlpPublicKey,
  SlpAccountDomain,
  SlpTransactionInstruction,
  SlpSysVars,
  SlpSystemProgram,
  SlpTokenProgram,
  SlpDecodedInstruction;

type
  /// <summary>
  /// Implements the Associated Token Account Program methods.
  /// <remarks>
  /// For more information see: https://spl.solana.com/associated-token-account
  /// </remarks>
  /// </summary>
  TAssociatedTokenAccountProgram = class
  private
    /// <summary>
    /// The program's name.
    /// </summary>
    const ProgramName = 'Associated Token Account Program';
    /// <summary>
    /// The instruction's name.
    /// </summary>
    const InstructionName = 'Create Associated Token Account';

    class var FProgramIdKey: IPublicKey;

    class function GetProgramIdKey: IPublicKey; static;
  public

     /// <summary>
     /// The address of the Associated Token Account (ATA) Program.
    /// </summary>
    class property ProgramIdKey: IPublicKey read GetProgramIdKey;

    class constructor Create;
    class destructor Destroy;

    /// <summary>
    /// Initialize a new transaction which interacts with the Associated Token Account Program to create
    /// a new associated token account.
    /// </summary>
    /// <param name="APayer">The public key of the account used to fund the associated token account.</param>
    /// <param name="AOwner">The public key of the owner account for the new associated token account.</param>
    /// <param name="AMint">The public key of the mint for the new associated token account.</param>
    /// <returns>The transaction instruction, returns nil whenever an associated token address could not be derived.</returns>
    class function CreateAssociatedTokenAccount(
      const APayer, AOwner, AMint: IPublicKey
    ): ITransactionInstruction; static;

    /// <summary>
    /// Derive the public key of the associated token account
    /// </summary>
    /// <param name="AOwner">The public key of the owner account for the new associated token account.</param>
    /// <param name="AMint">The public key of the mint for the new associated token account.</param>
    /// <returns>The public key of the associated token account if it could be found, otherwise nil.</returns>
    class function DeriveAssociatedTokenAccount(
      const AOwner, AMint: IPublicKey
    ): IPublicKey; static;

    /// <summary>
    /// Decodes an instruction created by the Associated Token Account Program.
    /// </summary>
    /// <param name="AData">The instruction data to decode.</param>
    /// <param name="AKeys">The account keys present in the transaction.</param>
    /// <param name="AKeyIndices">The indices of the account keys for the instruction as they appear in the transaction.</param>
    /// <returns>A decoded instruction.</returns>
    class function Decode(
      const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes
    ): IDecodedInstruction; static;
  end;

implementation

{ TAssociatedTokenAccountProgram }

class constructor TAssociatedTokenAccountProgram.Create;
begin
  FProgramIdKey := TPublicKey.Create('ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL');
end;

class destructor TAssociatedTokenAccountProgram.Destroy;
begin
  FProgramIdKey := nil;
end;

class function TAssociatedTokenAccountProgram.GetProgramIdKey: IPublicKey;
begin
  Result := FProgramIdKey;
end;

class function TAssociatedTokenAccountProgram.DeriveAssociatedTokenAccount(
  const AOwner, AMint: IPublicKey
): IPublicKey;
var
  LSeeds: TArray<TBytes>;
  LDerived: IPublicKey;
  LNonce: Byte;
  LOk: Boolean;
begin
  Result := nil;

  SetLength(LSeeds, 3);
  LSeeds[0] := AOwner.KeyBytes;
  LSeeds[1] := TTokenProgram.ProgramIdKey.KeyBytes;
  LSeeds[2] := AMint.KeyBytes;

  LOk := TPublicKey.TryFindProgramAddress(LSeeds, ProgramIdKey, LDerived, LNonce);
  if LOk then
    Result := LDerived;
end;

class function TAssociatedTokenAccountProgram.CreateAssociatedTokenAccount(
  const APayer, AOwner, AMint: IPublicKey
): ITransactionInstruction;
var
  LAssociated: IPublicKey;
  LKeys: TList<IAccountMeta>;
begin
  Result := nil;

  LAssociated := DeriveAssociatedTokenAccount(AOwner, AMint);
  if LAssociated = nil then
    Exit(nil);

  LKeys := TList<IAccountMeta>.Create;

  LKeys.Add(TAccountMeta.Writable(APayer, True));
  LKeys.Add(TAccountMeta.Writable(LAssociated, False));
  LKeys.Add(TAccountMeta.ReadOnly(AOwner, False));
  LKeys.Add(TAccountMeta.ReadOnly(AMint, False));
  LKeys.Add(TAccountMeta.ReadOnly(TSystemProgram.ProgramIdKey, False));
  LKeys.Add(TAccountMeta.ReadOnly(TTokenProgram.ProgramIdKey, False));
  LKeys.Add(TAccountMeta.ReadOnly(TSysVars.RentKey, False));

  Result := TTransactionInstruction.Create(ProgramIdKey.KeyBytes, LKeys, nil);
end;

class function TAssociatedTokenAccountProgram.Decode(
  const AData: TBytes; const AKeys: TArray<IPublicKey>; const AKeyIndices: TBytes
): IDecodedInstruction;
begin
  Result := TDecodedInstruction.Create;
  Result.PublicKey       := ProgramIdKey;
  Result.InstructionName := InstructionName;
  Result.ProgramName     := ProgramName;

  Result.Values := TDictionary<string, TValue>.Create;

  Result.Values.Add('Payer', TValue.From<IPublicKey>(AKeys[AKeyIndices[0]]));
  Result.Values.Add('Associated Token Account Address', TValue.From<IPublicKey>(AKeys[AKeyIndices[1]]));
  Result.Values.Add('Owner', TValue.From<IPublicKey>(AKeys[AKeyIndices[2]]));
  Result.Values.Add('Mint', TValue.From<IPublicKey>(AKeys[AKeyIndices[3]]));

  Result.InnerInstructions := TList<IDecodedInstruction>.Create();
end;

end.

