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

TARGET_NAMES=(home config claude)

target_dir() {
  case "$1" in
    home)   echo "$HOME" ;;
    config) echo "$HOME/.config" ;;
    # Claude Code config; sources may live in a private repo (see EXTRA_REPO_DIRS)
    claude) echo "$HOME/.claude" ;;
    *)
      echo "target_dir: unknown target '$1'" >&2
      return 1
      ;;
  esac
}

# Extra repos linked with the same file-links/ + dir-links/ layout as this
# one. The repo containing the link scripts is always linked first; each path
# here is linked after it, in order. Missing paths are skipped (the linkers
# guard with -d), so a public fork without these repos, or a machine that has
# not cloned a private repo yet, simply links what it has.
#
# To add another private/work repo: clone it, give it file-links/<target>/
# and/or dir-links/<target>/ subtrees, and add its absolute path below.
EXTRA_REPO_DIRS=(
  "$HOME/dotfiles-private"
)
