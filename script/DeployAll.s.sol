// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DAOFactory} from "../src/DAOFactory.sol";
import {console} from "forge-std/console.sol";

contract DeployAll is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        // Customize these as needed
        uint256 rewardRate = 5e18;
        uint256 votingPeriod = 3600;

        DAOFactory factory = new DAOFactory(rewardRate, votingPeriod);

        console.log("AlpyToken:", factory.token());
        console.log("AlpyStaking:", factory.staking());
        console.log("AlpyDAO:", factory.dao());
        console.log("LendingPool:", factory.lending());

        vm.stopBroadcast();
    }
}
