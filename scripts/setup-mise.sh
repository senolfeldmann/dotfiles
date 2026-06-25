#!/bin/bash
set -e

if ! command -v mise >/dev/null 2>&1; then
  echo "[setup-mise] mise not available, skipping."
  exit 0
fi

echo "Setting mise compile flags for Python and Ruby"
mise settings python.compile=1
mise settings ruby.compile=true

echo "Installing stuff with mise"
mise use -g python@3.14.4
mise use -g ruby@4.0.2
mise use -g node@25.9.0