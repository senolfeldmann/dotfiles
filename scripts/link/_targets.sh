#!/bin/bash
# Single source of truth for the two things both linkers share:
#   1. TARGETS         - the link target map (logical name -> destination root).
#   2. EXTRA_REPO_DIRS - extra source repos linked alongside this one.
# Sourced by both link-files.sh and link-dirs.sh; each walks its source tree
# (file-links/ or dir-links/) in every repo and resolves <target>/<rel> to
# <TARGETS[target]>/<rel> for symlink creation.
#
# Add a TARGETS entry to make a new logical destination available to both
# linkers. Values must be absolute paths; the precheck rejects relative
# paths with a clear error.

declare -A TARGETS=(
  [home]="$HOME"
  [config]="$HOME/.config"
  [claude]="$HOME/.claude"  # Claude Code config; sources may live in a private repo (see EXTRA_REPO_DIRS)
)

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
