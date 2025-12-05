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
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
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
  TestUtils;

type
  TJsonConverterTests = class(TSolLibTestCase)
  private
    FResDir: string;
    function LoadJson(const AFileName: string): string;
  protected
    procedure SetUp; override;

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
  FResDir := TTestUtils.GetSourceDirWithSuffix('src\Resources\JsonConverter', '');
end;

function TJsonConverterTests.LoadJson(const AFileName: string): string;
begin
  Result := TTestUtils.ReadAllText(TTestUtils.CombineAll([FResDir, AFileName]));
end;

{ TAccountDataConverter Tests - via TAccountInfo.Data }

procedure TJsonConverterTests.Test_AccountInfo_DataConverter_Base64_Roundtrip;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TAccountInfo;
begin
  JsonInput := LoadJson('AccountInfo_Data_Base64.json');
  ExpectedJson := JsonInput; // Should match after roundtrip
  
  Model := TTestUtils.Deserialize<TAccountInfo>(JsonInput);
  try
    // Verify data was deserialized (TAccountDataConverter used)
    AssertTrue(Model.Data <> nil, 'Data should be deserialized');
    AssertEquals(2, Length(Model.Data), 'Data should have 2 elements');
    AssertEquals('base64', Model.Data[1], 'Second element should be encoding');
    
    // Roundtrip serialize
    JsonOutput := TTestUtils.Serialize<TAccountInfo>(Model);
    
    // Validate JSON structure matches
    AssertJsonMatch(ExpectedJson, JsonOutput, 'Roundtrip JSON should match original');
    
    // Verify fields
    AssertEquals(UInt64(5478840), Model.Lamports);
    AssertEquals('11111111111111111111111111111111', Model.Owner);
  finally
    Model.Free;
  end;
end;

procedure TJsonConverterTests.Test_AccountInfo_DataConverter_JsonParsed_RoundTrip;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model, Model2: TAccountInfo;
begin
  JsonInput := LoadJson('AccountInfo_Data_JsonParsed.json');
  ExpectedJson := JsonInput;
   
  Model := TTestUtils.Deserialize<TAccountInfo>(JsonInput);
  try
    JsonOutput := TTestUtils.Serialize<TAccountInfo>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
    
    // Second roundtrip
    Model2 := TTestUtils.Deserialize<TAccountInfo>(JsonOutput);
    try
      AssertEquals(Model.Lamports, Model2.Lamports);
      AssertEquals(Model.Owner, Model2.Owner);
    finally
      Model2.Free;
    end;
  finally
    Model.Free;
  end;
end;

{ TJsonUInt64ClampNumberConverter Tests - via TAccountInfoBase.RentEpoch }

procedure TJsonConverterTests.Test_AccountInfo_RentEpochClamp_Roundtrip;
var
  JsonInput, JsonOutput: string;
  Model: TAccountInfo;
begin
  JsonInput := LoadJson('AccountInfo_Data_Base64.json');
  
  Model := TTestUtils.Deserialize<TAccountInfo>(JsonInput);
  try
    // RentEpoch uses TJsonUInt64ClampNumberConverter
    AssertEquals(UInt64(195), Model.RentEpoch, 'RentEpoch should be clamped correctly');
    
    JsonOutput := TTestUtils.Serialize<TAccountInfo>(Model);
    AssertJsonMatch(JsonInput, JsonOutput);
  finally
    Model.Free;
  end;
end;

{ TNullableDoubleConverter Tests - via TTokenBalance.UiAmount }

procedure TJsonConverterTests.Test_TokenBalance_NullableUiAmount_WithValue;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TTokenBalance;
begin
  JsonInput := LoadJson('TokenBalance_WithUiAmount.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TTokenBalance>(JsonInput);
  try
    // UiAmount uses TNullableDoubleConverter
    AssertTrue(Model.UiAmount.HasValue, 'UiAmount should have value');
    AssertEquals(1.0, Model.UiAmount.Value);
    
    JsonOutput := TTestUtils.Serialize<TTokenBalance>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

procedure TJsonConverterTests.Test_TokenBalance_NullableUiAmount_Null;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TTokenBalance;
begin
  JsonInput := LoadJson('TokenBalance_NullUiAmount.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TTokenBalance>(JsonInput);
  try
    // UiAmount should be None/null
    AssertFalse(Model.UiAmount.HasValue, 'UiAmount should be None');
    
    JsonOutput := TTestUtils.Serialize<TTokenBalance>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

{ TNullableUInt64Converter Tests - via TBlockInfo.BlockHeight }

procedure TJsonConverterTests.Test_BlockInfo_NullableBlockHeight_WithValue;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TBlockInfo;
begin
  JsonInput := LoadJson('BlockInfo_Full.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TBlockInfo>(JsonInput);
  try
    // BlockHeight uses TNullableUInt64Converter
    AssertTrue(Model.BlockHeight.HasValue, 'BlockHeight should have value');
    AssertEquals(UInt64(166500), Model.BlockHeight.Value);
    
    JsonOutput := TTestUtils.Serialize<TBlockInfo>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

procedure TJsonConverterTests.Test_BlockInfo_NullableBlockHeight_Null;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TBlockInfo;
begin
  JsonInput := LoadJson('BlockInfo_NullBlockHeight.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TBlockInfo>(JsonInput);
  try
    AssertFalse(Model.BlockHeight.HasValue, 'BlockHeight should be None');
    
    JsonOutput := TTestUtils.Serialize<TBlockInfo>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

{ TJsonRpcRequestParamsConverter Tests - via TJsonRpcRequest.Params }

procedure TJsonConverterTests.Test_RpcRequest_ParamsConverter_WithValues;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TJsonRpcRequest;
begin
  JsonInput := LoadJson('RpcRequest_WithParams.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TJsonRpcRequest>(JsonInput);
  try
    // Params uses TJsonRpcRequestParamsConverter
    AssertNotNull(Model.Params, 'Params should exist');
    AssertEquals(2, Model.Params.Count, 'Should have 2 params');
    
    JsonOutput := TTestUtils.Serialize<TJsonRpcRequest>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

procedure TJsonConverterTests.Test_RpcRequest_ParamsConverter_EmptyParams;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TJsonRpcRequest;
begin
  JsonInput := LoadJson('RpcRequest_EmptyParams.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TJsonRpcRequest>(JsonInput);
  try
    AssertNotNull(Model.Params);
    AssertEquals(0, Model.Params.Count, 'Params should be empty');
    
    JsonOutput := TTestUtils.Serialize<TJsonRpcRequest>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

{ TJsonRpcBatchRequestConverter Tests }

procedure TJsonConverterTests.Test_RpcBatchRequest_MultipleRequests_Roundtrip;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TJsonRpcBatchRequest;
begin
  JsonInput := LoadJson('RpcBatchRequest.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TJsonRpcBatchRequest>(JsonInput);
  try
    AssertEquals(2, Model.Count, 'Should have 2 requests');
    
    JsonOutput := TTestUtils.Serialize<TJsonRpcBatchRequest>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

{ TJsonRpcBatchResponseConverter Tests }

procedure TJsonConverterTests.Test_RpcBatchResponse_MultipleResponses_Roundtrip;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TJsonRpcBatchResponse;
begin
  JsonInput := LoadJson('RpcBatchResponse.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TJsonRpcBatchResponse>(JsonInput);
  try
    AssertEquals(2, Model.Count, 'Should have 2 responses');
    
    // TJsonRpcBatchResponseItemResultConverter - verify Result field is deserialized
    AssertNotNull(Model[0], 'First response should exist');
    AssertFalse(Model[0].Result.IsEmpty, 'First response result should be deserialized');
    AssertEquals(5478840, Model[0].Result.AsInteger, 'First result should be integer');
    
    AssertNotNull(Model[1], 'Second response should exist');
    AssertFalse(Model[1].Result.IsEmpty, 'Second response result should be deserialized');
    
    JsonOutput := TTestUtils.Serialize<TJsonRpcBatchResponse>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

{ TRpcErrorResponseConverter Tests }

procedure TJsonConverterTests.Test_RpcErrorResponse_WithMessage_Roundtrip;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TJsonRpcErrorResponse;
begin
  JsonInput := LoadJson('RpcError_WithMessage.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TJsonRpcErrorResponse>(JsonInput);
  try
    AssertEquals('Invalid params', Model.ErrorMessage);
    AssertTrue(Model.Id.HasValue);
    
    JsonOutput := TTestUtils.Serialize<TJsonRpcErrorResponse>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

procedure TJsonConverterTests.Test_RpcErrorResponse_WithErrorObject_Roundtrip;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TJsonRpcErrorResponse;
begin
  JsonInput := LoadJson('RpcError_WithErrorObject.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TJsonRpcErrorResponse>(JsonInput);
  try
    AssertNotNull(Model.Error);
    AssertEquals(-32600, Model.Error.Code);
    AssertNull(Model.Error.Data);
    
    JsonOutput := TTestUtils.Serialize<TJsonRpcErrorResponse>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

{ TTokenListItemExtensionsConverter Tests - via TTokenListItem.Extensions }

procedure TJsonConverterTests.Test_TokenListItem_ExtensionsConverter_Roundtrip;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TTokenListItem;
begin
  JsonInput := LoadJson('TokenListItem_WithExtensions.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TTokenListItem>(JsonInput);
  try
    // Extensions uses TTokenListItemExtensionsConverter
    AssertNotNull(Model.Extensions, 'Extensions should exist');
    AssertEquals(3, Model.Extensions.Count);
    AssertEquals('https://solana.com', Model.Extensions['website'].AsString);
    
    JsonOutput := TTestUtils.Serialize<TTokenListItem>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

{ TEpochInfo Tests }

procedure TJsonConverterTests.Test_EpochInfo_CompleteModel_Roundtrip;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TEpochInfo;
begin
  JsonInput := LoadJson('EpochInfo_Full.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TEpochInfo>(JsonInput);
  try
    AssertEquals(UInt64(166598), Model.AbsoluteSlot);
    AssertEquals(UInt64(27), Model.Epoch);
    
    JsonOutput := TTestUtils.Serialize<TEpochInfo>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

procedure TJsonConverterTests.Test_RpcResponse_EpochInfo_Roundtrip;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TJsonRpcResponse<TEpochInfo>;
begin
  JsonInput := LoadJson('RpcResponse_EpochInfo.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TJsonRpcResponse<TEpochInfo>>(JsonInput);
  try
    AssertNotNull(Model.Result);
    AssertEquals(UInt64(166598), Model.Result.AbsoluteSlot);
    
    JsonOutput := TTestUtils.Serialize<TJsonRpcResponse<TEpochInfo>>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

{ TNullableInt64Converter Tests - via TTransactionMetaSlotInfo.BlockTime }

procedure TJsonConverterTests.Test_TransactionMetaSlotInfo_NullableBlockTime_WithValue;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TTransactionMetaSlotInfo;
begin
  JsonInput := LoadJson('TransactionMetaSlotInfo_WithBlockTime.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TTransactionMetaSlotInfo>(JsonInput);
  try
    // BlockTime uses TNullableInt64Converter
    AssertTrue(Model.BlockTime.HasValue, 'BlockTime should have value');
    AssertEquals(Int64(1234567890), Model.BlockTime.Value);
    
    // Transaction uses TTransactionMetaInfoTransactionConverter
    AssertFalse(Model.Transaction.IsEmpty, 'Transaction should be deserialized');
    
    // Version uses TTransactionMetaInfoVersionConverter
    AssertFalse(Model.Version.IsEmpty, 'Version should be deserialized');
    AssertEquals('legacy', Model.Version.AsString, 'Version should be "legacy"');
    
    // Meta should be populated
    AssertNotNull(Model.Meta, 'Meta should exist');
    AssertEquals(UInt64(5000), Model.Meta.Fee, 'Fee should match');
    
    JsonOutput := TTestUtils.Serialize<TTransactionMetaSlotInfo>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

procedure TJsonConverterTests.Test_TransactionMetaSlotInfo_NullableBlockTime_Null;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TTransactionMetaSlotInfo;
begin
  JsonInput := LoadJson('TransactionMetaSlotInfo_NullBlockTime.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TTransactionMetaSlotInfo>(JsonInput);
  try
    AssertFalse(Model.BlockTime.HasValue, 'BlockTime should be None');
    
    JsonOutput := TTestUtils.Serialize<TTransactionMetaSlotInfo>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

{ TTransactionErrorJsonConverter Tests - via TSignatureStatusInfo.Error }

procedure TJsonConverterTests.Test_SignatureStatusInfo_TransactionError_WithError;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TSignatureStatusInfo;
begin
  JsonInput := LoadJson('SignatureStatusInfo_WithError.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TSignatureStatusInfo>(JsonInput);
  try
    // Error uses TTransactionErrorJsonConverter
    AssertNotNull(Model.Error, 'Error should exist');
    
    JsonOutput := TTestUtils.Serialize<TSignatureStatusInfo>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

procedure TJsonConverterTests.Test_SignatureStatusInfo_TransactionError_NoError;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TSignatureStatusInfo;
begin
  JsonInput := LoadJson('SignatureStatusInfo_NoError.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TSignatureStatusInfo>(JsonInput);
  try
    AssertNull(Model.Error, 'Error should be null');
    
    JsonOutput := TTestUtils.Serialize<TSignatureStatusInfo>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

{ TTokenAccountDataConverter Tests - via TTokenAccountInfo.Data }

procedure TJsonConverterTests.Test_TokenAccountInfo_DataConverter_JsonParsed_Roundtrip;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TTokenAccountInfo;
begin
  JsonInput := LoadJson('TokenAccountInfo_ParsedData.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TTokenAccountInfo>(JsonInput);
  try
    // Data uses TTokenAccountDataConverter
    AssertFalse(Model.Data.IsEmpty, 'Data should be deserialized');
    
    JsonOutput := TTestUtils.Serialize<TTokenAccountInfo>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
    
    // Verify fields
    AssertEquals(UInt64(2039280), Model.Lamports);
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', Model.Owner);
  finally
    Model.Free;
  end;
end;

{ TBlockProductionInfoMapConverter Tests - via TBlockProductionInfo.ByIdentity }

procedure TJsonConverterTests.Test_BlockProductionInfo_MapConverter_Roundtrip;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Model: TBlockProductionInfo;
begin
  JsonInput := LoadJson('BlockProductionInfo_ByIdentity.json');
  ExpectedJson := JsonInput;
  
  Model := TTestUtils.Deserialize<TBlockProductionInfo>(JsonInput);
  try
    // ByIdentity uses TBlockProductionInfoMapConverter
    AssertNotNull(Model.ByIdentity, 'ByIdentity should exist');
    AssertEquals(2, Model.ByIdentity.Count, 'Should have 2 identities');
    
    JsonOutput := TTestUtils.Serialize<TBlockProductionInfo>(Model);
    AssertJsonMatch(ExpectedJson, JsonOutput);
  finally
    Model.Free;
  end;
end;

{ TJsonStringEnumConverter Tests - Direct }

procedure TJsonConverterTests.Test_JsonStringEnumConverter_Commitment_CamelCase;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Value: TCommitment;
begin
  JsonInput := LoadJson('Enum_Commitment_Finalized.json');
  ExpectedJson := '"finalized"'; // Should be lowercase camelCase
  
  Value := TTestUtils.Deserialize<TCommitment>(JsonInput);
  AssertEquals(Ord(TCommitment.Finalized), Ord(Value), 'Should deserialize to Finalized');
  
  JsonOutput := TTestUtils.Serialize<TCommitment>(Value);
  AssertJsonMatch(ExpectedJson, JsonOutput, 'Should serialize to camelCase');
end;

procedure TJsonConverterTests.Test_JsonStringEnumConverter_Commitment_Roundtrip;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Value1, Value2: TCommitment;
begin
  JsonInput := LoadJson('Enum_Commitment_Confirmed.json');
  ExpectedJson := '"confirmed"';
  
  Value1 := TTestUtils.Deserialize<TCommitment>(JsonInput);
  AssertEquals(Ord(TCommitment.Confirmed), Ord(Value1));
  
  JsonOutput := TTestUtils.Serialize<TCommitment>(Value1);
  AssertJsonMatch(ExpectedJson, JsonOutput);
  
  // Second roundtrip
  Value2 := TTestUtils.Deserialize<TCommitment>(JsonOutput);
  AssertEquals(Ord(Value1), Ord(Value2), 'Roundtrip should preserve value');
end;

{ TEncodingConverter Tests - Direct }

procedure TJsonConverterTests.Test_EncodingConverter_Base64_Roundtrip;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Value: TBinaryEncoding;
begin
  JsonInput := LoadJson('Encoding_Base64.json');
  ExpectedJson := '"base64"';
  
  Value := TTestUtils.Deserialize<TBinaryEncoding>(JsonInput);
  AssertEquals(Ord(TBinaryEncoding.Base64), Ord(Value));
  
  JsonOutput := TTestUtils.Serialize<TBinaryEncoding>(Value);
  AssertJsonMatch(ExpectedJson, JsonOutput);
end;

procedure TJsonConverterTests.Test_EncodingConverter_JsonParsed_CamelCase;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Value: TBinaryEncoding;
begin
  JsonInput := LoadJson('Encoding_JsonParsed.json');
  ExpectedJson := '"jsonParsed"'; // CamelCase conversion
  
  Value := TTestUtils.Deserialize<TBinaryEncoding>(JsonInput);
  AssertEquals(Ord(TBinaryEncoding.JsonParsed), Ord(Value));
  
  JsonOutput := TTestUtils.Serialize<TBinaryEncoding>(Value);
  AssertJsonMatch(ExpectedJson, JsonOutput, 'Should convert JsonParsed to camelCase');
end;

procedure TJsonConverterTests.Test_EncodingConverter_Base64Zstd_Roundtrip;
var
  JsonInput, JsonOutput, ExpectedJson: string;
  Value: TBinaryEncoding;
begin
  JsonInput := LoadJson('Encoding_Base64Zstd.json');
  ExpectedJson := '"base64+zstd"'; // Special character handling
  
  Value := TTestUtils.Deserialize<TBinaryEncoding>(JsonInput);
  AssertEquals(Ord(TBinaryEncoding.Base64Zstd), Ord(Value));
  
  JsonOutput := TTestUtils.Serialize<TBinaryEncoding>(Value);
  AssertJsonMatch(ExpectedJson, JsonOutput, 'Should handle Base64Zstd conversion');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TJsonConverterTests);
{$ELSE}
  RegisterTest(TJsonConverterTests.Suite);
{$ENDIF}

end.
