# Şenol's dotfiles
This repo holds my dotfiles and packages. **macOS is the primary target**; **Fedora KDE Plasma Desktop (43+)** is the secondary system for Linux-only work (dual boot and VMs); **Ubuntu/Debian** is supported as a terminal-only target for servers and the occasional WSL2 instance. Except for the package-manager-specific parts, everything *should* work on any distribution of your choice.

This repo serves multiple purposes:
- Keeping my dotfiles in sync across devices
- Being able to quickly setup my env
- Self-documenting
- Hopefully inspiring others and exchanging ideas

## Philosophy
Generally, I prefer minimal and simple approaches with the goals of minimal brittleness, longterm maintainability and portability. Genuinely great tools like `chezmoi` exist, but for my personal taste and **current** requirements, they do too much, are too opinionated and have too much overhead. I am re-evaluating from time to time, so my opinion is subject to change.

## Idempotency

Every script in this repo is **idempotent**: running it ten times must leave the system in the same state as running it once. This is the invariant that makes the repo useful across multiple machines: pull the repo, run `apply.sh`, and the machine reflects the current repo state, regardless of how many times you've run it before.

Three legitimate paths to idempotency:

1. **Intrinsic** - package managers (`dnf install -y`, `apt-get install -y`, `brew bundle`) skip already-installed packages by design.
2. **Check-before-do guard** - explicit early-return when the work is already done. Examples: `[[ -d "$HOME/.oh-my-zsh" ]] && exit 0`, `command -v brew && exit 0`. See [`scripts/setup-zsh.sh`](./scripts/setup-zsh.sh) for the pattern applied with two independent guards in one script.
3. **Idempotent overwrite** - the operation overwrites with the same result every time (e.g. `kwriteconfig6` writing the same config value, `flatpak override` setting the same override, `unzip -o` re-extracting an archive into a known directory).

### Sub-rule: no duplicate downloads

Every `curl` / `wget` is gated by an existence check on the result. The real argument is consistency: if the work is done, don't redo it. Reduced bandwidth and offline-reapply ability are nice bonuses.

Examples in this repo:
- `install-nerd-fonts.sh` checks the font directory before downloading each font
- `setup-zsh.sh` checks `~/.oh-my-zsh` and the gruvbox theme path
- `install-claude-code.sh` checks `command -v claude` before running the upstream installer
- `setup-homebrew.sh` checks `command -v brew` before running the Homebrew installer

### Self-contained scripts

Each script also checks its own platform/tool preconditions and exits cleanly with a skip message when not applicable - e.g. `install-dnf.sh` skips on macOS, `install-brew.sh` skips when Homebrew isn't installed yet. `apply.sh` is just a sequencer; it contains no conditionals of its own. As a result every script is also runnable standalone for granular work: `./scripts/install-dnf.sh` syncs dnf packages, `./scripts/tweaks/kde.sh` re-applies KDE settings, etc.

The applicability checks themselves are shared: [`scripts/_guards.sh`](./scripts/_guards.sh) provides `require_command`, `require_linux`, `require_ui` and the underlying `skip`, each printing a uniform `[script-name] <reason>, skipping.` line and exiting 0 (skipping is success; apply.sh runs everything everywhere). Idempotency guards of the opposite kind ("already installed, nothing to do", e.g. in `setup-homebrew.sh`) stay inline, since they answer a different question than applicability.

### Adding new scripts

1. Make it idempotent via one of the three mechanisms above.
2. Guard its applicability with the shared helpers from `scripts/_guards.sh`, not hand-rolled checks.
3. Any download must be gated by an existence check on its result.
4. Add it to `apply.sh` in the right dependency order: things that produce a tool come before things that consume it.

## My pragmatic cross-platform (dev) environment model
My mental model for my environment can be structured into layers:
### Layer 1: OS baseline
The native package manager is only used for the most basic libs and applications such as:
- `git`
- `curl`
- `build-essential` / Xcode
- `ca-certificates`
- `pkg-config`
- `openssl` headers

This layer is ideally rarely touched. As you can see in `packages/dnf.txt`, several exceptions exist.

### Layer 2: Homebrew everywhere (primary tool source)
Brew is used as the canonical source for:
- CLI tools
- TUI tools
- dev utilities
- infra tools
- editors
- (if needed) newest versions of packages you would normally handle in Layer 1
- etc.

This way, we have:
- same tools on macOS and Linux
- same versions
- same paths (via `brew --prefix`)
- central Brewfiles
- instead of a bunch of cloned git repos for various tools, we have one `brew upgrade`

Brew is a proven tool in the macOS world, and the Linux community is embracing it more and more, too. It gets the job done and reduces cognitive load massively, bringing the actual work at hand into focus.

### Layer 2.5: Flatpak (sandboxed GUI apps, Fedora only)
Flatpak is used for self-contained GUI applications that don't need to integrate with the dev environment or communicate with other apps. Think media players, chat apps, image editors etc.
Apps that need IPC, filesystem access, access to dev toolchains or shell integration should **not** be installed via Flatpak but in lower layers instead.

Flathub defaults are often sane, so the cost of sandboxing isn't really `flatpak override` maintenance. A one-time override committed to dotfiles is fine. The real cost is cognitive: apps central to daily workflow end up in a different mental model than everything else, and debugging gets harder the moment something doesn't "just work."

Counter-intuitively, sandboxing is *more* valuable for casual, less-trusted apps than for identity-critical ones. A mail client technically benefits from isolation, but once you hand it your GPG keys, Kerberos tickets, and default mail-handler registration, the sandbox's net value shrinks.

Rule of thumb: if the app just does its own thing, Flatpak is fine. If it's woven into daily workflow or identity, use `dnf` or Brew.

**In practice:**
- **Thunderbird → `dnf`**: GPG, Kerberos, default mail handler, used constantly. Flathub defaults cover the permissions, but the app is too central for a separate sandbox model to earn its keep.
- **VS Code, KeePassXC → `dnf`**: shell integration, host toolchains, browser IPC. Layer 1 is the path of least resistance.
- **Spotify, Joplin, Plex, Bambu Studio → Flatpak**: leaf apps, no coupling to the rest of the system. Sandbox is pure upside.
- **DBeaver, Postman, RedisInsight → Flatpak**: GUI network clients; they talk to databases and APIs over the wire, not to host toolchains.

### Layer 3: mise (runtimes)
I chose `mise` to manage my runtimes. Instead of installed `nodenv`, `pyenv`, `rbenv`, `goenv`, `tfenv` etc., mise handles it all.

> I used to use `asdf`. [This writeup](https://mise.jdx.dev/dev-tools/comparison-to-asdf.html) outlines most of the issues I see with `asdf`.

So Brew manages tools, and `mise` manages runtimes (where possible, exceptions exist). This is a clear boundary which reduces friction.

### Layer 4: dotfiles repo
The repo itself. It unifies all the layers before and through included conditionals we get:

- OS detection
- Brew prefix detection
- A unified PATH to work with

The repo is organized by purpose:

```
file-links/          → individual files to be symlinked (subdirs map to destinations)
file-links.linux/    → same, but linked only on Linux
file-links.darwin/   → same, but linked only on macOS
dir-links/           → whole directories to be symlinked (same target map, different unit)
dir-links.linux/     → same, but linked only on Linux
dir-links.darwin/    → same, but linked only on macOS
packages/            → package lists (Brewfile + Brewfile_extras, dnf.txt + dnf-ui.txt,
                       apt.txt + apt-ui.txt, dnf-extras.txt, flatpak.txt)
scripts/             → setup and install scripts
apps/                → app-specific configs for manual import
```

Two orthogonal splits inside `packages/`:

- **`Brewfile` vs `Brewfile_extras`**: productivity baseline vs personal extras (entertainment, media tooling). Nothing secret about the second file; it is what I would *not* install on a pure work machine. `install-brew.sh` bundles both.
- **`dnf.txt`/`apt.txt` vs `dnf-ui.txt`/`apt-ui.txt`**: terminal baseline vs desktop-only packages. The `-ui` lists (plus Flatpaks, Nerd Fonts and desktop tweaks) are skipped when `apply.sh` runs with `--no-ui`, so servers and minimal VMs stay lean.

The two link trees mirror each other in shape but differ in what they symlink. `file-links/` is for single files in shared destinations (e.g. `.zshrc` in `$HOME` next to other dotfiles you do not own); `dir-links/` is for whole directories you take over completely (e.g. a `~/.config/<tool>/` directory where any file the tool drops should land in a tracked repo). Both are driven by the same shared target map (`scripts/link/_targets.sh`) and the same precheck that detects conflicts between them. The linkers also read `EXTRA_REPO_DIRS` in `scripts/link/_targets.sh`, so the same trees can be sourced from additional repos alongside this one. I use that for a private sibling repo (`~/dotfiles-private`, same `file-links`/`dir-links` layout) holding what does not belong in public: personal Claude Code config, machine-specific values like NAS share definitions. The split rule: this repo documents *interfaces* (variable names, layouts, guards), the private one holds *values*. A machine without the private repo simply links what it has - the linkers skip missing repos. See `scripts/link/`.

Each tree additionally has OS-scoped siblings (`file-links.linux/`, `file-links.darwin/`, same for `dir-links`): content there is linked only when `uname` matches, so an OS-specific config (kitty on Linux, for example) never shows up as a meaningless symlink on the other OS. The linkers walk the common tree plus the matching OS tree per repo; the conflict precheck covers all trees active on the current OS, while the same destination in `.linux` and `.darwin` is deliberately legal (per-OS variants of one config).

### Layer 5: One command updates everything

A single command upgrades every package manager, framework, and runtime registered in this setup:

```sh
update-all
```

The function lives in [`file-links/home/.zaliases`](file-links/home/.zaliases), sourced by `.zshrc`. It auto-detects the OS and only runs the relevant steps; per-tool `command -v X` guards skip anything that isn't installed, so a minimal box without Homebrew or mas won't fail on those branches.

Each step is wrapped in a clearly delimited section header (bold cyan banner) and concludes with a green `[OK]` or red `[FAIL]` line, so it stays scannable even when individual package managers spew a lot of output. A failure does not abort the run; remaining steps continue, and an end-of-run summary report lists the succeeded and failed sections separately with exit codes.

| Tool                        | macOS | Fedora | Debian/Ubuntu |
|-----------------------------|:-----:|:------:|:--------------:|
| Homebrew (formulae)         | ✓     | ✓      | ✓              |
| Homebrew Casks (`--greedy`) | ✓     | n/a    | n/a            |
| Mac App Store (`mas`)       | ✓     | n/a    | n/a            |
| dnf                         | n/a   | ✓      | n/a            |
| apt                         | n/a   | n/a    | ✓              |
| Flatpak                     | n/a   | ✓      | ✓              |
| mise (self + runtimes)      | ✓     | ✓      | ✓              |
| Oh My Zsh                   | ✓     | ✓      | ✓              |
| tmux Plugin Manager (TPM)   | ✓     | ✓      | ✓              |

The `--greedy` flag is deliberate policy, not an oversight: casks marked `auto_updates` are upgraded by brew too. In-app auto-updaters are switched off wherever the app has a setting for it (same for App Store auto-updates), so `update-all` is the single update path for everything brew and mas manage. Apps whose self-updater cannot be disabled keep updating themselves; `--greedy` simply reconciles brew's metadata with reality on the next run.

Deliberately **not** covered: macOS system updates (`softwareupdate`). They need sudo, can force a reboot mid-run, and are better left to System Settings' auto-update - the Fedora equivalence (where `dnf upgrade` covers the OS) ends there. Also out of scope: apps installed outside any manager (e.g. CrossOver bottles) and self-updating application installed via native installers (e.g. Claude Code); they keep themselves current.

This is distinct from `apply.sh`: `update-all` upgrades versions of installed software, while `apply.sh` syncs the machine to the repo's package lists, symlinks, and tweaks. Both are safe to run any time; typical sequence after a `git pull` is `./scripts/apply.sh && update-all` (or run them separately depending on intent).

`update-all` is the largest of a small set of shell helpers that live in [`file-links/home/.zaliases`](file-links/home/.zaliases) (currently also `agent`, which opens a Claude Code session in one of the personas under `~/agents/<name>/`). Each helper is inline-commented with what it does, why it exists, and any non-obvious design choices; if the set grows materially they'll be split out into their own file.

## Setting up a new machine

There are two stages: **manual prerequisites** done by hand, then **`apply.sh`** which does everything else and is re-runnable any time afterwards.

### Manual prerequisites

These can't be automated meaningfully. They require physical authentication or interactive credential setup - or, in the CLT case, precede the repo itself.

#### Xcode Command Line Tools (macOS only)

```sh
xcode-select --install
```

Provides git and the compiler toolchain. By construction this cannot live in apply.sh: without the CLT there is no git, without git no clone of this repo, without the clone no apply.sh - so whenever apply.sh runs, the CLT are necessarily already installed and the step would be dead code. The install is also GUI-interactive (confirmation dialog), which disqualifies it from an unattended run anyway.

#### SSH keys for git
I keep forgetting the commands, they are stated here:
https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent

#### GPG for git

Import your private GPG key like this:

```sh
gpg --import <keyfile.asc>
gpg --list-secret-keys
gpg --edit-key <KeyID>
trust
```

Configure git to use your newly imported key as your signing key:

https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key

#### Clone the repo

```sh
git clone git@github.com:senolfeldmann/dotfiles.git
```

### Run apply

```sh
cd dotfiles
./scripts/apply.sh
```

On a machine without a desktop (server, minimal VM, WSL), run it in terminal-only mode instead:

```sh
./scripts/apply.sh --no-ui
```

The flag sets the environment variable `DOTFILES_NO_UI=1`, which every script apply.sh calls inherits; the affected scripts check it and skip themselves. Skipped in this mode: the desktop package lists (`dnf-ui.txt`, `apt-ui.txt`), Flatpaks, Nerd Fonts, desktop-only tweaks etc. Because the guards live inside the scripts, a standalone run works the same way: `DOTFILES_NO_UI=1 ./scripts/install-dnf.sh`.

This is the same command that does routine sync. On a fresh machine it does the heavy lifting: the Homebrew installer, oh-my-zsh installer, all packages, fonts, tweaks. On every subsequent run, idempotent guards skip everything that's already in place; typical re-runs are fast and silent except where there's actual new work.

If a future change ever introduces a second password prompt unexpectedly, run `./scripts/apply.sh --debug` to annotate each section header with the current sudo cache state (`[cache: VALID]` / `[cache: EXPIRED]`). The first section that flips to `EXPIRED` identifies which sub-script invalidated the cache.

### Switch default shell to zsh (after first apply)

After `apply.sh` has installed zsh via your OS package manager:

```sh
chsh -s $(which zsh)
```

This requires your user password and modifies system-level user metadata, so it lives outside the apply chain.

### What apply.sh does, in order

1. **Sudo**: cache the user's sudo credentials with a single `sudo -v` so the rest of the run is silent on the password front
2. **Symlinks**: `link/link-dirs.sh` then `link/link-files.sh`, both in unattended mode. Directory-level symlinks first (structural takeovers), then file-level symlinks. Both run a shared precheck that aborts if `file-links/` and `dir-links/` would target overlapping paths. Existing real files or directories at the destination get backed up to `.bak`, then symlinked.
3. **Fedora repos**: `setup-fedora-repos.sh` (skips on non-Fedora)
4. **OS packages**: `install-dnf.sh`, `install-dnf-extras.sh`, `install-apt.sh` (each skips if its package manager isn't present; the `-ui` package lists are skipped under `--no-ui`)
5. **Homebrew tool**: `setup-homebrew.sh` (installs Brew itself if missing)
6. **Homebrew packages**: `install-brew.sh` (`brew bundle` from `packages/Brewfile`, then `packages/Brewfile_extras`)
7. **Flatpaks**: `install-flatpak.sh` (skipped under `--no-ui`)
8. **Nerd fonts**: `install-nerd-fonts.sh` (skipped under `--no-ui`; on macOS the fonts come from Brew casks instead)
9. **Claude Code**: `install-claude-code.sh` (official installer on every OS; deliberately no Brew cask, one update channel)
10. **Ollama**: `install-ollama.sh` (Linux only, official installer: systemd service + GPU support; on macOS Ollama is the `ollama-app` cask)
11. **Oh My Zsh**: `setup-zsh.sh` (depends on zsh from step 4)
12. **mise runtimes**: `setup-mise.sh` (depends on mise from step 6; includes Rust via mise's rustup delegation)
13. **Tweaks**: `tweaks/_run.sh` (KDE settings, flatpak overrides, docker group + daemon, etc.; the desktop-only tweaks skip themselves under `--no-ui`)

The order follows tool dependencies: things that produce a tool come before things that consume it. `install-brew.sh` is a special case worth flagging: brew internally calls `sudo -k` as a safety measure (it refuses to run as root and clears any lingering authorization to enforce that). On a shared TTY that would kill the parent shell's sudo cache and force a second password prompt at Tweaks. To keep the single-prompt invariant, `install-brew.sh` wraps `brew bundle` in `script(1)`, giving brew its own pseudo-TTY; with sudo's default `tty_tickets=on`, the cache is keyed by TTY, so brew's `sudo -k` only clears the (empty) PTY timestamp and the parent cache stays alive.

`script(1)` ships in Fedora's `util-linux-script` package (listed in `packages/dnf.txt`); on macOS it is part of the BSD base.

Each script is also runnable standalone: `./scripts/install-dnf.sh` syncs dnf packages, `./scripts/tweaks/kde.sh` re-applies KDE settings. Drop a new `*.sh` into `scripts/tweaks/` and it gets picked up by `_run.sh` automatically.

### Tmux plugins
After the first apply (and shell switch), in a tmux session:
- Install plugins with `prefix + I` (capital I!)