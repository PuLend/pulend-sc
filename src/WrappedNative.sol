// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title WrappedNative
 * @author Pulend Protocol Team
 * @notice Contract that provides a constant reference to the wrapped native token
 * @dev This contract stores the address of the wrapped native token (like WETH) as a constant.
 *      The address appears to be for a specific chain's wrapped native token contract.
 *
 * Key Features:
 * - Immutable reference to wrapped native token address
 * - Gas-efficient constant storage
 * - Chain-specific wrapped token configuration
 */
contract WrappedNative {
    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /// @notice The address of the wrapped native token contract (e.g., WETH)
    /// @dev This appears to be a chain-specific address, possibly for Optimism or Base
    ///      where this address pattern is used for system contracts
    address public constant WRAPPED_ERC20 = 0x4200000000000000000000000000000000000006;
}
