#!/usr/bin/env bash
# Clones the reference repos listed in tools/refs.txt next to this repo (into ../),
# checked out at the pinned commits, so build.sh and the docs find them.
#
#   tools/fetch-refs.sh           clone missing repos at the pinned commits
#   tools/fetch-refs.sh --update  also move existing ones to the pinned commits
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
dest="${REFS:-$(cd "$here/../.." && pwd)}"
update="${1:-}"

grep -v '^\s*#' "$here/refs.txt" | while read -r name url commit; do
	[[ -n "$name" ]] || continue
	dir="$dest/$name"
	if [[ ! -d "$dir/.git" ]]; then
		echo "==> cloning $name"
		git clone -q "$url" "$dir"
	elif [[ "$update" != "--update" ]]; then
		echo "==> $name already there (use --update to move it to the pinned commit)"
		continue
	fi
	git -C "$dir" fetch -q origin "$commit" 2>/dev/null || git -C "$dir" fetch -q origin
	git -C "$dir" -c advice.detachedHead=false checkout -q "$commit"
	echo "    $name @ ${commit:0:9}"
done
