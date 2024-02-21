This project defines an IPLD-based merkle tree to be used in Solidity, provides a Solidity library for merkle proof verification, and provides shell scripts for tree and proof generations.

## IPDL-based Merkle tree in Solidity

Using IPDL-based merkle trees in Ethereum merkle proofs allows generating an IPFS content identifier (CID) from a given root hash.
Using the generated CID, anyone can retrieve the entire merkle tree from IPFS and generate a proof in a decentralized and permissionless manner.

## Design

Leaf properties are initially Solidity ABI encoded. The resulting bytes
are then DAG-CBOR encoded, which has the followin DAG-JSON representation.

```
{"/": { "bytes": String /* Leaf bytes */ }}
```

The DAG-CBOR object is then converted to the following CID representation.

```
base      : raw       // 0x00
version   : cidv1     // 0x01
codec     : dag-cbor  // 0x71
hash algo : keccak256 // 0x16
hash len  : 256 bits  // 0x20
```

If the number of leaves is not a power of two, null leaves are inserted until the number of leaves is a power of two. A null leaf is the CID of `null` DAG-CBOR object (`0xf6`), which is `bafyrwie3cmps4ofjp7zlyrzxhydka74mcppswcpj76ox7kfqhfxtfftfti`.

Leaves are then sorted from lesser to greater, and then combined into nodes in pairs of two. The leaf pairs are encoded to DAG-CBOR with the following DAG-JSON representation.

```
[{"/": String /* Node0 CID */}, {"/": String /* Node1 CID */}]
```

The resulting DAG-CBOR object is then converted to the CID representation specified earlier.

After all leaves are processed in this manner, the resulting layer of nodes are also processed in pairs. But this time, instead of the entire node layer getting sorted, each pair is sorted wihin before being processed. Nodes are then combined and encoded the same way as leaves. The process ends when the root node is reached.

## Usage

### Merkle tree generation

Create a `leaves.txt` file. Each line of the file is an entry. Each entry consists of properties (Solidity types) separated by space. During leaf generation, these arguments will be abi encoded and converted into DAG-CBOR object as a string. A leaves file might look like below.

```csv
0x000000000000000000000000000000000000dead 666
0xffffffffffffffffffffffffffffffffffffffff 69
0x00000000000000000000000000000000000ba5ed 420
0x000000000000000000000000000000000000beef 420000000000000000000000000000000000000000000000000
0x00000000000000000000000000000dddd000beef 420000000000000000000000000000000000000000000000000
0x000000000000000000000000000000000000beef 420000000000000000000000000000000000000000000000000
0x729ff36456a950552663852e0ece2efed62e3abc 7050
0x5fd1c10f643d36712c2311c0b3917ead9b3d9c6e 20657
0x03b2e5e0aa6fc158f8c3e7179382976599fbb249 10405
0x70a4943fe8380264b934cdeb2d7cbd3160ead4a3 26909
0x53c42367d85469a43fd4b69547a9fb6847b3c2d7 15529
0x935b324c900d022f219729f25a8e89aabeded87b 24575
0x1658862a107c0317753780af0cdacddfb404fad2 26721
```

To generate the tree, execute shell script `script/generate_tree.sh`.

```shell
sh script/generate_tree.sh 'address, uint256' example/leaves.txt
```

The script takes the abi encoder types as the first argument and the leaves file location as the second argument. This script will create a directory with tree data inside `script/tree_from_leaves`, put the DAG-CBOR tree on IPFS, and output the root hash and CID. The root hash is what the library uses to verify the proof, not the root CID. Likewise, the library uses hashes in the proof as well, not the nodes' CIDs.

You need to be mindful of the below when running the `generate_tree.sh` script:

1. Any previous tree in `script/tree_from_leaves` will be overwritten
2. DAG-CBOR tree will be public on IPFS unless your node is private
3. IPFS tree can be garbage collected, pass `--pin` as the third argument to the script to prevent garbage collection

Also note that this script is a protype and hence very slow. Ideally someone writes this in an efficient language.

### Tree retreival

Merkle tree for can be retreived from the root CID by running

```shell
sh script/get_tree.sh ROOT_CID
```

which will output the entire tree to `script/tree_from_cid`. Note that

1. Any previous tree in `script/tree_from_cid` will be overwritten
2. DAG_CBOR tree has to be accessible on IPFS (local or remote)
3. It gets the leaves' CIDs, but not their contents

### Proof generation

Proof for a LEAF_CID's inclusion in ROOT_CID can be generated by running

```shell
sh script/generate_proof.sh ROOT_CID LEAF_CID
```

This will use the tree in `script/tree_from_cid`. If such tree doesn't exist, or the root cid's don't match, then the script will run the `get_tree.sh` script, overwriting any previous retreived trees.

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

This implementation is not vulnerable to second preimage attack. This is due to the difference in how leaves and nodes are generated. In CBOR encoding, leaves are byte strings and user input is always prepended by a byte in the range `0x40...0x5f`. Empty leaves are simply `0xf6`. Nodes on the other hand, are combined as an array of two, hence always prepended by `0x82`.

## Gas Cost

This implementation is expected to be slightly more expensive than OpenZeppelin's implementation due to encoding operations involving insertion of extra bytes.

## Future

NPM repo. Proper versioning, etc.

Shell scripts should be replaced by a proper language. Especially a JS script for generating proof from CID to enable usage in web browser dapps.

Potentially leaf data can be native CBOR encoded instead of Solidity ABI encoded bytes encoded as CBOR. That could for example simplify querying IPFS for an address associated to a leaf. Eg. for (address user, uint256 amount) it could allow user to construct proof without downloading the entire merkle tree even if they don't know the amount airdropped.

standardize???
