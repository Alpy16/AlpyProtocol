// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DAOFactory} from "src/DAOFactory.sol";
import {AlpyToken} from "src/AlpyToken.sol";
import {AlpyStaking} from "src/AlpyStaking.sol";
import {AlpyDAO} from "src/AlpyDAO.sol";
import {LendingPool} from "src/LendingPool.sol";

contract DAOFlowTest is Test {
    DAOFactory public factory;
    AlpyToken public token;
    AlpyStaking public staking;
    AlpyDAO public dao;
    LendingPool public lending;

    address public user = address(1);
    uint256 public constant STAKE_AMOUNT = 10 ether;
    uint256 public constant STAKE_DURATION = 30 days;
    uint256 public constant VOTING_PERIOD = 3600;

    function setUp() public {
        factory = new DAOFactory(VOTING_PERIOD);

        token = AlpyToken(factory.token());
        staking = AlpyStaking(factory.staking());
        dao = AlpyDAO(factory.dao());
        lending = LendingPool(factory.lending());

        // Fund the test account with tokens from factory's deployer balance
        vm.prank(address(factory));
        token.transfer(address(this), STAKE_AMOUNT);

        token.transfer(user, STAKE_AMOUNT);

        vm.startPrank(user);
        token.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT, STAKE_DURATION);
        vm.stopPrank();
    }

    function testProposalFlow_SetLTV() public {
        uint256 newLTV = 7500;
        bytes memory callData = abi.encodeWithSignature(
            "setLTV(uint256)",
            newLTV
        );

        vm.startPrank(user);
        uint256 proposalId = dao.createProposal(
            address(lending),
            0,
            callData,
            "Adjust Lending LTV"
        );
        dao.vote(proposalId, true);
        vm.warp(block.timestamp + VOTING_PERIOD + 2);
        dao.executeProposal(proposalId);
        vm.stopPrank();

        assertEq(lending.getLTV(), newLTV);
    }
}
