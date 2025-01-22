import { expect } from "chai";
import { ethers } from "hardhat";
import { HardhatEthersProvider } from "@nomicfoundation/hardhat-ethers/internal/hardhat-ethers-provider";
import { constants } from '@unique-nft/solidity-interfaces';
import { Stake } from "../typechain-types/Stake";
import BigNumber from 'bignumber.js';
BigNumber.config({ DECIMAL_PLACES: 0, ROUNDING_MODE: BigNumber.ROUND_DOWN, EXPONENTIAL_AT: 255 });

describe("Stake contract", function () {
  let stakeContract: Stake;
  let gasPrice: BigNumber;
  let provider: HardhatEthersProvider;
  let caller: any;
  let gasParameters: {
    gasLimit: ethers.BigNumber,
    maxFeePerGas: ethers.BigNumber,
    maxPriorityFeePerGas: ethers.BigNumber,
  } = {
    gasLimit: 500000,
    maxFeePerGas: ethers.parseUnits("10", "gwei"),
    maxPriorityFeePerGas: ethers.parseUnits("10", "gwei"),
  };

  before(async () => {
    stakeContract = await ethers.deployContract("Stake", gasParameters);
    await stakeContract.waitForDeployment();
    // stakeContract = await ethers.getContractAt("Stake", "0xE6d5fE09D078ba87e67e5De961Bee4fbe1178d38");
    console.log(`Contract deployed at address: ${await stakeContract.getAddress()}`);
  });

  it("Call stake_from_this_contract_to_alice", async () => {
    const tx = await stakeContract.stake_from_this_contract_to_alice({ ...gasParameters, value: ethers.parseEther("0.1") });

    // Wait for the transaction to be mined
    const receipt = await tx.wait();
    console.log(receipt);
  });

  it("Call unstake_from_alice_to_this_contract", async () => {
    const tx = await stakeContract.unstake_from_alice_to_this_contract(gasParameters);

    // Wait for the transaction to be mined
    const receipt = await tx.wait();
    console.log(receipt);
  });

});
