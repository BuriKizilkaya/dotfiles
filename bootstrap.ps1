# Bootstrap script for Windows (PowerShell)
# Usage: .\bootstrap.ps1
#
# This script only does the minimum needed to get chezmoi running.
# Everything else (mise tools, etc.) is handled by chezmoi hooks
# in home/run_once_* and home/run_onchange_* — run automatically by `chezmoi apply`.

$ErrorActionPreference = "Stop"

$DotfilesDir = Split-Path -Parent $PSScriptRoot

# Windows is always a dev_computer environment.
$env:DOTFILES_ENV = "dev_computer"
Write-Host "==> Environment: $env:DOTFILES_ENV" -ForegroundColor Cyan

Write-Host "==> Installing chezmoi..." -ForegroundColor Cyan
if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
    iex "&{$(irm 'https://get.chezmoi.io/ps1')} -b '~/bin'"
    $env:PATH = "$env:USERPROFILE\bin;$env:PATH"
} else {
    Write-Host "  chezmoi already installed, skipping." -ForegroundColor Green
}

Write-Host "==> Applying dotfiles..." -ForegroundColor Cyan

# Write chezmoi config so the environment is persisted for future runs.
$ChezmoiConfigDir = "$env:USERPROFILE\.config\chezmoi"
New-Item -ItemType Directory -Force -Path $ChezmoiConfigDir | Out-Null
@"
[data]
    env = "$env:DOTFILES_ENV"
"@ | Set-Content -Path "$ChezmoiConfigDir\chezmoi.toml" -Encoding UTF8

# Symlink ~/.local/share/chezmoi -> dotfiles repo root so that chezmoi cd
# lands in the git root. .chezmoiroot tells chezmoi the source files are in
# the home/ subdirectory.
$ChezmoiShareDir = "$env:USERPROFILE\.local\share"
New-Item -ItemType Directory -Force -Path $ChezmoiShareDir | Out-Null
$ChezmoiLink = "$ChezmoiShareDir\chezmoi"
if (Test-Path $ChezmoiLink) {
    Remove-Item $ChezmoiLink -Force -Recurse
}
New-Item -ItemType SymbolicLink -Path $ChezmoiLink -Target $DotfilesDir | Out-Null

# chezmoi apply runs all dotfiles + the run_once_/run_onchange_ hooks
chezmoi apply

# Link PowerShell profile
$PsProfileDir = Split-Path $PROFILE
New-Item -ItemType Directory -Force -Path $PsProfileDir | Out-Null
$PsSrc = "$env:USERPROFILE\.config\powershell\Microsoft.PowerShell_profile.ps1"
if (Test-Path $PsSrc) {
    New-Item -ItemType SymbolicLink -Path $PROFILE -Target $PsSrc -Force | Out-Null
    Write-Host "  Linked PowerShell profile" -ForegroundColor Green
}

# Link Windows Terminal settings
$WtPath = Get-ChildItem "$env:LOCALAPPDATA\Packages" -Filter "Microsoft.WindowsTerminal_*" -ErrorAction SilentlyContinue |
    Select-Object -First 1 |
    ForEach-Object { "$($_.FullName)\LocalState\settings.json" }
$WtSrc = "$env:USERPROFILE\.config\windows-terminal\settings.json"
if ($WtPath -and (Test-Path $WtSrc)) {
    New-Item -ItemType SymbolicLink -Path $WtPath -Target $WtSrc -Force | Out-Null
    Write-Host "  Linked Windows Terminal settings" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done! Restart your terminal to apply changes." -ForegroundColor Green
