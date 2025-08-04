// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {AlpyDAO} from "src/AlpyDAO.sol";

contract ExecuteProposal is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        AlpyDAO dao = AlpyDAO(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0);
        dao.execute(0); // proposalId = 0

        vm.stopBroadcast();
    }
}
