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

unit SlpGetTokenAccountsByOwnerExample;

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
  LTokenAccData: TTokenAccountData;

  // helpers
  function UiOrEmpty(const S: string): string;
  begin
    if S <> '' then Result := S else Result := '0';
  end;

  function HasDelegatedAmount(const A: TTokenAccountInfoDetails): Boolean;
  begin
    Result := Assigned(A.DelegatedAmount);
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
     if not Assigned(LAcc)
     or not Assigned(LAcc.Account)
     or LAcc.Account.Data.IsEmpty then
      Continue;

      LTokenAccData := LAcc.Account.Data.AsType<TTokenAccountData>;
      // Account: <pubkey> - Mint: <mint> - Balance: <ui>
      Writeln(Format('Account: %s - Mint: %s - Balance: %s',
        [LAcc.PublicKey,
         LTokenAccData.Parsed.Info.Mint,
         UiOrEmpty(LTokenAccData.Parsed.Info.TokenAmount.UiAmountString)
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
     if not Assigned(LAcc)
     or not Assigned(LAcc.Account)
     or LAcc.Account.Data.IsEmpty then
      Continue;

     LTokenAccData := LAcc.Account.Data.AsType<TTokenAccountData>;
      if HasDelegatedAmount(LTokenAccData.Parsed.Info) then
        Writeln(Format(
          'Account: %s - Mint: %s - TokenBalance: %s - Delegate: %s - DelegatedBalance: %s',
          [LAcc.PublicKey,
           LTokenAccData.Parsed.Info.Mint,
           UiOrEmpty(LTokenAccData.Parsed.Info.TokenAmount.UiAmountString),
           LTokenAccData.Parsed.Info.Delegate,
           UiOrEmpty(LTokenAccData.Parsed.Info.DelegatedAmount.UiAmountString)
           ]))
      else
        Writeln(Format(
          'Account: %s - Mint: %s - TokenBalance: %s',
          [LAcc.PublicKey,
           LTokenAccData.Parsed.Info.Mint,
           UiOrEmpty(LTokenAccData.Parsed.Info.TokenAmount.UiAmountString)]
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
     if not Assigned(LAcc)
     or not Assigned(LAcc.Account)
     or LAcc.Account.Data.IsEmpty then
      Continue;

     LTokenAccData := LAcc.Account.Data.AsType<TTokenAccountData>;
      if HasDelegatedAmount(LTokenAccData.Parsed.Info) then
        Writeln(Format(
          'Account: %s - Mint: %s - TokenBalance: %s - Delegate: %s - DelegatedBalance: %s',
          [LAcc.PublicKey,
           LTokenAccData.Parsed.Info.Mint,
           UiOrEmpty(LTokenAccData.Parsed.Info.TokenAmount.UiAmountString),
           LTokenAccData.Parsed.Info.Delegate,
           UiOrEmpty(LTokenAccData.Parsed.Info.DelegatedAmount.UiAmountString)]))
      else
        Writeln(Format(
          'Account: %s - Mint: %s - TokenBalance: %s',
          [LAcc.PublicKey,
           LTokenAccData.Parsed.Info.Mint,
           UiOrEmpty(LTokenAccData.Parsed.Info.TokenAmount.UiAmountString)]));
    end;
  end
  else
    Writeln('GetTokenAccountsByDelegate (MainNet) failed or returned no data.');
end;

end.

