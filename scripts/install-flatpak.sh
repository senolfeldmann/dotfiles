#!/bin/bash
set -e

if ! command -v flatpak >/dev/null 2>&1; then
  echo "[install-flatpak] flatpak not available, skipping."
  exit 0
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

while IFS= read -r app; do
  [[ -z "$app" || "$app" =~ ^[[:space:]]*# ]] && continue
  if flatpak info "$app" >/dev/null 2>&1; then
    echo "Flatpak $app already installed, skipping."
    continue
  fi
  flatpak install -y --noninteractive flathub "$app"
done < "$REPO_DIR/packages/flatpak.txt"
