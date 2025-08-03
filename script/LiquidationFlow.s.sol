// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LendingPool} from "../src/LendingPool.sol";

contract LiquidationFlow is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address poolAddr = vm.envAddress("POOL_ADDRESS");
        address collateral = vm.envAddress("COLLATERAL_TOKEN");
        address borrower = vm.envAddress("BORROWER");
        uint256 repayAmount = vm.envUint("REPAY_AMOUNT");

        vm.startBroadcast(pk);

        LendingPool pool = LendingPool(poolAddr);
        pool.liquidate(IERC20(collateral), borrower, repayAmount);

        vm.stopBroadcast();
    }
}
