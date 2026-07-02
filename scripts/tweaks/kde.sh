#!/usr/bin/env bash
# KDE Plasma 6 settings (tested on Fedora Workstation 43, Plasma 6.6).
# Only portable, machine-independent settings live here. Stateful things
# like panel layout, monitor geometry and wallpaper paths are handled
# outside this script (see README).

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../_guards.sh"

require_ui
# Also covers macOS, headless Fedora and non-KDE desktops.
require_command kwriteconfig6

# --- Power management (AC profile) ---
kwriteconfig6 --file powerdevilrc --group "AC" --group "Display" --key "DimDisplayIdleTimeoutSec" -- -1
kwriteconfig6 --file powerdevilrc --group "AC" --group "Display" --key "DimDisplayWhenIdle" --type bool false
kwriteconfig6 --file powerdevilrc --group "AC" --group "Display" --key "TurnOffDisplayIdleTimeoutSec" 900
kwriteconfig6 --file powerdevilrc --group "AC" --group "Display" --key "TurnOffDisplayIdleTimeoutWhenLockedSec" 300
kwriteconfig6 --file powerdevilrc --group "AC" --group "SuspendAndShutdown" --key "AutoSuspendAction" 0
kwriteconfig6 --file powerdevilrc --group "AC" --group "SuspendAndShutdown" --key "PowerButtonAction" 0

# --- Keyboard layout (EurKEY) ---
kwriteconfig6 --file kxkbrc --group "Layout" --key "LayoutList" "eu"
kwriteconfig6 --file kxkbrc --group "Layout" --key "Use" --type bool true

# --- Default browser ---
kwriteconfig6 --file kdeglobals --group "General" --key "BrowserApplication" "google-chrome.desktop"

# --- Dolphin: hide menu bar ---
kwriteconfig6 --file dolphinrc --group "MainWindow" --key "MenuBar" "Enabled"

# --- KWrite chrome ---
kwriteconfig6 --file kwriterc --group "General" --key "Show Menu Bar" --type bool false
kwriteconfig6 --file kwriterc --group "General" --key "Show Url Nav Bar" --type bool false

# --- KDED modules we don't want auto-loaded ---
kwriteconfig6 --file kded5rc --group "Module-browserintegrationreminder" --key "autoload" --type bool false
kwriteconfig6 --file kded5rc --group "Module-device_automounter" --key "autoload" --type bool false

# --- Trash confirmation ---
kwriteconfig6 --file kiorc --group "Confirmations" --key "ConfirmEmptyTrash" --type bool true

# --- Disable edge barrier (sticky cursor between monitors) ---
kwriteconfig6 --file kwinrc --group "EdgeBarrier" --key "EdgeBarrier" 0

# --- Global shortcut: Meta+C toggles Handy transcription ---
# Plasma "Custom Commands" are .desktop files with a special flag;
# kglobalshortcutsrc then binds the hotkey to the desktop id.
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/net.local.handy.desktop" <<'EOF'
[Desktop Entry]
Exec=handy --toggle-transcription
Name=Toggle Handy Transcription
NoDisplay=true
StartupNotify=false
Type=Application
X-KDE-GlobalAccel-CommandShortcut=true
EOF
kwriteconfig6 --file kglobalshortcutsrc --group "services" --group "net.local.handy.desktop" --key "_launch" "Meta+C"

echo "Done. Log out and back in (or run: systemctl --user restart plasma-powerdevil.service) for power changes to take effect."
