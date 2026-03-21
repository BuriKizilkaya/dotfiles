#!/usr/bin/env bash
# Bootstrap script for Linux and macOS
# Usage: bash bootstrap.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Switch to zsh..."
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)" $USER
fi

echo "  install oh-my-zsh..."
rm -rf "$HOME/.oh-my-zsh"
ZSH="$HOME/.oh-my-zsh" ZSH_DISABLE_COMPFIX=true RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions

echo "==> Installing mise..."
if ! command -v mise &>/dev/null; then
    curl https://mise.run | sh
fi
mise self-update

echo "==> Installing tools with mise..."
mkdir -p "$HOME/.config/mise"
cp $DOTFILES_DIR/home/dot_config/mise/config.toml "$HOME/.config/mise/config.toml"
mise install

echo "==> Applying dotfiles..."
chezmoi init --apply --source "$DOTFILES_DIR/home"

echo ""
echo "Done! You may need to restart your shell."
