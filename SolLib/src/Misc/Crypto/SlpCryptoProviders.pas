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

unit SlpCryptoProviders;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils;

type
  /// <summary>
  /// Ed25519 keypair (libsodium-style).
  /// </summary>
  TEd25519KeyPair = record
    /// <summary>64 bytes: Seed(32) || PublicKey(32)</summary>
    SecretKey: TBytes;
    /// <summary>32 bytes</summary>
    PublicKey: TBytes;
  end;

  /// <summary>
  /// Interface for hash operations.
  /// </summary>
  IHashProvider = interface
    ['{768AB7D5-DE28-4E3A-96D6-7F3465D5A5C7}']
    function SHA256(const Data: TBytes): TBytes;
    function SHA512(const Data: TBytes): TBytes;
    function Keccak256(const Data: TBytes): TBytes;
  end;

  /// <summary>
  /// Interface for HMAC operations.
  /// </summary>
  IHmacProvider = interface
    ['{E13418A1-C541-4D0F-AD43-55C37EA6F1D5}']
    function HmacSHA256(const Key, Data: TBytes): TBytes;
    function HmacSHA512(const Key, Data: TBytes): TBytes;
  end;

  /// <summary>
  /// Interface for key derivation functions.
  /// </summary>
  IKdfProvider = interface
    ['{6825F0B5-3695-40AC-A6E9-29CD9F5F4C27}']
    function Pbkdf2SHA256(const Password, Salt: TBytes; Iterations, DKLen: Integer): TBytes;
    function Pbkdf2SHA512(const Password, Salt: TBytes; Iterations, DKLen: Integer): TBytes;
    function Scrypt(const Password, Salt: TBytes; N, R, P, DKLen: Integer): TBytes;
  end;

  /// <summary>
  /// Interface for cipher operations.
  /// </summary>
  ICipherProvider = interface
    ['{4AD1E604-A576-47A9-9F5A-4D58EE662AA5}']
    function AesCtrEncrypt(const Key, IV, Data: TBytes): TBytes;
    function AesCtrDecrypt(const Key, IV, Data: TBytes): TBytes;
  end;

  /// <summary>
  /// Interface for cryptographically secure random number generation.
  /// </summary>
  IRandomProvider = interface
    ['{04233D8D-DCD5-4AE6-BDF0-90247E337832}']
    function RandomBytes(Size: Integer): TBytes;
    procedure FillRandom(const Output: TBytes);
  end;

  /// <summary>
  /// Interface for Ed25519 signature operations.
  /// </summary>
  IEd25519Provider = interface
    ['{3EBF4388-1CA6-48A1-ACE5-E4BC27B024B8}']
    function GenerateKeyPair(const Seed32: TBytes): TEd25519KeyPair;
    function Sign(const SecretKey64, &Message: TBytes): TBytes;
    function Verify(const PublicKey32, &Message, Signature64: TBytes): Boolean;
    /// <summary>
    /// Checks whether the PublicKey bytes are on the Ed25519 curve.
    /// </summary>
    function IsOnCurve(const PublicKey32: TBytes): Boolean;
  end;

  /// <summary>
  /// Static accessor for crypto providers. Can be replaced with custom implementations.
  /// </summary>
  TCryptoProviders = class sealed
  strict private
    class var FHash: IHashProvider;
    class var FHmac: IHmacProvider;
    class var FKdf: IKdfProvider;
    class var FCipher: ICipherProvider;
    class var FRandom: IRandomProvider;
    class var FEd25519: IEd25519Provider;
    class constructor Create;
  public
    class property Hash: IHashProvider read FHash write FHash;
    class property Hmac: IHmacProvider read FHmac write FHmac;
    class property Kdf: IKdfProvider read FKdf write FKdf;
    class property Cipher: ICipherProvider read FCipher write FCipher;
    class property Random: IRandomProvider read FRandom write FRandom;
    class property Ed25519: IEd25519Provider read FEd25519 write FEd25519;
  end;

// =============================================================================
// Example: Providing a custom crypto provider implementation
// =============================================================================
//
// To use a custom provider, create a class implementing the interface and assign
// it to the appropriate TCryptoProviders property:
//
//   type
//     TMyCustomHashProvider = class(TInterfacedObject, IHashProvider)
//     public
//       function SHA256(const Data: TBytes): TBytes;
//       function SHA512(const Data: TBytes): TBytes;
//       function Keccak256(const Data: TBytes): TBytes;
//     end;
//
//   // At application startup:
//   TCryptoProviders.Hash := TMyCustomHashProvider.Create;
//
// The default CryptoLib4Pascal implementations from SlpDefaultCryptoProviders
// are loaded when USE_DEFAULT_CRYPTO_PROVIDERS is defined.
// Define USE_CUSTOM_CRYPTO_PROVIDERS to supply your own implementations.
//
// =============================================================================

implementation

{$IFDEF USE_DEFAULT_CRYPTO_PROVIDERS}
uses
  SlpDefaultCryptoProviders;
{$ENDIF}

class constructor TCryptoProviders.Create;
begin
  {$IFDEF USE_DEFAULT_CRYPTO_PROVIDERS}
  FHash := TDefaultHashProvider.Create;
  FHmac := TDefaultHmacProvider.Create;
  FKdf := TDefaultKdfProvider.Create;
  FCipher := TDefaultCipherProvider.Create;
  FRandom := TDefaultRandomProvider.Create;
  FEd25519 := TDefaultEd25519Provider.Create;
  {$ELSEIF DEFINED(USE_CUSTOM_CRYPTO_PROVIDERS)}
  // User must assign providers before using TCryptoProviders
  // Example:
  //   FHash := TMyCustomHashProvider.Create;
  //   FHmac := TMyCustomHmacProvider.Create;
  //   etc.
  {$ELSE}
  {$MESSAGE ERROR 'Either USE_DEFAULT_CRYPTO_PROVIDERS or USE_CUSTOM_CRYPTO_PROVIDERS must be defined'}
  {$ENDIF}
end;

end.
