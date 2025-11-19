program SolLib.Tests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

{$WARN DUPLICATE_CTOR_DTOR OFF}

{$IFNDEF TESTINSIGHT}
  {$IFDEF CONSOLE_TESTRUNNER}
    {$APPTYPE CONSOLE}
  {$ENDIF}
{$ENDIF}

uses
{$IFDEF TESTINSIGHT}
   TestInsight.DUnit,
{$ELSE}
   Forms,
   TestFramework,
   GUITestRunner,
   TextTestRunner,
{$ENDIF}
  SlpTokenModel in '..\..\SolLib\src\Token\SlpTokenModel.pas',
  SlpTokenMintResolver in '..\..\SolLib\src\Token\SlpTokenMintResolver.pas',
  SlpTokenDomain in '..\..\SolLib\src\Token\SlpTokenDomain.pas',
  SlpTokenWalletRpcProxy in '..\..\SolLib\src\Token\SlpTokenWalletRpcProxy.pas',
  SlpWellKnownTokens in '..\..\SolLib\src\Token\SlpWellKnownTokens.pas',
  SlpJsonHelpers in '..\..\SolLib\src\Helpers\SlpJsonHelpers.pas',
  SlpValueHelpers in '..\..\SolLib\src\Helpers\SlpValueHelpers.pas',
  SlpBaseJsonConverter in '..\..\SolLib\src\JsonConverters\SlpBaseJsonConverter.pas',
  SlpAccountDataConverter in '..\..\SolLib\src\JsonConverters\SlpAccountDataConverter.pas',
  SlpTokenAccountDataConverter in '..\..\SolLib\src\JsonConverters\SlpTokenAccountDataConverter.pas',
  SlpEncodingConverter in '..\..\SolLib\src\JsonConverters\SlpEncodingConverter.pas',
  SlpJsonListConverter in '..\..\SolLib\src\JsonConverters\SlpJsonListConverter.pas',
  SlpJsonRpcBatchRequestConverter in '..\..\SolLib\src\JsonConverters\SlpJsonRpcBatchRequestConverter.pas',
  SlpJsonRpcBatchResponseConverter in '..\..\SolLib\src\JsonConverters\SlpJsonRpcBatchResponseConverter.pas',
  SlpJsonRpcBatchResponseItemResultConverter in '..\..\SolLib\src\JsonConverters\SlpJsonRpcBatchResponseItemResultConverter.pas',
  SlpJsonRpcRequestParamsConverter in '..\..\SolLib\src\JsonConverters\SlpJsonRpcRequestParamsConverter.pas',
  SlpJsonStringEnumConverter in '..\..\SolLib\src\JsonConverters\SlpJsonStringEnumConverter.pas',
  SlpNullableConverter in '..\..\SolLib\src\JsonConverters\SlpNullableConverter.pas',
  SlpRpcErrorResponseConverter in '..\..\SolLib\src\JsonConverters\SlpRpcErrorResponseConverter.pas',
  SlpTokenListItemExtensionsConverter in '..\..\SolLib\src\JsonConverters\SlpTokenListItemExtensionsConverter.pas',
  SlpTransactionErrorJsonConverter in '..\..\SolLib\src\JsonConverters\SlpTransactionErrorJsonConverter.pas',
  SlpTransactionMetaInfoTransactionConverter in '..\..\SolLib\src\JsonConverters\SlpTransactionMetaInfoTransactionConverter.pas',
  SlpTransactionMetaInfoVersionConverter in '..\..\SolLib\src\JsonConverters\SlpTransactionMetaInfoVersionConverter.pas',
  SlpJsonClampNumberConverter in '..\..\SolLib\src\JsonConverters\SlpJsonClampNumberConverter.pas',
  SlpJsonKeyStoreSerializer in '..\..\SolLib\src\KeyStore\SlpJsonKeyStoreSerializer.pas',
  SlpKeyStoreCrypto in '..\..\SolLib\src\KeyStore\SlpKeyStoreCrypto.pas',
  SlpKeyStoreEnum in '..\..\SolLib\src\KeyStore\SlpKeyStoreEnum.pas',
  SlpKeyStoreKdfChecker in '..\..\SolLib\src\KeyStore\SlpKeyStoreKdfChecker.pas',
  SlpKeyStoreModel in '..\..\SolLib\src\KeyStore\SlpKeyStoreModel.pas',
  SlpKeyStoreService in '..\..\SolLib\src\KeyStore\SlpKeyStoreService.pas',
  SlpSecretKeyStoreService in '..\..\SolLib\src\KeyStore\SlpSecretKeyStoreService.pas',
  SlpSolanaKeyStoreService in '..\..\SolLib\src\KeyStore\SlpSolanaKeyStoreService.pas',
  SlpBitWriter in '..\..\SolLib\src\Misc\SlpBitWriter.pas',
  SlpDataEncoders in '..\..\SolLib\src\Misc\Encoder\SlpDataEncoders.pas',
  SlpJsonKit in '..\..\SolLib\src\Misc\SlpJsonKit.pas',
  SlpNullable in '..\..\SolLib\src\Misc\SlpNullable.pas',
  SlpSolLibExceptions in '..\..\SolLib\src\Misc\SlpSolLibExceptions.pas',
  SlpStringTransformer in '..\..\SolLib\src\Misc\SlpStringTransformer.pas',
  SlpTimeTicker in '..\..\SolLib\src\Misc\SlpTimeTicker.pas',
  SlpMulticast in '..\..\SolLib\src\Misc\SlpMulticast.pas',
  SlpUTF8NoBOMEncoding in '..\..\SolLib\src\Misc\Encoder\SlpUTF8NoBOMEncoding.pas',
  SlpKdTable in '..\..\SolLib\src\Misc\Normalization\SlpKdTable.pas',
  SlpArrayUtils in '..\..\SolLib\src\Utils\SlpArrayUtils.pas',
  SlpCryptoUtils in '..\..\SolLib\src\Utils\SlpCryptoUtils.pas',
  SlpEd25519Utils in '..\..\SolLib\src\Utils\SlpEd25519Utils.pas',
  SlpListUtils in '..\..\SolLib\src\Utils\SlpListUtils.pas',
  SlpStringUtils in '..\..\SolLib\src\Utils\SlpStringUtils.pas',
  SlpValueUtils in '..\..\SolLib\src\Utils\SlpValueUtils.pas',
  SlpIOUtils in '..\..\SolLib\src\Utils\SlpIOUtils.pas',
  SlpMathUtils in '..\..\SolLib\src\Utils\SlpMathUtils.pas',
  SlpAccount in '..\..\SolLib\src\Wallet\SlpAccount.pas',
  SlpEd25519Bip32 in '..\..\SolLib\src\Wallet\SlpEd25519Bip32.pas',
  SlpPrivateKey in '..\..\SolLib\src\Wallet\SlpPrivateKey.pas',
  SlpPublicKey in '..\..\SolLib\src\Wallet\SlpPublicKey.pas',
  SlpWallet in '..\..\SolLib\src\Wallet\SlpWallet.pas',
  SlpWalletEnum in '..\..\SolLib\src\Wallet\SlpWalletEnum.pas',
  SlpHardcodedWordListSource in '..\..\SolLib\src\Wallet\Bip39\SlpHardcodedWordListSource.pas',
  SlpMnemonic in '..\..\SolLib\src\Wallet\Bip39\SlpMnemonic.pas',
  SlpWordList in '..\..\SolLib\src\Wallet\Bip39\SlpWordList.pas',
  SlpAccountDomain in '..\..\SolLib\src\Rpc\SlpAccountDomain.pas',
  SlpClientFactory in '..\..\SolLib\src\Rpc\SlpClientFactory.pas',
  SlpConnectionStatistics in '..\..\SolLib\src\Rpc\SlpConnectionStatistics.pas',
  SlpIdGenerator in '..\..\SolLib\src\Rpc\SlpIdGenerator.pas',
  SlpMessageBuilder in '..\..\SolLib\src\Rpc\SlpMessageBuilder.pas',
  SlpMessageDomain in '..\..\SolLib\src\Rpc\SlpMessageDomain.pas',
  SlpRateLimiter in '..\..\SolLib\src\Rpc\SlpRateLimiter.pas',
  SlpRpcEnum in '..\..\SolLib\src\Rpc\SlpRpcEnum.pas',
  SlpRpcMessage in '..\..\SolLib\src\Rpc\SlpRpcMessage.pas',
  SlpRpcModel in '..\..\SolLib\src\Rpc\SlpRpcModel.pas',
  SlpShortVectorEncoding in '..\..\SolLib\src\Rpc\SlpShortVectorEncoding.pas',
  SlpRequestResult in '..\..\SolLib\src\Rpc\Http\SlpRequestResult.pas',
  SlpSolanaRpcBatchComposer in '..\..\SolLib\src\Rpc\Http\SlpSolanaRpcBatchComposer.pas',
  SlpSolanaRpcBatchWithCallbacks in '..\..\SolLib\src\Rpc\Http\SlpSolanaRpcBatchWithCallbacks.pas',
  SlpJsonRpcClient in '..\..\SolLib\src\Rpc\Http\SlpJsonRpcClient.pas',
  SlpSolanaRpcClient in '..\..\SolLib\src\Rpc\Http\SlpSolanaRpcClient.pas',
  SlpSubscriptionEvent in '..\..\SolLib\src\Rpc\Sockets\SlpSubscriptionEvent.pas',
  SlpStreamingRpcClient in '..\..\SolLib\src\Rpc\Sockets\SlpStreamingRpcClient.pas',
  SlpSolanaStreamingRpcClient in '..\..\SolLib\src\Rpc\Sockets\SlpSolanaStreamingRpcClient.pas',
  SlpTransactionBuilder in '..\..\SolLib\src\Rpc\SlpTransactionBuilder.pas',
  SlpTransactionInstruction in '..\..\SolLib\src\Rpc\SlpTransactionInstruction.pas',
  SlpTransactionInstructionFactory in '..\..\SolLib\src\Rpc\SlpTransactionInstructionFactory.pas',
  SlpTransactionDomain in '..\..\SolLib\src\Rpc\SlpTransactionDomain.pas',
  SlpConfigObject in '..\..\SolLib\src\Rpc\SlpConfigObject.pas',
  SlpComputeBudgetEstimator in '..\..\SolLib\src\Rpc\SlpComputeBudgetEstimator.pas',
  SlpHttpApiClient in '..\..\SolLib\src\Misc\Http\SlpHttpApiClient.pas',
  SlpHttpApiResponse in '..\..\SolLib\src\Misc\Http\SlpHttpApiResponse.pas',
  SlpWebSocketClientBase in '..\..\SolLib\src\Misc\Sockets\SlpWebSocketClientBase.pas',
  SlpWebSocketApiClient in '..\..\SolLib\src\Misc\Sockets\SlpWebSocketApiClient.pas',
  SlpJsonConverterFactory in '..\..\SolLib\src\JsonConverters\SlpJsonConverterFactory.pas',
  SlpScryptImpl in '..\..\SolLib\src\Misc\Crypto\SlpScryptImpl.pas',
  SlpHttpClientBase in '..\..\SolLib\src\Misc\Http\SlpHttpClientBase.pas',
  SlpHttpClientDelphi in '..\..\SolLib\src\Misc\Http\SlpHttpClientDelphi.pas',
  SlpComparerFactory in '..\..\SolLib\src\Utils\SlpComparerFactory.pas',
  SlpBinaryPrimitives in '..\..\SolLib\src\Misc\SlpBinaryPrimitives.pas',
  SlpLogger in '..\..\SolLib\src\Misc\Logger\SlpLogger.pas',
  SlpSolConverter in '..\..\SolLib\src\Token\SlpSolConverter.pas',
  SlpTokenWallet in '..\..\SolLib\src\Token\SlpTokenWallet.pas',
  SlpSerialization in '..\..\SolLib\src\Programs\Utils\SlpSerialization.pas',
  SlpDeserialization in '..\..\SolLib\src\Programs\Utils\SlpDeserialization.pas',
  SlpSysVars in '..\..\SolLib\src\Programs\SlpSysVars.pas',
  SlpDecodedInstruction in '..\..\SolLib\src\Programs\Models\SlpDecodedInstruction.pas',
  SlpTokenProgram in '..\..\SolLib\src\Programs\SlpTokenProgram.pas',
  SlpSystemProgram in '..\..\SolLib\src\Programs\SlpSystemProgram.pas',
  SlpAssociatedTokenAccountProgram in '..\..\SolLib\src\Programs\SlpAssociatedTokenAccountProgram.pas',
  SlpMemoProgram in '..\..\SolLib\src\Programs\SlpMemoProgram.pas',
  SlpComputeBudgetProgram in '..\..\SolLib\src\Programs\SlpComputeBudgetProgram.pas',
  TestUtils in '..\src\Misc\TestUtils.pas',
  RpcClientMocks in '..\src\Misc\RpcClientMocks.pas',
  JsonStructuralComparer in '..\src\Misc\JsonStructuralComparer.pas',
  SolLibTestCase in '..\src\SolLibTestCase.pas',
  SolLibRpcClientTestCase in '..\src\Rpc\SolLibRpcClientTestCase.pas',
  SolLibWalletTestCase in '..\src\Wallet\SolLibWalletTestCase.pas',
  SolLibTokenTestCase in '..\src\Token\SolLibTokenTestCase.pas',
  SolLibKeyStoreTestCase in '..\src\KeyStore\SolLibKeyStoreTestCase.pas',
  SolLibRpcHttpMockTestCase in '..\src\SolLibRpcHttpMockTestCase.pas',
  SolLibRpcSocketMockTestCase in '..\src\SolLibRpcSocketMockTestCase.pas',
  SolLibStreamingRpcClientTestCase in '..\src\Rpc\SolLibStreamingRpcClientTestCase.pas',
  SolanaRpcClientTests in '..\src\Rpc\SolanaRpcClientTests.pas',
  SolanaRpcClientAccountTests in '..\src\Rpc\SolanaRpcClientAccountTests.pas',
  SolanaRpcClientBatchTests in '..\src\Rpc\SolanaRpcClientBatchTests.pas',
  SolanaRpcClientBlockTests in '..\src\Rpc\SolanaRpcClientBlockTests.pas',
  SolanaRpcClientFeeTests in '..\src\Rpc\SolanaRpcClientFeeTests.pas',
  SolanaRpcClientInflationTests in '..\src\Rpc\SolanaRpcClientInflationTests.pas',
  SolanaRpcClientLeaderScheduleTests in '..\src\Rpc\SolanaRpcClientLeaderScheduleTests.pas',
  SolanaRpcClientSignaturesTests in '..\src\Rpc\SolanaRpcClientSignaturesTests.pas',
  SolanaRpcClientTokenTests in '..\src\Rpc\SolanaRpcClientTokenTests.pas',
  SolanaRpcClientTransactionsTests in '..\src\Rpc\SolanaRpcClientTransactionsTests.pas',
  SolanaRpcRateLimitingTests in '..\src\Rpc\SolanaRpcRateLimitingTests.pas',
  TransactionBuilderTests in '..\src\Rpc\TransactionBuilderTests.pas',
  MessageTests in '..\src\Rpc\MessageTests.pas',
  ClientFactoryTests in '..\src\Rpc\ClientFactoryTests.pas',
  TransactionTests in '..\src\Rpc\TransactionTests.pas',
  ShortVectorEncodingTests in '..\src\Rpc\ShortVectorEncodingTests.pas',
  AccountTests in '..\src\Wallet\AccountTests.pas',
  Base58Tests in '..\src\Wallet\Base58Tests.pas',
  Bip39Tests in '..\src\Wallet\Bip39Tests.pas',
  Ed25519Bip32Tests in '..\src\Wallet\Ed25519Bip32Tests.pas',
  KeysTests in '..\src\Wallet\KeysTests.pas',
  WalletTests in '..\src\Wallet\WalletTests.pas',
  KeyStoreKdfCheckerTests in '..\src\KeyStore\KeyStoreKdfCheckerTests.pas',
  SecretKeyStoreServiceTests in '..\src\KeyStore\SecretKeyStoreServiceTests.pas',
  SolanaKeygenKeyStoreTests in '..\src\KeyStore\SolanaKeygenKeyStoreTests.pas',
  TokenMintTests in '..\src\Token\TokenMintTests.pas',
  SolConverterTests in '..\src\Token\SolConverterTests.pas',
  TokenWalletTests in '..\src\Token\TokenWalletTests.pas',
  JsonStructuralComparerTests in '..\src\Misc\JsonStructuralComparerTests.pas',
  SolanaStreamingRpcClientTests in '..\src\Rpc\SolanaStreamingRpcClientTests.pas';

begin

{$IFDEF TESTINSIGHT}
   TestInsight.DUnit.RunRegisteredTests;
{$ELSE}
  Application.Initialize;
  if IsConsole then
    TextTestRunner.RunRegisteredTests
  else
    GUITestRunner.RunRegisteredTests;
{$ENDIF}

end.
