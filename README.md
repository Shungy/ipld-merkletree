## IPDL-based Merkle tree in Solidity

Using IPDL-based merkle trees in Ethereum merkle proofs allows generating an IPFS content identifier (CID) from a given root hash.
Using the generated CID, anyone can retrieve the entire merkle tree from IPFS and generate a proof in a decentralized and permissionless manner.

## Usage

### Merkle tree generation

### Solidity

The inclusion of `data` within a merkle tree with root `rootHash` can be checked with

```solidity
    MerkleProofLib.verify(proof, rootHash, abi.encode(data));
```

where `proof` is an array of raw node hashes, and not their CIDs.

The CID of the `rootHash`, or any other node hash can be exposed using

```solidity
    MerkleProofLib.toCID(rootHash);
```

The base32 CID can be obtained by

```shell
    echo "$base_cid" | sed 's/^0x00/f/' | ipfs cid format -b base32
```

where `$base_cid` is the raw bytes output from `MerkleProofLib.toCID()`.

## Safety

This work has not been reviewed by an independent security researcher. Use it at your own risk.

### Nodes as leaves

This implementation always hashes CBOR representation of input bytes. Therefore it is not possible to pass special values that can clash with the nodes.

### Second preimage attack

This implementation is not vulnerable to second preimage attack. This is due to the difference in how leaves and nodes are generated. In CBOR encoding, leaves are byte strings and user input is always prepended by a byte in the range `0x40...0x5f`. Nodes on the other hand, are combined as an array of two, hence always prepended by `0x82`.

## Gas Cost

This implementation is expected to be slightly more expensive than OpenZeppelin's implementation due to encoding operations involving insertion of extra bytes.
