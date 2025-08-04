// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {LendingPool} from "../../src/LendingPool.sol";
import {AlpyToken} from "../../src/AlpyToken.sol";
import {MockV3Aggregator} from "chainlink-brownie-contracts/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendingPoolTest is Test {
    LendingPool pool;
    AlpyToken token;
    MockV3Aggregator feed;
    address alice = address(0x1);

    function setUp() public {
        token = new AlpyToken();
        pool = new LendingPool(address(this));
        feed = new MockV3Aggregator(8, 1e8);

        pool.addAsset(address(token), 0, 0, 0, 1e18, 0);
        pool.setPriceFeed(address(token), AggregatorV3Interface(address(feed)));

        token.transfer(alice, 200 ether);
        vm.prank(alice);
        token.approve(address(pool), type(uint256).max);
    }

    function testWithdrawRevertsWhenDebtAtMaxLTV() public {
        vm.startPrank(alice);
        pool.supply(IERC20(address(token)), 100 ether);
        pool.borrow(IERC20(address(token)), 50 ether);
        vm.expectRevert(LendingPool.ExceedsLTV.selector);
        pool.withdraw(IERC20(address(token)), 1 ether);
        vm.stopPrank();
    }

    function testWithdrawWithinLTV() public {
        vm.startPrank(alice);
        pool.supply(IERC20(address(token)), 100 ether);
        pool.borrow(IERC20(address(token)), 40 ether);
        pool.withdraw(IERC20(address(token)), 10 ether);
        vm.stopPrank();
        assertEq(token.balanceOf(alice), 150 ether);
    }
}
