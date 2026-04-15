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

unit TokenWalletTests;

interface

uses
  SysUtils,
  Classes,
  Generics.Collections,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpRpcMessage,
  SlpRpcEnum,
  SlpRequestResult,
  SlpClientFactory,
  SlpHttpApiClient,
  SlpWallet,
  SlpAccount,
  SlpPublicKey,
  SlpTokenDomain,
  SlpTokenWalletRpcProxy,
  SlpWellKnownTokens,
  SlpTokenMintResolver,
  SlpTokenWallet,
  SlpTransactionBuilder,
  SlpSolanaRpcClient,
  SlpSolanaRpcBatchWithCallbacks,
  SlpAssociatedTokenAccountProgram,
  RpcClientMocks,
  TestUtils,
  SolLibTokenTestCase;

type
  TTokenWalletTests = class(TSolLibTokenTestCase)
  private
    const
      MnemonicWords =
        'route clerk disease box emerge airport loud waste attitude film army tray' +
        ' forward deal onion eight catalog surface unit card window walnut wealth medal';
      Blockhash = '5cZja93sopRB9Bkhckj5WzCxCaVyriv2Uh5fFDPDFFfj';
  private
    function CreateMockRequestResult<T>(const AReqJson, ARespJson: string; const AHttpStatusCode: Integer): IRequestResult<T>;

  published
    procedure TestLoadKnownMint;
    procedure TestLoadUnknownMint;
    procedure TestProvisionAtaInjectBuilder;
    procedure TestLoadRefresh;
    procedure TestSendTokenProvisionAta;

    procedure TestTokenWalletLoadAddressCheck;
    procedure TestTokenWalletSendAddressCheck;

    /// <summary>
    /// Check to make sure callee can not send source TokenWalletAccount from Wallet A using Wallet B
    /// </summary>
    procedure TestSendTokenDefendAgainstAccountMismatch;

    procedure TestMockJsonRpcParseResponseValue;
    procedure TestMockJsonRpcSendTxParse;
    procedure TestOnCurveSanityChecks;

    procedure TestTokenWalletViaBatch;
    procedure TestTokenWalletFilterList;
  end;

implementation

{ TTokenWalletTests }

function TTokenWalletTests.CreateMockRequestResult<T>(
  const AReqJson, ARespJson: string; const AHttpStatusCode: Integer): IRequestResult<T>;
var
  LRes: TRequestResult<T>;
begin
  LRes := TRequestResult<T>.Create;
  LRes.HttpStatusCode := AHttpStatusCode;
  LRes.RawRpcRequest := AReqJson;
  LRes.RawRpcResponse := ARespJson;

  if AHttpStatusCode = 200 then
    LRes.Result := TTestUtils.Deserialize<T>(ARespJson);

  Result := LRes;
end;

procedure TTokenWalletTests.TestLoadKnownMint;
var
  LOwnerWallet: IWallet;
  LSigner: IAccount;
  LMockRpcClient: TMockTokenWalletRpcProxy;
  LRpcProxy: ITokenWalletRpcProxy;
  LTokens: ITokenMintResolver;
  LTestToken: ITokenDef;
  LWallet: ITokenWallet;
  LAccounts,
  LTestList: ITokenWalletFilterList;
  LPubKey: string;
begin
  LOwnerWallet := TWallet.Create(MnemonicWords);
  LSigner := LOwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', LSigner.PublicKey.Key);

  LMockRpcClient := TMockTokenWalletRpcProxy.Create;
  LRpcProxy := LMockRpcClient;

  // Load mock responses
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));

  // Token resolver setup
  LTokens := TTokenMintResolver.Create;
  LTestToken := TTokenDef.Create(
    '98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819', 'TEST', 'TEST', 2);
  LTokens.Add(LTestToken);

  // Conversion sanity checks
  AssertEquals(125, LTestToken.ConvertDoubleToUInt64(1.25), 'decimal->raw');
  AssertEquals(1.25, LTestToken.ConvertUInt64ToDouble(125), 0.01, 'raw->decimal');

  LPubKey := '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5';
  LWallet := TTokenWallet.Load(LRpcProxy, LTokens, LPubKey);

  // Wallet checks
  AssertNotNull(LWallet, 'Wallet should not be nil');
  AssertEquals(LPubKey, LWallet.PublicKey.Key);
  AssertEquals(168855000000, LWallet.Lamports);
  AssertEquals(168.855, LWallet.Sol, 0.01);
  AssertEquals(168.855000000, LWallet.Sol, 0.01);

  LAccounts := LWallet.TokenAccounts;
  AssertNotNull(LAccounts);

  // Locate known test mint account
  LTestList := LWallet.TokenAccounts.WithMint('98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819');
  AssertEquals(1, LTestList.Count);
  AssertEquals(2039280, LTestList.First.Lamports);
  AssertEquals(0, LTestList.WhichAreAssociatedTokenAccounts.Count);

  AssertEquals(
    1,
    LWallet.TokenAccounts
      .WithCustomFilter(
        function(AAccount: ITokenWalletAccount): Boolean
        begin
          Result := AAccount.PublicKey.StartsWith('G');
        end
      )
      .Count
  );

  // Verify mint data
  AssertEquals(2, LWallet.TokenAccounts.WithSymbol('TEST').First.DecimalPlaces);
  AssertEquals(LTestToken.TokenMint, LWallet.TokenAccounts.WithSymbol('TEST').First.TokenMint);
  AssertEquals(LTestToken.Symbol,
    LWallet.TokenAccounts.WithMint('98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819').First.Symbol);
  AssertEquals(10.0, LWallet.TokenAccounts.WithSymbol('TEST').First.QuantityDouble, 0.01);
  AssertEquals('G5SA5eMmbqSFnNZNB2fQV9ipHbh9y9KS65aZkAh9t8zv',
    LWallet.TokenAccounts.WithSymbol('TEST').First.PublicKey);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5',
    LWallet.TokenAccounts.WithSymbol('TEST').First.Owner);
end;

procedure TTokenWalletTests.TestLoadUnknownMint;
var
  LOwnerWallet: IWallet;
  LSigner: IAccount;
  LMockRpcClient: TMockTokenWalletRpcProxy;
  LRpcProxy: ITokenWalletRpcProxy;
  LTokens: ITokenMintResolver;
  LWallet: ITokenWallet;
  LUnknown: ITokenWalletFilterList;
begin
  LOwnerWallet := TWallet.Create(MnemonicWords);
  LSigner := LOwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', LSigner.PublicKey.Key);

  LMockRpcClient := TMockTokenWalletRpcProxy.Create;
  LRpcProxy := LMockRpcClient;

  // Load mock responses
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));

  // Token resolver (no known mints)
  LTokens := TTokenMintResolver.Create;

  // Load wallet
  LWallet := TTokenWallet.Load(LRpcProxy, LTokens, '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');

  // Assertions
  AssertNotNull(LWallet);
  AssertNotNull(LWallet.TokenAccounts);

  // Locate unknown mint account
  LUnknown := LWallet.TokenAccounts.WithMint('88ocFjrLgHEMQRMwozC7NnDBQUsq2UoQaqREFZoDEex');
  AssertEquals(1, LUnknown.Count);
  AssertEquals(0, LUnknown.WhichAreAssociatedTokenAccounts.Count);
  AssertEquals(2, LWallet.TokenAccounts.WithMint('88ocFjrLgHEMQRMwozC7NnDBQUsq2UoQaqREFZoDEex').First.DecimalPlaces);
  AssertEquals(10.0, LWallet.TokenAccounts.WithMint('88ocFjrLgHEMQRMwozC7NnDBQUsq2UoQaqREFZoDEex').First.QuantityDouble, 0.01);
  AssertEquals('4NSREK36nAr32vooa3L9z8tu6JWj5rY3k4KnsqTgynvm',
    LWallet.TokenAccounts.WithMint('88ocFjrLgHEMQRMwozC7NnDBQUsq2UoQaqREFZoDEex').First.PublicKey);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5',
    LWallet.TokenAccounts.WithMint('88ocFjrLgHEMQRMwozC7NnDBQUsq2UoQaqREFZoDEex').First.Owner);
end;

procedure TTokenWalletTests.TestProvisionAtaInjectBuilder;
var
  LOwnerWallet: IWallet;
  LSigner: IAccount;
  LMockRpcClient: TMockTokenWalletRpcProxy;
  LRpcProxy: ITokenWalletRpcProxy;
  LTokens: ITokenMintResolver;
  LTestToken: ITokenDef;
  LWallet: ITokenWallet;
  LAccounts, LTestList: ITokenWalletFilterList;
  LBuilder: ITransactionBuilder;
  LBeforeTx, LAfterTx: TBytes;
  LTestAta, LPubKey: IPublicKey;
begin
  LOwnerWallet := TWallet.Create(MnemonicWords);
  LSigner := LOwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', LSigner.PublicKey.Key);

  LMockRpcClient := TMockTokenWalletRpcProxy.Create;
  LRpcProxy := LMockRpcClient;

  // Load mock responses
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));

  // Token resolver setup
  LTokens := TTokenMintResolver.Create;
  LTestToken := TTokenDef.Create(
    '98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819',
    'TEST',
    'TEST',
    2
  );
  LTokens.Add(LTestToken);

  // Load wallet
  LWallet := TTokenWallet.Load(
    LRpcProxy,
    LTokens,
    '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5'
  );
  AssertNotNull(LWallet);

  LAccounts := LWallet.TokenAccounts;
  AssertNotNull(LAccounts);

  // Locate known test mint account
  LTestList := LWallet.TokenAccounts.WithMint('98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819');
  AssertEquals(1, LTestList.Count);
  AssertEquals(0, LTestList.WhichAreAssociatedTokenAccounts.Count);

  // Inject ATA creation into a transaction builder
  LBuilder := TTransactionBuilder.Create;

  LBuilder.SetFeePayer(LSigner.PublicKey)
      .SetRecentBlockHash(Blockhash);

  LBeforeTx := LBuilder.Build(LSigner);

  LPubKey := TPublicKey.Create('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');
  LTestAta := LWallet.JitCreateAssociatedTokenAccount(
    LBuilder,
    LTestToken.TokenMint,
    LPubKey
  );

  LAfterTx := LBuilder.Build(LSigner);

  AssertEquals('F6qCC87R5cmAJUKbhwERSFQHkQpSKyUkETgrjTJKB2nK', LTestAta.Key);
  AssertTrue(Length(LAfterTx) > Length(LBeforeTx));
end;

procedure TTokenWalletTests.TestLoadRefresh;
var
  LOwnerWallet: IWallet;
  LSigner: IAccount;
  LMockRpcClient: TMockTokenWalletRpcProxy;
  LRpcProxy: ITokenWalletRpcProxy;
  LTokens: ITokenMintResolver;
  LTestToken: ITokenDef;
  LWallet: ITokenWallet;
begin
  LOwnerWallet := TWallet.Create(MnemonicWords);
  LSigner := LOwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', LSigner.PublicKey.Key);

  // Mock client setup
  LMockRpcClient := TMockTokenWalletRpcProxy.Create;
  LRpcProxy := LMockRpcClient;

  // Add mock JSON responses
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));

  // Token resolver
  LTokens := TTokenMintResolver.Create;
  LTestToken := TTokenDef.Create(
    '98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819', 'TEST', 'TEST', 2);
  LTokens.Add(LTestToken);

  // Load and refresh wallet
  LWallet := TTokenWallet.Load(LRpcProxy, LTokens, '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');
  AssertNotNull(LWallet);

  LWallet.Refresh;
end;

procedure TTokenWalletTests.TestSendTokenProvisionAta;
var
  LOwnerWallet: IWallet;
  LSigner, LTargetOwner: IAccount;
  LMintPubkey, LDeterministicPda: IPublicKey;
  LMockRpcClient: TMockTokenWalletRpcProxy;
  LRpcProxy: ITokenWalletRpcProxy;
  LTokens: ITokenMintResolver;
  LTestToken: ITokenDef;
  LWallet: ITokenWallet;
  LTestTokenAccount: ITokenWalletAccount;
  LSendResponse: IRequestResult<string>;
begin
  // get owner
  LOwnerWallet := TWallet.Create(MnemonicWords);
  LSigner := LOwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', LSigner.PublicKey.Key);

  // use other account as mock target and check derived PDA
  LMintPubkey := TPublicKey.Create('98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819');
  LTargetOwner := LOwnerWallet.GetAccountByIndex(99);
  LDeterministicPda := TAssociatedTokenAccountProgram.DeriveAssociatedTokenAccount(LTargetOwner.PublicKey, LMintPubkey);

  AssertEquals('3FmSwkHqwRdqYQ74Nx84LNYLnwPhcNivuqhDGWghZY7F', LTargetOwner.PublicKey.Key);
  AssertNotNull(LDeterministicPda);
  AssertEquals('HwkThm2LadHWCnqaSkJCpQutvrt8qwp2PpSxBHbhcwYV', LDeterministicPda.Key);

  // create mock proxy
  LMockRpcClient := TMockTokenWalletRpcProxy.Create;
  LRpcProxy := LMockRpcClient;

  // setup mock responses
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));

  // define some mints
  LTokens := TTokenMintResolver.Create;
  LTestToken := TTokenDef.Create(LMintPubkey.Key, 'TEST', 'TEST', 2);
  LTokens.Add(LTestToken);

  // load account
  LWallet := TTokenWallet.Load(LRpcProxy, LTokens, '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');
  AssertNotNull(LWallet);

  // identify test token account with some balance
  LTestTokenAccount := LWallet.TokenAccounts.ForToken(LTestToken).WithAtLeast(5.0).First;
  AssertFalse(LTestTokenAccount.IsAssociatedTokenAccount);

  // going to send some TEST token to destination wallet that does not have an ATA
  // internally triggers a wallet load so we preload responses
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse2.json'));
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetRecentBlockhashResponse.json'));
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/SendTransactionResponse.json'));

  // send token
  LSendResponse := LWallet.Send(
    LTestTokenAccount,
    1.0,
    LTargetOwner.PublicKey,
    LSigner.PublicKey,
    function(ABuilder: ITransactionBuilder): TBytes
    begin
      Result := ABuilder.Build(LSigner);
    end
  );

  AssertEquals('FAKEGpFLmgktqjTu3cXW4wbTkfXpdGZUnxjVDHTet22F3rZNPQbmQaVFvYmLmGuhvFjuuSVrAR4BWJAGxNDNrFDU', LSendResponse.Result);
end;

procedure TTokenWalletTests.TestTokenWalletLoadAddressCheck;
var
  LMockRpcClient: TMockTokenWalletRpcProxy;
  LRpcProxy: ITokenWalletRpcProxy;
  LTokens: ITokenMintResolver;
begin
  // try to load a made-up wallet address
  LMockRpcClient := TMockTokenWalletRpcProxy.Create;
  LRpcProxy := LMockRpcClient;

  LTokens := TTokenMintResolver.Create;

  AssertException(
    procedure
    begin
      TTokenWallet.Load(LRpcProxy, LTokens, 'FAKEkjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');
    end,
    EArgumentException
  );
end;

procedure TTokenWalletTests.TestTokenWalletSendAddressCheck;
var
  LOwnerWallet: IWallet;
  LSigner: IAccount;
  LMockRpcClient: TMockTokenWalletRpcProxy;
  LRpcProxy: ITokenWalletRpcProxy;
  LTokens: ITokenMintResolver;
  LTestToken: ITokenDef;
  LWallet: ITokenWallet;
  LTestTokenAccount: ITokenWalletAccount;
  LTargetOwner: string;
begin
  // get owner
  LOwnerWallet := TWallet.Create(MnemonicWords);
  LSigner := LOwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', LSigner.PublicKey.Key);

  // create mock proxy
  LMockRpcClient := TMockTokenWalletRpcProxy.Create;
  LRpcProxy := LMockRpcClient;

  // setup mock responses
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));

  // define some mints
  LTokens := TTokenMintResolver.Create;
  LTestToken := TTokenDef.Create('98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819', 'TEST', 'TEST', 2);
  LTokens.Add(LTestToken);

  // load account and identify test token account with some balance
  LWallet := TTokenWallet.Load(LRpcProxy, LTokens, '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');
  AssertNotNull(LWallet);

  LTestTokenAccount := LWallet.TokenAccounts.ForToken(LTestToken).WithAtLeast(5.0).First;
  AssertFalse(LTestTokenAccount.IsAssociatedTokenAccount);

  // trigger send to bogus target wallet
  LTargetOwner := 'BADxzxtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5';
  AssertException(
    procedure
    begin
      LWallet.Send(
        LTestTokenAccount,
        1.0,
        LTargetOwner,
        LSigner.PublicKey,
        function(ABuilder: ITransactionBuilder): TBytes
        begin
          Result := ABuilder.Build(LSigner);
        end
      );
    end,
    Exception
  );
end;

procedure TTokenWalletTests.TestSendTokenDefendAgainstAccountMismatch;
var
  LMockRpcClient: TMockTokenWalletRpcProxy;
  LRpcProxy: ITokenWalletRpcProxy;
  LMintPubkey: IPublicKey;
  LTokens: ITokenMintResolver;
  LTestToken: ITokenDef;
  LOwnerWallet: IWallet;
  LAccountA, LAccountB, LDestination: IAccount;
  LWalletA, LWalletB: ITokenWallet;
  LAccountInA: ITokenWalletAccount;
begin
  // create mock RPC proxy (interface will manage lifetime)
  LMockRpcClient := TMockTokenWalletRpcProxy.Create;
  LRpcProxy := LMockRpcClient;

  // define mint and owner
  LMintPubkey := TPublicKey.Create('98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819');

  LTokens := TTokenMintResolver.Create;
  LTestToken := TTokenDef.Create(LMintPubkey.Key, 'TEST', 'TEST', 2);
  LTokens.Add(LTestToken);

  LOwnerWallet := TWallet.Create(MnemonicWords);

  // load wallet A
  LAccountA := LOwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', LAccountA.PublicKey.Key);
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));
  LWalletA := TTokenWallet.Load(LRpcProxy, LTokens, LAccountA.PublicKey);

  // load wallet B
  LAccountB := LOwnerWallet.GetAccountByIndex(2);
  AssertEquals('3F2RNf2f2kWYgJ2XsqcjzVeh3rsEQnwf6cawtBiJGyKV', LAccountB.PublicKey.Key);
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  LMockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse2.json'));
  LWalletB := TTokenWallet.Load(LRpcProxy, LTokens, LAccountB.PublicKey);

  // use another account as mock target and check derived PDA
  LDestination := LOwnerWallet.GetAccountByIndex(99);

  // identify test token account with some balance in Wallet A
  LAccountInA := LWalletA.TokenAccounts.ForToken(LTestToken).WithAtLeast(5.0).First;
  AssertFalse(LAccountInA.IsAssociatedTokenAccount);

  // attempt to send using wallet B should raise an exception (account mismatch)
  AssertException(
    procedure
    begin
      LWalletB.Send(
        LAccountInA,
        1.0,
        LDestination.PublicKey,
        LAccountA.PublicKey,
        function (ABuilder: ITransactionBuilder): TBytes
        begin
          Result := ABuilder.Build(LAccountB);
        end
      );
    end,
    EArgumentException
  );
end;

procedure TTokenWalletTests.TestMockJsonRpcParseResponseValue;
var
  LJson: string;
  LResp: TJsonRpcResponse<TResponseValue<UInt64>>;
begin
  LJson := LoadTestData('TokenWallet/GetBalanceResponse.json');
  LResp := nil;
  try
    LResp := TTestUtils.Deserialize<TJsonRpcResponse<TResponseValue<UInt64>>>(LJson);
    AssertNotNull(LResp);
  finally
    if Assigned(LResp) then
      LResp.Free;
  end;
end;

procedure TTokenWalletTests.TestMockJsonRpcSendTxParse;
var
  LJson: string;
  LResp: TJsonRpcResponse<string>;
begin
  LJson := LoadTestData('TokenWallet/SendTransactionResponse.json');
  LResp := nil;
  try
    LResp := TTestUtils.Deserialize<TJsonRpcResponse<string>>(LJson);
    AssertNotNull(LResp);
  finally
    if Assigned(LResp) then
      LResp.Free;
  end;
end;

procedure TTokenWalletTests.TestOnCurveSanityChecks;
var
  LOwnerWallet: IWallet;
  LOwner: IAccount;
  LMintPubkey, LAta, LFake: IPublicKey;
begin
  // check real wallet address
  LOwnerWallet := TWallet.Create(MnemonicWords);

  LOwner := LOwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', LOwner.PublicKey.Key);
  AssertTrue(LOwner.PublicKey.IsOnCurve);

  // spot an ata
  LMintPubkey := TPublicKey.Create(TWellKnownTokens.Serum.TokenMint);
  LAta := TAssociatedTokenAccountProgram.DeriveAssociatedTokenAccount(LOwner.PublicKey, LMintPubkey);
  AssertFalse(LAta.IsOnCurve);

  // spot a fake address
  LFake := TPublicKey.Create('FAKEkjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');
  AssertFalse(LFake.IsOnCurve);
end;

procedure TTokenWalletTests.TestTokenWalletViaBatch;
var
  LExpectedReq, LExpectedResp: string;
  LTokens: ITokenMintResolver;
  LTestToken: ITokenDef;
  LUnusedRpc: IRpcClient;
  LBatch: TSolanaRpcBatchWithCallbacks;
  LOwnerWallet: IWallet;
  LSigner: IAccount;
  LPubKey, LJson: string;
  LWalletPromise: TFunc<ITokenWallet>;
  LReqs: TJsonRpcBatchRequest;
  LResp: IRequestResult<TJsonRpcBatchResponse>;
  LBatchResp: TJsonRpcBatchResponse;
  LWallet: ITokenWallet;
  LMockRpcHttpClient: TMockRpcHttpClient;
  LRpcHttpClient: IHttpApiClient;
begin
  LExpectedReq := LoadTestData('TokenWallet/SampleBatchRequest.json');
  LExpectedResp := LoadTestData('TokenWallet/SampleBatchResponse.json');

  // Token resolver setup
  LTokens := TTokenMintResolver.Create;
  LTestToken := TTokenDef.Create(
    '98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819', 'TEST', 'TEST', 2);
  LTokens.Add(LTestToken);

  // Initialize mock RPC client
  LMockRpcHttpClient := SetupTest('', 200, 'OK');
  LRpcHttpClient := LMockRpcHttpClient;

  LUnusedRpc := TClientFactory.GetClient(TCluster.TestNet, LRpcHttpClient);
  LBatch := TSolanaRpcBatchWithCallbacks.Create(LUnusedRpc);
  try
    // Test wallet setup
    LOwnerWallet := TWallet.Create(MnemonicWords);
    LSigner := LOwnerWallet.GetAccountByIndex(1);
    LPubKey := LSigner.PublicKey.Key;
    AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', LPubKey);

    LWalletPromise := TTokenWallet.Load(LBatch, LTokens, LPubKey);

    // Serialize batch and verify JSON
    LReqs := LBatch.Composer.CreateJsonRequests;
    try
      AssertNotNull(LReqs);
      AssertEquals(2, LReqs.Count);

      LJson := TTestUtils.Serialize<TJsonRpcBatchRequest>(LReqs);
      AssertJsonMatch(LExpectedReq, LJson);

      // Fake RPC response
      LResp := CreateMockRequestResult<TJsonRpcBatchResponse>(
        LExpectedReq, LExpectedResp, 200);
      AssertNotNull(LResp.Result);
      AssertEquals(2, LResp.Result.Count);

      // Process and invoke callbacks - this unblocks LWalletPromise
      LBatchResp := LBatch.Composer.ProcessBatchResponse(LResp);
      try
        LWallet := LWalletPromise();

        // Assertions
        AssertEquals(168855000000, LWallet.Lamports);
        AssertEquals(168.855, LWallet.Sol, 0.01);
        AssertEquals(168.855000000, LWallet.Sol, 0.01);

        // Token assertions
        AssertEquals(10.0, LWallet.TokenAccounts.WithSymbol('TEST').First.QuantityDouble, 0.01);
        AssertEquals(10.0, LWallet.TokenAccounts.WithMint(LTestToken).First.QuantityDouble, 0.01);
        AssertEquals(10.0, LWallet.TokenAccounts.WithAtLeast(10.0).First.QuantityDouble, 0.01);
        AssertEquals(10.0, LWallet.TokenAccounts.WithAtLeast(1000).First.QuantityDouble, 0.01);
        AssertEquals(10.0, LWallet.TokenAccounts.WithNonZero.First.QuantityDouble, 0.01);
      finally
        LBatchResp.Free;
      end;
    finally
      LReqs.Free;
    end;
  finally
    LBatch.Free;
  end;
end;

procedure TTokenWalletTests.TestTokenWalletFilterList;
var
  LEmptyAccounts: TList<ITokenWalletAccount>;
  LList: ITokenWalletFilterList;
  LPass: Boolean;
  LCount: Integer;
  LIt: ITokenWalletAccount;
begin
  LEmptyAccounts := TList<ITokenWalletAccount>.Create;
  try
    LList := TTokenWalletFilterList.Create(LEmptyAccounts);
    LPass := False;
    try
      LList.WithPublicKey('');
    except
      on E: EArgumentException do
        LPass := True;
    end;

    try
      LList.WithMint(ITokenDef(nil));
    except
      on E: EArgumentNilException do
        LPass := LPass and True;
    end;

    try
      LList.WithCustomFilter(nil);
    except
      on E: EArgumentNilException do
        LPass := LPass and True;
    end;

    LCount := 0;
    for LIt in LList do
      Inc(LCount);
    AssertEquals(0, LCount);
    AssertTrue(LPass);
  finally
    LEmptyAccounts.Free;
  end;
end;

initialization
{$IFDEF FPC}
  RegisterTest(TTokenWalletTests);
{$ELSE}
  RegisterTest(TTokenWalletTests.Suite);
{$ENDIF}

end.

