#!/bin/bash
# Mount CIFS/SMB shares from a personal NAS via fstab.
#
# Host, shares, and a profile name are personal/machine-specific and live
# OUTSIDE this public repo, in:
#     ~/.config/dotfiles/cifs.conf   (synced via a private dotfiles repo)
# That file sets:
#     CIFS_NAME="<profile>"        # used for mountpoints, creds file, fstab markers
#     CIFS_HOST="<host>"           # SMB host, e.g. nas.fritz.box
#     CIFS_SHARES=(share1 share2)  # share names to mount
# If the config is absent (a public clone, or a machine without the NAS),
# this script skips cleanly.
#
# Layout (derived from the config):
#   //$CIFS_HOST/<share>  ->  /mnt/$CIFS_NAME/<share>
#
# Credentials live in /etc/cifs-credentials/$CIFS_NAME, root:root 0600.
# The file is never overwritten by this script: it is created with a
# placeholder once, then left alone. After first apply, edit it manually
# (sudoedit /etc/cifs-credentials/$CIFS_NAME) to insert real values.
#
# Mounts come up at boot (auto + _netdev). nofail keeps a missing or
# unreachable server from blocking boot; mount-timeout caps the wait at 10s.
# No idle-timeout: once mounted the share stays mounted until shutdown
#
# Why CIFS-utils instead of pam_mount or a systemd-user trigger:
#   * pam_mount: cleanest in theory but tangles with Fedora's authselect
#     stack; PAM edits get rewritten by authselect on profile changes.
#   * systemd-user + KWallet: race-prone (KWallet not unlocked yet at
#     mount time) and still needs a sudoers whitelist for mount.cifs.
#   * fstab + creds file: explicit, well-understood, no race conditions.
#     Trade-off is a plaintext-with-root-only-perms file.
#
# Idempotency:
#   * mkdir -p for mount points and credentials directory
#   * credentials file: created with placeholder if missing, perms always
#     enforced
#   * fstab block delimited by sentinel comments; rewritten wholesale on
#     every run via awk-strip + append. Self-healing if the END marker is
#     ever lost.

set -e

# --- Personal config (name/host/shares), kept out of this public repo ---
CIFS_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/cifs.conf"
if [[ ! -f "$CIFS_CONF" ]]; then
    echo "[cifs-mounts] no $CIFS_CONF, skipping (no NAS configured on this machine)."
    exit 0
fi
# shellcheck source=/dev/null
source "$CIFS_CONF"   # sets CIFS_NAME, CIFS_HOST, CIFS_SHARES

if [[ -z "${CIFS_NAME:-}" || -z "${CIFS_HOST:-}" || ${#CIFS_SHARES[@]} -eq 0 ]]; then
    echo "[cifs-mounts] $CIFS_CONF is incomplete (need CIFS_NAME, CIFS_HOST, CIFS_SHARES). Skipping." >&2
    exit 1
fi

CREDS_DIR=/etc/cifs-credentials
CREDS_FILE="$CREDS_DIR/$CIFS_NAME"
MOUNT_BASE="/mnt/$CIFS_NAME"
FSTAB=/etc/fstab
BEGIN_MARK="# --- BEGIN dotfiles-managed: $CIFS_NAME cifs mounts ---"
END_MARK="# --- END dotfiles-managed: $CIFS_NAME cifs mounts ---"

# --- Mount points ---
for share in "${CIFS_SHARES[@]}"; do
    sudo mkdir -p "$MOUNT_BASE/$share"
done

# --- Credentials directory ---
sudo install -d -o root -g root -m 0700 "$CREDS_DIR"

# --- Credentials file (placeholder, never overwrites existing) ---
if ! sudo test -e "$CREDS_FILE"; then
    sudo tee "$CREDS_FILE" > /dev/null <<'EOF'
# CIFS credentials. Replace the placeholder values.
# This file MUST stay out of any backup that lacks its own encryption,
# and MUST NOT be added to the dotfiles repo.
username=REPLACE_ME
password=REPLACE_ME
domain=REPLACE_ME
EOF
fi
sudo chown root:root "$CREDS_FILE"
sudo chmod 600 "$CREDS_FILE"

# --- fstab block ---
# Build the desired block, then strip any previous occurrence of the same
# block from /etc/fstab and append the new one. The sentinel markers make
# this a robust idempotent overwrite without line-by-line guessing.
COMMON_OPTS="credentials=$CREDS_FILE,uid=0,iocharset=utf8,vers=3.0,noperm"
NEW_BLOCK="$BEGIN_MARK"
for share in "${CIFS_SHARES[@]}"; do
    NEW_BLOCK+=$'\n'"//$CIFS_HOST/$share  $MOUNT_BASE/$share  cifs  $COMMON_OPTS  0 0"
done
NEW_BLOCK+=$'\n'"$END_MARK"

# Strip any existing managed block (markers + body), keep everything else.
STRIPPED=$(awk -v begin="$BEGIN_MARK" -v end="$END_MARK" '
    $0 == begin { skip = 1; next }
    $0 == end   { skip = 0; next }
    !skip       { print }
' "$FSTAB")

# Compose new fstab and install it atomically (mv on same fs is atomic;
# install handles owner/perms in one shot).
TMP_FSTAB=$(mktemp)
trap 'rm -f "$TMP_FSTAB"' EXIT
{
    printf '%s\n' "$STRIPPED"
    printf '%s\n' "$NEW_BLOCK"
} > "$TMP_FSTAB"
sudo install -m 0644 -o root -g root "$TMP_FSTAB" "$FSTAB"

# --- Pick up the new fstab entries ---
sudo systemctl daemon-reload

# --- Bring the mounts up now (skip if creds are still placeholder) ---
mount_units=()
for share in "${CIFS_SHARES[@]}"; do
    mount_units+=("$(systemd-escape -p --suffix=mount "$MOUNT_BASE/$share")")
done

if sudo grep -q '^password=REPLACE_ME' "$CREDS_FILE"; then
    echo
    echo "Note: $CREDS_FILE still has placeholder credentials."
    echo "      Edit it (sudoedit $CREDS_FILE), then run:"
    echo "        sudo systemctl start ${mount_units[*]}"
else
    sudo systemctl start "${mount_units[@]}"
fi

echo "Done."
