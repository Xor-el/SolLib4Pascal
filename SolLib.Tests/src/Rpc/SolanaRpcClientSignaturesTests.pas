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

unit SolanaRpcClientSignaturesTests;

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
  TSolanaRpcClientSignaturesTests = class(TSolLibRpcClientTestCase)
  published
    procedure TestGetSignaturesForAddress;
    procedure TestGetSignaturesForAddress_InvalidCommitment;
    procedure TestGetSignaturesForAddressUntil;
    procedure TestGetSignaturesForAddressBefore;
    procedure TestGetSignaturesForAddressBeforeConfirmed;

    procedure TestGetSignatureStatuses;
    procedure TestGetSignatureStatusesWithHistory;
  end;

implementation

{ TSolanaRpcClientSignaturesTests }

procedure TSolanaRpcClientSignaturesTests.TestGetSignaturesForAddress;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TObjectList<TSignatureStatusInfo>>;
begin
  responseData := LoadTestData('Signatures/GetSignaturesForAddressResponse.json');
  requestData  := LoadTestData('Signatures/GetSignaturesForAddressRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetSignaturesForAddress('4Rf9mGD7FeYknun5JczX5nGLTfQuS1GRjNVfkEMKE92b', 3);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result, 'Result should not be nil');
  AssertTrue(result.WasSuccessful, 'Should be successful');

  AssertEquals(3, result.Result.Count);
  AssertEquals(1616245823, result.Result[0].BlockTime.Value);
  AssertEquals(68710495,   result.Result[0].Slot);
  AssertEquals('5Jofwx5JcPT1dMsgo6DkyT6x61X5chS9K7hM7huGKAnUq8xxHwGKuDnnZmPGoapWVZcN4cPvQtGNCicnWZfPHowr', result.Result[0].Signature);
  AssertEquals('', result.Result[0].Memo);
  AssertNull(result.Result[0].Error);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientSignaturesTests.TestGetSignaturesForAddress_InvalidCommitment;
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
      rpcClient.GetSignaturesForAddress(
        '4Rf9mGD7FeYknun5JczX5nGLTfQuS1GRjNVfkEMKE92b',
        1000,
        '',
        '',
        TCommitment.Processed
      );
    end,
    EArgumentException
  );
end;

procedure TSolanaRpcClientSignaturesTests.TestGetSignaturesForAddressUntil;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TObjectList<TSignatureStatusInfo>>;
begin
  responseData := LoadTestData('Signatures/GetSignaturesForAddressUntilResponse.json');
  requestData  := LoadTestData('Signatures/GetSignaturesForAddressUntilRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetSignaturesForAddress(
    'Vote111111111111111111111111111111111111111',
    1,
    '',
    'Vote111111111111111111111111111111111111111'
  );

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);
  AssertEquals(1, result.Result.Count);
  AssertFalse(result.Result[0].BlockTime.HasValue);
  AssertEquals(114, result.Result[0].Slot);
  AssertEquals('5h6xBEauJ3PK6SWCZ1PGjBvj8vDdWG3KpwATGy1ARAXFSDwt8GFXM7W5Ncn16wmqokgpiKRLuS83KUxyZyv2sUYv', result.Result[0].Signature);
  AssertEquals('', result.Result[0].Memo);
  AssertNull(result.Result[0].Error);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientSignaturesTests.TestGetSignaturesForAddressBefore;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TObjectList<TSignatureStatusInfo>>;
begin
  responseData := LoadTestData('Signatures/GetSignaturesForAddressBeforeResponse.json');
  requestData  := LoadTestData('Signatures/GetSignaturesForAddressBeforeRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetSignaturesForAddress(
    'Vote111111111111111111111111111111111111111',
    1, 'Vote111111111111111111111111111111111111111', ''
  );

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);
  AssertEquals(1, result.Result.Count);
  AssertFalse(result.Result[0].BlockTime.HasValue);
  AssertEquals(114, result.Result[0].Slot);
  AssertEquals('5h6xBEauJ3PK6SWCZ1PGjBvj8vDdWG3KpwATGy1ARAXFSDwt8GFXM7W5Ncn16wmqokgpiKRLuS83KUxyZyv2sUYv', result.Result[0].Signature);
  AssertEquals('', result.Result[0].Memo);
  AssertNull(result.Result[0].Error);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientSignaturesTests.TestGetSignaturesForAddressBeforeConfirmed;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  result: IRequestResult<TObjectList<TSignatureStatusInfo>>;
begin
  responseData := LoadTestData('Signatures/GetSignaturesForAddressBeforeResponse.json');
  requestData  := LoadTestData('Signatures/GetSignaturesForAddressBeforeConfirmedRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetSignaturesForAddress(
    'Vote111111111111111111111111111111111111111',
    1,
    'Vote111111111111111111111111111111111111111', '',
    TCommitment.Confirmed
  );

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);
  AssertEquals(1, result.Result.Count);
  AssertFalse(result.Result[0].BlockTime.HasValue);
  AssertEquals(114, result.Result[0].Slot);
  AssertEquals('5h6xBEauJ3PK6SWCZ1PGjBvj8vDdWG3KpwATGy1ARAXFSDwt8GFXM7W5Ncn16wmqokgpiKRLuS83KUxyZyv2sUYv', result.Result[0].Signature);
  AssertEquals('', result.Result[0].Memo);
  AssertNull(result.Result[0].Error);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientSignaturesTests.TestGetSignatureStatuses;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  sigs: TArray<string>;
  result: IRequestResult<TResponseValue<TObjectList<TSignatureStatusInfo>>>;
begin
  responseData := LoadTestData('Signatures/GetSignatureStatusesResponse.json');
  requestData  := LoadTestData('Signatures/GetSignatureStatusesRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  sigs := TArray<string>.Create(
    '5VERv8NMvzbJMEkV8xnrLkEaWRtSz9CosKDYjCJjBRnbJLgp8uirBgmQpjKhoR4tjF3ZpRzrFmBV6UjKdiSZkQUW',
    '5j7s6NiJS3JAkvgkoc18WVAsiSaci2pxB2A6ueCJP4tprA2TFg9wSyTLeYouxPBJEMzJinENTkpA52YStRW5Dia7'
  );

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetSignatureStatuses(sigs);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);

  AssertEquals(82, result.Result.Context.Slot);
  AssertEquals(2, result.Result.Value.Count);
  AssertTrue(result.Result.Value[1] = nil);
  AssertEquals(72, result.Result.Value[0].Slot);
  AssertEquals(10, result.Result.Value[0].Confirmations.Value);
  AssertEquals('confirmed', result.Result.Value[0].ConfirmationStatus);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientSignaturesTests.TestGetSignatureStatusesWithHistory;
var
  responseData, requestData: string;
  mockRpcHttpClient: TMockRpcHttpClient;
  rpcHttpClient: IHttpApiClient;
  rpcClient: IRpcClient;
  sigs: TArray<string>;
  result: IRequestResult<TResponseValue<TObjectList<TSignatureStatusInfo>>>;
begin
  responseData := LoadTestData('Signatures/GetSignatureStatusesWithHistoryResponse.json');
  requestData  := LoadTestData('Signatures/GetSignatureStatusesWithHistoryRequest.json');

  mockRpcHttpClient := SetupTest(responseData, 200);
  rpcHttpClient := mockRpcHttpClient;

  sigs := TArray<string>.Create(
    '5VERv8NMvzbJMEkV8xnrLkEaWRtSz9CosKDYjCJjBRnbJLgp8uirBgmQpjKhoR4tjF3ZpRzrFmBV6UjKdiSZkQUW',
    '5j7s6NiJS3JAkvgkoc18WVAsiSaci2pxB2A6ueCJP4tprA2TFg9wSyTLeYouxPBJEMzJinENTkpA52YStRW5Dia7'
  );

  rpcClient := TSolanaRpcClient.Create(TestnetUrl, rpcHttpClient);
  result := rpcClient.GetSignatureStatuses(sigs, True);

  AssertJsonMatch(requestData, mockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(result.Result);
  AssertTrue(result.WasSuccessful);

  AssertEquals(82, result.Result.Context.Slot);
  AssertEquals(2, result.Result.Value.Count);
  AssertTrue(result.Result.Value[1] = nil);
  AssertEquals(48, result.Result.Value[0].Slot);
  AssertFalse(result.Result.Value[0].Confirmations.HasValue);
  AssertEquals('finalized', result.Result.Value[0].ConfirmationStatus);

  FinishTest(mockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientSignaturesTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientSignaturesTests.Suite);
{$ENDIF}

end.
