# Session environment: PATH and other env vars, meant to run ONCE per
# session and be inherited by every child process.
#
# zsh reads this file natively only for LOGIN shells. macOS terminals open
# every tab as a login shell, so it fires there by itself; Linux terminals
# usually spawn NON-login interactive shells, which never read .zprofile -
# for those, .zshrc sources this file explicitly (guarded by the flag
# below). Interactive-only setup (prompt, plugins, completions, aliases)
# does NOT belong here; that lives in .zshrc.

# Session marker for .zshrc's source guard. Exported, so subshells inherit
# it and never re-source this file: once per session, as profile semantics
# intend.
export __DOTFILES_PROFILE_LOADED=1

export PATH="$HOME/.local/bin:$PATH"

# Homebrew lives outside the default PATH on both OSes; bootstrap it from
# its fixed install location. The -x guard keeps a fresh machine (before
# setup-homebrew.sh has run) from erroring on every new shell.
if [[ "$OSTYPE" == "darwin"* && -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
elif [[ "$OSTYPE" == "linux"* && -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# Rancher Desktop CLIs (docker, buildx, compose, kubectl, nerdctl, helm).
# Path Management in the app is set to "Manual" (see packages/Brewfile) so
# it never edits symlinked shell files; the PATH entry lives here instead,
# as the Rancher docs prescribe for manual mode.
if [[ -d "$HOME/.rd/bin" ]]; then
  export PATH="$HOME/.rd/bin:$PATH"
fi
