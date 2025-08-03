// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {AlpyDAO} from "../src/AlpyDAO.sol";

contract DAOProposalFlow is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        AlpyDAO dao = AlpyDAO(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0);

        dao.propose(
            0x0000000000000000000000000000000000000001,
            0,
            abi.encodeWithSignature("doSomething()"),
            "Execute doSomething"
        );

        dao.vote(0, true);

        vm.stopBroadcast();
    }
}
