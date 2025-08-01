// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AlpyToken is ERC20 {
    constructor() ERC20("AlpyToken", "AT") {
        _mint(msg.sender, 10_000_000 ether);
    }
}
