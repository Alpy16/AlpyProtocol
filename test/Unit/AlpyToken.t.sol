// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {AlpyToken} from "src/AlpyToken.sol";

contract AlpyTokenTest is Test {
    AlpyToken token;
    address deployer = address(this);

    function setUp() public {
        token = new AlpyToken();
    }

    function testInitialSupply() public view {
        assertEq(token.totalSupply(), 10_000_000 ether);
        assertEq(token.balanceOf(deployer), 10_000_000 ether);
    }
}
