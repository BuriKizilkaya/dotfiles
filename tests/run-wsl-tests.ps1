param(
    [string]$Branch = (git rev-parse --abbrev-ref HEAD),
    [ValidateSet("dev_computer", "home_lab", "devcontainer")]
    [string]$DotfilesEnv = "devcontainer"
)

$ErrorActionPreference = "Stop"

$DOTFILES_REPO = "https://github.com/BuriKizilkaya/dotfiles.git"
$WSL_DISTRO = "UbuntuDotFilesTests"

function Invoke-Wsl {
    param([string[]]$Arguments)
    wsl @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "WSL command failed with exit code $LASTEXITCODE`: wsl $Arguments"
    }
}

Write-Host "==> Importing WSL distro..." -ForegroundColor Cyan
$wslRootfs = "$env:TEMP\ubuntu-wsl.tar.gz"
if (Test-Path $wslRootfs) { Remove-Item $wslRootfs -Force }
curl -fsSL -o $wslRootfs https://cloud-images.ubuntu.com/wsl/jammy/current/ubuntu-jammy-wsl-amd64-ubuntu22.04lts.rootfs.tar.gz

$existingDistros = wsl --list --quiet
if ($existingDistros -contains $WSL_DISTRO) {
    Write-Host "  Removing existing $WSL_DISTRO distro..." -ForegroundColor Yellow
    wsl --unregister $WSL_DISTRO
}
Invoke-Wsl @("--import", $WSL_DISTRO, "$env:TEMP\Ubuntu", $wslRootfs)

try {
    Write-Host "==> Installing dependencies in WSL..." -ForegroundColor Cyan
    Invoke-Wsl @("-d", $WSL_DISTRO, "bash", "-c", "apt-get update && apt-get install -y --no-install-recommends curl git zsh unzip wget ca-certificates sudo build-essential")

    Write-Host "==> Cloning and bootstrapping dotfiles in WSL (branch: $Branch, env: $DotfilesEnv)..." -ForegroundColor Cyan
    Invoke-Wsl @("-d", $WSL_DISTRO, "bash", "-c", "cd /root && git clone --branch $Branch $DOTFILES_REPO && cd dotfiles && DOTFILES_ENV=$DotfilesEnv bash bootstrap.sh")

    Write-Host "==> Running assertions in WSL" -ForegroundColor Cyan
    Invoke-Wsl @("-d", $WSL_DISTRO, "bash", "-c", "cd /root/dotfiles && bash tests/assert_wsl.sh")

    Write-Host "==> WSL tests completed successfully." -ForegroundColor Green
}
finally {
    Write-Host "==> Cleaning up..." -ForegroundColor Cyan
    wsl --unregister $WSL_DISTRO 2>$null
    Remove-Item $wslRootfs -Force -ErrorAction SilentlyContinue
}

exit $LASTEXITCODE
