# Assertion script — runs on Windows after bootstrap.
# Checks that all dotfiles are applied and tools are available.

$ErrorActionPreference = "Stop"

$Pass = 0
$Fail = 0
$Errors = @()

# ── Helpers ────────────────────────────────────────────────────────────────

function Pass([string]$msg) {
    Write-Host "  [PASS] $msg"
    $script:Pass++
}

function Fail([string]$msg) {
    Write-Host "  [FAIL] $msg"
    $script:Fail++
    $script:Errors += $msg
}

function Assert-File([string]$path) {
    if (Test-Path $path -PathType Leaf) {
        Pass "File exists: $path"
    } else {
        Fail "File missing: $path"
    }
}

function Assert-FileContains([string]$path, [string]$pattern) {
    if ((Test-Path $path -PathType Leaf) -and (Select-String -Path $path -Pattern $pattern -Quiet)) {
        Pass "File $path contains '$pattern'"
    } else {
        Fail "File $path does not contain '$pattern'"
    }
}

function Assert-Command([string]$cmd) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Pass "Command available: $cmd"
    } else {
        Fail "Command not found: $cmd"
    }
}

# ── Tests ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "── Dotfiles (chezmoi) ────────────────────────────────────────────────"

Assert-File "$env:USERPROFILE\.gitconfig"
Assert-FileContains "$env:USERPROFILE\.gitconfig" "defaultBranch = main"
Assert-FileContains "$env:USERPROFILE\.gitconfig" "autocrlf = false"

Assert-File "$env:USERPROFILE\.config\starship.toml"
Assert-FileContains "$env:USERPROFILE\.config\starship.toml" "add_newline"

Assert-File "$env:USERPROFILE\.config\mise\config.toml"
Assert-FileContains "$env:USERPROFILE\.config\mise\config.toml" "opencode"

Assert-File "$env:USERPROFILE\.config\powershell\Microsoft.PowerShell_profile.ps1"

Write-Host ""
Write-Host "── Tools ─────────────────────────────────────────────────────────────"

Assert-Command "chezmoi"
Assert-Command "git"
Assert-Command "mise"
Assert-Command "starship"

# ── Summary ────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "──────────────────────────────────────────────────────────────────────"
Write-Host "  Results: $Pass passed, $Fail failed"

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "  Failed checks:"
    foreach ($e in $Errors) { Write-Host "    - $e" }
    Write-Host ""
    exit 1
}

Write-Host ""
