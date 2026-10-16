---
name: herdr-worktrees
description: |
  Use when the user asks to create, open, list, or manage Git worktrees in a Herdr session, including parallel issue workspaces; or asks to delegate work to a sub-agent/worktree. Create them through the Herdr worktree API/CLI, not raw `git worktree`.
---

# Herdr worktrees

When the user explicitly asks for worktrees in the current Herdr session, use Herdr's worktree commands so each checkout is registered and visible as a Herdr workspace. Never use `git worktree add` for this purpose.

Verify the managed session and identify the repository:

```bash
test "${HERDR_ENV:-}" = 1
herdr worktree
```

Use the running CLI's help for syntax, then create each desired worktree from the repository root (`--cwd "$PWD"`). Example:

```bash
herdr worktree create --cwd "$PWD" \
  --branch <branch-name> --base <base-ref> --label '<workspace label>'
```

Omit `--focus` / pass `--no-focus` unless the user asks to switch focus. Herdr stores managed worktree checkouts under its worktree directory (typically `~/.herdr/worktrees/`); do not move them into the repository. Confirm creation and visibility with:

```bash
herdr worktree list --cwd "$PWD"
```

Use the JSON response fields for the created workspace, branch, path, and root-pane ID. Avoid creating duplicate branches/worktrees; inspect the list first. For multiple independent issues, make separate calls with a distinct branch and descriptive label per issue. Before removing any worktree, verify its exact path/branch and ensure it is the one the user requested to remove.

## Delegate implementation to Pi

Treat an instruction such as “arbeite das in einem Sub-Agenten ab”, “delegiere das”, “bearbeite das in einem Worktree”, or an equivalent request as an instruction to create a Herdr worktree **and immediately start a Pi agent with the task prompt**. Do not ask a follow-up question when the task, base branch, and worktree/branch naming are clear.

Launch Pi in the root pane returned by that worktree's `create` response, then submit the requested task. Do this after the worktree is created, not by manually sending `pi` to its terminal:

```bash
herdr agent start <unique-agent-name> --kind pi --pane <root-pane-id>
herdr agent prompt <unique-agent-name> '<task prompt>'
```

Choose a unique, lowercase agent name matching `[a-z][a-z0-9_-]{0,31}`, such as `issue2_publish`. Include the issue number, title, acceptance criteria, and any requested constraints in the prompt. Do not use `--wait` for an implementation task unless the user asks for synchronous completion; the agent should continue independently. Keep the new workspace unfocused unless the user requests otherwise.

When the user only asks to create worktrees, do **not** start Pi automatically. Conversely, when they ask for a sub-agent or delegated worktree, starting Pi is mandatory even if they do not explicitly say “open Pi”. Confirm the created workspace IDs, branches, labels, and started agent names when applicable.
