// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PulendScript} from "../Pulend.s.sol";

/**
 * @title Deploy Router
 * @notice Step 4: Deploy Router contract (central coordination)
 * @dev Independent deployment step
 */
contract DeployRouter is Script, PulendScript {
    function run() public override {
        vm.startBroadcast(privateKey);
        _deployRouter();
        vm.stopBroadcast();
    }
}

// RUN
// forge script DeployRouter --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DeployRouter --broadcast -vvv
// forge script DeployRouter -vvv
