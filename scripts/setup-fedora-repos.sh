#!/bin/bash
# Sets up Fedora-specific dnf repos (Chrome, VS Code, RPM Fusion) so that
# subsequent install-dnf.sh runs can pull packages from them. All operations are
# intrinsically idempotent: dnf config-manager and rpm --import succeed
# silently if already done, the .repo file is overwritten with identical
# content, and the RPM Fusion release packages are guarded with rpm -q.
set -e

if ! command -v dnf >/dev/null 2>&1; then
  echo "[setup-fedora-repos] dnf not available, skipping."
  exit 0
fi

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

