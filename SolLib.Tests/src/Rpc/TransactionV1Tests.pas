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

unit TransactionV1Tests;

interface

uses
  SysUtils,
  Generics.Collections,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpPublicKey,
  SlpDataEncoderUtilities,
  SlpMessageDomain,
  SlpTransactionInstruction,
  SlpTransactionDomain,
  SlpTransactionConfig,
  TestResourceLoader,
  SolLibTestCase;

type
  TTransactionV1Tests = class(TSolLibTestCase)
  private
    const
      // Priority fee, compute unit limit, loaded accounts data size limit and heap size,
      // mirroring the upstream Solnet v1 message test.
      PriorityFeeValue = UInt64(20000);
      ComputeUnitLimitValue = UInt32(5000);
      LoadedAccountsDataSizeValue = UInt32(64 * 1024);
      HeapSizeValue = UInt32(64 * 1024);

      // A real mainnet version-1 transaction (epoch 1037), signature
      // 39dH3RGKtePYsnhXjv4mYJRFRsxXPN8dukZyv4pp4PqfKtz3XD1AdwTUk95V3bAPrsSzRhA6uYPAewZK2uuscrGb
      // The base64 lives in Resources/Rpc/Http/Transaction/MainnetV1Tx.txt.
      MainnetV1TxResource = 'Rpc/Http/Transaction/MainnetV1Tx.txt';
  published
    procedure ConfigMaskReflectsSetOptions;
    procedure ConfigMaskDetectsInvalidPriorityFeeBits;
    procedure V1MessageSerializeDeserializeRoundTrip;
    procedure MainnetV1TransactionRoundTrip;
  end;

implementation

{ TTransactionV1Tests }

procedure TTransactionV1Tests.ConfigMaskReflectsSetOptions;
var
  LConfig: TTransactionConfig;
  LMask: TTransactionConfigMask;
begin
  LConfig := TTransactionConfig.Create;
  try
    LConfig.PriorityFee := PriorityFeeValue;
    LConfig.ComputeUnitLimit := ComputeUnitLimitValue;

    LMask := TTransactionConfigMask.FromConfig(LConfig);

    AssertEquals(
      Integer(TTransactionConfigMask.PriorityFee or TTransactionConfigMask.ComputeUnitLimit),
      Integer(LMask.Value));
    AssertTrue(LMask.HasPriorityFee, 'expected priority fee bit');
    AssertTrue(LMask.HasComputeUnitLimit, 'expected compute unit limit bit');
    AssertFalse(LMask.HasLoadedAccountsDataSize, 'unexpected loaded accounts data size bit');
    AssertFalse(LMask.HasHeapSize, 'unexpected heap size bit');
    AssertFalse(LMask.HasUnknownBits, 'unexpected unknown bits');
    AssertFalse(LMask.HasInvalidPriorityFeeBits, 'unexpected invalid priority fee bits');
    AssertEquals(SizeOf(UInt64) + SizeOf(UInt32), LMask.SizeOfConfig);
  finally
    LConfig.Free;
  end;
end;

procedure TTransactionV1Tests.ConfigMaskDetectsInvalidPriorityFeeBits;
var
  LMask: TTransactionConfigMask;
begin
  // Only the low priority-fee bit set (0b01) is an invalid partial value.
  LMask := TTransactionConfigMask.Create(1);
  AssertTrue(LMask.HasInvalidPriorityFeeBits, 'expected invalid priority fee bits');

  // A bit outside the known set.
  LMask := TTransactionConfigMask.Create($100);
  AssertTrue(LMask.HasUnknownBits, 'expected unknown bits');
end;

procedure TTransactionV1Tests.V1MessageSerializeDeserializeRoundTrip;
var
  LMsg, LRoundTrip: IVersionedMessage;
  LConfig: TTransactionConfig;
  LBytes: TBytes;
  LMsgIntf: IMessage;
begin
  LMsg := TVersionedMessage.Create;
  LMsg.Version := 1;
  LMsg.Header := TMessageHeader.Create;
  LMsg.Header.RequiredSignatures := 1;
  LMsg.Header.ReadOnlySignedAccounts := 0;
  LMsg.Header.ReadOnlyUnsignedAccounts := 1;
  LMsg.AccountKeys := TList<IPublicKey>.Create;
  LMsg.AccountKeys.Add(TPublicKey.Create('11111111111111111111111111111111'));
  LMsg.Instructions := TList<ICompiledInstruction>.Create;
  LMsg.RecentBlockhash := '11111111111111111111111111111111';

  LConfig := TTransactionConfig.Create;
  LConfig.PriorityFee := PriorityFeeValue;
  LConfig.ComputeUnitLimit := ComputeUnitLimitValue;
  LConfig.LoadedAccountsDataSizeLimit := LoadedAccountsDataSizeValue;
  LConfig.HeapSize := HeapSizeValue;
  LMsg.TransactionConfig := LConfig;

  LBytes := LMsg.Serialize;

  // v1 prefix (0x80 | 1).
  AssertEquals($81, Integer(LBytes[0]), 'v1 prefix mismatch');

  LMsgIntf := TVersionedMessage.Deserialize(LBytes);
  AssertNotNull(LMsgIntf);
  AssertTrue(Supports(LMsgIntf, IVersionedMessage, LRoundTrip), 'expected IVersionedMessage');

  AssertEquals(1, Integer(LRoundTrip.Version), 'version not preserved');
  AssertNotNull(LRoundTrip.TransactionConfig, 'config not preserved');
  AssertTrue(LRoundTrip.TransactionConfig.PriorityFee.HasValue, 'priority fee missing');
  AssertEquals(PriorityFeeValue, LRoundTrip.TransactionConfig.PriorityFee.Value);
  AssertEquals(Int64(ComputeUnitLimitValue), Int64(LRoundTrip.TransactionConfig.ComputeUnitLimit.Value));
  AssertEquals(Int64(LoadedAccountsDataSizeValue), Int64(LRoundTrip.TransactionConfig.LoadedAccountsDataSizeLimit.Value));
  AssertEquals(Int64(HeapSizeValue), Int64(LRoundTrip.TransactionConfig.HeapSize.Value));
  AssertEquals(1, LRoundTrip.AccountKeys.Count, 'account count mismatch');

  // Re-serializing must reproduce the exact bytes.
  AssertEquals(LBytes, LRoundTrip.Serialize, 'v1 message round-trip mismatch');
end;

procedure TTransactionV1Tests.MainnetV1TransactionRoundTrip;
var
  LRaw: TBytes;
  LTx: ITransaction;
  LVersioned: IVersionedTransaction;
begin
  LRaw := TBase64Encoder.DecodeData(TTestResourceLoader.LoadTestData(MainnetV1TxResource));

  AssertEquals($81, Integer(LRaw[0]), 'expected v1 transaction prefix');

  LTx := TVersionedTransaction.Deserialize(LRaw);
  AssertNotNull(LTx);
  AssertTrue(Supports(LTx, IVersionedTransaction, LVersioned), 'expected IVersionedTransaction');
  AssertEquals(1, Integer(LVersioned.Version), 'expected version 1');
  AssertNotNull(LVersioned.TransactionConfig, 'expected a transaction config');

  // Deserialize -> re-serialize must be byte-identical to the on-chain transaction.
  AssertEquals(LRaw, LTx.Serialize, 'mainnet v1 transaction round-trip mismatch');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TTransactionV1Tests);
{$ELSE}
  RegisterTest(TTransactionV1Tests.Suite);
{$ENDIF}

end.
