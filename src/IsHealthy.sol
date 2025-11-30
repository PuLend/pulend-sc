// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {ITokenDataStream} from "./interfaces/ITokenDataStream.sol";
import {ILendingPool} from "./interfaces/ILendingPool.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title IsHealthy
 * @author Pulend Protocol Team
 * @notice Contract that validates the health of borrowing positions based on collateral ratios
 * @dev This contract implements health checks for lending positions by comparing the value
 *      of a user's collateral against their borrowed amount and the loan-to-value (LTV) ratio.
 *      It prevents users from borrowing more than their collateral can safely support.
 *
 * Key Features:
 * - Multi-token collateral support across different chains
 * - Real-time price feed integration via TokenDataStream
 * - Configurable loan-to-value ratios per token
 * - Automatic liquidation threshold detection
 * - Precision handling for different token decimals
 */
contract IsHealthy is Ownable {
    // =============================================================
    //                           ERRORS
    // =============================================================

    /// @notice Thrown when an invalid loan-to-value ratio is provided (e.g., zero)
    /// @param ltv The invalid LTV ratio that was provided
    error InvalidLtv(address lendingPool, uint256 ltv);

    error ZeroCollateralAmount(address lendingPool, uint256 userCollateralAmount, uint256 totalCollateral);

    error LtvMustBeLessThanThreshold(address lendingPool, uint256 ltv, uint256 threshold);

    error LiquidationAlert(uint256 borrowValue, uint256 collateralValue);

    error LiquidationThresholdNotSet(address lendingPool);

    error LiquidationBonusNotSet(address lendingPool);

    error MaxLiquidationPercentageNotSet(uint256 percentage);
    
    error ZeroAddress();

    event RouterSet(address router);

    event LiquidationThresholdSet(address lendingPool, uint256 threshold);

    event LiquidationBonusSet(address lendingPool, uint256 bonus);

    event MaxLiquidationPercentageSet(uint256 percentage);

    // =============================================================
    //                       STATE VARIABLES
    // =============================================================

    /// @notice Address of the Router contract for accessing protocol configurations
    address public router;

    /// @notice Liquidation threshold for each collateral token (with 18 decimals precision)
    /// @dev lendingPool address => liquidation threshold (e.g., 0.85e18 = 85%)
    /// When health factor drops below this, position can be liquidated
    mapping(address => uint256) public liquidationThreshold;

    /// @notice Liquidation bonus for each collateral token (with 18 decimals precision)
    /// @dev token address => liquidation bonus (e.g., 0.05e18 = 5% bonus to liquidator)
    /// Liquidators receive collateral worth (debt repaid * (1 + bonus))
    mapping(address => uint256) public liquidationBonus;

    /// @notice Maximum percentage of debt that can be liquidated in a single transaction
    /// @dev Scaled by 1e18 (e.g., 0.5e18 = 50%)
    uint256 public maxLiquidationPercentage;

    /// @notice Minimum health factor required to avoid liquidation
    /// @dev Scaled by 1e18 (e.g., 1e18 = 100% = healthy)
    uint256 public constant MIN_HEALTH_FACTOR = 1e18;

    // =============================================================
    //                           CONSTRUCTOR
    // =============================================================

    /// @notice Initializes the IsHealthy contract with a router address
    /// @dev Sets up Ownable with deployer as owner and configures the router
    /// @param _router The router contract address for accessing protocol configurations
    constructor(address _router) Ownable(msg.sender) {
        if (_router == address(0)) revert ZeroAddress();
        router = _router;
    }

    // =============================================================
    //                        HEALTH CHECK FUNCTIONS
    // =============================================================

    /// @notice Validates whether a user's borrowing position is healthy
    /// @dev Calculates the total USD value of user's collateral across all supported tokens
    ///      and compares it against their borrowed amount and the liquidation threshold.
    ///      Reverts if the position is unhealthy (over-leveraged).
    /// @param user The user address whose position is being checked
    /// @param lendingPool The lending pool contract address
    function isHealthy(address user, address lendingPool) public view {
        uint256 borrowValue = _userBorrowValue(lendingPool, _borrowToken(lendingPool), user);
        if (borrowValue == 0) return; // No borrows = always healthy
        
        uint256 maxCollateralValue = _userCollateralStats(lendingPool, _collateralToken(lendingPool), user);
        // If user has borrows but insufficient collateral, revert
        if (borrowValue > maxCollateralValue) revert LiquidationAlert(borrowValue, maxCollateralValue);
    }

    function checkLiquidatable(address user, address lendingPool) public view returns (bool, uint256, uint256, uint256) {
        uint256 borrowValue = _userBorrowValue(lendingPool, _borrowToken(lendingPool), user);
        if (borrowValue == 0) return (true, 0, 0, 0);
        uint256 maxCollateralValue = _userCollateralStats(lendingPool, _collateralToken(lendingPool), user);
        uint256 liquidationAllocation = _userCollateral(lendingPool, user) * liquidationBonus[lendingPool] / 1e18;
        return (borrowValue > maxCollateralValue, borrowValue, maxCollateralValue, liquidationAllocation);
    }

    // =============================================================
    //                   CONFIGURATION FUNCTIONS
    // =============================================================

    /// @notice Updates the router contract address
    /// @dev Only the contract owner can call this function
    /// @param _router The new router contract address
    function setRouter(address _router) public onlyOwner {
        if (_router == address(0)) revert ZeroAddress();
        router = _router;
        emit RouterSet(_router);
    }

    function setLiquidationThreshold(address _lendingPool, uint256 _threshold) public onlyOwner {
        uint256 ltv = _ltv(_lendingPool);
        if (ltv > _threshold) revert LtvMustBeLessThanThreshold(_lendingPool, ltv, _threshold);
        liquidationThreshold[_lendingPool] = _threshold;
        emit LiquidationThresholdSet(_lendingPool, _threshold);
    }

    function setLiquidationBonus(address _lendingPool, uint256 bonus) public onlyOwner {
        liquidationBonus[_lendingPool] = bonus;
        emit LiquidationBonusSet(_lendingPool, bonus);
    }

    function setMaxLiquidationPercentage(uint256 percentage) public onlyOwner {
        maxLiquidationPercentage = percentage;
        emit MaxLiquidationPercentageSet(percentage);
    }

    // isPositionLiquidatable(borrower, collateralToken, borrowToken)
    // getHealthFactor(borrower, collateralToken, borrowToken)

    // =============================================================
    //                    INTERNAL HELPER FUNCTIONS
    // =============================================================

    function _userCollateralStats(address _lendingPool, address _token, address _user) internal view returns (uint256) {
        _checkLiquidation(_lendingPool);
        uint256 userCollateral = _userCollateral(_lendingPool, _user);
        // if (userCollateral == 0) {
        //     revert ZeroCollateralAmount(_lendingPool, userCollateral, _totalCollateral(_lendingPool));
        // }
        uint256 collateralAdjustedPrice = (_tokenPrice(_token) * 1e18) / (10 ** _oracleDecimal(_token));
        // For NFTs, userCollateral is the count, and we don't need to adjust for decimals (treat as 0 decimals)
        uint256 tokenDecimals = _tokenDecimals(_token);
        uint256 userCollateralValue = (userCollateral * collateralAdjustedPrice) / (10 ** tokenDecimals);
        uint256 maxBorrowValue = (userCollateralValue * liquidationThreshold[_lendingPool]) / 1e18;
        return maxBorrowValue;
    }

    function _userBorrowValue(address _lendingPool, address _token, address _user) internal view returns (uint256) {
        uint256 shares = _userBorrowShares(_lendingPool, _user);
        if (shares == 0) return 0;
        if (_totalBorrowShares(_lendingPool) == 0) return 0;
        uint256 userBorrowAmount = (shares * _totalBorrowAssets(_lendingPool)) / _totalBorrowShares(_lendingPool);
        uint256 borrowAdjustedPrice = (_tokenPrice(_token) * 1e18) / (10 ** _oracleDecimal(_token));
        uint256 userBorrowValue = (userBorrowAmount * borrowAdjustedPrice) / (10 ** _tokenDecimals(_token));
        return userBorrowValue;
    }

    function _collateralToken(address _lendingPool) internal view returns (address) {
        return ILendingPool(_lendingPool).collateralToken();
    }

    function _borrowToken(address _lendingPool) internal view returns (address) {
        return ILendingPool(_lendingPool).borrowToken();
    }

    function _userBorrowShares(address _lendingPool, address _user) internal view returns (uint256) {
        return ILendingPool(_lendingPool).userBorrowShares(_user);
    }

    function _totalBorrowAssets(address _lendingPool) internal view returns (uint256) {
        return ILendingPool(_lendingPool).totalBorrowAssets();
    }

    function _totalBorrowShares(address _lendingPool) internal view returns (uint256) {
        return ILendingPool(_lendingPool).totalBorrowShares();
    }

    function _userCollateral(address _lendingPool, address _user) internal view returns (uint256) {
        return ILendingPool(_lendingPool).userCollateral(_user);
    }

    function _totalCollateral(address _lendingPool) internal view returns (uint256) {
        return ILendingPool(_lendingPool).totalCollateral();
    }

    function _ltv(address _lendingPool) internal view returns (uint256) {
        uint256 ltv = ILendingPool(_lendingPool).ltv();
        if (ltv == 0) revert InvalidLtv(_lendingPool, ltv);
        return ltv;
    }

    /// @notice Gets the current price of a collateral token from the price feed
    /// @dev Retrieves the latest price data from the TokenDataStream oracle
    /// @param _token The token address to get the price for
    /// @return The current price of the token from the oracle
    function _tokenPrice(address _token) internal view returns (uint256) {
        (, uint256 price,,,) = ITokenDataStream(_tokenDataStream()).latestRoundData(_token);
        return price;
    }

    /// @notice Gets the number of decimals used by the oracle for a token's price
    /// @dev Used to properly normalize price values from different oracle sources
    /// @param _token The token address to get oracle decimals for
    /// @return The number of decimals used by the token's price oracle
    function _oracleDecimal(address _token) internal view returns (uint256) {
        return ITokenDataStream(_tokenDataStream()).decimals(_token);
    }

    function _tokenDataStream() internal view returns (address) {
        return IRouter(router).tokenDataStream();
    }

    /// @notice Gets the number of decimals used by an ERC20 token or 0 for NFTs
    /// @dev Used to properly normalize token amounts for value calculations
    ///      For NFTs (ERC721), returns 0 since each NFT is a whole unit
    /// @param _token The token address to get decimals for
    /// @return The number of decimals used by the ERC20 token, or 0 for NFTs
    function _tokenDecimals(address _token) internal view returns (uint256) {
        // Try to call decimals() - if it fails, assume it's an NFT (0 decimals)
        try IERC20Metadata(_token).decimals() returns (uint8 decimals) {
            return decimals;
        } catch {
            // Token doesn't support decimals() - treat as NFT with 0 decimals
            return 0;
        }
    }

    function _checkLiquidation(address _lendingPool) internal view {
        if (liquidationThreshold[_lendingPool] == 0) revert LiquidationThresholdNotSet(_lendingPool);
        if (liquidationBonus[_lendingPool] == 0) revert LiquidationBonusNotSet(_lendingPool);
        if (maxLiquidationPercentage == 0) revert MaxLiquidationPercentageNotSet(maxLiquidationPercentage);
    }
}
