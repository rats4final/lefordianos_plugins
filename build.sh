#!/usr/bin/env bash
# Shortcut for: python3 tools/build.py [plugin]   (the real build script; works on Windows too)
exec python3 "$(dirname "$0")/tools/build.py" "$@"
