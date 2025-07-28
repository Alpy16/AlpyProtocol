// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AlpyStaking {
    using SafeERC20 for IERC20;

    error ZeroAmount();
    error InvalidDuration();
    error AlreadyStaked();
    error NoStake();
    error LockNotExpired();

    IERC20 public immutable stakingToken;
    uint256 public constant MAX_LOCK_DURATION = 180 days;

    struct Stake {
        uint256 amount;
        uint256 lockEnd;
        uint256 lockDuration;
    }

    mapping(address => Stake) public stakes;

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }

    function stake(uint256 amount, uint256 duration) external {
        if (amount == 0) revert ZeroAmount();
        if (duration == 0 || duration > MAX_LOCK_DURATION)
            revert InvalidDuration();

        Stake storage s = stakes[msg.sender];
        if (s.amount > 0) revert AlreadyStaked();

        s.amount = amount;
        s.lockDuration = duration;
        s.lockEnd = block.timestamp + duration;

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function extendLock(uint256 newDuration) external {
        Stake storage s = stakes[msg.sender];
        if (s.amount == 0) revert NoStake();
        if (newDuration <= s.lockDuration || newDuration > MAX_LOCK_DURATION)
            revert InvalidDuration();

        s.lockDuration = newDuration;
        s.lockEnd = block.timestamp + newDuration;
    }

    function withdraw() external {
        Stake storage s = stakes[msg.sender];
        if (block.timestamp < s.lockEnd) revert LockNotExpired();

        uint256 amt = s.amount;
        delete stakes[msg.sender];
        stakingToken.safeTransfer(msg.sender, amt);
    }

    function getVotingPower(address user) external view returns (uint256) {
        Stake storage s = stakes[user];
        if (block.timestamp >= s.lockEnd) return 0;
        return s.amount * s.lockDuration;
    }
}
