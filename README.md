# Example of interaction with BitTensor EVM precompiles

## Setup

0. Install dependencies
```
yarn install
```

1. Copy `secrets.example.ts` to `secrets.ts` and insert private keys for the accounts that have adequate balance for deploying and calling the smart contracts.

2. Setup network:
```
npx hardhat run src/network-setup.ts
```

3. Deploy a contract (example):
```
npx hardhat run src/deploy.ts
```

## Testing on local devnet

1. Run the local BitTensor chain and wait until it builds and starts producing blocks

2. Send some testnet currency to your accounts in secrets.ts file:

```
npx hardhat run src/fill_accounts.ts
```

3. Run tests
```
npx hardhat test
```
