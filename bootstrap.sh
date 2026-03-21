#!/usr/bin/env bash
# Bootstrap script for Linux and macOS
# Usage: DOTFILES_ENV=<env> bash bootstrap.sh
#   DOTFILES_ENV: devcontainer | dev_computer | home_lab (default: dev_computer)

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES_ENV="${DOTFILES_ENV:-dev_computer}"
if [[ "$DOTFILES_ENV" != "devcontainer" && "$DOTFILES_ENV" != "dev_computer" && "$DOTFILES_ENV" != "home_lab" ]]; then
    echo "Error: DOTFILES_ENV must be one of: devcontainer, dev_computer, home_lab" >&2
    exit 1
fi

echo "==> Environment: $DOTFILES_ENV"

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
CHEZMOI_SOURCE="$DOTFILES_DIR/home"

# Write chezmoi config so the environment is persisted for future runs.
mkdir -p "$HOME/.config/chezmoi"
cat > "$HOME/.config/chezmoi/chezmoi.toml" <<EOF
[data]
    env = "$DOTFILES_ENV"
EOF

# Symlink ~/.local/share/chezmoi -> dotfiles/home so that chezmoi cd,
# chezmoi source-path, and chezmoi git all work correctly without needing
# a remote repo clone. chezmoi walks up from the symlink target and finds
# the .git directory at $DOTFILES_DIR.
mkdir -p "$HOME/.local/share"
ln -sfn "$CHEZMOI_SOURCE" "$HOME/.local/share/chezmoi"

chezmoi apply

echo ""
echo "Done! You may need to restart your shell."
