# Assertion script — runs on Windows after bootstrap.
# Checks that all dotfiles are applied and tools are available.
# Usage: pwsh -File tests\assert.ps1

# Do NOT use $ErrorActionPreference = "Stop" — all assertions must run even if some fail.

$Pass = 0
$Fail = 0
$Errors = @()

# ── Helpers ────────────────────────────────────────────────────────────────

function Write-Pass([string]$msg) {
    Write-Host "  [PASS] $msg" -ForegroundColor Green
    $script:Pass++
}

function Write-Fail([string]$msg) {
    Write-Host "  [FAIL] $msg" -ForegroundColor Red
    $script:Fail++
    $script:Errors += $msg
}

function Assert-File([string]$path) {
    if (Test-Path $path -PathType Leaf) {
        Write-Pass "File exists: $path"
    } else {
        Write-Fail "File missing: $path"
    }
}

function Assert-FileContains([string]$path, [string]$pattern) {
    if ((Test-Path $path -PathType Leaf) -and (Select-String -Path $path -Pattern $pattern -Quiet)) {
        Write-Pass "File $(Split-Path $path -Leaf) contains '$pattern'"
    } else {
        Write-Fail "File $path does not contain '$pattern'"
    }
}

function Assert-Command([string]$cmd) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Write-Pass "Command available: $cmd"
    } else {
        Write-Fail "Command not found: $cmd"
    }
}

function Assert-Symlink([string]$path) {
    $item = Get-Item $path -ErrorAction SilentlyContinue -Force
    if ($item -and ($item.LinkType -in @("SymbolicLink", "Junction"))) {
        Write-Pass "Symlink/junction exists: $path"
    } else {
        Write-Fail "Symlink/junction missing: $path"
    }
}

# Extend PATH so mise-installed tools are reachable during assertions.
$env:PATH = "$env:LOCALAPPDATA\mise\shims;$env:USERPROFILE\bin;$env:PATH"

# ── Chezmoi config ─────────────────────────────────────────────────────────

Write-Host ""
Write-Host "── Chezmoi config ────────────────────────────────────────────────────"

Assert-File    "$env:USERPROFILE\.config\chezmoi\chezmoi.toml"
Assert-FileContains "$env:USERPROFILE\.config\chezmoi\chezmoi.toml" "env"
Assert-Symlink "$env:USERPROFILE\.local\share\chezmoi"

# ── Dotfiles (chezmoi) ─────────────────────────────────────────────────────

Write-Host ""
Write-Host "── Dotfiles (chezmoi) ────────────────────────────────────────────────"

Assert-File         "$env:USERPROFILE\.gitconfig"
Assert-FileContains "$env:USERPROFILE\.gitconfig" "defaultBranch = main"
Assert-FileContains "$env:USERPROFILE\.gitconfig" "autocrlf = false"

Assert-File         "$env:USERPROFILE\.config\starship.toml"
Assert-FileContains "$env:USERPROFILE\.config\starship.toml" "add_newline"

Assert-File         "$env:USERPROFILE\.config\mise\conf.d\common.toml"
Assert-FileContains "$env:USERPROFILE\.config\mise\conf.d\common.toml" "starship"
Assert-FileContains "$env:USERPROFILE\.config\mise\conf.d\common.toml" "eza"
Assert-FileContains "$env:USERPROFILE\.config\mise\conf.d\common.toml" "opencode"

Assert-File         "$env:USERPROFILE\.config\powershell\Microsoft.PowerShell_profile.ps1"
Assert-FileContains "$env:USERPROFILE\.config\powershell\Microsoft.PowerShell_profile.ps1" "starship init powershell"
Assert-FileContains "$env:USERPROFILE\.config\powershell\Microsoft.PowerShell_profile.ps1" "mise activate"
Assert-File         "$env:USERPROFILE\.config\powershell\Install-Modules.ps1"

Assert-File         "$env:USERPROFILE\.ssh\config"
Assert-FileContains "$env:USERPROFILE\.ssh\config" "IdentityAgent"
Assert-FileContains "$env:USERPROFILE\.ssh\config" "openssh-ssh-agent"

Assert-File         "$env:USERPROFILE\.config\windows-terminal\settings.json"

# ── Tools ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "── Tools ─────────────────────────────────────────────────────────────"

Assert-Command "chezmoi"
Assert-Command "git"
Assert-Command "mise"
Assert-Command "starship"
Assert-Command "eza"

# ── Summary ────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "──────────────────────────────────────────────────────────────────────"
Write-Host "  Results: $Pass passed, $Fail failed"

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "  Failed checks:" -ForegroundColor Red
    foreach ($e in $Errors) { Write-Host "    - $e" -ForegroundColor Red }
    Write-Host ""
    exit 1
}

Write-Host ""
