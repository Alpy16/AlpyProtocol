// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {DAOFactory} from "../src/DAOFactory.sol";

contract DeployAll is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        uint256 votingPeriod = 3 days;

        vm.startBroadcast(deployerKey);

        DAOFactory factory = new DAOFactory(votingPeriod);

        address token = factory.token();
        address staking = factory.staking();
        address dao = factory.dao();
        address lending = factory.lending();

        console.log("Token:   ", token);
        console.log("Staking: ", staking);
        console.log("DAO:     ", dao);
        console.log("Lending: ", lending);

        vm.stopBroadcast();
    }
}
