// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PulendScript} from "../Pulend.s.sol";

/**
 * @title Deploy LendingPool Implementation
 * @notice Step 6: Deploy LendingPool implementation contract
 * @dev Independent deployment step (proxy deployed later)
 */
contract DeployLendingPoolImplementation is Script, PulendScript {
    function run() public override {
        vm.startBroadcast(privateKey);
        _deployImplementation();
        vm.stopBroadcast();
    }
}

// RUN
// forge script DeployLendingPoolImplementation --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DeployLendingPoolImplementation --broadcast -vvv
// forge script DeployLendingPoolImplementation -vvv
