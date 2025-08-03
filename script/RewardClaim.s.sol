// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {RewardDistributor} from "../src/RewardDistributor.sol";

contract RewardClaim is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address distributorAddr = vm.envAddress("DISTRIBUTOR_ADDRESS");

        vm.startBroadcast(pk);

        RewardDistributor distributor = RewardDistributor(distributorAddr);
        distributor.claim();

        vm.stopBroadcast();
    }
}
