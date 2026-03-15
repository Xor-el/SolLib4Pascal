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

unit SlpSolLibExceptions;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  SlpRequestResult,
  SlpRpcMessage;

type
  /// <summary>
  /// An exception thrown by the TokenWallet that includes the failing RPC call.
  /// </summary>
  ETokenWalletException<T> = class(Exception)
  private
    FRequestResult: IRequestResult<T>;
  public
    /// <summary>
    /// The failing RequestResult that caused the exception.
    /// </summary>
    property RequestResult: IRequestResult<T> read FRequestResult;

    /// <summary>
    /// Create a new TokenWallet exception.
    /// </summary>
    /// <param name="AMessage">The exception message.</param>
    /// <param name="AFailedResult">The failing RequestResult that caused the exception.</param>
    constructor Create(const AMessage: string;
      const AFailedResult: IRequestResult<T>);
  end;

  /// <summary>
  /// Exception thrown during decryption operations.
  /// </summary>
  EDecryptionException = class(Exception);

  /// <summary>
  /// Exception thrown when KDF type is invalid.
  /// </summary>
  EInvalidKdfException = class(Exception)
  public
    /// <summary>
    /// Create a new invalid KDF exception.
    /// </summary>
    /// <param name="AKdf">The invalid KDF string.</param>
    constructor Create(const AKdf: string);
  end;

  /// <summary>
  /// Encapsulates the batch request failure that is relayed to all callbacks.
  /// </summary>
  EBatchRequestException = class(Exception)
  private
    FRpcResult: IRequestResult<TJsonRpcBatchResponse>;
  public
    /// <summary>
    /// Create a new batch request exception.
    /// </summary>
    /// <param name="ARpcResult">The failing RPC result.</param>
    constructor Create(const ARpcResult: IRequestResult<TJsonRpcBatchResponse>);

    /// <summary>
    /// The RPC result that caused the batch failure.
    /// </summary>
    property RpcResult: IRequestResult<TJsonRpcBatchResponse> read FRpcResult;
  end;

  /// <summary>
  /// Exception raised when KDF normalization is not supported.
  /// </summary>
  EKdfNormalizationNotSupported = class(ENotSupportedException);

  /// <summary>
  /// Exception raised when a token mint address cannot be resolved.
  /// </summary>
  ETokenMintResolveException = class(Exception);

  /// <summary>
  /// Exception raised when compute-budget estimation cannot be completed.
  /// </summary>
  EComputeBudgetEstimationError = class(Exception);

  /// <summary>
  /// Exception raised when an invalid program is encountered.
  /// </summary>
  EInvalidProgramException = class(Exception);

implementation

{ ETokenWalletException<T> }

constructor ETokenWalletException<T>.Create(const AMessage: string;
  const AFailedResult: IRequestResult<T>);
begin
  inherited Create(AMessage);
  FRequestResult := AFailedResult;
end;

{ EInvalidKdfException }

constructor EInvalidKdfException.Create(const AKdf: string);
begin
  inherited Create('Invalid kdf: ' + AKdf);
end;

{ EBatchRequestException }

constructor EBatchRequestException.Create(
  const ARpcResult: IRequestResult<TJsonRpcBatchResponse>);
begin
  inherited Create('Batch request failure - ' + ARpcResult.Reason);
  FRpcResult := ARpcResult;
end;

end.
