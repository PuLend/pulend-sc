// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IInterestRateModel
 * @notice Interface for the InterestRateModel contract
 */
interface IInterestRateModel {
    /**
     * @notice Calculates the current borrow rate based on utilization
     * @param _lendingPool The lending pool address to calculate borrow rate for
     * @return borrowRate The annual borrow rate scaled by 100 (e.g., 500 = 5%)
     */
    function calculateBorrowRate(address _lendingPool) external view returns (uint256 borrowRate);

    /**
     * @notice Calculates interest accrued over a time period
     * @param _lendingPool The lending pool address to calculate interest for
     * @param _borrowRate The borrow rate (scaled by 100)
     * @param _elapsedTime Time elapsed since last accrual in seconds
     * @return interest The interest amount accrued
     */
    function calculateInterest(address _lendingPool, uint256 _borrowRate, uint256 _elapsedTime)
        external
        pure
        returns (uint256 interest);

    /**
     * @notice Returns the maximum allowed utilization rate for a lending pool
     * @param _lendingPool The lending pool address
     * @return The maximum utilization rate (scaled by 1e18)
     */
    function lendingPoolMaxUtilization(address _lendingPool) external view returns (uint256);
}

