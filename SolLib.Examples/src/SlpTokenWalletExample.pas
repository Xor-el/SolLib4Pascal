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

unit SlpTokenWalletExample;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.StrUtils,
  SlpExample,
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
  TTokenWalletExample = class(TBaseExample)
  private
   const
   // TestNet token minted by examples (symbol STT, 2 decimals)
    Mint = 'AHRNasvVB8UDkU9knqPcn4aVfRbnbVC9HJgSTBwbx8re';
    Name = 'Solnet Test Token';
    Symbol  = 'STT';
    DecimalPlaces = 2;
    MnemonicWords = TBaseExample.MNEMONIC_WORDS;
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
  LAccounts, LSublist: ITokenWalletFilterList;
  LMaxSym, LMaxName: Integer;
  B: ITokenWalletBalance;
  A: ITokenWalletAccount;

  // formatting helpers
  function PadRight(const S: string; const AWidth: Integer): string;
  begin
    if Length(S) >= AWidth then
      Exit(S);
    Result := S + StringOfChar(' ', AWidth - Length(S));
  end;

  function FormatQty(const V: Double; const AWidth: Integer): string;
  var
    FS: TFormatSettings;
    S: string;
  begin
    FS := TFormatSettings.Invariant; // use '.' decimal
    S := FormatFloat('0.####################', V, FS); // up to 20 dp, no trailing zeros
    if Length(S) < AWidth then
      Result := StringOfChar(' ', AWidth - Length(S)) + S
    else
      Result := S;
  end;

begin
  // Wallet from mnemonic (Sollet-style: no passphrase for this example)
  LWallet := TWallet.Create(MnemonicWords);
  LOwner  := LWallet.GetAccountByIndex(0);

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
    LMaxSym  := 0;
    LMaxName := 0;
    for B in LBalances do
    begin
      if Length(B.Symbol)    > LMaxSym  then LMaxSym  := Length(B.Symbol);
      if Length(B.TokenName) > LMaxName then LMaxName := Length(B.TokenName);
    end;

    Writeln('Individual Accounts...');
    for A in LAccounts do
    begin
      Writeln(
        PadRight(A.Symbol, LMaxSym), ' ',
        FormatQty(A.QuantityDouble, 14), ' ',
        PadRight(A.TokenName, LMaxName), ' ',
        A.PublicKey, ' ',
        IfThen(A.IsAssociatedTokenAccount, '[ATA]', '')
      );
    end;
    Writeln;

    Writeln('Filtered Accounts...');
    LSublist := LTokenWallet.TokenAccounts.WithSymbol(Symbol).WithMint(Mint);
    for A in LSublist do
    begin
      Writeln(
        PadRight(A.Symbol, LMaxSym), ' ',
        FormatQty(A.QuantityDouble, 14), ' ',
        PadRight(A.TokenName, LMaxName), ' ',
        A.PublicKey, ' ',
        IfThen(A.IsAssociatedTokenAccount, '[ATA]', '')
      );
    end;
    Writeln;

    // Show consolidated balances
    Writeln('Consolidated Balances...');
    for B in LBalances do
    begin
      Writeln(
        PadRight(B.Symbol, LMaxSym), ' ',
        FormatQty(B.QuantityDouble, 14), ' ',
        PadRight(B.TokenName, LMaxName), ' in ',
        B.AccountCount, ' ',
        IfThen(B.AccountCount = 1, 'account', 'accounts')
      );
    end;

    Writeln;
  finally
    LBalances.Free;
  end;
end;

end.

