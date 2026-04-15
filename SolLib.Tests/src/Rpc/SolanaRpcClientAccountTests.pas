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

unit SolanaRpcClientAccountTests;

interface

uses
  SysUtils,
  Generics.Collections,
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
  SlpNullable,
  RpcClientMocks,
  SolLibRpcClientTestCase;

type
  TSolanaRpcClientAccountTests = class(TSolLibRpcClientTestCase)
  published
    procedure TestGetAccountInfoDefault;
    procedure TestGetTokenAccountInfo;
    procedure TestGetTokenMintInfo;
    procedure TestGetAccountInfoParsed;
    procedure TestGetAccountInfoConfirmed;

    procedure TestGetProgramAccounts;
    procedure TestGetProgramAccountsDataSize;
    procedure TestGetProgramAccountsMemoryCompare;
    procedure TestGetProgramAccountsProcessed;

    procedure TestGetMultipleAccounts;
    procedure TestGetMultipleAccountsConfirmed;

    procedure TestGetLargestAccounts;
    procedure TestGetLargestAccountsNonCirculatingProcessed;

    procedure TestGetVoteAccounts;
    procedure TestGetVoteAccountsWithConfigParams;
  end;

implementation

{ TSolanaRpcClientAccountTests }

procedure TSolanaRpcClientAccountTests.TestGetAccountInfoDefault;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TAccountInfo>>;
begin
  LResponseData := LoadTestData('Accounts/GetAccountInfoResponse.json');
  LRequestData := LoadTestData('Accounts/GetAccountInfoRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetAccountInfo('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  AssertEquals(79200467, LResult.Result.Context.Slot);
  AssertEquals('', LResult.Result.Value.Data[0]);
  AssertEquals('base64', LResult.Result.Value.Data[1]);
  AssertFalse(LResult.Result.Value.Executable);
  AssertEquals(5478840, LResult.Result.Value.Lamports);
  AssertEquals('11111111111111111111111111111111', LResult.Result.Value.Owner);
  AssertEquals(195, LResult.Result.Value.RentEpoch);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetTokenAccountInfo;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TTokenAccountInfo>>;
  LTokenAccountData: TTokenAccountData;
begin
  LResponseData := LoadTestData('Accounts/GetTokenAccountInfoResponse.json');
  LRequestData := LoadTestData('Accounts/GetTokenAccountInfoRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetTokenAccountInfo('FMFMUFqRsGnKm2tQzsaeytATzSG6Evna4HEbKuS6h9uk');

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(103677806, LResult.Result.Context.Slot);
  AssertFalse(LResult.Result.Value.Executable);
  AssertEquals(2039280, LResult.Result.Value.Lamports);
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LResult.Result.Value.Owner);
  AssertEquals(239, LResult.Result.Value.RentEpoch);

  LTokenAccountData := LResult.Result.Value.Data.AsType<TTokenAccountData>;

  AssertEquals('spl-token', LTokenAccountData.&Program);
  AssertEquals(165, LTokenAccountData.Space);

  AssertEquals('account', LTokenAccountData.Parsed.&Type);

  AssertEquals('2v6JjYRt93Z1h8iTZavSdGdDufocHCFKT8gvHpg3GNko', LTokenAccountData.Parsed.Info.Mint);
  AssertEquals('47vp5BqxBQoMJkitajbsZRhyAR5phW28nKPvXhFDKTFH', LTokenAccountData.Parsed.Info.Owner);
  AssertFalse(LTokenAccountData.Parsed.Info.IsNative);
  AssertEquals('initialized', LTokenAccountData.Parsed.Info.State);

  AssertEquals('1', LTokenAccountData.Parsed.Info.TokenAmount.Amount);
  AssertEquals(0, LTokenAccountData.Parsed.Info.TokenAmount.Decimals);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetTokenMintInfo;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TTokenMintInfo>>;
begin
  LResponseData := LoadTestData('Accounts/GetTokenMintInfoResponse.json');
  LRequestData := LoadTestData('Accounts/GetTokenMintInfoRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetTokenMintInfo('2v6JjYRt93Z1h8iTZavSdGdDufocHCFKT8gvHpg3GNko', TBinaryEncoding.JsonParsed, TCommitment.Confirmed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(103677835, LResult.Result.Context.Slot);
  AssertFalse(LResult.Result.Value.Executable);
  AssertEquals(1461600, LResult.Result.Value.Lamports);
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LResult.Result.Value.Owner);
  AssertEquals(239, LResult.Result.Value.RentEpoch);

  AssertEquals('spl-token', LResult.Result.Value.Data.&Program);
  AssertEquals(82, LResult.Result.Value.Data.Space);

  AssertEquals('mint', LResult.Result.Value.Data.Parsed.&Type);

  AssertEquals('Ad35ryfDYGvwGETsvkbgFoGasxdGAEtLPv8CYG3eNaMu', LResult.Result.Value.Data.Parsed.Info.FreezeAuthority);
  AssertEquals('Ad35ryfDYGvwGETsvkbgFoGasxdGAEtLPv8CYG3eNaMu', LResult.Result.Value.Data.Parsed.Info.MintAuthority);
  AssertEquals('1', LResult.Result.Value.Data.Parsed.Info.Supply);
  AssertEquals(0, LResult.Result.Value.Data.Parsed.Info.Decimals);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetAccountInfoParsed;
var
  LResponseData, LParsedJsonDataOnly, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TAccountInfo>>;
begin
  LResponseData := LoadTestData('Accounts/GetAccountInfoParsedResponse.json');
  LParsedJsonDataOnly := LoadTestData('Accounts/GetAccountInfoParsedResponseDataOnly.json');
  LRequestData := LoadTestData('Accounts/GetAccountInfoParsedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetAccountInfo('2v6JjYRt93Z1h8iTZavSdGdDufocHCFKT8gvHpg3GNko', TBinaryEncoding.JsonParsed, TCommitment.Confirmed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(103659529, LResult.Result.Context.Slot);
  AssertJsonMatch(LParsedJsonDataOnly, LResult.Result.Value.Data[0]);
  AssertEquals('jsonParsed', LResult.Result.Value.Data[1]);
  AssertFalse(LResult.Result.Value.Executable);
  AssertEquals(1461600, LResult.Result.Value.Lamports);
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LResult.Result.Value.Owner);
  AssertEquals(239, LResult.Result.Value.RentEpoch);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetAccountInfoConfirmed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TAccountInfo>>;
begin
  LResponseData := LoadTestData('Accounts/GetAccountInfoResponse.json');
  LRequestData := LoadTestData('Accounts/GetAccountInfoConfirmedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetAccountInfo('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', TBinaryEncoding.Base64, TCommitment.Confirmed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(79200467, LResult.Result.Context.Slot);
  AssertEquals('', LResult.Result.Value.Data[0]);
  AssertEquals('base64', LResult.Result.Value.Data[1]);
  AssertFalse(LResult.Result.Value.Executable);
  AssertEquals(5478840, LResult.Result.Value.Lamports);
  AssertEquals('11111111111111111111111111111111', LResult.Result.Value.Owner);
  AssertEquals(195, LResult.Result.Value.RentEpoch);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetProgramAccounts;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TObjectList<TAccountKeyPair>>;
begin
  LResponseData := LoadTestData('Accounts/GetProgramAccountsResponse.json');
  LRequestData := LoadTestData('Accounts/GetProgramAccountsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetProgramAccounts('GrAkKfEpTKQuVHG2Y97Y2FF4i7y7Q5AHLK94JBy7Y5yv', TNullable<Integer>.None);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  AssertEquals(2, LResult.Result.Count);
  AssertEquals('FzNKvS4SCHDoNbnnfhmGSLVRCLNBUuGecxdvobSGmWMh', LResult.Result[0].PublicKey);

  AssertEquals(
    'NhOiFR2mEcZJFj1ciaG2IrWOf2poe4LNGYC5gvdULBYyFH1Kq4cdNyYf+7u2r6NaWXHwnqiXnCzkFhIDU' +
    'jSbNN2i/bmtSgasAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADkpoamWb2mUaHqREQNm8VPcqSWUGCgPjWK' +
    'jh0raCI+OEo8UAXpyc1w/8KV64XXwhGP70z6aN3K1vnzjpYXQqr3vvsgJ4UD4OatRY1IsR9NYTReSKpRIhPpTupzQ9W' +
    'zTpfWSTLZP2xvdcWyo8spQGJ2uGX0jH9h4ZxJ+orI/IsnqxyAHH+MXZuMBl28YfgFJRh8PZHPKbmFvVPDFs3xgBVWzz' +
    'QuNTAlY5aWAEN5CRqkYmOXDcge++gRlEry6ItrMEA0VZV0zsOFk2oDiT9W7slB3JefUOpWS4DMPJW6N0zRUDTtXaGmW' +
    'rqt6W4vEGC0DnBI++A2ZkHoMmJ+qeCKBVkNJgAAADc4o2AAAAAA/w==',
    LResult.Result[0].Account.Data[0]
  );
  AssertEquals('base64', LResult.Result[0].Account.Data[1]);
  AssertFalse(LResult.Result[0].Account.Executable);
  AssertEquals(3486960, LResult.Result[0].Account.Lamports);
  AssertEquals('GrAkKfEpTKQuVHG2Y97Y2FF4i7y7Q5AHLK94JBy7Y5yv', LResult.Result[0].Account.Owner);
  AssertEquals(188, LResult.Result[0].Account.RentEpoch);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetProgramAccountsDataSize;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TObjectList<TAccountKeyPair>>;
begin
  LResponseData := LoadTestData('Accounts/GetProgramAccountsResponse.json');
  LRequestData := LoadTestData('Accounts/GetProgramAccountsDataSizeRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetProgramAccounts('4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T', 500);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  AssertEquals(2, LResult.Result.Count);
  AssertEquals('FzNKvS4SCHDoNbnnfhmGSLVRCLNBUuGecxdvobSGmWMh', LResult.Result[0].PublicKey);

  AssertEquals(
    'NhOiFR2mEcZJFj1ciaG2IrWOf2poe4LNGYC5gvdULBYyFH1Kq4cdNyYf+7u2r6NaWXHwnqiXnCzkFhIDU' +
    'jSbNN2i/bmtSgasAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADkpoamWb2mUaHqREQNm8VPcqSWUGCgPjWK' +
    'jh0raCI+OEo8UAXpyc1w/8KV64XXwhGP70z6aN3K1vnzjpYXQqr3vvsgJ4UD4OatRY1IsR9NYTReSKpRIhPpTupzQ9W' +
    'zTpfWSTLZP2xvdcWyo8spQGJ2uGX0jH9h4ZxJ+orI/IsnqxyAHH+MXZuMBl28YfgFJRh8PZHPKbmFvVPDFs3xgBVWzz' +
    'QuNTAlY5aWAEN5CRqkYmOXDcge++gRlEry6ItrMEA0VZV0zsOFk2oDiT9W7slB3JefUOpWS4DMPJW6N0zRUDTtXaGmW' +
    'rqt6W4vEGC0DnBI++A2ZkHoMmJ+qeCKBVkNJgAAADc4o2AAAAAA/w==',
    LResult.Result[0].Account.Data[0]
  );
  AssertEquals('base64', LResult.Result[0].Account.Data[1]);
  AssertFalse(LResult.Result[0].Account.Executable);
  AssertEquals(3486960, LResult.Result[0].Account.Lamports);
  AssertEquals('GrAkKfEpTKQuVHG2Y97Y2FF4i7y7Q5AHLK94JBy7Y5yv', LResult.Result[0].Account.Owner);
  AssertEquals(188, LResult.Result[0].Account.RentEpoch);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetProgramAccountsMemoryCompare;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LFilter: TMemCmp;
  LFilters: TArray<TMemCmp>;
  LResult: IRequestResult<TObjectList<TAccountKeyPair>>;
begin
  LResponseData := LoadTestData('Accounts/GetProgramAccountsResponse.json');
  LRequestData := LoadTestData('Accounts/GetProgramAccountsMemoryCompareRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LFilter := TMemCmp.Create;
  try
    LFilter.Offset := 25;
    LFilter.Bytes := '3Mc6vR';

    SetLength(LFilters, 1);
    LFilters[0] := LFilter;

    LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
    LResult := LRpcClient.GetProgramAccounts(
      '4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T', 500,
      nil, LFilters
    );

    AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
    AssertTrue(LResult.Result <> nil, 'Result should not be nil');
    AssertTrue(LResult.WasSuccessful, 'Should be successful');

    AssertEquals(2, LResult.Result.Count);
    AssertEquals('FzNKvS4SCHDoNbnnfhmGSLVRCLNBUuGecxdvobSGmWMh', LResult.Result[0].PublicKey);

    AssertEquals(
      'NhOiFR2mEcZJFj1ciaG2IrWOf2poe4LNGYC5gvdULBYyFH1Kq4cdNyYf+7u2r6NaWXHwnqiXnCzkFhIDU' +
      'jSbNN2i/bmtSgasAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADkpoamWb2mUaHqREQNm8VPcqSWUGCgPjWK' +
      'jh0raCI+OEo8UAXpyc1w/8KV64XXwhGP70z6aN3K1vnzjpYXQqr3vvsgJ4UD4OatRY1IsR9NYTReSKpRIhPpTupzQ9W' +
      'zTpfWSTLZP2xvdcWyo8spQGJ2uGX0jH9h4ZxJ+orI/IsnqxyAHH+MXZuMBl28YfgFJRh8PZHPKbmFvVPDFs3xgBVWzz' +
      'QuNTAlY5aWAEN5CRqkYmOXDcge++gRlEry6ItrMEA0VZV0zsOFk2oDiT9W7slB3JefUOpWS4DMPJW6N0zRUDTtXaGmW' +
      'rqt6W4vEGC0DnBI++A2ZkHoMmJ+qeCKBVkNJgAAADc4o2AAAAAA/w==',
      LResult.Result[0].Account.Data[0]
    );
    AssertEquals('base64', LResult.Result[0].Account.Data[1]);
    AssertFalse(LResult.Result[0].Account.Executable);
    AssertEquals(3486960, LResult.Result[0].Account.Lamports);
    AssertEquals('GrAkKfEpTKQuVHG2Y97Y2FF4i7y7Q5AHLK94JBy7Y5yv', LResult.Result[0].Account.Owner);
    AssertEquals(188, LResult.Result[0].Account.RentEpoch);

    FinishTest(LMockRpcHttpClient, TestnetUrl);
  finally
    LFilter.Free;
    if Length(LFilters) > 0 then LFilters[0] := nil;
  end;
end;

procedure TSolanaRpcClientAccountTests.TestGetProgramAccountsProcessed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TObjectList<TAccountKeyPair>>;
begin
  LResponseData := LoadTestData('Accounts/GetProgramAccountsResponse.json');
  LRequestData := LoadTestData('Accounts/GetProgramAccountsProcessedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetProgramAccounts('GrAkKfEpTKQuVHG2Y97Y2FF4i7y7Q5AHLK94JBy7Y5yv',
                                      TNullable<Integer>.None, nil, nil, TBinaryEncoding.Base64, TCommitment.Processed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  AssertEquals(2, LResult.Result.Count);
  AssertEquals('FzNKvS4SCHDoNbnnfhmGSLVRCLNBUuGecxdvobSGmWMh', LResult.Result[0].PublicKey);

  AssertEquals(
    'NhOiFR2mEcZJFj1ciaG2IrWOf2poe4LNGYC5gvdULBYyFH1Kq4cdNyYf+7u2r6NaWXHwnqiXnCzkFhIDU' +
    'jSbNN2i/bmtSgasAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADkpoamWb2mUaHqREQNm8VPcqSWUGCgPjWK' +
    'jh0raCI+OEo8UAXpyc1w/8KV64XXwhGP70z6aN3K1vnzjpYXQqr3vvsgJ4UD4OatRY1IsR9NYTReSKpRIhPpTupzQ9W' +
    'zTpfWSTLZP2xvdcWyo8spQGJ2uGX0jH9h4ZxJ+orI/IsnqxyAHH+MXZuMBl28YfgFJRh8PZHPKbmFvVPDFs3xgBVWzz' +
    'QuNTAlY5aWAEN5CRqkYmOXDcge++gRlEry6ItrMEA0VZV0zsOFk2oDiT9W7slB3JefUOpWS4DMPJW6N0zRUDTtXaGmW' +
    'rqt6W4vEGC0DnBI++A2ZkHoMmJ+qeCKBVkNJgAAADc4o2AAAAAA/w==',
    LResult.Result[0].Account.Data[0]
  );
  AssertEquals('base64', LResult.Result[0].Account.Data[1]);
  AssertFalse(LResult.Result[0].Account.Executable);
  AssertEquals(3486960, LResult.Result[0].Account.Lamports);
  AssertEquals('GrAkKfEpTKQuVHG2Y97Y2FF4i7y7Q5AHLK94JBy7Y5yv', LResult.Result[0].Account.Owner);
  AssertEquals(188, LResult.Result[0].Account.RentEpoch);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetMultipleAccounts;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TObjectList<TAccountInfo>>>;
  LPubKeys: TArray<string>;
begin
  LResponseData := LoadTestData('Accounts/GetMultipleAccountsResponse.json');
  LRequestData := LoadTestData('Accounts/GetMultipleAccountsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LPubKeys := TArray<string>.Create(
    'Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu',
    '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5'
  );

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetMultipleAccounts(LPubKeys);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(2, LResult.Result.Value.Count);
  AssertEquals('base64', LResult.Result.Value[0].Data[1]);
  AssertEquals('',       LResult.Result.Value[0].Data[0]);
  AssertFalse(LResult.Result.Value[0].Executable);
  AssertEquals(503668985208, LResult.Result.Value[0].Lamports);
  AssertEquals('11111111111111111111111111111111', LResult.Result.Value[0].Owner);
  AssertEquals(197, LResult.Result.Value[0].RentEpoch);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetMultipleAccountsConfirmed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TObjectList<TAccountInfo>>>;
  LPubkeys: TArray<string>;
begin
  LResponseData := LoadTestData('Accounts/GetMultipleAccountsResponse.json');
  LRequestData := LoadTestData('Accounts/GetMultipleAccountsConfirmedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LPubkeys := TArray<string>.Create(
    'Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu',
    '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5'
  );

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetMultipleAccounts(LPubkeys, TBinaryEncoding.Base64, TCommitment.Confirmed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(2, LResult.Result.Value.Count);
  AssertEquals('base64', LResult.Result.Value[0].Data[1]);
  AssertEquals('',       LResult.Result.Value[0].Data[0]);
  AssertFalse(LResult.Result.Value[0].Executable);
  AssertEquals(503668985208, LResult.Result.Value[0].Lamports);
  AssertEquals('11111111111111111111111111111111', LResult.Result.Value[0].Owner);
  AssertEquals(197, LResult.Result.Value[0].RentEpoch);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetLargestAccounts;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TObjectList<TLargeAccount>>>;
begin
  LResponseData := LoadTestData('Accounts/GetLargestAccountsResponse.json');
  LRequestData := LoadTestData('Accounts/GetLargestAccountsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetLargestAccounts(TAccountFilterType.Circulating);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(20, LResult.Result.Value.Count);
  AssertEquals('6caH6ayzofHnP8kcPQTEBrDPG4A2qDo1STE5xTMJ52k8', LResult.Result.Value[0].Address);
  AssertEquals(20161157050000000, LResult.Result.Value[0].Lamports);
  AssertEquals('gWgqQ4udVxE3uNxRHEwvftTHwpEmPHAd8JR9UzaHbR2', LResult.Result.Value[19].Address);
  AssertEquals(2499999990454560, LResult.Result.Value[19].Lamports);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetLargestAccountsNonCirculatingProcessed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TResponseValue<TObjectList<TLargeAccount>>>;
begin
  LResponseData := LoadTestData('Accounts/GetLargestAccountsResponse.json');
  LRequestData := LoadTestData('Accounts/GetLargestAccountsNonCirculatingProcessedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetLargestAccounts(TAccountFilterType.NonCirculating, TCommitment.Processed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(20, LResult.Result.Value.Count);
  AssertEquals('6caH6ayzofHnP8kcPQTEBrDPG4A2qDo1STE5xTMJ52k8', LResult.Result.Value[0].Address);
  AssertEquals(20161157050000000, LResult.Result.Value[0].Lamports);
  AssertEquals('gWgqQ4udVxE3uNxRHEwvftTHwpEmPHAd8JR9UzaHbR2', LResult.Result.Value[19].Address);
  AssertEquals(2499999990454560, LResult.Result.Value[19].Lamports);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetVoteAccounts;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TVoteAccounts>;
begin
  LResponseData := LoadTestData('GetVoteAccountsResponse.json');
  LRequestData := LoadTestData('GetVoteAccountsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetVoteAccounts;

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(1, LResult.Result.Current.Count);
  AssertEquals(1, LResult.Result.Delinquent.Count);

  AssertEquals(81274518, LResult.Result.Current[0].RootSlot);
  AssertEquals('3ZT31jkAGhUaw8jsy4bTknwBMP8i4Eueh52By4zXcsVw', LResult.Result.Current[0].VotePublicKey);
  AssertEquals('B97CCUW3AEZFGy6uUg6zUdnNYvnVq5VG8PUtb2HayTDD', LResult.Result.Current[0].NodePublicKey);
  AssertEquals(42,  LResult.Result.Current[0].ActivatedStake);
  AssertEquals(0,   LResult.Result.Current[0].Commission);
  AssertEquals(147, LResult.Result.Current[0].LastVote);
  AssertTrue(LResult.Result.Current[0].EpochVoteAccount);
  AssertEquals(2,   Length(LResult.Result.Current[0].EpochCredits));

  AssertEquals(1234, LResult.Result.Delinquent[0].RootSlot);
  AssertEquals('CmgCk4aMS7KW1SHX3s9K5tBJ6Yng2LBaC8MFov4wx9sm', LResult.Result.Delinquent[0].VotePublicKey);
  AssertEquals('6ZPxeQaDo4bkZLRsdNrCzchNQr5LN9QMc9sipXv9Kw8f', LResult.Result.Delinquent[0].NodePublicKey);
  AssertEquals(0,    LResult.Result.Delinquent[0].ActivatedStake);
  AssertFalse(LResult.Result.Delinquent[0].EpochVoteAccount);
  AssertEquals(127,  LResult.Result.Delinquent[0].Commission);
  AssertEquals(0,    LResult.Result.Delinquent[0].LastVote);
  AssertEquals(0,    Length(LResult.Result.Delinquent[0].EpochCredits));

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetVoteAccountsWithConfigParams;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TVoteAccounts>;
begin
  LResponseData := LoadTestData('GetVoteAccountsResponse.json');
  LRequestData := LoadTestData('GetVoteAccountsWithParamsRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetVoteAccounts('6ZPxeQaDo4bkZLRsdNrCzchNQr5LN9QMc9sipXv9Kw8f', TCommitment.Processed);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(LResult.Result <> nil);
  AssertTrue(LResult.WasSuccessful);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientAccountTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientAccountTests.Suite);
{$ENDIF}

end.

