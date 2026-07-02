#!/usr/bin/env bash
# Runs every non-underscore script in this directory.
# Add a new tweak = drop a new `*.sh` file here.
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
for script in "$SCRIPT_DIR"/[^_]*.sh; do
    "$script"
done
