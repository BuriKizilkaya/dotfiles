"""Pi agent assertions — file deployment + CLI smoke tests."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

from helpers.runner import Runner


# ---------------------------------------------------------------------------
# CLI helper
# ---------------------------------------------------------------------------

def run_cli(
    args: list[str],
    *,
    extra_env: dict[str, str] | None = None,
    strip_keys: list[str] | None = None,
    timeout: int = 30,
) -> tuple[int, str, str]:
    """Run ``pi <args>`` and return ``(returncode, stdout, stderr)``.

    Args:
        args:       Arguments forwarded to ``pi``, e.g. ``["--list-models"]``.
        extra_env:  Key/value pairs merged on top of the current environment.
        strip_keys: Environment variable names to remove before the call.
                    Useful for simulating an absent API key without mutating
                    the calling process's environment.
        timeout:    Seconds before the subprocess is killed (default 30).

    Returns:
        A 3-tuple of (exit code, stdout text, stderr text).

    Raises:
        subprocess.TimeoutExpired: re-raised after the process is killed.
        FileNotFoundError: if ``pi`` is not on PATH.
    """
    env = dict(os.environ)
    for key in strip_keys or []:
        env.pop(key, None)
    if extra_env:
        env.update(extra_env)

    # On Windows, mise shims are .cmd batch files which CreateProcess cannot
    # execute directly (only .exe files work without shell=True).  Using
    # shell=True delegates to cmd.exe which handles .cmd resolution correctly.
    result = subprocess.run(
        ["pi", *args],
        capture_output=True,
        text=True,
        env=env,
        timeout=timeout,
        shell=(sys.platform == "win32"),
    )
    return result.returncode, result.stdout, result.stderr


# ---------------------------------------------------------------------------
# Assertion groups
# ---------------------------------------------------------------------------

def assert_pi_extensions(r: Runner, home: Path) -> None:
    """Check that chezmoi deployed the extension file with the right content."""
    r.section("Pi agent extensions — deployment")

    ext = home / ".pi" / "agent" / "extensions" / "ollama-cloud.ts"

    r.assert_file(ext)
    r.assert_file_contains(ext, "ollama-cloud")             # provider ID
    r.assert_file_contains(ext, "OLLAMA_CLOUD_API_KEY")     # API key env var
    r.assert_file_contains(ext, "OLLAMA_CLOUD_BASE_URL")    # base URL override env var
    r.assert_file_contains(ext, "OLLAMA_CLOUD_MODELS")      # fallback models env var
    r.assert_file_contains(ext, "ollama.com/v1")            # default base URL
    r.assert_file_contains(ext, "registerProvider")         # core pi API call
    r.assert_file_contains(ext, "authHeader")               # bearer auth flag


def assert_pi_cli(r: Runner) -> None:
    """Smoke-test the pi CLI to verify the extension integrates cleanly."""
    r.section("Pi agent extensions — CLI smoke tests")

    # 1. pi binary is on PATH --------------------------------------------------
    r.assert_command("pi")

    # 2. pi --version -----------------------------------------------------------
    try:
        rc, stdout, stderr = run_cli(["--version"])
        if rc == 0:
            r._pass(f"pi --version exits 0 (version: {(stdout + stderr).strip()})")
        else:
            r._fail(f"pi --version exited {rc}: {stderr.strip()}")
    except FileNotFoundError:
        r._fail("pi not found on PATH — skipping remaining CLI checks")
        return
    except subprocess.TimeoutExpired:
        r._fail("pi --version timed out")
        return

    # 3. No key, no fallback models → fetch fails, falls back to empty list,
    #    registerProvider still called → pi must exit 0.
    try:
        rc, stdout, stderr = run_cli(
            ["--list-models"],
            strip_keys=["OLLAMA_CLOUD_API_KEY", "OLLAMA_CLOUD_MODELS", "OLLAMA_CLOUD_BASE_URL"],
        )
        if rc == 0:
            r._pass("pi --list-models exits 0 (no OLLAMA_CLOUD_API_KEY)")
        else:
            r._fail(f"pi --list-models exited {rc} with no key set")
    except subprocess.TimeoutExpired:
        r._fail("pi --list-models timed out (no-key run)")

    # 4. Fake key → fetch fails, fallback to empty model list, exit 0 ----------
    try:
        rc, stdout, stderr = run_cli(
            ["--list-models"],
            strip_keys=["OLLAMA_CLOUD_API_KEY", "OLLAMA_CLOUD_MODELS", "OLLAMA_CLOUD_BASE_URL"],
            extra_env={"OLLAMA_CLOUD_API_KEY": "ollama_ci_fake"},
        )
        if rc == 0:
            r._pass("pi --list-models exits 0 with bad OLLAMA_CLOUD_API_KEY (fetch error handled)")
        else:
            r._fail(f"pi --list-models exited {rc} with bad key")
    except subprocess.TimeoutExpired:
        r._fail("pi --list-models timed out (fake-key run)")
