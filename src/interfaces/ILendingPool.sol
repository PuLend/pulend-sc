// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILendingPool
 * @author Pulend Protocol Team
 * @notice Interface for the main LendingPool contract that manages cross-chain borrowing and lending
 * @dev This interface defines all external functions for interacting with the lending pool,
 *      including collateral management, liquidity provision, borrowing, and administrative functions.
 */
interface ILendingPool {
    // =============================================================
    //                        VIEW FUNCTIONS
    // =============================================================

    /// @notice Returns the total amount of assets borrowed for a token
    /// @return The total borrowed assets amount
    function totalBorrowAssets() external view returns (uint256);

    /// @notice Returns the total borrow shares issued for a token
    /// @return The total borrow shares
    function totalBorrowShares() external view returns (uint256);

    /// @notice Returns the number of NFTs a user has deposited as collateral
    /// @param _user The user address
    /// @return The number of NFT tokens deposited by the user
    function userCollateral(address _user) external view returns (uint256);

    /// @notice Returns the total number of NFTs deposited as collateral
    /// @return The total number of NFT tokens deposited
    function totalCollateral() external view returns (uint256);

    /// @notice Returns all NFT token IDs deposited by a user
    /// @param _user The user address to check
    /// @return Array of NFT token IDs deposited by the user
    function getUserCollateralTokenIds(address _user) external view returns (uint256[] memory);

    /// @notice Returns the total supply assets for a token
    /// @return The total supply assets amount
    function totalSupplyAssets() external view returns (uint256);

    /// @notice Returns the total supply shares issued for a token
    /// @return The total supply shares
    function totalSupplyShares() external view returns (uint256);

    /// @notice Returns a user's supply shares for a token
    /// @param _user The user address
    /// @return The user's supply shares
    function userSupplyShares(address _user) external view returns (uint256);

    /// @notice Returns a user's borrow shares for a token
    /// @param _user The user address
    /// @return The user's borrow shares
    function userBorrowShares(address _user) external view returns (uint256);

    /// @notice Returns the loan-to-value ratio
    /// @return The LTV ratio with 18 decimal precision
    function ltv() external view returns (uint256);

    /// @notice Returns the timestamp of last interest accrual for a token
    /// @return The last accrual timestamp
    function lastAccrued() external view returns (uint256);

    /// @notice Returns whether an address is authorized as an operator
    /// @param _operator The operator address to check
    /// @return True if authorized, false otherwise
    function operator(address _operator) external view returns (bool);

    /// @notice Returns the router contract address
    /// @return The router contract address
    function router() external view returns (address);

    /// @notice Returns the collateral token address at a specific index
    /// @return The token address at the specified index
    function collateralToken() external view returns (address);

    /// @notice Returns the borrow token address at a specific index
    /// @return The token address at the specified index
    function borrowToken() external view returns (address);

    // =============================================================
    //                    CORE LENDING FUNCTIONS
    // =============================================================

    /// @notice Borrows tokens from the pool, potentially cross-chain
    /// @param _user The user account that will receive the borrowed tokens
    /// @param _token The token address to borrow
    /// @param _amount The amount of tokens to borrow
    /// @param _chainDst The destination chain ID where tokens should be sent
    function borrow(address _user, address _token, uint256 _amount, uint256 _chainDst) external payable;

    /// @notice Repays borrowed tokens by burning borrow shares
    /// @param _user The user account repaying the borrowed tokens
    /// @param _token The token address being repaid
    /// @param _shares The number of borrow shares to burn for repayment
    function repay(address _user, address _token, uint256 _shares) external;

    /// @notice Supplies NFT collateral to the pool
    /// @param _tokenId The NFT token ID to supply as collateral
    function supplyCollateral(uint256 _tokenId) external;

    /// @notice Supplies liquidity tokens to the pool for lending
    /// @param _user The user account that will own the liquidity shares
    /// @param _token The token address to supply as liquidity
    /// @param _amount The amount of tokens to supply as liquidity
    function supplyLiquidity(address _user, address _token, uint256 _amount) external;

    /// @notice Withdraws NFT collateral from the pool
    /// @param _tokenId The NFT token ID to withdraw
    function withdrawCollateral(uint256 _tokenId) external;

    /// @notice Withdraws liquidity from the pool by burning shares
    /// @param _user The user account to withdraw liquidity for
    /// @param _token The token address to withdraw
    /// @param _shares The number of shares to burn for withdrawal
    function withdrawLiquidity(address _user, address _token, uint256 _shares) external;

    // =============================================================
    //                INTEREST CALCULATION FUNCTIONS
    // =============================================================

    /// @notice Accrues interest for all borrow tokens based on elapsed time and current borrow rate
    function accrueInterest() external;

    /// @notice Calculates the current borrow rate based on utilization
    /// @param _token The token address to calculate borrow rate for
    /// @return The annual borrow rate scaled by 100
    function calculateBorrowRate(address _token) external view returns (uint256);

    // =============================================================
    //                   ADMINISTRATIVE FUNCTIONS
    // =============================================================

    /// @notice Sets or revokes operator privileges for an address
    /// @param _operator The address to grant or revoke operator privileges
    /// @param _status True to grant operator privileges, false to revoke
    function setOperator(address _operator, bool _status) external;

    /// @notice Adds or removes a collateral token from the supported list
    /// @param _token The token address to add or remove
    /// @param _active True to add the token, false to remove it
    function setCollateralToken(address _token, bool _active) external;

    /// @notice Adds or removes a borrow token from the supported list
    /// @param _token The token address to add or remove
    /// @param _active True to add the token, false to remove it
    function setBorrowToken(address _token, bool _active) external;

    /// @notice Sets the active status of a token for pool operations
    /// @param _token The token address to update
    /// @param _active True to activate the token, false to deactivate
    function setTokenActive(address _token, bool _active) external;

    /// @notice Sets the router contract address
    /// @param _router The new router contract address
    function setRouter(address _router) external;

    /// @notice Sets the loan-to-value ratio
    /// @param _ltv The LTV ratio with 18 decimal precision
    function setLtv(uint256 _ltv) external;

    /// @notice Pauses all contract operations
    function pause() external;

    /// @notice Unpauses all contract operations
    function unpause() external;

    // =============================================================
    //                   ACCESS CONTROL FUNCTIONS
    // =============================================================

    /// @notice Returns whether an account has a specific role
    /// @param role The role identifier
    /// @param account The account to check
    /// @return True if the account has the role, false otherwise
    function hasRole(bytes32 role, address account) external view returns (bool);

    /// @notice Returns the admin role for a given role
    /// @param role The role to get the admin for
    /// @return The admin role identifier
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /// @notice Grants a role to an account
    /// @param role The role to grant
    /// @param account The account to grant the role to
    function grantRole(bytes32 role, address account) external;

    /// @notice Revokes a role from an account
    /// @param role The role to revoke
    /// @param account The account to revoke the role from
    function revokeRole(bytes32 role, address account) external;

    /// @notice Renounces a role (can only be called by the role holder)
    /// @param role The role to renounce
    /// @param account The account renouncing the role (must be msg.sender)
    function renounceRole(bytes32 role, address account) external;

    // =============================================================
    //                     UPGRADE FUNCTIONS
    // =============================================================

    /// @notice Upgrades the contract to a new implementation
    /// @param newImplementation The address of the new implementation contract
    function upgradeTo(address newImplementation) external;

    /// @notice Upgrades the contract and calls a function on the new implementation
    /// @param newImplementation The address of the new implementation contract
    /// @param data The calldata to execute on the new implementation
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;

    // =============================================================
    //                           EVENTS
    // =============================================================

    /// @notice Emitted when an operator's authorization status is updated
    event OperatorSet(address indexed operator, bool status);

    /// @notice Emitted when a user supplies NFT collateral to the pool
    event SupplyCollateral(address indexed user, address indexed token, uint256 tokenId);

    /// @notice Emitted when a user withdraws NFT collateral from the pool
    event WithdrawCollateral(address indexed user, address indexed token, uint256 tokenId);

    /// @notice Emitted when a user supplies liquidity to the pool for lending
    event SupplyLiquidity(address indexed user, address indexed token, uint256 amount);

    /// @notice Emitted when a user withdraws liquidity from the pool
    event WithdrawLiquidity(address indexed user, address indexed token, uint256 amount);

    /// @notice Emitted when a user borrows tokens from the pool (potentially cross-chain)
    event Borrow(address indexed user, address indexed token, uint256 amount, uint256 chainDst);

    /// @notice Emitted when a user repays borrowed tokens
    event Repay(address indexed user, address indexed token, uint256 amount);

    /// @notice Emitted when a collateral token is updated
    event CollateralTokenSet(address indexed token, bool active);

    /// @notice Emitted when a borrow token is updated
    event BorrowTokenSet(address indexed token, bool active);

    /// @notice Emitted when a token's active status is updated
    event TokenActiveSet(address indexed token, bool active);

    /// @notice Emitted when the router address is updated
    event RouterSet(address router);

    /// @notice Emitted when a token's borrow LTV ratio is updated
    event BorrowLtvSet(address indexed token, uint256 ltv);

    /// @notice Emitted when a token's minimum supply amount is updated
    event TokenMinSupplyAmountSet(address indexed token, uint256 amount);
}
