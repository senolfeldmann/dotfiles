#!/bin/bash
# Flatpak overrides and per-app tweaks. Assumes `install-flatpak.sh` has run.
set -e

sudo flatpak override --env=GDK_SCALE=2 org.jdownloader.JDownloader
flatpak override --user --filesystem=home com.rtosta.zapzap