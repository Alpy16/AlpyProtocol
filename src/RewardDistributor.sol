// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AlpyToken.sol";
import "./LendingPool.sol";

contract RewardDistributor {
    AlpyToken public immutable rewardToken;
    LendingPool public immutable lendingPool;
    mapping(address => uint256) public lastClaim;

    error NoDebtToClaim();
    error RewardAlreadyClaimed();

    constructor(address _rewardToken, address _lendingPool) {
        rewardToken = AlpyToken(_rewardToken);
        lendingPool = LendingPool(_lendingPool);
    }

    function claim() external {
        uint256 totalDebt = lendingPool.getTotalDebt(msg.sender);
        if (totalDebt == 0) revert NoDebtToClaim();

        uint256 timeElapsed = block.timestamp - lastClaim[msg.sender];
        if (timeElapsed == 0) revert RewardAlreadyClaimed();

        uint256 reward = (totalDebt * timeElapsed) / 1 days;
        lastClaim[msg.sender] = block.timestamp;

        rewardToken.transfer(msg.sender, reward);
    }
}
