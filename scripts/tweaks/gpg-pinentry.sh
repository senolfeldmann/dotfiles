#!/usr/bin/env bash
# Finish the macOS GPG pinentry setup after Homebrew and the file linker ran.
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../_guards.sh"

require_darwin
require_ui
require_command defaults
require_command gpgconf
require_command pinentry-mac
require_command pinentry-touchid

[[ -x "$HOME/.local/bin/pinentry-gpg" ]] || skip "pinentry-gpg not linked"

# pinentry-touchid delegates initial/password entry to Homebrew's default
# pinentry. Keep that fallback on the GUI pinentry-mac implementation.
if ! pinentry-touchid -check >/dev/null 2>&1; then
  pinentry-touchid -fix
fi

# pinentry-mac must never fetch a stored passphrase silently. The Touch ID
# wrapper remains able to use its authenticated Keychain entry.
defaults write org.gpgtools.common DisableKeychain -bool yes

# Apply the config and flush passphrases cached under the previous policy.
gpgconf --kill gpg-agent

echo "GPG pinentry configured: Touch ID when open, password when closed."
