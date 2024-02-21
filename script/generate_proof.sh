#!/usr/bin/env sh
set -C #noclobber
set -e #errexit
set -f #noglob
set -u #nounset

print_usage() {
	printf '\nUsage: `sh %s ROOT_CID LEAF_CID`\n\n' "$0"
	exit
}

valid_node() {
	printf '%s' "$1" | jq --raw-output --exit-status '
		all(
			.[]; has("/") and (.["/"] |
				type == "string" and length == 59 and test("^[A-Za-z2-7]+$"))
		)
	' > /dev/null 2>&1
}

get_root_cid() {
	head -1 "$tree_path"/0
}

[ "$#" -ne 2 ] && print_usage
script_path="$(dirname "$0")"
root="$1"
leaf="$2"

. "$script_path"/shared.sh

tree_path="$script_path"/tree_from_cid

[ -f "$tree_path"/0 -a $(head -1 "$tree_path"/0) = "$root" ] || {
	echo "Tree not found locally, downloading the tree from root cid".
	sh "$script_path"/get_tree.sh "$root"
}

layer=$(ls "$tree_path"/ | sort -r | head -1)
grep --quiet "$leaf" "$tree_path"/"$layer" || {
	echo "Error: Leaf not found within leaves. Either incorrect root or corrupted tree."
	exit
}

cid="$leaf"
cid_hash="$(strip_cid "$cid")"
proof_in_cid=""
proof_in_hash=""
while [ "$layer" -gt 0 ]
do
	grep --quiet "$cid" "$tree_path"/"$layer" || {
		echo "Error: Corrupted merkle tree in tree_from_cid file."
		exit
	}

	line_no=$(grep --line-number "$cid" "$tree_path"/"$layer" | sed 's/:.*//')
	if [ $(( line_no % 2 )) -eq 0 ]
	then
		pair_line_no=$(( line_no - 1 ))
	else
		pair_line_no=$(( line_no + 1 ))
	fi

	pair_cid="$(sed "$pair_line_no"'!d' "$tree_path"/"$layer")"
	pair_hash="$(strip_cid "$pair_cid")"

	lineA="$pair_hash":"$pair_cid"
	lineB="$cid_hash":"$cid"
	node0=$(printf '%s\n%s\n' "$lineA" "$lineB" | sort | sed '2d;s/.*://')
	node1=$(printf '%s\n%s\n' "$lineA" "$lineB" | sort | sed '1d;s/.*://')

	cid="$(printf '[{"/": "%s"}, {"/": "%s"}]\n' "$node0" "$node1" | ipfs_put)"
	cid_hash="$(strip_cid "$cid")"

	# Print proof
	echo "$lineA"

	layer=$(( layer - 1 ))
done

#i=0
#while true
#do
#	echo "Retreving layer $i"
#
#	j=0
#	while read -r cid
#	do
#		object=$(ipfs dag get "$cid")
#
#		valid_node "$object" || {
#			# Guess whether we are at leaves or if object is invalid.
#			if [ "$j" -eq 0 ] && [ "$i" -ne 0 ]
#			then
#				break 2
#			else
#				err="invalid_cid"
#				break 2
#			fi
#		}
#
#		node0=$(printf '%s' "$object" | jq --raw-output --exit-status '.[0]."/"')
#		node1=$(printf '%s' "$object" | jq --raw-output --exit-status '.[1]."/"')
#		printf '%s\n%s\n' "$node0" "$node1"
#
#		j=$(( j + 1 ))
#	done < "$tree_path"/"$i" > "$tree_path"/"$(( i + 1 ))"
#
#	i=$(( i + 1 ))
#done
#rm "$tree_path"/"$(( i + 1 ))"
#
#[ "$err" = 'invalid_cid' ] && {
#	echo "Invalid CID object"
#	print_usage
#}
#echo "Retreived the tree."

