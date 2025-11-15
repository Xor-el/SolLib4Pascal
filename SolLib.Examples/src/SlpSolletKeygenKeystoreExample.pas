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

unit SlpSolletKeygenKeystoreExample;

interface

uses
  System.SysUtils,
  SlpExample,
  SlpWallet,
  SlpAccount,
  SlpMnemonic,
  SlpWordList,
  SlpPublicKey,
  SlpSecretKeyStoreService,
  SlpDataEncoders;

type
  /// <summary>
  /// Demonstrates encrypting a Sollet-compatible mnemonic into a keystore JSON,
  /// decrypting it back, restoring the wallet, and verifying derived addresses
  /// (indexes 0..9) match expected Base58 (public/private) pairs.
  /// </summary>
  TSolletKeygenKeystoreExample = class(TBaseExample)
private

const
  Password = 'password';

  Expected: array[0..9] of TExpectedKeyPair = (
    (Pub: '6bhhceZToGG9RsTe1nfNFXEMjavhj6CV55EsvearAt2z';
     Priv: '5S1UT7L6bQ8sVaPjpJyYFEEYh8HAXRXPFUEuj6kHQXs6ZE9F6a2wWrjdokAmSPP5HVP46bYxsrU8yr2FxxYmVBi6'),
    (Pub: '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5';
     Priv: '22J7rH3DFJb1yz8JuWUWfrpsQrNsvZKov8sznfwHbPGTznSgQ8u6LQ6KixPC2mYCJDsfzME1FbdX1x89zKq4MU3K'),
    (Pub: '3F2RNf2f2kWYgJ2XsqcjzVeh3rsEQnwf6cawtBiJGyKV';
     Priv: '5954a6aMxVnPTyMNdVKrSiqoVMRvZcwU7swGp9kHsV9HP9Eu81TebS4Mbq5ZGmZwUaJkkKoCJ2eJSY9cTdWzRXeF'),
    (Pub: 'GyWQGKYpvzFmjhnG5Pfw9jfvgDM7LB31HnTRPopCCS9';
     Priv: 'tUV1EeY6CARAbuEfVqKS46X136PRBea8PcmYfHRWNQc6yYB14GkSBZ6PTybUt5W14A7FSJ6Mm6NN22fLhUhDUGu'),
    (Pub: 'GjtWSPacUQFVShQKRKPc342MLCdNiusn3WTJQKxuDfXi';
     Priv: 'iLtErFEn6w5xbsUW63QLYMTJeX8TAgFTUDTgat3gxpaiN3AJbebv6ybtmTj1t1yvkqqY2k1uwFxaKZoCQAPcDZe'),
    (Pub: 'DjGCyxjGxpvEo921Ad4tUUWquiRG6dziJUCk8HKZoaKK';
     Priv: '3uvEiJiMyXqQmELLjxV8r3E7CyRFg42LUAxzz6q7fPhzTCxCzPkaMCQ9ARpWYDNiDXhue2Uma1C7KR9AkiiWUS8y'),
    (Pub: 'HU6aKFapq4RssJqV96rfE7vv1pepz5A5miPAMxGFso4X';
     Priv: '4xFZDEhhw3oVewE3UCvzLmhRWjjcqvVMxuYiETWiyaV2wJwEJ4ceDDE359NMirh43VYisViHAwsXjZ3F9fk6dAxB'),
    (Pub: 'HunD57AAvhBiX2SxmEDMbrgQ9pcqrtRyWKy7dWPEWYkJ';
     Priv: '2Z5CFuVDPQXxrB3iw5g6SAnKqApE1djAqtTZDA83rLZ1NDi6z13rwDX17qdyUDCxK9nDwKAHdVuy3h6jeXspcYxA'),
    (Pub: '9KmfMX4Ne5ocb8C7PwjmJTWTpQTQcPhkeD2zY35mawhq';
     Priv: 'c1BzdtL4RByNQnzcaUq3WuNLuyY4tQogGT7JWwy4YGBE8FGSgWUH8eNJFyJgXNYtwTKq4emhC4V132QX9REwujm'),
    (Pub: '7MrtfwpJBw2hn4eopB2CVEKR1kePJV5kKmKX3wUAFsJ9';
     Priv: '4skUmBVmaLoriN9Ge8xcF4xQFJmF554rnRRa2u1yDbre2zj2wUpgCXUaPETLSAWNudCkNAkWM5oJFJRaeZY1g9JR')
  );

  MnemonicWords = TBaseExample.MNEMONIC_WORDS;
  public
    /// <summary>Runs the example.</summary>
    procedure Run; override;
  end;

implementation

{ TSolletKeygenKeystoreExample }

procedure TSolletKeygenKeystoreExample.Run;
var
  LMnemonic: IMnemonic;
  LWallet: IWallet;
  LKeystoreSvc: TSecretKeyStoreService;
  LEncryptedJson, LAddrFromKeystore, LRestoredMnemonicStr: string;
  LSeed, LDecryptedBytes, LRestoredSeed: TBytes;
  LRestoredMnemonic: IMnemonic;
  LRestoredWallet: IWallet;
  LAccount: IAccount;
  I: Integer;
  LOk: Boolean;
begin
  // Build Sollet-compatible mnemonic (no passphrase hardening).
  LMnemonic := TMnemonic.Create(MnemonicWords, TWordList.English);

  // Create wallet from mnemonic and derive the mnemonic seed
  LWallet := TWallet.Create(LMnemonic);
  LSeed   := LWallet.DeriveMnemonicSeed;

  Writeln('Seed: ', TEncoders.Solana.EncodeData(LSeed));
  Writeln('Address: ', LWallet.Account.PublicKey.Key);

  LKeystoreSvc := TSecretKeyStoreService.Create;
  try
    // 1) Encrypt the MNEMONIC (as UTF-8 bytes) into a keystore JSON.
    LEncryptedJson := LKeystoreSvc.EncryptAndGenerateDefaultKeyStoreAsJson(
      Password,
      TEncoding.UTF8.GetBytes(LMnemonic.ToString),
      LWallet.Account.PublicKey.Key
    );

    // Resolve the address field from the generated keystore JSON.
    LAddrFromKeystore := TSecretKeyStoreService.GetAddressFromKeyStore(LEncryptedJson);

    Writeln('Keystore JSON: ', LEncryptedJson);
    Writeln('Keystore Address: ', LAddrFromKeystore);

    // 2) Decrypt from keystore JSON back to the original mnemonic bytes.
    LDecryptedBytes := LKeystoreSvc.DecryptKeyStoreFromJson(Password, LEncryptedJson);
  finally
    LKeystoreSvc.Free;
  end;

  LRestoredMnemonicStr := TEncoding.UTF8.GetString(LDecryptedBytes);

  // 3) Restore wallet from the restored mnemonic string.
  LRestoredMnemonic := TMnemonic.Create(LRestoredMnemonicStr, TWordList.English);
  LRestoredWallet   := TWallet.Create(LRestoredMnemonic);
  LRestoredSeed     := LRestoredWallet.DeriveMnemonicSeed;

  Writeln('Seed: ', TEncoders.Solana.EncodeData(LRestoredSeed));

  // Mimic Sollet key generation and verify the first 10 accounts.
  LOk := True;
  for I := 0 to 9 do
  begin
    LAccount := LRestoredWallet.GetAccountByIndex(I);
    Writeln('RESTORED SOLLET address ', LAccount.PublicKey.Key);

    if (not SameText(LAccount.PublicKey.Key, Expected[I].Pub)) or
       (not SameText(LAccount.PrivateKey.Key, Expected[I].Priv)) then
      LOk := False;
  end;

  if LOk then
    Writeln('GOOD RESTORE FOR THE SOLLET')
  else
    Writeln('NOT GOOD RESTORE FOR THE SOLLET');
end;

end.

