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
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TTokenBalance>>;
begin
  LResponseData := LoadTestData('Token/GetTokenSupplyResponse.json');
  LRequestData := LoadTestData('Token/GetTokenSupplyRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;
  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.GetTokenSupply('7ugkvt26sFjMdiFQFP5AQX8m8UkxWaW7rk2nBk4R6Gf2');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(79266576, LResult.Result.Context.Slot);
  AssertEquals('1000', LResult.Result.Value.Amount);
  AssertEquals(2, LResult.Result.Value.Decimals);
  AssertEquals('10', LResult.Result.Value.UiAmountString);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenSupplyProcessed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TTokenBalance>>;
begin
  LResponseData := LoadTestData('Token/GetTokenSupplyResponse.json');
  LRequestData := LoadTestData('Token/GetTokenSupplyProcessedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;
  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.GetTokenSupply('7ugkvt26sFjMdiFQFP5AQX8m8UkxWaW7rk2nBk4R6Gf2', TCommitment.Processed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(79266576, LResult.Result.Context.Slot);
  AssertEquals('1000', LResult.Result.Value.Amount);
  AssertEquals(2, LResult.Result.Value.Decimals);
  AssertEquals('10', LResult.Result.Value.UiAmountString);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountsByOwnerException;
var
  LRpcClient: IRpcClient;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
begin
  LMockRpcHttpClient := SetupTest('', 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  AssertException(
    procedure
    begin
      LRpcClient.GetTokenAccountsByOwner(
        '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5'
      );
    end,
    EArgumentException
  );
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountsByOwner;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
begin
  LResponseData := LoadTestData('Token/GetTokenAccountsByOwnerResponse.json');
  LRequestData := LoadTestData('Token/GetTokenAccountsByOwnerRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;
  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.GetTokenAccountsByOwner(
    '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5',
    '', 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(79200468, LResult.Result.Context.Slot);
  AssertEquals(7, LResult.Result.Value.Count);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountsByOwnerConfirmed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
begin
  LResponseData := LoadTestData('Token/GetTokenAccountsByOwnerResponse.json');
  LRequestData := LoadTestData('Token/GetTokenAccountsByOwnerConfirmedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;
  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.GetTokenAccountsByOwner(
    '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5',
    'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', '', TBinaryEncoding.JsonParsed, TCommitment.Confirmed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(79200468, LResult.Result.Context.Slot);
  AssertEquals(7, LResult.Result.Value.Count);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountsByOwnerWithRentEpochGreaterThanUInt64;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
begin
  LResponseData := LoadTestData('Token/GetTokenAccountsByOwnerWithRentEpochGreaterThanUInt64Response.json');
  LRequestData := LoadTestData('Token/GetTokenAccountsByOwnerWithRentEpochGreaterThanUInt64Request.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;
  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.GetTokenAccountsByOwner(
    '5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj',
    '', 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(366348635, LResult.Result.Context.Slot);
  AssertEquals(53, LResult.Result.Value.Count);

  AssertEquals(18446744073709551615, LResult.Result.Value[0].Account.RentEpoch);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountsByDelegate;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
  LTokenAccountData: TTokenAccountData;
begin
  LResponseData := LoadTestData('Token/GetTokenAccountsByDelegateResponse.json');
  LRequestData := LoadTestData('Token/GetTokenAccountsByDelegateRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;
  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.GetTokenAccountsByDelegate(
    '4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T',
    '', 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(1114, LResult.Result.Context.Slot);
  AssertEquals(1, LResult.Result.Value.Count);
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LResult.Result.Value[0].Account.Owner);
  AssertFalse(LResult.Result.Value[0].Account.Executable);
  AssertEquals(4, LResult.Result.Value[0].Account.RentEpoch);
  AssertEquals(1726080, LResult.Result.Value[0].Account.Lamports);

  LTokenAccountData := LResult.Result.Value[0].Account.Data.AsType<TTokenAccountData>;

  AssertEquals('4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T', LTokenAccountData.Parsed.Info.Delegate);
  AssertEquals('1', LTokenAccountData.Parsed.Info.DelegatedAmount.Amount);
  AssertEquals(1, LTokenAccountData.Parsed.Info.DelegatedAmount.Decimals);
  AssertEquals('0.1', LTokenAccountData.Parsed.Info.DelegatedAmount.UiAmountString);
  AssertEquals(0.1, LTokenAccountData.Parsed.Info.DelegatedAmount.AmountDouble, 0.0);
  AssertEquals(1, LTokenAccountData.Parsed.Info.DelegatedAmount.AmountUInt64);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountsByDelegateProcessed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TObjectList<TTokenAccount>>>;
  LTokenAccountData: TTokenAccountData;
begin
  LResponseData := LoadTestData('Token/GetTokenAccountsByDelegateResponse.json');
  LRequestData := LoadTestData('Token/GetTokenAccountsByDelegateProcessedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;
  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.GetTokenAccountsByDelegate(
    '4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T',
    'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', '', TBinaryEncoding.JsonParsed, TCommitment.Processed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(1114, LResult.Result.Context.Slot);
  AssertEquals(1, LResult.Result.Value.Count);
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LResult.Result.Value[0].Account.Owner);
  AssertFalse(LResult.Result.Value[0].Account.Executable);
  AssertEquals(4, LResult.Result.Value[0].Account.RentEpoch);
  AssertEquals(1726080, LResult.Result.Value[0].Account.Lamports);

  LTokenAccountData := LResult.Result.Value[0].Account.Data.AsType<TTokenAccountData>;

  AssertEquals('4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T', LTokenAccountData.Parsed.Info.Delegate);
  AssertEquals('1', LTokenAccountData.Parsed.Info.DelegatedAmount.Amount);
  AssertEquals(1, LTokenAccountData.Parsed.Info.DelegatedAmount.Decimals);
  AssertEquals('0.1', LTokenAccountData.Parsed.Info.DelegatedAmount.UiAmountString);
  AssertEquals(0.1, LTokenAccountData.Parsed.Info.DelegatedAmount.AmountDouble, 0.0);
  AssertEquals(1, LTokenAccountData.Parsed.Info.DelegatedAmount.AmountUInt64);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountsByDelegateBadParams;
var
  LRpcClient: IRpcClient;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
begin
  LMockRpcHttpClient := SetupTest('', 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  AssertException(
    procedure
    begin
      LRpcClient.GetTokenAccountsByDelegate(
        '4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T'
      );
    end,
    EArgumentException
  );
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountBalance;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TTokenBalance>>;
begin
  LResponseData := LoadTestData('Token/GetTokenAccountBalanceResponse.json');
  LRequestData := LoadTestData('Token/GetTokenAccountBalanceRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;
  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.GetTokenAccountBalance('7247amxcSBamBSKZJrqbj373CiJSa1v21cRav56C3WfZ');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(79207643, LResult.Result.Context.Slot);
  AssertEquals('1000', LResult.Result.Value.Amount);
  AssertEquals(2, LResult.Result.Value.Decimals);
  AssertEquals('10', LResult.Result.Value.UiAmountString);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenAccountBalanceConfirmed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TTokenBalance>>;
begin
  LResponseData := LoadTestData('Token/GetTokenAccountBalanceResponse.json');
  LRequestData := LoadTestData('Token/GetTokenAccountBalanceConfirmedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;
  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.GetTokenAccountBalance('7247amxcSBamBSKZJrqbj373CiJSa1v21cRav56C3WfZ', TCommitment.Confirmed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(79207643, LResult.Result.Context.Slot);
  AssertEquals('1000', LResult.Result.Value.Amount);
  AssertEquals(2, LResult.Result.Value.Decimals);
  AssertEquals('10', LResult.Result.Value.UiAmountString);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenLargestAccounts;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TObjectList<TLargeTokenAccount>>>;
begin
  LResponseData := LoadTestData('Token/GetTokenLargestAccountsResponse.json');
  LRequestData := LoadTestData('Token/GetTokenLargestAccountsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;
  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.GetTokenLargestAccounts('7ugkvt26sFjMdiFQFP5AQX8m8UkxWaW7rk2nBk4R6Gf2');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(79207653, LResult.Result.Context.Slot);
  AssertEquals(1, LResult.Result.Value.Count);
  AssertEquals('7247amxcSBamBSKZJrqbj373CiJSa1v21cRav56C3WfZ', LResult.Result.Value[0].Address);
  AssertEquals('1000', LResult.Result.Value[0].Amount);
  AssertEquals(2, LResult.Result.Value[0].Decimals);
  AssertEquals('10', LResult.Result.Value[0].UiAmountString);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientTokenTests.TestGetTokenLargestAccountsProcessed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TObjectList<TLargeTokenAccount>>>;
begin
  LResponseData := LoadTestData('Token/GetTokenLargestAccountsResponse.json');
  LRequestData := LoadTestData('Token/GetTokenLargestAccountsProcessedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;
  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);

  LResult := LRpcClient.GetTokenLargestAccounts('7ugkvt26sFjMdiFQFP5AQX8m8UkxWaW7rk2nBk4R6Gf2', TCommitment.Processed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(79207653, LResult.Result.Context.Slot);
  AssertEquals(1, LResult.Result.Value.Count);
  AssertEquals('7247amxcSBamBSKZJrqbj373CiJSa1v21cRav56C3WfZ', LResult.Result.Value[0].Address);
  AssertEquals('1000', LResult.Result.Value[0].Amount);
  AssertEquals(2, LResult.Result.Value[0].Decimals);
  AssertEquals('10', LResult.Result.Value[0].UiAmountString);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientTokenTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientTokenTests.Suite);
{$ENDIF}

end.

