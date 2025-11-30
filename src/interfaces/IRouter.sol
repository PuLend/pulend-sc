// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IRouter
 * @author Pulend Protocol Team
 * @notice Interface for the Router contract that manages cross-chain configurations
 * @dev This interface defines functions for accessing cross-chain mappings and protocol contract addresses
 */
interface IRouter {
    /// @notice Returns the TokenDataStream contract address
    /// @return The TokenDataStream contract address
    function tokenDataStream() external view returns (address);

    /// @notice Returns the LendingPool contract address
    /// @return The LendingPool contract address
    function lendingPool() external view returns (address);

    /// @notice Returns the IsHealthy contract address
    /// @return The IsHealthy contract address
    function isHealthy() external view returns (address);

    /// @notice Returns the InterestRateModel contract address
    /// @return The InterestRateModel contract address
    function interestRateModel() external view returns (address);
}
