// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {AlpyDAO} from "../src/AlpyDAO.sol";

contract DAOProposalFlow is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address daoAddr = vm.envAddress("DAO_ADDRESS");
        address stakingAddr = vm.envAddress("STAKING_ADDRESS");
        address reviewer = vm.envAddress("REVIEWER");

        vm.startBroadcast(pk);

        AlpyDAO dao = AlpyDAO(daoAddr);

        uint256 id = dao.propose(
            stakingAddr, 0, abi.encodeWithSignature("setReviewer(address,bool)", reviewer, true), "add reviewer"
        );

        dao.vote(id, true);
        dao.execute(id);

        vm.stopBroadcast();
    }
}
