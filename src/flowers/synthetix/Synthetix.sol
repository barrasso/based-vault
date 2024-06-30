// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Hive} from "../../Hive.sol";
import {ERC20} from "../../tokens/ERC20.sol";
import {Flower} from "../Flower.sol";
import {ISynthetix} from "./ISynthetix.sol";

/// @title Synthetix Flower
/// @author Honeycomb Finance
/// @author Jared Borders
contract Synthetix is Flower {

    /*//////////////////////////////////////////////////////////////
                          CONSTANTS/IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Synthetix sUSDC spot market id
    uint128 public constant sUSDC_MARKET_ID = 1;

    /// @notice Synthetix collateral leverage amount
    uint256 public constant LEVERAGE = 1 ether;

    /// @notice Synthetix core proxy
    ISynthetix public immutable SYNTHETIX_CORE;

    /// @notice Synthetix spot market proxy
    ISynthetix public immutable SYNTHETIX_SPOT_MARKET;

    /// @notice Synthetix preferred pool id
    uint128 public immutable PREFERRED_POOL_ID;

    /// @notice Synthetix sUSDC synth
    ERC20 public immutable sUSDC;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice mapping of beekeepers to Synthetix accounts
    mapping(address beekeeper => uint128 synthetixAccountId) public
        protocolAccounts;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Constructs the Synthetix Flower
    /// @param _core Synthetix core proxy address
    /// @param _spot Synthetix spot market proxy address
    /// @param _hive Hive contract address
    constructor(
        address _core,
        address _spot,
        Hive _hive
    )
        Flower(_hive, _hive.asset())
    {
        SYNTHETIX_CORE = ISynthetix(_core);
        SYNTHETIX_SPOT_MARKET = ISynthetix(_spot);
        sUSDC = ERC20(SYNTHETIX_SPOT_MARKET.getSynth(sUSDC_MARKET_ID));

        PREFERRED_POOL_ID = SYNTHETIX_CORE.getPreferredPool();

        BEE.approve(address(SYNTHETIX_CORE), type(uint256).max);
        BEE.approve(address(SYNTHETIX_SPOT_MARKET), type(uint256).max);
        sUSDC.approve(address(SYNTHETIX_CORE), type(uint256).max);
        sUSDC.approve(address(SYNTHETIX_SPOT_MARKET), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                               POLLINATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Provide Bees to the Flower for pollination
    /// @dev Bees provided capitalize yield bearing position
    /// @dev Throws if the Hive is not the caller
    /// @param _for beekeeper whom the Flower associates the resulting position
    /// @param _with amount of Bees to provide for pollination
    function pollinate(
        address _for,
        uint256 _with
    )
        external
        override
        onlyOwner
    {
        // transfer Bees to the Flower from the Hive
        BEE.transferFrom(address(HIVE), address(this), _with);

        /// @dev Synthetix expects 18 decimals of precision
        uint256 withD18 = _with * 10 ** (18 - BEE.decimals());

        // wrap the Bess for the Synthetix Core
        SYNTHETIX_SPOT_MARKET.wrap({
            marketId: sUSDC_MARKET_ID,
            wrapAmount: _with,
            minAmountReceived: withD18
        });

        // establish Synthetix account for the beekeeper;
        // if none exists, create one and store it
        uint128 accountId = protocolAccounts[_for] == 0
            ? (protocolAccounts[_for] = SYNTHETIX_CORE.createAccount())
            : protocolAccounts[_for];

        // transfer Bees to the Synthetix Core address as collateral
        SYNTHETIX_CORE.deposit({
            accountId: accountId,
            collateralType: address(sUSDC),
            tokenAmount: withD18
        });

        // delegate collateral to the preferred pool
        SYNTHETIX_CORE.delegateCollateral({
            accountId: accountId,
            poolId: PREFERRED_POOL_ID,
            collateralType: address(sUSDC),
            amount: withD18,
            leverage: LEVERAGE
        });
    }

    /*//////////////////////////////////////////////////////////////
                                HARVEST
    //////////////////////////////////////////////////////////////*/

    /// @notice Conclude pollination and withdraw from the Flower
    /// @dev Throws if the Hive is not the caller
    /// @param _for beekeeper whom the account is associated with by the Flower
    /// @return harvested amount
    function harvest(address _for)
        external
        override
        onlyOwner
        returns (uint256 harvested)
    {
        /// @dev account preserved (despite withdrawal);
        /// future pollination won't require minting a new account
        uint128 accountId = protocolAccounts[_for];

        /// @dev specifying a new collateral amount of zero unwinds the position
        SYNTHETIX_CORE.delegateCollateral({
            accountId: accountId,
            poolId: PREFERRED_POOL_ID,
            collateralType: address(sUSDC),
            amount: 0,
            leverage: LEVERAGE
        });

        // determine unwound position's collateral amount
        uint256 availableCollateral = SYNTHETIX_CORE
            .getAccountAvailableCollateral({
            accountId: accountId,
            collateralType: address(sUSDC)
        });

        // withdraw unwound collateral
        SYNTHETIX_CORE.withdraw({
            accountId: accountId,
            collateralType: address(sUSDC),
            tokenAmount: availableCollateral
        });

        // adjust precision back to Bee's decimal representation
        harvested = availableCollateral / 10 ** (18 - BEE.decimals());

        // unwrap the balance harvested from the Synthetix Core
        SYNTHETIX_SPOT_MARKET.unwrap({
            marketId: sUSDC_MARKET_ID,
            unwrapAmount: availableCollateral,
            minAmountReceived: harvested
        });

        // realize the harvest by depositing it into the Hive
        HIVE.deposit(harvested, _for);
    }

    /// @notice Harvest any rewards accumulated
    /// @dev Pollination remains ongoing
    /// @custom:caution calling may result in Synthetix imposed timelocks
    /// @param _for beekeeper whom the account is associated with by the Flower
    /// @return rewards harvested
    function harvestSynthetixRewards(address _for)
        external
        onlyOwner
        returns (uint256 rewards)
    {
        uint128 accountId = protocolAccounts[_for];

        uint256[] memory claimableD18;
        address[] memory distributors;

        // retrieve claimable rewards and associated distributors
        (claimableD18, distributors) = SYNTHETIX_CORE.updateRewards({
            poolId: PREFERRED_POOL_ID,
            collateralType: address(BEE),
            accountId: accountId
        });

        // sanity check; should never fail under normal circumstances
        assert(claimableD18.length == distributors.length);

        // claim rewards from each distributor
        /// @dev rewards are automatically transferred to the Flower
        for (uint256 i = 0; i < claimableD18.length; i++) {
            rewards += SYNTHETIX_CORE.claimRewards({
                accountId: accountId,
                poolId: PREFERRED_POOL_ID,
                collateralType: address(BEE),
                distributor: distributors[i]
            });
        }

        /// @dev use contract balance to determine final amount of rewards
        rewards = BEE.balanceOf(address(this));

        // realize the harvested rewards by depositing it into the Hive
        HIVE.deposit(rewards, _for);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC721 RECEIVED
    //////////////////////////////////////////////////////////////*/

    /// @notice Flower must be ERC-721 compliant
    /// @dev Synthetix accounts are represented as ERC-721 tokens
    /// @return selector to confirm the token transfer
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    )
        external
        pure
        returns (bytes4 selector)
    {
        selector = this.onERC721Received.selector;
    }

}
