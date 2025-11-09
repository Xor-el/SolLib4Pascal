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

unit SlpClientFactory;

{$I ..\Include\SolLib.inc}

interface

uses
  System.SysUtils,
  System.TypInfo,
  SlpSolanaRpcClient,
  SlpSolanaStreamingRpcClient,
  SlpRpcEnum,
  SlpRateLimiter,
  SlpLogger,
  SlpHttpApiClient,
  SlpWebSocketApiClient;

/// <summary>
/// Implements a client factory for Solana RPC APIs.
/// </summary>
type
  TClientFactory = class
  private
  const
  /// <summary>
  /// The dev net cluster.
  /// </summary>
  RpcDevNet  = 'https://api.devnet.solana.com';
  /// <summary>
  /// The test net cluster.
  /// </summary>
  RpcTestNet = 'https://api.testnet.solana.com';
  /// <summary>
  /// The main net cluster.
  /// </summary>
  RpcMainNet = 'https://api.mainnet-beta.solana.com';
  /// <summary>
  /// The dev net cluster.
  /// </summary>
  StreamingRpcDevNet = 'wss://api.devnet.solana.com';
  /// <summary>
  /// The test net cluster.
  /// </summary>
  StreamingRpcTestNet = 'wss://api.testnet.solana.com';
    /// <summary>
  /// The main net cluster.
  /// </summary>
  StreamingRpcMainNet = 'wss://api.mainnet-beta.solana.com';

  public
    /// <summary>
    /// Instantiate a rpc client.
    /// </summary>
    /// <param name="ACluster">The network cluster.</param>
    /// <param name="AClient">A HTTP client instance.</param>
    /// <param name="ALogger">An ILogger instance or nil.</param>
    /// <param name="ARateLimiter">An IRateLimiter instance or nil.</param>
    /// <returns>The rpc client.</returns>
    class function GetClient(ACluster: TCluster; const AClient: IHttpApiClient; const ALogger: ILogger = nil; const ARateLimiter: IRateLimiter = nil): IRpcClient; overload; static;

    /// <summary>
    /// Instantiate a rpc client.
    /// </summary>
    /// <param name="AUrl">The network cluster url.</param>
    /// <param name="AClient">A HTTP client instance.</param>
    /// <param name="ALogger">An ILogger instance or nil.</param>
    /// <param name="ARateLimiter">An IRateLimiter instance or nil.</param>
    /// <returns>The rpc client.</returns>
    class function GetClient(const AUrl: string; const AClient: IHttpApiClient; const ALogger: ILogger = nil; const ARateLimiter: IRateLimiter = nil): IRpcClient; overload; static;

    /// <summary>
    /// Instantiate a streaming client.
    /// </summary>
    /// <param name="ACluster">The network cluster.</param>
    /// <param name="AClient">A WebSocket client instance.</param>
    /// <param name="logger">The logger.</param>
    /// <returns>The streaming client.</returns>
    class function GetStreamingClient(ACluster: TCluster; const AClient: IWebSocketApiClient; const ALogger: ILogger = nil): IStreamingRpcClient; overload; static;

    /// <summary>
    /// Instantiate a streaming client.
    /// </summary>
    /// <param name="AUrl">The network cluster url.</param>
    /// <param name="AClient">A WebSocket client instance.</param>
    /// <param name="logger">The logger.</param>
    /// <returns>The streaming client.</returns>
    class function GetStreamingClient(const AUrl: string; const AClient: IWebSocketApiClient; const ALogger: ILogger = nil): IStreamingRpcClient; overload; static;
  end;


implementation

{ TClientFactory }

class function TClientFactory.GetClient(ACluster: TCluster; const AClient: IHttpApiClient; const ALogger: ILogger; const ARateLimiter: IRateLimiter): IRpcClient;
var
  LUrl: string;
begin
  case ACluster of
    TCluster.DevNet:  LUrl := RpcDevNet;
    TCluster.TestNet: LUrl := RpcTestNet;
    TCluster.MainNet: LUrl := RpcMainNet;
  else
    raise Exception.CreateFmt('Invalid cluster specified: %s', [GetEnumName(TypeInfo(TCluster), Ord(ACluster))]);
  end;

  Result := GetClient(LUrl, AClient, ALogger, ARateLimiter);
end;

class function TClientFactory.GetClient(const AUrl: string; const AClient: IHttpApiClient; const ALogger: ILogger; const ARateLimiter: IRateLimiter): IRpcClient;
begin
  Result := TSolanaRpcClient.Create(AUrl, AClient, ALogger, ARateLimiter);
end;

class function TClientFactory.GetStreamingClient(ACluster: TCluster; const AClient: IWebSocketApiClient; const ALogger: ILogger): IStreamingRpcClient;
var
  LUrl: string;
begin
  case ACluster of
    TCluster.DevNet:  LUrl := StreamingRpcDevNet;
    TCluster.TestNet: LUrl := StreamingRpcTestNet;
    TCluster.MainNet: LUrl := StreamingRpcMainNet;
  else
    raise Exception.CreateFmt('Invalid cluster specified: %s', [GetEnumName(TypeInfo(TCluster), Ord(ACluster))]);
  end;

  Result := GetStreamingClient(LUrl, AClient, ALogger);
end;

class function TClientFactory.GetStreamingClient(const AUrl: string; const AClient: IWebSocketApiClient; const ALogger: ILogger): IStreamingRpcClient;
begin
  Result := TSolanaStreamingRpcClient.Create(AUrl, AClient, ALogger);
end;


end.
