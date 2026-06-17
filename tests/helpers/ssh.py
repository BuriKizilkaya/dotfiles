"""SSH config assertions.

Exercises the OS-conditional rendering of `home/private_dot_ssh/private_config.tmpl`:
  - Linux / WSL host:  IdentityAgent ~/.1password/agent.sock
  - macOS host:        IdentityAgent ~/Library/Group Containers/2BUA8C4S2C.com.1password/...

`.chezmoiignore` strips the config inside devcontainers, and WSL routes SSH
through the Windows host (ssh.exe alias), so the file is absent there.
"""

from __future__ import annotations

import os
from pathlib import Path

from helpers.platform import Platform
from helpers.runner import Runner


def assert_ssh_config(r: Runner, home: Path, platform: Platform) -> None:
    r.section("SSH config")
    ssh_config = home / ".ssh" / "config"
    dotfiles_env = os.environ.get("DOTFILES_ENV", "dev_computer")

    if dotfiles_env == "devcontainer" or platform.is_wsl:
        r.assert_file_absent(ssh_config)
        return

    r.assert_file(ssh_config)
    r.assert_file_contains(ssh_config, "ForwardAgent yes")
    r.assert_file_contains(ssh_config, "IdentityAgent")

    # 1Password's Apple Developer Team ID is identical on every Mac.
    if platform.is_macos:
        r.assert_file_contains(ssh_config, "2BUA8C4S2C.com.1password")
    else:
        r.assert_file_contains(ssh_config, "~/.1password/agent.sock")
