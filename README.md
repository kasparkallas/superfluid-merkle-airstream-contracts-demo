## Superfluid Merkle Airstream demo contract

The following is a proof of concept smart contract _demo_ of how to achieve merkle tree "airstream" capability using the Superfluid Protocol along with the Superfluid VestingSchedulerV2 contract.

1. A merkle tree is deployed with recipients and amounts.
2. A recipient claims their amounts by providing the proof. A Superfluid flow/stream is created for during claiming using the Superfluid VestingSchedulerV2 contract. The vesting schedule will show up in the recipients Superfluid Dashboard view.
3. An automation system (not included here) will finalize the vesting schedule when it's the right time defined by the vesting schedule, doing it through invoking VestingSchedulerV2, which only allows execution following the rules set by the vesting schedule.

UI demo: https://superfluid-merkle-airdrop-demo.vercel.app/

## Foundry (original auto-scaffolded readme)

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
