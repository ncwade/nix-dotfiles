---
name: rex
description: Inspect and control sibling panes, tabs, and dev servers via the rex CLI when running inside a Rex terminal session.
---

# Rex

Use the `rex` CLI to inspect and control sibling panes (blocks), tabs (windows), and dev servers when running inside Rex.

## Identify your session and pane

- `$REX_SESSION` identifies the current session (`-s "$REX_SESSION"`).
- `$REX_BLOCK` identifies the current pane (`-b "$REX_BLOCK"`).
- If either is unset or stale, check `rex whoami --json` and `rex ls --json`.

## Inspect state

```sh
rex session inspect "$REX_SESSION" --json
rex window ls -s "$REX_SESSION" --json
rex block ls -s "$REX_SESSION" --json
```

Use full IDs from JSON output (`window_id`, `focused_block_id`, `block_id`) in follow-up commands.

## Run commands and dev servers

Put Rex flags before `--` and the command after it:

```sh
# Split beside the current pane (directions: right, left, above, below)
rex split -s "$REX_SESSION" -b "$REX_BLOCK" --split=right -c "$PWD" -- <cmd...>

# Open a new tab (window) in the current session
rex run -s "$REX_SESSION" -c "$PWD" -- <cmd...>
```

## Read output and send input

```sh
rex capture -s "$REX_SESSION" -b <block_id> --trim
rex send -s "$REX_SESSION" -b <block_id> "<text>"
rex send-key -s "$REX_SESSION" -b <block_id> <key>
```

## Guardrails

- Prefer `--json` when discovering IDs or verifying layout state.
- Do not terminate Rex processes or restart the Rex server unless explicitly asked.
