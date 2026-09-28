"""Herdr deployment and configuration assertions."""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

from helpers.runner import Runner


def assert_herdr_config(r: Runner, home: Path) -> None:
    """Verify the deployed Herdr configuration is present and accepted."""
    r.section("Herdr configuration")
    config_path = home / ".config/herdr/config.toml"

    r.assert_command("herdr")
    r.assert_file(config_path)
    r.assert_file_contains(config_path, 'name = "gruvbox"')
    r.assert_file_contains(config_path, 'agent_panel_sort = "spaces"')
    r.assert_file_contains(config_path, 'show_agent_labels_on_pane_borders = true')
    r.assert_file_contains(config_path, 'delivery = "terminal"')

    if not config_path.is_file():
        r.skip("Herdr config validation skipped because config.toml is missing")
        return

    env = os.environ.copy()
    env["HERDR_CONFIG_PATH"] = str(config_path)
    result = subprocess.run(
        ["herdr", "config", "check"],
        capture_output=True,
        text=True,
        check=False,
        env=env,
    )
    if result.returncode == 0:
        r._pass("herdr config check accepts the deployed configuration")
    else:
        details = (result.stderr or result.stdout).strip()
        r._fail(f"herdr config check rejected the deployed configuration: {details}")
