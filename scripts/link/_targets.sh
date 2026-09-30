#!/usr/bin/env bash
# Single source of truth for the two things both linkers share:
#   1. TARGET_NAMES + target_dir() - the link target map
#      (logical name -> destination root).
#   2. EXTRA_REPO_DIRS - extra source repos linked alongside this one.
# Sourced by both link-files.sh and link-dirs.sh; each walks its source
# trees (file-links/ or dir-links/, plus the OS-scoped .linux/.darwin
# variants, see set_link_source_trees in _link_lib.sh) in every repo and
# resolves <target>/<rel> to $(target_dir <target>)/<rel> for symlink
# creation.
#
# Deliberately NOT a `declare -A` associative array: macOS ships bash 3.2
# (the last GPLv2 release, frozen in 2007), which has no associative arrays,
# and the linkers must work on a fresh Mac before Homebrew can provide a
# newer bash. A name array plus a case lookup is the bash-3.2-portable
# equivalent, with deterministic iteration order as a bonus.
#
# Add a target = one entry in TARGET_NAMES + one case arm in target_dir().
# Values must be absolute paths; the precheck rejects relative paths with a
# clear error.

TARGET_NAMES=(home config claude codex agents)

target_dir() {
  case "$1" in
    home)   echo "$HOME" ;;
    config) echo "$HOME/.config" ;;
    # Claude Code config
    claude) echo "$HOME/.claude" ;;
    # Codex CLI config (config.toml, global AGENTS.md)
    codex)  echo "$HOME/.codex" ;;
    # Agent-Skills-standard shared location (~/.agents/skills), read by Codex
    # and other AGENTS.md-standard harnesses
    agents) echo "$HOME/.agents" ;;
    *)
      echo "target_dir: unknown target '$1'" >&2
      return 1
      ;;
  esac
}

# This work setup links only its own repository.
EXTRA_REPO_DIRS=()
