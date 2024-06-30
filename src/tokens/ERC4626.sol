// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {ERC20} from "./ERC20.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate
/// @author Honeycomb Finance
/// @custom:todo Prevent ERC4626 inflation attacks
contract ERC4626 is ERC20 {

    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZeroShares();
    error ZeroAssets();

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    )
        ERC20(_name, _symbol, _asset.decimals())
    {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(
        uint256 assets,
        address receiver
    )
        public
        returns (uint256 shares)
    {
        // Check for rounding error since we round down in previewDeposit
        require((shares = previewDeposit(assets)) != 0, ZeroShares());

        // Need to transfer before minting or ERC777s could reenter
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        _afterDeposit(assets, shares);
    }

    function mint(
        uint256 shares,
        address receiver
    )
        public
        returns (uint256 assets)
    {
        // No need to check for rounding error, previewMint rounds up
        assets = previewMint(shares);

        // Need to transfer before minting or ERC777s could reenter
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        _afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    )
        public
        returns (uint256 shares)
    {
        // No need to check for rounding error, previewWithdraw rounds up
        shares = previewWithdraw(assets);

        if (msg.sender != owner) {
            // Saves gas for limited approvals
            uint256 allowed = allowance[owner][msg.sender];

            if (allowed != type(uint256).max) {
                allowance[owner][msg.sender] = allowed - shares;
            }
        }

        _beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    )
        public
        returns (uint256 assets)
    {
        if (msg.sender != owner) {
            // Saves gas for limited approvals
            uint256 allowed = allowance[owner][msg.sender];

            if (allowed != type(uint256).max) {
                allowance[owner][msg.sender] = allowed - shares;
            }
        }

        // Check for rounding error since we round down in previewRedeem
        require((assets = previewRedeem(shares)) != 0, ZeroAssets());

        _beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        // Saves an extra SLOAD if totalSupply is non-zero
        uint256 supply = totalSupply;

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        // Saves an extra SLOAD if totalSupply is non-zero
        uint256 supply = totalSupply;

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view returns (uint256) {
        // Saves an extra SLOAD if totalSupply is non-zero
        uint256 supply = totalSupply;

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view returns (uint256) {
        // Saves an extra SLOAD if totalSupply is non-zero
        uint256 supply = totalSupply;

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public pure returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public pure returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function _beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function _afterDeposit(uint256 assets, uint256 shares) internal virtual {}

}
