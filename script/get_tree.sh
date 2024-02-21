#!/usr/bin/env sh
set -C #noclobber
set -e #errexit
set -f #noglob
set -u #nounset

print_usage() {
	printf '\nUsage: `sh %s ROOT_CID`\n\n' "$0"
	printf 'ROOT_CID: IPLD CID of the root object.\n\n'
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

[ "$#" -ne 1 ] && print_usage
script_path="$(dirname "$0")"
root="$1"

tree_path="$script_path"/tree_from_cid
rm -rf "$tree_path"
mkdir "$tree_path"

printf '%s\n' "$root" > "$tree_path"/0
err=""

i=0
while true
do
	echo "Retreving layer $i"

	j=0
	while read -r cid
	do
		object=$(ipfs dag get "$cid")

		valid_node "$object" || {
			# Guess whether we are at leaves or if object is invalid.
			if [ "$j" -eq 0 ] && [ "$i" -ne 0 ]
			then
				break 2
			else
				err="invalid_cid"
				break 2
			fi
		}

		node0=$(printf '%s' "$object" | jq --raw-output --exit-status '.[0]."/"')
		node1=$(printf '%s' "$object" | jq --raw-output --exit-status '.[1]."/"')
		printf '%s\n%s\n' "$node0" "$node1"

		j=$(( j + 1 ))
	done < "$tree_path"/"$i" > "$tree_path"/"$(( i + 1 ))"

	i=$(( i + 1 ))
done
rm "$tree_path"/"$(( i + 1 ))"

[ "$err" = 'invalid_cid' ] && {
	echo "Invalid CID object"
	print_usage
}
echo "Retreived the tree."
