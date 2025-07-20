// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DAOFactory} from "../src/DAOFactory.sol";
import {AlpyToken} from "../src/AlpyToken.sol";
import {AlpyStaking} from "../src/AlpyStaking.sol";
import {AlpyDAO} from "../src/AlpyDAO.sol";
import {LendingPool} from "../src/LendingPool.sol";

contract DAOFlowTest is Test {
    DAOFactory factory;
    AlpyToken token;
    AlpyStaking staking;
    AlpyDAO dao;
    LendingPool lending;

    address user = address(1);

    function setUp() public {
    uint256 rewardRate = 1e18;
    uint256 votingPeriod = 3600;

    // Use the state variable, not a new local one
    factory = new DAOFactory(rewardRate, votingPeriod);

    // Cast returned addresses to contracts
    token = AlpyToken(factory.token());
    staking = AlpyStaking(factory.staking());
    dao = AlpyDAO(factory.dao());
    lending = LendingPool(factory.lending());

    // Simulate DAOFactory having ownership to transfer tokens
    vm.prank(address(factory));
    token.transfer(address(this), 10 ether);

    token.transfer(user, 10 ether);

    vm.startPrank(user);
    token.approve(address(staking), 10 ether);
    staking.stakeTokens(10 ether);
    vm.stopPrank();
}


    function testProposalFlow_SetRewardRate() public {
        vm.startPrank(user);
        bytes memory callData = abi.encodeWithSignature("setRewardRate(uint256)", 7e18);
        dao.createProposal(address(staking), 0, callData, "Change reward rate");
        dao.vote(0, true);
        vm.warp(block.timestamp + 3602);
        dao.executeProposal(0);
        vm.stopPrank();
        assertEq(staking.rewardRate(), 7e18);
    }

    function testProposalFlow_SetLTV() public {
        vm.startPrank(user);
        bytes memory callData = abi.encodeWithSignature("setLTV(uint256)", 7500);
        dao.createProposal(address(lending), 0, callData, "Change LTV");
        dao.vote(0, true);
        vm.warp(block.timestamp + 3602);
        dao.executeProposal(0);
        vm.stopPrank();
        assertEq(lending.ltv(), 7500);
    }
}
