# Dotfiles

Minimal [chezmoi](https://www.chezmoi.io/) dotfiles for Windows, macOS, Debian, and Ubuntu.

## Windows

On a new PC, install Git, chezmoi, and the standard PowerShell 7 MSI build:

```powershell
winget install --id Git.Git --exact --source winget
winget install --id Microsoft.PowerShell --exact --source winget --installer-type wix
winget install --id twpayne.chezmoi --exact --source winget
```

Open a new PowerShell 7 window, then run:

```powershell
chezmoi init --apply Markeljan
```

Windows bootstrap installs Cursor, Windows Terminal, GitHub CLI, fnm and Node LTS, Bun, pnpm, uv and Python 3.13, Neovim, Claude Code, Codex, and the shared terminal utilities through winget/npm/uv. Installers may request administrator access. Prefer the standard PowerShell MSI build: the Store/MSIX build can isolate runtime files from other tools.

The shared PowerShell profile lives in `~/.config/powershell/profile.ps1`, with include hooks in both PowerShell 7 and Windows PowerShell's all-host profiles. Local profile contents are preserved. The old one-off `developer-tools` profile block is backed up and migrated automatically. Machine-specific PowerShell customizations belong in `~/.config/powershell/local.ps1`.

Cursor formatting preferences and Windows Terminal styling are adapted from the macOS configuration, with native Windows paths. Cursor, Biome, Prettier, Tailwind and Remote WSL are installed. Existing additional editor settings and terminal profiles are preserved, except profiles that launch `fish`: fish is not part of the Windows setup. Changed Windows application configuration is backed up under `%LOCALAPPDATA%/dotfiles/backups`. Neovim uses `%LOCALAPPDATA%/nvim` on Windows.

Git defaults are applied only when absent; identity and credentials are never copied into the repository. On each new machine, set your commit name/email and sign in to GitHub, Cursor, Claude, and Codex yourself. Reopen terminals after installing tools so they receive the updated PATH.

### Optional WSL

The native Windows setup does not enable virtualization or reboot your PC. For Linux development, run `wsl --install -d Ubuntu-24.04` from an administrator terminal, restart if requested, and complete Ubuntu's user/password creation. Then follow the Linux quick start below inside Ubuntu. Keep Linux projects in `~/Projects` and open them through Cursor Remote WSL.

### Fonts

No custom font is installed; terminals and editors use their default monospace font, and the prompt and file listings avoid Nerd Font glyphs. Older MartianMono NFM installs and settings are removed on apply.

### Verification

`tests/verify-unix.sh` and `tests/verify-windows.ps1` test temporary destinations with package installation disabled, including shell syntax, repeated application, OS-specific exclusions, and local configuration preservation. GitHub Actions runs them on Ubuntu, macOS, and Windows. These rendering checks do not install every package on every CI runner; actual Windows and Ubuntu package/runtime checks should also be performed when changing bootstrap logic.

The bootstrap rejects a failed `fnm env` before running Node commands, and clears an inherited runtime directory that the current Linux user cannot write. Windows has a small junction fallback for fnm aliases and uses uv's verified Python installation path if the version alias is unavailable.

## Quick Start

Use chezmoi directly.

If chezmoi is not installed yet on Ubuntu, prefer:

```bash
sudo snap install chezmoi --classic
chezmoi init --apply Markeljan
```

If chezmoi is not installed yet and `snap` is unavailable:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply Markeljan
```

If chezmoi is already installed:

```bash
chezmoi init --apply Markeljan
```

On interactive Linux `chezmoi init --apply` runs, dotfiles offers an optional multiselect prompt for bootstrap extras. All options default to unselected, and you can pick any combination of:

- `desktop-vnc` for a headless VNC desktop with `Xvfb`, `x11vnc`, Openbox, and Google Chrome on `amd64`; the bootstrap tries to run `x11vnc -storepasswd`, enables a systemd service that keeps the display stack running, and exports `DISPLAY=:99` from the shared shell config
- `desktop-rdp` for XFCE, Xorg, `xrdp`, Google Chrome on `amd64`, and a `~/.xsession` with `startxfce4` when one is not already present
- `openclaw` for a global Bun install of `openclaw@2026.4.12`, followed by `bun pm --global trust --all`, plus `NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache` and `OPENCLAW_NO_RESPAWN=1`

Because this repo is named `dotfiles`, `chezmoi init Markeljan` uses chezmoi's default GitHub URL guessing and resolves to the `Markeljan/dotfiles` repo.

If `fish` does not become the login shell automatically, run:

```bash
echo "$(command -v fish)" | sudo tee -a /etc/shells
sudo chsh -s "$(command -v fish)" "$USER"
```

Skip package installation when testing:

```bash
DOTFILES_SKIP_PACKAGES=1 chezmoi init --apply Markeljan
```

Skip the login-shell change when testing:

```bash
DOTFILES_SKIP_LOGIN_SHELL=1 chezmoi apply
```

Preseed the Linux-over-SSH bootstrap extras explicitly:

```bash
chezmoi init --apply \
  --promptMultichoice 'Select optional Linux SSH bootstrap extras=desktop-vnc/desktop-rdp/openclaw' \
  Markeljan
```

If you re-run `chezmoi init --apply` later and unselect `desktop-vnc` or `desktop-rdp`, dotfiles disables and stops the corresponding service but leaves installed packages in place.

If you choose `openclaw`, dotfiles also creates `/var/tmp/openclaw-compile-cache` when possible, exports:

```bash
export NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
export OPENCLAW_NO_RESPAWN=1
```

and installs OpenClaw with:

```bash
bun install --global openclaw@2026.4.12
bun pm --global trust --all
```

It also writes an OpenClaw gateway systemd user drop-in so the service gets the same env. When `desktop-vnc` is also selected, that drop-in adds `DISPLAY=:99` so `openclaw browser open ...` targets the VNC display too. Re-running `chezmoi init --apply` with `openclaw` selected applies the same config to existing installs too.

If you choose `desktop-vnc`, dotfiles stores a VNC password, writes `~/.local/bin/dotfiles-start-vnc-display`, and enables a systemd service that runs:

```bash
Xvfb :99 -screen 0 "$DOTFILES_VNC_SCREEN" &
export DISPLAY=:99
openbox &
x11vnc -display :99 -forever -shared -rfbauth "$HOME/.vnc/passwd" -rfbport 5900 -noxdamage
```

Openbox keeps window focus sane and avoids some Chrome glitches compared with a bare virtual display. The service starts on boot, defaults to `DOTFILES_VNC_SCREEN=1440x900x24`, and can be overridden with a systemd service override if you want a different size. You can connect to `vnc://HOST:5900` at any time after the password exists.

## New VPS Example

On a fresh Ubuntu or Debian VPS, use a non-root user:

```bash
ssh your-user@your-server
sudo snap install chezmoi --classic
chezmoi init --apply Markeljan
```

What happens:

- chezmoi clones the repo into its source directory
- the package script installs the baseline packages with APT and Homebrew formulae, installs `claude-code@latest` and `codex` with Homebrew when `claude` or `codex` are missing, and then installs `fnm`, Node.js LTS, `uv`, and `bun`
- on macOS, app-provided CLI helpers are linked into `~/.local/bin` only when the matching app bundle is already installed
- your shell, SSH, Neovim, and prompt config are applied
- dotfiles tries to set `fish` as the login shell

If the shell switch cannot happen automatically, run the two manual commands shown above. Fresh Ubuntu cloud users often have passwordless `sudo` but no local account password, so `sudo chsh` is the reliable manual fix there.

## Daily Use

Pull new repo changes and apply them:

```bash
chezmoi update
```

Preview local changes before applying:

```bash
chezmoi diff
```

Apply the current source state again:

```bash
chezmoi apply
```

Show non-script drift:

```bash
chezmoi status --exclude=scripts
```

## Updating This Repo

If you want to change the shared dotfiles source itself, work in the chezmoi source directory:

```bash
chezmoi cd
```

For example, to add a shared alias:

```bash
chezmoi cd
$EDITOR .chezmoidata/shell.toml
chezmoi diff
chezmoi apply
git add .chezmoidata/shell.toml
git commit -m "feat: add alias"
git push
```

Shared aliases live in `.chezmoidata/shell.toml`, then render into bash, zsh, and fish.

If you prefer maintaining the repo from an explicit checkout like `~/Projects/dotfiles`, point chezmoi at that checkout once:

```bash
git clone https://github.com/Markeljan/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
chezmoi init --apply --source "$PWD"
```

After that, plain `chezmoi apply`, `chezmoi update`, and `chezmoi doctor` use that checkout as the source directory.

## Syncing An Existing Local Machine

If this machine is already set up and chezmoi is already configured, the normal sync command is:

```bash
chezmoi update
```

That pulls the latest Git changes in the configured source directory and reapplies them to your home directory.

If you are actively editing the source repo on the same machine and do not want chezmoi to pull first, use:

```bash
chezmoi diff
chezmoi apply
```

## How To Change Things

Edit the files in this repo, then apply them:

```bash
chezmoi cd
$EDITOR .chezmoidata/shell.toml
chezmoi diff
chezmoi apply
```

Useful chezmoi commands:

- `chezmoi diff` shows pending home-directory changes before you apply them.
- `chezmoi apply` writes the managed files to your home directory.
- `chezmoi status --exclude=scripts` shows which managed files differ.
- `chezmoi managed` lists the files managed by chezmoi.
- `chezmoi cd` opens a shell in the source directory.
- `chezmoi update` pulls and reapplies repo changes.

## What This Repo Manages

This repo stays intentionally small:

- macOS, Debian, and Ubuntu support
- bash, zsh, and fish shell configs from one shared data model
- minimal `starship` prompt
- `fzf` preview configuration and `fzf-preview`
- shell completions for common installed tools in bash, zsh, and fish
- `tmux` installed without repo-managed auto-attach or custom config
- local SSH top-level config passthrough with `config.local`
- append-safe `authorized_keys` generation from the repo key and local file
- minimal Neovim with a left file tree and editor pane
- package bootstrap with APT and Homebrew formulae, Homebrew-managed Claude Code and Codex installs when missing, plus `fnm`, Node.js LTS, `uv`, and `bun`
- synced Ghostty and cmux terminal settings on macOS only
- Cursor user settings and keybindings on macOS only
- Kiro user settings on macOS only

## Managed files

- `~/.config/sh/bash_profile`
- `~/.config/sh/bashrc`
- `~/.config/sh/zprofile`
- `~/.config/sh/zshrc`
- `~/.config/sh/shared.sh`
- `~/.config/fish/conf.d/*.fish`
- `~/.config/fish/functions/mkcd.fish`
- `~/.config/fish/functions/rmrf.fish`
- `~/.config/starship.toml`
- `~/.config/nvim`
- `~/.hushlogin` (empty; suppresses login banners in terminal sessions)
- `~/.ssh/authorized_keys`
- `~/.local/bin/fzf-preview`
- `~/.config/ghostty/config` (macOS only)
- `~/.config/ghostty/backgrounds/tahoe-day.jpg` (macOS only)
- `~/.config/cmux/cmux.json` (macOS only; includes custom shortcuts)
- `~/Library/Application Support/com.cmuxterm.app/config.ghostty` (macOS only; linked to the primary Ghostty config)
- `~/Library/Application Support/Cursor/User/settings.json` (macOS only)
- `~/Library/Application Support/Cursor/User/keybindings.json` (macOS only)
- `~/Library/Application Support/Kiro/User/settings.json` (macOS only)

On macOS, dotfiles also manages app CLI helper symlinks in `~/.local/bin` when the matching app bundle already exists:

- `~/.local/bin/cursor`
- `~/.local/bin/cursor-tunnel`
- `~/.local/bin/code` (points at Cursor's bundled CLI, not Visual Studio Code)
- `~/.local/bin/github`

On macOS, chezmoi also creates a symlink from:

- `~/Library/Application Support/com.mitchellh.ghostty/config`
- `~/Library/Application Support/com.cmuxterm.app/config.ghostty`

to:

- `~/.config/ghostty/config`

If `~/.bashrc`, `~/.zshrc`, `~/.bash_profile`, `~/.zprofile`, or `~/.ssh/config` already exist, this repo preserves them. New machines get minimal create-only files, and existing machines get a small source/include hook when needed instead of a full replacement.

`~/.config/fish/config.fish` is also create-only. Shared fish behavior lives in repo-managed `~/.config/fish/conf.d/*.fish`, while machine-specific edits and third-party tool additions can live in `~/.config/fish/config.fish` or `~/.config/fish/conf.d/99-local.fish` without fighting `chezmoi apply`.

If a stale `~/.config/nvim/init.vim` exists alongside the managed `init.lua`, the cleanup hook removes `init.vim` after apply so Neovim does not see conflicting startup configs.

## Shared shell baseline

The shared shell model lives in `.chezmoidata/shell.toml`.

v1 keeps the shell layer intentionally plain, with a few restored workflow helpers:

- shared PATH entries for `~/.local/bin` and `~/.bun/bin`
- optional `brew shellenv`
- optional `fnm` initialization with Node.js LTS via `fnm`
- optional completion bootstrap for bash, zsh, fish, Bun, pnpm, cargo, and `fzf`
- optional `zoxide` and `starship` initialization (`z` stays available without overriding `cd`)
- shared functions: `mkcd`, `gc`, `rmrf`
- bun shortcuts: `b`, `bi`, `bx`, `brd`, `brb`, `brs`, `brt`, `brl`, `brf`, `brc`
- shell shortcuts: `cat`, `grep`, `mkdir`, `rsy`
- `eza` shortcuts: `l`, `la`, `ll`, `lt`
- git shortcuts: `ga`, `gd`, `gl`, `gp`, `gs`, `gst`, `gfl`
- system shortcut: `sys`
- `procs` default: `procs --pager disable --sorta mem`
- pnpm shortcuts: `pi`, `px`, `prd`, `prb`, `prs`, `prt`, `prl`, `prf`, `prc`
- Claude/Codex shortcuts: `dclaude`, `dcodex`

fish uses `abbr` for shared aliases. bash and zsh use aliases. Shared functions are defined separately.

`rmrf` stages removal by renaming the target to a hidden sibling and deleting it in the background. It refuses empty paths, `.`, `..`, `~`, `/`, and the resolved home directory, and it does not follow the final symlink component when removing a link. If a real directory cannot be renamed in place, it falls back to clearing that directory's contents asynchronously while keeping the directory itself.

`fzf` is configured with a right-hand 50% preview split and `~/.local/bin/fzf-preview`.

## SSH behavior

`~/.ssh/config` is treated as local. On machines where it already exists, dotfiles adds:

- `Include ~/.ssh/config.local`

On machines with no existing `~/.ssh/config`, the post-apply hook creates a minimal top-level file that also includes:

- `Include ~/.orbstack/ssh/config`
- `Include ~/.ssh/config.local`

`authorized_keys` is generated on every `chezmoi apply` from:

- the existing `~/.ssh/authorized_keys` file
- the repo-managed shared public key embedded in the post-apply hook
- optional local append file: `~/.ssh/authorized_keys.local`

Entries are merged and de-duplicated, so existing keys are preserved rather than overwritten.

When using Ghostty over SSH, the macOS Ghostty config keeps only `sudo` shell integration enabled. The shared bash, zsh, and fish startup files force `TERM=xterm-256color` for SSH sessions and also downgrade to `xterm-256color` on local hosts where `xterm-ghostty` is not resolvable.

## Packages

Baseline package definitions live in `.chezmoidata/packages.toml`. The package script also conditionally installs `claude-code@latest` and `codex` with Homebrew when those commands are missing.

- macOS uses Homebrew formulae for repo-managed packages
- Debian and Ubuntu use APT for baseline packages and Homebrew for `bat`, `eza`, `fastfetch`, `procs`, `claude-code@latest`, `codex`, and `fnm`
- Debian and Ubuntu install the Homebrew prerequisites from the official Homebrew docs
- Bash completion support installs through `bash-completion@2` on macOS and `bash-completion` on Debian/Ubuntu
- macOS installs the `gh` CLI, but does not install Cursor, Visual Studio Code, or GitHub Desktop
- On macOS and Linux, dotfiles installs `claude-code@latest` when `claude` is missing and `codex` when `codex` is missing
- when `Cursor.app` or `GitHub Desktop.app` already exist in `/Applications` or `~/Applications`, dotfiles links their CLI helpers into `~/.local/bin`
- `code` is linked to Cursor's own `bin/code`, so `code` opens Cursor; Visual Studio Code is not used
- On Debian and Ubuntu, `starship` installs from APT when available; otherwise dotfiles downloads the matching GitHub release tarball directly
- On interactive Linux bootstraps, dotfiles can optionally install a `desktop-vnc` bundle with `Xvfb`, `x11vnc`, Openbox, a systemd-managed always-on VNC display, and Google Chrome on `amd64`, a `desktop-rdp` bundle with XFCE, `xrdp`, and Google Chrome on `amd64`, plus OpenClaw via `bun install --global openclaw@2026.4.12` and `bun pm --global trust --all`, with `/var/tmp/openclaw-compile-cache`, `OPENCLAW_NO_RESPAWN=1`, and a managed OpenClaw gateway systemd user drop-in; all of these extras default to off
- `fnm` installs through Homebrew
- Node.js LTS installs through `fnm`
- `pnpm` and `pnpx` are enabled through Corepack after Node.js LTS is active
- `uv` installs through the official Astral installer
- `bun` installs through the official Bun installer
- `neovim` installs through the system package manager

On macOS, the package bootstrap no longer installs Homebrew `bash` or `zsh`. The system shells are sufficient, and `fish` remains the primary shell.

Set `DOTFILES_SKIP_PACKAGES=1` when you want to test or apply the repo without running package installs.

Set `DOTFILES_SKIP_LOGIN_SHELL=1` when you want to skip the login-shell update script.

## Local overrides

Keep machine-specific changes outside the repo:

- `~/.config/sh/local.sh`
- `~/.config/fish/config.fish`
- `~/.config/fish/conf.d/99-local.fish`
- `~/.ssh/config.local`
- `~/.ssh/authorized_keys.local`

## Daily usage

After the first install, `chezmoi update` is the normal sync command.
