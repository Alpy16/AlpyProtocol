// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AlpyToken.sol";
import "./AlpyStaking.sol";
import "./AlpyDAO.sol";
import "./LendingPool.sol";

contract DAOFactory {
    address public token;
    address public staking;
    address public dao;
    address public lending;

    constructor(uint256 votingPeriod) {
        AlpyToken _token = new AlpyToken();
        token = address(_token);

        AlpyStaking _staking = new AlpyStaking(
            token,
            address(this),
            address(this)
        );
        staking = address(_staking);

        AlpyDAO _dao = new AlpyDAO(staking, votingPeriod);
        dao = address(_dao);

        LendingPool _lending = new LendingPool(dao);
        lending = address(_lending);
    }
}
