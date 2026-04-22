# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). Supports Linux, macOS, and Windows.

## Structure

```
dotfiles/
├── home/                          # chezmoi source directory (mirrors $HOME)
│   ├── dot_bashrc                 # ~/.bashrc
│   ├── dot_gitconfig.tmpl         # ~/.gitconfig (template)
│   ├── dot_profile.dev.tmpl       # ~/.profile.dev (shell helpers & aliases)
│   ├── dot_zshrc                  # ~/.zshrc
│   ├── dot_chezmoi.toml.tmpl      # chezmoi config
│   ├── .chezmoiignore             # skips platform-specific files
│   ├── .chezmoiremove             # files to remove from $HOME
│   ├── .chezmoiscripts/           # lifecycle scripts
│   │   ├── run_before_01_install-zsh.sh.tmpl
│   │   └── run_after_02_mise-install.{sh,ps1}.tmpl
│   └── dot_config/
│       ├── mise/config.toml
│       ├── starship.toml
│       ├── terminator/config      # Linux
│       ├── powershell/            # Windows
│       │   ├── Microsoft.PowerShell_profile.ps1
│       │   └── Install-Modules.ps1
│       └── windows-terminal/      # Windows
│           └── settings.json
├── tests/                         # Docker-based test suite
├── bootstrap.sh                   # Linux/macOS bootstrap
└── bootstrap.ps1                   # Windows bootstrap
```

## Platform Requirements

### Linux (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install -y curl git zsh unzip ca-certificates
curl https://mise.run | sh
```

### macOS

```bash
# Requires Homebrew (https://brew.sh/)
brew install curl git zsh
curl https://mise.run | sh
```

### Windows (PowerShell as Administrator)

```powershell
# Requirements:
# - PowerShell 5.1+ or PowerShell 7+
# - Git for Windows (https://git-scm.com/download/win)
# - Execution policy must allow scripts: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
winget install jdx.mise
```

## Quick Start

### Linux / macOS

```bash
bash bootstrap.sh
```

### Windows

```powershell
.\bootstrap.ps1
```

## How it works

- **chezmoi** manages all files under `home/` and applies them to `$HOME`
- Files prefixed with `dot_` map to dotfiles (e.g. `dot_zshrc` → `~/.zshrc`)
- Files ending in `.tmpl` are Go templates rendered per-machine (OS, username, etc.)
- `run_before_*` scripts execute before chezmoi applies; `run_after_*` scripts execute after
- `.chezmoiignore` skips platform-specific folders on other platforms
- `bootstrap.ps1` symlinks Windows paths that chezmoi can't target directly

## Testing

Run the full test suite in a clean Ubuntu 24.04 Docker container:

```bash
bash tests/run-tests.sh
```

Force a full rebuild:

```bash
bash tests/run-tests.sh --no-cache
```

## Adding new dotfiles

```bash
chezmoi add ~/.someconfig
chezmoi edit ~/.someconfig
chezmoi apply
```

## Tools configured

| Tool             | Config file                        | Platforms             |
| ---------------- | ---------------------------------- | --------------------- |
| git              | `~/.gitconfig`                     | Linux, macOS, Windows |
| bash             | `~/.bashrc`                        | Linux, macOS          |
| zsh + oh-my-zsh  | `~/.zshrc`                         | Linux, macOS          |
| Shell helpers    | `~/.profile.dev`                   | Linux, macOS          |
| mise             | `~/.config/mise/config.toml`       | Linux, macOS, Windows |
| starship         | `~/.config/starship.toml`          | Linux, macOS, Windows |
| Terminator       | `~/.config/terminator/config`      | Linux                 |
| PowerShell       | `~/.config/powershell/`            | Windows               |
| Windows Terminal | `~/.config/windows-terminal/`      | Windows               |
