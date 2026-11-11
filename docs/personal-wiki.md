# Shared personal wiki for local Codex

The wiki lives at `~/knowledge/personal-wiki` and serves local Codex chats across
projects. Each completed update is committed locally through the wiki helper.
A macOS background job syncs committed changes every 15 minutes, even when Codex
is closed. Sources and wiki content stay outside the Nix store. Ordinary chats
are never automatically captured.

## Configuration and activation

The integration is disabled by default. Only the explicit `luna` host entry in
`nix-hosts/flake.nix` enables it and selects `https://github.com/ncwade/personal-wiki.git`.
Employer hosts supplied by the private employer flake remain disabled, as do
new hosts unless they explicitly opt in. Keep opt-ins in personal host definitions,
not shared Home Manager user modules: the same user profile can serve a work Mac.

Disabled hosts install no wiki helper/settings, wiki skill, global routing or
permission grants, or sync job. Their git-workflow skill retains its normal
approval policy. On an enabled personal host, installation appends only the
[wiki authorization](../skills/personal-wiki/references/git-authorization.md) to
that skill. This is device configuration, not automatic device-ownership detection.

The relevant options are:

```nix
programs.personalWiki = {
  enable = true; # Only in an explicitly selected personal host.
  path = "/Users/ncwade/knowledge/personal-wiki";
  remote = "https://github.com/ncwade/personal-wiki.git";
  branch = "main";
  sync.enable = true;
  sync.intervalSeconds = 900;
  permissionProfile = "personal-wiki";
};
```

The remote/branch are the explicit allowed destination, not credentials. They
must match the checkout's origin fetch/push URLs and checked-out branch.
Changing the path does not move data; changing the remote does not rewrite
origin. A null remote disables the scheduled job. The branch defaults to main;
change it if the real wiki uses another branch. The connected GitHub tool could
not verify access to this repository during implementation, so remote access
and its branch must be checked during setup.

Close Codex to avoid concurrent configuration writes, then activate this Mac:

```sh
cd /Users/ncwade/src/github.com/ncwade/nix-hosts
sudo darwin-rebuild switch --flake path:.#luna
```

This applies the full host configuration, including other pending changes.
`path:` includes new files before they are tracked. Activation installs the
helper, copies the personal-wiki and updated git-workflow skills, and merges
short managed blocks into mutable Codex config/global instructions. Unrelated
settings, comments, and instructions are preserved; existing files get a one-time
`*.before-personal-wiki` backup. Conflicts and symlinked config files stop the
merge instead of replacing their owner. A nonempty AGENTS.override.md shadows
global routing and must be reconciled separately.

It also installs the Home Manager user agent
`org.nix-community.home.personal-wiki-sync`. It runs on load/login and at the
configured interval while the machine is awake and the user session is active.
Sleep can coalesce attempts. Failures retry on the next interval, without
repeated immediate retries. Until the wiki is initialized and credentials work,
attempts fail safely and log the reason. No full-system switch or live sync was
performed as part of implementation/testing.

## One-time repository setup

After activation, inspect the settings:

```sh
personal-wiki config
```

If the remote already contains the wiki, clone its configured branch into the
configured path **before** bootstrapping. The path must be absent or empty.
If starting with an empty remote, bootstrap locally, then initialize the Git
repository, set origin, review and commit the initial scaffold, and push the
configured branch once. Preserve existing Git identity, signing, and credential
settings. Repository creation, initialization, remote changes, and first
publication remain explicit setup actions; automation never guesses them.

```sh
personal-wiki bootstrap
```

This command creates missing `raw/`, `sources/`, `entities/`, `topics/`, `notes/`,
`index.md`, `log.md`, `AGENTS.md`, and `.gitignore`. It invokes no Git and preserves
existing content. Make sure `.wiki-write.lock/` is ignored. The helper requires
a standalone checkout with its own `.git` directory, an initial commit, and an
existing remote branch before automatic sync; linked worktrees are unsupported.

For an earlier scaffold, update only its obsolete prohibition on auto-push to
the begin/finish/sync authorization in
[the current template](../skills/personal-wiki/assets/template/AGENTS.md), then
commit that migration. Bootstrap deliberately does not overwrite existing
instructions. An initial clone/bootstrap may leave new scaffold files to review
and commit before the first transaction.

HTTPS sync uses your normal Git credential helper. Configure authenticated Git
access once; no tokens go in Nix. SSH is also supported if both the Nix remote
and origin use the same SSH URL. Sync cannot answer terminal password prompts;
ensure your chosen helper/SSH agent works unattended. Existing 1Password/SSH
signing stays enabled for foreground commits; a locked signer may need you to
unlock it. The implementation never bypasses signing or hooks.

## Inline commits

The skill now performs one transaction per logical update:

1. `personal-wiki begin <unique-owner-token>` acquires the lock and checks that
   the wiki is clean, on the configured branch, and has no Git operation underway.
2. The agent reads the current pages, edits only the requested update, updates
   the index/log, and validates links and source preservation.
3. `personal-wiki finish <same-token> --message "docs(wiki): describe update" --
   <exact-relative-file> ...` stages the exact changed files, commits once,
   and releases the lock. No changes means no empty commit. It does not push.

The helper refuses unlisted changes rather than staging them. It remembers HEAD
at begin and stops if another writer changes it. A failed commit retains files,
staging, and the lock for recovery. Fix the cause and retry finish with the same
token. Never claim a failed commit was saved to Git. If abandoning a transaction,
explicitly unlock it; unresolved dirty files then block begin/sync until reviewed.

Your request authorizes these helper Git operations without repeated approval.
The installed git-workflow skill receives the
[scoped exception](../skills/personal-wiki/references/git-authorization.md) only
on enabled personal devices.
Arbitrary Git commands and other repositories retain their existing approval
requirements. External editors must cooperate with begin/finish or use reviewed
manual commits; no filesystem watcher commits partial saves.

## Periodic sync and recovery

The background job acquires the same lock, skips active writers, verifies the
exact origin/branch, and requires a clean tree. It fetches and either
fast-forwards incoming commits or pushes outgoing commits. Equal histories are
a no-op. Divergence, unfinished edits, operation markers, remote mismatch,
missing remote branches, or authentication failures stop the attempt. There is
no auto-stash, rebase, conflict resolution, force push, or remote reconfiguration.
No extra tags or submodule repositories are pushed.

Run or inspect it yourself:

```sh
personal-wiki sync
personal-wiki sync-status
```

Status records the last completed attempt and last success time in UTC at
`<wiki>/.git/personal-wiki-sync.json`, outside versioned content. A previous
success does not mean subsequent commits have synced. Lock skips and failures
before validating the checkout are recorded only in
`~/Library/Logs/personal-wiki-sync.log`. The log also captures other errors.
There are no desktop notifications.

A crashed process can leave a lock. Confirm the recorded owner is inactive
before `personal-wiki unlock <owner-token>`. Locks are not stolen on a timer.
For divergence, review both histories and perform an explicitly chosen manual
resolution. For credential failures, restore normal credential access. Then
request sync or let the next interval retry. Each Git command is bounded by a
120-second timeout; no terminal prompt is allowed.

## Codex access

The optional profile extends `:workspace`, adds the wiki root, and grants write
access specifically to `<wiki>/.git` so inline commits work. Other workspaces'
Git metadata and baseline `.agents`, `.codex`, and `.aws` protections remain.
Network/approval policy is unchanged. Periodic sync runs as the native user
agent; foreground helpers still obey the chat's sandbox.

Restart Codex and start a fresh local chat outside the wiki. Verify the skill
is discovered and `index.md` is readable, then perform a requested test update
through begin/finish. A profile in config does not override a chat's runtime or
managed selection. Select personal-wiki if offered, or attach the wiki as a
secondary folder and request the narrow metadata access required for commits.
Do not enable Full access. Managed requirements may need administrator changes.
A secondary folder does not itself supply global instructions/skills.

Legacy sandbox_mode/sandbox_workspace_write do not compose with named profiles.
The merger stops on those keys in user config; inspect project/admin layers too.
Use `permissionProfile = null` to leave permission configuration untouched if
using another access setup. Null does not remove previously installed blocks.
This integration does not give ChatGPT web chats/cloud tasks local file access.

## Disable and validate

Set `programs.personalWiki.sync.enable = false` and activate to unload the job
while keeping inline commits. Set `programs.personalWiki.enable = false` to
remove Home Manager's command/settings/job. Copied skills and marked mutable
Codex blocks persist; remove only their personal-wiki portions explicitly for
full removal. Activation restores the base git-workflow skill without the wiki
exception on disabled hosts. If an older configuration was already activated
on a work Mac, remove those copied wiki files and marked blocks there as part
of disabling it; merely disabling the option does not erase those prior copies.
The wiki and GitHub repository are never deleted. Nix rollback does not roll
back wiki content, copied skills, or mutable config blocks.

Run local tests from the `nix-dotfiles` checkout (all test repositories/remotes are disposable and local):

```sh
python3 -B -m unittest discover -s tests -p 'test_personal_wiki*.py'
```

Evaluation/builds through `nix-hosts` check module integration and the launchd job. Local Git
tests exercise commits, signing failure, locks, dirty trees, remote/branch
mismatch, fast-forwards, pushes, and divergence. These tests do not establish
real GitHub credentials or live desktop permissions; verify after activation.

References: [LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f),
[OpenAI skills](https://learn.chatgpt.com/docs/build-skills),
[global instructions](https://learn.chatgpt.com/docs/agent-configuration/agents-md),
and [permission profiles](https://learn.chatgpt.com/docs/permissions).
