// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20, Flower, Hive} from "../../../src/flowers/Flower.sol";
import {MockProtocol} from "./MockProtocol.sol";

/// @title Panoptic Flower
/// @author Honeycomb Finance
/// @author Jared Borders
contract MockFlower is Flower {

    MockProtocol public immutable protocol;

    constructor(address _protocol, Hive _hive) Flower(_hive, _hive.asset()) {
        protocol = MockProtocol(_protocol);
        BEE.approve(address(protocol), type(uint256).max);
        BEE.approve(address(HIVE), type(uint256).max);
    }

    function pollinate(address _for, uint256 _with) external override {
        BEE.transferFrom(address(HIVE), address(this), _with);
        protocol.stake(_for, _with, BEE);
    }

    function harvest(address _for)
        external
        override
        returns (uint256 harvested)
    {
        uint256 staked = protocol.staked(_for);
        harvested = protocol.unstake(_for, staked, BEE);
        HIVE.deposit(harvested, _for);
    }

}
