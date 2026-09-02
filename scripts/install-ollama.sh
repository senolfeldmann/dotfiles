#!/usr/bin/env bash
# Installs Ollama on Linux via the official installer, which sets up the
# systemd service and GPU support - both of which the brew formula lacks.
# On macOS Ollama is the `ollama-app` cask instead (see packages/Brewfile).
#
# Idempotent: `command -v ollama` guards the install; the firewall rule is
# idempotent by nature (firewalld reports ALREADY_ENABLED and exits 0).
# Upgrades on Linux are re-runs of the same installer (it overwrites in
# place); Ollama has no self-update mechanism outside macOS.
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/_guards.sh"

require_linux

if command -v ollama >/dev/null 2>&1; then
  echo "[install-ollama] Ollama already installed, skipping install."
else
  echo "Installing Ollama"
  curl -fsSL https://ollama.com/install.sh | sh
fi

# Open the Ollama API port for LAN access. Only meaningful when the service
# is bound beyond localhost (OLLAMA_HOST=0.0.0.0 in the systemd unit); the
# rule is harmless otherwise. Skipped on machines without firewalld.
if command -v firewall-cmd >/dev/null 2>&1; then
  echo "[install-ollama] Opening TCP port 11434 (Ollama API)"
  sudo firewall-cmd --permanent --add-port=11434/tcp
  sudo firewall-cmd --reload
fi
