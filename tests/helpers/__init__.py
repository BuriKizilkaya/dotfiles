"""Reusable assertion helpers, grouped by feature.

Each module exports one or more `assert_*` functions that take a `Runner`
plus the inputs they need (e.g. home directory, platform flags).

The top-level `run_*` functions in `assert.py` are thin orchestrators that
call these helpers — making it trivial to run a single feature in isolation:

    from helpers.runner import Runner
    from helpers.ssh import assert_ssh_config
    r = Runner()
    assert_ssh_config(r, Path.home(), darwin=True)
    sys.exit(r.summary())
"""
