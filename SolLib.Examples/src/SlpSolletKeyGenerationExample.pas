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

unit SlpSolletKeyGenerationExample;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  SlpExample,
  SlpWallet,
  SlpAccount,
  SlpMnemonic,
  SlpWordList,
  SlpPublicKey;

type
  /// <summary>
  /// Generates Sollet-compatible accounts from a BIP-39 mnemonic (no passphrase)
  /// and verifies Base58 public/private keys at derivation indexes 0..9 against
  /// expected pairs.
  /// </summary>
  TSolletKeyGenerationExample = class(TBaseExample)
  private

 const
  // Expected (Public, Private) Base58 pairs for derivation indexes 0..9
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
    procedure Run; override;
  end;

implementation

{ TSolletKeyGenerationExample }

procedure TSolletKeyGenerationExample.Run;
var
  LMnemonic: IMnemonic;
  LWallet: IWallet;
  LAccount: IAccount;
  LOk: Boolean;
  I: Integer;
  LPubB58, LPrivB58: string;
begin
  // Sollet derivation uses the mnemonic only (no passphrase hardening here)
  LMnemonic := TMnemonic.Create(MnemonicWords, TWordList.English);
  LWallet   := TWallet.Create(LMnemonic);

  LOk := True;

  // Mimic Sollet key generation across the first 10 accounts
  for I := 0 to 9 do
  begin
    LAccount := LWallet.GetAccountByIndex(I);

    // Read Base58 keys (Base58 is case-sensitive; use exact equality)
    LPubB58  := LAccount.PublicKey.Key;
    LPrivB58 := LAccount.PrivateKey.Key;

    Writeln('SOLLET publicKey>b58 ', LPubB58);
    Writeln('SOLLET privateKey>b58 ', LPrivB58);

    if (not SameText(LPubB58, Expected[I].Pub)) or (not SameText(LPrivB58, Expected[I].Priv)) then
      LOk := False;
  end;

  if LOk then
    Writeln('GOOD FOR THE SOLLET')
  else
    Writeln('NOT GOOD FOR THE SOLLET');
end;

end.

