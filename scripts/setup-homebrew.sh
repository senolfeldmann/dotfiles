#!/bin/bash
# Installs the Homebrew tool itself. Package installation via `brew bundle`
# is handled separately by install-brew.sh.
# Source: https://brew.sh/

if command -v brew >/dev/null 2>&1; then
  echo "Homebrew already installed, skipping."
  exit 0
fi

echo "Installing Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"