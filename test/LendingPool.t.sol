// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {AlpyToken} from "../src/AlpyToken.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {MockAggregator} from "./mocks/MockAggregator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendingPoolTest is Test {
    AlpyToken token;
    LendingPool pool;
    address user = address(1);

    function setUp() public {
        token = new AlpyToken();
        pool = new LendingPool(address(this));
        pool.addAsset(address(token), 0, 0, 0, 1e18, 0);
        MockAggregator agg = new MockAggregator(1e8, 8);
        pool.setPriceFeed(address(token), agg);
        deal(address(token), user, 1_000 ether);
    }

    function testSupplyBorrowRepayWithdraw() public {
        vm.startPrank(user);
        token.approve(address(pool), 1_000 ether);
        pool.supply(token, 1_000 ether);
        pool.borrow(token, 500 ether);
        token.approve(address(pool), 500 ether);
        pool.repay(token, 500 ether, user);
        pool.withdraw(token, 1_000 ether, user);
        vm.stopPrank();
        assertEq(token.balanceOf(user), 1_000 ether);
    }
}
