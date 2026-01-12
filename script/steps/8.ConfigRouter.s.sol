// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PulendScript} from "../Pulend.s.sol";

/**
 * @title Configure Router
 * @notice Step 8: Connect Router with TokenDataStream, IsHealthy, and InterestRateModel
 * @dev Dependencies: Steps 2, 4, 5, 7
 */
contract ConfigRouter is Script, PulendScript {
    function run() public override {
        vm.startBroadcast(privateKey);
        _getUtils();
        _configRouter();
        vm.stopBroadcast();
    }
}

// RUN
// forge script ConfigRouter --broadcast -vvv
// forge script ConfigRouter -vvv
