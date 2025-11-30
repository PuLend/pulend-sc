// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IIsHealthy
 * @author Pulend Protocol Team
 * @notice Interface for the IsHealthy contract that validates borrowing position health
 * @dev This interface defines the function for checking if a user's borrowing position
 *      remains healthy based on their collateral and debt ratios
 */
interface IIsHealthy {
    /// @notice Validates whether a user's borrowing position is healthy
    /// @dev This function should revert if the position is unhealthy (under-collateralized)
    /// @param user The user address whose position is being checked
    /// @param lendingPool The lending pool contract address
    function isHealthy(address user, address lendingPool) external view;

    function checkLiquidatable(address user, address lendingPool) external view returns (bool, uint256, uint256, uint256);
}
