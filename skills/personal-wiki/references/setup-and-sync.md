# Setup, access, and automated sync

Read `personal-wiki config` for the canonical path, exact origin URL, and branch.
Never guess another remote or create a GitHub repository. The user authorized
inline commits and periodic sync for this configured wiki, with other Git
operations still subject to `git-workflow`. Do not put credentials in URLs.

## One-time setup

If the remote already contains the wiki, obtain approval to clone that exact
remote into the configured path before bootstrapping. Otherwise run
`personal-wiki bootstrap` for the initial scaffold, then obtain approval for
initialization, origin setup, the reviewed first commit, and first push. Honor
existing identity, SSH, and signing preferences. Both the local and remote
configured branch must exist before automation runs. `begin` requires an initial
commit and a clean tree; `sync` never creates an absent remote branch.

Bootstrap preserves existing files and invokes no Git. Existing scaffolds may
still say "Never auto-capture chats or auto-push changes." When enabling this
user-requested automation, update only that outdated auto-push prohibition to
the scoped begin/finish/sync authorization in the current template, retaining
all unrelated instructions, then commit the migration. Do not overwrite the
wiki's entire AGENTS.md. A path change does not move the checkout.

## Access and discovery

Home Manager copies this skill to `~/.codex/skills/personal-wiki`, merges routing
into `~/.codex/AGENTS.md`, and installs the helper. A nonempty AGENTS.override.md
shadows the global routing. Restart Codex and use a fresh local chat outside the
wiki to verify discovery and filesystem access.

The named permission profile extends `:workspace` with the wiki root and a
write grant for only that wiki's `.git` directory, needed for inline commits.
Other projects' `.git` protection and existing approval/network policies remain.
A managed/default selection may override config defaults. Select the profile if
offered; otherwise attach the wiki as a secondary folder and request the narrow
Git metadata access when needed. Never switch to Full access. Managed policy
may need an administrator to permit this. Legacy sandbox settings do not compose
with named profiles; use `permissionProfile = null` and retain existing policy
if that is the chosen setup. A secondary folder does not supply global skills
or instructions. Ordinary ChatGPT web/cloud tasks do not inherit local access.

## Sync behavior

The macOS launchd user agent runs `personal-wiki sync` at login/load and every
configured interval (15 minutes by default). Codex need not remain open. The
machine must be awake with the user session and credentials available; this is
not a guarantee of a run exactly every 15 minutes. No remote means no scheduled
job. Run `personal-wiki sync` to request an immediate attempt.

Sync uses the same write lock as begin/finish. A busy lock causes a harmless
skip. It checks repository root, branch, operation state, exact origin fetch and
push URLs, and a clean tree. Then it fetches the configured branch, fast-forwards
incoming commits when local history is only behind, or pushes existing commits
when only ahead. Divergence, missing branches, unfinished edits, remote mismatch,
and authentication failures stop that attempt. It never stages/commits edits,
auto-stashes, rebases, resolves conflicts, changes remotes, or force-pushes.
It does not disable signing or hooks. Each Git subprocess has a timeout and no
terminal credential prompt; preconfigure the normal credential helper/agent.

Use `personal-wiki sync-status` for the last completed attempt, its error, and
last successful sync time (UTC). This is historical status, not proof that later
commits were synced. State lives in `.git/personal-wiki-sync.json` and is not
committed. Early failures before repository validation, and lock skips, appear
in `~/Library/Logs/personal-wiki-sync.log`; they do not replace a prior status.

## Recovery

A failed finish keeps files, staged changes, and the lock. Restore signing or
other prerequisites and retry with the same owner token. If another process
changed HEAD, review and recover manually. To abandon the transaction without
losing edits, explicitly unlock it; the dirty tree then blocks new transactions
and sync until the changes are reviewed and committed or otherwise resolved.

A crashed process can leave `.wiki-write.lock`. Confirm the owner is inactive
before explicitly unlocking with its token. There is no timed lock stealing.
Only use helpers against a standalone checkout with its own `.git` directory,
not a linked worktree. Keep `.wiki-write.lock/` ignored. Other editors must honor
the lock; they are not watched or auto-committed.

If histories diverge, inspect the competing commits and choose a manual
resolution with the user. After obtaining the required Git approval and
resolving it, sync can resume on the next interval. For a remote change, update
the Nix option and origin deliberately; a mismatch fails closed. Disable the
scheduled job with `programs.personalWiki.sync.enable = false` and activate.
