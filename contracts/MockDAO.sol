// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IVetoVault {
    function queueProposal(
        uint256 proposalId,
        address target,
        uint256 value,
        bytes calldata data
    ) external;
}

/**
 * @title MockDAO
 * @dev A simplified DAO Governor that simulates a proposal passing and 
 * handing off execution to the VetoVault for the challenge period.
 */
contract MockDAO is Ownable {
    IVetoVault public vault;
    uint256 public proposalCount;

    event ProposalPassed(uint256 indexed proposalId, address target, uint256 value, bytes data);

    constructor(address _vault) Ownable(msg.sender) {
        vault = IVetoVault(_vault);
    }

    /**
     * @dev Sets the VetoVault address.
     */
    function setVault(address _vault) external onlyOwner {
        vault = IVetoVault(_vault);
    }

    /**
     * @dev Simulates a proposal that has reached quorum and passed.
     * Instead of executing immediately, it queues it in the VetoVault.
     */
    function passProposal(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyOwner {
        uint256 proposalId = uint256(keccak256(abi.encodePacked(block.timestamp, proposalCount)));
        proposalCount++;

        emit ProposalPassed(proposalId, target, value, data);

        // Hand off to VetoVault
        vault.queueProposal(proposalId, target, value, data);
    }

    /**
     * @dev Fallback to receive funds if the DAO is the treasury holder.
     */
    receive() external payable {}
}