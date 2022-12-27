# Linux Dotfiles

For Linux machines the dotfiles are manged with [GNU Stow](https://www.gnu.org/software/stow/). The dotfiles are organized into packages, each package is a directory with the same name as the package. The dotfiles are then symlinked into the home directory using the `stow` command.

## Installation

To install the dotfiles, clone the repository and run the `install.sh target-folder` script. The `target-folder` is the folder where the dotfiles will be installed. The default is `~`.

## Todos

- [ ] Stow
  - [x] Git

- [ ] Add script for installing packages
  - [ ] OH MY POSH
  - [ ] Plugins for ZSH
