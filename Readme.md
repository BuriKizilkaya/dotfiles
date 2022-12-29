# Dotfiles

This repository contains dotfiles for Linux and Windows machines. It will installed with ansible.

## Installation

tbd

## Run playbook for linux host OS

```bash

ansible-playbook linux/linux-playbook.yml -i linux/linux-inventory.yml -K

```

## Run playbook for WSL

```bash

ansible-playbook linux/linux-playbook.yml -i linux/linux-inventory.yml --tags "ohmyzsh"

```

## Run playbook for Windows OS

This command will run from WSL for a Windows host.

```bash
```

## Todos

- [x] Stow
  - [x] Git

- [ ] Add Ansible top of everything
  - [ ] Install packages
    - [ ] vscode
    - [ ] docker
  - [x] Install dotfiles
