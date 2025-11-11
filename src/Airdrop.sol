// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "../lib/openzeppelin-contracts/contracts/utils/Pausable.sol";

contract Airdrop is Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    
    bool public isAirdropStarted;
    uint256 public airdropEndTime;
    uint256 public totalAllocated;
    uint256 public totalClaimed;

    mapping(address => uint256) public allocations;  
    mapping(address => bool) public hasClaimed; 

    // Events
    event AirdropStarted(uint256 startTime, uint256 endTime);
    event WhitelistSet(address[] recipients, uint256[] amounts);
    event TokensClaimed(address indexed recipient, uint256 amount);
    event UnclaimedTokensRecovered(address indexed to, uint256 amount);
    event AllocationUpdated(address indexed recipient, uint256 oldAmount, uint256 newAmount);

    // Errors
    error AirdropAlreadyStarted();
    error AirdropNotStarted();
    error AirdropEnded();
    error AlreadyClaimed();
    error NoAllocation();
    error InsufficientContractBalance();
    error LengthMismatch();
    error ZeroAddress();
    error InvalidAmount();
    error AirdropStillActive();

    constructor(address tokenAddr) Ownable(msg.sender) {
        if (tokenAddr == address(0)) revert ZeroAddress();
        token = IERC20(tokenAddr);
    }

    /**
     * @notice Start the airdrop with an optional end time
     * @param duration Duration in seconds (0 for no end time)
     */
    function startAirdrop(uint256 duration) external onlyOwner {
        if (isAirdropStarted) revert AirdropAlreadyStarted();
        
        isAirdropStarted = true;
        if (duration > 0) {
            airdropEndTime = block.timestamp + duration;
        }
        
        emit AirdropStarted(block.timestamp, airdropEndTime);
    }

    /**
     * @notice Set allocations for multiple recipients
     * @param recipients Array of recipient addresses
     * @param amounts Array of token amounts
     * @param overwrite Allow overwriting existing allocations
     */
    function setWhitelist(
        address[] calldata recipients, 
        uint256[] calldata amounts,
        bool overwrite
    ) external onlyOwner {
        if (recipients.length != amounts.length) revert LengthMismatch();
        
        for (uint256 i = 0; i < recipients.length;) {
            if (recipients[i] == address(0)) revert ZeroAddress();
            if (amounts[i] == 0) revert InvalidAmount();
            
            uint256 oldAmount = allocations[recipients[i]];
            
            // Prevent accidental overwrites unless explicitly allowed
            if (oldAmount > 0 && !overwrite) {
                revert InvalidAmount(); // Or create a specific error: AllocationExists
            }
            
            // Update total allocated
            if (oldAmount > 0) {
                totalAllocated -= oldAmount;
            }
            totalAllocated += amounts[i];
            
            allocations[recipients[i]] = amounts[i];
            
            if (oldAmount != amounts[i]) {
                emit AllocationUpdated(recipients[i], oldAmount, amounts[i]);
            }
            
            unchecked { ++i; }
        }
        
        emit WhitelistSet(recipients, amounts);
    }

    /**
     * @notice Claim allocated tokens
     */
    function claimTokens() external whenNotPaused {
        if (!isAirdropStarted) revert AirdropNotStarted();
        if (airdropEndTime > 0 && block.timestamp > airdropEndTime) revert AirdropEnded();
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();

        uint256 amount = allocations[msg.sender];
        if (amount == 0) revert NoAllocation();

        uint256 contractBalance = token.balanceOf(address(this));
        if (contractBalance < amount) revert InsufficientContractBalance();

        hasClaimed[msg.sender] = true;
        totalClaimed += amount;
        
        token.safeTransfer(msg.sender, amount);
        
        emit TokensClaimed(msg.sender, amount);
    }

    /**
     * @notice Recover unclaimed tokens after airdrop ends
     * @param to Address to send unclaimed tokens
     */
    function recoverUnclaimedTokens(address to) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        if (airdropEndTime == 0 || block.timestamp <= airdropEndTime) {
            revert AirdropStillActive();
        }

        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.safeTransfer(to, balance);
            emit UnclaimedTokensRecovered(to, balance);
        }
    }

    /**
     * @notice Emergency withdrawal (only use if airdrop not started)
     * @param to Address to send tokens
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        if (isAirdropStarted) revert AirdropAlreadyStarted();
        
        token.safeTransfer(to, amount);
    }

    /**
     * @notice Pause claiming in case of emergency
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Resume claiming
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Get allocation info for an address
     * @param user Address to check
     * @return allocated Amount allocated
     * @return claimed Whether tokens have been claimed
     */
    function getAllocationInfo(address user) external view returns (
        uint256 allocated,
        bool claimed
    ) {
        return (allocations[user], hasClaimed[user]);
    }

    /**
     * @notice Get overall airdrop statistics
     */
    function getAirdropStats() external view returns (
        uint256 allocated,
        uint256 claimed,
        uint256 remaining,
        uint256 contractBalance
    ) {
        return (
            totalAllocated,
            totalClaimed,
            totalAllocated - totalClaimed,
            token.balanceOf(address(this))
        );
    }

    /**
     * @notice Check if airdrop is currently active
     */
    function isActive() external view returns (bool) {
        if (!isAirdropStarted) return false;
        if (airdropEndTime == 0) return true;
        return block.timestamp <= airdropEndTime;
    }
}
