import { ethers } from "hardhat";
import artifact from "../artifacts/contracts/subnet-manager.sol/SubnetManager.json";
const abi = artifact.abi;

// SN manager contract address
const snmgrAddress = "0x414F36FCee4192e59F323440a0024e1d68680a2A";

async function main() {
  const [deployer] = await ethers.getSigners();
  const registrator = deployer;

  // Registrator signer (can be anyone)
  const snmgrReg = new ethers.Contract(snmgrAddress, abi, registrator);

  // Read accumulated owner cut
  const accumulatedOwnerCut = await snmgrReg.getOwnerStake();
  console.log(`accumulatedOwnerCut = ${accumulatedOwnerCut}`);

  // Read registrator's stake
  const registratorStakeBefore = await snmgrReg.registratorAccumulatedStake();
  console.log(`registratorStakeBefore = ${registratorStakeBefore}`);

  // Read developer's stake
  const developerStakeBefore = await snmgrReg.developerAccumulatedStake();
  console.log(`developerStakeBefore = ${developerStakeBefore}`);

  const tx1 = await snmgrReg.distributeRewards({ caller: registrator, gasLimit: 3_000_000 });
  await tx1.wait();
  console.log("Transaction confirmed:", tx1.hash);

  // Read registrator's stake after transaction
  const registratorStakeAfter = await snmgrReg.registratorAccumulatedStake();
  console.log(`registratorStakeAfter = ${registratorStakeAfter}`);

  // Read developer's stake after transaction
  const developerStakeAfter = await snmgrReg.developerAccumulatedStake();
  console.log(`developerStakeAfter = ${developerStakeAfter}`);

  // Check the distribution
  const registratorShare = registratorStakeAfter - registratorStakeBefore;
  const developerShare = developerStakeAfter - developerStakeBefore;
  const totalDistributed = registratorShare + developerShare;
  if (accumulatedOwnerCut != totalDistributed) {
    console.log(`ERROR: accumulatedOwnerCut (${accumulatedOwnerCut}) != totalDistributed (${totalDistributed})`);
  } else {
    console.log(`totalDistributed (${totalDistributed}) matches accumulatedOwnerCut - ok`);
  }

  console.log(`Registrator received ${Number(registratorShare) * 100 / Number(totalDistributed)}% of the cut`);
  console.log(`Developer received ${Number(developerShare) * 100 / Number(totalDistributed)}% of the cut`);

  console.log("Finished");
}

main().catch(console.error).finally(() => process.exit());
