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

6. Register validators

- Set netuid in src/register-validators.ts
- Fund validator coldkeys (Bob and Charlie for testing). Then execute
```
npx hardhat run src/register-validators.ts
```

7. Set registrator and developer hotkeys in smart contract

- Set contract address in setup-keys.ts
- Set public keys for validaotrs in setup-keys.ts and run
```
npx hardhat run src/setup-keys.ts
```

8. Wait until subnet owner emissions accumulate on the contract address and call distributeRewards in the contract

- The deploy script outputs the contract mirror address like this:
```
SS58 Mirror address of this contract: 5GBDecCfCQHfuaf16Gb9V13qwFiKJLGnfmoPm3EG2E2zj89x
```
This address will be the subnet owner coldkey.
The subnet owner hotkey is set in step 4 (It is Dave for testing: 5CiPPseXPECbkjWCa6MnjNokrgYjMqmKndv2rSnekmSK2DjL)
The hotkey can be monitored for subnet owner stake (which will be transferred by the distributeRewards method).

In order to distribute rewards:

- Fill the contract address in distribute-rewards.ts and run
```
npx hardhat run src/distribute-rewards.ts
```

9. Setting hyperparameters (developer only)

- Run
```
npx hardhat run src/set-hyperparameters.ts
```
- Verify Kappa using Polkadot AppsUI

