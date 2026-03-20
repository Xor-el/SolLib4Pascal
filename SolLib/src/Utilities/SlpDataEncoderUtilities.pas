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

unit SlpDataEncoderUtilities;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  SlpDataEncoderProviders;

type
  TDataEncoderAlgorithm = class abstract
  public
    class function EncodeData(const AData: TBytes): string; virtual; abstract;
    class function DecodeData(const AEncoded: string): TBytes; virtual; abstract;
    class function IsValidCharset(const AEncoded: string): Boolean; virtual; abstract;
  end;
  /// <summary>Base58 encode/decode (static-style)</summary>
  TBase58Encoder = class(TDataEncoderAlgorithm)
  public
    class function EncodeData(const AData: TBytes): string; override;
    class function DecodeData(const AEncoded: string): TBytes; override;
    class function IsValidCharset(const AEncoded: string): Boolean; override;
  end;

  /// <summary>Base64 encode/decode (static-style)</summary>
  TBase64Encoder = class(TDataEncoderAlgorithm)
  public
    class function EncodeData(const AData: TBytes): string; override;
    class function DecodeData(const AEncoded: string): TBytes; override;
    class function IsValidCharset(const AEncoded: string): Boolean; override;
  end;

  /// <summary>Hex encode/decode (static-style)</summary>
  THexEncoder = class(TDataEncoderAlgorithm)
  public
    class function EncodeData(const AData: TBytes): string; override;
    class function DecodeData(const AEncoded: string): TBytes; override;
    class function IsValidCharset(const AEncoded: string): Boolean; override;
  end;

  /// <summary>Solana cli keypair array-style encode/decode (static-style)</summary>
  TSolanaKeyPairJsonEncoder = class(TDataEncoderAlgorithm)
  public
    class function EncodeData(const AData: TBytes): string; override;
    class function DecodeData(const AEncoded: string): TBytes; override;
    class function IsValidCharset(const AEncoded: string): Boolean; override;
  end;

implementation

{ TBase58Encoder }

class function TBase58Encoder.EncodeData(const AData: TBytes): string;
begin
  Result := TDataEncoderProviders.Base58.EncodeData(AData, 0, Length(AData));
end;

class function TBase58Encoder.DecodeData(const AEncoded: string): TBytes;
begin
  Result := TDataEncoderProviders.Base58.DecodeData(AEncoded);
end;

class function TBase58Encoder.IsValidCharset(const AEncoded: string): Boolean;
begin
  Result := TDataEncoderProviders.Base58.IsValidCharset(AEncoded);
end;

{ TBase64Encoder }

class function TBase64Encoder.EncodeData(const AData: TBytes): string;
begin
  Result := TDataEncoderProviders.Base64.EncodeData(AData, 0, Length(AData));
end;

class function TBase64Encoder.DecodeData(const AEncoded: string): TBytes;
begin
  Result := TDataEncoderProviders.Base64.DecodeData(AEncoded);
end;

class function TBase64Encoder.IsValidCharset(const AEncoded: string): Boolean;
begin
  Result := TDataEncoderProviders.Base64.IsValidCharset(AEncoded);
end;

{ THexEncoder }

class function THexEncoder.EncodeData(const AData: TBytes): string;
begin
  Result := TDataEncoderProviders.Hex.EncodeData(AData, 0, Length(AData));
end;

class function THexEncoder.DecodeData(const AEncoded: string): TBytes;
begin
  Result := TDataEncoderProviders.Hex.DecodeData(AEncoded);
end;

class function THexEncoder.IsValidCharset(const AEncoded: string): Boolean;
begin
  Result := TDataEncoderProviders.Hex.IsValidCharset(AEncoded);
end;

{ TSolanaKeyPairJsonEncoder }

class function TSolanaKeyPairJsonEncoder.EncodeData(const AData: TBytes): string;
begin
  Result := TDataEncoderProviders.SolanaKeyPairJson.EncodeData(AData, 0, Length(AData));
end;

class function TSolanaKeyPairJsonEncoder.DecodeData(const AEncoded: string): TBytes;
begin
  Result := TDataEncoderProviders.SolanaKeyPairJson.DecodeData(AEncoded);
end;

class function TSolanaKeyPairJsonEncoder.IsValidCharset(const AEncoded: string): Boolean;
begin
  Result := TDataEncoderProviders.SolanaKeyPairJson.IsValidCharset(AEncoded);
end;

end.
