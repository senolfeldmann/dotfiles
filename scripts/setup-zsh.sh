#!/usr/bin/env bash
# Installs oh-my-zsh and the gruvbox theme. Idempotent: re-running skips both
# steps if already installed. Designed to leave the existing .zshrc symlink
# untouched (KEEP_ZSHRC=yes); the installer is run --unattended so it does
# not chsh or start zsh at the end.
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/_guards.sh"

require_command zsh

# Install oh-my-zsh if not already present
# Source: https://github.com/ohmyzsh/ohmyzsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "Setting up Oh My Zsh"
  KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "oh-my-zsh already installed, skipping."
fi

# Install gruvbox theme if not already present
# Source: https://github.com/sbugzu/gruvbox-zsh
GRUVBOX_THEME="$HOME/.oh-my-zsh/custom/themes/gruvbox.zsh-theme"
if [[ ! -f "$GRUVBOX_THEME" ]]; then
  echo "Fetching Gruvbox theme"
  curl -L https://raw.githubusercontent.com/sbugzu/gruvbox-zsh/master/gruvbox.zsh-theme > "$GRUVBOX_THEME"
else
  echo "Gruvbox theme already installed, skipping."
fi