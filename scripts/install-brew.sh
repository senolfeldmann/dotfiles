#!/usr/bin/env bash
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

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/_guards.sh"

require_command brew

run_bundle() {
  local brewfile="$1"
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
}

# Brewfile is the productivity baseline; Brewfile_extras holds the personal
# extras (entertainment, media tooling) that a pure work machine would skip.
# On such a machine, comment the second line out or run this script's steps
# manually with just the first file.
run_bundle "$REPO_DIR/packages/Brewfile"
run_bundle "$REPO_DIR/packages/Brewfile_extras"
