// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "../../../src/tokens/ERC20.sol";
import {MockToken} from "./MockToken.sol";

/// @title Mock Protocol
/// @author Honeycomb Finance
/// @author Jared Borders
contract MockProtocol {

    mapping(address => uint256) public staked;
    uint256 public yield;

    function stake(address _for, uint256 _amount, ERC20 _token) external {
        _token.transferFrom(msg.sender, address(this), _amount);
        staked[_for] += _amount;
    }

    function unstake(
        address _for,
        uint256 _amount,
        ERC20 _token
    )
        external
        returns (uint256)
    {
        MockToken(address(_token)).mint(address(this), yield);
        staked[_for] -= _amount;
        _token.transfer(msg.sender, _amount + yield);
        return _amount + yield;
    }

    function setYield(uint256 _yield) external {
        yield = _yield;
    }

}
