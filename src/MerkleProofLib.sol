// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice A verification of proof of inclusion for a leaf in an IPLD-based Merkle tree. The IPLD-based Merkle tree is defined here.
///
///         Leaves are provided as bytes and encoded to DAG-CBOR with the following DAG-JSON representation.
///             {"/": { "bytes": String /* Leaf bytes */ }}
///
///         The DAG-CBOR data is then converted to the following CID representation.
///             base      : raw (0x00)
///             version   : cidv1 (0x01)
///             codec     : dag-cbor (0x71)
///             hash algo : keccak256 (0x16)
///             hash len  : 256 bits (0x20)
///
///         Two nodes ordered by their data digest are encoded to DAG-CBOR with the following DAG-JSON representation.
///             [{"/": String /* Node0 CID */}, {"/": String /* Node1 CID */}]
///
///         Keccak256 hash of the final operation is checked against the root hash.
///
///         During tree generation, for empty objects, 0xf6 (`null`) is used.
///
/// @author shung (https://github.com/Shungy)
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol)
library MerkleProofLib {
    /// @dev Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes memory leaf
    ) internal pure returns (bool isValid) {
        bytes32 node = hashLeaf(leaf);
        uint256 length = proof.length;
        unchecked {
            for (uint256 i; i < length; ++i) node = hashNodes(node, proof[i]);
        }
        return node == root;
    }

    /// @dev Hashes leaf after generating a CBOR object from it.
    function hashLeaf(bytes memory input) internal pure returns (bytes32) {
        return keccak256(toCBOR(input));
    }

    /// @dev Hashes nodes based on their hash digest by generating their CIDs on the fly.
    function hashNodes(bytes32 digestA, bytes32 digestB) internal pure returns (bytes32) {
        return keccak256(toCBOR(digestA, digestB));
    }

    /// @dev Returns DAG-CBOR object `{"/": { "bytes": String /* Leaf bytes */ }`
    function toCBOR(bytes memory input) internal pure returns (bytes memory) {
        uint256 length = input.length;

        if (length < 24) {
            return abi.encodePacked(bytes1(0x40 ^ uint8(length)), input);
        } else if (length < 1 << 8) {
            return abi.encodePacked(bytes1(0x58), bytes1(uint8(length)), input);
        } else if (length < 1 << 16) {
            return abi.encodePacked(bytes1(0x59), bytes2(uint16(length)), input);
        } else if (length < 1 << 32) {
            return abi.encodePacked(bytes1(0x5a), bytes4(uint32(length)), input);
        } else {
            // CBOR standard allows for more, but that is impossible in EVM due to gas limit.
            assert(false);
            return "";
        }
    }

    /// @dev Returns DAG-CBOR object `[{"/": String /* CID0 */}, {"/": String /* CID1 */}]`
    function toCBOR(bytes32 digestA, bytes32 digestB) internal pure returns (bytes memory) {
        // Order nodes based on the hash digest order, not CID order.
        (bytes32 digest0, bytes32 digest1) = digestA < digestB
            ? (digestA, digestB)
            : (digestB, digestA);

        return
            abi.encodePacked(
                hex"82", // CBOR tag for array with len 2
                toCBOR(digest0),
                toCBOR(digest1)
            );
    }

    /// @dev Returns DAG-CBOR object `{"/": String /* CID */}`
    function toCBOR(bytes32 digest) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"d8", // CBOR custom tag len: 1 byte
                hex"2a", // CBOR custom tag: dag-cbor CID link
                hex"58", // CBOR data len byte: 1 byte
                hex"25", // CBOR data len: 37 bytes (5 prefix + 32 digest)
                toCID(digest)
            );
    }

    /// @dev Returns CID from the keccak256 digest of a dag-cbor object.
    function toCID(bytes32 digest) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"00", // CID base: raw binary base
                hex"01", // CID version: 1
                hex"71", // CID codec: dag-cbor
                hex"1b", // CID hash algo: keccak256
                hex"20", // CID hash len: 256 bits
                digest
            );
    }
}
