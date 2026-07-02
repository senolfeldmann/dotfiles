#!/usr/bin/env bash
# Installs Ollama on Linux via the official installer, which sets up the
# systemd service and GPU support - both of which the brew formula lacks.
# On macOS Ollama is the `ollama-app` cask instead (see packages/Brewfile).
#
# Idempotent via `command -v ollama` guard. Upgrades on Linux are re-runs
# of the same installer (it overwrites in place); Ollama has no
# self-update mechanism outside macOS.
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/_guards.sh"

require_linux

if command -v ollama >/dev/null 2>&1; then
  echo "[install-ollama] Ollama already installed, skipping."
  exit 0
fi

echo "Installing Ollama"
curl -fsSL https://ollama.com/install.sh | sh
