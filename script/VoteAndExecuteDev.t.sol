// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {AlpyDAO} from "src/AlpyDAO.sol";

//this is a dev version of Vote and Execute scripts combined into one for testing purposes
//it votes on the first proposal and executes it after the voting period
// this is not meant for production use, it also warps time to simulate the voting period
// in production, you would run the vote and execute scripts separately
contract VoteAndExecuteDev is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        AlpyDAO dao = AlpyDAO(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0);
        dao.vote(0, true);

        vm.warp(block.timestamp + 3601); // replace with actual votingPeriod
        dao.executeProposal(0);

        vm.stopBroadcast();
    }
}
