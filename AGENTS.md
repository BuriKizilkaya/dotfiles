# AGENTS.md — Coding Agent Instructions

This is a personal dotfiles repository managed by [chezmoi](https://www.chezmoi.io/).
It provisions a consistent shell environment across Linux, macOS, and Windows.
This is **not** an application — there is no build pipeline, package manager, or compilation step.

---

## Repository Structure

```
dotfiles/
├── bootstrap.sh           # Linux/macOS bootstrap: installs mise + chezmoi, runs apply
├── bootstrap.ps1          # Windows bootstrap: installs chezmoi via winget, symlinks profiles
├── home/                  # chezmoi source root (mirrors $HOME); pointed to by .chezmoiroot
│   ├── dot_*              # Dotfiles: dot_ prefix maps to . (e.g. dot_zshrc → ~/.zshrc)
│   ├── *.tmpl             # Go templates: processed by chezmoi before writing
│   ├── .chezmoiignore     # Platform-conditional file exclusions (Go template)
│   ├── .chezmoiremove     # Files chezmoi should delete from $HOME
│   └── .chezmoiscripts/   # Lifecycle automation scripts, organised in tool subfolders
│       ├── zsh/
│       ├── mise/
│       └── tailscale/
└── tests/
    ├── Dockerfile         # Ubuntu 24.04; runs bootstrap.sh as build step
    ├── run-tests.sh       # Builds Docker image and runs assertions
    └── assert.sh          # Assertion helpers: assert_file, assert_command, assert_symlink, etc.
```

---

## Commands

### Run all tests
```bash
bash tests/run-tests.sh
```
Tests run inside Docker (Ubuntu 24.04). They execute `bootstrap.sh` and assert that
files exist, contain expected content, and tools are on `$PATH`.

### Force a clean Docker rebuild
```bash
bash tests/run-tests.sh --no-cache
```

### Run a single test (workaround — no native support)
There is no test filter mechanism. To target specific assertions, run the container
interactively after a build:
```bash
docker run --rm -it dotfiles-test bash
# then manually run: bash /dotfiles/tests/assert.sh
```
Or temporarily comment out assertions in `tests/assert.sh`.

### Apply dotfiles manually
```bash
chezmoi apply
```

### Bootstrap (Linux/macOS)
```bash
DOTFILES_ENV=dev_computer bash bootstrap.sh
# DOTFILES_ENV options: devcontainer | dev_computer | home_lab (default: dev_computer)
```

### Bootstrap (Windows, PowerShell as Administrator)
```powershell
.\bootstrap.ps1
```

---

## Chezmoi Conventions

### File naming
| Pattern | Meaning |
|---|---|
| `dot_foo` | Maps to `~/.foo` |
| `*.tmpl` | Processed as a Go template before writing |
| `run_once_*` | Script runs exactly once per machine (tracked by content hash) |
| `run_onchange_*` | Script re-runs whenever its content changes |
| `run_after_*` | Script runs after dotfiles are applied |
| `01_`, `02_` numeric prefix | Controls execution order |
| `*_unix.sh.tmpl` | Runs on Linux and macOS (excluded on Windows) |
| `*_linux.sh.tmpl` | Runs on Linux only |
| `*_darwin.sh.tmpl` | Runs on macOS only |
| `*_windows.ps1.tmpl` | Runs on Windows only |

### Template variables
| Variable | Values |
|---|---|
| `.chezmoi.os` | `"linux"`, `"darwin"`, `"windows"` |
| `.env` | `"devcontainer"`, `"dev_computer"`, `"home_lab"` |
| `.name` | Full name string |
| `.email` | Email string |

### Template patterns
```gotemplate
{{/* OS guard — exclude Windows from a bash script */}}
{{ if ne .chezmoi.os "windows" -}}

{{/* Environment guard */}}
{{ if and (ne .chezmoi.os "windows") (or (eq .env "dev_computer") (eq .env "home_lab")) -}}

{{/* macOS vs Linux branch inside a shared unix script */}}
{{ if eq .chezmoi.os "darwin" -}}
brew install --cask foo
{{ else -}}
curl -fsSL https://example.com/install.sh | sh
{{ end -}}

{{/* Cache-busting: re-run script when a config file changes */}}
# config hash: {{ include "dot_config/mise/config.toml" | sha256sum }}

{{/* Check if a binary exists on PATH */}}
{{ if lookPath "code" -}}
```

### Adding a new tool installer
1. Create a subdirectory under `home/.chezmoiscripts/<toolname>/`
2. Add `run_once_install-<toolname>_unix.sh.tmpl` and/or `run_once_install-<toolname>_windows.ps1.tmpl`
3. Wrap the entire file body in an OS + env guard
4. Always check if the tool is already installed before installing (idempotency)

---

## Code Style

### Bash scripts
- Shebang: `#!/usr/bin/env bash` (never `#!/bin/bash`)
- Always start with `set -euo pipefail`
- Progress output convention:
  ```bash
  echo "==> Top-level step description..."
  echo "  Sub-step detail."
  ```
- Redirect error messages to stderr: `echo "Error: ..." >&2`
- Check for existing tools before installing:
  ```bash
  if command -v foo &>/dev/null; then
      echo "==> foo already installed, skipping."
      exit 0
  fi
  ```
- Variable naming: `UPPER_SNAKE_CASE` for exported/environment vars, `lower_snake_case` for locals
- Shell function naming: `snake_case`
- Git plugin updates: use `git pull --ff-only` (safe, no force-merging)

### PowerShell scripts
- Always set `$ErrorActionPreference = "Stop"` at the top
- Color-coded output:
  ```powershell
  Write-Host "==> Step description..." -ForegroundColor Cyan
  Write-Host "  Done." -ForegroundColor Green
  ```
- Variable naming: `PascalCase` (e.g. `$DotfilesDir`, `$PsSrc`)
- Check for existing tools: `Get-Command foo -ErrorAction SilentlyContinue`

### Chezmoi templates (`.tmpl` files)
- Keep template logic minimal — prefer OS/env guards at the top of the file over scattered inline conditionals
- Use `{{- ... -}}` (dash trim markers) on all template tags to avoid blank lines in rendered output
- Embed a sha256 hash comment to trigger `run_onchange_` re-execution when a dependency file changes

### Line endings (enforced by `.gitattributes`)
| File type | Line ending |
|---|---|
| `*.sh`, `*.toml`, `*.md` | LF |
| `*.ps1` | CRLF |

---

## Three Deployment Environments

| `DOTFILES_ENV` | Description | Differences |
|---|---|---|
| `dev_computer` | Personal dev machine (default) | Full setup, Tailscale installed |
| `home_lab` | Home lab servers | Full setup, Tailscale installed |
| `devcontainer` | Dev containers / CI | Skips `chsh`, skips Tailscale |

Scripts should gate on environment using:
```bash
{{ if or (eq .env "dev_computer") (eq .env "home_lab") -}}
```

---

## Error Handling Patterns

### Bash
- `set -euo pipefail` — abort on error, unset variable, or failed pipe
- Validate inputs early and `exit 1` with a message to stderr
- Use guard clauses (`if already installed → exit 0`) to keep scripts idempotent

### PowerShell
- `$ErrorActionPreference = "Stop"` — all errors are terminating
- Use `-ErrorAction SilentlyContinue` only for explicit existence checks

### Tests (`tests/assert.sh`)
- Uses an accumulator pattern — all assertions run even if some fail
- `ERRORS=()` array collects failures; exit code deferred to end
- Do **not** add `set -euo pipefail` to `assert.sh`; individual assertion failures must not abort the suite

---

## Key Tools Managed by This Repo

| Tool | Config file | Notes |
|---|---|---|
| chezmoi | `home/dot_chezmoi.toml.tmpl` | Dotfile manager |
| mise | `home/dot_config/mise/config.toml` | Polyglot version manager (replaces nvm/pyenv/asdf) |
| starship | `home/dot_config/starship.toml` | Cross-shell prompt |
| just | via mise | Command runner |
| opencode | via mise | AI coding assistant |
| Tailscale | `.chezmoiscripts/tailscale/` | VPN; installed on `dev_computer` + `home_lab` only |

---

## What NOT to Do

- Do not edit files directly in `~/.config/` or `~/` — always edit the source in `home/` and run `chezmoi apply`
- Do not add secrets or credentials to any tracked file; use `.env` (git-ignored) for local secrets
- Do not use `chezmoi init --apply --source` with a path to `home/` — the source is the repo root (`.chezmoiroot` redirects to `home/`)
- Do not skip `set -euo pipefail` in new bash scripts
- Do not create per-OS duplicate scripts when a single `_unix.sh.tmpl` with an internal branch will do
