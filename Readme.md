# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). Supports Linux, macOS, and Windows.

## Structure

```
home/                          # chezmoi source directory (mirrors $HOME)
├── .chezmoiignore             # skips Windows-only files on Linux/macOS
├── dot_gitconfig              # ~/.gitconfig
├── dot_zshrc                  # ~/.zshrc  (Linux/macOS)
├── dot_profile.dev            # ~/.profile.dev  (shell helpers & aliases)
├── dot_chezmoi.toml.tmpl      # chezmoi config template
└── dot_config/
    ├── mise/
    │   └── config.toml        # ~/.config/mise/config.toml  (global tools)
    ├── starship/
    │   └── starship.toml      # ~/.config/starship/starship.toml
    ├── terminator/
    │   └── config             # ~/.config/terminator/config  (Linux only)
    ├── powershell/            # ~/.config/powershell/  (Windows only)
    │   ├── Microsoft.PowerShell_profile.ps1
    │   └── Install-Modules.ps1
    └── windows-terminal/      # ~/.config/windows-terminal/  (Windows only)
        └── settings.json

scripts/
├── bootstrap.sh               # Linux/macOS setup script
└── bootstrap.ps1              # Windows setup script

tests/
├── Dockerfile                 # Ubuntu 24.04 test container
├── run-tests.sh               # Build image and run tests
└── assert.sh                  # Test assertions (runs inside container)
```

## Quick Start

### Linux / macOS

#### Requirements

```bash
sudo apt-get update
sudo apt-get install -y curl git zsh unzip curl wget ca-certificates 
```

```bash
bash scripts/bootstrap.sh
```

### Windows (PowerShell as Administrator)

```powershell
.\scripts\bootstrap.ps1
```

## How it works

- **chezmoi** manages all files in `home/` and applies them to `$HOME`
- Files prefixed with `dot_` map to dotfiles (e.g. `dot_zshrc` → `~/.zshrc`)
- Files ending in `.tmpl` are Go templates rendered per-machine (OS, username, etc.)
- `.chezmoiignore` skips Windows-only folders (`powershell/`, `windows-terminal/`) on Linux/macOS
- `bootstrap.ps1` symlinks Windows-specific paths that chezmoi can't target directly:
  - PowerShell profile → `$PROFILE`
  - Windows Terminal → `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_*\LocalState\`
- VSCode is excluded — use VSCode's built-in Settings Sync instead

## Testing

Run the full test suite in a clean Ubuntu 24.04 Docker container:

```bash
bash tests/run-tests.sh
```

Use `--no-cache` to force a full rebuild:

```bash
bash tests/run-tests.sh --no-cache
```

The tests verify that all dotfiles are placed correctly and all tools (`chezmoi`, `mise`, `just`, `starship`, etc.) are available after bootstrap.

## Adding new dotfiles

```bash
# Track an existing file
chezmoi add ~/.someconfig

# Edit a tracked file
chezmoi edit ~/.someconfig

# Apply changes
chezmoi apply
```

## Tools configured

| Tool             | Config file                        | Platforms             |
| ---------------- | ---------------------------------- | --------------------- |
| git              | `~/.gitconfig`                     | Linux, macOS, Windows |
| zsh + oh-my-zsh  | `~/.zshrc`                         | Linux, macOS          |
| Shell helpers    | `~/.profile.dev`                   | Linux, macOS          |
| mise             | `~/.config/mise/config.toml`       | Linux, macOS, Windows |
| starship         | `~/.config/starship/starship.toml` | Linux, macOS, Windows |
| VSCode           | built-in Settings Sync             | —                     |
| PowerShell       | `~/.config/powershell/`            | Windows               |
| Terminator       | `~/.config/terminator/config`      | Linux                 |
| Windows Terminal | `~/.config/windows-terminal/`      | Windows               |
