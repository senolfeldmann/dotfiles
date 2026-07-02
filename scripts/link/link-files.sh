#!/usr/bin/env bash
# Symlink individual files from file-links/<target>/<rel> to
# $(target_dir <target>)/<rel>. For files that share a destination directory
# with other unmanaged files (e.g. ~/.zshrc next to OS-managed dotfiles).
# For whole-directory takeovers, see link-dirs.sh.
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

# Behaviour:
# - If a symlink already exists at the destination:
#     recreate_links=true  -> remove and re-create the symlink
#     recreate_links=false -> skip
# - If a regular file already exists:
#     skip_existing=true   -> skip
#     skip_existing=false  -> back up to .bak, then link
# - Otherwise: create the symlink

link_file() {
  local src="$1"
  local dest="$2"

  # -h detects symlinks (including dangling); -f follows and misses dangling
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
      echo "File exists: $dest (skipping)"
      return
    else
      echo "File exists: $dest (backing up to ${dest}.bak)"
      mv "$dest" "${dest}.bak"
    fi
  fi

  mkdir -p "$(dirname "$dest")"
  echo "Linking: $src -> $dest"
  ln -s "$src" "$dest"
}

# --- Preview ---
echo "The following file mappings will be applied:"
for repo_dir in "${REPO_DIRS[@]}"; do
  [[ -d "$repo_dir" ]] || continue
  echo "[$repo_dir]"
  set_link_source_trees "$repo_dir" file-links
  for links_dir in ${LINK_SOURCE_TREES[@]+"${LINK_SOURCE_TREES[@]}"}; do
    tree_name="${links_dir#"$repo_dir"/}"
    for dir in "${TARGET_NAMES[@]}"; do
      src_dir="$links_dir/$dir"
      if [[ ! -d "$src_dir" ]]; then
        echo "  $tree_name/$dir/ (directory not found, skipping)"
        continue
      fi
      echo "  $tree_name/$dir/ -> $(target_dir "$dir")"
      while IFS= read -r -d '' file; do
        rel="${file#"$src_dir"/}"
        echo "    $rel"
      done < <(find "$src_dir" -type f -print0 | sort -z)
    done
  done
done

if [[ "${DOTFILES_UNATTENDED:-0}" == "1" ]]; then
  recreate_links="true"
  skip_existing="false"
  echo ""
  echo "Running unattended (DOTFILES_UNATTENDED=1):"
  echo "  recreate_links=true  (existing symlinks will be re-created)"
  echo "  skip_existing=false  (existing real files get backed up to .bak, then linked)"
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
  read -rp "Skip creation of symbolic links for files which already exist? [y/n] " input
  if [[ "$input" == "y" ]]; then
    skip_existing="true"
    echo "Skipping existing files"
  else
    skip_existing="false"
    echo "Not skipping existing files"
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
  set_link_source_trees "$repo_dir" file-links
  for links_dir in ${LINK_SOURCE_TREES[@]+"${LINK_SOURCE_TREES[@]}"}; do
    for dir in "${TARGET_NAMES[@]}"; do
      src_dir="$links_dir/$dir"
      dest="$(target_dir "$dir")"
      [[ -d "$src_dir" ]] || continue

      while IFS= read -r -d '' file; do
        rel="${file#"$src_dir"/}"
        link_file "$file" "$dest/$rel"
      done < <(find "$src_dir" -type f -print0)
    done
  done
done

echo "Script finished"
