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

unit SlpSolanaKeyStoreService;

{$I ../Include/SolLib.inc}

interface

uses
  SysUtils,
  SlpIOUtilities,
  SlpWalletEnum,
  SlpDataEncoderUtilities,
  SlpWallet;

type
  /// <summary>
  /// Keystore operations compatible with solana-keygen (Rust CLI).
  /// Stateless: all methods are class/static.
  /// </summary>
  TSolanaKeyStoreService = class sealed
  private
    class function InitializeWallet(const ASeed: TBytes;
      const APassphrase: string = ''): IWallet; static;
  public
    /// <summary>
    /// Restores a wallet from a solana-keygen JSON byte array string.
    /// </summary>
    class function RestoreKeystore(const APrivateKey: string;
      const APassphrase: string = ''): IWallet; static;

    /// <summary>
    /// Restores a wallet from a solana-keygen JSON keystore file.
    /// </summary>
    class function RestoreKeystoreFromFile(const APath: string;
      const APassphrase: string = ''): IWallet; static;

    /// <summary>
    /// Saves a wallet's private key to a solana-keygen compatible JSON file.
    /// </summary>
    class procedure SaveKeystore(const APath: string; const AWallet: IWallet); static;
  end;

implementation

{ TSolanaKeyStoreService }

class function TSolanaKeyStoreService.RestoreKeystore(const APrivateKey,
  APassphrase: string): IWallet;
begin
  if APrivateKey = '' then
    raise EArgumentNilException.Create('privateKey');

  Result := InitializeWallet(TSolanaKeyPairJsonEncoder.DecodeData(APrivateKey), APassphrase);
end;

class function TSolanaKeyStoreService.RestoreKeystoreFromFile(const APath,
  APassphrase: string): IWallet;
begin
  if APath = '' then
    raise EArgumentNilException.Create('path');

  Result := InitializeWallet(
    TSolanaKeyPairJsonEncoder.DecodeData(TIOUtilities.ReadAllText(APath, TEncoding.UTF8)),
    APassphrase);
end;

class procedure TSolanaKeyStoreService.SaveKeystore(const APath: string;
  const AWallet: IWallet);
begin
  if APath = '' then
    raise EArgumentNilException.Create('path');
  if AWallet = nil then
    raise EArgumentNilException.Create('wallet');

  TIOUtilities.WriteAllBytes(APath,
    TEncoding.ASCII.GetBytes(
      TSolanaKeyPairJsonEncoder.EncodeData(AWallet.Account.PrivateKey.KeyBytes)));
end;

class function TSolanaKeyStoreService.InitializeWallet(const ASeed: TBytes;
  const APassphrase: string): IWallet;
begin
  Result := TWallet.Create(ASeed, APassphrase, TSeedMode.Bip39);
end;

end.

