# Strip CID from everything except its remaining raw keccak hash. Takes CID as positional argument.
strip_cid() {
	ipfs cid format -b base16 "$1" | grep --extended-regexp --only-matching '.{64}$'
}

# Create DAG-CBOR object from the DAG-JSON stdin input and publish it to IPFS.
ipfs_put() {
	ipfs dag put ${pin:-} --hash keccak-256 --input-codec dag-json --store-codec dag-cbor
}

line_count() {
	wc -l "$1" | sed 's/ .*//'
}
