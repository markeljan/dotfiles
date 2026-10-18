# AGENTS.md

This repo is a minimal chezmoi-managed dotfiles baseline for Windows, macOS, Debian, and Ubuntu.

## Primary workflow

1. Bootstrap with `chezmoi init --apply Markeljan`.
2. Use `chezmoi update` for normal sync.
3. Use `chezmoi apply` when you want to re-render the current source state without pulling Git changes.

On Ubuntu, prefer `sudo snap install chezmoi --classic` and then `chezmoi init --apply Markeljan`.

On interactive Linux `chezmoi init --apply Markeljan` runs, dotfiles may prompt for optional extras. All default to off, and the user can choose any combination of `desktop-vnc`, `desktop-rdp`, and `openclaw`.

If chezmoi is not installed and `snap` is unavailable, use `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply Markeljan`.

Because the repo is named `dotfiles`, `chezmoi init Markeljan` uses chezmoi's default GitHub URL guessing and resolves to `Markeljan/dotfiles`.

Maintainers may also point chezmoi at an explicit local checkout with `chezmoi init --apply --source "$PWD"`.

## Managed targets

On Windows, `~/.config/powershell/profile.ps1` and `fnm.ps1` are managed, and PowerShell all-host profiles receive a source hook. A Windows-only hook adapts the shared Cursor settings, Windows Terminal appearance, and native Neovim config path; it backs up changed application files under `%LOCALAPPDATA%/dotfiles/backups`. `~/.config/windows/tahoe-day.jpg` holds the terminal wallpaper. Existing additional settings/profiles are preserved. Personal identity, credentials, and WSL installation/reboots are not repo-managed.

All platforms install the regular/medium/bold MartianMono NFM font files from the pinned, SHA-256-verified Nerd Fonts archive in `.chezmoidata/fonts.toml`. `DOTFILES_SKIP_PACKAGES=1` skips downloads. Windows hooks run only on Windows; Unix shell scripts and targets are excluded there.

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
- `~/.config/ghostty/config` on macOS only
- `~/.config/ghostty/backgrounds/tahoe-day.jpg` on macOS only
- `~/.config/cmux/cmux.json` on macOS only
- `~/Library/Application Support/com.cmuxterm.app/config.ghostty` on macOS only (linked to the primary Ghostty config)
- `~/Library/Application Support/Cursor/User/settings.json` and `~/Library/Application Support/Cursor/User/keybindings.json` on macOS only
- `~/Library/Application Support/Kiro/User/settings.json` on macOS only
- `~/.local/bin/cursor`, `~/.local/bin/cursor-tunnel`, `~/.local/bin/code`, and `~/.local/bin/github` on macOS only when the matching app bundle is already installed

Top-level shell files are created when missing. `~/.ssh/config` is created by a post-apply hook when missing. If they already exist, they are preserved and may receive a small source/include hook instead of being replaced.

`~/.config/fish/config.fish` is create-only. Shared fish behavior belongs in `~/.config/fish/conf.d/*.fish`, while machine-specific edits can live in `~/.config/fish/config.fish` or `~/.config/fish/conf.d/99-local.fish`.

On macOS, `~/Library/Application Support/com.mitchellh.ghostty/config` and `~/Library/Application Support/com.cmuxterm.app/config.ghostty` are linked to `~/.config/ghostty/config`.

Package bootstrap installs `claude-code@latest` and `codex` with Homebrew when `claude` or `codex` are missing, installs Node.js LTS through `fnm`, and enables `pnpm` and `pnpx` through Corepack. It does not install Cursor or GitHub Desktop. On macOS, dotfiles only links their CLI helpers into `~/.local/bin` when the matching app bundle already exists in `/Applications` or `~/Applications`. Visual Studio Code is not used at all: `~/.local/bin/code` is linked to Cursor's own `bin/code`, so `code` opens Cursor.
On interactive Linux bootstraps, package bootstrap can also opt into a `desktop-vnc` bundle with `Xvfb`, `x11vnc`, Openbox, a systemd-managed always-on VNC display, and Google Chrome on `amd64`, or a `desktop-rdp` bundle with XFCE desktop packages, `xrdp`, and Google Chrome on `amd64`. Re-running `chezmoi init --apply` reconciles those services: selected ones are enabled and started, deselected ones are disabled and stopped. The VNC path tries to run `x11vnc -storepasswd` when an interactive TTY is available, exports `DISPLAY=:99` through the shared shell config, and defaults the virtual screen size to `1440x900x24`. The optional OpenClaw path installs `openclaw@2026.4.12` with `bun install --global`, runs `bun pm --global trust --all`, also creates `/var/tmp/openclaw-compile-cache` when possible, exports `NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache` plus `OPENCLAW_NO_RESPAWN=1`, and manages an OpenClaw gateway systemd user drop-in that adds those env vars and `DISPLAY=:99` when `desktop-vnc` is selected, including on reruns for existing installs.

## Constraints

- Keep the repo portable across Windows, macOS, Debian, and Ubuntu. Use LF source files per `.gitattributes` so Windows checkouts remain usable from WSL.
- Windows scripts require standard PowerShell 7 and winget. Do not automatically enable WSL, reboot, change commit identity, or copy credentials.
- Initialize fnm in the same process before activation. Fail clearly if initialization fails; never inherit an unwritable XDG_RUNTIME_DIR through sudo/runuser.
- Do not add plugin frameworks or shell-specific bloat.
- Keep `fzf` and Neovim customizations focused on the current lightweight workflow.
- Do not store secrets in the repo.
- Keep machine-specific aliases, SSH hosts, and extra keys in local override files.
- Do not seed host aliases or existing `authorized_keys` entries from the current machine into the repo.
- Preserve any existing `~/.ssh/authorized_keys` entries when regenerating the managed file, keep the repo-wide public key appended automatically, and keep machine-specific additions in `~/.ssh/authorized_keys.local`.
- Preserve existing top-level shell rc files and SSH config when include hooks or create-only files are sufficient.
- Keep `fish` as the intended login shell and do not auto-attach or repo-manage `tmux`.
- Do not reintroduce a separate installer wrapper when chezmoi can express the workflow directly.

## Verification

After changes, run:

The maintained equivalents of the Unix checks below are `bash tests/verify-unix.sh` and `pwsh -NoProfile -File tests/verify-windows.ps1`. Run both when available. CI exercises their render/preservation checks on Ubuntu, macOS, and Windows. Test real bootstrap/runtime changes separately on the available operating systems.

```bash
tmp_home="$(mktemp -d)"
mkdir -p "$tmp_home/.config/nvim"
printf 'set number\n' >"$tmp_home/.config/nvim/init.vim"
HOME="$tmp_home" DOTFILES_SKIP_PACKAGES=1 DOTFILES_SKIP_LOGIN_SHELL=1 chezmoi init --apply --force --source "$PWD" --destination "$tmp_home"
bash -n "$tmp_home/.bashrc"
zsh -n "$tmp_home/.zshrc"
for file in "$tmp_home/.config/fish/config.fish" "$tmp_home"/.config/fish/conf.d/*.fish "$tmp_home"/.config/fish/functions/*.fish; do fish -n "$file"; done
printf '# local machine change\n' >>"$tmp_home/.config/fish/config.fish"
HOME="$tmp_home" DOTFILES_SKIP_PACKAGES=1 DOTFILES_SKIP_LOGIN_SHELL=1 chezmoi apply --force --source "$PWD" --destination "$tmp_home"
grep -Fq '# local machine change' "$tmp_home/.config/fish/config.fish"
HOME="$tmp_home" nvim --headless "+qa" || true
test -f "$tmp_home/.ssh/authorized_keys"
grep -Fq 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILwXOaRFvzRwWE6lRt4DMK26VSR4e2b2hWQ7IEfi09Xa' "$tmp_home/.ssh/authorized_keys"
test ! -e "$tmp_home/.ssh/authorized_keys.shared"
test ! -e "$tmp_home/.ssh/config.shared"
test ! -e "$tmp_home/bin"
test ! -e "$tmp_home/.config/nvim/init.vim"
test ! -e "$tmp_home/.tmux.conf"
test ! -e "$tmp_home/CLAUDE.md"
rm -rf "$tmp_home"
git diff --stat
```

## Safe extension points

- `~/.config/powershell/local.ps1` on Windows

- `~/.config/sh/local.sh`
- `~/.config/fish/config.fish`
- `~/.config/fish/conf.d/99-local.fish`
- `~/.ssh/config.local`
- `~/.ssh/authorized_keys.local`

If you add new managed files, update both this document and `README.md`.
