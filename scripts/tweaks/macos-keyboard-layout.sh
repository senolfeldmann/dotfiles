#!/usr/bin/env bash
# Install US German Turkish on macOS.
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../_guards.sh"

require_darwin
require_ui
require_command rsync
require_command diff

source_bundle="$SCRIPT_DIR/../../assets/keyboard-layouts/us-german-turkish/USGermanTurkish.bundle"
target_bundle="/Library/Keyboard Layouts/USGermanTurkish.bundle"

if [[ -L "$target_bundle" ]]; then
  echo "[macos-keyboard-layout] Target is a symlink: $target_bundle" >&2
  exit 1
fi

if [[ -d "$target_bundle" ]] && diff -qr -x .DS_Store "$source_bundle" "$target_bundle" >/dev/null; then
  echo "[macos-keyboard-layout] Layout is current, skipping."
  exit 0
fi

sudo rsync -a --delete --exclude .DS_Store "$source_bundle/" "$target_bundle/"
echo "[macos-keyboard-layout] US German Turkish installed. Enable it in Keyboard settings, then log out and back in."
