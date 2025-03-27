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
    bytes32 public registratorStakingColdkey;
    bytes32 public developerStakingColdkey;
    uint16 public netuid;
    uint256 public registratorAccumulatedStake;
    uint256 public developerAccumulatedStake;
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
    function setRegistratorStakingColdkey(bytes32 coldkey) external onlyRegistrator() {
        registratorStakingColdkey = coldkey;
    }
    function setDeveloperStakingColdkey(bytes32 coldkey) external onlyDeveloper() {
        developerStakingColdkey = coldkey;
    }

    function getOwnerStake() public view returns (uint256) {
        (bool success, bytes memory resultData) = ISTAKING_ADDRESS.staticcall(
            abi.encodeWithSelector(staking.getStake.selector, subnetOwnerHotkey, thisSs58PublicKey, netuid)
        );
        require(success, "Failed to read getStake");
        return abi.decode(resultData, (uint256));
    }

    function _transferStake(bytes32 destinationColdkey, bytes32 hotkey, uint256 amount) private {
        (bool success, ) = ISTAKING_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(staking.transferStake.selector, destinationColdkey, hotkey, netuid, netuid, amount)
        );
        require(success, "Move stake call failed");
    }

    // Reward distribution logic
    function distributeRewards() external {
        require(thisSs58PublicKey != 0, "Public key is not set");
        require(registratorStakingColdkey != 0 && developerStakingColdkey != 0, "Coldkeys are not set");

        // // First remove stake from both accounts
        uint256 pendingStake = getOwnerStake();

        // Decide proportion based on alpha stake threshold
        uint256 registratorShare;
        uint256 developerShare;
        
        // 420_000 is 2% of 21M
        // if (registratorAccumulatedStake < 420_000_000_000_000) {
        if (registratorAccumulatedStake < 100_000_000_000) {
            registratorShare = pendingStake / 2; // 50% / 50%
        } else {
            registratorShare = pendingStake / 5; // 20% / 80%
        }
        developerShare = pendingStake - registratorShare;

        // Move and then transfer stake proportions
        // Move sends the stake to the hotkey with the same (owner) coldkey
        // Transfer gives up the stake to another coldkey
        _transferStake(registratorStakingColdkey, subnetOwnerHotkey, registratorShare);
        _transferStake(developerStakingColdkey, subnetOwnerHotkey, developerShare);

        registratorAccumulatedStake += registratorShare;
        developerAccumulatedStake += developerShare;
    }
}
