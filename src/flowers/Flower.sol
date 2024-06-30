// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Hive} from "../Hive.sol";
import {Owned} from "../auth/Owned.sol";
import {ERC20} from "../tokens/ERC20.sol";

/// @title Flower
/// @author Honeycomb Finance
abstract contract Flower is Owned(msg.sender) {

    /// @notice Hive contract
    Hive public immutable HIVE;

    /// @notice BEE token contract
    /// @dev is the underlying Hive token; i.e., USDC, DAI, etc.
    ERC20 public immutable BEE;

    /// @notice Construct a new Flower
    /// @param _hive Hive contract
    /// @param _bee BEE token contract
    constructor(Hive _hive, ERC20 _bee) {
        HIVE = _hive;
        BEE = _bee;
    }

    /// @notice called via Hive to pollinate the flower on behalf of a beekeeper
    /// @param _for address of the beekeeper
    /// @param _with amount of capital to deploy to the flower; i.e., Bees
    function pollinate(address _for, uint256 _with) external virtual;

    /// @notice called via Hive to harvest the flower on behalf of a beekeeper
    /// @dev unwound capital is returned to the Hive via ERC4626 deposit
    /// @param _for address of the beekeeper
    /// @return harvested amount harvested from the flower
    function harvest(address _for)
        external
        virtual
        returns (uint256 harvested);

}
