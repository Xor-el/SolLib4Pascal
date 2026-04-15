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

{
  JSON Converter Round-Trip Tests

 Converters Tested:
    - TAccountDataConverter → via TAccountInfo.Data property
    - TJsonUInt64ClampNumberConverter → via TAccountInfoBase.RentEpoch property  
    - TNullableDoubleConverter → via TTokenBalance.UiAmount property
    - TNullableUInt64Converter → via TBlockInfo.BlockHeight property
    - TNullableInt64Converter → via TTransactionMetaSlotInfo.BlockTime property
    - TNullableIntegerConverter → via TJsonRpcBase.Id property (batch responses)
    - TJsonRpcRequestParamsConverter → via TJsonRpcRequest.Params property
    - TJsonRpcBatchRequestConverter → via TJsonRpcBatchRequest (class-level)
    - TJsonRpcBatchResponseConverter → via TJsonRpcBatchResponse (class-level)
    - TJsonRpcBatchResponseItemResultConverter → via TJsonRpcBatchResponseItem.Result
    - TRpcErrorResponseConverter → via TJsonRpcErrorResponse (class-level)
    - TTokenListItemExtensionsConverter → via TTokenListItem.Extensions property
    - TTokenAccountDataConverter → via TTokenAccountInfo.Data property
    - TTransactionErrorJsonConverter → via TSignatureStatusInfo.Error (class-level)
    - TTransactionMetaInfoTransactionConverter → via TTransactionMetaSlotInfo.Transaction
    - TTransactionMetaInfoVersionConverter → via TTransactionMetaSlotInfo.Version
    - TBlockProductionInfoMapConverter → via TBlockProductionInfo.ByIdentity property
    - TEncodingConverter → directly tested
    - TJsonStringEnumConverter → directly tested
}

unit JsonConverterTests;

interface

uses
  SysUtils,
  Rtti,
  Generics.Collections,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpRpcEnum,
  SlpRpcModel,
  SlpRpcMessage,
  SlpTokenModel,
  SolLibTestCase,
  TestResourceLoader,
  TestUtils;

type
  TJsonConverterTests = class(TSolLibTestCase)
  private
    FResCategory: string;
    function ResPath(const ASubPath: string): string;
    function LoadTestData(const ASubPath: string): string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    { TAccountDataConverter - via TAccountInfo.Data }
    procedure Test_AccountInfo_DataConverter_Base64_Roundtrip;
    procedure Test_AccountInfo_DataConverter_JsonParsed_RoundTrip;
    
    { TJsonUInt64ClampNumberConverter - via TAccountInfoBase.RentEpoch }
    procedure Test_AccountInfo_RentEpochClamp_Roundtrip;
    
    { TNullableDoubleConverter - via TTokenBalance.UiAmount }
    procedure Test_TokenBalance_NullableUiAmount_WithValue;
    procedure Test_TokenBalance_NullableUiAmount_Null;
    
    { TNullableUInt64Converter - via TBlockInfo.BlockHeight }
    procedure Test_BlockInfo_NullableBlockHeight_WithValue;
    procedure Test_BlockInfo_NullableBlockHeight_Null;
    
    { TJsonRpcRequestParamsConverter - via TJsonRpcRequest.Params }
    procedure Test_RpcRequest_ParamsConverter_WithValues;
    procedure Test_RpcRequest_ParamsConverter_EmptyParams;
    
    { TJsonRpcBatchRequestConverter - via TJsonRpcBatchRequest }
    procedure Test_RpcBatchRequest_MultipleRequests_Roundtrip;
    
    { TJsonRpcBatchResponseConverter - via TJsonRpcBatchResponse }
    procedure Test_RpcBatchResponse_MultipleResponses_Roundtrip;
    
    { TRpcErrorResponseConverter - via TJsonRpcErrorResponse }
    procedure Test_RpcErrorResponse_WithMessage_Roundtrip;
    procedure Test_RpcErrorResponse_WithErrorObject_Roundtrip;
    
    { TTokenListItemExtensionsConverter - via TTokenListItem.Extensions }
    procedure Test_TokenListItem_ExtensionsConverter_Roundtrip;
    
    { TEpochInfo - complete model test }
    procedure Test_EpochInfo_CompleteModel_Roundtrip;
    procedure Test_RpcResponse_EpochInfo_Roundtrip;
    
    { TNullableInt64Converter - via TTransactionMetaSlotInfo.BlockTime }
    procedure Test_TransactionMetaSlotInfo_NullableBlockTime_WithValue;
    procedure Test_TransactionMetaSlotInfo_NullableBlockTime_Null;
    
    { TTransactionErrorJsonConverter - via TSignatureStatusInfo.Error }
    procedure Test_SignatureStatusInfo_TransactionError_WithError;
    procedure Test_SignatureStatusInfo_TransactionError_NoError;

    { TTokenAccountDataConverter - via TTokenAccountInfo.Data }
    procedure Test_TokenAccountInfo_DataConverter_JsonParsed_Roundtrip;

    { TBlockProductionInfoMapConverter - via TBlockProductionInfo.ByIdentity }
    procedure Test_BlockProductionInfo_MapConverter_Roundtrip;
    
    { TJsonStringEnumConverter - direct test with CamelCase }
    procedure Test_JsonStringEnumConverter_Commitment_CamelCase;
    procedure Test_JsonStringEnumConverter_Commitment_Roundtrip;
    
    { TEncodingConverter - direct test }
    procedure Test_EncodingConverter_Base64_Roundtrip;
    procedure Test_EncodingConverter_JsonParsed_CamelCase;
    procedure Test_EncodingConverter_Base64Zstd_Roundtrip;
  end;

implementation

{ TJsonConverterTests }

procedure TJsonConverterTests.SetUp;
begin
  inherited;
  FResCategory := 'JsonConverter';
end;

procedure TJsonConverterTests.TearDown;
begin
  FResCategory := '';
  inherited;
end;

function TJsonConverterTests.ResPath(const ASubPath: string): string;
begin
  Result := FResCategory + '/' + ASubPath;
end;

function TJsonConverterTests.LoadTestData(const ASubPath: string): string;
begin
  Result := TTestResourceLoader.LoadTestData(ResPath(ASubPath));
end;

{ TAccountDataConverter Tests - via TAccountInfo.Data }

procedure TJsonConverterTests.Test_AccountInfo_DataConverter_Base64_Roundtrip;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TAccountInfo;
begin
  LJsonInput := LoadTestData('AccountInfo_Data_Base64.json');
  LExpectedJson := LJsonInput; // Should match after roundtrip
  
  LModel := TTestUtils.Deserialize<TAccountInfo>(LJsonInput);
  try
    // Verify data was deserialized (TAccountDataConverter used)
    AssertTrue(LModel.Data <> nil, 'Data should be deserialized');
    AssertEquals(2, Length(LModel.Data), 'Data should have 2 elements');
    AssertEquals('base64', LModel.Data[1], 'Second element should be encoding');
    
    // Roundtrip serialize
    LJsonOutput := TTestUtils.Serialize<TAccountInfo>(LModel);
    
    // Validate JSON structure matches
    AssertJsonMatch(LExpectedJson, LJsonOutput, 'Roundtrip JSON should match original');
    
    // Verify fields
    AssertEquals(UInt64(5478840), LModel.Lamports);
    AssertEquals('11111111111111111111111111111111', LModel.Owner);
  finally
    LModel.Free;
  end;
end;

procedure TJsonConverterTests.Test_AccountInfo_DataConverter_JsonParsed_RoundTrip;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel, LModel2: TAccountInfo;
begin
  LJsonInput := LoadTestData('AccountInfo_Data_JsonParsed.json');
  LExpectedJson := LJsonInput;
   
  LModel := TTestUtils.Deserialize<TAccountInfo>(LJsonInput);
  try
    LJsonOutput := TTestUtils.Serialize<TAccountInfo>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
    
    // Second roundtrip
    LModel2 := TTestUtils.Deserialize<TAccountInfo>(LJsonOutput);
    try
      AssertEquals(LModel.Lamports, LModel2.Lamports);
      AssertEquals(LModel.Owner, LModel2.Owner);
    finally
      LModel2.Free;
    end;
  finally
    LModel.Free;
  end;
end;

{ TJsonUInt64ClampNumberConverter Tests - via TAccountInfoBase.RentEpoch }

procedure TJsonConverterTests.Test_AccountInfo_RentEpochClamp_Roundtrip;
var
  LJsonInput, LJsonOutput: string;
  LModel: TAccountInfo;
begin
  LJsonInput := LoadTestData('AccountInfo_Data_Base64.json');
  
  LModel := TTestUtils.Deserialize<TAccountInfo>(LJsonInput);
  try
    // RentEpoch uses TJsonUInt64ClampNumberConverter
    AssertEquals(UInt64(195), LModel.RentEpoch, 'RentEpoch should be clamped correctly');
    
    LJsonOutput := TTestUtils.Serialize<TAccountInfo>(LModel);
    AssertJsonMatch(LJsonInput, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

{ TNullableDoubleConverter Tests - via TTokenBalance.UiAmount }

procedure TJsonConverterTests.Test_TokenBalance_NullableUiAmount_WithValue;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TTokenBalance;
begin
  LJsonInput := LoadTestData('TokenBalance_WithUiAmount.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TTokenBalance>(LJsonInput);
  try
    // UiAmount uses TNullableDoubleConverter
    AssertTrue(LModel.UiAmount.HasValue, 'UiAmount should have value');
    AssertEquals(1.0, LModel.UiAmount.Value);
    
    LJsonOutput := TTestUtils.Serialize<TTokenBalance>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

procedure TJsonConverterTests.Test_TokenBalance_NullableUiAmount_Null;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TTokenBalance;
begin
  LJsonInput := LoadTestData('TokenBalance_NullUiAmount.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TTokenBalance>(LJsonInput);
  try
    // UiAmount should be None/null
    AssertFalse(LModel.UiAmount.HasValue, 'UiAmount should be None');
    
    LJsonOutput := TTestUtils.Serialize<TTokenBalance>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

{ TNullableUInt64Converter Tests - via TBlockInfo.BlockHeight }

procedure TJsonConverterTests.Test_BlockInfo_NullableBlockHeight_WithValue;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TBlockInfo;
begin
  LJsonInput := LoadTestData('BlockInfo_Full.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TBlockInfo>(LJsonInput);
  try
    // BlockHeight uses TNullableUInt64Converter
    AssertTrue(LModel.BlockHeight.HasValue, 'BlockHeight should have value');
    AssertEquals(UInt64(166500), LModel.BlockHeight.Value);
    
    LJsonOutput := TTestUtils.Serialize<TBlockInfo>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

procedure TJsonConverterTests.Test_BlockInfo_NullableBlockHeight_Null;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TBlockInfo;
begin
  LJsonInput := LoadTestData('BlockInfo_NullBlockHeight.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TBlockInfo>(LJsonInput);
  try
    AssertFalse(LModel.BlockHeight.HasValue, 'BlockHeight should be None');
    
    LJsonOutput := TTestUtils.Serialize<TBlockInfo>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

{ TJsonRpcRequestParamsConverter Tests - via TJsonRpcRequest.Params }

procedure TJsonConverterTests.Test_RpcRequest_ParamsConverter_WithValues;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TJsonRpcRequest;
begin
  LJsonInput := LoadTestData('RpcRequest_WithParams.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TJsonRpcRequest>(LJsonInput);
  try
    // Params uses TJsonRpcRequestParamsConverter
    AssertNotNull(LModel.Params, 'Params should exist');
    AssertEquals(2, LModel.Params.Count, 'Should have 2 params');
    
    LJsonOutput := TTestUtils.Serialize<TJsonRpcRequest>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

procedure TJsonConverterTests.Test_RpcRequest_ParamsConverter_EmptyParams;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TJsonRpcRequest;
begin
  LJsonInput := LoadTestData('RpcRequest_EmptyParams.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TJsonRpcRequest>(LJsonInput);
  try
    AssertNotNull(LModel.Params);
    AssertEquals(0, LModel.Params.Count, 'Params should be empty');
    
    LJsonOutput := TTestUtils.Serialize<TJsonRpcRequest>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

{ TJsonRpcBatchRequestConverter Tests }

procedure TJsonConverterTests.Test_RpcBatchRequest_MultipleRequests_Roundtrip;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TJsonRpcBatchRequest;
begin
  LJsonInput := LoadTestData('RpcBatchRequest.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TJsonRpcBatchRequest>(LJsonInput);
  try
    AssertEquals(2, LModel.Count, 'Should have 2 requests');
    
    LJsonOutput := TTestUtils.Serialize<TJsonRpcBatchRequest>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

{ TJsonRpcBatchResponseConverter Tests }

procedure TJsonConverterTests.Test_RpcBatchResponse_MultipleResponses_Roundtrip;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TJsonRpcBatchResponse;
begin
  LJsonInput := LoadTestData('RpcBatchResponse.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TJsonRpcBatchResponse>(LJsonInput);
  try
    AssertEquals(2, LModel.Count, 'Should have 2 responses');
    
    // TJsonRpcBatchResponseItemResultConverter - verify Result field is deserialized
    AssertNotNull(LModel[0], 'First response should exist');
    AssertFalse(LModel[0].Result.IsEmpty, 'First response result should be deserialized');
    AssertEquals(5478840, LModel[0].Result.AsInteger, 'First result should be integer');
    
    AssertNotNull(LModel[1], 'Second response should exist');
    AssertFalse(LModel[1].Result.IsEmpty, 'Second response result should be deserialized');
    
    LJsonOutput := TTestUtils.Serialize<TJsonRpcBatchResponse>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

{ TRpcErrorResponseConverter Tests }

procedure TJsonConverterTests.Test_RpcErrorResponse_WithMessage_Roundtrip;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TJsonRpcErrorResponse;
begin
  LJsonInput := LoadTestData('RpcError_WithMessage.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TJsonRpcErrorResponse>(LJsonInput);
  try
    AssertEquals('Invalid params', LModel.ErrorMessage);
    AssertTrue(LModel.Id.HasValue);
    
    LJsonOutput := TTestUtils.Serialize<TJsonRpcErrorResponse>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

procedure TJsonConverterTests.Test_RpcErrorResponse_WithErrorObject_Roundtrip;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TJsonRpcErrorResponse;
begin
  LJsonInput := LoadTestData('RpcError_WithErrorObject.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TJsonRpcErrorResponse>(LJsonInput);
  try
    AssertNotNull(LModel.Error);
    AssertEquals(-32600, LModel.Error.Code);
    AssertNull(LModel.Error.Data);
    
    LJsonOutput := TTestUtils.Serialize<TJsonRpcErrorResponse>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

{ TTokenListItemExtensionsConverter Tests - via TTokenListItem.Extensions }

procedure TJsonConverterTests.Test_TokenListItem_ExtensionsConverter_Roundtrip;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TTokenListItem;
begin
  LJsonInput := LoadTestData('TokenListItem_WithExtensions.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TTokenListItem>(LJsonInput);
  try
    // Extensions uses TTokenListItemExtensionsConverter
    AssertNotNull(LModel.Extensions, 'Extensions should exist');
    AssertEquals(3, LModel.Extensions.Count);
    AssertEquals('https://solana.com', LModel.Extensions['website'].AsString);
    
    LJsonOutput := TTestUtils.Serialize<TTokenListItem>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

{ TEpochInfo Tests }

procedure TJsonConverterTests.Test_EpochInfo_CompleteModel_Roundtrip;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TEpochInfo;
begin
  LJsonInput := LoadTestData('EpochInfo_Full.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TEpochInfo>(LJsonInput);
  try
    AssertEquals(UInt64(166598), LModel.AbsoluteSlot);
    AssertEquals(UInt64(27), LModel.Epoch);
    
    LJsonOutput := TTestUtils.Serialize<TEpochInfo>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

procedure TJsonConverterTests.Test_RpcResponse_EpochInfo_Roundtrip;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TJsonRpcResponse<TEpochInfo>;
begin
  LJsonInput := LoadTestData('RpcResponse_EpochInfo.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TJsonRpcResponse<TEpochInfo>>(LJsonInput);
  try
    AssertNotNull(LModel.Result);
    AssertEquals(UInt64(166598), LModel.Result.AbsoluteSlot);
    
    LJsonOutput := TTestUtils.Serialize<TJsonRpcResponse<TEpochInfo>>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

{ TNullableInt64Converter Tests - via TTransactionMetaSlotInfo.BlockTime }

procedure TJsonConverterTests.Test_TransactionMetaSlotInfo_NullableBlockTime_WithValue;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TTransactionMetaSlotInfo;
begin
  LJsonInput := LoadTestData('TransactionMetaSlotInfo_WithBlockTime.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TTransactionMetaSlotInfo>(LJsonInput);
  try
    // BlockTime uses TNullableInt64Converter
    AssertTrue(LModel.BlockTime.HasValue, 'BlockTime should have value');
    AssertEquals(Int64(1234567890), LModel.BlockTime.Value);
    
    // Transaction uses TTransactionMetaInfoTransactionConverter
    AssertFalse(LModel.Transaction.IsEmpty, 'Transaction should be deserialized');
    
    // Version uses TTransactionMetaInfoVersionConverter
    AssertFalse(LModel.Version.IsEmpty, 'Version should be deserialized');
    AssertEquals('legacy', LModel.Version.AsString, 'Version should be "legacy"');
    
    // Meta should be populated
    AssertNotNull(LModel.Meta, 'Meta should exist');
    AssertEquals(UInt64(5000), LModel.Meta.Fee, 'Fee should match');
    
    LJsonOutput := TTestUtils.Serialize<TTransactionMetaSlotInfo>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

procedure TJsonConverterTests.Test_TransactionMetaSlotInfo_NullableBlockTime_Null;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TTransactionMetaSlotInfo;
begin
  LJsonInput := LoadTestData('TransactionMetaSlotInfo_NullBlockTime.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TTransactionMetaSlotInfo>(LJsonInput);
  try
    AssertFalse(LModel.BlockTime.HasValue, 'BlockTime should be None');
    
    LJsonOutput := TTestUtils.Serialize<TTransactionMetaSlotInfo>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

{ TTransactionErrorJsonConverter Tests - via TSignatureStatusInfo.Error }

procedure TJsonConverterTests.Test_SignatureStatusInfo_TransactionError_WithError;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TSignatureStatusInfo;
begin
  LJsonInput := LoadTestData('SignatureStatusInfo_WithError.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TSignatureStatusInfo>(LJsonInput);
  try
    // Error uses TTransactionErrorJsonConverter
    AssertNotNull(LModel.Error, 'Error should exist');
    
    LJsonOutput := TTestUtils.Serialize<TSignatureStatusInfo>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

procedure TJsonConverterTests.Test_SignatureStatusInfo_TransactionError_NoError;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TSignatureStatusInfo;
begin
  LJsonInput := LoadTestData('SignatureStatusInfo_NoError.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TSignatureStatusInfo>(LJsonInput);
  try
    AssertNull(LModel.Error, 'Error should be null');
    
    LJsonOutput := TTestUtils.Serialize<TSignatureStatusInfo>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

{ TTokenAccountDataConverter Tests - via TTokenAccountInfo.Data }

procedure TJsonConverterTests.Test_TokenAccountInfo_DataConverter_JsonParsed_Roundtrip;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TTokenAccountInfo;
begin
  LJsonInput := LoadTestData('TokenAccountInfo_ParsedData.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TTokenAccountInfo>(LJsonInput);
  try
    // Data uses TTokenAccountDataConverter
    AssertFalse(LModel.Data.IsEmpty, 'Data should be deserialized');
    
    LJsonOutput := TTestUtils.Serialize<TTokenAccountInfo>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
    
    // Verify fields
    AssertEquals(UInt64(2039280), LModel.Lamports);
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LModel.Owner);
  finally
    LModel.Free;
  end;
end;

{ TBlockProductionInfoMapConverter Tests - via TBlockProductionInfo.ByIdentity }

procedure TJsonConverterTests.Test_BlockProductionInfo_MapConverter_Roundtrip;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LModel: TBlockProductionInfo;
begin
  LJsonInput := LoadTestData('BlockProductionInfo_ByIdentity.json');
  LExpectedJson := LJsonInput;
  
  LModel := TTestUtils.Deserialize<TBlockProductionInfo>(LJsonInput);
  try
    // ByIdentity uses TBlockProductionInfoMapConverter
    AssertNotNull(LModel.ByIdentity, 'ByIdentity should exist');
    AssertEquals(2, LModel.ByIdentity.Count, 'Should have 2 identities');
    
    LJsonOutput := TTestUtils.Serialize<TBlockProductionInfo>(LModel);
    AssertJsonMatch(LExpectedJson, LJsonOutput);
  finally
    LModel.Free;
  end;
end;

{ TJsonStringEnumConverter Tests - Direct }

procedure TJsonConverterTests.Test_JsonStringEnumConverter_Commitment_CamelCase;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LValue: TCommitment;
begin
  LJsonInput := LoadTestData('Enum_Commitment_Finalized.json');
  LExpectedJson := '"finalized"'; // Should be lowercase camelCase
  
  LValue := TTestUtils.Deserialize<TCommitment>(LJsonInput);
  AssertEquals(Ord(TCommitment.Finalized), Ord(LValue), 'Should deserialize to Finalized');
  
  LJsonOutput := TTestUtils.Serialize<TCommitment>(LValue);
  AssertJsonMatch(LExpectedJson, LJsonOutput, 'Should serialize to camelCase');
end;

procedure TJsonConverterTests.Test_JsonStringEnumConverter_Commitment_Roundtrip;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LValue1, LValue2: TCommitment;
begin
  LJsonInput := LoadTestData('Enum_Commitment_Confirmed.json');
  LExpectedJson := '"confirmed"';
  
  LValue1 := TTestUtils.Deserialize<TCommitment>(LJsonInput);
  AssertEquals(Ord(TCommitment.Confirmed), Ord(LValue1));
  
  LJsonOutput := TTestUtils.Serialize<TCommitment>(LValue1);
  AssertJsonMatch(LExpectedJson, LJsonOutput);
  
  // Second roundtrip
  LValue2 := TTestUtils.Deserialize<TCommitment>(LJsonOutput);
  AssertEquals(Ord(LValue1), Ord(LValue2), 'Roundtrip should preserve value');
end;

{ TEncodingConverter Tests - Direct }

procedure TJsonConverterTests.Test_EncodingConverter_Base64_Roundtrip;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LValue: TBinaryEncoding;
begin
  LJsonInput := LoadTestData('Encoding_Base64.json');
  LExpectedJson := '"base64"';
  
  LValue := TTestUtils.Deserialize<TBinaryEncoding>(LJsonInput);
  AssertEquals(Ord(TBinaryEncoding.Base64), Ord(LValue));
  
  LJsonOutput := TTestUtils.Serialize<TBinaryEncoding>(LValue);
  AssertJsonMatch(LExpectedJson, LJsonOutput);
end;

procedure TJsonConverterTests.Test_EncodingConverter_JsonParsed_CamelCase;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LValue: TBinaryEncoding;
begin
  LJsonInput := LoadTestData('Encoding_JsonParsed.json');
  LExpectedJson := '"jsonParsed"'; // CamelCase conversion
  
  LValue := TTestUtils.Deserialize<TBinaryEncoding>(LJsonInput);
  AssertEquals(Ord(TBinaryEncoding.JsonParsed), Ord(LValue));
  
  LJsonOutput := TTestUtils.Serialize<TBinaryEncoding>(LValue);
  AssertJsonMatch(LExpectedJson, LJsonOutput, 'Should convert JsonParsed to camelCase');
end;

procedure TJsonConverterTests.Test_EncodingConverter_Base64Zstd_Roundtrip;
var
  LJsonInput, LJsonOutput, LExpectedJson: string;
  LValue: TBinaryEncoding;
begin
  LJsonInput := LoadTestData('Encoding_Base64Zstd.json');
  LExpectedJson := '"base64+zstd"'; // Special character handling
  
  LValue := TTestUtils.Deserialize<TBinaryEncoding>(LJsonInput);
  AssertEquals(Ord(TBinaryEncoding.Base64Zstd), Ord(LValue));
  
  LJsonOutput := TTestUtils.Serialize<TBinaryEncoding>(LValue);
  AssertJsonMatch(LExpectedJson, LJsonOutput, 'Should handle Base64Zstd conversion');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TJsonConverterTests);
{$ELSE}
  RegisterTest(TJsonConverterTests.Suite);
{$ENDIF}

end.
