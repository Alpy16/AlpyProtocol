// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AlpyToken.sol";
import "./LendingPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract RewardDistributor is Ownable, ReentrancyGuard {
    AlpyToken public immutable rewardToken;
    LendingPool public immutable lendingPool;

    uint256 public emissionRate;
    uint256 public lastUpdate;
    bool public paused;

    uint256 public constant MAX_EMISSION_RATE = 10 ether;

    address[] public rewardTokens;
    mapping(address => bool) public isRewarded;

    mapping(address => uint256) public supplyIndex;
    mapping(address => uint256) public borrowIndex;

    mapping(address => mapping(address => uint256)) public userSupplyIndex;
    mapping(address => mapping(address => uint256)) public userBorrowIndex;

    event Claimed(address indexed user, uint256 amount);
    event EmissionRateUpdated(uint256 newRate);
    event Paused(bool status);
    event TokenAdded(address token);

    constructor(
        address _rewardToken,
        address _lendingPool,
        uint256 _emissionRate
    ) Ownable(msg.sender) {
        require(_emissionRate <= MAX_EMISSION_RATE, "Initial rate too high");
        rewardToken = AlpyToken(_rewardToken);
        lendingPool = LendingPool(_lendingPool);
        emissionRate = _emissionRate;
        lastUpdate = block.timestamp;
    }

    function updateIndices() public {
        if (paused) return;

        uint256 elapsed = block.timestamp - lastUpdate;
        if (elapsed == 0) return;

        uint256 totalReward = emissionRate * elapsed;
        uint256 half = totalReward / 2;

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            if (!isRewarded[token]) continue;

            (, , , , , uint256 totalSupplied, uint256 totalDebt) = lendingPool
                .assetData(token);

            if (totalSupplied > 0) {
                supplyIndex[token] += (half * 1e18) / totalSupplied;
            }

            if (totalDebt > 0) {
                borrowIndex[token] += (half * 1e18) / totalDebt;
            }
        }

        lastUpdate = block.timestamp;
    }

    function claim() external nonReentrant {
        updateIndices();

        uint256 totalReward;
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            if (!isRewarded[token]) continue;

            uint256 supplied = lendingPool.collateral(msg.sender, token);
            uint256 borrowed = lendingPool.debt(msg.sender, token);

            uint256 supplyDelta = supplyIndex[token] -
                userSupplyIndex[msg.sender][token];
            uint256 borrowDelta = borrowIndex[token] -
                userBorrowIndex[msg.sender][token];

            if (supplied > 0) {
                totalReward += (supplyDelta * supplied) / 1e18;
            }

            if (borrowed > 0) {
                totalReward += (borrowDelta * borrowed) / 1e18;
            }

            userSupplyIndex[msg.sender][token] = supplyIndex[token];
            userBorrowIndex[msg.sender][token] = borrowIndex[token];
        }

        if (totalReward > 0) {
            uint256 balance = rewardToken.balanceOf(address(this));
            uint256 payout = totalReward > balance ? balance : totalReward;
            if (payout > 0) {
                rewardToken.transfer(msg.sender, payout);
                emit Claimed(msg.sender, payout);
            }
        }
    }

    function addRewardToken(address token) external onlyOwner {
        require(!isRewarded[token], "Already added");
        require(lendingPool.isSupported(token), "Not supported in pool");
        isRewarded[token] = true;
        rewardTokens.push(token);
        emit TokenAdded(token);
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    function setEmissionRate(uint256 newRate) external onlyOwner {
        require(newRate <= MAX_EMISSION_RATE, "Rate too high");
        updateIndices();
        emissionRate = newRate;
        emit EmissionRateUpdated(newRate);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        rewardToken.transfer(to, amount);
    }
}
