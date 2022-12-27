#!/bin/bash

set -o errexit

reset_color=$(tput sgr 0)
info() {
  printf "%s[*] %s%s\n" "$(tput setaf 4)" "$1" "$reset_color"
}

success() {
  printf "%s[*] %s%s\n" "$(tput setaf 2)" "$1" "$reset_color"
}

err() {
  printf "%s[*] %s%s\n" "$(tput setaf 1)" "$1" "$reset_color"
}

warn() {
  printf "%s[*] %s%s\n" "$(tput setaf 3)" "$1" "$reset_color"
}


info "### Install packages ###"
sudo apt update
sudo apt install -y zsh stow


# add zsh as a login shell
info "### Configure Shell ###"
command -v zsh | sudo tee -a /etc/shells
sudo chsh -s $(which zsh) $USER

# setup oh my zsh
info "Installing oh my zsh..."
if [[ ! -f ~/.zshrc ]]; then
    ZSH=~/.oh-my-zsh ZSH_DISABLE_COMPFIX=true sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    chmod 744 ~/.oh-my-zsh/oh-my-zsh.sh
else
    warn "oh-my-zsh already installed"
fi

# plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || true


info "### Stow pacakges to ###"
target_dir=${1:-$HOME}
declare -a stow_folders=("zsh" "git")
for stow_folder in ${stow_folders[@]}
do
    info "Stow ${stow_folder} to '${target_dir}'"
    stow -v ${stow_folder} -t ${target_dir}
done
