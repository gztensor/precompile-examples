import { ethers } from "hardhat";
import { blake2AsU8a, encodeAddress, decodeAddress } from "@polkadot/util-crypto";
import { hexToU8a, u8aToHex } from "@polkadot/util";
import { createApi } from "./setup";
const { Keyring } = require('@polkadot/api');

// Make sure this hotkey doesn't exist on the network, otherwise creation tx will fail
const subnetOwnerHotkey = "5CiPPseXPECbkjWCa6MnjNokrgYjMqmKndv2rSnekmSK2DjL"; // Ferdie
const subnetOwnerColdkeySeed = "//Alice";

const blockTime = 1000;

/**
 * This function deploys the SubnetManager contract, then it configures it 
 * and call to create the subnet in the following sequence:
 * 
 *   - Deploy the contract
 *   - Set public key of this contract (for stake balance)
 *   - Call createSubnet
 * 
 * 
 * 
 */
async function main() {
  const api = await createApi();

  const [deployer, developerAcc] = await ethers.getSigners();

  const registrator = deployer.address;
  const developer = developerAcc.address; // replace with actual dev address

  // // Deploy the contract
  const snmgr = await ethers.deployContract(
    "SubnetManager",
    [registrator, developer],
    { gasLimit: 5_000_000 }
  );
  await snmgr.waitForDeployment();
  const snmgrAddress = snmgr.target;
  console.log(`SubnetManager contract deployed to ${snmgrAddress}`);
  const checkRegistrator = await snmgr.registrator();
  console.log(`Registrator address: ${checkRegistrator}`)
  const checkDeveloper = await snmgr.developer();
  console.log(`Developer address: ${checkDeveloper}`)

  // Set public key of this contract (for stake balance)
  const ss58Mirror = convertH160ToSS58(snmgrAddress);
  console.log(`SS58 Mirror address of this contract: ${ss58Mirror}`);
  const ss58MirrorPubKey = decodeAddress(ss58Mirror);
  const ss58MirrorPubKeyHex = u8aToHex(ss58MirrorPubKey);
  console.log(`SS58 Mirror public key: ${ss58MirrorPubKeyHex}`);
  await snmgr.setThisSs58PublicKey(ss58MirrorPubKeyHex, { caller: registrator, gasLimit: 5_000_000 });
  await sleep(blockTime);
  const checkPubKey = await snmgr.thisSs58PublicKey();
  console.log(`Mirror public key set (${checkPubKey})`);

  // Call createSubnet
  const newNetuid = await createSubnet(api, snmgr, ss58Mirror, registrator);

  // Set netuid in the contract
  console.log(`Setting netuid in the contract...`);
  await snmgr.setSubnetId(newNetuid, { caller: registrator, gasLimit: 5_000_000 });
  await sleep(blockTime);
  const checkNetuid = await snmgr.netuid();
  console.log(`Netuid set (${checkNetuid})`);

  // Register registrator's validator

  // Set registrator and developer validators' keys

  console.log("Finished");
}

async function createSubnet(api: any, snmgr: any, ss58Mirror: any, registrator: any) {
  // Get the subnet creation cost
  const lockCost = (await get_network_lock_cost(api)) + 500;
  console.log(`Network lock cost is ${lockCost / 1e9} TAO. Transferring this amount+ED to this contract's ss58 mirror (${ss58Mirror}).`);
  console.log(lockCost.toFixed(0));
  const tx = api.tx.balances.transferKeepAlive(ss58Mirror, lockCost.toFixed(0));
  const keyring = new Keyring({ type: 'sr25519' });
  const snOwner = keyring.addFromUri(subnetOwnerColdkeySeed);
  await sendTransaction(api, tx, snOwner);
  await sleep(blockTime);

  // Get the existing netuids
  let i = 0;
  let exists = true;
  let netuids = [];
  while (exists) {
    exists = (await api.query.subtensorModule.networksAdded(i)).toJSON()?.valueOf();
    if (exists) {
      // console.log(`Netuid ${i} already registered`);
      netuids.push(i);
    }
    i++;
  }

  // Call createSubnet
  const subnetOwnerPublicKey = u8aToHex(decodeAddress(subnetOwnerHotkey));
  console.log(`Registering subnet...`);
  await snmgr.createSubnet(subnetOwnerPublicKey, {caller: registrator, gasLimit: 3_000_000});
  await sleep(blockTime);
  console.log(`Subnet created`);
  const snOwnerCheck = await snmgr.subnetOwnerHotkey();
  console.log(`Subnet owner hotkey: ${snOwnerCheck}`);

  // Get the new netuid
  i = 0;
  exists = true;
  let newNetuid;
  while (exists) {
    exists = (await api.query.subtensorModule.networksAdded(i)).toJSON()?.valueOf();
    if (exists) {
      if (!(i in netuids)) {
        newNetuid = i;
        console.log(`New netuid: ${newNetuid}`);
        break;
      }
    }
    i++;
  }

  return newNetuid;
}

async function get_network_lock_cost(api: any) {
  let last_lock = await api.query.subtensorModule.networkLastLockCost();
  let min_lock = await api.query.subtensorModule.networkMinLockCost();
  let last_lock_block = await api.query.subtensorModule.networkLastRegistered();
  let current_block = (await api.rpc.chain.getHeader()).number;
  let lock_reduction_interval = await api.query.subtensorModule.networkLockReductionInterval();
  let mult = 1;
  if (last_lock_block != 0) {
    mult = 2;
  }

  let lock_cost = last_lock * mult - last_lock / lock_reduction_interval * (current_block - last_lock_block);

  if (lock_cost < min_lock) {
      lock_cost = min_lock;
  }

  return parseInt(lock_cost);
}

/**
 * Converts an Ethereum H160 address to a Substrate SS58 address public key.
 * @param {string} ethAddress - The H160 Ethereum address as a hex string.
 * @return {string} The bytes array containing the Substrate public key.
 */
function convertH160ToSS58(ethAddress: string) {
  const prefix = 'evm:';
  const prefixBytes = new TextEncoder().encode(prefix);
  const addressBytes = hexToU8a(ethAddress.startsWith('0x') ? ethAddress : `0x${ethAddress}`);
  const combined = new Uint8Array(prefixBytes.length + addressBytes.length);

  // Concatenate prefix and Ethereum address
  combined.set(prefixBytes);
  combined.set(addressBytes, prefixBytes.length);

  // Hash the combined data (the public key)
  const hash = blake2AsU8a(combined);

  // Convert the hash to SS58 format
  const ss58Address = encodeAddress(hash, 42); // Assuming network ID 42, change as per your network
  return ss58Address;
}

function sendTransaction(api: any, call: any, signer: any) {
  return new Promise((resolve, reject) => {
    let unsubscribed = false;

    const unsubscribe = call.signAndSend(signer, ({ status, events, dispatchError }) => {
      const safelyUnsubscribe = () => {
        if (!unsubscribed) {
          unsubscribed = true;
          unsubscribe.then(() => {})
            .catch(error => console.error('Failed to unsubscribe:', error));
        }
      };
      
      // Check for transaction errors
      if (dispatchError) {
        let errout = dispatchError.toString();
        if (dispatchError.isModule) {
          // for module errors, we have the section indexed, lookup
          const decoded = api.registry.findMetaError(dispatchError.asModule);
          const { docs, name, section } = decoded;
          errout = `${name}: ${docs}`;
        }
        safelyUnsubscribe();
        reject(Error(errout));
      }
      // Log and resolve when the transaction is included in a block
      if (status.isInBlock) {
        safelyUnsubscribe();
        resolve(status.asInBlock);
      }
    }).catch((error) => {
      reject(error);
    });
  });
}

function sleep(ms: any) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

main().catch(console.error).finally(() => process.exit());