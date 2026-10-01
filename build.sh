#!/usr/bin/env bash
# Compiles every plugin in plugins/*/scripting/ into build/, laid out like a
# server's left4dead2/ folder, so deploying is a straight copy.
#
#   ./build.sh                 build everything
#   ./build.sh lef_teams_panel build one plugin
#
# Uses the compiler and include files from the sibling reference repos.
# Override the locations with REFS=/path/to/l4d2_plugins if they move.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
refs="${REFS:-$here/..}"

spcomp="$refs/L4D2-Competitive-Rework/addons/sourcemod/scripting/sourcemod/spcomp64"
# Order matters: the newest Left4DHooks headers win over the copy bundled with the competitive repo.
includes=(
	"$refs/Left4DHooks/sourcemod/scripting/include"
	"$refs/L4D2-Competitive-Rework/addons/sourcemod/scripting/include"
	"$refs/L4D2-Competitive-Rework/addons/sourcemod/scripting/sourcemod/include"
)

[[ -f "$spcomp" ]] || { echo "Compiler not found: $spcomp" >&2; exit 1; }

# The compiler sometimes loses its executable bit when the repo is copied around;
# starting it through the dynamic loader works either way without touching the file.
run_spcomp() {
	if [[ -x "$spcomp" ]]; then "$spcomp" "$@"; else /lib64/ld-linux-x86-64.so.2 "$spcomp" "$@"; fi
}

out="$here/build/addons/sourcemod"
mkdir -p "$out/plugins" "$out/translations"

inc_args=()
for dir in "${includes[@]}"; do inc_args+=("-i$dir"); done

status=0
for plugin_dir in "$here"/plugins/*/; do
	name="$(basename "$plugin_dir")"
	[[ $# -gt 0 && "$name" != "$1" ]] && continue

	for sp in "$plugin_dir"scripting/*.sp; do
		[[ -e "$sp" ]] || continue
		smx="$out/plugins/$(basename "${sp%.sp}").smx"
		echo "==> $name: $(basename "$sp")"
		if ! run_spcomp "${inc_args[@]}" -i"${plugin_dir}scripting/include" "$sp" -o"$smx" -v0; then
			status=1
		fi
	done

	if [[ -d "${plugin_dir}translations" ]]; then
		cp -r "${plugin_dir}translations/." "$out/translations/"
	fi
done

exit $status
