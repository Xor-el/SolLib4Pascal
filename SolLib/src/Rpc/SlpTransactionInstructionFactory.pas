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

unit SlpTransactionInstructionFactory;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpPublicKey,
  SlpAccountDomain,
  SlpTransactionInstruction;

type
  TTransactionInstructionFactory = class
  public
    class function Create(const AProgramId: IPublicKey;
                          const AKeys: TList<IAccountMeta>;
                          const AData: TBytes): ITransactionInstruction; static;
  end;

implementation

{ TTransactionInstructionFactory }

class function TTransactionInstructionFactory.Create(
  const AProgramId: IPublicKey;
  const AKeys: TList<IAccountMeta>;
  const AData: TBytes): ITransactionInstruction;
begin
  if AProgramId = nil then
    raise EArgumentNilException.Create('AProgramId');
  if AKeys = nil then
    raise EArgumentNilException.Create('AKeys');
  if AData = nil then
    raise EArgumentNilException.Create('AData');

  Result := TTransactionInstruction.Create(AProgramId.KeyBytes, AKeys, AData);
end;

end.

