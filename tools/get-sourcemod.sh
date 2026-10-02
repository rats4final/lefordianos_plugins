#!/usr/bin/env bash
# Downloads the SourceMod compiler and include files we build with into tools/sourcemod/.
# The version is pinned in tools/SOURCEMOD_VERSION so everyone builds with the same one.
#
#   tools/get-sourcemod.sh            download the pinned version
#   tools/get-sourcemod.sh latest     download the newest 1.12 build and pin it
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
branch="1.12"
version="$(cat "$here/SOURCEMOD_VERSION")"

if [[ "${1:-}" == "latest" ]]; then
	file="$(curl -fsSL "https://sm.alliedmods.net/smdrop/$branch/sourcemod-latest-linux")"
	version="${file#sourcemod-}"
	version="${version%-linux.tar.gz}"
	echo "$version" > "$here/SOURCEMOD_VERSION"
fi

dest="$here/sourcemod/$version"
if [[ -x "$dest/spcomp64" ]]; then
	echo "SourceMod $version already in $dest"
else
	tmp="$(mktemp -d)"
	trap 'rm -rf "$tmp"' EXIT
	url="https://sm.alliedmods.net/smdrop/$branch/sourcemod-$version-linux.tar.gz"
	echo "Downloading $url"
	curl -fsSL "$url" -o "$tmp/sm.tar.gz"
	tar -xzf "$tmp/sm.tar.gz" -C "$tmp" addons/sourcemod/scripting
	mkdir -p "$dest"
	cp -r "$tmp/addons/sourcemod/scripting/spcomp64" "$tmp/addons/sourcemod/scripting/include" "$dest/"
	chmod +x "$dest/spcomp64"
fi

ln -sfn "$version" "$here/sourcemod/current"
"$dest/spcomp64" 2>&1 | head -1 || true
