#!/bin/bash
# Installs dnf packages from packages/dnf.txt.
#
# Two passes:
# 1. Regular package and group entries get fed to a single `dnf install`
#    call. dnf handles its own idempotency (already-installed -> skip).
# 2. URL entries (direct .rpm URLs) need explicit handling because dnf
#    re-downloads them on every run, even when the package is already
#    installed. We parse the package name out of the RPM filename and
#    skip the URL entirely if `rpm -q <name>` reports it as installed.
#
# RPM filename convention: <name>-<version>-<release>.<arch>.rpm
# Stripping from the right with bash parameter expansion gives us <name>,
# even when <name> contains hyphens (e.g. gnu-make).
set -e

if ! command -v dnf >/dev/null 2>&1; then
  echo "[install-dnf] dnf not available, skipping."
  exit 0
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
DNF_TXT="$REPO_DIR/packages/dnf.txt"

# --- Pass 1: regular packages and groups, in one dnf transaction ---
mapfile -t regular < <(grep -vE '^\s*(#|$)' "$DNF_TXT" | grep -vE '^https?://')
if (( ${#regular[@]} > 0 )); then
  sudo dnf install -y "${regular[@]}"
fi

# --- Pass 2: URL entries with rpm -q guard ---
# Note: the RPM filename's <name> may not match the installed package name
# byte-for-byte. RPM specs are allowed to set Name: independently of the
# filename's casing (e.g. Handy-0.8.2-1.x86_64.rpm registers as "handy").
# We therefore check case-insensitively against rpm -qa.
mapfile -t urls < <(grep -E '^https?://' "$DNF_TXT" | grep -vE '^\s*#')
for url in "${urls[@]}"; do
  filename="${url##*/}"
  # Strip "-version-release.arch.rpm" from the right; what remains is the name.
  pkg_name="${filename%-*-*.*.rpm}"

  if rpm -qa --queryformat '%{NAME}\n' | grep -qix "$pkg_name"; then
    echo "[install-dnf] $pkg_name already installed, skipping URL download."
    continue
  fi

  echo "[install-dnf] Installing $pkg_name from $url"
  sudo dnf install -y "$url"
done
