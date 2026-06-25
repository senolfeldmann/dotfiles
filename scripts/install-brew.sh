#!/bin/bash
# Installs Homebrew packages from packages/Brewfile via `brew bundle`.
# The Homebrew tool itself is installed separately by setup-homebrew.sh.
#
# brew internally calls `sudo -k` as a safety measure (it refuses to run as
# root and clears any lingering sudo authorization). On a shared TTY that
# would kill apply.sh's parent sudo cache and force a second password prompt
# later in the run. We wrap the brew call in `script(1)` to give it its own
# pseudo-TTY: with sudo's default `tty_tickets=on`, the cache is keyed by
# TTY, so brew's sudo -k targets the (empty) PTY's timestamp instead of the
# parent's, and the parent cache survives untouched.
#
# `script(1)` ships by default on macOS (BSD) but on Fedora is in the
# separate `util-linux-script` package, listed in packages/dnf.txt so
# apply.sh installs it before this script runs on a fresh machine. The
# Linux and BSD invocations differ; we branch on $OSTYPE. If `script` is
# unavailable for any reason, we fall back to a direct brew call and
# accept the second password prompt.
set -e

if ! command -v brew >/dev/null 2>&1; then
  echo "[install-brew] brew not installed, skipping."
  exit 0
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
brewfile="$REPO_DIR/packages/Brewfile"

if command -v script >/dev/null 2>&1; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # BSD script: command and args follow the typescript file.
    script -q /dev/null brew bundle --file="$brewfile"
  else
    # GNU/util-linux script: -c takes the command as a single shell string.
    script -qc "brew bundle --file='$brewfile'" /dev/null
  fi
else
  echo "[install-brew] note: script(1) not available; brew will invalidate the parent sudo cache."
  brew bundle --file="$brewfile"
fi
