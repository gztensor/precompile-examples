// SPDX-License-Identifier: GPL-3.0
// 
// This example demonstrates calling of IStaking precompile 
// from another smart contract

pragma solidity ^0.8.3;

address constant ISUBTENSOR_STAKING_ADDRESS = 0x0000000000000000000000000000000000000801;
bytes32 constant HOTKEY = 0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d; // ALICE
uint256 constant NETUID = 1;

interface IStaking {
    function addStake(bytes32 hotkey, uint256 netuid) external payable;
    function removeStake(bytes32 hotkey, uint256 amount, uint256 netuid) external;
}

contract Stake {
    function stake_from_this_contract_to_alice() external payable {
        IStaking stakingPrecompile = IStaking(ISUBTENSOR_STAKING_ADDRESS);
        (bool success, ) = ISUBTENSOR_STAKING_ADDRESS.call{value: msg.value}(
            abi.encodeWithSelector(stakingPrecompile.addStake.selector, HOTKEY, NETUID)
        );
        require(success, "Staking call failed");
    }

    function unstake_from_alice_to_this_contract() external {
        uint256 amount = 1000000000000;
        IStaking stakingPrecompile = IStaking(ISUBTENSOR_STAKING_ADDRESS);
        stakingPrecompile.removeStake(HOTKEY, amount, NETUID);

        //(bool success, ) = ISUBTENSOR_STAKING_ADDRESS.call(
        //    abi.encodeWithSelector(stakingPrecompile.removeStake.selector, HOTKEY, amount, NETUID)
        //);
        //require(success, "Unstaking call failed");

    }
}
