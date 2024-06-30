// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @author Solady
/// @author Honeycomb Finance
library StringLib {

    function concat(
        string memory a,
        string memory b
    )
        internal
        pure
        returns (string memory result)
    {
        assembly {
            let w := not(0x1f)
            result := mload(0x40)
            let aLength := mload(a)
            for { let o := and(add(aLength, 0x20), w) } 1 {} {
                mstore(add(result, o), mload(add(a, o)))
                o := add(o, w)
                if iszero(o) { break }
            }
            let bLength := mload(b)
            let output := add(result, aLength)
            for { let o := and(add(bLength, 0x20), w) } 1 {} {
                mstore(add(output, o), mload(add(b, o)))
                o := add(o, w)
                if iszero(o) { break }
            }
            let totalLength := add(aLength, bLength)
            let last := add(add(result, 0x20), totalLength)
            mstore(last, 0)
            mstore(result, totalLength)
            mstore(0x40, and(add(last, 0x1f), w))
        }
    }

}
