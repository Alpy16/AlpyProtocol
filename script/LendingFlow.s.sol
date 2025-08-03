// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LendingPool} from "../src/LendingPool.sol";

contract LendingFlow is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        IERC20 token = IERC20(0x5FbDB2315678afecb367f032d93F642f64180aa3);
        LendingPool pool = LendingPool(
            0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
        );

        token.approve(address(pool), 1_000 ether);
        token.approve(address(pool), 1_000 ether);
        pool.supply(token, 1_000 ether);

        vm.stopBroadcast();
    }
}
