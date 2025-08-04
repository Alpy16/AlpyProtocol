// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {AlpyToken} from "../src/AlpyToken.sol";
import {AlpyStaking} from "../src/AlpyStaking.sol";
import {AlpyDAO} from "../src/AlpyDAO.sol";

contract SubmitProposal is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        AlpyToken token = AlpyToken(0x5FbDB2315678afecb367f032d93F642f64180aa3);
        AlpyStaking staking = AlpyStaking(
            0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
        );
        AlpyDAO dao = AlpyDAO(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0);

        // Gain voting power
        token.approve(address(staking), 10 ether);
        staking.stake(10 ether, 30 days);

        // Only valid proposal: Update LTV
        dao.propose(
            0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9, // LendingPool address
            0,
            abi.encodeWithSignature("setLTV(uint256)", 7500),
            "Update LTV to 75%"
        );

        vm.stopBroadcast();
    }
}
