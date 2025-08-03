// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {AlpyToken} from "../src/AlpyToken.sol";
import {AlpyStaking} from "../src/AlpyStaking.sol";
import {AlpyDAO} from "../src/AlpyDAO.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {RewardDistributor} from "../src/RewardDistributor.sol";

contract DeployAll is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        vm.startBroadcast(privateKey);

        AlpyToken token = new AlpyToken();

        AlpyStaking staking = new AlpyStaking(
            address(token),
            deployer,
            deployer
        );

        AlpyDAO dao = new AlpyDAO(address(staking), 3 days);

        LendingPool pool = new LendingPool(address(dao));

        RewardDistributor distributor = new RewardDistributor(
            address(token),
            address(pool),
            1e16
        );

        token.transferOwnership(address(dao));
        staking.transferOwnership(address(dao));
        distributor.transferOwnership(address(dao));

        vm.stopBroadcast();
    }
}
