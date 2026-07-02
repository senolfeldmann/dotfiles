#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/_guards.sh"

require_command apt-get

PACKAGE_FILES=("$REPO_DIR/packages/apt.txt")
if [[ "${DOTFILES_NO_UI:-0}" == "1" ]]; then
  echo "[install-apt] DOTFILES_NO_UI=1, skipping packages/apt-ui.txt."
else
  PACKAGE_FILES+=("$REPO_DIR/packages/apt-ui.txt")
fi

grep -hvE '^\s*(#|$)' "${PACKAGE_FILES[@]}" | xargs -r sudo apt-get install -y
