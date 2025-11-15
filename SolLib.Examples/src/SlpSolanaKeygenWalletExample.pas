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

unit SlpSolanaKeygenWalletExample;

interface

uses
  System.SysUtils,
  SlpExample,
  SlpWallet,
  SlpMnemonic,
  SlpWordList,
  SlpWalletEnum,
  SlpPublicKey;

type
  /// <summary>
  /// Demonstrates generating a wallet from a BIP-39 mnemonic and passphrase and
  /// verifying the Base58-encoded public/private keys against expected values
  /// compatible with solana-keygen / SOLLET.
  /// </summary>
  TSolanaKeygenWalletExample = class(TBaseExample)
  private
  const
  ExpectedSolKeygenPublicKey  = 'AZzmpdbZWARkPzL8GKRHjjwY74st4URgk9v7QBubeWba';
  ExpectedSolKeygenPrivateKey =
    '2RitwnKZwoigHk9S3ftvFQhoTy5QQKAipNjZHDgCet8hyciUbJSuhMWDKRL8JKE784pK8jJPFaNerFsS6KXhY9K6';
  // Mnemonic and passphrase used to derive the wallet (BIP-39)
  PassPhrase = 'thisiseightbytesithink';
  MnemonicWords = TBaseExample.MNEMONIC_WORDS;

  public
    procedure Run; override;
  end;

implementation

{ TSolanaKeygenWalletExample }

procedure TSolanaKeygenWalletExample.Run;
var
  LWallet: IWallet;
  LPubKeyB58, LPrivKeyB58: string;
  LMatch: Boolean;
  LMnemonic: IMnemonic;
begin
  LMnemonic := TMnemonic.Create(MnemonicWords, TWordList.English);
  LWallet := TWallet.Create(LMnemonic, PassPhrase, TSeedMode.Bip39);

  LPubKeyB58  := LWallet.Account.PublicKey.Key;
  LPrivKeyB58 := LWallet.Account.PrivateKey.Key;

  Writeln('SOLLET publicKey>b58  ', LPubKeyB58);
  Writeln('SOLLET privateKey>b58 ', LPrivKeyB58);

  LMatch := SameText(LPubKeyB58, ExpectedSolKeygenPublicKey) and
            SameText(LPrivKeyB58, ExpectedSolKeygenPrivateKey);

  if not LMatch then
    Writeln('NOT GOOD FOR THE SOL')
  else
    Writeln('GOOD FOR THE SOL');
end;

end.

