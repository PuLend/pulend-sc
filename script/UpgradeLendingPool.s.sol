// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {LendingPool} from "../src/LendingPool.sol";

/**
 * @title UpgradeLendingPoolScript
 * @notice Script to upgrade the LendingPool contract to a new implementation
 * @dev This script:
 *      1. Deploys a new LendingPool implementation
 *      2. Upgrades the existing proxy to point to the new implementation
 *      3. Requires UPGRADER_ROLE on the proxy contract
 *
 * Usage:
 *   forge script script/UpgradeLendingPool.s.sol --broadcast --verify --verifier blockscout --verifier-url 'https://aeneid.storyscan.io/api/' -vvv
 *   forge script script/UpgradeLendingPool.s.sol --broadcast --verify --verifier blockscout
 *   forge script script/UpgradeLendingPool.s.sol
 *
 * Environment Variables Required:
 *   - PRIVATE_KEY: Deployer private key (must have UPGRADER_ROLE)
 *   - LENDING_POOL_PROXY: Address of the existing LendingPool proxy
 */
contract UpgradeLendingPoolScript is Script {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("story_testnet"));
    }

    function run() public {
        // Load environment variables
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = 0x848fDD471ebad6CFD8AfBfB58ba243782AD9201C;

        address deployer = vm.addr(privateKey);
        console.log("Deployer:", deployer);
        console.log("Proxy Address:", proxyAddress);

        vm.startBroadcast(privateKey);

        // Step 1: Deploy new implementation
        console.log("\n=== Deploying New LendingPool Implementation ===");
        LendingPool newImplementation = new LendingPool();
        console.log("New Implementation deployed at:", address(newImplementation));

        // Step 2: Get the proxy contract instance
        LendingPool proxy = LendingPool(payable(proxyAddress));

        // Step 3: Upgrade the proxy to the new implementation
        console.log("\n=== Upgrading Proxy ===");
        console.log("Upgrading proxy from old implementation to new implementation...");

        // upgradeToAndCall with empty data (no initialization needed)
        proxy.upgradeToAndCall(address(newImplementation), "");

        console.log("Upgrade completed successfully!");
        console.log("\n=== Verification ===");
        console.log("Proxy Address:", proxyAddress);
        console.log("New Implementation:", address(newImplementation));

        // Verify the upgrade by calling view functions
        address borrowToken = proxy.borrowToken();
        address collateralToken = proxy.collateralToken();
        uint256 ltv = proxy.ltv();

        console.log("Borrow Token (verification):", borrowToken);
        console.log("Collateral Token (verification):", collateralToken);
        console.log("LTV (verification):", ltv);

        vm.stopBroadcast();
    }
}

