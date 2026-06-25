#!/bin/bash
# Symlink whole directories from dir-links/<target>/<dirname> to
# <TARGETS[target]>/<dirname>. For destinations dedicated to user-curated
# content where Claude Code or another tool may write new files into the
# directory and we want them to land in the dotfiles repo automatically.
# For individual files in mixed directories, see link-files.sh.
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# shellcheck source=_targets.sh
source "$SCRIPT_DIR/_targets.sh"
# shellcheck source=_link_lib.sh
source "$SCRIPT_DIR/_link_lib.sh"

# This repo first, then the extra source repos from _targets.sh. Each is
# walked the same way; non-existent ones are skipped so a machine missing a
# private repo still links the rest.
REPO_DIRS=("$REPO_DIR" ${EXTRA_REPO_DIRS[@]+"${EXTRA_REPO_DIRS[@]}"})

check_targets_sanity
for repo_dir in "${REPO_DIRS[@]}"; do
  [[ -d "$repo_dir" ]] || continue
  precheck_no_conflicts "$repo_dir"
done

# Behaviour mirrors link-files.sh:
# - If a symlink already exists at the destination:
#     recreate_links=true  -> remove and re-create the symlink
#     recreate_links=false -> skip
# - If a regular directory already exists:
#     skip_existing=true   -> skip
#     skip_existing=false  -> back up to .bak, then link
# - Otherwise: create the symlink
#
# Note: backing up a non-empty directory to .bak has more force than
# backing up a single file. The output line records every backup so the
# operator can decide whether to merge the .bak contents back into the
# linked source manually.

link_dir() {
  local src="$1"
  local dest="$2"

  if [[ -h "$dest" ]]; then
    if [[ "$recreate_links" == "true" ]]; then
      echo "Link already exists: $dest (recreating)"
      rm "$dest"
    else
      echo "Link already exists: $dest (skipping)"
      return
    fi
  fi

  if [[ -e "$dest" ]]; then
    if [[ "$skip_existing" == "true" ]]; then
      echo "Directory exists: $dest (skipping)"
      return
    else
      echo "Directory exists: $dest (backing up to ${dest}.bak)"
      mv "$dest" "${dest}.bak"
    fi
  fi

  mkdir -p "$(dirname "$dest")"
  echo "Linking: $src -> $dest"
  ln -s "$src" "$dest"
}

# --- Preview ---
echo "The following directory mappings will be applied:"
for repo_dir in "${REPO_DIRS[@]}"; do
  [[ -d "$repo_dir" ]] || continue
  links_dir="$repo_dir/dir-links"
  echo "[$repo_dir]"
  for dir in "${!TARGETS[@]}"; do
    src_dir="$links_dir/$dir"
    if [[ ! -d "$src_dir" ]]; then
      echo "  $dir/ (directory not found, skipping)"
      continue
    fi
    echo "  dir-links/$dir/ -> ${TARGETS[$dir]}"
    while IFS= read -r -d '' subdir; do
      rel="${subdir#"$src_dir"/}"
      echo "    $rel/"
    done < <(find "$src_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
  done
done

if [[ "${DOTFILES_UNATTENDED:-0}" == "1" ]]; then
  recreate_links="true"
  skip_existing="false"
  echo ""
  echo "Running unattended (DOTFILES_UNATTENDED=1):"
  echo "  recreate_links=true  (existing symlinks will be re-created)"
  echo "  skip_existing=false  (existing real directories get backed up to .bak, then linked)"
else
  echo ""
  read -rp "Recreate already existing symbolic links? [y/n] " input
  if [[ "$input" == "y" ]]; then
    recreate_links="true"
    echo "Recreating existing symbolic links"
  else
    recreate_links="false"
    echo "Skipping existing symbolic links"
  fi

  echo ""
  read -rp "Skip creation of symbolic links for directories which already exist? [y/n] " input
  if [[ "$input" == "y" ]]; then
    skip_existing="true"
    echo "Skipping existing directories"
  else
    skip_existing="false"
    echo "Not skipping existing directories"
  fi

  echo ""
  read -rp "Continue? [y/n] " input
  if [[ "$input" != "y" ]]; then
    echo "Nothing happened. Exiting script"
    exit 0
  fi
fi

# --- Link ---
for repo_dir in "${REPO_DIRS[@]}"; do
  [[ -d "$repo_dir" ]] || continue
  links_dir="$repo_dir/dir-links"
  for dir in "${!TARGETS[@]}"; do
    src_dir="$links_dir/$dir"
    dest="${TARGETS[$dir]}"
    [[ -d "$src_dir" ]] || continue

    while IFS= read -r -d '' subdir; do
      rel="${subdir#"$src_dir"/}"
      link_dir "$subdir" "$dest/$rel"
    done < <(find "$src_dir" -mindepth 1 -maxdepth 1 -type d -print0)
  done
done

echo "Script finished"
