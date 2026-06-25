#!/bin/bash
set -e

if ! command -v dnf >/dev/null 2>&1; then
  echo "[install-dnf-extras] dnf not available, skipping."
  exit 0
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
while IFS= read -r cmd; do
    sudo dnf -y $cmd
done < <(grep -vE '^\s*(#|$)' "$REPO_DIR/packages/dnf-extras.txt")
