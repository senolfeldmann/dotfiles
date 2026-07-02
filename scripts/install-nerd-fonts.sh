#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/_guards.sh"

require_ui
# On macOS the Nerd Fonts come from Brew casks instead; no fontconfig there.
require_command fc-list

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

fonts=("FiraCode" "FiraMono")
installed_any=0

for font in "${fonts[@]}"; do
  # Check the install dir directly instead of fc-list. Nerd Fonts ship under
  # different family-name conventions across versions ("FiraCode Nerd Font"
  # with spaces vs "FiraCodeNerdFont" without), but the on-disk file names
  # always start with "<font>NerdFont*". Globbing the dir we just installed
  # into is more reliable than parsing fc-list output.
  if compgen -G "$FONT_DIR/${font}NerdFont*" > /dev/null; then
    echo "${font} Nerd Font already installed, skipping."
    continue
  fi
  echo "Installing $font Nerd Font..."
  url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
  tmp=$(mktemp -d)
  echo "Downloading $font Nerd Font..."
  curl -fSL "$url" -o "$tmp/${font}.zip"
  echo "Extracting $font Nerd Font..."
  unzip -qo "$tmp/${font}.zip" -d "$FONT_DIR"
  rm -rf "$tmp"
  echo "$font Nerd Font installed."
  installed_any=1
done

if [[ "$installed_any" == "1" ]]; then
  fc-cache -f
  echo "Done. Fonts installed and cache rebuilt."
else
  echo "Done. All Nerd Fonts already present."
fi