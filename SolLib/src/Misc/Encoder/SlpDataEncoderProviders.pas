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

unit SlpDataEncoderProviders;

{$I ../../Include/SolLib.inc}

interface

uses
  System.SysUtils;

type
  /// <summary>
  /// Interface for data encoder provider operations.
  /// </summary>
  IDataEncoderProvider = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    /// <summary>
    /// Encode the data.
    /// </summary>
    /// <param name="AData">The data to encode.</param>
    /// <param name="AOffset">The offset at which to start encoding.</param>
    /// <param name="ACount">The number of bytes to encode.</param>
    /// <returns>The encoded data.</returns>
    function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;

    /// <summary>
    /// Decode the data.
    /// </summary>
    /// <param name="AEncoded">The data to decode.</param>
    /// <returns>The decoded data.</returns>
    function DecodeData(const AEncoded: string): TBytes;

    /// <summary>
    /// Check if the encoded string contains only valid characters for this encoding charset.
    /// </summary>
    /// <param name="AEncoded">The encoded string to validate.</param>
    /// <returns>True if valid, false otherwise.</returns>
    function IsValidCharset(const AEncoded: string): Boolean;
  end;

  /// <summary>
  /// Static accessor for data encoder providers. Can be replaced with custom implementations.
  /// </summary>
  TDataEncoderProviders = class sealed
  strict private
    class var FBase58: IDataEncoderProvider;
    class var FBase64: IDataEncoderProvider;
    class var FHex: IDataEncoderProvider;
    class var FSolanaKeyPairJson: IDataEncoderProvider;
    class constructor Create;
  public
    class property Base58: IDataEncoderProvider read FBase58 write FBase58;
    class property Base64: IDataEncoderProvider read FBase64 write FBase64;
    class property Hex: IDataEncoderProvider read FHex write FHex;
    class property SolanaKeyPairJson: IDataEncoderProvider read FSolanaKeyPairJson write FSolanaKeyPairJson;
  end;

// =============================================================================
// Example: Providing a custom encoder provider implementation
// =============================================================================
//
// To use a custom encoder provider, create a class implementing IDataEncoderProvider
// and assign it to the appropriate TDataEncoderProviders property:
//
//   type
//     TMyCustomBase58EncoderProvider = class(TInterfacedObject, IDataEncoderProvider)
//     public
//       function EncodeData(const AData: TBytes; AOffset, ACount: Integer): string;
//       function DecodeData(const AEncoded: string): TBytes;
//       function IsValidCharset(const AEncoded: string): Boolean;
//     end;
//
//   // At application startup:
//   TDataEncoderProviders.Base58 := TMyCustomBase58EncoderProvider.Create;
//
// The default implementations from SlpDefaultDataEncoderProviders are loaded
// when USE_DEFAULT_DATA_ENCODER_PROVIDERS is defined. Define
// USE_CUSTOM_DATA_ENCODER_PROVIDERS to supply your own implementations.
//
// =============================================================================

implementation

{$IFDEF USE_DEFAULT_DATA_ENCODER_PROVIDERS}
uses
  SlpDefaultDataEncoderProviders;
{$ENDIF}

{ TDataEncoderProviders }

class constructor TDataEncoderProviders.Create;
begin
  {$IFDEF USE_DEFAULT_DATA_ENCODER_PROVIDERS}
  FBase58 := TDefaultBase58EncoderProvider.Create;
  FBase64 := TDefaultBase64EncoderProvider.Create;
  FHex := TDefaultHexEncoderProvider.Create;
  FSolanaKeyPairJson := TDefaultSolanaKeyPairJsonEncoderProvider.Create;
  {$ELSEIF DEFINED(USE_CUSTOM_DATA_ENCODER_PROVIDERS)}
  // User must assign providers before using TDataEncoderProviders
  {$ELSE}
  {$MESSAGE ERROR 'Either USE_DEFAULT_DATA_ENCODER_PROVIDERS or USE_CUSTOM_DATA_ENCODER_PROVIDERS must be defined'}
  {$ENDIF}
end;

end.
