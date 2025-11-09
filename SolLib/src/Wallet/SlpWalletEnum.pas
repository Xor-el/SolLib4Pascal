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

unit SlpWalletEnum;

{$I ..\Include\SolLib.inc}

interface

type
  /// <summary>
  /// Specifies the available seed modes for key generation
  /// </summary>
  TSeedMode = (
    /// <summary>
    /// Generates Ed25519 based BIP32 keys
    /// This seed mode is compatible with the keys generated in the Sollet/SPL Token Wallet,
    /// it does not use a passphrase to harden the mnemonic seed
    /// </summary>
    Ed25519Bip32,

    /// <summary>
    /// Generates BIP39 keys
    /// This seed mode is compatible with the keys generated in the solana-keygen cli,
    /// it uses a passphrase to harden the mnemonic seed
    /// </summary>
    Bip39
  );

  /// <summary>
  /// Specifies the available lengths for the mnemonic.
  /// </summary>
  TWordCount = (
    /// <summary>
    /// Twelve words.
    /// </summary>
    Twelve = 12,

    /// <summary>
    /// Fifteen words.
    /// </summary>
    Fifteen = 15,

    /// <summary>
    /// Eighteen words.
    /// </summary>
    Eighteen = 18,

    /// <summary>
    /// Twenty one words.
    /// </summary>
    TwentyOne = 21,

    /// <summary>
    /// Twenty four words.
    /// </summary>
    TwentyFour = 24
  );

  /// <summary>
  /// Specifies the available languages for mnemonic generation
  /// </summary>
  TLanguage = (
    /// <summary>
    /// English
    /// </summary>
    English = 0,
    /// <summary>
    /// Japanese
    /// </summary>
    Japanese = 1,
    /// <summary>
    /// Spanish
    /// </summary>
    Spanish = 2,
    /// <summary>
    /// Simplified Chinese
    /// </summary>
    ChineseSimplified = 3,
    /// <summary>
    /// Traditional Chinese
    /// </summary>
    ChineseTraditional = 4,
    /// <summary>
    /// French
    /// </summary>
    French = 5,
    /// <summary>
    /// Brazilian portuguese
    /// </summary>
    PortugueseBrazil = 6,
    /// <summary>
    /// Czech
    /// </summary>
    Czech = 7,
    /// <summary>
    /// Unknown
    /// </summary>
    Unknown = 8
  );

implementation

end.
