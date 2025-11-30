// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title USDC
 * @author Pulend Protocol Team
 * @notice Mock USDC token contract for testing and development purposes
 * @dev This contract implements a simple ERC20 token that mimics USDC characteristics
 *      including 6 decimal places. It includes mint and burn functionality for testing.
 *      This contract should only be used in development/testing environments.
 *
 * Key Features:
 * - ERC20 compliant token with USDC branding
 * - 6 decimal places (matching real USDC)
 * - Unrestricted minting capability for testing
 * - Burn functionality for token removal
 * - Owner-based access control
 */
contract USDC is ERC20, Ownable {
    /// @notice Initializes the mock USDC token
    /// @dev Sets up the ERC20 token with "USDC" name and symbol, and sets deployer as owner
    constructor() ERC20("USDC", "USDC") Ownable(msg.sender) {}

    /// @notice Returns the number of decimals for the token
    /// @dev Overrides the default ERC20 decimals to match real USDC (6 decimals)
    /// @return The number of decimals (6)
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /// @notice Mints new tokens to a specified address
    /// @dev This function is public and unrestricted for testing purposes
    /// @param _to The address to receive the newly minted tokens
    /// @param _amount The amount of tokens to mint
    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    /// @notice Burns tokens from a specified address
    /// @dev This function is public and unrestricted for testing purposes
    /// @param _from The address to burn tokens from
    /// @param _amount The amount of tokens to burn
    function burn(address _from, uint256 _amount) public {
        _burn(_from, _amount);
    }
}
