// SPDX-License-Identifier: GPL-3.0
// 
// This example demonstrates calling of IStaking precompile 
// from another smart contract

pragma solidity 0.8.3;

import "./interfaces/ISubnet.sol";
import "./interfaces/IStakingV2.sol";

contract SubnetManager {
    // Precompile instances
    ISubnet public subnet;
    IStaking public staking;

    address public registrator;
    address public developer;
    bytes32 public subnetOwnerHotkey;
    bytes32 public registratorStakingHotkey;
    bytes32 public registratorStakingColdkey;
    bytes32 public developerStakingHotkey;
    bytes32 public developerStakingColdkey;
    uint16 public netuid;
    uint256 public registratorAccumulatedStake;
    bytes32 public thisSs58PublicKey;

    modifier onlyRegistrator() {
        require(registrator == msg.sender, "Caller is not the registrator");
        _;
    }

    modifier onlyDeveloper() {
        require(developer == msg.sender, "Caller is not the developer");
        _;
    }

    constructor(
        address _registrator,
        address _developer
    ) {
        require(_registrator != address(0) && _developer != address(0), "Invalid addresses");

        registrator = _registrator;
        developer = _developer;

        subnet = ISubnet(ISUBNET_ADDRESS);
        staking = IStaking(ISTAKING_ADDRESS);
    }

    // Registrator-only method to register a network
    function createSubnet(bytes32 hotkey) external onlyRegistrator() {
        require(subnetOwnerHotkey == 0, "Already registered");
        subnetOwnerHotkey = hotkey;
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.registerNetwork.selector, hotkey)
        );
        require(success, "Subnet creation call failed");
    }

    // Registrator-only method to set this contract address ss58 mirror public key
    // Solidity doesn't not have support for blake2b hash, neither there is a precompile
    // for this yet, so the public key for stake querying should be set manually.
    function setThisSs58PublicKey(bytes32 hotkey) external onlyRegistrator() {
        thisSs58PublicKey = hotkey;
    }

    // Set netuid manually because we don't get it in registration
    function setSubnetId(uint16 id) external onlyRegistrator() {
        netuid = id;
    }

    // Registrator can withdraw remaining balance
    function withdraw() external onlyRegistrator() {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    // Developer can set Kappa
    function setKappa(uint16 kappa) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setKappa.selector, netuid, kappa)
        );
        require(success, "SetKappa call failed");
    }

    // Allows registrator and developer to set hotkeys and coldkeys of their validators
    function setRegistratorStakingHotkey(bytes32 hotkey) external onlyRegistrator() {
        registratorStakingHotkey = hotkey;
    }
    function setRegistratorStakingColdkey(bytes32 coldkey) external onlyRegistrator() {
        registratorStakingColdkey = coldkey;
    }
    function setDeveloperStakingHotkey(bytes32 hotkey) external onlyDeveloper() {
        developerStakingHotkey = hotkey;
    }
    function setDeveloperStakingColdkey(bytes32 coldkey) external onlyRegistrator() {
        developerStakingColdkey = coldkey;
    }

    // Reward distribution logic
    function distribute_rewards() external {
        require(thisSs58PublicKey != 0, "Public key is not set");
        require(registratorStakingHotkey != 0 && developerStakingHotkey != 0, "Hotkeys are not set");
        require(registratorStakingColdkey != 0 && developerStakingColdkey != 0, "Coldkeys are not set");

        // First remove stake from both accounts
        uint256 pendingStake = staking.getStake(subnetOwnerHotkey, thisSs58PublicKey, netuid);

        // Decide proportion based on alpha stake threshold
        uint256 registratorShare;
        uint256 developerShare;
        
        // 420_000 is 2% of 21M
        if (registratorAccumulatedStake < 420_000_000_000_000_000_000_000) {
            registratorShare = pendingStake / 2; // 50%
            developerShare = pendingStake / 2; // 50%
        } else {
            registratorShare = (pendingStake * 20) / 100; // 20%
            developerShare = (pendingStake * 80) / 100; // 80%
        }

        // Move and then transfer stake proportions
        // Move sends the stake to the hotkey with the same (owner) coldkey
        // Transfer gives up the stake to another coldkey
        staking.moveStake(subnetOwnerHotkey, registratorStakingHotkey, netuid, netuid, registratorShare);
        staking.moveStake(subnetOwnerHotkey, developerStakingHotkey, netuid, netuid, developerShare);
        staking.transferStake(registratorStakingColdkey, registratorStakingHotkey, netuid, netuid, registratorShare);
        staking.transferStake(developerStakingColdkey, developerStakingHotkey, netuid, netuid, developerShare);

        registratorAccumulatedStake += registratorShare;
    }
}
