// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {MockERC20} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vendor/forge-std/src/mocks/MockERC20.sol";
import {AlpyToken} from "src/AlpyToken.sol";

contract LiquidationFlow is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(pk);
        vm.startBroadcast(pk);

        console.log("---- Liquidation Debug ----");

        AlpyToken alpy = AlpyToken(0x5FbDB2315678afecb367f032d93F642f64180aa3); // Collateral
        MockERC20 debtToken = MockERC20(
            0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
        ); // Debt token with mint()
        LendingPool pool = LendingPool(
            0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
        );

        alpy.approve(address(pool), 100 ether);
        pool.supply(address(alpy), 100 ether);

        debtToken.mint(user, 100 ether);
        debtToken.approve(address(pool), 100 ether);
        pool.borrow(address(debtToken), 100 ether);

        // Optional: Simulate price change here via oracle (if needed)

        pool.liquidate(address(alpy), user, 100 ether);

        vm.stopBroadcast();
    }
}
