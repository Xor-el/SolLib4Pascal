<p align="center">
  <img src="assets/branding/logo.svg" width="160" alt="SolLib4Pascal logo" />
  <h1 align="center">SolLib4Pascal</h1>
  <p align="center">
    <strong>Solana blockchain SDK for Object Pascal</strong>
  </p>
  <p align="center">
    <!-- CI: uncomment when a GitHub Actions workflow exists for this repo.
    <a href="https://github.com/Xor-el/SolLib4Pascal/actions/workflows/make.yml"><img src="https://github.com/Xor-el/SolLib4Pascal/actions/workflows/make.yml/badge.svg" alt="Build Status"></a>
    -->
    <a href="https://github.com/Xor-el/SolLib4Pascal/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
    <a href="https://www.embarcadero.com/products/delphi"><img src="https://img.shields.io/badge/Delphi-10.4%2B-red.svg" alt="Delphi"></a>
  </p>
</p>

---

SolLib4Pascal is a Solana blockchain SDK for Object Pascal, providing JSON RPC clients, wallet management, transaction building, and program interfaces for seamless Solana integration in Delphi applications, released under the permissive [MIT License](https://github.com/Xor-el/SolLib4Pascal/blob/main/LICENSE).

## Table of Contents

- [Features](#features)
- [Available Programs](#available-programs)
- [Getting Started](#getting-started)
- [Quick Examples](#quick-examples)
- [Running Tests](#running-tests)
- [Contributing](#contributing)
- [Sponsors](#sponsors)
- [Tip Jar](#tip-jar)
- [License](#license)
- [Branding](assets/branding/README.md)

## Features

- **JSON RPC API** -- full coverage of Solana JSON RPC methods
- **Streaming JSON RPC API** -- WebSocket-based subscription support
- **Wallet and accounts** -- HD wallet derivation from mnemonic phrases
- **Keystore** -- secure key storage
- **Transaction encoding/decoding** -- base64 and wire format support
- **Message encoding/decoding** -- base64 and wire format support
- **Instruction decompilation** -- decode instructions back to structured data
- **Program interfaces** -- typed wrappers for native and SPL programs

## Available Programs

### Native Programs

`System Program`

### Loader Programs

`BPF Loader Program`

### Solana Program Library (SPL)

`Compute Budget Program` | `Address Lookup Table Program` | `Memo Program` | `Token Program` | `Token Swap Program` | `Associated Token Account Program` | `Shared Memory Program`

## Getting Started

### Prerequisites

| Compiler | Minimum Version |
| --- | --- |
| Delphi | 10.4 or later |

### Compile-Time Dependencies

- [SimpleBaseLib4Pascal](https://github.com/Xor-el/SimpleBaseLib4Pascal)
- [HashLib4Pascal](https://github.com/Xor-el/HashLib4Pascal)
- [CryptoLib4Pascal](https://github.com/Xor-el/CryptoLib4Pascal)

### Installation

Add the **SolLib** sources and its dependencies to your compiler search path.

## Quick Examples

### Fetch Balance and Send a Memo

```pascal
var
  LRpc: IRpcClient;
  LHttpClient: IHttpApiClient;
  LWallet: IWallet;
  LFrom: IAccount;
  LBlock: IRequestResult<TResponseValue<TLatestBlockHash>>;
  LBalance: IRequestResult<TResponseValue<UInt64>>;
  LTxBytes: TBytes;
  LSignature, LMnemonicWords: string;
  LBuilder: ITransactionBuilder;
  LPriorityFees: IPriorityFeesInformation;
begin
  LHttpClient := THttpApiClient.Create();
  LRpc    := TClientFactory.GetClient(TCluster.MainNet, LHttpClient);

  LMnemonicWords := 'Your Mnemonic Words';
  LWallet := TWallet.Create(LMnemonicWords);
  LFrom   := LWallet.GetAccountByIndex(0);

  // Get balance
  LBalance := LRpc.GetBalance(LFrom.PublicKey.Key);
  if LBalance.WasSuccessful then
    Writeln(Format('Balance: %d lamports', [LBalance.Result.Value]))
  else
    Writeln('Balance: <unavailable>');

  LBlock := LRpc.GetLatestBlockHash;
  if (LBlock = nil) or (not LBlock.WasSuccessful) or (LBlock.Result = nil) then
    raise Exception.Create('Failed to fetch recent blockhash.');

  // Build priority fee information
  LPriorityFees := TPriorityFeesInformation.Create(
    TComputeBudgetProgram.SetComputeUnitLimit(400000), // limit
    TComputeBudgetProgram.SetComputeUnitPrice(100000)  // price (micro-lamports)
  );

  // Build transaction (Send a simple memo transaction)
  LBuilder := TTransactionBuilder.Create;
  LTxBytes :=
    LBuilder
      .SetRecentBlockHash(LBlock.Result.Value.Blockhash)
      .SetFeePayer(LFrom.PublicKey)
      .SetPriorityFeesInformation(LPriorityFees)
      .AddInstruction(TMemoProgram.NewMemo(LFrom.PublicKey, 'Hello from SolLib'))
      .Build(LFrom);

  LSignature := LRpc.SendTransaction(LTxBytes);
  Writeln(Format('Transaction Signature: %s', [LSignature]));
end;
```

## Running Tests

Tests are provided for Delphi.

- **Delphi:** Open and run `SolLib.Tests/Delphi.Tests/SolLib.Tests.dpr` in the IDE.

Additional samples can be found in the `SolLib.Examples` folder.

## Contributing

Contributions are welcome. Please open an [issue](https://github.com/Xor-el/SolLib4Pascal/issues) for bug reports or feature requests, and submit pull requests.

## Sponsors

- [InstallAware](https://www.installaware.com/)

## Tip Jar

If you find this library useful and would like to support its continued development, tips are greatly appreciated! 🙏

| Cryptocurrency | Wallet Address |
|---|---|
| <img src="https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/32/icon/btc.png" width="20" alt="Bitcoin" /> **Bitcoin (BTC)** | `bc1quqhe342vw4ml909g334w9ygade64szqupqulmu` |
| <img src="https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/32/icon/eth.png" width="20" alt="Ethereum" /> **Ethereum (ETH)** | `0x53651185b7467c27facab542da5868bfebe2bb69` |
| <img src="https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/32/icon/sol.png" width="20" alt="Solana" /> **Solana (SOL)** | `BPZHjY1eYCdQjLecumvrTJRi5TXj3Yz1vAWcmyEB9Miu` |

## License

This project is licensed under the [MIT License](https://github.com/Xor-el/SolLib4Pascal/blob/main/LICENSE).