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

unit TokenWalletExample;

interface

uses
  SysUtils,
  Generics.Collections,
  StrUtils,
  ExampleBase,
  SlpWallet,
  SlpTokenDomain,
  SlpAccount,
  SlpTokenWallet,
  SlpTokenMintResolver;

type
  /// <summary>
  /// Loads token accounts for a wallet on TestNet, prints individual accounts,
  /// filtered accounts (by symbol+mint), and consolidated balances.
  /// </summary>
  TTokenWalletExample = class(TExampleBase)
  private
   const
   // TestNet token minted by examples (symbol STT, 2 decimals)
    Mint = 'AHRNasvVB8UDkU9knqPcn4aVfRbnbVC9HJgSTBwbx8re';
    Name = 'Solnet Test Token';
    Symbol = 'STT';
    DecimalPlaces = 2;
    MnemonicWords = TExampleBase.MNEMONIC_WORDS;
  public
    procedure Run; override;
  end;

implementation

{ TTokenWalletExample }

procedure TTokenWalletExample.Run;
var
  LWallet: IWallet;
  LOwner: IAccount;
  LTokenResolver: ITokenMintResolver;
  LTokenWallet: ITokenWallet;
  LBalances: TList<ITokenWalletBalance>;
  LAccounts, LSubList: ITokenWalletFilterList;
  LMaxSym, LMaxName: Integer;
  LBalance: ITokenWalletBalance;
  LAccount: ITokenWalletAccount;

  // formatting helpers
  function PadRight(const AStr: string; const AWidth: Integer): string;
  begin
    if Length(AStr) >= AWidth then
      Exit(AStr);
    Result := AStr + StringOfChar(' ', AWidth - Length(AStr));
  end;

  function FormatQty(const AValue: Double; const AWidth: Integer): string;
  var
    LFS: TFormatSettings;
    LStr: string;
  begin
    LFS := TFormatSettings.Invariant; // use '.' decimal
    LStr := FormatFloat('0.####################', AValue, LFS); // up to 20 dp, no trailing zeros
    if Length(LStr) < AWidth then
      Result := StringOfChar(' ', AWidth - Length(LStr)) + LStr
    else
      Result := LStr;
  end;

begin
  // Wallet from mnemonic (Sollet-style: no passphrase for this example)
  LWallet := TWallet.Create(MnemonicWords);
  LOwner := LWallet.GetAccountByIndex(0);

  // Token mint resolver with the STT mint
  LTokenResolver := TTokenMintResolver.Create;
  LTokenResolver.Add(TTokenDef.Create(Mint, Name, Symbol, DecimalPlaces));

  // Load snapshot of wallet + sub-accounts
  LTokenWallet := TTokenWallet.Load(TestNetRpcClient, LTokenResolver, LOwner.PublicKey);

  // For consolidated/individual listings
  LBalances := LTokenWallet.Balances;
  LAccounts := LTokenWallet.TokenAccounts;

  try
    // Compute max widths for pretty columns
    LMaxSym := 0;
    LMaxName := 0;
    for LBalance in LBalances do
    begin
      if Length(LBalance.Symbol)    > LMaxSym  then LMaxSym := Length(LBalance.Symbol);
      if Length(LBalance.TokenName) > LMaxName then LMaxName := Length(LBalance.TokenName);
    end;

    Writeln('Individual Accounts...');
    for LAccount in LAccounts do
    begin
      Writeln(
        PadRight(LAccount.Symbol, LMaxSym), ' ',
        FormatQty(LAccount.QuantityDouble, 14), ' ',
        PadRight(LAccount.TokenName, LMaxName), ' ',
        LAccount.PublicKey, ' ',
        IfThen(LAccount.IsAssociatedTokenAccount, '[ATA]', '')
      );
    end;
    Writeln;

    Writeln('Filtered Accounts...');
    LSubList := LTokenWallet.TokenAccounts.WithSymbol(Symbol).WithMint(Mint);
    for LAccount in LSubList do
    begin
      Writeln(
        PadRight(LAccount.Symbol, LMaxSym), ' ',
        FormatQty(LAccount.QuantityDouble, 14), ' ',
        PadRight(LAccount.TokenName, LMaxName), ' ',
        LAccount.PublicKey, ' ',
        IfThen(LAccount.IsAssociatedTokenAccount, '[ATA]', '')
      );
    end;
    Writeln;

    // Show consolidated balances
    Writeln('Consolidated Balances...');
    for LBalance in LBalances do
    begin
      Writeln(
        PadRight(LBalance.Symbol, LMaxSym), ' ',
        FormatQty(LBalance.QuantityDouble, 14), ' ',
        PadRight(LBalance.TokenName, LMaxName), ' in ',
        LBalance.AccountCount, ' ',
        IfThen(LBalance.AccountCount = 1, 'account', 'accounts')
      );
    end;

    Writeln;
  finally
    LBalances.Free;
  end;
end;

end.

