// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PulendScript} from "../Pulend.s.sol";

/**
 * @title Tweaking Interest Rate Model
 * @notice Step 10: Set interest rate parameters (base rate, optimal utilization, etc.)
 * @dev Dependencies: Steps 7, 9 (InterestRateModel, LendingPool Proxy)
 */
contract TweakingInterestRateModel is Script, PulendScript {
    function run() public override {
        vm.startBroadcast(privateKey);
        _getUtils();
        _tweakingInterestRateModel();
        vm.stopBroadcast();
    }
}

// RUN
// forge script TweakingInterestRateModel --broadcast -vvv
// forge script TweakingInterestRateModel -vvv
