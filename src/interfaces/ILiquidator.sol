// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILiquidator
 * @author Pulend Protocol Team
 * @notice Interface for the Liquidator contract
 */
interface ILiquidator {
    // =============================================================
    //                           ERRORS
    // =============================================================

    error ZeroAmount();
    error PositionHealthy(uint256 healthFactor, uint256 liquidationThreshold);
    error InsufficientCollateral(uint256 available, uint256 required);
    error NoDebtToLiquidate();
    error InvalidParameter(string parameter);
    error ThresholdMustExceedLtv(uint256 threshold, uint256 ltv);

    // =============================================================
    //                           EVENTS
    // =============================================================

    event Liquidation(
        address indexed liquidator,
        address indexed borrower,
        address indexed collateralToken,
        address borrowToken,
        uint256 debtRepaid,
        uint256 collateralSeized,
        uint256 liquidationBonus
    );

    event LiquidationThresholdSet(address indexed token, uint256 oldThreshold, uint256 newThreshold);
    event LiquidationBonusSet(address indexed token, uint256 oldBonus, uint256 newBonus);
    event MaxLiquidationPercentageSet(uint256 oldPercentage, uint256 newPercentage);
    event RouterSet(address oldRouter, address newRouter);

    // =============================================================
    //                    LIQUIDATION FUNCTIONS
    // =============================================================

    /// @notice Liquidates an unhealthy borrowing position
    function liquidate(address _borrower, address _borrowToken, address _collateralToken, uint256 _repayAmount)
        external;

    /// @notice Checks if a position is liquidatable
    function isPositionLiquidatable(address _borrower, address _collateralToken, address _borrowToken)
        external
        view
        returns (bool isLiquidatable, uint256 healthFactor);

    /// @notice Calculates the health factor for a borrower's position
    function getHealthFactor(address _borrower, address _collateralToken, address _borrowToken)
        external
        view
        returns (uint256 healthFactor);

    // =============================================================
    //                    CONFIGURATION FUNCTIONS
    // =============================================================

    /// @notice Sets the liquidation threshold for a collateral token
    function setLiquidationThreshold(address _token, uint256 _threshold) external;

    /// @notice Sets the liquidation bonus for a collateral token
    function setLiquidationBonus(address _token, uint256 _bonus) external;

    /// @notice Sets the maximum percentage of debt that can be liquidated
    function setMaxLiquidationPercentage(uint256 _percentage) external;

    /// @notice Updates the router contract address
    function setRouter(address _router) external;

    // =============================================================
    //                        VIEW FUNCTIONS
    // =============================================================

    /// @notice Returns the router address
    function router() external view returns (address);

    /// @notice Returns the liquidation threshold for a token
    function liquidationThreshold(address _token) external view returns (uint256);

    /// @notice Returns the liquidation bonus for a token
    function liquidationBonus(address _token) external view returns (uint256);

    /// @notice Returns the maximum liquidation percentage
    function maxLiquidationPercentage() external view returns (uint256);

    /// @notice Returns the minimum health factor constant
    function MIN_HEALTH_FACTOR() external view returns (uint256);
}

