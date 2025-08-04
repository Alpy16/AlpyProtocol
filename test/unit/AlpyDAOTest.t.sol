// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "src/DAOFactory.sol";
import "src/AlpyToken.sol";
import "src/AlpyStaking.sol";
import "src/AlpyDAO.sol";
import "src/LendingPool.sol";

contract AlpyDAOTest is Test {
    DAOFactory public factory;
    AlpyToken public token;
    AlpyStaking public staking;
    AlpyDAO public dao;
    LendingPool public lending;

    address public user1 = address(1);
    address public user2 = address(2);
    uint256 public constant STAKE_AMOUNT = 10 ether;
    uint256 public constant STAKE_DURATION = 30 days;
    uint256 public constant VOTING_PERIOD = 3600;

    function setUp() public {
        factory = new DAOFactory(VOTING_PERIOD);
        token = AlpyToken(factory.token());
        staking = AlpyStaking(factory.staking());
        dao = AlpyDAO(factory.dao());
        lending = LendingPool(factory.lending());

        vm.prank(address(factory));
        token.transfer(user1, STAKE_AMOUNT);
        vm.prank(address(factory));
        token.transfer(user2, STAKE_AMOUNT);

        vm.startPrank(user1);
        token.approve(address(staking), STAKE_AMOUNT);
        staking.stake(STAKE_AMOUNT, STAKE_DURATION);
        vm.stopPrank();
    }

    function testProposalCreationAndExecution() public {
        vm.startPrank(user1);
        bytes memory callData = abi.encodeWithSignature(
            "setLTV(uint256)",
            7000
        );
        uint256 proposalId = dao.createProposal(
            address(lending),
            0,
            callData,
            "Set new LTV"
        );
        dao.vote(proposalId, true);
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        dao.executeProposal(proposalId);
        vm.stopPrank();

        assertEq(lending.getLTV(), 7000);
    }

}
