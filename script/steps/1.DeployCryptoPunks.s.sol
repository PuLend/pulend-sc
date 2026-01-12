// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PulendScript} from "../Pulend.s.sol";

/**
 * @title Deploy CryptoPunks
 * @notice Step 1: Deploy CryptoPunks NFT contract
 * @dev Independent deployment step
 */
contract DeployCryptoPunks is Script, PulendScript {
    function run() public override {
        vm.startBroadcast(privateKey);
        _deployCryptoPunks();
        vm.stopBroadcast();
    }
}

// RUN
// forge script DeployCryptoPunks --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DeployCryptoPunks --broadcast -vvv
// forge script DeployCryptoPunks -vvv
