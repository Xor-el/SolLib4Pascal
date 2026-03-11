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

unit SlpKeyStoreModel;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.JSON.Serializers,
  SlpDataEncoderUtils;

type
  TKdfParams = class
  private
    FSalt: string;
    FDkLen: Integer;
  public
    [JsonName('dklen')]
    property DkLen: Integer read FDkLen write FDkLen;

    [JsonName('salt')]
    property Salt: string read FSalt write FSalt;
  end;

  TScryptParams = class(TKdfParams)
  private
    FN: Integer;
    FR: Integer;
    FP: Integer;
  public
    [JsonName('n')]
    property N: Integer read FN write FN;
    [JsonName('r')]
    property R: Integer read FR write FR;
    [JsonName('p')]
    property P: Integer read FP write FP;
  end;

  TPbkdf2Params = class(TKdfParams)
  private
    FCount: Integer;
    FPrf: string;
  public
    [JsonName('c')]
    property Count: Integer read FCount write FCount;
    [JsonName('prf')]
    property Prf: string read FPrf write FPrf;
  end;

  TCipherParams = class
  private
    FIv: string;
  public
    constructor Create(const AIV: TBytes); overload;

    [JsonName('iv')]
    property Iv: string read FIv write FIv;
  end;

  TCryptoInfo<TKdfParamsType: TKdfParams> = class
  private
    FCipher: string;
    FCipherText: string;
    FCipherParams: TCipherParams;
    FKdf: string;
    FMac: string;
    FKdfParams: TKdfParamsType;
  public
    constructor Create(const ACipher: string; const ACipherText, AIV, AMac, ASalt: TBytes;
      AKdfParams: TKdfParamsType; const AKdfType: string); overload; virtual;
    destructor Destroy; override;

    [JsonName('cipher')]
    property Cipher: string read FCipher write FCipher;
    [JsonName('ciphertext')]
    property CipherText: string read FCipherText write FCipherText;
    [JsonName('cipherparams')]
    property CipherParams: TCipherParams read FCipherParams write FCipherParams;
    [JsonName('kdf')]
    property Kdf: string read FKdf write FKdf;
    [JsonName('mac')]
    property Mac: string read FMac write FMac;
    [JsonName('kdfparams')]
    property KdfParams: TKdfParamsType read FKdfParams write FKdfParams;
  end;

  TKeyStore<TKdfParamsType: TKdfParams> = class
  private
    FCrypto: TCryptoInfo<TKdfParamsType>;
    FId: string;
    FAddress: string;
    FVersion: Integer;
  public
    destructor Destroy; override;

    [JsonName('crypto')]
    property Crypto: TCryptoInfo<TKdfParamsType> read FCrypto write FCrypto;
    [JsonName('id')]
    property Id: string read FId write FId;
    [JsonName('address')]
    property Address: string read FAddress write FAddress;
    [JsonName('version')]
    property Version: Integer read FVersion write FVersion;
  end;

implementation

{ TCipherParams }

constructor TCipherParams.Create(const AIV: TBytes);
begin
  inherited Create;
  FIv := THexEncoder.EncodeData(AIV).ToLower;
end;

{ TCryptoInfo<T> }

constructor TCryptoInfo<TKdfParamsType>.Create(const ACipher: string;
  const ACipherText, AIV, AMac, ASalt: TBytes;
  AKdfParams: TKdfParamsType; const AKdfType: string);
begin
  inherited Create;
  FCipher := ACipher;
  FCipherText := THexEncoder.EncodeData(ACipherText).ToLower;
  FMac := THexEncoder.EncodeData(AMac).ToLower;
  FCipherParams := TCipherParams.Create(AIV);
  FKdf := AKdfType;
  FKdfParams := AKdfParams;
  if Assigned(FKdfParams) then
    FKdfParams.Salt := THexEncoder.EncodeData(ASalt).ToLower;
end;

destructor TCryptoInfo<TKdfParamsType>.Destroy;
begin
  FCipherParams.Free;
  FKdfParams.Free;
  inherited;
end;

{ TKeyStore<T> }

destructor TKeyStore<TKdfParamsType>.Destroy;
begin
  FCrypto.Free;
  inherited;
end;

end.

