#!/usr/bin/env bash
# Sets up Fedora-specific dnf repos (Chrome, VS Code, RPM Fusion) so that
# subsequent install-dnf.sh runs can pull packages from them. All operations are
# intrinsically idempotent: dnf config-manager and rpm --import succeed
# silently if already done, the .repo file is overwritten with identical
# content, and the RPM Fusion release packages are guarded with rpm -q.
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/_guards.sh"

require_command dnf

# Enable google chrome repo
echo "Enabling google chrome repo"
sudo dnf config-manager setopt google-chrome.enabled=1

# Setup vs code repo
echo "Setting up VS Code repo"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

# Enable RPM Fusion (free + nonfree): codecs, drivers and extra packages.
# The release RPMs register as rpmfusion-free-release / rpmfusion-nonfree-release.
# dnf re-downloads URL operands on every run even when already installed, so we
# guard with rpm -q (same reasoning as install-dnf.sh's URL pass) to keep
# repeated applies cheap. rpm -E %fedora keeps the URL portable across releases.
if rpm -q rpmfusion-free-release rpmfusion-nonfree-release >/dev/null 2>&1; then
  echo "RPM Fusion already enabled"
else
  echo "Enabling RPM Fusion (free + nonfree)"
  fedora_ver="$(rpm -E %fedora)"
  sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm"
fi

# Enable Cisco's OpenH264 repo (provides the openh264 codec for Firefox etc.).
# config-manager setopt is intrinsically idempotent.
echo "Enabling fedora-cisco-openh264 repo"
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1

# Docker CE repo (docker-ce and friends in packages/dnf.txt come from here).
# `addrepo` refuses to overwrite an existing repo file, so guard on presence.
if [[ -f /etc/yum.repos.d/docker-ce.repo ]]; then
  echo "Docker CE repo already present"
else
  echo "Setting up Docker CE repo"
  sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
fi

# Docker stopped publishing source repos for Fedora >= 43 (fedora/44/source/
# stable 404s), and `dnf builddep` (install-dnf-extras.sh) force-enables
# *-source repos regardless of enabled=0, then hard-fails on the 404.
# skip_if_unavailable lets dnf tolerate the missing repos. setopt writes to
# /etc/dnf/repos.override.d/ (survives docker-ce.repo updates) and is
# intrinsically idempotent.
sudo dnf config-manager setopt \
  docker-ce-stable-source.skip_if_unavailable=1 \
  docker-ce-test-source.skip_if_unavailable=1

# Ookla repo for the official Speedtest CLI (`speedtest` in packages/dnf.txt).
# On macOS the same tool comes from the teamookla/speedtest brew tap instead.
#
# We write the repo file ourselves instead of running Ookla's documented
# packagecloud script (script.rpm.sh), whose generated config is broken on
# Fedora in three independent ways: the fedora/$releasever baseurls contain
# zero packages (Ookla only publishes under el/*), it pins the legacy
# sslcacert path /etc/pki/tls/certs/ca-bundle.crt that Fedora 44 removed
# (curl error 77 on every fetch), and it sets repo_gpgcheck=1 while the
# gpgkey URL no longer serves the key that actually signs the metadata
# (repomd signed by 8E61C2AB9A6D1557, URL serves E723ACAA -> permanent
# "Signing key not found"). Hence: el/9 baseurl (the RHEL 9 build runs fine
# on current Fedora), no repo_gpgcheck. Packages are unsigned upstream
# anyway (gpgcheck=0 in Ookla's own config), so TLS to packagecloud.io is
# the trust anchor, exactly as with the upstream script.
#
# priority=90 (default 99, lowest value wins regardless of version): Fedora
# ships an unrelated GTK librespeed app also named `speedtest` with a higher
# version number, which would otherwise shadow Ookla's CLI.
#
# Unconditional tee (no presence guard): overwrites broken configs written
# by the packagecloud script on machines set up before this fix; content is
# static, so repeated applies are byte-identical.
echo "Setting up Ookla speedtest repo"
echo -e "[ookla_speedtest-cli]\nname=Ookla Speedtest CLI (el/9 build)\nbaseurl=https://packagecloud.io/ookla/speedtest-cli/el/9/\$basearch\nenabled=1\ngpgcheck=0\nrepo_gpgcheck=0\npriority=90" | sudo tee /etc/yum.repos.d/ookla_speedtest-cli.repo > /dev/null

