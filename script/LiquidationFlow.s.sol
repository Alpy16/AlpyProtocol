// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/LendingPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidationFlow is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address poolAddr = vm.envAddress("LENDING_POOL");
        address borrower = vm.envAddress("BORROWER");
        address debtToken = vm.envAddress("DEBT_TOKEN");
        address collateralToken = vm.envAddress("COLLATERAL_TOKEN");
        uint256 repayAmount = vm.envUint("REPAY_AMOUNT");

        vm.startBroadcast(pk);
        LendingPool(poolAddr).liquidate(
            IERC20(debtToken),
            IERC20(collateralToken),
            borrower,
            repayAmount
        );
        vm.stopBroadcast();
    }
}
