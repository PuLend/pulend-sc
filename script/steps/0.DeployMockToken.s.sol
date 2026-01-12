// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PulendScript} from "../Pulend.s.sol";

/**
 * @title Deploy Mock Tokens
 * @notice Step 0: Deploy mock ERC20 tokens (USDC, WETH, WBTC)
 * @dev This is the first deployment step with no dependencies
 */
contract DeployMockToken is Script, PulendScript {
    function run() public override {
        vm.startBroadcast(privateKey);
        _deployMockToken();
        vm.stopBroadcast();
    }
}

// RUN
// forge script DeployMockToken --broadcast -vvv --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
// forge script DeployMockToken --broadcast -vvv
// forge script DeployMockToken -vvv
