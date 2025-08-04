// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {AlpyDAO} from "src/AlpyDAO.sol";

contract VoteForProposal is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        AlpyDAO dao = AlpyDAO(0x34A1D3fff3958843C43aD80F30b94c510645C316);
        dao.vote(0, true); // proposalId = 0

        vm.stopBroadcast();
    }
}
