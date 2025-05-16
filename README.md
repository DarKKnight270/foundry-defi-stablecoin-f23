<<<<<<< HEAD
# foundry-defi-stablecoin-f23
A decentralized stablecoin protocol built in Solidity, with the exclusive help of cyfrin updraft's courses.
=======
## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
1. Relative Stability Anchored or Pegged -> $1.00
   Chainlink Price feed
   Set a function to exchange ETH and BTC -> $$$
2. Stability Mechanism (Minting): Algoritmic (Decentralized)
   People can only mint the stablecoin with enough collateral (coded)
3. Collateral: Exogenous (Crypto)
    wETH
    wBTC
>>>>>>> 81b49ad (Initial commit: stablecoin project)
