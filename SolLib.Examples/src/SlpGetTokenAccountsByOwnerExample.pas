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

unit SlpGetTokenAccountsByOwnerExample;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  SlpExample,
  SlpRequestResult,
  SlpRpcModel,
  SlpRpcMessage,
  SlpWallet,
  SlpAccount,
  SlpPublicKey;

type
  TGetTokenAccountsByOwnerExample = class(TBaseExample)
  private
    const
      MnemonicWords = TBaseExample.MNEMONIC_WORDS;
      TokenProgramId = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
  public
    procedure Run; override;
  end;

implementation

{ TGetTokenAccountsByOwnerExample }

procedure TGetTokenAccountsByOwnerExample.Run;
var
  LWallet: IWallet;
  LOwner: IAccount;
  LOwnerMain, LDelegateKey: IPublicKey;
  LResOwnerTestNet, LResOwnerMainNet, LResDelegate: IRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
  LAcc: TTokenAccount;

  // helpers
  function UiOrEmpty(const S: string): string;
  begin
    if S <> '' then Result := S else Result := '0';
  end;

  function HasDelegatedAmount(const A: TTokenAccount): Boolean;
  begin
    Result := Assigned(A.Account) and
              Assigned(A.Account.Data) and
              Assigned(A.Account.Data.Parsed) and
              Assigned(A.Account.Data.Parsed.Info) and
              Assigned(A.Account.Data.Parsed.Info.DelegatedAmount);
  end;

begin
  //
  // TestNet: list token accounts for a deterministic owner (from mnemonic)
  //
  LWallet := TWallet.Create(MnemonicWords);
  LOwner  := LWallet.GetAccountByIndex(0);

  LResOwnerTestNet := TestNetRpcClient.GetTokenAccountsByOwner(
                 LOwner.PublicKey.Key,
                 '',
                 TokenProgramId
               );

  if (LResOwnerTestNet <> nil) and LResOwnerTestNet.WasSuccessful and (LResOwnerTestNet.Result <> nil) then
  begin
    for LAcc in LResOwnerTestNet.Result.Value do
    begin
      // Account: <pubkey> - Mint: <mint> - Balance: <ui>
      Writeln(Format('Account: %s - Mint: %s - Balance: %s',
        [LAcc.PublicKey,
         LAcc.Account.Data.Parsed.Info.Mint,
         UiOrEmpty(LAcc.Account.Data.Parsed.Info.TokenAmount.UiAmountString)
         ]));
    end;
  end
  else
    Writeln('GetTokenAccountsByOwner (TestNet) failed or returned no data.');

  // Owner on MainNet
  LOwnerMain := TPublicKey.Create('CuieVDEDtLo7FypA9SbLM9saXFdb1dsshEkyErMqkRQq');
  LResOwnerMainNet := MainNetRpcClient.GetTokenAccountsByOwner(
                     LOwnerMain.Key,
                     '',
                     TokenProgramId
                   );

  if (LResOwnerMainNet <> nil) and LResOwnerMainNet.WasSuccessful and (LResOwnerMainNet.Result <> nil) then
  begin
    for LAcc in LResOwnerMainNet.Result.Value do
    begin
      if HasDelegatedAmount(LAcc) then
        Writeln(Format(
          'Account: %s - Mint: %s - TokenBalance: %s - Delegate: %s - DelegatedBalance: %s',
          [LAcc.PublicKey,
           LAcc.Account.Data.Parsed.Info.Mint,
           UiOrEmpty(LAcc.Account.Data.Parsed.Info.TokenAmount.UiAmountString),
           LAcc.Account.Data.Parsed.Info.Delegate,
           UiOrEmpty(LAcc.Account.Data.Parsed.Info.DelegatedAmount.UiAmountString)
           ]))
      else
        Writeln(Format(
          'Account: %s - Mint: %s - TokenBalance: %s',
          [LAcc.PublicKey,
           LAcc.Account.Data.Parsed.Info.Mint,
           UiOrEmpty(LAcc.Account.Data.Parsed.Info.TokenAmount.UiAmountString)]
           ));
    end;
  end
  else
    Writeln('GetTokenAccountsByOwner (MainNet) failed or returned no data.');

  // By Delegate on MainNet
  LDelegateKey := TPublicKey.Create('4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T');

  // The example filters by a specific mint when querying delegates.
  LResDelegate := MainNetRpcClient.GetTokenAccountsByDelegate(
                    LDelegateKey.Key,
                    'StepAscQoEioFxxWGnh2sLBDFp9d8rvKz2Yp39iDpyT' // mint
                  );

  if (LResDelegate <> nil) and LResDelegate.WasSuccessful and (LResDelegate.Result <> nil) then
  begin
    for LAcc in LResDelegate.Result.Value do
    begin
      if HasDelegatedAmount(LAcc) then
        Writeln(Format(
          'Account: %s - Mint: %s - TokenBalance: %s - Delegate: %s - DelegatedBalance: %s',
          [LAcc.PublicKey,
           LAcc.Account.Data.Parsed.Info.Mint,
           UiOrEmpty(LAcc.Account.Data.Parsed.Info.TokenAmount.UiAmountString),
           LAcc.Account.Data.Parsed.Info.Delegate,
           UiOrEmpty(LAcc.Account.Data.Parsed.Info.DelegatedAmount.UiAmountString)]))
      else
        Writeln(Format(
          'Account: %s - Mint: %s - TokenBalance: %s',
          [LAcc.PublicKey,
           LAcc.Account.Data.Parsed.Info.Mint,
           UiOrEmpty(LAcc.Account.Data.Parsed.Info.TokenAmount.UiAmountString)]));
    end;
  end
  else
    Writeln('GetTokenAccountsByDelegate (MainNet) failed or returned no data.');
end;

end.

