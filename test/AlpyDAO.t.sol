// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {AlpyToken} from "../src/AlpyToken.sol";
import {AlpyStaking} from "../src/AlpyStaking.sol";
import {AlpyDAO} from "../src/AlpyDAO.sol";

contract AlpyDAOTest is Test {
    AlpyToken token;
    AlpyStaking staking;
    AlpyDAO dao;
    address voter = address(1);

    function setUp() public {
        token = new AlpyToken();
        staking = new AlpyStaking(address(token), address(this), address(this));
        dao = new AlpyDAO(address(staking), 1 days);
        staking.transferOwnership(address(dao));
        deal(address(token), voter, 1_000 ether);

        vm.startPrank(voter);
        token.approve(address(staking), 1_000 ether);
        staking.stake(1_000 ether, 7 days);
        vm.stopPrank();

        token.transfer(address(dao), 100 ether);
    }

    function testProposeVoteExecute() public {
        vm.prank(voter);
        uint256 id = dao.propose(
            address(token), 0, abi.encodeWithSignature("transfer(address,uint256)", voter, 100 ether), "payout"
        );

        vm.prank(voter);
        dao.vote(id, true);

        vm.prank(voter);
        dao.execute(id);

        assertEq(token.balanceOf(voter), 100 ether);
    }
}
