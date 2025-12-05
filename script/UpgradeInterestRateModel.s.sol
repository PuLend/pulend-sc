// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {InterestRateModel} from "../src/InterestRateModel.sol";

/**
 * @title UpgradeInterestRateModelScript
 * @notice Script to upgrade the InterestRateModel contract to a new implementation
 * @dev This script:
 *      1. Deploys a new InterestRateModel implementation
 *      2. Upgrades the existing proxy to point to the new implementation
 *      3. Requires UPGRADER_ROLE on the proxy contract
 *
 * Usage:
 *   forge script script/UpgradeInterestRateModel.s.sol --broadcast --verify --verifier blockscout -vvv
 *   forge script script/UpgradeInterestRateModel.s.sol
 *
 * Environment Variables Required:
 *   - PRIVATE_KEY: Deployer private key (must have UPGRADER_ROLE)
 *   - INTEREST_RATE_MODEL_PROXY: Address of the existing InterestRateModel proxy
 */
contract UpgradeInterestRateModelScript is Script {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("story_testnet"));
    }

    function run() public {
        // Load environment variables
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = 0xa89Ff50f77A59D6a175c738C3F705B5401BcEbc0;

        address deployer = vm.addr(privateKey);
        console.log("Deployer:", deployer);
        console.log("Proxy Address:", proxyAddress);

        vm.startBroadcast(privateKey);

        // Step 1: Deploy new implementation
        console.log("\n=== Deploying New InterestRateModel Implementation ===");
        InterestRateModel newImplementation = new InterestRateModel();
        console.log("New Implementation deployed at:", address(newImplementation));

        // Step 2: Get the proxy contract instance
        InterestRateModel proxy = InterestRateModel(payable(proxyAddress));

        // Step 3: Upgrade the proxy to the new implementation
        console.log("\n=== Upgrading Proxy ===");
        console.log("Upgrading proxy from old implementation to new implementation...");

        // upgradeToAndCall with empty data (no initialization needed)
        proxy.upgradeToAndCall(address(newImplementation), "");

        console.log("Upgrade completed successfully!");
        console.log("\n=== Verification ===");
        console.log("Proxy Address:", proxyAddress);
        console.log("New Implementation:", address(newImplementation));

        // Verify the upgrade by calling a view function
        uint256 scaledPercentage = proxy.scaledPercentage();
        console.log("ScaledPercentage (verification):", scaledPercentage);

        vm.stopBroadcast();
    }
}

