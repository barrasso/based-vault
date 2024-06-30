// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "../../../src/tokens/ERC20.sol";

/// @notice Mock ERC20 token
/// @dev Exposed mint/burn functions for testing purposes
/// @author Honeycomb Finance
/// @author Jared Borders
contract MockToken is ERC20("Mock Token", "MOCK", 18) {

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        _burn(_from, _amount);
    }

}
