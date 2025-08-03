// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {AlpyToken} from "../src/AlpyToken.sol";
import {AlpyStaking} from "../src/AlpyStaking.sol";

contract AlpyStakingTest is Test {
    AlpyToken token;
    AlpyStaking staking;
    address user = address(1);

    function setUp() public {
        token = new AlpyToken();
        staking = new AlpyStaking(address(token), address(this), address(this));
        deal(address(token), user, 1_000 ether);
    }

    function testStakeExtendWithdraw() public {
        vm.startPrank(user);
        token.approve(address(staking), 100 ether);
        staking.stake(100 ether, 7 days);
        staking.extendLock(14 days);
        vm.warp(block.timestamp + 14 days + 1);
        staking.withdraw();
        vm.stopPrank();
        assertEq(token.balanceOf(user), 1_000 ether);
    }
}
