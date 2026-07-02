#!/usr/bin/env bash
# Run ydotoold as a user service (needed by Handy voice→text) and disable the broken upstream service.
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../_guards.sh"

require_ui
# udev + systemd user units; and on macOS Handy injects input itself.
require_linux
require_command ydotoold

# --- Disable the system service so it can't hold the socket ---
# May not be installed or already disabled; ignore either case.
sudo systemctl disable --now ydotoold.service 2>/dev/null || true

# --- Grant /dev/uinput access to the input group ---
sudo tee /etc/udev/rules.d/60-uinput.rules > /dev/null <<'EOF'
KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
EOF
sudo udevadm control --reload
sudo udevadm trigger

# --- Ensure $USER is in the input group ---
# Also set in scripts/one-off-fedora.sh; idempotent, safe to repeat.
sudo usermod -aG input "$USER"

# --- Install user systemd unit ---
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/ydotool.service" <<'EOF'
[Unit]
Description=Starts ydotoold service

[Service]
Type=simple
Restart=always
ExecStart=/usr/bin/ydotoold --socket-path=%t/.ydotool_socket
ExecReload=/usr/bin/kill -HUP $MAINPID
KillMode=process
TimeoutSec=180

[Install]
WantedBy=default.target
EOF

# --- Activate ---
systemctl --user daemon-reload
systemctl --user enable --now ydotool.service

echo "Done. If 'input' group membership was just added, log out and back in for /dev/uinput access to take effect."
