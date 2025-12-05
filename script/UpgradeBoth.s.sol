// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {InterestRateModel} from "../src/InterestRateModel.sol";

/**
 * @title UpgradeBothScript
 * @notice Script to upgrade both InterestRateModel and LendingPool contracts in a single transaction
 * @dev This script:
 *      1. Deploys new implementations for both contracts
 *      2. Upgrades both proxies to point to their new implementations
 *      3. Requires UPGRADER_ROLE on both proxy contracts
 * 
 * Usage:
 *   forge script script/UpgradeBoth.s.sol --broadcast --verify --verifier blockscout -vvv
 *   
 * Environment Variables Required:
 *   - PRIVATE_KEY: Deployer private key (must have UPGRADER_ROLE on both contracts)
 *   - INTEREST_RATE_MODEL_PROXY: Address of the existing InterestRateModel proxy
 *   - LENDING_POOL_PROXY: Address of the existing LendingPool proxy
 */
contract UpgradeBothScript is Script {
    function run() public {
        // Load environment variables
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address interestRateModelProxyAddress = vm.envAddress("INTEREST_RATE_MODEL_PROXY");
        address lendingPoolProxyAddress = vm.envAddress("LENDING_POOL_PROXY");
        
        address deployer = vm.addr(privateKey);
        console.log("Deployer:", deployer);
        console.log("InterestRateModel Proxy:", interestRateModelProxyAddress);
        console.log("LendingPool Proxy:", lendingPoolProxyAddress);
        
        vm.startBroadcast(privateKey);
        
        // ========================================
        // STEP 1: Upgrade InterestRateModel
        // ========================================
        console.log("\n=== UPGRADING INTEREST RATE MODEL ===");
        console.log("Deploying new InterestRateModel implementation...");
        InterestRateModel newInterestRateModelImpl = new InterestRateModel();
        console.log("New InterestRateModel Implementation:", address(newInterestRateModelImpl));
        
        InterestRateModel interestRateModelProxy = InterestRateModel(payable(interestRateModelProxyAddress));
        console.log("Upgrading InterestRateModel proxy...");
        interestRateModelProxy.upgradeToAndCall(address(newInterestRateModelImpl), "");
        console.log("InterestRateModel upgrade completed!");
        
        // Verify InterestRateModel upgrade
        uint256 scaledPercentage = interestRateModelProxy.scaledPercentage();
        console.log("InterestRateModel ScaledPercentage (verification):", scaledPercentage);
        
        // ========================================
        // STEP 2: Upgrade LendingPool
        // ========================================
        console.log("\n=== UPGRADING LENDING POOL ===");
        console.log("Deploying new LendingPool implementation...");
        LendingPool newLendingPoolImpl = new LendingPool();
        console.log("New LendingPool Implementation:", address(newLendingPoolImpl));
        
        LendingPool lendingPoolProxy = LendingPool(payable(lendingPoolProxyAddress));
        console.log("Upgrading LendingPool proxy...");
        lendingPoolProxy.upgradeToAndCall(address(newLendingPoolImpl), "");
        console.log("LendingPool upgrade completed!");
        
        // Verify LendingPool upgrade
        address borrowToken = lendingPoolProxy.borrowToken();
        address collateralToken = lendingPoolProxy.collateralToken();
        uint256 ltv = lendingPoolProxy.ltv();
        
        console.log("LendingPool Borrow Token (verification):", borrowToken);
        console.log("LendingPool Collateral Token (verification):", collateralToken);
        console.log("LendingPool LTV (verification):", ltv);
        
        // ========================================
        // SUMMARY
        // ========================================
        console.log("\n=== UPGRADE SUMMARY ===");
        console.log("InterestRateModel Proxy:", interestRateModelProxyAddress);
        console.log("  New Implementation:", address(newInterestRateModelImpl));
        console.log("LendingPool Proxy:", lendingPoolProxyAddress);
        console.log("  New Implementation:", address(newLendingPoolImpl));
        console.log("\nBoth upgrades completed successfully!");
        
        vm.stopBroadcast();
    }
}

