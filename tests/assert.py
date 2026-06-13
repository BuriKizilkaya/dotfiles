#!/usr/bin/env python3
"""
Dotfiles assertion suite — Linux, macOS, Windows, and WSL.
Replaces assert.sh, assert_wsl.sh, and assert.ps1.

Usage:
    python3 tests/assert.py              # auto-detects platform
    python3 tests/assert.py --platform linux
    python3 tests/assert.py --platform wsl
    python3 tests/assert.py --platform windows
"""

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path


# ── Platform detection ─────────────────────────────────────────────────────

def _detect_platform() -> str:
    if sys.platform == "win32":
        return "windows"
    if sys.platform == "linux":
        try:
            proc_version = Path("/proc/version").read_text().lower()
        except OSError:
            proc_version = ""
        if "microsoft" in proc_version or os.environ.get("WSL_DISTRO_NAME"):
            return "wsl"
    return "linux"


# ── Assertion runner ───────────────────────────────────────────────────────

class Runner:
    def __init__(self) -> None:
        self.passed = 0
        self.failed = 0
        self.errors: list[str] = []

    # -- primitives --

    def _pass(self, msg: str) -> None:
        print(f"  [PASS] {msg}")
        self.passed += 1

    def _fail(self, msg: str) -> None:
        print(f"  [FAIL] {msg}", file=sys.stderr)
        self.failed += 1
        self.errors.append(msg)

    def skip(self, msg: str) -> None:
        print(f"  [SKIP] {msg}")

    def section(self, title: str) -> None:
        bar = "-" * (68 - len(title))
        print(f"\n-- {title} {bar}")

    # -- assertions --

    def assert_file(self, path: "str | Path") -> None:
        p = Path(path)
        if p.is_file():
            self._pass(f"File exists: {p}")
        else:
            self._fail(f"File missing: {p}")

    def assert_file_contains(self, path: "str | Path", pattern: str) -> None:
        p = Path(path)
        try:
            content = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            content = ""
        if p.is_file() and pattern in content:
            self._pass(f"File {p.name} contains {pattern!r}")
        else:
            self._fail(f"File {p} does not contain {pattern!r}")

    def assert_command(self, cmd: str) -> None:
        if shutil.which(cmd):
            self._pass(f"Command available: {cmd}")
        else:
            self._fail(f"Command not found: {cmd}")

    def assert_symlink(self, path: "str | Path") -> None:
        p = Path(path)
        if p.is_symlink():
            self._pass(f"Symlink exists: {p}")
        else:
            self._fail(f"Symlink missing: {p}")

    def assert_file_absent(self, path: "str | Path") -> None:
        p = Path(path)
        if not p.exists():
            self._pass(f"File absent: {p}")
        else:
            self._fail(f"File should not exist: {p}")

    # -- summary --

    def summary(self) -> int:
        """Print result summary and return an exit code (0 = all pass)."""
        print()
        print("-" * 70)
        print(f"  Results: {self.passed} passed, {self.failed} failed")
        if self.errors:
            print("\n  Failed checks:")
            for e in self.errors:
                print(f"    - {e}")
            print()
            return 1
        print()
        return 0


# ── Test suites ────────────────────────────────────────────────────────────

def run_common(r: Runner, home: Path) -> None:
    """Assertions that apply on every platform."""

    r.section("Chezmoi config")
    r.assert_file(home / ".config/chezmoi/chezmoi.toml")
    r.assert_file_contains(home / ".config/chezmoi/chezmoi.toml", "env")
    r.assert_symlink(home / ".local/share/chezmoi")

    r.section("Dotfiles")
    r.assert_file(home / ".gitconfig")
    r.assert_file_contains(home / ".gitconfig", "defaultBranch = main")
    r.assert_file_contains(home / ".gitconfig", "autocrlf = false")

    r.assert_file(home / ".config/starship.toml")
    r.assert_file_contains(home / ".config/starship.toml", "add_newline")

    r.assert_file(home / ".config/mise/conf.d/common.toml")
    r.assert_file_contains(home / ".config/mise/conf.d/common.toml", "opencode")
    r.assert_file_contains(home / ".config/mise/conf.d/common.toml", "starship")
    r.assert_file_contains(home / ".config/mise/conf.d/common.toml", "eza")

    r.section("Tools")
    r.assert_command("chezmoi")
    r.assert_command("git")
    r.assert_command("mise")
    r.assert_command("starship")


def run_linux(r: Runner, home: Path, *, wsl: bool = False) -> None:
    """Common assertions + Linux/macOS-specific checks."""
    run_common(r, home)

    r.section("Linux dotfiles")
    if wsl:
        r.assert_file_contains(home / ".gitconfig", "sshCommand = ssh.exe")

    r.assert_file(home / ".zshrc")
    r.assert_file_contains(home / ".zshrc", "starship init zsh")
    r.assert_file_contains(home / ".zshrc", "mise activate")

    r.assert_file(home / ".profile.dev")
    r.assert_file_contains(home / ".profile.dev", "groot")
    r.assert_file_contains(home / ".profile.dev", "alias isodate")

    r.assert_file(home / ".config/terminator/config")
    r.assert_file_contains(home / ".config/terminator/config", "background_color")

    r.section("Linux tools")
    r.assert_command("zsh")

    # .chezmoiignore strips the host's 1Password SSH config inside devcontainers.
    # WSL routes SSH through the Windows host (ssh.exe alias), so the file is unused there.
    r.section("Env-conditional ignores")
    ssh_config = home / ".ssh" / "config"
    dotfiles_env = os.environ.get("DOTFILES_ENV", "dev_computer")
    if dotfiles_env == "devcontainer" or wsl:
        r.assert_file_absent(ssh_config)
    else:
        r.assert_file(ssh_config)


def run_windows(r: Runner, home: Path) -> None:
    """Common assertions + Windows-specific checks."""
    run_common(r, home)

    r.section("Windows dotfiles")
    r.assert_file(home / ".ssh/config")

    r.assert_file(home / ".config/powershell/Microsoft.PowerShell_profile.ps1")
    r.assert_file(home / ".config/powershell/Install-Modules.ps1")

    # PowerShell $PROFILE — verify the file was copied by the run_after hook
    try:
        profile_path = subprocess.check_output(
            ["pwsh", "-NoProfile", "-Command", "Write-Output $PROFILE"],
            text=True,
        ).strip()
        r.assert_file(profile_path)
    except Exception as exc:
        r._fail(f"Could not resolve $PROFILE: {exc}")

    # Windows Terminal settings (optional — skip if not installed)
    local_app_data = os.environ.get("LOCALAPPDATA", "")
    if local_app_data:
        wt_state = Path(local_app_data) / "Microsoft" / "Windows Terminal"
        if wt_state.exists() or wt_state.is_symlink():
            r.assert_symlink(wt_state)
            r.assert_file(home / ".config/windows-terminal/settings.json")
        else:
            r.skip("Windows Terminal not installed")

    r.section("Windows tools")
    r.assert_command("eza")


# ── Entry point ────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description="Dotfiles assertion suite")
    parser.add_argument(
        "--platform",
        choices=["linux", "wsl", "windows"],
        default=None,
        help="Override platform detection (default: auto-detect)",
    )
    args = parser.parse_args()

    platform: str = args.platform or _detect_platform()
    print(f"Platform: {platform}")

    r = Runner()

    if platform == "windows":
        home = Path(os.environ.get("USERPROFILE", str(Path.home())))
        local_app_data = os.environ.get("LOCALAPPDATA", "")
        # Prepend mise shims so installed tools are reachable during checks
        extra_paths = [
            str(Path(local_app_data) / "mise" / "shims"),
            str(home / "bin"),
        ]
        os.environ["PATH"] = os.pathsep.join(extra_paths) + os.pathsep + os.environ.get("PATH", "")
        run_windows(r, home)
    else:
        home = Path.home()
        # Prepend mise shims so installed tools are reachable during checks
        extra_paths = [
            str(home / ".local" / "bin"),
            str(home / ".local" / "share" / "mise" / "shims"),
        ]
        os.environ["PATH"] = os.pathsep.join(extra_paths) + os.pathsep + os.environ.get("PATH", "")
        run_linux(r, home, wsl=(platform == "wsl"))

    return r.summary()


if __name__ == "__main__":
    sys.exit(main())
