import { ethers } from "hardhat";

async function main() {
  const gasConsumer = await ethers.deployContract("Stake", { gasLimit: 5000000 });

  await gasConsumer.waitForDeployment();

  console.log(
    `Stake contract deployed to ${gasConsumer.target}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
