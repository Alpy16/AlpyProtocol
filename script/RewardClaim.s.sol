pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract LiquidationFlow is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        LendingPool pool = LendingPool(
            0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
        );
        IERC20 token = IERC20(0x5FbDB2315678afecb367f032d93F642f64180aa3);
        address user = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        uint256 repayAmount = 100 * 1e18;

        console2.log("Debt:", pool.debt(user, address(token)));
        console2.log("Collateral:", pool.collateral(user, address(token)));
        console2.log("Debt USD:", pool.getDebtValueUSD(user));
        console2.log("Collateral USD:", pool.getCollateralValueUSD(user));
        console2.log("LTV:", pool.getLTV());

        pool.liquidate(token, user, repayAmount);

        vm.stopBroadcast();
    }
}
