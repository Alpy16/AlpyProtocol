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
    error TransferFailed();

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

    function getVotingPower(address user) external view returns (uint256) {
        Stake storage s = stakes[user];
        if (block.timestamp >= s.lockEnd) return 0;
        return s.amount * s.lockDuration;
    }

    function slash(address user) external onlyAuthorized {
        if (block.timestamp < lastSlashed[user] + COOLDOWN)
            revert CooldownActive();

        uint256 stakeAmt = stakes[user].amount;
        uint256 tokenBal = stakingToken.balanceOf(user);
        uint256 stakeSlash;
        uint256 tokenSlash;
        uint256 totalSlashed;

        if (stakeAmt > 0) {
            stakeSlash = (stakeAmt * SLASH_PERCENT_WITH_STAKE) / 100;
            stakes[user].amount -= stakeSlash;
            stakingToken.safeTransfer(treasury, stakeSlash);
            totalSlashed += stakeSlash;
        }

        if (tokenBal > 0) {
            tokenSlash =
                (tokenBal *
                    (
                        stakeAmt > 0
                            ? SLASH_PERCENT_WITH_STAKE
                            : SLASH_PERCENT_NO_STAKE
                    )) /
                100;
            bool success = stakingToken.transferFrom(
                user,
                treasury,
                tokenSlash
            );
            if (!success) revert TransferFailed();
            totalSlashed += tokenSlash;
        }

        if (totalSlashed == 0) revert NothingToSlash();

        slashCount[user]++;
        bannedUntil[user] = block.timestamp + (7 days << slashCount[user]);

        lastSlashed[user] = block.timestamp;

        emit Slashed(user, stakeSlash, tokenSlash, bannedUntil[user]);
    }

    function setReviewer(address reviewer, bool status) external {
        if (msg.sender != DAO) revert NotAuthorized();
        isReviewer[reviewer] = status;
    }
}
