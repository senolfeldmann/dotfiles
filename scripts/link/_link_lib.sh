#!/usr/bin/env bash
# Shared helpers for link-files.sh and link-dirs.sh. Sourced, not invoked.
# Assumes the caller has already sourced _targets.sh (TARGET_NAMES and
# target_dir must exist) and runs under `set -euo pipefail`.

# set_link_source_trees <repo_dir> <kind>: fill the global LINK_SOURCE_TREES
# array with the source trees to walk for this repo and kind ("file-links"
# or "dir-links"): the common tree plus the OS-scoped sibling matching the
# current OS (<kind>.linux on Linux, <kind>.darwin on macOS). Content in an
# OS-scoped tree is linked only on that OS, so OS-specific configs never end
# up as meaningless symlinks on the other one. Non-existent trees are simply
# omitted. A global array instead of stdout because bash 3.2 (macOS) has no
# mapfile to read a list back conveniently.
set_link_source_trees() {
  local repo_dir="$1" kind="$2" suffix=""
  LINK_SOURCE_TREES=()
  case "$(uname -s)" in
    Linux)  suffix="linux" ;;
    Darwin) suffix="darwin" ;;
  esac
  [[ -d "$repo_dir/$kind" ]] && LINK_SOURCE_TREES+=("$repo_dir/$kind")
  [[ -n "$suffix" && -d "$repo_dir/$kind.$suffix" ]] && LINK_SOURCE_TREES+=("$repo_dir/$kind.$suffix")
  return 0
}

# Sanity check: every target must resolve to an absolute path. Catches typos
# in _targets.sh before they cause silent damage downstream (relative paths
# would resolve against $PWD when the script runs, producing surprises).
check_targets_sanity() {
  local target val
  for target in "${TARGET_NAMES[@]}"; do
    val="$(target_dir "$target")"
    if [[ "$val" != /* ]]; then
      echo "Invalid target: $target -> \"$val\" (must be an absolute path)" >&2
      exit 1
    fi
  done
}

# Pre-check: detect conflicts between file-links/ and dir-links/ source layouts.
#
# A conflict is any of:
#   1. Two entries (any combination of file/dir) resolve to the SAME absolute
#      destination path.
#   2. A directory entry's destination is an ANCESTOR of another entry's
#      destination (would create a symlink loop or a destructive overlap).
#
# Comparison is purely lexical: we trust $HOME and the target directories to
# be canonical, and do not call realpath. If $HOME or any target directory
# passes through symlinks itself, we may miss a conflict or report a false
# positive. Documented limitation; not worth realpath complexity for this repo.
#
# Usage: precheck_no_conflicts <repo_dir>
# On conflict: prints all conflicts to stderr and exits 1 (no changes made).
precheck_no_conflicts() {
  local repo_dir="$1"

  # Parallel arrays: type ("f" or "d"), source path, absolute destination
  local -a types=()
  local -a sources=()
  local -a dests=()

  local tree target src_dir entry rel dest

  # Collect every file under each active file-links tree's <target>/...
  # Only the trees active on this OS are checked: the same destination in
  # file-links.linux/ and file-links.darwin/ is a per-OS variant of one
  # config, not a conflict.
  set_link_source_trees "$repo_dir" file-links
  for tree in ${LINK_SOURCE_TREES[@]+"${LINK_SOURCE_TREES[@]}"}; do
    for target in "${TARGET_NAMES[@]}"; do
      src_dir="$tree/$target"
      [[ -d "$src_dir" ]] || continue
      while IFS= read -r -d '' entry; do
        rel="${entry#"$src_dir"/}"
        dest="$(target_dir "$target")/$rel"
        types+=("f")
        sources+=("$entry")
        dests+=("$dest")
      done < <(find "$src_dir" -type f -print0)
    done
  done

  # Collect every top-level directory under each active dir-links tree's
  # <target>/. Only first-level directories are linkable units; nested
  # content lives inside the linked directory.
  set_link_source_trees "$repo_dir" dir-links
  for tree in ${LINK_SOURCE_TREES[@]+"${LINK_SOURCE_TREES[@]}"}; do
    for target in "${TARGET_NAMES[@]}"; do
      src_dir="$tree/$target"
      [[ -d "$src_dir" ]] || continue
      while IFS= read -r -d '' entry; do
        rel="${entry#"$src_dir"/}"
        dest="$(target_dir "$target")/$rel"
        types+=("d")
        sources+=("$entry")
        dests+=("$dest")
      done < <(find "$src_dir" -mindepth 1 -maxdepth 1 -type d -print0)
    done
  done

  # Pairwise compare. O(n^2) but n is small.
  local -a conflicts=()
  local n="${#dests[@]}"
  local i j t1 s1 d1 t2 s2 d2
  for ((i = 0; i < n; i++)); do
    t1="${types[i]}"; s1="${sources[i]}"; d1="${dests[i]}"
    for ((j = i + 1; j < n; j++)); do
      t2="${types[j]}"; s2="${sources[j]}"; d2="${dests[j]}"
      if [[ "$d1" == "$d2" ]]; then
        conflicts+=("$s1 and $s2 both resolve to: $d1")
      elif [[ "$t1" == "d" && "$d2" == "$d1"/* ]]; then
        conflicts+=("$s1 (directory) is ancestor of $s2: target $d2 lies under $d1")
      elif [[ "$t2" == "d" && "$d1" == "$d2"/* ]]; then
        conflicts+=("$s2 (directory) is ancestor of $s1: target $d1 lies under $d2")
      fi
    done
  done

  if (( ${#conflicts[@]} > 0 )); then
    echo "Pre-check failed: link source layout has conflicts." >&2
    echo "Resolve before re-running:" >&2
    printf '  %s\n' "${conflicts[@]}" >&2
    exit 1
  fi
}
