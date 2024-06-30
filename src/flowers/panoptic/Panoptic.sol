// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Hive} from "../../Hive.sol";
import {ERC20} from "../../tokens/ERC20.sol";
import {Flower} from "../Flower.sol";
import {IPanoptic} from "./IPanoptic.sol";

/// @title Panoptic Flower
/// @author Honeycomb Finance
/// @author Jared Borders
contract Panoptic is Flower {

    error NotImplemented();

    IPanoptic public immutable PANOPTIC;

    constructor(address _protocol, Hive _hive) Flower(_hive, _hive.asset()) {
        PANOPTIC = IPanoptic(_protocol);
        BEE.approve(_protocol, type(uint256).max);
    }

    function pollinate(address, uint256) external pure override {
        revert NotImplemented();
    }

    function harvest(address) external pure override returns (uint256) {
        revert NotImplemented();
    }

}
