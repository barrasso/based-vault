// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Deploy to deterministic addresses without an initcode factor
/// @author Solmate
/// @author Honeycomb Finance
library CREATE3 {

    error DeploymentFailed();
    error InitializationFailed();

    function fromLast20Bytes(bytes32 bytesValue)
        internal
        pure
        returns (address)
    {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(bytes20(addressValue));
    }

    bytes internal constant PROXY_BYTECODE =
        hex"67363d3d37363d34f03d5260086018f3";

    bytes32 internal constant PROXY_BYTECODE_HASH = keccak256(PROXY_BYTECODE);

    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value
    )
        internal
        returns (address deployed)
    {
        bytes memory proxyChildBytecode = PROXY_BYTECODE;

        address proxy;

        assembly {
            proxy :=
                create2(
                    0, add(proxyChildBytecode, 32), mload(proxyChildBytecode), salt
                )
        }

        require(proxy != address(0), DeploymentFailed());

        deployed = getDeployed(salt);
        (bool success,) = proxy.call{value: value}(creationCode);
        require(success && deployed.code.length != 0, InitializationFailed());
    }

    function getDeployed(bytes32 salt) internal view returns (address) {
        return getDeployed(salt, address(this));
    }

    function getDeployed(
        bytes32 salt,
        address creator
    )
        internal
        pure
        returns (address)
    {
        bytes1 prefix = 0xFF;
        address proxy = fromLast20Bytes(
            keccak256(
                abi.encodePacked(prefix, creator, salt, PROXY_BYTECODE_HASH)
            )
        );

        return fromLast20Bytes(
            keccak256(abi.encodePacked(hex"d694", proxy, hex"01"))
        );
    }

}
