// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Router
 * @author Pulend Protocol Team
 * @notice Central routing contract that manages cross-chain configurations and token mappings
 * @dev This contract serves as a configuration hub for cross-chain operations, maintaining
 *      mappings between chain IDs, LayerZero endpoint IDs, OApp contracts, and token addresses.
 *      It provides a centralized way to manage cross-chain infrastructure without hardcoding
 *      addresses in the main lending contracts.
 *
 * Key Features:
 * - Chain ID to LayerZero endpoint ID mappings
 * - Chain ID to OApp contract address mappings
 * - Cross-chain token address mappings
 * - References to core protocol contracts (TokenDataStream, IsHealthy, LendingPool)
 */
contract Router is Ownable {
    // =============================================================
    //                       STATE VARIABLES
    // =============================================================

    /// @notice Address of the TokenDataStream contract that manages price feeds
    address public tokenDataStream;

    /// @notice Address of the IsHealthy contract that validates borrowing positions
    address public isHealthy;

    /// @notice Address of the main LendingPool contract
    address public lendingPool;

    /// @notice Address of the liquidator contract
    address public liquidator;

    /// @notice Address of the InterestRateModel contract
    address public interestRateModel;

    // =============================================================
    //                           ERRORS
    // =============================================================kj    
    error ZeroAddress();

    // =============================================================
    //                           EVENTS
    // =============================================================

    /// @notice Emitted when the TokenDataStream contract address is updated
    /// @param tokenDataStream The new TokenDataStream contract address
    event TokenDataStreamSet(address tokenDataStream);

    /// @notice Emitted when the IsHealthy contract address is updated
    /// @param isHealthy The new IsHealthy contract address
    event IsHealthySet(address isHealthy);

    /// @notice Emitted when the LendingPool contract address is updated
    /// @param lendingPool The new LendingPool contract address
    event LendingPoolSet(address lendingPool);

    /// @notice Emitted when the Liquidator contract address is updated
    /// @param liquidator The new Liquidator contract address
    event LiquidatorSet(address liquidator);

    /// @notice Emitted when the InterestRateModel contract address is updated
    /// @param interestRateModel The new InterestRateModel contract address
    event InterestRateModelSet(address interestRateModel);

    // =============================================================
    //                           CONSTRUCTOR
    // =============================================================

    /// @notice Initializes the Router contract and sets the deployer as owner
    /// @dev Sets up Ownable with the message sender as the initial owner
    constructor() Ownable(msg.sender) {}

    // =============================================================
    //                    CONFIGURATION FUNCTIONS
    // =============================================================

    /// @notice Sets the TokenDataStream contract address
    /// @dev Only the contract owner can call this function
    /// @param _tokenDataStream The address of the TokenDataStream contract
    function setTokenDataStream(address _tokenDataStream) public onlyOwner {
        if (_tokenDataStream == address(0)) revert ZeroAddress();
        tokenDataStream = _tokenDataStream;
        emit TokenDataStreamSet(_tokenDataStream);
    }

    /// @notice Sets the IsHealthy contract address
    /// @dev Only the contract owner can call this function
    /// @param _isHealthy The address of the IsHealthy contract
    function setIsHealthy(address _isHealthy) public onlyOwner {
        if (_isHealthy == address(0)) revert ZeroAddress();
        isHealthy = _isHealthy;
        emit IsHealthySet(_isHealthy);
    }

    /// @notice Sets the LendingPool contract address
    /// @dev Only the contract owner can call this function
    /// @param _lendingPool The address of the LendingPool contract
    function setLendingPool(address _lendingPool) public onlyOwner {
        if (_lendingPool == address(0)) revert ZeroAddress();
        lendingPool = _lendingPool;
        emit LendingPoolSet(_lendingPool);
    }

    function setLiquidator(address _liquidator) public onlyOwner {
        if (_liquidator == address(0)) revert ZeroAddress();
        liquidator = _liquidator;
        emit LiquidatorSet(_liquidator);
    }

    function setInterestRateModel(address _interestRateModel) public onlyOwner {
        if (_interestRateModel == address(0)) revert ZeroAddress();
        interestRateModel = _interestRateModel;
        emit InterestRateModelSet(_interestRateModel);
    }
}
