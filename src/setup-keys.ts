import { ethers } from "hardhat";
import { decodeAddress } from "@polkadot/util-crypto";
import artifact from "../artifacts/contracts/subnet-manager.sol/SubnetManager.json";
const abi = artifact.abi;

// SN manager contract address
const snmgrAddress = "0x414F36FCee4192e59F323440a0024e1d68680a2A";

// Replace this with validator coldkeys and hotkeys
const registratorColdkey = "5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty"; // Bob
const developerColdkey = "5FLSigC9HGRKVhB9FiEo4Y3koPsNmBmLJbpXg2mp1hXcS59Y"; // Charlie

async function main() {
  const [deployer, developerAcc] = await ethers.getSigners();

  const registrator = deployer;
  const developer = developerAcc;

  // Setup registrator's validator
  const snmgrReg = new ethers.Contract(snmgrAddress, abi, registrator);
  const pubkeyRegistratorCold = decodeAddress(registratorColdkey);

  const tx1 = await snmgrReg.setRegistratorStakingColdkey(pubkeyRegistratorCold);
  await tx1.wait();
  console.log("Transaction confirmed:", tx1.hash);
  
  // Setup developer's validator
  const snmgrDev = new ethers.Contract(snmgrAddress, abi, developer);
  const pubkeyDeveloperCold = decodeAddress(developerColdkey);

  const tx2 = await snmgrDev.setDeveloperStakingColdkey(pubkeyDeveloperCold);
  await tx2.wait();
  console.log("Transaction confirmed:", tx2.hash);

  console.log("Finished");
}

main().catch(console.error).finally(() => process.exit());
