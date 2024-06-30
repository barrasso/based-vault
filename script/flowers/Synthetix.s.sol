// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Hive} from "../../src/Hive.sol";
import {Panoptic} from "../../src/flowers/panoptic/Panoptic.sol";
import {Synthetix} from "../../src/flowers/synthetix/Synthetix.sol";
import {ERC20} from "../../src/tokens/ERC20.sol";
import {Base} from "../configs/Base.sol";
import {BaseSepolia} from "../configs/BaseSepolia.sol";
import {Script} from "lib/forge-std/src/Script.sol";

contract DeploySynthetixFlower is Script {

    modifier broadcast() {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        _;
        vm.stopBroadcast();
    }

    function deploy(
        address core,
        address spot,
        address hive
    )
        public
        returns (address)
    {
        Hive hive = Hive(hive);

        Synthetix synthetix =
            new Synthetix({_core: core, _spot: spot, _hive: hive});

        return address(synthetix);
    }

}

/// @dev steps to deploy and verify on Base:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script
/// script/flowers/Synthetix.s.sol:DeploySynthetixFlowerBase --rpc-url
/// $BASE_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify
/// -vvvv`
contract DeploySynthetixFlowerBase is Deploy, Base {

    function run() public broadcast returns (address synthetix) {
        synthetix = deploy(SYNTHETIX_CORE, SYNTHETIX_SPOT_MARKET, HIVE);
    }

}

/// @dev steps to deploy and verify on BaseSepolia:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script
/// script/flowers/Synthetix.s.sol:DeploySynthetixFlowerBaseSepolia --rpc-url
/// $BASE_SEPOLIA_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast
/// --verify -vvvv`
contract DeploySynthetixFlowerBaseSepolia is Deploy, BaseSepolia {

    function run() public broadcast returns (address synthetix) {
        synthetix = deploy(SYNTHETIX_CORE, SYNTHETIX_SPOT_MARKET, HIVE);
    }

}
