// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {AlpyToken} from "src/AlpyToken.sol";
import {AlpyStaking} from "src/AlpyStaking.sol";

contract StakeAgain is Script {
    function run() external {
        vm.startBroadcast();

        AlpyToken token = AlpyToken(0x5FbDB2315678afecb367f032d93F642f64180aa3);
        AlpyStaking staking = AlpyStaking(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

        token.approve(address(staking), 1000 ether);
        staking.stakeTokens(1000 ether);

        vm.stopBroadcast();
    }
}
