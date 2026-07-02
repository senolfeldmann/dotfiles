#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/_guards.sh"

require_command mise

echo "Setting mise compile flags for Python and Ruby"
mise settings python.compile=1
mise settings ruby.compile=true

echo "Installing stuff with mise"
mise use -g python@3.14.4
mise use -g ruby@4.0.2
mise use -g node@25.9.0
mise use -g rust@1.96.1