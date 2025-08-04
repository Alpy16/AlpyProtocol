// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AlpyToken} from "./AlpyToken.sol";
import {AlpyStaking} from "./AlpyStaking.sol";
import {AlpyDAO} from "./AlpyDAO.sol";
import {LendingPool} from "./LendingPool.sol";

contract DAOFactory {
    address public token;
    address public staking;
    address public dao;
    address public lending;

    constructor(uint256 initialRewardRate, uint256 votingPeriod) {
        AlpyToken _token = new AlpyToken();
        token = address(_token);

        // Deploy staking with this factory as temporary DAO/treasury holder
        AlpyStaking _staking = new AlpyStaking(
            token,
            address(this),
            address(this)
        );
        staking = address(_staking);

        // Deploy DAO pointing to staking for vote weight
        AlpyDAO _dao = new AlpyDAO(staking, votingPeriod);
        dao = address(_dao);

        // Deploy lending pool governed by DAO
        LendingPool _lending = new LendingPool(dao);
        lending = address(_lending);
    }
}
