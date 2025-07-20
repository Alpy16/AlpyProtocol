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
        AlpyStaking staking = AlpyStaking(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
        AlpyDAO dao = AlpyDAO(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0);

        // Gain voting power
        token.approve(address(staking), 10 ether);
        staking.stakeTokens(10 ether);

        // Proposal 1: Update reward rate
        dao.createProposal(
            address(staking),
            0,
            abi.encodeWithSignature("setRewardRate(uint256)", 5e18),
            "Change reward rate to 5 ALPY/sec"
        );

        // Proposal 2: Update LTV
        dao.createProposal(
            0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9,
            0,
            abi.encodeWithSignature("setLTV(uint256)", 7500),
            "Update LTV to 75%"
        );

        vm.stopBroadcast();
    }
}
