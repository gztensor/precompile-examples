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
    function createSubnet(
        bytes32 hotkey,
        string memory subnetName,
        string memory githubRepo,
        string memory subnetContact,
        string memory subnetUrl,
        string memory discord,
        string memory description,
        string memory additional
    ) external onlyRegistrator() {
        require(subnetOwnerHotkey == 0, "Already registered");
        subnetOwnerHotkey = hotkey;
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(
                subnet.registerNetwork.selector,
                hotkey,
                subnetName,
                githubRepo,
                subnetContact,
                subnetUrl,
                discord,
                description,
                additional
            )
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

    function setServingRateLimit(uint64 servingRateLimit) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setServingRateLimit.selector, netuid, servingRateLimit)
        );
        require(success, "setServingRateLimit call failed");
    }

    function setMinDifficulty(uint64 minDifficulty) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setMinDifficulty.selector, netuid, minDifficulty)
        );
        require(success, "setMinDifficulty call failed");
    }

    function setMaxDifficulty(uint64 maxDifficulty) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setMaxDifficulty.selector, netuid, maxDifficulty)
        );
        require(success, "setMaxDifficulty call failed");
    }

    function setWeightsVersionKey(uint64 weightsVersionKey) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setWeightsVersionKey.selector, netuid, weightsVersionKey)
        );
        require(success, "setWeightsVersionKey call failed");
    }

    function setWeightsSetRateLimit(uint64 weightsSetRateLimit) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setWeightsSetRateLimit.selector, netuid, weightsSetRateLimit)
        );
        require(success, "setWeightsSetRateLimit call failed");
    }

    function setAdjustmentAlpha(uint64 adjustmentAlpha) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setAdjustmentAlpha.selector, netuid, adjustmentAlpha)
        );
        require(success, "setAdjustmentAlpha call failed");
    }

    function setMaxWeightLimit(uint16 maxWeightLimit) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setMaxWeightLimit.selector, netuid, maxWeightLimit)
        );
        require(success, "setMaxWeightLimit call failed");
    }

    function setImmunityPeriod(uint64 immunityPeriod) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setImmunityPeriod.selector, netuid, immunityPeriod)
        );
        require(success, "setImmunityPeriod call failed");
    }

    function setMinAllowedWeights(uint16 minAllowedWeights) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setMinAllowedWeights.selector, netuid, minAllowedWeights)
        );
        require(success, "setMinAllowedWeights call failed");
    }

    function setRho(uint16 rho) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setRho.selector, netuid, rho)
        );
        require(success, "setRho call failed");
    }

    function setActivityCutoff(uint16 activityCutoff) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setActivityCutoff.selector, netuid, activityCutoff)
        );
        require(success, "setActivityCutoff call failed");
    }

    function setNetworkRegistrationAllowed(bool networkRegistrationAllowed) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setNetworkRegistrationAllowed.selector, netuid, networkRegistrationAllowed)
        );
        require(success, "setNetworkRegistrationAllowed call failed");
    }

    function setNetworkPowRegistrationAllowed(bool networkPowRegistrationAllowed) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setNetworkPowRegistrationAllowed.selector, netuid, networkPowRegistrationAllowed)
        );
        require(success, "setNetworkPowRegistrationAllowed call failed");
    }

    function setMinBurn(uint64 minBurn) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setMinBurn.selector, netuid, minBurn)
        );
        require(success, "setMinBurn call failed");
    }

    function setMaxBurn(uint64 maxBurn) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setMaxBurn.selector, netuid, maxBurn)
        );
        require(success, "setMaxBurn call failed");
    }

    function setDifficulty(uint64 difficulty) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setDifficulty.selector, netuid, difficulty)
        );
        require(success, "setDifficulty call failed");
    }

    function setBondsMovingAverage(uint64 bondsMovingAverage) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setBondsMovingAverage.selector, netuid, bondsMovingAverage)
        );
        require(success, "setBondsMovingAverage call failed");
    }

    function setCommitRevealWeightsEnabled(bool commitRevealWeightsEnabled) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setCommitRevealWeightsEnabled.selector, netuid, commitRevealWeightsEnabled)
        );
        require(success, "setCommitRevealWeightsEnabled call failed");
    }

    function setLiquidAlphaEnabled(bool liquidAlphaEnabled) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setLiquidAlphaEnabled.selector, netuid, liquidAlphaEnabled)
        );
        require(success, "setLiquidAlphaEnabled call failed");
    }

    function setAlphaValues(
        uint16 alphaLow,
        uint16 alphaHigh
    ) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setAlphaValues.selector, netuid, alphaLow, alphaHigh)
        );
        require(success, "setAlphaValues call failed");
    }

    function setCommitRevealWeightsInterval(uint64 commitRevealWeightsInterval) external onlyDeveloper() {
        (bool success, ) = ISUBNET_ADDRESS.call{gas: gasleft()}(
            abi.encodeWithSelector(subnet.setCommitRevealWeightsInterval.selector, netuid, commitRevealWeightsInterval)
        );
        require(success, "setCommitRevealWeightsInterval call failed");
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
