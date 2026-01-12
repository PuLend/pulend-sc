// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PulendScript} from "../Pulend.s.sol";

/**
 * @title Deploy Token Data Stream
 * @notice Step 2: Deploy TokenDataStream oracle/price feed system
 * @dev Independent deployment step
 */
contract DeployTokenDataStream is Script, PulendScript {
    function run() public override {
        vm.startBroadcast(privateKey);
        _deployTokenDataStream();
        vm.stopBroadcast();
    }
}

// RUN
// forge script DeployTokenDataStream --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DeployTokenDataStream --broadcast -vvv
// forge script DeployTokenDataStream -vvv
