"""Detected host platform — single source of truth for helper functions."""

from __future__ import annotations

import os
import sys
from enum import Enum
from pathlib import Path


class Platform(Enum):
    LINUX = "linux"
    DARWIN = "darwin"
    WSL = "wsl"
    WINDOWS = "windows"

    @property
    def is_unix(self) -> bool:
        return self in (Platform.LINUX, Platform.DARWIN, Platform.WSL)

    @property
    def is_macos(self) -> bool:
        return self is Platform.DARWIN

    @property
    def is_wsl(self) -> bool:
        return self is Platform.WSL

    @property
    def is_windows(self) -> bool:
        return self is Platform.WINDOWS


def detect_platform() -> Platform:
    """Auto-detect the current host platform."""
    if sys.platform == "win32":
        return Platform.WINDOWS
    if sys.platform == "darwin":
        return Platform.DARWIN
    if sys.platform == "linux":
        try:
            proc_version = Path("/proc/version").read_text().lower()
        except OSError:
            proc_version = ""
        if "microsoft" in proc_version or os.environ.get("WSL_DISTRO_NAME"):
            return Platform.WSL
    return Platform.LINUX
