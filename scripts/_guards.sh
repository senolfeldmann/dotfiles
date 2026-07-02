#!/usr/bin/env bash
# Shared applicability guards. Sourced (not invoked) by install/setup/tweak
# scripts; each guard checks one precondition and, when unmet, prints a
# uniform skip message and exits 0. Skipping is success by design: apply.sh
# runs every script on every OS and expects the not-applicable ones to bow
# out cleanly.
#
# Scope note: these are "does this script apply here?" guards. Idempotency
# guards of the opposite kind ("already done, nothing to do", e.g. in
# setup-homebrew.sh and install-claude-code.sh) stay inline; conflating the
# two would blur what a skip message means.
#
# The message prefix is derived from the sourcing script's filename, so
# scripts carry no naming boilerplate.
#
# Keep this file bash-3.2 compatible (macOS /bin/bash): no associative
# arrays, no mapfile.

GUARD_NAME="$(basename "$0" .sh)"

# skip <reason>: uniform skip message + clean exit.
skip() {
  echo "[$GUARD_NAME] $1, skipping."
  exit 0
}

# require_linux: for scripts touching Linux-only machinery
# (systemd, udev, fstab, firewalld, sysctl).
require_linux() {
  [[ "$(uname -s)" == "Linux" ]] || skip "not Linux"
}

# require_darwin: counterpart for macOS-only machinery
# (defaults, launchd, osascript).
require_darwin() {
  [[ "$(uname -s)" == "Darwin" ]] || skip "not macOS"
}

# require_command <cmd>: the tool this script drives must exist. The message
# deliberately names only the missing command, not where it comes from:
# references to other scripts or install methods drift out of date.
require_command() {
  command -v "$1" >/dev/null 2>&1 || skip "$1 not available"
}

# require_ui: desktop-only scripts bow out under apply.sh --no-ui.
require_ui() {
  [[ "${DOTFILES_NO_UI:-0}" != "1" ]] || skip "DOTFILES_NO_UI=1"
}
