import { ethers } from "hardhat";
import artifact from "../artifacts/contracts/subnet-manager.sol/SubnetManager.json";
const abi = artifact.abi;

// SN manager contract address
const snmgrAddress = "0x414F36FCee4192e59F323440a0024e1d68680a2A";

async function main() {
  const [_, developerAcc] = await ethers.getSigners();
  const developer = developerAcc;

  // Registrator signer (can be anyone)
  const snmgrDev = new ethers.Contract(snmgrAddress, abi, developer);

  const tx1 = await snmgrDev.setKappa(54321);
  await tx1.wait();
  console.log("Transaction confirmed:", tx1.hash);

  console.log("Finished");
}

main().catch(console.error).finally(() => process.exit());
