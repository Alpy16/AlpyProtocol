// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/LendingPool.sol";

contract DeployScript is Script {
    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        LendingPool pool = new LendingPool(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0);

        console.log("LendingPool deployed to:", address(pool));
        vm.stopBroadcast();
    }
}
