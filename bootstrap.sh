set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ENV="${DOTFILES_ENV:-dev_computer}"
if [[ "$DOTFILES_ENV" != "devcontainer" && "$DOTFILES_ENV" != "dev_computer" && "$DOTFILES_ENV" != "home_lab" ]]; then
    echo "Error: DOTFILES_ENV must be one of: devcontainer, dev_computer, home_lab" >&2
    exit 1
fi
echo "==> Environment: $DOTFILES_ENV"

echo "==> Installing chezmoi..."
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"

echo "==> Applying dotfiles..."
mkdir -p "$HOME/.config/chezmoi"
cat > "$HOME/.config/chezmoi/chezmoi.toml" <<EOF
[data]
    env = "$DOTFILES_ENV"
EOF

mkdir -p "$HOME/.local/share"
ln -sfn "$DOTFILES_DIR" "$HOME/.local/share/chezmoi"

# chezmoi apply runs all dotfiles + the run_once_/run_onchange_ hooks
$HOME/.local/bin/chezmoi apply

echo ""
echo "Done! You may need to restart your shell."
