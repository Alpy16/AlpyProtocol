// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {LendingPool} from "src/LendingPool.sol";
import {AlpyToken} from "src/AlpyToken.sol";
import {MockV3Aggregator} from "chainlink-brownie-contracts/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidationFlowTest is Test {
    LendingPool pool;
    AlpyToken collateralToken;
    AlpyToken debtToken;
    MockV3Aggregator collateralFeed;
    MockV3Aggregator debtFeed;
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        collateralToken = new AlpyToken();
        debtToken = new AlpyToken();
        pool = new LendingPool(address(this));
        collateralFeed = new MockV3Aggregator(8, 1e8);
        debtFeed = new MockV3Aggregator(8, 1e8);

        pool.addAsset(address(collateralToken), 0, 0, 0, 1e18, 0);
        pool.addAsset(address(debtToken), 0, 0, 0, 1e18, 0);
        pool.setPriceFeed(
            address(collateralToken),
            AggregatorV3Interface(address(collateralFeed))
        );
        pool.setPriceFeed(
            address(debtToken),
            AggregatorV3Interface(address(debtFeed))
        );

        collateralToken.transfer(alice, 200 ether);
        debtToken.transfer(bob, 200 ether);

        vm.prank(alice);
        collateralToken.approve(address(pool), type(uint256).max);

        vm.prank(bob);
        debtToken.approve(address(pool), type(uint256).max);

        // provide liquidity for debt token
        vm.prank(bob);
        pool.supply(IERC20(address(debtToken)), 100 ether);
    }

    function _setupBorrow() internal {
        vm.startPrank(alice);
        pool.supply(IERC20(address(collateralToken)), 100 ether);
        pool.borrow(IERC20(address(debtToken)), 40 ether);
        vm.stopPrank();
    }

    function testCannotLiquidateHealthyPosition() public {
        _setupBorrow();
        vm.prank(bob);
        vm.expectRevert(LendingPool.NotLiquidatable.selector);
        pool.liquidate(
            IERC20(address(debtToken)),
            IERC20(address(collateralToken)),
            alice,
            10 ether
        );
    }

    function testLiquidateCrossAsset() public {
        _setupBorrow();
        // collateral price drops by 30%
        collateralFeed.updateAnswer(0.7e8);

        vm.prank(bob);
        pool.liquidate(
            IERC20(address(debtToken)),
            IERC20(address(collateralToken)),
            alice,
            20 ether
        );

        assertEq(pool.debt(alice, address(debtToken)), 20 ether);

        uint256 price = pool.getPrice(address(collateralToken));
        uint256 repayUSD = 20 ether; // debt token price is 1
        uint256 seizeUSD = (repayUSD * 110) / 100;
        uint256 seizeAmountNormalized = (seizeUSD * 1e8) / price;
        uint256 expectedSeize = pool._changeDecimals(
            seizeAmountNormalized,
            18,
            18
        );

        assertEq(collateralToken.balanceOf(bob), expectedSeize);
    }
}
