#!/usr/bin/env bash
# Sync the current machine to repo state. Safe to re-run any time.
#
# Each step is a self-contained, idempotent script: guards (command -v X,
# already-installed checks, etc.) live inside each script, not here.
# apply.sh just calls them in dependency order: things that produce a tool
# come before things that consume it.
#
# On a fresh machine, the manual prerequisites (SSH keys, GPG keys, git
# clone of this repo, chsh -s zsh) must be done first; see README.
#
# Usage: apply.sh [--debug] [--no-ui]
#   --debug   Annotate each section header with the current sudo cache state.
#             Useful for diagnosing unexpected password prompts during a run.
#   --no-ui   Terminal-only mode for machines without a desktop (servers,
#             minimal VMs, WSL): skips the desktop package lists
#             (packages/dnf-ui.txt, packages/apt-ui.txt), Flatpaks, Nerd
#             Fonts and the desktop tweaks. Sets the environment variable
#             DOTFILES_NO_UI=1, which every child script inherits; the
#             guards live inside the affected scripts, so a standalone run
#             works the same: DOTFILES_NO_UI=1 ./scripts/install-dnf.sh
set -e

DEBUG=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--debug)
      DEBUG=1
      shift
      ;;
    --no-ui)
      export DOTFILES_NO_UI=1
      shift
      ;;
    -h|--help)
      sed -n '2,/^set -e$/{s/^# \{0,1\}//; /^set -e$/d; p}' "$0"
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Section header. Default is timestamp + name. With --debug, also probe the
# sudo cache state via `sudo -n true` (non-interactive: never prompts;
# succeeds if cache is valid, fails silently if not). The probe refreshes
# the cache as a side effect when valid, so a transition to EXPIRED in the
# log means the cache was actively killed (e.g. by `sudo -k` somewhere)
# since the previous section, not just time-expired.
section() {
  if (( DEBUG )); then
    local cache_state
    if sudo -n true 2>/dev/null; then
      cache_state="VALID"
    else
      cache_state="EXPIRED"
    fi
    printf '\n=== [%s] [cache: %s] %s ===\n' "$(date +%H:%M:%S)" "$cache_state" "$1"
  else
    printf '\n=== [%s] %s ===\n' "$(date +%H:%M:%S)" "$1"
  fi
}

section "Sudo"
# Cache sudo credentials. Default cache lifetime is 5 minutes
# (timestamp_timeout=300). For a normal apply.sh run, that is plenty: the
# whole script finishes well within the cache window. No background keepalive
# needed.
#
# If you ever see a SECOND password prompt during a run, the section header
# right above it tells you exactly when it happened, so we can tell whether
# it is sudo cache expiring (very unlikely on a seconds-long run) or
# something else (e.g. a polkit prompt from `flatpak install` looking like a
# sudo prompt, or a tool that bypasses the cache).
sudo -v

section "Symlinks"
# Two linkers: dirs first (structural takeovers of whole content
# directories), then files (individual files in shared destinations).
# See scripts/link/ for the precheck and the conflict rules they enforce.
DOTFILES_UNATTENDED=1 "$SCRIPT_DIR/link/link-dirs.sh"
DOTFILES_UNATTENDED=1 "$SCRIPT_DIR/link/link-files.sh"

section "Fedora repos"
"$SCRIPT_DIR/setup-fedora-repos.sh"

section "OS packages"
"$SCRIPT_DIR/install-dnf.sh"
"$SCRIPT_DIR/install-dnf-extras.sh"
"$SCRIPT_DIR/install-apt.sh"

section "Homebrew (tool)"
"$SCRIPT_DIR/setup-homebrew.sh"

# install-brew.sh wraps `brew bundle` in script(1) so brew's internal
# `sudo -k` does not invalidate the parent sudo cache. See the comment at
# the top of install-brew.sh for the full reasoning.
section "Homebrew packages"
"$SCRIPT_DIR/install-brew.sh"

section "Flatpak"
"$SCRIPT_DIR/install-flatpak.sh"

section "Fonts"
"$SCRIPT_DIR/install-nerd-fonts.sh"

section "Claude Code"
"$SCRIPT_DIR/install-claude-code.sh"

section "Ollama"
"$SCRIPT_DIR/install-ollama.sh"

section "Oh My Zsh"
"$SCRIPT_DIR/setup-zsh.sh"

section "Runtimes (mise)"
"$SCRIPT_DIR/setup-mise.sh"

section "Tweaks"
"$SCRIPT_DIR/tweaks/_run.sh"

section "Done"
