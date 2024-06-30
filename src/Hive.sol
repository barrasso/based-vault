// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Owned} from "./auth/Owned.sol";
import {Flower} from "./flowers/Flower.sol";
import {ERC20} from "./tokens/ERC20.sol";
import {ERC4626} from "./tokens/ERC4626.sol";

/// @title Hive
/// @author Honeycomb Finance
/// @author Jared Borders
contract Hive is ERC4626, Owned(msg.sender) {

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice name of the Hive vault share token
    string public constant NAME = "Honeycomb";

    /// @notice symbol of the Hive vault share token
    string public constant SYMBOL = "COMB";

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice mapping of registered flowers; true if registered
    /// @dev only Hive owner can add/remove flowers
    mapping(address flower => bool) public flowers;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when a flower has been registered
    event FlowerAdded(address indexed flower);

    /// @notice emitted when a flower has been removed
    event FlowerRemoved(address indexed flower);

    /// @notice emitted when a flower has been pollinated
    /// @param flower address of the flower
    /// @param beekeeper address of the beekeeper (i.e., caller)
    /// @param bees amount of capital deployed to the flower
    event Pollinated(
        address indexed flower, address indexed beekeeper, uint256 bees
    );

    /// @notice emitted when a flower has been harvested
    /// @param flower address of the flower
    /// @param beekeeper address of the beekeeper (i.e., caller)
    /// @param bees amount of capital harvested from the flower
    event Harvested(
        address indexed flower, address indexed beekeeper, uint256 bees
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice thrown if attempting to interact with unregistered flower
    error WiltedFlower();

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice sanitizes given flower address; throws if not registered
    modifier onlyFlower(address _flower) {
        require(flowers[_flower], WiltedFlower());
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice initializes Hive with given underlying asset
    /// @param _underlying address of the underlying asset
    constructor(address _underlying)
        ERC4626(ERC20(_underlying), NAME, SYMBOL)
    {}

    /*//////////////////////////////////////////////////////////////
                           FLOWER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice adds given flower to the list of registered flowers
    /// @dev throws if caller is not the owner
    /// @param _flower address of the flower to add
    function addFlower(address _flower) external onlyOwner {
        flowers[_flower] = true;

        emit FlowerAdded(_flower);
    }

    /// @notice removes given flower from the list of registered flowers
    /// @dev throws if caller is not the owner
    /// @param _flower address of the flower to remove
    function removeFlower(address _flower) external onlyOwner {
        delete flowers[_flower];

        emit FlowerRemoved(_flower);
    }

    /*//////////////////////////////////////////////////////////////
                                 SWARM
    //////////////////////////////////////////////////////////////*/

    /// @notice pollinates given flower with bees
    /// @dev redeems caller's shares and deploys capital to the flower
    /// @dev throws if flower is not registered
    /// @param _flower address of the flower to pollinate
    function pollinate(address _flower) external onlyFlower(_flower) {
        uint256 bees = previewRedeem(maxRedeem(msg.sender));

        redeem(bees, address(this), msg.sender);

        asset.approve(_flower, bees);

        Flower(_flower).pollinate({_for: msg.sender, _with: bees});

        emit Pollinated(_flower, msg.sender, bees);
    }

    /// @notice harvests given flower
    /// @dev unwinds caller's capital from the flower
    /// @dev unwound capital is deposited back into the Hive; can be redeemed
    /// @dev throws if flower is not registered
    /// @param _flower address of the flower to harvest
    function harvest(address _flower) external onlyFlower(_flower) {
        uint256 harvested = Flower(_flower).harvest(msg.sender);

        emit Harvested(_flower, msg.sender, harvested);
    }

}
