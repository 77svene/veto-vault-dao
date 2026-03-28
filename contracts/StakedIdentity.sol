// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title StakedIdentity
 * @dev Wraps a governance token or acts as one, tracking the block timestamp of the last 
 * balance-changing event for every address. This "age" is used by VetoVault to 
 * validate long-term commitment.
 */
contract StakedIdentity is ERC20 {
    // Maps user address to the timestamp of their last balance change (mint/transfer)
    mapping(address => uint256) public lastTransferTimestamp;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Initial supply for testing/deployment
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }

    /**
     * @dev Returns the "age" of the stake in seconds.
     * If the user has no balance, age is 0.
     */
    function getStakeAge(address account) public view returns (uint256) {
        if (balanceOf(account) == 0 || lastTransferTimestamp[account] == 0) {
            return 0;
        }
        return block.timestamp - lastTransferTimestamp[account];
    }

    /**
     * @dev Overrides _update to refresh the lastTransferTimestamp whenever tokens move.
     * This resets the "age" of the stake to 0 upon receiving or sending tokens.
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        super._update(from, to, value);
        
        // Reset age for both sender and receiver to prevent "age-washing"
        // We update the timestamp to the current block for any balance change.
        if (from != address(0)) {
            lastTransferTimestamp[from] = block.timestamp;
        }
        if (to != address(0)) {
            lastTransferTimestamp[to] = block.timestamp;
        }
    }
}