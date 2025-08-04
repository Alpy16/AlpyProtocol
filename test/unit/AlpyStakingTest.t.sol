// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {AlpyToken} from "../../src/AlpyToken.sol";
import {AlpyStaking} from "../../src/AlpyStaking.sol";

contract AlpyStakingTest is Test {
    AlpyToken token;
    AlpyStaking staking;
    address user = address(0x1);
    address treasury = address(0xdead);

    function setUp() public {
        token = new AlpyToken();
        staking = new AlpyStaking(address(token), address(this), treasury);
        token.transfer(user, 1000 ether);
        vm.prank(user);
        token.approve(address(staking), type(uint256).max);
    }

    function _stake() internal {
        vm.prank(user);
        staking.stake(100 ether, 10 days);
    }

    // After staking, voting power equals stake * lock duration and
    // drops to zero once the lock ends.
    function testGetVotesExpires() public {
        _stake();
        // initial voting power is proportional to both amount and duration
        assertEq(staking.getVotes(user), 100 ether * 10 days);
        // advance past lock end so voting power decays to zero
        vm.warp(block.timestamp + 10 days + 1);
        assertEq(staking.getVotes(user), 0);
    }

    // Slashing should seize both stake and wallet tokens when approved and
    // the ban duration should double with each slash.
    function testSlashBannedDurationDoubles() public {
        _stake();
        // top up the user's wallet so some extra tokens can be seized
        token.transfer(user, 100 ether);

        uint256 t1 = block.timestamp + staking.COOLDOWN() + 1;
        vm.warp(t1);
        staking.slash(user);
        // first offence => 7 day ban
        assertEq(staking.bannedUntil(user), t1 + 7 days);
        assertEq(staking.slashCount(user), 1);
        // 10% of stake (10) + 10% of wallet (100) sent to treasury
        assertEq(token.balanceOf(treasury), 110 ether);

        vm.warp(t1 + staking.COOLDOWN() + 1);
        staking.slash(user);
        uint256 t2 = block.timestamp;
        // second offence => ban doubles to 14 days
        assertEq(staking.bannedUntil(user), t2 + 14 days);
        assertEq(staking.slashCount(user), 2);
    }

    // If the user revokes allowance, only their staked tokens can be slashed
    // and wallet tokens remain untouched.
    function testSlashOnlyStakeWhenNoAllowance() public {
        _stake();
        // revoke any remaining allowance after staking
        vm.prank(user);
        token.approve(address(staking), 0);

        uint256 treasuryBefore = token.balanceOf(treasury);
        vm.warp(block.timestamp + staking.COOLDOWN() + 1);
        staking.slash(user);
        // treasury only receives 10% of the staked amount (10 tokens)
        assertEq(token.balanceOf(treasury) - treasuryBefore, 10 ether);
        // user's wallet balance stays the same since it wasn't approved
        assertEq(token.balanceOf(user), 900 ether);
    }

    // Without any staked tokens or allowance the slash call reverts.
    function testSlashRevertsWhenNothingToSlash() public {
        address other = address(0x2);
        // give the user some tokens but no approval and no stake
        token.transfer(other, 50 ether);

        vm.warp(block.timestamp + staking.COOLDOWN() + 1);
        vm.expectRevert(AlpyStaking.NothingToSlash.selector);
        staking.slash(other);
    }
}
