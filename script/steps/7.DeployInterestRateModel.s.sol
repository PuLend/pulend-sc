// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PulendScript} from "../Pulend.s.sol";

/**
 * @title Deploy Interest Rate Model
 * @notice Step 7: Deploy InterestRateModel implementation and proxy
 * @dev Dependency: Step 4 (Router)
 */
contract DeployInterestRateModel is Script, PulendScript {
    function run() public override {
        vm.startBroadcast(privateKey);
        _deployInterestRateModel();
        vm.stopBroadcast();
    }
}

// RUN
// forge script DeployInterestRateModel --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DeployInterestRateModel --broadcast -vvv
// forge script DeployInterestRateModel -vvv
