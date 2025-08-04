// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {DAOFactory} from "../src/DAOFactory.sol";

contract DeployAll is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        DAOFactory factory = new DAOFactory(5 minutes);

        console2.log("AlpyToken:", factory.token());
        console2.log("AlpyStaking:", factory.staking());
        console2.log("AlpyDAO:", factory.dao());
        console2.log("LendingPool:", factory.lending());

        vm.stopBroadcast();
    }
}
