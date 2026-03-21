#!/usr/bin/env bash
# Bootstrap script for Linux and macOS
# Usage: DOTFILES_ENV=<env> bash bootstrap.sh
#   DOTFILES_ENV: devcontainer | dev_computer | home_lab (default: dev_computer)
#
# This script only does the minimum needed to get mise and chezmoi running.
# Everything else (zsh, oh-my-zsh, mise tools) is handled by chezmoi hooks
# in home/run_once_* and home/run_onchange_* — run automatically by `chezmoi apply`.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ENV="${DOTFILES_ENV:-dev_computer}"
if [[ "$DOTFILES_ENV" != "devcontainer" && "$DOTFILES_ENV" != "dev_computer" && "$DOTFILES_ENV" != "home_lab" ]]; then
    echo "Error: DOTFILES_ENV must be one of: devcontainer, dev_computer, home_lab" >&2
    exit 1
fi
echo "==> Environment: $DOTFILES_ENV"

echo "==> Installing chezmoi..."
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin

echo "==> Applying dotfiles..."
# Write chezmoi config so the environment is persisted for future runs.
mkdir -p "$HOME/.config/chezmoi"
cat > "$HOME/.config/chezmoi/chezmoi.toml" <<EOF
[data]
    env = "$DOTFILES_ENV"
EOF

# Symlink ~/.local/share/chezmoi -> dotfiles repo root so that chezmoi cd
# lands in the git root. .chezmoiroot tells chezmoi the source files are in
# the home/ subdirectory.
mkdir -p "$HOME/.local/share"
ln -sfn "$DOTFILES_DIR" "$HOME/.local/share/chezmoi"

# chezmoi apply runs all dotfiles + the run_once_/run_onchange_ hooks
chezmoi apply

echo ""
echo "Done! You may need to restart your shell."
