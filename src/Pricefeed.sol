// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Pricefeed
 * @author Pulend Protocol Team
 * @notice Price feed contract that stores and manages token price data
 * @dev This contract implements a Chainlink-compatible price feed interface
 *      for providing token price information to the lending protocol.
 *      It stores price data with standard Chainlink aggregator format including
 *      round information and timestamps.
 *
 * Key Features:
 * - Chainlink aggregator-compatible interface
 * - Owner-controlled price updates
 * - Round-based price history
 * - Configurable decimals precision
 * - Token-specific price feeds
 */
contract Pricefeed is Ownable {
    // =============================================================
    //                           ERRORS
    // =============================================================

    /// @notice Thrown when a price feed is not properly configured for a token
    /// @param token The token address that doesn't have a price feed set
    error PricefeedNotSet(address token);

    // =============================================================
    //                       STATE VARIABLES
    // =============================================================

    /// @notice Number of decimals for price precision (default: 8, like Chainlink)
    uint8 public decimals = 8;

    /// @notice Current round ID for price updates
    uint80 public idRound;

    /// @notice Current price answer for the token
    int256 public priceAnswer;

    /// @notice Timestamp when the current round was started
    uint256 public startedAt;

    /// @notice Timestamp when the price was last updated
    uint256 public updated;

    /// @notice Round ID when the current answer was computed
    uint80 public answeredInRound;

    /// @notice Address of the token this price feed represents
    address public token;

    // =============================================================
    //                           EVENTS
    // =============================================================

    /// @notice Emitted when price data is updated
    /// @param idRound The round ID
    /// @param priceAnswer The new price
    /// @param startedAt When the round started
    /// @param updated When the price was updated
    /// @param answeredInRound The round when this answer was computed
    event PriceSet(uint80 idRound, int256 priceAnswer, uint256 startedAt, uint256 updated, uint80 answeredInRound);

    /// @notice Emitted when the token address is updated
    /// @param token The new token address
    event TokenSet(address token);

    // =============================================================
    //                           CONSTRUCTOR
    // =============================================================

    /// @notice Initializes the Pricefeed contract for a specific token
    /// @dev Sets up Ownable with deployer as owner and assigns the token address
    /// @param _token The address of the token this price feed will represent
    constructor(address _token) Ownable(msg.sender) {
        setToken(_token);
    }

    // =============================================================
    //                    ADMINISTRATION FUNCTIONS
    // =============================================================

    /// @notice Updates the price data for the token
    /// @dev Only the contract owner can update price data. Follows Chainlink aggregator format.
    /// @param _idRound The round ID for this price update
    /// @param _priceAnswer The price with configured decimals precision
    /// @param _startedAt Timestamp when this round started
    /// @param _updated Timestamp when this price was last updated
    /// @param _answeredInRound The round ID when this answer was computed
    function setPrice(
        uint80 _idRound,
        int256 _priceAnswer,
        uint256 _startedAt,
        uint256 _updated,
        uint80 _answeredInRound
    ) public onlyOwner {
        idRound = _idRound;
        priceAnswer = _priceAnswer;
        startedAt = _startedAt;
        updated = _updated;
        answeredInRound = _answeredInRound;

        emit PriceSet(_idRound, _priceAnswer, _startedAt, _updated, _answeredInRound);
    }

    /// @notice Sets the token address this price feed represents
    /// @dev Only the contract owner can update the token address
    /// @param _token The new token address
    function setToken(address _token) public onlyOwner {
        token = _token;
        emit TokenSet(_token);
    }

    // =============================================================
    //                        VIEW FUNCTIONS
    // =============================================================

    /// @notice Returns the latest price data in Chainlink aggregator format
    /// @dev This function provides compatibility with Chainlink AggregatorV3Interface
    /// @return roundId The round ID
    /// @return answer The price answer
    /// @return startedAt When the round started
    /// @return updatedAt When the price was last updated
    /// @return answeredInRound The round when this answer was computed
    function latestRoundData() public view returns (uint80, int256, uint256, uint256, uint80) {
        return (idRound, priceAnswer, startedAt, updated, answeredInRound);
    }
}
