#!/usr/bin/env bash
# Install the global mise runtimes. The set of runtimes, their pinned
# versions, and the compile settings are declared in the tracked global
# config (file-links/config/mise/config.toml, symlinked to
# ~/.config/mise/config.toml before this runs - see apply.sh ordering).
# This script only realizes that declaration, so the config file stays the
# single source of truth; `mise use -g` here would write back through the
# symlink and drift the repo copy.
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/_guards.sh"

require_command mise

echo "Installing global mise runtimes from ~/.config/mise/config.toml"
mise install
