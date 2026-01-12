// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PulendScript} from "../Pulend.s.sol";

/**
 * @title Tweaking IsHealthy
 * @notice Step 11: Set liquidation threshold and bonus parameters
 * @dev Dependencies: Steps 5, 9 (IsHealthy, LendingPool Proxy)
 */
contract TweakingIsHealthy is Script, PulendScript {
    function run() public override {
        vm.startBroadcast(privateKey);
        _getUtils();
        _tweakingIsHealthy();
        vm.stopBroadcast();
    }
}

// RUN
// forge script TweakingIsHealthy --broadcast -vvv
// forge script TweakingIsHealthy -vvv
