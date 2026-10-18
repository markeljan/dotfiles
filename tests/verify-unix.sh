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
chezmoi init --apply --force --no-tty --source "$repo" --destination "$HOME"
bash -n "$HOME/.bashrc"
zsh -n "$HOME/.zshrc"
for file in "$HOME/.config/fish/config.fish" "$HOME"/.config/fish/conf.d/*.fish "$HOME"/.config/fish/functions/*.fish; do fish -n "$file"; done
printf '# local machine change\n' >> "$HOME/.config/fish/config.fish"
chezmoi apply --force --no-tty --source "$repo" --destination "$HOME"
grep -Fq '# local machine change' "$HOME/.config/fish/config.fish"
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
