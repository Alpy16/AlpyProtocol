// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {AlpyToken} from "../src/AlpyToken.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {RewardDistributor} from "../src/RewardDistributor.sol";
import {MockAggregator} from "./mocks/MockAggregator.sol";

contract RewardDistributorTest is Test {
    AlpyToken token;
    LendingPool pool;
    RewardDistributor distributor;
    address user = address(1);

    function setUp() public {
        token = new AlpyToken();
        pool = new LendingPool(address(this));
        pool.addAsset(address(token), 0, 0, 0, 1e18, 0);
        MockAggregator agg = new MockAggregator(1e8, 8);
        pool.setPriceFeed(address(token), agg);
        distributor = new RewardDistributor(address(token), address(pool), 1e18);
        distributor.addRewardToken(address(token));
        deal(address(token), address(distributor), 1_000 ether);
        deal(address(token), user, 1_000 ether);
    }

    function testClaimRewards() public {
        vm.startPrank(user);
        token.approve(address(pool), 100 ether);
        pool.supply(token, 100 ether);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);
        distributor.updateIndices();

        vm.prank(user);
        distributor.claim();

        assertGt(token.balanceOf(user), 900 ether); // earned some rewards
    }
}
