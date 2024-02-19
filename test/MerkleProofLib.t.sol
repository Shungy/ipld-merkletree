// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MerkleProofLib} from "../src/MerkleProofLib.sol";

contract MerkleProofLibTest is Test {
    function test_toBytes() public {
        {
            bytes
                memory data = hex"6969696969ffffffff6969696969ffff6969696969ffffffff6969696969ffff";
            bytes memory calculated = MerkleProofLib.toCBOR(data);
            bytes memory expected = hex"5820"
            hex"6969696969ffffffff6969696969ffff6969696969ffffffff6969696969ffff";
            assertEq(calculated, expected);
        }

        {
            bytes memory data = hex"6969696969";
            bytes memory calculated = MerkleProofLib.toCBOR(data);
            bytes memory expected = hex"45" hex"6969696969";
            assertEq(calculated, expected);
        }

        // Test zero
        {
            bytes memory data = hex"";
            bytes memory calculated = MerkleProofLib.toCBOR(data);
            bytes memory expected = hex"40";
            assertEq(calculated, expected);
        }

        // Test 0x17 (23) bytes
        {
            bytes memory data = hex"ffffffffffffffffffffffffffffffffffffffffffffff";
            bytes memory calculated = MerkleProofLib.toCBOR(data);
            bytes memory expected = hex"57" hex"ffffffffffffffffffffffffffffffffffffffffffffff";
            assertEq(calculated, expected);
        }

        // Test 24 bytes
        {
            bytes memory data = hex"ffffffffffffffffffffffffffffffffffffffffffffffff";
            bytes memory calculated = MerkleProofLib.toCBOR(data);
            bytes memory expected = hex"58"
            hex"18"
            hex"ffffffffffffffffffffffffffffffffffffffffffffffff";
            assertEq(calculated, expected);
        }

        // Test 255 bytes
        {
            bytes
                memory data = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
            bytes memory calculated = MerkleProofLib.toCBOR(data);
            bytes memory expected = hex"58"
            hex"ff"
            hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
            assertEq(calculated, expected);
        }

        // Test 256 bytes
        {
            bytes
                memory data = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
            bytes memory calculated = MerkleProofLib.toCBOR(data);
            bytes memory expected = hex"59"
            hex"0100"
            hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
            assertEq(calculated, expected);
        }
    }

    function test_hashLeaf() public {
        {
            bytes
                memory data = hex"6969696969ffffffff6969696969ffff6969696969ffffffff6969696969ffff";
            bytes32 calculated = MerkleProofLib.hashLeaf(data);
            bytes32 expected = 0x49d4dc4475c918f56a1198c7c617928e46ef15ede702260fcf7361ab1e9abd8f;
            assertEq(calculated, expected);
        }

        {
            bytes memory data = hex"6969696969";
            bytes32 calculated = MerkleProofLib.hashLeaf(data);
            bytes32 expected = 0xa05dbb80f1064e80588498868394c8d38c16a0d21fcf34134907c8b06c42b638;
            assertEq(calculated, expected);
        }
    }

    function test_hashNodes() public {
        bytes32 calculated = MerkleProofLib.hashNodes(
            0x49d4dc4475c918f56a1198c7c617928e46ef15ede702260fcf7361ab1e9abd8f,
            0xa05dbb80f1064e80588498868394c8d38c16a0d21fcf34134907c8b06c42b638
        );
        bytes32 expected = 0x94bcc2dc6acfbdcae2439a49d0e01f69de68ecd3797752b77bf4b53aa2a3ed4d;
        assertEq(calculated, expected);

        // Reverse order.
        calculated = MerkleProofLib.hashNodes(
            0xa05dbb80f1064e80588498868394c8d38c16a0d21fcf34134907c8b06c42b638,
            0x49d4dc4475c918f56a1198c7c617928e46ef15ede702260fcf7361ab1e9abd8f
        );
        assertEq(calculated, expected);
    }

    function test_toCID() public {
        {
            bytes memory calculated = MerkleProofLib.toCID(
                0x49d4dc4475c918f56a1198c7c617928e46ef15ede702260fcf7361ab1e9abd8f
            );
            bytes memory expected = hex"0001711b20"
            hex"49d4dc4475c918f56a1198c7c617928e46ef15ede702260fcf7361ab1e9abd8f";
            assertEq(calculated, expected);
        }

        {
            bytes memory calculated = MerkleProofLib.toCID(
                0xa05dbb80f1064e80588498868394c8d38c16a0d21fcf34134907c8b06c42b638
            );
            bytes memory expected = hex"0001711b20"
            hex"a05dbb80f1064e80588498868394c8d38c16a0d21fcf34134907c8b06c42b638";
            assertEq(calculated, expected);
        }

        {
            bytes memory calculated = MerkleProofLib.toCID(
                0x94bcc2dc6acfbdcae2439a49d0e01f69de68ecd3797752b77bf4b53aa2a3ed4d
            );
            bytes memory expected = hex"0001711b20"
            hex"94bcc2dc6acfbdcae2439a49d0e01f69de68ecd3797752b77bf4b53aa2a3ed4d";
            assertEq(calculated, expected);
        }
    }

    function test_toLink() public {
        {
            bytes memory calculated = MerkleProofLib.toCBOR(
                0x49d4dc4475c918f56a1198c7c617928e46ef15ede702260fcf7361ab1e9abd8f
            );
            bytes memory expected = hex"d82a58250001711b20"
            hex"49d4dc4475c918f56a1198c7c617928e46ef15ede702260fcf7361ab1e9abd8f";
            assertEq(calculated, expected);
        }

        {
            bytes memory calculated = MerkleProofLib.toCBOR(
                0xa05dbb80f1064e80588498868394c8d38c16a0d21fcf34134907c8b06c42b638
            );
            bytes memory expected = hex"d82a58250001711b20"
            hex"a05dbb80f1064e80588498868394c8d38c16a0d21fcf34134907c8b06c42b638";
            assertEq(calculated, expected);
        }
    }

    function test_toArray() public {
        bytes memory calculated = MerkleProofLib.toCBOR(
            0x49d4dc4475c918f56a1198c7c617928e46ef15ede702260fcf7361ab1e9abd8f,
            0xa05dbb80f1064e80588498868394c8d38c16a0d21fcf34134907c8b06c42b638
        );
        bytes memory expected = hex"82"
        hex"d82a58250001711b20"
        hex"49d4dc4475c918f56a1198c7c617928e46ef15ede702260fcf7361ab1e9abd8f"
        hex"d82a58250001711b20"
        hex"a05dbb80f1064e80588498868394c8d38c16a0d21fcf34134907c8b06c42b638";
        assertEq(calculated, expected);

        // Reverse order.
        calculated = MerkleProofLib.toCBOR(
            0xa05dbb80f1064e80588498868394c8d38c16a0d21fcf34134907c8b06c42b638,
            0x49d4dc4475c918f56a1198c7c617928e46ef15ede702260fcf7361ab1e9abd8f
        );
        assertEq(calculated, expected);
    }
}
