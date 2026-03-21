# Bootstrap script for Windows (PowerShell)
# Usage: .\bootstrap.ps1

$ErrorActionPreference = "Stop"
$DotfilesDir = Split-Path -Parent $PSScriptRoot

Write-Host "==> Installing chezmoi..." -ForegroundColor Cyan
if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
    winget install twpayne.chezmoi
}

Write-Host "==> Applying dotfiles..." -ForegroundColor Cyan
chezmoi init --apply --source "$DotfilesDir\home"

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
