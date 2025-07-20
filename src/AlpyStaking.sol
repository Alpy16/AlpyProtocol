// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IAlpyDAO {
    function getVotes(address user) external view returns (uint256);
}

contract AlpyStaking {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;
    address public dao;

    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public totalStaked;

    mapping(address => uint256) public userStakes;
    mapping(address => uint256) public userRewards;
    mapping(address => uint256) public userRewardDebt;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    modifier onlyDAO() {
        require(msg.sender == dao, "Only DAO can call");
        _;
    }

    constructor(address _stakingToken, address _rewardToken, uint256 _rewardRate, address _dao) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _rewardRate;
        lastUpdateTime = block.timestamp;
        dao = _dao;
    }

    function setRewardRate(uint256 newRate) external onlyDAO {
        _updateRewards(address(0));
        rewardRate = newRate;
    }

    function stakeTokens(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        _updateRewards(msg.sender);
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Stake failed");
        userStakes[msg.sender] += amount;
        totalStaked += amount;
        userRewardDebt[msg.sender] = (userStakes[msg.sender] * rewardPerTokenStored) / 1e18;
        emit Staked(msg.sender, amount);
    }

    function withdrawStakedTokens(uint256 amount) external {
        require(amount > 0 && userStakes[msg.sender] >= amount, "Invalid withdraw");
        _updateRewards(msg.sender);
        userStakes[msg.sender] -= amount;
        totalStaked -= amount;
        userRewardDebt[msg.sender] = (userStakes[msg.sender] * rewardPerTokenStored) / 1e18;
        require(stakingToken.transfer(msg.sender, amount), "Withdraw failed");
        emit Unstaked(msg.sender, amount);
    }

    function withdrawEarnedRewards(uint256 amount) external {
        _updateRewards(msg.sender);
        require(userRewards[msg.sender] >= amount, "Insufficient rewards");
        userRewards[msg.sender] -= amount;
        require(rewardToken.transfer(msg.sender, amount), "Reward transfer failed");
        emit RewardsClaimed(msg.sender, amount);
    }

    function getVotes(address user) external view returns (uint256) {
        return userStakes[user];
    }

    function _updateRewards(address user) internal {
        uint256 timeElapsed = block.timestamp - lastUpdateTime;
        if (timeElapsed > 0 && totalStaked > 0) {
            uint256 reward = timeElapsed * rewardRate;
            rewardPerTokenStored += (reward * 1e18) / totalStaked;
            lastUpdateTime = block.timestamp;
        }

        if (user != address(0)) {
            uint256 delta = rewardPerTokenStored - userRewardDebt[user];
            uint256 earned = (userStakes[user] * delta) / 1e18;
            userRewards[user] += earned;
            userRewardDebt[user] = (userStakes[user] * rewardPerTokenStored) / 1e18;
        }
    }

    function setDao(address _dao) external {
        require(dao == address(0), "DAO already set");
        dao = _dao;
    }
}
