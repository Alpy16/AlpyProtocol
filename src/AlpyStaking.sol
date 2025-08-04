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
    error NotAuthorized();
    error NothingToSlash();
    error CooldownActive();

    IERC20 public immutable stakingToken;
    address public immutable DAO;
    address public immutable treasury;

    uint256 public constant MAX_LOCK_DURATION = 180 days;
    uint256 public constant MIN_LOCK_DURATION = 7 days;

    uint256 public constant SLASH_PERCENT_WITH_STAKE = 10;
    uint256 public constant SLASH_PERCENT_NO_STAKE = 20;
    uint256 public constant COOLDOWN = 5 minutes;

    event Slashed(
        address indexed user,
        uint256 stakeSlashed,
        uint256 tokenSlashed,
        uint256 bannedUntil
    );

    struct Stake {
        uint256 amount;
        uint256 lockEnd;
        uint256 lockDuration;
    }

    mapping(address => Stake) public stakes;
    mapping(address => uint256) public slashCount;
    mapping(address => uint256) public bannedUntil;
    mapping(address => uint256) public lastSlashed;
    mapping(address => bool) public isReviewer;

    constructor(address _stakingToken, address _DAO, address _treasury) {
        stakingToken = IERC20(_stakingToken);
        DAO = _DAO;
        treasury = _treasury;
    }

    modifier onlyAuthorized() {
        if (msg.sender != DAO && !isReviewer[msg.sender])
            revert NotAuthorized();
        _;
    }

    function stake(uint256 amount, uint256 duration) external {
        if (amount == 0) revert ZeroAmount();
        if (duration < MIN_LOCK_DURATION || duration > MAX_LOCK_DURATION)
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

    function getVotes(address user) public view returns (uint256) {
        Stake storage s = stakes[user];
        if (block.timestamp >= s.lockEnd) return 0;
        return s.amount * s.lockDuration;
    }

    function getVotingPower(address user) external view returns (uint256) {
        return getVotes(user);
    }

    function slash(address user) external onlyAuthorized {
        // Prevent rapid repeated slashing — require cooldown between slashes
        if (block.timestamp < lastSlashed[user] + COOLDOWN)
            revert CooldownActive();

        uint256 stakeAmt = stakes[user].amount;
        uint256 tokenBal = stakingToken.balanceOf(user);
        uint256 allowance = stakingToken.allowance(user, address(this));
        uint256 stakeSlash;
        uint256 tokenSlash;
        uint256 totalSlashed;

        // If the user has an active stake, slash 10% of it and send to treasury
        if (stakeAmt > 0) {
            stakeSlash = (stakeAmt * SLASH_PERCENT_WITH_STAKE) / 100;
            stakes[user].amount = stakeAmt - stakeSlash;
            stakingToken.safeTransfer(treasury, stakeSlash);
            totalSlashed += stakeSlash;
        }

        // Determine how much of the user's wallet balance we can slash (based on allowance)
        uint256 transferable = tokenBal < allowance ? tokenBal : allowance;

        // If we can slash wallet tokens, do it:
        // - Slash 10% if they have an active stake
        // - Slash 20% if they have no active stake
        if (transferable > 0) {
            tokenSlash =
                (transferable *
                    (
                        stakeAmt > 0
                            ? SLASH_PERCENT_WITH_STAKE
                            : SLASH_PERCENT_NO_STAKE
                    )) /
                100;
            stakingToken.safeTransferFrom(user, treasury, tokenSlash);
            totalSlashed += tokenSlash;
        }

        // If neither stake nor wallet tokens could be slashed, revert
        if (totalSlashed == 0) revert NothingToSlash();

        // Increment their slash count, and extend their ban duration exponentially (first ban 7 days, next ban 14 etc.)
        uint256 count = ++slashCount[user];
        bannedUntil[user] = block.timestamp + (7 days << (count - 1));

        // Update the timestamp of the slash, so we can do the cooldown period
        lastSlashed[user] = block.timestamp;

        emit Slashed(user, stakeSlash, tokenSlash, bannedUntil[user]);
    }
}
