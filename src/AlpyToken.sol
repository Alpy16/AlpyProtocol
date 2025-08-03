// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AlpyToken is ERC20, Ownable {
    constructor() ERC20("AlpyToken", "AT") Ownable(msg.sender) {
        _mint(msg.sender, 10_000_000 ether);
    }
}
