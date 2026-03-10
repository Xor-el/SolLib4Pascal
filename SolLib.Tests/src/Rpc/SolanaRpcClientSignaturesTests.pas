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
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TObjectList<TSignatureStatusInfo>>;
begin
  LResponseData := LoadTestData('Signatures/GetSignaturesForAddressResponse.json');
  LRequestData := LoadTestData('Signatures/GetSignaturesForAddressRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetSignaturesForAddress('4Rf9mGD7FeYknun5JczX5nGLTfQuS1GRjNVfkEMKE92b', 3);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result, 'Result should not be nil');
  AssertTrue(LResult.WasSuccessful, 'Should be successful');

  AssertEquals(3, LResult.Result.Count);
  AssertEquals(1616245823, LResult.Result[0].BlockTime.Value);
  AssertEquals(68710495,   LResult.Result[0].Slot);
  AssertEquals('5Jofwx5JcPT1dMsgo6DkyT6x61X5chS9K7hM7huGKAnUq8xxHwGKuDnnZmPGoapWVZcN4cPvQtGNCicnWZfPHowr', LResult.Result[0].Signature);
  AssertEquals('', LResult.Result[0].Memo);
  AssertNull(LResult.Result[0].Error);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientSignaturesTests.TestGetSignaturesForAddress_InvalidCommitment;
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
      LRpcClient.GetSignaturesForAddress(
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
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TObjectList<TSignatureStatusInfo>>;
begin
  LResponseData := LoadTestData('Signatures/GetSignaturesForAddressUntilResponse.json');
  LRequestData := LoadTestData('Signatures/GetSignaturesForAddressUntilRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetSignaturesForAddress(
    'Vote111111111111111111111111111111111111111',
    1,
    '',
    'Vote111111111111111111111111111111111111111'
  );

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);
  AssertEquals(1, LResult.Result.Count);
  AssertFalse(LResult.Result[0].BlockTime.HasValue);
  AssertEquals(114, LResult.Result[0].Slot);
  AssertEquals('5h6xBEauJ3PK6SWCZ1PGjBvj8vDdWG3KpwATGy1ARAXFSDwt8GFXM7W5Ncn16wmqokgpiKRLuS83KUxyZyv2sUYv', LResult.Result[0].Signature);
  AssertEquals('', LResult.Result[0].Memo);
  AssertNull(LResult.Result[0].Error);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientSignaturesTests.TestGetSignaturesForAddressBefore;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TObjectList<TSignatureStatusInfo>>;
begin
  LResponseData := LoadTestData('Signatures/GetSignaturesForAddressBeforeResponse.json');
  LRequestData := LoadTestData('Signatures/GetSignaturesForAddressBeforeRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetSignaturesForAddress(
    'Vote111111111111111111111111111111111111111',
    1, 'Vote111111111111111111111111111111111111111', ''
  );

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);
  AssertEquals(1, LResult.Result.Count);
  AssertFalse(LResult.Result[0].BlockTime.HasValue);
  AssertEquals(114, LResult.Result[0].Slot);
  AssertEquals('5h6xBEauJ3PK6SWCZ1PGjBvj8vDdWG3KpwATGy1ARAXFSDwt8GFXM7W5Ncn16wmqokgpiKRLuS83KUxyZyv2sUYv', LResult.Result[0].Signature);
  AssertEquals('', LResult.Result[0].Memo);
  AssertNull(LResult.Result[0].Error);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientSignaturesTests.TestGetSignaturesForAddressBeforeConfirmed;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LResult: IRequestResult<TObjectList<TSignatureStatusInfo>>;
begin
  LResponseData := LoadTestData('Signatures/GetSignaturesForAddressBeforeResponse.json');
  LRequestData := LoadTestData('Signatures/GetSignaturesForAddressBeforeConfirmedRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetSignaturesForAddress(
    'Vote111111111111111111111111111111111111111',
    1,
    'Vote111111111111111111111111111111111111111', '',
    TCommitment.Confirmed
  );

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);
  AssertEquals(1, LResult.Result.Count);
  AssertFalse(LResult.Result[0].BlockTime.HasValue);
  AssertEquals(114, LResult.Result[0].Slot);
  AssertEquals('5h6xBEauJ3PK6SWCZ1PGjBvj8vDdWG3KpwATGy1ARAXFSDwt8GFXM7W5Ncn16wmqokgpiKRLuS83KUxyZyv2sUYv', LResult.Result[0].Signature);
  AssertEquals('', LResult.Result[0].Memo);
  AssertNull(LResult.Result[0].Error);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientSignaturesTests.TestGetSignatureStatuses;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LSigs: TArray<string>;
  LResult: IRequestResult<TResponseValue<TObjectList<TSignatureStatusInfo>>>;
begin
  LResponseData := LoadTestData('Signatures/GetSignatureStatusesResponse.json');
  LRequestData := LoadTestData('Signatures/GetSignatureStatusesRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LSigs := TArray<string>.Create(
    '5VERv8NMvzbJMEkV8xnrLkEaWRtSz9CosKDYjCJjBRnbJLgp8uirBgmQpjKhoR4tjF3ZpRzrFmBV6UjKdiSZkQUW',
    '5j7s6NiJS3JAkvgkoc18WVAsiSaci2pxB2A6ueCJP4tprA2TFg9wSyTLeYouxPBJEMzJinENTkpA52YStRW5Dia7'
  );

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetSignatureStatuses(LSigs);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(82, LResult.Result.Context.Slot);
  AssertEquals(2, LResult.Result.Value.Count);
  AssertTrue(LResult.Result.Value[1] = nil);
  AssertEquals(72, LResult.Result.Value[0].Slot);
  AssertEquals(10, LResult.Result.Value[0].Confirmations.Value);
  AssertEquals('confirmed', LResult.Result.Value[0].ConfirmationStatus);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

procedure TSolanaRpcClientSignaturesTests.TestGetSignatureStatusesWithHistory;
var
  LResponseData, LRequestData: string;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
  LRpcClient: IRpcClient;
  LSigs: TArray<string>;
  LResult: IRequestResult<TResponseValue<TObjectList<TSignatureStatusInfo>>>;
begin
  LResponseData := LoadTestData('Signatures/GetSignatureStatusesWithHistoryResponse.json');
  LRequestData := LoadTestData('Signatures/GetSignatureStatusesWithHistoryRequest.json');

  LMockRpcHttpClient := SetupTest(LResponseData, 200);
  LRpcHttpClient := LMockRpcHttpClient;

  LSigs := TArray<string>.Create(
    '5VERv8NMvzbJMEkV8xnrLkEaWRtSz9CosKDYjCJjBRnbJLgp8uirBgmQpjKhoR4tjF3ZpRzrFmBV6UjKdiSZkQUW',
    '5j7s6NiJS3JAkvgkoc18WVAsiSaci2pxB2A6ueCJP4tprA2TFg9wSyTLeYouxPBJEMzJinENTkpA52YStRW5Dia7'
  );

  LRpcClient := TSolanaRpcClient.Create(TestnetUrl, LRpcHttpClient);
  LResult := LRpcClient.GetSignatureStatuses(LSigs, True);

  AssertJsonMatch(LRequestData, LMockRpcHttpClient.LastJson, 'Sent JSON mismatch');
  AssertNotNull(LResult.Result);
  AssertTrue(LResult.WasSuccessful);

  AssertEquals(82, LResult.Result.Context.Slot);
  AssertEquals(2, LResult.Result.Value.Count);
  AssertTrue(LResult.Result.Value[1] = nil);
  AssertEquals(48, LResult.Result.Value[0].Slot);
  AssertFalse(LResult.Result.Value[0].Confirmations.HasValue);
  AssertEquals('finalized', LResult.Result.Value[0].ConfirmationStatus);

  FinishTest(LMockRpcHttpClient, TestnetUrl);
end;

initialization
{$IFDEF FPC}
  RegisterTest(TSolanaRpcClientSignaturesTests);
{$ELSE}
  RegisterTest(TSolanaRpcClientSignaturesTests.Suite);
{$ENDIF}

end.
