#!/usr/bin/env bash
# Finish the macOS GPG pinentry setup after Homebrew and the file linker ran.
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../_guards.sh"

require_darwin
require_ui
require_command defaults
require_command brew
require_command gpgconf
require_command pinentry-mac
require_command pinentry-touchid

[[ -x "$HOME/.local/bin/pinentry-gpg" ]] || skip "pinentry-gpg not linked"

# pinentry-touchid delegates initial/password entry to Homebrew's default
# pinentry. Its -check/-fix flags hang with the lid closed, so inspect the
# Homebrew symlink directly and keep the GUI fallback in place.
PINENTRY_PREFIX="$(brew --prefix pinentry)"
PINENTRY_PATH="$PINENTRY_PREFIX/bin/pinentry"
PINENTRY_MAC="$(command -v pinentry-mac)"
if [[ "$(readlink -f "$PINENTRY_PATH")" != "$(readlink -f "$PINENTRY_MAC")" ]]; then
  ln -sfn "$PINENTRY_MAC" "$PINENTRY_PATH"
fi

# pinentry-mac must never fetch a stored passphrase silently. The Touch ID
# wrapper remains able to use its authenticated Keychain entry.
defaults write org.gpgtools.common DisableKeychain -bool yes

# Apply the config and flush passphrases cached under the previous policy.
gpgconf --kill gpg-agent

echo "GPG pinentry configured: Touch ID when open, password when closed."
