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
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
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
  LRes.RawRpcRequest  := AReqJson;
  LRes.RawRpcResponse := ARespJson;

  if AHttpStatusCode = 200 then
    LRes.Result := TTestUtils.Deserialize<T>(ARespJson);

  Result := LRes;
end;

procedure TTokenWalletTests.TestLoadKnownMint;
var
  OwnerWallet: IWallet;
  Signer     : IAccount;
  MockRpcClient: TMockTokenWalletRpcProxy;
  RpcProxy   : ITokenWalletRpcProxy;
  Tokens     : ITokenMintResolver;
  TestToken  : ITokenDef;
  Wallet     : ITokenWallet;
  Accounts,
  TestList   : ITokenWalletFilterList;
  PubKey     : string;
begin
  OwnerWallet := TWallet.Create(MnemonicWords);
  Signer := OwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', Signer.PublicKey.Key);

  MockRpcClient := TMockTokenWalletRpcProxy.Create;
  RpcProxy := MockRpcClient;

  // Load mock responses
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));

  // Token resolver setup
  Tokens := TTokenMintResolver.Create;
  TestToken := TTokenDef.Create(
    '98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819', 'TEST', 'TEST', 2);
  Tokens.Add(TestToken);

  // Conversion sanity checks
  AssertEquals(125, TestToken.ConvertDoubleToUInt64(1.25), 'decimal->raw');
  AssertEquals(1.25, TestToken.ConvertUInt64ToDouble(125), 0.01, 'raw->decimal');

  PubKey := '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5';
  Wallet := TTokenWallet.Load(RpcProxy, Tokens, PubKey);

  // Wallet checks
  AssertNotNull(Wallet, 'Wallet should not be nil');
  AssertEquals(PubKey, Wallet.PublicKey.Key);
  AssertEquals(168855000000, Wallet.Lamports);
  AssertEquals(168.855, Wallet.Sol, 0.01);
  AssertEquals(168.855000000, Wallet.Sol, 0.01);

  Accounts := Wallet.TokenAccounts;
  AssertNotNull(Accounts);

  // Locate known test mint account
  TestList := Wallet.TokenAccounts.WithMint('98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819');
  AssertEquals(1, TestList.Count);
  AssertEquals(2039280, TestList.First.Lamports);
  AssertEquals(0, TestList.WhichAreAssociatedTokenAccounts.Count);

  AssertEquals(
    1,
    Wallet.TokenAccounts
      .WithCustomFilter(
        function(X: ITokenWalletAccount): Boolean
        begin
          Result := X.PublicKey.StartsWith('G');
        end
      )
      .Count
  );

  // Verify mint data
  AssertEquals(2, Wallet.TokenAccounts.WithSymbol('TEST').First.DecimalPlaces);
  AssertEquals(TestToken.TokenMint, Wallet.TokenAccounts.WithSymbol('TEST').First.TokenMint);
  AssertEquals(TestToken.Symbol,
    Wallet.TokenAccounts.WithMint('98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819').First.Symbol);
  AssertEquals(10.0, Wallet.TokenAccounts.WithSymbol('TEST').First.QuantityDouble, 0.01);
  AssertEquals('G5SA5eMmbqSFnNZNB2fQV9ipHbh9y9KS65aZkAh9t8zv',
    Wallet.TokenAccounts.WithSymbol('TEST').First.PublicKey);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5',
    Wallet.TokenAccounts.WithSymbol('TEST').First.Owner);
end;

procedure TTokenWalletTests.TestLoadUnknownMint;
var
  OwnerWallet : IWallet;
  Signer      : IAccount;
  MockRpcClient : TMockTokenWalletRpcProxy;
  RpcProxy    : ITokenWalletRpcProxy;
  Tokens      : ITokenMintResolver;
  Wallet      : ITokenWallet;
  Unknown     : ITokenWalletFilterList;
begin
  OwnerWallet := TWallet.Create(MnemonicWords);
  Signer := OwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', Signer.PublicKey.Key);

  MockRpcClient := TMockTokenWalletRpcProxy.Create;
  RpcProxy := MockRpcClient;

  // Load mock responses
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));

  // Token resolver (no known mints)
  Tokens := TTokenMintResolver.Create;

  // Load wallet
  Wallet := TTokenWallet.Load(RpcProxy, Tokens, '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');

  // Assertions
  AssertNotNull(Wallet);
  AssertNotNull(Wallet.TokenAccounts);

  // Locate unknown mint account
  Unknown := Wallet.TokenAccounts.WithMint('88ocFjrLgHEMQRMwozC7NnDBQUsq2UoQaqREFZoDEex');
  AssertEquals(1, Unknown.Count);
  AssertEquals(0, Unknown.WhichAreAssociatedTokenAccounts.Count);
  AssertEquals(2, Wallet.TokenAccounts.WithMint('88ocFjrLgHEMQRMwozC7NnDBQUsq2UoQaqREFZoDEex').First.DecimalPlaces);
  AssertEquals(10.0, Wallet.TokenAccounts.WithMint('88ocFjrLgHEMQRMwozC7NnDBQUsq2UoQaqREFZoDEex').First.QuantityDouble, 0.01);
  AssertEquals('4NSREK36nAr32vooa3L9z8tu6JWj5rY3k4KnsqTgynvm',
    Wallet.TokenAccounts.WithMint('88ocFjrLgHEMQRMwozC7NnDBQUsq2UoQaqREFZoDEex').First.PublicKey);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5',
    Wallet.TokenAccounts.WithMint('88ocFjrLgHEMQRMwozC7NnDBQUsq2UoQaqREFZoDEex').First.Owner);
end;

procedure TTokenWalletTests.TestProvisionAtaInjectBuilder;
var
  OwnerWallet : IWallet;
  Signer      : IAccount;
  MockRpcClient : TMockTokenWalletRpcProxy;
  RpcProxy    : ITokenWalletRpcProxy;
  Tokens      : ITokenMintResolver;
  TestToken   : ITokenDef;
  Wallet      : ITokenWallet;
  Accounts, TestList : ITokenWalletFilterList;
  Builder     : ITransactionBuilder;
  BeforeTx, AfterTx : TBytes;
  TestAta, PubKey : IPublicKey;
begin
  OwnerWallet := TWallet.Create(MnemonicWords);
  Signer := OwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', Signer.PublicKey.Key);

  MockRpcClient := TMockTokenWalletRpcProxy.Create;
  RpcProxy := MockRpcClient;

  // Load mock responses
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));

  // Token resolver setup
  Tokens := TTokenMintResolver.Create;
  TestToken := TTokenDef.Create(
    '98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819',
    'TEST',
    'TEST',
    2
  );
  Tokens.Add(TestToken);

  // Load wallet
  Wallet := TTokenWallet.Load(
    RpcProxy,
    Tokens,
    '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5'
  );
  AssertNotNull(Wallet);

  Accounts := Wallet.TokenAccounts;
  AssertNotNull(Accounts);

  // Locate known test mint account
  TestList := Wallet.TokenAccounts.WithMint('98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819');
  AssertEquals(1, TestList.Count);
  AssertEquals(0, TestList.WhichAreAssociatedTokenAccounts.Count);

  // Inject ATA creation into a transaction builder
  Builder := TTransactionBuilder.Create;

  Builder.SetFeePayer(Signer.PublicKey)
      .SetRecentBlockHash(Blockhash);

  BeforeTx := Builder.Build(Signer);

  PubKey := TPublicKey.Create('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');
  TestAta := Wallet.JitCreateAssociatedTokenAccount(
    Builder,
    TestToken.TokenMint,
    PubKey
  );

  AfterTx := Builder.Build(Signer);

  AssertEquals('F6qCC87R5cmAJUKbhwERSFQHkQpSKyUkETgrjTJKB2nK', TestAta.Key);
  AssertTrue(Length(AfterTx) > Length(BeforeTx));
end;

procedure TTokenWalletTests.TestLoadRefresh;
var
  OwnerWallet : IWallet;
  Signer      : IAccount;
  MockRpcClient : TMockTokenWalletRpcProxy;
  RpcProxy    : ITokenWalletRpcProxy;
  Tokens      : ITokenMintResolver;
  TestToken   : ITokenDef;
  Wallet      : ITokenWallet;
begin
  OwnerWallet := TWallet.Create(MnemonicWords);
  Signer := OwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', Signer.PublicKey.Key);

  // Mock client setup
  MockRpcClient := TMockTokenWalletRpcProxy.Create;
  RpcProxy := MockRpcClient;

  // Add mock JSON responses
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));

  // Token resolver
  Tokens := TTokenMintResolver.Create;
  TestToken := TTokenDef.Create(
    '98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819', 'TEST', 'TEST', 2);
  Tokens.Add(TestToken);

  // Load and refresh wallet
  Wallet := TTokenWallet.Load(RpcProxy, Tokens, '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');
  AssertNotNull(Wallet);

  Wallet.Refresh;
end;

procedure TTokenWalletTests.TestSendTokenProvisionAta;
var
  OwnerWallet       : IWallet;
  Signer, TargetOwner: IAccount;
  MintPubkey, DeterministicPda: IPublicKey;
  MockRpcClient     : TMockTokenWalletRpcProxy;
  RpcProxy          : ITokenWalletRpcProxy;
  Tokens            : ITokenMintResolver;
  TestToken         : ITokenDef;
  Wallet            : ITokenWallet;
  TestTokenAccount  : ITokenWalletAccount;
  SendResponse      : IRequestResult<string>;
begin
  // get owner
  OwnerWallet := TWallet.Create(MnemonicWords);
  Signer := OwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', Signer.PublicKey.Key);

  // use other account as mock target and check derived PDA
  MintPubkey := TPublicKey.Create('98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819');
  TargetOwner := OwnerWallet.GetAccountByIndex(99);
  DeterministicPda := TAssociatedTokenAccountProgram.DeriveAssociatedTokenAccount(TargetOwner.PublicKey, MintPubkey);

  AssertEquals('3FmSwkHqwRdqYQ74Nx84LNYLnwPhcNivuqhDGWghZY7F', TargetOwner.PublicKey.Key);
  AssertNotNull(DeterministicPda);
  AssertEquals('HwkThm2LadHWCnqaSkJCpQutvrt8qwp2PpSxBHbhcwYV', DeterministicPda.Key);

  // create mock proxy
  MockRpcClient := TMockTokenWalletRpcProxy.Create;
  RpcProxy := MockRpcClient;

  // setup mock responses
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));

  // define some mints
  Tokens := TTokenMintResolver.Create;
  TestToken := TTokenDef.Create(MintPubkey.Key, 'TEST', 'TEST', 2);
  Tokens.Add(TestToken);

  // load account
  Wallet := TTokenWallet.Load(RpcProxy, Tokens, '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');
  AssertNotNull(Wallet);

  // identify test token account with some balance
  TestTokenAccount := Wallet.TokenAccounts.ForToken(TestToken).WithAtLeast(5.0).First;
  AssertFalse(TestTokenAccount.IsAssociatedTokenAccount);

  // going to send some TEST token to destination wallet that does not have an ATA
  // internally triggers a wallet load so we preload responses
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse2.json'));
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetRecentBlockhashResponse.json'));
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/SendTransactionResponse.json'));

  // send token
  SendResponse := Wallet.Send(
    TestTokenAccount,
    1.0,
    TargetOwner.PublicKey,
    Signer.PublicKey,
    function(B: ITransactionBuilder): TBytes
    begin
      Result := B.Build(Signer);
    end
  );

  AssertEquals('FAKEGpFLmgktqjTu3cXW4wbTkfXpdGZUnxjVDHTet22F3rZNPQbmQaVFvYmLmGuhvFjuuSVrAR4BWJAGxNDNrFDU', SendResponse.Result);
end;

procedure TTokenWalletTests.TestTokenWalletLoadAddressCheck;
var
  MockRpcClient: TMockTokenWalletRpcProxy;
  RpcProxy: ITokenWalletRpcProxy;
  Tokens: ITokenMintResolver;
begin
  // try to load a made-up wallet address
  MockRpcClient := TMockTokenWalletRpcProxy.Create;
  RpcProxy := MockRpcClient;

  Tokens := TTokenMintResolver.Create;

  AssertException(
    procedure
    begin
      TTokenWallet.Load(RpcProxy, Tokens, 'FAKEkjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');
    end,
    EArgumentException
  );
end;

procedure TTokenWalletTests.TestTokenWalletSendAddressCheck;
var
  OwnerWallet: IWallet;
  Signer: IAccount;
  MockRpcClient: TMockTokenWalletRpcProxy;
  RpcProxy: ITokenWalletRpcProxy;
  Tokens: ITokenMintResolver;
  TestToken: ITokenDef;
  Wallet: ITokenWallet;
  TestTokenAccount: ITokenWalletAccount;
  TargetOwner: string;
begin
  // get owner
  OwnerWallet := TWallet.Create(MnemonicWords);
  Signer := OwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', Signer.PublicKey.Key);

  // create mock proxy
  MockRpcClient := TMockTokenWalletRpcProxy.Create;
  RpcProxy := MockRpcClient;

  // setup mock responses
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));

  // define some mints
  Tokens := TTokenMintResolver.Create;
  TestToken := TTokenDef.Create('98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819', 'TEST', 'TEST', 2);
  Tokens.Add(TestToken);

  // load account and identify test token account with some balance
  Wallet := TTokenWallet.Load(RpcProxy, Tokens, '9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');
  AssertNotNull(Wallet);

  TestTokenAccount := Wallet.TokenAccounts.ForToken(TestToken).WithAtLeast(5.0).First;
  AssertFalse(TestTokenAccount.IsAssociatedTokenAccount);

  // trigger send to bogus target wallet
  TargetOwner := 'BADxzxtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5';
  AssertException(
    procedure
    begin
      Wallet.Send(
        TestTokenAccount, 1.0, TargetOwner, Signer.PublicKey,
        TFunc<ITransactionBuilder, TBytes>(
          function (const B: ITransactionBuilder): TBytes
          begin
            Result := B.Build(Signer);
          end
        )
      );
    end,
    Exception
  );
end;

procedure TTokenWalletTests.TestSendTokenDefendAgainstAccountMismatch;
var
  MockRpcClient : TMockTokenWalletRpcProxy;
  RpcProxy      : ITokenWalletRpcProxy;
  MintPubkey    : IPublicKey;
  Tokens        : ITokenMintResolver;
  TestToken     : ITokenDef;
  OwnerWallet   : IWallet;
  AccountA, AccountB, Destination: IAccount;
  WalletA, WalletB: ITokenWallet;
  AccountInA    : ITokenWalletAccount;
begin
  // create mock RPC proxy (interface will manage lifetime)
  MockRpcClient := TMockTokenWalletRpcProxy.Create;
  RpcProxy := MockRpcClient;

  // define mint and owner
  MintPubkey := TPublicKey.Create('98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819');

  Tokens := TTokenMintResolver.Create;
  TestToken := TTokenDef.Create(MintPubkey.Key, 'TEST', 'TEST', 2);
  Tokens.Add(TestToken);

  OwnerWallet := TWallet.Create(MnemonicWords);

  // load wallet A
  AccountA := OwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', AccountA.PublicKey.Key);
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse.json'));
  WalletA := TTokenWallet.Load(RpcProxy, Tokens, AccountA.PublicKey);

  // load wallet B
  AccountB := OwnerWallet.GetAccountByIndex(2);
  AssertEquals('3F2RNf2f2kWYgJ2XsqcjzVeh3rsEQnwf6cawtBiJGyKV', AccountB.PublicKey.Key);
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetBalanceResponse.json'));
  MockRpcClient.AddTextContent(LoadTestData('TokenWallet/GetTokenAccountsByOwnerResponse2.json'));
  WalletB := TTokenWallet.Load(RpcProxy, Tokens, AccountB.PublicKey);

  // use another account as mock target and check derived PDA
  Destination := OwnerWallet.GetAccountByIndex(99);

  // identify test token account with some balance in Wallet A
  AccountInA := WalletA.TokenAccounts.ForToken(TestToken).WithAtLeast(5.0).First;
  AssertFalse(AccountInA.IsAssociatedTokenAccount);

  // attempt to send using wallet B should raise an exception (account mismatch)
  AssertException(
    procedure
    begin
      WalletB.Send(
        AccountInA,
        1.0,
        Destination.PublicKey,
        AccountA.PublicKey,
        function (B: ITransactionBuilder): TBytes
        begin
          Result := B.Build(AccountB);
        end
      );
    end,
    EArgumentException
  );
end;

procedure TTokenWalletTests.TestMockJsonRpcParseResponseValue;
var
  Json: string;
  Resp: TJsonRpcResponse<TResponseValue<UInt64>>;
begin
  Json := LoadTestData('TokenWallet/GetBalanceResponse.json');
  Resp := nil;
  try
    Resp := TTestUtils.Deserialize<TJsonRpcResponse<TResponseValue<UInt64>>>(Json);
    AssertNotNull(Resp);
  finally
    if Assigned(Resp) then
      Resp.Free;
  end;
end;

procedure TTokenWalletTests.TestMockJsonRpcSendTxParse;
var
  Json: string;
  Resp: TJsonRpcResponse<string>;
begin
  Json := LoadTestData('TokenWallet/SendTransactionResponse.json');
  Resp := nil;
  try
    Resp := TTestUtils.Deserialize<TJsonRpcResponse<string>>(Json);
    AssertNotNull(Resp);
  finally
    if Assigned(Resp) then
      Resp.Free;
  end;
end;

procedure TTokenWalletTests.TestOnCurveSanityChecks;
var
  OwnerWallet: IWallet;
  Owner      : IAccount;
  MintPubkey, Ata, Fake : IPublicKey;
begin
  // check real wallet address
  OwnerWallet := TWallet.Create(MnemonicWords);

  Owner := OwnerWallet.GetAccountByIndex(1);
  AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', Owner.PublicKey.Key);
  AssertTrue(Owner.PublicKey.IsOnCurve);

  // spot an ata
  MintPubkey := TPublicKey.Create(TWellKnownTokens.Serum.TokenMint);
  Ata := TAssociatedTokenAccountProgram.DeriveAssociatedTokenAccount(Owner.PublicKey, MintPubkey);
  AssertFalse(Ata.IsOnCurve);

  // spot a fake address
  Fake := TPublicKey.Create('FAKEkjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5');
  AssertFalse(Fake.IsOnCurve);
end;

procedure TTokenWalletTests.TestTokenWalletViaBatch;
var
  ExpectedReq, ExpectedResp: string;
  Tokens     : ITokenMintResolver;
  TestToken  : ITokenDef;
  UnusedRpc  : IRpcClient;
  Batch      : TSolanaRpcBatchWithCallbacks;
  OwnerWallet: IWallet;
  Signer     : IAccount;
  PubKey, Json: string;
  WalletPromise: TFunc<ITokenWallet>;
  Reqs       : TJsonRpcBatchRequest;
  Resp       : IRequestResult<TJsonRpcBatchResponse>;
  BatchResp  : TJsonRpcBatchResponse;
  Wallet     : ITokenWallet;
  MockRpcHttpClient: TMockRpcHttpClient;
  RpcHttpClient: IHttpApiClient;
begin
  ExpectedReq  := LoadTestData('TokenWallet/SampleBatchRequest.json');
  ExpectedResp := LoadTestData('TokenWallet/SampleBatchResponse.json');

  // Token resolver setup
  Tokens := TTokenMintResolver.Create;
  TestToken := TTokenDef.Create(
    '98mCaWvZYTmTHmimisaAQW4WGLphN1cWhcC7KtnZF819', 'TEST', 'TEST', 2);
  Tokens.Add(TestToken);

  // Initialize mock RPC client
  MockRpcHttpClient := SetupTest('', 200, 'OK');
  RpcHttpClient := MockRpcHttpClient;

  UnusedRpc := TClientFactory.GetClient(TCluster.TestNet, RpcHttpClient);
  Batch := TSolanaRpcBatchWithCallbacks.Create(UnusedRpc);
  try
    // Test wallet setup
    OwnerWallet := TWallet.Create(MnemonicWords);
    Signer := OwnerWallet.GetAccountByIndex(1);
    PubKey := Signer.PublicKey.Key;
    AssertEquals('9we6kjtbcZ2vy3GSLLsZTEhbAqXPTRvEyoxa8wxSqKp5', PubKey);

    WalletPromise := TTokenWallet.Load(Batch, Tokens, PubKey);

    // Serialize batch and verify JSON
    Reqs := Batch.Composer.CreateJsonRequests;
    try
      AssertNotNull(Reqs);
      AssertEquals(2, Reqs.Count);

      Json := TTestUtils.Serialize<TJsonRpcBatchRequest>(Reqs);
      AssertJsonMatch(ExpectedReq, Json);

      // Fake RPC response
      Resp := CreateMockRequestResult<TJsonRpcBatchResponse>(
        ExpectedReq, ExpectedResp, 200);
      AssertNotNull(Resp.Result);
      AssertEquals(2, Resp.Result.Count);

      // Process and invoke callbacks - this unblocks WalletPromise
      BatchResp := Batch.Composer.ProcessBatchResponse(Resp);
      try
        Wallet := WalletPromise();

        // Assertions
        AssertEquals(168855000000, Wallet.Lamports);
        AssertEquals(168.855, Wallet.Sol, 0.01);
        AssertEquals(168.855000000, Wallet.Sol, 0.01);

        // Token assertions
        AssertEquals(10.0, Wallet.TokenAccounts.WithSymbol('TEST').First.QuantityDouble, 0.01);
        AssertEquals(10.0, Wallet.TokenAccounts.WithMint(TestToken).First.QuantityDouble, 0.01);
        AssertEquals(10.0, Wallet.TokenAccounts.WithAtLeast(10.0).First.QuantityDouble, 0.01);
        AssertEquals(10.0, Wallet.TokenAccounts.WithAtLeast(1000).First.QuantityDouble, 0.01);
        AssertEquals(10.0, Wallet.TokenAccounts.WithNonZero.First.QuantityDouble, 0.01);
      finally
        BatchResp.Free;
      end;
    finally
      Reqs.Free;
    end;
  finally
    Batch.Free;
  end;
end;

procedure TTokenWalletTests.TestTokenWalletFilterList;
var
  EmptyAccounts: TList<ITokenWalletAccount>;
  List         : ITokenWalletFilterList;
  Pass         : Boolean;
  Count        : Integer;
  It           : ITokenWalletAccount;
begin
  EmptyAccounts := TList<ITokenWalletAccount>.Create;
  try
    List := TTokenWalletFilterList.Create(EmptyAccounts);
    Pass := False;
    try
      List.WithPublicKey('');
    except
      on E: EArgumentException do
        Pass := True;
    end;

    try
      List.WithMint(ITokenDef(nil));
    except
      on E: EArgumentNilException do
        Pass := Pass and True;
    end;

    try
      List.WithCustomFilter(nil);
    except
      on E: EArgumentNilException do
        Pass := Pass and True;
    end;

    Count := 0;
    for It in List do
      Inc(Count);
    AssertEquals(0, Count);
    AssertTrue(Pass);
  finally
    EmptyAccounts.Free;
  end;
end;

initialization
{$IFDEF FPC}
  RegisterTest(TTokenWalletTests);
{$ELSE}
  RegisterTest(TTokenWalletTests.Suite);
{$ENDIF}

end.

