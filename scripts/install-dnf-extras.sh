#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/_guards.sh"

require_command dnf
while IFS= read -r cmd; do
    sudo dnf -y $cmd
done < <(grep -vE '^\s*(#|$)' "$REPO_DIR/packages/dnf-extras.txt")
