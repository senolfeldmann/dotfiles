#!/bin/bash
set -e

if ! command -v apt-get >/dev/null 2>&1; then
  echo "[install-apt] apt-get not available, skipping."
  exit 0
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
grep -vE '^\s*(#|$)' "$REPO_DIR/packages/apt.txt" | xargs -r sudo apt-get install -y
