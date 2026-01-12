// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PulendScript} from "../Pulend.s.sol";

/**
 * @title Deploy Proxy
 * @notice Step 9: Deploy LendingPool proxy and configure initial settings
 * @dev Dependencies: Steps 1, 4, 6 (CryptoPunks, Router, LendingPool Implementation)
 */
contract DeployProxy is Script, PulendScript {
    function run() public override {
        vm.startBroadcast(privateKey);
        _getUtils();
        _deployProxy();
        vm.stopBroadcast();
    }
}

// RUN
// forge script DeployProxy --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DeployProxy --broadcast -vvv
// forge script DeployProxy -vvv
