#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT
export HOME="$temporary"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export DOTFILES_SKIP_PACKAGES=1 DOTFILES_SKIP_LOGIN_SHELL=1 DOTFILES_SKIP_NVIM_BOOTSTRAP=1
mkdir -p "$HOME/.config/nvim" "$HOME/.ssh"
printf 'set number\n' > "$HOME/.config/nvim/init.vim"
printf '# preserved SSH config\n' > "$HOME/.ssh/config"
# Legacy fish and fzf files from older revisions must be cleaned up on apply.
mkdir -p "$HOME/.config/fish/conf.d" "$HOME/.config/fish/functions" "$HOME/.config/sh" "$HOME/.local/bin"
touch "$HOME/.config/fish/conf.d/00-path-and-env.fish" "$HOME/.config/fish/functions/rmrf.fish" "$HOME/.config/sh/fzf.sh" "$HOME/.local/bin/fzf-preview"
chezmoi init --apply --force --no-tty --source "$repo" --destination "$HOME"
bash -n "$HOME/.bashrc"
zsh -n "$HOME/.zshrc"
zsh -n "$HOME/.config/sh/zshrc"
bash -n "$HOME/.config/sh/bashrc"
bash -n "$HOME/.config/sh/shared.sh"
bash -n "$HOME/.local/bin/rmrf"
zsh -i -c 'type mkcd gc >/dev/null' </dev/null
bash -i -c 'type mkcd gc >/dev/null' </dev/null
mkdir -p "$HOME/rmrf-target/nested"
"$HOME/.local/bin/rmrf" "$HOME/rmrf-target" >/dev/null
test ! -e "$HOME/rmrf-target"
! "$HOME/.local/bin/rmrf" // 2>/dev/null
test ! -e "$HOME/.config/sh/fzf.sh"
test ! -e "$HOME/.local/bin/fzf-preview"
printf '# local machine change\n' >> "$HOME/.zshrc"
chezmoi apply --force --no-tty --source "$repo" --destination "$HOME"
grep -Fq '# local machine change' "$HOME/.zshrc"
test ! -e "$HOME/.config/fish"
grep -Fq '# preserved SSH config' "$HOME/.ssh/config"
grep -Fq 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILwXOaRFvzRwWE6lRt4DMK26VSR4e2b2hWQ7IEfi09Xa' "$HOME/.ssh/authorized_keys"
test ! -e "$HOME/.ssh/authorized_keys.shared"
test ! -e "$HOME/.config/nvim/init.vim"
test ! -e "$HOME/.tmux.conf"
test ! -e "$HOME/AGENTS.md"
test ! -e "$HOME/tests"
test ! -e "$HOME/.config/powershell"
test ! -e "$HOME/.chezmoiscripts/15-windows.ps1"
if [ "$(uname -s)" = Linux ]; then
  test ! -e "$HOME/Library"
  test ! -e "$HOME/.config/ghostty"
fi
echo 'PASS: Unix rendering, shell syntax, repeat apply, local configuration preservation and OS exclusions'
