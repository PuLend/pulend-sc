// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PulendScript} from "../Pulend.s.sol";

/**
 * @title Set Price Feed
 * @notice Step 3: Configure price feeds for all tokens
 * @dev Dependencies: Steps 0 (tokens), 2 (TokenDataStream)
 */
contract SetPriceFeed is Script, PulendScript {
    function run() public override {
        vm.startBroadcast(privateKey);
        _getUtils();
        _setPricefeed();
        vm.stopBroadcast();
    }
}

// RUN
// forge script SetPriceFeed --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script SetPriceFeed --broadcast -vvv
// forge script SetPriceFeed -vvv
