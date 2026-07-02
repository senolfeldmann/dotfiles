#!/usr/bin/env bash
# Flatpak overrides and per-app tweaks. Assumes `install-flatpak.sh` has run.
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../_guards.sh"

require_ui
require_command flatpak

sudo flatpak override --env=GDK_SCALE=2 org.jdownloader.JDownloader
flatpak override --user --filesystem=home com.rtosta.zapzap