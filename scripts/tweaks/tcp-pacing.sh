#!/usr/bin/env bash
# TCP-Pacing tuning for masterfedora.
#
# Background: this host sits behind two small unmanaged 10G switches in
# series (QNAP QSW-2104-2T and TRENDnet TEG-S750). Both have small packet
# buffers (~hundreds of KB). Linux default TCP stack (CUBIC + fq_codel
# without pacing) bursts aggressively enough to overflow those buffers at
# sustained line rate, which manifested as ~14k iperf3 retransmits per 60s
# and downstream as failed CIFS writes / smbd reconnects. Windows on the
# same hardware sees ~1.1k retransmits in the same test because its TCP
# stack paces inherently.
#
# Two changes bring Linux into the Windows ballpark:
#   * net.core.default_qdisc = fq      -> per-flow pacing on new interfaces
#   * net.ipv4.tcp_congestion_control = bbr
#                                       -> BBR replaces CUBIC. Less burst-
#                                          y after loss events.
#
# Scope: only applies to host 'masterfedora'. The laptop talks to the
# server over different paths and does not exhibit the issue; tweaking
# its TCP stack would be a change without empirical justification.
#
# Idempotency:
#   * /etc/sysctl.d and /etc/modules-load.d files written via install,
#     so re-running just overwrites the same content
#   * modprobe and sysctl --system are no-ops if state already matches
#   * tc qdisc replace is idempotent by design

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../_guards.sh"

require_linux

# --- Host filter -------------------------------------------------------------
# Only run on the PC. The laptop and other hosts get the distro default.
[[ "$(hostname)" == "masterfedora" ]] || skip "host is not masterfedora"

SYSCTL_FILE=/etc/sysctl.d/90-tcp-pacing.conf
MODULES_FILE=/etc/modules-load.d/tcp-bbr.conf

# --- Load BBR now and at every boot -----------------------------------------
sudo modprobe tcp_bbr

TMP_MODULES=$(mktemp)
trap 'rm -f "$TMP_MODULES" "${TMP_SYSCTL:-}"' EXIT
printf 'tcp_bbr\n' > "$TMP_MODULES"
sudo install -m 0644 -o root -g root "$TMP_MODULES" "$MODULES_FILE"

# --- sysctl: pacing qdisc + BBR ---------------------------------------------
TMP_SYSCTL=$(mktemp)
cat > "$TMP_SYSCTL" <<'EOF'
# Managed by dotfiles tweak: tcp-pacing.sh
# See script header for rationale.
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
sudo install -m 0644 -o root -g root "$TMP_SYSCTL" "$SYSCTL_FILE"

# --- Apply now --------------------------------------------------------------
sudo sysctl --system >/dev/null

# default_qdisc only affects newly-created interfaces, so existing ones
# keep whatever qdisc they came up with. Replace explicitly on every
# physical interface. /sys/class/net/*/device exists for real hardware
# only (no loopback, no bridges, no veth).
for dev_path in /sys/class/net/*/device; do
    iface=$(basename "$(dirname "$dev_path")")
    sudo tc qdisc replace dev "$iface" root fq 2>/dev/null || true
done

echo "Done."
