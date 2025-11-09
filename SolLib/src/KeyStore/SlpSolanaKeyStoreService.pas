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

unit SlpSolanaKeyStoreService;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  SlpIOUtils,
  SlpWalletEnum,
  SlpDataEncoders,
  SlpWallet;

type
  /// <summary>
  /// Implements a keystore compatible with the solana-keygen made in rust.
  /// </summary>
  TSolanaKeyStoreService = class
  public
    /// <summary>
    /// Restores a keypair from a keystore compatible with the solana-keygen made in rust.
    /// </summary>
    /// <param name="APrivateKey">The string with the private key bytes.</param>
    /// <param name="APassphrase">The passphrase used while originally generating the keys.</param>
    function RestoreKeystore(const APrivateKey: string; const APassphrase: string = ''): IWallet;

    /// <summary>
    /// Restores a keypair from a keystore compatible with the solana-keygen made in rust.
    /// </summary>
    /// <param name="APath">The path to the keystore.</param>
    /// <param name="APassphrase">The passphrase used while originally generating the keys.</param>
    function RestoreKeystoreFromFile(const APath: string; const APassphrase: string = ''): IWallet;

    /// <summary>
    /// Saves a keypair to a keystore compatible with the solana-keygen made in rust.
    /// </summary>
    /// <param name="APath">The path to the keystore</param>
    /// <param name="AWallet">The wallet to save to the keystore.</param>
    procedure SaveKeystore(const APath: string; const AWallet: IWallet);
  private
    /// <summary>
    /// Initialize the wallet.
    /// </summary>
    /// <param name="ASeed">The seed.</param>
    /// <param name="APassphrase">The passphrase.</param>
    /// <returns>The wallet.</returns>
    function InitializeWallet(const ASeed: TBytes; const APassphrase: string = ''): IWallet;
  end;

implementation

{ TSolanaKeyStoreService }

function TSolanaKeyStoreService.RestoreKeystore(const APrivateKey, APassphrase: string): IWallet;
begin
  if APrivateKey = '' then
    raise EArgumentNilException.Create('privateKey');

  Result := InitializeWallet(TEncoders.Solana.DecodeData(APrivateKey), APassphrase);
end;

function TSolanaKeyStoreService.RestoreKeystoreFromFile(const APath, APassphrase: string): IWallet;
var
  JsonText: string;
begin
  if APath = '' then
    raise EArgumentNilException.Create('path');

  JsonText := TIOUtils.ReadAllText(APath, TEncoding.UTF8);
  Result := InitializeWallet(TEncoders.Solana.DecodeData(JsonText), APassphrase);
end;

procedure TSolanaKeyStoreService.SaveKeystore(const APath: string; const AWallet: IWallet);
var
  SeedString: string;
begin
  if APath = '' then
    raise EArgumentNilException.Create('path');
  if AWallet = nil then
    raise EArgumentNilException.Create('wallet');

  SeedString := TEncoders.Solana.EncodeData(AWallet.Account.PrivateKey.KeyBytes);

  TIOUtils.WriteAllBytes(APath, TEncoding.ASCII.GetBytes(SeedString));
end;

function TSolanaKeyStoreService.InitializeWallet(const ASeed: TBytes; const APassphrase: string): IWallet;
begin
  Result := TWallet.Create(ASeed, APassphrase, TSeedMode.Bip39);
end;

end.

