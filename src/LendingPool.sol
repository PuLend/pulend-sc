// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ITokenDataStream} from "./interfaces/ITokenDataStream.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {IIsHealthy} from "./interfaces/IIsHealthy.sol";
import {IInterestRateModel} from "./interfaces/IInterestRateModel.sol";

/**
 * @title LendingPool
 * @author Pulend Protocol Team
 * @notice Core lending pool contract that manages cross-chain borrowing and lending operations
 * @dev This contract is upgradeable and uses OpenZeppelin's upgradeable contracts.
 *      It implements a lending pool with collateral-based borrowing, cross-chain functionality via LayerZero,
 *      and dynamic interest rate calculations based on utilization rates.
 *
 * Key Features:
 * - Cross-chain borrowing and lending via LayerZero
 * - Collateral-based lending with configurable LTV ratios
 * - Dynamic interest rates based on utilization
 * - Share-based accounting for deposits and borrows
 * - Role-based access control for administrative functions
 * - Pausable operations for emergency situations
 */
contract LendingPool is
    Initializable,
    ContextUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuard,
    IERC721Receiver
{
    using SafeERC20 for IERC20;

    // =============================================================
    //                           ERRORS
    // =============================================================

    /// @notice Thrown when a token's data stream (price feed) is not set
    /// @param _token The token address that doesn't have a data stream set
    error TokenDataStreamNotSet(address _token);

    /// @notice Thrown when user has insufficient collateral for withdrawal
    /// @param _token The collateral token address
    /// @param _amount The amount being withdrawn
    /// @param _userCollateralBalance The user's actual collateral balance
    error InsufficientCollateral(address _token, uint256 _amount, uint256 _userCollateralBalance);

    /// @notice Thrown when pool has insufficient liquidity for withdrawal or borrow
    /// @param _token The token address
    /// @param _amount The amount being requested
    /// @param _totalSupplyAssets The total supply assets available
    error InsufficientLiquidity(address _token, uint256 _amount, uint256 _totalSupplyAssets);

    /// @notice Thrown when user attempts to withdraw more shares than they own
    /// @param _token The token address
    /// @param _shares The shares being withdrawn
    /// @param _userSupplyShares The user's actual share balance
    error InvalidShares(address _token, uint256 _shares, uint256 _userSupplyShares);

    /// @notice Thrown when a zero amount is provided for operations that require non-zero amounts
    error ZeroAmount();

    /// @notice Thrown when attempting to use a token that is not active
    /// @param _token The inactive token address
    error TokenNotActive(address _token);

    /// @notice Thrown when user access control validation fails
    /// @param _sender The sender address
    /// @param _user The user address being accessed
    error UserAccessControl(address _sender, address _user);

    /// @notice Thrown when attempting to add a collateral token that already exists
    /// @param _token The token address that already exists
    error CollateralTokenExist(address _token);

    /// @notice Thrown when attempting to remove a collateral token that does not exist
    /// @param _token The token address that does not exist
    error CollateralTokenNotExist(address _token);

    /// @notice Thrown when attempting to add a borrow token that already exists
    /// @param _token The token address that already exists
    error BorrowTokenExist(address _token);

    /// @notice Thrown when attempting to remove a borrow token that does not exist
    /// @param _token The token address that does not exist
    error BorrowTokenNotExist(address _token);

    /// @notice Thrown when user is not authorized to perform the operation
    /// @param _user The user address that is not authorized
    error UserNotAuthorized(address _user);

    /// @notice Thrown when the supply amount is less than the minimum supply amount
    /// @param _token The token address that has less than the minimum supply amount
    /// @param _amount The amount that is less than the minimum supply amount
    /// @param _minAmount The minimum supply amount
    error MinSupplyAmountNotMet(address _token, uint256 _amount, uint256 _minAmount);

    /// @notice Thrown when the asset is not liquidatable
    /// @param _collateralToken The collateral token address
    /// @param _collateralValue The user's collateral value
    /// @param _borrowValue The user's borrow value
    error AssetNotLiquidatable(address _collateralToken, uint256 _collateralValue, uint256 _borrowValue);

    /// @notice Thrown when a zero address is provided
    error ZeroAddress();

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /// @notice Role identifier for accounts that can pause/unpause the contract
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Role identifier for accounts that can upgrade the contract
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @notice Role identifier for accounts that have owner privileges
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // bytes public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

    // =============================================================
    //                       STATE VARIABLES
    // =============================================================

    /// @notice Array of supported token addresses
    address public collateralToken;
    address public borrowToken;

    /// @notice Address of the Router contract that manages cross-chain configurations
    address public router;

    /// @notice Total assets supplied to the pool for each token (for lending)
    /// @dev token address => total supply assets amount
    uint256 public totalSupplyAssets;

    /// @notice Total shares issued for supplied assets for each token
    /// @dev token address => total supply shares
    uint256 public totalSupplyShares;

    /// @notice Total assets borrowed from the pool for each token
    /// @dev total borrow assets amount
    uint256 public totalBorrowAssets;

    /// @notice Total shares issued for borrowed assets for each token
    /// @dev total borrow shares
    uint256 public totalBorrowShares;

    /// @notice Timestamp of last interest accrual
    /// @dev timestamp
    uint256 public lastAccrued;

    uint256 public minSupplyAmount;

    uint256 public ltv;

    /// @notice User NFT collateral token IDs by user
    /// @dev user address => array of token IDs
    mapping(address => uint256[]) public userCollateralTokenIds;

    /// @notice Total number of NFTs deposited as collateral
    uint256 public totalCollateralNfts;

    /// @notice User shares for supplied assets by user and token
    /// @dev user address => token address => shares amount
    mapping(address => uint256) public userSupplyShares;

    /// @notice User shares for borrowed assets by user and token
    /// @dev user address => token address => shares amount
    mapping(address => uint256) public userBorrowShares;

    // =============================================================
    //                           EVENTS
    // =============================================================

    /// @notice Emitted when a user supplies NFT collateral to the pool
    /// @param user The user supplying collateral
    /// @param token The NFT contract address being supplied as collateral
    /// @param tokenId The NFT token ID being supplied
    event SupplyCollateral(address indexed user, address indexed token, uint256 tokenId);

    /// @notice Emitted when a user withdraws NFT collateral from the pool
    /// @param user The user withdrawing collateral
    /// @param token The NFT contract address being withdrawn
    /// @param tokenId The NFT token ID being withdrawn
    event WithdrawCollateral(address indexed user, address indexed token, uint256 tokenId);

    /// @notice Emitted when a user supplies liquidity to the pool for lending
    /// @param user The user supplying liquidity
    /// @param token The token address being supplied
    /// @param amount The amount of liquidity supplied
    event SupplyLiquidity(address indexed user, address indexed token, uint256 amount);

    /// @notice Emitted when a user withdraws liquidity from the pool
    /// @param user The user withdrawing liquidity
    /// @param token The token address being withdrawn
    /// @param amount The amount of liquidity withdrawn
    event WithdrawLiquidity(address indexed user, address indexed token, uint256 amount);

    /// @notice Emitted when a user borrows tokens from the pool (potentially cross-chain)
    /// @param user The user borrowing tokens
    /// @param token The token address being borrowed
    /// @param amount The amount being borrowed
    event Borrow(address indexed user, address indexed token, uint256 amount);

    /// @notice Emitted when a user repays borrowed tokens
    /// @param user The user repaying tokens
    /// @param token The token address being repaid
    /// @param amount The amount being repaid
    event Repay(address indexed user, address indexed token, uint256 amount);

    /// @notice Emitted when a collateral token is configured
    /// @param token The token address
    event CollateralTokenSet(address indexed token);

    /// @notice Emitted when a borrow token is configured
    /// @param token The token address
    event BorrowTokenSet(address indexed token);

    /// @notice Emitted when the router address is updated
    /// @param router The new router address
    event RouterSet(address router);

    /// @notice Emitted when a token's Token LTV ratio is updated
    /// @param ltv The new LTV ratio (with 18 decimals precision)
    event LtvSet(uint256 ltv);

    /// @notice Emitted when the interest rate model address is updated
    /// @param interestRateModel The new interest rate model address
    event InterestRateModelSet(address interestRateModel);

    /// @notice Emitted when a token's minimum supply amount is updated
    /// @param token The token address
    /// @param amount The new minimum supply amount
    event MinSupplyAmountSet(address indexed token, uint256 amount);

    event Liquidation(
        address indexed borrower,
        address indexed borrowToken,
        address indexed collateralToken,
        uint256 userBorrowAssets,
        uint256[] collateralTokenIds,
        uint256[] liquidatorTokenIds,
        uint256[] borrowerTokenIds
    );

    error MaxUtilizationReached(address _token, uint256 _utilization, uint256 _maxUtilization);

    // =============================================================
    //                           MODIFIERS
    // =============================================================

    /// @notice Validates user access control permissions
    /// @param _user The user address to validate access for
    modifier userAccessControl(address _user) {
        _;
    }

    // =============================================================
    //                           CONSTRUCTOR
    // =============================================================

    /// @notice Contract constructor that disables initializers for the implementation contract
    /// @dev This prevents the implementation contract from being initialized directly
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the upgradeable contract with default settings and roles
    /// @dev This function replaces the constructor for upgradeable contracts.
    ///      It sets up all the inherited contracts and grants initial roles to the deployer.
    ///      The current chain ID is automatically added to the supported chains list.
    function initialize(address _router, address _collateralToken, address _borrowToken) public initializer {
        if (_router == address(0)) revert ZeroAddress();
        if (_collateralToken == address(0)) revert ZeroAddress();
        if (_borrowToken == address(0)) revert ZeroAddress();

        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);

        router = _router;
        _checkTokenDataStream(_collateralToken);
        _checkTokenDataStream(_borrowToken);
        collateralToken = _collateralToken;
        borrowToken = _borrowToken;
        lastAccrued = block.timestamp; // Initialize to prevent incorrect first interest accrual

        emit CollateralTokenSet(_collateralToken);
        emit BorrowTokenSet(_borrowToken);
    }

    // =============================================================
    //                       VIEW FUNCTIONS
    // =============================================================

    /// @notice Returns the number of NFTs a user has deposited as collateral
    /// @param _user The user address to check
    /// @return The number of NFT tokens deposited by the user
    function userCollateral(address _user) public view returns (uint256) {
        return userCollateralTokenIds[_user].length;
    }

    /// @notice Returns the total number of NFTs deposited as collateral
    /// @return The total number of NFT tokens deposited
    function totalCollateral() public view returns (uint256) {
        return totalCollateralNfts;
    }

    /// @notice Returns all NFT token IDs deposited by a user
    /// @param _user The user address to check
    /// @return Array of NFT token IDs deposited by the user
    function getUserCollateralTokenIds(address _user) public view returns (uint256[] memory) {
        return userCollateralTokenIds[_user];
    }

    // =============================================================
    //                       CORE FUNCTIONS
    // =============================================================

    /// @notice Supplies NFT collateral to the pool on behalf of a user
    /// @dev NFT collateral can be used to secure borrowing positions.
    ///      Interest is accrued before updating balances to ensure accurate accounting.
    /// @param _tokenId The NFT token ID to supply as collateral
    function supplyCollateral(uint256 _tokenId) public userAccessControl(msg.sender) whenNotPaused nonReentrant {
        accrueInterest();

        userCollateralTokenIds[msg.sender].push(_tokenId);
        totalCollateralNfts += 1;
        IERC721(collateralToken).safeTransferFrom(msg.sender, address(this), _tokenId);

        emit SupplyCollateral(msg.sender, collateralToken, _tokenId);
    }

    /// @notice Withdraws NFT collateral from the pool for a user
    /// @dev Validates that the user has the NFT deposited before withdrawal.
    ///      Interest is accrued before updating balances. Health check validates position AFTER withdrawal.
    /// @param _tokenId The NFT token ID to withdraw
    function withdrawCollateral(uint256 _tokenId) public userAccessControl(msg.sender) whenNotPaused nonReentrant {
        // Find and remove the token ID from user's collateral
        uint256[] storage tokenIds = userCollateralTokenIds[msg.sender];
        bool found = false;
        uint256 indexToRemove;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == _tokenId) {
                found = true;
                indexToRemove = i;
                break;
            }
        }

        if (!found) {
            revert InsufficientCollateral(collateralToken, _tokenId, tokenIds.length);
        }

        accrueInterest();

        // Update state BEFORE health check so it validates the post-withdrawal position
        // Remove token ID from array by swapping with last element and popping
        tokenIds[indexToRemove] = tokenIds[tokenIds.length - 1];
        tokenIds.pop();
        totalCollateralNfts -= 1;

        // Check health AFTER state update (critical for security)
        IIsHealthy(_isHealthy()).isHealthy(msg.sender, address(this));

        IERC721(collateralToken).safeTransferFrom(address(this), msg.sender, _tokenId);
        emit WithdrawCollateral(msg.sender, collateralToken, _tokenId);
    }

    /// @notice Supplies liquidity tokens to the pool for lending on behalf of a user
    /// @dev Uses a share-based system where shares represent proportional ownership of the pool.
    ///      If this is the first deposit, shares equal the amount. Otherwise, shares are calculated
    ///      proportionally based on existing pool size. Interest is accrued before calculations.
    /// @param _amount The amount of tokens to supply as liquidity (must be > 0)
    function supplyLiquidity(uint256 _amount) public userAccessControl(msg.sender) whenNotPaused nonReentrant {
        if (_amount == 0) revert ZeroAmount();
        accrueInterest();
        uint256 shares = 0;
        if (totalSupplyAssets == 0) {
            if (_amount < minSupplyAmount) revert MinSupplyAmountNotMet(borrowToken, _amount, minSupplyAmount);
            shares = _amount;
        } else {
            shares = (_amount * totalSupplyShares) / totalSupplyAssets;
        }

        userSupplyShares[msg.sender] += shares;
        totalSupplyShares += shares;
        totalSupplyAssets += _amount;
        IERC20(borrowToken).safeTransferFrom(msg.sender, address(this), _amount);
        emit SupplyLiquidity(msg.sender, borrowToken, _amount);
    }

    /// @notice Withdraws liquidity from the pool by burning shares and receiving underlying tokens
    /// @dev Converts shares back to tokens based on current pool ratio. Ensures sufficient liquidity
    ///      remains to cover outstanding borrows. Interest is accrued before calculations.
    /// @param _shares The number of shares to burn for withdrawal (must be > 0)
    function withdrawLiquidity(uint256 _shares) public userAccessControl(msg.sender) whenNotPaused nonReentrant {
        if (_shares == 0) revert ZeroAmount();
        if (_shares > userSupplyShares[msg.sender]) {
            revert InvalidShares(borrowToken, _shares, userSupplyShares[msg.sender]);
        }

        accrueInterest();
        uint256 amount = ((_shares * totalSupplyAssets) / totalSupplyShares);
        if (totalSupplyAssets - amount < totalBorrowAssets) {
            revert InsufficientLiquidity(borrowToken, amount, totalSupplyAssets);
        }

        userSupplyShares[msg.sender] -= _shares;
        totalSupplyShares -= _shares;
        totalSupplyAssets -= amount;

        IERC20(borrowToken).safeTransfer(msg.sender, amount);
        emit WithdrawLiquidity(msg.sender, borrowToken, amount);
    }

    /// @notice Borrows tokens from the pool, potentially cross-chain via LayerZero
    /// @dev Supports both same-chain and cross-chain borrowing. For cross-chain borrows,
    ///      uses LayerZero's OApp to send tokens to the destination chain.
    ///      Interest is accrued before borrowing. Health checks are currently commented out.
    /// @param _amount The amount of tokens to borrow (must be > 0)
    function borrow(uint256 _amount) public payable userAccessControl(msg.sender) whenNotPaused nonReentrant {
        if (_amount == 0) revert ZeroAmount();
        accrueInterest();

        // Check if the new borrow would exceed max utilization

        _borrow(msg.sender, _amount);
        IIsHealthy(_isHealthy()).isHealthy(msg.sender, address(this));
        IERC20(borrowToken).safeTransfer(msg.sender, _amount);
        emit Borrow(msg.sender, borrowToken, _amount);
    }

    /// @notice Repays borrowed tokens by burning borrow shares
    /// @dev Converts shares to token amount based on current borrow pool ratio.
    ///      Interest is accrued before calculations to ensure accurate repayment amounts.
    /// @param _shares The number of borrow shares to burn for repayment (must be > 0)
    function repay(uint256 _shares) public userAccessControl(msg.sender) whenNotPaused nonReentrant {
        if (_shares == 0) revert ZeroAmount();
        if (_shares > userBorrowShares[msg.sender]) {
            revert InvalidShares(borrowToken, _shares, userBorrowShares[msg.sender]);
        }
        accrueInterest();

        uint256 amount = ((_shares * totalBorrowAssets) / totalBorrowShares);

        userBorrowShares[msg.sender] -= _shares;
        totalBorrowShares -= _shares;
        totalBorrowAssets -= amount;

        IERC20(borrowToken).safeTransferFrom(msg.sender, address(this), amount);
        emit Repay(msg.sender, borrowToken, amount);
    }

    function liquidation(address _borrower) public whenNotPaused nonReentrant {
        (bool isLiquidatable, uint256 borrowValue, uint256 collateralValue, uint256 liquidationAllocationValue) =
            IIsHealthy(_isHealthy()).checkLiquidatable(_borrower, address(this));
        if (!isLiquidatable) revert AssetNotLiquidatable(collateralToken, collateralValue, borrowValue);

        // Store values before modifying state
        uint256[] memory borrowerCollateralTokenIds = userCollateralTokenIds[_borrower];
        uint256 userBorrowAssets = userBorrowShares[_borrower] * totalBorrowAssets / totalBorrowShares;

        // Calculate NFT allocation based on liquidation percentage
        // liquidationAllocation represents the value that should go back to borrower
        // The rest goes to the liquidator
        uint256 totalNfts = borrowerCollateralTokenIds.length;
        uint256 nftsToReturn = 0;

        if (collateralValue > 0 && totalNfts > 0) {
            // Calculate percentage to return to borrower
            nftsToReturn = (liquidationAllocationValue * totalNfts) / collateralValue;
            if (nftsToReturn > totalNfts) nftsToReturn = totalNfts;
        }

        uint256 nftsToLiquidator = totalNfts - nftsToReturn;

        // Arrays to track which NFTs go where
        uint256[] memory liquidatorTokenIds = new uint256[](nftsToLiquidator);
        uint256[] memory borrowerTokenIds = new uint256[](nftsToReturn);

        // Allocate NFTs: first ones to liquidator, rest to borrower
        for (uint256 i = 0; i < nftsToLiquidator; i++) {
            liquidatorTokenIds[i] = borrowerCollateralTokenIds[i];
        }
        for (uint256 i = 0; i < nftsToReturn; i++) {
            borrowerTokenIds[i] = borrowerCollateralTokenIds[nftsToLiquidator + i];
        }

        // Update state
        totalBorrowAssets -= userBorrowAssets;
        totalBorrowShares -= userBorrowShares[_borrower];
        totalCollateralNfts -= totalNfts;
        userBorrowShares[_borrower] = 0;
        delete userCollateralTokenIds[_borrower];

        // Transfers - borrow token from liquidator to pool
        IERC20(borrowToken).safeTransferFrom(msg.sender, address(this), userBorrowAssets);

        // Transfer NFTs to liquidator
        for (uint256 i = 0; i < nftsToLiquidator; i++) {
            IERC721(collateralToken).safeTransferFrom(address(this), msg.sender, liquidatorTokenIds[i]);
        }

        // Transfer remaining NFTs back to borrower
        for (uint256 i = 0; i < nftsToReturn; i++) {
            IERC721(collateralToken).safeTransferFrom(address(this), _borrower, borrowerTokenIds[i]);
        }

        emit Liquidation(
            _borrower,
            borrowToken,
            collateralToken,
            userBorrowAssets,
            borrowerCollateralTokenIds,
            liquidatorTokenIds,
            borrowerTokenIds
        );
    }

    // TODO: Repay With Collateral connecting with vault

    // =============================================================
    //                    ADMINISTRATIVE FUNCTIONS
    // =============================================================

    function setMinSupplyAmount(uint256 _amount) public onlyRole(OWNER_ROLE) {
        minSupplyAmount = _amount;
        emit MinSupplyAmountSet(borrowToken, _amount);
    }

    /// @notice Sets the router contract address
    /// @dev The router manages cross-chain configurations and token mappings.
    ///      Only OWNER_ROLE can call this.
    /// @param _router The new router contract address
    function setRouter(address _router) public onlyRole(OWNER_ROLE) {
        if (_router == address(0)) revert ZeroAddress();
        router = _router;
        emit RouterSet(_router);
    }

    function setLtv(uint256 _ltv) public onlyRole(OWNER_ROLE) {
        ltv = _ltv;
        emit LtvSet(_ltv);
    }

    // =============================================================
    //                    INTEREST CALCULATION
    // =============================================================

    /// @notice Accrues interest for all borrow tokens based on elapsed time and current borrow rate
    /// @dev Calculates interest based on total borrowed assets and time elapsed since last accrual.
    ///      Interest is added to both supply and borrow totals. Updates lastAccrued timestamp.
    ///      Skips tokens with no borrows or uninitialized timestamps.
    function accrueInterest() public {
        _accrueInterest();
    }

    function _accrueInterest() internal {
        if (totalBorrowAssets == 0) return;

        uint256 elapsedTime = block.timestamp - lastAccrued;
        if (elapsedTime == 0) return; // No time elapsed, skip

        uint256 borrowRate = IInterestRateModel(_interestRateModel()).calculateBorrowRate(address(this));
        uint256 interest =
            IInterestRateModel(_interestRateModel()).calculateInterest(address(this), borrowRate, elapsedTime);

        totalSupplyAssets += interest;
        totalBorrowAssets += interest;
        lastAccrued = block.timestamp;
    }

    // =============================================================
    //                    INTERNAL HELPER FUNCTIONS
    // =============================================================

    /// @notice Internal function to validate that a token has a configured price feed
    /// @dev Checks if the token has a price feed set in the TokenDataStream contract
    /// @param _token The token address to validate
    function _checkTokenDataStream(address _token) internal view {
        if (ITokenDataStream(IRouter(router).tokenDataStream()).tokenPriceFeed(_token) == address(0)) {
            revert TokenDataStreamNotSet(_token);
        }
    }

    function _isHealthy() internal view returns (address) {
        return IRouter(router).isHealthy();
    }

    /// @notice Internal function to handle borrow logic and share calculation
    /// @dev Calculates borrow shares based on current pool ratio, updates user and total balances.
    ///      Validates sufficient liquidity exists. Health check is currently commented out.
    /// @param _user The user address borrowing tokens
    /// @param _amount The amount of tokens to borrow
    function _borrow(address _user, uint256 _amount) internal {
        uint256 shares = 0;
        if (totalBorrowShares == 0) shares = _amount;
        else shares = ((_amount * totalBorrowShares) / totalBorrowAssets);

        userBorrowShares[_user] += shares;
        totalBorrowShares += shares;
        totalBorrowAssets += _amount;
        if (totalBorrowAssets > totalSupplyAssets) {
            revert InsufficientLiquidity(borrowToken, _amount, totalSupplyAssets);
        }

        uint256 newUtilization = (totalBorrowAssets * 1e18) / totalSupplyAssets;
        uint256 maxUtilization = IInterestRateModel(_interestRateModel()).lendingPoolMaxUtilization(address(this));
        if (newUtilization >= maxUtilization) revert MaxUtilizationReached(borrowToken, newUtilization, maxUtilization);
    }

    function _interestRateModel() internal view returns (address) {
        return IRouter(router).interestRateModel();
    }

    // =============================================================
    //                    EMERGENCY & UPGRADE FUNCTIONS
    // =============================================================

    /// @notice Pauses all contract operations
    /// @dev Only accounts with PAUSER_ROLE can call this function.
    ///      When paused, most contract functions will revert.
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses all contract operations
    /// @dev Only accounts with PAUSER_ROLE can call this function.
    ///      Resumes normal contract functionality.
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Authorizes contract upgrades
    /// @dev Only accounts with UPGRADER_ROLE can authorize upgrades.
    ///      This is required by the UUPSUpgradeable pattern.
    /// @param newImplementation The address of the new implementation contract
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /// @notice Receives Ether sent to the contract
    /// @dev Required for cross-chain operations that may involve native token transfers
    receive() external payable {}

    /// @notice Fallback function for any calls with invalid function signatures
    /// @dev Required for cross-chain operations that may involve native token transfers
    fallback() external payable {}

    /// @notice Handles the receipt of an NFT
    /// @dev Required by IERC721Receiver to accept safeTransferFrom
    /// @return bytes4 The function selector to confirm the token transfer
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
