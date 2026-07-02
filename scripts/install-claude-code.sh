#!/usr/bin/env bash
# Installs Claude Code via the upstream installer script.
# Idempotent via `command -v claude` guard.
set -e

if command -v claude >/dev/null 2>&1; then
  echo "[install-claude-code] Claude Code already installed, skipping."
  exit 0
fi

echo "Installing Claude Code"
curl -fsSL https://claude.ai/install.sh | bash
