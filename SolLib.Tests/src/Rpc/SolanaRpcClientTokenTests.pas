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

unit SolanaRpcClientTokenTests;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpRpcEnum,
  SlpHttpApiClient,
  SlpHttpApiResponse,
  SlpRpcMessage,
  SlpRpcModel,
  SlpRequestResult,
  SlpSolanaRpcClient,
  RpcClientMocks,
  TestUtils,
  SolLibRpcClientTestCase;

type
  TSolanaRpcClientTokenTests = class(TSolLibRpcClientTestCase)
  published
    procedure TestGetTokenSupply;
    procedure TestGetTokenSupplyProcessed;

    procedure TestGetTokenAccountsByOwnerException;
    procedure TestGetTokenAccountsByOwner;
    procedure TestGetTokenAccountsByOwnerConfirmed;

    /// <summary>
    /// See References for more context
    /// </summary>
    /// <remarks>
    /// References:
    /// <see href="https://github.com/gagliardetto/solana-go/issues/172">solana-go #172</see>,
    /// <see href="https://github.com/anza-xyz/agave/issues/2950">agave #2950</see>,
    /// <see href="https://github.com/magicblock-labs/Solana.Unity-Core/issues/49">Solana.Unity-Core #49</see>.
    /// </remarks>
    procedure TestGetTokenAccountsByOwnerWithRentEpochGreaterThanUInt64;

    procedure TestGetTokenAccountsByDelegate;
    procedure TestGetTokenAccountsByDelegateProcessed;
    procedure TestGetTokenAccountsByDelegateBadParams;

    procedure TestGetTokenAccountBalance;
    procedure TestGetTokenAccountBalanceConfirmed;

    procedure TestGetTokenLargestAccounts;
    procedure TestGetTokenLargestAccountsProcessed;
  end;

implementation

{ TSolanaRpcClientTokenTests }

procedure TSolanaRpcClientTokenTests.TestGetTokenSupply;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TTokenBalance>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenSupplyResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenSupplyRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;
  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.GetTokenSupply('7ugkvt26sFjMdiFQFP5AQX8m8UkxWaW7rk2nBk4R6Gf2');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);

  AssertEquals(79266576, result.Result.Context.Slot);
  AssertEquals('1000', result.Result.Value.Amount);
  AssertEquals(2, result.Result.Value.Decimals);
  AssertEquals('10', result.Result.Value.UiAmountString);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenSupplyProcessed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TTokenBalance>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenSupplyResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenSupplyProcessedRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;
  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.GetTokenSupply('7ugkvt26sFjMdiFQFP5AQX8m8UkxWaW7rk2nBk4R6Gf2', TCommitment.Processed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);

  AssertEquals(79266576, result.Result.Context.Slot);
  AssertEquals('1000', result.Result.Value.Amount);
  AssertEquals(2, result.Result.Value.Decimals);
  AssertEquals('10', result.Result.Value.UiAmountString);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountsByOwnerException;
var
  rpcClient: IRpcClient;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
begin
  mockRpcHttpClient := SetupTest('', 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  AssertException(
    procedure
    begin
      rpcClient.GetTokenAccountsByOwner(
        '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5'
      );
    end,
    EArgumentException
  );
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountsByOwner;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenAccountsByOwnerResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenAccountsByOwnerRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;
  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.GetTokenAccountsByOwner(
    '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5',
    '', 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);

  AssertEquals(79200468, result.Result.Context.Slot);
  AssertEquals(7, result.Result.Value.Count);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountsByOwnerConfirmed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenAccountsByOwnerResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenAccountsByOwnerConfirmedRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;
  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.GetTokenAccountsByOwner(
    '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5',
    'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', '', TCommitment.Confirmed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);

  AssertEquals(79200468, result.Result.Context.Slot);
  AssertEquals(7, result.Result.Value.Count);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountsByOwnerWithRentEpochGreaterThanUInt64;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenAccountsByOwnerWithRentEpochGreaterThanUInt64Response.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenAccountsByOwnerWithRentEpochGreaterThanUInt64Request.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;
  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.GetTokenAccountsByOwner(
    '5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj',
    '', 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);

  AssertEquals(366348635, result.Result.Context.Slot);
  AssertEquals(53, result.Result.Value.Count);

  AssertEquals(18446744073709551615, result.Result.Value[0].Account.RentEpoch);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountsByDelegate;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenAccountsByDelegateResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenAccountsByDelegateRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;
  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.GetTokenAccountsByDelegate(
    '4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T',
    '', 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);

  AssertEquals(1114, result.Result.Context.Slot);
  AssertEquals(1, result.Result.Value.Count);
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', result.Result.Value[0].Account.Owner);
  AssertFalse(result.Result.Value[0].Account.Executable);
  AssertEquals(4, result.Result.Value[0].Account.RentEpoch);
  AssertEquals(1726080, result.Result.Value[0].Account.Lamports);
  AssertEquals('4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T',
    result.Result.Value[0].Account.Data.Parsed.Info.Delegate);
  AssertEquals('1', result.Result.Value[0].Account.Data.Parsed.Info.DelegatedAmount.Amount);
  AssertEquals(1, result.Result.Value[0].Account.Data.Parsed.Info.DelegatedAmount.Decimals);
  AssertEquals('0.1', result.Result.Value[0].Account.Data.Parsed.Info.DelegatedAmount.UiAmountString);
  AssertEquals(0.1, result.Result.Value[0].Account.Data.Parsed.Info.DelegatedAmount.AmountDouble, 0.0);
  AssertEquals(1, result.Result.Value[0].Account.Data.Parsed.Info.DelegatedAmount.AmountUInt64);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountsByDelegateProcessed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenAccountsByDelegateResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenAccountsByDelegateProcessedRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;
  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.GetTokenAccountsByDelegate(
    '4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T',
    'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', '', TCommitment.Processed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);

  AssertEquals(1114, result.Result.Context.Slot);
  AssertEquals(1, result.Result.Value.Count);
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', result.Result.Value[0].Account.Owner);
  AssertFalse(result.Result.Value[0].Account.Executable);
  AssertEquals(4, result.Result.Value[0].Account.RentEpoch);
  AssertEquals(1726080, result.Result.Value[0].Account.Lamports);
  AssertEquals('4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T',
    result.Result.Value[0].Account.Data.Parsed.Info.Delegate);
  AssertEquals('1', result.Result.Value[0].Account.Data.Parsed.Info.DelegatedAmount.Amount);
  AssertEquals(1, result.Result.Value[0].Account.Data.Parsed.Info.DelegatedAmount.Decimals);
  AssertEquals('0.1', result.Result.Value[0].Account.Data.Parsed.Info.DelegatedAmount.UiAmountString);
  AssertEquals(0.1, result.Result.Value[0].Account.Data.Parsed.Info.DelegatedAmount.AmountDouble, 0.0);
  AssertEquals(1, result.Result.Value[0].Account.Data.Parsed.Info.DelegatedAmount.AmountUInt64);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountsByDelegateBadParams;
var
  rpcClient: IRpcClient;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
begin
  mockRpcHttpClient := SetupTest('', 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  AssertException(
    procedure
    begin
      rpcClient.GetTokenAccountsByDelegate(
        '4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T'
      );
    end,
    EArgumentException
  );
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountBalance;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TTokenBalance>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenAccountBalanceResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenAccountBalanceRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;
  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.GetTokenAccountBalance('7247amxcSBamBSKZJrqbj373CiJSa1v21cRav56C3WfZ');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);

  AssertEquals(79207643, result.Result.Context.Slot);
  AssertEquals('1000', result.Result.Value.Amount);
  AssertEquals(2, result.Result.Value.Decimals);
  AssertEquals('10', result.Result.Value.UiAmountString);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountBalanceConfirmed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TTokenBalance>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenAccountBalanceResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenAccountBalanceConfirmedRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;
  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.GetTokenAccountBalance('7247amxcSBamBSKZJrqbj373CiJSa1v21cRav56C3WfZ', TCommitment.Confirmed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);

  AssertEquals(79207643, result.Result.Context.Slot);
  AssertEquals('1000', result.Result.Value.Amount);
  AssertEquals(2, result.Result.Value.Decimals);
  AssertEquals('10', result.Result.Value.UiAmountString);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenLargestAccounts;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TObjectList<TLargeTokenAccount>>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenLargestAccountsResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenLargestAccountsRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;
  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.GetTokenLargestAccounts('7ugkvt26sFjMdiFQFP5AQX8m8UkxWaW7rk2nBk4R6Gf2');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);

  AssertEquals(79207653, result.Result.Context.Slot);
  AssertEquals(1, result.Result.Value.Count);
  AssertEquals('7247amxcSBamBSKZJrqbj373CiJSa1v21cRav56C3WfZ', result.Result.Value[0].Address);
  AssertEquals('1000', result.Result.Value[0].Amount);
  AssertEquals(2, result.Result.Value[0].Decimals);
  AssertEquals('10', result.Result.Value[0].UiAmountString);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenLargestAccountsProcessed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TObjectList<TLargeTokenAccount>>>;
begin
  responseData := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenLargestAccountsResponse.json']));
  requestData  := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, 'Token', 'GetTokenLargestAccountsProcessedRequest.json']));

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;
  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);

  result := rpcClient.GetTokenLargestAccounts('7ugkvt26sFjMdiFQFP5AQX8m8UkxWaW7rk2nBk4R6Gf2', TCommitment.Processed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);

  AssertEquals(79207653, result.Result.Context.Slot);
  AssertEquals(1, result.Result.Value.Count);
  AssertEquals('7247amxcSBamBSKZJrqbj373CiJSa1v21cRav56C3WfZ', result.Result.Value[0].Address);
  AssertEquals('1000', result.Result.Value[0].Amount);
  AssertEquals(2, result.Result.Value[0].Decimals);
  AssertEquals('10', result.Result.Value[0].UiAmountString);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientTokenTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientTokenTests.Suite);
{$ENDIF}

end.

