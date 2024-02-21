#!/usr/bin/env sh
set -C #noclobber
set -e #errexit
set -f #noglob
set -u #nounset

print_usage() {
	printf '\nUsage: `sh %s ARG_STRUCT LEAVES_FILE [--pin]`\n\n' "$0"
	printf 'ARG_STRUCT: Types to define Solidity abi encoder structure. eg. `address, uint256`\n'
	printf 'LEAVES_FILE: File that stores one leaf data per line. Leaf data is space delimited abi.encode arguments.\n\n'
	printf 'Test correct leaves file structure with `cast abi-encode "foo(ARG_STRUCT)" LEAVES_FILE[n]`.\n\n'
	exit
}

[ -z "$1" ] && print_usage
[ -f "$2" ] || print_usage

script_path="$(dirname "$0")"
arg_struct="$1"
leaves_file="$2"

if [ "$#" -eq 3 ]
then
	pin="$3"
	[ "$pin" != '--pin' ] && print_usage
elif [ "$#" -gt 3 ]
then
	print_usage
fi

. "$script_path"/shared.sh

# Get diff btw $1 and smallest power of two that fits $1
# e.g f(3)->(4-3)=1, f(4)->(4-4)=0, f(5)->(8-5)=3, etc
# Exception is f(1)->1, not f(1)->(1-1)=0.
smallest_power_of_two_diff() {
	bits=$(printf 'obase=2; %u\n' "$1" | bc)

	if [ "$1" -eq 0 ]
	then
		echo "Empty leaves file!"
		print_usage
	elif [ "$1" -eq 1 ]
	then
		echo 1
	else
		highest_bit=$(printf '%s\n' "$bits" | sed 's/^\(.\).*/\1/')
		lower_bits=$(printf '%s\n' "$bits" | sed 's/^.\(.*\)/\1/')

		if [ "$(printf '%u\n' "$lower_bits")" -eq 0 ] && [ "$highest_bit" -eq 1 ]
		then
			echo 0
		else
			bit_count=$(printf '%s' "$bits" | wc -c)
			power_of_two=$(cast shl 1 "$bit_count")
			echo $(( power_of_two - $1 ))
		fi
	fi
}

get_twos_power() {
	printf 'obase=2; %u\n' "$1" | bc | tr -d '\n1' | wc -c
}

# Overwrites previous tree.
tree_path="$script_path"/tree_from_leaves
rm -rf "$tree_path"
mkdir "$tree_path"

# Parse leaves.
echo "Hashing leaves. Might take a while."
while read -r line
do
	leaf_hexdata=$(cast abi-encode "foo(${arg_struct})" $line)
	leaf_hexdata=${leaf_hexdata##0x}
	leaf_base64data=$(python3 "$script_path"/hex2base64.py "$leaf_hexdata")
	leaf_base64data=${leaf_base64data##b\'}
	leaf_base64data=${leaf_base64data%%\'}
	leaf=$(printf '{"/":{"bytes":"%s"}}\n' "$leaf_base64data" | ipfs_put)
	leaf_hash=$(strip_cid "$leaf")
	printf '%s:%s\n' "$leaf_hash" "$leaf"
done < "$leaves_file" | sort | uniq > "$tree_path"/0

# Add null leaves to ensure there are 2^n elements.
missing_count=$(smallest_power_of_two_diff $(line_count "$tree_path"/0))
empty_leaf=$(echo 'null' | ipfs_put)
empty_hash=$(strip_cid "$empty_leaf")
yes "$empty_hash:$empty_leaf" | head -"$missing_count" > "$tree_path"/0.tmp
cat "$tree_path"/0 >> "$tree_path"/0.tmp
rm "$tree_path"/0
sort "$tree_path"/0.tmp > "$tree_path"/0
rm "$tree_path"/0.tmp

# Generate rest of the tree.
i=$(get_twos_power $(line_count "$tree_path"/0))
mv "$tree_path"/0 "$tree_path"/"$i"
while true
do
	[ "$(line_count "$tree_path"/"$i")" -eq 1 ] && {
		sed 's/\(.*\):\(.*\)/ROOT HASH: \1\nROOT CID: \2/' "$tree_path"/"$i"
		break
	}

	echo "Generating node layer $i"

	prev_line=""
	while read -r line
	do
		if [ -z "$prev_line" ]
		then
			prev_line="$line"
		else
			node0=$(printf '%s\n%s\n' "$prev_line" "$line" | sort | sed '2d;s/.*://')
			node1=$(printf '%s\n%s\n' "$prev_line" "$line" | sort | sed '1d;s/.*://')
			node=$(printf '[{"/": "%s"}, {"/": "%s"}]\n' "$node0" "$node1" | ipfs_put)
			node_hash=$(strip_cid "$node")
			printf '%s:%s\n' "$node_hash" "$node"

			prev_line=""
		fi
	done < "$tree_path"/"$i" > "$tree_path"/$(( i - 1 ))

	i=$(( i - 1 ))
done
