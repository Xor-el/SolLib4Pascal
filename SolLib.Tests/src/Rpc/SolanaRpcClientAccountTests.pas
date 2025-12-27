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
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TAccountInfo>>;
begin
  responseData := LoadTestData('Accounts/GetAccountInfoResponse.json');
  requestData  := LoadTestData('Accounts/GetAccountInfoRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetAccountInfo('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  AssertEquals(79200467, result.Result.Context.Slot);
  AssertEquals('', result.Result.Value.Data[0]);
  AssertEquals('base64', result.Result.Value.Data[1]);
  AssertFalse(result.Result.Value.Executable);
  AssertEquals(5478840, result.Result.Value.Lamports);
  AssertEquals('11111111111111111111111111111111', result.Result.Value.Owner);
  AssertEquals(195, result.Result.Value.RentEpoch);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetTokenAccountInfo;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TTokenAccountInfo>>;
  LTokenAccountData: TTokenAccountData;
begin
  responseData := LoadTestData('Accounts/GetTokenAccountInfoResponse.json');
  requestData  := LoadTestData('Accounts/GetTokenAccountInfoRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetTokenAccountInfo('FMFMUFqRsGnKm2tQzsaeytATzSG6Evna4HEbKuS6h9uk');

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil);
  AssertTrue(result.WasSuccessful);

  AssertEquals(103677806, result.Result.Context.Slot);
  AssertFalse(result.Result.Value.Executable);
  AssertEquals(2039280, result.Result.Value.Lamports);
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', result.Result.Value.Owner);
  AssertEquals(239, result.Result.Value.RentEpoch);

  LTokenAccountData := result.Result.Value.Data.AsType<TTokenAccountData>;

  AssertEquals('spl-token', LTokenAccountData.&Program);
  AssertEquals(165, LTokenAccountData.Space);

  AssertEquals('account', LTokenAccountData.Parsed.&Type);

  AssertEquals('2v6JjYRt93Z1h8iTZavSdGdDufocHCFKT8gvHpg3GNko', LTokenAccountData.Parsed.Info.Mint);
  AssertEquals('47vp5BqxBQoMJkitajbsZRhyAR5phW28nKPvXhFDKTFH', LTokenAccountData.Parsed.Info.Owner);
  AssertFalse(LTokenAccountData.Parsed.Info.IsNative);
  AssertEquals('initialized', LTokenAccountData.Parsed.Info.State);

  AssertEquals('1', LTokenAccountData.Parsed.Info.TokenAmount.Amount);
  AssertEquals(0, LTokenAccountData.Parsed.Info.TokenAmount.Decimals);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetTokenMintInfo;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TTokenMintInfo>>;
begin
  responseData := LoadTestData('Accounts/GetTokenMintInfoResponse.json');
  requestData  := LoadTestData('Accounts/GetTokenMintInfoRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetTokenMintInfo('2v6JjYRt93Z1h8iTZavSdGdDufocHCFKT8gvHpg3GNko', TBinaryEncoding.JsonParsed, TCommitment.Confirmed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil);
  AssertTrue(result.WasSuccessful);

  AssertEquals(103677835, result.Result.Context.Slot);
  AssertFalse(result.Result.Value.Executable);
  AssertEquals(1461600, result.Result.Value.Lamports);
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', result.Result.Value.Owner);
  AssertEquals(239, result.Result.Value.RentEpoch);

  AssertEquals('spl-token', result.Result.Value.Data.&Program);
  AssertEquals(82, result.Result.Value.Data.Space);

  AssertEquals('mint', result.Result.Value.Data.Parsed.&Type);

  AssertEquals('Ad35ryfDYGvwGETsvkbgFoGasxdGAEtLPv8CYG3eNaMu', result.Result.Value.Data.Parsed.Info.FreezeAuthority);
  AssertEquals('Ad35ryfDYGvwGETsvkbgFoGasxdGAEtLPv8CYG3eNaMu', result.Result.Value.Data.Parsed.Info.MintAuthority);
  AssertEquals('1', result.Result.Value.Data.Parsed.Info.Supply);
  AssertEquals(0, result.Result.Value.Data.Parsed.Info.Decimals);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetAccountInfoParsed;
var
  responseData, parsedJsonDataOnly, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TAccountInfo>>;
begin
  responseData       := LoadTestData('Accounts/GetAccountInfoParsedResponse.json');
  parsedJsonDataOnly := LoadTestData('Accounts/GetAccountInfoParsedResponseDataOnly.json');
  requestData        := LoadTestData('Accounts/GetAccountInfoParsedRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetAccountInfo('2v6JjYRt93Z1h8iTZavSdGdDufocHCFKT8gvHpg3GNko', TBinaryEncoding.JsonParsed, TCommitment.Confirmed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil);
  AssertTrue(result.WasSuccessful);

  AssertEquals(103659529, result.Result.Context.Slot);
  AssertJsonMatch(parsedJsonDataOnly, result.Result.Value.Data[0]);
  AssertEquals('jsonParsed', result.Result.Value.Data[1]);
  AssertFalse(result.Result.Value.Executable);
  AssertEquals(1461600, result.Result.Value.Lamports);
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', result.Result.Value.Owner);
  AssertEquals(239, result.Result.Value.RentEpoch);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetAccountInfoConfirmed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TAccountInfo>>;
begin
  responseData := LoadTestData('Accounts/GetAccountInfoResponse.json');
  requestData  := LoadTestData('Accounts/GetAccountInfoConfirmedRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetAccountInfo('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', TBinaryEncoding.Base64, TCommitment.Confirmed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil);
  AssertTrue(result.WasSuccessful);

  AssertEquals(79200467, result.Result.Context.Slot);
  AssertEquals('', result.Result.Value.Data[0]);
  AssertEquals('base64', result.Result.Value.Data[1]);
  AssertFalse(result.Result.Value.Executable);
  AssertEquals(5478840, result.Result.Value.Lamports);
  AssertEquals('11111111111111111111111111111111', result.Result.Value.Owner);
  AssertEquals(195, result.Result.Value.RentEpoch);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetProgramAccounts;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TObjectList<TAccountKeyPair>>;
begin
  responseData := LoadTestData('Accounts/GetProgramAccountsResponse.json');
  requestData  := LoadTestData('Accounts/GetProgramAccountsRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetProgramAccounts('GrAkKfEpTKQuVHG2Y97Y2FF4i7y7Q5AHLK94JBy7Y5yv', TNullable<Integer>.None);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  AssertEquals(2, result.Result.Count);
  AssertEquals('FzNKvS4SCHDoNbnnfhmGSLVRCLNBUuGecxdvobSGmWMh', result.Result[0].PublicKey);

  AssertEquals(
    'NhOiFR2mEcZJFj1ciaG2IrWOf2poe4LNGYC5gvdULBYyFH1Kq4cdNyYf+7u2r6NaWXHwnqiXnCzkFhIDU' +
    'jSbNN2i/bmtSgasAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADkpoamWb2mUaHqREQNm8VPcqSWUGCgPjWK' +
    'jh0raCI+OEo8UAXpyc1w/8KV64XXwhGP70z6aN3K1vnzjpYXQqr3vvsgJ4UD4OatRY1IsR9NYTReSKpRIhPpTupzQ9W' +
    'zTpfWSTLZP2xvdcWyo8spQGJ2uGX0jH9h4ZxJ+orI/IsnqxyAHH+MXZuMBl28YfgFJRh8PZHPKbmFvVPDFs3xgBVWzz' +
    'QuNTAlY5aWAEN5CRqkYmOXDcge++gRlEry6ItrMEA0VZV0zsOFk2oDiT9W7slB3JefUOpWS4DMPJW6N0zRUDTtXaGmW' +
    'rqt6W4vEGC0DnBI++A2ZkHoMmJ+qeCKBVkNJgAAADc4o2AAAAAA/w==',
    result.Result[0].Account.Data[0]
  );
  AssertEquals('base64', result.Result[0].Account.Data[1]);
  AssertFalse(result.Result[0].Account.Executable);
  AssertEquals(3486960, result.Result[0].Account.Lamports);
  AssertEquals('GrAkKfEpTKQuVHG2Y97Y2FF4i7y7Q5AHLK94JBy7Y5yv', result.Result[0].Account.Owner);
  AssertEquals(188, result.Result[0].Account.RentEpoch);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetProgramAccountsDataSize;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TObjectList<TAccountKeyPair>>;
begin
  responseData := LoadTestData('Accounts/GetProgramAccountsResponse.json');
  requestData  := LoadTestData('Accounts/GetProgramAccountsDataSizeRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetProgramAccounts('4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T', 500);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  AssertEquals(2, result.Result.Count);
  AssertEquals('FzNKvS4SCHDoNbnnfhmGSLVRCLNBUuGecxdvobSGmWMh', result.Result[0].PublicKey);

  AssertEquals(
    'NhOiFR2mEcZJFj1ciaG2IrWOf2poe4LNGYC5gvdULBYyFH1Kq4cdNyYf+7u2r6NaWXHwnqiXnCzkFhIDU' +
    'jSbNN2i/bmtSgasAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADkpoamWb2mUaHqREQNm8VPcqSWUGCgPjWK' +
    'jh0raCI+OEo8UAXpyc1w/8KV64XXwhGP70z6aN3K1vnzjpYXQqr3vvsgJ4UD4OatRY1IsR9NYTReSKpRIhPpTupzQ9W' +
    'zTpfWSTLZP2xvdcWyo8spQGJ2uGX0jH9h4ZxJ+orI/IsnqxyAHH+MXZuMBl28YfgFJRh8PZHPKbmFvVPDFs3xgBVWzz' +
    'QuNTAlY5aWAEN5CRqkYmOXDcge++gRlEry6ItrMEA0VZV0zsOFk2oDiT9W7slB3JefUOpWS4DMPJW6N0zRUDTtXaGmW' +
    'rqt6W4vEGC0DnBI++A2ZkHoMmJ+qeCKBVkNJgAAADc4o2AAAAAA/w==',
    result.Result[0].Account.Data[0]
  );
  AssertEquals('base64', result.Result[0].Account.Data[1]);
  AssertFalse(result.Result[0].Account.Executable);
  AssertEquals(3486960, result.Result[0].Account.Lamports);
  AssertEquals('GrAkKfEpTKQuVHG2Y97Y2FF4i7y7Q5AHLK94JBy7Y5yv', result.Result[0].Account.Owner);
  AssertEquals(188, result.Result[0].Account.RentEpoch);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetProgramAccountsMemoryCompare;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  filter: TMemCmp;
  filters: TArray<TMemCmp>;
  result: IRequestResult<TObjectList<TAccountKeyPair>>;
begin
  responseData := LoadTestData('Accounts/GetProgramAccountsResponse.json');
  requestData  := LoadTestData('Accounts/GetProgramAccountsMemoryCompareRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  filter := TMemCmp.Create;
  try
    filter.Offset := 25;
    filter.Bytes  := '3Mc6vR';

    SetLength(filters, 1);
    filters[0] := filter;

    rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
    result := rpcClient.GetProgramAccounts(
      '4Nd1mBQtrMJVYVfKf2PJy9NZUZdTAsp7D4xWLs4gDB4T', 500,
      nil, filters
    );

    AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
    AssertTrue(result.Result <> nil, 'Result should not be nil');
    AssertTrue(result.WasSuccessful, 'Should be successful');

    AssertEquals(2, result.Result.Count);
    AssertEquals('FzNKvS4SCHDoNbnnfhmGSLVRCLNBUuGecxdvobSGmWMh', result.Result[0].PublicKey);

    AssertEquals(
      'NhOiFR2mEcZJFj1ciaG2IrWOf2poe4LNGYC5gvdULBYyFH1Kq4cdNyYf+7u2r6NaWXHwnqiXnCzkFhIDU' +
      'jSbNN2i/bmtSgasAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADkpoamWb2mUaHqREQNm8VPcqSWUGCgPjWK' +
      'jh0raCI+OEo8UAXpyc1w/8KV64XXwhGP70z6aN3K1vnzjpYXQqr3vvsgJ4UD4OatRY1IsR9NYTReSKpRIhPpTupzQ9W' +
      'zTpfWSTLZP2xvdcWyo8spQGJ2uGX0jH9h4ZxJ+orI/IsnqxyAHH+MXZuMBl28YfgFJRh8PZHPKbmFvVPDFs3xgBVWzz' +
      'QuNTAlY5aWAEN5CRqkYmOXDcge++gRlEry6ItrMEA0VZV0zsOFk2oDiT9W7slB3JefUOpWS4DMPJW6N0zRUDTtXaGmW' +
      'rqt6W4vEGC0DnBI++A2ZkHoMmJ+qeCKBVkNJgAAADc4o2AAAAAA/w==',
      result.Result[0].Account.Data[0]
    );
    AssertEquals('base64', result.Result[0].Account.Data[1]);
    AssertFalse(result.Result[0].Account.Executable);
    AssertEquals(3486960, result.Result[0].Account.Lamports);
    AssertEquals('GrAkKfEpTKQuVHG2Y97Y2FF4i7y7Q5AHLK94JBy7Y5yv', result.Result[0].Account.Owner);
    AssertEquals(188, result.Result[0].Account.RentEpoch);

    FinishTest(mockRpcHttpClient, TestnetUrl);
  finally
    filter.Free;
    if Length(filters) > 0 then filters[0] := nil;
  end;
end;

procedure TSolanaRpcClientAccountTests.TestGetProgramAccountsProcessed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TObjectList<TAccountKeyPair>>;
begin
  responseData := LoadTestData('Accounts/GetProgramAccountsResponse.json');
  requestData  := LoadTestData('Accounts/GetProgramAccountsProcessedRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetProgramAccounts('GrAkKfEpTKQuVHG2Y97Y2FF4i7y7Q5AHLK94JBy7Y5yv',
                                      TNullable<Integer>.None, nil, nil, TBinaryEncoding.Base64, TCommitment.Processed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  AssertEquals(2, result.Result.Count);
  AssertEquals('FzNKvS4SCHDoNbnnfhmGSLVRCLNBUuGecxdvobSGmWMh', result.Result[0].PublicKey);

  AssertEquals(
    'NhOiFR2mEcZJFj1ciaG2IrWOf2poe4LNGYC5gvdULBYyFH1Kq4cdNyYf+7u2r6NaWXHwnqiXnCzkFhIDU' +
    'jSbNN2i/bmtSgasAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADkpoamWb2mUaHqREQNm8VPcqSWUGCgPjWK' +
    'jh0raCI+OEo8UAXpyc1w/8KV64XXwhGP70z6aN3K1vnzjpYXQqr3vvsgJ4UD4OatRY1IsR9NYTReSKpRIhPpTupzQ9W' +
    'zTpfWSTLZP2xvdcWyo8spQGJ2uGX0jH9h4ZxJ+orI/IsnqxyAHH+MXZuMBl28YfgFJRh8PZHPKbmFvVPDFs3xgBVWzz' +
    'QuNTAlY5aWAEN5CRqkYmOXDcge++gRlEry6ItrMEA0VZV0zsOFk2oDiT9W7slB3JefUOpWS4DMPJW6N0zRUDTtXaGmW' +
    'rqt6W4vEGC0DnBI++A2ZkHoMmJ+qeCKBVkNJgAAADc4o2AAAAAA/w==',
    result.Result[0].Account.Data[0]
  );
  AssertEquals('base64', result.Result[0].Account.Data[1]);
  AssertFalse(result.Result[0].Account.Executable);
  AssertEquals(3486960, result.Result[0].Account.Lamports);
  AssertEquals('GrAkKfEpTKQuVHG2Y97Y2FF4i7y7Q5AHLK94JBy7Y5yv', result.Result[0].Account.Owner);
  AssertEquals(188, result.Result[0].Account.RentEpoch);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetMultipleAccounts;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TObjectList<TAccountInfo>>>;
  pubkeys: TArray<string>;
begin
  responseData := LoadTestData('Accounts/GetMultipleAccountsResponse.json');
  requestData  := LoadTestData('Accounts/GetMultipleAccountsRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  pubkeys := TArray<string>.Create(
    'Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu',
    '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5'
  );

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetMultipleAccounts(pubkeys);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful);

  AssertEquals(2, result.Result.Value.Count);
  AssertEquals('base64', result.Result.Value[0].Data[1]);
  AssertEquals('',       result.Result.Value[0].Data[0]);
  AssertFalse(result.Result.Value[0].Executable);
  AssertEquals(503668985208, result.Result.Value[0].Lamports);
  AssertEquals('11111111111111111111111111111111', result.Result.Value[0].Owner);
  AssertEquals(197, result.Result.Value[0].RentEpoch);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetMultipleAccountsConfirmed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TObjectList<TAccountInfo>>>;
  pubkeys: TArray<string>;
begin
  responseData := LoadTestData('Accounts/GetMultipleAccountsResponse.json');
  requestData  := LoadTestData('Accounts/GetMultipleAccountsConfirmedRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  pubkeys := TArray<string>.Create(
    'Bbe9EKucmRtJr2J4dd5Eb5ybQmY7Fm7jYxKXxmmkLFsu',
    '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5'
  );

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetMultipleAccounts(pubkeys, TBinaryEncoding.Base64, TCommitment.Confirmed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful);

  AssertEquals(2, result.Result.Value.Count);
  AssertEquals('base64', result.Result.Value[0].Data[1]);
  AssertEquals('',       result.Result.Value[0].Data[0]);
  AssertFalse(result.Result.Value[0].Executable);
  AssertEquals(503668985208, result.Result.Value[0].Lamports);
  AssertEquals('11111111111111111111111111111111', result.Result.Value[0].Owner);
  AssertEquals(197, result.Result.Value[0].RentEpoch);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetLargestAccounts;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TObjectList<TLargeAccount>>>;
begin
  responseData := LoadTestData('Accounts/GetLargestAccountsResponse.json');
  requestData  := LoadTestData('Accounts/GetLargestAccountsRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetLargestAccounts(TAccountFilterType.Circulating);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful);

  AssertEquals(20, result.Result.Value.Count);
  AssertEquals('6caH6ayzofHnP8kcPQTEBrDPG4A2qDo1STE5xTMJ52k8', result.Result.Value[0].Address);
  AssertEquals(20161157050000000, result.Result.Value[0].Lamports);
  AssertEquals('gWgqQ4udVxE3uNxRHEwvftTHwpEmPHAd8JR9UzaHbR2', result.Result.Value[19].Address);
  AssertEquals(2499999990454560, result.Result.Value[19].Lamports);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetLargestAccountsNonCirculatingProcessed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TResponseValue<TObjectList<TLargeAccount>>>;
begin
  responseData := LoadTestData('Accounts/GetLargestAccountsResponse.json');
  requestData  := LoadTestData('Accounts/GetLargestAccountsNonCirculatingProcessedRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetLargestAccounts(TAccountFilterType.NonCirculating, TCommitment.Processed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil, 'Result should not be nil');
  AssertTrue(result.WasSuccessful);

  AssertEquals(20, result.Result.Value.Count);
  AssertEquals('6caH6ayzofHnP8kcPQTEBrDPG4A2qDo1STE5xTMJ52k8', result.Result.Value[0].Address);
  AssertEquals(20161157050000000, result.Result.Value[0].Lamports);
  AssertEquals('gWgqQ4udVxE3uNxRHEwvftTHwpEmPHAd8JR9UzaHbR2', result.Result.Value[19].Address);
  AssertEquals(2499999990454560, result.Result.Value[19].Lamports);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetVoteAccounts;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TVoteAccounts>;
begin
  responseData := LoadTestData('GetVoteAccountsResponse.json');
  requestData  := LoadTestData('GetVoteAccountsRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetVoteAccounts;

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil);
  AssertTrue(result.WasSuccessful);

  AssertEquals(1, result.Result.Current.Count);
  AssertEquals(1, result.Result.Delinquent.Count);

  AssertEquals(81274518, result.Result.Current[0].RootSlot);
  AssertEquals('3ZT31jkAGhUaw8jsy4bTknwBMP8i4Eueh52By4zXcsVw', result.Result.Current[0].VotePublicKey);
  AssertEquals('B97CCUW3AEZFGy6uUg6zUdnNYvnVq5VG8PUtb2HayTDD', result.Result.Current[0].NodePublicKey);
  AssertEquals(42,  result.Result.Current[0].ActivatedStake);
  AssertEquals(0,   result.Result.Current[0].Commission);
  AssertEquals(147, result.Result.Current[0].LastVote);
  AssertTrue(result.Result.Current[0].EpochVoteAccount);
  AssertEquals(2,   Length(result.Result.Current[0].EpochCredits));

  AssertEquals(1234, result.Result.Delinquent[0].RootSlot);
  AssertEquals('CmgCk4aMS7KW1SHX3s9K5tBJ6Yng2LBaC8MFov4wx9sm', result.Result.Delinquent[0].VotePublicKey);
  AssertEquals('6ZPxeQaDo4bkZLRsdNrCzchNQr5LN9QMc9sipXv9Kw8f', result.Result.Delinquent[0].NodePublicKey);
  AssertEquals(0,    result.Result.Delinquent[0].ActivatedStake);
  AssertFalse(result.Result.Delinquent[0].EpochVoteAccount);
  AssertEquals(127,  result.Result.Delinquent[0].Commission);
  AssertEquals(0,    result.Result.Delinquent[0].LastVote);
  AssertEquals(0,    Length(result.Result.Delinquent[0].EpochCredits));

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientAccountTests.TestGetVoteAccountsWithConfigParams;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TVoteAccounts>;
begin
  responseData := LoadTestData('GetVoteAccountsResponse.json');
  requestData  := LoadTestData('GetVoteAccountsWithParamsRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetVoteAccounts('6ZPxeQaDo4bkZLRsdNrCzchNQr5LN9QMc9sipXv9Kw8f', TCommitment.Processed);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertTrue(result.Result <> nil);
  AssertTrue(result.WasSuccessful);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientAccountTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientAccountTests.Suite);
{$ENDIF}

end.

