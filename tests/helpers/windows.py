"""Windows-specific dotfile & tool assertions."""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

from helpers.runner import Runner


def assert_windows_dotfiles(r: Runner, home: Path) -> None:
    r.section("Windows dotfiles")
    # Windows configures 1Password's SSH agent via the desktop app, so a
    # hand-written ~/.ssh/config is unnecessary and is stripped by .chezmoiignore.
    r.assert_file_absent(home / ".ssh" / "config")

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


def assert_windows_terminal(r: Runner, home: Path) -> None:
    r.section("Windows Terminal")
    local_app_data = os.environ.get("LOCALAPPDATA", "")
    if not local_app_data:
        r.skip("LOCALAPPDATA not set")
        return

    wt_state = Path(local_app_data) / "Microsoft" / "Windows Terminal"
    if wt_state.exists() or wt_state.is_symlink():
        r.assert_symlink(wt_state)
        r.assert_file(home / ".config/windows-terminal/settings.json")
    else:
        r.skip("Windows Terminal not installed")


def assert_windows_tools(r: Runner) -> None:
    r.section("Windows tools")
    r.assert_command("eza")
