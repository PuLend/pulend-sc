// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IOracle
 * @author Pulend Protocol Team
 * @notice Interface for oracle contracts that provide price data
 * @dev This interface follows the Chainlink AggregatorV3Interface standard
 *      for compatibility with existing price feed infrastructure
 */
interface IOracle {
    /// @notice Returns the latest price data in Chainlink aggregator format
    /// @dev This function provides compatibility with Chainlink AggregatorV3Interface
    /// @return roundId The round ID
    /// @return answer The price answer
    /// @return startedAt When the round started
    /// @return updatedAt When the price was last updated
    /// @return answeredInRound The round when this answer was computed
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);

    /// @notice Returns the number of decimals for the price data
    /// @return The number of decimals used by this oracle (typically 8 for Chainlink compatibility)
    function decimals() external view returns (uint8);
}
