// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Hive} from "../../src/Hive.sol";
import {Panoptic} from "../../src/flowers/panoptic/Panoptic.sol";
import {Synthetix} from "../../src/flowers/synthetix/Synthetix.sol";
import {ERC20} from "../../src/tokens/ERC20.sol";
import {Base} from "../configs/Base.sol";
import {BaseSepolia} from "../configs/BaseSepolia.sol";
import {Script} from "lib/forge-std/src/Script.sol";

contract DeployHive is Script {

    modifier broadcast() {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        _;
        vm.stopBroadcast();
    }

    function deploy(address underlying) public returns (address) {
        Hive hive = new Hive(underlying);

        return address(hive);
    }

}

/// @dev steps to deploy and verify on Base:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/hive/Hive.s.sol:DeployHiveBase --rpc-url
/// $BASE_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify
/// -vvvv`
contract DeployHiveBase is DeployHive, Base {

    function run() public broadcast returns (address hive) {
        hive = deploy(USDC);
    }

}

/// @dev steps to deploy and verify on BaseSepolia:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/hive/Hive.s.sol:DeployHiveBaseSepolia --rpc-url
/// $BASE_SEPOLIA_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast
/// --verify -vvvv`
contract DeployHiveBaseSepolia is DeployHive, BaseSepolia {

    function run() public broadcast returns (address hive) {
        hive = deploy(USDC);
    }

}
