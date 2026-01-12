// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PulendScript} from "../Pulend.s.sol";

/**
 * @title Deploy IsHealthy
 * @notice Step 5: Deploy IsHealthy contract for health factor calculation
 * @dev Dependency: Step 4 (Router)
 */
contract DeployIsHealthy is Script, PulendScript {
    function run() public override {
        vm.startBroadcast(privateKey);
        _getUtils();
        _deployAndSetIsHealthy();
        vm.stopBroadcast();
    }
}

// RUN
// forge script DeployIsHealthy --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DeployIsHealthy --broadcast -vvv
// forge script DeployIsHealthy -vvv
