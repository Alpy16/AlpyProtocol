// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AlpyStaking} from "../src/AlpyStaking.sol";

contract StakingFlow is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        IERC20 token = IERC20(0x5FbDB2315678afecb367f032d93F642f64180aa3);
        AlpyStaking staking = AlpyStaking(
            0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
        );

        token.approve(address(staking), 1_000 ether);
        staking.stake(1_000 ether, 10 days);
        staking.extendLock(20 days);
        staking.withdraw();

        vm.stopBroadcast();
    }
}
