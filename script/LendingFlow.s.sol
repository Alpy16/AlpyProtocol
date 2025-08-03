// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LendingPool} from "../src/LendingPool.sol";

contract LendingFlow is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address poolAddr = vm.envAddress("POOL_ADDRESS");
        address tokenAddr = vm.envAddress("TOKEN_ADDRESS");
        address user = vm.addr(pk);

        vm.startBroadcast(pk);

        LendingPool pool = LendingPool(poolAddr);
        IERC20 token = IERC20(tokenAddr);

        token.approve(address(pool), 1_000 ether);
        pool.supply(token, 1_000 ether);
        pool.borrow(token, 500 ether);
        token.approve(address(pool), 500 ether);
        pool.repay(token, 500 ether, user);
        pool.withdraw(token, 1_000 ether, user);

        vm.stopBroadcast();
    }
}
