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

3. Build contracts:
```
npx hardhat compile
```

4. Deploy a contract (example):
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

## Testing Subnet Manager locally

1. `yarn install`
2. `npx hardhat compile`
3. Launch a local network with ./scripts/localnet.sh
4. Do preliminary setup 
4.1 
```
npx hardhat run src/fill_accounts.ts
npx hardhat run src/network-setup.ts
```
4.2 Set your subnetOwnerHotkey in src/deploy-subnet-manager.ts
Important: It will become a neuron on the subnet with uid 0, so it is important to have the private key for it.

5. Run the deploy script. It will deploy the contract and perform self-diagnostics.
```
npx hardhat run src/deploy-subnet-manager.ts
```
