#!/usr/bin/env bash
# Installs dnf packages from packages/dnf.txt, plus packages/dnf-ui.txt
# unless DOTFILES_NO_UI=1 (apply.sh --no-ui) asks for a terminal-only setup.
#
# Two passes:
# 1. Regular package and group entries get fed to a single `dnf install`
#    call. dnf handles its own idempotency (already-installed -> skip).
# 2. URL entries (direct .rpm URLs) need explicit handling because dnf
#    re-downloads them on every run, even when the package is already
#    installed. We parse the package name out of the RPM filename and
#    skip the URL entirely if `rpm -q <name>` reports it as installed.
#
# RPM filename convention: <name>-<version>-<release>[.<arch>].rpm
# Stripping from the right with bash parameter expansion gives us <name>,
# even when <name> contains hyphens (e.g. gnu-make).
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/_guards.sh"

require_command dnf

PACKAGE_FILES=("$REPO_DIR/packages/dnf.txt")
if [[ "${DOTFILES_NO_UI:-0}" == "1" ]]; then
  echo "[install-dnf] DOTFILES_NO_UI=1, skipping packages/dnf-ui.txt."
else
  PACKAGE_FILES+=("$REPO_DIR/packages/dnf-ui.txt")
fi

# --- Pass 1: regular packages and groups, in one dnf transaction ---
mapfile -t regular < <(grep -hvE '^\s*(#|$)' "${PACKAGE_FILES[@]}" | grep -vE '^https?://')
if (( ${#regular[@]} > 0 )); then
  sudo dnf install -y "${regular[@]}"
fi

# --- Pass 2: URL entries with rpm -q guard ---
# Note: the RPM filename's <name> may not match the installed package name
# byte-for-byte. RPM specs are allowed to set Name: independently of the
# filename's casing (e.g. Handy-0.8.2-1.x86_64.rpm registers as "handy").
# We therefore check case-insensitively against rpm -qa.
mapfile -t urls < <(grep -hE '^https?://' "${PACKAGE_FILES[@]}")
for url in "${urls[@]}"; do
  filename="${url##*/}"
  # Strip ".rpm", then "-version-release" from the right; what remains is
  # the name. Done in two steps because the <arch> part is optional in the
  # wild (crossover-26.2.0-1.rpm has none) and a single glob covering both
  # shapes would misparse one of them.
  base="${filename%.rpm}"
  pkg_name="${base%-*-*}"

  if rpm -qa --queryformat '%{NAME}\n' | grep -qix "$pkg_name"; then
    echo "[install-dnf] $pkg_name already installed, skipping URL download."
    continue
  fi

  echo "[install-dnf] Installing $pkg_name from $url"
  sudo dnf install -y "$url"
done
