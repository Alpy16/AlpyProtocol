// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AlpyStaking} from "../src/AlpyStaking.sol";

contract StakingFlow is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address tokenAddr = vm.envAddress("TOKEN_ADDRESS");
        address stakingAddr = vm.envAddress("STAKING_ADDRESS");
        vm.startBroadcast(pk);

        IERC20 token = IERC20(tokenAddr);
        AlpyStaking staking = AlpyStaking(stakingAddr);

        token.approve(address(staking), 1_000 ether);
        staking.stake(1_000 ether, 10 days);
        staking.extendLock(20 days);
        vm.warp(block.timestamp + 20 days + 1);
        staking.withdraw();

        vm.stopBroadcast();
    }
}
