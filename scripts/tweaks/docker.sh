#!/usr/bin/env bash
# Docker Engine post-install (Linux only). The packages themselves come from
# packages/dnf.txt via Docker's own repo (see setup-fedora-repos.sh); this
# tweak covers the two steps the packages don't do:
#   * put $USER into the docker group (socket access without sudo)
#   * enable and start the daemon
#
# Guards: macOS gets Docker via Brew casks/formulae and has no systemd, so
# this is Linux-only; the command guard keeps it a no-op on Linux boxes
# that intentionally have no Docker (e.g. an apt server without it).
#
# Idempotency: usermod -aG is a no-op when already a member; systemctl
# enable --now is a no-op when already enabled and running.
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../_guards.sh"

require_linux
require_command docker

sudo usermod -aG docker "$USER"
sudo systemctl enable --now docker.service

echo "Done. If 'docker' group membership was just added, log out and back in for sudo-less docker."
